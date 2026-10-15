from pathlib import Path
import unittest
from test_sirus_regressions import env
ROOT=Path(__file__).resolve().parents[1]
class MerchantWithoutSkin(unittest.TestCase):
 def setup_ui(self):
  l=env();l.execute('''
  E.private={skins={blizzard={enable=false,merchant=false}}};MerchantFrame={selectedTab=1};alt=true;shift=false;ctrl=false;repair=false
  function IsAltKeyDown() return alt end;function IsShiftKeyDown() return shift end;function IsControlKeyDown() return ctrl end
  function InRepairMode() return repair end;function GetCursorInfo() return cursor end
  function GetItemInfo() return 'item',nil,nil,nil,nil,nil,nil,20 end
  function GetMerchantItemLink() return 'item:1' end
  function GetMerchantItemInfo() return 'item',nil,10,1,-1,nil,false end
  function GetMerchantItemMaxStack() return 1 end;function GetMoney() return 1000 end
  function BuyMerchantItem(_,quantity) purchases=(purchases or 0)+1;bought=quantity end
  function MerchantItemButton_OnEnter() entered=true end
  GameTooltip=newFrame();function GameTooltip:SetMerchantItem() end
  MERCHANT_HIGH_PRICE_COST=1500000
  MerchantItem1ItemButton=newFrame();local b=MerchantItem1ItemButton
  function b:GetID() return 1 end
  function b:GetScript(name) return self.scripts[name] end
  b:SetScript('OnClick',function() native=(native or 0)+1 end)
  local base=CreateFrame
  function CreateFrame(...)
   local f=base(...)
   function f:SetAllPoints(owner) self.owner=owner end
   function f:RegisterForClicks(...) self.clicks={...} end
   function f:EnableMouse(value) self.mouse=value end
   return f
  end
  ''')
  l.execute((ROOT/'ElvUI/Core/Modules/Misc/Merchant.lua').read_text())
  l.execute('watcher=frames[#frames];watcher.scripts.OnEvent(watcher,"MERCHANT_SHOW");overlay=MerchantItem1ItemButton.elvAltStackButton')
  return l
 def test_disabled_skins_still_buy_once_and_install_once(self):
  l=self.setup_ui();l.execute('overlay.scripts.OnClick(overlay,"LeftButton")')
  self.assertEqual(l.eval('bought'),20);self.assertEqual(l.eval('purchases'),1);self.assertIsNone(l.eval('native'))
  l.execute('before=#frames;watcher.scripts.OnEvent(watcher,"MERCHANT_SHOW")');self.assertEqual(l.eval('#frames'),l.eval('before'))
 def test_normal_click_modifiers_repair_and_buyback_are_preserved(self):
  for state in ('alt=false','shift=true','ctrl=true','repair=true','MerchantFrame.selectedTab=2','cursor="item"'):
   with self.subTest(state=state):
    l=self.setup_ui();l.execute(state+';watcher.scripts.OnEvent(watcher,"MODIFIER_STATE_CHANGED");overlay.scripts.OnClick(overlay,"RightButton")')
    self.assertEqual(l.eval('native'),1);self.assertIsNone(l.eval('purchases'))
 def test_original_script_and_tooltip_are_untouched(self):
  l=self.setup_ui();l.execute('overlay.scripts.OnEnter();overlay.scripts.OnLeave();MerchantItem1ItemButton.scripts.OnClick()')
  self.assertTrue(l.eval('entered'));self.assertEqual(l.eval('native'),1)
 def test_core_xml_loads_functionality_outside_skins(self):
  self.assertIn("file='Merchant.lua'",(ROOT/'ElvUI/Core/Modules/Misc/Load_Misc.xml').read_text())
  self.assertNotIn('AltStackBuy',(ROOT/'ElvUI/Core/Modules/Skins/Blizzard/Merchant.lua').read_text())
