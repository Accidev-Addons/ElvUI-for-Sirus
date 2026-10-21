local E, L = unpack(ElvUI)
local _G = _G
local select = select
local GetItemInfo = GetItemInfo
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
	if not stackSize or stackSize <= 1 then return false end

	local _, _, price, bundleSize, stock, _, extendedCost = GetMerchantItemInfo(index)
	bundleSize = math.max(1, bundleSize or 1)
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

local function MerchantItemButton_AltStackHint(tooltip, index)
	if _G.MerchantFrame.selectedTab ~= 1 or not tooltip.merchantSlotIndex then return end

	local link = GetMerchantItemLink(index)
	local stackSize = link and select(8, GetItemInfo(link))
	if not stackSize or stackSize <= 1 then return end

	tooltip:AddLine(L["Alt-click to buy the full stack"], 1, 1, 1)
	tooltip:Show()
end

hooksecurefunc(_G.GameTooltip, "SetMerchantItem", MerchantItemButton_AltStackHint)

local buttons = {}
local function UpdateAltMouse()
	local enabled = IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown()
	for _, button in ipairs(buttons) do button:EnableMouse(enabled) end
end
local function InstallAltStackButtons()
	for i = 1, 12 do
		local button = _G["MerchantItem"..i.."ItemButton"]
		if button and not button.elvAltStackButton then
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
			altButton:SetScript("OnLeave", function()
				local onLeave = button:GetScript("OnLeave")
				if onLeave then onLeave(button) end
			end)
			altButton:SetScript("OnShow", UpdateAltMouse)
			button.elvAltStackButton = altButton
			buttons[#buttons + 1] = altButton
		end
	end
	UpdateAltMouse()
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("MERCHANT_SHOW")
watcher:RegisterEvent("MODIFIER_STATE_CHANGED")
watcher:SetScript("OnEvent", function(_, event)
	if event == "MERCHANT_SHOW" then InstallAltStackButtons() else UpdateAltMouse() end
end)
