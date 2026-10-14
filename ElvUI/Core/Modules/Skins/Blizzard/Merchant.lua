local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local select = select
local hooksecurefunc = hooksecurefunc
local GetBuybackItemInfo = GetBuybackItemInfo
local GetItemInfo = GetItemInfo
local GetMerchantNumItems = GetMerchantNumItems
local GetMerchantItemMaxStack = GetMerchantItemMaxStack
local GetMoney = GetMoney
local IsAltKeyDown = IsAltKeyDown
local floor = math.floor

local function MerchantItemButton_AltStackBuy(button, mouseButton)
	if not IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown()
		or _G.MerchantFrame.selectedTab ~= 1
		or (mouseButton ~= "LeftButton" and mouseButton ~= "RightButton")
		or InRepairMode() or GetCursorInfo() or _G.MerchantFrame.refundItem then return false end

	local index = button:GetID()
	local link = GetMerchantItemLink(index)
	local stackSize = link and select(8, GetItemInfo(link))
	-- Do not guess a stack size when the item cache has not loaded yet.
	if not stackSize or stackSize <= 1 then return false end

	local _, _, price, bundleSize, stock, _, extendedCost = GetMerchantItemInfo(index)
	bundleSize = math.max(1, bundleSize or 1)
	-- The Sirus confirmation API expects number of purchases, not number of items.
	local purchases = floor(stackSize / bundleSize)
	local vendorLimit = GetMerchantItemMaxStack(index)
	if vendorLimit and vendorLimit > 1 then purchases = math.min(purchases, vendorLimit) end
	if stock and stock >= 0 then purchases = math.min(purchases, floor(stock / bundleSize)) end
	if price and price > 0 then purchases = math.min(purchases, floor(GetMoney() / price)) end

	if extendedCost then
		local honor, arena, itemCount = GetMerchantItemCostInfo(index)
		if honor and honor > 0 then purchases = math.min(purchases, floor((GetHonorCurrency() or 0) / honor)) end
		if arena and arena > 0 then purchases = math.min(purchases, floor((GetArenaCurrency() or 0) / arena)) end
		for i = 1, itemCount or 0 do
			local _, cost, itemLink = GetMerchantItemCostItem(index, i)
			if not itemLink or not cost or cost <= 0 then return true end
			purchases = math.min(purchases, floor(GetItemCount(itemLink) / cost))
		end
	end

	-- Consume the Alt click even when nothing can be bought; never fall through
	-- to the native one-item purchase after a full-stack request.
	if purchases < 1 then return true end
	if extendedCost then
		MerchantFrame_ConfirmExtendedItemCost(button, purchases)
	elseif price and price * purchases >= _G.MERCHANT_HIGH_PRICE_COST then
		MerchantFrame_ConfirmHighCostItem(button, purchases)
	else
		BuyMerchantItem(index, purchases)
	end
	return true
end

local function MerchantItemButton_AltStackHint(tooltip)
	if _G.MerchantFrame.selectedTab ~= 1 or not tooltip.merchantSlotIndex then return end

	tooltip:AddLine(L["Alt-click to buy the full stack"], 1, 1, 1)
end

