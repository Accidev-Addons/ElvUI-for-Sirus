local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local floor, strjoin = floor, strjoin
local GetInstanceInfo = GetInstanceInfo
local GetTime = GetTime

local displayString, db = ''
local timerText, timer, startTime = L["Combat"], 0, 0

local function UpdateText()
	return floor(timer/60), timer % 60, (timer - floor(timer)) * 100
end

local function OnUpdate(self)
	timer = GetTime() - startTime
	self.text:SetFormattedText(displayString, timerText, UpdateText())
end

local function DelayOnUpdate(self, elapsed)
	startTime = startTime - elapsed
	if startTime <= 0 then
		timer, startTime = 0, GetTime()
		self:SetScript('OnUpdate', OnUpdate)
	end
end

local function OnEvent(self, event, _, timeSeconds)
	local _, instanceType = GetInstanceInfo()
	local inArena = instanceType == 'arena'
	timerText = db.NoLabel and '' or inArena and L["Arena"] or L["Combat"]

	if inArena and event == 'START_TIMER' then
		timer, startTime = 0, timeSeconds
		self.text:SetFormattedText(displayString, timerText, UpdateText())
		self:SetScript('OnUpdate', DelayOnUpdate)
	elseif not inArena and event == 'PLAYER_REGEN_ENABLED' then
		self:SetScript('OnUpdate', nil)
	elseif not inArena and event == 'PLAYER_REGEN_DISABLED' then
		timer, startTime = 0, GetTime()
		self:SetScript('OnUpdate', OnUpdate)
	elseif not self.text:GetText() or event == 'ELVUI_FORCE_UPDATE' then
		self.text:SetFormattedText(displayString, timerText, UpdateText())
	end
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	displayString = strjoin('', '%s', db.NoLabel and '' or ': ', hex, (db.TimeFull and '%02d|cFFFFFFFF:|r%02d|cFFFFFFFF:|r%02d' or '%02d|cFFFFFFFF:|r%02d')..'|r')
end

DT:RegisterDatatext('Combat', nil, { 'START_TIMER', 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED' }, OnEvent, nil, nil, nil, nil, L["Combat/Arena Time"], nil, ApplySettings)
