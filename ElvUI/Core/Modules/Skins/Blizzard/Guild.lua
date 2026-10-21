local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local function SkinApplicants()
	local scroll = _G.GuildInfoFrameApplicantsContainer
	for _, button in ipairs(scroll.buttons) do
		if not button.elvGuildApplicantSkinned then
			button.elvGuildApplicantSkinned = true
			button:SetTemplate("Default")
			local highlight = button:GetHighlightTexture()
			highlight:SetTexture(E.media.normTex)
			highlight:SetTexCoord(0, 1, 0, 1)
			highlight:SetVertexColor(1, 1, 1, .08)
			highlight:SetInside()
			button.selectedTex:SetTexture(E.media.normTex)
			button.selectedTex:SetTexCoord(0, 1, 0, 1)
			button.selectedTex:SetVertexColor(unpack(E.media.rgbvaluecolor))
			button.selectedTex:SetAlpha(.15)
			button.selectedTex:SetInside()
			button.classFrame.ring:Hide()
			button.classFrame:ClearAllPoints()
			button.classFrame:SetPoint("TOPLEFT", 10, -10)
			button.classFrame:SetSize(44, 44)
			local icon = button.classFrame.class
			icon:SetTexture([[Interface\TargetingFrame\UI-Classes-Circles]])
			icon:SetDrawLayer("ARTWORK")
			icon:SetAlpha(1)
			icon:SetInside()
			icon:Show()
			button.classFrame:EnableDrawLayer("ARTWORK")
			button.levelFrame.PointsSpentBgGold:Hide()
			button.levelFrame:SetTemplate("Default")
			button.levelFrame:ClearAllPoints()
			button.levelFrame:SetPoint("BOTTOMRIGHT", button.classFrame, "BOTTOMRIGHT", 4, -4)
			button.levelFrame:SetSize(24, 16)
			button.levelFrame.level:FontTemplate(nil, 11)
			button.name:FontTemplate(nil, 12)
			button.name:SetHeight(16)
			button.name:SetWordWrap(false)
			button.comment:FontTemplate(nil, 11)
			button.fullComment:FontTemplate(nil, 11)
			button.comment:ClearAllPoints()
			button.comment:SetPoint("TOPLEFT", button, "TOPLEFT", 74, -29)
			button.comment:SetPoint("BOTTOMRIGHT", button.timeLeft, "TOPRIGHT", 0, 4)
			button.timeLeft:FontTemplate(nil, 10)
			button.timeLeft:SetWidth(112)
			button.timeLeft:SetWordWrap(false)
			button.InviteSent:FontTemplate(nil, 10)
			button.InviteSent:ClearAllPoints()
			button.InviteSent:SetPoint("BOTTOMLEFT", 74, 8)
			button.InviteSent:SetWidth(100)
			button.InviteSent:SetWordWrap(false)
			button.tankTex:ClearAllPoints()
			button.tankTex:SetPoint("BOTTOMLEFT", 10, 7)
		end
		button.name:SetPoint("RIGHT", button, "RIGHT", -8, 0)
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.guild then return end

	S:HandlePortraitFrame(GuildFrame)

	GuildXPBar:StripTextures()
	GuildXPBar.progress:SetTexture(E.media.normTex)
	E:RegisterStatusBar(GuildXPBar.progress)
	GuildXPBar.cap:SetTexture(E.media.normTex)
	E:RegisterStatusBar(GuildXPBar.cap)
	GuildXPBarArt:StripTextures()
	GuildXPBar:CreateBackdrop()
	GuildXPBar.backdrop:SetOutside(GuildXPBarBG)

	for i = 1, 5 do
		local tab = _G["GuildFrameRightTab"..i]
		if i == 1 then
			tab:Point("TOPLEFT", GuildFrame, "TOPRIGHT", -E.Border, -36)
		end
		tab:GetRegions():Hide()
		tab:StyleButton()
		tab:SetTemplate("Default", true)

		tab.Icon:SetInside()
		tab.Icon:SetTexCoords()
	end

	for i = 1, 3 do
		local tab = _G["GuildInfoFrameTab"..i]
		S:HandleSirusTab(tab, i > 1 and _G["GuildInfoFrameTab"..(i - 1)])
	end

	S:HandleButton(GuildRecruitmentInviteButton, true)
	S:HandleButton(GuildRecruitmentMessageButton, true)
	S:HandleButton(GuildRecruitmentDeclineButton, true)
	S:HandleSirusScrollBar(_G.GuildInfoFrameApplicantsContainerScrollBar)
	hooksecurefunc("GuildInfoFrameApplicants_Update", SkinApplicants)
	hooksecurefunc(_G.GuildInfoFrameApplicantsContainer, "update", SkinApplicants)
	SkinApplicants()

	GuildAllPerksFrame:StripTextures()
	S:HandleSirusScrollBar(GuildPerksContainerScrollBar)

	for i = 1, #GuildPerksContainer.buttons do
		local button = GuildPerksContainer.buttons[i]
		local lockTexture = button.lock and button.lock:GetTexture()

		S:HandleSirusIconButton(button, button.icon)
		button:StripTextures()

		if lockTexture then button.lock:SetTexture(lockTexture) end
	end

	GuildRewardsFrame:StripTextures()
	S:HandleSirusScrollBar(GuildRewardsContainerScrollBar)

	for i = 1, #GuildRewardsContainer.buttons do
		local button = GuildRewardsContainer.buttons[i]

		S:HandleSirusIconButton(button, button.icon)
		button:StripTextures()
		button:StyleButton()
	end

	S:HandleDropDownBox(GuildRosterViewDropdown)

	for i = 1, 5 do
		_G["GuildRosterColumnButton"..i]:StripTextures()
		_G["GuildRosterColumnButton"..i]:StyleButton()
	end

	S:HandleSirusScrollBar(GuildRosterContainerScrollBar)

	S:HandleCheckBox(GuildRosterShowOfflineButton)

	GuildMemberDetailFrame:StripTextures()
	GuildMemberDetailFrame:SetTemplate("Transparent")

	S:HandleCloseButton(GuildMemberDetailCloseButton)

	S:HandleButton(GuildMemberRemoveButton)
	S:HandleButton(GuildMemberGroupInviteButton)

	GuildMemberRankDropdown:Point("LEFT", GuildMemberDetailRankLabel, "RIGHT", -18, -3)
	S:HandleDropDownBox(GuildMemberRankDropdown)

	GuildMemberNoteBackground:SetTemplate("Transparent")
	GuildMemberOfficerNoteBackground:SetTemplate("Transparent")

	GuildInfoFrame:StripTextures()
	if LookingForGuildFrameGuildCardsListScrollFrameScrollBar then
		S:HandleSirusScrollBar(LookingForGuildFrameGuildCardsListScrollFrameScrollBar)
	end
	S:HandleSirusScrollBar(GuildInfoFrameInfoMOTDScrollFrameScrollBar)

	GuildInfoFrameInfo:StripTextures()
	GuildInfoFrameInfo:SetTemplate("Transparent")

	S:HandleButton(GuildInfoEditMOTDButton)
	S:HandleButton(GuildInfoEditDetailsButton)
	S:HandleSirusScrollBar(GuildInfoDetailsFrameScrollBar)
	S:HandleButton(GuildAddMemberButton, true)
	S:HandleButton(GuildControlButton, true)
	S:HandleButton(GuildViewLogButton, true)
	S:HandleButton(GuildRenameButton, true)

	GuildTextEditFrame:StripTextures()
	GuildTextEditFrame:SetTemplate("Transparent")
	if GuildTextEditFrameCloseButton then
		S:HandleCloseButton(GuildTextEditFrameCloseButton)
	end
	GuildTextEditContainer:StripTextures()
	GuildTextEditContainer:SetBackdrop(nil)

	S:HandleSirusScrollBar(GuildTextEditScrollFrameScrollBar)

	S:HandleButton(GuildTextEditFrameAcceptButton)
	if GuildTextEditFrameCloseButton then
		S:HandleButton(GuildTextEditFrameCloseButton)
	end

	GuildLogFrame:StripTextures()
	GuildLogFrame:SetTemplate("Transparent")

	local CloseButton, _, CloseButton2 = GuildLogFrame:GetChildren()
	S:HandleCloseButton(CloseButton)
	GuildLogContainer:SetBackdrop(nil)

	S:HandleSirusScrollBar(GuildLogScrollFrameScrollBar)

	S:HandleButton(CloseButton2)

	GuildControlPopupFrame:StripTextures()
	GuildControlPopupFrame:SetTemplate("Transparent")
	GuildControlPopupFrameCheckboxes:StripTextures()

	S:HandleDropDownBox(GuildControlPopupFrameDropDown, 200)
	GuildControlPopupFrameDropDown:Height(30)

	S:HandleEditBox(GuildControlPopupFrameEditBox)
	GuildControlPopupFrameEditBox:Width(100)
	GuildControlPopupFrameEditBox:Height(25)

	S:HandleButton(GuildControlPopupAcceptButton)
	S:HandleButton(GuildControlPopupFrameCancelButton)

	GuildControlPopupFrameAddRankButton:ClearAllPoints()
	GuildControlPopupFrameAddRankButton:Point("RIGHT", GuildControlPopupFrameDropDown,"RIGHT", 10, 5)
	GuildControlPopupFrameAddRankButton:GetNormalTexture():SetTexture(E.Media.Textures.Plus)

	GuildControlPopupFrameRemoveRankButton:ClearAllPoints()
	GuildControlPopupFrameRemoveRankButton:Point("RIGHT", GuildControlPopupFrameAddRankButton,"RIGHT", 20, 0)
	GuildControlPopupFrameRemoveRankButton:GetNormalTexture():SetTexture(E.Media.Textures.Minus)

	local function guildcontrol_OnShow(self)
		for i = 1,13 do
			S:HandleCheckBox(_G["GuildControlPopupFrameCheckbox"..i])
		end
	end
	local function for17_OnShow(self)
		for i = 15,17 do
			S:HandleCheckBox(_G["GuildControlPopupFrameCheckbox"..i])
		end
	end

	local gcontl = GuildControlPopupFrameCheckboxes
		gcontl:HookScript("OnShow", guildcontrol_OnShow)
	local gcontl2 = GuildControlPopupFrameCheckbox17
		gcontl2:HookScript("OnShow", for17_OnShow)

	local function ebWithdrawGold(self)
		S:HandleEditBox(GuildControlWithdrawGoldEditBox)
		GuildControlWithdrawGoldEditBox:Width(70)
		GuildControlWithdrawGoldEditBox:Height(20)
	end

	GuildControlWithdrawGold:HookScript("OnShow", ebWithdrawGold)

	local function tabandhand(self)
		for i = 1,6 do
			_G["GuildBankTabPermissionsTab"..i]:StripTextures()
			S:HandleTab(_G["GuildBankTabPermissionsTab"..i])
			_G["GuildBankTabPermissionsTab"..i]:Width(35)
			_G["GuildBankTabPermissionsTab"..i]:Height(25)
		end
		local xoff = -95
		for i = 1,6 do
			_G["GuildBankTabPermissionsTab"..i]:ClearAllPoints()
			_G["GuildBankTabPermissionsTab"..i]:Point("TOPRIGHT", xoff, 17)
			xoff = xoff + 21
		end
		S:HandleCheckBox(GuildControlTabPermissionsViewTab)
		S:HandleCheckBox(GuildControlTabPermissionsDepositItems)
		S:HandleCheckBox(GuildControlTabPermissionsUpdateText)
		GuildControlWithdrawItemsEditBox:StripTextures()
		S:HandleEditBox(GuildControlWithdrawItemsEditBox)
		GuildControlWithdrawItemsEditBox:Width(70)
		GuildControlWithdrawItemsEditBox:Height(20)
	end

	GuildControlPopupFrameTabPermissions:HookScript("OnShow", tabandhand)
	GuildControlPopupFrameTabPermissions:StripTextures()

	local function handlelvl(self)
		GuildLevelFrame:StripTextures()

		GuildLevelFrame:ClearAllPoints()
		GuildLevelFrame:Point("TOP", GuildFrame, "TOPLEFT", 26, -46)
		GuildLevelFrame:Size(35, 20)
		GuildLevelFrameText:SetFont(E.media.normFont, 12, "OUTLINE")

	end
	GuildFrame:HookScript("OnShow", handlelvl)

	GuildRecruitmentInterestFrame:StripTextures()
	GuildRecruitmentInterestFrame:SetTemplate("Transparent")
	GuildRecruitmentAvailabilityFrame:StripTextures()
	GuildRecruitmentAvailabilityFrame:SetTemplate("Transparent")
	GuildRecruitmentRolesFrame:StripTextures()
	GuildRecruitmentRolesFrame:SetTemplate("Transparent")
	GuildRecruitmentLevelFrame:StripTextures()
	GuildRecruitmentLevelFrame:SetTemplate("Transparent")
	GuildRecruitmentCommentFrame:StripTextures()
	GuildRecruitmentCommentFrame:SetTemplate("Transparent")

	GuildRecruitmentListGuildButton:StripTextures()
	S:HandleButton(GuildRecruitmentListGuildButton)

	if GuildRecruitmentQuestButton then S:HandleCheckBox(GuildRecruitmentQuestButton) end
	if GuildRecruitmentPvPButton then S:HandleCheckBox(GuildRecruitmentPvPButton) end
	if GuildRecruitmentDungeonButton then S:HandleCheckBox(GuildRecruitmentDungeonButton) end
	if GuildRecruitmentRPButton then S:HandleCheckBox(GuildRecruitmentRPButton) end
	if GuildRecruitmentRaidButton then S:HandleCheckBox(GuildRecruitmentRaidButton) end

	S:HandleCheckBox(GuildRecruitmentLevelAnyButton)
	S:HandleCheckBox(GuildRecruitmentLevelMaxButton)

	GuildRecruitmentCommentInputFrameScrollFrameFocusButton:StripTextures()
	GuildRecruitmentCommentInputFrameScrollFrame:StripTextures()
	GuildRecruitmentCommentInputFrame:StripTextures()

	local recruitment = GuildInfoFrameRecruitment
	local function SkinRecruitmentDropdown(dropdown, parent, x)
		if not dropdown then return end
		S:HandleDropDownBox(dropdown, 144)
		dropdown:ClearAllPoints()
		dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -25)
		dropdown:SetHeight(20)
		dropdown.backdrop:ClearAllPoints()
		dropdown.backdrop:SetPoint("TOPLEFT", 0, 0)
		dropdown.backdrop:SetPoint("TOPRIGHT", -4, 0)
		dropdown.backdrop:SetHeight(20)
		local button = dropdown.Button
		E:UnlockPoints(button)
		button:ClearAllPoints()
		button:SetPoint("RIGHT", dropdown.backdrop, "RIGHT", -2, 0)
		button:SetSize(16, 16)
		E:LockPoints(button)
		dropdown.Text:ClearAllPoints()
		dropdown.Text:SetPoint("LEFT", dropdown.backdrop, "LEFT", 8, 0)
		dropdown.Text:SetPoint("RIGHT", button, "LEFT", -2, 0)
		if dropdown.Label then
			dropdown.Label:ClearAllPoints()
			dropdown.Label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 5)
			dropdown.Label:SetWidth(144)
			dropdown.Label:FontTemplate(nil, 11)
		end
	end

	SkinRecruitmentDropdown(GuildRecruitmentInterestFrame.InterestDropdown, GuildRecruitmentInterestFrame, 8)
	SkinRecruitmentDropdown(GuildRecruitmentInterestFrame.ClassesDropdown, GuildRecruitmentInterestFrame, 164)
	SkinRecruitmentDropdown(GuildRecruitmentAvailabilityFrame.AvailabilityDropdown, GuildRecruitmentAvailabilityFrame, 8)
	SkinRecruitmentDropdown(GuildRecruitmentAvailabilityFrame.ActivityDropdown, GuildRecruitmentAvailabilityFrame, 164)

	for _, role in ipairs({"Tank", "Healer", "Damager"}) do
		local button = _G["GuildRecruitment"..role.."Button"]
		if button and button.checkButton then S:HandleCheckBox(button.checkButton) end
	end

	if GuildRecruitmentItemLevelFrame then
		GuildRecruitmentItemLevelFrame:StripTextures()
		GuildRecruitmentItemLevelFrame:SetTemplate("Transparent")
		GuildRecruitmentItemLevelFrame:SetHeight(32)
		local label = _G.GuildRecruitmentItemLevelFrameText
		label:ClearAllPoints()
		label:SetPoint("LEFT", 8, 0)
		label:SetWidth(224)
		label:SetWordWrap(false)
		label:FontTemplate(nil, 11)
		S:HandleEditBox(GuildRecruitmentItemLevelEditBox)
		GuildRecruitmentItemLevelEditBox:ClearAllPoints()
		GuildRecruitmentItemLevelEditBox:SetPoint("RIGHT", GuildRecruitmentItemLevelFrame, "RIGHT", -12, 0)
		GuildRecruitmentItemLevelEditBox:SetSize(60, 20)
	end

	GuildRecruitmentCommentInputFrame:ClearAllPoints()
	GuildRecruitmentCommentInputFrame:SetPoint("TOPLEFT", GuildRecruitmentCommentFrame, "TOPLEFT", 8, -6)
	GuildRecruitmentCommentInputFrame:SetPoint("BOTTOMRIGHT", GuildRecruitmentCommentFrame, "BOTTOMRIGHT", -8, 6)
	GuildRecruitmentCommentEditBox:FontTemplate(nil, 11)
	S:ApplyElvUIFont(recruitment)

	GuildFactionFrame:ClearAllPoints()
	GuildFactionFrame:SetPoint("LEFT", GuildFrame.TabardOverlay, "RIGHT", -8, -2)
	GuildFactionFrame:Size(48, 48)
	GuildFactionFrame.Icon:SetAllPoints()

	for i = 1,15 do
		local btn = _G["GuildRosterContainerButton"..i]
		if btn then
			btn.CategoryIcon:SetTexCoords()

		end

	end

	GuildFrame:EnableMouse(true)
	GuildFrame:SetMovable(true)
	GuildFrame:RegisterForDrag("LeftButton")
	GuildFrame:SetScript("OnDragStart", function(self)
		self:StartMoving()
		end)
	GuildFrame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local frame_x,frame_y = self:GetCenter()
		frame_x = frame_x - GetScreenWidth() / 2
		frame_y = frame_y - GetScreenHeight() / 2
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent,"CENTER",frame_x,frame_y)
	end)

end

S:AddCallback("Skin_Guild", LoadSkin)
