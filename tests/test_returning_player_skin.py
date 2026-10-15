from pathlib import Path
import unittest
from test_sirus_regressions import env

ROOT = Path(__file__).resolve().parents[1]
SKIN = ROOT/'ElvUI/Core/Modules/Skins/Blizzard/ReturningPlayerInvite.lua'


def setup(global_enabled=True, friends_enabled=True, with_frames=True):
    l=env()
    l.execute('''
    E.private={skins={blizzard={enable=true,friends=true}}};E.Media={Textures={Highlight='ElvUI-highlight'}}
    S={}
    function E:GetModule() return S end
    function S:AddCallback(name,fn) callbackName=name;loadSkin=fn end
    function S:HandleCloseButton(f) f.closeSkinned=true end
    function S:HandleButton(f) f.buttonSkinned=true end
    function S:HandleSirusScrollBar(f) f.scrollSkinned=true end
    function S:HandleEditBox(f) f.editSkinned=true end
    function S:ApplyElvUIFont(f) f.fontApplications=(f.fontApplications or 0)+1;if f.Name then f.Name:FontTemplate() end end
    function skinFrame()
      local f=newFrame()
      function f:StripTextures() self.stripped=true;if self.Icon then self.Icon:SetTexture(nil);self.Icon:SetAlpha(0) end end
      function f:SetTemplate(template) self.template=template;self.templateCalls=(self.templateCalls or 0)+1 end
      function f:StyleButton() self.styled=true end
      function f:EnableDrawLayer(layer) self.enabledLayer=layer end
      function f:HookScript(name,fn) self.hooked=self.hooked or {};self.hooked[name]=fn end
      return f
    end
    function candidate()
      local b=skinFrame();b.Name=newFrame();b.highlight=newFrame();b.highlight.color='selection'
      function b.highlight:SetTexture(v) self.texture=v end
      function b:GetHighlightTexture() return self.highlight end
      b.scripts.OnClick=function() clicked=true end
      b.lockedHighlight=true
      return b
    end
    ''')
    l.execute('E.private.skins.blizzard.enable='+str(global_enabled).lower()+';E.private.skins.blizzard.friends='+str(friends_enabled).lower())
    if with_frames:
        l.execute('''
        ReturningPlayerInviteToggleButton=skinFrame();local t=ReturningPlayerInviteToggleButton;t.Icon=newFrame()
        t.Icon.texture='SOR-mail';function t.Icon:GetTexture() return self.texture end
        function t.Icon:SetTexture(v) self.texture=v end;function t.Icon:SetAlpha(v) self.alpha=v end;function t.Icon:SetDrawLayer(v) self.layer=v end
        t.scripts.OnClick=function() toggled=true end
        ReturningPlayerInviteFrame=skinFrame();f=ReturningPlayerInviteFrame
        ReturningPlayerInviteFrameCloseButton=skinFrame()
        f.List=skinFrame();f.List.ScrollFrame=skinFrame();f.List.ScrollFrame.scrollBar=skinFrame()
        f.Link=skinFrame();f.Link.URL=skinFrame();f.Link.URL.url='existing-url'
        f.Link.URL.scripts.OnTextChanged=function() urlChanged=true end
        f.RefreshButton=skinFrame();f.GetLinkButton=skinFrame();f.ErrorText=newFrame()
        function f:UpdateCandidateList() end;function f:Update() end
        ''')
    l.execute(SKIN.read_text())
    l.execute('loadSkin()')
    return l


