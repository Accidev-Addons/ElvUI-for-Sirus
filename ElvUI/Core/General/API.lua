------------------------------------------------------------------------
-- Collection of functions that can be used in multiple places
------------------------------------------------------------------------

local E, L, V, P, G = unpack(ElvUI)
local TT = E:GetModule('Tooltip')
local ElvUF = E.oUF

local _G = _G
local type, pairs, unpack = type, pairs, unpack
local wipe, next, tinsert, date, time = wipe, next, tinsert, date, time
local format, gsub, strlen, strmatch, strsub, tonumber, tostring = string.format, string.gsub, strlen, strmatch, strsub, tonumber, tostring
local abs = math.abs
local hooksecurefunc = hooksecurefunc

local CopyTable = CopyTable
local CreateFrame = CreateFrame
local GetBattlefieldArenaFaction = GetBattlefieldArenaFaction
local GetCVarBool = GetCVarBool
local GetDungeonDifficulty = GetDungeonDifficulty
local GetFunctionCPUUsage = GetFunctionCPUUsage
local GetGameTime = GetGameTime
local GetInstanceInfo = GetInstanceInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetPartyAssignment = GetPartyAssignment
local GetRaidDifficulty = GetRaidDifficulty
local GetWatchedFactionInfo = GetWatchedFactionInfo
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsLevelAtEffectiveMaxLevel = IsLevelAtEffectiveMaxLevel
local IsAddOnLoaded = IsAddOnLoaded
local IsXPUserDisabled = IsXPUserDisabled
local RequestBattlefieldScoreData = RequestBattlefieldScoreData
local UIParent = UIParent
local UnitAura = UnitAura
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInBattleground = UnitInBattleground
local UnitIsPlayer = UnitIsPlayer

local GetSpecialization = E.GetSpecialization
local GetSpecializationInfo = E.GetSpecializationInfo
local GetSpecializationInfoByID = E.GetSpecializationInfoByID
local GetInspectSpecialization = E.GetInspectSpecialization

local LGT = _G.LibStub('LibGroupTalents-1.0')
local LGT_ROLES = { tank = 'TANK', healer = 'HEALER', melee = 'DAMAGER', caster = 'DAMAGER' }

local NONE = NONE

local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT
local FACTION_HORDE = FACTION_HORDE
local FACTION_ALLIANCE = FACTION_ALLIANCE
local PLAYER_FACTION_GROUP = PLAYER_FACTION_GROUP

local GameMenuButtonLogout = GameMenuButtonLogout
local GameMenuButtonAddons = GameMenuButtonAddons
local GameMenuFrame = GameMenuFrame
local UIErrorsFrame = UIErrorsFrame
-- GLOBALS: ElvDB, ElvUI

local DebuffColors = DebuffTypeColor

E.GroupRoles = {}
E.GroupUnitsByRole = {
	TANK = {},
	HEALER = {},
	DAMAGER = {},
	NONE = {}
}

E.SpecInfoBySpecClass = {} -- ['Protection Warrior'] = specInfo (table)
E.SpecInfoBySpecID = {} -- [250] = specInfo (table)

E.SpecByClass = {
	DEATHKNIGHT	= { 250, 251, 252 },
	DRUID		= { 102, 103, 104, 105 },
	HUNTER		= { 253, 254, 255 },
	MAGE		= { 62, 63, 64 },
	PALADIN		= { 65, 66, 70 },
	PRIEST		= { 256, 257, 258 },
	ROGUE		= { 259, 260, 261 },
	SHAMAN		= { 262, 263, 264 },
	WARLOCK		= { 265, 266, 267 },
	WARRIOR		= { 71, 72, 73 },
}

E.ClassName = {
	DEATHKNIGHT	= 'Death Knight',
	DRUID		= 'Druid',
	HUNTER		= 'Hunter',
	MAGE		= 'Mage',
	PALADIN		= 'Paladin',
	PRIEST		= 'Priest',
	ROGUE		= 'Rogue',
	SHAMAN		= 'Shaman',
	WARLOCK		= 'Warlock',
	WARRIOR		= 'Warrior',
}

local EnglishClassName = CopyTable(E.ClassName)

