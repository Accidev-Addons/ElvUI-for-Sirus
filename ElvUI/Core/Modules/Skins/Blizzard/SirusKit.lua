local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local LSM = E.Libs.LSM

local _G = _G
local unpack = unpack
local ipairs = ipairs
local find = string.find
local hooksecurefunc = hooksecurefunc
local pairs = pairs
local select = select
local GetInventoryItemLink = GetInventoryItemLink
local GetItemGem = GetItemGem
local SocketInventoryItem = SocketInventoryItem
local SendServerMessage = SendServerMessage
local GetItemInfo = GetItemInfo
local GetItemIcon = GetItemIcon
local GetItemInfoInstant = GetItemInfoInstant
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
local UnitClass = UnitClass
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

local SOCKET_COLORS = {
	[utf8lower(EMPTY_SOCKET_RED or "")] = { 1, .11, .08, .5 },
	[utf8lower(EMPTY_SOCKET_YELLOW or "")] = { 1, .95, .08, .5 },
	[utf8lower(EMPTY_SOCKET_BLUE or "")] = { .08, .26, 1, .5 },
	[utf8lower(EMPTY_SOCKET_META or "")] = { 1, 1, 1, 1 },
	[utf8lower(EMPTY_SOCKET_NO_COLOR or "")] = { .99, .15, .9, .5 },
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

local ALWAYS_ENCHANTABLE = { HeadSlot = true, NeckSlot = true, ShoulderSlot = true, BackSlot = true, ChestSlot = true, WristSlot = true, HandsSlot = true, LegsSlot = true, FeetSlot = true, MainHandSlot = true }
local ENCHANTABLE_OFFHAND = { INVTYPE_WEAPON = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_SHIELD = true, INVTYPE_2HWEAPON = true }

local function IsEnchanter()
	for index = 1, GetNumSkillLines() do
		if GetSkillLineInfo(index) == "Наложение чар" then return true end
	end
end

local function CanEnchant(slotName, link, unit)
	if ALWAYS_ENCHANTABLE[slotName] then return true end
	if slotName == "SecondaryHandSlot" then return ENCHANTABLE_OFFHAND[select(9, GetItemInfo(link))] end
	if slotName == "Finger0Slot" or slotName == "Finger1Slot" then return unit == "player" and IsEnchanter() end
end

local SCROLL_SLOT_WORDS = { MainHandSlot = "оружи", SecondaryHandSlot = "оружи", WristSlot = "наруч", HandsSlot = "перчат", BackSlot = "плащ", ChestSlot = "нагрудн", FeetSlot = "обув" }

local enchantScrolls
local function FindEnchantScroll(name, slotName)
	if not enchantScrolls then
		enchantScrolls = {}
		for itemID, data in pairs(_G.ItemsCache or {}) do
			if data[6] == 0 and data[7] == 6 and type(data[2]) == "string" then
				enchantScrolls[#enchantScrolls + 1] = { itemID, utf8lower(data[2]) }
			end
		end
	end

	local exact = utf8lower(name)
	local tail, word, anyID = " - "..exact, SCROLL_SLOT_WORDS[slotName]
	for _, scroll in ipairs(enchantScrolls) do
		if scroll[2] == exact then return scroll[1] end
		if sub(scroll[2], -#tail) == tail then
			if word and find(scroll[2], word, 1, true) then return scroll[1] end
			anyID = anyID or scroll[1]
		end
	end
	return anyID
end

local RUNE_SPELLS = { 53344, 53343, 53341, 53331, 53342, 53323, 54447, 54446, 62158, 70164 }
local function GetRuneStats(name)
	for _, spellID in ipairs(RUNE_SPELLS) do
		if GetSpellInfo(spellID) == name then
			local tooltip = E.ScanTooltip
			tooltip:SetOwner(UIParent, "ANCHOR_NONE")
			tooltip:SetHyperlink("spell:"..spellID)

			local stats
			for index = 1, tooltip:NumLines() do
				local text = _G["ElvUI_ScanTooltipTextLeft"..index]:GetText() or ""
				if find(text, "^Гравировка") then
					stats = strmatch(text, "^(.-%.)%s") or text
					break
				end
			end

			tooltip:Hide()
			return stats
		end
	end
end

local function GetScrollStats(itemID)
	local tooltip = E.ScanTooltip
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink("item:"..itemID)

	local stats
	for index = 1, tooltip:NumLines() do
		local text = _G["ElvUI_ScanTooltipTextLeft"..index]:GetText() or ""
		local use = strmatch(text, "^Использование:%s*(.-%.)%s") or strmatch(text, "^Использование:%s*(.+)$")
		if use then
			local clause = strmatch(use, "^[^,]-, (увеличивающ.-)%.")
			stats = clause and gsub(clause, "^увеличивающ%S+", "Увеличивает") or use
			break
		end
	end

	tooltip:Hide()
	return stats
end

local Enchant_OnEnter

local function Enchant_OnUpdate(self, elapsed)
	self.retryWait = self.retryWait - elapsed
	if self.retryWait > 0 then return end
	self.retryWait, self.retries = .3, self.retries - 1
	if self.retries < 0 or not GameTooltip:IsOwned(self) then
		self:SetScript("OnUpdate", nil)
		return
	end
	Enchant_OnEnter(self, true)
end

function Enchant_OnEnter(self, retry)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	local text = self.enchantText
	if text and not find(text, "%d") then
		local name = gsub(text, "^Зачарование:%s*", "")
		local scrollID = FindEnchantScroll(name, self.slotName)
		local stats = scrollID and GetScrollStats(scrollID)
		if scrollID and not stats then
			if not retry then
				self.retryWait, self.retries = .3, 10
				self:SetScript("OnUpdate", Enchant_OnUpdate)
			end
		elseif retry then
			self:SetScript("OnUpdate", nil)
		end
		text = stats or GetRuneStats(name) or text
	end

	if self.illusionText then
		GameTooltip:SetText(self.illusionText, 1, .5, 1, 1, true)
		if text then
			GameTooltip:AddLine(text, .1, 1, .1, true)
		end
	elseif text then
		GameTooltip:SetText(text, .1, 1, .1, 1, true)
	end

	if not text then
		GameTooltip:AddLine(L["Not enchanted"], 1, .2, .2)
	end

	GameTooltip:Show()
end

local TABLET_SLOTS = { ShoulderSlot = 1, ChestSlot = 2, WristSlot = 3, LegsSlot = 4, NeckSlot = 5 }
local TABLET_SPECS = {
	WARRIOR = { "arms", "fury", "protection" },
	PALADIN = { "holy", "protection", "retribution" },
	HUNTER = { "beastmastery", "marksman", "survival" },
	ROGUE = { "assasinate", "combat", "subtlety" },
	PRIEST = { "discipline", "holy", "shadow" },
	DEATHKNIGHT = { "blood", "frost", "unholy" },
	SHAMAN = { "elemental", "enhancement", "restoration" },
	MAGE = { "arcane", "fire", "frost" },
	WARLOCK = { "affliction", "demonology", "destruction" },
	DRUID = { "moonkin", "feral", "restoration" },
}
local TABLET_RARITY = { ["Необычное"] = 2, ["Редкое"] = 3, ["Эпическое"] = 4 }
local TABLET_SPELL_FIRST, TABLET_SPELL_LAST = 381000, 382700
local tabletIcons, tabletCatalog, tabletByName, emptyTabletIcon
local function LoadTablets()
	if tabletIcons then return end
	tabletIcons, tabletCatalog, tabletByName = {}, {}, {}
	for spellID = TABLET_SPELL_FIRST, TABLET_SPELL_LAST do
		local spellName, rank, icon = GetSpellInfo(spellID)
		local class, spec, slot
		if icon then class, spec, slot = strmatch(lower(icon), "_tablets_(%a+)_(%a+)_(%d)") end
		if class then
			local key = class.."_"..spec.."_"..slot
			local name = gsub(spellName, "%s*%b()$", "")
			tabletIcons[name] = icon
			emptyTabletIcon = emptyTabletIcon or icon
			if rank and rank ~= "" then
				local entry = tabletCatalog[key]
				if not entry then
					entry = { name = name, icon = icon, spells = {} }
					tabletCatalog[key] = entry
					tabletByName[name] = entry
				end
				entry.spells[#entry.spells + 1] = spellID
			end
		end
	end
end

local function GetTabletIcon(name)
	LoadTablets()
	return tabletIcons[name]
end

local function GetTabletSuggestion(unit, slotName)
	local slot = TABLET_SLOTS[slotName]
	local _, classFile = UnitClass(unit)
	local specs = slot and classFile and TABLET_SPECS[classFile]
	if not specs then return end

	local best, bestPoints = nil, 0
	for tab = 1, 3 do
		local _, _, points = GetTalentTabInfo(tab, unit ~= "player")
		if points and points > bestPoints then best, bestPoints = tab, points end
	end
	if not best then return nil, true end

	LoadTablets()
	return tabletCatalog[lower(classFile).."_"..specs[best].."_"..slot]
end

local function GetTabletRanks(entry)
	if entry.ranks then return entry.ranks end

	local ranks, tooltip = {}, E.ScanTooltip
	for _, spellID in ipairs(entry.spells) do
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink("spell:"..spellID)
		local lines, recipe = {}, false
		for line = 2, tooltip:NumLines() do
			local text = _G["ElvUI_ScanTooltipTextLeft"..line]:GetText()
			if text and find(text, "Реагенты", 1, true) then recipe = true break end
			if text and text ~= "" then lines[#lines + 1] = text end
		end
		tooltip:Hide()
		if not recipe and #lines > 0 then
			ranks[#ranks + 1] = { rank = select(2, GetSpellInfo(spellID)), text = table.concat(lines, "\n") }
		end
	end

	if #ranks > 0 then entry.ranks = ranks end
	return ranks
end

local function GetTabletDescription(entry)
	local ranks = GetTabletRanks(entry)
	return ranks[#ranks] and ranks[#ranks].text or ""
end

local function RarityHex(rank)
	local r, g, b = E:GetItemQualityColor(TABLET_RARITY[rank] or 1)
	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function AddTabletRarities(entry)
	local ranks = GetTabletRanks(entry)
	if #ranks == 0 then return end

	local numbers, legend = {}, {}
	for index, rank in ipairs(ranks) do
		local list = {}
		for number in string.gmatch(StripColor(rank.text), "%d+[%.,]?%d*") do list[#list + 1] = number end
		numbers[index] = list
		legend[index] = RarityHex(rank.rank)..rank.rank.."|r"
	end

	local position = 0
	local text = gsub(StripColor(ranks[#ranks].text), "%d+[%.,]?%d*", function(number)
		position = position + 1
		local same = true
		for index = 1, #numbers do
			if numbers[index][position] ~= number then same = false end
		end
		if same then return number end

		local values = {}
		for index, rank in ipairs(ranks) do
			values[index] = RarityHex(rank.rank)..(numbers[index][position] or "?").."|r"
		end
		return table.concat(values, " / ")
	end)

	GameTooltip:AddLine(table.concat(legend, " / "), 1, 1, 1)
	GameTooltip:AddLine(text, 1, 1, 1, true)
end

local function Tablet_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local entry = self.entry or self.suggestion
	if entry and IsShiftKeyDown() then
		GameTooltip:SetText(entry.name, 1, 1, 1)
		AddTabletRarities(entry)
	elseif self.title then
		GameTooltip:SetText(self.title, 1, 1, 1)
		if self.text ~= "" then
			GameTooltip:AddLine(self.text, 1, 1, 1, true)
		end
	elseif self.suggestion then
		GameTooltip:SetText(self.suggestion.name, .6, .6, .6)
		local description = GetTabletDescription(self.suggestion)
		if description ~= "" then
			GameTooltip:AddLine(description, .6, .6, .6, true)
		end
		GameTooltip:AddLine(L["No ethnography"], 1, .2, .2)
	else
		GameTooltip:SetText(L["Ethnography"], 1, 1, 1)
		GameTooltip:AddLine(L["No ethnography"], 1, .2, .2)
	end
	if entry and not IsShiftKeyDown() then
		GameTooltip:AddLine(L["<Shift: compare rarities>"], .5, .5, .5)
	end
	GameTooltip:Show()
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

local function Tablet_OnEvent(self)
	if GameTooltip:IsOwned(self) then
		Tablet_OnEnter(self)
	else
		self:UnregisterEvent("MODIFIER_STATE_CHANGED")
	end
end

local function Tablet_OnLeave(self)
	self:UnregisterEvent("MODIFIER_STATE_CHANGED")
	GameTooltip_Hide()
end

local function ScanEnchantLine(state, line, plain)
	if not state.tabletIcon then
		local name = strmatch(plain, "^(.-) %(")
		local icon = name and GetTabletIcon(name)
		if icon then
			state.tabletIcon, state.tabletName = icon, name
			state.tabletTitle, state.tabletText = strmatch(line:GetText(), "^([^\n]*)\n?(.*)$")
			state.tabletText = gsub(gsub(state.tabletText, "|r$", ""), "%s*|T[^|]+|t%s*$", "")
			return
		end
	end

	local low = utf8lower(plain)
	if not state.illusion and find(low, "^иллюзия:") then
		state.illusion = plain
	elseif not state.enchant and find(low, "^зачарование:") then
		state.enchant = plain
	end
end

local ENCHANT_PROBE_LINK = "item:6948:"
local enchantLines = {}
local function GetEnchantLine(enchantID)
	local cached = enchantLines[enchantID]
	if cached ~= nil then return cached or nil end

	local tooltip = E.ScanTooltip
	local base = {}
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(ENCHANT_PROBE_LINK.."0")
	for index = 1, tooltip:NumLines() do
		local text = _G["ElvUI_ScanTooltipTextLeft"..index]:GetText()
		if text then base[text] = true end
	end

	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(ENCHANT_PROBE_LINK..enchantID)
	local numLines, line = tooltip:NumLines()
	for index = 1, numLines do
		local text = _G["ElvUI_ScanTooltipTextLeft"..index]:GetText()
		if text and not base[text] then
			line = StripColor(text)
			break
		end
	end
	tooltip:Hide()

	if numLines > 0 then enchantLines[enchantID] = line or false end
	return line
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

local function IsBlackDiamond(itemID, isMeta)
	local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID)
	if classID ~= 3 then return end

	if isMeta then
		return itemID >= 260050 and itemID <= 260071
	end

	return subclassID == 8
end

local function FindBlackDiamond(socketType)
	local isMeta = socketType == "Meta"
	local bestBag, bestSlot, bestID, bestLevel
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID and IsBlackDiamond(itemID, isMeta) then
				local _, _, quality, level = GetItemInfo(itemID)
				local _, _, locked = GetContainerItemInfo(bag, slot)
				level = level or 0
				if quality == 5 and not locked and (not bestLevel or level > bestLevel) then
					bestBag, bestSlot, bestID, bestLevel = bag, slot, itemID, level
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

local function CreateEnchantButton(info)
	local button = CreateFrame("Button", nil, info)
	button:SetTemplate("Default", nil, nil, true)
	button:SetScript("OnEnter", Enchant_OnEnter)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button.slotName = info.slotName
	button:Hide()

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
	button.Icon:SetTexCoord(unpack(E.TexCoords))

	return button
end

local function CreateTabletButton(info)
	local button = CreateFrame("Button", nil, info)
	button:SetTemplate("Default", nil, nil, true)
	button:SetScript("OnEnter", Tablet_OnEnter)
	button:SetScript("OnEvent", Tablet_OnEvent)
	button:SetScript("OnLeave", Tablet_OnLeave)
	button:Hide()

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetTexCoord(unpack(E.TexCoords))

	return button
end

local INFO_ICONS = { { "enchantIcon", "enchant" }, { "tablet", "tablet" } }
local WEAPON_ROW_ALIGN = { MainHandSlot = "RIGHT", SecondaryHandSlot = "", RangedSlot = "LEFT" }

local function CountInfoIcons(info)
	local count = 0
	for _, entry in ipairs(INFO_ICONS) do
		if info[entry[1]]:IsShown() then count = count + 1 end
	end
	return count
end

local function PlaceSocketRow(info, numSockets)
	local slotFrame, anchor, row = info:GetParent(), info.anchor, info.socketRow
	local db = E.db.general.characterInfo
	local position = db.socketPosition or "default"
	local weaponAlign = position == "default" and WEAPON_ROW_ALIGN[info.slotName]
	if position == "default" then position = "BOTTOMLEFT" end
	local x, y = db.socketXOffset or 0, db.socketYOffset or 0
	local numIcons = CountInfoIcons(info)
	local lead = info.iconsInline and numIcons or 0

	local size, step, pixel = GetSocketSize(row)

	row:ClearAllPoints()
	row:SetSize(math.max(numSockets + lead, 1) * step - pixel, size)

	local side, sign = "LEFT", 1
	if anchor == "LEFT" then side, sign = "RIGHT", -1 end

	for index, socket in ipairs(info.slots) do
		socket:SetSize(size, size)
		socket.Icon:SetInside(socket, pixel, pixel, nil, true)
		socket:ClearAllPoints()
		socket:SetPoint(side, row, side, sign * (index - 1 + lead) * step, 0)
	end

	local lineY, iconIndex = 0, 0
	if not info.iconsInline then
		if anchor == "TOP" then
			iconIndex = info.slotName == "RangedSlot" and numSockets or -numIcons
		else
			lineY = step
		end
	end
	for _, entry in ipairs(INFO_ICONS) do
		local icon, key = info[entry[1]], entry[2]
		icon:SetSize(size, size)
		icon.Icon:SetInside(icon, pixel, pixel, nil, true)
		icon:ClearAllPoints()
		if icon:IsShown() then
			local iconPosition, iconX, iconY = db[key.."Position"] or "default", db[key.."XOffset"] or 0, db[key.."YOffset"] or 0
			if iconPosition ~= "default" then
				icon:SetPoint(iconPosition, slotFrame, iconX, iconY)
			else
				icon:SetPoint(side, row, side, iconX + sign * iconIndex * step, lineY + iconY)
				iconIndex = iconIndex + 1
			end
		end
	end

	if anchor == "TOP" then
		local h = weaponAlign or string.find(position, "LEFT") and "LEFT" or string.find(position, "RIGHT") and "RIGHT" or ""
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
	info.enchantIcon = CreateEnchantButton(info)
	info.tablet = CreateTabletButton(info)

	for index = 1, MAX_DISPLAYED_SOCKETS do
		info.slots[index] = CreateSocket(info, index)
	end

	socketInfoFrames[info] = true
	return info
end

local function SetGemSocket(socket, gemLink)
	local _, _, quality = GetItemInfo(gemLink)
	local texture = GetItemIcon(gemLink)

	socket.isEmpty = nil
	socket.gemLink = gemLink
	socket.lineText = nil
	socket.canRemove = quality == 5

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

local function SetEmptySocket(socket, name, color)
	socket.isEmpty = true
	socket.gemLink = nil
	socket.lineText = name
	socket.canRemove = nil

	socket.Icon:SetTexture(E.Media.Textures.NormTex2)
	socket.Icon:SetTexCoord(0, 1, 0, 1)
	socket.Icon:SetVertexColor(unpack(color))

	socket:Show()
end

local function UpdateSocketInfoStyle(info, db)
	local parent = info:GetParent()
	local width, left, bottom = parent:GetWidth(), parent:GetLeft(), parent:GetBottom()
	local pixel = E:PixelSize(1, info.socketRow)
	local icons = CountInfoIcons(info) * 2 + (info.iconsInline and 1 or 0)
	if info.layoutPixel ~= pixel or info.layoutLeft ~= left or info.layoutBottom ~= bottom or
		info.layoutSockets ~= info.numSockets or info.layoutWidth ~= width or info.layoutIcons ~= icons or
		info.layoutSize ~= db.socketSize or info.layoutPosition ~= db.socketPosition or
		info.layoutX ~= db.socketXOffset or info.layoutY ~= db.socketYOffset or
		info.layoutEnchantPosition ~= db.enchantPosition or
		info.layoutEnchantX ~= db.enchantXOffset or info.layoutEnchantY ~= db.enchantYOffset or
		info.layoutTabletPosition ~= db.tabletPosition or
		info.layoutTabletX ~= db.tabletXOffset or info.layoutTabletY ~= db.tabletYOffset then
		ApplySocketInfoLayout(info)
		info.layoutPixel, info.layoutLeft, info.layoutBottom = pixel, left, bottom
		info.layoutSockets, info.layoutWidth, info.layoutIcons = info.numSockets, width, icons
		info.layoutSize, info.layoutPosition = db.socketSize, db.socketPosition
		info.layoutX, info.layoutY = db.socketXOffset, db.socketYOffset
		info.layoutEnchantPosition = db.enchantPosition
		info.layoutEnchantX, info.layoutEnchantY = db.enchantXOffset, db.enchantYOffset
		info.layoutTabletPosition = db.tabletPosition
		info.layoutTabletX, info.layoutTabletY = db.tabletXOffset, db.tabletYOffset
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

local socketRetries = {}

function S:RetrySocketInfo(key, attempts, delay, callback)
	local state = socketRetries[key]
	if not state then
		state = { attempt = 0 }
		socketRetries[key] = state
	end

	if state.timer then E:CancelTimer(state.timer) end

	state.attempt = state.attempt + 1

	if callback() and state.attempt < attempts then
		state.timer = E:ScheduleTimer(function()
			state.timer = nil
			S:RetrySocketInfo(key, attempts, delay, callback)
		end, delay)
	else
		socketRetries[key] = nil
	end
end

function S:ResetSocketRetry(key)
	local state = socketRetries[key]
	if state and state.timer then E:CancelTimer(state.timer) end
	socketRetries[key] = nil
end

local function ScanSocketInfo(unit, inventorySlot, slotName, showGems, showEnchants, iconStyle, showTablets)
	local empty = {}
	local enchantText
	local icon = {}
	local scanIcons = (showEnchants and iconStyle) or showTablets

	local tooltip = E.ScanTooltip
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetInventoryItem(unit, inventorySlot)
	tooltip:Show()

	for index = 1, tooltip:NumLines() do
		local line = _G["ElvUI_ScanTooltipTextLeft"..index]
		local text = line and line:GetText()
		if text then
			local plain = StripColor(text)
			local normalized = utf8lower(plain)
			local socketColor = showGems and SOCKET_COLORS[normalized]
			if socketColor then
				empty[#empty + 1] = { name = plain, color = socketColor }
			else
				if scanIcons then
					ScanEnchantLine(icon, line, plain)
				end
				if showEnchants and not iconStyle and not enchantText then
					enchantText = MatchEnchant(line, plain, normalized, slotName)
				end
			end
		end
		if not showGems and not scanIcons and enchantText then break end
	end

	tooltip:Hide()

	return { empty = empty, enchant = enchantText, icon = icon }
end

function S:HandleSirusEquipmentSocketInfo(slotFrame, inventorySlot, anchor, slotName, unit)
	if not slotFrame or not inventorySlot then return end
	unit = unit or "player"

	local db = E.db.general.characterInfo
	local showForUnit = unit == "player" or db.showOnInspect
	local showGems, showEnchants = db.showGems, db.showEnchants and showForUnit
	local iconStyle = db.enchantStyle == "ICON"
	local showTablets = db.showTablets and showForUnit
	local info = slotFrame.sirusSocketInfo
	if not showGems and not showEnchants and not showTablets then
		if info then info:Hide() end
		return
	end
	if not info then
		info = CreateSocketInfo(slotFrame, anchor or "RIGHT", slotName)
		slotFrame.sirusSocketInfo = info
	end

	local link = GetInventoryItemLink(unit, inventorySlot)
	local numSockets, enchantText, scan = 0
	local hasUnknown = link and not GetItemInfo(link)

	if link and (showGems or showEnchants or showTablets) then
		scan = ScanSocketInfo(unit, inventorySlot, slotName, showGems, showEnchants, iconStyle, showTablets)

		if showGems then
			local nextEmpty = 1
			for index = 1, MAX_DISPLAYED_SOCKETS do
				local socket = info.slots[index]
				local _, gemLink = GetItemGem(link, index)

				if gemLink then
					if not SetGemSocket(socket, gemLink) then
						hasUnknown = true
					end
				elseif scan.empty[nextEmpty] then
					local empty = scan.empty[nextEmpty]
					SetEmptySocket(socket, empty.name, empty.color)
					nextEmpty = nextEmpty + 1
				else
					break
				end

				socket.unit = unit
				socket.inventorySlot = inventorySlot
				numSockets = index
			end
		end

		enchantText = scan.enchant
	end

	for index = numSockets + 1, MAX_DISPLAYED_SOCKETS do
		info.slots[index]:Hide()
	end

	local enchantIcon = info.enchantIcon
	local enchantID = link and tonumber(strmatch(link, "item:%d+:(%d+)")) or 0
	local showEnchantIcon = showEnchants and iconStyle and link and (enchantID ~= 0 or CanEnchant(slotName, link, unit)) and true or false
	if showEnchantIcon then
		local iconScan = scan and scan.icon or {}
		local line, illusion = enchantID ~= 0 and GetEnchantLine(enchantID) or nil, iconScan.illusion
		if line and find(utf8lower(line), "^иллюзия:") then
			illusion, line = illusion or line, iconScan.enchant
		end
		local enchanted = line ~= nil
		enchantIcon.enchantText = line
		enchantIcon.illusionText = illusion
		enchantIcon.Icon:SetDesaturated(not enchanted)
		enchantIcon.Icon:SetAlpha(enchanted and 1 or .6)
		if enchanted then
			enchantIcon:SetBackdropBorderColor(unpack(E.media.bordercolor))
		else
			enchantIcon:SetBackdropBorderColor(1, 0, 0)
		end
	end
	enchantIcon:SetShown(showEnchantIcon)

	local tablet = info.tablet
	local iconScan = scan and scan.icon or {}
	local showTablet = showTablets and link and (iconScan.tabletIcon or TABLET_SLOTS[slotName]) and true or false
	if showTablet then
		if iconScan.tabletIcon then
			tablet.Icon:SetTexture(iconScan.tabletIcon)
			tablet.title, tablet.text, tablet.suggestion = iconScan.tabletTitle, iconScan.tabletText, nil
			tablet.entry = tabletByName[iconScan.tabletName]
			tablet:SetBackdropBorderColor(unpack(E.media.bordercolor))
		else
			LoadTablets()
			local suggestion, pending = GetTabletSuggestion(unit, slotName)
			if pending and unit ~= "player" then hasUnknown = true end
			tablet.Icon:SetTexture(suggestion and suggestion.icon or emptyTabletIcon)
			tablet.title, tablet.text, tablet.suggestion = nil, nil, suggestion
			tablet.entry = nil
			tablet:SetBackdropBorderColor(1, 0, 0)
		end
		tablet.Icon:SetDesaturated(not iconScan.tabletIcon)
		tablet.Icon:SetAlpha(iconScan.tabletIcon and 1 or .6)
	end
	tablet:SetShown(showTablet)

	local showIcons = CountInfoIcons(info) > 0
	info.iconsInline = showIcons and (numSockets == 0 or (info.anchor == "TOP" and numSockets < MAX_DISPLAYED_SOCKETS))
	info.numSockets = numSockets
	UpdateSocketInfoStyle(info, db)

	enchantText = not iconStyle and enchantText and ShortenEnchantText(enchantText) or nil
	info.enchant:SetText(enchantText)
	info.enchant:SetShown(enchantText ~= nil)
	info:SetShown(numSockets > 0 or enchantText ~= nil or showIcons)

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

function S:UpdateEquipmentGradient(slotFrame, slotName, quality)
	if not slotFrame then return end

	local anchor = S.EquipmentSlotAnchors[slotName]
	local gradient = slotFrame.QualityGradient
	if not E.db.general.characterInfo.gearGradient or not quality or (anchor ~= "LEFT" and anchor ~= "RIGHT") then
		if gradient then gradient:Hide() end
		return
	end

	if not gradient then
		gradient = slotFrame:CreateTexture(nil, "BACKGROUND")
		gradient:Size(132, 41)
		gradient:SetTexture(E.Media.Textures.Gradation)
		if anchor == "RIGHT" then
			gradient:SetPoint("LEFT", slotFrame, "LEFT")
		else
			gradient:SetPoint("RIGHT", slotFrame, "RIGHT")
			gradient:SetTexCoord(1, 0, 0, 1)
		end
		slotFrame.QualityGradient = gradient
	end

	gradient:SetVertexColor(E:GetItemQualityColor(quality))
	gradient:Show()
end

local ARMORY_PATH = [[Interface\AddOns\ElvUI\Core\Media\Textures\Armory\]]
local modelBackgrounds = {
	Space = ARMORY_PATH.."Space",
	Castle = ARMORY_PATH.."Castle",
	["Alliance-text"] = ARMORY_PATH.."Alliance-text",
	["Horde-text"] = ARMORY_PATH.."Horde-text",
	["Arena-bliz"] = [[Interface\PVPFrame\PvpBg-NagrandArena-ToastBG]],
	fxpw = ARMORY_PATH.."FXPW",
}
local modelBackgroundParts = { "BackgroundTopLeft", "BackgroundTopRight", "BackgroundBotLeft", "BackgroundBotRight" }

function S:UpdateModelBackground(model, unit)
	local overlay = model and model.BackgroundOverlay
	if not overlay then return end

	local db = E.db.general.characterInfo
	local choice = db.modelBackground
	local isDefault = choice == "DEFAULT"

	for _, key in ipairs(modelBackgroundParts) do
		if model[key] then
			model[key]:SetShown(isDefault)
		end
	end

	if isDefault then
		overlay:SetTexture(0, 0, 0)
		overlay:SetAlpha(_G.GetDressUpTextureAlpha(unit or "player"))
		return
	end

	local texture
	if choice == "CUSTOM" then
		texture = db.modelBackgroundCustom
	elseif choice == "CLASS" then
		local _, class = UnitClass(unit or "player")
		texture = class and ARMORY_PATH..class
	elseif choice ~= "HIDE" then
		texture = modelBackgrounds[choice]
	end

	overlay:SetTexture(texture ~= "" and texture or nil)
	overlay:SetAlpha(1)
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

	S:UpdateTabSelected(tab, S:IsTabSelected(tab))

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

local function UpdateTabSystemSelected(tab, isSelected)
	S:UpdateTabSelected(tab, isSelected)
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

			if tab.SetTabSelected then
				hooksecurefunc(tab, "SetTabSelected", UpdateTabSystemSelected)
				S:UpdateTabSelected(tab, tab.isSelected)
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

function S:HandleSirusTutorialButton(btn)
	if not btn then
		return
	end
	if btn.backdrop then
		btn.backdrop:Hide()
	end
	local icon = btn.HelpI or btn.I
	if icon then
		icon:SetAllPoints(btn)
		icon:SetDrawLayer("ARTWORK")
		icon:SetVertexColor(1, 1, 1)
	end
	local ht = (btn.GetHighlightTexture and btn:GetHighlightTexture()) or btn.HighlightTexture
	if not ht then
		ht = btn:CreateTexture(nil, "HIGHLIGHT")
		ht:SetAllPoints(btn)
		btn.HighlightTexture = ht
	end
	if btn.Ring then
		btn.Ring:SetAlpha(0)
		ht:SetAllPoints(btn)
	end
	S:HandleButtonHighlight(ht, 1, 1, 1, 0.25)
	if btn.SetHitRectInsets then
		btn:SetHitRectInsets(4, 4, 4, 4)
	end
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

	local function SkinArrow(arrow)
		if not arrow or arrow.elvArrowSkinned then return end
		arrow.elvArrowSkinned = true

		local function HideClientState()
			for _, key in next, { 'NormalTexture', 'PushedTexture', 'HighlightTexture' } do
				local texture = arrow[key]
				if texture then texture:SetAlpha(0) end
			end
		end

		HideClientState()

		if arrow.Art then
			arrow.Art:SetVertexColor(1, 1, 1)

			arrow:HookScript('OnEnter', function()
				HideClientState()
				arrow.Art:SetVertexColor(1, 0.82, 0)
			end)

			arrow:HookScript('OnLeave', function()
				arrow.Art:SetVertexColor(1, 1, 1)
			end)
		end
	end

	local function SkinButton(button)
		if not button or button.isSkinned then return end
		S:HandleButton(button, true)
		S:ApplyElvUIFont(button)
		button.xoffset = 1

		SkinArrow(button.MenuArrowButton)

		button.isSkinned = true
	end

	local function SkinButtons()
		SkinButton(navBar.home)

		if navBar.navList then
			for _, button in ipairs(navBar.navList) do
				SkinButton(button)
			end
		end
	end

	SkinButtons()
	navBar:HookScript('OnShow', SkinButtons)

	if _G.NavBar_AddButton then
		hooksecurefunc('NavBar_AddButton', function(self)
			if self ~= navBar then return end
			SkinButton(self.navList[#self.navList])
		end)
	end

	navBar.isSkinned = true
end
