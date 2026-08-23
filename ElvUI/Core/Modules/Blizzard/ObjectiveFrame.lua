local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local min = min

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local function ObjectiveTracker_SetPoint(tracker, _, parent)
	if parent ~= tracker.holder then
		tracker:ClearAllPoints()
		tracker:SetPoint('TOP', tracker.holder)
	end
end

function BL:ObjectiveTracker_SetHeight()
	local tracker = BL:GetObjectiveTracker()
	local top = tracker:GetTop() or 0
	local gapFromTop = E.screenHeight - top
	local maxHeight = E.screenHeight - gapFromTop
	local frameHeight = min(maxHeight, E.db.general.objectiveFrameHeight)

	tracker.editModeHeight = frameHeight
	tracker:Height(frameHeight)
end

function BL:ObjectiveTracker_AutoHideOnHide()
	local tracker = BL:GetObjectiveTracker()
	if not tracker or BL:ObjectiveTracker_IsCollapsed(tracker) then return end

	BL:ObjectiveTracker_Collapse(tracker)
end

function BL:ObjectiveTracker_Setup()
	local holder = CreateFrame('Frame', 'ObjectiveFrameHolder', E.UIParent)
	holder:Point('TOPRIGHT', E.UIParent, -135, -300)
	holder:Size(130, 22)

	E:CreateMover(holder, 'ObjectiveFrameMover', L["Objective Frame"], nil, nil, nil, nil, nil, 'general,blizzardImprovements')
	holder:SetAllPoints(_G.ObjectiveFrameMover)

	-- prevent it from being moved by blizzard (the hook below will most likely do nothing now)
	local tracker = BL:GetObjectiveTracker()
	tracker:SetMovable(true)
	tracker:SetUserPlaced(true)
	tracker:SetDontSavePosition(true)
	tracker:SetClampedToScreen(false)

	if tracker.BreakFromFrameManager then
		tracker:BreakFromFrameManager()
	end

	if tracker.systemInfo then
		tracker.systemInfo.isInDefaultPosition = false
	end

	tracker:ClearAllPoints()
	tracker:SetPoint('TOP', holder)

	tracker.holder = holder
	hooksecurefunc(tracker, 'SetPoint', ObjectiveTracker_SetPoint)

	BL:ObjectiveTracker_AutoHide() -- supported but no boss frames, only works for arena
	BL:ObjectiveTracker_SetHeight()
end
