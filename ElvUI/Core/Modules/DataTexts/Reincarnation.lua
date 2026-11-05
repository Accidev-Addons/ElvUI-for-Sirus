local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

if E.myclass ~= 'SHAMAN' then return end

local floor, format, strjoin = floor, format, strjoin
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local IsInInstance = IsInInstance
local IsSpellKnown = IsSpellKnown
local SendChatMessage = SendChatMessage

local READY = READY
local SPELL_FAILED_NOT_KNOWN = SPELL_FAILED_NOT_KNOWN
local TIME_REMAINING = TIME_REMAINING

local SPELL_ID, REAGENT_ID = 20608, 17030
local SPELL_NAME = GetSpellInfo(SPELL_ID) or 'Reincarnation'
local ICON = [[Interface\Icons\Spell_Nature_Reincarnation]]
local iconString = '|T%s:20:20:0:0:64:64:4:55:4:55|t'
local displayString = ''

local function GetRemaining()
	local start, duration = GetSpellCooldown(SPELL_ID)
	if start and start > 0 and duration and duration > 2 then
		return duration - (GetTime() - start)
	end
end

local function FormatTime(remaining)
	return format('%d:%02d', floor(remaining / 60), floor(remaining % 60))
end

local function UpdateText(self)
	local remaining, text

	if not IsSpellKnown(SPELL_ID) then
		text = SPELL_FAILED_NOT_KNOWN
	else
		remaining = GetRemaining()
		text = remaining and FormatTime(remaining) or READY..'!'
	end

	self.text:SetFormattedText(displayString, format(iconString, ICON), text)

	return remaining
end

local function OnUpdate(self, elapsed)
	self.reincarnationElapsed = (self.reincarnationElapsed or 0) + elapsed
	if self.reincarnationElapsed < 0.5 then return end

	self.reincarnationElapsed = 0

	if not UpdateText(self) then
		self:SetScript('OnUpdate', nil)
	end
end

local function OnEvent(self)
	self:SetScript('OnUpdate', UpdateText(self) and OnUpdate or nil)
end

local function OnClick(_, button)
	if button ~= 'LeftButton' or not IsSpellKnown(SPELL_ID) then return end

	local _, instanceType = IsInInstance()
	local channel = (instanceType == 'raid' and 'RAID') or (instanceType == 'party' and 'PARTY')
	if not channel then return end

	local remaining = GetRemaining()
	local status = remaining and format('%s %s', TIME_REMAINING, FormatTime(remaining)) or READY..'!'

	SendChatMessage(format('%s - %s', SPELL_NAME, status), channel)
end

local function OnEnter()
	DT.tooltip:ClearLines()
	DT.tooltip:AddLine(SPELL_NAME)
	DT.tooltip:AddLine(' ')

	local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(REAGENT_ID)
	if name then
		DT.tooltip:AddDoubleLine(strjoin('', format(iconString, texture), ' ', name), GetItemCount(REAGENT_ID), 1, 1, 1)
	end

	DT.tooltip:Show()
end

local function ApplySettings(_, hex)
	displayString = strjoin('', '%s ', hex, '%s|r')
end

DT:RegisterDatatext('Reincarnation', nil, { 'PLAYER_ENTERING_WORLD', 'SPELL_UPDATE_COOLDOWN' }, OnEvent, nil, OnClick, OnEnter, nil, SPELL_NAME, nil, ApplySettings)