class ReturningPlayerSkin(unittest.TestCase):
    def test_frame_and_toggle_components(self):
        l=setup()
        self.assertEqual(l.eval('callbackName'),'Skin_ReturningPlayerInvite')
        self.assertEqual(l.eval('f.template'),'Transparent')
        self.assertEqual(l.eval('f.List.template'),'Default')
        for expr in ['ReturningPlayerInviteFrameCloseButton.closeSkinned','f.RefreshButton.buttonSkinned','f.GetLinkButton.buttonSkinned','f.List.ScrollFrame.scrollBar.scrollSkinned','f.Link.URL.editSkinned','ReturningPlayerInviteToggleButton.styled']:
            self.assertTrue(l.eval(expr),expr)
        self.assertEqual(l.eval('f.Link.URL.height'),24)
        self.assertEqual(l.eval('ReturningPlayerInviteToggleButton.Icon.texture'),'SOR-mail')
        self.assertEqual(l.eval('ReturningPlayerInviteToggleButton.Icon.alpha'),1)

    def test_lazy_rows_and_selection_refresh(self):
        l=setup();l.execute('f.List.ScrollFrame.buttons={candidate()};f.hooked.OnShow();row=f.List.ScrollFrame.buttons[1]')
        self.assertEqual(l.eval('row.highlight.texture'),'ElvUI-highlight')
        self.assertTrue(l.eval('row.Name.fontSet and row.lockedHighlight'))
        self.assertEqual(l.eval('row.highlight.color'),'selection')
        l.execute('row.Name.fontSet=false;row.highlight.color="new-selection";hooks.UpdateCandidateList()')
        self.assertTrue(l.eval('row.Name.fontSet'))
        self.assertEqual(l.eval('row.highlight.color'),'new-selection')
        l.execute('f.List.ScrollFrame.buttons[2]=candidate();hooks.UpdateCandidateList();hooks.Update()')
        self.assertTrue(l.eval('f.List.ScrollFrame.buttons[2].Name.fontSet and f.ErrorText.fontSet'))

    def test_disabled_settings(self):
        for global_enabled,friends_enabled in [(False,True),(True,False)]:
            with self.subTest(global_enabled=global_enabled,friends_enabled=friends_enabled):
                l=setup(global_enabled,friends_enabled)
                self.assertIsNone(l.eval('f.template'))
                self.assertIsNone(l.eval('ReturningPlayerInviteToggleButton.template'))
                self.assertIsNone(l.eval('hooks.UpdateCandidateList'))

    def test_idempotence_and_original_behaviour(self):
        l=setup();l.execute('loadSkin();ReturningPlayerInviteToggleButton.scripts.OnClick();f.Link.URL.scripts.OnTextChanged()')
        self.assertEqual(l.eval('f.templateCalls'),1)
        self.assertEqual(l.eval('ReturningPlayerInviteToggleButton.templateCalls'),1)
        self.assertTrue(l.eval('toggled and urlChanged'))
        self.assertEqual(l.eval('f.Link.URL.url'),'existing-url')

    def test_optional_frames_absent(self):
        setup(with_frames=False)

    def test_xml_registration(self):
        from xml.etree import ElementTree
        path=ROOT/'ElvUI/Core/Modules/Skins/Blizzard/Load_Blizzard.xml'
        tree=ElementTree.parse(path)
        files=[el.attrib.get('file') for el in tree.getroot()]
        self.assertEqual(files.count('ReturningPlayerInvite.lua'),1)



class ReturningPlayerIcon(unittest.TestCase):
    def test_icon_is_above_backdrop(self):
        l=setup()
        self.assertEqual(l.eval('ReturningPlayerInviteToggleButton.Icon.layer'),'ARTWORK')
        self.assertTrue(l.eval('ReturningPlayerInviteToggleButton.Icon.shown'))
    def test_native_texture_restored_if_prior_skin_cleared_it(self):
        l=setup();l.execute('ReturningPlayerInviteToggleButton.elvReturningPlayerSkinned=nil;ReturningPlayerInviteToggleButton.Icon.texture=nil;loadSkin()')
        self.assertEqual(l.eval('ReturningPlayerInviteToggleButton.Icon.texture'),r'Interface\Icons\SOR-mail')

if __name__ == "__main__":
    unittest.main()
