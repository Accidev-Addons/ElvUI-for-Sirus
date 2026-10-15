from pathlib import Path
from lupa.lua51 import LuaRuntime
import re, unittest
ROOT=Path(__file__).resolve().parents[1]
KEYS=['Absorption','Absorb Amount','Threat Level','Nameplate Target','Reset Position','Restore the default Sirus client anchors.','Sirus Size and Spacing']
class NameplateLocales(unittest.TestCase):
 def test_english_and_russian_keys_exist(self):
  for lang in ('enUS','ruRU'):
   l=LuaRuntime();l.execute('L={};ElvUI={{Libs={ACL={NewLocale=function() return L end}}}}')
   l.execute((ROOT/'ElvUI_Options/Locales'/f'{lang}.lua').read_text())
   for key in KEYS:self.assertIsNotNone(l.globals().L[key],(lang,key))
 def test_options_use_locale_keys_and_have_no_embedded_russian_labels(self):
  s=(ROOT/'ElvUI_Options/Core/Nameplates.lua').read_text()
  for key in KEYS:self.assertIn('L["'+key+'"]',s)
  self.assertIsNone(re.search(r'[А-Яа-яЁё]',s))
