local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local format = format
local ipairs = ipairs
local hooksecurefunc = hooksecurefunc

local GetNumQuestLogEntries = GetNumQuestLogEntries
local GetQuestLogTitle = GetQuestLogTitle
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset

local GROUP_R, GROUP_G, GROUP_B = 79 / 255, 140 / 255, 201 / 255

local function GroupMates_SetTextColor(fontString, r, g, b)
	if not E.db.general.showQuestLevel then return end
	if r == GROUP_R and g == GROUP_G and b == GROUP_B then return end

	fontString:SetTextColor(GROUP_R, GROUP_G, GROUP_B)
end

local function ShowLevel()
	if not E.db.general.showQuestLevel or not _G.QuestLogFrame:IsShown() then return end

	local scrollFrame = _G.QuestLogScrollFrame
	local numEntries = GetNumQuestLogEntries()
	local offset = HybridScrollFrame_GetOffset(scrollFrame)

	for i, button in ipairs(scrollFrame.buttons) do
		local questIndex = i + offset
		if questIndex > numEntries then break end

		local title, level, _, _, isHeader, _, _, _, questID, displayQuestID = GetQuestLogTitle(questIndex)
		if title and not isHeader then
			if questID and displayQuestID then
				title = format('%s - %s', questID, title)
			end

			button:SetText(format('  [%d] %s', level, title))
			_G.QuestLogTitleButton_Resize(button)
		end
	end
end

function BL:QuestLevelToggle()
	local scrollFrame = _G.QuestLogScrollFrame
	if not scrollFrame or not scrollFrame.buttons then return end

	if E.db.general.showQuestLevel and not BL.QuestLevelHooked then
		BL.QuestLevelHooked = true

		hooksecurefunc('QuestLog_Update', ShowLevel)
		scrollFrame.scrollBar:HookScript('OnValueChanged', ShowLevel)

		for _, button in ipairs(scrollFrame.buttons) do
			hooksecurefunc(button.groupMates, 'SetTextColor', GroupMates_SetTextColor)
		end
	end

	if BL.QuestLevelHooked and _G.QuestLogFrame:IsShown() then
		_G.QuestLog_Update()
	end
end
