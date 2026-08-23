local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local format, strjoin = format, strjoin

local C_Talent = C_Talent
local GetEquipmentSetInfo = GetEquipmentSetInfo
local GetNumEquipmentSets = GetNumEquipmentSets
local GetTalentTabInfo = GetTalentTabInfo
local IsResting = IsResting
local IsShiftKeyDown = IsShiftKeyDown
local MouseIsOver = MouseIsOver
local ToggleTalentFrame = ToggleTalentFrame
local UseEquipmentSet = UseEquipmentSet

local TALENT_TAB_NAME = TALENT_TAB_NAME

local mainIcon = '|T%s:%d:%d:0:0:64:64:4:60:4:60|t'
local listIcon = '|T%s:20:20:0:0:64:64:4:60:4:60|t'

local displayString = '%s %s'
local displayNoIcon = '%s'

local db, synced
local activeGroup, maxGroups, selectedIndex = 1, 1, 1

local function GetGroupInfo(index)
	local name, texture = C_Talent.GetTalentGroupSettings(index)

	if not name or name == '' or not texture then
		local tabIndex = C_Talent.GetPrimaryTabIndexForTalentGroup(index)

		if tabIndex and tabIndex > 0 then
			local tabName, tabTexture = GetTalentTabInfo(tabIndex, false, false, index <= 2 and index or 1)

			if not name or name == '' then name = tabName end
			if not texture then texture = tabTexture end
		end
	end

	if not name or name == '' then
		name = format(TALENT_TAB_NAME, index)
	end

	return name, texture
end

local function SwitchEquipmentSet()
	local cache = C_Talent.GetSpecInfoCache()
	local setName = C_Talent.GetTalentGroupSettings((cache and cache.activeTalentGroup) or activeGroup)
	if not setName or setName == '' then return end

	for i = 1, GetNumEquipmentSets() do
		local name = GetEquipmentSetInfo(i)
		if name and name == setName then
			UseEquipmentSet(name)
			return
		end
	end
end

local function OnEnter()
	DT.tooltip:ClearLines()

	for i = 1, maxGroups do
		local name, texture = GetGroupInfo(i)
		local icon = texture and format(listIcon, texture) or ''
		local line = i == activeGroup and format(L["%s %s (Current)"], icon, name) or format('%s %s', icon, name)

		if i == selectedIndex then
			DT.tooltip:AddLine(line, .31, .99, .46)
		else
			DT.tooltip:AddLine(line, 1, 1, 1)
		end
	end

	DT.tooltip:AddLine(' ')
	DT.tooltip:AddDoubleLine(L["Left Click:"], format(L["Change specialization to %s"], (GetGroupInfo(selectedIndex))), 1, 1, 1, 1, 1, 0)
	DT.tooltip:AddDoubleLine(L["Right Click:"], L["Open Talent Frame"], 1, 1, 1, 1, 1, 0)
	DT.tooltip:AddDoubleLine(L["Mouse Wheel:"], L["Select Specialization"], 1, 1, 1, 1, 1, 0)
	DT.tooltip:AddDoubleLine(L["Shift + Middle Click:"], L["Auto Equipment Set"]..': '..((db and db.autoEquipmentSet) and L["Enabled"] or L["Disabled"]), 1, 1, 1, 1, 1, 0)

	DT.tooltip:Show()
end

local function OnMouseWheel(_, delta)
	local index = selectedIndex - delta

	if index > maxGroups then
		index = maxGroups
	elseif index < 1 then
		index = 1
	end

	selectedIndex = index

	OnEnter()
end

local function OnEvent(self)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	self:EnableMouseWheel(true)
	self:SetScript('OnMouseWheel', OnMouseWheel)

	maxGroups = C_Talent.GetNumTalentGroups() or 1
	if maxGroups < 1 then maxGroups = 1 end

	local cache = C_Talent.GetSpecInfoCache()
	activeGroup = (cache and cache.activeTalentGroup) or C_Talent.GetActiveTalentGroup() or 1

	if not synced and C_Talent.IsSpecInfoLoaded() then
		synced = true
		selectedIndex = activeGroup
	end

	if selectedIndex > maxGroups then selectedIndex = maxGroups end
	if selectedIndex < 1 then selectedIndex = 1 end

	local name, texture = GetGroupInfo(activeGroup)
	local size = (db and db.iconSize) or 16
	local icon = texture and format(mainIcon, texture, size, size)

	if icon and db and db.iconOnly then
		self.text:SetText(icon)
	elseif icon then
		self.text:SetFormattedText(displayString, icon, name)
	else
		self.text:SetFormattedText(displayNoIcon, name)
	end
end

local function OnClick(self, button)
	if button == 'LeftButton' then
		if selectedIndex == C_Talent.GetSelectedTalentGroup() then return end

		C_Talent.SelectTalentGroup(selectedIndex)

		if selectedIndex > 2 then
			C_Talent.SelectedCurrency(IsResting() and 1 or 2)
			C_Talent.SetActiveTalentGroup(selectedIndex)

			if db and db.autoEquipmentSet then
				E:Delay(11, SwitchEquipmentSet)
				E:Delay(12, SwitchEquipmentSet)
			end
		else
			C_Talent.SetActiveTalentGroup(selectedIndex)

			if db and db.autoEquipmentSet then
				E:Delay(6, SwitchEquipmentSet)
				E:Delay(7, SwitchEquipmentSet)
			end
		end
	elseif button == 'RightButton' then
		ToggleTalentFrame()
	elseif button == 'MiddleButton' and IsShiftKeyDown() then
		if db then
			db.autoEquipmentSet = not db.autoEquipmentSet
		end

		E:Delay(0.01, function()
			if MouseIsOver(self) then
				DT.OnEnter(self)
			end
		end)
	end
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	displayString = strjoin('', '%s ', hex, '%s|r')
	displayNoIcon = strjoin('', hex, '%s|r')
end

DT:RegisterDatatext('Talent Specialization', nil, { 'PLAYER_ENTERING_WORLD', 'CHARACTER_POINTS_CHANGED', 'PLAYER_TALENT_UPDATE', 'ACTIVE_TALENT_GROUP_CHANGED', 'PLAYER_TALENT_UPDATE_EX', 'PLAYER_TALENT_NOTES_UPDATE' }, OnEvent, nil, OnClick, OnEnter, nil, L["Talent Specialization"], nil, ApplySettings)
