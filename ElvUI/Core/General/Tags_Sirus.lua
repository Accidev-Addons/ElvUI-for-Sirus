local E, L, V, P, G = unpack(ElvUI)
local ElvUF = E.oUF

local _G = _G
local ipairs, select, type = ipairs, select, type
local tonumber, unpack, format = tonumber, unpack, format
local gsub, strmatch = gsub, strmatch
local floor, pcall = floor, pcall

local LibStub = LibStub
local CheckInteractDistance = CheckInteractDistance
local CreateFrame = CreateFrame
local HasPetUI = HasPetUI
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHealthMax = UnitHealthMax
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit

local C_Unit, C_Inspect = C_Unit, C_Inspect
local UnitAura, UnitRace = UnitAura, UnitRace
local GetPetHappiness = GetPetHappiness
local GetItemLevelColor = GetItemLevelColor
local GetOnslaughtRating = GetOnslaughtRating
local GetUnitRatedBattlegroundRankInfo = GetUnitRatedBattlegroundRankInfo
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local S_PREMIUM_SPELL_ID = _G.S_PREMIUM_SPELL_ID

-- Sirus: server specific tags. Everything is read from the live aura data instead of
-- hardcoded spellID tables, so categories/VIP tiers added server side keep working.

local ICON_FORMAT = '|T%s:18:18:0:0:64:64:4:60:4:60|t'
local SIRUS_ENABLED = C_Unit and C_Unit.GetCategoryInfo and true or false

local function ServiceAura(unit, spellID)
	if not spellID then return end

	local index = C_Unit.GetAuraIndexForSpellID(unit, spellID, 'HARMFUL')
	if not index then return end

	local name, _, icon = UnitAura(unit, index, 'HARMFUL')
	return name, icon
end

local function CategoryName(unit)
	local fallback, spellID = C_Unit.GetCategoryInfo(unit)
	if not spellID then return end

	local name = ServiceAura(unit, spellID)
	return name or fallback, spellID
end

-- '1-я (++++++) Категория' -> '1-я (++++++)'. Cyrillic is multibyte, so no character classes here.
local function StripCategoryWord(name)
	local head = strmatch(name, '^(.-)%s*Категория%s*$') or strmatch(name, '^(.-)%s*категория%s*$')
	if head and head ~= '' then return head end

	head = gsub(name, 'Вне категории', 'В.К.')
	return (gsub(head, 'Вне котегории', 'В.К.'))
end

