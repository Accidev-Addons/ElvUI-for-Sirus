local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local print = print
local type, assert = type, assert
local select, error = select, error
local pcall, xpcall = pcall, xpcall
local strjoin, format = strjoin, format
local geterrorhandler = geterrorhandler
local debugstack = debugstack

function Private.argcheck(value, num, ...)
	assert(type(num) == 'number', "Bad argument #2 to 'argcheck' (number expected, got " .. type(num) .. ')')

	for i = 1, select('#', ...) do
		if(type(value) == select(i, ...)) then return end
	end

	local types = strjoin(', ', ...)
	local name = debugstack(2,2,0):match(": in function [`<](.-)['>]")
	error(format("Bad argument #%d to '%s' (%s expected, got %s)", num, name, types, type(value)), 3)
end

function Private.print(...)
	print('|cff33ff99oUF:|r', ...)
end

function Private.error(...)
	Private.print('|cffff0000Error:|r ' .. format(...))
end

function Private.nierror(...)
	return geterrorhandler()(...)
end

function Private.unitExists(unit)
	return unit and (UnitExists(unit) or UnitIsVisible(unit))
end

local validator = CreateFrame('Frame')

local function GetUnitSelectionType(unit, useExtended)
	if not UnitExists(unit) then return nil end

	local r, g, b, a = UnitSelectionColor(unit, useExtended)
	if not r then return nil end

	-- check alive state first (alpha often lower for dead)
	if a and a < 0.5 then
		return 9 -- dead
	end

	-- basic thresholds for colors
	if r > 0.9 and g < 0.2 and b < 0.2 then
		return 0 -- hostile (red)
	elseif r > 0.9 and g > 0.5 and b < 0.2 then
		return 1 -- unfriendly (orange)
	elseif r > 0.8 and g > 0.8 and b < 0.2 then
		return 2 -- neutral (yellow)
	elseif r < 0.2 and g > 0.8 and b < 0.2 then
		return 3 -- friendly NPC (green)
	elseif r < 0.2 and g < 0.2 and b > 0.8 then
		return 4 -- player / same faction (blue)
	elseif r > 0.7 and g > 0.7 and b > 0.7 then
		return 13 -- tapped / unselectable (grey/white)
	end

	return 3 -- fallback to friendly
end

-- Map of valid selection types
local selectionTypes = {
	[ 0] = 0, -- hostile
	[ 1] = 1, -- unfriendly
	[ 2] = 2, -- neutral
	[ 3] = 3, -- friendly
	[ 4] = 4, -- player
	[ 5] = 5,
	[ 6] = 6,
	[ 7] = 7,
	[ 8] = 8,
	[ 9] = 9, -- dead
	-- [10] = 10, -- unavailable to players
	-- [11] = 11, -- unavailable to players
	-- [12] = 12, -- inconsistent due to bugs and its reliance on cvars
	[13] = 13, -- tapped / unselectable
}

function Private.unitSelectionType(unit, considerHostile)
	if considerHostile and UnitThreatSituation('player', unit) then
		return 0
	end

	local t = GetUnitSelectionType(unit, true)
	return selectionTypes[t] or 3
end

function Private.xpcall(func, ...)
	return xpcall(func, Private.nierror, ...)
end

function Private.validateEvent(event)
	local isOK = xpcall(function()
		validator:RegisterEvent(event)
	end, Private.nierror)

	if isOK then
		validator:UnregisterEvent(event)
	end

	return isOK
end

function Private.isUnitEvent(event, unit)
	local isOK = pcall(function()
		validator:RegisterEvent(event, unit)
	end)

	if isOK then
		validator:UnregisterEvent(event)
	end

	return isOK
end