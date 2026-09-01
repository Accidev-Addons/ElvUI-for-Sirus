local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule('Misc')
local CH = E:GetModule('Chat')
local LSM = E.Libs.LSM

local select, unpack, ipairs = select, unpack, ipairs
local format = format
local strmatch, strlower, gmatch, gsub = strmatch, strlower, gmatch, gsub

local CreateFrame = CreateFrame
local PRIEST_COLOR = RAID_CLASS_COLORS.PRIEST
local UIParent = UIParent
local WorldFrame = WorldFrame
local WorldGetChildren = WorldFrame.GetChildren
local WorldGetNumChildren = WorldFrame.GetNumChildren

--Message caches
local messageToGUID = {}
local messageToSender = {}

local function ReplaceIconTags(value)
    local index = _G.ICON_TAG_LIST[strlower(value)]
    local icon = index and _G.ICON_LIST[index]
    if icon then
        return format('%s0|t', icon)
    end
end

function M:UpdateBubbleBorder()
    local holder = self
    local str = holder and holder.text
    if not str then return end

    local option = E.private.general.chatBubbles
    if option == 'backdrop' then
        holder:SetBackdropBorderColor(str:GetTextColor())
    elseif option == 'backdrop_noborder' then
        holder:SetBackdropBorderColor(0,0,0,0)
    end

    local name = self.Name and self.Name:GetText()
    if name then self.Name:SetText() end

    local text = str:GetText()
    if not text then return end

    if E.private.general.chatBubbleName then
        M:AddChatBubbleName(self, messageToGUID[text], messageToSender[text])
    end

    local rebuiltString
    if E.private.chat.enable and E.private.general.classColorMentionsSpeech then
        local isFirstWord
        if strmatch(text, '%s-%S+%s*') then
            for word in gmatch(text, '%s-%S+%s*') do
                local tempWord = gsub(word, '^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$', '%1%2')
                local lowerCaseWord = strlower(tempWord)

                local classMatch = CH.ClassNames[lowerCaseWord]
                local wordMatch = classMatch and lowerCaseWord

                if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
                    local classColorTable = E:ClassColor(classMatch)
                    if classColorTable then
                        word = gsub(word, gsub(tempWord, '%-','%%-'), format('|cff%.2x%.2x%.2x%s|r', classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
                    end
                end

                if not isFirstWord then
                    rebuiltString = word
                    isFirstWord = true
                else
                    rebuiltString = format('%s%s', rebuiltString, word)
                end
            end
        end
    end

    rebuiltString = gsub(rebuiltString or text, '{([^}]+)}', ReplaceIconTags)

    if rebuiltString ~= text then
        str:SetText(E:RemoveExtraSpaces(rebuiltString))
    end
end

function M:AddChatBubbleName(chatBubble, guid, name)
    if not name then return end

    local color = PRIEST_COLOR
    local data = guid and guid ~= '' and CH:GetPlayerInfoByGUID(guid)
    if data and data.classColor then
        color = data.classColor
    end

    chatBubble.Name:SetFormattedText('|c%s%s|r', color.colorStr, name)
    chatBubble.Name:SetWidth(chatBubble:GetWidth()-10)
end

local function SetFontTemplate(name, db)
	if db and db.replaceBubbleFont then
		local font, size, outline = LSM:Fetch('font', db.chatBubbleFont), db.chatBubbleFontSize, db.chatBubbleFontOutline
		name:FontTemplate(font, size * 0.85, outline)
	else
		local font, size, outline = name:GetFont()
		name:FontTemplate(font, size, outline)
	end
end

local yOffset --Value set in M:LoadChatBubbles()
function M:SkinBubble(frame)
    local db, mult, bubbleType = E.private.general, E.mult * UIParent:GetScale(), E.private.general.chatBubbles
    local r, g, b

    for _, region in ipairs({frame:GetRegions()}) do
        if region:IsObjectType('Texture') then
            region:SetTexture(nil)
        elseif region:IsObjectType('FontString') then
            frame.text, r, g, b = region, region:GetTextColor()
        end
    end

	if not frame.Name then
		local name = frame:CreateFontString(nil, 'BORDER')
		name:Height(10) --Width set in M:AddChatBubbleName()
		name:Point('BOTTOM', frame, 'TOP', 0, yOffset)
		name:SetFontObject('GameFontNormal')
		name:SetJustifyH('LEFT')

		SetFontTemplate(name, db)

		frame.Name = name
	end

    if bubbleType == 'backdrop' then
        if E.PixelMode then
            frame:SetBackdrop({
                bgFile = E.media.blankTex,
                edgeFile = E.media.blankTex,
                edgeSize = mult,
                insets = {left = 0, right = 0, top = 0, bottom = 0}
            })
            frame:SetBackdropColor(unpack(E.media.backdropfadecolor))
            frame:SetBackdropBorderColor(0, 0, 0)
        else
            frame.backdrop = frame.backdrop or frame:CreateTexture(nil, 'BACKGROUND')
            frame.backdrop:SetAllPoints(frame)
            frame.backdrop:SetTexture(unpack(E.media.backdropfadecolor))

			local border = frame:CreateTexture(nil, 'ARTWORK')
			border:SetPoint('TOPLEFT', -mult * 2, mult * 2)
			border:SetPoint('BOTTOMRIGHT', mult * 2, -mult * 2)
			border:SetTexture(r, g, b)

			local backdrop = frame:CreateTexture(nil, 'BORDER')
			backdrop:SetPoint('TOPLEFT', border, -mult, mult)
			backdrop:SetPoint('BOTTOMRIGHT', border, mult, -mult)
			backdrop:SetTexture(0, 0, 0)
        end
    elseif bubbleType == 'backdrop_noborder' then
        frame:SetBackdrop(nil)
        frame.backdrop = frame.backdrop or frame:CreateTexture(nil, 'ARTWORK')
        frame.backdrop:SetInside(frame, 4, 4)
        frame.backdrop:SetTexture(unpack(E.media.backdropfadecolor))
        frame:SetClampedToScreen(false)
    else
        frame:SetBackdrop(nil)
        frame:SetClampedToScreen(false)
    end

	SetFontTemplate(frame.text, db)

    frame:HookScript('OnShow', M.UpdateBubbleBorder)
    frame:SetFrameStrata('BACKGROUND')
    M.UpdateBubbleBorder(frame)

    frame.isSkinnedElvUI = true
end

function M:IsChatBubble(frame)
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region.GetTexture and region:GetTexture() and region:GetTexture() == [[Interface\Tooltips\ChatBubble-Background]] then
            return true
        end
    end
end

local function ChatBubble_OnEvent(self, event, msg, sender, _, _, _, _, _, _, _, _, _, guid)
    if not E.private.general.chatBubbleName then return end

    messageToGUID[msg] = guid
    messageToSender[msg] = sender
end

local lastChildern, numChildren = 0, 0
local function GetAllChatBubbles(...)
    for i = lastChildern + 1, numChildren do
        local frame = select(i, ...)
        if not frame.isSkinnedElvUI and M:IsChatBubble(frame) then
            M:SkinBubble(frame)
        end
    end
end

local function ChatBubble_OnUpdate()
    numChildren = WorldGetNumChildren(WorldFrame)
    if lastChildern ~= numChildren then
        GetAllChatBubbles(WorldGetChildren(WorldFrame))
        lastChildern = numChildren
    end
end

function M:LoadChatBubbles()
	yOffset = (E.private.general.chatBubbles == 'backdrop' and 2) or (E.private.general.chatBubbles == 'backdrop_noborder' and -2) or 0

    M.BubbleFrame = CreateFrame('Frame')
    M.BubbleFrame:RegisterEvent('CHAT_MSG_SAY')
    M.BubbleFrame:RegisterEvent('CHAT_MSG_YELL')
    M.BubbleFrame:RegisterEvent('CHAT_MSG_PARTY')
    M.BubbleFrame:RegisterEvent('CHAT_MSG_PARTY_LEADER')
    M.BubbleFrame:RegisterEvent('CHAT_MSG_MONSTER_SAY')
    M.BubbleFrame:RegisterEvent('CHAT_MSG_MONSTER_YELL')

    if E.private.general.chatBubbles ~= 'disabled' then
        M.BubbleFrame:SetScript('OnEvent', ChatBubble_OnEvent)
        M.BubbleTimer = M:ScheduleRepeatingTimer(ChatBubble_OnUpdate, 0.1)
    else
        M.BubbleFrame:SetScript('OnEvent', nil)
        M:CancelTimer(M.BubbleTimer)
        M.BubbleTimer = nil
    end
end