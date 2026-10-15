from pathlib import Path
import unittest
from test_sirus_regressions import env,load_finalized_tags
ROOT=Path(__file__).resolve().parents[1]
def options():
 l=env();l.execute('''DEFAULT_CHAT_FRAME=newFrame();function DEFAULT_CHAT_FRAME:GetName() return 'ChatFrame1' end
 function CopyTable(t) local c={} for k,v in pairs(t) do c[k]=type(v)=='table' and CopyTable(v) or v end return c end''')
 l.execute((ROOT/'ElvUI/Core/Defaults/Profile.lua').read_text())
 l.execute('''E.db=CopyTable(ElvUI[4]);NP.db=E.db.nameplates;E.NamePlates={Initialized=true};L=ElvUI[2];P=ElvUI[4]
 C={Values={FontFlags={NONE='None',OUTLINE='Outline',MONOCHROMEOUTLINE='Monochrome'},FontSorting={'NONE','OUTLINE','MONOCHROMEOUTLINE'}}};AceGUIWidgetLSMlists={font={}}
 E.global={nameplates={specialFilters={}},unitframe={aurafilters={}}};E.InversePoints={};E.noop=function() end
 function NP:ConfigureAll() configured=(configured or 0)+1 end;function E:Print(message) lastError=message end
 positionValues={}
 ''')
 s=(ROOT/'ElvUI_Options/Core/Nameplates.lua').read_text();l.execute(s[s.index('local ORDER = 100'):s.index('E.Options.args.nameplates =')]+' getOptions=GetUnitSettings')
 l.execute('opts=getOptions("ENEMY_NPC","Enemy");custom=opts.args.customText;custom.args.create.set(nil,"Mine");row=custom.args["text:Mine"]')
 return l
def runtime():
 l=env();load_finalized_tags(l)
 l.execute('''NP.db.font='default';NP.db.fontSize=17;NP.db.fontOutline='MONOCHROMEOUTLINE'
 NP.db.units.ENEMY_NPC={customTexts={a={text_format='[name]',justifyH='LEFT',attachTextTo='Frame'}}}
 frame=newFrame();frame.UnitType='ENEMY_NPC';frame.unit='nameplate1';unitGUIDs.nameplate1='NPC';frame.Health=newFrame(frame);frame.CastBar=newFrame(frame);frame.Name=newFrame(frame)
 frame.Health:SetFrameLevel(7);frame.CastBar:SetFrameLevel(8)
 local base=CreateFrame;function CreateFrame(...) local f=base(...);local create=f.CreateFontString
 function f:CreateFontString(...) local text=create(self,...);function text:FontTemplate(font,size,outline) self.fontSet=true;self.font=font;self.fontSize=size;self.outline=outline end;return text end;return f end
 ''')
 l.execute((ROOT/'ElvUI/Core/Modules/Nameplates/Elements/CustomText.lua').read_text());return l
