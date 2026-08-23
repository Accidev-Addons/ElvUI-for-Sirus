local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")

--Lua functions
local _G = _G
local type = type
local tonumber = tonumber
local select, unpack, pairs, next = select, unpack, pairs, next
local random, abs = math.random, math.abs
local format, gsub, match = string.format, string.gsub, string.match
local twipe = table.wipe
--WoW API / Variables
local CompactUnitFrame_UnregisterEvents = CompactUnitFrame_UnregisterEvents
local CreateFrame = CreateFrame
local GetBattlefieldScore = GetBattlefieldScore
local GetNumBattlefieldScores = GetNumBattlefieldScores
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local RequestBattlefieldScoreData = RequestBattlefieldScoreData
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsFriend = UnitIsFriend
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitLevel = UnitLevel
local UnitReaction = UnitReaction
local UnitName = UnitName
local UnitThreatSituation = UnitThreatSituation
local GetRaidTargetIndex = GetRaidTargetIndex
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local C_NamePlate_GetNamePlates = C_NamePlate.GetNamePlates
local C_NamePlate_SetNamePlateEnemySize = C_NamePlate.SetNamePlateEnemySize
local C_NamePlate_SetNamePlateFriendlySize = C_NamePlate.SetNamePlateFriendlySize

local hasTarget
local FSPAT = "%s*"..(gsub(gsub(_G.FOREIGN_SERVER_LABEL, "^%s", ""), "[%*()]", "%%%1")).."$"

local RaidIconIndex = {
	[1] = "STAR", [2] = "CIRCLE", [3] = "DIAMOND", [4] = "TRIANGLE",
	[5] = "MOON", [6] = "SQUARE", [7] = "CROSS", [8] = "SKULL"
}

NP.CreatedPlates = {}
NP.VisiblePlates = {}
NP.Healers = {}

NP.NameByUnit = {}

NP.ResizeQueue = {}

NP.Totems = {}
NP.UniqueUnits = {}

function NP:CheckBGHealers()
	RequestBattlefieldScoreData()

	local name, _, classToken, damageDone, healingDone
	for i = 1, GetNumBattlefieldScores() do
		name, _, _, _, _, _, _, _, _, classToken, damageDone, healingDone = GetBattlefieldScore(i)
		if name and classToken and E.HealingClasses[classToken] then
			name = match(name, "([^%-]+).*")
			if name and healingDone > (damageDone * 2) then
				NP.Healers[name] = true
			elseif name and NP.Healers[name] then
				NP.Healers[name] = nil
			end
		end
	end

	NP:ForEachVisiblePlate("Update_HealerIcon")
end

function NP:SetFrameScale(frame, scale, noPlayAnimation)
	if frame.currentScale ~= scale then
		NP:Configure_HealthBarScale(frame, scale, noPlayAnimation)
		NP:Configure_CastBarScale(frame, scale, noPlayAnimation)
		NP:Configure_CPointsScale(frame, scale, noPlayAnimation)
		frame.currentScale = scale
	end
end

function NP:GetPlateFrameLevel(frame)
	local plateLevel
	if frame.plateID then
		plateLevel = 10 + frame.plateID*NP.levelStep
	end
	return plateLevel
end

function NP:SetPlateFrameLevel(frame, level, isTarget)
	if frame and level then
		if isTarget then
			level = 890 --10 higher than the max calculated level of 880
		elseif frame.FrameLevelChanged then
			--calculate Style Filter FrameLevelChanged leveling
			--level method: (10*(40*2)) max 800 + max 80 (40*2) = max 880
			--highest possible should be level 880 and we add 1 to all so 881
			local leveledCount = NP.CollectedFrameLevelCount or 1
			level = (frame.FrameLevelChanged*(40*NP.levelStep)) + (leveledCount*NP.levelStep)
		end

		frame:SetFrameLevel(level+1)
		frame.Shadow:OffsetFrameLevel(-1, frame)
		frame.Buffs:SetFrameLevel(level+1)
		frame.Debuffs:SetFrameLevel(level+1)
		if frame.RaidIcon then
			frame.RaidIcon:GetParent():SetFrameLevel(level+2)
		end
	end
end

function NP:ResetNameplateFrameLevel(frame)
	local isTarget = frame.isTarget --frame.isTarget is not the same here so keep this.
	local plateLevel = NP:GetPlateFrameLevel(frame)
	if plateLevel then
		if frame.FrameLevelChanged then --keep how many plates we change, this is reset to 1 post-ResetNameplateFrameLevel
			NP.CollectedFrameLevelCount = (NP.CollectedFrameLevelCount and NP.CollectedFrameLevelCount + 1) or 1
		end
		NP:SetPlateFrameLevel(frame, plateLevel, isTarget)
	end
end

