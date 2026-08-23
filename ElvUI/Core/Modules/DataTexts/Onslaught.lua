local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin

local GetOnslaughtRating = GetOnslaughtRating

local displayString = ''

local function OnEvent(self)
	self.text:SetFormattedText(displayString, GetOnslaughtRating() or 0)
end

local function ApplySettings(_, hex)
	displayString = strjoin('', L["Onslaught"], ': ', hex, '%.0f|r')
end

DT:RegisterDatatext('Onslaught', nil, { 'PLAYER_ENTERING_WORLD', 'UNIT_STATS', 'COMBAT_RATING_UPDATE' }, OnEvent, nil, nil, nil, nil, L["Onslaught"], nil, ApplySettings)
