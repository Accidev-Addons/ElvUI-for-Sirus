from pathlib import Path
from lupa.lua51 import LuaRuntime
import unittest, subprocess
ROOT=Path(__file__).resolve().parents[1];PLUGIN=ROOT.parent/'ElvUI_DmgAtNameplates'
COMMON=r'''
format=string.format; tinsert=table.insert; max=math.max
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
function newFrame(parent)
 local f={parent=parent,shown=true,width=100,height=16,points={},scripts={},events={}}
 function f:ClearAllPoints() self.points={} end
 function f:SetPoint(...) table.insert(self.points,{...}) end
 f.Point=f.SetPoint
 function f:ClearAndSetPoint(...) self:ClearAllPoints() self:SetPoint(...) end
 function f:SetSize(w,h) self.width=w self.height=h or w end; f.Size=f.SetSize
 function f:SetWidth(v) self.width=v end; f.Width=f.SetWidth
 function f:SetHeight(v) self.height=v end; f.Height=f.SetHeight
 function f:GetWidth() return self.width end
 function f:GetHeight() return self.height end
 function f:GetSize() return self.width,self.height end
 function f:GetFrameLevel() return 1 end
 function f:GetParent() return self.parent end
 function f:SetParent(p) self.parent=p end
 function f:IsShown() return self.shown end; f.IsVisible=f.IsShown
 function f:Show() self.shown=true end
 function f:Hide() self.shown=false end
 function f:SetShown(v) self.shown=not not v end
 function f:SetText(v)
  assert(not self.isFontString or self.fontSet, "SetText(): Font not set")
  self.text=v
 end
 function f:FontTemplate() self.fontSet=true end
 function f:SetFont() self.fontSet=true end
 function f:SetFormattedText(fmt,...) assert(not self.isFontString or self.fontSet,"SetFormattedText(): Font not set");self.text=string.format(fmt,...) end
 function f:GetStringHeight() return 12 end
 function f:SetTextColor(...) self.color={...} end
 function f:SetValue(v) self.value=v end
 function f:SetMinMaxValues(a,b) self.min=a self.max=b end
 function f:CreateTexture() return newFrame(self) end
 function f:CreateFontString() local text=newFrame(self);text.isFontString=true;return text end
 function f:SetScript(k,v) self.scripts[k]=v end
 function f:RegisterEvent(k) self.events[k]=true end
 function f:UnregisterEvent(k) self.events[k]=nil end
 function f:CanChangeProtectedState() return not self.locked end
 function f:IsObjectType() return true end
 function f:GetStatusBarTexture() return self.texture end
 setmetatable(f,{__index=function(_,k) if k:match('^Set') or k:match('^Get') or k=='FontTemplate' or k=='EnableMouse' then return function() end end end})
 return f
end
frames={}
function CreateFrame(_,name,parent) local f=newFrame(parent); table.insert(frames,f); if name then _G[name]=f end return f end
hooks={}
function hooksecurefunc(a,b,c) if type(a)=='string' then hooks[a]=b else hooks[b]=c end end
C_Timer={After=function(_,_,fn) fn() end}
NP={db={units={}},VisiblePlates={},CreatedPlates={}}
function NP:Pixel(x) return x end; NP.SirusPixel=NP.Pixel
function NP:GetHealth(f) return f.health or 80,f.maxHealth or 100 end
E={media={blankTex='blank'},Libs={LSM={Fetch=function(_,_,v) return v end}},UIParent=newFrame(),oUF={Private={frame_metatable={__index={}}},colors={}}}
function E:GetModule() return NP end
function E:ShortValue(v) return tostring(v) end
function E:ClassColor() return {r=1,g=0,b=0} end
function E:CreateMover() end
ElvUI={E,setmetatable({},{__index=function(_,k) return k end}),{},{nameplates={units={}}},{}}
unitGUIDs={player='PLAYER',target='NPC'}
function UnitGUID(u) return unitGUIDs[u] end
function UnitExists(u) return unitGUIDs[u]~=nil end
function UnitName(u) return u end
function UnitClass() return 'Mage','MAGE' end
function UnitIsPlayer() return false end
function UnitCanAttack() return true end
function GetSpellInfo(x) return tostring(x),nil,'texture' end
'''
def env():
 l=LuaRuntime(unpack_returned_tuples=True);l.execute(COMMON);return l

def chunk(path,a,b):
 s=(ROOT/path).read_text();return s[s.index(a):s.index(b,s.index(a))]


