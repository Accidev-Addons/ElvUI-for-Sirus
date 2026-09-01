local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

--Lua functions
local select, wipe = select, wipe
local tinsert = table.insert
local floor = math.floor
local split = string.split
--WoW API / Variables
local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitAura = UnitAura

local VISIBLE, HIDDEN = 1, 0

local positionValues = {
	BOTTOMLEFT = "TOP",
	BOTTOMRIGHT = "TOP",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	TOPLEFT = "BOTTOM",
	TOPRIGHT = "BOTTOM"
}

local positionValues2 = {
	BOTTOMLEFT = "BOTTOM",
	BOTTOMRIGHT = "BOTTOM",
	LEFT = "LEFT",
	RIGHT = "RIGHT",
	TOPLEFT = "TOP",
	TOPRIGHT = "TOP"
}


local playerSpells = {}

local playerFilters = {
	HELPFUL = "HELPFUL|PLAYER",
	HARMFUL = "HARMFUL|PLAYER"
}

function NP:UpdateTime(elapsed)
	local timeLeft = self.endTime - GetTime()
	self.timeLeft = timeLeft
	self:SetValue(timeLeft)

	if timeLeft < 0 then
		self:SetScript("OnUpdate", nil)
		self:Hide()
		return
	end

	if E:Cooldown_TimerEnabled(self) then
		E.Cooldown_OnUpdate(self, elapsed)
	else
		self.nextUpdate = 0
		self.text:SetText("")
	end
end

local unstableAffliction = GetSpellInfo(30108)
local vampiricTouch = GetSpellInfo(34914)
function NP:SetAura(frame, unit, index, filter, isDebuff, visible, spells)
	local isAura, name, texture, count, debuffType, duration, expiration, caster, spellID, _

	if unit then
		name, _, texture, count, debuffType, duration, expiration, caster, _, _, spellID = UnitAura(unit, index, filter)
		isAura = name ~= nil
	end

	if frame.forceShow then
		spellID = 47540
		name, _, texture = GetSpellInfo(spellID)
		isAura, count, debuffType, duration, expiration = true, 5, "Magic", 0, 0
	end

	if isAura then
		local position = visible + 1
		local button = frame[position] or NP:Construct_AuraIcon(frame, position)

		local filterCheck = true
		if not frame.forceShow then
			filterCheck = NP:AuraFilter(unit, button, name, texture, count, debuffType, duration, expiration, caster, spellID, spells)
		end

		if filterCheck then
			if button.icon then button.icon:SetTexture(texture) end
			if button.count then button.count:SetText(count > 1 and count) end

			if duration > 0 and expiration ~= 0 then
				local timeLeft = expiration - GetTime()
				if timeLeft > 0 then
					button.timeLeft = timeLeft
					button.endTime = expiration
					button.nextUpdate = 0

					button:SetMinMaxValues(0, duration)
					button:SetValue(timeLeft)

					button:SetScript("OnUpdate", NP.UpdateTime)
				end
			else
				button.timeLeft = nil
				button.endTime = nil
				button.text:SetText("")
				button:SetScript("OnUpdate", nil)
				button:SetMinMaxValues(0, 1)
				button:SetValue(0)
			end

			button:SetID(index)
			button:Show()

			if isDebuff then
				local color = (debuffType and DebuffTypeColor[debuffType]) or DebuffTypeColor.none
				if name and (name == unstableAffliction or name == vampiricTouch) and E.myclass ~= "WARLOCK" then
					self:StyleFrameColor(button, 0.05, 0.85, 0.94)
				else
					self:StyleFrameColor(button, color.r * 0.6, color.g * 0.6, color.b * 0.6)
				end
			end

			return VISIBLE
		else
			return HIDDEN
		end
	end
end

