local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

--Lua functions
--WoW API / Variables
local UnitPlayerControlled = UnitPlayerControlled
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList

local function IsTapDenied(unit)
	return not UnitPlayerControlled(unit) and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit)
end

function NP:GetHealthColor(frame)
	local r, g, b
	local scale = 1

	local class = frame.UnitClass
	local classColor = E:ClassColor(class)
	local useClassColor = NP.db.units[frame.UnitType].health.useClassColor
	if classColor and ((frame.UnitType == "FRIENDLY_PLAYER" and useClassColor) or (frame.UnitType == "ENEMY_PLAYER" and useClassColor)) then
		r, g, b = classColor.r, classColor.g, classColor.b
	else
		local db = self.db.colors
		local status = frame.ThreatStatus
		if status then
			if status == 3 then
				if E.myrole == "TANK" then
					r, g, b = db.threat.goodColor.r, db.threat.goodColor.g, db.threat.goodColor.b
					scale = NP.db.threat.goodScale
				else
					r, g, b = db.threat.badColor.r, db.threat.badColor.g, db.threat.badColor.b
					scale = NP.db.threat.badScale
				end
			elseif status == 2 then
				if E.myrole == "TANK" then
					r, g, b = db.threat.badTransition.r, db.threat.badTransition.g, db.threat.badTransition.b
				else
					r, g, b = db.threat.goodTransition.r, db.threat.goodTransition.g, db.threat.goodTransition.b
				end
			elseif status == 1 then
				if E.myrole == "TANK" then
					r, g, b = db.threat.goodTransition.r, db.threat.goodTransition.g, db.threat.goodTransition.b
				else
					r, g, b = db.threat.badTransition.r, db.threat.badTransition.g, db.threat.badTransition.b
				end
			else
				if E.myrole == "TANK" then
					r, g, b = db.threat.badColor.r, db.threat.badColor.g, db.threat.badColor.b
					scale = self.db.threat.badScale
				else
					r, g, b = db.threat.goodColor.r, db.threat.goodColor.g, db.threat.goodColor.b
					scale = self.db.threat.goodScale
				end
			end
		end

		if (not status) or (status and not NP.db.threat.useThreatColor) then
			local reactionType = frame.UnitReaction
			if reactionType == 4 then
				r, g, b = db.reactions.neutral.r, db.reactions.neutral.g, db.reactions.neutral.b
			elseif reactionType and reactionType > 4 then
				if frame.UnitType == "FRIENDLY_PLAYER" then
					r, g, b = db.reactions.friendlyPlayer.r, db.reactions.friendlyPlayer.g, db.reactions.friendlyPlayer.b
				else
					r, g, b = db.reactions.good.r, db.reactions.good.g, db.reactions.good.b
				end
			else
				r, g, b = db.reactions.bad.r, db.reactions.bad.g, db.reactions.bad.b
			end
		end
	end

	if frame.unit and IsTapDenied(frame.unit) then
		local tapped = self.db.colors.tapped
		r, g, b = tapped.r, tapped.g, tapped.b
	end

	return r, g, b, scale
end

function NP:Update_HealthColor(frame)
	if not frame.Health:IsShown() then return end

	local r, g, b, scale = NP:GetHealthColor(frame)

	if r ~= frame.Health.r or g ~= frame.Health.g or b ~= frame.Health.b then
		if not frame.HealthColorChanged then
			frame.Health:SetStatusBarColor(r, g, b)

			if frame.HealthColorChangeCallbacks then
				for _, cb in ipairs(frame.HealthColorChangeCallbacks) do
					cb(self, frame, r, g, b)
				end
			end
		end
		frame.Health.r, frame.Health.g, frame.Health.b = r, g, b
	end

	if frame.ThreatScale ~= scale then
		frame.ThreatScale = scale
		if frame.isTarget and self.db.useTargetScale then
			scale = scale * self.db.targetScale
		end
		self:SetFrameScale(frame, scale * (frame.ActionScale or 1))
	end
end

function NP:Update_Health(frame)
	if not frame.Health:IsShown() then return end

	local health, maxHealth = NP:GetHealth(frame)
	frame.Health:SetMinMaxValues(0, maxHealth)

	if frame.HealthValueChangeCallbacks then
		for _, cb in ipairs(frame.HealthValueChangeCallbacks) do
			cb(self, frame, health, maxHealth)
		end
	end

	frame.Health:SetValue(health)
	frame.FlashTexture:Point("TOPRIGHT", frame.Health:GetStatusBarTexture(), "TOPRIGHT") --idk why this fixes this

	if self.db.units[frame.UnitType].health.text.enable then
		frame.Health.Text:SetText(E:GetFormattedText(self.db.units[frame.UnitType].health.text.format, health, maxHealth, nil, true))
	end

	frame.polledHealth, frame.polledMaxHealth = health, maxHealth
	NP:Update_Absorb(frame)
