local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local strjoin = strjoin
local tonumber = tonumber

local GetNumBattlefieldScores = GetNumBattlefieldScores
local GetBattlefieldStatData = GetBattlefieldStatData
local GetBattlefieldStatInfo = GetBattlefieldStatInfo
local GetBattlefieldScore = GetBattlefieldScore

local GetNumBattlefieldStats = GetNumBattlefieldStats

local displayString = ''
local data = { killingBlows = 0, honorableKills = 0, healingDone = 0, deaths = 0, damageDone = 0, honorGained = 0 }

local function GetBattleStats(name)
	if name == 'PvP: Kills' then
		return _G.KILLING_BLOWS, data.killingBlows
	elseif name == 'PvP: Honorable Kills' then
		return _G.HONORABLE_KILLS, data.honorableKills
	elseif name == 'PvP: Heals' then
		return _G.SHOW_COMBAT_HEALING, data.healingDone
	elseif name == 'PvP: Deaths' then
		return _G.DEATHS, data.deaths
	elseif name == 'PvP: Damage Done' then
		return _G.DAMAGE, data.damageDone
	elseif name == 'PvP: Honor Gained' then
		return _G.HONOR, data.honorGained
	elseif name == 'PvP: Objectives' then
		return _G.OBJECTIVES_LABEL
	end
end

function DT:UPDATE_BATTLEFIELD_SCORE()
	data.myIndex = nil

	for i = 1, GetNumBattlefieldScores() do
		local name, killingBlows, honorableKills, deaths, honorGained, _, _, _, _, _, damageDone, healingDone = GetBattlefieldScore(i)

		if name == E.myname then
			data.myIndex = i
			data.killingBlows, data.honorableKills, data.deaths, data.honorGained = killingBlows, honorableKills, deaths, honorGained
			data.damageDone, data.healingDone = damageDone, healingDone
			break
		end
	end

	if not data.myIndex then
		data.killingBlows, data.honorableKills, data.healingDone = 0, 0, 0
		data.deaths, data.damageDone, data.honorGained = 0, 0, 0
	end
end

function DT:HoverBattleStats() -- Objectives OnEnter -- Idea is to store this in a table and probably rotate it on the text field.
	DT.tooltip:ClearLines()

	if data.myIndex and DT.ShowingBattleStats == 'pvp' then
		for i = 1, GetNumBattlefieldStats() do
			local name = GetBattlefieldStatInfo(i)
			if name then
				DT.tooltip:AddDoubleLine(name, GetBattlefieldStatData(data.myIndex, i), 1,1,1)
			end
		end

		DT.tooltip:Show()
	end
end

DT.ForceHideBGStats = false
function DT:ToggleBattleStats()
	DT.ForceHideBGStats = not DT.ForceHideBGStats

	if DT.ForceHideBGStats then
		E:Print(L["Battleground datatexts temporarily hidden, to show type /bgstats"])
	else
		E:Print(L["Battleground datatexts will now show again if you are inside a battleground."])
	end

	DT:LoadDataTexts()
end

local function OnUpdate(self, elapsed)
	self.timeSinceUpdate = (self.timeSinceUpdate or 0) + elapsed

	if self.needsUpdate and self.timeSinceUpdate > 0.3 then -- this will allow the main event to update the dt
		local locale, value = GetBattleStats(self.name)
		if value then
			self.text:SetFormattedText(displayString, locale, E:ShortValue(tonumber(value) or 0))
		else
			self.text:SetFormattedText('%s', locale)
		end

		self.needsUpdate = false
	end
end

local function OnEvent(self)
	self.timeSinceUpdate = 0
	self.needsUpdate = true
end

local function ValueColorUpdate(_, hex)
	displayString = strjoin('', '%s: ', hex, '%s|r')
end

E.valueColorUpdateFuncs.Battlegrounds = ValueColorUpdate

DT:RegisterDatatext('PvP: Kills', L["Battlegrounds"], { 'UPDATE_BATTLEFIELD_SCORE' }, OnEvent, OnUpdate, DT.ToggleBattleStats, nil, nil, L["PvP: Kills"])
DT:RegisterDatatext('PvP: Honorable Kills', L["Battlegrounds"], { 'UPDATE_BATTLEFIELD_SCORE' }, OnEvent, OnUpdate, DT.ToggleBattleStats, nil, nil, L["PvP: Honorable Kills"])
DT:RegisterDatatext('PvP: Heals', L["Battlegrounds"], { 'UPDATE_BATTLEFIELD_SCORE' }, OnEvent, OnUpdate, DT.ToggleBattleStats, nil, nil, L["PvP: Heals"])
DT:RegisterDatatext('PvP: Deaths', L["Battlegrounds"], { 'UPDATE_BATTLEFIELD_SCORE' }, OnEvent, OnUpdate, DT.ToggleBattleStats, nil, nil, L["PvP: Deaths"])
DT:RegisterDatatext('PvP: Damage Done', L["Battlegrounds"], { 'UPDATE_BATTLEFIELD_SCORE' }, OnEvent, OnUpdate, DT.ToggleBattleStats, nil, nil, L["PvP: Damage Done"])
DT:RegisterDatatext('PvP: Honor Gained', L["Battlegrounds"], { 'UPDATE_BATTLEFIELD_SCORE' }, OnEvent, OnUpdate, DT.ToggleBattleStats, nil, nil, L["PvP: Honor Gained"])
DT:RegisterDatatext('PvP: Objectives', L["Battlegrounds"], { 'UPDATE_BATTLEFIELD_SCORE' }, OnEvent, OnUpdate, DT.ToggleBattleStats, DT.HoverBattleStats, nil, L["PvP: Objectives"])
