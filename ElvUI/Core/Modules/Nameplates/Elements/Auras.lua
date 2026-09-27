local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

--Lua functions
local select, wipe = select, wipe
local tinsert = table.insert
local floor, ceil, min = math.floor, math.ceil, math.min
local split = string.split
--WoW API / Variables
local CreateFrame = CreateFrame
local GetCVar = GetCVar
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitAura = UnitAura

local DebuffColors = E.DebuffColors

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

function NP:StyleAura(button, index, texture, count, debuffType, duration, expiration, isDebuff, spellID, name)
	if button.icon then button.icon:SetTexture(texture) end
	if button.count then button.count:SetText(count > 1 and count) end

	if duration and duration > 0 and expiration and expiration ~= 0 then
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

	button.expirationTime = expiration
	button.spellID = spellID
	button.name = name

	button:SetID(index)
	button:Show()

	if isDebuff then
		local color = (debuffType and DebuffColors[debuffType]) or DebuffColors.none
		if name and (name == unstableAffliction or name == vampiricTouch) and E.myclass ~= "WARLOCK" then
			self:StyleFrameColor(button, 0.05, 0.85, 0.94)
		else
			self:StyleFrameColor(button, color.r * 0.6, color.g * 0.6, color.b * 0.6)
		end
	end
end

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
			NP:StyleAura(button, index, texture, count, debuffType, duration, expiration, isDebuff, spellID, name)

			return VISIBLE
		else
			return HIDDEN
		end
	end
end

local function GetAuraDB(frame, auraType)
	local units = NP.db.units[frame.UnitType]
	if not units then return end

	return units[auraType] or units.debuffs
end

local function GetSirusAurasFrame(frame)
	local unitFrame = NP:GetSirusUnitFrame(frame:GetParent())

	return unitFrame and unitFrame.AurasFrame
end

local sirusListFrames = {
	buffs = "BuffListFrame",
	debuffs = "DebuffListFrame",
	crowdcontrol = "CrowdControlListFrame"
}

local sirusAuraLists = {
	buffs = "buffList",
	debuffs = "debuffList",
	crowdcontrol = "crowdControlList"
}

local sirusContainers = { "Buffs", "Debuffs", "CrowdControl", "LossOfControl" }

local namePointsAbove = {
	TOP = true,
	TOPLEFT = true,
	TOPRIGHT = true
}

local function GetSirusAuraAnchor(frame, auraType)
	local db = NP.db.units[frame.UnitType]

	if auraType == "debuffs" then
		local padding = NP:SirusPixel(tonumber(GetCVar(_G.NamePlateConstants.DEBUFF_PADDING_CVAR)) or 0)

		return "BOTTOMLEFT", (db.name.enable and namePointsAbove[db.name.position]) and frame.Name or frame.Health, "TOPLEFT", 0, padding
	elseif auraType == "buffs" then
		return "RIGHT", frame.Health, "LEFT", -NP:SirusPixel(5), 0
	end

	return "LEFT", (db.level.enable and db.level.position == "RIGHT") and frame.Level or frame.Health, "RIGHT", NP:SirusPixel(5), 0
end

local function ConfigureSirusAuras(frame, auras, aurasFrame)
	local list = aurasFrame[sirusListFrames[auras.type]]
	local itemScale = aurasFrame.auraItemScale
	local stride, limit = list.stride, list.maxAuraItemsDisplayed
	local perrow = min(stride, limit)
	local numrows = ceil(limit / perrow)
	local size = NP:SirusPixel(_G.NamePlateConstants.AURA_ITEM_HEIGHT * (itemScale or 1))
	local spacing, rowSpacing = NP:SirusPixel(list.childXPadding), NP:SirusPixel(list.childYPadding)
	local goingUp, goingRight = list.layoutFramesGoingUp, list.layoutFramesGoingRight

	local layout = auras.sirusLayout or {}
	layout.point = (goingUp and "BOTTOM" or "TOP") .. (goingRight and "LEFT" or "RIGHT")
	layout.growthX = goingRight and "RIGHT" or "LEFT"
	layout.growthY = goingUp and "UP" or "DOWN"
	layout.size, layout.spacing, layout.rowSpacing, layout.perrow = size, spacing, rowSpacing, perrow

	auras.sirusLayout, auras.sirusList, auras.sirusScale, auras.sirusStride = layout, list, itemScale, stride
	auras.anchoredIcons = 0

	auras:SetSize(perrow * size + (perrow - 1) * spacing, numrows * size + (numrows - 1) * rowSpacing)
	auras:ClearAndSetPoint(GetSirusAuraAnchor(frame, auras.type))
end

local sirusItems = {}
local numSirusItems = 0

