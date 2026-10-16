local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule('Minimap')
local LSM = E.Libs.LSM

local RB = E:GetModule('ReminderBuffs', true) or E:NewModule('ReminderBuffs', 'AceEvent-3.0')

local _G = _G
local ipairs, pairs, tonumber, type = ipairs, pairs, tonumber, type
local hooksecurefunc = hooksecurefunc

local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitAura = UnitAura

local Minimap = _G.Minimap

-------------------------------------------------------------
-- Settings
-------------------------------------------------------------
-- Порядок кнопок = порядок ключей в настройках
RB.SlotKeys = { 'pot', 'food', 'drubuff', 'palcask', 'inta', 'palmp5', 'oil' }

RB.Defaults = {
	enable = true,
	durations = true,
	reverse = true,
	position = 'LEFT',
	keepButtonSizeRatio = true,
	height = 32,
	font = 'PT Sans Narrow',
	fontSize = 12,
	fontOutline = 'OUTLINE',
	pot = true,
	food = true,
	drubuff = true,
	palcask = true,
	inta = true,
	palmp5 = true,
	oil = true,
}

-- Если профильных дефолтов ещё нет (файла Settings/Profile.lua у нас нет), регистрируем их здесь
if P.general and not P.general.reminder then
	P.general.reminder = E:CopyTable({}, RB.Defaults)
end

function RB:SetupDB()
	local general = E.db.general
	if type(general.reminder) ~= 'table' then
		general.reminder = {}
	end

	for key, value in pairs(RB.Defaults) do
		if general.reminder[key] == nil then
			general.reminder[key] = value
		end
	end

	RB.db = general.reminder
end

-------------------------------------------------------------
-- Buff lists
-------------------------------------------------------------
RB.Spell1Buffs = {
	67016, -- Flask of the North (SP)
	67017, -- Flask of the North (AP)
	67018, -- Flask of the North (STR)
	53755, -- Flask of the Frost Wyrm
	53758, -- Flask of Stoneblood
	53760, -- Flask of Endless Rage
	54212, -- Flask of Pure Mojo
	53752, -- Lesser Flask of Toughness (50 Resilience)
	17627, -- Flask of Distilled Wisdom
	270006, -- Настой сопротивления
	270007, -- Настой Драконьего разума
	270008, -- Настой Сила титана
	270009, -- Настой Текущей воды
	270010, -- Настой Стальной Кожи
	270011, -- Настой Крепости

	33721, -- Spellpower Elixir
	53746, -- Wrath Elixir
	28497, -- Elixir of Mighty Agility
	53748, -- Elixir of Mighty Strength
	60346, -- Elixir of Lightning Speed
	60344, -- Elixir of Expertise
	60341, -- Elixir of Deadly Strikes
	60345, -- Elixir of Armor Piercing
	60340, -- Elixir of Accuracy
	53749, -- Guru's Elixir

	60343, -- Elixir of Mighty Defense
	53751, -- Elixir of Mighty Fortitude
	53764, -- Elixir of Mighty Mageblood
	60347, -- Elixir of Mighty Thoughts
	53763, -- Elixir of Protection
	53747, -- Elixir of Spirit
	46837, -- shattrat elixirs
	46839, -- shattrat elixirs
	41609, -- shattrat elixirs
	41610, -- shattrat elixirs
	41611, -- shattrat elixirs
	41608, -- shattrat elixirs
	45373, -- shattrat elixirs
}

RB.Spell2Buffs = {
	57325, -- 80 AP
	57327, -- 46 SP
	57329, -- 40 Critical Strike Rating
	57332, -- 40 Haste Rating
	57334, -- 20 MP5
	57356, -- 40 Expertise Rating
	57358, -- 40 ARP
	57360, -- 40 Hit Rating
	57363, -- Tracking Humanoids
	57365, -- 40 Spirit
	57367, -- 40 AGI
	57371, -- 40 STR
	57373, -- Tracking Beasts
	57399, -- 80 AP, 46 SP
	59230, -- 40 Dodge Rating
	65247, -- 20 STR
}

