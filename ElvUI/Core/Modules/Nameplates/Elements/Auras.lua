local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

--Lua functions
local select, wipe = select, wipe
local tinsert = table.insert
local floor, ceil, min = math.floor, math.ceil, math.min
local sort = table.sort
local split = string.split
--WoW API / Variables
local CreateFrame = CreateFrame
local GetCVar = GetCVar
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitAura = UnitAura

local AURA_ITEM_HEIGHT = 25 -- NamePlateConstants.AURA_ITEM_HEIGHT on the sirus side

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
		local color = (debuffType and DebuffTypeColor[debuffType]) or DebuffTypeColor.none
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

local function GetSirusLossOfControlFrame(frame)
	local aurasFrame = GetSirusAurasFrame(frame)

	return aurasFrame and aurasFrame.LossOfControlFrame
end

local function GetSirusAuraList(frame, auraType)
	local auras = GetSirusAurasFrame(frame)
	if not auras then return end

	if auraType == "buffs" or auraType == "Buffs" then
		return auras.BuffListFrame
	elseif auraType == "crowdcontrol" or auraType == "CrowdControl" then
		return auras.CrowdControlListFrame
	end

	return auras.DebuffListFrame
end

function NP:GetSirusAuraItemScale()
	local scale = tonumber(GetCVar("nameplateAuraScale")) or 1
	local driver = _G.NamePlateDriverFrame

	if driver and driver.GetNamePlateScale then
		local namePlateScale = driver:GetNamePlateScale(tonumber(GetCVar("nameplateStyle")) or 0)
		if namePlateScale then
			scale = scale * (namePlateScale.aura or 1)
		end
	end

	return scale
end

function NP:GetSirusAuraLayout(frame, auraType)
	local list = GetSirusAuraList(frame, auraType)
	if not list then return end

	local stride = tonumber(list.stride) or 10
	local limit = tonumber(list.maxAuraItemsDisplayed) or (stride * 2)
	local perrow = min(stride, limit)
	local goingRight, goingUp = list.layoutFramesGoingRight ~= false, list.layoutFramesGoingUp ~= false

	return {
		list = list,
		point = (goingUp and "BOTTOM" or "TOP") .. (goingRight and "LEFT" or "RIGHT"),
		growthX = goingRight and "RIGHT" or "LEFT",
		growthY = goingUp and "UP" or "DOWN",
		size = NP:SirusPixel(AURA_ITEM_HEIGHT * NP:GetSirusAuraItemScale()),
		spacing = NP:SirusPixel(tonumber(list.childXPadding) or 0),
		rowSpacing = NP:SirusPixel(tonumber(list.childYPadding) or 0),
		perrow = perrow,
		numrows = ceil(limit / perrow),
		limit = limit
	}
end

function NP:CheckSirusAuraLayout(frame, auraType)
	local auras = frame[auraType]

	if not GetSirusAuraList(frame, auraType) then
		if auras.sirusLayout then
			NP:Configure_Auras(frame, auraType)
		end

		return nil
	end

	local layout, old = NP:GetSirusAuraLayout(frame, auraType), auras.sirusLayout

	if not old or old.list ~= layout.list or old.point ~= layout.point or old.size ~= layout.size
	or old.perrow ~= layout.perrow or old.numrows ~= layout.numrows or old.spacing ~= layout.spacing
	or old.rowSpacing ~= layout.rowSpacing then
		NP:Configure_Auras(frame, auraType)
	end

	return auras.sirusLayout
end

local function GetSirusAuraAnchor(frame, auraType)
	local health, name, level = frame.Health, frame.Name, frame.Level
	if not health then return end

	local constants, setup = _G.NamePlateConstants, _G.NamePlateSetupOptions
	local styles = constants and constants.NAME_ANCHOR_STYLES
	local padding = NP:SirusPixel(tonumber(GetCVar(constants and constants.DEBUFF_PADDING_CVAR or "nameplateDebuffPadding")) or 0)

	if auraType == "Debuffs" then
		local nameAbove = name and type(name.IsShown) == "function" and name:IsShown()
			and ((styles and setup and setup.unitNameAnchorStyle ~= styles.InsideHealthBar) or ((name:GetTop() or 0) > (health:GetTop() or 0)))

		return "BOTTOMLEFT", nameAbove and name or health, "TOPLEFT", 0, padding
	end

	if auraType == "Buffs" then
		return "RIGHT", health, "LEFT", -NP:SirusPixel(5), 0
	end

	local target = health

	if level and type(level.IsShown) == "function" and level:IsShown() and (level:GetLeft() or 0) > (health:GetRight() or 0) then
		target = level
	end

	return "LEFT", target, "RIGHT", NP:SirusPixel(5), 0
end

local function ResolveSirusAura(unit, auraInstanceID, stored)
	local unitAuras = _G.C_UnitAuras
	if unit and auraInstanceID and unitAuras and unitAuras.GetAuraDataByAuraInstanceID then
		local aura = unitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
		if aura then
			return aura
		end
	end

	return stored
