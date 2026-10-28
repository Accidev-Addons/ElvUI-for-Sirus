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

local DebuffColors = E.DebuffColors

local VISIBLE, HIDDEN = 1, 0

local playerSpells = {}

local playerFilters = {
	HELPFUL = "HELPFUL|PLAYER",
	HARMFUL = "HARMFUL|PLAYER"
}

local activeAuraTimers = {}
local auraTimerFrame = CreateFrame("Frame")
auraTimerFrame:Hide()

local function StopAuraTimer(button)
	if not activeAuraTimers[button] then return end
	activeAuraTimers[button] = nil
	if not next(activeAuraTimers) then auraTimerFrame:Hide() end
end

local function StartAuraTimer(button)
	activeAuraTimers[button] = true
	auraTimerFrame:Show()
end

function NP:UpdateTime(elapsed)
	local timeLeft = self.endTime - GetTime()
	self.timeLeft = timeLeft
	self:SetValue(timeLeft)

	if timeLeft < 0 then
		StopAuraTimer(self)
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

auraTimerFrame:SetScript("OnUpdate", function(_, elapsed)
	for button in next, activeAuraTimers do
		if button:IsVisible() then NP.UpdateTime(button, elapsed) end
	end
end)

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

			if not button.auraTimerPreview then StartAuraTimer(button) end
		end
	else
		button.timeLeft = nil
		button.endTime = nil
		button.text:SetText("")
		StopAuraTimer(button)
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

local function RenderAuraIcon(auras, position, index, texture, count, debuffType, duration, expiration, isDebuff, spellID, name, preview)
	local button = auras[position] or NP:Construct_AuraIcon(auras, position)
	button.auraTimerPreview = preview and true or nil
	NP:StyleAura(button, index, texture, count, debuffType, duration, expiration, isDebuff, spellID, name)
	if preview then
		NP.UpdateTime(button, 0)
		StopAuraTimer(button)
	end
end

local function HideAuraIcons(auras, visible)
	for i = visible + 1, #auras do
		local button = auras[i]
		button.timeLeft, button.endTime = nil, nil
		StopAuraTimer(button)
		button:Hide()
	end
end

local function FinishAuraUpdate(auras, visible, db)
	HideAuraIcons(auras, visible)
	if #auras > auras.anchoredIcons then
		NP:Update_AurasPosition(auras, db, auras.auraLayout)
		auras.anchoredIcons = #auras
	end
end

function NP:SetAura(frame, unit, index, filter, isDebuff, visible, spells)
	local name, _, texture, count, debuffType, duration, expiration, caster, spellID
	if unit then
		name, _, texture, count, debuffType, duration, expiration, caster, _, _, spellID = UnitAura(unit, index, filter)
	end
	if not name then return end

	local position = visible + 1
	local button = frame[position] or NP:Construct_AuraIcon(frame, position)
	if NP:AuraFilter(unit, button, name, texture, count, debuffType, duration, expiration, caster, spellID, spells) then
		RenderAuraIcon(frame, position, index, texture, count, debuffType, duration, expiration, isDebuff, spellID, name)
		return VISIBLE
	end
	return HIDDEN
end

local function GetAuraDB(frame, auraType)
	if auraType == "lossofcontrol" then auraType = "crowdcontrol" end
	local units = NP.db.units[frame.UnitType]
	if not units then return end

	local db = units[auraType]

	if not db then
		local defaults = P.nameplates.units[frame.UnitType]
		db = defaults and defaults[auraType]
	end

	return db or units.debuffs
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

local auraContainers = { "Buffs", "Debuffs", "CrowdControl", "LossOfControl" }

local sirusAnchorPoints = {
	BOTTOM = "TOP",
	BOTTOMLEFT = "TOPLEFT",
	BOTTOMRIGHT = "TOPRIGHT",
	CENTER = "CENTER",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	TOP = "BOTTOM",
	TOPLEFT = "BOTTOMLEFT",
	TOPRIGHT = "BOTTOMRIGHT"
}