RB.Spell3Buffs = {
	72588, -- Gift of the Wild
	48469, -- Mark of the Wild
}

RB.Spell4Buffs = {
	25898, -- Greater Blessing of Kings
	20217, -- Blessing of Kings
	72586, -- Blessing of Forgotten Kings
}

RB.CasterSpell5Buffs = {
	61316, -- Dalaran Brilliance
	61024, -- Dalaran Brilliance
	43002, -- Arcane Brilliance
	42995, -- Arcane Intellect
}

RB.MeleeSpell5Buffs = {
	48162, -- Prayer of Fortitude
	48161, -- Power Word: Fortitude
	72590, -- Fortitude
}

RB.CasterSpell6Buffs = {
	48938, -- Greater Blessing of Wisdom
	48936, -- Blessing of Wisdom
	58777, -- Mana Spring
}

RB.MeleeSpell6Buffs = {
	48934, -- Greater Blessing of Might
	48932, -- Blessing of Might
	47436, -- Battle Shout
	150000, -- mythic buff ap
}

RB.CasterSpell7Buffs = {
	317727, -- caster oil
}

RB.MeleeSpell7Buffs = {
	317728, -- melee oil
}

-------------------------------------------------------------
-- Sizes
-------------------------------------------------------------
function RB:GetButtonSize()
	local db = RB.db
	local minimapSize = E.MinimapSize or (Minimap and Minimap:GetHeight()) or 140
	local gap = E.Border - E.Spacing * 3

	-- 7 кнопок на высоту миникарты (как в старой версии)
	local width = (minimapSize - gap * 6) / 7
	local height = width

	if db.keepButtonSizeRatio == false and db.height and db.height > 0 then
		height = db.height
	end

	return width, height, gap, minimapSize
end

-------------------------------------------------------------
-- Масло (оружейное/нагрудное усиление Sirus): время берём из тултипа предмета
-------------------------------------------------------------
RB.remainingTime = 0

local function ParseRemainingTime(text)
	local hours = tonumber(text:match('(%d+)%s*час')) or 0
	local mins = tonumber(text:match('(%d+)%s*мин')) or 0
	-- в старом коде первая буква "c" была латинской, поэтому проверяем оба варианта
	local secs = tonumber(text:match('(%d+)%s*сек')) or tonumber(text:match('(%d+)%s*cек')) or 0

	return hours * 3600 + mins * 60 + secs
end

function RB:ScanOilTime()
	local tip = self.oilTooltip
	if not tip then
		tip = CreateFrame('GameTooltip', 'ElvUI_ReminderBuffsTooltip', nil, 'GameTooltipTemplate')
		self.oilTooltip = tip
	end

	tip:SetOwner(E.UIParent, 'ANCHOR_NONE')
	tip:ClearLines()
	tip:SetInventoryItem('player', 5)

	local remaining = 0
	for i = 1, tip:NumLines() do
		local line = _G['ElvUI_ReminderBuffsTooltipTextLeft'..i]
		local text = line and line:GetText()

		if text and (text:find('+52 к силе заклинаний', 1, true) or text:find('+90 к силе атаки', 1, true)) then
			remaining = ParseRemainingTime(text)
			break
		end
	end

	self.remainingTime = remaining
end

-------------------------------------------------------------
-- Поиск активного баффа
-------------------------------------------------------------
function RB:FindBuff(filter, isOil)
	if not filter then return end

	for _, spell in ipairs(filter) do
		local spellName = GetSpellInfo(spell)
		if spellName then
			local name, _, texture, _, _, duration, expirationTime = UnitAura('player', spellName)
			if name then
				if isOil then
					RB:ScanOilTime()
					return texture, 3600, RB.remainingTime + GetTime()
				end

				return texture, duration, expirationTime
			end
		end
	end
end

-------------------------------------------------------------
-- Таймер на кнопке
-------------------------------------------------------------
local function SetButtonCooldown(cd, start, duration)
	if _G.CooldownFrame_SetTimer then
		_G.CooldownFrame_SetTimer(cd, start, duration, (duration and duration > 0) and 1 or 0)
	else
		cd:SetCooldown(start, duration)
	end
