local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local select, next, ipairs, pairs, tonumber, getmetatable = select, next, ipairs, pairs, tonumber, getmetatable
local abs, floor, max, min = math.abs, math.floor, math.max, math.min
local find, format, gmatch, lower, sub, trim = string.find, string.format, string.gmatch, string.lower, string.sub, string.trim
local tinsert, tremove, sort, wipe = table.insert, table.remove, table.sort, table.wipe
local gsub = string.gsub
local CreateFrame = CreateFrame

local GearManagerDialog = GearManagerDialog
local GetAttackPowerForStat = GetAttackPowerForStat
local GetBlockChance = GetBlockChance
local GetCombatRating = GetCombatRating
local GetCombatRatingBonus = GetCombatRatingBonus
local GetCompanionCooldown = GetCompanionCooldown
local GetCompanionInfo = GetCompanionInfo
local GetCritChance = GetCritChance
local GetCritChanceFromAgility = GetCritChanceFromAgility
local GetCurrentTitle = GetCurrentTitle
local GetCursorPosition = GetCursorPosition
local GetDodgeChance = GetDodgeChance
local GetEquipmentSetInfo = GetEquipmentSetInfo
local GetEquipmentSetInfoByName = GetEquipmentSetInfoByName
local GetInventorySlotInfo = GetInventorySlotInfo
local GetMaxCombatRatingBonus = GetMaxCombatRatingBonus
local GetNumCompanions = GetNumCompanions
local GetNumEquipmentSets = GetNumEquipmentSets
local GetNumTitles = GetNumTitles
local GetParryChance = GetParryChance
local GetScreenHeightScale = GetScreenHeightScale
local GetShieldBlock = GetShieldBlock
local GetSpellCritChanceFromIntellect = GetSpellCritChanceFromIntellect
local GetTitleName = GetTitleName
local GetUnitHealthModifier = GetUnitHealthModifier
local GetUnitHealthRegenRateFromSpirit = GetUnitHealthRegenRateFromSpirit
local GetUnitManaRegenRateFromSpirit = GetUnitManaRegenRateFromSpirit
local GetUnitMaxHealthModifier = GetUnitMaxHealthModifier
local GetUnitPowerModifier = GetUnitPowerModifier

local IsTitleKnown = IsTitleKnown
local PlaySound = PlaySound
local SetCVar = SetCVar
local SetPortraitTexture = SetPortraitTexture
local UnitAttackSpeed = UnitAttackSpeed
local UnitClass = UnitClass
local UnitDamage = UnitDamage
local UnitHasMana = UnitHasMana

local UnitLevel = UnitLevel
local UnitRace = UnitRace
local UnitResistance = UnitResistance
local UnitStat = UnitStat

local GetItemInfo = GetItemInfo
local GetNumFactions = GetNumFactions
local GetPetHappiness = GetPetHappiness
local HasPetUI = HasPetUI
local UnitFactionGroup = UnitFactionGroup
local hooksecurefunc = hooksecurefunc

local CharacterRangedDamageFrame_OnEnter = CharacterRangedDamageFrame_OnEnter
local CharacterSpellCritChance_OnEnter = CharacterSpellCritChance_OnEnter
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local GameTooltip_Hide = GameTooltip_Hide
local GearManagerDialogSaveSet_OnClick = GearManagerDialogSaveSet_OnClick

local PaperDollFrame_ClearIgnoredSlots = PaperDollFrame_ClearIgnoredSlots
local PaperDollFrame_SetArmor = PaperDollFrame_SetArmor
local PaperDollFrame_SetAttackPower = PaperDollFrame_SetAttackPower
local PaperDollFrame_SetAttackSpeed = PaperDollFrame_SetAttackSpeed
local PaperDollFrame_SetDamage = PaperDollFrame_SetDamage
local PaperDollFrame_SetDefense = PaperDollFrame_SetDefense
local PaperDollFrame_SetExpertise = PaperDollFrame_SetExpertise
local PaperDollFrame_SetManaRegen = PaperDollFrame_SetManaRegen
local PaperDollFrame_SetRangedAttackPower = PaperDollFrame_SetRangedAttackPower
local PaperDollFrame_SetRangedAttackSpeed = PaperDollFrame_SetRangedAttackSpeed
local PaperDollFrame_SetRangedCritChance = PaperDollFrame_SetRangedCritChance
local PaperDollFrame_SetRangedDamage = PaperDollFrame_SetRangedDamage
local PaperDollFrame_SetSpellBonusHealing = PaperDollFrame_SetSpellBonusHealing
local PaperDollFrame_SetSpellCritChance = PaperDollFrame_SetSpellCritChance
local PaperDollFrame_SetSpellHaste = PaperDollFrame_SetSpellHaste
local PetPaperDollFrameCompanionFrame = PetPaperDollFrameCompanionFrame
local PetPaperDollFrame_FindCompanionIndex = PetPaperDollFrame_FindCompanionIndex
local ARMOR_PER_AGILITY = ARMOR_PER_AGILITY
local BLOCK_CHANCE = BLOCK_CHANCE
local BLOCK_PER_STRENGTH = BLOCK_PER_STRENGTH
local CR_BLOCK = CR_BLOCK
local CR_BLOCK_TOOLTIP = CR_BLOCK_TOOLTIP
local CR_CRIT_MELEE = CR_CRIT_MELEE
local CR_CRIT_MELEE_TOOLTIP = CR_CRIT_MELEE_TOOLTIP
local CR_CRIT_TAKEN_MELEE = CR_CRIT_TAKEN_MELEE
local CR_CRIT_TAKEN_RANGED = CR_CRIT_TAKEN_RANGED
local CR_CRIT_TAKEN_SPELL = CR_CRIT_TAKEN_SPELL
local CR_DODGE = CR_DODGE
local CR_DODGE_TOOLTIP = CR_DODGE_TOOLTIP
local CR_HIT_MELEE = CR_HIT_MELEE
local CR_HIT_RANGED = CR_HIT_RANGED
local CR_HIT_SPELL = CR_HIT_SPELL
local CR_PARRY = CR_PARRY
local CR_PARRY_TOOLTIP = CR_PARRY_TOOLTIP
local DAMAGE_PER_SECOND = DAMAGE_PER_SECOND

local DODGE_CHANCE = DODGE_CHANCE
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local GREEN_FONT_COLOR = GREEN_FONT_COLOR
local GREEN_FONT_COLOR_CODE = GREEN_FONT_COLOR_CODE
local HEALTH_PER_STAMINA = HEALTH_PER_STAMINA
local HIGHLIGHT_FONT_COLOR_CODE = HIGHLIGHT_FONT_COLOR_CODE
local MANA_PER_INTELLECT = MANA_PER_INTELLECT
local MANA_REGEN_FROM_SPIRIT = MANA_REGEN_FROM_SPIRIT
local MAX_EQUIPMENT_SETS_PER_PLAYER = MAX_EQUIPMENT_SETS_PER_PLAYER
local MELEE_CRIT_CHANCE = MELEE_CRIT_CHANCE
local NONE = NONE
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local PAPERDOLLFRAME_TOOLTIP_FORMAT = PAPERDOLLFRAME_TOOLTIP_FORMAT
local PARRY_CHANCE = PARRY_CHANCE
local PET_BONUS_TOOLTIP_INTELLECT = PET_BONUS_TOOLTIP_INTELLECT
local PET_BONUS_TOOLTIP_RESISTANCE = PET_BONUS_TOOLTIP_RESISTANCE
local PET_BONUS_TOOLTIP_STAMINA = PET_BONUS_TOOLTIP_STAMINA
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local RED_FONT_COLOR_CODE = RED_FONT_COLOR_CODE
local RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER = RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER
local RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER = RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER
local RESILIENCE_TOOLTIP = RESILIENCE_TOOLTIP
local RESISTANCE_EXCELLENT = RESISTANCE_EXCELLENT
local RESISTANCE_FAIR = RESISTANCE_FAIR
local RESISTANCE_GOOD = RESISTANCE_GOOD
local RESISTANCE_NONE = RESISTANCE_NONE
local RESISTANCE_POOR = RESISTANCE_POOR
local RESISTANCE_TOOLTIP_SUBTEXT = RESISTANCE_TOOLTIP_SUBTEXT
local RESISTANCE_VERYGOOD = RESISTANCE_VERYGOOD
local STAT_ATTACK_POWER = STAT_ATTACK_POWER
local STAT_BLOCK = STAT_BLOCK
local STAT_BLOCK_TOOLTIP = STAT_BLOCK_TOOLTIP
local STAT_DODGE = STAT_DODGE
local STAT_FORMAT = STAT_FORMAT
local STAT_PARRY = STAT_PARRY
local STAT_RESILIENCE = STAT_RESILIENCE


local C_PlayerInfo = C_PlayerInfo

local CHARACTERFRAME_EXPANDED_WIDTH = 252

local SCROLL_WIDTH_SIRUS_STATS = 145
local SCROLL_WIDTH_SIRUS_STATS_CHILD = 245

local STATCATEGORY_MOVING_INDENT = 4
local MOVING_STAT_CATEGORY

local PAPERDOLL_SIDEBARS = {
	{
		name = L["Character Stats"],
		frame = "CharacterStatsPane",
		icon = nil,
		texCoords = {0.109375, 0.890625, 0.09375, 0.90625}
	},
	{
		name = L["Titles"],
		frame = "PaperDollTitlesPane",
		icon = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs",
		texCoords = {0.01562500, 0.53125000, 0.32421875, 0.46093750}
	},
	{
		name = L["Equipment Manager"],
		frame = "PaperDollEquipmentManagerPane",
		icon = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs",
		texCoords = {0.01562500, 0.53125000, 0.46875000, 0.60546875}
	}
}

V.character = V.character or {}
V.character.character = V.character.character or {}
V.character.character.player = V.character.character.player or {}
V.character.character.player.STRENGTHEN = false

local PAPERDOLL_STATINFO = {
	["STRENGTHEN1"] = {
		updateFunc = function(statFrame, unit) S:StrengthenStat(statFrame, unit, 1) end
	},
	["STRENGTHEN2"] = {
		updateFunc = function(statFrame, unit) S:StrengthenStat(statFrame, unit, 2) end
	},
	["STRENGTHEN3"] = {
		updateFunc = function(statFrame, unit) S:StrengthenStat(statFrame, unit, 3) end
	},
	["STRENGTHEN4"] = {
		updateFunc = function(statFrame, unit) S:StrengthenStat(statFrame, unit, 4) end
	},
	["STRENGTHEN5"] = {
		updateFunc = function(statFrame, unit) S:StrengthenStat(statFrame, unit, 5) end
	},
	["STRENGTHEN6"] = {
		updateFunc = function(statFrame, unit) S:StrengthenStat(statFrame, unit, 6) end
	},
	["STRENGTHEN7"] = {
		updateFunc = function(statFrame, unit) S:StrengthenStat(statFrame, unit, 7) end
	},

	["STRENGTH"] = {
		updateFunc = function(statFrame, unit) S:SetStat(statFrame, unit, 1) end
	},
	["AGILITY"] = {
		updateFunc = function(statFrame, unit) S:SetStat(statFrame, unit, 2) end
	},
	["STAMINA"] = {
		updateFunc = function(statFrame, unit) S:SetStat(statFrame, unit, 3) end
	},
	["INTELLECT"] = {
		updateFunc = function(statFrame, unit) S:SetStat(statFrame, unit, 4) end
	},
	["SPIRIT"] = {
		updateFunc = function(statFrame, unit) S:SetStat(statFrame, unit, 5) end
	},

	["MELEE_DAMAGE"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetDamage(statFrame, unit) end,
		updateFunc2 = function(statFrame) CharacterDamageFrame_OnEnter(statFrame) end
	},
	["MELEE_DPS"] = {
		updateFunc = function(statFrame, unit) S:SetMeleeDPS(statFrame, unit) end
	},
	["MELEE_AP"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetAttackPower(statFrame, unit) end
	},
	["MELEE_ATTACKSPEED"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetAttackSpeed(statFrame, unit) end
	},
	["HITCHANCE"] = {
		updateFunc = function(statFrame) PaperDollFrame_SetRating(statFrame, CR_HIT_MELEE) end
	},
	["CRITCHANCE"] = {
		updateFunc = function(statFrame, unit) S:SetMeleeCritChance(statFrame, unit) end
	},
	["EXPERTISE"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetExpertise(statFrame, unit) end
	},

	["RANGED_COMBAT1"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedDamage(statFrame, unit) end,
		updateFunc2 = function(statFrame) CharacterRangedDamageFrame_OnEnter(statFrame) end
	},
	["RANGED_COMBAT2"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedAttackSpeed(statFrame, unit) end
	},
	["RANGED_COMBAT3"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedAttackPower(statFrame, unit) end
	},
	["RANGED_COMBAT4"] = {
		updateFunc = function(statFrame) PaperDollFrame_SetRating(statFrame, CR_HIT_RANGED) end
	},
	["RANGED_COMBAT5"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRangedCritChance(statFrame, unit) end
	},

	["SPELL_COMBAT1"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetSpellBonusDamage(statFrame, unit) end,
		updateFunc2 = function(statFrame) CharacterSpellBonusDamage_OnEnter(statFrame) end
	},
	["SPELL_COMBAT2"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetSpellBonusHealing(statFrame, unit) end
	},
	["SPELL_COMBAT3"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetRating(statFrame, CR_HIT_SPELL) end
	},
	["SPELL_COMBAT4"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetSpellCritChance(statFrame, unit) end,
		updateFunc2 = function(statFrame) CharacterSpellCritChance_OnEnter(statFrame) end
	},
	["SPELL_COMBAT5"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetSpellHaste(statFrame, unit) end
	},
	["SPELL_COMBAT6"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetManaRegen(statFrame, unit) end
	},

	["DEFENSES1"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetArmor(statFrame, unit) end
	},
	["DEFENSES2"] = {
		updateFunc = function(statFrame, unit) PaperDollFrame_SetDefense(statFrame, unit) end
	},
	["DEFENSES3"] = {
		updateFunc = function(statFrame, unit) S:SetDodge(statFrame, unit) end
	},
	["DEFENSES4"] = {
		updateFunc = function(statFrame, unit) S:SetParry(statFrame, unit) end
	},
	["DEFENSES5"] = {
		updateFunc = function(statFrame, unit) S:SetBlock(statFrame, unit) end
	},
	["DEFENSES6"] = {
		updateFunc = function(statFrame, unit) S:SetResilience(statFrame, unit) end
	},

	["ARCANE"] = {
		updateFunc = function(statFrame, unit) S:SetResistance(statFrame, unit, 6) end
	},
	["FIRE"] = {
		updateFunc = function(statFrame, unit) S:SetResistance(statFrame, unit, 2) end
	},
	["FROST"] = {
		updateFunc = function(statFrame, unit) S:SetResistance(statFrame, unit, 4) end
	},
	["NATURE"] = {
		updateFunc = function(statFrame, unit) S:SetResistance(statFrame, unit, 3) end
	},
	["SHADOW"] = {
		updateFunc = function(statFrame, unit) S:SetResistance(statFrame, unit, 5) end
	},
}

