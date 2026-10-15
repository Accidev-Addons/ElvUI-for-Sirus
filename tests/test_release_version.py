from pathlib import Path
import hashlib, unittest
ROOT=Path(__file__).resolve().parents[1]
class ReleaseVersion(unittest.TestCase):
 def test_addon_versions(self):
  for addon in ('ElvUI','ElvUI_Options','ElvUI_Libraries'):
   self.assertIn('## Version: 9.09.08',(ROOT/addon/(addon+'.toc')).read_text())
 def test_published_changelog_is_preserved(self):
  md=(ROOT/'CHANGELOG.md').read_text();lua=(ROOT/'ElvUI_Options/Core/Changelog.lua').read_text()
  self.assertTrue(md.index('## Версия 9.09.08')<md.index('## Версия 9.09.07'))
  self.assertEqual(hashlib.sha256(md.split('## Версия 9.09.07',1)[1].encode()).hexdigest(),'56bbcbb563008ed28cc96f3bafca819b6fa69587982f09b34a73cf7d231b15f5')
  self.assertEqual(hashlib.sha256(lua.split("\t{\n\t\tversion = '9.09.07'",1)[1].encode()).hexdigest(),'bc1f81130888dcc19f6dbe698102be9d53e772418f8b28ebe91615d6482f6c9e')
