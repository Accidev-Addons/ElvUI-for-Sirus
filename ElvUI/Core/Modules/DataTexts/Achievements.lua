local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin

local GetTotalAchievementPoints = GetTotalAchievementPoints
local ToggleAchievementFrame = ToggleAchievementFrame

local ACHIEVEMENTS = ACHIEVEMENTS

local displayString = ''

local function OnEvent(self)
	self.text:SetFormattedText(displayString, GetTotalAchievementPoints() or 0)
end

local function OnClick()
	if not E:AlertCombat() then
		ToggleAchievementFrame()
	end
end

local function ApplySettings(_, hex)
	displayString = strjoin('', ACHIEVEMENTS, ': ', hex, '%d|r')
end

DT:RegisterDatatext('Achievements', nil, { 'PLAYER_ENTERING_WORLD', 'ACHIEVEMENT_EARNED' }, OnEvent, nil, OnClick, nil, nil, L["Achievements"], nil, ApplySettings)