local PAPERDOLL_STATCATEGORIES = {
	["STRENGTHEN"] = {
		id = 1,
		stats = {
			"STRENGTHEN1",
			"STRENGTHEN2",
			"STRENGTHEN3",
			"STRENGTHEN4",
			"STRENGTHEN5",
			"STRENGTHEN6",
			"STRENGTHEN7",
		}
	},
	["BASE_STATS"] = {
		id = 2,
		stats = {
			"STRENGTH",
			"AGILITY",
			"STAMINA",
			"INTELLECT",
			"SPIRIT"
		}
	},
	["MELEE_COMBAT"] = {
		id = 3,
		stats = {
			"MELEE_DAMAGE",
			"MELEE_DPS",
			"MELEE_AP",
			"MELEE_ATTACKSPEED",
			"HITCHANCE",
			"CRITCHANCE",
			"EXPERTISE"
		}
	},
	["RANGED_COMBAT"] = {
		id = 4,
		stats = {
			"RANGED_COMBAT1",
			"RANGED_COMBAT2",
			"RANGED_COMBAT3",
			"RANGED_COMBAT4",
			"RANGED_COMBAT5"
		}
	},
	["SPELL_COMBAT"] = {
		id = 5,
		stats = {
			"SPELL_COMBAT1",
			"SPELL_COMBAT2",
			"SPELL_COMBAT3",
			"SPELL_COMBAT4",
			"SPELL_COMBAT5",
			"SPELL_COMBAT6"
		}
	},
	["DEFENSES"] = {
		id = 6,
		stats = {
			"DEFENSES1",
			"DEFENSES2",
			"DEFENSES3",
			"DEFENSES4",
			"DEFENSES5",
			"DEFENSES6"
		}
	},
	["RESISTANCE"] = {
		id = 7,
		stats = {
			"ARCANE",
			"FIRE",
			"FROST",
			"NATURE",
			"SHADOW"
		}
	},
}

local PAPERDOLL_STATCATEGORY_DEFAULTORDER = {
	"STRENGTHEN",
	"BASE_STATS",
	"MELEE_COMBAT",
	"RANGED_COMBAT",
	"SPELL_COMBAT",
	"DEFENSES",
	"RESISTANCE"
}
local classTextFormat = "%2$s%4$s (%3$s)|r %1$s-го уровня"

local function CenterCharacterHeader()
	local width = CharacterFrame:GetWidth()
	if not width or width <= 0 then return end

	CharacterNamesText:ClearAllPoints()
	CharacterNamesText:SetSize(width, 16)
	CharacterNamesText:SetPoint("TOP", CharacterFrame, "TOP", 0, -5)
	CharacterNamesText:SetJustifyH("CENTER")
	CharacterNamesText:SetWordWrap(false)

	CharacterLevelText:ClearAllPoints()
	CharacterLevelText:SetSize(width, 16)
	CharacterLevelText:SetPoint("TOP", CharacterNamesText, "BOTTOM", 0, -2)
	CharacterLevelText:SetJustifyH("CENTER")
	CharacterLevelText:SetWordWrap(false)
end

function S:PaperDollFrame_SetLevel()
	local _, specName = E:GetTalentSpecInfo()
	local classDisplayName, class = UnitClass("player")
	local classColor = E:ClassColor(class) or RAID_CLASS_COLORS[class]
	local classColorString = format("|cFF%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)

	if specName == NONE then
		CharacterLevelText:SetFormattedText(PLAYER_LEVEL, UnitLevel("player"), classColorString, classDisplayName)
	else
		CharacterLevelText:SetFormattedText(classTextFormat, UnitLevel("player"), classColorString, specName, classDisplayName)
	end

	CenterCharacterHeader()
end

local function PlusButton_OnShow(self)
	self:GetParent().Value:SetPoint("RIGHT", -22, 0)
end

local function PlusButton_OnHide(self)
	self:GetParent().Value:SetPoint("RIGHT", -3, 0)
end

local function PlusButton_OnEnable(self)
	self.Texture:SetVertexColor(1, 1, 1)
end

local function PlusButton_OnDisable(self)
	self.Texture:SetVertexColor(0.6, 0.6, 0.6)
end

local function StatFrame_OnEnter()
	PaperDollStatTooltip("player")
end


local function OnPlusButtonClick(frame,click)
	local bonusStatIndex = frame.id
	if IsModifiedClick("SHIFT") then
		C_PlayerInfo.InceaseBonusStat(bonusStatIndex, 10)
	elseif IsModifiedClick("CTRL") then
		C_PlayerInfo.InceaseBonusStat(bonusStatIndex, 100)
	elseif IsModifiedClick("ALT") then
		local _, _, availableUps = C_PlayerInfo.GetBonusStatPointInfo()
		C_PlayerInfo.InceaseBonusStat(bonusStatIndex, availableUps)
	else
		C_PlayerInfo.InceaseBonusStat(bonusStatIndex, 1)
	end
end

local function OnPlusButtonEnter(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	GameTooltip:SetText(PAPERDOLLFRAME_UPS, 1.0, 1.0, 1.0)
	GameTooltip:AddLine(string.format(PAPERDOLLFRAME_UPS_TOOLTIP_HELP_1, frame.multiplier), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:AddLine(PAPERDOLLFRAME_UPS_TOOLTIP_HELP_2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:AddLine(PAPERDOLLFRAME_UPS_TOOLTIP_HELP_3, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:AddLine(PAPERDOLLFRAME_UPS_TOOLTIP_HELP_4, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:AddLine("При зажатой Alt вложить все.", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:Show()
end

function S:CharacterStatFrame(button,id)
	if button.isCharacterStatSkinned then return end
	button.isCharacterStatSkinned = true
	button:Size(SCROLL_WIDTH_SIRUS_STATS, 15)

	button.Label = button:CreateFontString("$parentLabel", "OVERLAY", "GameFontNormalSmall")
	button.Label:SetJustifyH("LEFT")
	button.Label:SetSize(122, 0)
	button.Label:SetPoint("LEFT", 7, 0)

	button.Value = button:CreateFontString("$parentStatText", "OVERLAY", "GameFontHighlightSmall")
	button.Value:SetJustifyH("RIGHT")
	button.Value:SetPoint("RIGHT", -3, 0)

	button.Plus = CreateFrame("Button", nil, button)
	button.Plus.id = id
	local _, _, _, multiplier = C_PlayerInfo.GetBonusStatInfo(id)
	button.Plus.multiplier = multiplier
	button.Plus:Hide()
	button.Plus:Size(19)
	button.Plus:SetPoint("RIGHT", -3, 0)

	button.Plus.Texture = button.Plus:CreateTexture()
	button.Plus.Texture:SetAllPoints()
	button.Plus.Texture:SetTexture(E.Media.Textures.Plus)

	button.Plus:SetScript("OnClick", OnPlusButtonClick)
	button.Plus:SetScript("OnShow", PlusButton_OnShow)
	button.Plus:SetScript("OnHide", PlusButton_OnHide)
	button.Plus:SetScript("OnEnter", OnPlusButtonEnter)
	button.Plus:SetScript("OnLeave", GameTooltip_Hide)
	button.Plus:SetScript("OnEnable", PlusButton_OnEnable)
	button.Plus:SetScript("OnDisable", PlusButton_OnDisable)

	button:SetScript("OnEnter", StatFrame_OnEnter)
	button:SetScript("OnLeave", GameTooltip_Hide)
end

function S:PaperDollSidebarTab(button)
	if button.isCharacterSidebarSkinned then return end
	button.isCharacterSidebarSkinned = true
	button:Size(33, 35)

	button:SetTemplate("Default")

	local sidebarID = button.sidebarID or button:GetID()
	local sidebar = PAPERDOLL_SIDEBARS[sidebarID]
	if not sidebar then return end
	button.sidebarID = sidebarID

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetInside()
	button.Icon:SetTexture(sidebar.icon)
	local tcoords = sidebar.texCoords
	button.Icon:SetTexCoord(tcoords[1], tcoords[2], tcoords[3], tcoords[4])

	button.Hider = button:CreateTexture(nil, "OVERLAY")
	button.Hider:SetTexture(0.4, 0.4, 0.4, 0.4)
	button.Hider:SetInside()

	button.Highlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.Highlight:SetTexture(1, 1, 1, 0.3)
	button.Highlight:SetInside()

	button:SetScript("OnClick", function(self)
		local id = self.sidebarID
		if id and PAPERDOLL_SIDEBARS[id] then
			S:PaperDollFrame_SetSidebar(self, id)
			PlaySound("igMainMenuOption")
		end
	end)

	button:SetScript("OnEnter", function(self)
		local sidebar = PAPERDOLL_SIDEBARS[self.sidebarID]
		if sidebar then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(sidebar.name, 1, 1, 1)
		end
	end)

	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end

function S:CharacterFrame_Collapse(sizeOnly)
	if self.skinEnabled then
		CharacterFrame.backdrop:Width(341)

		S:SetBackdropHitRect(PaperDollFrame, CharacterFrame.backdrop)
		S:SetBackdropHitRect(PetPaperDollFrame, CharacterFrame.backdrop)
	else
		CharacterFrame:Width(384)

		S:SetBackdropHitRect(PaperDollFrame)
		S:SetBackdropHitRect(PetPaperDollFrame)
	end

	S:SetUIPanelWindowInfo(CharacterFrame, "width")

	if sizeOnly then return end

	CharacterFrame.Expanded = false

	S:SetNextPrevButtonDirection(CharacterFrameExpandButton, "right")

	for i = 1, #PAPERDOLL_SIDEBARS do
		_G[PAPERDOLL_SIDEBARS[i].frame]:Hide()
	end

	PaperDollSidebarTabs:Hide()
end

function S:CharacterFrame_Expand(sizeOnly)
	if self.skinEnabled then
		CharacterFrame.backdrop:Width(341 + CHARACTERFRAME_EXPANDED_WIDTH)

		S:SetBackdropHitRect(PaperDollFrame, CharacterFrame.backdrop)
		S:SetBackdropHitRect(PetPaperDollFrame, CharacterFrame.backdrop)
	else
		CharacterFrame:Width(352 + CHARACTERFRAME_EXPANDED_WIDTH)

		S:SetBackdropHitRect(PaperDollFrame)
		S:SetBackdropHitRect(PetPaperDollFrame)
	end

	S:SetUIPanelWindowInfo(CharacterFrame, "width")

	if sizeOnly then return end

	CharacterFrame.Expanded = true

	S:SetNextPrevButtonDirection(CharacterFrameExpandButton, "left")

	if PaperDollFrame:IsShown() and PaperDollFrame.currentSideBar then
		CharacterStatsPane:Hide()
		PaperDollFrame.currentSideBar:Show()
	else
		CharacterStatsPane:Show()
	end

	S:PaperDollFrame_UpdateSidebarTabs()
	PaperDollSidebarTabs:Show()
end

local StatCategoryFrames = {}

function S:SetLabelAndText(statFrame, label, text, isPercentage)
	statFrame.Label:SetFormattedText(STAT_FORMAT, label)
	if isPercentage then
		statFrame.Value:SetFormattedText("%.2F%%", text)
	else
		statFrame.Value:SetText(text)
	end
end

local StrengthenStats = {SPELL_STAT1_NAME, SPELL_STAT2_NAME, SPELL_STAT3_NAME, SPELL_STAT4_NAME, SPELL_STAT5_NAME, PAPERDOLLFRAME_UPS_SPELL_POWER, ATTACK_POWER}

function S:StrengthenStat(statFrame, unit, statIndex)
	statFrame.Label:SetText(StrengthenStats[statIndex])

	local _, value, baseValue, multiplier = C_PlayerInfo.GetBonusStatInfo(statIndex)

	if value then
		if statIndex == 6 then
			statFrame.Value:SetFormattedText(value > 0 and "%.0f (+|cff00FF00%.1f|r)" or "%.0f (+|cff00FF00%.0f|r)", value, baseValue)
		else
			if value == floor(value) and baseValue == floor(baseValue) then
				statFrame.Value:SetFormattedText("%d (+|cff00FF00%d|r)", value, baseValue)
			else
				statFrame.Value:SetFormattedText("%.1f (+|cff00FF00%.1f|r)", value, baseValue)
			end
		end
	else
		statFrame.Value:SetText("0")
	end

	local _, _, availableUps = C_PlayerInfo.GetBonusStatPointInfo()

	if availableUps == 0 then
		statFrame.Plus:Disable()
	else
		statFrame.Plus:Enable()
	end
	statFrame.Plus.multiplier = multiplier
	statFrame.Plus:Show()
end

function S:SetStat(statFrame, unit, statIndex)
	local stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex)
	local statName = _G["SPELL_STAT"..statIndex.."_NAME"]
	statFrame.Label:SetFormattedText(STAT_FORMAT, statName)

	local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName).." "
	if posBuff == 0 and negBuff == 0 then
		statFrame.Value:SetText(effectiveStat)
		statFrame.tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE
	else
		tooltipText = tooltipText..effectiveStat
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText.." ("..(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE
		end
		if posBuff > 0 then
			tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE
		end
		if negBuff < 0 then
			tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE
		end
		if posBuff > 0 or negBuff < 0 then
			tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE
		end
		statFrame.tooltip = tooltipText

		if negBuff < 0 then
			statFrame.Value:SetText(RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE)
		else
			statFrame.Value:SetText(GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE)
		end
	end
	statFrame.tooltip2 = _G["DEFAULT_STAT"..statIndex.."_TOOLTIP"]

	if unit == "player" then
		local _, unitClass = UnitClass("player")
		if statIndex == 1 then
			local attackPower = GetAttackPowerForStat(statIndex, effectiveStat)
			statFrame.tooltip2 = format(statFrame.tooltip2, attackPower)

			if unitClass == "WARRIOR" or unitClass == "SHAMAN" or unitClass == "PALADIN" then
				statFrame.tooltip2 = statFrame.tooltip2.."\n"..format(STAT_BLOCK_TOOLTIP, max(0, effectiveStat * BLOCK_PER_STRENGTH - 10))
			end
		elseif statIndex == 3 then
			local baseStam = min(20, effectiveStat)
			local moreStam = effectiveStat - baseStam
			statFrame.tooltip2 = format(statFrame.tooltip2, (baseStam + (moreStam * HEALTH_PER_STAMINA)) * GetUnitMaxHealthModifier("player"))
			local petStam = ComputePetBonus("PET_BONUS_STAM", effectiveStat)

			if petStam > 0 then
				statFrame.tooltip2 = statFrame.tooltip2.."\n"..format(PET_BONUS_TOOLTIP_STAMINA, petStam)
			end
		elseif statIndex == 2 then
			local attackPower = GetAttackPowerForStat(statIndex, effectiveStat)

			if attackPower > 0 then
				statFrame.tooltip2 = format(STAT_ATTACK_POWER, attackPower)..format(statFrame.tooltip2, GetCritChanceFromAgility("player"), effectiveStat * ARMOR_PER_AGILITY)
			else
				statFrame.tooltip2 = format(statFrame.tooltip2, GetCritChanceFromAgility("player"), effectiveStat * ARMOR_PER_AGILITY)
			end
		elseif statIndex == 4 then
			local baseInt = min(20, effectiveStat)
			local moreInt = effectiveStat - baseInt

			if UnitHasMana("player") then
				statFrame.tooltip2 = format(statFrame.tooltip2, baseInt + moreInt * MANA_PER_INTELLECT, GetSpellCritChanceFromIntellect("player"))
			else
				statFrame.tooltip2 = nil
			end

			local petInt = ComputePetBonus("PET_BONUS_INT", effectiveStat)
			if petInt > 0 then
				if not statFrame.tooltip2 then
					statFrame.tooltip2 = ""
				end

				statFrame.tooltip2 = statFrame.tooltip2.."\n"..format(PET_BONUS_TOOLTIP_INTELLECT, petInt)
			end
		elseif statIndex == 5 then
			statFrame.tooltip2 = format(statFrame.tooltip2, GetUnitHealthRegenRateFromSpirit("player"))

			if UnitHasMana("player") then
				local regen = GetUnitManaRegenRateFromSpirit("player")
				regen = floor(regen * 5.0)
				statFrame.tooltip2 = statFrame.tooltip2.."\n"..format(MANA_REGEN_FROM_SPIRIT, regen)
			end
		end
	elseif unit == "pet" then
		if statIndex == 1 then
			local attackPower = effectiveStat - 20
			statFrame.tooltip2 = format(statFrame.tooltip2, attackPower)
		elseif statIndex == 3 then
			local expectedHealthGain = (((stat - posBuff - negBuff) - 20) * 10 + 20) * GetUnitHealthModifier("pet")
			local realHealthGain = ((effectiveStat - 20) * 10 + 20) * GetUnitHealthModifier("pet")
			local healthGain = (realHealthGain - expectedHealthGain) * GetUnitMaxHealthModifier("pet")
			statFrame.tooltip2 = format(statFrame.tooltip2, healthGain)
		elseif statIndex == 2 then
			local newLineIndex = find(statFrame.tooltip2, "|n") + 1
			statFrame.tooltip2 = sub(statFrame.tooltip2, 1, newLineIndex)
			statFrame.tooltip2 = format(statFrame.tooltip2, GetCritChanceFromAgility("pet"))
		elseif statIndex == 4 then
			if UnitHasMana("pet") then
				local manaGain = ((effectiveStat - 20) * 15 + 20) * GetUnitPowerModifier("pet")
				statFrame.tooltip2 = format(statFrame.tooltip2, manaGain, GetSpellCritChanceFromIntellect("pet"))
			else
				local newLineIndex = find(statFrame.tooltip2, "|n") + 2
				statFrame.tooltip2 = sub(statFrame.tooltip2, newLineIndex)
				statFrame.tooltip2 = format(statFrame.tooltip2, GetSpellCritChanceFromIntellect("pet"))
			end
		elseif statIndex == 5 then
			statFrame.tooltip2 = format(statFrame.tooltip2, GetUnitHealthRegenRateFromSpirit("pet"))
			if UnitHasMana("pet") then
				statFrame.tooltip2 = statFrame.tooltip2.."\n"..format(MANA_REGEN_FROM_SPIRIT, GetUnitManaRegenRateFromSpirit("pet"))
			end
		end
	end
	statFrame:Show()
end

local ResistanceNames = {
	[6] = STRING_SCHOOL_ARCANE,
	[2] = STRING_SCHOOL_FIRE,
	[4] = STRING_SCHOOL_FROST,
	[3] = STRING_SCHOOL_NATURE,
	[5] = STRING_SCHOOL_SHADOW
}

function S:SetResistance(statFrame, unit, resistanceIndex)
	local base, resistance, positive, negative = UnitResistance(unit, resistanceIndex)
	local petBonus = ComputePetBonus("PET_BONUS_RES", resistance)

	local resistanceName = _G["RESISTANCE"..resistanceIndex.."_NAME"]
	local resistanceIconCode = "|TInterface\\PaperDollInfoFrame\\SpellSchoolIcon"..(resistanceIndex + 1)..":16:16:2:2:16:16:2:14:2:14|t"
	statFrame.Label:SetText(resistanceIconCode.." "..format(STAT_FORMAT, ResistanceNames[resistanceIndex]))
	local text = _G[statFrame:GetName().."StatText"]
	PaperDollFormatStat(resistanceName, base, positive, negative, statFrame, text)
	statFrame.tooltip = resistanceIconCode.." "..HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, resistanceName).." "..resistance..FONT_COLOR_CODE_CLOSE

	if positive ~= 0 or negative ~= 0 then
		statFrame.tooltip = statFrame.tooltip.." ( "..HIGHLIGHT_FONT_COLOR_CODE..base
		if positive > 0 then
			statFrame.tooltip = statFrame.tooltip..GREEN_FONT_COLOR_CODE.." +"..positive
		end
		if negative < 0 then
			statFrame.tooltip = statFrame.tooltip.." "..RED_FONT_COLOR_CODE..negative
		end
		statFrame.tooltip = statFrame.tooltip..FONT_COLOR_CODE_CLOSE.." )"
	end

	local resistanceLevel
	local unitLevel = UnitLevel(unit)
	unitLevel = max(unitLevel, 20)

	local magicResistanceNumber = resistance / unitLevel
	if magicResistanceNumber > 5 then
		resistanceLevel = RESISTANCE_EXCELLENT
	elseif magicResistanceNumber > 3.75 then
		resistanceLevel = RESISTANCE_VERYGOOD
	elseif magicResistanceNumber > 2.5 then
		resistanceLevel = RESISTANCE_GOOD
	elseif magicResistanceNumber > 1.25 then
		resistanceLevel = RESISTANCE_FAIR
	elseif magicResistanceNumber > 0 then
		resistanceLevel = RESISTANCE_POOR
	else
		resistanceLevel = RESISTANCE_NONE
	end
	statFrame.tooltip2 = format(RESISTANCE_TOOLTIP_SUBTEXT, _G["RESISTANCE_TYPE"..resistanceIndex], unitLevel, resistanceLevel)

	if unitLevel == 80 then
		statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(RESISTANCE_TOOLTIP_SUBTEXT2, 100 / ((((unitLevel * 675.5) / 83) + unitLevel) / resistance + 1));
	end
	if petBonus > 0 then
		statFrame.tooltip2 = statFrame.tooltip2.."\n"..format(PET_BONUS_TOOLTIP_RESISTANCE, petBonus)
	end
end

function S:SetDodge(statFrame, unit)
	if unit ~= "player" then
		statFrame:Hide()
		return
	end

	local chance = GetDodgeChance()
	S:SetLabelAndText(statFrame, STAT_DODGE, chance, 1)
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE).." "..format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE
	statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE))
	statFrame:Show()
end

function S:SetBlock(statFrame, unit)
	if unit ~= "player" then
		statFrame:Hide()
		return
	end

	local chance = GetBlockChance()
	S:SetLabelAndText(statFrame, STAT_BLOCK, chance, 1)
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE).." "..format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE
	statFrame.tooltip2 = format(CR_BLOCK_TOOLTIP, GetCombatRating(CR_BLOCK), GetCombatRatingBonus(CR_BLOCK), GetShieldBlock())
	statFrame:Show()
end

function S:SetParry(statFrame, unit)
	if unit ~= "player" then
		statFrame:Hide()
		return
	end

	local chance = GetParryChance()
	S:SetLabelAndText(statFrame, STAT_PARRY, chance, 1)
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE).." "..format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE
	statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY))
	statFrame:Show()