local function CollectSirusAuraItems(...)
	numSirusItems = 0

	for i = 1, select("#", ...) do
		local item = select(i, ...)
		local index = item.layoutIndex

		if index then
			sirusItems[index] = item

			if index > numSirusItems then
				numSirusItems = index
			end
		end

		item:Hide()
	end

	return numSirusItems
end

local function UpdateSirusAuraList(frame, auras, aurasFrame, draw)
	local list = aurasFrame[sirusListFrames[auras.type]]
	local count = CollectSirusAuraItems(list:GetChildren())
	local db = GetAuraDB(frame, auras.type)
	local show = draw and db and db.enable and list:IsVisible()
	local auraList = aurasFrame[sirusAuraLists[auras.type]]
	local visible = 0

	if show and (auras.sirusList ~= list or auras.sirusScale ~= aurasFrame.auraItemScale or auras.sirusStride ~= list.stride) then
		ConfigureSirusAuras(frame, auras, aurasFrame)
	end

	for index = 1, count do
		local item = sirusItems[index]
		sirusItems[index] = nil

		local aura = show and item and auraList and auraList[item.auraInstanceID]
		if aura and NP:SirusAuraAllowed(db, aura) then
			visible = visible + 1

			local button = auras[visible] or NP:Construct_AuraIcon(auras, visible)
			NP:StyleAura(button, visible, aura.icon, aura.applications or 0, aura.dispelName, aura.duration, aura.expirationTime, auras.type ~= "buffs", aura.spellId, aura.name)
		end
	end

	for i = visible + 1, #auras do
		auras[i].timeLeft = nil
		auras[i]:SetScript("OnUpdate", nil)
		auras[i]:Hide()
	end

	if show and #auras > auras.anchoredIcons then
		NP:Update_AurasPosition(auras, db, auras.sirusLayout)
		auras.anchoredIcons = #auras
	end
end

local function UpdateSirusLossOfControl(frame, aurasFrame)
	local auras = frame.LossOfControl
	local locFrame = aurasFrame.LossOfControlFrame
	local db = GetAuraDB(frame, auras.type)
	local aura = db and db.enable and frame.Health:IsShown() and aurasFrame.unitToken and locFrame:IsVisible() and aurasFrame:GetLossOfControlAura()

	locFrame.AuraItemFrame:Hide()

	if aura and aura.icon and NP:SirusAuraAllowed(db, aura) then
		local button = auras[1] or NP:Construct_AuraIcon(auras, 1)
		local size = NP:SirusPixel(locFrame:GetWidth() * (aurasFrame.auraItemScale or 1))

		auras:SetSize(size, size)
		auras:ClearAndSetPoint(GetSirusAuraAnchor(frame, auras.type))

		button:SetSize(size, size)
		button:ClearAndSetPoint("CENTER", auras, "CENTER")

		if auras.anchoredIcons == 0 then
			NP:StyleAuraButton(button, db)
			auras.anchoredIcons = 1
		end

		NP:StyleAura(button, 1, aura.icon, aura.applications or 0, aura.dispelName, aura.duration, aura.expirationTime, true, aura.spellId, aura.name)
	elseif auras[1] then
		auras[1].timeLeft = nil
		auras[1]:SetScript("OnUpdate", nil)
		auras[1]:Hide()
	end
end

local function MirrorSirusAuras(frame, aurasFrame, draw)
	UpdateSirusAuraList(frame, frame.Buffs, aurasFrame, draw)
	UpdateSirusAuraList(frame, frame.Debuffs, aurasFrame, draw)
	UpdateSirusAuraList(frame, frame.CrowdControl, aurasFrame, draw)
end

local function HideSirusAuraItems(...)
	for i = 1, select("#", ...) do
		select(i, ...):Hide()
	end
end

local function SirusAurasRefreshed(aurasFrame)
	local plate = aurasFrame:GetParent():GetParent()
	local frame = plate and plate.ElvUIFrame

	if not frame then
		HideSirusAuraItems(aurasFrame.BuffListFrame:GetChildren())
		HideSirusAuraItems(aurasFrame.DebuffListFrame:GetChildren())
		HideSirusAuraItems(aurasFrame.CrowdControlListFrame:GetChildren())
		return
	end

	local draw = frame.unit and frame.unit == aurasFrame.unitToken and frame.Health:IsShown()
	MirrorSirusAuras(frame, aurasFrame, draw)

	if draw then
		NP:StyleFilterUpdate(frame, "UNIT_AURA")
	end
end

local function SirusLossOfControlRefreshed(aurasFrame)
	local plate = aurasFrame:GetParent():GetParent()
	local frame = plate and plate.ElvUIFrame

	if frame and frame.unit and frame.unit == aurasFrame.unitToken then
		UpdateSirusLossOfControl(frame, aurasFrame)
	else
		aurasFrame.LossOfControlFrame.AuraItemFrame:Hide()
	end