-- '1-я (++++++)' -> '1-я (6+)'
local function CompactPluses(name)
	return (gsub(name, '%((%++)%)', function(plus) return format('(%d+)', #plus) end))
end

if SIRUS_ENABLED then
	E:AddTag('category:name', 'UNIT_AURA', function(unit)
		return (CategoryName(unit))
	end)

	E:AddTag('category:name:short', 'UNIT_AURA', function(unit)
		local name = CategoryName(unit)
		if name then return StripCategoryWord(name) end
	end)

	E:AddTag('category:name:veryshort', 'UNIT_AURA', function(unit)
		local name = CategoryName(unit)
		if name then return CompactPluses(StripCategoryWord(name)) end
	end)

	E:AddTag('category:sirus', 'UNIT_AURA', function(unit)
		local name = CategoryName(unit)
		if name then return CompactPluses(StripCategoryWord(name)) end
	end)

	E:AddTag('category:icon', 'UNIT_AURA', function(unit)
		local _, spellID = C_Unit.GetCategoryInfo(unit)
		local _, icon = ServiceAura(unit, spellID)
		if icon then return format(ICON_FORMAT, icon) end
	end)

	E:AddTag('vip:name', 'UNIT_AURA', function(unit)
		local info = C_Unit.GetClassification(unit)
		if info and info.vipSpellID then
			return info.vipName or (ServiceAura(unit, info.vipSpellID))
		end
	end)

	E:AddTag('vip:icon', 'UNIT_AURA', function(unit)
		local info = C_Unit.GetClassification(unit)
		if info and info.vipSpellID then
			local _, icon = ServiceAura(unit, info.vipSpellID)
			if icon then return format(ICON_FORMAT, icon) end
		end
	end)

	local function PremiumAura(unit)
		if not S_PREMIUM_SPELL_ID then return end

		local index = C_Unit.FindAuraBySpell(unit, S_PREMIUM_SPELL_ID, 'HARMFUL')
		if not index then return end

		local name, _, icon = UnitAura(unit, index, 'HARMFUL')
		return name, icon
	end

	E:AddTag('premium:name', 'UNIT_AURA', function(unit)
		return (PremiumAura(unit))
	end)

	E:AddTag('premium:name:short', 'UNIT_AURA', function(unit)
		if PremiumAura(unit) then return '(P)' end
	end)

	E:AddTag('premium:icon', 'UNIT_AURA', function(unit)
		local _, icon = PremiumAura(unit)
		if icon then return format(ICON_FORMAT, icon) end
	end)

	E:AddTag('zodiac:name', 'UNIT_AURA', function(unit)
		return (select(2, C_Unit.GetZodiacByDebuff(unit)))
	end)

	E:AddTag('zodiac:icon', 'UNIT_AURA', function(unit)
		local icon = select(4, C_Unit.GetZodiacByDebuff(unit))
		if icon then return format(ICON_FORMAT, icon) end
	end)

	E:AddTag('classification:sirus', 'UNIT_CLASSIFICATION_CHANGED UNIT_AURA', function(unit)
		local info = C_Unit.GetClassification(unit)
		if not info then return end

		if info.vipName then return info.vipName end

		local c = info.classification
		if c == 'worldboss' then return L["Boss"]
		elseif c == 'rareelite' then return L["Rare Elite"]
		elseif c == 'elite' then return L["Elite"]
		elseif c == 'rare' then return L["Rare"] end
	end)

	-- the server answers a rank request asynchronously; refresh the waiting frames when it lands
	local pending = {}
	if _G.EventHandler and _G.EventHandler.RegisterListener then
		_G.EventHandler:RegisterListener({
			ASMSG_CHARACTER_BG_INFO = function(_, msg)
				local guid = tonumber(strmatch(msg, '^(.-)|'))
				local waiting = guid and pending[guid]
				if not waiting then return end

				pending[guid] = nil

				for _, frame in ipairs(ElvUF.objects) do
					if frame.unit == waiting and frame.UpdateTags then
						frame:UpdateTags()
					end
				end
			end
		})
	end

	local function RatedBGRank(unit)
		if not UnitIsPlayer(unit) then return end

		local title, rankID, coords = GetUnitRatedBattlegroundRankInfo(unit)
		if title then return title, rankID, coords end

		local guid = tonumber(UnitGUID(unit) or '')
		if guid then pending[guid] = unit end
	end

	E:AddTag('pvp:name', 'UNIT_FACTION UNIT_TARGET', function(unit)
		return (RatedBGRank(unit))
	end)

	E:AddTag('pvp:id', 'UNIT_FACTION UNIT_TARGET', function(unit)
		return (select(2, RatedBGRank(unit)))
	end)

	E:AddTag('pvp:icon', 'UNIT_FACTION UNIT_TARGET', function(unit)
		local coords = select(3, RatedBGRank(unit))
		if type(coords) ~= 'table' then return end

		local left, right, top, bottom = unpack(coords)
		if not bottom then return end

		return format('|T%s:18:18:0:0:1024:512:%d:%d:%d:%d|t', 'Interface\\PVPFrame\\PvPPrestigeIcons', left * 1024, right * 1024, top * 512, bottom * 512)
	end)

	local ilvlPending = {}
	local ilvlUpdater = CreateFrame('Frame')

	ilvlUpdater:SetScript('OnEvent', function(_, event, guid)
		if event == 'PLAYER_AVG_ITEM_LEVEL_READY' then
			guid = UnitGUID('player')
		end

		if not guid or not ilvlPending[guid] then return end
		ilvlPending[guid] = nil

		for _, frame in ipairs(ElvUF.objects) do
			if frame.unit and frame.UpdateTags and UnitGUID(frame.unit) == guid then
				frame:UpdateTags()
			end
		end
	end)

	if ilvlUpdater.RegisterCustomEvent then
		ilvlUpdater:RegisterCustomEvent('INSPECT_ITEM_LEVEL_UPDATE')
		ilvlUpdater:RegisterCustomEvent('PLAYER_AVG_ITEM_LEVEL_READY')
	end

	E:AddTag('ilvl', 'UNIT_INVENTORY_CHANGED UNIT_TARGET UNIT_NAME_UPDATE', function(unit)
		if not UnitIsPlayer(unit) or UnitCanAttack(unit, 'player') then return end

		local ilvl = C_Inspect.GetAvgItemLevel(unit)
		if not ilvl or ilvl == 0 then
			local guid = UnitGUID(unit)
			if guid then ilvlPending[guid] = true end

			C_Inspect.RequestAvgItemLevel(unit)
			return
		end

		local color = GetItemLevelColor(ilvl)
		local hex = color and color.GenerateHexColor and color:GenerateHexColor()

		return hex and format('|c%s%d|r', hex, ilvl) or ilvl
	end)
end

local RACE_ABBREV = {
	Human = 'Чл.', Dwarf = 'Дв.', Gnome = 'Гн.', Draenei = 'Др.', Worgen = 'Вр.',
	NightElf = 'Нэ.', Queldo = 'Вэ.', VoidElf = 'Эб.', DarkIronDwarf = 'Дчж.',
	Lightforged = 'ОДр.', Pandaren = 'Пн.', Vulpera = 'Вп.', Orc = 'Орк',
	Scourge = 'Отр.', Tauren = 'Тн.', Troll = 'Тр.', Goblin = 'Гб.', Naga = 'Нг.',
	BloodElf = 'Сн.', Nightborne = 'Нр.', Eredar = 'Эрд.', ZandalariTroll = 'Зн.',
	Dracthyr = 'Драк.'
}

E:AddTag('race:abbrev', 'UNIT_NAME_UPDATE UNIT_TARGET', function(unit)
	if UnitIsPlayer(unit) then
		return RACE_ABBREV[select(2, UnitRace(unit))]
	end
end)

local HAPPINESS_ICONS = {
	[[|TInterface\PetPaperDollFrame\UI-PetHappiness:16:16:0:0:128:64:48:72:0:23|t]],
	[[|TInterface\PetPaperDollFrame\UI-PetHappiness:16:16:0:0:128:64:24:48:0:23|t]],
	[[|TInterface\PetPaperDollFrame\UI-PetHappiness:16:16:0:0:128:64:0:24:0:23|t]]
}

local HAPPINESS_FACES = { ':<', ':|', ':D' }

E:AddTag('happiness', 'UNIT_HAPPINESS PET_UI_UPDATE', function(unit)
	if UnitIsUnit(unit, 'pet') then
		return HAPPINESS_FACES[GetPetHappiness() or 0]
	end
end)

E:AddTag('happiness:icon', 'UNIT_HAPPINESS PET_UI_UPDATE', function(unit)
	local hasPetUI, isHunterPet = HasPetUI()
	if hasPetUI and isHunterPet and UnitIsUnit(unit, 'pet') then
		return HAPPINESS_ICONS[GetPetHappiness() or 0]
	end
end)

if GetOnslaughtRating then
	E:AddTag('onslaught', 'UNIT_STATS', function(unit)
		if UnitIsPlayer(unit) then
			return GetOnslaughtRating()
		end
	end)

	E:AddTagInfo('onslaught', 'Sirus', "Показывает рейтинг натиска")
end

local LRC

local function RangeCheckLib()
	if not LRC and LibStub then
		LRC = LibStub('LibRangeCheck-2.0', true)
	end

	return LRC
end

local function LibRange(unit)
	local lib = RangeCheckLib()
	if not lib or not lib.GetRange then return end

	local ok, minRange, maxRange = pcall(lib.GetRange, lib, unit)
	if ok then return minRange, maxRange end
end

local INTERACT_RANGE = { '0-10', '10-11', '11-28', '>28' }
local INTERACT_COMPARE = { '<10', '<11', '<28', '>28' }

local function InteractStep(unit)
	if not CheckInteractDistance then return end

	if CheckInteractDistance(unit, 3) then
		return 1
	elseif CheckInteractDistance(unit, 2) then
		return 2
	elseif CheckInteractDistance(unit, 1) then
		return 3
	end

	return 4
end

E:AddTag('distance:check', 0.2, function(unit)
	if not UnitExists(unit) then return end

	local minRange, maxRange = LibRange(unit)
	if minRange and maxRange then
		return format('%d-%d', floor(minRange), floor(maxRange))
	elseif minRange then
		return format('>%d', floor(minRange))
	elseif maxRange then
		return format('<%d', floor(maxRange))
	end

	return INTERACT_RANGE[InteractStep(unit) or 0]
end)

E:AddTag('distance:check:compare', 0.2, function(unit)
	if not UnitExists(unit) then return end

	local minRange, maxRange = LibRange(unit)
	if minRange and maxRange then
		return format('>%d <%d', floor(minRange), floor(maxRange))
	elseif minRange then
		return format('>%d', floor(minRange))
	elseif maxRange then
		return format('<%d', floor(maxRange))
	end

	return INTERACT_COMPARE[InteractStep(unit) or 0]
end)

if UnitGetTotalAbsorbs then
	local ABSORB_EVENTS = 'UNIT_ABSORB_AMOUNT_CHANGED UNIT_AURA UNIT_MAXHEALTH'

	E:AddTag('absorbs', ABSORB_EVENTS, function(unit)
		local absorb = UnitGetTotalAbsorbs(unit) or 0
		if absorb > 0 then
			return E:ShortValue(absorb)
		end
	end)

	E:AddTag('absorbs()', ABSORB_EVENTS, function(unit)
		local absorb = UnitGetTotalAbsorbs(unit) or 0
		if absorb > 0 then
			return format('(%s)', E:ShortValue(absorb))
		end
	end)

	E:AddTag('absorbs:percent', ABSORB_EVENTS, function(unit)
		local absorb = UnitGetTotalAbsorbs(unit) or 0
		local maxHealth = UnitHealthMax(unit)
		if absorb > 0 and maxHealth > 0 then
			return format('%.1f%%', (absorb / maxHealth) * 100)
		end
	end)

	E:AddTag('absorbsall', ABSORB_EVENTS, function(unit)
		local absorb = (UnitGetTotalAbsorbs(unit) or 0) + (UnitGetTotalHealAbsorbs and UnitGetTotalHealAbsorbs(unit) or 0)
		if absorb > 0 then
			return E:ShortValue(absorb)
		end
	end)

	E:AddTagInfo('absorbs', 'Sirus', "Показывает величину поглощения (сокращённо)")
	E:AddTagInfo('absorbs()', 'Sirus', "Показывает величину поглощения в скобках")
	E:AddTagInfo('absorbs:percent', 'Sirus', "Показывает величину поглощения в процентах от максимума здоровья")
	E:AddTagInfo('absorbsall', 'Sirus', "Показывает сумму поглощения урона и поглощения лечения")
end

if SIRUS_ENABLED then
	E:AddTagInfo('category:name', 'Sirus', "Показывает категорию юнита в виде текста")
	E:AddTagInfo('category:name:short', 'Sirus', "Показывает категорию юнита без слова «Категория»")
	E:AddTagInfo('category:name:veryshort', 'Sirus', "Показывает категорию юнита кратко: 1-я (6+)")
	E:AddTagInfo('category:sirus', 'Sirus', "Показывает категорию юнита кратко: 1-я (6+)")
	E:AddTagInfo('category:icon', 'Sirus', "Показывает категорию юнита в виде иконки")
	E:AddTagInfo('vip:name', 'Sirus', "Показывает VIP статус юнита в виде текста")
	E:AddTagInfo('vip:icon', 'Sirus', "Показывает VIP статус юнита в виде иконки")
	E:AddTagInfo('premium:name', 'Sirus', "Показывает Premium статус юнита в виде текста")
	E:AddTagInfo('premium:name:short', 'Sirus', "Показывает Premium статус юнита как (P)")
	E:AddTagInfo('premium:icon', 'Sirus', "Показывает Premium статус юнита в виде иконки")
	E:AddTagInfo('pvp:name', 'Sirus', "Показывает PvP ранг юнита в виде текста")
	E:AddTagInfo('pvp:id', 'Sirus', "Показывает PvP ранг юнита в виде ID")
	E:AddTagInfo('pvp:icon', 'Sirus', "Показывает PvP ранг юнита в виде иконки")
	E:AddTagInfo('zodiac:name', 'Sirus', "Показывает знак зодиака в виде текста")
	E:AddTagInfo('zodiac:icon', 'Sirus', "Показывает знак зодиака в виде иконки")
	E:AddTagInfo('classification:sirus', 'Sirus', "Показывает классификацию с учётом VIP статуса")
	E:AddTagInfo('ilvl', 'Sirus', "Показывает средний уровень предметов юнита")
end

E:AddTagInfo('race:abbrev', 'Sirus', "Показывает расу юнита сокращённо")
E:AddTagInfo('happiness', 'Sirus', "Показывает счастье питомца текстом")
E:AddTagInfo('happiness:icon', 'Sirus', "Показывает счастье питомца иконкой")
E:AddTagInfo('distance:check', 'Sirus', "Показывает дистанцию до юнита диапазоном: 20-25 (без LibRangeCheck: 0-10/10-11/11-28/>28)")
E:AddTagInfo('distance:check:compare', 'Sirus', "Показывает дистанцию до юнита сравнением: >20 <25 (без LibRangeCheck: <10/<11/<28/>28)")