local function AnchorSirusAuras(frame, auras)
	local db = GetAuraDB(frame, auras.type)
	local unitFrame = NP:GetSirusUnitFrame(frame:GetParent())
	local nativeAuras = unitFrame and unitFrame.AurasFrame
	local native = nativeAuras and nativeAuras[sirusListFrames[auras.type] or "LossOfControlFrame"]
	auras:ClearAllPoints()
	if db.useSirusPosition ~= false and native then
		local anchors = {
			[unitFrame.healthBar] = frame.Health,
			[unitFrame.name] = frame.Name,
			[unitFrame.LevelFrame] = frame.Level,
			[unitFrame.ClassificationFrame] = frame.Elite
		}
		for i = 1, native:GetNumPoints() do
			local point, relative, relativePoint, x, y = native:GetPoint(i)
			auras:SetPoint(point, anchors[relative] or relative, relativePoint, NP:SirusPixel(x or 0), NP:SirusPixel(y or 0))
		end
		return
	end

	local point = db.anchorPoint or "TOPLEFT"
	local anchor = db.attachTo == "BUFFS" and frame.Buffs
		or db.attachTo == "DEBUFFS" and frame.Debuffs
		or db.attachTo == "NAME" and frame.Name
		or db.attachTo == "LEVEL" and frame.Level
		or frame.Health
	if anchor == auras or (anchor == frame.Debuffs and auras == frame.Buffs) then anchor = frame.Health end
	auras:SetPoint(sirusAnchorPoints[point] or point, anchor, point, NP:SirusPixel(db.xOffset or 0), NP:SirusPixel(db.yOffset or 0))
end

local function ConfigureAuraLayout(frame, auras, aurasFrame, force)
	local db = GetAuraDB(frame, auras.type)
	if not db then return end

	local single = auras.type == "lossofcontrol"
	local native = aurasFrame and aurasFrame[single and "LossOfControlFrame" or sirusListFrames[auras.type]]
	local nativeSize = db.useSirusSize ~= false and native ~= nil
	local size, spacing, rowSpacing = db.size, db.spacing, db.spacing
	if nativeSize then
		local height = single and native:GetWidth() or _G.NamePlateConstants.AURA_ITEM_HEIGHT
		size = height * (aurasFrame.auraItemScale or 1)
		if not single then spacing, rowSpacing = native.childXPadding, native.childYPadding end
	end
	local perrow, numrows = single and 1 or db.perrow, single and 1 or db.numrows
	local layout = auras.auraLayout
	if not force and layout and layout.db == db and layout.native == native
		and layout.rawSize == size and layout.rawSpacing == spacing and layout.rawRowSpacing == rowSpacing
		and layout.nativeSize == nativeSize and layout.perfect == E.perfect
		and layout.uiScale == E.uiscale and layout.plateScale == NP.db.plateScale
		and layout.growthX == db.growthX and layout.growthY == db.growthY
		and layout.perrow == perrow and layout.numrows == numrows
		and layout.anchorPoint == db.anchorPoint and layout.attachTo == db.attachTo
		and layout.xOffset == db.xOffset and layout.yOffset == db.yOffset
		and layout.useSirusPosition == db.useSirusPosition then
		return layout
	end

	layout = layout or {}
	layout.rawSize, layout.rawSpacing, layout.rawRowSpacing = size, spacing, rowSpacing
	layout.nativeSize, layout.perfect, layout.uiScale, layout.plateScale = nativeSize, E.perfect, E.uiscale, NP.db.plateScale
	if nativeSize then
		size, spacing, rowSpacing = NP:SirusPixel(size), NP:SirusPixel(spacing), NP:SirusPixel(rowSpacing)
	else
		size, spacing, rowSpacing = NP:Pixel(size), NP:Pixel(spacing), NP:Pixel(rowSpacing)
	end
	layout.point = single and "CENTER" or ((db.growthY == "UP" and "BOTTOM" or "TOP") .. (db.growthX == "RIGHT" and "LEFT" or "RIGHT"))
	layout.growthX, layout.growthY = db.growthX, db.growthY
	layout.size, layout.spacing, layout.rowSpacing = size, spacing, rowSpacing
	layout.perrow, layout.numrows = perrow, numrows
	layout.db, layout.native = db, native
	layout.anchorPoint, layout.attachTo = db.anchorPoint, db.attachTo
	layout.xOffset, layout.yOffset = db.xOffset, db.yOffset
	layout.useSirusPosition = db.useSirusPosition
	auras.auraLayout = layout
	auras.anchoredIcons = 0
	auras:SetSize(layout.perrow * size + (layout.perrow - 1) * spacing, layout.numrows * size + (layout.numrows - 1) * rowSpacing)
	AnchorSirusAuras(frame, auras)
	return layout
end

local function HideSirusAuraItems(...)
	for i = 1, select("#", ...) do
		select(i, ...):Hide()
	end
end

local auraFilters = {
	buffs = "HELPFUL",
	debuffs = "HARMFUL",
	crowdcontrol = "HARMFUL"
}

local function IsSirusCrowdControl(aura)
	return NP:CheckFilter(aura.name, aura.spellId, aura.isFromPlayerOrPlayerPet, true, (aura.duration or 0) == 0, aura.canDispell, "CCDebuffs") == true
end

local PREVIEW_STACKS = 5