local EnglishSpecName = {
	-- Death Knight
	[250]	= 'Blood',
	[251]	= 'Frost',
	[252]	= 'Unholy',
	-- Druids
	[102]	= 'Balance',
	[103]	= 'Feral',
	[104]	= 'Guardian',
	[105]	= 'Restoration',
	-- Hunter
	[253]	= 'Beast Mastery',
	[254]	= 'Marksmanship',
	[255]	= 'Survival',
	-- Mage
	[62]	= 'Arcane',
	[63]	= 'Fire',
	[64]	= 'Frost',
	-- Paladin
	[65]	= 'Holy',
	[66]	= 'Protection',
	[70]	= 'Retribution',
	-- Priest
	[256]	= 'Discipline',
	[257]	= 'Holy',
	[258]	= 'Shadow',
	-- Rogue
	[259]	= 'Assasination',
	[260]	= 'Combat',
	[261]	= 'Sublety',
	-- Shaman
	[262]	= 'Elemental',
	[263]	= 'Enhancement',
	[264]	= 'Restoration',
	-- Walock
	[265]	= 'Affliction',
	[266]	= 'Demonology',
	[267]	= 'Destruction',
	-- Warrior
	[71]	= 'Arms',
	[72]	= 'Fury',
	[73]	= 'Protection',
}

E.SpecName = {}

do
	local SpecNameGlobal = {
		[250]	= 'DEATHKNIGHT_SPEC_BLOOD_TITLE',
		[251]	= 'DEATHKNIGHT_SPEC_FROST_TITLE',
		[252]	= 'DEATHKNIGHT_SPEC_UNHOLY_TITLE',
		[102]	= 'DRUID_BALANCE_TITLE',
		[103]	= 'DRUID_FERAL_TITLE',
		[104]	= 'DRUID_FERAL_TITLE',
		[105]	= 'DRUID_RESTORATION_TITLE',
		[253]	= 'HUNTER_SPEC_BEASTMASTERY_TITLE',
		[254]	= 'HUNTER_SPEC_MARKSMANSHIP_TITLE',
		[255]	= 'HUNTER_SPEC_SURVIVAL_TITLE',
		[62]	= 'MAGE_SPEC_ARCANE_TITLE',
		[63]	= 'MAGE_SPEC_FIRE_TITLE',
		[64]	= 'MAGE_SPEC_FROST_TITLE',
		[65]	= 'PALADIN_SPEC_HOLY_TITLE',
		[66]	= 'PALADIN_SPEC_PROTECTION_TITLE',
		[70]	= 'PALADIN_SPEC_RETRIBUTION_TITLE',
		[256]	= 'PRIEST_SPEC_DISCIPLINE_TITLE',
		[257]	= 'PRIEST_SPEC_HOLY_TITLE',
		[258]	= 'PRIEST_SPEC_SHADOW_TITLE',
		[259]	= 'ROGUE_SPEC_ASSASSINATION_TITLE',
		[260]	= 'ROGUE_SPEC_COMBAT_TITLE',
		[261]	= 'ROGUE_SPEC_SUBTLETY_TITLE',
		[262]	= 'SHAMAN_SPEC_ELEMENTAL_TITLE',
		[263]	= 'SHAMAN_SPEC_ENHANCEMENT_TITLE',
		[264]	= 'SHAMAN_SPEC_RESTORATION_TITLE',
		[265]	= 'WARLOCK_AFFLICTION_TITLE',
		[266]	= 'WARLOCK_DEMONOLOGY_TITLE',
		[267]	= 'WARLOCK_DESTRUCTION_TITLE',
		[71]	= 'WARRIOR_SPEC_ARMS_TITLE',
		[72]	= 'WARRIOR_SPEC_FURY_TITLE',
		[73]	= 'WARRIOR_SPEC_PROTECTION_TITLE',
	}

	local localizedClass = _G.LOCALIZED_CLASS_NAMES_MALE
	for classFile, name in pairs(E.ClassName) do
		local localized = localizedClass and localizedClass[classFile]
		if type(localized) == 'string' and localized ~= '' then
			E.ClassName[classFile] = localized
		else
			E.ClassName[classFile] = name
		end
	end

	for id, name in pairs(EnglishSpecName) do
		local localized = _G[SpecNameGlobal[id]]
		if type(localized) == 'string' and localized ~= '' then
			E.SpecName[id] = localized
		else
			E.SpecName[id] = name
		end
	end
end

function E:RemoveExtraSpaces(str)
	return gsub(str, '     +', '    ')	--Replace all instances of 5+ spaces with only 4 spaces.
end

function E:GetDateTime(localTime, unix)
	if not localTime then -- try to properly handle realm time
		local dateTable = date('*t', time())

		local hours, minutes = GetGameTime() -- realm time since it doesnt match ServerTimeLocal
		dateTable.hour = hours
		dateTable.min = minutes

		if unix then
			return time(dateTable)
		else
			return dateTable
		end
	elseif unix then
		return time()
	else
		return date('*t', time())
	end
end

