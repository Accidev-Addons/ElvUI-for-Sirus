local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin
local format = format

local _G = _G
local UnitXPMax = UnitXPMax
local MouseIsOver = MouseIsOver
local IsShiftKeyDown = IsShiftKeyDown
local GetQuestLogTitle = GetQuestLogTitle
local GetQuestLogRewardXP = GetQuestLogRewardXP
local SelectQuestLogEntry = SelectQuestLogEntry
local GetQuestLogSelection = GetQuestLogSelection
local GetQuestLogRewardMoney = GetQuestLogRewardMoney
local BreakUpLargeNumbers = BreakUpLargeNumbers

local GetNumQuestLogEntries = GetNumQuestLogEntries

local MAX_QUESTLOG_QUESTS = MAX_QUESTLOG_QUESTS -- 20 for ERA, 25 for WotLK, 35 for Retail
local QUESTS_LABEL = QUESTS_LABEL
local COMPLETE = COMPLETE
local INCOMPLETE = INCOMPLETE
local MONEY = MONEY
local XP = XP

local displayString = ''
local numEntries, numQuests, xpToLevel = 0, 0, 0

local function GetQuestInfo(questIndex)
	local info = {}
	info.title, info.level, info.questTag, info.suggestedGroup, info.isHeader, info.isCollapsed, info.isComplete, info.isDaily, info.questID, info.displayQuestID = GetQuestLogTitle(questIndex)
	SelectQuestLogEntry(questIndex)

	return info
end

local function XPPercent(xp)
	return xpToLevel > 0 and (xp / xpToLevel) * 100 or 0
end

local function OnEnter()
	DT.tooltip:ClearLines()

	local totalMoney, totalXP, completedXP = 0, 0, 0
	local isShiftDown = IsShiftKeyDown()
	local previousQuest = GetQuestLogSelection()

	DT.tooltip:AddLine(QUESTS_LABEL)
	DT.tooltip:AddLine(' ')

	for questIndex = 1, numEntries do
		local info = GetQuestInfo(questIndex)
		if info and not info.isHeader then
			local xp = GetQuestLogRewardXP(info.questID) or 0
			local money = GetQuestLogRewardMoney(info.questID) or 0
			local isComplete = info.isComplete

			totalMoney = totalMoney + money
			totalXP = totalXP + xp
			completedXP = completedXP + (isComplete and xp or 0)

			DT.tooltip:AddDoubleLine(info.title, isShiftDown and format('%s (%.2f%%)', BreakUpLargeNumbers(xp), XPPercent(xp)) or (isComplete and COMPLETE or INCOMPLETE), 1, 1, 1, isComplete and .2 or 1, isComplete and 1 or .2, .2)
		end
	end

	if previousQuest then
		SelectQuestLogEntry(previousQuest)
	end

	if completedXP > 0 then
		DT.tooltip:AddLine(' ')
		DT.tooltip:AddDoubleLine(format('%s %s:', COMPLETE, XP), format('%s (%.2f%%)', BreakUpLargeNumbers(completedXP), XPPercent(completedXP)), nil, nil, nil, 1, 1, 1)
	end

	DT.tooltip:AddLine(' ')
	DT.tooltip:AddDoubleLine(L["Total: "]..MONEY, E:FormatMoney(totalMoney, 'SMART'), nil, nil, nil, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Total: "]..XP, format('%s (%.2f%%)', BreakUpLargeNumbers(totalXP), XPPercent(totalXP)), nil, nil, nil, 1, 1, 1)
	DT.tooltip:Show()
end

local function OnClick()
	_G.ToggleFrame(_G.QuestLogFrame)
end

local function OnEvent(self)
	numEntries, numQuests = GetNumQuestLogEntries()
	xpToLevel = UnitXPMax('player')

	self.text:SetFormattedText(displayString, numQuests, MAX_QUESTLOG_QUESTS)

	if MouseIsOver(self) then
		OnEnter(self)
	end
end

local function ApplySettings(_, hex)
	displayString = strjoin('', QUESTS_LABEL, ': ', hex, '%d|r', '/', hex, '%d|r')
end

DT:RegisterDatatext('Quests', nil, { 'QUEST_ACCEPTED', 'QUEST_LOG_UPDATE', 'MODIFIER_STATE_CHANGED' }, OnEvent, nil, OnClick, OnEnter, nil, L["Quest Log"], nil, ApplySettings)
