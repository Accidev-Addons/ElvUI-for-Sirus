local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local LSM = E.Libs.LSM

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
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemID = GetContainerItemID
local GetContainerItemInfo = GetContainerItemInfo
local GetCursorInfo = GetCursorInfo
local ClearCursor = ClearCursor
local GetExistingSocketLink = GetExistingSocketLink
local GetNewSocketLink = GetNewSocketLink
local PickupContainerItem = PickupContainerItem
local GetSocketTypes = GetSocketTypes
local ClickSocketButton = ClickSocketButton
local AcceptSockets = AcceptSockets
local CloseSocketInfo = CloseSocketInfo
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
local utf8lower = utf8.lower

local ENCHANT_TEXT_MAX_LENGTH = 20
local MAX_DISPLAYED_SOCKETS = 3

local function GetSocketSize(row)
	local pixel = E:PixelSize(1, row)
	local size = math.max(3, math.floor(E.db.general.characterInfo.socketSize / pixel + 0.5)) * pixel
	return size, size + pixel, pixel
end

local socketInfoFrames = setmetatable({}, { __mode = "k" })

local function SetSocketRowPoint(row, point, relativeTo, relativePoint, x, y)
	row:SetPoint(point, relativeTo, relativePoint, x, y)
	local left, bottom = row:GetLeft(), row:GetBottom()
	if left and bottom then
		local pixel = E:PixelSize(1, row)
		local dx = math.floor(left / pixel + 0.5) * pixel - left
		local dy = math.floor(bottom / pixel + 0.5) * pixel - bottom
		row:SetPoint(point, relativeTo, relativePoint, x + dx, y + dy)
	end
end

local BLACK_DIAMONDS = {
	[100754] = 1, [100758] = 1, [100762] = 1, [100764] = 1,
	[100765] = 1, [100766] = 1, [100767] = 1, [100769] = 1,
	[100770] = 1, [100771] = 1, [100773] = 1, [100774] = 1,
	[100775] = 1, [100777] = 1, [100778] = 1, [100781] = 1,
	[100782] = 1, [100783] = 1, [100784] = 1, [100785] = 1,
	[100786] = 1, [100787] = 1, [100788] = 1, [100789] = 1,
	[100790] = 1, [100791] = 1, [100792] = 1, [100793] = 1,
	[100794] = 1, [100795] = 1, [100796] = 1, [100797] = 1,
	[100798] = 1, [100799] = 1, [100801] = 1, [100802] = 1,
	[100803] = 1, [100805] = 1, [100806] = 1, [100807] = 1,
	[100809] = 1, [100810] = 1, [100813] = 1, [100814] = 1,
	[100815] = 1, [100817] = 1, [100818] = 1, [100821] = 1,
	[100822] = 1, [149186] = 1,
}

local META_BLACK_DIAMONDS = {}

do
	local function AddGemRange(target, firstID, lastID, priority)
		for itemID = firstID, lastID do
			target[itemID] = priority
		end
	end

	AddGemRange(BLACK_DIAMONDS, 100700, 100752, 1)
	AddGemRange(BLACK_DIAMONDS, 100824, 100884, 2)
	AddGemRange(BLACK_DIAMONDS, 103501, 103520, 1)
	AddGemRange(BLACK_DIAMONDS, 104000, 104019, 2)
	AddGemRange(BLACK_DIAMONDS, 260030, 260048, 1)
	AddGemRange(META_BLACK_DIAMONDS, 260050, 260070, 1)
end

local SOCKET_COLORS = {
	[utf8lower(EMPTY_SOCKET_RED or "")] = { 1, .11, .08, .5 },
	[utf8lower(EMPTY_SOCKET_YELLOW or "")] = { 1, .95, .08, .5 },
	[utf8lower(EMPTY_SOCKET_BLUE or "")] = { .08, .26, 1, .5 },
	[utf8lower(EMPTY_SOCKET_META or "")] = { 1, 1, 1, 1 },
	[utf8lower(EMPTY_SOCKET_NO_COLOR or "")] = { .99, .15, .9, .5 },
}

