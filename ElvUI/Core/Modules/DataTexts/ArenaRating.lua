local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local ceil, format, strjoin = ceil, format, strjoin
local ipairs, select, wipe = ipairs, select, wipe
local tconcat, tinsert = table.concat, tinsert

local C_GlobalStorage = C_GlobalStorage
local GetArenaRating = GetArenaRating
local GetRatedBattlegroundRankInfo = GetRatedBattlegroundRankInfo
local TogglePVPUIFrame = TogglePVPUIFrame

local PVP_LADDER_DAY = PVP_LADDER_DAY
local PVP_LADDER_SEASON = PVP_LADDER_SEASON
local PVP_LADDER_WEEK = PVP_LADDER_WEEK

local RBG_BRACKET = 4
local statFormat = '|cff00ff00%d|r |cffff0000%d|r %d%%'

local brackets = {
	{ key = 'showSolo', label = L["Solo"] },
	{ key = 'show2v2', label = '2x2' },
	{ key = 'show3v3', label = '3x3' },
	{ key = 'showRBG', label = 'RBG' }
}

local displayString = ''
local cache = {}
local db

local function AddStatLine(label, wins, games)
	wins, games = wins or 0, games or 0

	local perc = games == 0 and 0 or ceil(wins / games * 100)
	local passed = perc >= 50

	DT.tooltip:AddDoubleLine(label, format(statFormat, wins, games - wins, perc), 1, 1, 1, passed and 0 or 1, passed and 1 or 0, 0)
end

local function OnEvent(self)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	wipe(cache)

	local rbgRating = select(5, GetRatedBattlegroundRankInfo())

	for i, info in ipairs(brackets) do
		if db[info.key] then
			tinsert(cache, format(displayString, info.label, (i == RBG_BRACKET and rbgRating or GetArenaRating(i)) or 0))
		end
	end

	self.text:SetText(tconcat(cache, ' '))
end

local function OnEnter()
	DT.tooltip:ClearLines()

	if not db then return end

	local pvpStats = C_GlobalStorage.GetVar('ASMSG_PVP_STATS') or {}

	for i, info in ipairs(brackets) do
		if db[info.key] then
			if i == RBG_BRACKET then
				local rankName, _, _, _, _, _, _, _, _, weekWins, weekGames, seasonWins, seasonGames = GetRatedBattlegroundRankInfo()

				DT.tooltip:AddLine(rankName and format('%s (%s)', info.label, rankName) or info.label)
				AddStatLine(PVP_LADDER_WEEK, weekWins, weekGames)
				AddStatLine(PVP_LADDER_SEASON, seasonWins, seasonGames)
			else
				local stats = pvpStats[i]

				DT.tooltip:AddLine(info.label)
				AddStatLine(PVP_LADDER_DAY, stats and stats.todayWins, stats and stats.todayGames)
				AddStatLine(PVP_LADDER_WEEK, stats and stats.weekWins, stats and stats.weekGames)
				AddStatLine(PVP_LADDER_SEASON, stats and stats.seasonWins, stats and stats.seasonGames)
			end
		end
	end

	DT.tooltip:Show()
end

local function OnClick()
	TogglePVPUIFrame()
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	displayString = strjoin('', '%s: ', hex, '%d|r')
end

DT:RegisterDatatext('ArenaRating', nil, { 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED_NEW_AREA', 'PLAYER_BATTLEGROUND_STATS_UPDATE' }, OnEvent, nil, OnClick, OnEnter, nil, L["Arena Rating"], nil, ApplySettings)
