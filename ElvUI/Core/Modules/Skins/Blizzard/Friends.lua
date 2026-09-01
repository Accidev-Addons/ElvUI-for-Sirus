local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.friends then return end

	S:HandleSirusFrame(FriendsFrame)
	if FriendsFrameIcon then FriendsFrameIcon:Hide() end

	local friendsTitle = _G.FriendsFrameTitleText
	if friendsTitle then
		friendsTitle:ClearAllPoints()
		friendsTitle:SetPoint("CENTER", FriendsFrame, "TOP", 0, -12)
		friendsTitle:SetJustifyH("CENTER")
	end

	S:HandleDropDownBox(FriendsFrameStatusDropDown, 70)

	if FriendsFrameStatusDropDown then
		FriendsFrameStatusDropDown:ClearAllPoints()
		FriendsFrameStatusDropDown:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", 240, -58)
	end

	if FriendsFrameBroadcastInput then
		S:HandleEditBox(FriendsFrameBroadcastInput)
	end

	S:HandleSirusTabSystem(FriendsTabHeader and FriendsTabHeader.TabSystem)

	S:HandleSirusTabs("FriendsFrameTab", 4)

	for i = 1, #FriendsFrameFriendsScrollFrame.buttons do
		local button = FriendsFrameFriendsScrollFrame.buttons[i]
		local summon = button and button.summonButton
		if summon then
			local summonIcon = _G[summon:GetName().."Icon"]
			if summonIcon then summonIcon:SetTexCoords() end

			local summonNormal = _G[summon:GetName().."NormalTexture"]
			if summonNormal then summonNormal:SetAlpha(0) end

			summon:StyleButton()
		end
	end

	S:HandleSirusScrollFrame(FriendsFrameFriendsScrollFrame)

	S:HandleSirusButton(FriendsFrameAddFriendButton, true)
	S:HandleSirusButton(FriendsFrameSendMessageButton, true)

	S:HandleSirusButton(FriendsFrameIgnorePlayerButton, true)
	S:HandleSirusButton(FriendsFrameUnsquelchButton, true)

	WhoFrame:StripTextures()
	S:HandleDropDownBox(WhoFrameDropDown, 120)
	WhoFrameDropDown.backdrop:Point("TOPLEFT", 8, -2)

	for i = 1, 5 do
		local header = _G["WhoFrameColumnHeader"..i]
		if header then
			header:StripTextures()
			header:StyleButton()
			S:ApplyElvUIFont(header)
		end
	end

	for i = 1, 17 do
		local button = _G["WhoFrameButton"..i]
		if button then
			button:StripTextures()
			S:HandleButtonHighlight(button)
		end
	end

	S:HandleSirusScrollFrame(WhoListScrollFrame)

	S:HandleEditBox(WhoFrameEditBox)

	S:HandleSirusButton(WhoFrameWhoButton)
	S:HandleSirusButton(WhoFrameAddFriendButton)
	S:HandleSirusButton(WhoFrameGroupInviteButton)

	ChannelFrameVerticalBar:Kill()

	S:HandleCheckBox(ChannelFrameAutoJoinParty)
	S:HandleCheckBox(ChannelFrameAutoJoinBattleground)

	S:HandleButton(ChannelFrameNewButton)

	ChannelListScrollFrame:StripTextures()
	S:HandleSirusScrollBar(ChannelListScrollFrameScrollBar)

	for i = 1, MAX_DISPLAY_CHANNEL_BUTTONS do
		_G["ChannelButton"..i]:StripTextures()
		_G["ChannelButton"..i.."Collapsed"]:SetTextColor(1, 1, 1)

		S:HandleButtonHighlight(_G["ChannelButton"..i])
	end

	for i = 1, 22 do
		S:HandleButtonHighlight(_G["ChannelMemberButton"..i])
	end

	ChannelRosterScrollFrame:StripTextures()
	S:HandleSirusScrollBar(ChannelRosterScrollFrameScrollBar)

	ChannelFrameDaughterFrame:StripTextures()
	ChannelFrameDaughterFrame:SetTemplate("Transparent")

	S:HandleEditBox(ChannelFrameDaughterFrameChannelName)
	S:HandleEditBox(ChannelFrameDaughterFrameChannelPassword)

	if ChannelFrameDaughterFrameDetailCloseButton then
		S:HandleCloseButton(ChannelFrameDaughterFrameDetailCloseButton)
	end

	S:HandleButton(ChannelFrameDaughterFrameCancelButton)
	S:HandleButton(ChannelFrameDaughterFrameOkayButton)

	S:ApplyElvUIFont(ChannelFrame)
	ChannelFrame:HookScript("OnShow", function(self)
		S:ApplyElvUIFont(self)
	end)
	if ChannelFrameDaughterFrame then
		S:ApplyElvUIFont(ChannelFrameDaughterFrame)
	end

	S:HandleButton(RaidFrameConvertToRaidButton)
	S:HandleButton(RaidFrameRaidInfoButton)

	RaidInfoFrame:StripTextures(true)
	RaidInfoFrame:SetTemplate("Transparent")

	if RaidInfoFrame.Border then RaidInfoFrame.Border:StripTextures() end
	if RaidInfoFrame.Header then RaidInfoFrame.Header:StripTextures() end

	RaidInfoFrame:ClearAllPoints()
	RaidInfoFrame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", 34, -28)

	RaidInfoInstanceLabel:StripTextures()
	RaidInfoIDLabel:StripTextures()

	S:HandleCloseButton(RaidInfoCloseButton)

	S:HandleSirusScrollBar(RaidInfoScrollFrameScrollBar)

	S:HandleButton(RaidInfoExtendButton)
	S:HandleButton(RaidInfoCancelButton)
end

S:AddCallback("Skin_Friends", LoadSkin)
