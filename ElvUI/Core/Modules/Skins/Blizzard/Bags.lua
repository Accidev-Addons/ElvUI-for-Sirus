local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local B = E:GetModule("Bags")

--Lua functions
local _G = _G
local ipairs = ipairs
local select = select
local unpack = unpack
--WoW API / Variables
local ContainerIDToInventoryID = ContainerIDToInventoryID
local GetContainerItemLink = GetContainerItemLink
local GetContainerItemQuestInfo = GetContainerItemQuestInfo
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local GetInventoryItemID = GetInventoryItemID

local BANK_CONTAINER = BANK_CONTAINER
local REAGENTBANK_CONTAINER = REAGENTBANK_CONTAINER

local function SetItemBorder(button, r, g, b)
	if r then
		button:SetBackdropBorderColor(r, g, b)
		button.ignoreBorderColors = true
	else
		button:SetBackdropBorderColor(unpack(E.media.bordercolor))
		button.ignoreBorderColors = nil
	end
end

local function QualityColor(quality)
	if quality and quality > 1 then
		return E:GetItemQualityColor(quality)
	end
end

local function UpdateSlotBorder(button, bagID, slotID, questTexture)
	if questTexture then
		questTexture:Hide()
	end

	local link = GetContainerItemLink(bagID, slotID)
	if not link then
		return SetItemBorder(button)
	end

	local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bagID, slotID)

	if questId and not isActive then
		if questTexture then
			questTexture:Show()
		end

		return SetItemBorder(button, unpack(B.QuestColors.questStarter))
	elseif questId or isQuestItem then
		return SetItemBorder(button, unpack(B.QuestColors.questItem))
	end

	return SetItemBorder(button, QualityColor(select(3, GetItemInfo(link))))
end

local function SkinItemButton(button)
	if button.elvSkinned then return end

	button:SetNormalTexture(nil)
	button:SetTemplate("Default", true)
	button:StyleButton()
	button.emptyBackgroundAtlas = nil
	button.emptyBackgroundTexture = nil

	button.icon:SetInside()
	button.icon:SetTexCoords()

	if button.IconBorder then
		button.IconBorder:SetAlpha(0)
	end

	button.IconQuestTexture:SetTexture(E.Media.Textures.BagQuestIcon)
	button.IconQuestTexture.SetTexture = E.noop
	button.IconQuestTexture:SetTexCoord(0, 1, 0, 1)
	button.IconQuestTexture:SetInside()

	button.Cooldown.CooldownOverride = "bags"
	E:RegisterCooldown(button.Cooldown)

	button.elvSkinned = true
end

S:AddCallback("Skin_ItemExpiration", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.bags then return end

	local frame = _G.ContainerItemExpirationFrame
	if not frame then return end

	frame:StripTextures()
	frame:SetTemplate("Transparent")

	frame.Title:ClearAllPoints()
	frame.Title:Point("TOPLEFT", 8, -9)
	frame.Title:SetJustifyH("LEFT")

	frame.TextBackground:SetTexture(E.media.blankTex)
	frame.TextBackground:SetVertexColor(0, 0, 0, 0.25)

	S:HandleCloseButton(_G.ContainerItemExpirationFrameCloseButton)

	hooksecurefunc(frame, "UpdateItems", function(self)
		for _, button in ipairs(self.buttons) do
			SkinItemButton(button)

			if button.IconBorder:IsShown() then
				SetItemBorder(button, button.IconBorder:GetVertexColor())
			else
				SetItemBorder(button)
			end
		end
	end)
end)

