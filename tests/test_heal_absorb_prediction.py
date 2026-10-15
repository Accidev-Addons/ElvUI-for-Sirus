import unittest
from test_unitframe_absorbs import setup
class HealAbsorbPrediction(unittest.TestCase):
 def test_client_overflow_cap_includes_heal_absorb(self):
  l=setup();l.execute('health=90;healAbsorb=40;personal=10;incoming=30;shield=0;UF:Configure_HealComm(frame);p=frame.HealCommBar')
  self.assertEqual(l.eval('p.myBar.value+p.otherBar.value'),30)
  self.assertEqual(l.eval('p.myBar.points.TOPLEFT[3]'),-40)
  self.assertEqual(l.eval('p.healAbsorbBar.width'),10)
 def test_other_heals_start_at_absorb_when_personal_is_zero(self):
  l=setup();l.execute('health=90;healAbsorb=40;personal=0;incoming=30;UF:Configure_HealComm(frame)')
  self.assertEqual(l.eval('frame.HealCommBar.otherBar.points.TOPLEFT[3]'),-40)
 def test_vertical_orientation_and_fully_covered_heal_absorb(self):
  l=setup();l.execute("frame.db.health.orientation='VERTICAL';frame.Health.orientation='VERTICAL';health=90;healAbsorb=40;personal=10;incoming=60;UF:Configure_HealComm(frame)")
  self.assertEqual(l.eval('frame.HealCommBar.myBar.points.BOTTOMLEFT[4]'),-8)
  self.assertFalse(l.eval('frame.HealCommBar.healAbsorbBar.shown'))
 def test_no_absorb_and_extreme_overflow(self):
  l=setup();l.execute('health=90;healAbsorb=0;personal=30;incoming=100;UF:Configure_HealComm(frame)')
  self.assertEqual(l.eval('frame.HealCommBar.myBar.value'),10)
  l.execute('health=50;healAbsorb=200;personal=20;incoming=150;frame.HealCommBar:ForceUpdate()')
  self.assertEqual(l.eval('frame.HealCommBar.myBar.value+frame.HealCommBar.otherBar.value'),100)
  self.assertTrue(l.eval('frame.HealCommBar.overHealAbsorb.shown'))
