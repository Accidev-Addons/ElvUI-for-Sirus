local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local M = E:GetModule("Misc")

local ipairs, pairs, tremove = ipairs, pairs, tremove
local gsub, strmatch, strsub = gsub, strmatch, strsub

local CreateFrame = CreateFrame
local ChatTypeInfo = ChatTypeInfo

NP.ChatBubbleEvents = {
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_MONSTER_SAY",
	"CHAT_MSG_MONSTER_YELL"
}

local bubbles, pool = {}, {}

local function Release(bubble)
	if not bubble.author then return end

	if bubbles[bubble.author] == bubble then
		bubbles[bubble.author] = nil
	end

	if bubble.plate then
		bubble.plate.ChatBubble = nil
		bubble.plate = nil
	end

	bubble.author = nil
	E:UIFrameFadeRemoveFrame(bubble)
	bubble:Hide()
	pool[#pool + 1] = bubble
end

local function FadeFinished(bubble)
	if bubble.fadeInfo.mode == "OUT" then
		Release(bubble)
	end
end

local function Expire(bubble, token)
	if bubble.token ~= token then return end

	if bubble.plate then
		E:UIFrameFadeOut(bubble, 0.2, bubble:GetAlpha(), 0)
	else
		Release(bubble)
	end
end

local function Attach(bubble, frame)
	bubble.plate = frame
	frame.ChatBubble = bubble

	bubble.text:ClearAllPoints()
	bubble.text:SetPoint("BOTTOM", frame, "TOP", 0, 20)
	bubble:Show()
end

local function Acquire(name)
	local bubble = tremove(pool)
	if not bubble then
		bubble = CreateFrame("Frame")
		bubble:Hide()

		local text = bubble:CreateFontString(nil, "OVERLAY")
		text:SetJustifyH("CENTER")
		text:SetJustifyV("MIDDLE")
		text:SetWordWrap(true)
		text:SetNonSpaceWrap(true)
		bubble.text = text

		bubble:SetPoint("TOPLEFT", text, -15, 15)
		bubble:SetPoint("BOTTOMRIGHT", text, 15, -15)
		M:SkinBubble(bubble)

		bubble.FadeObject = { finishedFuncKeep = true, finishedArg1 = bubble, finishedFunc = FadeFinished }
	end

	bubble.author = name
	bubbles[name] = bubble

	return bubble
end

local function ShowBubble(frame, name, msg, author, guid, info)
	local bubble = bubbles[name]
	local isNew = not bubble
	if isNew then
		bubble = Acquire(name)
	end

	if bubble.plate ~= frame then
		if bubble.plate then
			bubble.plate.ChatBubble = nil
		end

		Attach(bubble, frame)
	end

	local text = bubble.text
	text:SetWidth(0)
	text:SetText(msg)
	if text:GetStringWidth() > 300 then
		text:SetWidth(300)
	end
	text:SetTextColor(info.r, info.g, info.b)

	M.UpdateBubbleBorder(bubble)

	if E.private.general.chatBubbleName then
		M:AddChatBubbleName(bubble, guid, author)
	end

	E:UIFrameFadeIn(bubble, 0.2, isNew and 0 or bubble:GetAlpha(), 1)

	local token = (bubble.token or 0) + 1
	bubble.token = token

	local _, words = gsub(msg, "%s+", "")
	E:Delay(2 + 0.5 * words, Expire, bubble, token)
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, msg, author, _, _, _, _, _, channelID, _, _, _, guid)
	if not (msg and author) then return end

	local chatType = strsub(event, 10)
	if chatType == "CHANNEL" then
		chatType = "CHANNEL"..channelID
	end

	local info = ChatTypeInfo[chatType]
	if not info then return end

	local name = strmatch(author, "^[^%-]+") or author
	for frame in pairs(NP.VisiblePlates) do
		if frame.UnitName == name then
			ShowBubble(frame, name, msg, author, guid, info)
			return
		end
	end
end)

function NP:ChatBubble_OnShow(frame)
	local bubble = frame.UnitName and bubbles[frame.UnitName]
	if bubble and not bubble.plate then
		Attach(bubble, frame)
	end
end

function NP:ChatBubble_OnHide(frame)
	local bubble = frame.ChatBubble
	if bubble then
		frame.ChatBubble = nil
		bubble.plate = nil
		bubble:Hide()
	end
end

function NP:UpdateChatBubbles()
	local db = self.db.chatBubbles
	eventFrame:UnregisterAllEvents()

	if db.enable then
		for _, event in ipairs(NP.ChatBubbleEvents) do
			if db[event] then
				eventFrame:RegisterEvent(event)
			end
		end
	end
end
