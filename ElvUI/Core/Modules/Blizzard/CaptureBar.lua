local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local hooksecurefunc = hooksecurefunc

local captureBarHolder = CreateFrame('Frame', 'ElvUI_CaptureBarHolder', E.UIParent)
local pvpHolder = CreateFrame('Frame', 'ElvUI_PvPHolder', E.UIParent)

local numAlwaysUpFrames = 0

local function captureBarUpdate(id)
	local captureBar = _G['WorldStateCaptureBar'..id]
	if captureBar then
		captureBar:ClearAllPoints()

		if id == 1 then
			captureBar:Point('CENTER', captureBarHolder, 'CENTER', 0, 0)
			captureBar.SetPoint = E.noop
		else
			captureBar:Point('TOPLEFT', _G['WorldStateCaptureBar'..id - 1], 'TOPLEFT', 0, -45)
		end
	end
end

local function alwaysUpFrameUpdate(id)
	local frame = _G['AlwaysUpFrame'..id]
	if not frame then return end

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
end

local function alwaysUpFramesUpdate()
	local numFrames = _G.NUM_ALWAYS_UP_UI_FRAMES or 0

	if numAlwaysUpFrames < numFrames then
		for id = numAlwaysUpFrames + 1, numFrames do
			alwaysUpFrameUpdate(id)
			numAlwaysUpFrames = id
		end
	end
end

function BL:PositionAlwaysUpFrame()
	pvpHolder:SetSize(30, 70)
	pvpHolder:Point('TOP', E.UIParent, 'TOP', 0, -4)

	hooksecurefunc('WorldStateAlwaysUpFrame_Update', alwaysUpFramesUpdate)

	alwaysUpFramesUpdate()

	E:CreateMover(pvpHolder, 'PvPMover', L["PvP"], nil, nil, nil, 'ALL')
end

function BL:PositionCaptureBar()
	captureBarHolder:SetSize(172, 16)
	captureBarHolder:Point('TOP', E.UIParent, 'TOP', 0, -150)

	hooksecurefunc(ExtendedUI['CAPTUREPOINT'], 'create', captureBarUpdate)

	if _G.NUM_EXTENDED_UI_FRAMES and _G.NUM_EXTENDED_UI_FRAMES > 0 then
		for id = 1, _G.NUM_EXTENDED_UI_FRAMES do
			captureBarUpdate(id)
		end
	end

	E:CreateMover(captureBarHolder, 'CaptureBarMover', L["Capture Bar"], nil, nil, nil, 'ALL')
end