function E:ClassColor(class, usePriestColor)
	if not class then return end

	local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class]) or _G.RAID_CLASS_COLORS[class]
	if type(color) ~= 'table' then return end

	if not color.colorStr then
		color.colorStr = E:RGBToHex(color.r, color.g, color.b, 'ff')
	elseif strlen(color.colorStr) == 6 then
		color.colorStr = 'ff'..color.colorStr
	end

	if usePriestColor and class == 'PRIEST' and tonumber(color.colorStr, 16) > tonumber(E.PriestColors.colorStr, 16) then
		return E.PriestColors
	else
		return color
	end
end

function E:GetQualityColor(quality)
	return _G.ITEM_QUALITY_COLORS[quality]
end

function E:GetAddOnDisplayName(name)
	if not name then return end

	local first = strsub(name, 1, 1)
	if first == '+' or first == '!' or first == '_' then
		return strsub(name, 2)
	end

	return name
end

function E:SyncFauxScrollBar(scrollBar, offset, maxOffset, rowHeight)
	if not scrollBar then return end

	scrollBar:SetMinMaxValues(0, maxOffset * rowHeight)
	scrollBar:SetValueStep(rowHeight)
	scrollBar:SetShown(maxOffset > 0)

	if abs(scrollBar:GetValue() - offset * rowHeight) > 0.01 then
		scrollBar:SetValue(offset * rowHeight)
	end
end

function E:GetItemQualityColor(quality)
	if quality == -1 then
		return 0, 0, 0
	end

	local color = quality and E:GetQualityColor(quality)
	if color then
		return color.r, color.g, color.b
	else
		return unpack(E.media.bordercolor)
	end
end

-- taken from https://gitlab.com/Tsoukie/classicapi/-/blob/main/!!!ClassicAPI/Util/C_CreatureInfo.lua
local classData = {
	[1] = 'WARRIOR',
	[2] = 'PALADIN',
	[3] = 'HUNTER',
	[4] = 'ROGUE',
	[5] = 'PRIEST',
	[6] = 'DEATHKNIGHT',
	[7] = 'SHAMAN',
	[8] = 'MAGE',
	[9] = 'WARLOCK',
	[11] = 'DRUID',
}

local function GetClassInfo(classID)
	local classFile = classData[classID]
	if not classFile then return end

	return {
		className = _G.LOCALIZED_CLASS_NAMES_MALE[classFile],
		classFile = classFile,
		classID = classID
	}
end

do
	local classByID = {}
	local classByFile = {}

	E.ClassInfoByID = classByID
	E.ClassInfoByFile = classByFile

	for index = 1, 11 do
		local info = GetClassInfo(index)
		if info then
			classByID[info.classID] = info
			classByFile[info.classFile] = info
		end
	end
end

do -- other non-english locales require this
	E.UnlocalizedClasses = {}

	local classMale = _G.LOCALIZED_CLASS_NAMES_MALE
	local classFemale = _G.LOCALIZED_CLASS_NAMES_FEMALE

	for k, v in pairs(classMale) do E.UnlocalizedClasses[v] = k end
	for k, v in pairs(classFemale) do E.UnlocalizedClasses[v] = k end

	function E:UnlocalizedClassName(className)
		return E.UnlocalizedClasses[className]
	end

	function E:LocalizedClassName(className, unit)
		local gender = (type(unit) == 'number' and unit) or (not unit and E.mygender) or UnitSex(unit)
		return (gender == 3 and classFemale[className]) or classMale[className]
	end
end

function E:GetUnitSpecInfo(unit)
	if not UnitIsPlayer(unit) then return end

	local specID = GetInspectSpecialization(unit)
	local specInfo = specID and E.SpecInfoBySpecID[specID]
	if specInfo then return specInfo end

	E.ScanTooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')
	E.ScanTooltip:SetUnit(unit)

	local _, specLine = TT:GetLevelLine(E.ScanTooltip, 1, true)

	local specText = specLine and specLine.leftText
	if specText then
		return E.SpecInfoBySpecClass[specText]
	end
end

