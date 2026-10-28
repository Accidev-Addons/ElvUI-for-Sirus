local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule('Minimap')
local LSM = E.Libs.LSM

local RB = E:NewModule('ReminderBuffs', 'AceEvent-3.0')

local _G = _G
local ipairs, pairs, wipe = ipairs, pairs, wipe

local CreateFrame = CreateFrame
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitAura = UnitAura
local hooksecurefunc = hooksecurefunc

local Minimap = _G.Minimap

RB.SlotKeys = { 'pot', 'food', 'drubuff', 'palcask', 'inta', 'palmp5', 'oil' }

local casterSpecs = {
	[62] = true, [63] = true, [64] = true,
	[65] = true,
	[102] = true, [105] = true,
	[256] = true, [257] = true, [258] = true,
	[262] = true, [264] = true,
	[265] = true, [266] = true, [267] = true,
}

local commonBuffs = {
	[1] = {
		67016, 67017, 67018, 53755, 53758, 53760, 54212, 53752, 17627,
		270006, 270007, 270008, 270009, 270010, 270011,
		33721, 53746, 28497, 53748, 60346, 60344, 60341, 60345, 60340, 53749,
		60343, 53751, 53764, 60347, 53763, 53747,
		46837, 46839, 41609, 41610, 41611, 41608, 45373,
	},
	[2] = { 57325, 57327, 57329, 57332, 57334, 57356, 57358, 57360, 57363, 57365, 57367, 57371, 57373, 57399, 59230, 65247 },
	[3] = { 72588, 48469 },
	[4] = { 25898, 20217, 72586 },
}

local casterBuffs = {
	[5] = { 61316, 61024, 43002, 42995 },
	[6] = { 48938, 48936, 58777 },
	[7] = { 317727 },
}

local meleeBuffs = {
	[5] = { 48162, 48161, 72590 },
	[6] = { 48934, 48932, 47436, 150000 },
	[7] = { 317728 },
}

local defaultIcons = {
	[1] = [[Interface\Icons\INV_Potion_97]],
	[2] = [[Interface\Icons\Spell_Misc_Food]],
	[3] = [[Interface\Icons\Spell_Nature_Regeneration]],
	[4] = [[Interface\Icons\Spell_Magic_GreaterBlessingofKings]],
	[7] = [[Interface\Icons\INV_Potion_141]],
}

local casterIcons = { [[Interface\Icons\Spell_Holy_MagicalSentry]], [[Interface\Icons\Spell_Holy_GreaterBlessingofWisdom]] }
local meleeIcons = { [[Interface\Icons\Spell_Holy_WordFortitude]], [[Interface\Icons\Ability_Warrior_BattleShout]] }

local spellSlots = {}
local auraTexture, auraDuration, auraExpiration = {}, {}, {}

local function AddSpellSlots(lists)
	for slot, spells in pairs(lists) do
		for _, spell in ipairs(spells) do
			local name = GetSpellInfo(spell)
			if name and not spellSlots[name] then
				spellSlots[name] = slot
			end
		end
	end
end

function RB:IsCaster()
	return casterSpecs[E.myspecID] or false
end

function RB:UpdateRole()
	self.caster = self:IsCaster()

	wipe(spellSlots)
	AddSpellSlots(commonBuffs)
	AddSpellSlots(self.caster and casterBuffs or meleeBuffs)

	local icons = self.caster and casterIcons or meleeIcons
	defaultIcons[5], defaultIcons[6] = icons[1], icons[2]
end

local function MinimapBorder()
	local scale = Minimap:GetEffectiveScale() / E.UIParent:GetEffectiveScale()
	return E:Scale(E.Border) * scale, scale
end

function RB:GetButtonSize(count)
	local border, scale = MinimapBorder()
	local minimapSize = Minimap:GetHeight() * scale + border * 2
	local height = minimapSize / count
	local width = self.db.keepButtonSizeRatio and height or self.db.height

	return width, height, minimapSize
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

local function SetDimmed(button, dimmed)
	button.t:SetDesaturated(dimmed)
	if dimmed then
		button.t:SetVertexColor(0.6, 0.6, 0.6)
		button.t:SetAlpha(0.5)
	else
		button.t:SetVertexColor(1, 1, 1)
		button.t:SetAlpha(1)
	end
end

