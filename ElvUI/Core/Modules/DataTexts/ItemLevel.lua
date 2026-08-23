local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local ipairs = ipairs
local format = format

local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemTexture = GetInventoryItemTexture
local GetAverageItemLevel = GetAverageItemLevel

local sameString = '%s: %s%d|r'
local iconString = '|T%s:24:24:0:0:50:50:4:46:4:46|t %s'
local slotID = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
local r, g, b, avg = 1, 1, 1, 0
local db

local function OnEvent(self)
	avg = GetAverageItemLevel()
	r, g, b = E:ColorizeItemLevel(avg)

	local hex = db.rarityColor and E:RGBToHex(r, g, b) or '|cFFFFFFFF'

	self.text:SetFormattedText(sameString, L["iLvL"], hex, avg or 0)
end

local function OnEnter()
	DT.tooltip:ClearLines()

	DT.tooltip:AddDoubleLine(L["Item Level"], format('%d', avg), 1, 1, 1, r, g, b)
	DT.tooltip:AddLine(" ")

	for _, k in ipairs(slotID) do
		local info = E:GetGearSlotInfo('player', k)
		local ilvl = (info and info ~= 'tooSoon') and info.iLvl
		if ilvl then
			local link = GetInventoryItemLink('player', k)
			local icon = GetInventoryItemTexture('player', k)
			DT.tooltip:AddDoubleLine(format(iconString, icon, link), ilvl, 1, 1, 1, E:ColorizeItemLevel(ilvl - avg))
		end
	end

	DT.tooltip:Show()
end

local function ApplySettings(self)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end
end

DT:RegisterDatatext('Item Level', L["Stats"], { 'UNIT_INVENTORY_CHANGED', 'PLAYER_EQUIPMENT_CHANGED', 'PLAYER_AVG_ITEM_LEVEL_READY' }, OnEvent, nil, nil, OnEnter, nil, L["Item Level"], nil, ApplySettings)