end

function S:SetResilience(statFrame, unit)
	if unit ~= "player" then
		statFrame:Hide()
		return
	end

	local melee = GetCombatRating(CR_CRIT_TAKEN_MELEE)
	local ranged = GetCombatRating(CR_CRIT_TAKEN_RANGED)
	local spell = GetCombatRating(CR_CRIT_TAKEN_SPELL)

	local minResilience = min(melee, ranged)
	minResilience = min(minResilience, spell)

	local lowestRating
	if melee == minResilience then
		lowestRating = CR_CRIT_TAKEN_MELEE
	elseif ranged == minResilience then
		lowestRating = CR_CRIT_TAKEN_RANGED
	else
		lowestRating = CR_CRIT_TAKEN_SPELL
	end

	local maxRatingBonus = GetMaxCombatRatingBonus(lowestRating)
	local lowestRatingBonus = GetCombatRatingBonus(lowestRating)

	S:SetLabelAndText(statFrame, STAT_RESILIENCE, minResilience)

	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RESILIENCE).." "..minResilience..FONT_COLOR_CODE_CLOSE
	statFrame.tooltip2 = format(RESILIENCE_TOOLTIP, lowestRatingBonus, min(lowestRatingBonus * RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER, maxRatingBonus), lowestRatingBonus * RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER)
	local onslaughtRating = GetOnslaughtRating();
	if onslaughtRating < 0 then
		statFrame.tooltip2 = statFrame.tooltip2 .. "\n\n" .. format(CR_ONSLAUGHT_RATING_INCREASE_TOOLTIP, onslaughtRating, onslaughtRating);
	else
		statFrame.tooltip2 = statFrame.tooltip2 .. "\n\n" .. format(CR_ONSLAUGHT_RATING_REDUSE_TOOLTIP, onslaughtRating, onslaughtRating);
	end
	statFrame:Show()
end

function S:SetMeleeDPS(statFrame, unit)
	statFrame.Label:SetFormattedText(STAT_FORMAT, L["Damage Per Second"])
	local speed, offhandSpeed = UnitAttackSpeed(unit)
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage(unit)

	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg

	local baseDamage = (minDamage + maxDamage) * 0.5
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent
	local totalBonus = (fullDamage - baseDamage)
	local damagePerSecond = (max(fullDamage, 1) / speed)

	local colorPos = "|cff20ff20"
	local colorNeg = "|cffff2020"
	local text

	if totalBonus < 0.1 and totalBonus > -0.1 then
		totalBonus = 0.0
	end

	if totalBonus == 0 then
		text = format("%.1F", damagePerSecond)
	else
		local color
		if totalBonus > 0 then
			color = colorPos
		else
			color = colorNeg
		end
		text = color..format("%.1F", damagePerSecond).."|r"
	end

	if offhandSpeed then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent
		local offhandDamagePerSecond = (max(offhandFullDamage, 1) / offhandSpeed)
		local offhandTotalBonus = (offhandFullDamage - offhandBaseDamage)

		if offhandTotalBonus < 0.1 and offhandTotalBonus > -0.1 then
			offhandTotalBonus = 0.0
		end
		local separator = " / "
		if damagePerSecond > 1000 and offhandDamagePerSecond > 1000 then
			separator = "/"
		end
		if offhandTotalBonus == 0 then
			text = text..separator..format("%.1F", offhandDamagePerSecond)
		else
			local color
			if offhandTotalBonus > 0 then
				color = colorPos
			else
				color = colorNeg
			end
			text = text..separator..color..format("%.1F", offhandDamagePerSecond).."|r"
		end
	end

	statFrame.Value:SetText(text)
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..DAMAGE_PER_SECOND..FONT_COLOR_CODE_CLOSE
	statFrame:Show()
end

function S:SetMeleeCritChance(statFrame, unit)
	if unit ~= "player" then
		statFrame:Hide()
		return
	end

	statFrame.Label:SetFormattedText(STAT_FORMAT, MELEE_CRIT_CHANCE)
	local critChance = GetCritChance()
	statFrame.Value:SetFormattedText("%.2F%%", critChance)
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MELEE_CRIT_CHANCE).." "..format("%.2F%%", critChance)..FONT_COLOR_CODE_CLOSE
	statFrame.tooltip2 = format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE))
end

local function PaperDollFrame_CollapseStatCategory(categoryFrame)
	if not categoryFrame.collapsed then
		categoryFrame.collapsed = true
		categoryFrame.Toolbar.Background:Hide()
		if categoryFrame.ResetStatButton then
			categoryFrame.ResetStatButton:Hide()
		end
		local index = 1
		while categoryFrame.Stats[index] do
			categoryFrame.Stats[index]:Hide()
			index = index + 1
		end
		categoryFrame:Height(18)
		S:PaperDollFrame_UpdateStatScrollChildHeight()
	end
end

local function PaperDollFrame_ExpandStatCategory(categoryFrame)
	if categoryFrame.collapsed then
		categoryFrame.collapsed = false
		categoryFrame.Toolbar.Background:Show()
		S:PaperDollFrame_UpdateStatCategory(categoryFrame)
		S:PaperDollFrame_UpdateStatScrollChildHeight()
	end
end

