local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin

local GetPVPLifetimeStats = GetPVPLifetimeStats

local KILLS = KILLS

local displayString = ''

local function OnEvent(self)
	local honorableKills = GetPVPLifetimeStats()

	self.text:SetFormattedText(displayString, honorableKills or 0)
end

local function ApplySettings(_, hex)
	displayString = strjoin('', KILLS, ': ', hex, '%d|r')
end

DT:RegisterDatatext('Honorable Kills', nil, { 'PLAYER_ENTERING_WORLD', 'PLAYER_PVP_KILLS_CHANGED', 'PLAYER_PVP_RANK_CHANGED' }, OnEvent, nil, nil, nil, nil, L["Honorable Kills"], nil, ApplySettings)