function E:PopulateSpecInfo()
	wipe(E.SpecInfoBySpecID)
	wipe(E.SpecInfoBySpecClass)

	for classFile, specID in next, E.SpecByClass do
		local info = E.ClassInfoByFile[classFile]
		if info then
			local classMale, classFemale = E:LocalizedClassName(classFile, 2), E:LocalizedClassName(classFile, 3)
			for index, id in next, specID do
				local _, libName, _, libIcon, _, role = GetSpecializationInfoByID(id)
				local englishName = EnglishSpecName[id]
				local name = E.SpecName[id] or libName

				local data = {
					id = id,
					index = index,
					classFile = classFile,
					className = info.className,
					classMale = classMale,
					classFemale = classFemale,
					englishName = englishName,
					name = name,
					icon = libIcon,
					role = role
				}

				E.SpecInfoBySpecID[id] = data

				local englishClass = EnglishClassName[classFile]
				if englishName and englishClass then
					E.SpecInfoBySpecClass[englishName..' '..englishClass] = data
				end

				if name then
					if classMale then
						E.SpecInfoBySpecClass[name..' '..classMale] = data
					end

					if classFemale and classFemale ~= classMale then
						E.SpecInfoBySpecClass[name..' '..classFemale] = data
					end
				end
			end
		end
	end
end

do
	function E:ScanTooltipTextures()
		local tt = E.ScanTooltip

		if not tt.gems then
			tt.gems = {}
		else
			wipe(tt.gems)
		end

		for i = 1, 10 do
			local tex = _G['ElvUI_ScanTooltipTexture'..i]
			local texture = tex and tex:IsShown() and tex:GetTexture()
			if texture then
				tt.gems[i] = texture
			end
		end

		return tt.gems
	end
end

do
	function E:GetAuraData(unitToken, index, filter)
		return UnitAura(unitToken, index, filter)
	end

	local function FindAura(key, value, unit, index, filter, ...)
		local name, _, _, _, _, _, _, _, _, spellID = ...

		if not name then
			return
		elseif key == 'name' and value == name then
			return ...
		elseif key == 'spellID' and value == spellID then
			return ...
		else
			index = index + 1
			return FindAura(key, value, unit, index, filter, E:GetAuraData(unit, index, filter))
		end
	end

	function E:GetAuraByID(unit, spellID, filter)
		return FindAura('spellID', spellID, unit, 1, filter, E:GetAuraData(unit, 1, filter))
	end

	function E:GetAuraByName(unit, name, filter)
		return FindAura('name', name, unit, 1, filter, E:GetAuraData(unit, 1, filter))
	end
end

function E:GetThreatStatusColor(status, nothreat)
	local color = ElvUF.colors.threat[status]
	if color then
		return color.r, color.g, color.b, color.a or 1
	elseif nothreat then
		if status == -1 then -- how or why?
			return 1, 1, 1, 1
		else
			return .7, .7, .7, 1
		end
	end
end

function E:GetPlayerRole()
	local tank, healer, damage = UnitGroupRolesAssigned('player')
	local role = (tank and 'TANK') or (healer and 'HEALER') or (damage and 'DAMAGER') or NONE

	return (role ~= NONE and role) or E.myspecRole or NONE
end

function E:CheckRole()
	E.myspec = GetSpecialization()

	if E.myspec then
		E.myspecID, E.myspecName, E.myspecDesc, E.myspecIcon, E.myspecBackground, E.myspecRole = GetSpecializationInfo(E.myspec)
	end

	E.myrole = E:GetPlayerRole()
end

function E:GetDifficultyText(isRaid)
	local dungID = GetDungeonDifficulty()
	local raidID = GetRaidDifficulty()

    local id = isRaid and raidID or dungID
	local diffID = isRaid and (id > 2 and 2 or 1) or id
    local playerDiff = _G['PLAYER_DIFFICULTY'..diffID]
    local diffSize = gsub(_G[(isRaid and 'RAID_DIFFICULTY' or 'DUNGEON_DIFFICULTY')..id], '%D+', '')
    local difficulty = format('%s %s', playerDiff, diffSize)

    return difficulty
end

function E:IsDispellableByMe(debuffType)
	if not E.DispelClasses[E.myclass] then return end
	if E.DispelClasses[E.myclass][debuffType] then return true end
end

function E:UpdateDispelColor(debuffType, r, g, b)
	local color = DebuffColors[debuffType]
	if color then
		color.r, color.g, color.b = r, g, b
	end

	local db = E.db.general.debuffColors[debuffType]
	if db then
		db.r, db.g, db.b = r, g, b
	end
end

function E:UpdateDispelColors()
	local colors = E.db.general.debuffColors
	for debuffType, db in next, colors do
		local color = DebuffColors[debuffType]
		if color then
			E:UpdateClassColor(db)
			color.r, color.g, color.b = db.r, db.g, db.b
		end
	end
end