end

function NP:RegisterHealthBarCallbacks(frame, valueChangeCB, colorChangeCB)
	if valueChangeCB then
		frame.HealthValueChangeCallbacks = frame.HealthValueChangeCallbacks or {}
		tinsert(frame.HealthValueChangeCallbacks, valueChangeCB)
	end

	if colorChangeCB then
		frame.HealthColorChangeCallbacks = frame.HealthColorChangeCallbacks or {}
		tinsert(frame.HealthColorChangeCallbacks, colorChangeCB)
	end
end

function NP:Update_HealthBar(frame)
	frame.Health:SetShown(self.db.units[frame.UnitType].health.enable or (frame.isTarget and self.db.alwaysShowTargetHealth))
end

function NP:Configure_HealthBarScale(frame, scale, noPlayAnimation)
	local width = NP:Pixel(self.db.units[frame.UnitType].health.width * scale, true)
	local height = NP:Pixel(self.db.units[frame.UnitType].health.height * scale)

	if noPlayAnimation then
		frame.Health:SetWidth(width)
		frame.Health:SetHeight(height)
	else
		if frame.Health.scale:IsPlaying() then
			frame.Health.scale:Stop()
		end

		frame.Health.scale.width:SetChange(width)
		frame.Health.scale.height:SetChange(height)
		frame.Health.scale:Play()
	end
end

function NP:Configure_HealthBar(frame, configuring)
	local db = self.db.units[frame.UnitType].health
	local healthBar = frame.Health

	healthBar:SetPoint("TOP", frame, "TOP", 0, 0)

	if configuring then
		healthBar:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.statusbar), "BORDER")

		self:Configure_HealthBarScale(frame, frame.currentScale or 1, configuring)

		E:SetSmoothing(healthBar, self.db.smoothbars)

		healthBar.Text:FontTemplate(LSM:Fetch("font", db.text.font), db.text.fontSize, db.text.fontOutline)

		if db.text.enable then
			healthBar.Text:ClearAllPoints()
			healthBar.Text:Point(E.InversePoints[db.text.position], db.text.parent == "Nameplate" and frame or frame[db.text.parent], db.text.position, db.text.xOffset, db.text.yOffset)
			healthBar.Text:Show()
		else
			healthBar.Text:Hide()
		end
	end
end

local function HealthBar_OnSizeChanged(self, width)
	local health = self:GetValue()
	local _, maxHealth = self:GetMinMaxValues()
	if not maxHealth or maxHealth == 0 then return end

	self:GetStatusBarTexture():SetPoint("TOPRIGHT", -(width * ((maxHealth - health) / maxHealth)), 0)
	if self:GetParent().UnitType then NP:Update_Absorb(self:GetParent()) end
end

function NP:Construct_HealthBar(parent)
	local frame = CreateFrame("StatusBar", "$parentHealthBar", parent)
	frame:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.statusbar), "BORDER")
	self:StyleFrame(frame)

	frame:SetScript("OnSizeChanged", HealthBar_OnSizeChanged)

	parent.FlashTexture = frame:CreateTexture(nil, "OVERLAY")
	parent.FlashTexture:SetTexture(LSM:Fetch("background", "ElvUI Blank"))
	parent.FlashTexture:Point("BOTTOMLEFT", frame:GetStatusBarTexture(), "BOTTOMLEFT")
	parent.FlashTexture:Point("TOPRIGHT", frame:GetStatusBarTexture(), "TOPRIGHT")
	parent.FlashTexture:Hide()

	frame.Text = frame:CreateFontString(nil, "OVERLAY")
	frame.Text:SetAllPoints(frame)
	frame.Text:SetWordWrap(false)

	frame.scale = CreateAnimationGroup(frame)
	frame.scale.width = frame.scale:CreateAnimation("Width")
	frame.scale.width:SetDuration(0.2)
	frame.scale.height = frame.scale:CreateAnimation("Height")
	frame.scale.height:SetDuration(0.2)

	frame:Hide()

	return frame
end
local function HidePlateLabel(text)
	if not text then return end
	text:Hide()
	if text.lastValue ~= nil then text:SetText("") end
	text.lastValue, text.lastClass, text.lastStatus = nil, nil, nil
end

