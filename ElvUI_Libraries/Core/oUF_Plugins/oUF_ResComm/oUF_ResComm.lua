--[[
# Element: Resurrect Indicator

Handles the visibility and updating of an indicator based on the unit's incoming resurrect status.

## Widget

ResurrectIndicator - A `Texture` used to display if the unit has an incoming resurrect.

## Notes

A default texture will be applied if the widget is a Texture and doesn't have a texture or a color set.

## Examples

    -- Position and size
    local ResurrectIndicator = self:CreateTexture(nil, 'OVERLAY')
    ResurrectIndicator:SetSize(16, 16)
    ResurrectIndicator:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.ResurrectIndicator = ResurrectIndicator
--]]

local _, ns = ...
local oUF = ns.oUF
assert(oUF, "oUF_ResComm was unable to locate oUF install")

local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local function Update(self, event)
	local unit = self.unit
	if not unit then return end

	local element = self.ResurrectIndicator

	--[[ Callback: ResurrectIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the ResurrectIndicator element
	--]]
	if element.PreUpdate then
		element:PreUpdate()
	end

	local incomingResurrect = UnitIsDeadOrGhost(unit) and UnitHasIncomingResurrection(unit)
	if incomingResurrect then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: ResurrectIndicator:PostUpdate(incomingResurrect)
	Called after the element has been updated.

	* self              - the ResurrectIndicator element
	* incomingResurrect - indicates if the unit has an incoming resurrection (boolean)
	--]]
	if element.PostUpdate then
		return element:PostUpdate(incomingResurrect)
	end
end

local function Path(self, ...)
	--[[ Override: ResurrectIndicator.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	return (self.ResurrectIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local element = self.ResurrectIndicator

	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("INCOMING_RESURRECT_CHANGED", Path, true)
		self:RegisterEvent("UNIT_HEALTH", Path)
		self:RegisterEvent("UNIT_FLAGS", Path)

		if element:IsObjectType("Texture") and not element:GetTexture() then
			element:SetTexture([[Interface\Icons\Spell_Holy_Resurrection]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.ResurrectIndicator

	if element then
		element:Hide()

		self:UnregisterEvent("INCOMING_RESURRECT_CHANGED", Path)
		self:UnregisterEvent("UNIT_HEALTH", Path)
		self:UnregisterEvent("UNIT_FLAGS", Path)
	end
end

oUF:AddElement("ResurrectIndicator", Path, Enable, Disable)