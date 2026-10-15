-- Thin oUF renderer for prediction data supplied by the Sirus client.
-- No spell database, addon messages, cast estimation or LibHealComm instance.
local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "SirusHealPrediction was unable to locate oUF")
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local hasAbsorbs = UnitGetTotalAbsorbs and true or false

local function Update(self)
	local unit = self.unit
	local element = self.HealCommBar

	--[[ Callback: HealthPrediction:PreUpdate(unit)
	Called before the element has been updated.

	* self - the HealthPrediction element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local myIncomingHeal = UnitGetIncomingHeals(unit, "player") or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
	local health = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)
	local maxOverflowHP = maxHealth * element.maxOverflow
	local healAbsorb = (UnitGetTotalHealAbsorbs and UnitGetTotalHealAbsorbs(unit)) or 0
	local currentHealAbsorb = math.min(health, healAbsorb)
	local otherIncomingHeal = 0

	if health - currentHealAbsorb + allIncomingHeal > maxOverflowHP then
		allIncomingHeal = math.max(0, maxOverflowHP - health + currentHealAbsorb)
	end

	if allIncomingHeal < myIncomingHeal then
		myIncomingHeal = allIncomingHeal
	else
		otherIncomingHeal = allIncomingHeal - myIncomingHeal
	end

	if element.myBar then
		element.myBar:SetMinMaxValues(0, maxHealth)
		element.myBar:SetValue(myIncomingHeal)
		element.myBar:Show()
	end

	if element.otherBar then
		element.otherBar:SetMinMaxValues(0, maxHealth)
		element.otherBar:SetValue(otherIncomingHeal)
		element.otherBar:Show()
	end

	-- absorbs are fed by the server (UNIT_ABSORB_AMOUNT_CHANGED), LibHealComm knows nothing about them
	local absorb, hasOverAbsorb, hasOverHealAbsorb = 0, false, false
	if hasAbsorbs then
		absorb = UnitGetTotalAbsorbs(unit) or 0

		if healAbsorb > health then
			hasOverHealAbsorb = true
		end

		if absorb > 0 and (health + absorb >= maxHealth or health - currentHealAbsorb + allIncomingHeal + absorb >= maxHealth) then
			hasOverAbsorb = true
		end

		if element.absorbBar then
			element.absorbBar:SetMinMaxValues(0, maxHealth)
			element.absorbBar:SetValue(absorb)
			element.absorbBar:Show()
		end

		if element.healAbsorbBar then
			element.healAbsorbBar:SetMinMaxValues(0, maxHealth)
			element.healAbsorbBar:SetValue(hasOverHealAbsorb and health or healAbsorb)
			element.healAbsorbBar:Show()
		end
	end

	--[[ Callback: HealthPrediction:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, health, maxHealth)
	Called after the element has been updated.

	* self               - the HealthPrediction element
	* unit               - the unit for which the update has been triggered (string)
	* myIncomingHeal     - the amount of incoming healing done by the player (number)
	* otherIncomingHeal  - the amount of incoming healing done by others (number)
	* absorb             - the amount of damage absorbs on the unit (number)
	* healAbsorb         - the amount of heal absorbs on the unit (number)
	* hasOverAbsorb      - whether the absorb reaches past the health bar (boolean)
	* hasOverHealAbsorb  - whether the heal absorb is larger than the unit's health (boolean)
	* health             - the unit's current health (number)
	* maxHealth          - the unit's maximum health (number)
	--]]
	if element.PostUpdate then
		return element:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, health, maxHealth)
	end
end

local function Path(self, event, unit, ...)
	if unit and unit ~= self.unit then return end
	--[[ Override: HealthPrediction.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event
	--]]
	return (self.HealCommBar.Override or Update) (self, event, unit, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self)
	local element = self.HealCommBar

	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_HEALTH", Path)
		self:RegisterEvent("UNIT_MAXHEALTH", Path)
		self:RegisterEvent("UNIT_HEAL_PREDICTION", Path)

		if hasAbsorbs then
			self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Path)
			self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Path)
		end

		if not element.maxOverflow then
			element.maxOverflow = 1.05
		end

		if element.myBar and element.myBar:IsObjectType("StatusBar") and not element.myBar:GetStatusBarTexture() then
			element.myBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		if element.otherBar and element.otherBar:IsObjectType("StatusBar") and not element.otherBar:GetStatusBarTexture() then
			element.otherBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		if element.absorbBar and element.absorbBar:IsObjectType("StatusBar") and not element.absorbBar:GetStatusBarTexture() then
			element.absorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		if element.healAbsorbBar and element.healAbsorbBar:IsObjectType("StatusBar") and not element.healAbsorbBar:GetStatusBarTexture() then
			element.healAbsorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end


		return true
	end
end

local function Disable(self)
	local element = self.HealCommBar

	if element then
		if element.myBar then
			element.myBar:Hide()
		end

		if element.otherBar then
			element.otherBar:Hide()
		end

		if element.absorbBar then
			element.absorbBar:Hide()
		end

		if element.healAbsorbBar then
			element.healAbsorbBar:Hide()
		end

		self:UnregisterEvent("UNIT_HEALTH", Path)
		self:UnregisterEvent("UNIT_MAXHEALTH", Path)
		self:UnregisterEvent("UNIT_HEAL_PREDICTION", Path)

		if hasAbsorbs then
			self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Path)
			self:UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Path)
		end


	end
end

oUF:AddElement("SirusHealPrediction", Path, Enable, Disable)