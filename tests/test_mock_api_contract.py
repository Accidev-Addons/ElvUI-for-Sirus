import unittest
from test_sirus_regressions import env
class MockAPIContract(unittest.TestCase):
 def test_unknown_set_get_and_event_methods_raise(self):
  l=env()
  for method in ('SetMissingFont','GetMissingValue','RegisterMissingEvent'):
   with self.subTest(method=method):
    with self.assertRaises(Exception):l.execute(f'newFrame():{method}()')
 def test_known_setters_store_state_and_scripts_are_callable(self):
  l=env();l.execute("f=newFrame();f:SetFrameLevel(17);f:SetFrameStrata('HIGH');f:SetAlpha(.5);f:SetScript('OnClick',function() clicked=true end);f:GetScript('OnClick')()")
  self.assertEqual(l.eval('f:GetFrameLevel()'),17);self.assertEqual(l.eval('f.strata'),'HIGH');self.assertEqual(l.eval('f.alpha'),.5);self.assertTrue(l.eval('clicked'))