end

local function SirusAnchorsUpdated(unitFrame)
	local plate = unitFrame:GetParent()
	local frame = plate and plate.ElvUIFrame
	if not (frame and frame.UnitType and frame.unit and frame.unit == unitFrame.unit and frame.Health:IsShown()) then return end

	for _, key in next, sirusContainers do
		local auras = frame[key]
		auras:ClearAndSetPoint(GetSirusAuraAnchor(frame, auras.type))
	end
end

function NP:HookSirusPlate(unitFrame)
	if unitFrame.__elvNPSirusHooked then return end
	unitFrame.__elvNPSirusHooked = true

	hooksecurefunc(unitFrame.AurasFrame, "RefreshAuras", SirusAurasRefreshed)
	hooksecurefunc(unitFrame.AurasFrame, "RefreshLossOfControl", SirusLossOfControlRefreshed)
	hooksecurefunc(unitFrame, "UpdateAnchors", SirusAnchorsUpdated)
end

function NP:UpdateSirusAuras(frame)
	local aurasFrame = frame.unit and GetSirusAurasFrame(frame)
	if not aurasFrame then return false end

	MirrorSirusAuras(frame, aurasFrame, frame.Health:IsShown())
	UpdateSirusLossOfControl(frame, aurasFrame)

	return true
end

function NP:SirusAuraAllowed(db, aura)
	local filters = db.filters
	if not filters then return true end

	local duration = aura.duration or 0
	local noDuration = duration == 0
	if not noDuration and ((filters.maxDuration > 0 and duration > filters.maxDuration) or (filters.minDuration > 0 and duration < filters.minDuration)) then
		return false
	end

	return filters.priority == "" or NP:CheckFilter(aura.name, aura.spellId, aura.isFromPlayerOrPlayerPet, true, noDuration, split(",", filters.priority)) ~= false
end

function NP:StyleAuraButton(button, db)
	if not db then return end

	button.count:FontTemplate(LSM:Fetch("font", db.countFont), db.countFontSize, db.countFontOutline)
	button.count:ClearAndSetPoint(db.countPosition, db.countXOffset, db.countYOffset)

	button.text:FontTemplate(LSM:Fetch("font", db.durationFont), db.durationFontSize, db.durationFontOutline)
	button.text:ClearAndSetPoint(db.durationPosition, db.durationXOffset, db.durationYOffset)

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

function NP:Update_AurasPosition(frame, db, sirus)
	local size = sirus and sirus.size or NP:Pixel(db.size)
	local spacing = sirus and sirus.spacing or NP:Pixel(db.spacing)
	local rowSpacing = sirus and sirus.rowSpacing or spacing
	local step, rowStep = size + spacing, size + rowSpacing
	local anchor = sirus and sirus.point or E.InversePoints[db.anchorPoint]
	local growthx = sirus and sirus.growthX or db.growthX
	local growthy = sirus and sirus.growthY or db.growthY
	local cols = sirus and sirus.perrow or db.perrow

	growthx = (growthx == "LEFT" and -1) or 1
	growthy = (growthy == "DOWN" and -1) or 1

	for i = frame.anchoredIcons + 1, #frame do
		local button = frame[i]
		if not button then break end

		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)

		button:SetSize(size, size)
		button:ClearAndSetPoint(anchor, frame, anchor, col * step * growthx, row * rowStep * growthy)

		NP:StyleAuraButton(button, db)
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
	if NP:UpdateSirusAuras(frame) then
		if frame.Health:IsShown() then
			self:StyleFilterUpdate(frame, "UNIT_AURA")
		end
		return
	end

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
	local db = GetAuraDB(parent:GetParent(), parent.type)

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
	local db = GetAuraDB(frame, auras.type)

	auras.anchoredIcons = 0

	if not db then return end

	local aurasFrame = GetSirusAurasFrame(frame)
	if aurasFrame then
		ConfigureSirusAuras(frame, auras, aurasFrame)
		return
	end

	local size, spacing = NP:Pixel(db.size), NP:Pixel(db.spacing)
	auras:SetWidth(NP:Pixel(db.perrow * size + ((db.perrow - 1) * spacing), true))
	auras:SetHeight(db.numrows * size + ((db.numrows - 1) * spacing))
	auras:ClearAllPoints()
	auras:SetPoint(positionValues[db.anchorPoint], db.attachTo == "BUFFS" and frame.Buffs or frame.Health, positionValues2[db.anchorPoint], NP:Pixel(db.xOffset), NP:Pixel(db.yOffset))
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