function NP:Configure_Absorb(frame)
	local healthBar = frame.Health
	local absorbDB = self.db.units[frame.UnitType].health.absorb
	if not absorbDB or not absorbDB.enable then
		if healthBar.Absorb then healthBar.Absorb:Hide() end
		HidePlateLabel(healthBar.AbsorbText)
		return
	end
	local overlay, text = healthBar.Absorb, healthBar.AbsorbText
	if not overlay then
		overlay = healthBar:CreateTexture(nil, "ARTWORK")
		overlay:SetTexture(E.media.blankTex)
		overlay:SetVertexColor(0.3, 0.75, 1, 0.55)
		healthBar.Absorb = overlay
		text = healthBar:CreateFontString(nil, "OVERLAY")
		text:SetWordWrap(false)
		healthBar.AbsorbText = text
		overlay:Hide()
		text:Hide()
	end
	text:FontTemplate(LSM:Fetch("font", absorbDB.font), absorbDB.fontSize, absorbDB.fontOutline)
	text:ClearAllPoints()
	text:SetPoint(absorbDB.position, healthBar, absorbDB.position, NP:Pixel(absorbDB.xOffset), NP:Pixel(absorbDB.yOffset))
	overlay:ClearAllPoints()
	overlay.lastWidth, overlay.lastOffset = nil, nil
end

function NP:Update_Absorb(frame)
	local healthBar = frame.Health
	local absorbDB = self.db.units[frame.UnitType].health.absorb
	if not absorbDB or not absorbDB.enable or (not frame.unit and not frame.testUnitType) or not healthBar:IsShown() then
		if healthBar.Absorb then healthBar.Absorb:Hide() end
		HidePlateLabel(healthBar.AbsorbText)
		return
	end
	local absorb
	if frame.testUnitType then
		absorb = frame.testAbsorb or 0
	else
		absorb = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(frame.unit) or 0
	end
	local health, maxHealth = NP:GetHealth(frame)
	if absorb <= 0 or maxHealth <= 0 then
		if healthBar.Absorb then healthBar.Absorb:Hide() end
		HidePlateLabel(healthBar.AbsorbText)
		return
	end
	if not healthBar.Absorb then NP:Configure_Absorb(frame) end
	local overlay, text = healthBar.Absorb, healthBar.AbsorbText
	local barWidth = healthBar:GetWidth()
	local width = barWidth * math.min(absorb / maxHealth, 1)
	local offset = math.min(barWidth * health / maxHealth, barWidth - width)
	if overlay.lastOffset ~= offset then
		overlay:SetPoint("TOPLEFT", healthBar, "TOPLEFT", offset, 0)
		overlay:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", offset, 0)
		overlay.lastOffset = offset
	end
	if overlay.lastWidth ~= width then overlay:SetWidth(width) overlay.lastWidth = width end
	overlay:Show()
	if absorbDB.showText then
		if text.lastValue ~= absorb then text:SetText("+"..E:ShortValue(absorb)) text.lastValue = absorb end
		text:Show()
	else
		HidePlateLabel(text)
	end
end

function NP:Configure_PlateLabel(frame, key)
	local db = self.db.units[frame.UnitType][key]
	local text = frame[key]
	if not db.enable or (key == "threatText" and frame.UnitType ~= "ENEMY_NPC") then
		HidePlateLabel(text)
		return nil, db
	end
	local parent = NP:GetTextLayerParent(frame, db.layer or "OVERLAY")
	if not text then
		text = parent:CreateFontString(nil, "OVERLAY")
		text:SetWordWrap(false)
		frame[key] = text
	end
	if text:GetParent() ~= parent then text:SetParent(parent) end
	text:FontTemplate(LSM:Fetch("font", db.font), db.fontSize, db.fontOutline)
	text:ClearAllPoints()
	text:SetPoint(db.position, frame.Health, db.position, NP:Pixel(db.xOffset), NP:Pixel(db.yOffset))
	text:SetJustifyH(db.justifyH)
	return text, db
end

function NP:Configure_PlateExtras(frame)
	NP:Configure_Absorb(frame)
	NP:Configure_PlateLabel(frame, "threatText")
end

function NP:Update_ThreatText(frame)
	local db = self.db.units[frame.UnitType].threatText
	if not db.enable or frame.UnitType ~= "ENEMY_NPC" or (not frame.unit and not frame.testUnitType) or not frame.Health:IsShown() then
		HidePlateLabel(frame.threatText)
		return
	end
	local _, status, percent
	if frame.testUnitType then
		status, percent = 2, 75
	elseif UnitCanAttack("player", frame.unit) then
		_, status, percent = UnitDetailedThreatSituation("player", frame.unit)
	end
	if percent == nil then HidePlateLabel(frame.threatText) return end
	local text = frame.threatText or NP:Configure_PlateLabel(frame, "threatText")
	if text.lastValue ~= percent then text:SetText(string.format("%.0f%%", percent)) text.lastValue = percent end
	if text.lastStatus ~= status then text:SetTextColor(GetThreatStatusColor(status or 0)) text.lastStatus = status end
	text:Show()
end