end

function RB:UpdateReminderTime(elapsed)
	self.expiration = self.expiration - elapsed

	if self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
		return
	end

	if self.expiration <= 0 then
		self.timer:SetText('')
		self:SetScript('OnUpdate', nil)
		return
	end

	local value, id, nextUpdate, remainder = E:GetTimeInfo(self.expiration, 4)
	self.nextUpdate = nextUpdate

	local style = E.TimeFormats[id]
	if style then
		self.timer:SetFormattedText(style[1], value, remainder)
	end
end

-- Приглушённая (серая) или обычная иконка
local function SetDimmed(button, dimmed)
	if dimmed then
		if button.t.SetDesaturated then
			button.t:SetDesaturated(true)
		end
		button.t:SetVertexColor(0.6, 0.6, 0.6)
		button.t:SetAlpha(0.5)
	else
		if button.t.SetDesaturated then
			button.t:SetDesaturated(false)
		end
		button.t:SetVertexColor(1, 1, 1)
		button.t:SetAlpha(1)
	end
end

function RB:UpdateReminder(event, unit)
	if not self.frame or not self.db then return end
	if event == 'UNIT_AURA' and unit ~= 'player' then return end
	if event == 'UNIT_INVENTORY_CHANGED' and unit ~= 'player' then return end

	local db = self.db

	for i = 1, 7 do
		local button = self.frame[i]

		if db[RB.SlotKeys[i]] then
			local texture, duration, expirationTime = self:FindBuff(self['Spell'..i..'Buffs'], i == 7)

			if texture then
				button.t:SetTexture(texture)

				if (duration == 0 and expirationTime == 0) or db.durations ~= true then
					SetDimmed(button, not db.reverse)
					button:SetScript('OnUpdate', nil)
					button.timer:SetText('')
					SetButtonCooldown(button.cd, 0, 0)
				else
					button.expiration = expirationTime - GetTime()
					button.nextUpdate = 0
					SetDimmed(button, false)
					SetButtonCooldown(button.cd, expirationTime - duration, duration)
					button.cd:SetReverse(db.reverse)
					button:SetScript('OnUpdate', self.UpdateReminderTime)
				end
			else
				SetButtonCooldown(button.cd, 0, 0)
				button:SetScript('OnUpdate', nil)
				button.timer:SetText('')
				button.t:SetTexture(self.DefaultIcons[i])
				SetDimmed(button, db.reverse)
			end
		end
	end
end

-------------------------------------------------------------
-- Создание и настройка
-------------------------------------------------------------
function RB:CreateButton(parent)
	local button = CreateFrame('Button', nil, parent)
	button:SetTemplate('Default')

	button.t = button:CreateTexture(nil, 'OVERLAY')
	button.t:SetInside()
	button.t:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])

	button.cd = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	button.cd:SetInside()
	button.cd.noOCC = true
	button.cd.noCooldownCount = true

	button.timer = button.cd:CreateFontString(nil, 'OVERLAY')
	button.timer:SetPoint('CENTER')

	return button
end

function RB:UpdateDefaultIcons()
	local caster = E.Role == 'Caster'

	self.DefaultIcons = {
		[1] = [[Interface\Icons\INV_Potion_97]],
		[2] = [[Interface\Icons\Spell_Misc_Food]],
		[3] = [[Interface\Icons\Spell_Nature_Regeneration]],
		[4] = [[Interface\Icons\Spell_Magic_GreaterBlessingofKings]],
		[5] = caster and [[Interface\Icons\Spell_Holy_MagicalSentry]] or [[Interface\Icons\Spell_Holy_WordFortitude]],
		[6] = caster and [[Interface\Icons\Spell_Holy_GreaterBlessingofWisdom]] or [[Interface\Icons\Ability_Warrior_BattleShout]],
		[7] = [[Interface\Icons\INV_Potion_141]],
	}

	self.Spell5Buffs = caster and self.CasterSpell5Buffs or self.MeleeSpell5Buffs
	self.Spell6Buffs = caster and self.CasterSpell6Buffs or self.MeleeSpell6Buffs
	self.Spell7Buffs = caster and self.CasterSpell7Buffs or self.MeleeSpell7Buffs
