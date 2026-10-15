from pathlib import Path
import unittest
from test_sirus_regressions import env
ROOT=Path(__file__).resolve().parents[1]
class LabelDefaults(unittest.TestCase):
 def test_every_unit_defaults_to_opt_in(self):
  l=env();l.execute("DEFAULT_CHAT_FRAME=newFrame();function DEFAULT_CHAT_FRAME:GetName() return 'ChatFrame1' end")
  l.execute("function CopyTable(t) local c={} for k,v in pairs(t) do c[k]=type(v)=='table' and CopyTable(v) or v end return c end")
  l.execute((ROOT/'ElvUI/Core/Defaults/Profile.lua').read_text())
  l.execute("for unit,db in pairs(ElvUI[4].nameplates.units) do assert(db.targetText.enable==false,unit);assert(db.threatText.enable==false,unit) end")
