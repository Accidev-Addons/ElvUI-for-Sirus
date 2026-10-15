import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


class RemovedAuraNotice(unittest.TestCase):
    def test_deleted_notice_has_no_code_or_locale_entries(self):
        marker='The game client decides '+'which auras a nameplate can show'
        paths=[ROOT/'ElvUI_Options/Core/Nameplates.lua']
        for dirname in ['ElvUI/Locales','ElvUI_Options/Locales']:
            locales=list((ROOT/dirname).glob('*.lua'))
            self.assertTrue(locales,dirname)
            paths.extend(locales)
        for path in paths:
            with self.subTest(file=str(path.relative_to(ROOT))):
                self.assertNotIn(marker,path.read_text())
                self.assertNotIn('Какие ауры и в каком порядке',path.read_text())


if __name__=='__main__':
    unittest.main()