function NP:Update_AurasPosition(frame, db)
	local size = db.size + db.spacing
	local anchor = E.InversePoints[db.anchorPoint]
	local growthx = (db.growthX == "LEFT" and -1) or 1
	local growthy = (db.growthY == "DOWN" and -1) or 1
	local cols = db.perrow

	for i = frame.anchoredIcons + 1, #frame do
		local button = frame[i]
		if not button then break end

		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)

		button:SetSize(db.size, db.size)
		button:ClearAllPoints()
		button:SetPoint(anchor, frame, anchor, col * size * growthx, row * size * growthy)

		button.count:FontTemplate(LSM:Fetch("font", db.countFont), db.countFontSize, db.countFontOutline)
		button.count:ClearAllPoints()
		button.count:SetPoint(db.countPosition, db.countXOffset, db.countYOffset)

		button.text:FontTemplate(LSM:Fetch("font", db.durationFont), db.durationFontSize, db.durationFontOutline)
		button.text:ClearAllPoints()
		button.text:SetPoint(db.durationPosition, db.durationXOffset, db.durationYOffset)

		button:SetOrientation(db.cooldownOrientation)

		button.bg:ClearAllPoints()
		if db.cooldownOrientation == "VERTICAL" then
			button.bg:SetPoint("TOPLEFT", button)
			button.bg:SetPoint("BOTTOMRIGHT", button:GetStatusBarTexture(), "TOPRIGHT")
		else
			button.bg:SetPoint("TOPRIGHT", button)
			button.bg:SetPoint("BOTTOMLEFT", button:GetStatusBarTexture(), "BOTTOMRIGHT")
		end

		if db.reverseCooldown then
			button:SetStatusBarColor(0, 0, 0, 0.5)
			button.bg:SetTexture(0, 0, 0, 0)
		else
			button:SetStatusBarColor(0, 0, 0, 0)
			button.bg:SetTexture(0, 0, 0, 0.5)
		end
	end
end

function NP:UpdateElement_AuraIcons(frame, unit, filter, limit, isDebuff)
	local index, visible = 1, 0

	wipe(playerSpells)

	if unit then
		local playerFilter = playerFilters[filter]
		local i = 1
		while true do
			local name, _, _, _, _, _, expiration, _, _, _, spellID = UnitAura(unit, i, playerFilter)
			if not name then break end

			if spellID then
				playerSpells[spellID] = expiration
			end

			i = i + 1
		end
	end

	while visible < limit do
		local result = NP:SetAura(frame, unit, index, filter, isDebuff, visible, playerSpells)
		if not result then
			break
		elseif result == VISIBLE then
			visible = visible + 1
		end
		index = index + 1
	end

	for i = visible + 1, #frame do
		frame[i].timeLeft = nil
		frame[i]:SetScript("OnUpdate", nil)
		frame[i]:Hide()
	end
	return visible
end

function NP:UpdateElement_Auras(frame)
	if not frame.Health:IsShown() then return end

	local unit = frame.unit
	if not unit and not frame.Buffs.forceShow and not frame.Debuffs.forceShow then
		return
	end

	local db = NP.db.units[frame.UnitType].buffs
	if db.enable then
		local buffs = frame.Buffs
		NP:UpdateElement_AuraIcons(buffs, unit, "HELPFUL", db.perrow * db.numrows)

		if #buffs > buffs.anchoredIcons then
			self:Update_AurasPosition(buffs, db)

			buffs.anchoredIcons = #buffs
		end
	end

	db = NP.db.units[frame.UnitType].debuffs
	if db.enable then
		local debuffs = frame.Debuffs
		NP:UpdateElement_AuraIcons(debuffs, unit, "HARMFUL", db.perrow * db.numrows, true)

		if #debuffs > debuffs.anchoredIcons then
			self:Update_AurasPosition(debuffs, db)

			debuffs.anchoredIcons = #debuffs
		end
	end

	self:StyleFilterUpdate(frame, "UNIT_AURA")
end

