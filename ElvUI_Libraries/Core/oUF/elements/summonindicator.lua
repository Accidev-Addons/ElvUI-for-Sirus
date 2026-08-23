local _, ns = ...
local oUF = ns.oUF

local UnitExists = UnitExists
local C_IncomingSummon = C_IncomingSummon
local C_Timer = C_Timer

local SUMMON_TEXTURE = [[Interface\RaidFrame\RaidFrameSummon]]

-- Atlas-based icons (Retail); NilChecker falls back to SUMMON_TEXTURE below
local ATLAS = {
	[1] = 'Raid-Icon-SummonPending',
	[2] = 'Raid-Icon-SummonAccepted',
	[3] = 'Raid-Icon-SummonDeclined'
}

local DURATION = {
	[1] = 120,
	[2] = 10,
	[3] = 4
}

local function AutoHide(element, status)
	element.hideToken = (element.hideToken or 0) + 1
	if not (C_Timer and C_Timer.After) then return end

	local token = element.hideToken
	C_Timer:After(DURATION[status] or 10, function()
		if element.hideToken == token then
			element:Hide()
		end
	end)
end

local hasAPI = C_IncomingSummon and C_IncomingSummon.HasIncomingSummon and C_IncomingSummon.IncomingSummonStatus

local function Update(self, event)
	local element = self.SummonIndicator
	if not element then return end

	local unit = self.unit

	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local status = 0
	if hasAPI and unit and UnitExists(unit) and C_IncomingSummon.HasIncomingSummon(unit) then
		status = C_IncomingSummon.IncomingSummonStatus(unit)
	end

	if status and ATLAS[status] then
		pcall(element.SetAtlas, element, ATLAS[status])
		element:Show()
		AutoHide(element, status)
	elseif status and status > 0 then
		-- non-atlas fallback — just show the default texture
		if element:IsObjectType('Texture') and not element:GetTexture() then
			element:SetTexture(SUMMON_TEXTURE)
		end
		element:Show()
		AutoHide(element, status)
	else
		element.hideToken = (element.hideToken or 0) + 1
		element:Hide()
	end

	if element.PostUpdate then
		return element:PostUpdate(unit, status)
	end
end

local function Path(self, ...)
	return (self.SummonIndicator.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.SummonIndicator
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('INCOMING_SUMMON_CHANGED', Path, true)

		if element:IsObjectType('Texture') and not element:GetTexture() then
			element:SetTexture(SUMMON_TEXTURE)
		end

		element:Hide()

		return true
	end
end

local function Disable(self)
	local element = self.SummonIndicator
	if element then
		element.hideToken = (element.hideToken or 0) + 1
		element:Hide()

		self:UnregisterEvent('INCOMING_SUMMON_CHANGED', Path)
	end
end

oUF:AddElement('SummonIndicator', Path, Enable, Disable)