do
	local callbacks = {}
	function E:CustomClassColorUpdate()
		for func in next, callbacks do
			func()
		end
	end

	function E:CustomClassColorRegister(func)
		callbacks[func] = true
	end

	function E:CustomClassColorUnregister(func)
		callbacks[func] = nil
	end

	function E:CustomClassColorNotify()
		local changed = E:UpdateCustomClassColors()
		if changed then
			E:CustomClassColorUpdate()
		end
	end

	function E:CustomClassColorClassToken(className)
		return E:UnlocalizedClassName(className)
	end

	local meta = {
		__index = {
			RegisterCallback = E.CustomClassColorRegister,
			UnregisterCallback = E.CustomClassColorUnregister,
			NotifyChanges = E.CustomClassColorNotify,
			GetClassToken = E.CustomClassColorClassToken
		}
	}

	function E:SetupCustomClassColors()
		local object = CopyTable(_G.RAID_CLASS_COLORS)

		_G.CUSTOM_CLASS_COLORS = setmetatable(object, meta)

		return object
	end

	function E:UpdateCustomClassColor(classTag, r, g, b)
		local colors = _G.CUSTOM_CLASS_COLORS
		local color = colors and colors[classTag]
		if color then
			color.r, color.g, color.b = r, g, b
			color.colorStr = E:RGBToHex(r, g, b, 'ff')
		end

		if classTag == E.myclass then
			E.myClassColor = E:ClassColor(E.myclass, true)
		end

		local db = E.db.general.classColors[classTag]
		if db then
			db.r, db.g, db.b = r, g, b
		end

		E:CustomClassColorNotify()
	end

	function E:UpdateCustomClassColors()
		if not E.private.general.classColors then return end

		local custom = _G.CUSTOM_CLASS_COLORS or E:SetupCustomClassColors()
		local colors, changed = E.db.general.classColors

		for classTag, db in next, colors do
			local color, r, g, b = custom[classTag], db.r, db.g, db.b
			if color and (color.r ~= r or color.g ~= g or color.b ~= b) then
				color.r, color.g, color.b = r, g, b
				color.colorStr = E:RGBToHex(r, g, b, 'ff')

				if classTag == E.myclass then
					E.myClassColor = E:ClassColor(E.myclass, true)
				end

				changed = true
			end
		end

		return changed
	end
end

do
	local Masque = E.Libs.Masque
	local MasqueGroupState = {}
	local MasqueGroupToTableElement = {
		['ActionBars'] = {'actionbar', 'actionbars'},
		['Pet Bar'] = {'actionbar', 'petBar'},
		['Stance Bar'] = {'actionbar', 'stanceBar'},
		['Buffs'] = {'auras', 'buffs'},
		['Debuffs'] = {'auras', 'debuffs'},
	}

	function E:MasqueCallback(Group, _, _, _, _, Disabled)
		if not E.private then return end
		local element = MasqueGroupToTableElement[Group]
		if element then
			if Disabled then
				if E.private[element[1]].masque[element[2]] and MasqueGroupState[Group] == 'enabled' then
					E.private[element[1]].masque[element[2]] = false
					E:StaticPopup_Show('CONFIG_RL')
				end
				MasqueGroupState[Group] = 'disabled'
			else
				MasqueGroupState[Group] = 'enabled'
			end
		end
	end

	if Masque then
		Masque:Register('ElvUI', E.MasqueCallback)
	end
end

do
	local CPU_USAGE = {}
	local function CompareCPUDiff(showall, minCalls)
		local greatestUsage, greatestCalls, greatestName, newName, newFunc
		local greatestDiff, lastModule, mod, usage, calls, diff = 0

		for name, oldUsage in pairs(CPU_USAGE) do
			newName, newFunc = strmatch(name, '^([^:]+):(.+)$')
			if not newFunc then
				E:Print('CPU_USAGE:', name, newFunc)
			else
				if newName ~= lastModule then
					mod = E:GetModule(newName, true) or E
					lastModule = newName
				end
				usage, calls = GetFunctionCPUUsage(mod[newFunc], true)
				diff = usage - oldUsage
				if showall and (calls > minCalls) then
					E:Print('Name('..name..') Calls('..calls..') Diff('..(diff > 0 and format('%.3f', diff) or 0)..')')
				end
				if (diff > greatestDiff) and calls > minCalls then
					greatestName, greatestUsage, greatestCalls, greatestDiff = name, usage, calls, diff
				end
			end
		end

		if greatestName then
			E:Print(greatestName..' had the CPU usage of: '..(greatestUsage > 0 and format('%.3f', greatestUsage) or 0)..'ms. And has been called '..greatestCalls..' times.')
		else
			E:Print('CPU Usage: No CPU Usage differences found.')
		end

		wipe(CPU_USAGE)
	end

	function E:GetTopCPUFunc(msg)
		if not GetCVarBool('scriptProfile') then
			E:Print('For `/cpuusage` to work, you need to enable script profiling via: `/console scriptProfile 1` then reload. Disable after testing by setting it back to 0.')
			return
		end

		local module, showall, delay, minCalls = strmatch(msg, '^(%S+)%s*(%S*)%s*(%S*)%s*(.*)$')
		local checkCore, mod = (not module or module == '') and 'E'

		showall = (showall == 'true' and true) or false
		delay = (delay == 'nil' and nil) or tonumber(delay) or 5
		minCalls = (minCalls == 'nil' and nil) or tonumber(minCalls) or 15

		wipe(CPU_USAGE)
		if module == 'all' then
			for moduName, modu in pairs(self.modules) do
				for funcName, func in pairs(modu) do
					if (funcName ~= 'GetModule') and (type(func) == 'function') then
						CPU_USAGE[moduName..':'..funcName] = GetFunctionCPUUsage(func, true)
					end
				end
			end
		else
			if not checkCore then
				mod = self:GetModule(module, true)
				if not mod then
					self:Print(module..' not found, falling back to checking core.')
					mod, checkCore = self, 'E'
				end
			else
				mod = self
			end
			for name, func in pairs(mod) do
				if (name ~= 'GetModule') and type(func) == 'function' then
					CPU_USAGE[(checkCore or module)..':'..name] = GetFunctionCPUUsage(func, true)
				end
			end
		end

		self:Delay(delay, CompareCPUDiff, showall, minCalls)
		self:Print('Calculating CPU Usage differences (module: '..(checkCore or module)..', showall: '..tostring(showall)..', minCalls: '..tostring(minCalls)..', delay: '..tostring(delay)..')')
	end
