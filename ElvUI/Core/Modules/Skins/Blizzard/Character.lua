local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local select = select
local unpack = unpack

local GetCurrencyListInfo = GetCurrencyListInfo
local GetInventoryItemQuality = GetInventoryItemQuality

local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetNumFactions = GetNumFactions
local GetPetHappiness = GetPetHappiness
local HasPetUI = HasPetUI
local UnitFactionGroup = UnitFactionGroup
local hooksecurefunc = hooksecurefunc

local NUM_FACTIONS_DISPLAYED = NUM_FACTIONS_DISPLAYED


local Slots = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
		"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
		"MainHandSlot", "SecondaryHandSlot", "RangedSlot", "AmmoSlot"
	}

local function ColorGemBorder(prefix, unit)
	for _, name in pairs(Slots) do
		local link = GetInventoryItemLink(unit, GetInventorySlotInfo(name))
		local slot = _G[prefix..name]

		if slot then
			if not slot.textureSoc then
				slot.textureSoc = slot:CreateTexture("nil", "TOOLTIP")
				slot.textureSoc:SetInside()
				slot.textureSoc:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\BagNewItemGlow]])
				slot.textureSoc:SetVertexColor(GetItemQualityColor(5))
				slot.textureSoc:Hide()
			end

			local found
			if link then
				for i = 1, 3 do
					local _, gemLink = GetItemGem(link, i)
					if gemLink and select(3, GetItemInfo(gemLink)) == 5 then
						slot.textureSoc:Show()
						found = true
						break
					end
				end
			end

			if not found then
				slot.textureSoc:Hide()
			end
		end
	end
end

function S:ColorItemCharacterBorder()
	ColorGemBorder("Character", "player")
end

function S:ColorItemInspectBorder()
	ColorGemBorder("Inspect", "target")
end

