from pathlib import Path
import unittest
from test_sirus_regressions import env
ROOT=Path(__file__).resolve().parents[1]
def setup(enabled):
 l=env();l.execute('''fonts=0;anchors=0;texts=0;apis=0
 local base=newFrame
 function newFrame(parent)
  local f=base(parent)
  function f:FontTemplate() self.fontSet=true;fonts=fonts+1 end
  function f:ClearAllPoints() self.points={};anchors=anchors+1 end
  function f:SetText(v) assert(not self.isFontString or self.fontSet);self.text=v;texts=texts+1 end
  return f
 end
 function UnitGetTotalAbsorbs() apis=apis+1;return 20 end
 function UnitDetailedThreatSituation() apis=apis+1;return false,1,60 end
 function GetThreatStatusColor() return 1,1,0 end
 NP.db.units.ENEMY_NPC={health={absorb={enable=true,showText=true},text={font='font',fontSize=12}},threatText={enable=true,position='CENTER',xOffset=0,yOffset=0},targetText={enable=true,position='CENTER',xOffset=0,yOffset=0}}
 frame=newFrame();frame.Health=newFrame(frame);frame.UnitType='ENEMY_NPC';frame.unit='target';unitGUIDs.targettarget='OTHER'
 ''')
 l.execute(f'local db=NP.db.units.ENEMY_NPC;db.health.absorb.enable={str(enabled).lower()};db.threatText.enable={str(enabled).lower()};db.targetText.enable={str(enabled).lower()}')
 l.execute((ROOT/'ElvUI/Core/Modules/Nameplates/Elements/HealthBar.lua').read_text())
 return l
class NameplateUpdateCost(unittest.TestCase):
 def test_disabled_features_do_not_allocate_query_or_configure(self):
  l=setup(False);l.execute('NP:Configure_PlateExtras(frame);for i=1,5 do NP:Update_Absorb(frame);NP:Update_ThreatText(frame);NP:Update_TargetText(frame) end')
  for key in ('fonts','anchors','texts','apis'):self.assertEqual(l.eval(key),0,key)
  self.assertIsNone(l.eval('frame.threatText'));self.assertIsNone(l.eval('frame.Health.Absorb'))
 def test_unchanged_values_do_not_reset_fonts_anchors_or_text(self):
  l=setup(True);l.execute('NP:Configure_PlateExtras(frame);NP:Update_Absorb(frame);NP:Update_ThreatText(frame);NP:Update_TargetText(frame);fonts=0;anchors=0;texts=0;for i=1,5 do NP:Update_Absorb(frame);NP:Update_ThreatText(frame);NP:Update_TargetText(frame) end')
  for key in ('fonts','anchors','texts'):self.assertEqual(l.eval(key),0,key)
 def test_disable_after_display_and_reenable(self):
  l=setup(True);l.execute('NP:Configure_PlateExtras(frame);NP:Update_Absorb(frame);NP:Update_ThreatText(frame);NP:Update_TargetText(frame);local d=NP.db.units.ENEMY_NPC;d.health.absorb.enable=false;d.threatText.enable=false;d.targetText.enable=false;NP:Configure_PlateExtras(frame)')
  self.assertFalse(l.eval('frame.Health.Absorb.shown or frame.threatText.shown or frame.targetText.shown'))
  l.execute('NP.db.units.ENEMY_NPC.targetText.enable=true;NP:Configure_PlateExtras(frame);NP:Update_TargetText(frame)')
  self.assertEqual(l.eval('frame.targetText.text'),'targettarget')
 def test_polling_does_not_double_update_absorb(self):
  s=(ROOT/'ElvUI/Core/Modules/Nameplates/Nameplates.lua').read_text();poll=s[s.index('if pollHealth and frame.unit'):s.index('function NP:UpdateVisiblePlates')]
  self.assertIn('else\n\t\t\t\tNP:Update_Absorb(frame)',poll)
