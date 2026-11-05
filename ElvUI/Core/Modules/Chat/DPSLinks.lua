local E, L, V, P, G = unpack(ElvUI)
local CH = E:GetModule('Chat')

local _G = _G
local format, gsub, ipairs, tinsert, tonumber = format, gsub, ipairs, tinsert, tonumber
local strfind, strmatch = strfind, strmatch

local GetTime = GetTime

local Meters = {}

local channelEvents = {
	'CHAT_MSG_CHANNEL',
	'CHAT_MSG_GUILD',
	'CHAT_MSG_OFFICER',
	'CHAT_MSG_PARTY',
	'CHAT_MSG_PARTY_LEADER',
	'CHAT_MSG_RAID',
	'CHAT_MSG_RAID_LEADER',
	'CHAT_MSG_SAY',
	'CHAT_MSG_WHISPER',
	'CHAT_MSG_WHISPER_INFORM',
	'CHAT_MSG_YELL',
	'CHAT_MSG_BN_WHISPER',
	'CHAT_MSG_BN_WHISPER_INFORM',
}

local firstLines = {
	'^Recount - (.*)$',
	'^Skada: (.*) for (.*):$',
	'^Skada: (.*) por (.*):$',
	'^Skada: (.*) für (.*):$',
	'^Skada: (.*) pour (.*):$',
	'^Skada: (.*) для (.*):$',
	'^(.*) 의 Skada 보고 (.*):$',
	'^Отчёт Skada: (.*), с (.*):$',
	'^Skada报告(.*)的(.*):$',
	'^Skada:(.*)來自(.*):$',
	'^(.*) Done for (.*)$',
	'^Details!:(.*)$',
}

local nextLines = {
	'^(%d+)%. (.*)$',
	'^ (%d+). (.*)$',
	'^.*%%%)$',
	'^(%d+). (.*):(.*)(%d+)(.*)(%d+)%%(.*)%((%d+)%)$',
}

local function FilterLine(event, source, msg)
	local now = GetTime()

	for _, pattern in ipairs(nextLines) do
		if strmatch(msg, pattern) then
			for i = #Meters, 1, -1 do
				local meter = Meters[i]
				if now - meter.time >= 6 then break end

				if meter.src == source and meter.evt == event then
					for _, line in ipairs(meter.data) do
						if line == msg then return true end
					end

					tinsert(meter.data, msg)
					return true
				end
			end
		end
	end

	for _, pattern in ipairs(firstLines) do
		if strmatch(msg, pattern) then
			if strfind(msg, '|cff(.+)|r') then
				msg = gsub(gsub(msg, '|cff%w%w%w%w%w%w', ''), '|r', '')
			end

			local id
			for i = #Meters, 1, -1 do
				local meter = Meters[i]
				if now - meter.time >= 1 then break end

				if meter.src == source and meter.evt == event then
					id = i
					break
				end
			end

			if not id then
				id = #Meters + 1
				Meters[id] = { src = source, evt = event, time = now, data = {}, title = msg }
			end

			return format('|Hedl:%d|h|cFFFFFF00[%s]|r|h', id, msg)
		end
	end
end

local function ParseChatEvent(_, event, msg, sender, ...)
	local result = FilterLine(event, sender, msg)
	if result == true then
		return true
	elseif result then
		return false, result, sender, ...
	end
end

function CH:ShowDPSLink(data)
	local meter = Meters[tonumber(strmatch(data, '^edl:(%d+)'))]
	if not meter then return end

	local tooltip = _G.ItemRefTooltip
	if not tooltip:IsShown() then
		tooltip:SetOwner(_G.UIParent, 'ANCHOR_PRESERVE')
	end

	tooltip:ClearLines()
	tooltip:AddLine(meter.title)
	tooltip:AddLine(format(L["Reported by %s"], meter.src))

	for _, line in ipairs(meter.data) do
		tooltip:AddLine(line, 1, 1, 1)
	end

	tooltip:Show()
end

function CH:UpdateDPSLinks()
	local enabled = CH.Initialized and E.db.chat.dpsLinks

	for _, event in ipairs(channelEvents) do
		if enabled then
			_G.ChatFrame_AddMessageEventFilter(event, ParseChatEvent)
		else
			_G.ChatFrame_RemoveMessageEventFilter(event, ParseChatEvent)
		end
	end
end