local function ColorizeStatPane(frame)
	if frame.leftGrad then return end

	local r, g, b = 0.8, 0.8, 0.8
	frame.leftGrad = frame:CreateTexture(nil, "BORDER")
	frame.leftGrad:Width(frame:GetWidth() * .5)
	frame.leftGrad:Height(frame:GetHeight())
	frame.leftGrad:Point("LEFT", frame, "CENTER")
	frame.leftGrad:SetTexture(E.media.blankTex)
	frame.leftGrad:SetGradientAlpha("Horizontal", r, g, b, 0.35, r, g, b, 0)

	frame.rightGrad = frame:CreateTexture(nil, "BORDER")
	frame.rightGrad:Width(frame:GetWidth() * .5)
	frame.rightGrad:Height(frame:GetHeight())
	frame.rightGrad:Point("RIGHT", frame, "CENTER")
	frame.rightGrad:SetTexture(E.Media.Textures.White8x8)
	frame.rightGrad:SetGradientAlpha("Horizontal", r, g, b, 0, r, g, b, 0.35)
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.character then return end

	S:HandlePortraitFrame(CharacterFrame)

	local characterTabs = {}
	for i = 1, #CHARACTERFRAME_SUBFRAMES do
		local tab = _G["CharacterFrameTab" .. i]
		if tab then
			S:HandleSirusTab(tab)
			characterTabs[i] = tab
		end
	end
	S:HandleSirusTabFlow(characterTabs, "PetPaperDollFrame_UpdateIsAvailable")

	GearManagerDialog:StripTextures()
	GearManagerDialog:CreateBackdrop("Transparent")
	GearManagerDialog.backdrop:Point("TOPLEFT", 5, -2)
	GearManagerDialog.backdrop:Point("BOTTOMRIGHT", -1, 4)

	if GearManagerDialogClose then
		S:HandleCloseButton(GearManagerDialogClose)
	end

	for i = 1, 10 do
		_G["GearSetButton"..i]:StripTextures()
		_G["GearSetButton"..i]:StyleButton()
		_G["GearSetButton"..i]:CreateBackdrop("Default")
		_G["GearSetButton"..i].backdrop:SetAllPoints()
		_G["GearSetButton"..i.."Icon"]:SetTexCoord(unpack(E.TexCoords))
		_G["GearSetButton"..i.."Icon"]:SetInside()
	end

	S:HandleButton(GearManagerDialogDeleteSet)
	S:HandleButton(GearManagerDialogEquipSet)
	S:HandleButton(GearManagerDialogSaveSet)

	GearManagerDialogPopup:StripTextures()
	GearManagerDialogPopup:CreateBackdrop("Transparent")
	GearManagerDialogPopup.backdrop:Point("TOPLEFT", 5, -2)
	GearManagerDialogPopup.backdrop:Point("BOTTOMRIGHT", -4, 8)

	GearManagerDialogPopup:Height(287 + 15)
	GearManagerDialogPopupScrollFrame:Height(184 + 15)
	GearManagerDialogPopup.BorderBox:StripTextures()
	S:HandleEditBox(GearManagerDialogPopupSearchBox)

	S:HandleEditBox(GearManagerDialogPopupEditBox)

	GearManagerDialogPopupScrollFrame:StripTextures()
	S:HandleSirusScrollBar(GearManagerDialogPopupScrollFrameScrollBar)

	for i = 1, NUM_GEARSET_ICONS_SHOWN do
		local button = _G["GearManagerDialogPopupButton"..i]
		local icon = button.icon

		if button then
			button:StripTextures()
			button:StyleButton(true)

			icon:SetTexCoord(unpack(E.TexCoords))
			_G["GearManagerDialogPopupButton"..i.."Icon"]:SetTexture(nil)

			icon:SetInside()
			button:SetFrameLevel(button:GetFrameLevel() + 2)
			if not button.backdrop then
				button:CreateBackdrop("Default")
				button.backdrop:SetAllPoints()
			end
		end
	end

	S:HandleButton(GearManagerDialogPopupOkay)
	S:HandleButton(GearManagerDialogPopupCancel)

	PaperDollFrame:StripTextures(true)

	PaperDollFrame.NewPanel:StripTextures()
	ColorizeStatPane(PaperDollFrameStrengthenFrame.Title)
	PaperDollFrameStrengthenFrame.Title.Background:SetAlpha(0)

	S:HandleButton(PaperDollFrameStrengthenFrame.ResetButton)

	for i = 1, C_PlayerInfo.GetNumBonusStats() do
		local statPlus = _G["PaperDollFrameStrengthenFrameStat"..i.."Plus"]
		if statPlus then
			S:HandleSirusToggle(statPlus, E.Media.Textures.Plus)
			statPlus:SetDisabledTexture(E.Media.Textures.Plus)
			statPlus:GetDisabledTexture():SetInside()
			statPlus:GetDisabledTexture():SetDesaturated(true)
		end
	end

	PaperDollSidebarTabs:StripTextures()

	C_Timer:After(0,function()
		if PaperDollFrameItemSetSwapButton then
			PaperDollFrameItemSetSwapButton:StripTextures()
			S:HandleButton(PaperDollFrameItemSetSwapButton)
			PaperDollFrameItemSetSwapButton.Icon:SetTexCoord(unpack(E.TexCoords))
			PaperDollFrameItemSetSwapButton:ClearAllPoints()
			PaperDollFrameItemSetSwapButton:SetParent(ElvUI_PaperDollSidebarTabs and ElvUI_PaperDollSidebarTabs or PaperDollSidebarTabs)
			PaperDollFrameItemSetSwapButton:Size(32)
			local level = ElvUI_PaperDollSidebarTab1 and ElvUI_PaperDollSidebarTab1:GetFrameLevel() or PaperDollSidebarTab1:GetFrameLevel()
			local point = ElvUI_PaperDollSidebarTab1 and ElvUI_PaperDollSidebarTab1 or PaperDollSidebarTab1
			PaperDollFrameItemSetSwapButton:SetFrameLevel(level+1)
			PaperDollFrameItemSetSwapButton:SetPoint("RIGHT",point,"LEFT",-4,0)
		end
	end)
	PaperDollFrame.StatsInset:StripTextures()
	PaperDollFrame.EquipInset:StripTextures()
	CharacterModelFrame:CreateBackdrop()
	CharacterModelFrame.backdrop:SetOutside(CharacterModelFrameBackgroundOverlay)
	CharacterModelFrame:DisableDrawLayer("OVERLAY")

	S:HandleControlFrame(CharacterModelFrame.controlFrame)

	ColorizeStatPane(CharacterItemLevelFrame)
	CharacterItemLevelFrame.ilvlbackground:SetAlpha(0)

	PlayerTitleFrame:StripTextures()
	PlayerTitleFrame:CreateBackdrop("Default")
	PlayerTitleFrame.backdrop:Point("TOPLEFT", 20, 3)
	PlayerTitleFrame.backdrop:Point("BOTTOMRIGHT", -16, 14)
	PlayerTitleFrame.backdrop:SetFrameLevel(PlayerTitleFrame:GetFrameLevel())
	S:HandleNextPrevButton(PlayerTitleFrameButton)
	PlayerTitleFrameButton:ClearAllPoints()
	PlayerTitleFrameButton:Point("RIGHT", PlayerTitleFrame.backdrop, "RIGHT", -2, 0)

	PlayerTitlePickerScrollFrame:StripTextures()
	PlayerTitlePickerScrollFrame:CreateBackdrop("Transparent")

	for i = 1, #PlayerTitlePickerScrollFrame.buttons do
		PlayerTitlePickerScrollFrame.buttons[i].text:FontTemplate()
	end

	S:HandleSirusScrollBar(PlayerTitlePickerScrollFrameScrollBar)

	for i = 1, #PAPERDOLL_SIDEBARS do
		local tab = _G["PaperDollSidebarTab"..i]
		if tab then
			tab:CreateBackdrop()
			tab.Icon:SetAllPoints()
			tab.Highlights:SetTexture(1, 1, 1, .3)
			tab.Highlights:SetAllPoints()
			tab.TabBg:Kill()
		end
	end

	if CharacterCustomizationButton then
		CharacterCustomizationButton:ClearAllPoints()
		CharacterCustomizationButton:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 18, -18)

		CharacterCustomizationButton:Size(28, 28)
		CharacterCustomizationButton:CreateBackdrop()

		if CharacterCustomizationButton.NormalTexture then
			CharacterCustomizationButton.NormalTexture:SetInside()
			CharacterCustomizationButton.NormalTexture:SetTexCoord(unpack(E.TexCoords))
		end

		if CharacterCustomizationButton.HighlightTexture then
			CharacterCustomizationButton.HighlightTexture:SetTexture(1, 1, 1, 0.3)
			CharacterCustomizationButton.HighlightTexture:SetInside()
		end

		if CharacterCustomizationButton.DisabledTexture then
			CharacterCustomizationButton.DisabledTexture:SetInside()
			CharacterCustomizationButton.DisabledTexture:SetTexCoord(unpack(E.TexCoords))
		end
	end

	_G["GearManagerToggleButton"]:Size(26, 32)
	_G["GearManagerToggleButton"]:CreateBackdrop("Default")

	GearManagerToggleButton:GetNormalTexture():SetTexCoord(0.1875, 0.8125, 0.125, 0.90625)
	GearManagerToggleButton:GetPushedTexture():SetTexCoord(0.1875, 0.8125, 0.125, 0.90625)
	GearManagerToggleButton:GetHighlightTexture():SetTexture(1, 1, 1, 0.3)
	GearManagerToggleButton:GetHighlightTexture():SetAllPoints()

	local popoutButtonOnEnter = function(btn) btn.icon:SetVertexColor(unpack(E.media.rgbvaluecolor)) end
	local popoutButtonOnLeave = function(btn) btn.icon:SetVertexColor(1, 1, 1) end

	for _, slot in pairs(Slots) do
		local icon = _G["Character"..slot.."IconTexture"]
		local cooldown = _G["Character"..slot.."Cooldown"]
		local popout = _G["Character"..slot.."PopoutButton"]

		slot = _G["Character"..slot]
		slot:StripTextures()
		slot:StyleButton(false)
		slot:SetTemplate("Default", true, true)

		icon:SetTexCoord(unpack(E.TexCoords))
		icon:SetInside()

		slot:SetFrameLevel(PaperDollFrame:GetFrameLevel() + 2)

		if cooldown then
			E:RegisterCooldown(cooldown)
		end

		if popout then
			popout:StripTextures()
			popout:HookScript("OnEnter", popoutButtonOnEnter)
			popout:HookScript("OnLeave", popoutButtonOnLeave)

			popout.icon = popout:CreateTexture(nil, "ARTWORK")
			popout.icon:Size(24)
			popout.icon:Point("CENTER")
			popout.icon:SetTexture(E.Media.Textures.ArrowUp)

			if slot.verticalFlyout then
				popout.icon:SetRotation(S.ArrowRotation.down)
			else
				popout.icon:SetRotation(S.ArrowRotation.right)
			end
		end
	end

	local function ColorItemBorder()
		for _, slot in pairs(Slots) do
			local target = _G["Character"..slot]
			local slotId = GetInventorySlotInfo(slot)
			local itemId = GetInventoryItemID("player", slotId)

			if itemId then
				local rarity = GetInventoryItemQuality("player", slotId)
				if rarity then
					target:SetBackdropBorderColor(GetItemQualityColor(rarity))
				else
					target:SetBackdropBorderColor(unpack(E.media.bordercolor))
				end
			else
				target:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		end

		S:ColorItemCharacterBorder()

	end

	local CheckItemBorderColor = CreateFrame("Frame")
	CheckItemBorderColor:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

	CheckItemBorderColor:SetScript("OnEvent", ColorItemBorder)
	CharacterFrame:HookScript("OnShow", ColorItemBorder)
	ColorItemBorder()

	local function HandleResistanceFrame(frameName)
		for i = 1, 5 do
			local frame = _G[frameName..i]
			frame:Size(24)
			frame:SetTemplate("Default")

			if i ~= 1 then
				frame:ClearAllPoints()
				frame:Point("TOP", _G[frameName..i-1], "BOTTOM", 0, -(E.Border + E.Spacing))
			end

			select(1, _G[frameName..i]:GetRegions()):SetInside()
			select(1, _G[frameName..i]:GetRegions()):SetDrawLayer("ARTWORK")
			select(2, _G[frameName..i]:GetRegions()):SetDrawLayer("OVERLAY")
		end
	end

	HandleResistanceFrame("MagicResFrame")

	select(1, MagicResFrame1:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.25, 0.32421875)
	select(1, MagicResFrame2:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.0234375, 0.09765625)
	select(1, MagicResFrame3:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.13671875, 0.2109375)
	select(1, MagicResFrame4:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.36328125, 0.4375)
	select(1, MagicResFrame5:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.4765625, 0.55078125)

	S:HandleDropDownBox(PlayerStatFrameLeftDropDown, 140, "down")
	S:HandleDropDownBox(PlayerStatFrameRightDropDown, 140, "down")
	CharacterAttributesFrame:StripTextures()

	PetPaperDollFrame:StripTextures(true)

	S:HandleRotateButton(PetModelFrameRotateLeftButton)
	S:HandleRotateButton(PetModelFrameRotateRightButton)
	PetModelFrameRotateRightButton:SetPoint("TOPLEFT", PetModelFrameRotateLeftButton, "TOPRIGHT", 3, 0)

	HandleResistanceFrame("PetMagicResFrame")

	select(1, PetMagicResFrame1:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.25, 0.32421875)
	select(1, PetMagicResFrame2:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.0234375, 0.09765625)
	select(1, PetMagicResFrame3:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.13671875, 0.2109375)
	select(1, PetMagicResFrame4:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.36328125, 0.4375)
	select(1, PetMagicResFrame5:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.4765625, 0.55078125)

	PetAttributesFrame:StripTextures()

	S:HandleSirusStatusBar(PetPaperDollFrameExpBar)

	local function updHappiness(self)
		local happiness = GetPetHappiness()
		local _, isHunterPet = HasPetUI()
		if not happiness or not isHunterPet then return end

		local texture = self:GetRegions()
		if happiness == 1 then
			texture:SetTexCoord(0.41, 0.53, 0.06, 0.30)
		elseif happiness == 2 then
			texture:SetTexCoord(0.22, 0.345, 0.06, 0.30)
		elseif happiness == 3 then
			texture:SetTexCoord(0.04, 0.15, 0.06, 0.30)
		end
	end

	PetPaperDollPetInfo:SetPoint("TOPLEFT", PetModelFrameRotateLeftButton, "BOTTOMLEFT", 9, -3)
	PetPaperDollPetInfo:GetRegions():SetTexCoord(0.04, 0.15, 0.06, 0.30)
	PetPaperDollPetInfo:SetFrameLevel(PetModelFrame:GetFrameLevel() + 2)
	PetPaperDollPetInfo:CreateBackdrop("Default")
	PetPaperDollPetInfo:Size(24, 24)
	updHappiness(PetPaperDollPetInfo)

	PetPaperDollPetInfo:RegisterEvent("UNIT_HAPPINESS")
	PetPaperDollPetInfo:SetScript("OnEvent", updHappiness)
	PetPaperDollPetInfo:SetScript("OnShow", updHappiness)

	PetPaperDollFrameCompanionFrame:StripTextures()

	S:HandleRotateButton(CompanionModelFrameRotateLeftButton)
	S:HandleRotateButton(CompanionModelFrameRotateRightButton)
	CompanionModelFrameRotateRightButton:SetPoint("TOPLEFT", CompanionModelFrameRotateLeftButton, "TOPRIGHT", 3, 0)

	S:HandleButton(CompanionSummonButton)

	S:HandleNextPrevButton(CompanionPrevPageButton)
	S:HandleNextPrevButton(CompanionNextPageButton)

	ReputationFrame:StripTextures(true)

	for i = 1, NUM_FACTIONS_DISPLAYED do
		local factionRow = _G["ReputationBar"..i]
		local factionBar = _G["ReputationBar"..i.."ReputationBar"]
		local factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"]
		local headerButton = _G["ReputationBar"..i.."HeaderButton"]

		factionRow:StripTextures(true)			S:HandleSirusStatusBar(factionBar)

		factionButton:SetNormalTexture(E.Media.Textures.Minus)
		factionButton.SetNormalTexture = E.noop
		factionButton.SetNormalAtlas = E.noop
		factionButton.SetPushedAtlas = E.noop
		factionButton:GetNormalTexture():Size(15)
		factionButton:SetHighlightTexture(nil)

		if headerButton then
			if headerButton.HighlightLeft then headerButton.HighlightLeft:Kill() end
			if headerButton.HighlightRight then headerButton.HighlightRight:Kill() end
			if headerButton.HighlightMiddle then headerButton.HighlightMiddle:Kill() end
			if headerButton.Name then headerButton.Name:Kill() end

			local arrow = headerButton:CreateTexture(nil, "ARTWORK")
			arrow:Size(15)
			arrow:SetPoint("LEFT", 5, 0)
			headerButton.collapseArrow = arrow
		end
	end

	local function UpdateFaction()
		local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame)
		local factionIndex, factionRow, factionButton, headerButton
		local numFactions = GetNumFactions()
		for i = 1, NUM_FACTIONS_DISPLAYED, 1 do
			factionRow = _G["ReputationBar"..i]
			factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"]
			headerButton = _G["ReputationBar"..i.."HeaderButton"]
			factionIndex = factionOffset + i
			if factionIndex <= numFactions then
				if headerButton and headerButton:IsShown() then
					if headerButton.Left then headerButton.Left:SetTexture() end
					if headerButton.Right then headerButton.Right:SetTexture() end
					if headerButton.Middle then headerButton.Middle:SetTexture() end

					S:SetSirusCollapseIcon(headerButton, factionRow.isCollapsed)
				end

				S:SetSirusCollapseIcon(factionButton, factionRow.isCollapsed)
			end
		end
	end
	hooksecurefunc("ReputationFrame_Update", UpdateFaction)

	ReputationListScrollFrame:StripTextures()
	S:HandleSirusScrollBar(ReputationListScrollFrameScrollBar)

	ReputationDetailFrame:StripTextures()
	ReputationDetailFrame:SetTemplate("Transparent")
	ReputationDetailFrame.TextContainer:StripTextures()
	ReputationDetailFrame.TextContainer.ShadowOverlay:StripTextures()

	S:HandleCloseButton(ReputationDetailCloseButton)
	ReputationDetailCloseButton:Point("TOPRIGHT", 3, 4)

	S:HandleCheckBox(ReputationDetailAtWarCheckBox)
	ReputationDetailAtWarCheckBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-SwordCheck")
	S:HandleCheckBox(ReputationDetailInactiveCheckBox)
	S:HandleCheckBox(ReputationDetailMainScreenCheckBox)

	SkillFrame:StripTextures(true)

	S:HandleNextPrevButton(SkillDetailStatusBarUnlearnButton)

	SkillDetailStatusBarUnlearnButton:Size(24)
	SkillDetailStatusBarUnlearnButton:Point("LEFT", SkillDetailStatusBarBorder, "RIGHT", 5, 0)
	SkillDetailStatusBarUnlearnButton:SetHitRectInsets(0, 0, 0, 0)

	SkillFrameExpandButtonFrame:StripTextures()

	S:HandleSirusCollapseToggle(SkillFrameCollapseAllButton)
	SkillFrameCollapseAllButton:Point("LEFT", SkillFrameExpandTabLeft, "RIGHT", -40, -3)

	for i = 1, SKILLS_TO_DISPLAY do
		local statusBar = _G["SkillRankFrame"..i]
		local statusBarBorder = _G["SkillRankFrame"..i.."Border"]
		local statusBarBackground = _G["SkillRankFrame"..i.."Background"]

		S:HandleSirusStatusBar(statusBar)

		statusBarBorder:StripTextures()
		statusBarBackground:SetTexture(nil)

		local skillTypeLabelText = _G["SkillTypeLabel"..i]
		S:HandleSirusCollapseToggle(skillTypeLabelText)
	end

	SkillDetailStatusBar:SetParent(SkillDetailScrollFrame)
	S:HandleSirusStatusBar(SkillDetailStatusBar)
	SkillDetailStatusBar:SetParent(SkillDetailScrollFrame)

	SkillListScrollFrame:StripTextures()
	S:HandleSirusScrollBar(SkillListScrollFrameScrollBar)

	SkillDetailScrollFrame:StripTextures()
	S:HandleSirusScrollBar(SkillDetailScrollFrameScrollBar)

	TokenFrame:StripTextures(true)

	hooksecurefunc("TokenFrame_Update", function()
		local scrollFrame = TokenFrameContainer
		local offset = HybridScrollFrame_GetOffset(scrollFrame)
		local buttons = scrollFrame.buttons
		local numButtons = #buttons
		local _, name, isHeader, isExpanded, extraCurrencyType, icon
		local button, index

		for i = 1, numButtons do
			index = offset+i
			name, isHeader, isExpanded, _, _, _, extraCurrencyType, icon = GetCurrencyListInfo(index)
			button = buttons[i]

			if not button.isSkinned then
				if button.HighlightLeft then button.HighlightLeft:Kill() end
				if button.HighlightRight then button.HighlightRight:Kill() end
				if button.HighlightMiddle then button.HighlightMiddle:Kill() end

				if button.HeaderButton then
					if button.HeaderButton.HighlightLeft then button.HeaderButton.HighlightLeft:Kill() end
					if button.HeaderButton.HighlightRight then button.HeaderButton.HighlightRight:Kill() end
					if button.HeaderButton.HighlightMiddle then button.HeaderButton.HighlightMiddle:Kill() end

					local arrow = button.HeaderButton:CreateTexture(nil, "ARTWORK")
					arrow:Size(15)
					arrow:SetPoint("LEFT", 5, 0)
					button.HeaderButton.collapseArrow = arrow

					if button.HeaderButton.Name then
						button.HeaderButton.Name:SetPoint("LEFT", 24, 0)
					end
				end

				button.isSkinned = true
			end

			if isHeader and button.HeaderButton then
				if button.HeaderButton.Left then button.HeaderButton.Left:SetTexture() end
				if button.HeaderButton.Right then button.HeaderButton.Right:SetTexture() end
				if button.HeaderButton.Middle then button.HeaderButton.Middle:SetTexture() end

				local arrow = button.HeaderButton.collapseArrow
				if arrow then
					S:SetSirusCollapseIcon(button.HeaderButton, not isExpanded)
				end
			end

			if name or name == "" then
				if not isHeader then
					if extraCurrencyType == 1 then
						button.icon:SetTexCoord(unpack(E.TexCoords))
					elseif extraCurrencyType == 2 then
						local factionGroup = UnitFactionGroup("player")
						if factionGroup then
							button.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)
							button.icon:SetTexCoord(0.03125, 0.59375, 0.03125, 0.59375)
						else
							button.icon:SetTexCoord(unpack(E.TexCoords))
						end
					else
						button.icon:SetTexture(icon)
						button.icon:SetTexCoord(unpack(E.TexCoords))
					end
				end
			end
		end
	end)

	TokenFrameContainer.update = TokenFrame_Update

	S:HandleSirusScrollBar(TokenFrameContainerScrollBar)

	TokenFramePopup:StripTextures()
	TokenFramePopup:SetTemplate("Transparent")

	if TokenFramePopupCloseButton then
		S:HandleCloseButton(TokenFramePopupCloseButton)
	end	S:HandleCheckBox(TokenFramePopupInactiveCheckBox)
	S:HandleCheckBox(TokenFramePopupBackpackCheckBox)

	local flyoutFrame = _G.EquipmentFlyoutFrame
	if flyoutFrame then
		local flyoutHighlight = _G.EquipmentFlyoutFrameHighlight
		if flyoutHighlight then flyoutHighlight:StripTextures() end

		local function SkinFlyout()
			local buttons = _G.EquipmentFlyoutFrameButtons
			if buttons then
				for i = 1, buttons.numBGs or 1 do
					local bg = buttons["bg"..i]
					if bg then bg:SetAlpha(0) end
				end
				buttons:DisableDrawLayer("ARTWORK")
				if not buttons.isSkinned then
					buttons:SetTemplate("Transparent")
					buttons.isSkinned = true
				end
			end

			local navFrame = flyoutFrame.NavigationFrame
			if navFrame then
				if not navFrame.isSkinned then
					navFrame:StripTextures()
					navFrame:SetTemplate("Transparent")
					navFrame.isSkinned = true
				end
				if navFrame.PrevButton then
					S:HandleNextPrevButton(navFrame.PrevButton, "left")
				end
				if navFrame.NextButton then
					S:HandleNextPrevButton(navFrame.NextButton, "right")
				end
			end

			if flyoutFrame.buttons then
				for _, button in next, flyoutFrame.buttons do
					if button and not button.isSkinned then
						if button.NormalTexture then button.NormalTexture:SetAlpha(0) end
						if button.HighlightTexture then button.HighlightTexture:SetAlpha(0) end
						button:SetTemplate("Default", true)
						if button.icon then
							button.icon:SetTexCoord(unpack(E.TexCoords))
							button.icon:SetInside()
						end
						button.isSkinned = true
					end
				end
			end
		end

		SkinFlyout()
		hooksecurefunc("EquipmentFlyout_UpdateItems", SkinFlyout)
	end
end

S:AddCallback("Skin_Character", LoadSkin)
