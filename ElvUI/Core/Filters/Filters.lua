local E, L, V, P, G = unpack(ElvUI)

local unpack = unpack

E.Filters = {}

E.Filters.List = function(priority)
	return {
		enable = true,
		priority = priority or 0,
		stackThreshold = 0
	}
end

E.Filters.Aura = function(auraID, includeIDs, point, color, anyUnit, onlyShowMissing, displayText, textThreshold, xOffset, yOffset)
	local r, g, b = 1, 1, 1
	if color then r, g, b = unpack(color) end

	return {
		id = auraID,
		includeIDs = includeIDs,
		enabled = true,
		point = point or 'TOPLEFT',
		color = { r = r, g = g, b = b },
		anyUnit = anyUnit or false,
		onlyShowMissing = onlyShowMissing or false,
		displayText = displayText or false,
		textThreshold = textThreshold or -1,
		xOffset = xOffset or 0,
		yOffset = yOffset or 0,
		style = 'coloredIcon',
		sizeOffset = 0
	}
end
