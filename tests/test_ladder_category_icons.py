import unittest
from test_sirus_regressions import env, chunk


class LadderCategoryIcons(unittest.TestCase):
    def test_shared_categories_do_not_create_icon_background(self):
        for index,label in enumerate(['SoloQ','Арена 2х2','Арена 1х1','Поля боя','Ренегаты','Манекен 83 уровня'],1):
            for use_atlas in (False,True):
                with self.subTest(category=label,atlas=use_atlas):
                    l=env();l.execute('''S={};function S:HandleButton(b) b.isSkinned=true;b.categoryBackground=true end
                    function SetPortraitToTexture(icon) icon.texture=nil end
                    b=newFrame();b.Ring=newFrame();b.Background=newFrame();b.Icon=newFrame(b);b.Name=newFrame()
                    b.Icon.texture='native-emblem';b.Icon.allocations=0
                    function b.Icon:CreateBackdrop() self.allocations=self.allocations+1;self.backdrop=newFrame() end
                    function b.Icon:GetTexture() return self.texture end
                    function b.Icon:SetTexture(v) self.texture=v end
                    function b.Icon:SetAtlas(v) self.atlas=v end
                    function b.Icon:SetTexCoord(...) self.coords={...} end
                    function b:GetAttribute() return nil end
                    ''')
                    if use_atlas:l.execute("b.Icon._atlasName='native-atlas'")
                    l.execute(chunk('ElvUI/Core/Modules/Skins/Blizzard/LFD.lua','local c = .035','local function SkinLadderSubPanel')+' skinCategory=SkinCategoryButton')
                    l.globals().categoryIndex=index;l.execute('skinCategory(b,categoryIndex);skinCategory(b,categoryIndex)')
                    self.assertEqual(l.eval('b.Icon.allocations'),0)
                    self.assertTrue(l.eval('b.Icon.parent==b and b.categoryBackground'))
                    self.assertEqual(l.eval('b.Icon.width'),45)
                    self.assertEqual(l.eval('b.Icon.atlas' if use_atlas else 'b.Icon.texture'),'native-atlas' if use_atlas else 'native-emblem')
                    self.assertTrue(l.eval('b.Name.fontSet'))


if __name__=='__main__':
    unittest.main()