local function StrengthenCategory_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local total, maxPoints = C_PlayerInfo.GetBonusStatPointInfo()
	GameTooltip:SetText(PAPERDOLLFRAME_UPS_TOOLTIP_1, 1, 1, 1)
	GameTooltip:AddLine(format(PAPERDOLLFRAME_UPS_TOOLTIP_2, total or 0), 1, .82, 0, 1)
	GameTooltip:AddLine(format(PAPERDOLLFRAME_UPS_TOOLTIP_3, maxPoints or 0), 1, .82, 0, 1)
	GameTooltip:Show()
end

local function StrengthenCategoryReset_OnClick(self)
	C_PlayerInfo.ResetBonusStats()
end

local function StrengthenCategoryReset_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(RESET, 1, 1, 1)
	local cost = C_PlayerInfo.GetResetBonusStatsCost()
	if cost and cost > 0 then
		SetTooltipMoney(GameTooltip, cost)
	end
	GameTooltip:AddLine("Сбросить все очки усилений", 1, 0.82, 0)
	GameTooltip:Show()
end
function S:PaperDollFrame_UpdateStatCategory(categoryFrame)
	if not categoryFrame.Category then categoryFrame:Hide() return end

	local categoryInfo = PAPERDOLL_STATCATEGORIES[categoryFrame.Category]
	if categoryInfo == PAPERDOLL_STATCATEGORIES["RESISTANCE"] then
		categoryFrame.NameText:SetText(L["Resistance"])
	elseif categoryInfo == PAPERDOLL_STATCATEGORIES["STRENGTHEN"] then
		local _, _, available = C_PlayerInfo.GetBonusStatPointInfo()
		categoryFrame.NameText:SetFormattedText(PAPERDOLLFRAME_UPS_AVAILABLE, available or 0)
		categoryFrame.Toolbar:SetScript("OnEnter", StrengthenCategory_OnEnter)
		categoryFrame.Toolbar:SetScript("OnLeave", GameTooltip_Hide)

		if not categoryFrame.ResetStatButton then
			categoryFrame.ResetStatButton = CreateFrame("Button", nil, categoryFrame)
			categoryFrame.ResetStatButton:Size(14)
			categoryFrame.ResetStatButton:Point("TOPRIGHT", categoryFrame, "TOPRIGHT", -10, -5)
			categoryFrame.ResetStatButton:SetFrameLevel(categoryFrame.Toolbar:GetFrameLevel() + 1)

			categoryFrame.ResetStatButton.Icon = categoryFrame.ResetStatButton:CreateTexture(nil, "ARTWORK")
			categoryFrame.ResetStatButton.Icon:SetAllPoints()
			categoryFrame.ResetStatButton.Icon:SetTexture([[Interface\Buttons\UI-RefreshButton]])
			categoryFrame.ResetStatButton.Icon:SetDesaturated(true)

			categoryFrame.ResetStatButton:SetScript("OnClick", StrengthenCategoryReset_OnClick)
			categoryFrame.ResetStatButton:SetScript("OnEnter", function(self)
				self.Icon:SetDesaturated(false)
				StrengthenCategoryReset_OnEnter(self)
			end)
			categoryFrame.ResetStatButton:SetScript("OnLeave", function(self)
				self.Icon:SetDesaturated(true)
				GameTooltip_Hide()
			end)
		end
		if categoryFrame.collapsed then
			categoryFrame.ResetStatButton:Hide()
		else
			categoryFrame.ResetStatButton:Show()
		end
	else
		categoryFrame.NameText:SetText(_G["PLAYERSTAT_"..categoryFrame.Category])
	end

	if categoryInfo ~= PAPERDOLL_STATCATEGORIES["STRENGTHEN"] then
		categoryFrame.Toolbar:SetScript("OnEnter", nil)
		categoryFrame.Toolbar:SetScript("OnLeave", nil)
		if categoryFrame.ResetStatButton then
			categoryFrame.ResetStatButton:Hide()
		end
	end

	if categoryFrame.collapsed then return end

	local totalHeight = 25
	local numVisible = 0
	if categoryInfo then
		local prevStatFrame = nil
		for _, stat in next, categoryInfo.stats do
			local statInfo = PAPERDOLL_STATINFO[stat]
			if statInfo then
				local statFrame = categoryFrame.Stats[numVisible + 1]
				if not statFrame then
					statFrame = CreateFrame("Button", "$parentStat"..numVisible + 1, categoryFrame)
					S:CharacterStatFrame(statFrame,numVisible + 1)
					if prevStatFrame then
						statFrame:SetPoint("TOPLEFT", prevStatFrame, "BOTTOMLEFT")
						statFrame:SetPoint("TOPRIGHT", prevStatFrame, "BOTTOMRIGHT")
					end
					categoryFrame.Stats[numVisible + 1] = statFrame
				end
				statFrame:Show()

				if stat ~= "STRENGTHEN" and statFrame.Plus:IsShown() then
					statFrame.Plus:Hide()
				end

				if statInfo.updateFunc2 then
					statFrame:SetScript("OnEnter", PaperDollStatTooltip)
					statFrame:SetScript("OnEnter", statInfo.updateFunc2)
				else
					statFrame:SetScript("OnEnter", PaperDollStatTooltip)
				end

				statFrame.tooltip = nil
				statFrame.tooltip2 = nil
				statFrame.UpdateTooltip = nil
				statFrame:SetScript("OnUpdate", nil)
				statInfo.updateFunc(statFrame, CharacterStatsPane.unit)

				if statFrame:IsShown() then
					numVisible = numVisible + 1
					statFrame:SetID(numVisible)

					totalHeight = totalHeight + statFrame:GetHeight()
					prevStatFrame = statFrame

					if GameTooltip:GetOwner() == statFrame then
						statFrame:GetScript("OnEnter")(statFrame)
					end
				end
			end
		end
	end

	for index = 1, numVisible do
		if index % 2 == 0 then
			local statFrame = categoryFrame.Stats[index]
			if not statFrame.Background then
				statFrame.Background = statFrame:CreateTexture(nil, "BACKGROUND")
				statFrame.Background:SetAllPoints()
				statFrame.Background:SetTexture(E.Media.Textures.Highlight)
				statFrame.Background:SetAlpha(0.3)
			end
		end
	end

	local index = numVisible + 1
	while categoryFrame.Stats[index] do
		categoryFrame.Stats[index]:Hide()
		index = index + 1
	end

	categoryFrame:Height(totalHeight)
end

function S:PaperDollFrame_UpdateStats()
	local index = 1
	while CharacterStatsPane.Categories[index] do
		self:PaperDollFrame_UpdateStatCategory(CharacterStatsPane.Categories[index])
		index = index + 1
	end
	self:PaperDollFrame_UpdateStatScrollChildHeight()
end

function S:PaperDollFrame_UpdateStatScrollChildHeight()
	local index = 1
	local totalHeight = 0
	while CharacterStatsPane.Categories[index] do
		if CharacterStatsPane.Categories[index]:IsShown() then
			totalHeight = totalHeight + CharacterStatsPane.Categories[index]:GetHeight() + 1
		end
		index = index + 1
	end
	CharacterStatsPaneScrollChild:Height(totalHeight + 10)
end

local function FindCategoryById(id)
	for categoryName, category in pairs(PAPERDOLL_STATCATEGORIES) do
		if category.id == id then
			return categoryName
		end
	end
	return nil
end

function S:PaperDoll_InitStatCategories(defaultOrder, orderData, collapsedData, unit)
	local order = defaultOrder

	local orderString = orderData
	local savedOrder = {}
	if orderString and orderString ~= "" then
		for i in gmatch(orderString, "%d+,?") do
			i = gsub(i, ",", "")
			i = tonumber(i)
			if i then
				local categoryName = FindCategoryById(i)
				if categoryName then
					tinsert(savedOrder, categoryName)
				end
			end
		end

		local valid = true
		if #savedOrder == #defaultOrder then
			for _, category1 in ipairs(defaultOrder) do
				local found = false
				for _, category2 in ipairs(savedOrder) do
					if category1 == category2 then
						found = true
						break
					end
				end
				if not found then
					valid = false
					break
				end
			end
		else
			valid = false
		end

		if valid then
			order = savedOrder
		else
			orderData = ""
		end
	end

	wipe(StatCategoryFrames)
	for index = 1, #order do
		local frame = CharacterStatsPane.Categories[index]
		tinsert(StatCategoryFrames, frame)
		frame.Category = order[index]
		frame:Show()

		local categoryInfo = PAPERDOLL_STATCATEGORIES[frame.Category]
		if categoryInfo and collapsedData[frame.Category] then
			PaperDollFrame_CollapseStatCategory(frame)
		else
			PaperDollFrame_ExpandStatCategory(frame)
		end
	end

	local index = #order + 1
	while CharacterStatsPane.Categories[index] do
		CharacterStatsPane.Categories[index]:Hide()
		CharacterStatsPane.Categories[index].Category = nil
		index = index + 1
	end

	CharacterStatsPane.defaultOrder = defaultOrder
	CharacterStatsPane.orderData = orderData
	CharacterStatsPane.collapsedData = collapsedData
	CharacterStatsPane.unit = unit

	self:PaperDoll_UpdateCategoryPositions()
	self:PaperDollFrame_UpdateStats()
end

local function PaperDoll_GetUnitSettings(unit)
	if E.private.character.character and E.private.character.character[unit] then
		return E.private.character.character[unit]
	end
	return E.private.character[unit]
end

local function PaperDoll_SaveStatCategoryOrder()
	if CharacterStatsPane.defaultOrder and #CharacterStatsPane.defaultOrder == #StatCategoryFrames then
		local same = true
		for index = 1, #StatCategoryFrames do
			if StatCategoryFrames[index].Category ~= CharacterStatsPane.defaultOrder[index] then
				same = false
				break
			end
		end
		if same then
			local settings = PaperDoll_GetUnitSettings(CharacterStatsPane.unit)
			if settings then
				settings.orderName = ""
			end
			return
		end
	end

	local string = ""
	for index = 1, #StatCategoryFrames do
		if index ~= #StatCategoryFrames then
			string = string..PAPERDOLL_STATCATEGORIES[StatCategoryFrames[index].Category].id..","
		else
			string = string..PAPERDOLL_STATCATEGORIES[StatCategoryFrames[index].Category].id
		end
	end
	local settings = PaperDoll_GetUnitSettings(CharacterStatsPane.unit)
	if settings then
		settings.orderName = string
	end
end

function S:PaperDoll_UpdateCategoryPositions()
	local prevFrame = nil
	for index = 1, #StatCategoryFrames do
		local frame = StatCategoryFrames[index]
		frame:ClearAllPoints()
	end

	for index = 1, #StatCategoryFrames do
		local frame = StatCategoryFrames[index]

		local xOffset = 0
		if frame == MOVING_STAT_CATEGORY then
			xOffset = STATCATEGORY_MOVING_INDENT
		elseif prevFrame and prevFrame == MOVING_STAT_CATEGORY then
			xOffset = -STATCATEGORY_MOVING_INDENT
		end

		if prevFrame then
			frame:Point("TOPLEFT", prevFrame, "BOTTOMLEFT", 0 + xOffset, -1)
		else
			frame:Point("TOPLEFT", xOffset, 0)
		end
		prevFrame = frame
	end
end