function NP:StyleFrame(parent, noBackdrop, point)
	point = point or parent
	local noscalemult = E:PixelSize(1, parent)

	if point.bordertop then return end

	if not noBackdrop then
		point.backdrop = parent:CreateTexture(nil, "BACKGROUND")
		point.backdrop:SetAllPoints(point)
		point.backdrop:SetTexture(unpack(E.media.backdropfadecolor))
	end

	if E.PixelMode then
		point.bordertop = parent:CreateTexture()
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E.media.bordercolor))

		point.borderbottom = parent:CreateTexture()
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E.media.bordercolor))

		point.borderleft = parent:CreateTexture()
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E.media.bordercolor))

		point.borderright = parent:CreateTexture()
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E.media.bordercolor))
	else
		point.bordertop = parent:CreateTexture(nil, "OVERLAY")
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult*2)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult*2)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E.media.bordercolor))

		point.bordertop.backdrop = parent:CreateTexture()
		point.bordertop.backdrop:SetPoint("TOPLEFT", point.bordertop, "TOPLEFT", noscalemult, noscalemult)
		point.bordertop.backdrop:SetPoint("TOPRIGHT", point.bordertop, "TOPRIGHT", -noscalemult, noscalemult)
		point.bordertop.backdrop:SetHeight(noscalemult * 3)
		point.bordertop.backdrop:SetTexture(0, 0, 0)

		point.borderbottom = parent:CreateTexture(nil, "OVERLAY")
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult*2)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult*2)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E.media.bordercolor))

		point.borderbottom.backdrop = parent:CreateTexture()
		point.borderbottom.backdrop:SetPoint("BOTTOMLEFT", point.borderbottom, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderbottom.backdrop:SetPoint("BOTTOMRIGHT", point.borderbottom, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderbottom.backdrop:SetHeight(noscalemult * 3)
		point.borderbottom.backdrop:SetTexture(0, 0, 0)

		point.borderleft = parent:CreateTexture(nil, "OVERLAY")
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult*2, -noscalemult*2)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E.media.bordercolor))

		point.borderleft.backdrop = parent:CreateTexture()
		point.borderleft.backdrop:SetPoint("TOPLEFT", point.borderleft, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft.backdrop:SetPoint("BOTTOMLEFT", point.borderleft, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderleft.backdrop:SetWidth(noscalemult * 3)
		point.borderleft.backdrop:SetTexture(0, 0, 0)

		point.borderright = parent:CreateTexture(nil, "OVERLAY")
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult*2, -noscalemult*2)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E.media.bordercolor))

		point.borderright.backdrop = parent:CreateTexture()
		point.borderright.backdrop:SetPoint("TOPRIGHT", point.borderright, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright.backdrop:SetPoint("BOTTOMRIGHT", point.borderright, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderright.backdrop:SetWidth(noscalemult * 3)
		point.borderright.backdrop:SetTexture(0, 0, 0)
	end
end

function NP:StyleFrameColor(frame, r, g, b)
	frame.bordertop:SetTexture(r, g, b)
	frame.borderbottom:SetTexture(r, g, b)
	frame.borderleft:SetTexture(r, g, b)
	frame.borderright:SetTexture(r, g, b)
end

function NP:GetHealth(frame)
	if frame.testHealth then
		return frame.testHealth, frame.testMaxHealth or 1
	end

	local unit = frame.unit
	if not unit then return 0, 1 end

	return UnitHealth(unit) or 0, UnitHealthMax(unit) or 1
end

function NP:UnitClass(frame)
	if frame.testUnitType then
		return frame.testClass
	end

	local unit = frame.unit
	if not unit then return end

	if UnitIsPlayer(unit) then
		return select(2, UnitClass(unit))
	end
end

function NP:UnitDetailedThreatSituation(frame)
	if not frame.unit then return end

	return UnitThreatSituation("player", frame.unit)
end

function NP:UnitLevel(frame)
	if frame.testUnitType then
		return E.mylevel, 1, 1, 1
	end

	local unit = frame.unit
	if not unit then return "??", 0.9, 0, 0 end

	local level = UnitLevel(unit)
	local classification = UnitClassification(unit)
	if not level or level < 0 or classification == "worldboss" then
		return "??", 0.9, 0, 0
	end

	local color = GetQuestDifficultyColor(level)

	return level, color.r, color.g, color.b
end

function NP:GetUnitInfo(frame)
	if frame.testUnitType then
		return frame.testUnitType == "ENEMY_NPC" and 2 or 5, frame.testUnitType
	end

	local unit = frame.unit
	if not unit then return 3, "ENEMY_PLAYER" end

	local reaction = UnitReaction("player", unit) or 4

	return reaction, NP:GetUnitTypeFromUnit(unit)
end

function NP:GetUnitTypeFromUnit(unit)
	local reaction = UnitReaction("player", unit)
	local isPlayer = UnitIsPlayer(unit)

	if isPlayer and UnitIsFriend("player", unit) and reaction and reaction >= 5 then
		return "FRIENDLY_PLAYER"
	elseif not isPlayer and ((reaction and reaction >= 5) or UnitFactionGroup(unit) == "Neutral") then
		return "FRIENDLY_NPC"
	elseif not isPlayer and (reaction and reaction <= 4) then
		return "ENEMY_NPC"
	else
		return "ENEMY_PLAYER"
	end
end

function NP:OnShow(isConfig, dontHideHighlight, unitToken)
	local frame = self.ElvUIFrame
	if not frame then return end

	NP:DisableBlizzard(self)

	local unit = unitToken or self.namePlateUnitToken
	frame.unit = unit
	frame.guid = unit and UnitGUID(unit)

	NP.VisiblePlates[frame] = 1

	NP:CheckRaidIcon(frame)

	if frame.testUnitType then
		frame.unit, frame.guid = nil, nil
	end

	frame.UnitName = frame.testUnitType and (L[frame.testUnitType] or frame.testUnitType) or gsub((unit and UnitName(unit)) or "", FSPAT, "")
	local reaction, unitType = NP:GetUnitInfo(frame)
	local oldUnitType = frame.UnitType
	frame.UnitType = unitType
	frame.UnitReaction = reaction

	frame.UnitClass = NP:UnitClass(frame)

	if unitType ~= oldUnitType or isConfig then
		NP:Update_HealthBar(frame)

		NP:Configure_CPoints(frame, true)

		NP:Configure_Level(frame)
		NP:Configure_Name(frame)

		NP:Configure_Auras(frame, "Buffs")
		NP:Configure_Auras(frame, "Debuffs")

		if NP.db.units[unitType].health.enable or (frame.isTarget and NP.db.alwaysShowTargetHealth) then
			NP:Configure_HealthBar(frame, true)
			NP:Configure_CastBar(frame, true)
		end

		NP:Configure_Glow(frame)
		NP:Configure_Elite(frame)
		NP:Configure_Highlight(frame)
		NP:Configure_IconFrame(frame)
	end

	frame.CutawayHealth:Hide()

	NP:RegisterEvents(frame)
	NP:UpdateElement_All(frame, nil, true)

	NP:SetSize(self)

	if not frame.isAlphaChanged then
		if not dontHideHighlight then
			NP:PlateFade(frame, NP.db.fadeIn and 1 or 0, 0, 1)
		end
	end

	frame:Show()

	NP:StyleFilterUpdate(frame, "NAME_PLATE_UNIT_ADDED")
	NP:ForEachVisiblePlate("ResetNameplateFrameLevel") --keep this after `StyleFilterUpdate`
end

function NP:OnHide(isConfig)
	local frame = self.ElvUIFrame
	if not frame then return end

	NP.VisiblePlates[frame] = nil

	frame.unit = nil

	for i = 1, #frame.Buffs do
		frame.Buffs[i]:SetScript("OnUpdate", nil)
		frame.Buffs[i].timeLeft = nil
		frame.Buffs[i]:Hide()
	end

	for i = 1, #frame.Debuffs do
		frame.Debuffs[i]:SetScript("OnUpdate", nil)
		frame.Debuffs[i].timeLeft = nil
		frame.Debuffs[i]:Hide()
	end

	if isConfig then
		frame.Buffs.anchoredIcons = 0
		frame.Debuffs.anchoredIcons = 0
	end

	NP:StyleFilterClear(frame)

	if frame.currentScale and frame.currentScale ~= 1 then
		NP:SetFrameScale(frame, 1, true)
	end

	if frame.isEventsRegistered then
		NP:UnregisterFrameEvents(frame)
	end

	frame.TopIndicator:Hide()
	frame.LeftIndicator:Hide()
	frame.RightIndicator:Hide()
	frame.Shadow:Hide()
	frame.Spark:Hide()
	frame.Health.r, frame.Health.g, frame.Health.b = nil, nil, nil
	frame.Health:Hide()
	frame.CastBar:Hide()
	frame.CastBar.casting = nil
	frame.CastBar.channeling = nil
	frame.CastBar.notInterruptible = nil
	frame.CastBar.spellName = nil
	frame.Level:SetText()
	frame.Name.r, frame.Name.g, frame.Name.b = nil, nil, nil
	frame.Name:SetText()
	frame.Name.NameOnlyGlow:Hide()
	frame.Elite:Hide()
	frame.CPoints:Hide()
	frame.IconFrame:Hide()
	frame:Hide()
	frame.isTarget = nil
	frame.isMouseover = nil
	frame.currentScale = nil
	frame.UnitName = nil
	frame.UnitClass = nil
	frame.UnitReaction = nil
	frame.guid = nil
	frame.alpha = nil
	frame.isAlphaChanged = nil
	frame.RaidIconType = nil
	frame.ThreatScale = nil
	frame.ThreatStatus = nil

	NP:StyleFilterClearVariables(frame)
end

function NP:UpdateAllFrame(frame, isConfig, dontHideHighlight)
	frame = frame:GetParent()

	NP.OnHide(frame, isConfig)
	NP.OnShow(frame, isConfig, dontHideHighlight)
end

function NP:ConfigureAll()
	if not E.private.nameplates.enable then return end

	NP:StyleFilterConfigure()
	NP:ForEachPlate("UpdateAllFrame", true, true)
	NP:SetCVars()
	NP:UpdateClickableSizes()
end

function NP:ForEachPlate(functionToRun, ...)
	for frame in pairs(NP.CreatedPlates) do
		if frame and frame.ElvUIFrame then
			NP[functionToRun](NP, frame.ElvUIFrame, ...)
		end
	end

	if functionToRun == "ResetNameplateFrameLevel" then
		NP.CollectedFrameLevelCount = 1
	end
end

function NP:ForEachVisiblePlate(functionToRun, ...)
	for frame in pairs(NP.VisiblePlates) do
		NP[functionToRun](NP, frame, ...)
	end

	if functionToRun == "ResetNameplateFrameLevel" then
		NP.CollectedFrameLevelCount = 1
	end
end

function NP:UpdateElement_All(frame, noTargetFrame, filterIgnore)
	local healthShown = NP.db.units[frame.UnitType].health.enable or (frame.isTarget and NP.db.alwaysShowTargetHealth)

	NP:Update_HealthBar(frame)

	if healthShown then
		NP:Update_Health(frame)
		NP:Update_HealthColor(frame)
		NP:Update_CastBar(frame, nil, frame.unit)
		NP:UpdateElement_Auras(frame)
	end

	NP:Update_RaidIcon(frame)
	NP:Update_HealerIcon(frame)

	frame.Level:ClearAllPoints()
	frame.Name:ClearAllPoints()
	NP:Update_Name(frame)
	NP:Update_Level(frame)

	if not noTargetFrame then
		NP:Update_Elite(frame)
		NP:Update_Highlight(frame)
		NP:Update_Glow(frame)

		NP:SetTargetFrame(frame)
	end

	NP:Update_IconFrame(frame)

	if not filterIgnore then
		NP:StyleFilterUpdate(frame, "UpdateElement_All")
	end
end

function NP:SetSize(frame)
	if InCombatLockdown() then
		NP.ResizeQueue[frame] = true
	else
		local unitFrame = frame.ElvUIFrame
		local unitType = unitFrame and unitFrame.UnitType
		unitType = (unitType == "FRIENDLY_PLAYER" or unitType == "FRIENDLY_NPC") and "friendly" or "enemy"

		if NP.db.clickThrough[unitType] then
			frame:SetSize(0.001, 0.001)
		else
			if unitType == "friendly" then
				frame:SetSize(NP.db.plateSize.friendlyWidth, NP.db.plateSize.friendlyHeight)
			else
				frame:SetSize(NP.db.plateSize.enemyWidth, NP.db.plateSize.enemyHeight)
			end
		end

		NP.ResizeQueue[frame] = nil
	end
end

function NP:UpdateClickableSizes()
	if InCombatLockdown() then
		NP.ClickableSizeQueued = true
	else
		NP.ClickableSizeQueued = nil
		C_NamePlate_SetNamePlateEnemySize(NP.db.plateSize.enemyWidth, NP.db.plateSize.enemyHeight)
		C_NamePlate_SetNamePlateFriendlySize(NP.db.plateSize.friendlyWidth, NP.db.plateSize.friendlyHeight)
	end
end

local blizzardRegions = { "healthBar", "castBar", "BuffFrame", "ClassificationFrame", "RaidTargetFrame", "aggroHighlight", "selectionHighlight", "classificationIndicator", "name" }

local function muteBlizzardPlate(blizz)
	blizz:SetAlpha(0)

	for _, key in next, blizzardRegions do
		local region = blizz[key]
		if region then
			region:SetAlpha(0)
		end
	end

	local castBar = blizz.castBar
	if castBar then
		if castBar.Icon then castBar.Icon:SetAlpha(0) end
		if castBar.BorderShield then castBar.BorderShield:SetAlpha(0) end
	end

	if CompactUnitFrame_UnregisterEvents then
		CompactUnitFrame_UnregisterEvents(blizz)
	end
end

function NP:DisableBlizzard(plate)
	if not plate then return end

	local blizz = plate.UnitFrame
	if not (blizz and blizz.isNamePlate) then return end

	plate.BlizzardFrame = blizz

	muteBlizzardPlate(blizz)
end

local function neutralizeDriverPlate(plate)
	local blizz = plate.UnitFrame
	if not blizz then return end

	if CompactUnitFrame_UnregisterEvents then
		CompactUnitFrame_UnregisterEvents(blizz)
	end

	if blizz.BuffFrame and blizz.BuffFrame.SetActive then
		blizz.BuffFrame:SetActive(false)
	end
end

local plateID = 0
function NP:OnCreated(frame)
	plateID = plateID + 1

	local unitFrame = CreateFrame("Frame", format("ElvUI_NamePlate%d", plateID), frame)
	frame.ElvUIFrame = unitFrame
	unitFrame:Hide()
	unitFrame:SetAllPoints(frame)
	unitFrame:SetScript("OnEvent", NP.OnEvent)
	unitFrame:SetScale(NP.db.plateScale and E.uiscale or 1)
	unitFrame.plateID = plateID

	unitFrame.Health = NP:Construct_HealthBar(unitFrame)
	unitFrame.Health.Highlight = NP:Construct_Highlight(unitFrame)
	unitFrame.CutawayHealth = NP:ConstructElement_CutawayHealth(unitFrame)
	unitFrame.Level = NP:Construct_Level(unitFrame)
	unitFrame.Name = NP:Construct_Name(unitFrame)
	unitFrame.CastBar = NP:Construct_CastBar(unitFrame)
	unitFrame.Elite = NP:Construct_Elite(unitFrame)
	unitFrame.Buffs = NP:ConstructElement_Auras(unitFrame, "Buffs")
	unitFrame.Debuffs = NP:ConstructElement_Auras(unitFrame, "Debuffs")
	unitFrame.HealerIcon = NP:Construct_HealerIcon(unitFrame)
	unitFrame.CPoints = NP:Construct_CPoints(unitFrame)
	unitFrame.IconFrame = NP:Construct_IconFrame(unitFrame)
	unitFrame.RaidIcon = NP:Construct_RaidIcon(unitFrame)
	NP:Construct_Glow(unitFrame)

	NP:DisableBlizzard(frame)

	unitFrame.UnitType = "ENEMY_NPC"
	NP:Configure_Level(unitFrame)
	NP:Configure_Name(unitFrame)
	NP:Configure_CastBar(unitFrame, true)
	NP:Configure_HealthBar(unitFrame, true)

	NP:SetSize(frame)

	NP.CreatedPlates[frame] = true
end

local healthEvents = {
	UNIT_HEALTH = true,
	UNIT_MAXHEALTH = true
}

function NP:OnEvent(event, unit, ...)
	if not unit and not self.unit then return end
	if unit and self.unit ~= unit then return end

	if healthEvents[event] then
		NP:Update_Health(self)
		NP:Update_HealthColor(self)
		NP:Update_Glow(self)
		NP:StyleFilterUpdate(self, "UNIT_HEALTH")
		return
	end

	if event == "UNIT_AURA" then
		NP:UpdateElement_Auras(self)
		return
	end

	if event == "UNIT_FACTION" then
		local reaction, unitType = NP:GetUnitInfo(self)
		if unitType == self.UnitType then
			self.UnitReaction = reaction

			NP:Update_HealthColor(self)
			NP:Update_Name(self)
			return
		end
	end

	if event == "UNIT_NAME_UPDATE" or event == "UNIT_LEVEL" or event == "UNIT_FACTION" then
		NP:UpdateAllFrame(self, nil, true)
		return
	end

	NP:Update_CastBar(self, event, unit, ...)
end

local function registerUnitEvent(frame, event)
	frame:RegisterUnitEvent(event, frame.unit)
end

function NP:RegisterEvents(frame)
	if not frame.unit then return end

	registerUnitEvent(frame, "UNIT_HEALTH")
	registerUnitEvent(frame, "UNIT_MAXHEALTH")
	registerUnitEvent(frame, "UNIT_NAME_UPDATE")
	registerUnitEvent(frame, "UNIT_LEVEL")
	registerUnitEvent(frame, "UNIT_FACTION")
	registerUnitEvent(frame, "UNIT_AURA")
	frame.isEventsRegistered = true

	if NP.db.units[frame.UnitType].health.enable or (frame.isTarget and NP.db.alwaysShowTargetHealth) then
		if NP.db.units[frame.UnitType].castbar.enable then
			registerUnitEvent(frame, "UNIT_SPELLCAST_INTERRUPTED")
			registerUnitEvent(frame, "UNIT_SPELLCAST_DELAYED")
			registerUnitEvent(frame, "UNIT_SPELLCAST_CHANNEL_START")
			registerUnitEvent(frame, "UNIT_SPELLCAST_CHANNEL_UPDATE")
			registerUnitEvent(frame, "UNIT_SPELLCAST_CHANNEL_STOP")
			registerUnitEvent(frame, "UNIT_SPELLCAST_INTERRUPTIBLE")
			registerUnitEvent(frame, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
			registerUnitEvent(frame, "UNIT_SPELLCAST_START")
			registerUnitEvent(frame, "UNIT_SPELLCAST_STOP")
			registerUnitEvent(frame, "UNIT_SPELLCAST_FAILED")
		end

		NP.OnEvent(frame, nil, frame.unit)
	end
end

function NP:UnregisterFrameEvents(frame)
	frame:UnregisterEvent("UNIT_HEALTH")
	frame:UnregisterEvent("UNIT_MAXHEALTH")
	frame:UnregisterEvent("UNIT_NAME_UPDATE")
	frame:UnregisterEvent("UNIT_LEVEL")
	frame:UnregisterEvent("UNIT_FACTION")
	frame:UnregisterEvent("UNIT_AURA")
	frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	frame:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
	frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	frame:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	frame:UnregisterEvent("UNIT_SPELLCAST_START")
	frame:UnregisterEvent("UNIT_SPELLCAST_STOP")
	frame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	frame.isEventsRegistered = nil
end

function NP:PlateFade(nameplate, timeToFade, startAlpha, endAlpha)
	-- we need our own function because we want a smooth transition and dont want it to force update every pass.
	-- its controlled by fadeTimer which is reset when UIFrameFadeOut or UIFrameFadeIn code runs.

	if not nameplate.FadeObject then
		nameplate.FadeObject = {}
	end

	nameplate.FadeObject.timeToFade = (nameplate.isTarget and 0) or timeToFade
	nameplate.FadeObject.startAlpha = startAlpha
	nameplate.FadeObject.endAlpha = endAlpha
	nameplate.FadeObject.diffAlpha = endAlpha - startAlpha

	if nameplate.FadeObject.fadeTimer then
		nameplate.FadeObject.fadeTimer = 0
	else
		E:UIFrameFade(nameplate, nameplate.FadeObject)
	end
end

function NP:SetTargetFrame(frame)
	if hasTarget and frame.unit and UnitIsUnit(frame.unit, "target") then
		if not frame.isTarget then
			frame.isTarget = true

			NP:SetPlateFrameLevel(frame, NP:GetPlateFrameLevel(frame), true)

			if NP.db.useTargetScale then
				NP:SetFrameScale(frame, (frame.ThreatScale or 1) * NP.db.targetScale)
			end

			NP:UpdateElement_Auras(frame)

			if not NP.db.units[frame.UnitType].health.enable and NP.db.alwaysShowTargetHealth then
				frame.Health.r, frame.Health.g, frame.Health.b = nil, nil, nil

				NP:Configure_HealthBar(frame)
				NP:Configure_CastBar(frame)
				NP:Configure_Elite(frame)
				NP:Configure_CPoints(frame)

				NP:RegisterEvents(frame)

				NP:UpdateElement_All(frame, true)
			end

			NP:PlateFade(frame, NP.db.fadeIn and 1 or 0, frame:GetAlpha(), 1)

			NP:Update_Highlight(frame)
			NP:Update_CPoints(frame)
			NP:StyleFilterUpdate(frame, "PLAYER_TARGET_CHANGED")
			NP:ForEachVisiblePlate("ResetNameplateFrameLevel") --keep this after `StyleFilterUpdate`
		end
	elseif frame.isTarget then
		frame.isTarget = nil

		NP:SetPlateFrameLevel(frame, NP:GetPlateFrameLevel(frame))

		if NP.db.useTargetScale then
			NP:SetFrameScale(frame, (frame.ThreatScale or 1))
		end


		if not NP.db.units[frame.UnitType].health.enable then
			NP:UpdateAllFrame(frame, nil, true)
		end

		NP:Update_CPoints(frame)

		if not frame.AlphaChanged then
			if hasTarget then
				NP:PlateFade(frame, NP.db.fadeIn and 1 or 0, frame:GetAlpha(), NP.db.nonTargetTransparency)
			else
				NP:PlateFade(frame, NP.db.fadeIn and 1 or 0, frame:GetAlpha(), 1)
			end
		end

		NP:StyleFilterUpdate(frame, "PLAYER_TARGET_CHANGED")
		NP:ForEachVisiblePlate("ResetNameplateFrameLevel") --keep this after `StyleFilterUpdate`
	else
		if hasTarget and not frame.isAlphaChanged then
			frame.isAlphaChanged = true

			if not frame.AlphaChanged then
				NP:PlateFade(frame, NP.db.fadeIn and 1 or 0, frame:GetAlpha(), NP.db.nonTargetTransparency)
			end

			NP:StyleFilterUpdate(frame, "PLAYER_TARGET_CHANGED")
		elseif not hasTarget and frame.isAlphaChanged then
			frame.isAlphaChanged = nil

			if not frame.AlphaChanged then
				NP:PlateFade(frame, NP.db.fadeIn and 1 or 0, frame:GetAlpha(), 1)
			end

			NP:StyleFilterUpdate(frame, "PLAYER_TARGET_CHANGED")
		end
	end

	if NP:GlowLayoutStale(frame) then
		NP:Configure_Glow(frame)
	end

	NP:Update_Glow(frame)
end

-- UPDATE_MOUSEOVER_UNIT only fires when the unit is acquired, never when it is dropped
local mouseoverWatcher = CreateFrame("Frame")
mouseoverWatcher:Hide()
mouseoverWatcher.elapsed = 0
mouseoverWatcher:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed < 0.1 then return end
	self.elapsed = 0

	if not UnitExists("mouseover") then
		self:Hide()

		NP:UpdateVisiblePlates()
	end
end)

function NP:SetMouseoverFrame(frame)
	if frame.unit and UnitIsUnit(frame.unit, "mouseover") then
		if not frame.isMouseover then
			frame.isMouseover = true

			mouseoverWatcher.elapsed = 0
			mouseoverWatcher:Show()

			NP:Update_Highlight(frame)
			NP:UpdateElement_Auras(frame)
		end
	elseif frame.isMouseover then
		frame.isMouseover = nil

		NP:Update_Highlight(frame)
	end
end

-- the engine places plates on fractional pixels, which smears the 1px border over two rows
function NP:PixelSnap(frame)
	local health = frame.Health
	local left, top = health:GetLeft(), health:GetTop()
	if not left or not top then return end

	local pixel = E.perfect / health:GetEffectiveScale()
	local x, y = (left / pixel) % 1, (top / pixel) % 1
	if x > 0.5 then x = x - 1 end
	if y > 0.5 then y = y - 1 end

	if abs(x) < 0.02 and abs(y) < 0.02 then return end

	local offsetX = (frame.snapX or 0) - x * pixel
	local offsetY = (frame.snapY or 0) - y * pixel
	frame.snapX = (offsetX > pixel and pixel) or (offsetX < -pixel and -pixel) or offsetX
	frame.snapY = (offsetY > pixel and pixel) or (offsetY < -pixel and -pixel) or offsetY

	health:SetPoint("TOP", frame, "TOP", frame.snapX, frame.snapY)
end

local pixelSnapper = CreateFrame("Frame")
local healthElapsed = 0
pixelSnapper:SetScript("OnUpdate", function(_, elapsed)
	if not next(NP.VisiblePlates) then return end

	healthElapsed = healthElapsed + elapsed

	local pollHealth = healthElapsed > 0.2
	if pollHealth then healthElapsed = 0 end

	for frame in pairs(NP.VisiblePlates) do
		NP:PixelSnap(frame)

		if pollHealth and frame.unit then
			local health, maxHealth = NP:GetHealth(frame)
			if frame.polledHealth ~= health or frame.polledMaxHealth ~= maxHealth then
				frame.polledHealth, frame.polledMaxHealth = health, maxHealth

				NP:Update_Health(frame)
				NP:Update_HealthColor(frame)
			end
		end
	end
end)

function NP:UpdateVisiblePlates()
	for frame in pairs(NP.VisiblePlates) do
		NP:SetMouseoverFrame(frame)
		NP:SetTargetFrame(frame)

		local status = NP:UnitDetailedThreatSituation(frame)
		if frame.ThreatStatus ~= status then
			frame.ThreatStatus = status

			NP:Update_HealthColor(frame)
		end
	end
end

function NP:CheckRaidIcon(frame)
	local index = frame.testRaidIcon or (frame.unit and GetRaidTargetIndex(frame.unit))
	frame.RaidIconIndex = index
	frame.RaidIconType = index and RaidIconIndex[index] or nil
end

local function CopySettings(from, to)
	for setting, value in pairs(from) do
		if type(value) == "table" and to[setting] ~= nil then
			CopySettings(from[setting], to[setting])
		else
			if to[setting] ~= nil then
				to[setting] = from[setting]
			end
		end
	end
end

function NP:ResetAuraPriority()
	for unitType, content in pairs(E.db.nameplates.units) do
		local default = P.nameplates.units[unitType]
		if default then
			if content.buffs and content.buffs.filters then
				content.buffs.filters.priority = default.buffs.filters.priority
			end
			if content.debuffs and content.debuffs.filters then
				content.debuffs.filters.priority = default.debuffs.filters.priority
			end
		end
	end
end

function NP:ResetSettings(unit)
	CopySettings(P.nameplates.units[unit], NP.db.units[unit])
end

function NP:CopySettings(from, to)
	if from == to then return end

	CopySettings(NP.db.units[from], NP.db.units[to])
end

function NP:PLAYER_ENTERING_WORLD()
	twipe(NP.Healers)

	NP:AcquireExistingPlates()

	local inInstance, instanceType = IsInInstance()
	if inInstance and (instanceType == "pvp") and NP.db.units.ENEMY_PLAYER.markHealers then
		NP:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "CheckBGHealers")
		NP.CheckHealerTimer = NP:ScheduleRepeatingTimer("CheckBGHealers", 3)
	else
		NP:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
		if NP.CheckHealerTimer then
			NP:CancelTimer(NP.CheckHealerTimer)
			NP.CheckHealerTimer = nil;
		end
	end

	NP:PLAYER_TARGET_CHANGED()
end

function NP:AcquireExistingPlates()
	for _, plate in ipairs(C_NamePlate_GetNamePlates()) do
		local unit = plate.namePlateUnitToken
		if unit and UnitExists(unit) then
			NP:NAME_PLATE_UNIT_ADDED(nil, unit)
		end
	end
end

function NP:NAME_PLATE_CREATED(_, plate)
	if plate and not NP.CreatedPlates[plate] then
		NP:OnCreated(plate)
	end
end

function NP:NAME_PLATE_UNIT_ADDED(_, unit)
	if not unit then return end

	local plate = C_NamePlate_GetNamePlateForUnit(unit)
	if not plate then return end

	if not NP.CreatedPlates[plate] then
		NP:OnCreated(plate)
	end

	NP.OnShow(plate, nil, nil, unit)

	neutralizeDriverPlate(plate)
end

function NP:NAME_PLATE_UNIT_REMOVED(_, unit)
	if not unit then return end

	local plate = C_NamePlate_GetNamePlateForUnit(unit)
	if plate and NP.CreatedPlates[plate] then
		NP.OnHide(plate)
	end
end

function NP:PLAYER_TARGET_CHANGED()
	hasTarget = UnitExists("target") and true or false

	NP:UpdateVisiblePlates()
end

function NP:UPDATE_MOUSEOVER_UNIT()
	NP:UpdateVisiblePlates()
end

function NP:UNIT_THREAT_LIST_UPDATE(_, unit)
	if not unit then return end

	for frame in pairs(NP.VisiblePlates) do
		if frame.unit and UnitIsUnit(frame.unit, unit) then
			local status = NP:UnitDetailedThreatSituation(frame)
			if frame.ThreatStatus ~= status then
				frame.ThreatStatus = status

				NP:Update_HealthColor(frame)
			end
		end
	end
end

function NP:PLAYER_FOCUS_CHANGED()
	local unitName

	if UnitIsPlayer("focus") and not UnitIsUnit("focus", "player") then
		local name = UnitName("focus")

		NP.NameByUnit.focus = name

		unitName = name
	elseif NP.NameByUnit.focus then
		unitName = NP.NameByUnit.focus
		NP.NameByUnit.focus = nil
	end

	if not unitName then
		return
	end

	for frame in pairs(NP.VisiblePlates) do
		if frame.UnitName == unitName then
			NP:UpdateAllFrame(frame, nil, true)
		end
	end
end

function NP:SetCVars()
	E:SetCVar('nameplateMaxDistance', NP.db.loadDistance or 41)
	E:SetCVar('ShowClassColorInNameplate', 1)
	E:SetCVar('showVKeyCastbar', 0)
	E:SetCVar('nameplateAllowOverlap', NP.db.motionType == 'STACKED' and 0 or 1)

	-- the order of these is important !!
	E:SetCVar('nameplateShowEnemyGuardians', NP.db.visibility.enemy.guardians and 1 or 0)
	E:SetCVar('nameplateShowEnemyPets', NP.db.visibility.enemy.pets and 1 or 0)
	E:SetCVar('nameplateShowEnemyTotems', NP.db.visibility.enemy.totems and 1 or 0)
	E:SetCVar('nameplateShowFriendlyGuardians', NP.db.visibility.friendly.guardians and 1 or 0)
	E:SetCVar('nameplateShowFriendlyPets', NP.db.visibility.friendly.pets and 1 or 0)
	E:SetCVar('nameplateShowFriendlyTotems', NP.db.visibility.friendly.totems and 1 or 0)
end

function NP:PLAYER_REGEN_DISABLED()
	if NP.db.showFriendlyCombat == 'TOGGLE_ON' then
		E:SetCVar('nameplateShowFriends', 1)
	elseif NP.db.showFriendlyCombat == 'TOGGLE_OFF' then
		E:SetCVar('nameplateShowFriends', 0)
	end

	if NP.db.showEnemyCombat == 'TOGGLE_ON' then
		E:SetCVar('nameplateShowEnemies', 1)
	elseif NP.db.showEnemyCombat == 'TOGGLE_OFF' then
		E:SetCVar('nameplateShowEnemies', 0)
	end

	NP:ForEachVisiblePlate("StyleFilterUpdate", "PLAYER_REGEN_DISABLED")
end

function NP:PLAYER_REGEN_ENABLED()
	if next(NP.ResizeQueue) then
		for frame in pairs(NP.ResizeQueue) do
			NP:SetSize(frame)
		end
	end

	if NP.ClickableSizeQueued then
		NP:UpdateClickableSizes()
	end

	if NP.db.showFriendlyCombat == 'TOGGLE_ON' then
		E:SetCVar('nameplateShowFriends', 0)
	elseif NP.db.showFriendlyCombat == 'TOGGLE_OFF' then
		E:SetCVar('nameplateShowFriends', 1)
	end

	if NP.db.showEnemyCombat == 'TOGGLE_ON' then
		E:SetCVar('nameplateShowEnemies', 0)
	elseif NP.db.showEnemyCombat == 'TOGGLE_OFF' then
		E:SetCVar('nameplateShowEnemies', 1)
	end

	NP:ForEachVisiblePlate("StyleFilterUpdate", "PLAYER_REGEN_ENABLED")
end

function NP:UNIT_COMBO_POINTS(_, unit)
	if unit == "player" or unit == "vehicle" then
		NP:ForEachVisiblePlate("Update_CPoints")
	end
end

for _, powerEvent in pairs({"UNIT_HEALTH", "UNIT_MANA", "UNIT_ENERGY", "UNIT_FOCUS", "UNIT_RAGE", "UNIT_RUNIC_POWER", "UNIT_DISPLAYPOWER"}) do
	NP[powerEvent] = function(_, _, unit)
		if unit ~= "player" then return end

		NP:ForEachVisiblePlate("StyleFilterUpdate", powerEvent)
	end
end

function NP:SPELL_UPDATE_COOLDOWN(...)
	NP:ForEachVisiblePlate("StyleFilterUpdate", "SPELL_UPDATE_COOLDOWN")
end

function NP:PLAYER_UPDATE_RESTING()
	NP:ForEachVisiblePlate("StyleFilterUpdate", "PLAYER_UPDATE_RESTING")
end

function NP:RAID_TARGET_UPDATE()
	for frame in pairs(NP.VisiblePlates) do
		NP:CheckRaidIcon(frame)
		NP:Update_RaidIcon(frame)
		NP:StyleFilterUpdate(frame, "RAID_TARGET_UPDATE")
	end
end

function NP:TogleTestFrame(unitType)
	local unitFrame = ElvNP_Test.ElvUIFrame
	if not ElvNP_Test:IsShown() or unitFrame.UnitType ~= unitType then
		local maxHealth = UnitHealthMax("player")
		unitFrame.testUnitType = unitType
		unitFrame.testMaxHealth = maxHealth
		unitFrame.testHealth = random(1, maxHealth)
		unitFrame.testClass = (unitType == "ENEMY_PLAYER" or unitType == "FRIENDLY_PLAYER") and E.myclass or nil
		unitFrame.testRaidIcon = random(1, 8)

		unitFrame.Buffs.forceShow = true
		unitFrame.Debuffs.forceShow = true

		if not ElvNP_Test:IsShown() then
			ElvNP_Test:Show()
		end

		NP:UpdateAllFrame(unitFrame, true, true)
	else
		ElvNP_Test:Hide()
	end
end

function NP:Initialize()
	if not E.private.nameplates.enable then return end
	NP.Initialized = true

	NP.db = E.db.nameplates


	--Add metatable to all our StyleFilters so they can grab default values if missing
	NP:StyleFilterInitialize()

	--Populate `NP.StyleFilterEvents` with events Style Filters will be using and sort the filters based on priority.
	NP:StyleFilterConfigure()

	NP.levelStep = 2

	NP:SetCVars()

	NP:UpdateClickableSizes()

	if _G.NamePlateDriverFrame then
		hooksecurefunc(_G.NamePlateDriverFrame, "UpdateNamePlateOptions", function()
			NP:UpdateClickableSizes()

			for _, plate in ipairs(C_NamePlate_GetNamePlates()) do
				neutralizeDriverPlate(plate)
			end
		end)
	end

	local ElvNP_Test = CreateFrame("Button", "ElvNP_Test")
	ElvNP_Test:SetScale(1)
	ElvNP_Test:ClearAllPoints()
	ElvNP_Test:Point("BOTTOM", UIParent, "BOTTOM", 0, 250)
	ElvNP_Test:SetMovable(true)
	ElvNP_Test:RegisterForDrag("LeftButton", "RightButton")
	ElvNP_Test:SetScript("OnDragStart", function() ElvNP_Test:StartMoving() end)
	ElvNP_Test:SetScript("OnDragStop", function() ElvNP_Test:StopMovingOrSizing() end)

	NP:OnCreated(ElvNP_Test)

	ElvNP_Test.isTestFrame = true
	ElvNP_Test.ElvUIFrame.testUnitType = "ENEMY_NPC"
	ElvNP_Test.ElvUIFrame.testMaxHealth = 100
	ElvNP_Test.ElvUIFrame.testHealth = 70
	NP.OnShow(ElvNP_Test, true, true)

	NP:Configure_HealthBar(ElvNP_Test.ElvUIFrame, true)
	NP:Configure_CastBar(ElvNP_Test.ElvUIFrame, true)

	local castbar = ElvNP_Test.ElvUIFrame.CastBar
	castbar:SetParent(ElvNP_Test.ElvUIFrame.Health)
	castbar.Hide = castbar.Show
	castbar:Show()
	castbar.Name:SetText("Casting")
	castbar.Time:SetText("3.1")
	castbar.Icon.texture:SetTexture([[Interface\Icons\Spell_Holy_Penance]])
	castbar:SetStatusBarColor(NP.db.colors.castColor.r, NP.db.colors.castColor.g, NP.db.colors.castColor.b)
	ElvNP_Test:Hide()

	NP:RegisterEvent("NAME_PLATE_CREATED")
	NP:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	NP:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	NP:RegisterEvent("UNIT_THREAT_LIST_UPDATE")

	NP:RegisterEvent("PLAYER_ENTERING_WORLD")
	NP:RegisterEvent("PLAYER_REGEN_ENABLED")
	NP:RegisterEvent("PLAYER_REGEN_DISABLED")
	NP:RegisterEvent("PLAYER_LOGOUT")
	NP:RegisterEvent("PLAYER_TARGET_CHANGED")
	NP:RegisterEvent("PLAYER_FOCUS_CHANGED")
	NP:RegisterEvent("PLAYER_UPDATE_RESTING")
	NP:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	NP:RegisterEvent("RAID_TARGET_UPDATE")
	NP:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	NP:RegisterEvent("UNIT_COMBO_POINTS")
end

E:RegisterModule(NP:GetName())
