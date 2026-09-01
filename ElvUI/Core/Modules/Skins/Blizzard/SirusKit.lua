local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local ipairs = ipairs
local find = string.find
local hooksecurefunc = hooksecurefunc
local pairs = pairs
local GetInventoryItemLink = GetInventoryItemLink
local GetItemGem = GetItemGem
local IsModifiedClick = IsModifiedClick
local IsControlKeyDown = IsControlKeyDown
local C_ItemSocketInfo = C_ItemSocketInfo
local SocketInventoryItem = SocketInventoryItem
local CloseSocketInfo = CloseSocketInfo
local HideUIPanel = HideUIPanel
local ClickSocketButton = ClickSocketButton
local SendServerMessage = SendServerMessage
local GetItemIcon = GetItemIcon
local GetItemInfo = GetItemInfo
local GameTooltip = GameTooltip
local GameTooltip_Hide = GameTooltip_Hide
local ITEMSOCKET_TO_GET_BRILLIANT = ITEMSOCKET_TO_GET_BRILLIANT
local CreateFrame = CreateFrame
local strmatch = string.match
local gsub = string.gsub
local sub = string.sub
local strtrim = strtrim
local utf8sub = utf8.sub
local lower = string.lower

local ENCHANT_TEXT_MAX_LENGTH = 20

local function HideAtlasTexture(texture)
	hooksecurefunc(texture, "SetAtlas", function(self)
		self:SetAlpha(0)
	end)
	texture:SetAlpha(0)
end

local function GetElement(frame, key)
	return frame[key] or (frame.GetName and _G[frame:GetName()..key])
end

function S:UpdateTemplateScale(frame)
	if not frame or not frame.template or not frame.GetEffectiveScale then return end

	local scale = frame:GetEffectiveScale()
	if not scale or scale <= 0 or frame.templateScale == scale then return end

	frame.templateScale = scale

	frame:SetTemplate(frame.template, frame.glossTex, frame.ignoreUpdates, frame.forcePixelMode, frame.isUnitFrameElement, frame.isNamePlateElement)
end

function S:HandleSirusPortrait(frame)
	if not frame then return end

	local titleText = GetElement(frame, "TitleText")
	if not titleText then return end

	local overlay = GetElement(frame, "PortraitOverlay")
	if overlay then
		overlay:SetAlpha(1)

		if overlay.portrait then overlay.portrait:SetAlpha(0) end
		if frame.portraitFrame then frame.portraitFrame:SetAlpha(0) end
	end

	titleText:Show()
	titleText:SetAlpha(1)
	titleText:FontTemplate(nil, nil, "NONE")
	titleText:SetTextColor(1, 1, 1)

	if overlay and titleText.GetParent and titleText:GetParent() == overlay then
		titleText:ClearAllPoints()
		titleText:SetPoint("TOP", frame, "TOP", 0, -5)
		titleText:SetJustifyH("CENTER")
	end
end

function S:HandleSirusFrame(frame, createBackdrop, noStrip)
	if not frame then return end

	S:HandlePortraitFrame(frame, createBackdrop, noStrip)
	S:HandleSirusPortrait(frame)

	if not noStrip then
		for _, key in next, { "Background", "Background2" } do
			local object = GetElement(frame, key)
			if object and object.IsObjectType and object:IsObjectType("Texture") then
				HideAtlasTexture(object)
			end
		end

		for _, key in next, { "InsetLeft", "InsetRight", "LeftInset", "RightInset" } do
			local object = GetElement(frame, key)
			if object and object ~= frame then
				object:StripTextures()
			end
		end
	end
end

function S:DisableFrameInteraction(frame)
	if not frame then return end
	frame:Hide()
	frame:SetAlpha(0)
	frame:EnableMouse(false)
	frame:SetHitRectInsets(0, 0, 0, 0)
	frame:SetScript("OnShow", function(self)
		self:Hide()
	end)
end