local function StatCategory_OnDragUpdate(self)
	local _, cursorY = GetCursorPosition()
	cursorY = cursorY * GetScreenHeightScale()

	local myIndex = nil
	local insertIndex = nil
	local closestPos

	for index = 1, #StatCategoryFrames + 1 do
		if StatCategoryFrames[index] == self then
			myIndex = index
		end

		local frameY
		if index <= #StatCategoryFrames then
			frameY = StatCategoryFrames[index]:GetTop()
		else
			frameY = StatCategoryFrames[#StatCategoryFrames]:GetBottom()
		end
		frameY = frameY - 8
		if myIndex and index > myIndex then
			frameY = frameY + self:GetHeight()
		end
		if not closestPos or abs(cursorY - frameY) < closestPos then
			insertIndex = index
			closestPos = abs(cursorY - frameY)
		end
	end

	if insertIndex > myIndex then
		insertIndex = insertIndex - 1
	end

	if myIndex ~= insertIndex then
		tremove(StatCategoryFrames, myIndex)
		tinsert(StatCategoryFrames, insertIndex, self)
		S:PaperDoll_UpdateCategoryPositions()
	end
end

local function PaperDollStatCategory_OnDragStart(self)
	MOVING_STAT_CATEGORY = self
	S:PaperDoll_UpdateCategoryPositions()
	GameTooltip:Hide()
	self:SetScript("OnUpdate", StatCategory_OnDragUpdate)

	for i, frame in next, StatCategoryFrames do
		if frame ~= self then
			UIFrameFadeIn(frame, 0.2, 1, 0.6)
		end
	end
end

local function PaperDollStatCategory_OnDragStop(self)
	MOVING_STAT_CATEGORY = nil
	S:PaperDoll_UpdateCategoryPositions()
	self:SetScript("OnUpdate", nil)

	for i, frame in next, StatCategoryFrames do
		if frame ~= self then
			UIFrameFadeOut(frame, 0.2, 0.6, 1)
		end
	end
	PaperDoll_SaveStatCategoryOrder()
end

function S:PaperDollFrame_UpdateSidebarTabs()
	for i = 1, #PAPERDOLL_SIDEBARS do
		local tab = _G["ElvUI_PaperDollSidebarTab"..i]
		local frame = _G[PAPERDOLL_SIDEBARS[i].frame]
		if tab and frame then
			if frame:IsShown() then
				tab.Hider:Hide()
				tab.Highlight:Hide()
			else
				tab.Hider:Show()
				tab.Highlight:Show()
			end
		end
	end
end

local function SidebarFadeOutFinished(frame)
	frame:Hide()
end

local function DisableStrengthenResetButton()
	local resetButton = PaperDollFrameStrengthenFrame and PaperDollFrameStrengthenFrame.ResetButton
	if resetButton then
		resetButton:Hide()
		resetButton:EnableMouse(false)
	end
end

function S:PaperDollFrame_SetSidebar(button, index)
	local sidebar = PAPERDOLL_SIDEBARS[index]
	if not sidebar then return end
	local selectedFrame = _G[sidebar.frame]
	if not selectedFrame then return end
	if not selectedFrame:IsShown() then
		for i = 1, #PAPERDOLL_SIDEBARS do
			local frame = _G[PAPERDOLL_SIDEBARS[i].frame]
			local tab = _G["ElvUI_PaperDollSidebarTab"..i]
			if i ~= index and frame and frame:IsShown() then
				E:UIFrameFadeOut(frame, 0.2, 1, 0)
				if frame.fadeInfo then
					frame.fadeInfo.finishedFunc = SidebarFadeOutFinished
					frame.fadeInfo.finishedArg1 = frame
				end

				if tab then
					tab.Hider:Show()
					tab.Highlight:Show()
				end
			end
		end

		local newFrame = selectedFrame
		newFrame:Show()
		E:UIFrameFadeIn(newFrame, 0.2, 0, 1)
		if newFrame.fadeInfo then
			newFrame.fadeInfo.finishedFunc = nil
			newFrame.fadeInfo.finishedArg1 = nil
		end
		PaperDollFrame.currentSideBar = newFrame
		DisableStrengthenResetButton()

		local selectedTab = _G["ElvUI_PaperDollSidebarTab"..index]
		if selectedTab then
			selectedTab.Hider:Hide()
			selectedTab.Highlight:Hide()
		end
	end
end

function S:PaperDollTitlesPane_UpdateScrollFrame()
	local buttons = PaperDollTitlesPane.buttons
	local playerTitles = PaperDollTitlesPane.titles
	local numButtons = #buttons
	local scrollOffset = HybridScrollFrame_GetOffset(PaperDollTitlesPane)
	local button, playerTitle

	for i = 1, numButtons do
		button = buttons[i]
		playerTitle = playerTitles[i + scrollOffset]

		if playerTitle then
			button:Show()
			button.text:SetText(playerTitle.name)
			button.titleId = playerTitle.id

			if PaperDollTitlesPane.selected == playerTitle.id then
				button.Check:SetAlpha(1)
				button.SelectedBar:Show()
			else
				button.Check:SetAlpha(0)
				button.SelectedBar:Hide()
			end

			if (i + scrollOffset) % 2 == 0 then
				button.Stripe:SetTexture(0.9, 0.9, 1)
				button.Stripe:SetAlpha(0.1)
				button.Stripe:Show()
			else
				button.Stripe:Hide()
			end
		else
			button:Hide()
		end
	end
end

local function PlayerTitleSort(a, b) return a.name < b.name end

function S:PaperDollTitlesPane_Update()
	local playerTitles = {}
	local currentTitle = GetCurrentTitle()
	local titleCount = 1
	local buttons = PaperDollTitlesPane.buttons
	local fontstringText = buttons[1].text

	PaperDollTitlesPane.selected = -1
	playerTitles[1] = {}
	playerTitles[1].name = "       "
	playerTitles[1].id = -1

	for i = 1, GetNumTitles() do
		if IsTitleKnown(i) ~= 0 then
			titleCount = titleCount + 1
			playerTitles[titleCount] = playerTitles[titleCount] or {}
			playerTitles[titleCount].name = trim(GetTitleName(i))
			playerTitles[titleCount].id = i

			if i == currentTitle then
				PaperDollTitlesPane.selected = i
			end

			fontstringText:SetText(playerTitles[titleCount].name)
		end
	end

	sort(playerTitles, PlayerTitleSort)
	playerTitles[1].name = NONE
	PaperDollTitlesPane.titles = playerTitles

	HybridScrollFrame_Update(PaperDollTitlesPane, (titleCount * 22) + 20 , PaperDollTitlesPane:GetHeight())
	if not PaperDollTitlesPane.scrollBar.thumbTexture:IsShown() then
		PaperDollTitlesPane.scrollBar.thumbTexture:Show()
	end

	self:PaperDollTitlesPane_UpdateScrollFrame()
end
function S:PaperDollEquipmentManagerPane_Update()

	local _, setID = GetEquipmentSetInfoByName(PaperDollEquipmentManagerPane.selectedSetName or "")
	if setID then
		PaperDollEquipmentManagerPaneSaveSet:Enable()
		PaperDollEquipmentManagerPaneEquipSet:Enable()
	else
		PaperDollEquipmentManagerPaneSaveSet:Disable()
		PaperDollEquipmentManagerPaneEquipSet:Disable()

		if PaperDollEquipmentManagerPane.selectedSetName then
			PaperDollEquipmentManagerPane.selectedSetName = nil
			PaperDollFrame_ClearIgnoredSlots()
		end
	end

	local numSets = GetNumEquipmentSets()
	local numRows = numSets
	if numSets < MAX_EQUIPMENT_SETS_PER_PLAYER then
		numRows = numRows + 1
	end

	HybridScrollFrame_Update(PaperDollEquipmentManagerPane, numRows * 44 + PaperDollEquipmentManagerPaneEquipSet:GetHeight() + 20 , PaperDollEquipmentManagerPane:GetHeight())
	if not PaperDollEquipmentManagerPane.scrollBar.thumbTexture:IsShown() then
		PaperDollEquipmentManagerPane.scrollBar.thumbTexture:Show()
	end

	local scrollOffset = HybridScrollFrame_GetOffset(PaperDollEquipmentManagerPane)
	local buttons = PaperDollEquipmentManagerPane.buttons
	local selectedName = PaperDollEquipmentManagerPane.selectedSetName
	local name, texture, button

	for i = 1, #buttons do
		button = buttons[i]
		if (i + scrollOffset) <= numRows then
			button:Show()
			button:Enable()

			if (i + scrollOffset) <= numSets then
				name, texture = GetEquipmentSetInfo(i + scrollOffset)
				button.name = name
				button.text:SetText(name)
				button.text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

				if texture then
					button.icon:SetTexture(texture)
				else
					button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				end

				if selectedName and button.name == selectedName then
					button.SelectedBar:Show()
					GearManagerDialog.selectedSet = button
				else
					button.SelectedBar:Hide()
				end
			else
				button.name = nil
				button.text:SetText(L["New Set"])
				button.text:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)
				button.icon:SetTexture("Interface\\Icons\\Spell_ChargePositive")
				button.SelectedBar:Hide()
			end

			if (i + scrollOffset) % 2 == 0 then
				button.Stripe:SetTexture(0.9, 0.9, 1)
				button.Stripe:SetAlpha(0.1)
				button.Stripe:Show()
			else
				button.Stripe:Hide()
			end
		else
			button:Hide()
		end
	end
end

local function SetScrollValue(self, value)
	if self.scrollBar.anim:IsPlaying() then
		self.scrollBar.anim:Stop()
	end
	self.scrollBar.anim.progress:SetChange(value)
	self.scrollBar.anim:Play()
end

local function Animation_OnMouseWheel(self, delta, stepSize)
	if not self.scrollBar:IsVisible() then return end

	self.times = self.times + 1

	if self.direction ~= delta then
		self.direction = delta
		self.times = 1
	end

	local minVal, maxVal = 0, self.range
	stepSize = (stepSize or self.stepSize or self.buttonHeight or self.scrollBar.scrollStep) * self.times

	if delta == 1 then
		SetScrollValue(self, max(minVal, self.scrollBar:GetValue() - stepSize))
	else
		SetScrollValue(self, min(maxVal, self.scrollBar:GetValue() + stepSize))
	end
end

local function CreateSmoothScrollAnimation(scrollBar, hybridScroll)
	local scrollFrame = scrollBar:GetParent()
	scrollFrame.times = 0
	scrollFrame.direction = -1

	scrollBar.anim = CreateAnimationGroup(scrollBar)
	scrollBar.anim.progress = scrollBar.anim:CreateAnimation("Progress")
	scrollBar.anim.progress:SetSmoothing("Out")
	scrollBar.anim.progress:SetDuration(0.5)

	scrollBar.anim.progress:SetScript("OnPlay", function(self)
		if (self:GetChange() >= self.Parent:GetParent().range) or (self:GetChange() <= 0) then
			self.Parent:GetParent().times = self.Parent:GetParent().times - 1
		end
	end)

	scrollBar.anim.progress:SetScript("OnFinished", function(self)
		self.Parent:GetParent().times = 0
	end)

	scrollFrame:SetScript("OnMouseWheel", Animation_OnMouseWheel)

	if not hybridScroll then
		scrollFrame:HookScript("OnScrollRangeChanged", function(self)
			self.range = select(2, self.scrollBar:GetMinMaxValues())
		end)
	end
end

local function PaneFadeFinishedFunc(frame)
	if frame.fadeInfo.mode == "OUT" then
		frame:Hide()
	end
end

local function PaneFadeInfo(frame)
	frame.FadeObject = {
		finishedFuncKeep = true,
		finishedArg1 = frame,
		finishedFunc = PaneFadeFinishedFunc
	}
end

