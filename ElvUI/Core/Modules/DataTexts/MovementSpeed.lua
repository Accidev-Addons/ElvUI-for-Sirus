local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin
local GetUnitSpeed = GetUnitSpeed

local BASE_MOVEMENT_SPEED = 7

local displayString, db = ''

local function UpdateSpeed(self)
	local percent = GetUnitSpeed('player') / BASE_MOVEMENT_SPEED * 100
	if db.NoLabel then
		self.text:SetFormattedText(displayString, percent)
	else
		self.text:SetFormattedText(displayString, db.Label ~= '' and db.Label or L["Mov. Speed"], percent)
	end
end

local function OnUpdate(self, elapsed)
	self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
	if self.timeSinceLastUpdate >= 1 then
		UpdateSpeed(self)
		self.timeSinceLastUpdate = 0
	end
end

local function OnEvent(self, event)
	self:SetScript('OnUpdate', OnUpdate)
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	displayString = strjoin('', db.NoLabel and '' or '%s: ', hex, '%.'..db.decimalLength..'f%%|r')
end

DT:RegisterDatatext('MovementSpeed', L["Enhancements"], { 'UNIT_STATS', 'UNIT_AURA', 'COMBAT_RATING_UPDATE' }, OnEvent, nil, nil, nil, nil, L["Movement Speed"], nil, ApplySettings)