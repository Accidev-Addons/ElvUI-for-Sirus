import unittest
from test_sirus_regressions import env, chunk


def setup():
    l=env()
    l.execute('''panel=newFrame();panel.backdrop=newFrame(panel);header=newFrame(panel);header:SetHeight(36);created=0
    function panel:CreateTexture(name,layer,template,sublevel)
      created=created+1;local t=newFrame(self);t.layer=layer;t.sublevel=sublevel
      function t:SetTexture(...) self.rgba={...} end
      return t
    end''')
    l.execute(chunk('ElvUI/Core/Modules/Skins/Blizzard/Talent.lua','local function SkinTalentHeader','local function LayoutTreeArt')+' applyHeader=SkinTalentHeader')
    return l


class TalentHeader(unittest.TestCase):
    def test_background_spans_full_header_under_text(self):
        l=setup();l.execute('applyHeader(panel,header);shade=panel.headerShade')
        self.assertEqual(l.eval('shade.layer'),'ARTWORK')
        self.assertEqual(l.eval('shade.sublevel'),1)
        self.assertEqual(l.eval('shade.rgba[4]'),0.65)
        self.assertEqual(l.eval('shade.height'),36)
        self.assertTrue(l.eval("#shade.points==2 and shade.points[1][1]=='TOPLEFT' and shade.points[2][1]=='TOPRIGHT'"))
        self.assertTrue(l.eval('shade.points[1][2]==panel.backdrop and shade.points[2][2]==panel.backdrop'))
        self.assertEqual(l.eval('shade.points[1][4]'),1)
        self.assertEqual(l.eval('shade.points[2][4]'),-1)

    def test_repeated_layout_reuses_texture_and_follows_header_height(self):
        l=setup();l.execute('applyHeader(panel,header);header:SetHeight(46);applyHeader(panel,header)')
        self.assertEqual(l.eval('created'),1)
        self.assertEqual(l.eval('panel.headerShade.height'),46)
        self.assertEqual(l.eval('#panel.headerShade.points'),2)


if __name__=='__main__':
    unittest.main()
