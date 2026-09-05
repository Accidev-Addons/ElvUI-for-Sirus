local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local ipairs = ipairs
local find = string.find
local hooksecurefunc = hooksecurefunc
local pairs = pairs
local wipe, select = wipe, select
local GetInventoryItemLink = GetInventoryItemLink
local GetItemGem = GetItemGem
local SocketInventoryItem = SocketInventoryItem
local SendServerMessage = SendServerMessage
local GetItemInfo = GetItemInfo
local C_Item = C_Item
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemLink = GetContainerItemLink
local PickupContainerItem = PickupContainerItem
local GetSocketTypes = GetSocketTypes
local ClickSocketButton = ClickSocketButton
local AcceptSockets = AcceptSockets
local HideUIPanel = HideUIPanel
local GameTooltip = GameTooltip
local GameTooltip_Hide = GameTooltip_Hide
local CreateFrame = CreateFrame
local UIParent = UIParent
local strmatch = string.match
local gsub = string.gsub
local sub = string.sub
local strtrim = strtrim
local utf8sub = utf8.sub
local lower = string.lower

local ENCHANT_TEXT_MAX_LENGTH = 20
local MAX_DISPLAYED_SOCKETS = 3
local SOCKET_SIZE, SOCKET_STEP = 14, 15

local GEM_CLASS, META_GEM_SUBCLASS = 3, 6

local SOCKET_COLORS = {
	[lower(EMPTY_SOCKET_RED or "")] = { 1, .11, .08, .5 },
	[lower(EMPTY_SOCKET_YELLOW or "")] = { 1, .95, .08, .5 },
	[lower(EMPTY_SOCKET_BLUE or "")] = { .08, .26, 1, .5 },
	[lower(EMPTY_SOCKET_META or "")] = { 1, 1, 1, 1 },
	[lower(EMPTY_SOCKET_NO_COLOR or "")] = { .99, .15, .9, .5 },
}

local function HideAtlasTexture(texture)
	hooksecurefunc(texture, "SetAtlas", function(self)
		self:SetAlpha(0)
	end)
	texture:SetAlpha(0)
end

local function GetElement(frame, key)
	return frame[key] or (frame.GetName and _G[frame:GetName()..key])
end

function S:UpdateTemplateScale(frame)
	if not frame or not frame.template or not frame.GetEffectiveScale then return end

	local scale = frame:GetEffectiveScale()
	if not scale or scale <= 0 or frame.templateScale == scale then return end

	frame.templateScale = scale

	frame:SetTemplate(frame.template, frame.glossTex, frame.ignoreUpdates, frame.forcePixelMode, frame.isUnitFrameElement, frame.isNamePlateElement)
end

function S:HandleSirusPortrait(frame)
	if not frame then return end

	local titleText = GetElement(frame, "TitleText")
	if not titleText then return end

	local overlay = GetElement(frame, "PortraitOverlay")
	if overlay then
		overlay:SetAlpha(1)

		if overlay.portrait then overlay.portrait:SetAlpha(0) end
		if frame.portraitFrame then frame.portraitFrame:SetAlpha(0) end
	end

	titleText:Show()
	titleText:SetAlpha(1)
	titleText:FontTemplate(nil, nil, "NONE")
	titleText:SetTextColor(1, 1, 1)

	if overlay and titleText.GetParent and titleText:GetParent() == overlay then
		titleText:ClearAllPoints()
		titleText:SetPoint("TOP", frame, "TOP", 0, -5)
		titleText:SetJustifyH("CENTER")
	end
end

function S:HandleSirusFrame(frame, createBackdrop, noStrip)
	if not frame then return end

	S:HandlePortraitFrame(frame, createBackdrop, noStrip)
	S:HandleSirusPortrait(frame)

	if not noStrip then
		for _, key in next, { "Background", "Background2" } do
			local object = GetElement(frame, key)
			if object and object.IsObjectType and object:IsObjectType("Texture") then
				HideAtlasTexture(object)
			end
		end

		for _, key in next, { "InsetLeft", "InsetRight", "LeftInset", "RightInset" } do
			local object = GetElement(frame, key)
			if object and object ~= frame then
				object:StripTextures()
			end
		end
	end
