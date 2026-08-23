local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local type = type
local strjoin = strjoin

local UnitStat = UnitStat
local GetSpecialization = E.GetSpecialization

local PRIMARY_STAT = L["Primary Stat"]
local NOT_APPLICABLE = NOT_APPLICABLE

local displayString = ''

local classStat = {
	WARRIOR = 1,
	PALADIN = 1,
	DEATHKNIGHT = 1,
	HUNTER = 2,
	ROGUE = 2,
	MAGE = 4,
	WARLOCK = 4,
	PRIEST = 4,
	DRUID = { 4, 2, 4 },
	SHAMAN = { 4, 2, 4 }
}

local function OnEvent(self)
	local stat = classStat[E.myclass]
	local statID = (type(stat) == 'table' and stat[GetSpecialization() or 1]) or (type(stat) == 'number' and stat)

	local name = statID and _G['SPELL_STAT'..statID..'_NAME']
	if name then
		self.text:SetFormattedText(displayString, name..': ', UnitStat('player', statID))
	else
		self.text:SetText(NOT_APPLICABLE)
	end
end

local function ApplySettings(_, hex)
	displayString = strjoin('', '%s', hex, '%.f|r')
end

DT:RegisterDatatext('Primary Stat', L["Attributes"], { 'UNIT_STATS', 'UNIT_AURA' }, OnEvent, nil, nil, nil, nil, PRIMARY_STAT, nil, ApplySettings)