function NP:Construct_AuraIcon(parent, index)
	local db = NP.db.units[parent:GetParent().UnitType][parent.type]

	local button = CreateFrame("StatusBar", "$parentButton"..index, parent)
	NP:StyleFrame(button, true)

	button:SetStatusBarTexture(E.media.blankTex)
	button:SetStatusBarColor(0, 0, 0, 0)
	button:SetOrientation("VERTICAL")

	button.bg = button:CreateTexture()
	button.bg:SetTexture(0, 0, 0, 0.5)

	button.bg:SetPoint("TOPLEFT", button)
	button.bg:SetPoint("BOTTOMRIGHT", button:GetStatusBarTexture(), "TOPRIGHT")

	button.icon = button:CreateTexture(nil, "BORDER")
	button.icon:SetTexCoords()
	button.icon:SetAllPoints()

	button.count = button:CreateFontString(nil, "OVERLAY")
	button.count:SetJustifyH("RIGHT")
	button.count:FontTemplate(LSM:Fetch("font", db.countFont), db.countFontSize, db.countFontOutline)

	button.text = button:CreateFontString(nil, "OVERLAY")

	-- support cooldown override
	E:RegisterCooldownOverride(button, "nameplates")

	button.text:FontTemplate(LSM:Fetch("font", db.durationFont), db.durationFontSize, db.durationFontOutline)

	NP:Update_CooldownOptions(button)

	tinsert(parent, button)

	return button
end

function NP:Update_CooldownOptions(button)
	E:Cooldown_Options(button, self.db.cooldown, button)
end

function NP:Configure_Auras(frame, auraType)
	local auras = frame[auraType]
	local db = self.db.units[frame.UnitType][auras.type]

	auras.anchoredIcons = 0

	auras:SetWidth(db.perrow * db.size + ((db.perrow - 1) * db.spacing))
	auras:SetHeight(db.numrows * db.size + ((db.numrows - 1) * db.spacing))
	auras:ClearAllPoints()
	auras:SetPoint(positionValues[db.anchorPoint], db.attachTo == "BUFFS" and frame.Buffs or frame.Health, positionValues2[db.anchorPoint], db.xOffset, db.yOffset)
end

function NP:ConstructElement_Auras(frame, auraType)
	local auras = CreateFrame("Frame", "$parent"..auraType, frame)
	auras:Show()
	auras:SetSize(150, 27)
	auras:SetPoint("TOP", 0, 22)
	auras.anchoredIcons = 0
	auras.type = string.lower(auraType)

	return auras
end

function NP:CheckFilter(name, spellID, isPlayer, allowDuration, noDuration, ...)
	for i = 1, select("#", ...) do
		local filterName = select(i, ...)
		if G.nameplates.specialFilters[filterName] or E.global.unitframe.aurafilters[filterName] then
			local filter = E.global.unitframe.aurafilters[filterName]
			if filter then
				local filterType = filter.type
				local spellList = filter.spells
				local spell = spellList and (spellList[spellID] or spellList[name])

				if filterType and (filterType == "Whitelist") and (spell and spell.enable) and allowDuration then
					return true
				elseif filterType and (filterType == "Blacklist") and (spell and spell.enable) then
					return false
				end
			elseif filterName == "Personal" and isPlayer and allowDuration then
				return true
			elseif filterName == "nonPersonal" and (not isPlayer) and allowDuration then
				return true
			elseif filterName == "blockNoDuration" and noDuration then
				return false
			elseif filterName == "blockNonPersonal" and (not isPlayer) then
				return false
			end
		end
	end
end

function NP:AuraFilter(unit, button, name, texture, count, debuffType, duration, expiration, caster, spellID, spells)
	local parent = button:GetParent()
	local parentType = parent.type
	local db = NP.db.units[parent:GetParent().UnitType][parentType]
	if not db then return true end

	local isPlayer = (spells and spells[spellID] == expiration) or caster == "player"

	button.expirationTime = expiration
	button.name = name
	button.spellID = spellID

	if not db.filters then return true end

	local priority = db.filters.priority
	local noDuration = (not duration or duration == 0)
	local allowDuration = noDuration or (duration and (duration > 0) and db.filters.maxDuration == 0 or duration <= db.filters.maxDuration) and (db.filters.minDuration == 0 or duration >= db.filters.minDuration)
	local filterCheck

	if priority ~= "" then
		filterCheck = NP:CheckFilter(name, spellID, isPlayer, allowDuration, noDuration, split(",", priority))
	else
		filterCheck = allowDuration and true -- Allow all auras to be shown when the filter list is empty, while obeying duration sliders
	end

	return filterCheck
end