local EMPTY_SOCKET_TEXTURES = {
	[utf8lower(EMPTY_SOCKET_RED or "")] = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Red",
	[utf8lower(EMPTY_SOCKET_YELLOW or "")] = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Yellow",
	[utf8lower(EMPTY_SOCKET_BLUE or "")] = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Blue",
	[utf8lower(EMPTY_SOCKET_META or "")] = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Meta",
	[utf8lower(EMPTY_SOCKET_NO_COLOR or "")] = "Interface\\ItemSocketingFrame\\UI-EmptySocket",
}

S.EquipmentSlotAnchors = {
	HeadSlot = "RIGHT", NeckSlot = "RIGHT", ShoulderSlot = "RIGHT", ShirtSlot = "RIGHT", ChestSlot = "RIGHT",
	WristSlot = "RIGHT", BackSlot = "RIGHT", TabardSlot = "RIGHT",
	HandsSlot = "LEFT", WaistSlot = "LEFT", LegsSlot = "LEFT", FeetSlot = "LEFT",
	Finger0Slot = "LEFT", Finger1Slot = "LEFT", Trinket0Slot = "LEFT", Trinket1Slot = "LEFT",
	MainHandSlot = "TOP", SecondaryHandSlot = "TOP", RangedSlot = "TOP",
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

local ENCHANT_REPLACEMENTS = {
	["спд"] = {
		"к силе заклинаний", "к силе заклинания", "силе заклинаний",
		"силе заклинания", "сила заклинаний", "сила заклинания",
		"заклинаний", "заклинания",
	},
	["пен"] = {
		"к проникающей способности заклинаний", "проникающей способности заклинаний",
	},
	["са"] = {
		"к силе атаки", "силе атаки",
	},
	["крит"] = {
		"к критическому удару", "к рейтингу критического удара", "рейтингу критического удара",
		"к рейтингу критического эффекта", "рейтингу критического эффекта",
	},
	["рпб"] = {
		"к пробиванию брони", "к рейтингу пробивания брони", "рейтингу пробивания брони",
	},
	["уст"] = {
		"к устойчивости", "к рейтингу устойчивости", "рейтингу устойчивости",
		"устойчивости",
	},
	["метк"] = {
		"к меткости", "к рейтингу меткости", "рейтингу меткости",
	},
	["скор"] = {
		"к скорости", "к рейтингу скорости", "рейтингу скорости",
	},
	["маст"] = {
		"к мастерству", "к рейтингу мастерства", "рейтингу мастерства",
	},
	["защ"] = {
		"к защите", "к рейтингу защиты", "рейтингу защиты",
	},
	["вын"] = {
		"к выносливости", "к выносливость", "выносливости",
		"выносливость",
	},
	["лов"] = {
		"к ловкости", "ловкость",
	},
	["инт"] = {
		"к интеллекту", "интеллект",
	},
	["дух"] = {
		"к духу",
	},
	["бр"] = {
		"к броне", "броня",
	},
	["сопр"] = {
		"к сопротивлению", "сопротивление",
	},
	["ко всем"] = {
		"ко всем характеристикам",
	},
	["мп5"] = {
		"ед. маны каждые 5 секунд", "маны каждые 5 секунд",
	},
	["бег"] = {
		"увеличение скорости передвижения на",
	},
}

local ENCHANT_WORD_PATTERN = "[%w_\128-\255]+"
local ENCHANT_TOKEN_PATTERN = "()("..ENCHANT_WORD_PATTERN..")()"
local ENCHANT_REPLACEMENT_TRIE = {}
do
	for replacement, aliases in pairs(ENCHANT_REPLACEMENTS) do
		for _, alias in ipairs(aliases) do
			local node, previousEnd = ENCHANT_REPLACEMENT_TRIE, 1
			for _, _, after in string.gmatch(alias, ENCHANT_TOKEN_PATTERN) do
				local key = sub(alias, previousEnd, after - 1)
				if not node[key] then node[key] = {} end
				node.hasChildren = true
				node, previousEnd = node[key], after
			end
			node[1] = replacement
		end
	end
end

local function ReplaceEnchantStats(text)
	local result, copiedTo, position = nil, 1, 1
	while true do
		local wordStart, wordEnd = find(text, ENCHANT_WORD_PATTERN, position)
		if not wordStart then break end
		local node = ENCHANT_REPLACEMENT_TRIE[sub(text, wordStart, wordEnd)]
		local replacement, matchEnd
		local after = wordEnd + 1
		while node do
			if node[1] then replacement, matchEnd = node[1], after end
			if not node.hasChildren then break end
			local nextStart, nextEnd = find(text, ENCHANT_WORD_PATTERN, after)
			if not nextStart then break end
			node = node[sub(text, after, nextEnd)]
			after = nextEnd + 1
		end
		if replacement then
			result = result or {}
			result[#result + 1] = sub(text, copiedTo, wordStart - 1)
			result[#result + 1] = replacement
			copiedTo, position = matchEnd, matchEnd
		else
			position = wordEnd + 1
		end
	end
	if not result then return text end
	result[#result + 1] = sub(text, copiedTo)
	return table.concat(result)
end

local ENCHANT_ROMAN_RANKS = {
	i = "I", ii = "II", iii = "III", iv = "IV", v = "V",
	vi = "VI", vii = "VII", viii = "VIII", ix = "IX", x = "X",
}

local function FormatEnchantText(text)
	text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = gsub(text, "|r", "")
	if find(text, "\208[\129\144-\175]") then
		text = utf8lower(text)
	else
		text = lower(text)
	end
	text = gsub(text, "\194\160", " ")
	text = gsub(text, "%s+", " ")
	text = strtrim(text)
	text = gsub(text, "^зачарование:%s*", "")
	text = gsub(text, "^зачаровано:%s*", "")
	if find(text, "отцепить от пояса", 1, true) and find(text, "кобальтов", 1, true) and find(text, "бомб", 1, true) then
		return "бомбы"
	end
	text = gsub(text, "^([0-9]+)%s*", "%1 ")
	text = gsub(text, "%sй%s", " и ")
	text = gsub(text, "и%s+увеличение скорости передвижения на%s+(%d+%%%s*)", " и %1 бег")
	text = gsub(text, "увеличение скорости передвижения на%s+(%d+%%%s*)", "%1 бег")
	text = gsub(text, "снижение угрозы на%s+(%d+%%%s*)", "-%1 угрозы")

	text = ReplaceEnchantStats(text)
	text = ReplacePlain(text, "бомбы, которая нано", "бомбы")
	text = ReplacePlain(text, "использование:", "")

	text = strtrim((gsub(text, "%s+", " ")))
	text = gsub(text, "%S+", ENCHANT_ROMAN_RANKS)
	if find(text, "%d") then return text end
	return utf8sub(text, 1, ENCHANT_TEXT_MAX_LENGTH)
end

local ENCHANT_CACHE_LIMIT, ENCHANT_CACHE_MAX_TEXT = 128, 1024
local enchantCache, enchantCacheKeys, enchantCacheNext = {}, {}, 1
local function ShortenEnchantText(text)
	if not text then return end
	local cached = enchantCache[text]
	if cached then return cached end

	local shortened = FormatEnchantText(text)
	if #text <= ENCHANT_CACHE_MAX_TEXT then
		local previous = enchantCacheKeys[enchantCacheNext]
		if previous then enchantCache[previous] = nil end
		enchantCacheKeys[enchantCacheNext] = text
		enchantCache[text] = shortened
		enchantCacheNext = enchantCacheNext % ENCHANT_CACHE_LIMIT + 1
	end
	return shortened
end

local function StripColor(text)
	return strtrim((gsub(gsub(text, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")))
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

	local isPlayer = self.unit == "player"
	if self.gemLink then
		GameTooltip:SetHyperlink(self.gemLink)
		if isPlayer and self.canRemove then
			GameTooltip:AddLine(L["<Click to extract the gem>"], 0, .8, 1)
		end
	elseif self.isEmpty then
		GameTooltip:SetText(self.lineText, 1, 1, 1)
		if isPlayer then
			GameTooltip:AddLine(L["<Click to insert a black diamond>"], 0, .8, 1)
		end
	else
		GameTooltip:SetText(L["Gem data unavailable"], .6, .6, .6)
	end

	GameTooltip:Show()
end

local function FindBlackDiamond(socketType)
	local candidates
	if socketType == "Meta" then
		candidates = META_BLACK_DIAMONDS
	elseif socketType == "Red" or socketType == "Yellow" or socketType == "Blue" or socketType == "Socket" then
		candidates = BLACK_DIAMONDS
	else
		return
	end

	local bestBag, bestSlot, bestID, bestPriority
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			local priority = itemID and candidates[itemID]
			if priority and (not bestPriority or priority > bestPriority) then
				local _, _, locked = GetContainerItemInfo(bag, slot)
				if not locked then
					bestBag, bestSlot, bestID, bestPriority = bag, slot, itemID, priority
					if priority == 2 or candidates == META_BLACK_DIAMONDS then
						return bestBag, bestSlot, bestID
					end
				end
			end
		end
	end

	return bestBag, bestSlot, bestID
end

local function Socket_OnClick(self)
	if self.unit ~= "player" or GetCursorInfo() then return end

	if self.gemLink then
		if self.canRemove then
			SendServerMessage("ACMSG_REMOVE_SOCKET_FROM_ITEM", -1, self.inventorySlot, self.index)
		end
	elseif self.isEmpty then
		SocketInventoryItem(self.inventorySlot)
		if GetExistingSocketLink(self.index) then return end

		local bag, slot, itemID = FindBlackDiamond(GetSocketTypes(self.index))
		if not bag then return end

		PickupContainerItem(bag, slot)
		local cursorType, cursorID = GetCursorInfo()
		if cursorType ~= "item" or cursorID ~= itemID then return end

		ClickSocketButton(self.index)
		local link = GetNewSocketLink(self.index)
		if link and tonumber(strmatch(link, "item:(%d+)")) == itemID then
			AcceptSockets()
			CloseSocketInfo()
		else
			cursorType, cursorID = GetCursorInfo()
			if cursorType == "item" and cursorID == itemID then
				ClearCursor()
			end
		end
	end
end

local function CreateSocket(info, index)
	local socket = CreateFrame("Button", nil, info)
	socket:SetTemplate("Default", nil, nil, true)
	socket:RegisterForClicks("LeftButtonUp")
	socket:SetScript("OnEnter", Socket_OnEnter)
	socket:SetScript("OnLeave", GameTooltip_Hide)
	socket:SetScript("OnClick", Socket_OnClick)
	socket.index = index

	socket.Icon = socket:CreateTexture(nil, "ARTWORK")

	return socket
end

local function PlaceSocketRow(info, numSockets)
	local slotFrame, anchor, row = info:GetParent(), info.anchor, info.socketRow
	local db = E.db.general.characterInfo
	local position = db.socketPosition or "default"
	if position == "default" then position = "BOTTOMLEFT" end
	local x, y = db.socketXOffset or 0, db.socketYOffset or 0

	local size, step, pixel = GetSocketSize(row)

	row:ClearAllPoints()
	row:SetSize(math.max(numSockets, 1) * step - pixel, size)

	for index, socket in ipairs(info.slots) do
		local offset = (index - 1) * step
		socket:SetSize(size, size)
		socket.Icon:SetInside(socket, pixel, pixel, nil, true)
		socket:ClearAllPoints()
		if anchor == "LEFT" then
			socket:SetPoint("RIGHT", row, "RIGHT", -offset, 0)
		else
			socket:SetPoint("LEFT", row, "LEFT", offset, 0)
		end
	end

	if anchor == "TOP" then
		local h = string.find(position, "LEFT") and "LEFT" or string.find(position, "RIGHT") and "RIGHT" or ""
		SetSocketRowPoint(row, "TOP"..h, slotFrame, "BOTTOM"..h, x, -pixel + y)
	else
		local v = string.find(position, "TOP") and "TOP" or string.find(position, "BOTTOM") and "BOTTOM" or ""
		if anchor == "RIGHT" then
			SetSocketRowPoint(row, v.."LEFT", slotFrame, v.."RIGHT", pixel + x, y)
		else
			SetSocketRowPoint(row, v.."RIGHT", slotFrame, v.."LEFT", -pixel + x, y)
		end
	end
end

local function ApplySocketInfoLayout(info)
	if not info then return end

	local slotFrame = info:GetParent()
	local anchor, slotName = info.anchor, info.slotName
	if not slotFrame or not anchor then return end

	local db = E.db.general.characterInfo
	local enchantPosition, enchantX, enchantY = db.enchantPosition or "default", db.enchantXOffset or 0, db.enchantYOffset or 0
	local slotWidth = slotFrame:GetWidth() or 0

	info:ClearAllPoints()
	info.enchant:ClearAllPoints()
	PlaceSocketRow(info, info.numSockets or 0)

	if anchor == "TOP" then
		if slotName == "MainHandSlot" then
			info:SetPoint("TOPRIGHT", slotFrame, "BOTTOMLEFT", -3, -3)
			info.enchant:SetJustifyH("RIGHT")
			info.enchant:SetPoint("BOTTOMRIGHT", slotFrame, "BOTTOMLEFT", -3 + enchantX, 1 + enchantY)
		elseif slotName == "SecondaryHandSlot" then
			info:SetPoint("TOPLEFT", slotFrame, "BOTTOMRIGHT", 3, -3)
			info.enchant:SetJustifyH("LEFT")
			info.enchant:SetPoint("TOPLEFT", slotFrame, "TOPRIGHT", slotWidth + 8 + enchantX, -3 + enchantY)
		elseif slotName == "RangedSlot" then
			info:SetPoint("BOTTOM", slotFrame, "TOP", 0, 4)
			info.enchant:SetJustifyH("LEFT")
			info.enchant:SetPoint("BOTTOMLEFT", slotFrame, "BOTTOMRIGHT", 3 + enchantX, -3 + enchantY)
		else
			info:SetPoint("BOTTOM", slotFrame, "TOP", 0, 4)
			info.enchant:SetJustifyH("CENTER")
			info.enchant:SetPoint("BOTTOM", info.socketRow, "TOP", enchantX, 1 + enchantY)
		end
	elseif anchor == "RIGHT" then
		info:SetPoint("LEFT", slotFrame, "RIGHT", 3, 0)
		info.enchant:SetJustifyH("LEFT")
		info.enchant:SetPoint("BOTTOMLEFT", info.socketRow, "TOPLEFT", enchantX, 1 + enchantY)
	else
		info:SetPoint("RIGHT", slotFrame, "LEFT", -3, 0)
		info.enchant:SetJustifyH("RIGHT")
		info.enchant:SetPoint("BOTTOMRIGHT", info.socketRow, "TOPRIGHT", enchantX, 1 + enchantY)
	end

	if enchantPosition ~= "default" then
		info.enchant:ClearAllPoints()
		info.enchant:SetPoint(enchantPosition, slotFrame, enchantX, enchantY)

		if string.find(enchantPosition, "LEFT") then
			info.enchant:SetJustifyH("LEFT")
		elseif string.find(enchantPosition, "RIGHT") then
			info.enchant:SetJustifyH("RIGHT")
		else
			info.enchant:SetJustifyH("CENTER")
		end
	end
end

local function CreateSocketInfo(slotFrame, anchor, slotName)
	local info = CreateFrame("Frame", nil, slotFrame)
	info:SetFrameLevel(slotFrame:GetFrameLevel() + 1)
	info:SetSize(220, anchor == "TOP" and 46 or 31)
	info.slots = {}
	info.anchor = anchor
	info.slotName = slotName

	info.socketRow = CreateFrame("Frame", nil, info)
	info.enchant = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	info.enchant:SetTextColor(0.1, 1, 0.1)
	info.enchant:SetWordWrap(false)
	info.enchant:SetWidth(220)

	for index = 1, MAX_DISPLAYED_SOCKETS do
		info.slots[index] = CreateSocket(info, index)
	end

	socketInfoFrames[info] = true
	return info
end

local function SetGemSocket(socket, gemLink, texture)
	local quality
	if gemLink then
		local _, _, gemQuality, _, _, _, _, _, _, gemTexture = GetItemInfo(gemLink)
		quality, texture = gemQuality, gemTexture or texture
	end

	socket.isEmpty = nil
	socket.gemLink = gemLink
	socket.lineText = nil
	socket.canRemove = gemLink and quality == 5

	if texture then
		socket.Icon:SetTexture(texture)
		socket.Icon:SetTexCoord(unpack(E.TexCoords))
		socket.Icon:SetVertexColor(1, 1, 1, 1)
	else
		socket.Icon:SetTexture(E.Media.Textures.NormTex2)
		socket.Icon:SetTexCoord(0, 1, 0, 1)
		socket.Icon:SetVertexColor(.4, .4, .4, 1)
	end

	socket:Show()

	return texture ~= nil and quality ~= nil
end

local function SetEmptySocket(socket, name, color, texture)
	socket.isEmpty = true
	socket.gemLink = nil
	socket.lineText = name
	socket.canRemove = nil

	if texture then
		socket.Icon:SetTexture(texture)
		socket.Icon:SetTexCoord(0, 1, 0, 1)
		socket.Icon:SetVertexColor(1, 1, 1, 1)
	else
		socket.Icon:SetTexture(E.Media.Textures.NormTex2)
		socket.Icon:SetTexCoord(0, 1, 0, 1)
		socket.Icon:SetVertexColor(unpack(color))
	end

	socket:Show()
end

local function UpdateSocketInfoStyle(info, db)
	local parent = info:GetParent()
	local width, left, bottom = parent:GetWidth(), parent:GetLeft(), parent:GetBottom()
	local pixel = E:PixelSize(1, info.socketRow)
	if info.layoutPixel ~= pixel or info.layoutLeft ~= left or info.layoutBottom ~= bottom or
		info.layoutSockets ~= info.numSockets or info.layoutWidth ~= width or
		info.layoutSize ~= db.socketSize or info.layoutPosition ~= db.socketPosition or
		info.layoutX ~= db.socketXOffset or info.layoutY ~= db.socketYOffset or
		info.layoutEnchantPosition ~= db.enchantPosition or
		info.layoutEnchantX ~= db.enchantXOffset or info.layoutEnchantY ~= db.enchantYOffset then
		ApplySocketInfoLayout(info)
		info.layoutPixel, info.layoutLeft, info.layoutBottom = pixel, left, bottom
		info.layoutSockets, info.layoutWidth = info.numSockets, width
		info.layoutSize, info.layoutPosition = db.socketSize, db.socketPosition
		info.layoutX, info.layoutY = db.socketXOffset, db.socketYOffset
		info.layoutEnchantPosition = db.enchantPosition
		info.layoutEnchantX, info.layoutEnchantY = db.enchantXOffset, db.enchantYOffset
	end

	local font = LSM:Fetch("font", db.enchantFont or "Expressway")
	local size, outline = db.enchantFontSize or 11, db.enchantFontOutline or "SHADOW"
	if info.enchantFont ~= font or info.enchantFontSize ~= size or info.enchantFontOutline ~= outline then
		info.enchant:FontTemplate(font, size, outline)
		info.enchantFont, info.enchantFontSize, info.enchantFontOutline = font, size, outline
	end
end

hooksecurefunc(E, "UpdateFrameTemplates", function()
	for info in pairs(socketInfoFrames) do
		if info:IsVisible() then
			UpdateSocketInfoStyle(info, E.db.general.characterInfo)
		end
	end
end)

local gemTextures, emptyNames, emptyColors, emptyTextures = {}, {}, {}, {}
function S:HandleSirusEquipmentSocketInfo(slotFrame, inventorySlot, anchor, slotName, unit)
	local hasUnknown
	if not slotFrame or not inventorySlot then return end
	unit = unit or "player"

	local db = E.db.general.characterInfo
	local showGems, showEnchants = db.showGems, db.showEnchants and unit == "player"
	local info = slotFrame.sirusSocketInfo
	if not showGems and not showEnchants then
		if info then info:Hide() end
		return
	end
	if not info then
		info = CreateSocketInfo(slotFrame, anchor or "RIGHT", slotName)
		slotFrame.sirusSocketInfo = info
	end

	local link = GetInventoryItemLink(unit, inventorySlot)
	local numSockets, enchantText = 0

	if link and (showGems or showEnchants) then
		local tooltip = E.ScanTooltip
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetInventoryItem(unit, inventorySlot)
		tooltip:Show()

		if showGems then
			for index = 1, 10 do
				local texture = _G["ElvUI_ScanTooltipTexture"..index]
				if texture and texture:IsShown() then
					gemTextures[#gemTextures + 1] = texture:GetTexture()
				end
			end
		end

		for index = 1, tooltip:NumLines() do
			local line = _G["ElvUI_ScanTooltipTextLeft"..index]
			local text = line:GetText()
			if text then
				local plain = StripColor(text)
				local normalized = utf8lower(plain)
				local socketColor = showGems and SOCKET_COLORS[normalized]
				if socketColor then
					emptyNames[#emptyNames + 1] = plain
					emptyColors[#emptyColors + 1] = socketColor
					emptyTextures[#emptyTextures + 1] = EMPTY_SOCKET_TEXTURES[normalized]
				elseif showEnchants and not enchantText then
					enchantText = MatchEnchant(line, plain, normalized, slotName)
				end
			end
			if not showGems and enchantText then break end
		end

		tooltip:Hide()

		if showGems then
			local nextTexture, nextEmpty = 1, 1
			for index = 1, MAX_DISPLAYED_SOCKETS do
				local socket = info.slots[index]
				local _, gemLink = GetItemGem(link, index)

				if gemLink then
					if not SetGemSocket(socket, gemLink, gemTextures[nextTexture]) then
						hasUnknown = true
					end
					nextTexture = nextTexture + 1
				elseif emptyNames[nextEmpty] then
					SetEmptySocket(socket, emptyNames[nextEmpty], emptyColors[nextEmpty], emptyTextures[nextEmpty])
					nextEmpty = nextEmpty + 1
				else
					break
				end

				socket.unit = unit
				socket.inventorySlot = inventorySlot
				numSockets = index
			end
		end

		wipe(gemTextures)
		wipe(emptyNames)
		wipe(emptyColors)
		wipe(emptyTextures)
	end

	for index = numSockets + 1, MAX_DISPLAYED_SOCKETS do
		info.slots[index]:Hide()
	end

	info.numSockets = numSockets
	UpdateSocketInfoStyle(info, db)

	enchantText = enchantText and ShortenEnchantText(enchantText)
	info.enchant:SetText(enchantText)
	info.enchant:SetShown(enchantText ~= nil)
	info:SetShown(numSockets > 0 or enchantText ~= nil)

	return hasUnknown
end

function S:UpdateBlackDiamondHighlight(slotFrame, link)
	if not slotFrame then return end

	local glow = slotFrame.textureSoc
	if E.db.general.characterInfo.highlightBlackDiamonds and link then
		for index = 1, MAX_DISPLAYED_SOCKETS do
			local _, gemLink = GetItemGem(link, index)
			if gemLink and select(3, GetItemInfo(gemLink)) == 5 then
				if not glow then
					glow = slotFrame:CreateTexture(nil, "TOOLTIP")
					glow:SetInside()
					glow:SetTexture([[Interface\AddOns\ElvUI\Core\Media\Textures\BagNewItemGlow]])
					glow:SetVertexColor(E:GetItemQualityColor(5))
					slotFrame.textureSoc = glow
				end
				glow:Show()
				return
			end
		end
	end

	if glow then glow:Hide() end
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

	local current = E.Media.Textures.Plus
	button:SetNormalTexture(current)
	button:GetNormalTexture():Size(size or 16)
	button:SetHighlightTexture(nil)

	hooksecurefunc(button, "SetNormalTexture", function(self, texture)
		if type(texture) == "string" then
			if find(texture, "MinusButton") then
				current = E.Media.Textures.Minus
			elseif find(texture, "PlusButton") then
				current = E.Media.Textures.Plus
			end
		end
		self:GetNormalTexture():SetTexture(current)
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
