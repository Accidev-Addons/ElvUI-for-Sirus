local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local ipairs = ipairs
local format, strjoin = format, strjoin

local C_BattlePass = C_BattlePass
local HideUIPanel = HideUIPanel
local SecondsToTime = SecondsToTime
local ShowUIPanel = ShowUIPanel
local time = time

local BATTLEPASS_PREMIUM = BATTLEPASS_PREMIUM
local BATTLEPASS_QUESTS_DAILY = BATTLEPASS_QUESTS_DAILY
local BATTLEPASS_QUESTS_WEEKLY = BATTLEPASS_QUESTS_WEEKLY
local BATTLEPASS_QUEST_COMPLETED = BATTLEPASS_QUEST_COMPLETED
local BATTLEPASS_SEASON_TIMELEFT_INACTIVE = BATTLEPASS_SEASON_TIMELEFT_INACTIVE
local BATTLEPASS_SEASON_TIMELEFT_LABEL = BATTLEPASS_SEASON_TIMELEFT_LABEL

local displayString = ''
local normalLabel = ''
local premiumLabel = ''

local CATEGORIES = {
	{ '|cFFFF5A5A'..L["PvP"]..'|r', 28010, 28011, 28013, 28014, 28015, 28016, 28017, 28019, 28020, 28026, 28046, 28047, 28049, 28050, 28051, 28052, 28053, 28054, 28055, 28064, 28075, 28078, 28081, 28083, 28088, 28089, 28091, 28093, 28095, 28150 },
	{ '|cFFB07FFF'..L["Dungeons and Raids"]..'|r', 28003, 28007, 28008, 28009, 28040, 28041, 28042, 28043, 28044, 28060, 28080, 28151, 28152, 28153, 28154, 28155, 28156, 28157, 28159 },
	{ '|cFFFF70C0'..L["World Bosses"]..'|r', 28006, 28045, 28082, 28111, 28114, 28115 },
	{ '|cFF40E0D0'..L["Mini-games"]..'|r', 28035, 28059, 28065, 28067, 28085, 28086, 28092, 28098, 28099, 28100, 28101, 28102, 28103, 28104, 28105, 28106, 28107, 28108, 28109, 28110, 28116, 28117, 28120, 28121 },
	{ '|cFFD9B26F'..L["Professions"]..'|r', 28001, 28028, 28029, 28030, 28031, 28032, 28033 },
	{ '|cFF6FA8FF'..L["Quests and Reputation"]..'|r', 28000, 28004, 28027, 28036, 28037, 28038, 28039, 28057, 28068, 28069, 28070, 28112, 28113 },
	{ '|cFF9D9D9D'..L["Other"]..'|r' },
}

local questCategory = {}
for index, category in ipairs(CATEGORIES) do
	for i = 2, #category do
		questCategory[category[i]] = index
	end
end

local function IsAvailable()
	return C_BattlePass and C_BattlePass.IsEnabled and C_BattlePass.IsEnabled()
end

local bonusUsedUntil = 0

local function GetQuestBonus()
	local bonusPercent, bonusTimeLeft = C_BattlePass.GetQuestBonusInfo()
	if bonusPercent and bonusPercent > 0 and time() >= bonusUsedUntil then
		return bonusPercent, bonusTimeLeft
	end
end

local function MarkBonusUsed(bonusTimeLeft)
	bonusUsedUntil = time() + (bonusTimeLeft > 0 and bonusTimeLeft or 86400)
end

local function CollectCompletedQuests()
	local bonusPercent, bonusTimeLeft = GetQuestBonus()
	if bonusPercent then
		local bestIndex, bestReward
		for i = 1, C_BattlePass.GetNumQuests(2) do
			local _, _, rewardAmount = C_BattlePass.GetQuestInfo(2, i)
			if C_BattlePass.IsQuestComplete(2, i) and (not bestReward or rewardAmount > bestReward) then
				bestIndex, bestReward = i, rewardAmount
			end
		end

		if bestIndex then
			C_BattlePass.CollectQuestReward(2, bestIndex)
			MarkBonusUsed(bonusTimeLeft)
		end
	end

	for i = C_BattlePass.GetNumQuests(1), 1, -1 do
		if C_BattlePass.IsQuestComplete(1, i) then
			C_BattlePass.CollectQuestReward(1, i)
		end
	end
end

local function AddQuestLine(questType, i)
	local name, description, _, _, progressValue, progressMaxValue = C_BattlePass.GetQuestInfo(questType, i)
	local text = (description and description ~= '' and description) or name or ''

	progressValue, progressMaxValue = progressValue or 0, progressMaxValue or 0

	if progressMaxValue > 0 and progressValue >= progressMaxValue then
		DT.tooltip:AddLine(format('%s - %s', BATTLEPASS_QUEST_COMPLETED, text), .31, .99, .46)
	else
		DT.tooltip:AddLine(format('|cFFFFFF00%d|r/|cFF00FF00%d|r - %s', progressValue, progressMaxValue, text), 1, 1, 1)
	end
end

local function AddQuestLines(questType, header)
	local numQuests = C_BattlePass.GetNumQuests(questType)
	if numQuests == 0 then return end

	DT.tooltip:AddLine(format('|cFFFF8000%s: %d|r', header, numQuests), 1, 1, 1)

	for index, category in ipairs(CATEGORIES) do
		local hasHeader
		for i = 1, numQuests do
			if (questCategory[C_BattlePass.GetQuestID(questType, i)] or #CATEGORIES) == index then
				if not hasHeader then
					DT.tooltip:AddLine(category[1])
					hasHeader = true
				end
				AddQuestLine(questType, i)
			end
		end
	end

	DT.tooltip:AddLine(' ')
end

local function OnEvent(self, event)
	if not IsAvailable() then
		self.text:SetText('-')
		return
	end

	if event == 'BATTLEPASS_QUEST_REWARD_RECIVED' then
		local bonusPercent, bonusTimeLeft = GetQuestBonus()
		if bonusPercent then
			MarkBonusUsed(bonusTimeLeft)
		end
	end

	local level, levelXP, maxXP = C_BattlePass.GetLevelInfo()
	local unclaimed = C_BattlePass.HasUnclaimedReward()

	self.text:SetFormattedText(displayString, C_BattlePass.IsPremiumActive() and premiumLabel or normalLabel, level or 0, levelXP or 0, maxXP or 0, unclaimed and '!' or '')
end

local function OnEnter()
	DT.tooltip:ClearLines()

	if not IsAvailable() then return end

	local bonusPercent, bonusTimeLeft = GetQuestBonus()
	if bonusPercent then
		DT.tooltip:AddDoubleLine(format(L["Quest Bonus: +%d%%"], bonusPercent), (bonusTimeLeft and bonusTimeLeft > 0) and SecondsToTime(bonusTimeLeft, true, nil, 2) or '', .31, .99, .46, .8, .8, .8)
		DT.tooltip:AddLine(' ')
	end

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

DT:RegisterDatatext('BattlePass', nil, { 'PLAYER_ENTERING_WORLD', 'BATTLEPASS_EXPERIENCE_UPDATE', 'BATTLEPASS_ACCOUNT_UPDATE', 'BATTLEPASS_QUEST_LIST_UPDATE', 'BATTLEPASS_QUEST_REWARD_RECIVED' }, OnEvent, nil, OnClick, OnEnter, nil, L["Battle Pass"], nil, ApplySettings)
