local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")

local strjoin = strjoin
local format = format

local CR_ARMOR_PENETRATION = CR_ARMOR_PENETRATION

local GetCombatRating = GetCombatRating
local GetArmorPenetration = GetArmorPenetration

local displayString = ''
local APRating, APPercent = 0, 0

local function OnEvent(self)
	APRating = GetCombatRating(CR_ARMOR_PENETRATION)
	APPercent = GetArmorPenetration()

	self.text:SetFormattedText(displayString, L["Armor Penetration"], APRating)
end

local function OnEnter()
	DT.tooltip:ClearLines()

	DT.tooltip:AddDoubleLine(L["Armor Penetration"], format('%d (%.2f%%)', APRating, APPercent), 1, 1, 1)

	DT.tooltip:Show()
end

local function ApplySettings(_, hex)
	displayString = strjoin('', '%s: ', hex, '%d|r')
end

DT:RegisterDatatext('Armor Penetration', L["Enhancements"], { 'COMBAT_RATING_UPDATE' }, OnEvent, nil, nil, OnEnter, nil, L["Armor Penetration"], nil, ApplySettings)
