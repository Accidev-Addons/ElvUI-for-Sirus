local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")

--Lua functions
local max = math.max
--WoW API / Variables
local CreateFrame = CreateFrame
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

local ABSORB_GLOW = [[Interface\RaidFrame\Shield-Overshield]]
local HEAL_ABSORB_GLOW = [[Interface\RaidFrame\Absorb-Overabsorb]]
local GLOW_SIZE = 16

local hasAbsorbs = UnitGetTotalAbsorbs and true or false

function UF.HealthClipFrame_HealComm(frame)
	local pred = frame.HealCommBar
	if pred then
		UF:SetAlpha_HealComm(pred, true)
		UF:SetVisibility_HealComm(pred)
	end
end

function UF:SetAlpha_HealComm(obj, show)
	local alpha = show and 1 or 0

	obj.myBar:SetAlpha(alpha)
	obj.otherBar:SetAlpha(alpha)

	if hasAbsorbs then
		obj.absorbBar:SetAlpha(alpha)
		obj.healAbsorbBar:SetAlpha(alpha)
		obj.overlay:SetAlpha(alpha)
	end
end

function UF:SetVisibility_HealComm(obj)
	-- the first update is from `HealthClipFrame_HealComm`
	-- we set this variable to allow `Configure_HealComm` to
	-- update the elements overflow lock later on by option
	if not obj.allowClippingUpdate then
		obj.allowClippingUpdate = true
	end

	local parent = (obj.maxOverflow > 1 and obj.health) or obj.parent

	obj.myBar:SetParent(parent)
	obj.otherBar:SetParent(parent)

	if hasAbsorbs then
		obj.absorbBar:SetParent(parent)
		obj.healAbsorbBar:SetParent(parent)
		obj.overlay:SetParent(parent)
	end
end

function UF:Construct_HealComm(frame)
	local health = frame.Health
	local parent = health.ClipFrame

	local myBar = CreateFrame("StatusBar", nil, parent)
	local otherBar = CreateFrame("StatusBar", nil, parent)

	myBar:SetFrameLevel(11)
	otherBar:SetFrameLevel(11)

	UF.statusbars[myBar] = true
	UF.statusbars[otherBar] = true

	local texture = (not health.isTransparent and health:GetStatusBarTexture()) or E.media.blankTex
	UF:Update_StatusBar(myBar, texture)
	UF:Update_StatusBar(otherBar, texture)

	local healPrediction = {
		myBar = myBar,
		otherBar = otherBar,
		PostUpdate = UF.UpdateHealComm,
		maxOverflow = 1,
		health = health,
		parent = parent,
		frame = frame
	}

	if hasAbsorbs then
		local absorbBar = CreateFrame("StatusBar", nil, parent)
		local healAbsorbBar = CreateFrame("StatusBar", nil, parent)

		absorbBar:SetFrameLevel(11)
		healAbsorbBar:SetFrameLevel(11)

		UF.statusbars[absorbBar] = true
		UF.statusbars[healAbsorbBar] = true

		UF:Update_StatusBar(absorbBar, texture)
		UF:Update_StatusBar(healAbsorbBar, texture)

		-- glows sit above the bars, so they need their own frame level
		local overlay = CreateFrame("Frame", nil, parent)
		overlay:SetAllPoints(health)
		overlay:SetFrameLevel(12)

		local overAbsorb = overlay:CreateTexture(nil, "OVERLAY")
		overAbsorb:SetTexture(ABSORB_GLOW)
		overAbsorb:SetBlendMode("ADD")
		overAbsorb:Hide()

		local overHealAbsorb = overlay:CreateTexture(nil, "OVERLAY")
		overHealAbsorb:SetTexture(HEAL_ABSORB_GLOW)
		overHealAbsorb:SetBlendMode("ADD")
		overHealAbsorb:Hide()

		healPrediction.absorbBar = absorbBar
		healPrediction.healAbsorbBar = healAbsorbBar
		healPrediction.overlay = overlay
		healPrediction.overAbsorb = overAbsorb
		healPrediction.overHealAbsorb = overHealAbsorb
		healPrediction.absorbStyle = "NORMAL"
	end

	UF:SetAlpha_HealComm(healPrediction)

	return healPrediction
end

-- 3.3.5a has no StatusBar:SetReverseFill, so bars that have to grow backwards are
-- sized instead of filled: the bar is pinned to the far edge and its width is the amount
local function SetReversedAmount(bar, amount, maxValue, health, orientation)
	local percent = (maxValue > 0 and amount / maxValue) or 0
	if percent > 1 then percent = 1 end

	if orientation == "HORIZONTAL" then
		bar:SetWidth(max(percent * health:GetWidth(), 0.001))
	else
		bar:SetHeight(max(percent * health:GetHeight(), 0.001))
	end

	bar:SetMinMaxValues(0, 1)
	bar:SetValue(1)
end

