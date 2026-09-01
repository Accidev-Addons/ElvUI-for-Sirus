local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local date = date
local FormatShortDate = FormatShortDate

local displayString

local function OnClick()
    _G.GameTimeFrame:Click()
end

local function OnEvent(self)
	local dateTable = date('*t')

	self.text:SetText(FormatShortDate(dateTable.day, dateTable.month, dateTable.year):gsub('([/.])', displayString))
end

local function ApplySettings(_, hex)
	displayString = hex..'%1|r'
end

DT:RegisterDatatext('Date', nil, { 'UPDATE_INSTANCE_INFO' }, OnEvent, nil, OnClick, nil, nil, L["Date"], nil, ApplySettings)