function S:CharacterInit()
	local characterSettings = E.private.character
	if characterSettings and characterSettings.character then
		characterSettings = characterSettings.character
	end
	if not characterSettings or not characterSettings.enable then return end
	characterSettings.player = characterSettings.player or {}
	characterSettings.pet = characterSettings.pet or {}

	PlayerTitleFrame:Kill()
	PlayerTitlePickerFrame:Kill()
	CharacterAttributesFrame:Kill()
	CharacterResistanceFrame:Kill()
	GearManagerToggleButton:Kill()
	DisableStrengthenFrame:Kill()

	PaperDollSidebarTabs:Kill()
	PaperDollFrameStrengthenFrame:SetAlpha(0)
	DisableStrengthenResetButton()

	for i = 1, PaperDollFrameStrengthenFrame:GetNumChildren() do
		local frame = select(i, PaperDollFrameStrengthenFrame:GetChildren())
		if frame then
			frame:Kill()
		end
	end
	local realmName = GetRealmName()
	if realmName == "Sirus x5 - 3.3.5a+" or realmName:match("x4") or realmName:match("x5") or realmName:match("x2") then
		PaperDollFrameStatsFrameLeftCategory:Kill()
		PaperDollFrameStatsFrameRightCategory:Kill()

		if CharacterItemLevelFrame then
			CharacterItemLevelFrame:ClearAllPoints()
			CharacterItemLevelFrame:SetParent(CharacterModelFrame)
			CharacterItemLevelFrame:SetPoint("CENTER",CharacterModelFrame,"CENTER",0,-100)
		end
		PaperDollFrameStatsFrameItemLevelCategory:Kill()
	end






	SendServerMessage("GET_ALL_STRENGTHENING_STATS")


	SetCVar("equipmentManager", 1)

	local sidebarTabs = CreateFrame("Frame", "ElvUI_PaperDollSidebarTabs", PaperDollFrame)
	sidebarTabs:SetSize(SCROLL_WIDTH_SIRUS_STATS, 35)
	sidebarTabs:Point("BOTTOMRIGHT", CharacterFrame, "TOPRIGHT", -4, -48)

	local sidebarTabs3 = CreateFrame("Button", "ElvUI_PaperDollSidebarTab3", sidebarTabs)
	sidebarTabs3:SetID(3)
	sidebarTabs3.sidebarID = 3
	sidebarTabs3:Point("BOTTOMRIGHT", -30, 0)		S:PaperDollSidebarTab(sidebarTabs3)

	local sidebarTabs2 = CreateFrame("Button", "ElvUI_PaperDollSidebarTab2", sidebarTabs)
	sidebarTabs2:SetID(2)
	sidebarTabs2.sidebarID = 2
	sidebarTabs2:Point("RIGHT", ElvUI_PaperDollSidebarTab3, "LEFT", -4, 0)		S:PaperDollSidebarTab(sidebarTabs2)

	local sidebarTabs1 = CreateFrame("Button", "ElvUI_PaperDollSidebarTab1", sidebarTabs)
	sidebarTabs1:SetID(1)
	sidebarTabs1.sidebarID = 1
	sidebarTabs1:Point("RIGHT", ElvUI_PaperDollSidebarTab2, "LEFT", -4, 0)		S:PaperDollSidebarTab(sidebarTabs1)

	sidebarTabs1:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	sidebarTabs1:RegisterEvent("PLAYER_ENTERING_WORLD")
	sidebarTabs1:RegisterEvent("PLAYER_LOGIN")

	local tcoords = PAPERDOLL_SIDEBARS[1].texCoords
	local function UpdateCharacterPortrait(button)
		if not button or not button.Icon then return end
		SetPortraitTexture(button.Icon, "player")
		button.Icon:SetTexCoord(tcoords[1], tcoords[2], tcoords[3], tcoords[4])
		button.Icon:Show()
	end

	UpdateCharacterPortrait(sidebarTabs1)
	sidebarTabs1:SetScript("OnEvent", function(self, event, unit)
		if event == "UNIT_PORTRAIT_UPDATE" and unit and unit ~= "player" then return end
		UpdateCharacterPortrait(self)
	end)
	local previousOnShow = sidebarTabs1:GetScript("OnShow")
	sidebarTabs1:SetScript("OnShow", function(self)
		if previousOnShow then previousOnShow(self) end
		UpdateCharacterPortrait(self)
	end)

	local titlePane = CreateFrame("ScrollFrame", "PaperDollTitlesPane", PaperDollFrame, "HybridScrollFrameTemplate")
	titlePane:Hide()
	titlePane:SetSize(SCROLL_WIDTH_SIRUS_STATS_CHILD, 363)
	PaneFadeInfo(titlePane)

	titlePane.scrollBar = CreateFrame("Slider", "$parentScrollBar", titlePane, "HybridScrollBarTemplate")
	titlePane.scrollBar:Width(20)
	titlePane.scrollBar:ClearAllPoints()
	titlePane.scrollBar:Point("TOPLEFT", titlePane, "TOPRIGHT", 3, -16)
	titlePane.scrollBar:Point("BOTTOMLEFT", titlePane, "BOTTOMRIGHT", 3, 16)
	S:HandleSirusScrollBar(titlePane.scrollBar)

	CreateSmoothScrollAnimation(titlePane.scrollBar, true)

	titlePane.scrollBar.Show = function(self)
		titlePane:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		titlePane:Point("TOPRIGHT", CharacterFrame, -24, -55)
		for _, button in next, titlePane.buttons do
			button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		end
		getmetatable(self).__index.Show(self)
	end

	titlePane.scrollBar.Hide = function(self)
		titlePane:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		titlePane:Point("TOPRIGHT", CharacterFrame, -6, -55)
		for _, button in next, titlePane.buttons do
			button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		end
		getmetatable(self).__index.Hide(self)
	end

	titlePane:SetFrameLevel(CharacterFrame:GetFrameLevel() + 1)

	HybridScrollFrame_OnLoad(titlePane)
	titlePane.update = S.PaperDollTitlesPane_UpdateScrollFrame
	HybridScrollFrame_CreateButtons(PaperDollTitlesPane, "PlayerTitleButtonTemplate2", 2, -4)

	local statsPane = CreateFrame("ScrollFrame", "CharacterStatsPane", PaperDollFrame, "UIPanelScrollFrameTemplate")
	statsPane:SetSize(SCROLL_WIDTH_SIRUS_STATS_CHILD, 363)
	PaneFadeInfo(statsPane)
	statsPane.Categories = {}

	if not CharacterStatsPaneScrollBar then
		CharacterStatsPaneScrollBar = CreateFrame("Slider", "CharacterStatsPaneScrollBar", statsPane, "UIPanelScrollBarTemplate")
		CharacterStatsPaneScrollBar:SetValueStep(1)
		CharacterStatsPaneScrollBar:SetMinMaxValues(0, 0)
	end

	statsPane.scrollBar = CharacterStatsPaneScrollBar
	CharacterStatsPaneScrollBar:ClearAllPoints()
	CharacterStatsPaneScrollBar:Point("TOPLEFT", CharacterStatsPane, "TOPRIGHT", 3, -16)
	CharacterStatsPaneScrollBar:Point("BOTTOMLEFT", CharacterStatsPane, "BOTTOMRIGHT", 3, 16)
	S:HandleSirusScrollBar(CharacterStatsPaneScrollBar)

	CharacterStatsPaneScrollBar.scrollStep = 50
	CharacterStatsPane.scrollBarHideable = 1
	ScrollFrame_OnLoad(statsPane)
	ScrollFrame_OnScrollRangeChanged(statsPane)

	CreateSmoothScrollAnimation(CharacterStatsPaneScrollBar)

	local statsPaneScrollChild = CreateFrame("Frame", "CharacterStatsPaneScrollChild", statsPane)
	statsPaneScrollChild:SetSize(SCROLL_WIDTH_SIRUS_STATS_CHILD + 18, 0)
	statsPaneScrollChild:Point("TOPLEFT")

	for i = 1, 8 do
		local button = CreateFrame("Frame", "CharacterStatsPaneCategory"..i, statsPaneScrollChild)
		button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)

		button.Toolbar = CreateFrame("Button", nil, button)
		button.Toolbar:RegisterForDrag("LeftButton")
		button.Toolbar:Size(251, 24)
		button.Toolbar:Point("TOP")

		button.Toolbar.Background = button.Toolbar:CreateTexture(nil, "BACKGROUND")
		button.Toolbar.Background:SetAllPoints()
		button.Toolbar.Background:SetTexture(E.Media.Textures.Highlight)
		button.Toolbar.Background:SetAlpha(0.3)

		button.Toolbar:SetScript("OnClick", function(self)
			if self:GetParent().collapsed then
				PaperDollFrame_ExpandStatCategory(self:GetParent())
				CharacterStatsPane.collapsedData[self:GetParent().Category] = false
			else
				PaperDollFrame_CollapseStatCategory(self:GetParent())
				CharacterStatsPane.collapsedData[self:GetParent().Category] = true
			end
		end)
		button.Toolbar:SetScript("OnDragStart", function(self)
			PaperDollStatCategory_OnDragStart(self:GetParent())
		end)
		button.Toolbar:SetScript("OnDragStop", function(self)
			PaperDollStatCategory_OnDragStop(self:GetParent())
		end)

		button.NameText = button.Toolbar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		button.NameText:Point("CENTER")

		button.Stats = {}
		button.Stats[1] = CreateFrame("Button", "$parentStat1", button)
		button.Stats[1]:Point("TOPLEFT", 0, -25)
		button.Stats[1]:Point("RIGHT", -4, 0)
		S:CharacterStatFrame(button.Stats[1],1)

		statsPane.Categories[i] = button
	end

	statsPane:SetScrollChild(statsPaneScrollChild)

	CharacterStatsPaneScrollBar.Show = function(self)
		statsPane:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		statsPane:Point("TOPRIGHT", CharacterFrame, -24, -55)
		statsPaneScrollChild:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		for _, button in next, statsPane.Categories do
			button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
			button.Toolbar:Width(241 - 18)
		end
		getmetatable(self).__index.Show(self)
	end

	CharacterStatsPaneScrollBar.Hide = function(self)
		statsPane:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD + 18)
		statsPane:Point("TOPRIGHT", CharacterFrame, -6, -55)
		statsPaneScrollChild:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD + 18)
		for _, button in next, statsPane.Categories do
			button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD + 18)
			button.Toolbar:Width(246)
		end
		getmetatable(self).__index.Hide(self)
	end

	statsPane:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD + 18)
	statsPane:Point("TOPRIGHT", CharacterFrame, -6, -55)
	for _, button in next, statsPane.Categories do
		button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD + 18)
	end

	statsPane:SetScript("OnShow", function(self)
		S:PaperDollTitlesPane_Update()
	end)

	local equipmentManagerPane = CreateFrame("ScrollFrame", "PaperDollEquipmentManagerPane", PaperDollFrame, "HybridScrollFrameTemplate")
	equipmentManagerPane:Hide()
	equipmentManagerPane:SetSize(SCROLL_WIDTH_SIRUS_STATS_CHILD, 363)
	equipmentManagerPane:Point("TOPRIGHT", CharacterFrame, -24, -55)
	PaneFadeInfo(equipmentManagerPane)

	local btnsInsets = 4
	local frameInsets = 10
	local btnSize = (SCROLL_WIDTH_SIRUS_STATS_CHILD - btnsInsets * 2 - frameInsets) / 3
	equipmentManagerPane.EquipSet = CreateFrame("Button", "$parentEquipSet", equipmentManagerPane, "UIPanelButtonTemplate")
	equipmentManagerPane.EquipSet:SetText(EQUIPSET_EQUIP)
	equipmentManagerPane.EquipSet:SetSize(btnSize, 22)
	equipmentManagerPane.EquipSet:Point("TOP", -75, 0)
	S:HandleButton(equipmentManagerPane.EquipSet)

	equipmentManagerPane.EquipSet:SetScript("OnClick", function()
		local selectedSetName = PaperDollEquipmentManagerPane.selectedSetName
		if selectedSetName and selectedSetName ~= "" then
			PlaySound("igCharacterInfoTab")
			EquipmentManager_EquipSet(selectedSetName)
		end
	end)

	equipmentManagerPane.SaveSet = CreateFrame("Button", "$parentSaveSet", equipmentManagerPane, "UIPanelButtonTemplate")
	equipmentManagerPane.SaveSet:SetText(SAVE)
	equipmentManagerPane.SaveSet:SetSize(btnSize, 22)
	equipmentManagerPane.SaveSet:Point("LEFT", "$parentEquipSet", "RIGHT", 4, 0)
	S:HandleButton(equipmentManagerPane.SaveSet)

	equipmentManagerPane.SaveSet:SetScript("OnClick", GearManagerDialogSaveSet_OnClick)

	equipmentManagerPane.Undress = CreateFrame("Button", "$parentUndressSet", equipmentManagerPane, "UIPanelButtonTemplate")
	equipmentManagerPane.Undress:SetText("Раздеть")
	equipmentManagerPane.Undress:SetSize(btnSize, 22)
	equipmentManagerPane.Undress:Point("LEFT", "$parentSaveSet", "RIGHT", 4, 0)

	equipmentManagerPane.Undress:SetScript("OnClick", function()
		for i = 1,19 do
			PickupInventoryItem(i)
			PutItemInBackpack()
		end
	end)
	S:HandleButton(equipmentManagerPane.Undress)

	equipmentManagerPane.scrollBar = CreateFrame("Slider", "$parentScrollBar", equipmentManagerPane, "HybridScrollBarTemplate")
	equipmentManagerPane.scrollBar:Width(20)
	equipmentManagerPane.scrollBar:ClearAllPoints()
	equipmentManagerPane.scrollBar:Point("TOPLEFT", equipmentManagerPane, "TOPRIGHT", 3, -16)
	equipmentManagerPane.scrollBar:Point("BOTTOMLEFT", equipmentManagerPane, "BOTTOMRIGHT", 3, 16)
	S:HandleSirusScrollBar(equipmentManagerPane.scrollBar)

	CreateSmoothScrollAnimation(equipmentManagerPane.scrollBar, true)

	equipmentManagerPane.scrollBar.Show = function(self)
		equipmentManagerPane:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		equipmentManagerPane:Point("TOPRIGHT", CharacterFrame, -24, -55)
		for _, button in next, equipmentManagerPane.buttons do
			button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		end
		getmetatable(self).__index.Show(self)
	end

	equipmentManagerPane.scrollBar.Hide = function(self)
		equipmentManagerPane:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		equipmentManagerPane:Point("TOPRIGHT", CharacterFrame, -6, -55)
		for _, button in next, equipmentManagerPane.buttons do
			button:Width(SCROLL_WIDTH_SIRUS_STATS_CHILD)
		end
		getmetatable(self).__index.Hide(self)
	end

	equipmentManagerPane:SetFrameLevel(CharacterFrame:GetFrameLevel() + 1)
	equipmentManagerPane.EquipSet:SetFrameLevel(equipmentManagerPane:GetFrameLevel() + 3)
	equipmentManagerPane.SaveSet:SetFrameLevel(equipmentManagerPane:GetFrameLevel() + 3)

	HybridScrollFrame_OnLoad(equipmentManagerPane)
	equipmentManagerPane.update = S.PaperDollEquipmentManagerPane_Update
	HybridScrollFrame_CreateButtons(equipmentManagerPane, "GearSetButtonTemplate2", 2, -(equipmentManagerPane.EquipSet:GetHeight() + 4))

	equipmentManagerPane:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
	equipmentManagerPane:RegisterEvent("EQUIPMENT_SETS_CHANGED")
	equipmentManagerPane:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	equipmentManagerPane:RegisterEvent("BAG_UPDATE")

	equipmentManagerPane:SetScript("OnShow", function(self)
		S:PaperDollEquipmentManagerPane_Update()

	end)

	equipmentManagerPane:SetScript("OnHide", function()
		PaperDollFrame_ClearIgnoredSlots()

		GearManagerDialogPopup:Hide()
		StaticPopup_Hide("CONFIRM_SAVE_EQUIPMENT_SET")
		StaticPopup_Hide("CONFIRM_OVERWRITE_EQUIPMENT_SET")
	end)

	equipmentManagerPane:SetScript("OnEvent", function(self, event, ...)
		if event == "EQUIPMENT_SWAP_FINISHED" then
			local completed, setName = ...
			if completed then
				if self:IsShown() then
					self.selectedSetName = setName
					S:PaperDollEquipmentManagerPane_Update()
				end
			end
		end

		if self:IsShown() then
			if event == "EQUIPMENT_SETS_CHANGED" then
				S:PaperDollEquipmentManagerPane_Update()
			elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" then
				self.queuedUpdate = true
			end
		end
	end)

	equipmentManagerPane:SetScript("OnUpdate", function(self)
		for i = 1, #self.buttons do
			local button = self.buttons[i]
			if button:IsMouseOver() then
				if button.name then
					button.DeleteButton:Show()
					button.EditButton:Show()
				else
					button.DeleteButton:Hide()
					button.EditButton:Hide()
				end
				button.HighlightBar:Show()
			else
				button.DeleteButton:Hide()
				button.EditButton:Hide()
				button.HighlightBar:Hide()
			end
		end
		if self.queuedUpdate then
			S:PaperDollEquipmentManagerPane_Update()
			self.queuedUpdate = false
		end
	end)

	GearManagerDialogPopup:SetParent(PaperDollFrame)
	GearManagerDialogPopup:ClearAllPoints()
	GearManagerDialogPopup:SetPoint("LEFT", CharacterFrame, "RIGHT")

	local playerSettings = E.private.character.character and E.private.character.character.player or E.private.character.player or {}
	S:PaperDoll_InitStatCategories(PAPERDOLL_STATCATEGORY_DEFAULTORDER, playerSettings.orderName or "", playerSettings.collapsedName or {}, "player")

	PaperDollFrame:RegisterEvent("PLAYER_TALENT_UPDATE")

	PaperDollFrame:HookScript("OnEvent", function(self, event, ...)
		if not self:IsVisible() then return end
		if event == "PLAYER_ENTERING_WORLD" or event == "DISPLAY_SIZE_CHANGED" then
			CenterCharacterHeader()
		end

		local unit = ...
		if event == "KNOWN_TITLES_UPDATE" or (event == "UNIT_NAME_UPDATE" and unit == "player") then
			if PaperDollTitlesPane:IsShown() then
				S:PaperDollTitlesPane_Update()
			end

		end

		if unit == "player" then
			if event == "UNIT_LEVEL" then
				S:PaperDollFrame_SetLevel()
			elseif event == "UNIT_DAMAGE" or event == "PLAYER_DAMAGE_DONE_MODS" or event == "UNIT_ATTACK_SPEED" or event == "UNIT_RANGEDDAMAGE" or event == "UNIT_ATTACK" or event == "UNIT_STATS" or event == "UNIT_RANGED_ATTACK_POWER" then
				S:PaperDollFrame_UpdateStats()
			elseif event == "UNIT_RESISTANCES" then
				S:PaperDollFrame_UpdateStats()
			end
		end

		if event == "COMBAT_RATING_UPDATE" then
			S:PaperDollFrame_UpdateStats()
		elseif event == "PLAYER_TALENT_UPDATE" then
			S:PaperDollFrame_SetLevel()
		end
	end)

	PaperDollFrame:HookScript("OnShow", function()
		CenterCharacterHeader()
		local playerSettings = E.private.character.character and E.private.character.character.player or E.private.character.player or {}
	S:PaperDoll_InitStatCategories(PAPERDOLL_STATCATEGORY_DEFAULTORDER, playerSettings.orderName or "", playerSettings.collapsedName or {}, "player")

		S:PaperDollFrame_SetLevel()

	end)


	S:PaperDollFrame_UpdateSidebarTabs()






	PetModelFrameRotateLeftButton:Point("TOPLEFT", PetPaperDollFrame, "TOPLEFT", 27, -80)












end