end

function E:RegisterObjectForVehicleLock(object, originalParent)
	if not object or not originalParent then
		E:Print('Error. Usage: RegisterObjectForVehicleLock(object, originalParent)')
		return
	end

	object = _G[object] or object
	--Entering/Exiting vehicles will often happen in combat.
	--For this reason we cannot allow protected objects.
	if object.IsProtected and object:IsProtected() then
		E:Print('Error. Object is protected and cannot be changed in combat.')
		return
	end

	--Check if we are already in a vehicles
	if UnitHasVehicleUI('player') then
		object:SetParent(E.HiddenFrame)
	end

	--Add object to table
	E.VehicleLocks[object] = originalParent
end

function E:UnregisterObjectForVehicleLock(object)
	if not object then
		E:Print('Error. Usage: UnregisterObjectForVehicleLock(object)')
		return
	end

	object = _G[object] or object
	--Check if object was registered to begin with
	if not E.VehicleLocks[object] then return end

	--Change parent of object back to original parent
	local originalParent = E.VehicleLocks[object]
	if originalParent then
		object:SetParent(originalParent)
	end

	--Remove object from table
	E.VehicleLocks[object] = nil
end

function E:EnterVehicleHideFrames(_, unit)
	if unit ~= 'player' then return end
	for object in pairs(E.VehicleLocks) do
		object:SetParent(E.HiddenFrame)
	end
end

function E:ExitVehicleShowFrames(_, unit)
	if unit ~= 'player' then return end
	for object, originalParent in pairs(E.VehicleLocks) do
		object:SetParent(originalParent)
	end
end

function E:RequestBGInfo()
	RequestBattlefieldScoreData()
end

do
	local watchedInfo = {}
	function E:GetWatchedFactionInfo()
		watchedInfo.name, watchedInfo.reaction, watchedInfo.currentReactionThreshold, watchedInfo.nextReactionThreshold, watchedInfo.currentStanding = GetWatchedFactionInfo()
		return watchedInfo
	end
end

function E:PLAYER_ENTERING_WORLD()
	E:CheckRole()

	if not ElvDB.DisabledAddOns then
		ElvDB.DisabledAddOns = {}
	end

	E:CheckIncompatible()

	if not E.MediaUpdated then
		E:UpdateMedia()
		E.MediaUpdated = true
	end

	if E.db.general.lockCameraDistanceMax then
		E:SetCVar('cameraDistanceMax', E.db.general.cameraDistanceMax)
	end

	local _, instanceType = GetInstanceInfo()
	if instanceType == 'pvp' then
		E.BGTimer = E:ScheduleRepeatingTimer('RequestBGInfo', 5)
		E:RequestBGInfo()
	elseif E.BGTimer then
		E:CancelTimer(E.BGTimer)
		E.BGTimer = nil
	end
end

function E:PLAYER_REGEN_ENABLED()
	if E.ShowOptions then
		E:ToggleOptions()

		E.ShowOptions = nil
	end
end

