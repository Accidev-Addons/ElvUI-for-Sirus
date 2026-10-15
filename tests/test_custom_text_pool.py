from pathlib import Path
import unittest
from test_sirus_regressions import env,load_finalized_tags
ROOT=Path(__file__).resolve().parents[1]
def setup():
 l=env();load_finalized_tags(l)
 l.execute('''NP.db.units.ENEMY_NPC={customTexts={}};frame=newFrame();frame.UnitType='ENEMY_NPC';frame.unit='nameplate1';unitGUIDs.nameplate1='NPC';frame.Health=newFrame(frame);created=0
 local base=frame.CreateFontString;function frame:CreateFontString(...) created=created+1;return base(self,...) end''')
 l.execute((ROOT/'ElvUI/Core/Modules/Nameplates/Elements/CustomText.lua').read_text());return l
class CustomTextPool(unittest.TestCase):
 def test_hundred_distinct_names_reuse_one_fontstring(self):
  l=setup();l.execute('''for i=1,100 do NP.db.units.ENEMY_NPC.customTexts={['text'..i]={font='font',size=12,text_format='[name]'}};NP:Configure_CustomTexts(frame) end;NP.db.units.ENEMY_NPC.customTexts={};NP:Configure_CustomTexts(frame)''')
  self.assertEqual(l.eval('created'),1);self.assertEqual(l.eval('#frame.customTextPool'),1);self.assertTrue(l.eval('next(frame.customTexts)==nil'));self.assertIsNone(l.eval('frame.customTextPool[1].UpdateTag'))
 def test_peak_live_count_and_disabled_entries(self):
  l=setup();l.execute("NP.db.units.ENEMY_NPC.customTexts={a={font='font',size=12,text_format='[name]'},b={font='font',size=12,text_format='[curhp]'}};NP:Configure_CustomTexts(frame);a=frame.customTexts.a;NP.db.units.ENEMY_NPC.customTexts.a.enable=false;NP:Configure_CustomTexts(frame)")
  self.assertEqual(l.eval('created'),2);self.assertEqual(l.eval('#frame.customTextPool'),1);self.assertIsNone(l.eval('a.UpdateTag'))
  l.execute('NP.db.units.ENEMY_NPC.customTexts.a.enable=true;NP:Configure_CustomTexts(frame)')
  self.assertEqual(l.eval('created'),2);self.assertEqual(l.eval('frame.customTexts.a.text'),'nameplate1')
  self.assertIsNone(l.eval('frame.customTexts.a.frequentUpdates'))
 def test_pool_rebinds_unit_and_text_format(self):
  l=setup();l.execute("NP.db.units.ENEMY_NPC.customTexts={a={font='font',size=12,text_format='[name]'}};NP:Configure_CustomTexts(frame);old=frame.customTexts.a;NP.db.units.ENEMY_NPC.customTexts={b={font='font',size=12,text_format='[curhp]'}};frame.unit='nameplate2';unitGUIDs.nameplate2='OTHER';NP:Configure_CustomTexts(frame)")
  self.assertTrue(l.eval('old==frame.customTexts.b'));self.assertEqual(l.eval('old.text'),'80')
  l.execute('NP:Clear_CustomTexts(frame)');self.assertIsNone(l.eval('old.UpdateTag'))