local Slots = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
		"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
		"MainHandSlot", "SecondaryHandSlot", "RangedSlot"
	}

function S:ColorItemCharacterBorder()
	for _, slot in pairs(Slots) do
		local clink = GetInventoryItemLink("player", GetInventorySlotInfo(slot))
		slot = _G["Character"..slot]
		if not slot.textureSoc then
			slot.textureSoc = slot:CreateTexture("nil", "TOOLTIP")
			slot.textureSoc:SetInside()
			slot.textureSoc:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\BagNewItemGlow]])
			slot.textureSoc:SetVertexColor(E:GetItemQualityColor(5))
			slot.textureSoc:Hide()
		end
		local found
		if clink then
			for i = 1, 3 do
				local _, glink = GetItemGem(clink, i)
				if glink then
					local _, _, itemRarity = GetItemInfo(glink)
					if itemRarity == 5 then
						slot.textureSoc:Show()
						found = true
						break
					end
				end
			end
		end
		if not found and slot.textureSoc then
			slot.textureSoc:Hide()
		end
	end
end

function S:ColorItemInspectBorder()
	for _, slot in pairs(Slots) do
		local clink = GetInventoryItemLink("target", GetInventorySlotInfo(slot))
		slot = _G["Inspect"..slot]
		if slot then
			if not slot.textureSoc then
				slot.textureSoc = slot:CreateTexture("nil", "TOOLTIP")
				slot.textureSoc:SetInside()
				slot.textureSoc:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\BagNewItemGlow]])
				slot.textureSoc:SetVertexColor(E:GetItemQualityColor(5))
				slot.textureSoc:Hide()
			end
			local found
			if clink then
				for i = 1, 3 do
					local _, glink = GetItemGem(clink, i)
					if glink then
						local _, _, itemRarity = GetItemInfo(glink)
						if itemRarity == 5 then
							slot.textureSoc:Show()
							found = true
							break
						end
					end
				end
			end
			if not found and slot.textureSoc then
				slot.textureSoc:Hide()
			end
		end
	end
end