do
	local function NoCombat()
		UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.2, 0.2, 1.0)
	end

	function E:PLAYER_REGEN_DISABLED()
		local wasShown

		if IsAddOnLoaded('ElvUI_Options') then
			local ACD = E.Libs.AceConfigDialog
			if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI then
				ACD:Close('ElvUI')
				wasShown = true
			end
		end

		if E.CreatedMovers then
			for name in pairs(E.CreatedMovers) do
				local mover = _G[name]
				if mover and mover:IsShown() then
					mover:Hide()
					wasShown = true
				end
			end
		end

		if wasShown then
			NoCombat()
		end
	end

	function E:AlertCombat()
		local combat = InCombatLockdown()
		if combat then NoCombat() end
		return combat
	end
end

function E:XPIsLevelMax()
	return IsLevelAtEffectiveMaxLevel(E.mylevel) or IsXPUserDisabled()
end

function E:GetUnitBattlefieldFaction(unit)
	local englishFaction, localizedFaction = UnitFactionGroup(unit)

	-- this might be a rated BG or wargame and if so the player's faction might be altered
	if unit == 'player' and UnitInBattleground(unit) then
		englishFaction = PLAYER_FACTION_GROUP[GetBattlefieldArenaFaction()]
		localizedFaction = (englishFaction == 'Alliance' and FACTION_ALLIANCE) or FACTION_HORDE
	end

	return englishFaction, localizedFaction
end

function E:PLAYER_LEVEL_UP(_, level)
	E.mylevel = level
end

function E:PositionGameMenuButton()
	local button = GameMenuFrame.ElvUI
	if button then
		button:SetFormattedText('%sElvUI|r', E.media.hexvaluecolor)

		local _, relTo, _, _, offY = GameMenuButtonLogout:GetPoint()
		if relTo ~= button then
			button:ClearAllPoints()
			button:Point('TOPLEFT', relTo, 'BOTTOMLEFT', 0, -1)

			GameMenuButtonLogout:ClearAllPoints()
			GameMenuButtonLogout:Point('TOPLEFT', button, 'BOTTOMLEFT', 0, offY)
		end
	end
end

function E:ClickGameMenu()
	E:ToggleOptions() -- we already prevent it from opening in combat

	if not InCombatLockdown() then
		HideUIPanel(GameMenuFrame)
	end
end

function E:ScaleGameMenu()
	GameMenuFrame:SetScale(E.db.general.gameMenuScale or 1)
end

function E:SetupGameMenu()
	if GameMenuFrame.ElvUI then return end

	local button = CreateFrame('Button', 'ElvUI_GameMenuButton', GameMenuFrame, 'GameMenuButtonTemplate')
	button:SetScript('OnClick', E.ClickGameMenu)
	GameMenuFrame.ElvUI = button

	E:ScaleGameMenu()

	button:Size(GameMenuButtonLogout:GetSize())
	button:Point('TOPLEFT', GameMenuButtonAddons, 'BOTTOMLEFT', 0, -1)
	hooksecurefunc(GameMenuFrame, 'Show', function() E:PositionGameMenuButton() end)

	if GameMenuFrame_UpdateVisibleButtons then
		hooksecurefunc('GameMenuFrame_UpdateVisibleButtons', function()
			local button = GameMenuFrame.ElvUI
			if button and GameMenuButtonLogout then
				GameMenuFrame:Height(GameMenuFrame:GetHeight() + GameMenuButtonLogout:GetHeight() - 4)
			end
		end)
	end
end

function E:CompatibleTooltip(tt) -- knock off compatibility
	if tt.GetTooltipData then return end -- real support exists

	local info = { name = tt:GetName(), lines = {} }
	info.leftTextName = info.name .. 'TextLeft'
	info.rightTextName = info.name .. 'TextRight'

	tt.GetTooltipData = function()
		wipe(info.lines)

		for i = 1, tt:NumLines() do
			local left = _G[info.leftTextName..i]
			local leftText = left and left:GetText() or nil

			local right = _G[info.rightTextName..i]
			local rightText = right and right:GetText() or nil

			tinsert(info.lines, i, { lineIndex = i, leftText = leftText, rightText = rightText })
		end

		return info
	end
end

function E:GetClassCoords(classFile, crop, get)
	local t = _G.CLASS_ICON_TCOORDS[classFile]
	if not t then return 0, 1, 0, 1 end

	if get then
		return t
	elseif type(crop) == 'number' then
		return t[1] + crop, t[2] - crop, t[3] + crop, t[4] - crop
	elseif crop then
		return t[1] + 0.022, t[2] - 0.025, t[3] + 0.022, t[4] - 0.025
	else
		return t[1], t[2], t[3], t[4]
	end
end