S:AddCallback("Skin_Bags", function()
	if E.private.bags.enable then return end
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.bags then return end

	local function UpdateBorderColors(frame)
		if not frame.Items then return end

		for _, button in ipairs(frame.Items) do
			if button.elvSkinned then
				local bagID = button:GetBagID()
				local _, bagType = GetContainerNumFreeSlots(bagID)

				if B.ProfessionColors[bagType] then
					button.IconQuestTexture:Hide()
					SetItemBorder(button, unpack(B.ProfessionColors[bagType]))
				else
					UpdateSlotBorder(button, bagID, button:GetID(), button.IconQuestTexture)
				end
			end
		end
	end

	local function SkinFrameItems(frame)
		if not frame.Items then return end

		for _, button in ipairs(frame.Items) do
			SkinItemButton(button)
			button.emptyBackgroundAtlas = nil
			button.emptyBackgroundTexture = nil
		end
	end

	local BAG_COLUMNS, BAG_SPACING, BAG_ITEM_SIZE = 4, 2, 37
	local BAGS_PER_COLUMN = 3
	local BAG_WIDTH = (BAG_COLUMNS * BAG_ITEM_SIZE) + ((BAG_COLUMNS - 1) * BAG_SPACING) + 14

	local function GetColumns()
		return BAG_COLUMNS
	end

	local function GetAnchorLayout(self)
		return AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.BottomRightToTopLeft, self:GetColumns(), BAG_SPACING, BAG_SPACING)
	end

	local function CalculateWidth()
		return BAG_WIDTH
	end

	local function CalculateHeight(self)
		local rows = self:GetRows()
		return (rows * BAG_ITEM_SIZE) + ((rows - 1) * BAG_SPACING) + self:GetPaddingHeight() + self:CalculateExtraHeight()
	end

	local function SetSearchBoxPoint(self, searchBox)
		searchBox:ClearAllPoints()
		searchBox:Point("TOPLEFT", self, "TOPLEFT", 10, -44)
		searchBox:Width(BAG_WIDTH - 44)
	end

	local function AnchorKeyRing(self)
		local keyRingFrame = _G.BagKeyRingFrame
		if keyRingFrame:GetParent() == self then
			keyRingFrame:ClearAllPoints()
			keyRingFrame:Point("TOPRIGHT", self, "TOPRIGHT", -8, -42)
		end
	end

	for i = 1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame"..i]
		local closeButton = _G["ContainerFrame"..i.."CloseButton"]

		frame:StripTextures(true)

		if frame.Bg then
			frame.Bg:StripTextures(true)
		end

		frame:CreateBackdrop("Transparent")
		frame.backdrop:Point("TOPLEFT", 3, -4)
		frame.backdrop:Point("BOTTOMRIGHT", -4, 1)

		frame.GetColumns = GetColumns
		frame.GetAnchorLayout = GetAnchorLayout
		frame.CalculateWidth = CalculateWidth
		frame.CalculateHeight = CalculateHeight
		frame.SetSearchBoxPoint = SetSearchBoxPoint
		hooksecurefunc(frame, "UpdateSearchBox", AnchorKeyRing)

		local titleText = frame.TitleText
		if titleText then
			titleText:ClearAllPoints()
			titleText:Point("BOTTOMLEFT", _G["ContainerFrame"..i.."PortraitButton"], "BOTTOMRIGHT", 6, 0)
			titleText:Point("RIGHT", closeButton, "LEFT", -2, 0)
			titleText:SetJustifyH("LEFT")
		end

		S:HookScript(frame, "OnShow", function(self)
			S:SetBackdropHitRect(self)
			S:Unhook(self, "OnShow")
		end)

		S:HandleCloseButton(closeButton, frame.backdrop)

		if frame.UpdateItemSlots then
			hooksecurefunc(frame, "UpdateItemSlots", SkinFrameItems)
		end
		if frame.UpdateItems then
			hooksecurefunc(frame, "UpdateItems", UpdateBorderColors)
		end

		SkinFrameItems(frame)
	end

	hooksecurefunc("UpdateContainerFrameAnchors", function()
		local previous, columnStart

		for index, frame in ipairs(ContainerFrameSettingsManager:GetBagsShown()) do
			if index == 1 then
				columnStart = frame
			else
				frame:ClearAllPoints()

				if (index - 1) % BAGS_PER_COLUMN == 0 then
					frame:Point("BOTTOMRIGHT", columnStart, "BOTTOMLEFT", 4, 0)
					columnStart = frame
				else
					frame:Point("BOTTOMRIGHT", previous, "TOPRIGHT", 0, -2)
				end
			end

			previous = frame
		end
	end)

	local containerMoney = _G.ContainerFrame1MoneyFrame
	if containerMoney and containerMoney.Border then
		containerMoney.Border:StripTextures()
	end

	if _G.BagItemSearchBox then
		S:HandleEditBox(_G.BagItemSearchBox, nil, true)
	end

	local keyRing = _G.KeyRingButton
	if keyRing then
		_G.BagKeyRingFrame:Size(22)
		keyRing:Size(22)
		keyRing:SetTemplate()
		keyRing:StyleButton()

		if keyRing.IconBorder then
			keyRing.IconBorder:Hide()
		end

		keyRing.Icon:SetTexCoords()
		keyRing.Icon:SetInside()
	end

	BackpackTokenFrame:StripTextures()

	for i = 1, MAX_WATCHED_TOKENS do
		local token = _G["BackpackTokenFrameToken"..i]

		token:CreateBackdrop("Default")
		token.backdrop:SetOutside(token.icon)

		token.icon:SetTexCoords()
		token.icon:Size(16)
	end

	local function setBagIcon(frame, texture)
		if not frame.BagIcon then
			local portraitButton = _G[frame:GetName().."PortraitButton"]

			portraitButton:CreateBackdrop()
			portraitButton:Size(32)
			portraitButton:Point("TOPLEFT", frame.backdrop, "TOPLEFT", 2, -2)
			portraitButton:StyleButton(nil, true)
			portraitButton.hover:SetAllPoints()

			frame.BagIcon = portraitButton:CreateTexture()
			frame.BagIcon:SetTexCoords()
			frame.BagIcon:SetAllPoints()
		end

		frame.BagIcon:SetTexture(texture)
	end

	local bagIconCache = {
		[-2] = [[Interface\ContainerFrame\KeyRing-Bag-Icon]],
		[0] = [[Interface\Buttons\Button-Backpack-Up]]
	}

	hooksecurefunc("ContainerFrame_GenerateFrame", function(frame)
		local id = frame:GetID()

		if id > 0 then
			local itemID = GetInventoryItemID("player", ContainerIDToInventoryID(id))

			if not bagIconCache[itemID] then
				bagIconCache[itemID] = select(10, GetItemInfo(itemID))
			end

			setBagIcon(frame, bagIconCache[itemID])
		else
			setBagIcon(frame, bagIconCache[id])
		end
	end)

	-- BankFrame
	BankFrame:StripTextures(true)
	BankFrame:CreateBackdrop("Transparent")

	local bankSlotsFrame = _G.BankSlotsFrame
	if bankSlotsFrame then
		bankSlotsFrame:StripTextures(true)

		for _, region in next, { bankSlotsFrame:GetRegions() } do
			if region.SetText then
				local text = region:GetText()
				if text == ITEMSLOTTEXT or text == BAGSLOTTEXT then
					region:SetText("")
				end
			end
		end
	end
	BankFrame.backdrop:Point("TOPLEFT", 11, -12)
	BankFrame.backdrop:Point("BOTTOMRIGHT", -26, 2)

	local moneyInset = _G.BankFrameMoneyFrameInset
	if moneyInset then
		moneyInset:StripTextures(true)
	end

	local moneyBorder = _G.BankFrameMoneyFrameBorder
	if moneyBorder then
		moneyBorder:StripTextures(true)
	end

	local moneyFrame = _G.BankFrameMoneyFrame
	if moneyFrame then
		if moneyFrame.backdrop then
			moneyFrame.backdrop:Hide()
		end
		moneyFrame:ClearAllPoints()
		moneyFrame:Point("BOTTOMRIGHT", BankFrame, "BOTTOMRIGHT", -30, 20)
	end

	local titleText = BankFrame.TitleText
	if titleText then
		titleText:ClearAllPoints()
		titleText:Point("TOP", BankFrame.backdrop, "TOP", 0, -8)
	end

	S:HookScript(BankFrame, "OnShow", function(self)
		S:SetUIPanelWindowInfo(self, "width")
		S:SetBackdropHitRect(self)
		S:Unhook(self, "OnShow")
	end)

	S:HandleCloseButton(BankFrame.CloseButton, BankFrame.backdrop)

	BankFrameItem1:ClearAllPoints()
	BankFrameItem1:Point("TOPLEFT", _G.BankSlotsFrame or BankFrame, "TOPLEFT", 28, -73)

	for i = 2, NUM_BANKGENERIC_SLOTS do
		local button = _G["BankFrameItem"..i]
		if button then
			button:ClearAllPoints()

			if (i - 1) % 7 == 0 then
				button:Point("TOPLEFT", _G["BankFrameItem"..(i - 7)], "BOTTOMLEFT", 0, -7)
			else
				button:Point("TOPLEFT", _G["BankFrameItem"..(i - 1)], "TOPRIGHT", 12, 0)
			end
		end
	end

	BankFrameBag1:ClearAllPoints()
	BankFrameBag1:Point("TOPLEFT", BankFrameItem1, "BOTTOMLEFT", 0, -164)

	for i = 2, NUM_BANKBAGSLOTS do
		local button = _G["BankFrameBag"..i]
		if button then
			button:ClearAllPoints()
			button:Point("TOPLEFT", _G["BankFrameBag"..(i - 1)], "TOPRIGHT", 12, 0)
		end
	end

	for i = 1, NUM_BANKGENERIC_SLOTS do
		local button = _G["BankFrameItem"..i]

		if button.Background then
			button.Background:SetTexture(nil)
		end

		SkinItemButton(button)
	end

	BankFrame.itemBackdrop = CreateFrame("Frame", "BankFrameItemBackdrop", BankFrame)
	BankFrame.itemBackdrop:SetTemplate("Default")
	BankFrame.itemBackdrop:SetOutside(BankFrameItem1, 6, 6, BankFrameItem28)
	BankFrame.itemBackdrop:OffsetFrameLevel(nil, BankFrame)

	for i = 1, NUM_BANKBAGSLOTS do
		local button = _G["BankFrameBag"..i]
		local icon = _G["BankFrameBag"..i.."IconTexture"]
		local highlight = _G["BankFrameBag"..i.."HighlightFrameTexture"]

		button:SetNormalTexture(nil)
		button:SetTemplate("Default", true)
		button:StyleButton()

		if button.IconBorder then
			button.IconBorder:SetAlpha(0)
		end

		icon:SetInside()
		icon:SetTexCoords()

		local r, g, b = unpack(E.media.rgbvaluecolor)
		highlight:SetInside()
		highlight:SetTexture(r, g, b, 0.3)
	end

	BankFrame.bagBackdrop = CreateFrame("Frame", "BankFrameBagBackdrop", BankFrame)
	BankFrame.bagBackdrop:SetTemplate("Default")
	BankFrame.bagBackdrop:SetOutside(BankFrameBag1, 6, 6, BankFrameBag7)
	BankFrame.bagBackdrop:OffsetFrameLevel(nil, BankFrame)

	S:HandleButton(BankFramePurchaseButton)
	BankFramePurchaseButton:Point("RIGHT", -4, -10)

	for i = 1, 2 do
		local tab = _G["BankFrameTab"..i]
		if tab then
			S:HandleSirusTab(tab, i > 1 and _G["BankFrameTab"..(i - 1)])
		end
	end

	hooksecurefunc("BankFrameItemButton_Update", function(button)
		local id = button:GetID()

		button:SetNormalTexture(nil)

		if button.Background then
			button.Background:SetTexture(nil)
		end

		if button.isBag then
			local link = GetInventoryItemLink("player", ContainerIDToInventoryID(id))

			SetItemBorder(button, QualityColor(link and select(3, GetItemInfo(link))))
		else
			UpdateSlotBorder(button, button:GetBagID() or BANK_CONTAINER, id, _G[button:GetName().."IconQuestTexture"])
		end
	end)

	local reagentBankFrame = _G.ReagentBankFrame
	if reagentBankFrame then
		reagentBankFrame:StripTextures(true)

		local function SkinReagentBankSlot(button)
			if button.elvSkinned then return end

			if button.Background then
				button.Background:SetTexture(nil)
			end

			button:SetNormalTexture(nil)
			button:SetTemplate("Transparent")
			button:StyleButton()
			button.emptyBackgroundAtlas = nil
			button.emptyBackgroundTexture = nil

			button.icon:SetInside()
			button.icon:SetTexCoords()

			if button.IconBorder then
				button.IconBorder:SetAlpha(0)
			end

			button.IconQuestTexture:SetTexture(E.Media.Textures.BagQuestIcon)
			button.IconQuestTexture.SetTexture = E.noop
			button.IconQuestTexture:SetTexCoord(0, 1, 0, 1)
			button.IconQuestTexture:SetInside()

			button.Cooldown.CooldownOverride = "bags"
			E:RegisterCooldown(button.Cooldown)

			if not button.reagentTooltipFixed then
				local function ReagentTooltip_OnEnter(self)
					local link = GetContainerItemLink(REAGENTBANK_CONTAINER, self:GetID())
					if link then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetHyperlink(link)
						GameTooltip:Show()
					else
						GameTooltip:Hide()
					end
					ResetCursor()
				end
				button:SetScript("OnEnter", ReagentTooltip_OnEnter)
				button.UpdateTooltip = ReagentTooltip_OnEnter
				button.reagentTooltipFixed = true
			end

			button.elvSkinned = true
		end

		local function SkinReagentBank()
			if BankFrame.backdrop then
				BankFrame.backdrop:Hide()
			end

			if not reagentBankFrame.backdrop then
				reagentBankFrame:CreateBackdrop("Transparent")
				reagentBankFrame.backdrop:Point("TOPLEFT", 11, -12)
				reagentBankFrame.backdrop:Point("BOTTOMRIGHT", -26, 2)
			end
			reagentBankFrame.backdrop:Show()

			if reagentBankFrame.itemBackdrop then
				reagentBankFrame.itemBackdrop:Hide()
			end

			if BankFrame.itemBackdrop then
				BankFrame.itemBackdrop:Hide()
			end
			if BankFrame.bagBackdrop then
				BankFrame.bagBackdrop:Hide()
			end

			reagentBankFrame:StripTextures(true)
			for column = 1, 7 do
				local bg = reagentBankFrame["BG"..column]
				if bg then bg:SetTexture(nil) end
			end

			for i = 1, 98 do
				local button = _G["ReagentBankFrameItem"..i]
				if button then
					SkinReagentBankSlot(button)
				end
			end
		end

		reagentBankFrame:HookScript("OnShow", SkinReagentBank)
		SkinReagentBank()

		if reagentBankFrame.DespositButton then
			S:HandleButton(reagentBankFrame.DespositButton)
			reagentBankFrame.DespositButton:Point("BOTTOM", reagentBankFrame, "BOTTOM", 0, 24)
		end

		local sortButton = _G.BankItemAutoSortButton
		if sortButton then
			sortButton:ClearAllPoints()
			sortButton:Point("TOPRIGHT", BankFrame, "TOPRIGHT", -26, -30)
		end

		local unlockInfo = reagentBankFrame.UnlockInfo
		if unlockInfo then
			if unlockInfo.PurchaseButton then
				S:HandleButton(unlockInfo.PurchaseButton)
			end

			unlockInfo:StripTextures()
			unlockInfo:SetTemplate("Transparent")
		end

		if bankSlotsFrame then
			bankSlotsFrame:HookScript("OnShow", function()
				if BankFrame.backdrop then
					BankFrame.backdrop:Show()
				end
				if reagentBankFrame.backdrop then
					reagentBankFrame.backdrop:Hide()
				end
				if BankFrame.itemBackdrop then
					BankFrame.itemBackdrop:Show()
				end
				if BankFrame.bagBackdrop then
					BankFrame.bagBackdrop:Show()
				end
			end)
		end

		local BANK_WINDOW_WIDTH = 400
		local REAGENT_WINDOW_WIDTH = 755

		if BankFrame_ShowPanel then
			hooksecurefunc("BankFrame_ShowPanel", function(sidePanelName)
				if sidePanelName == "ReagentBankFrame" then
					BankFrame:SetWidth(REAGENT_WINDOW_WIDTH)
				elseif sidePanelName == "BankSlotsFrame" then
					BankFrame:SetWidth(BANK_WINDOW_WIDTH)
				end
			end)
		end

	end
end)