local function ReplacePlain(text, search, replacement)
	local start = find(text, search, 1, true)
	while start do
		text = sub(text, 1, start - 1)..replacement..sub(text, start + #search)
		start = find(text, search, start + #replacement, true)
	end
	return text
end

local function ShortenEnchantText(text)
	if not text then return end

	text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = gsub(text, "|r", "")
	text = lower(text)
	text = gsub(text, "^зачарование:%s*", "")
	text = gsub(text, "^зачаровано:%s*", "")
	text = gsub(text, "\194\160", " ")
	text = gsub(text, "%s+", " ")
	text = strtrim(text)
	text = ReplacePlain(text, "+", "")
	text = gsub(text, "^%s*([0-9]+)%s*", "%1 ")
	local originalNumber = strmatch(text, "^(%d+)")
	text = gsub(text, "[Ии]%s+увеличение скорости передвижения на%s+(%d+%%%s*)", " и %1 бег")
	text = gsub(text, "увеличение скорости передвижения на%s+(%d+%%%s*)", "%1 бег")

	local replacements = {
		{"к силе заклинаний", "спд"},
		{"к силе заклинания", "спд"},
		{"силе заклинаний", "спд"},
		{"силе заклинания", "спд"},
		{"сила заклинаний", "спд"},
		{"сила заклинания", "спд"},
		{"к проникающей способности заклинаний", "пен"},
		{"проникающей способности заклинаний", "пен"},
		{"к силе атаки", "са"},
		{"силе атаки", "са"},
		{"к критическому удару", "крит"},
		{"к рейтингу критического удара", "крит"},
		{"рейтингу критического удара", "крит"},
		{"к пробиванию брони", "проб"},
		{"к рейтингу пробивания брони", "проб"},
		{"рейтингу пробивания брони", "проб"},
		{"к устойчивости", "уст"},
		{"к рейтингу устойчивости", "уст"},
		{"рейтингу устойчивости", "уст"},
		{"к меткости", "метк"},
		{"к рейтингу меткости", "метк"},
		{"рейтингу меткости", "метк"},
		{"к скорости", "скор"},
		{"к рейтингу скорости", "скор"},
		{"рейтингу скорости", "скор"},
		{"к мастерству", "маст"},
		{"к рейтингу мастерства", "маст"},
		{"рейтингу мастерства", "маст"},
		{"к защите", "защ"},
		{"к рейтингу защиты", "защ"},
		{"рейтингу защиты", "защ"},
		{"к выносливости", "вын"},
		{"к выносливость", "вын"},
		{"выносливости", "вын"},
		{"выносливость", "вын"},
		{"к ловкости", "лов"},
		{"ловкость", "лов"},
		{"к интеллекту", "инт"},
		{"интеллект", "инт"},
		{"к духу", "дух"},
		{"к броне", "бр"},
		{"броня", "бр"},
		{"к сопротивлению", "сопр"},
		{"сопротивление", "сопр"},
	}

	for _, replacement in ipairs(replacements) do
		text = ReplacePlain(text, replacement[1], replacement[2])
	end

	text = ReplacePlain(text, "заклинаний", "спд")
	text = ReplacePlain(text, "заклинания", "спд")
	text = ReplacePlain(text, "устойчивости", "уст")
	text = ReplacePlain(text, "увеличение скорости передвижения на", "бег")
	local bombText = lower(text)
	if find(bombText, "отцепить от пояса", 1, true) and find(bombText, "кобальтов", 1, true) and find(bombText, "бомб", 1, true) then
		return "бомбы"
	end
	text = ReplacePlain(text, "отцепить от пояса и бросить кобальтовую осколочную бомбу", "бомбы")
	text = ReplacePlain(text, "бомбы, которая нано", "бомбы")
	text = ReplacePlain(text, "дар собирателя", "дар собирателя")
	text = ReplacePlain(text, "использование:", "")

	text = strtrim(gsub(text, "%s+", " "))
	local number, suffix = strmatch(text, "^[^0-9]*(%d+)(.*)$")
	if originalNumber then
		return originalNumber..suffix
	elseif number then
		return number..suffix
	end
	return utf8sub(text, 1, ENCHANT_TEXT_MAX_LENGTH)
end

local function GetCharacterInfoSetting(name)
	local characterInfo = E.db and E.db.general and E.db.general.characterInfo
	if not characterInfo or characterInfo[name] == nil then
		return name == "showGems"
	end

	return characterInfo[name]
end

function S:UpdateCharacterEquipmentSockets()
	if not CharacterFrame or not CharacterFrame:IsShown() then return end

	for slotName, inventorySlot in pairs(S.characterEquipmentSlots or {}) do
		local slotFrame = _G["Character"..slotName]
		if slotFrame then
			S:HandleSirusEquipmentSocketInfo(slotFrame, inventorySlot, S.characterEquipmentAnchors[slotName], slotName)
		end
	end
end

local function GetSirusEnchantText(inventorySlot, slotName, fallbackText)
	if not E.ScanTooltip or not inventorySlot then return ShortenEnchantText(fallbackText) end
	if slotName ~= "NeckSlot" and slotName ~= "WaistSlot" and slotName ~= "MainHandSlot" and slotName ~= "SecondaryHandSlot" and slotName ~= "RangedSlot" then return ShortenEnchantText(fallbackText) end

	local enchantText
	local tooltip = E.ScanTooltip
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	local hasItem = tooltip:SetInventoryItem("player", inventorySlot)
	if not hasItem then
		tooltip:Hide()
		return ShortenEnchantText(fallbackText)
	end

	tooltip:Show()
	local tooltipData = tooltip.GetTooltipData and tooltip:GetTooltipData()
	local function CheckText(text)
		if not text then return end

		text = gsub(text, "^|c%x%x%x%x%x%x%x%x", "")
		text = gsub(text, "|r$", "")
		text = gsub(text, "^%s+", "")
		local normalized = lower(text)

		if slotName == "MainHandSlot" or slotName == "SecondaryHandSlot" or slotName == "RangedSlot" then
			if find(normalized, "зачаровано:", 1, true) or find(normalized, "зачарование:", 1, true) then
				return ShortenEnchantText(strtrim(text))
			end
		elseif slotName == "NeckSlot" and find(normalized, "дар собирателя", 1, true) then
			return ShortenEnchantText("Дар собирателя")
		elseif slotName == "WaistSlot" and find(normalized, "использование:", 1, true) then
			return ShortenEnchantText(text)
		end
	end

	if tooltipData and tooltipData.lines then
		for _, line in next, tooltipData.lines do
			enchantText = CheckText(line and line.leftText) or CheckText(line and line.rightText)
			if enchantText then break end
		end
	end

	if not enchantText then
		for lineIndex = 1, tooltip:NumLines() do
			local left = _G["ElvUI_ScanTooltipTextLeft"..lineIndex]
			local right = _G["ElvUI_ScanTooltipTextRight"..lineIndex]
			enchantText = CheckText(left and left:GetText()) or CheckText(right and right:GetText())
			if enchantText then break end
		end
	end

	tooltip:Hide()
	if slotName == "MainHandSlot" or slotName == "SecondaryHandSlot" or slotName == "RangedSlot" then
		return ShortenEnchantText(enchantText)
	end

	return ShortenEnchantText(enchantText or fallbackText)
end

function S:HandleSirusEquipmentSocketInfo(slotFrame, inventorySlot, anchor, slotName)
	if not slotFrame or not inventorySlot then return end
	anchor = anchor or "RIGHT"
	local info = slotFrame.sirusSocketInfo
	if not info then
		info = CreateFrame("Frame", nil, slotFrame)
		info:SetFrameLevel(slotFrame:GetFrameLevel() + 1)
		info.slots = {}
		info.socketRow = CreateFrame("Frame", nil, info)
		info.socketRow:SetSize(45, 15)
		info.enchant = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		info.enchant:SetTextColor(0.1, 1, 0.1)
		info.enchant:SetWordWrap(false)
		info.enchant:SetJustifyH("CENTER")
		slotFrame.sirusSocketInfo = info
	end

	local link = GetInventoryItemLink("player", inventorySlot)
	local socketCount = 0
	local enchantText
	local showGems = GetCharacterInfoSetting("showGems")
	local showEnchants = GetCharacterInfoSetting("showEnchants")
	if link then
		if showEnchants and E.GetGearSlotInfo then
			local gearInfo = E:GetGearSlotInfo("player", inventorySlot, true)
			if type(gearInfo) == "table" and slotName ~= "MainHandSlot" and slotName ~= "SecondaryHandSlot" and slotName ~= "RangedSlot" then
				enchantText = gearInfo.enchantText
			end
		end

		if showEnchants then
			enchantText = GetSirusEnchantText(inventorySlot, slotName, enchantText)
		end
	end
	if not showGems then
		socketCount = 0
	end

	if link and showGems then
		for index = 1, 3 do
			local gemName, gemLink = GetItemGem(link, index)
			if gemName or gemLink then
				socketCount = socketCount + 1
				local socket = info.slots[socketCount]
				if not socket then
					socket = CreateFrame("Button", nil, info.socketRow)
					socket:SetSize(14, 14)
					socket.Icon = socket:CreateTexture(nil, "ARTWORK")
					socket.Icon:SetAllPoints()
					socket:ClearAllPoints()
								if anchor == "TOP" then
						if slotName == "MainHandSlot" then
							socket:SetPoint("BOTTOM", info.socketRow, "BOTTOM", 0, (socketCount - 1) * 15)
						else
							socket:SetPoint("BOTTOM", info.socketRow, "BOTTOM", 0, (socketCount - 1) * 15)
						end
					elseif anchor == "RIGHT" then
						socket:SetPoint("LEFT", info.socketRow, "LEFT", (socketCount - 1) * 15, 0)
					else
						socket:SetPoint("RIGHT", info.socketRow, "RIGHT", -(socketCount - 1) * 15, 0)
					end
					info.slots[socketCount] = socket				end

				local gemTexture = GetItemIcon(gemLink or gemName)
				socket.Icon:SetTexture(gemTexture or E.Media.Textures.White8x8)
				socket.Icon:SetTexCoord(unpack(E.TexCoords))
				socket.itemLink = gemLink or gemName
				socket.inventorySlot = inventorySlot
				socket.socketIndex = socketCount
				socket.anchor = anchor
				socket.slotName = slotName
				local gemDisplayName = gemName or (gemLink and GetItemInfo(gemLink))
				socket.canExtract = gemDisplayName and (
					find(gemDisplayName, "черный", 1, true) or
					find(gemDisplayName, "Черный", 1, true) or
					find(gemDisplayName, "ЧЕРНЫЙ", 1, true)
				)
				socket:SetScript("OnEnter", function(self)
					if self.itemLink then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetHyperlink(self.itemLink)
						if self.canExtract then
							GameTooltip:AddLine(ITEMSOCKET_TO_GET_BRILLIANT or "<Нажмите Ctrl и щелкните левой кнопкой мыши, чтобы достать камень.>", 0, 0.8, 1)
						end
						GameTooltip:Show()
					end
				end)

				socket:SetScript("OnLeave", GameTooltip_Hide)
				socket:SetScript("OnClick", function(self, button)
					if button ~= "LeftButton" or not IsModifiedClick() or not IsControlKeyDown() then return end
					local socketIndex = self.socketIndex
					SocketInventoryItem(self.inventorySlot)
					if C_ItemSocketInfo and C_ItemSocketInfo.CanRemoveGem and C_ItemSocketInfo.CanRemoveGem(socketIndex) then
						if C_ItemSocketInfo.RemoveGem then
							C_ItemSocketInfo.RemoveGem(socketIndex)
						elseif ClickSocketButton then
							ClickSocketButton(socketIndex)
						end
					elseif SendServerMessage then
						SendServerMessage("ACMSG_REMOVE_SOCKET_FROM_ITEM", string.format("%d:%d:%d", -1, self.inventorySlot, socketIndex))
					end
					if CloseSocketInfo then CloseSocketInfo() end
					if ItemSocketingFrame then HideUIPanel(ItemSocketingFrame) end
					local owner = self:GetParent():GetParent():GetParent()
					if owner and owner.sirusSocketInfo then
						owner.sirusSocketInfo:Hide()
					end
				end)
				socket:RegisterForClicks("AnyUp")

				if not socket.backdrop then
					socket:CreateBackdrop("Default")
				end
				socket:Show()
			end
		end
	end

	info:ClearAllPoints()
	local isMainHand = slotName == "MainHandSlot"
	local isOffHand = slotName == "SecondaryHandSlot"
	local isRanged = slotName == "RangedSlot"

	if anchor == "TOP" then
			info:SetSize(220, 46)
			if isMainHand then
				info:SetPoint("TOPRIGHT", slotFrame, "BOTTOMLEFT", -3, -3)
			elseif isOffHand then
				info:SetPoint("TOPLEFT", slotFrame, "BOTTOMRIGHT", 3, -3)
			else
				info:SetPoint("BOTTOM", slotFrame, "TOP", 0, 4)
			end
	else		info:SetSize(220, 31)
		if anchor == "RIGHT" then
			info:SetPoint("LEFT", slotFrame, "RIGHT", 3, 0)
		else
			info:SetPoint("RIGHT", slotFrame, "LEFT", -3, 0)
		end
	end

	info.socketRow:ClearAllPoints()
	info.enchant:ClearAllPoints()
	info.enchant:SetSize(220, 14)
	if anchor == "TOP" then
		info.socketRow:SetSize(15, 45)
		info.socketRow:SetPoint("BOTTOM", slotFrame, "TOP", 0, 3)
	else
		info.socketRow:SetSize(45, 15)
		if anchor == "RIGHT" then
			info.socketRow:SetPoint("LEFT", slotFrame, "RIGHT", 3, -3)
		else
			info.socketRow:SetPoint("RIGHT", slotFrame, "LEFT", -3, -3)
		end
	end
	if enchantText then
		enchantText = ShortenEnchantText(enchantText)
		info.enchant:SetText(enchantText)
		if anchor == "TOP" then
			info.enchant:SetJustifyH("RIGHT")
			if isMainHand then
				info.enchant:SetPoint("BOTTOMRIGHT", slotFrame, "BOTTOMLEFT", -3, 1)
			elseif isOffHand then
				info.enchant:SetJustifyH("LEFT")
				info.enchant:SetPoint("BOTTOMLEFT", slotFrame, "BOTTOMRIGHT", 3, -3)
			elseif isRanged then
				info.enchant:SetJustifyH("LEFT")
				info.enchant:SetPoint("LEFT", slotFrame, "RIGHT", 3, -3)
			else
				info.enchant:SetJustifyH("CENTER")
				info.enchant:SetPoint("BOTTOM", info.socketRow, "TOP", 0, 1)
			end
		elseif anchor == "RIGHT" then
			info.enchant:SetJustifyH("LEFT")
			info.enchant:SetPoint("BOTTOMLEFT", info.socketRow, "TOPLEFT", 0, 1)
		else
			info.enchant:SetJustifyH("RIGHT")
			info.enchant:SetPoint("BOTTOMRIGHT", info.socketRow, "TOPRIGHT", 0, 1)
		end
		info.enchant:Show()
	else
		info.enchant:Hide()
	end

	if socketCount == 0 and not enchantText then
		info:Hide()
	else
		for index = socketCount + 1, #info.slots do
			info.slots[index].itemLink = nil
			info.slots[index].inventorySlot = nil
			info.slots[index].socketIndex = nil
			info.slots[index]:Hide()
		end
		info:Show()
	end
end

function S:HandleSirusScrollFrame(scrollFrame, createBackdrop)
	if not scrollFrame then return end

	scrollFrame:StripTextures()

	if createBackdrop then
		scrollFrame:CreateBackdrop(createBackdrop == true and "Transparent" or createBackdrop)
	end

	local scrollBar = scrollFrame.ScrollBar or scrollFrame.scrollBar or (scrollFrame.GetName and _G[scrollFrame:GetName().."ScrollBar"])
	if scrollBar then
		S:HandleSirusScrollBar(scrollBar)
	end
end

function S:HandleSirusTab(tab, previousTab)
	if not tab then return end

	tab:StripTextures()
	S:HandleTab(tab, true)
	tab.isSkinned = true

	tab:CreateBackdrop()
	if tab.backdrop then
		tab.backdrop:ClearAllPoints()
		tab.backdrop:Point("TOPLEFT", 0, -3)
		tab.backdrop:Point("BOTTOMRIGHT", 0, 3)
	end

	if previousTab then
		tab:ClearAllPoints()
		tab:Point("TOPLEFT", previousTab, "TOPRIGHT", 2, 0)
	end
end

function S:HandleSirusTabFlow(tabs, onUpdate)
	if not tabs then return end

	local function Reflow()
		local lastShown
		for i, tab in ipairs(tabs) do
			if tab then
				if lastShown then
					tab:ClearAllPoints()
					tab:Point("TOPLEFT", lastShown, "TOPRIGHT", 2, 0)
				end

				if tab:IsShown() then
					lastShown = tab
				end
			end
		end
	end

	if type(onUpdate) == "string" then
		local func = _G[onUpdate]
		if func then
			hooksecurefunc(onUpdate, Reflow)
		end
	end

	Reflow()
end

function S:HandleSirusTabSystem(tabSystem)
	if not tabSystem then return end

	for _, tab in next, { tabSystem:GetChildren() } do
		if not tab.isSkinned then
			if tab.RotatedTextures then
				for _, texture in ipairs(tab.RotatedTextures) do
					texture:SetTexture()
				end
			end

			local highlight = tab.GetHighlightTexture and tab:GetHighlightTexture()
			if highlight then highlight:SetTexture() end

			tab:CreateBackdrop("Default")
			if tab.backdrop then
				tab.backdrop:Point("TOPLEFT", 3, -3)
				tab.backdrop:Point("BOTTOMRIGHT", -3, 1)
			end

			tab.isSkinned = true
		end
	end
end

function S:HandleSirusButton(button, strip, ...)
	if button then S:HandleButton(button, strip, ...) end
end

function S:HandleSirusDropDown(dropDown, width)
	if dropDown then S:HandleDropDownBox(dropDown, width) end
end

function S:HandleSirusCloseButton(closeButton, ...)
	if closeButton then S:HandleCloseButton(closeButton, ...) end
end

function S:HandleSirusIconButton(button, icon, iconBorder)
	if not button or not icon then return end

	local texture = icon:GetTexture()

	icon:SetTexCoords()
	button:CreateBackdrop("Default")
	if button.backdrop then
		icon:SetParent(button.backdrop)
		button.backdrop:SetOutside(icon, 1, 1)
	end

	if texture then icon:SetTexture(texture) end

	if iconBorder then
		S:HandleIconBorder(iconBorder, button.backdrop or icon)
	end
end

function S:HandleSirusToggle(toggle, texture)
	if not toggle then return end

	toggle:StripTextures()
	S:HandleButton(toggle)
	toggle:SetNormalTexture(texture)
	if toggle.GetNormalTexture then toggle:GetNormalTexture():SetInside() end
	toggle:SetPushedTexture(texture)
	if toggle.GetPushedTexture then toggle:GetPushedTexture():SetInside() end
	toggle:SetHighlightTexture("")

	return toggle
end

function S:HandleSirusStatusBar(statusBar)
	if not statusBar then return end

	statusBar:StripTextures()
	statusBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(statusBar)
	statusBar:CreateBackdrop("Default")

	return statusBar
end

function S:HandleSirusCollapseToggle(button, size)
	if not button then return end

	button:SetNormalTexture(E.Media.Textures.Plus)
	button.SetNormalTexture = E.noop
	button:GetNormalTexture():Size(size or 16)
	button:SetHighlightTexture(nil)

	hooksecurefunc(button, "SetNormalTexture", function(self, texture)
		if find(texture, "MinusButton") then
			self:GetNormalTexture():SetTexture(E.Media.Textures.Minus)
		elseif find(texture, "PlusButton") then
			self:GetNormalTexture():SetTexture(E.Media.Textures.Plus)
		end
	end)

	return button
end

function S:SetSirusCollapseIcon(button, collapsed)
	if not button then return end

	local texture = button.collapseArrow or (button.GetNormalTexture and button:GetNormalTexture())
	if not texture then return end

	texture:SetTexture(collapsed and E.Media.Textures.Plus or E.Media.Textures.Minus)
end

function S:HandleSirusSearchRow(searchBox, filterButton)
	if searchBox then S:HandleEditBox(searchBox) end

	if filterButton then
		filterButton:StripTextures(true)
		S:HandleButton(filterButton)

		local height = searchBox and searchBox:GetHeight()
		if height and height > 0 then
			filterButton:SetHeight(height)
		end
	end
end

function S:HandleSirusScrollBar(scrollBar)
	if not scrollBar or scrollBar.sirusStyled then return end
	scrollBar.sirusStyled = true

	if scrollBar.Track and scrollBar.Track.Thumb and not scrollBar.GetThumbTexture then
		local track = scrollBar.Track
		track:StripTextures()
		track:CreateBackdrop("Transparent")
		if track.backdrop then
			track.backdrop:ClearAllPoints()
			track.backdrop:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
			track.backdrop:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", 0, 0)
		end

		local thumb = track.Thumb
		thumb:StripTextures()
		thumb:CreateBackdrop(nil, true, true, nil, nil, nil, nil, nil, (scrollBar:GetFrameLevel() or 0) + 1)
		if thumb.backdrop then
			thumb.backdrop:ClearAllPoints()
			thumb.backdrop:SetPoint("TOPLEFT", thumb, "TOPLEFT", 0, 0)
			thumb.backdrop:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", 0, 0)
			thumb.backdrop:SetBackdropColor(unpack(E.media.rgbvaluecolor))
		end

		if thumb.Begin then thumb.Begin:Kill() end
		if thumb.Middle then thumb.Middle:Kill() end
		if thumb.End then thumb.End:Kill() end

		if scrollBar.Back then
			S:HandleNextPrevButton(scrollBar.Back, "up")
			scrollBar.Back:Size(12)
		end

		if scrollBar.Forward then
			S:HandleNextPrevButton(scrollBar.Forward, "down")
			scrollBar.Forward:Size(12)
		end

		return
	end

	if scrollBar.GetObjectType and scrollBar:GetObjectType() ~= "Slider" and scrollBar.GetThumb then
		S:HandleScrollBar(scrollBar)
		return
	end

	S:HandleScrollBar(scrollBar)

	scrollBar:SetWidth(8)
	local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
	if thumb then
		thumb:SetWidth(8)

		if thumb:GetHeight() < 1 then
			thumb:SetHeight(24)
		end
	end

	if scrollBar.backdrop then
		scrollBar.backdrop:ClearAllPoints()
		scrollBar.backdrop:Point("TOPLEFT", scrollBar, "TOPLEFT", 0, 0)
		scrollBar.backdrop:Point("BOTTOMRIGHT", scrollBar, "BOTTOMRIGHT", 0, 0)
	end

	local name = scrollBar:GetName()
	local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton or scrollBar.ScrollUp or (name and (_G[name.."ScrollUpButton"] or _G[name.."UpButton"] or _G[name.."ScrollUp"]))
	local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton or scrollBar.ScrollDown or (name and (_G[name.."ScrollDownButton"] or _G[name.."DownButton"] or _G[name.."ScrollDown"]))
	if not (upButton and downButton) then return end

	upButton:Size(12)
	downButton:Size(12)

	local function UpdateArrows()
		local minValue, maxValue = scrollBar:GetMinMaxValues()
		local value = scrollBar:GetValue()
		local scrollable = maxValue > minValue

		upButton:SetShown(scrollable and value > minValue + 0.05)
		downButton:SetShown(scrollable and value < maxValue - 0.05)
	end

	scrollBar:HookScript("OnValueChanged", UpdateArrows)
	scrollBar:HookScript("OnMinMaxChanged", UpdateArrows)
	scrollBar:HookScript("OnShow", UpdateArrows)
	UpdateArrows()
end

function S:HandleSirusNavBar(navBar)
	if not navBar or navBar.isSkinned then return end

	navBar:StripTextures()
	if navBar.overlay then navBar.overlay:StripTextures() end

	local function SkinButton(button)
		if not button or button.isSkinned then return end
		S:HandleButton(button, true)
		S:ApplyElvUIFont(button)
		button.xoffset = 1

		local arrow = button.MenuArrowButton
		if arrow then
			if arrow.NormalTexture then arrow.NormalTexture:Hide() end
			if arrow.PushedTexture then arrow.PushedTexture:Hide() end
			if arrow.HighlightTexture then arrow.HighlightTexture:Hide() end

			if arrow.Art then
				arrow.Art:SetVertexColor(1, 1, 1)
				arrow:HookScript("OnEnter", function(self)
					if self.Art then self.Art:SetVertexColor(1, 0.82, 0) end
				end)
				arrow:HookScript("OnLeave", function(self)
					if self.Art then self.Art:SetVertexColor(1, 1, 1) end
				end)
			end
		end

		button.isSkinned = true
	end

	SkinButton(navBar.home)

	if navBar.navList then
		for _, button in ipairs(navBar.navList) do
			SkinButton(button)
		end
	end

	if _G.NavBar_AddButton then
		hooksecurefunc("NavBar_AddButton", function(self)
			if self ~= navBar then return end
			SkinButton(self.navList[#self.navList])
		end)
	end

	navBar.isSkinned = true
end
