from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET
from test_sirus_regressions import env,ROOT,chunk

NS={'u':'http://www.blizzard.com/wow/ui/'}

def setup():
 l=env();l.execute('''S={};E.private={skins={blizzard={enable=true,friends=true}}}
 function E:UnlockPoints(f) f.unlocked=(f.unlocked or 0)+1 end
 function E:LockPoints(f) f.lockedPoints=(f.lockedPoints or 0)+1 end
 function S:HandleNextPrevButton(f) f:SetSize(22,22) end
 function S:ApplyElvUIFont(f) end
 local base=newFrame
 function newFrame(parent,name)
  local f=base(parent);f.name=name
  function f:GetName() return self.name end
  function f:SetPoint(point,relative,relativePoint,x,y)
   if type(relative)=='number' then x,y,relative,relativePoint=relative,relativePoint,self:GetParent(),point
   elseif type(relativePoint)=='number' then x,y,relativePoint=relativePoint,x,point end
   relative=relative or self:GetParent();relativePoint=relativePoint or point
   for i,p in ipairs(self.points) do if p[1]==point then table.remove(self.points,i);break end end
   table.insert(self.points,{point,relative,relativePoint,x or 0,y or 0})
  end
  f.Point=f.SetPoint
  function f:StripTextures() self.stripped=true end
  function f:StyleButton() self.styled=true end
  function f:GetFontString() return self.Text end
  function f:CreateBackdrop() self.backdrop=newFrame(self) end
  function f:OffsetFrameLevel(v) self:SetFrameLevel(self:GetFrameLevel()+v) end
  function f:SetHitRectInsets(...) self.hitInsets={...} end
  -- Resolve the horizontal anchor constraints used by this layout. Width
  -- setters do not override opposing anchors, as with native UI regions.
  function f:GetLeft()
   for _,p in ipairs(self.points) do
    if p[1]:find('LEFT') then return (p[3]:find('RIGHT') and p[2]:GetRight() or p[2]:GetLeft())+(p[4] or 0) end
   end
   for _,p in ipairs(self.points) do
    if p[1]:find('RIGHT') then return (p[3]:find('LEFT') and p[2]:GetLeft() or p[2]:GetRight())+(p[4] or 0)-self.width end
   end
   return self.left or 0
  end
  function f:GetRight()
   for _,p in ipairs(self.points) do
    if p[1]:find('RIGHT') then return (p[3]:find('LEFT') and p[2]:GetLeft() or p[2]:GetRight())+(p[4] or 0) end
   end
   return self:GetLeft()+self.width
  end
  function f:GetWidth() return self:GetRight()-self:GetLeft() end
  if name then _G[name]=f end
  return f
 end
 function GetChild(frame,name,key) return _G[name..key] end
 WhoFrame=newFrame(nil,'WhoFrame')
 ''')
 root=ET.parse(ROOT/'tests/fixtures/sirus_who_layout.xml').getroot()
 for header in root.findall('u:Frame/u:Frames/u:Button',NS):
  name=header.get('name');width=int(re.search(r'WhoFrameColumn_SetWidth\(self, (\d+)\)',header.find('u:Scripts/u:OnLoad',NS).text)[1])
  l.execute(f'{name}=newFrame(WhoFrame,"{name}");{name}:SetWidth({width});{name}:SetHeight(24);{name}.Text=newFrame({name});{name}Middle=newFrame({name})')
  anchor=header.find('u:Anchors/u:Anchor',NS)
  relative=anchor.get('relativeTo','WhoFrame');point=anchor.get('point');relpoint=anchor.get('relativePoint',point)
  l.execute(f'{name}:SetPoint("{point}",{relative},"{relpoint}",{anchor.get("x","0")},{anchor.get("y","0")})')
 l.execute('''WhoFrameDropDown=newFrame(WhoFrameColumnHeader2,'WhoFrameDropDown');WhoFrameDropDownButton=newFrame(WhoFrameDropDown,'WhoFrameDropDownButton');WhoFrameDropDownText=newFrame(WhoFrameDropDown,'WhoFrameDropDownText');WhoFrameDropDownMiddle=newFrame(WhoFrameDropDown,'WhoFrameDropDownMiddle')
 WhoFrameDropDown:SetPoint('TOPLEFT',WhoFrameColumnHeader2,'TOPLEFT',-15,0)
 ''')
 l.execute((ROOT/'tests/fixtures/sirus_who_width.lua').read_text())
 l.execute('UIDropDownMenu_SetWidth(WhoFrameDropDown,80)')
 l.execute(chunk('ElvUI/Core/Modules/Skins/Skins.lua','function S:HandleDropDownBox(', 'function S:HandleStatusBar'))
 s=(ROOT/'ElvUI/Core/Modules/Skins/Blizzard/Friends.lua').read_text();l.execute(s[:s.index('local function LoadSkin()')].replace('local S = E:GetModule("Skins")','local S = S')+' skinDropdown=SkinWhoDropDown')
 # Run the exact header skinning block, not a replacement implementation.
 a=s.index('for i = 1, 5 do');b=s.index('for i = 1, 17 do',a);l.execute(s[a:b])
 return l

