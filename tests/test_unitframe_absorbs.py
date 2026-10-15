from pathlib import Path
from lupa.lua51 import LuaRuntime
import unittest
ROOT=Path(__file__).resolve().parents[1]
# A strict renderer mock: unknown methods fail rather than silently succeeding.
UI=r'''
function ui(parent)
 local f={parent=parent,width=100,height=20,alpha=1,shown=true,points={},orientation='HORIZONTAL',scripts={},events={}}
 function f:SetFrameLevel(v) self.level=v end
 function f:SetAllPoints() end
 function f:SetAlpha(v) self.alpha=v end
 function f:SetParent(v) self.parent=v end
 function f:SetTexture(v) self.path=v end
 function f:SetBlendMode(v) self.blend=v end
 function f:Hide() self.shown=false end
 function f:Show() self.shown=true end
 function f:CreateTexture() return ui(self) end
 function f:GetStatusBarTexture() return self.texture end
 function f:SetStatusBarTexture(path) self.texture=self.texture or ui(self);self.texture.path=path end
 function f:SetWidth(v) self.width=v end;f.Width=f.SetWidth
 function f:SetHeight(v) self.height=v end;f.Height=f.SetHeight
 function f:Size(w,h) self.width=w;self.height=h end
 function f:GetWidth() return self.width end
 function f:GetHeight() return self.height end
 function f:GetSize() return self.width,self.height end
 function f:SetMinMaxValues(a,b) self.min=a;self.max=b end
 function f:SetValue(v) self.value=v end
 function f:SetOrientation(v) self.orientation=v end
 function f:GetOrientation() return self.orientation end
 function f:ClearAllPoints() self.points={} end
 function f:SetPoint(point,relative,relativePoint,x,y) self.points[point]={relative,relativePoint,x or 0,y or 0} end;f.Point=f.SetPoint
 function f:SetStatusBarColor(...) self.color={...} end
 function f:IsObjectType(kind) return kind=='StatusBar' end
 function f:RegisterEvent(event,fn) self.events[event]=fn end
 function f:UnregisterEvent(event) self.events[event]=nil end
 return f
end
function CreateFrame(_,_,parent) return ui(parent) end
health=100;maximum=100;shield=40;healAbsorb=0;personal=0;incoming=0
function UnitHealth() return health end
function UnitHealthMax() return maximum end
function UnitGetTotalAbsorbs() return shield end
function UnitGetTotalHealAbsorbs() return healAbsorb end
function UnitGetIncomingHeals(_,caster) return caster and personal or incoming end
UF={statusbars={},db={colors={healPrediction={maxOverflow=0}}}}
for _,name in ipairs({'personal','others','absorbs','healAbsorbs','overabsorbs','overhealabsorbs'}) do UF.db.colors.healPrediction[name]={r=1,g=1,b=0,a=.25} end
function UF:Update_StatusBar(bar,path) bar:SetStatusBarTexture(path) end
E={media={blankTex='blank'}};function E:GetModule() return UF end;ElvUI={E}
ns={oUF={AddElement=function(_,_,update,enable,disable) element={update=update,enable=enable,disable=disable} end}}
frame=ui();frame.unit='player';frame.db={healPrediction={enable=true,absorbStyle='NORMAL'},health={orientation='HORIZONTAL'}}
frame.Health=ui(frame);frame.Health:SetStatusBarTexture('health');frame.Health.ClipFrame=ui(frame.Health)
function frame:IsElementEnabled() return self.elementEnabled end
function frame:EnableElement() self.elementEnabled=element.enable(self) end
function frame:DisableElement() element.disable(self);self.elementEnabled=false end
'''
def setup():
 l=LuaRuntime(unpack_returned_tuples=True);l.execute(UI)
 l.execute((ROOT/'ElvUI/Core/Modules/UnitFrames/Elements/HealComm.lua').read_text())
 l.execute('local function loadPlugin(...)\n'+(ROOT/'ElvUI_Libraries/Core/oUF_Plugins/oUF_SirusHealPrediction/oUF_SirusHealPrediction.lua').read_text()+'\nend;loadPlugin("ElvUI",ns)')
 l.execute('frame.HealCommBar=UF:Construct_HealComm(frame)')
 return l
class UnitframeAbsorbs(unittest.TestCase):
 def test_full_health_shield_has_nonzero_visible_area(self):
  for orientation in ('HORIZONTAL','VERTICAL'):
   for style in ('NORMAL','STACKED','REVERSED'):
    with self.subTest(orientation=orientation,style=style):
     l=setup();l.execute(f"frame.db.health.orientation='{orientation}';frame.Health.orientation='{orientation}';frame.db.healPrediction.absorbStyle='{style}';UF:Configure_HealComm(frame);p=frame.HealCommBar;b=p.absorbBar")
     self.assertEqual(l.eval('b.alpha'),1);self.assertTrue(l.eval('b.shown'))
     if style=='REVERSED':self.assertAlmostEqual(l.eval('b.width' if orientation=='HORIZONTAL' else 'b.height'),40 if orientation=='HORIZONTAL' else 8)
     else:
      self.assertEqual(l.eval('b.value'),40)
      self.assertAlmostEqual(l.eval('b.points.LEFT[3]' if orientation=='HORIZONTAL' else 'b.points.BOTTOM[4]'),60 if orientation=='HORIZONTAL' else 12)
 def test_absorb_updates_and_clears_without_health_change(self):
  l=setup();l.execute('UF:Configure_HealComm(frame);shield=70;frame.events.UNIT_ABSORB_AMOUNT_CHANGED(frame,"UNIT_ABSORB_AMOUNT_CHANGED","player")')
  self.assertEqual(l.eval('frame.HealCommBar.absorbBar.value'),70)
  l.execute('shield=0;frame.events.UNIT_ABSORB_AMOUNT_CHANGED(frame,"UNIT_ABSORB_AMOUNT_CHANGED","player")')
  self.assertFalse(l.eval('frame.HealCommBar.absorbBar.shown'))
 def test_overflow_none_and_disable(self):
  l=setup();l.execute('shield=200;UF:Configure_HealComm(frame)')
  self.assertEqual(l.eval('frame.HealCommBar.absorbBar.value'),100)
  self.assertTrue(l.eval('frame.HealCommBar.overAbsorb.shown'))
  l.execute("frame.db.healPrediction.absorbStyle='NONE';UF:Configure_HealComm(frame)")
  self.assertFalse(l.eval('frame.HealCommBar.absorbBar.shown'))
  l.execute('frame.db.healPrediction.enable=false;UF:Configure_HealComm(frame)')
  self.assertFalse(l.eval('frame.elementEnabled'));self.assertIsNone(l.eval('frame.events.UNIT_ABSORB_AMOUNT_CHANGED'))
 def test_unknown_api_fails(self):
  l=setup()
  with self.assertRaises(Exception):l.execute('frame:NonexistentAPI()')
