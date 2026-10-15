from pathlib import Path
import unittest
from test_sirus_regressions import env, chunk

ROOT=Path(__file__).resolve().parents[1]


def setup():
    l=env()
    l.execute('''
    RU={};FriendsFrame=newFrame();FriendsFrame:Hide()
    FRIENDSFRAME_SUBFRAMES={'FriendsListFrame','IgnoreListFrame','PendingListFrame','WhoFrame','ChannelFrame','RaidFrame'}
    for _,name in ipairs(FRIENDSFRAME_SUBFRAMES) do _G[name]=newFrame();_G[name]:Hide() end
    FriendsTabHeader=newFrame();FriendsTabHeader.friendsTabID=1
    function FriendsTabHeader:GetTab() return 1 end
    FriendsFrameInset=newFrame();FriendsFrameIcon=newFrame();FriendsFrameTitleText=newFrame()
    function ButtonFrameTemplate_HideButtonBar() end
    function ButtonFrameTemplate_ShowButtonBar() end
    function ShowFriends() end;function WhoList_Update() end
    function PanelTemplates_GetSelectedTab(frame) return frame.selectedTab end
    function PanelTemplates_SetTab(frame,tab) frame.selectedTab=tab end
    function FriendsFrame_OnShow() FriendsFrame_Update() end
    function ShowUIPanel(frame) frame:Show();FriendsFrame_OnShow() end
    function HideUIPanel(frame) frame:Hide();for _,name in ipairs(FRIENDSFRAME_SUBFRAMES) do _G[name]:Hide() end end
    ''')
    l.execute((ROOT/'tests/fixtures/sirus_friends_frame.lua').read_text())
    l.execute('local ToggleFriendsFrame=ToggleFriendsFrame\n'+chunk('ElvUI/Core/Modules/Misc/RaidUtility.lua','function RU:OnClick_RaidControlButton()','function RU:OnEvent_MainTankButton()'))
    return l


class RaidControlNavigation(unittest.TestCase):
    def test_opens_raid_content_from_closed_window(self):
        l=setup();l.execute('RU:OnClick_RaidControlButton()')
        self.assertTrue(l.eval('FriendsFrame:IsShown() and RaidFrame:IsShown()'))
        self.assertEqual(l.eval('FriendsFrame.selectedTab'),4)
        self.assertFalse(l.eval('FriendsListFrame:IsShown() or WhoFrame:IsShown() or ChannelFrame:IsShown()'))

    def test_switches_from_each_other_tab(self):
        for tab in (1,2,3,5):
            with self.subTest(previous_tab=tab):
                l=setup();l.execute(f'FriendsFrame.selectedTab={tab};FriendsFrame:Show();RU:OnClick_RaidControlButton()')
                self.assertTrue(l.eval('FriendsFrame:IsShown() and RaidFrame:IsShown()'))
                self.assertEqual(l.eval('FriendsFrame.selectedTab'),4)

    def test_repeated_click_preserves_native_toggle(self):
        l=setup();l.execute('RU:OnClick_RaidControlButton();RU:OnClick_RaidControlButton()')
        self.assertFalse(l.eval('FriendsFrame:IsShown() or RaidFrame:IsShown()'))
        l.execute('RU:OnClick_RaidControlButton()')
        self.assertTrue(l.eval('FriendsFrame:IsShown() and RaidFrame:IsShown()'))

    def test_old_index_reproduces_missing_raid_content(self):
        l=setup();l.execute('ToggleFriendsFrame(5)')
        self.assertTrue(l.eval('FriendsFrame:IsShown()'))
        self.assertFalse(l.eval('RaidFrame:IsShown()'))


if __name__=='__main__':
    unittest.main()