hooksecurefunc(_G.GameTooltip, "SetMerchantItem", MerchantItemButton_AltStackHint)

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.merchant then return end

	local MerchantFrame = _G.MerchantFrame

	S:HandleSirusFrame(MerchantFrame)

	local searchBox = _G.MerchantFrameSearchEditBox
	if searchBox then
		S:HandleEditBox(searchBox, nil, true)
	end

	local lootFilter = _G.MerchantFrameLootFilter
	if lootFilter then
		S:HandleDropDownBox(lootFilter, 120)
	end

	MerchantFrameInset:StripTextures()
	MerchantFrame.ArtworkFrame:StripTextures()
	MerchantMoneyBg:StripTextures()
	MerchantMoneyInset:StripTextures()
	MerchantExtraCurrencyBg:StripTextures()
	MerchantExtraCurrencyInset:StripTextures()

	MerchantFrame:EnableMouseWheel(true)
	MerchantFrame:SetScript("OnMouseWheel", function(_, value)
		if value > 0 then
			if MerchantPrevPageButton:IsShown() and MerchantPrevPageButton:IsEnabled() == 1 then
				MerchantPrevPageButton_OnClick()
			end
		else
			if MerchantNextPageButton:IsShown() and MerchantNextPageButton:IsEnabled() == 1 then
				MerchantNextPageButton_OnClick()
			end
		end
	end)

	for i = 1, 12 do
		local item = _G["MerchantItem"..i]
		local button = _G["MerchantItem"..i.."ItemButton"]
		local icon = _G["MerchantItem"..i.."ItemButtonIconTexture"]
		local money = _G["MerchantItem"..i.."MoneyFrame"]
		local nameFrame = _G["MerchantItem"..i.."NameFrame"]
		local name = _G["MerchantItem"..i.."Name"]
		local slot = _G["MerchantItem"..i.."SlotTexture"]

		item:StripTextures(true)
		item:CreateBackdrop("Default")
		item.backdrop:Point("BOTTOMRIGHT", 0, -4)

		button:StripTextures()
		button:StyleButton()
		button:SetTemplate("Default", true)
		button:Size(40)
		button:Point("TOPLEFT", item, "TOPLEFT", 4, -4)
		-- Consume Alt clicks with an addon-owned hit target. Do not replace the
		-- client's script or post-hook a purchase that already happened.
		local altButton = CreateFrame("Button", nil, button)
		altButton:SetAllPoints(button)
		altButton:SetFrameLevel(button:GetFrameLevel() + 1)
		altButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		altButton:EnableMouse(false)
		altButton:SetScript("OnClick", function(_, mouseButton)
			if not MerchantItemButton_AltStackBuy(button, mouseButton) then
				local originalClick = button:GetScript("OnClick")
				if originalClick then originalClick(button, mouseButton) end
			end
		end)
		altButton:SetScript("OnEnter", function() MerchantItemButton_OnEnter(button) end)
		altButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
		local function UpdateAltMouse()
			altButton:EnableMouse(IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown())
		end
		altButton:RegisterEvent("MODIFIER_STATE_CHANGED")
		altButton:SetScript("OnEvent", UpdateAltMouse)
		altButton:SetScript("OnShow", UpdateAltMouse)
		UpdateAltMouse()

		icon:SetTexCoords()
		icon:SetInside()

		nameFrame:Point("LEFT", slot, "RIGHT", -6, -17)
		name:Point("LEFT", slot, "RIGHT", -4, 5)

		money:ClearAllPoints()
		money:Point("BOTTOMLEFT", button, "BOTTOMRIGHT", 3, 0)

		for j = 1, 2 do
			local currencyItem = _G["MerchantItem"..i.."AltCurrencyFrameItem"..j]
			local currencyIcon = _G["MerchantItem"..i.."AltCurrencyFrameItem"..j.."Texture"]

			currencyIcon.backdrop = CreateFrame("Frame", nil, currencyItem)
			currencyIcon.backdrop:SetTemplate("Default")
			currencyIcon.backdrop:SetFrameLevel(currencyItem:GetFrameLevel())
			currencyIcon.backdrop:SetOutside(currencyIcon)

			currencyIcon:SetTexCoords()
			currencyIcon:SetParent(currencyIcon.backdrop)
		end
	end

	S:HandleNextPrevButton(MerchantNextPageButton, nil, nil, true)
	S:HandleNextPrevButton(MerchantPrevPageButton, nil, nil, true)

	MerchantRepairItemButton:StyleButton()
	MerchantRepairItemButton:SetTemplate()

	for i = 1, MerchantRepairItemButton:GetNumRegions() do
		local region = select(i, MerchantRepairItemButton:GetRegions())
		if region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\MerchantFrame\\UI-Merchant-RepairIcons" then
			region:SetTexCoord(0.04, 0.24, 0.07, 0.5)
			region:SetInside()
		end
	end

	MerchantRepairAllButton:StyleButton()
	MerchantRepairAllButton:SetTemplate()

	MerchantRepairAllIcon:SetTexCoord(0.34, 0.1, 0.34, 0.535, 0.535, 0.1, 0.535, 0.535)
	MerchantRepairAllIcon:SetInside()

	MerchantGuildBankRepairButton:StyleButton()
	MerchantGuildBankRepairButton:SetTemplate()

	MerchantGuildBankRepairButtonIcon:SetTexCoord(0.61, 0.82, 0.1, 0.52)
	MerchantGuildBankRepairButtonIcon:SetInside()

	MerchantBuyBackItem:StripTextures(true)
	MerchantBuyBackItem:CreateBackdrop("Transparent")
	MerchantBuyBackItem.backdrop:Point("TOPLEFT", -6, 6)
	MerchantBuyBackItem.backdrop:Point("BOTTOMRIGHT", 6, -6)
	MerchantBuyBackItem:Point("TOPLEFT", MerchantItem10, "BOTTOMLEFT", 0, -48)

	MerchantBuyBackItemItemButton:StripTextures()
	MerchantBuyBackItemItemButton:SetTemplate("Default", true)
	MerchantBuyBackItemItemButton:StyleButton()

	MerchantBuyBackItemItemButtonIconTexture:SetTexCoords()
	MerchantBuyBackItemItemButtonIconTexture:SetInside()

	S:HandleSirusTabs("MerchantFrameTab", 2)

	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
		local numMerchantItems = GetMerchantNumItems()
		local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE
		local _, button, name, quality

		for i = 1, BUYBACK_ITEMS_PER_PAGE do
			index = index + 1

			if index <= numMerchantItems then
				button = _G["MerchantItem"..i.."ItemButton"]
				name = _G["MerchantItem"..i.."Name"]

				if button.link then
					_, _, quality = GetItemInfo(button.link)

					if quality and quality > 1 then
						local r, g, b = E:GetItemQualityColor(quality)
						button:SetBackdropBorderColor(r, g, b)
						name:SetTextColor(r, g, b)
					else
						button:SetBackdropBorderColor(unpack(E.media.bordercolor))
						name:SetTextColor(1, 1, 1)
					end
				else
					button:SetBackdropBorderColor(unpack(E.media.bordercolor))
					name:SetTextColor(1, 1, 1)
				end
			end

			local buybackName = GetBuybackItemInfo(GetNumBuybackItems())
			if buybackName then
				_, _, quality = GetItemInfo(buybackName)

				if quality and quality > 1 then
					local r, g, b = E:GetItemQualityColor(quality)
					MerchantBuyBackItemItemButton:SetBackdropBorderColor(r, g, b)
					MerchantBuyBackItemName:SetTextColor(r, g, b)
				else
					MerchantBuyBackItemItemButton:SetBackdropBorderColor(unpack(E.media.bordercolor))
					MerchantBuyBackItemName:SetTextColor(1, 1, 1)
				end
			else
				MerchantBuyBackItemItemButton:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		end
	end)

	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
		local numBuybackItems = GetNumBuybackItems()
		local _, button, name, quality

		for i = 1, BUYBACK_ITEMS_PER_PAGE do
			if i <= numBuybackItems then
				local buybackName = GetBuybackItemInfo(i)

				if buybackName then
					button = _G["MerchantItem"..i.."ItemButton"]
					name = _G["MerchantItem"..i.."Name"]
					_, _, quality = GetItemInfo(buybackName)

					if quality and quality > 1 then
						local r, g, b = E:GetItemQualityColor(quality)
						button:SetBackdropBorderColor(r, g, b)
						name:SetTextColor(r, g, b)
					else
						button:SetBackdropBorderColor(unpack(E.media.bordercolor))
						name:SetTextColor(1, 1, 1)
					end
				end
			end
		end
	end)
end

S:AddCallback("Skin_Merchant", LoadSkin)
