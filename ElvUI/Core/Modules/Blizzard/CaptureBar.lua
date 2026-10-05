local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown

local captureBarHolder = CreateFrame('Frame', 'ElvUI_CaptureBarHolder', E.UIParent)
local pvpHolder = CreateFrame('Frame', 'ElvUI_PvPHolder', E.UIParent)

local numAlwaysUpFrames = 0
local numExtendedUIFrames = 0

local function CanChangeProtectedState(frame)
	if frame.CanChangeProtectedState then
		return frame:CanChangeProtectedState()
	end

	return not InCombatLockdown()
end

local function captureBarUpdate(id)
	local captureBar = _G['WorldStateCaptureBar'..id]
	if not captureBar then return true end
	if not CanChangeProtectedState(captureBar) then return false end

	captureBar:ClearAllPoints()

	if id == 1 then
		captureBar:Point('CENTER', captureBarHolder, 'CENTER', 0, 0)
		captureBar.SetPoint = E.noop
	else
		captureBar:Point('TOPLEFT', _G['WorldStateCaptureBar'..id - 1], 'TOPLEFT', 0, -45)
	end

	return true
end

local function alwaysUpFrameUpdate(id)
	local frame = _G['AlwaysUpFrame'..id]
	if not frame then return true end
	if not CanChangeProtectedState(frame) then return false end

	local text = _G['AlwaysUpFrame'..id..'Text']
	local icon = _G['AlwaysUpFrame'..id..'Icon']
	local dynamicIconButton = _G['AlwaysUpFrame'..id..'DynamicIconButton']

	if text then
		text:ClearAllPoints()
		text:Point('CENTER', frame, 'CENTER', 0, 0)
	end

	if icon and text then
		icon:ClearAllPoints()
		icon:Point('CENTER', text, 'LEFT', -10, -9)
	end

	if dynamicIconButton and text then
		dynamicIconButton:ClearAllPoints()
		dynamicIconButton:Point('LEFT', text, 'RIGHT', 5, 0)
	end

	if id == 1 then
		frame:ClearAllPoints()
		frame:Point('CENTER', pvpHolder, 'CENTER', 0, 5)
		frame.SetPoint = E.noop
	end

	return true
end

local function alwaysUpFramesUpdate()
	local numFrames = _G.NUM_ALWAYS_UP_UI_FRAMES or 0

	if numAlwaysUpFrames >= numFrames then return end

	for id = numAlwaysUpFrames + 1, numFrames do
		if not alwaysUpFrameUpdate(id) then return end
		numAlwaysUpFrames = id
	end
end

local function captureBarsUpdate()
	local numFrames = _G.NUM_EXTENDED_UI_FRAMES or 0

	if numExtendedUIFrames >= numFrames then return end

	for id = numExtendedUIFrames + 1, numFrames do
		if not captureBarUpdate(id) then return end
		numExtendedUIFrames = id
	end
end

function BL:PositionAlwaysUpFrame()
	pvpHolder:SetSize(30, 70)
	pvpHolder:Point('TOP', E.UIParent, 'TOP', 0, -4)

	hooksecurefunc('WorldStateAlwaysUpFrame_Update', function()
		if numAlwaysUpFrames < (_G.NUM_ALWAYS_UP_UI_FRAMES or 0) then
			C_Timer:After(0, alwaysUpFramesUpdate)
		end

		if numExtendedUIFrames < (_G.NUM_EXTENDED_UI_FRAMES or 0) then
			C_Timer:After(0, captureBarsUpdate)
		end
	end)

	alwaysUpFramesUpdate()

	E:CreateMover(pvpHolder, 'PvPMover', L["PvP"], nil, nil, nil, 'ALL')
end

function BL:PositionCaptureBar()
	captureBarHolder:SetSize(172, 16)
	captureBarHolder:Point('TOP', E.UIParent, 'TOP', 0, -150)

	captureBarsUpdate()

	E:CreateMover(captureBarHolder, 'CaptureBarMover', L["Capture Bar"], nil, nil, nil, 'ALL')
end