end

local function GetItemAura(item)
	local count = item.CountFrame and item.CountFrame.Count and tonumber(item.CountFrame.Count:GetText())

	return {
		icon = item.Icon and item.Icon:GetTexture(),
		applications = count or 1,
		spellId = item.spellID
	}
end

local function GetSirusAuraItems(list)
	local items = {}

	if list and list.IsShown and list:IsShown() then
		for _, item in next, { list:GetChildren() } do
			if item.layoutIndex then
				items[#items + 1] = item
			end
		end

		sort(items, function(a, b) return a.layoutIndex < b.layoutIndex end)
	end

	return items
end

local function HideSirusAuraItem(item)
	item.includeAsLayoutChildWhenHidden = true
	item:Hide()
end

local function AuraTypeName(auraType)
	if auraType == "buffs" then return "Buffs" end
	if auraType == "crowdcontrol" then return "CrowdControl" end

	return "Debuffs"
end

function NP:UpdateElement_SirusAuras(auras)
	local frame = auras:GetParent()
	local list = GetSirusAuraList(frame, auras.type)
	if not list or not frame.UnitType then return end

	local db = GetAuraDB(frame, auras.type)
	local unit = frame.unit
	local items = GetSirusAuraItems(list)
	local visible = 0

	local sirus = NP:CheckSirusAuraLayout(frame, AuraTypeName(auras.type))

	for index = 1, #items do
		local item = items[index]
		local aura = ResolveSirusAura(unit, item.auraInstanceID, GetItemAura(item))

		if aura and aura.icon then
			visible = visible + 1

			local button = auras[visible] or NP:Construct_AuraIcon(auras, visible)
			NP:StyleAura(button, visible, aura.icon, tonumber(aura.applications) or 1, aura.dispelName, aura.duration, aura.expirationTime, auras.type ~= "buffs", aura.spellId, aura.name)
		end

		HideSirusAuraItem(item)
	end

	for i = visible + 1, #auras do
		auras[i].timeLeft = nil
		auras[i]:SetScript("OnUpdate", nil)
		auras[i]:Hide()
	end

	auras.anchoredIcons = 0
	if db and sirus then
		NP:Update_AurasPosition(auras, db, sirus)
	end

	auras.anchoredIcons = visible
end

function NP:UpdateElement_SirusLossOfControl(auras)
	local frame = auras:GetParent()
	local locFrame = GetSirusLossOfControlFrame(frame)
	local item = locFrame and locFrame.AuraItemFrame
	if not (locFrame and item and frame.UnitType) then return end

	local db = GetAuraDB(frame, auras.type)
	local unit = frame.unit
	local aura

	if locFrame:IsShown() and item:IsShown() then
		aura = ResolveSirusAura(unit, item.auraInstanceID, GetItemAura(item))
	end

	local size = NP:SirusPixel((tonumber(locFrame:GetWidth()) or AURA_ITEM_HEIGHT) * NP:GetSirusAuraItemScale())
	auras:SetSize(size, size)

	local point, relativeTo, relativePoint, x, y = GetSirusAuraAnchor(frame, "CrowdControl")

	if point then
		auras:ClearAndSetPoint(point, relativeTo, relativePoint, x, y)
	else
		auras:ClearAllPoints()
		auras:SetPoint("CENTER", locFrame, "CENTER")
	end

	local button = auras[1] or NP:Construct_AuraIcon(auras, 1)

	if aura and aura.icon then
		NP:StyleAura(button, 1, aura.icon, tonumber(aura.applications) or 1, aura.dispelName, aura.duration, aura.expirationTime, true, aura.spellId, aura.name)

		auras.anchoredIcons = 0
		if db then
			NP:Update_AurasPosition(auras, db, { point = "CENTER", growthX = "RIGHT", growthY = "DOWN", size = size, spacing = 0, rowSpacing = 0, perrow = 1 })
		else
			button:SetSize(size, size)
			button:ClearAndSetPoint("CENTER", auras, "CENTER")
		end
		auras.anchoredIcons = 1

		item:Hide()
	else
		button.timeLeft = nil
		button:SetScript("OnUpdate", nil)
		button:Hide()

		auras.anchoredIcons = 0
	end
end

function NP:UpdateSirusAuras(frame)
	if not NP:IsSirusNameplates() or not frame.UnitType then return false end

	local aurasFrame = GetSirusAurasFrame(frame)
	if not aurasFrame then return false end

	if aurasFrame.isActive == false and not aurasFrame.explicitAuraList then
		aurasFrame:SetActive(true)

		if aurasFrame.unitToken and type(aurasFrame.RefreshAuras) == "function" then
			aurasFrame:RefreshAuras()
		end
	end

	NP:HookSirusAuraRefresh(aurasFrame)

	NP:Configure_Auras(frame, "Buffs")
	NP:Configure_Auras(frame, "Debuffs")

	NP:UpdateElement_SirusAuras(frame.Buffs)
	NP:UpdateElement_SirusAuras(frame.Debuffs)

	if frame.CrowdControl then
		NP:Configure_Auras(frame, "CrowdControl")
		NP:UpdateElement_SirusAuras(frame.CrowdControl)
	end

	if type(frame.LossOfControl) == "table" then
		NP:UpdateElement_SirusLossOfControl(frame.LossOfControl)
	end

	return true
end

function NP:HookSirusAuraRefresh(aurasFrame)
	if not (aurasFrame and NP:IsSirusNameplates()) or aurasFrame.__elvNPAuraHook then return end
	if type(aurasFrame.RefreshList) ~= "function" then return end

	aurasFrame.__elvNPAuraHook = true

	hooksecurefunc(aurasFrame, "RefreshList", function(_, listFrame)
		local auras = listFrame and listFrame.__elvNPAuras
		if auras and auras.sirusList == listFrame and auras.sirusLayout then
			NP:UpdateElement_SirusAuras(auras)
		end
	end)

	local function UpdateLossOfControl()
		local unitFrame = aurasFrame:GetParent()
		local plate = unitFrame and unitFrame:GetParent()
		local elvUI = plate and plate.ElvUIFrame

		if elvUI and elvUI.LossOfControl then
			NP:UpdateElement_SirusLossOfControl(elvUI.LossOfControl)
		end
	end

	if type(aurasFrame.RefreshLossOfControl) == "function" then
		hooksecurefunc(aurasFrame, "RefreshLossOfControl", UpdateLossOfControl)
	end
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
	if not frame.Health:IsShown() then return end

	local unit = frame.unit
	if not unit and not frame.Buffs.forceShow and not frame.Debuffs.forceShow then
		return
	end

	if NP:UpdateSirusAuras(frame) then
		self:StyleFilterUpdate(frame, "UNIT_AURA")
		return
	end

	local db = NP.db.units[frame.UnitType].buffs
	if db.enable then
		local buffs = frame.Buffs
		local sirus = NP:CheckSirusAuraLayout(frame, "Buffs")
		NP:UpdateElement_AuraIcons(buffs, unit, "HELPFUL", sirus and sirus.limit or (db.perrow * db.numrows))

		if #buffs > buffs.anchoredIcons then
			self:Update_AurasPosition(buffs, db, sirus)

			buffs.anchoredIcons = #buffs
		end
	end

	db = NP.db.units[frame.UnitType].debuffs
	if db.enable then
		local debuffs = frame.Debuffs
		local sirus = NP:CheckSirusAuraLayout(frame, "Debuffs")
		NP:UpdateElement_AuraIcons(debuffs, unit, "HARMFUL", sirus and sirus.limit or (db.perrow * db.numrows), true)

		if #debuffs > debuffs.anchoredIcons then
			self:Update_AurasPosition(debuffs, db, sirus)

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
	local sirus = NP:GetSirusAuraLayout(frame, auras.type)

	auras.sirusLayout = sirus
	auras.anchoredIcons = 0

	if not db then return end

	local perrow, numrows = db.perrow, db.numrows
	local size, spacing = NP:Pixel(db.size), NP:Pixel(db.spacing)
	local rowSpacing = spacing

	if sirus then
		perrow, numrows = sirus.perrow, sirus.numrows
		size, spacing, rowSpacing = sirus.size, sirus.spacing, sirus.rowSpacing

		auras:SetWidth(perrow * size + ((perrow - 1) * spacing))
	else
		auras:SetWidth(NP:Pixel(perrow * size + ((perrow - 1) * spacing), true))
	end

	auras:SetHeight(numrows * size + ((numrows - 1) * rowSpacing))
	auras:ClearAllPoints()

	if sirus then
		local point, relativeTo, relativePoint, x, y = GetSirusAuraAnchor(frame, auraType)

		if point then
			auras:ClearAndSetPoint(point, relativeTo, relativePoint, x, y)
		else
			auras:SetPoint(sirus.point, sirus.list, sirus.point)
		end

		sirus.list.__elvNPAuras = auras
		auras.sirusList = sirus.list

		NP:HookSirusAuraAnchors(frame)
	else
		auras:SetPoint(positionValues[db.anchorPoint], db.attachTo == "BUFFS" and frame.Buffs or frame.Health, positionValues2[db.anchorPoint], NP:Pixel(db.xOffset), NP:Pixel(db.yOffset))
	end
end

function NP:HookSirusAuraAnchors(frame)
	local unitFrame = NP:GetSirusUnitFrame(frame:GetParent())
	if not unitFrame or unitFrame.__elvNPSirusHooked then return end
	if type(unitFrame.UpdateAnchors) ~= "function" then return end

	unitFrame.__elvNPSirusHooked = true

	hooksecurefunc(unitFrame, "UpdateAnchors", function()
		NP:Configure_Auras(frame, "Buffs")
		NP:Configure_Auras(frame, "Debuffs")
	end)
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