class WhoColumnLayout(unittest.TestCase):
 def assert_bounds(self,l):
  self.assertTrue(l.eval('WhoFrameDropDown.backdrop:GetLeft()>=WhoFrameColumnHeader5:GetRight()'))
  self.assertTrue(l.eval('WhoFrameDropDown.backdrop:GetRight()<=WhoFrameColumnHeader3:GetLeft()'))
  self.assertTrue(l.eval('WhoFrameDropDownText:GetLeft()>=WhoFrameDropDown.backdrop:GetLeft()'))
  self.assertTrue(l.eval('WhoFrameDropDownText:GetRight()<WhoFrameDropDownButton:GetLeft()'))
  self.assertTrue(l.eval('WhoFrameDropDownButton:GetRight()<=WhoFrameDropDown.backdrop:GetRight()'))
  self.assertGreater(l.eval('WhoFrameDropDownText:GetWidth()'),60)
 def test_initial_dropdown_is_inside_its_column(self):
  l=setup();l.execute('skinDropdown()');self.assert_bounds(l)
  self.assertEqual(l.eval('WhoFrameDropDownButton.width'),16)
  self.assertEqual(l.eval('WhoFrameDropDownButton.unlocked'),2);self.assertEqual(l.eval('WhoFrameDropDownButton.lockedPoints'),2)
 def test_client_width_changes_cannot_expand_control_over_neighbours(self):
  l=setup();l.execute('skinDropdown()')
  for width,native_width in [(110,90),(100,80),(110,90),(100,80)]:
   l.execute(f'WhoFrameColumn_SetWidth(WhoFrameColumnHeader2,{width});UIDropDownMenu_SetWidth(WhoFrameDropDown,{native_width})')
   self.assert_bounds(l);self.assertEqual(l.eval('WhoFrameDropDown:GetWidth()'),width-4)
 def test_long_selected_text_is_bounded_without_wrapping(self):
  l=setup();l.execute('skinDropdown()')
  for text in ('Игровая зона','Гильдия','Раса','Категория','Рейтинг подземелий','Very long localized column label'):
   l.globals().label=text;l.execute('WhoFrameDropDownText:SetText(label)');self.assert_bounds(l)
   self.assertFalse(l.eval('WhoFrameDropDownText.wordWrap'))
 def test_all_headers_have_bounded_single_line_text(self):
  l=setup();l.execute('skinDropdown()')
  for i in range(1,6):
   h=f'WhoFrameColumnHeader{i}'
   self.assertEqual(l.eval(h+'.Text:GetWidth()'),l.eval(h+':GetWidth()')-8)
   self.assertFalse(l.eval(h+'.Text.wordWrap'));self.assertEqual(l.eval(h+'.Text.justifyH'),'LEFT')
  self.assertEqual(l.eval('WhoFrameColumnHeader5:GetWidth()'),38)
 def test_native_decorative_padding_reproduces_overlap(self):
  l=setup();l.execute('S:HandleDropDownBox(WhoFrameDropDown,120);WhoFrameDropDown.backdrop:Point("TOPLEFT",8,-2);WhoFrameColumn_SetWidth(WhoFrameColumnHeader2,110);UIDropDownMenu_SetWidth(WhoFrameDropDown,90)')
  self.assertTrue(l.eval('WhoFrameDropDown.backdrop:GetLeft()<WhoFrameColumnHeader5:GetRight()'))
  self.assertTrue(l.eval('WhoFrameDropDown.backdrop:GetRight()>WhoFrameColumnHeader3:GetLeft()'))
 def test_skin_does_not_replace_sorting_or_menu_handlers(self):
  l=setup();l.execute('''local function native() end;WhoFrameDropDown:SetScript('OnMouseUp',native);WhoFrameDropDownButton:SetScript('OnClick',native);original=native;skinDropdown()''')
  self.assertTrue(l.eval('WhoFrameDropDown:GetScript("OnMouseUp")==original and WhoFrameDropDownButton:GetScript("OnClick")==original'))
 def test_missing_optional_dropdown_does_not_error(self):
  l=setup();l.execute('WhoFrameDropDown=nil;skinDropdown()')

if __name__=='__main__':unittest.main()
