local E, L, V, P, G = unpack(ElvUI)

local select = select
local IsFalling = IsFalling
local CreateFrame = CreateFrame
local GetUnitSpeed = GetUnitSpeed
local GetRealZoneText = GetRealZoneText
local GetMinimapZoneText = GetMinimapZoneText
local GetCurrentMapAreaID = GetCurrentMapAreaID
local GetCurrentMapContinent = GetCurrentMapContinent
local GetMapContinents = GetMapContinents
local GetMapInfoEx = GetMapInfoEx
local GetMapInfo = GetMapInfo
local GetZoneText = GetZoneText

local MapInfo = {}
E.MapInfo = MapInfo

local function GetContinentName()
	local index = GetCurrentMapContinent()
	if not index or index < 1 then return end

	return select(index, GetMapContinents())
end

function E:MapInfo_Update()
	local mapID = GetCurrentMapAreaID()

	MapInfo.name = (mapID and GetMapInfoEx(mapID)) or GetZoneText() or GetMapInfo() or nil

	MapInfo.mapID = mapID or nil
	MapInfo.continentName = GetContinentName() or nil
	MapInfo.zoneText = (mapID and E:GetZoneText(mapID)) or nil
	MapInfo.subZoneText = GetMinimapZoneText() or nil
	MapInfo.realZoneText = GetRealZoneText() or nil

	E:MapInfo_CoordsUpdate()
end

local coordsWatcher = CreateFrame('Frame')
function E:MapInfo_CoordsStart()
	MapInfo.coordsWatching = true
	MapInfo.coordsFalling = nil

	coordsWatcher:SetScript('OnUpdate', E.MapInfo_OnUpdate)

	if MapInfo.coordsStopTimer then
		E:CancelTimer(MapInfo.coordsStopTimer)
		MapInfo.coordsStopTimer = nil
	end
end

function E:MapInfo_CoordsStopWatching()
	MapInfo.coordsWatching = nil
	MapInfo.coordsStopTimer = nil
	coordsWatcher:SetScript('OnUpdate', nil)
end

function E:MapInfo_CoordsStop(event)
	if event == 'CRITERIA_UPDATE' then
		if not MapInfo.coordsFalling then return end -- stop if we weren't falling
		if (GetUnitSpeed('player') or 0) > 0 then return end -- we are still moving!
		MapInfo.coordsFalling = nil -- we were falling!
	elseif (GetUnitSpeed('player') or 0) == 0 and IsFalling() then
		MapInfo.coordsFalling = true
		return
	end

	if not MapInfo.coordsStopTimer then
		MapInfo.coordsStopTimer = E:ScheduleTimer('MapInfo_CoordsStopWatching', 0.5)
	end
end

function E:MapInfo_CoordsUpdate()
	if MapInfo.mapID then
		MapInfo.x, MapInfo.y = E:GetPlayerMapPos()
	else
		MapInfo.x, MapInfo.y = nil, nil
	end

	if MapInfo.x and MapInfo.y then
		MapInfo.xText = E:Round(100 * MapInfo.x, 2)
		MapInfo.yText = E:Round(100 * MapInfo.y, 2)
	else
		MapInfo.xText, MapInfo.yText = nil, nil
	end
end

function E:MapInfo_OnUpdate(elapsed)
	if GetUnitSpeed('player') == 0 then return end
	self.lastUpdate = (self.lastUpdate or 0) + elapsed
	if self.lastUpdate > 0.1 then
		E:MapInfo_CoordsUpdate()
		self.lastUpdate = 0
	end
end

local x, y = 0, 0
function E:GetPlayerMapPos()
	x, y = GetPlayerMapPosition('player')
	if not x then return end

	return x, y
end

function E:GetZoneText(mapID)
	if not (mapID and MapInfo.name) then return end

	return MapInfo.name
end

function E:MapInfo_CoordsToggle()
	if GetUnitSpeed('player') > 0 then
		E:MapInfo_CoordsStart()
	else
		E:MapInfo_CoordsStop()
	end
end

E:RegisterEvent('CRITERIA_UPDATE', 'MapInfo_CoordsStop') -- when the player goes into an animation (landing)
E:RegisterEventForObject('PLAYER_LOGIN', E.MapInfo, E.MapInfo_Update)
E:RegisterEventForObject('ZONE_CHANGED_NEW_AREA', E.MapInfo, E.MapInfo_Update)
E:RegisterEventForObject('ZONE_CHANGED_INDOORS', E.MapInfo, E.MapInfo_Update)
E:RegisterEventForObject('ZONE_CHANGED', E.MapInfo, E.MapInfo_Update)