local function ColorizeStatPane(frame)
	if frame.leftGrad then return end

	local r, g, b = 0.8, 0.8, 0.8
	frame.leftGrad = frame:CreateTexture(nil, "BORDER")
	frame.leftGrad:Width(frame:GetWidth() * .5)
	frame.leftGrad:Height(frame:GetHeight())
	frame.leftGrad:Point("LEFT", frame, "CENTER")
	frame.leftGrad:SetTexture(E.media.blankTex)
	frame.leftGrad:SetGradientAlpha("Horizontal", r, g, b, 0.35, r, g, b, 0)

	frame.rightGrad = frame:CreateTexture(nil, "BORDER")
	frame.rightGrad:Width(frame:GetWidth() * .5)
	frame.rightGrad:Height(frame:GetHeight())
	frame.rightGrad:Point("RIGHT", frame, "CENTER")
	frame.rightGrad:SetTexture(E.Media.Textures.White8x8)
	frame.rightGrad:SetGradientAlpha("Horizontal", r, g, b, 0, r, g, b, 0.35)
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.character then return end

	S:HandlePortraitFrame(CharacterFrame)

	CenterCharacterHeader()
	if PaperDollFrame_UpdateSpellButtons and not CharacterFrame.HeaderPositionHooked then
		hooksecurefunc("PaperDollFrame_UpdateSpellButtons", CenterCharacterHeader)
		CharacterFrame.HeaderPositionHooked = true
	end

	local characterTabs = {}
	for i = 1, #CHARACTERFRAME_SUBFRAMES do
		local tab = _G["CharacterFrameTab"..i]
		if tab then
			S:HandleSirusTab(tab)
			characterTabs[i] = tab
		end
	end
	S:HandleSirusTabFlow(characterTabs, "PetPaperDollFrame_UpdateIsAvailable")

	GearManagerDialog:StripTextures()
	GearManagerDialog:CreateBackdrop("Transparent")
	GearManagerDialog.backdrop:Point("TOPLEFT", 5, -2)
	GearManagerDialog.backdrop:Point("BOTTOMRIGHT", -1, 4)

	S:HandleCloseButton(GearManagerDialogClose)

	for i = 1, 10 do
		_G["GearSetButton"..i]:StripTextures()
		_G["GearSetButton"..i]:StyleButton()
		_G["GearSetButton"..i]:CreateBackdrop("Default")
		_G["GearSetButton"..i].backdrop:SetAllPoints()
		_G["GearSetButton"..i.."Icon"]:SetTexCoords()
		_G["GearSetButton"..i.."Icon"]:SetInside()
	end

	S:HandleButton(GearManagerDialogDeleteSet)
	S:HandleButton(GearManagerDialogEquipSet)
	S:HandleButton(GearManagerDialogSaveSet)

	GearManagerDialogPopup:StripTextures()
	GearManagerDialogPopup:CreateBackdrop("Transparent")
	GearManagerDialogPopup.backdrop:Point("TOPLEFT", 5, -2)
	GearManagerDialogPopup.backdrop:Point("BOTTOMRIGHT", -4, 8)

	GearManagerDialogPopup:Height(287 + 15)
	GearManagerDialogPopupScrollFrame:Height(184 + 15)
	GearManagerDialogPopup.BorderBox:StripTextures()
	S:HandleEditBox(GearManagerDialogPopupSearchBox)

	S:HandleEditBox(GearManagerDialogPopupEditBox)

	GearManagerDialogPopupScrollFrame:StripTextures()
	S:HandleSirusScrollBar(GearManagerDialogPopupScrollFrameScrollBar)

	for i = 1, NUM_GEARSET_ICONS_SHOWN do
		local button = _G["GearManagerDialogPopupButton"..i]

		if button then
			local icon = button.icon
			button:StripTextures()
			button:StyleButton(true)

			icon:SetTexCoords()
			_G["GearManagerDialogPopupButton"..i.."Icon"]:SetTexture(nil)

			icon:SetInside()
			button:SetFrameLevel(button:GetFrameLevel() + 2)
			if not button.backdrop then
				button:CreateBackdrop("Default")
				button.backdrop:SetAllPoints()
			end
		end
	end

	S:HandleButton(GearManagerDialogPopupOkay)
	S:HandleButton(GearManagerDialogPopupCancel)

	PaperDollFrame:StripTextures(true)

	PaperDollFrame.NewPanel:StripTextures()
	ColorizeStatPane(PaperDollFrameStrengthenFrame.Title)
	PaperDollFrameStrengthenFrame.Title.Background:SetAlpha(0)

	DisableStrengthenResetButton()

	for i = 1, C_PlayerInfo.GetNumBonusStats() do
		local statPlus = _G["PaperDollFrameStrengthenFrameStat"..i.."Plus"]
		if statPlus then
			statPlus:StripTextures()
			S:HandleButton(statPlus)
			statPlus:SetNormalTexture(E.Media.Textures.Plus)
			statPlus:GetNormalTexture():SetInside()
			statPlus:SetPushedTexture(E.Media.Textures.Plus)
			statPlus:GetPushedTexture():SetInside()
			statPlus:SetDisabledTexture(E.Media.Textures.Plus)
			statPlus:GetDisabledTexture():SetInside()
			statPlus:GetDisabledTexture():SetDesaturated(true)
		end
	end

	PaperDollSidebarTabs:StripTextures()

	C_Timer:After(0,function()
		if PaperDollFrameItemSetSwapButton then
			PaperDollFrameItemSetSwapButton:StripTextures()
			S:HandleButton(PaperDollFrameItemSetSwapButton)
			PaperDollFrameItemSetSwapButton.Icon:SetTexCoords()
			PaperDollFrameItemSetSwapButton:ClearAllPoints()
			PaperDollFrameItemSetSwapButton:SetParent(ElvUI_PaperDollSidebarTabs and ElvUI_PaperDollSidebarTabs or PaperDollSidebarTabs)
			PaperDollFrameItemSetSwapButton:Size(32)
			local level = ElvUI_PaperDollSidebarTab1 and ElvUI_PaperDollSidebarTab1:GetFrameLevel() or PaperDollSidebarTab1:GetFrameLevel()
			local point = ElvUI_PaperDollSidebarTab1 and ElvUI_PaperDollSidebarTab1 or PaperDollSidebarTab1
			PaperDollFrameItemSetSwapButton:SetFrameLevel(level+1)
			PaperDollFrameItemSetSwapButton:SetPoint("RIGHT",point,"LEFT",-4,0)
		end
	end)
	PaperDollFrame.StatsInset:StripTextures()
	PaperDollFrame.EquipInset:StripTextures()
	CharacterModelFrame:CreateBackdrop()
	CharacterModelFrame.backdrop:SetOutside(CharacterModelFrameBackgroundOverlay)
	CharacterModelFrame:DisableDrawLayer("OVERLAY")

	S:HandleControlFrame(CharacterModelFrame.controlFrame)

	ColorizeStatPane(CharacterItemLevelFrame)
	CharacterItemLevelFrame.ilvlbackground:SetAlpha(0)

	PlayerTitleFrame:StripTextures()
	PlayerTitleFrame:CreateBackdrop("Default")
	PlayerTitleFrame.backdrop:Point("TOPLEFT", 20, 3)
	PlayerTitleFrame.backdrop:Point("BOTTOMRIGHT", -16, 14)
	PlayerTitleFrame.backdrop:SetFrameLevel(PlayerTitleFrame:GetFrameLevel())
	S:HandleNextPrevButton(PlayerTitleFrameButton)
	PlayerTitleFrameButton:ClearAllPoints()
	PlayerTitleFrameButton:Point("RIGHT", PlayerTitleFrame.backdrop, "RIGHT", -2, 0)

	PlayerTitlePickerScrollFrame:StripTextures()
	PlayerTitlePickerScrollFrame:CreateBackdrop("Transparent")

	for i = 1, #PlayerTitlePickerScrollFrame.buttons do
		PlayerTitlePickerScrollFrame.buttons[i].text:FontTemplate()
	end

	S:HandleSirusScrollBar(PlayerTitlePickerScrollFrameScrollBar)

	for i = 1, #PAPERDOLL_SIDEBARS do
		local tab = _G["PaperDollSidebarTab"..i]
		if tab then
			tab:CreateBackdrop()
			tab.Icon:SetAllPoints()
			tab.Highlights:SetTexture(1, 1, 1, .3)
			tab.Highlights:SetAllPoints()
			tab.TabBg:Kill()
		end
	end

	if CharacterCustomizationButton then
		CharacterCustomizationButton:ClearAllPoints()
		CharacterCustomizationButton:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 18, -18)

		CharacterCustomizationButton:Size(28, 28)
		CharacterCustomizationButton:CreateBackdrop()

		if CharacterCustomizationButton.NormalTexture then
			CharacterCustomizationButton.NormalTexture:SetInside()
			CharacterCustomizationButton.NormalTexture:SetTexCoords()
		end

		if CharacterCustomizationButton.HighlightTexture then
			CharacterCustomizationButton.HighlightTexture:SetTexture(1, 1, 1, 0.3)
			CharacterCustomizationButton.HighlightTexture:SetInside()
		end

		if CharacterCustomizationButton.DisabledTexture then
			CharacterCustomizationButton.DisabledTexture:SetInside()
			CharacterCustomizationButton.DisabledTexture:SetTexCoords()
		end
	end

	_G["GearManagerToggleButton"]:Size(26, 32)
	_G["GearManagerToggleButton"]:CreateBackdrop("Default")

	GearManagerToggleButton:GetNormalTexture():SetTexCoord(0.1875, 0.8125, 0.125, 0.90625)
	GearManagerToggleButton:GetPushedTexture():SetTexCoord(0.1875, 0.8125, 0.125, 0.90625)
	GearManagerToggleButton:GetHighlightTexture():SetTexture(1, 1, 1, 0.3)
	GearManagerToggleButton:GetHighlightTexture():SetAllPoints()

	local popoutButtonOnEnter = function(btn) btn.icon:SetVertexColor(unpack(E.media.rgbvaluecolor)) end
	local popoutButtonOnLeave = function(btn) btn.icon:SetVertexColor(1, 1, 1) end

	local slots = {
		[1] = "HeadSlot", [2] = "NeckSlot", [3] = "ShoulderSlot", [4] = "ShirtSlot", [5] = "ChestSlot",
		[6] = "WaistSlot", [7] = "LegsSlot", [8] = "FeetSlot", [9] = "WristSlot", [10] = "HandsSlot",
		[11] = "Finger0Slot", [12] = "Finger1Slot", [13] = "Trinket0Slot", [14] = "Trinket1Slot",
		[15] = "BackSlot", [16] = "MainHandSlot", [17] = "SecondaryHandSlot", [18] = "RangedSlot", [19] = "TabardSlot"
	}

	local socketAnchors = {
		[1] = "RIGHT", [2] = "RIGHT", [3] = "RIGHT", [4] = "RIGHT", [5] = "RIGHT",
		[6] = "LEFT", [7] = "LEFT", [8] = "LEFT", [9] = "RIGHT", [10] = "LEFT",
		[11] = "LEFT", [12] = "LEFT", [13] = "LEFT", [14] = "LEFT", [15] = "RIGHT",
		[16] = "TOP", [17] = "TOP", [18] = "TOP", [19] = "RIGHT"
	}

	for _, slotName in ipairs(slots) do
		local slotFrame = _G["Character"..slotName]
		local icon = _G["Character"..slotName.."IconTexture"]
		local cooldown = _G["Character"..slotName.."Cooldown"]
		local popout = _G["Character"..slotName.."PopoutButton"]

		slotFrame:StripTextures()
		slotFrame:StyleButton(false)
		slotFrame:SetTemplate("Default", true, true)

		icon:SetTexCoords()
		icon:SetInside()

		slotFrame:SetFrameLevel(PaperDollFrame:GetFrameLevel() + 2)

		if cooldown then
			E:RegisterCooldown(cooldown)
		end

		if popout then
			popout:StripTextures()
			popout:HookScript("OnEnter", popoutButtonOnEnter)
			popout:HookScript("OnLeave", popoutButtonOnLeave)

			popout.icon = popout:CreateTexture(nil, "ARTWORK")
			popout.icon:Size(24)
			popout.icon:Point("CENTER")
			popout.icon:SetTexture(E.Media.Textures.ArrowUp)

			if slotFrame.verticalFlyout then
				popout.icon:SetRotation(S.ArrowRotation.down)
			else
				popout.icon:SetRotation(S.ArrowRotation.right)
			end
		end
	end

	local function ColorItemBorder()
		for _, slotName in pairs(slots) do
			local target = _G["Character"..slotName]
			local slotId = GetInventorySlotInfo(slotName)
			local itemId = GetInventoryItemID("player", slotId)

			if itemId then
				local rarity = GetInventoryItemQuality("player", slotId)
				if rarity then
					target:SetBackdropBorderColor(E:GetItemQualityColor(rarity))
				else
					target:SetBackdropBorderColor(unpack(E.media.bordercolor))
				end
			else
				target:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		end

		S:ColorItemCharacterBorder()
	end

	local function UpdateCharacterEquipmentSockets()
		ColorItemBorder()

		for slotIndex, slotName in ipairs(slots) do
			S:HandleSirusEquipmentSocketInfo(_G["Character"..slotName], GetInventorySlotInfo(slotName), socketAnchors[slotIndex], slotName)
		end
	end

	S.UpdateCharacterEquipmentSockets = UpdateCharacterEquipmentSockets

	local socketUpdateTimer
	local function SocketUpdateDelayed()
		socketUpdateTimer = nil
		UpdateCharacterEquipmentSockets()
	end

	local equipmentWatcher = CreateFrame("Frame")
	equipmentWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	equipmentWatcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
	equipmentWatcher:RegisterEvent("SOCKET_INFO_CLOSE")
	equipmentWatcher:SetScript("OnEvent", function(_, event, unit)
		if (event == "UNIT_INVENTORY_CHANGED" and unit ~= "player") or not CharacterFrame:IsShown() or socketUpdateTimer then return end
		socketUpdateTimer = E:Delay(0.1, SocketUpdateDelayed)
	end)

	CharacterFrame:HookScript("OnShow", UpdateCharacterEquipmentSockets)

	local function HandleResistanceFrame(frameName)
		for i = 1, 5 do
			local frame = _G[frameName..i]
			frame:Size(24)
			frame:SetTemplate("Default")

			if i ~= 1 then
				frame:ClearAllPoints()
				frame:Point("TOP", _G[frameName..i-1], "BOTTOM", 0, -(E.Border + E.Spacing))
			end

			select(1, _G[frameName..i]:GetRegions()):SetInside()
			select(1, _G[frameName..i]:GetRegions()):SetDrawLayer("ARTWORK")
			select(2, _G[frameName..i]:GetRegions()):SetDrawLayer("OVERLAY")
		end
	end

	HandleResistanceFrame("MagicResFrame")

	select(1, MagicResFrame1:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.25, 0.32421875)
	select(1, MagicResFrame2:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.0234375, 0.09765625)
	select(1, MagicResFrame3:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.13671875, 0.2109375)
	select(1, MagicResFrame4:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.36328125, 0.4375)
	select(1, MagicResFrame5:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.4765625, 0.55078125)

	S:HandleDropDownBox(PlayerStatFrameLeftDropDown, 140, "down")
	S:HandleDropDownBox(PlayerStatFrameRightDropDown, 140, "down")
	CharacterAttributesFrame:StripTextures()

	PetPaperDollFrame:StripTextures(true)

	S:HandleRotateButton(PetModelFrameRotateLeftButton)
	S:HandleRotateButton(PetModelFrameRotateRightButton)
	PetModelFrameRotateRightButton:SetPoint("TOPLEFT", PetModelFrameRotateLeftButton, "TOPRIGHT", 3, 0)

	HandleResistanceFrame("PetMagicResFrame")

	select(1, PetMagicResFrame1:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.25, 0.32421875)
	select(1, PetMagicResFrame2:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.0234375, 0.09765625)
	select(1, PetMagicResFrame3:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.13671875, 0.2109375)
	select(1, PetMagicResFrame4:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.36328125, 0.4375)
	select(1, PetMagicResFrame5:GetRegions()):SetTexCoord(0.21875, 0.8125, 0.4765625, 0.55078125)

	PetAttributesFrame:StripTextures()

	PetPaperDollFrameExpBar:StripTextures()
	PetPaperDollFrameExpBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(PetPaperDollFrameExpBar)
	PetPaperDollFrameExpBar:CreateBackdrop("Default")

	local function updHappiness(self)
		local happiness = GetPetHappiness()
		local _, isHunterPet = HasPetUI()
		if not happiness or not isHunterPet then return end

		local texture = self:GetRegions()
		if happiness == 1 then
			texture:SetTexCoord(0.41, 0.53, 0.06, 0.30)
		elseif happiness == 2 then
			texture:SetTexCoord(0.22, 0.345, 0.06, 0.30)
		elseif happiness == 3 then
			texture:SetTexCoord(0.04, 0.15, 0.06, 0.30)
		end
	end

	PetPaperDollPetInfo:SetPoint("TOPLEFT", PetModelFrameRotateLeftButton, "BOTTOMLEFT", 9, -3)
	PetPaperDollPetInfo:GetRegions():SetTexCoord(0.04, 0.15, 0.06, 0.30)
	PetPaperDollPetInfo:SetFrameLevel(PetModelFrame:GetFrameLevel() + 2)
	PetPaperDollPetInfo:CreateBackdrop("Default")
	PetPaperDollPetInfo:Size(24, 24)
	updHappiness(PetPaperDollPetInfo)

	PetPaperDollPetInfo:RegisterEvent("UNIT_HAPPINESS")
	PetPaperDollPetInfo:SetScript("OnEvent", updHappiness)
	PetPaperDollPetInfo:SetScript("OnShow", updHappiness)

	PetPaperDollFrameCompanionFrame:StripTextures()

	S:HandleRotateButton(CompanionModelFrameRotateLeftButton)
	S:HandleRotateButton(CompanionModelFrameRotateRightButton)
	CompanionModelFrameRotateRightButton:SetPoint("TOPLEFT", CompanionModelFrameRotateLeftButton, "TOPRIGHT", 3, 0)

	S:HandleButton(CompanionSummonButton)

	S:HandleNextPrevButton(CompanionPrevPageButton)
	S:HandleNextPrevButton(CompanionNextPageButton)

	ReputationFrame:StripTextures(true)

	for i = 1, NUM_FACTIONS_DISPLAYED do
		local factionRow = _G["ReputationBar"..i]
		local factionBar = _G["ReputationBar"..i.."ReputationBar"]
		local factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"]
		local headerButton = _G["ReputationBar"..i.."HeaderButton"]

		factionRow:StripTextures(true)			S:HandleSirusStatusBar(factionBar)

		factionButton:SetNormalTexture(E.Media.Textures.Minus)
		factionButton.SetNormalTexture = E.noop
		factionButton.SetNormalAtlas = E.noop
		factionButton.SetPushedAtlas = E.noop
		factionButton:GetNormalTexture():Size(15)
		factionButton:SetHighlightTexture(nil)

		if headerButton then
			if headerButton.HighlightLeft then headerButton.HighlightLeft:Kill() end
			if headerButton.HighlightRight then headerButton.HighlightRight:Kill() end
			if headerButton.HighlightMiddle then headerButton.HighlightMiddle:Kill() end
			if headerButton.Name then headerButton.Name:Kill() end

			local arrow = headerButton:CreateTexture(nil, "ARTWORK")
			arrow:Size(15)
			arrow:SetPoint("LEFT", 5, 0)
			headerButton.collapseArrow = arrow
		end
	end

	local function UpdateFaction()
		local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame)
		local factionIndex, factionRow, factionButton, headerButton
		local numFactions = GetNumFactions()
		for i = 1, NUM_FACTIONS_DISPLAYED, 1 do
			factionRow = _G["ReputationBar"..i]
			factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"]
			headerButton = _G["ReputationBar"..i.."HeaderButton"]
			factionIndex = factionOffset + i
			if factionIndex <= numFactions then
				if headerButton and headerButton:IsShown() then
					if headerButton.Left then headerButton.Left:SetTexture() end
					if headerButton.Right then headerButton.Right:SetTexture() end
					if headerButton.Middle then headerButton.Middle:SetTexture() end

					S:SetSirusCollapseIcon(headerButton, factionRow.isCollapsed)
				end

				S:SetSirusCollapseIcon(factionButton, factionRow.isCollapsed)
			end
		end
	end
	hooksecurefunc("ReputationFrame_Update", UpdateFaction)

	ReputationListScrollFrame:StripTextures()
	S:HandleSirusScrollBar(ReputationListScrollFrameScrollBar)

	ReputationDetailFrame:StripTextures()
	ReputationDetailFrame:SetTemplate("Transparent")
	ReputationDetailFrame.TextContainer:StripTextures()
	ReputationDetailFrame.TextContainer.ShadowOverlay:StripTextures()

	S:HandleCloseButton(ReputationDetailCloseButton)
	ReputationDetailCloseButton:Point("TOPRIGHT", 3, 4)

	S:HandleCheckBox(ReputationDetailAtWarCheckBox)
	ReputationDetailAtWarCheckBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-SwordCheck")
	S:HandleCheckBox(ReputationDetailInactiveCheckBox)
	S:HandleCheckBox(ReputationDetailMainScreenCheckBox)

	TokenFrame:StripTextures(true)

	hooksecurefunc("TokenFrame_Update", function()
		local scrollFrame = TokenFrameContainer
		local offset = HybridScrollFrame_GetOffset(scrollFrame)
		local buttons = scrollFrame.buttons
		local numButtons = #buttons
		local _, name, isHeader, isExpanded, extraCurrencyType, icon
		local button, index

		for i = 1, numButtons do
			index = offset+i
			name, isHeader, isExpanded, _, _, _, extraCurrencyType, icon = GetCurrencyListInfo(index)
			button = buttons[i]

			if not button.isSkinned then
				if button.HighlightLeft then button.HighlightLeft:Kill() end
				if button.HighlightRight then button.HighlightRight:Kill() end
				if button.HighlightMiddle then button.HighlightMiddle:Kill() end

				if button.HeaderButton then
					if button.HeaderButton.HighlightLeft then button.HeaderButton.HighlightLeft:Kill() end
					if button.HeaderButton.HighlightRight then button.HeaderButton.HighlightRight:Kill() end
					if button.HeaderButton.HighlightMiddle then button.HeaderButton.HighlightMiddle:Kill() end

					local arrow = button.HeaderButton:CreateTexture(nil, "ARTWORK")
					arrow:Size(15)
					arrow:SetPoint("LEFT", 5, 0)
					button.HeaderButton.collapseArrow = arrow

					if button.HeaderButton.Name then
						button.HeaderButton.Name:SetPoint("LEFT", 24, 0)
					end
				end

				button.isSkinned = true
			end

			if isHeader and button.HeaderButton then
				if button.HeaderButton.Left then button.HeaderButton.Left:SetTexture() end
				if button.HeaderButton.Right then button.HeaderButton.Right:SetTexture() end
				if button.HeaderButton.Middle then button.HeaderButton.Middle:SetTexture() end

				local arrow = button.HeaderButton.collapseArrow
				if arrow then
					S:SetSirusCollapseIcon(button.HeaderButton, not isExpanded)
				end
			end

			if name or name == "" then
				if not isHeader then
					if extraCurrencyType == 1 then
						button.icon:SetTexCoords()
					elseif extraCurrencyType == 2 then
						local factionGroup = UnitFactionGroup("player")
						if factionGroup then
							button.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)
							button.icon:SetTexCoord(0.03125, 0.59375, 0.03125, 0.59375)
						else
							button.icon:SetTexCoords()
						end
					else
						button.icon:SetTexture(icon)
						button.icon:SetTexCoords()
					end
				end
			end
		end
	end)

	TokenFrameContainer.update = TokenFrame_Update

	S:HandleSirusScrollBar(TokenFrameContainerScrollBar)

	TokenFramePopup:StripTextures()
	TokenFramePopup:SetTemplate("Transparent")

	if TokenFramePopupCloseButton then
		S:HandleCloseButton(TokenFramePopupCloseButton)
	end	S:HandleCheckBox(TokenFramePopupInactiveCheckBox)
	S:HandleCheckBox(TokenFramePopupBackpackCheckBox)

	local flyoutFrame = _G.EquipmentFlyoutFrame
	if flyoutFrame then
		local flyoutHighlight = _G.EquipmentFlyoutFrameHighlight
		if flyoutHighlight then flyoutHighlight:StripTextures() end

		local function SkinFlyout()
			local buttons = _G.EquipmentFlyoutFrameButtons
			if buttons then
				for i = 1, buttons.numBGs or 1 do
					local bg = buttons["bg"..i]
					if bg then bg:SetAlpha(0) end
				end
				buttons:DisableDrawLayer("ARTWORK")
				if not buttons.isSkinned then
					buttons:SetTemplate("Transparent")
					buttons.isSkinned = true
				end
			end

			local navFrame = flyoutFrame.NavigationFrame
			if navFrame then
				if not navFrame.isSkinned then
					navFrame:StripTextures()
					navFrame:SetTemplate("Transparent")
					navFrame.isSkinned = true
				end
				if navFrame.PrevButton then
					S:HandleNextPrevButton(navFrame.PrevButton, "left")
				end
				if navFrame.NextButton then
					S:HandleNextPrevButton(navFrame.NextButton, "right")
				end
			end

			if flyoutFrame.buttons then
				for _, button in next, flyoutFrame.buttons do
					if button and not button.isSkinned then
						if button.NormalTexture then button.NormalTexture:SetAlpha(0) end
						if button.HighlightTexture then button.HighlightTexture:SetAlpha(0) end
						button:SetTemplate("Default", true)
						if button.icon then
							button.icon:SetTexCoords()
							button.icon:SetInside()
						end
						button.isSkinned = true
					end
				end
			end
		end

		SkinFlyout()
		hooksecurefunc("EquipmentFlyout_UpdateItems", SkinFlyout)
	end

	if CharacterAmmoSlot then
		S:DisableFrameInteraction(CharacterAmmoSlot)
		hooksecurefunc("PaperDollFrame_OnShow", function()
			local slot = _G.CharacterAmmoSlot
			if slot then
			S:DisableFrameInteraction(slot)
			end
		end)
	end
end

S:AddCallback("Skin_Character", LoadSkin)

S:AddCallback("Character", S.CharacterInit)
