local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local format, strjoin = format, strjoin

local UnitAttackSpeed = UnitAttackSpeed

local SPEED = SPEED
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local HIGHLIGHT_FONT_COLOR_CODE = HIGHLIGHT_FONT_COLOR_CODE
local PAPERDOLLFRAME_TOOLTIP_FORMAT = PAPERDOLLFRAME_TOOLTIP_FORMAT

local displayString, db = ''

local function OnEnter()
	local speed, offhandSpeed = UnitAttackSpeed('player')

	DT.tooltip:ClearLines()
	DT.tooltip:AddDoubleLine(HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, SPEED)..' '..format(offhandSpeed and '%.2f / %.2f' or '%.2f', speed, offhandSpeed)..FONT_COLOR_CODE_CLOSE, nil, 1, 1, 1)
	DT.tooltip:Show()
end

local function OnEvent(self)
	local speed = UnitAttackSpeed('player')
	if db.NoLabel then
		self.text:SetFormattedText(displayString, speed)
	else
		self.text:SetFormattedText(displayString, db.Label ~= '' and db.Label or SPEED, speed)
	end
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	displayString = strjoin('', db.NoLabel and '' or '%s: ', hex, '%.'..db.decimalLength..'f|r')
end

DT:RegisterDatatext('Speed', L["Enhancements"], { 'UNIT_STATS', 'UNIT_AURA', 'PLAYER_DAMAGE_DONE_MODS' }, OnEvent, nil, nil, OnEnter, nil, SPEED, nil, ApplySettings)
