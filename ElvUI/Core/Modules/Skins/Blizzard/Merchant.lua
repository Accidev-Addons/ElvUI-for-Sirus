local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local select = select
local hooksecurefunc = hooksecurefunc
local GetBuybackItemInfo = GetBuybackItemInfo
local GetItemInfo = GetItemInfo
local GetMerchantNumItems = GetMerchantNumItems

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
