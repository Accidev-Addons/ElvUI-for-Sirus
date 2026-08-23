local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local format, strjoin = format, strjoin

local C_BattlePass = C_BattlePass
local HideUIPanel = HideUIPanel
local SecondsToTime = SecondsToTime
local ShowUIPanel = ShowUIPanel

local BATTLEPASS_PREMIUM = BATTLEPASS_PREMIUM
local BATTLEPASS_QUESTS_DAILY = BATTLEPASS_QUESTS_DAILY
local BATTLEPASS_QUESTS_WEEKLY = BATTLEPASS_QUESTS_WEEKLY
local BATTLEPASS_QUEST_COMPLETED = BATTLEPASS_QUEST_COMPLETED
local BATTLEPASS_SEASON_TIMELEFT_INACTIVE = BATTLEPASS_SEASON_TIMELEFT_INACTIVE
local BATTLEPASS_SEASON_TIMELEFT_LABEL = BATTLEPASS_SEASON_TIMELEFT_LABEL

local displayString = ''
local normalLabel = ''
local premiumLabel = ''

local function IsAvailable()
	return C_BattlePass and C_BattlePass.IsEnabled and C_BattlePass.IsEnabled()
end

local function CollectCompletedQuests()
	for questType = 1, 2 do
		for i = C_BattlePass.GetNumQuests(questType), 1, -1 do
			local _, _, _, _, progressValue, progressMaxValue = C_BattlePass.GetQuestInfo(questType, i)
			if progressValue and progressMaxValue and progressMaxValue > 0 and progressValue >= progressMaxValue then
				C_BattlePass.CollectQuestReward(questType, i)
			end
		end
	end
end

local function AddQuestLines(questType, header)
	local numQuests = C_BattlePass.GetNumQuests(questType)
	if numQuests == 0 then return end

	DT.tooltip:AddLine(format('|cFFFF8000%s: %d|r', header, numQuests), 1, 1, 1)

	for i = 1, numQuests do
		local name, description, _, _, progressValue, progressMaxValue = C_BattlePass.GetQuestInfo(questType, i)
		local text = (description and description ~= '' and description) or name or ''

		progressValue, progressMaxValue = progressValue or 0, progressMaxValue or 0

		if progressMaxValue > 0 and progressValue >= progressMaxValue then
			DT.tooltip:AddLine(format('%s - %s', BATTLEPASS_QUEST_COMPLETED, text), .31, .99, .46)
		else
			DT.tooltip:AddLine(format('|cFFFFFF00%d|r/|cFF00FF00%d|r - %s', progressValue, progressMaxValue, text), 1, 1, 1)
		end
	end

	DT.tooltip:AddLine(' ')
end

local function OnEvent(self)
	if not IsAvailable() then
		self.text:SetText('-')
		return
	end

	local level, levelXP, maxXP = C_BattlePass.GetLevelInfo()
	local unclaimed = C_BattlePass.HasUnclaimedReward()

	self.text:SetFormattedText(displayString, C_BattlePass.IsPremiumActive() and premiumLabel or normalLabel, level or 0, levelXP or 0, maxXP or 0, unclaimed and '!' or '')
end

local function OnEnter()
	DT.tooltip:ClearLines()

	if not IsAvailable() then return end

	AddQuestLines(1, BATTLEPASS_QUESTS_DAILY)
	AddQuestLines(2, BATTLEPASS_QUESTS_WEEKLY)

	local timeLeft = C_BattlePass.GetSeasonTimeLeft()
	DT.tooltip:AddDoubleLine(BATTLEPASS_SEASON_TIMELEFT_LABEL, (timeLeft and timeLeft > 0) and SecondsToTime(timeLeft, true, nil, 2) or BATTLEPASS_SEASON_TIMELEFT_INACTIVE, 1, 1, 1, .8, .8, .8)

	DT.tooltip:AddLine(' ')
	DT.tooltip:AddDoubleLine(L["Left Click:"], L["Toggle Battle Pass"], 1, 1, 1, 1, 1, 0)
	DT.tooltip:AddDoubleLine(L["Middle Click:"], L["Collect Completed Quests"], 1, 1, 1, 1, 1, 0)
	DT.tooltip:AddDoubleLine(L["Right Click:"], L["Take All Level Rewards"], 1, 1, 1, 1, 1, 0)

	DT.tooltip:Show()
end

local function OnClick(_, button)
	if not IsAvailable() then return end

	if button == 'LeftButton' then
		local frame = _G.BattlePassFrame
		if frame then
			if frame:IsShown() then
				HideUIPanel(frame)
			else
				ShowUIPanel(frame)
			end
		end
	elseif button == 'RightButton' then
		C_BattlePass.TakeAllLevelRewards()
	elseif button == 'MiddleButton' then
		CollectCompletedQuests()
	end
end

local function ApplySettings(_, hex)
	displayString = strjoin('', '%s: ', hex, '%d|r (', hex, '%.0f/%.0f|r) %s')
	normalLabel = L["BP"]
	premiumLabel = format('|cfff5cf00%s (%s)|r', L["BP"], BATTLEPASS_PREMIUM)
end

DT:RegisterDatatext('BattlePass', nil, { 'PLAYER_ENTERING_WORLD', 'BATTLEPASS_EXPERIENCE_UPDATE', 'BATTLEPASS_ACCOUNT_UPDATE', 'BATTLEPASS_QUEST_LIST_UPDATE' }, OnEvent, nil, OnClick, OnEnter, nil, L["Battle Pass"], nil, ApplySettings)