function E:CropRatio(width, height, mult)
	if not mult then mult = 0.5 end

	local left, right, top, bottom = E:GetTexCoords()

	if type(width) ~= 'number' or type(height) ~= 'number' or width <= 0 or height <= 0 then
		return left, right, top, bottom
	end

	local ratio = width / height
	if ratio > 1 then
		local trimAmount = (1 - (1 / ratio)) * mult
		top = top + trimAmount
		bottom = bottom - trimAmount
	else
		local trimAmount = (1 - ratio) * mult
		left = left + trimAmount
		right = right - trimAmount
	end

	return left, right, top, bottom
end

function E:ScanTooltip_UnitInfo(unit)
	E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	E.ScanTooltip:SetUnit(unit)
	E.ScanTooltip:Show()

	return E.ScanTooltip:GetTooltipData()
end

function E:ScanTooltip_InventoryInfo(unit, slot)
	E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	E.ScanTooltip:SetInventoryItem(unit, slot)
	E.ScanTooltip:Show()

	return E.ScanTooltip:GetTooltipData()
end

function E:ScanTooltip_HyperlinkInfo(link)
	E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	E.ScanTooltip:SetHyperlink(link)
	E.ScanTooltip:Show()

	return E.ScanTooltip:GetTooltipData()
end

function E:GroupRosterUpdate()
	local isInRaid = IsInRaid()
	E.IsInGroup = isInRaid or IsInGroup()

	wipe(E.GroupRoles)

	for _, units in next, E.GroupUnitsByRole do
		wipe(units)
	end

	if E.IsInGroup then
		local group = (isInRaid and 'raid') or 'party'
		local members = (isInRaid and GetNumGroupMembers()) or GetNumSubgroupMembers()

		for i = 1, members do
			local unit = group..i
			local guid = UnitGUID(unit)
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(unit)
			local role = guid and ((GetPartyAssignment('MAINTANK', unit) and 'TANK') or (isTank and 'TANK') or (isHealer and 'HEALER') or (isDamage and 'DAMAGER') or 'NONE')
			if role == 'NONE' then
				role = LGT_ROLES[LGT:GetUnitRole(unit)] or 'NONE'
			end

			if role then
				E.GroupRoles[guid] = role
				E.GroupUnitsByRole[role][guid] = unit
			end
		end
	end
end

function E:LoadAPI()
	E:RegisterEvent('PARTY_MEMBERS_CHANGED', 'GroupRosterUpdate')
	E:RegisterEvent('RAID_ROSTER_UPDATE', 'GroupRosterUpdate')
	E:RegisterEvent('PLAYER_LEVEL_UP')
	E:RegisterEvent('PLAYER_ENTERING_WORLD')
	E:RegisterEvent('PLAYER_REGEN_ENABLED')
	E:RegisterEvent('PLAYER_REGEN_DISABLED')
	E:RegisterEvent('DISPLAY_SIZE_CHANGED', 'PixelScaleChanged')

	LGT.RegisterCallback(E, 'LibGroupTalents_Update', 'GroupRosterUpdate')
	LGT.RegisterCallback(E, 'LibGroupTalents_RoleChange', 'GroupRosterUpdate')

	E:GroupRosterUpdate()
	E:SetupGameMenu()
	E:UpdateTexCoords() -- update cropIcon texCoords
	E:PopulateSpecInfo()

	E:CompatibleTooltip(E.ScanTooltip)
	E:CompatibleTooltip(E.ConfigTooltip)
	E:CompatibleTooltip(E.SpellBookTooltip)
	E:CompatibleTooltip(_G.GameTooltip)

	E.ScanTooltip.GetUnitInfo = E.ScanTooltip_UnitInfo
	E.ScanTooltip.GetHyperlinkInfo = E.ScanTooltip_HyperlinkInfo
	E.ScanTooltip.GetInventoryInfo = E.ScanTooltip_InventoryInfo

	E:RegisterEvent('SPELL_UPDATE_USABLE', 'CheckRole')
	E:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', 'CheckRole')
	E:RegisterEvent('PLAYER_TALENT_UPDATE', 'CheckRole')
	E:RegisterEvent('CHARACTER_POINTS_CHANGED', 'CheckRole')
	E:RegisterEvent('UNIT_INVENTORY_CHANGED', 'CheckRole')
	E:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'CheckRole')
	E:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckRole') -- role is not recalculated on entering an instance otherwise

	E:RegisterEvent('UNIT_ENTERED_VEHICLE', 'EnterVehicleHideFrames')
	E:RegisterEvent('UNIT_EXITED_VEHICLE', 'ExitVehicleShowFrames')
end
