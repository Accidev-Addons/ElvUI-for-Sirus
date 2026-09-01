local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

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

	GuildFactionFrame:ClearAllPoints()
	GuildFactionFrame:SetPoint("LEFT", GuildFrame.TabardOverlay, "RIGHT", -8, -2)
	GuildFactionFrame:Size(48, 48)
	GuildFactionFrame.Icon:SetAllPoints()

	LookingForGuildFrame:StripTextures()
	LookingForGuildFrame:CreateBackdrop("Transparent")
	if LookingForGuildFrameCloseButton then
		S:HandleCloseButton(LookingForGuildFrameCloseButton)
	end
	if LookingForGuildFrameOptionsListSearch then
		S:HandleButton(LookingForGuildFrameOptionsListSearch)

		local filterDropdown = LookingForGuildFrameOptionsListFilterDropdown
		local sizeDropdown = LookingForGuildFrameOptionsListSizeDropdown
		S:HandleDropDownBox(filterDropdown, 105)
		S:HandleDropDownBox(sizeDropdown, 105)
		for _, dropdown in next, { filterDropdown, sizeDropdown } do
			if dropdown.backdrop then
				dropdown.backdrop:ClearAllPoints()
				dropdown.backdrop:SetPoint('TOPLEFT', dropdown, 'TOPLEFT', 2, -2)
				dropdown.backdrop:SetPoint('BOTTOMRIGHT', dropdown, 'BOTTOMRIGHT', 2, -2)
			end
		end
		S:HandleEditBox(LookingForGuildFrameOptionsListSearchBox)
		LookingForGuildFrameOptionsListSearch:ClearAllPoints()
		LookingForGuildFrameOptionsListSearch:SetPoint("BOTTOM", LookingForGuildFrameOptionsListSearchBox, "BOTTOM", -5, -25)
		LookingForGuildFrameOptionsListSearchBox:SetSize(145, 20)
	end

	if LookingForGuildFrameInsetFrame then
		LookingForGuildFrameInsetFrame:StripTextures()
	end

	local chchbx = {
		"Tank",
		"Healer",
		"Dps"
	}
	for _,checkbox in ipairs(chchbx) do
		local frame = _G["LookingForGuildFrameOptionsList"..checkbox.."RoleFrameCheckBox"]
		if frame then
			S:HandleCheckBox(frame)
		end
	end
	for i = 1,15 do
		local btn = _G["GuildRosterContainerButton"..i]
		if btn then
			btn.CategoryIcon:SetTexCoords()

		end

	end
	local tabs = {
		"LookingForGuildFrameSearchTab",
		"LookingForGuildFramePendingTab"
	}
	for k,tabToSkin in ipairs(tabs) do
		local tab = _G[tabToSkin]
		if k == 1 then
			tab:Point("TOPLEFT", LookingForGuildFrame, "TOPRIGHT", -E.Border, -36)
		end
		tab:GetRegions():Hide()
		tab:StyleButton()
		tab:SetTemplate("Default", true)
		tab.Icon:SetInside()
		tab.Icon:SetTexCoords()
	end

	if LookingForGuildFrameGuildCardsFirstCardRequestJoin then
		S:HandleButton(LookingForGuildFrameGuildCardsFirstCardRequestJoin)
		S:HandleButton(LookingForGuildFrameGuildCardsSecondCardRequestJoin)
		S:HandleButton(LookingForGuildFrameGuildCardsThirdCardRequestJoin)
	end

	if LookingForGuildFrameRequestToJoinFrame then
		LookingForGuildFrameRequestToJoinFrame:HookScript("OnShow", function()
			LookingForGuildFrameRequestToJoinFrame:StripTextures()
			LookingForGuildFrameRequestToJoinFrame:CreateBackdrop("Transparent")
			S:HandleButton(LookingForGuildFrameRequestToJoinFrameApply)
			S:HandleButton(LookingForGuildFrameRequestToJoinFrameCancel)
			LookingForGuildFrameRequestToJoinFrame.BG:Hide()
			LookingForGuildFrameRequestToJoinFrameMessageFrame:StripTextures()
			LookingForGuildFrameRequestToJoinFrameMessageFrameMessageScroll:StripTextures()
			LookingForGuildFrameRequestToJoinFrameMessageFrameMessageScroll:CreateBackdrop("Transparent")
			S:HandleSirusScrollBar(LookingForGuildFrameRequestToJoinFrameMessageFrameMessageScrollScrollBar)
		end)
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