local function ConfigureAbsorb(healPrediction, health, orientation)
	local absorbBar = healPrediction.absorbBar
	local healAbsorbBar = healPrediction.healAbsorbBar
	local overAbsorb = healPrediction.overAbsorb
	local overHealAbsorb = healPrediction.overHealAbsorb
	local healthTexture = health:GetStatusBarTexture()
	local style = healPrediction.absorbStyle

	healPrediction.orientation = orientation

	absorbBar:SetOrientation(orientation)
	healAbsorbBar:SetOrientation(orientation)

	absorbBar:ClearAllPoints()
	healAbsorbBar:ClearAllPoints()
	overAbsorb:ClearAllPoints()
	overHealAbsorb:ClearAllPoints()

	if orientation == "HORIZONTAL" then
		local width = health:GetWidth()
		width = (width > 0 and width) or health.WIDTH

		absorbBar:Point("TOP", health, "TOP")
		absorbBar:Point("BOTTOM", health, "BOTTOM")

		if style == "REVERSED" then
			absorbBar:SetWidth(0.001)
			absorbBar:Point("RIGHT", healthTexture, "RIGHT")
		elseif style == "STACKED" then
			absorbBar:Size(width, 0)
			absorbBar:Point("LEFT", healPrediction.otherBar:GetStatusBarTexture(), "RIGHT")
		else
			absorbBar:Size(width, 0)
			absorbBar:Point("LEFT", healthTexture, "RIGHT")
		end

		healAbsorbBar:SetWidth(0.001)
		healAbsorbBar:Point("TOP", health, "TOP")
		healAbsorbBar:Point("BOTTOM", health, "BOTTOM")
		healAbsorbBar:Point("RIGHT", healthTexture, "RIGHT")

		-- CENTER together with TOP/BOTTOM is over-constrained: the client drops its X and
		-- the glow lands in the middle of the frame, so pin an edge with half the width instead
		overAbsorb:SetWidth(GLOW_SIZE)
		overAbsorb:Point("TOP", health, "TOP")
		overAbsorb:Point("BOTTOM", health, "BOTTOM")
		overAbsorb:Point("LEFT", health, "RIGHT", -GLOW_SIZE * 0.5, 0)

		overHealAbsorb:SetWidth(GLOW_SIZE)
		overHealAbsorb:Point("TOP", health, "TOP")
		overHealAbsorb:Point("BOTTOM", health, "BOTTOM")
		overHealAbsorb:Point("LEFT", health, "LEFT", -GLOW_SIZE * 0.5, 0)
	else
		local height = health:GetHeight()
		height = (height > 0 and height) or health.HEIGHT

		absorbBar:Point("LEFT", health, "LEFT")
		absorbBar:Point("RIGHT", health, "RIGHT")

		if style == "REVERSED" then
			absorbBar:SetHeight(0.001)
			absorbBar:Point("TOP", healthTexture, "TOP")
		elseif style == "STACKED" then
			absorbBar:Size(0, height)
			absorbBar:Point("BOTTOM", healPrediction.otherBar:GetStatusBarTexture(), "TOP")
		else
			absorbBar:Size(0, height)
			absorbBar:Point("BOTTOM", healthTexture, "TOP")
		end

		healAbsorbBar:SetHeight(0.001)
		healAbsorbBar:Point("LEFT", health, "LEFT")
		healAbsorbBar:Point("RIGHT", health, "RIGHT")
		healAbsorbBar:Point("TOP", healthTexture, "TOP")

		overAbsorb:SetHeight(GLOW_SIZE)
		overAbsorb:Point("LEFT", health, "LEFT")
		overAbsorb:Point("RIGHT", health, "RIGHT")
		overAbsorb:Point("BOTTOM", health, "TOP", 0, -GLOW_SIZE * 0.5)

		overHealAbsorb:SetHeight(GLOW_SIZE)
		overHealAbsorb:Point("LEFT", health, "LEFT")
		overHealAbsorb:Point("RIGHT", health, "RIGHT")
		overHealAbsorb:Point("BOTTOM", health, "BOTTOM", 0, -GLOW_SIZE * 0.5)
	end
end