function RB:UpdateReminder(_, unit)
	if unit and unit ~= 'player' then return end

	wipe(auraTexture)
	for i = 1, 40 do
		local name, _, texture, _, _, duration, expirationTime = UnitAura('player', i)
		if not name then break end

		local slot = spellSlots[name]
		if slot and not auraTexture[slot] then
			auraTexture[slot], auraDuration[slot], auraExpiration[slot] = texture, duration, expirationTime
		end
	end

	local db = self.db
	for i = 1, 7 do
		local button = self.frame[i]

		if db[RB.SlotKeys[i]] then
			local texture = auraTexture[i]

			if texture then
				local duration, expirationTime = auraDuration[i], auraExpiration[i]
				button.t:SetTexture(texture)

				if duration == 0 or not db.durations then
					SetDimmed(button, not db.reverse)
					button:SetScript('OnUpdate', nil)
					button.timer:SetText('')
					CooldownFrame_SetTimer(button.cd, 0, 0, 0)
				else
					button.expiration = expirationTime - GetTime()
					button.nextUpdate = 0
					SetDimmed(button, false)
					CooldownFrame_SetTimer(button.cd, expirationTime - duration, duration, 1)
					button.cd:SetReverse(db.reverse)
					button:SetScript('OnUpdate', self.UpdateReminderTime)
				end
			else
				CooldownFrame_SetTimer(button.cd, 0, 0, 0)
				button:SetScript('OnUpdate', nil)
				button.timer:SetText('')
				button.t:SetTexture(defaultIcons[i])
				SetDimmed(button, db.reverse)
			end
		end
	end
end

function RB:CreateButton(parent)
	local button = CreateFrame('Button', nil, parent)
	button:SetTemplate('Default')

	button.t = button:CreateTexture(nil, 'OVERLAY')
	button.t:SetInside()

	button.cd = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	button.cd:SetInside()
	button.cd.noOCC = true
	button.cd.noCooldownCount = true

	button.timer = button.cd:CreateFontString(nil, 'OVERLAY')
	button.timer:SetPoint('CENTER')

	return button
end

function RB:EnableRB()
	self.frame:Show()
	if self.frame.mover then E:EnableMover('ReminderBuffsMover') end
	self:RegisterEvent('UNIT_AURA', 'UpdateReminder')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateReminder')
end

function RB:DisableRB()
	self.frame:Hide()
	if self.frame.mover then E:DisableMover('ReminderBuffsMover') end
	self:UnregisterEvent('UNIT_AURA')
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function RB:UpdateSettings()
	local frame = self.frame
	if not frame then return end

	local db = E.db.general.reminder
	self.db = db

	local count = 0
	for i = 1, 7 do
		if db[RB.SlotKeys[i]] then
			count = count + 1
		end
	end

	local width, height, minimapSize = self:GetButtonSize(count > 0 and count or 1)
	local font = LSM:Fetch('font', db.font)

	self:UpdateRole()
	frame:Size(width, minimapSize)
	self:UpdateAnchor()

	local shown, previous = 0, nil
	for i = 1, 7 do
		local button = frame[i]
		button:ClearAllPoints()

		if db[RB.SlotKeys[i]] then
			button:Size(width, height)

			if db.keepButtonSizeRatio then
				button.t:SetTexCoords()
			else
				button.t:SetTexCoord(E:CropRatio(width, height))
			end

			button.cd:SetAlpha(db.durations and 1 or 0)
			button.timer:FontTemplate(font, db.fontSize, db.fontOutline)

			if previous then
				button:Point('TOP', previous, 'BOTTOM')
			else
				button:Point('TOP', frame, 'TOP')
			end

			shown = shown + 1
			if shown == count then
				button:Point('BOTTOM', frame, 'BOTTOM')
			end

			button:Show()
			previous = button
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

function RB:GetAnchor()
	local border = MinimapBorder()
	local offset = border + E:PixelSize(1, E.UIParent)

	if self.db.position == 'RIGHT' then
		return 'TOPLEFT', Minimap, 'TOPRIGHT', offset, border
	end

	return 'TOPRIGHT', Minimap, 'TOPLEFT', -offset, border
end

function RB:UpdateAnchor()
	local target = _G.ReminderBuffsMover or self.frame
	local _, anchor = target:GetPoint()
	if anchor ~= Minimap then return end

	target:ClearAllPoints()
	target:Point(self:GetAnchor())
end

function RB:UpdatePosition()
	local frame = self.frame
	if not frame then return end

	local mover = _G.ReminderBuffsMover
	local target = mover or frame

	target:ClearAllPoints()
	target:Point(self:GetAnchor())

	if mover then
		E:SaveMoverPosition('ReminderBuffsMover')
	end
end

function RB:Initialize()
	if not E.private.general.minimap.enable then return end

	self.db = E.db.general.reminder

	local frame = CreateFrame('Frame', 'ElvUI_ReminderBuffs', E.UIParent)
	frame:Point(self:GetAnchor())
	self.frame = frame

	for i = 1, 7 do
		frame[i] = self:CreateButton(frame)
		frame[i]:SetID(i)
	end

	self:UpdateSettings()

	E:CreateMover(frame, 'ReminderBuffsMover', L['Reminder Buffs'], nil, nil, nil, nil, function() return not E.db.general.reminder.enable end, 'maps,minimap,reminder')
	if not self.db.enable then E:DisableMover('ReminderBuffsMover') end
	self:UpdateAnchor()

	hooksecurefunc(M, 'UpdateSettings', function()
		RB:UpdateSettings()
	end)

	hooksecurefunc(E, 'CheckRole', function()
		if RB.caster ~= RB:IsCaster() then
			RB:UpdateSettings()
		end
	end)

	self.Initialized = true
end

E:RegisterModule(RB:GetName())
