local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local pairs = pairs
local strjoin = strjoin
local hooksecurefunc = hooksecurefunc

local NOT_APPLICABLE = NOT_APPLICABLE

local displayString = ''
local inRestrictedArea = false
local mapInfo = E.MapInfo
local watcherTimer

local function Update(self, elapsed)
	if inRestrictedArea or not mapInfo.coordsWatching then return end

	self.timeSinceUpdate = (self.timeSinceUpdate or 0) + elapsed

	if self.timeSinceUpdate > 0.1 then
		self.text:SetFormattedText(displayString, mapInfo.xText or 0, mapInfo.yText or 0)
		self.timeSinceUpdate = 0
	end
end

local function OnEvent(self)
	if mapInfo.x and mapInfo.y then
		inRestrictedArea = false
		self.text:SetFormattedText(displayString, mapInfo.xText or 0, mapInfo.yText or 0)
	else
		inRestrictedArea = true
		self.text:SetText(NOT_APPLICABLE)
	end
end

local function Click()
	_G.ToggleFrame(_G.WorldMapFrame)
end

local function ApplySettings(_, hex)
	displayString = strjoin('', hex, '%.2f|r', ' | ', hex, '%.2f|r')
end

local function UpdateWatcher()
	local active
	for _, data in pairs(DT.AssignedDatatexts) do
		if data.name == 'Coords' then
			active = true
			break
		end
	end

	if active then
		if not watcherTimer then
			watcherTimer = E:ScheduleRepeatingTimer('MapInfo_CoordsToggle', 0.5)
		end
	elseif watcherTimer then
		E:CancelTimer(watcherTimer)
		watcherTimer = nil

		E:MapInfo_CoordsStopWatching()
	end
end

hooksecurefunc(DT, 'UpdatePanelInfo', UpdateWatcher)

DT:RegisterDatatext('Coords', nil, { 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'ZONE_CHANGED_INDOORS', 'ZONE_CHANGED_NEW_AREA' }, OnEvent, Update, Click, nil, nil, L["Coords"], mapInfo, ApplySettings)