def load_finalized_tags(l):
 # oUF deliberately removes Private in finalize.lua, before ElvUI initializes.
 l.execute("""UnitHealth=function() return 80 end; UnitHealthMax=function() return 100 end; GetTime=function() return 0 end
 E.oUF.ColorGradient=function() return 0.8 end
 E.oUF.Private.unitExists=UnitExists; E.oUF.Private.validateEvent=function() return true end
 local methods=E.oUF.Private.frame_metatable.__index
 function E.oUF:RegisterMetaFunction(name,fn) methods[name]=fn end; ns={oUF=E.oUF}
 """)
 l.execute('local function loadTags(...)\n'+(ROOT/'ElvUI_Libraries/Core/oUF/elements/tags.lua').read_text()+'\nend; loadTags("ElvUI",ns)')
 l.execute('ns.oUF.Private=nil')


class Changes(unittest.TestCase):
 def test_lua51_syntax(self):
  l=env();compile=l.eval('function(s) local f,e=loadstring(s); return f~=nil,e end')
  paths=set([str(p.relative_to(ROOT)) for p in ROOT.rglob('*.lua')])
  for p in paths:
   if p.endswith('.lua'):self.assertTrue(compile((ROOT/p).read_text())[0],p)
  if (PLUGIN/'Core/Core.lua').exists(): self.assertTrue(compile((PLUGIN/'Core/Core.lua').read_text())[0])
 def test_full_defaults_and_options(self):
  l=env();l.execute("""DEFAULT_CHAT_FRAME=newFrame(); function DEFAULT_CHAT_FRAME:GetName() return 'ChatFrame1' end
  function CopyTable(t) local c={} for k,v in pairs(t) do c[k]=type(v)=='table' and CopyTable(v) or v end return c end
  """);l.execute((ROOT/'ElvUI/Core/Defaults/Profile.lua').read_text())
  l.execute("""E.db=CopyTable(ElvUI[4]); NP.db=E.db.nameplates; E.NamePlates={Initialized=true}; L=ElvUI[2]; P=ElvUI[4]; C={Values={FontFlags={},FontSorting={}}}; AceGUIWidgetLSMlists={font={}}; E.global={nameplates={specialFilters={}},unitframe={aurafilters={}}}; E.InversePoints={}; E.noop=function() end
  function NP:ConfigureAll() end; positionValues={}
  """)
  s=(ROOT/'ElvUI_Options/Core/Nameplates.lua').read_text();l.execute(s[s.index('local ORDER = 100'):s.index('E.Options.args.nameplates =')]+' getOptions=GetUnitSettings')
  l.execute('opts=getOptions("ENEMY_NPC","Enemy"); opts.args.customText.args.create.set(nil,"My text"); opts.args.buffsGroup.args.xOffset.set({"xOffset"},17)')
  self.assertEqual(l.eval('E.db.nameplates.units.ENEMY_NPC.customTexts["My text"].text_format'),'[name]')
  self.assertFalse(l.eval('E.db.nameplates.units.ENEMY_NPC.buffs.useSirusPosition'));self.assertTrue(l.eval('E.db.nameplates.units.ENEMY_NPC.crowdcontrol.useSirusPosition'))
  self.assertIsNone(l.eval('opts.args.buffsGroup.args.useSirusPosition'))
  self.assertIsNone(l.eval('opts.args.buffsGroup.args.xOffset.disabled'))
  self.assertEqual(l.eval('E.db.nameplates.units.ENEMY_NPC.buffs.xOffset'),17)
  l.execute('opts.args.buffsGroup.args.resetSirusPosition.func()')
  self.assertTrue(l.eval('E.db.nameplates.units.ENEMY_NPC.buffs.useSirusPosition'))
  self.assertTrue(l.eval('E.db.nameplates.units.ENEMY_NPC.buffs.xOffset==P.nameplates.units.ENEMY_NPC.buffs.xOffset'))
  self.assertNotIn('AddClientAuraNotice',s)
  l.execute('opts.args.customText.args["text:My text"].args.delete.func()');self.assertIsNone(l.eval('E.db.nameplates.units.ENEMY_NPC.customTexts["My text"]'))
 def test_pvp_each_update_and_combat(self):
  l=env();l.execute("InCombatLockdown=function() return false end; NUM_ALWAYS_UP_UI_FRAMES=2; AlwaysUpFrame1=newFrame(); AlwaysUpFrame2=newFrame(); AlwaysUpFrame1Text=newFrame(); AlwaysUpFrame2Text=newFrame()")
  l.execute((ROOT/'ElvUI/Core/Modules/Blizzard/CaptureBar.lua').read_text());l.execute('NP:PositionAlwaysUpFrame()')
  l.execute("AlwaysUpFrame1:ClearAndSetPoint('LEFT'); hooks.WorldStateAlwaysUpFrame_Update()")
  self.assertEqual(l.eval('AlwaysUpFrame1.points[1][1]'),'CENTER')
  self.assertTrue(l.eval('AlwaysUpFrame2.points[1][2]==AlwaysUpFrame1'))
  l.execute('AlwaysUpFrame1.locked=true; AlwaysUpFrame1:ClearAndSetPoint("LEFT"); hooks.WorldStateAlwaysUpFrame_Update()')
  self.assertEqual(l.eval('AlwaysUpFrame1.points[1][1]'),'LEFT')
  l.execute('AlwaysUpFrame1.locked=false; frames[#frames].scripts.OnEvent()')
  self.assertEqual(l.eval('AlwaysUpFrame1.points[1][1]'),'CENTER')
 def test_worldstate_text_centering(self):
  l=env();l.execute("""InCombatLockdown=function() return false end;NUM_ALWAYS_UP_UI_FRAMES=2
  for i=1,2 do
   _G['AlwaysUpFrame'..i]=newFrame();local t=newFrame();_G['AlwaysUpFrame'..i..'Text']=t
   function t:SetJustifyH(v) self.justifyH=v end
   function t:SetWordWrap(v) self.wordWrap=v end
   t.width=240;t.justifyH='LEFT';t.wordWrap=true
  end""")
  l.execute((ROOT/'ElvUI/Core/Modules/Blizzard/CaptureBar.lua').read_text());l.execute('NP:PositionAlwaysUpFrame()')
  for i in (1,2):
   l.execute(f't=AlwaysUpFrame{i}Text;f=AlwaysUpFrame{i}')
   self.assertEqual(l.eval('t.width'),0)
   self.assertEqual(l.eval('t.justifyH'),'CENTER')
   self.assertFalse(l.eval('t.wordWrap'))
   self.assertTrue(l.eval("#t.points==1 and t.points[1][1]=='CENTER' and t.points[1][2]==f and t.points[1][3]=='CENTER' and t.points[1][4]==0"))
  l.execute("AlwaysUpFrame1Text.width=300;AlwaysUpFrame1Text.justifyH='LEFT';hooks.WorldStateAlwaysUpFrame_Update()")
  self.assertEqual(l.eval('AlwaysUpFrame1Text.width'),0)
  self.assertEqual(l.eval('AlwaysUpFrame1Text.justifyH'),'CENTER')
 def test_capture_marker(self):
  l=env();l.execute('WorldStateCaptureBar1=newFrame(); WorldStateCaptureBar1.spark={}; WorldStateCaptureBar1Indicator=newFrame(); WorldStateCaptureBar1MiddleBar=newFrame()')
  code=chunk('ElvUI/Core/Modules/Skins/Blizzard/WorldStateFrame.lua','local function UpdateCaptureProgress','local function DeferCaptureBarWork')
  l.execute(code+' updateCapture=UpdateCaptureProgress')
  for value,expected in [(0,100),(50,50),(100,0),(-10,100),(120,0)]:
   l.globals().updateCapture(1,value,20);self.assertEqual(l.eval('WorldStateCaptureBar1Indicator.points[1][4]'),expected)
  self.assertEqual(l.eval('WorldStateCaptureBar1MiddleBar.width'),20)
  l.execute('WorldStateCaptureBar1.locked=true; updateCapture(1,25,30)')
  self.assertEqual(l.eval('WorldStateCaptureBar1.elvCaptureValue'),25)
  self.assertEqual(l.eval('WorldStateCaptureBar1MiddleBar.width'),20)
 def test_popup(self):
  l=env();l.execute("staticPopup=newFrame(); staticPopup.which='NOTE'; wideBox=newFrame(); wideBox.backdrop=newFrame(); StaticPopupDialogs={NOTE={hasEditBox=true,hasWideEditBox=true}}")
  code=chunk('ElvUI/Core/Modules/Skins/Blizzard/Misc.lua','\t\tlocal function UpdatePopupEditBox','\t\thooksecurefunc(\'StaticPopup_Resize\'')
  l.execute(code+' popupUpdate=UpdatePopupEditBox; popupUpdate(staticPopup)')
  self.assertEqual(l.eval('wideBox.height'),24)
  l.execute('wideBox.height=14; popupUpdate(staticPopup)');self.assertEqual(l.eval('wideBox.height'),24)
  l.execute('StaticPopupDialogs.NOTE.hasMultiLine=true; wideBox.height=64; popupUpdate(staticPopup)');self.assertEqual(l.eval('wideBox.height'),64)
 def test_merchant(self):
  l=env();l.execute(r'''
   MerchantFrame={selectedTab=1}; floor=math.floor; alt=true; stack=20; bundle=1; stock=-1; money=1000; price=10; extended=false; vendor=1; honor=0
   IsAltKeyDown=function() return alt end; IsControlKeyDown=function() return false end; IsShiftKeyDown=IsControlKeyDown
   InRepairMode=IsControlKeyDown; GetCursorInfo=function() end
   GetMerchantItemLink=function() return 'item' end
   GetItemInfo=function() return 'item',nil,nil,nil,nil,nil,nil,stack end
   GetMerchantItemInfo=function() return 'item',nil,price,bundle,stock,nil,extended end
   GetMerchantItemMaxStack=function() return vendor end; GetMoney=function() return money end
   GetMerchantItemCostInfo=function() return honor,0,0 end; GetHonorCurrency=function() return 55 end
   BuyMerchantItem=function(id,n) bought=n end
   MerchantFrame_ConfirmExtendedItemCost=function(_,n) confirmed=n end
   MerchantFrame_ConfirmHighCostItem=MerchantFrame_ConfirmExtendedItemCost; MERCHANT_HIGH_PRICE_COST=1500000
   button={GetID=function() return 1 end}
  ''')
  code=chunk('ElvUI/Core/Modules/Skins/Blizzard/Merchant.lua','local function MerchantItemButton_AltStackBuy','local function MerchantItemButton_AltStackHint')
  l.execute(code+' buy=MerchantItemButton_AltStackBuy')
  self.assertTrue(l.eval('buy(button,"LeftButton")'));self.assertEqual(l.eval('bought'),20)
  l.execute('bundle=5; buy(button,"RightButton")');self.assertEqual(l.eval('bought'),4)
  l.execute('bundle=1; money=35; buy(button,"RightButton")');self.assertEqual(l.eval('bought'),3)
  l.execute('money=1000; stock=7; buy(button,"RightButton")');self.assertEqual(l.eval('bought'),7)
  l.execute('stock=-1; extended=true; honor=10; buy(button,"LeftButton")');self.assertEqual(l.eval('confirmed'),5)
  l.execute('extended=false; money=0; bought=nil');self.assertTrue(l.eval('buy(button,"LeftButton")'));self.assertIsNone(l.eval('bought'))
  l.execute('stack=nil');self.assertFalse(l.eval('buy(button,"LeftButton")'))
  l.execute('stack=20; alt=false');self.assertFalse(l.eval('buy(button,"RightButton")'))
 def test_nameplate_labels(self):
  l=env();l.execute('''LSM=E.Libs.LSM; absorb=30; UnitGetTotalAbsorbs=function() return absorb end; percent=60
  UnitDetailedThreatSituation=function() return false,1,percent end; GetThreatStatusColor=function() return 1,1,0 end
  NP.db.units.ENEMY_NPC={health={absorb={enable=true,showText=true},text={font='font',fontSize=12,fontOutline='OUTLINE'}}, threatText={enable=true,position='BOTTOMRIGHT'},targetText={enable=true,position='BOTTOMLEFT'}}
  frame=newFrame(); frame.UnitType='ENEMY_NPC'; frame.unit='nameplate1'; frame.Health=newFrame(frame); unitGUIDs.nameplate1='NPC'; unitGUIDs.nameplate1target='OTHER'
  ''')
  s=(ROOT/'ElvUI/Core/Modules/Nameplates/Elements/HealthBar.lua').read_text();l.execute(s[s.index('function NP:Update_Absorb'):])
  l.execute('NP:Update_Absorb(frame); NP:Update_ThreatText(frame); NP:Update_TargetText(frame)')
  self.assertEqual(l.eval('frame.Health.Absorb.width'),30);self.assertEqual(l.eval('frame.Health.AbsorbText.text'),'+30')
  self.assertEqual(l.eval('frame.threatText.text'),'60%');self.assertEqual(l.eval('frame.targetText.text'),'nameplate1target')
  l.execute('absorb=200; NP:Update_Absorb(frame)');self.assertEqual(l.eval('frame.Health.Absorb.width'),100)
  l.execute('absorb=0; percent=nil; unitGUIDs.nameplate1target=nil; NP:Update_Absorb(frame); NP:Update_ThreatText(frame); NP:Update_TargetText(frame)')
  self.assertFalse(l.eval('frame.Health.Absorb.shown'));self.assertFalse(l.eval('frame.targetText.shown'));self.assertFalse(l.eval('frame.threatText.shown'))
 def test_absorb_initial_font(self):
  for state in ["zero", "no_unit", "disabled", "hidden", "zero_max", "text_off", "positive"]:
   with self.subTest(state=state):
    l=env();l.execute("""LSM=E.Libs.LSM; absorb=0; UnitGetTotalAbsorbs=function() return absorb end
    NP.db.units.ENEMY_NPC={health={absorb={enable=true,showText=true},text={font='font',fontSize=12,fontOutline='OUTLINE'}}}
    frame=newFrame();frame.UnitType='ENEMY_NPC';frame.Health=newFrame(frame);frame.unit='nameplate1'
    """)
    setup={"no_unit":"frame.unit=nil", "disabled":"NP.db.units.ENEMY_NPC.health.absorb.enable=false;absorb=20", "hidden":"frame.Health:Hide();absorb=20", "zero_max":"frame.maxHealth=0;absorb=20", "text_off":"NP.db.units.ENEMY_NPC.health.absorb.showText=false;absorb=20", "positive":"absorb=20"}
    if state in setup:l.execute(setup[state])
    s=(ROOT/'ElvUI/Core/Modules/Nameplates/Elements/HealthBar.lua').read_text();l.execute(s[s.index('function NP:Update_Absorb'):])
    l.execute('NP:Update_Absorb(frame); NP:Update_Absorb(frame)')
    self.assertTrue(l.eval('frame.Health.AbsorbText.fontSet'))
    l.execute('frame.unit="nameplate2";absorb=0;NP:Update_Absorb(frame)')
    self.assertEqual(l.eval('frame.Health.AbsorbText.text'),'')
 def test_aura_positions(self):
  l=env();l.execute('''frame=newFrame(); frame.UnitType='ENEMY_NPC'; frame.Health=newFrame(); frame.Name=newFrame(); frame.Level=newFrame(); frame.Elite=newFrame(); frame.Buffs=newFrame(); frame.Debuffs=newFrame(); frame.CrowdControl=newFrame(); frame.LossOfControl=newFrame()
  frame.Buffs.type='buffs'; frame.Debuffs.type='debuffs'; frame.CrowdControl.type='crowdcontrol'; frame.LossOfControl.type='lossofcontrol'
  native={healthBar=newFrame(),name=newFrame(),LevelFrame=newFrame(),ClassificationFrame=newFrame(),AurasFrame={}}
  native.AurasFrame.DebuffListFrame=newFrame(); native.AurasFrame.DebuffListFrame:SetPoint('LEFT',native.healthBar,'LEFT',0,0); native.AurasFrame.DebuffListFrame:SetPoint('BOTTOM',native.name,'TOP',0,8)
  function native.AurasFrame.DebuffListFrame:GetNumPoints() return #self.points end
  function native.AurasFrame.DebuffListFrame:GetPoint(i) return unpack(self.points[i]) end
  function NP:GetSirusUnitFrame() return native end
  NP.db.units.ENEMY_NPC={debuffs={useSirusPosition=true,anchorPoint='LEFT',attachTo='FRAME',xOffset=11,yOffset=12},crowdcontrol={useSirusPosition=false,anchorPoint='RIGHT',attachTo='LEVEL',xOffset=7,yOffset=2}}
  ''')
  code=chunk('ElvUI/Core/Modules/Nameplates/Elements/Auras.lua','local function GetAuraDB','local function ConfigureSirusAuras')
  l.execute(code+' anchor=AnchorSirusAuras; auradb=GetAuraDB; anchor(frame,frame.Debuffs)')
  self.assertEqual(l.eval('#frame.Debuffs.points'),2);self.assertTrue(l.eval('frame.Debuffs.points[1][2]==frame.Health and frame.Debuffs.points[2][2]==frame.Name'))
  l.execute('NP.db.units.ENEMY_NPC.debuffs.useSirusPosition=false; anchor(frame,frame.Debuffs)');self.assertEqual(l.eval('frame.Debuffs.points[1][4]'),11)
  l.execute('anchor(frame,frame.LossOfControl)');self.assertTrue(l.eval('frame.LossOfControl.points[1][2]==frame.Level'))
  self.assertTrue(l.eval('auradb(frame,"lossofcontrol")==NP.db.units.ENEMY_NPC.crowdcontrol'))
 def test_sirus_default_anchors_follow_client(self):
  l=env();l.execute("""frame=newFrame();frame.UnitType='ENEMY_NPC'
  frame.Health=newFrame();frame.Name=newFrame();frame.Level=newFrame();frame.Elite=newFrame()
  native={healthBar=newFrame(),name=newFrame(),LevelFrame=newFrame(),ClassificationFrame=newFrame(),AurasFrame={}}
  NP.db.units.ENEMY_NPC={}
  function NP:GetSirusUnitFrame() return native end
  for key,list in pairs({Buffs='BuffListFrame',Debuffs='DebuffListFrame',CrowdControl='CrowdControlListFrame',LossOfControl='LossOfControlFrame'}) do
   local group=newFrame();group.type=string.lower(key);frame[key]=group
   NP.db.units.ENEMY_NPC[group.type=='lossofcontrol' and 'crowdcontrol' or group.type]={useSirusPosition=true}
   local source=newFrame();native.AurasFrame[list]=source
   function source:GetNumPoints() return #self.points end
   function source:GetPoint(i) return unpack(self.points[i]) end
   source:SetPoint('LEFT',native.healthBar,'RIGHT',3,4)
   source:SetPoint('BOTTOM',native.name,'TOP',5,6)
  end""")
  l.execute(chunk('ElvUI/Core/Modules/Nameplates/Elements/Auras.lua','local function GetAuraDB','local function ConfigureSirusAuras')+' anchor=AnchorSirusAuras')
  for key,listname in [('Buffs','BuffListFrame'),('Debuffs','DebuffListFrame'),('CrowdControl','CrowdControlListFrame'),('LossOfControl','LossOfControlFrame')]:
   with self.subTest(group=key):
    l.execute(f'group=frame.{key};source=native.AurasFrame.{listname};anchor(frame,group)')
    self.assertTrue(l.eval('#group.points==2 and group.points[1][2]==frame.Health and group.points[2][2]==frame.Name'))
    self.assertEqual(l.eval('group.points[2][5]'),6)
    l.execute("source:ClearAllPoints();source:SetPoint('TOP',native.LevelFrame,'BOTTOM',9,13);anchor(frame,group)")
    self.assertTrue(l.eval('#group.points==1 and group.points[1][2]==frame.Level'))
    self.assertEqual(l.eval('group.points[1][5]'),13)
 def test_client_heals_without_lib(self):
  l=env();l.execute('''LibStub=function() error('must not load HealComm') end
   UnitHealth=function() return health end; UnitHealthMax=function() return 100 end
   UnitGetIncomingHeals=function(_,caster) return caster and personal or incoming end
   UnitGetTotalAbsorbs=function() return absorb end; UnitGetTotalHealAbsorbs=function() return healAbsorb end
   oUF={AddElement=function(_,name,update,enable,disable) elem={name=name,update=update,enable=enable,disable=disable} end}; ns={oUF=oUF}
   frame=newFrame(); frame.unit='party1'; frame.HealCommBar={myBar=newFrame(),otherBar=newFrame(),absorbBar=newFrame(),healAbsorbBar=newFrame(),maxOverflow=1}
   health=50; personal=10; incoming=30; absorb=60; healAbsorb=70
  ''')
  code=(ROOT/'ElvUI_Libraries/Core/oUF_Plugins/oUF_SirusHealPrediction/oUF_SirusHealPrediction.lua').read_text();l.execute('local function loadPlugin(...)\n'+code+'\nend; loadPlugin("ElvUI", ns)')
  l.execute('elem.enable(frame); elem.update(frame,"UNIT_HEAL_PREDICTION","party1")')
  self.assertEqual(l.eval('frame.HealCommBar.myBar.value'),10);self.assertEqual(l.eval('frame.HealCommBar.otherBar.value'),20)
  self.assertEqual(l.eval('frame.HealCommBar.absorbBar.value'),60);self.assertEqual(l.eval('frame.HealCommBar.healAbsorbBar.value'),50)
  self.assertTrue(l.eval('frame.events.UNIT_HEAL_PREDICTION'))
  l.execute('personal=80; incoming=120; elem.update(frame,"UNIT_HEAL_PREDICTION","party1")');self.assertEqual(l.eval('frame.HealCommBar.myBar.value'),50)
  l.execute('health=120; elem.update(frame,"UNIT_HEAL_PREDICTION","party1")');self.assertEqual(l.eval('frame.HealCommBar.myBar.value'),0)
  l.execute('elem.disable(frame)');self.assertFalse(l.eval('frame.HealCommBar.myBar.shown'));self.assertIsNone(l.eval('frame.events.UNIT_HEAL_PREDICTION'))
 def test_custom_lifecycle(self):
  l=env();load_finalized_tags(l)
  self.assertIsNone(l.eval('E.oUF.Private'))
  l.execute("""NP.db.units.ENEMY_NPC={customTexts={test={enable=true,text_format='[name]',font='font',size=12,position='CENTER',attachTextTo='Health'}}}
  frame=newFrame(); frame.UnitType='ENEMY_NPC'; frame.unit='nameplate1'; frame.Health=newFrame(frame); unitGUIDs.nameplate1='NPC'
  """)
  l.execute((ROOT/'ElvUI/Core/Modules/Nameplates/Elements/CustomText.lua').read_text());l.execute('NP:Configure_CustomTexts(frame)')
  self.assertEqual(l.eval('frame.customTexts.test.text'),'nameplate1')
  l.execute('NP:Clear_CustomTexts(frame)');self.assertIsNone(l.eval('frame.customTexts.test.UpdateTag'));self.assertFalse(l.eval('frame.customTexts.test.shown'))
  l.execute('frame.unit="nameplate2"; unitGUIDs.nameplate2="OTHER"; NP:Configure_CustomTexts(frame)');self.assertEqual(l.eval('frame.customTexts.test.text'),'nameplate2')
  l.execute('NP.db.units.ENEMY_NPC.customTexts={}; NP:Configure_CustomTexts(frame)');self.assertFalse(l.eval('frame.customTexts.test.shown'))
 def test_empty_custom_texts_after_finalization(self):
  l=env();load_finalized_tags(l)
  l.execute("""NP.db.units.ENEMY_NPC={customTexts={}}
  frame=newFrame(); frame.UnitType='ENEMY_NPC'; frame.Health=newFrame(frame)
  """)
  l.execute((ROOT/'ElvUI/Core/Modules/Nameplates/Elements/CustomText.lua').read_text());l.execute('NP:Configure_CustomTexts(frame); NP:Clear_CustomTexts(frame)')
  self.assertIsNone(l.eval('E.oUF.Private'))
  self.assertEqual(l.eval('type(frame.Tag)'),'function')
  self.assertEqual(l.eval('type(frame.UpdateTags)'),'function')
 def test_actual_ouf_tags(self):
  l=env();load_finalized_tags(l)
  l.execute("""E.oUF.Tags.Methods.grad=function() return ColorGradient(80,100,0,0,0,1,1,1) end
  E.oUF.Tags.Methods.test=function(u) return UnitName(u) end
  NP.db.units.ENEMY_NPC={customTexts={test={text_format='[test]: [curhp]/[maxhp] [grad]',font='font',size=12}}}
  frame=newFrame(); frame.Health=newFrame(frame); frame.UnitType='ENEMY_NPC'; frame.unit='nameplate1';unitGUIDs.nameplate1='NPC'
  """)
  l.execute((ROOT/'ElvUI/Core/Modules/Nameplates/Elements/CustomText.lua').read_text());l.execute('NP:Configure_CustomTexts(frame)')
  self.assertEqual(l.eval('frame.customTexts.test.text'),'nameplate1: 80/100 0.8')
  l.execute('NP:Clear_CustomTexts(frame)');self.assertIsNone(l.eval('frame.customTexts.test.UpdateTag'))
  l.execute('frame.unit="nameplate2"; unitGUIDs.nameplate2="OTHER"; NP:Configure_CustomTexts(frame)')
  self.assertEqual(l.eval('frame.customTexts.test.text'),'nameplate2: 80/100 0.8')
 def test_plugin_runtime_recycle(self):
  if not (PLUGIN/"Core/Core.lua").exists(): self.skipTest("Clone ElvUI_DmgAtNameplates alongside ElvUI to test plugin integration")
  l=env();l.execute("""DAN={}; E.db={DmgAtNameplates={enable=true,font='font',fontSize=20,fontOutline='OUTLINE',duration=1,showIcon=false,textFormat='none',showDmgToEnemy=true,playerToTargetDamageText=true,showFromAnotherPlayer=true}}
  E.Libs.EP={RegisterPlugin=function() end}; function E:GetModule(k) return k=='DmgAtNameplates' and DAN or NP end
  function E:RegisterModule() end
  LibStub=function() return {} end; bit={band=function(a,b) local r,p=0,1 while a>0 and b>0 do if a%2==1 and b%2==1 then r=r+p end a=math.floor(a/2);b=math.floor(b/2);p=p*2 end return r end}
  COMBATLOG_OBJECT_TYPE_PLAYER=1; COMBATLOG_OBJECT_TYPE_NPC=2; COMBATLOG_OBJECT_REACTION_FRIENDLY=4; COMBATLOG_OBJECT_REACTION_HOSTILE=8; COMBATLOG_OBJECT_REACTION_NEUTRAL=16; COMBATLOG_OBJECT_TYPE_PET=32; COMBATLOG_OBJECT_TYPE_GUARDIAN=64; COMBATLOG_OBJECT_AFFILIATION_MINE=128
  SCHOOL_MASK_PHYSICAL=1; SCHOOL_MASK_HOLY=2; SCHOOL_MASK_FIRE=4; SCHOOL_MASK_NATURE=8; SCHOOL_MASK_FROST=16; SCHOOL_MASK_SHADOW=32; SCHOOL_MASK_ARCANE=64
  UIParent=newFrame(); GetTime=function() return 0 end
  frame=newFrame();frame.guid='NPC';frame.unit='nameplate1';frame.Health=newFrame(frame);unitGUIDs.nameplate1='NPC';NP.VisiblePlates[frame]=1
  function DAN:RegisterEvent() end; function DAN:UnregisterEvent() end; function DAN:GetName() return 'DmgAtNameplates' end
  """)
  l.execute((PLUGIN/'Core/Core.lua').read_text());l.execute('DAN.db=E.db.DmgAtNameplates; DAN:PLAYER_ENTERING_WORLD()')
  l.execute('DAN.DmgTextFrame.scripts.OnEvent(DAN.DmgTextFrame,"COMBAT_LOG_EVENT_UNFILTERED",1,"SPELL_DAMAGE","PLAYER","player",1,"NPC","mob",10,123,"Spell",1,25,0,0,0,0,0,false)')
  self.assertIsNotNone(l.eval('DAN.DmgTextFrame.scripts.OnUpdate'))
  l.execute('frame.guid="OTHER"; DAN.DmgTextFrame.scripts.OnUpdate()')
  # All old text was discarded; a second tick stops the animation driver.
  l.execute('DAN.DmgTextFrame.scripts.OnUpdate()');self.assertIsNone(l.eval('DAN.DmgTextFrame.scripts.OnUpdate'))
  l.execute('DAN:OnDisable()');self.assertIsNone(l.eval('DAN.DmgTextFrame.events.COMBAT_LOG_EVENT_UNFILTERED'))
 def test_plugin_lookup(self):
  if not (PLUGIN/"Core/Core.lua").exists(): self.skipTest("Clone ElvUI_DmgAtNameplates alongside ElvUI to test plugin integration")
  l=env();l.execute('DAN={}; NP.VisiblePlates={}; frame=newFrame(); frame.guid="NPC"; frame.unit="nameplate1"; unitGUIDs.nameplate1="NPC"; NP.VisiblePlates[frame]=1')
  s=(PLUGIN/'Core/Core.lua').read_text();a=s.index('local platesByGUID');b=s.index('function DAN:GetFrame',a);l.execute(s[a:b])
  self.assertTrue(l.eval('DAN:GetNameplateFrame("NPC")==frame'))
  l.execute('frame.shown=false');self.assertIsNone(l.eval('DAN:GetNameplateFrame("NPC")'))
  l.execute('frame.shown=true; unitGUIDs.nameplate1="OTHER"');self.assertIsNone(l.eval('DAN:GetNameplateFrame("NPC")'))
  l.execute('NP.VisiblePlates=nil; NP.PlateGUID={NPC=frame}; frame.unit=nil');self.assertTrue(l.eval('DAN:GetNameplateFrame("NPC")==frame'))

if __name__=='__main__': unittest.main(verbosity=2)