class CustomTextParity(unittest.TestCase):
 def test_same_control_contract_as_unitframes(self):
  l=options();s=(ROOT/'ElvUI_Options/Core/UnitFrames.lua').read_text()
  l.execute('''UF={};CUSTOMTEXT_CONFIGS={};attachToValues={Health='Health',Power='Power',InfoPanel='InfoPanel',Frame='Frame'};E.Options={args={unitframe={args={player={args={customText={args={}}}}}}}}''')
  l.execute(s[s.index('local function CreateCustomTextGroup'):s.index('local function GetOptionsTable_CustomText')]+' CreateCustomTextGroup("player","Reference")')
  l.execute('reference=E.Options.args.unitframe.args.player.args.customText.args.Reference')
  for key in ('header','delete','enable','font','size','fontOutline','justifyH','xOffset','yOffset','attachTextTo','text_format'):
   self.assertEqual(l.eval(f'row.args.{key}.type'),l.eval(f'reference.args.{key}.type'),key)
  for key in ('xOffset','yOffset','size'):
   for prop in ('min','max','step'):self.assertEqual(l.eval(f'row.args.{key}.{prop}'),l.eval(f'reference.args.{key}.{prop}'))
  self.assertTrue(l.eval('row.args.fontOutline.values==reference.args.fontOutline.values and row.args.fontOutline.sorting==reference.args.fontOutline.sorting'))
  self.assertEqual(l.eval('row.args.text_format.desc'),l.eval('reference.args.text_format.desc'))
  self.assertIsNotNone(l.eval('row.args.attachTextTo.values.Frame'))
  self.assertIsNone(l.eval('row.args.attachTextTo.values.Power'))
 def test_new_text_uses_module_defaults_and_empty_format(self):
  l=options();l.execute('db=E.db.nameplates.units.ENEMY_NPC.customTexts.Mine')
  for a,b in [('font','font'),('size','fontSize'),('fontOutline','fontOutline')]:self.assertEqual(l.eval('db.'+a),l.eval('E.db.nameplates.'+b))
  self.assertEqual(l.eval('db.text_format'),'');self.assertIsNone(l.eval('db.position'))
 def test_conflicting_names_and_stable_option_identity(self):
  l=options();l.execute('custom.args.create.set(nil,"health")')
  self.assertIsNotNone(l.eval('lastError'));self.assertIsNone(l.eval('E.db.nameplates.units.ENEMY_NPC.customTexts.health'))
  l.execute('custom.args.create.set(nil,"mine");custom.hidden()');self.assertIsNone(l.eval('E.db.nameplates.units.ENEMY_NPC.customTexts.mine'))
  self.assertTrue(l.eval('row==custom.args["text:Mine"]'))
  l.execute('custom.args.create.set(nil,"create")');self.assertIsNotNone(l.eval('custom.args["text:create"]'));self.assertEqual(l.eval('custom.args.create.type'),'input')
 def test_profile_reconciliation_and_reenable(self):
  l=options();l.execute('E.db.nameplates.units.ENEMY_NPC.customTexts={New={text_format="[curhp]",enable=false}};custom.hidden()')
  self.assertIsNone(l.eval('custom.args["text:Mine"]'));self.assertIsNotNone(l.eval('custom.args["text:New"]'))
  l.execute('custom.args["text:New"].set({"enable"},true)');self.assertTrue(l.eval('E.db.nameplates.units.ENEMY_NPC.customTexts.New.enable'))
 def test_alignment_font_inheritance_and_raised_parent(self):
  l=runtime();l.execute('NP:Configure_CustomTexts(frame);t=frame.customTexts.a')
  self.assertEqual(l.eval('t.points[1][1]'),'LEFT');self.assertTrue(l.eval('t.points[1][2]==frame'))
  self.assertEqual(l.eval('t.font'),'default');self.assertEqual(l.eval('t.fontSize'),17);self.assertEqual(l.eval('t.outline'),'MONOCHROMEOUTLINE')
  self.assertTrue(l.eval('t:GetParent()==frame.CustomTextParent'));self.assertEqual(l.eval('frame.CustomTextParent:GetFrameLevel()'),9)
  l.execute("NP.db.units.ENEMY_NPC.customTexts.a.justifyH='RIGHT';NP:Configure_CustomTexts(frame)");self.assertEqual(l.eval('frame.customTexts.a.points[1][1]'),'RIGHT')
 def test_anchor_fallback_matches_unitframes(self):
  l=runtime();s=(ROOT/'ElvUI/Core/Modules/UnitFrames/UnitFrames.lua').read_text();l.execute('UF={}\n'+s[s.index('function UF:GetObjectAnchorPoint'):s.index('function UF:GetPositionOffset')])
  for point in ('Frame','Health','Name','CastBar','missing'):
   l.globals().point=point;self.assertTrue(l.eval('NP:GetCustomTextAnchor(frame,point)==UF:GetObjectAnchorPoint(frame,point)'))
  l.execute('frame.CastBar:Hide()');self.assertTrue(l.eval('NP:GetCustomTextAnchor(frame,"CastBar")==frame.Health'))
 def test_manual_legacy_anchor_and_automatic_mode(self):
  l=runtime();l.execute("NP.db.units.ENEMY_NPC.customTexts.a.position='TOPRIGHT';NP:Configure_CustomTexts(frame)")
  self.assertEqual(l.eval('frame.customTexts.a.points[1][1]'),'TOPRIGHT')
  l=options();l.execute('row.args.position.set(nil,"AUTO")');self.assertIsNone(l.eval('E.db.nameplates.units.ENEMY_NPC.customTexts.Mine.position'))

 def test_mouseover_marker_uses_actual_plate_lifecycle(self):
  l=runtime();s=(ROOT/'ElvUI/Core/Modules/Nameplates/Nameplates.lua').read_text()
  l.execute('mouseoverWatcher=newFrame();function NP:Update_Highlight() end;function NP:UpdateElement_Auras() end;function UnitIsUnit(a,b) return unitGUIDs[a] and unitGUIDs[a]==unitGUIDs[b] end')
  l.execute(s[s.index('function NP:SetMouseoverFrame'):s.index('-- the engine places plates')])
  l.execute('NP.db.units.ENEMY_NPC.customTexts.a.text_format="[mouseover][name]";NP:Configure_CustomTexts(frame);t=frame.customTexts.a')
  self.assertEqual(l.eval('t.text'),'nameplate1');self.assertEqual(l.eval('t.alpha'),0)
  l.execute('unitGUIDs.mouseover="NPC";NP:SetMouseoverFrame(frame)');self.assertEqual(l.eval('t.alpha'),1)
  l.execute('unitGUIDs.mouseover=nil;NP:SetMouseoverFrame(frame)');self.assertEqual(l.eval('t.alpha'),0)
  l.execute('NP.db.units.ENEMY_NPC.customTexts={b={text_format="[name]"}};NP:Configure_CustomTexts(frame)')
  self.assertEqual(l.eval('frame.customTexts.b.alpha'),1);self.assertIsNone(l.eval('frame.customTexts.b.customMouseover'))

 def test_mouseover_marker_does_not_inherit_stale_plate_state(self):
  l=runtime();l.execute('frame.isMouseover=true;function UnitIsUnit() return false end;NP.db.units.ENEMY_NPC.customTexts.a.text_format="[mouseover][name]";NP:Configure_CustomTexts(frame)')
  self.assertEqual(l.eval('frame.customTexts.a.alpha'),0)

 def test_external_tag_without_events_keeps_updating(self):
  l=runtime();l.execute('''value=1;E.oUF.Tags.Methods.dynamic=function() return tostring(value) end
  NP.db.units.ENEMY_NPC.customTexts.a.text_format='[dynamic]';NP:Configure_CustomTexts(frame);t=frame.customTexts.a''')
  self.assertEqual(l.eval('t.frequentUpdates'),.2);self.assertEqual(l.eval('t.text'),'1')
  l.execute('value=2;for _,timer in ipairs(frames) do if timer.timer==.2 and timer:IsShown() then timer.scripts.OnUpdate(timer,.2) end end');self.assertEqual(l.eval('t.text'),'2')
  l.execute('NP.db.units.ENEMY_NPC.customTexts.a.text_format="[name]";NP:Configure_CustomTexts(frame)')
  self.assertIsNone(l.eval('t.frequentUpdates'))
 def test_tag_parser_fallback_preserves_explicit_timers(self):
  l=runtime();l.execute('''E.oUF.Tags.Methods.dynamic=function() return 'value' end
  E.oUF.Tags.Methods.timed=function() return 'timed' end;E.oUF.Tags.OnUpdateThrottle.timed=1''')
  for fmt in ('[dynamic]','[prefix>dynamic<suffix]','[dynamic{arg}]'):
   l.globals().format=fmt;self.assertTrue(l.eval('E.oUF.Tags:NeedsFrequentUpdates(format)'))
  for fmt in ('plain text','[name]','[timed]','[unknown]'):
   l.globals().format=fmt;self.assertFalse(l.eval('E.oUF.Tags:NeedsFrequentUpdates(format)'))
  l.execute('NP.db.units.ENEMY_NPC.customTexts.a.text_format="[timed]";NP:Configure_CustomTexts(frame)')
  self.assertIsNone(l.eval('frame.customTexts.a.frequentUpdates'))