end

function S:DisableFrameInteraction(frame)
	if not frame then return end
	frame:Hide()
	frame:SetAlpha(0)
	frame:EnableMouse(false)
	frame:SetHitRectInsets(0, 0, 0, 0)
	frame:SetScript("OnShow", function(self)
		self:Hide()
	end)
end

local function ReplacePlain(text, search, replacement)
	local start = find(text, search, 1, true)
	while start do
		text = sub(text, 1, start - 1)..replacement..sub(text, start + #search)
		start = find(text, search, start + #replacement, true)
	end
	return text
end

local function ShortenEnchantText(text)
	if not text then return end

	text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = gsub(text, "|r", "")
	text = lower(text)
	text = gsub(text, "^зачарование:%s*", "")
	text = gsub(text, "^зачаровано:%s*", "")
	text = gsub(text, "\194\160", " ")
	text = gsub(text, "%s+", " ")
	text = strtrim(text)
	text = gsub(text, "^%s*([0-9]+)%s*", "%1 ")
	text = gsub(text, "[Ии]%s+увеличение скорости передвижения на%s+(%d+%%%s*)", " и %1 бег")
	text = gsub(text, "увеличение скорости передвижения на%s+(%d+%%%s*)", "%1 бег")
	text = gsub(text, "снижение угрозы на%s+(%d+%%%s*)", "-%1 угрозы")

	local replacements = {
		{"к силе заклинаний", "спд"},
		{"к силе заклинания", "спд"},
		{"силе заклинаний", "спд"},
		{"силе заклинания", "спд"},
		{"сила заклинаний", "спд"},
		{"сила заклинания", "спд"},
		{"к проникающей способности заклинаний", "пен"},
		{"проникающей способности заклинаний", "пен"},
		{"к силе атаки", "са"},
		{"силе атаки", "са"},
		{"к критическому удару", "крит"},
		{"к рейтингу критического удара", "крит"},
		{"рейтингу критического удара", "крит"},
		{"к рейтингу критического эффекта", "крит"},
		{"рейтингу критического эффекта", "крит"},
		{"к пробиванию брони", "рпб"},
		{"к рейтингу пробивания брони", "рпб"},
		{"рейтингу пробивания брони", "рпб"},
		{"к устойчивости", "уст"},
		{"к рейтингу устойчивости", "уст"},
		{"рейтингу устойчивости", "уст"},
		{"к меткости", "метк"},
		{"к рейтингу меткости", "метк"},
		{"рейтингу меткости", "метк"},
		{"к скорости", "скор"},
		{"к рейтингу скорости", "скор"},
		{"рейтингу скорости", "скор"},
		{"к мастерству", "маст"},
		{"к рейтингу мастерства", "маст"},
		{"рейтингу мастерства", "маст"},
		{"к защите", "защ"},
		{"к рейтингу защиты", "защ"},
		{"рейтингу защиты", "защ"},
		{"к выносливости", "вын"},
		{"к выносливость", "вын"},
		{"выносливости", "вын"},
		{"выносливость", "вын"},
		{"к ловкости", "лов"},
		{"ловкость", "лов"},
		{"к интеллекту", "инт"},
		{"интеллект", "инт"},
		{"к духу", "дух"},
		{"к броне", "бр"},
		{"броня", "бр"},
		{"к сопротивлению", "сопр"},
		{"сопротивление", "сопр"},
		{"ко всем характеристикам", "ко всем"},
		{"ед. маны каждые 5 секунд", "мп5"},
		{"маны каждые 5 секунд", "мп5"},
	}

	for _, replacement in ipairs(replacements) do
		text = ReplacePlain(text, replacement[1], replacement[2])
	end

	text = ReplacePlain(text, "заклинаний", "спд")
	text = ReplacePlain(text, "заклинания", "спд")
	text = ReplacePlain(text, "устойчивости", "уст")
	text = ReplacePlain(text, "увеличение скорости передвижения на", "бег")
	local bombText = lower(text)
	if find(bombText, "отцепить от пояса", 1, true) and find(bombText, "кобальтов", 1, true) and find(bombText, "бомб", 1, true) then
		return "бомбы"
	end
	text = ReplacePlain(text, "отцепить от пояса и бросить кобальтовую осколочную бомбу", "бомбы")
	text = ReplacePlain(text, "бомбы, которая нано", "бомбы")
	text = ReplacePlain(text, "дар собирателя", "дар собирателя")
	text = ReplacePlain(text, "использование:", "")

	text = strtrim(gsub(text, "%s+", " "))
	local number, suffix = strmatch(text, "^([^0-9]*%d+)(.*)$")
	if number then
		return number..suffix
	end
	return utf8sub(text, 1, ENCHANT_TEXT_MAX_LENGTH)
end

local function StripColor(text)
	return strtrim(gsub(gsub(text, "|c%x%x%x%x%x%x%x%x", ""), "|r", ""))
end

local function MatchEnchant(line, text, plain, slotName)
	if find(plain, "зачаров", 1, true) then
		return text
	elseif slotName == "NeckSlot" and find(plain, "дар собирателя", 1, true) then
		return "Дар собирателя"
	elseif slotName == "WaistSlot" and find(plain, "использование:", 1, true) then
		return text
	elseif find(text, "^%+") then
		local r, g, b = line:GetTextColor()
		if E:Round(r, 2) == 0 and E:Round(g, 2) == 1 and E:Round(b, 2) == 0 then
			return text
		end
	end
end

local function Socket_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	if self.gemLink then
		GameTooltip:SetHyperlink(self.gemLink)
		if self.canRemove then
			GameTooltip:AddLine(L["<Click to extract the gem>"], 0, .8, 1)
		end
	else
		GameTooltip:SetText(self.lineText, 1, 1, 1)
		if self.isEmpty then
			GameTooltip:AddLine(L["<Click to insert a black diamond>"], 0, .8, 1)
		end
	end

	GameTooltip:Show()
end

local function FindBlackDiamond(isMeta)
	local bestBag, bestSlot, bestLevel
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local _, _, quality, level, _, _, _, _, _, _, _, _, classID, subClassID = C_Item.GetItemInfo(link)
				if quality == 5 and classID == GEM_CLASS and (subClassID == META_GEM_SUBCLASS) == isMeta and (not bestLevel or level > bestLevel) then
					bestBag, bestSlot, bestLevel = bag, slot, level
				end
			end
		end
	end

	return bestBag, bestSlot
end

local function Socket_OnClick(self)
	if self.gemLink then
		if self.canRemove then
			SendServerMessage("ACMSG_REMOVE_SOCKET_FROM_ITEM", -1, self.inventorySlot, self.index)
		end
	elseif self.isEmpty then
		SocketInventoryItem(self.inventorySlot)

		local bag, slot = FindBlackDiamond(GetSocketTypes(self.index) == "Meta")
		if bag then
			PickupContainerItem(bag, slot)
			ClickSocketButton(self.index)
			AcceptSockets()
			HideUIPanel(_G.ItemSocketingFrame)
		end
	end
end

local function CreateSocket(info, index, anchor)
	local socket = CreateFrame("Button", nil, info)
	socket:SetSize(SOCKET_SIZE, SOCKET_SIZE)
	socket:SetTemplate("Default")
	socket:RegisterForClicks("LeftButtonUp")
	socket:SetScript("OnEnter", Socket_OnEnter)
	socket:SetScript("OnLeave", GameTooltip_Hide)
	socket:SetScript("OnClick", Socket_OnClick)
	socket.index = index

	socket.Icon = socket:CreateTexture(nil, "ARTWORK")
	socket.Icon:SetInside()

	local offset = (index - 1) * SOCKET_STEP
	if anchor == "RIGHT" then
		socket:SetPoint("LEFT", info.socketRow, "LEFT", offset, 0)
	elseif anchor == "LEFT" then
		socket:SetPoint("RIGHT", info.socketRow, "RIGHT", -offset, 0)
	end

	return socket
end

local function CreateSocketInfo(slotFrame, anchor, slotName)
	local info = CreateFrame("Frame", nil, slotFrame)
	info:SetFrameLevel(slotFrame:GetFrameLevel() + 1)
	info:SetSize(220, anchor == "TOP" and 46 or 31)
	info.slots = {}
	info.anchor = anchor

	info.socketRow = CreateFrame("Frame", nil, info)
	info.socketRow:SetSize(SOCKET_STEP * MAX_DISPLAYED_SOCKETS, SOCKET_STEP)
	info.enchant = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	info.enchant:SetTextColor(0.1, 1, 0.1)
	info.enchant:SetWordWrap(false)
	info.enchant:SetSize(220, 14)

	if anchor == "TOP" then
		info.socketRow:SetPoint("BOTTOM", slotFrame, "TOP", 0, 3)

		if slotName == "MainHandSlot" then
			info:SetPoint("TOPRIGHT", slotFrame, "BOTTOMLEFT", -3, -3)
			info.enchant:SetJustifyH("RIGHT")
			info.enchant:SetPoint("BOTTOMRIGHT", slotFrame, "BOTTOMLEFT", -3, 1)
		elseif slotName == "SecondaryHandSlot" then
			info:SetPoint("TOPLEFT", slotFrame, "BOTTOMRIGHT", 3, -3)
			info.enchant:SetJustifyH("LEFT")
			info.enchant:SetPoint("TOPLEFT", slotFrame, "TOPRIGHT", slotFrame:GetWidth() + 8, -3)
		elseif slotName == "RangedSlot" then
			info:SetPoint("BOTTOM", slotFrame, "TOP", 0, 4)
			info.enchant:SetJustifyH("LEFT")
			info.enchant:SetPoint("BOTTOMLEFT", slotFrame, "BOTTOMRIGHT", 3, -3)
		else
			info:SetPoint("BOTTOM", slotFrame, "TOP", 0, 4)
			info.enchant:SetJustifyH("CENTER")
			info.enchant:SetPoint("BOTTOM", info.socketRow, "TOP", 0, 1)
		end
	else
		if anchor == "RIGHT" then
			info:SetPoint("LEFT", slotFrame, "RIGHT", 3, 0)
			info.socketRow:SetPoint("LEFT", slotFrame, "RIGHT", 3, -3)
			info.enchant:SetJustifyH("LEFT")
			info.enchant:SetPoint("BOTTOMLEFT", info.socketRow, "TOPLEFT", 0, 1)
		else
			info:SetPoint("RIGHT", slotFrame, "LEFT", -3, 0)
			info.socketRow:SetPoint("RIGHT", slotFrame, "LEFT", -3, -3)
			info.enchant:SetJustifyH("RIGHT")
			info.enchant:SetPoint("BOTTOMRIGHT", info.socketRow, "TOPRIGHT", 0, 1)
		end
	end

	for index = 1, MAX_DISPLAYED_SOCKETS do
		info.slots[index] = CreateSocket(info, index, anchor)
	end

	return info
end

local function SetSocket(socket, inventorySlot, link, texture, lineText, socketColor)
	local gemLink = not socketColor and select(2, GetItemGem(link, socket.index))
	local quality = gemLink and select(3, GetItemInfo(gemLink))

	socket.inventorySlot = inventorySlot
	socket.isEmpty = socketColor ~= nil
	socket.gemLink = gemLink or nil
	socket.canRemove = quality == 5
	socket.lineText = lineText

	if socketColor then
		socket.Icon:SetTexture(E.Media.Textures.NormTex2)
		socket.Icon:SetTexCoord(0, 1, 0, 1)
		socket.Icon:SetVertexColor(unpack(socketColor))
	else
		socket.Icon:SetTexture(texture)
		socket.Icon:SetTexCoord(unpack(E.TexCoords))
		socket.Icon:SetVertexColor(1, 1, 1, 1)
	end

	socket:Show()
end

local gemLines = {}
function S:HandleSirusEquipmentSocketInfo(slotFrame, inventorySlot, anchor, slotName)
	if not slotFrame or not inventorySlot then return end

	local info = slotFrame.sirusSocketInfo
	if not info then
		info = CreateSocketInfo(slotFrame, anchor or "RIGHT", slotName)
		slotFrame.sirusSocketInfo = info
	end

	local db = E.db.general.characterInfo
	local link = GetInventoryItemLink("player", inventorySlot)
	local numSockets, enchantText = 0

	if link and (db.showGems or db.showEnchants) then
		local tooltip = E.ScanTooltip
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetInventoryItem("player", inventorySlot)
		tooltip:Show()

		for index = 1, 10 do
			local texture = _G["ElvUI_ScanTooltipTexture"..index]
			if texture and texture:IsShown() then
				local _, relativeTo = texture:GetPoint(1)
				gemLines[relativeTo] = texture:GetTexture()
			end
		end

		for index = 1, tooltip:NumLines() do
			local line = _G["ElvUI_ScanTooltipTextLeft"..index]
			local text = line:GetText()
			if text then
				local texture = gemLines[line]
				local plain = StripColor(text)
				local socketColor = SOCKET_COLORS[lower(plain)]

				if texture or socketColor then
					if db.showGems and numSockets < MAX_DISPLAYED_SOCKETS then
						numSockets = numSockets + 1
						SetSocket(info.slots[numSockets], inventorySlot, link, texture, plain, socketColor)
					end
				elseif db.showEnchants and not enchantText then
					enchantText = MatchEnchant(line, plain, lower(plain), slotName)
				end
			end
		end

		tooltip:Hide()
		wipe(gemLines)
	end

	for index = numSockets + 1, MAX_DISPLAYED_SOCKETS do
		info.slots[index]:Hide()
	end

	if info.anchor == "TOP" then
		for index = 1, numSockets do
			info.slots[index]:SetPoint("CENTER", info.socketRow, "CENTER", (index - (numSockets + 1) / 2) * SOCKET_STEP, 0)
		end
	end

	enchantText = enchantText and ShortenEnchantText(enchantText)
	info.enchant:SetText(enchantText)
	info.enchant:SetShown(enchantText ~= nil)
	info:SetShown(numSockets > 0 or enchantText ~= nil)
end

function S:HandleSirusScrollFrame(scrollFrame, createBackdrop)
	if not scrollFrame then return end

	scrollFrame:StripTextures()

	if createBackdrop then
		scrollFrame:CreateBackdrop(createBackdrop == true and "Transparent" or createBackdrop)
	end

	local scrollBar = scrollFrame.ScrollBar or scrollFrame.scrollBar or (scrollFrame.GetName and _G[scrollFrame:GetName().."ScrollBar"])
	if scrollBar then
		S:HandleSirusScrollBar(scrollBar)
	end
end

function S:HandleSirusTab(tab, previousTab)
	if not tab then return end

	tab:StripTextures()
	S:HandleTab(tab, true)
	tab.isSkinned = true

	tab:CreateBackdrop()
	if tab.backdrop then
		tab.backdrop:ClearAllPoints()
		tab.backdrop:Point("TOPLEFT", 0, -3)
		tab.backdrop:Point("BOTTOMRIGHT", 0, 3)
	end

	if previousTab then
		tab:ClearAllPoints()
		tab:Point("TOPLEFT", previousTab, "TOPRIGHT", 2, 0)
	end
end

function S:HandleSirusTabFlow(tabs, onUpdate)
	if not tabs then return end

	local function Reflow()
		local lastShown
		for i, tab in ipairs(tabs) do
			if tab then
				if lastShown then
					tab:ClearAllPoints()
					tab:Point("TOPLEFT", lastShown, "TOPRIGHT", 2, 0)
				end

				if tab:IsShown() then
					lastShown = tab
				end
			end
		end
	end

	if type(onUpdate) == "string" then
		local func = _G[onUpdate]
		if func then
			hooksecurefunc(onUpdate, Reflow)
		end
	end

	Reflow()
end

function S:HandleSirusTabSystem(tabSystem)
	if not tabSystem then return end

	for _, tab in next, { tabSystem:GetChildren() } do
		if not tab.isSkinned then
			if tab.RotatedTextures then
				for _, texture in ipairs(tab.RotatedTextures) do
					texture:SetTexture()
				end
			end

			local highlight = tab.GetHighlightTexture and tab:GetHighlightTexture()
			if highlight then highlight:SetTexture() end

			tab:CreateBackdrop("Default")
			if tab.backdrop then
				tab.backdrop:Point("TOPLEFT", 3, -3)
				tab.backdrop:Point("BOTTOMRIGHT", -3, 1)
			end

			tab.isSkinned = true
		end
	end
end

function S:HandleSirusButton(button, strip, ...)
	if button then S:HandleButton(button, strip, ...) end
end

function S:HandleSirusDropDown(dropDown, width)
	if dropDown then S:HandleDropDownBox(dropDown, width) end
end

function S:HandleSirusCloseButton(closeButton, ...)
	if closeButton then S:HandleCloseButton(closeButton, ...) end
end

function S:HandleSirusIconButton(button, icon, iconBorder)
	if not button or not icon then return end

	local texture = icon:GetTexture()

	icon:SetTexCoords()
	button:CreateBackdrop("Default")
	if button.backdrop then
		icon:SetParent(button.backdrop)
		button.backdrop:SetOutside(icon, 1, 1)
	end

	if texture then icon:SetTexture(texture) end

	if iconBorder then
		S:HandleIconBorder(iconBorder, button.backdrop or icon)
	end
end

function S:HandleSirusToggle(toggle, texture)
	if not toggle then return end

	toggle:StripTextures()
	S:HandleButton(toggle)
	toggle:SetNormalTexture(texture)
	if toggle.GetNormalTexture then toggle:GetNormalTexture():SetInside() end
	toggle:SetPushedTexture(texture)
	if toggle.GetPushedTexture then toggle:GetPushedTexture():SetInside() end
	toggle:SetHighlightTexture("")

	return toggle
end

function S:HandleSirusStatusBar(statusBar)
	if not statusBar then return end

	statusBar:StripTextures()
	statusBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(statusBar)
	statusBar:CreateBackdrop("Default")

	return statusBar
end

function S:HandleSirusCollapseToggle(button, size)
	if not button then return end

	button:SetNormalTexture(E.Media.Textures.Plus)
	button.SetNormalTexture = E.noop
	button:GetNormalTexture():Size(size or 16)
	button:SetHighlightTexture(nil)

	hooksecurefunc(button, "SetNormalTexture", function(self, texture)
		if find(texture, "MinusButton") then
			self:GetNormalTexture():SetTexture(E.Media.Textures.Minus)
		elseif find(texture, "PlusButton") then
			self:GetNormalTexture():SetTexture(E.Media.Textures.Plus)
		end
	end)

	return button
end

function S:SetSirusCollapseIcon(button, collapsed)
	if not button then return end

	local texture = button.collapseArrow or (button.GetNormalTexture and button:GetNormalTexture())
	if not texture then return end

	texture:SetTexture(collapsed and E.Media.Textures.Plus or E.Media.Textures.Minus)
end

function S:HandleSirusSearchRow(searchBox, filterButton)
	if searchBox then S:HandleEditBox(searchBox) end

	if filterButton then
		filterButton:StripTextures(true)
		S:HandleButton(filterButton)

		local height = searchBox and searchBox:GetHeight()
		if height and height > 0 then
			filterButton:SetHeight(height)
		end
	end
end

function S:HandleSirusScrollBar(scrollBar)
	if not scrollBar or scrollBar.sirusStyled then return end
	scrollBar.sirusStyled = true

	if scrollBar.Track and scrollBar.Track.Thumb and not scrollBar.GetThumbTexture then
		local track = scrollBar.Track
		track:StripTextures()
		track:CreateBackdrop("Transparent")
		if track.backdrop then
			track.backdrop:ClearAllPoints()
			track.backdrop:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
			track.backdrop:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 0, 0)
		end

		local thumb = track.Thumb
		thumb:StripTextures()
		thumb:CreateBackdrop(nil, true, true, nil, nil, nil, nil, nil, (scrollBar:GetFrameLevel() or 0) + 1)
		if thumb.backdrop then
			thumb.backdrop:ClearAllPoints()
			thumb.backdrop:SetPoint("TOPLEFT", thumb, "TOPLEFT", 0, 0)
			thumb.backdrop:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", 0, 0)
			thumb.backdrop:SetBackdropColor(unpack(E.media.rgbvaluecolor))
		end

		if thumb.Begin then thumb.Begin:Kill() end
		if thumb.Middle then thumb.Middle:Kill() end
		if thumb.End then thumb.End:Kill() end

		if scrollBar.Back then
			S:HandleNextPrevButton(scrollBar.Back, "up")
			scrollBar.Back:Size(12)
		end

		if scrollBar.Forward then
			S:HandleNextPrevButton(scrollBar.Forward, "down")
			scrollBar.Forward:Size(12)
		end

		return
	end

	if scrollBar.GetObjectType and scrollBar:GetObjectType() ~= "Slider" and scrollBar.GetThumb then
		S:HandleScrollBar(scrollBar)
		return
	end

	S:HandleScrollBar(scrollBar)

	scrollBar:SetWidth(8)
	local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
	if thumb then
		thumb:SetWidth(8)

		if thumb:GetHeight() < 1 then
			thumb:SetHeight(24)
		end
	end

	if scrollBar.backdrop then
		scrollBar.backdrop:ClearAllPoints()
		scrollBar.backdrop:Point("TOPLEFT", scrollBar, "TOPLEFT", 0, 0)
		scrollBar.backdrop:Point("BOTTOMRIGHT", scrollBar, "BOTTOMRIGHT", 0, 0)
	end

	local name = scrollBar:GetName()
	local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton or scrollBar.ScrollUp or (name and (_G[name.."ScrollUpButton"] or _G[name.."UpButton"] or _G[name.."ScrollUp"]))
	local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton or scrollBar.ScrollDown or (name and (_G[name.."ScrollDownButton"] or _G[name.."DownButton"] or _G[name.."ScrollDown"]))
	if not (upButton and downButton) then return end

	upButton:Size(12)
	downButton:Size(12)

	local function UpdateArrows()
		local minValue, maxValue = scrollBar:GetMinMaxValues()
		local value = scrollBar:GetValue()
		local scrollable = maxValue > minValue

		upButton:SetShown(scrollable and value > minValue + 0.05)
		downButton:SetShown(scrollable and value < maxValue - 0.05)
	end

	scrollBar:HookScript("OnValueChanged", UpdateArrows)
	scrollBar:HookScript("OnMinMaxChanged", UpdateArrows)
	scrollBar:HookScript("OnShow", UpdateArrows)
	UpdateArrows()
end

function S:HandleSirusNavBar(navBar)
	if not navBar or navBar.isSkinned then return end

	navBar:StripTextures()
	if navBar.overlay then navBar.overlay:StripTextures() end

	local function SkinButton(button)
		if not button or button.isSkinned then return end
		S:HandleButton(button, true)
		S:ApplyElvUIFont(button)
		button.xoffset = 1

		local arrow = button.MenuArrowButton
		if arrow then
			if arrow.NormalTexture then arrow.NormalTexture:Hide() end
			if arrow.PushedTexture then arrow.PushedTexture:Hide() end
			if arrow.HighlightTexture then arrow.HighlightTexture:Hide() end

			if arrow.Art then
				arrow.Art:SetVertexColor(1, 1, 1)
				arrow:HookScript("OnEnter", function(self)
					if self.Art then self.Art:SetVertexColor(1, 0.82, 0) end
				end)
				arrow:HookScript("OnLeave", function(self)
					if self.Art then self.Art:SetVertexColor(1, 1, 1) end
				end)
			end
		end

		button.isSkinned = true
	end

	SkinButton(navBar.home)

	if navBar.navList then
		for _, button in ipairs(navBar.navList) do
			SkinButton(button)
		end
	end

	if _G.NavBar_AddButton then
		hooksecurefunc("NavBar_AddButton", function(self)
			if self ~= navBar then return end
			SkinButton(self.navList[#self.navList])
		end)
	end

	navBar.isSkinned = true
end
