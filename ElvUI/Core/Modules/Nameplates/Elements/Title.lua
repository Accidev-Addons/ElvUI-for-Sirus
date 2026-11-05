local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

local GetGuildInfo = GetGuildInfo
local IsInGuild = IsInGuild
local IsInInstance = IsInInstance
local IsResting = IsResting
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsDead = UnitIsDead
local UnitPlayerControlled = UnitPlayerControlled

local separators = {
	[" "] = "%s",
	["<"] = "<%s>",
	["("] = "(%s)",
	["["] = "[%s]",
	["{"] = "{%s}"
}

local function IsGuildShown(visibility)
	if IsResting() then
		return visibility.city
	end

	local _, instanceType = IsInInstance()
	return visibility[instanceType] ~= false
end

local function GetGuildColor(colors, unit, guildName)
	if UnitInRaid(unit) then
		return colors.raid
	elseif UnitInParty(unit) then
		return colors.party
	elseif IsInGuild() and GetGuildInfo("player") == guildName then
		return colors.guild
	end

	return colors.none
end

function NP:Configure_Title(frame)
	local db = self.db.units[frame.UnitType].title
	if not (db and db.enable) then return end

	local title = frame.Title
	if not title then
		title = frame:CreateFontString(nil, "OVERLAY")
		title:SetWordWrap(false)
		frame.Title = title
	end

	title:FontTemplate(LSM:Fetch("font", db.font), db.fontSize, db.fontOutline)
	title:ClearAllPoints()
	title:SetPoint("TOP", frame.Name, "BOTTOM")
end

function NP:Update_Title(frame)
	local title = frame.Title
	if not title then return end

	local unit, unitType = frame.unit, frame.UnitType
	local units = self.db.units[unitType]
	local db = units.title
	local text, color

	if unit and db and db.enable and units.name.enable and not frame.Health:IsShown() then
		if unitType == "FRIENDLY_PLAYER" then
			local guildName = GetGuildInfo(unit)
			if guildName and IsGuildShown(db.visibility) then
				text, color = guildName, GetGuildColor(db.colors, unit, guildName)
			end
		elseif (unitType == "FRIENDLY_NPC" or unitType == "ENEMY_NPC") and not UnitPlayerControlled(unit) and not UnitIsDead(unit) then
			text = E.oUF.Tags.Env.GetTitleNPC(unit)

			if db.reactionColor then
				local reactions, reaction = self.db.colors.reactions, frame.UnitReaction or 4
				color = (reaction == 4 and reactions.neutral) or (reaction > 4 and reactions.good) or reactions.bad
			else
				color = db.color
			end
		end
	end

	if text then
		title:SetFormattedText(separators[db.separator] or "%s", text)
		title:SetTextColor(color.r, color.g, color.b)
		title:Show()
	else
		title:Hide()
	end
end