function UF:Configure_HealComm(frame)
	if frame.db.healPrediction and frame.db.healPrediction.enable then
		local healPrediction = frame.HealCommBar
		local myBar = healPrediction.myBar
		local otherBar = healPrediction.otherBar
		local c = self.db.colors.healPrediction
		healPrediction.maxOverflow = 1 + (c.maxOverflow or 0)

		if hasAbsorbs then
			local style = frame.db.healPrediction.absorbStyle
			if not style or style == "OVERFLOW" then -- OVERFLOW was dropped, keep old profiles working
				style = "NORMAL"
				frame.db.healPrediction.absorbStyle = style
			end

			healPrediction.absorbStyle = style
		end

		if healPrediction.allowClippingUpdate then
			UF:SetVisibility_HealComm(healPrediction)
		end

		if not frame:IsElementEnabled("HealComm4") then
			frame:EnableElement("HealComm4")
		end

		if frame.db.health then
			local health = frame.Health
			local orientation = frame.db.health.orientation or health:GetOrientation()

			myBar:SetOrientation(orientation)
			otherBar:SetOrientation(orientation)

			if orientation == "HORIZONTAL" then
				local width = health:GetWidth()
				width = (width > 0 and width) or health.WIDTH
				local healthTexture = health:GetStatusBarTexture()

				myBar:Size(width, 0)
				myBar:ClearAllPoints()
				myBar:Point("TOP", health, "TOP")
				myBar:Point("BOTTOM", health, "BOTTOM")
				myBar:Point("LEFT", healthTexture, "RIGHT")

				otherBar:Size(width, 0)
				otherBar:ClearAllPoints()
				otherBar:Point("TOP", health, "TOP")
				otherBar:Point("BOTTOM", health, "BOTTOM")
				otherBar:Point("LEFT", myBar:GetStatusBarTexture(), "RIGHT")
			else
				local height = health:GetHeight()
				height = (height > 0 and height) or health.HEIGHT
				local healthTexture = health:GetStatusBarTexture()

				myBar:Size(0, height)
				myBar:ClearAllPoints()
				myBar:Point("LEFT", health, "LEFT")
				myBar:Point("RIGHT", health, "RIGHT")
				myBar:Point("BOTTOM", healthTexture, "TOP")

				otherBar:Size(0, height)
				otherBar:ClearAllPoints()
				otherBar:Point("LEFT", health, "LEFT")
				otherBar:Point("RIGHT", health, "RIGHT")
				otherBar:Point("BOTTOM", myBar:GetStatusBarTexture(), "TOP")
			end

			if hasAbsorbs then
				ConfigureAbsorb(healPrediction, health, orientation)
			end
		end

		myBar:SetStatusBarColor(c.personal.r, c.personal.g, c.personal.b, c.personal.a)
		otherBar:SetStatusBarColor(c.others.r, c.others.g, c.others.b, c.others.a)

		if hasAbsorbs then
			healPrediction.absorbBar:SetStatusBarColor(c.absorbs.r, c.absorbs.g, c.absorbs.b, c.absorbs.a)
			healPrediction.healAbsorbBar:SetStatusBarColor(c.healAbsorbs.r, c.healAbsorbs.g, c.healAbsorbs.b, c.healAbsorbs.a)
		end
	elseif frame:IsElementEnabled("HealComm4") then
		frame:DisableElement("HealComm4")
	end
end

local function UpdateFillBar(frame, previousTexture, bar, amount)
	if amount == 0 then
		bar:Hide()
		return previousTexture
	end

	local orientation = frame:GetOrientation()
	bar:ClearAllPoints()
	if orientation == "HORIZONTAL" then
		bar:SetPoint("TOPLEFT", previousTexture, "TOPRIGHT")
		bar:SetPoint("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT")
	else
		bar:SetPoint("BOTTOMRIGHT", previousTexture, "TOPRIGHT")
		bar:SetPoint("BOTTOMLEFT", previousTexture, "TOPLEFT")
	end

	local totalWidth, totalHeight = frame:GetSize()
	if orientation == "HORIZONTAL" then
		bar:Width(totalWidth)
	else
		bar:Height(totalHeight)
	end

	return bar:GetStatusBarTexture()
end

function UF:UpdateHealComm(_, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, health, maxHealth)
	local healthBar = self.health
	local previousTexture = healthBar:GetStatusBarTexture()

	previousTexture = UpdateFillBar(healthBar, previousTexture, self.myBar, myIncomingHeal)
	UpdateFillBar(healthBar, previousTexture, self.otherBar, otherIncomingHeal)

	if not hasAbsorbs then return end

	local absorbBar = self.absorbBar
	local healAbsorbBar = self.healAbsorbBar
	local style = self.absorbStyle
	local orientation = self.orientation or healthBar:GetOrientation()
	local colors = UF.db.colors.healPrediction

	if style == "NONE" or absorb == 0 then
		absorbBar:Hide()
		self.overAbsorb:Hide()
	else
		if style == "REVERSED" then
			SetReversedAmount(absorbBar, absorb, maxHealth, healthBar, orientation)
		elseif hasOverAbsorb then
			-- the bar is clipped by the frame, so it is capped at the missing health
			local room = maxHealth - health
			if style == "STACKED" then
				room = room - myIncomingHeal - otherIncomingHeal
			end

			absorbBar:SetValue(max(room, 0))
		end

		local c = (hasOverAbsorb and colors.overabsorbs) or colors.absorbs
		absorbBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
		absorbBar:Show()

		if hasOverAbsorb then
			self.overAbsorb:Show()
		else
			self.overAbsorb:Hide()
		end
	end

	if style == "NONE" or healAbsorb == 0 then
		healAbsorbBar:Hide()
		self.overHealAbsorb:Hide()
	else
		SetReversedAmount(healAbsorbBar, (hasOverHealAbsorb and health) or healAbsorb, maxHealth, healthBar, orientation)

		local c = (hasOverHealAbsorb and colors.overhealabsorbs) or colors.healAbsorbs
		healAbsorbBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
		healAbsorbBar:Show()

		if hasOverHealAbsorb then
			self.overHealAbsorb:Show()
		else
			self.overHealAbsorb:Hide()
		end
	end
end