local function GetPreviewAura(auraType)
	if auraType == "lossofcontrol" then return end
	local control = auraType == "crowdcontrol"
	local spellID = control and 118 or (auraType == "buffs" and 21562 or 589)
	local name, _, icon = GetSpellInfo(spellID)
	return {
		name = name, icon = icon or [[Interface\Icons\INV_Misc_QuestionMark]],
		applications = PREVIEW_STACKS, dispelName = "Magic", duration = 30,
		expirationTime = GetTime() + 20, spellId = spellID
	}
end

local function GetUnitAura(unit, index, filter, aura)
	local name, _, icon, count, debuffType, duration, expiration, caster, isStealable, _, spellID = UnitAura(unit, index, filter)
	if not name then return end
	aura.name, aura.icon, aura.applications, aura.dispelName = name, icon, count, debuffType
	aura.duration, aura.expirationTime, aura.spellId = duration, expiration, spellID
	aura.isFromPlayerOrPlayerPet = (caster == "player" or caster == "pet")
	aura.isStealable = isStealable
	aura.canDispell = (isStealable and true) or (debuffType and E:IsDispellableByMe(debuffType)) or false
	return aura
end

local function PrepareAuraList(frame, auras, aurasFrame, draw)
	local db = GetAuraDB(frame, auras.type)
	if not db then return end
	local single = auras.type == "lossofcontrol"
	local native = aurasFrame and aurasFrame[single and "LossOfControlFrame" or sirusListFrames[auras.type]]
	local preview = frame.testUnitType and GetPreviewAura(auras.type)
	local show = draw and db.enable
	if frame.testUnitType then
		show = show and preview
	else
		show = show and frame.unit and native and native:IsVisible() and (not single or aurasFrame.unitToken)
	end

	if native then
		if single then native.AuraItemFrame:Hide() else HideSirusAuraItems(native:GetChildren()) end
	end
	if show then ConfigureAuraLayout(frame, auras, aurasFrame) end
	return db, show and (single and 1 or db.perrow * db.numrows) or 0, preview
end

local function UpdateAuraList(frame, auras, aurasFrame, draw)
	local db, limit, preview = PrepareAuraList(frame, auras, aurasFrame, draw)
	if not db then return end
	local single = auras.type == "lossofcontrol"
	local data = limit > 0 and not preview and not single and {}
	local visible, index = 0, 1
	while visible < limit do
		local aura
		if preview then
			aura = preview
		elseif single then
			aura = aurasFrame:GetLossOfControlAura()
		else
			aura = GetUnitAura(frame.unit, index, auraFilters[auras.type], data)
		end
		if not aura then break end
		if aura.icon and (preview or NP:SirusAuraAllowed(db, aura)) then
			visible = visible + 1
			RenderAuraIcon(auras, visible, visible, aura.icon, aura.applications or 0, aura.dispelName, aura.duration, aura.expirationTime, auras.type ~= "buffs", aura.spellId, aura.name, preview)
		end
		if single then break end
		index = index + 1
	end
	FinishAuraUpdate(auras, visible, db)
end

local function UpdateHarmfulAuras(frame, aurasFrame, draw)
	local debuffs, control = frame.Debuffs, frame.CrowdControl
	local debuffDB, debuffLimit = PrepareAuraList(frame, debuffs, aurasFrame, draw)
	local controlDB, controlLimit = PrepareAuraList(frame, control, aurasFrame, draw)
	debuffLimit, controlLimit = debuffLimit or 0, controlLimit or 0
	local debuffCount, controlCount, index = 0, 0, 1
	local data = (debuffLimit > 0 or controlLimit > 0) and {}
	while debuffCount < debuffLimit or controlCount < controlLimit do
		local aura = GetUnitAura(frame.unit, index, "HARMFUL", data)
		if not aura then break end
		local isControl = IsSirusCrowdControl(aura)
		local auras, db = isControl and control or debuffs, isControl and controlDB or debuffDB
		local visible, limit = isControl and controlCount or debuffCount, isControl and controlLimit or debuffLimit
		if visible < limit and aura.icon and NP:SirusAuraAllowed(db, aura) then
			visible = visible + 1
			RenderAuraIcon(auras, visible, visible, aura.icon, aura.applications or 0, aura.dispelName, aura.duration, aura.expirationTime, true, aura.spellId, aura.name)
			if isControl then controlCount = visible else debuffCount = visible end
		end
		index = index + 1
	end
	if debuffDB then FinishAuraUpdate(debuffs, debuffCount, debuffDB) end
	if controlDB then FinishAuraUpdate(control, controlCount, controlDB) end
end

