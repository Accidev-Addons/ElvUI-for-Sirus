-- Relevant client functions copied unchanged from sirus-patch-ruRU-i
-- Interface/FrameXML/FriendsFrame.lua at 1c4353a3c3144f985b90494f357b198458a9995c.
FRIEND_TAB_COUNT = 4;
FRIEND_TAB_FRIENDS = 1;
FRIEND_TAB_WHO = 2;
FRIEND_TAB_CHANNEL = 3;
FRIEND_TAB_RAID = 4;
function FriendsFrame_ShowSubFrame(frameName)
	for index, value in pairs(FRIENDSFRAME_SUBFRAMES) do
		if _G[value] then
			if ( value == frameName ) then
				_G[value]:Show()
			else
				_G[value]:Hide();
			end
		end
	end
end


function FriendsFrame_Update()
	local selectedTab = PanelTemplates_GetSelectedTab(FriendsFrame) or FRIEND_TAB_FRIENDS;
	FriendsTabHeader:SetShown(selectedTab == FRIEND_TAB_FRIENDS);

	if selectedTab == FRIEND_TAB_FRIENDS then
		local selectedHeaderTab = FriendsTabHeader:GetTab() or 1;

		FriendsFrameInset:SetPoint("TOPLEFT", 4, -83);
		ButtonFrameTemplate_ShowButtonBar(FriendsFrame)
		FriendsFrameIcon:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon");

		if selectedHeaderTab == FriendsTabHeader.friendsTabID then
			ShowFriends();
			FriendsFrameTitleText:SetText(FRIENDS_LIST);
			FriendsFrame_ShowSubFrame("FriendsListFrame");
		elseif selectedHeaderTab == FriendsTabHeader.ignoreTabID then
			if ( IsVoiceChatEnabled() ) then
				FriendsFrameMutePlayerButton:Show();
				FriendsFrameIgnorePlayerButton:SetWidth(110);
				FriendsFrameUnsquelchButton:SetWidth(111);
			else
				FriendsFrameMutePlayerButton:Hide();
				FriendsFrameIgnorePlayerButton:SetWidth(131);
				FriendsFrameUnsquelchButton:SetWidth(134);
			end
			FriendsFrameTitleText:SetText(IGNORE_LIST);
			FriendsFrame_ShowSubFrame("IgnoreListFrame");
			IgnoreList_Update();
		elseif selectedHeaderTab == FriendsTabHeader.pendingInveteTabID then
			FriendsFrameTitleText:SetText(PENDING_INVITE_LIST);
			FriendsFrame_ShowSubFrame("PendingListFrame");
		end
	else
		if ( FriendsFrame.selectedTab == 2 ) then
			FriendsFrameInset:SetPoint("TOPLEFT", 4, -83);
			ButtonFrameTemplate_ShowButtonBar(FriendsFrame)
			FriendsFrameIcon:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon");
			FriendsFrameTitleText:SetText(WHO_LIST);
			FriendsFrame_ShowSubFrame("WhoFrame");
			WhoList_Update();
		elseif ( FriendsFrame.selectedTab == 3 ) then
			FriendsFrameInset:SetPoint("TOPLEFT", 4, -60);
			ButtonFrameTemplate_ShowButtonBar(FriendsFrame)
			FriendsFrameIcon:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon");
			FriendsFrameTitleText:SetText(CHAT_CHANNELS);
			FriendsFrame_ShowSubFrame("ChannelFrame");
		elseif ( FriendsFrame.selectedTab == 4 ) then
			FriendsFrameInset:SetPoint("TOPLEFT", 4, -53);
			ButtonFrameTemplate_HideButtonBar(FriendsFrame)
			FriendsFrameIcon:SetTexture("Interface\\LFGFrame\\UI-LFR-PORTRAIT");
			FriendsFrameTitleText:SetText(RAID);
			FriendsFrame_ShowSubFrame("RaidFrame");
		end
	end
end


function ToggleFriendsFrame(tab)
	if ( not tab ) then
		if ( FriendsFrame:IsShown() ) then
			HideUIPanel(FriendsFrame);
		else
			ShowUIPanel(FriendsFrame);
		end
	else
		if ( tab == PanelTemplates_GetSelectedTab(FriendsFrame) and FriendsFrame:IsShown() ) then
			HideUIPanel(FriendsFrame);
			return;
		end
		PanelTemplates_SetTab(FriendsFrame, tab);
		if ( FriendsFrame:IsShown() ) then
			FriendsFrame_OnShow();
		else
			ShowUIPanel(FriendsFrame);
		end
	end
end