end

function RB:EnableRB()
	self.frame:Show()

	self:RegisterEvent('UNIT_AURA', 'UpdateReminder')
	self:RegisterEvent('UNIT_INVENTORY_CHANGED', 'UpdateReminder')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateReminder')
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', 'UpdateSettings')
	self:RegisterEvent('CHARACTER_POINTS_CHANGED', 'UpdateSettings')

	if E.RegisterCallback then
		E.RegisterCallback(self, 'RoleChanged', 'UpdateSettings')
	end
end

function RB:DisableRB()
	self.frame:Hide()

	self:UnregisterEvent('UNIT_AURA')
	self:UnregisterEvent('UNIT_INVENTORY_CHANGED')
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
	self:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	self:UnregisterEvent('CHARACTER_POINTS_CHANGED')

	if E.UnregisterCallback then
		E.UnregisterCallback(self, 'RoleChanged', 'UpdateSettings')
	end
end

function RB:UpdateSettings()
	local frame = self.frame
	if not frame then return end

	local db = self.db
	local width, height, gap, minimapSize = self:GetButtonSize()
	local font = LSM:Fetch('font', db.font)

	self:UpdateDefaultIcons()
	frame:Size(width, minimapSize)

	local shown = 0
	for i = 1, 7 do
		local button = frame[i]
		button:ClearAllPoints()

		if db[RB.SlotKeys[i]] then
			button:Size(width, height)

			if db.keepButtonSizeRatio ~= false then
				button.t:SetTexCoords()
			else
				button.t:SetTexCoord(E:CropRatio(width, height))
			end

			button.cd:SetAlpha(db.durations and 1 or 0)
			button.timer:FontTemplate(font, db.fontSize, db.fontOutline)

			button:Point('TOP', frame, 'TOP', 0, -shown * (height + gap))
			button:Show()

			shown = shown + 1
		else
			button:SetScript('OnUpdate', nil)
			button:Hide()
		end
	end

	if db.enable then
		self:EnableRB()
		self:UpdateReminder()
	else
		self:DisableRB()
	end
end

-- Сторона миникарты: LEFT - слева, RIGHT - справа
function RB:GetAnchor()
	local offset = 6 + E.Border

	if RB.db.position == 'RIGHT' then
		return 'TOPLEFT', Minimap, 'TOPRIGHT', offset, 0
	end

	return 'TOPRIGHT', Minimap, 'TOPLEFT', -offset, 0
end

-- Опция Position: переставляет колонку на выбранную сторону миникарты
function RB:UpdatePosition()
	local frame = self.frame
	if not frame then return end

	local mover = _G.ReminderBuffsMover
	local target = mover or frame

	target:ClearAllPoints()
	target:Point(self:GetAnchor())

	if mover and E.SaveMoverPosition then
		E:SaveMoverPosition('ReminderBuffsMover')
	end
end

function RB:Initialize()
	self:SetupDB()

	local frame = CreateFrame('Frame', 'ElvUI_ReminderBuffs', E.UIParent)
	frame:Point(self:GetAnchor())
	self.frame = frame

	for i = 1, 7 do
		frame[i] = self:CreateButton(frame)
		frame[i]:SetID(i)
	end

	self:UpdateSettings()

	E:CreateMover(frame, 'ReminderBuffsMover', L['Reminder Buffs'], nil, nil, nil, nil, nil, 'maps,minimap,reminder')

	-- размер миникарты поменялся -> пересчитать размер кнопок
	hooksecurefunc(M, 'UpdateSettings', function()
		if RB.frame then
			RB:UpdateSettings()
		end
	end)

	self.Initialized = true
end

E:RegisterModule(RB:GetName())