local function MirrorSirusAuras(frame, aurasFrame, draw)
	UpdateAuraList(frame, frame.Buffs, aurasFrame, draw)
	UpdateHarmfulAuras(frame, aurasFrame, draw)
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
		UpdateAuraList(frame, frame.LossOfControl, aurasFrame, frame.Health:IsShown())
	else
		aurasFrame.LossOfControlFrame.AuraItemFrame:Hide()
	end
end

local function SirusAnchorsUpdated(unitFrame)
	local plate = unitFrame:GetParent()
	local frame = plate and plate.ElvUIFrame
	if not (frame and frame.UnitType and frame.unit and frame.unit == unitFrame.unit and frame.Health:IsShown()) then return end

	for _, key in next, auraContainers do
		local auras = frame[key]
		AnchorSirusAuras(frame, auras)
	end
end

function NP:RefreshSirusAuraAnchors()
	if not NP:IsSirusNameplates() then return end

	for plate in pairs(NP.CreatedPlates) do
		local frame = plate.ElvUIFrame
		if frame and frame.UnitType and frame.Health:IsShown() then
			local unitFrame = NP:GetSirusUnitFrame(plate)
			if unitFrame and unitFrame.AurasFrame then
				for _, key in next, auraContainers do
					local auras = frame[key]
					if auras then
						AnchorSirusAuras(frame, auras)
					end
				end
			end
		end
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
	UpdateAuraList(frame, frame.LossOfControl, aurasFrame, frame.Health:IsShown())

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

	return filters.priority == "" or NP:CheckFilter(aura.name, aura.spellId, aura.isFromPlayerOrPlayerPet, true, noDuration, aura.canDispell, split(",", filters.priority)) == true
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

function NP:Update_AurasPosition(frame, db, layout)
	layout = layout or frame.auraLayout
	local size = layout and layout.size or NP:Pixel(db.size)
	local spacing = layout and layout.spacing or NP:Pixel(db.spacing)
	local rowSpacing = layout and layout.rowSpacing or spacing
	local step, rowStep = size + spacing, size + rowSpacing
	local anchor = layout and layout.point or E.InversePoints[db.anchorPoint]
	local growthx = layout and layout.growthX or db.growthX
	local growthy = layout and layout.growthY or db.growthY
	local cols = layout and layout.perrow or db.perrow

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

	return visible
end

function NP:UpdateElement_Auras(frame)
	if frame.testUnitType then
		for _, key in ipairs(auraContainers) do
			UpdateAuraList(frame, frame[key], nil, frame.Health:IsShown())
		end
		self:StyleFilterUpdate(frame, "UNIT_AURA")
		return
	end

	if NP:UpdateSirusAuras(frame) then
		if frame.Health:IsShown() then
			self:StyleFilterUpdate(frame, "UNIT_AURA")
		end
		return
	end

	if not frame.Health:IsShown() then return end

	local unit = frame.unit
	if not unit then
		return
	end

	for _, key in ipairs({ "Buffs", "Debuffs" }) do
		local auras = frame[key]
		local db = GetAuraDB(frame, auras.type)
		local visible = db.enable and NP:UpdateElement_AuraIcons(auras, unit, auraFilters[auras.type], db.perrow * db.numrows, key == "Debuffs") or 0
		FinishAuraUpdate(auras, visible, db)
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
	button:HookScript("OnHide", StopAuraTimer)
	button:HookScript("OnShow", function(self)
		if self.endTime and not self.auraTimerPreview then StartAuraTimer(self) end
	end)

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
	if not db then return end
	local layout = ConfigureAuraLayout(frame, auras, GetSirusAurasFrame(frame), true)
	HideAuraIcons(auras, layout.perrow * layout.numrows)
	if #auras > 0 then
		NP:Update_AurasPosition(auras, db, layout)
		auras.anchoredIcons = #auras
	end
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

function NP:CheckFilter(name, spellID, isPlayer, allowDuration, noDuration, canDispell, ...)
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
			elseif filterName == "Dispellable" and canDispell and allowDuration then
				return true
			elseif filterName == "notDispellable" and (not canDispell) and allowDuration then
				return true
			elseif filterName == "blockNoDuration" and noDuration then
				return false
			elseif filterName == "blockNonPersonal" and (not isPlayer) then
				return false
			elseif filterName == "blockDispellable" and canDispell then
				return false
			elseif filterName == "blockNotDispellable" and (not canDispell) then
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
	local canDispell = (debuffType and E:IsDispellableByMe(debuffType)) or false

	if priority ~= "" then
		filterCheck = NP:CheckFilter(name, spellID, isPlayer, allowDuration, noDuration, canDispell, split(",", priority))
	else
		filterCheck = allowDuration and true -- Allow all auras to be shown when the filter list is empty, while obeying duration sliders
	end

	return filterCheck
end