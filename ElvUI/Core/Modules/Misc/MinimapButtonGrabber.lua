local E, L, V, P, G = unpack(ElvUI)
local MBG = E:GetModule('MinimapButtonGrabber')
local S = E:GetModule('Skins')

local _G = _G

local CreateFrame = CreateFrame
local GetAddOnInfo = GetAddOnInfo
local GetMouseFocus = GetMouseFocus
local GetNumAddOns = GetNumAddOns
local Minimap = Minimap

local GameTooltip = GameTooltip
local GameTooltip_Hide = GameTooltip_Hide

local TooltipSetOwner = GameTooltip.SetOwner
local TooltipSetPoint = GameTooltip.SetPoint
local TooltipClearAllPoints = GameTooltip.ClearAllPoints

local floor, format, gsub, ipairs, max, min, pcall, select, sort, strfind, strlower, strmatch, strsub, tinsert, type, unpack, wipe =
	math.floor, format, gsub, ipairs, math.max, math.min, pcall, select, sort, strfind, strlower, strmatch, strsub, tinsert, type, unpack, wipe

local BUTTON_SIZE = 26
local ROW_HEIGHT = 22
local MAX_ROWS = 8
local MIN_PANEL_WIDTH = 200
local ICON_ONLY_WIDTH = 44
local ROW_EXTRA = 54
local SCROLLBAR_WIDTH = 14
local FALLBACK_ICON = [[Interface\Icons\INV_Misc_QuestionMark]]

local function GetDB()
	local db = E.private.general.minimapButtonGrabber
	if type(db) == 'table' then return db end
end

local function ShowNames()
	local db = GetDB()
	return not db or db.showNames ~= false
end

local function IsMouseInside(frame)
	if not frame then return false end

	local focus = GetMouseFocus()
	while focus do
		if focus == frame then return true end
		focus = focus.GetParent and focus:GetParent()
	end
end

local rowsList = {}

local minimapFrames = { _G.Minimap, _G.MinimapBackdrop, _G.MinimapCluster }

local ignoreButtons = {
	ElvConfigToggle = true,
	BattlefieldMinimap = true,
	ButtonCollectFrame = true,
	GameTimeFrame = true,
	MiniMapBattlefieldFrame = true,
	MiniMapBattlefieldDropDownButton = true,
	MiniMapLFGFrame = true,
	MiniMapMailFrame = true,
	MiniMapPing = true,
	MiniMapRecordingButton = true,
	MiniMapTracking = true,
	MiniMapTrackingButton = true,
	MiniMapTrackingDropDownButton = true,
	MiniMapVoiceChatFrame = true,
	MiniMapVoiceChatDropDownButton = true,
	MiniMapWorldMapButton = true,
	MinimapToggleButton = true,
	MinimapZoneTextButton = true,
	MinimapZoomIn = true,
	MinimapZoomOut = true,
	TimeManagerClockButton = true,
	QueueStatusMinimapButton = true,
}

local genericIgnores = {
	'GuildInstance',
	'GatherMatePin',
	'GatherNote',
	'GuildMap3Mini',
	'HandyNotesPin',
	'LibRockConfig-1.0_MinimapButton',
	'NauticusMiniIcon',
	'WestPointer',
	'poiMinimap',
	'Spy_MapNoteList_mini',
}

local partialIgnores = {
	'Node',
	'Note',
	'Pin',
}

local whiteList = {
	'LibDBIcon',
}

local panelAnchors = {
	LEFT = { 'LEFT', 'RIGHT', 4, 0 },
	RIGHT = { 'RIGHT', 'LEFT', -4, 0 },
	TOP = { 'TOPLEFT', 'TOPRIGHT', 4, 0 },
	BOTTOM = { 'BOTTOMLEFT', 'BOTTOMRIGHT', 4, 0 },
	TOPLEFT = { 'TOPLEFT', 'TOPRIGHT', 4, 0 },
	TOPRIGHT = { 'TOPRIGHT', 'TOPLEFT', -4, 0 },
	BOTTOMLEFT = { 'BOTTOMLEFT', 'BOTTOMRIGHT', 4, 0 },
	BOTTOMRIGHT = { 'BOTTOMRIGHT', 'BOTTOMLEFT', -4, 0 },
}

local buttonFunctions = {
	'SetParent',
	'SetFrameStrata',
	'SetFrameLevel',
	'ClearAllPoints',
	'SetPoint',
	'SetScale',
	'SetSize',
	'SetWidth',
	'SetHeight',
}

local function FindAddonForButton(button)
	local name = button:GetName()
	if not name then return end
	local lower = strlower(name)
	local tail = strmatch(lower, '^.*_(.+)$')
	local num = GetNumAddOns()
	local weak

	for i = 1, num do
		local raw, title = GetAddOnInfo(i)
		if raw then
			local display = E:GetAddOnDisplayName(raw)
			local candidates = { strlower(display), strlower(raw) }
			local titleStrip = gsub(strlower(title or ''), '%s+', '')
			if titleStrip ~= '' then
				tinsert(candidates, titleStrip)
			end
			for c = 1, #candidates do
				local candidate = candidates[c]
				if candidate ~= '' then
					if strsub(lower, 1, #candidate) == candidate then
						return i
					end
					if tail and tail == candidate then
						return i
					end
				end
			end
		end
	end

	for i = 1, num do
		local raw = GetAddOnInfo(i)
		if raw then
			local display = E:GetAddOnDisplayName(raw)
			local prefix = gsub(display, '^([^_%-]+)[_%-].*$', '%1')
			if prefix ~= display then
				prefix = strlower(prefix)
				if strsub(lower, 1, #prefix) == prefix then
					return i
				end
				if tail and tail == prefix then
					return i
				end
				if tail and not weak and strsub(prefix, 1, #tail) == tail then
					weak = i
				end
			end
		end
	end

	return weak
end

local function IsMinimapButton(button)
	if not button or not button.IsObjectType or not button:IsObjectType('Button') then return false end
	local name = button:GetName()
	if not name then return false end

	if strsub(name, 1, 6) == 'ElvUI_' then return false end

	for i = 1, #whiteList do
		if strsub(name, 1, #whiteList[i]) == whiteList[i] then
			return true
		end
	end

	if ignoreButtons[name] then return false end

	for i = 1, #genericIgnores do
		if strsub(name, 1, #genericIgnores[i]) == genericIgnores[i] then return false end
	end

	for i = 1, #partialIgnores do
		if strfind(name, partialIgnores[i]) then return false end
	end

	return true
end

local function ScanMinimapButtons()
	local found = {}
	for _, frame in ipairs(minimapFrames) do
		if frame then
			for i = 1, frame:GetNumChildren() do
				local child = select(i, frame:GetChildren())
				if child and child.IsObjectType and child ~= MBG.Frame and IsMinimapButton(child) then
					tinsert(found, child)
				end
			end
		end
	end

	if _G.AtlasButton then tinsert(found, _G.AtlasButton) end
	if _G.FishingBuddyMinimapButton then tinsert(found, _G.FishingBuddyMinimapButton) end
	if _G.HealBot_MMButton then tinsert(found, _G.HealBot_MMButton) end

	return found
end

local function OnRowsMouseWheel(_, delta)
	local maxOffset = max(0, #rowsList - MAX_ROWS)
	MBG.offset = min(max(0, MBG.offset - delta * 3), maxOffset)
	MBG:UpdateRows()
end

local function OnVerticalScroll(_, offset)
	MBG.offset = floor((offset / ROW_HEIGHT) + 0.5)
	MBG:UpdateRows()
end

local function ForwardClick(row, click)
	local button = row.button
	if not button then return end

	local onClick = button:GetScript('OnClick')
	if onClick then
		onClick(button, click, false)
		return
	end

	local onDown = button:GetScript('OnMouseDown')
	if onDown then onDown(button, click) end

	local onUp = button:GetScript('OnMouseUp')
	if onUp then onUp(button, click) end
end

local function AnchorTooltip(row)
	TooltipSetOwner(GameTooltip, row, 'ANCHOR_NONE')
	TooltipClearAllPoints(GameTooltip)

	if MBG.tooltipSide == 'LEFT' then
		TooltipSetPoint(GameTooltip, 'TOPRIGHT', row, 'BOTTOMRIGHT', 0, -2)
	else
		TooltipSetPoint(GameTooltip, 'TOPLEFT', row, 'BOTTOMLEFT', 0, -2)
	end
end

local function ForwardTooltip(row)
	local button = row.button
	if not button then return end

	local onEnter = button:GetScript('OnEnter')
	if not onEnter then
		if row.label then
			AnchorTooltip(row)
			GameTooltip:AddLine(row.label, 1, 0.82, 0)
			GameTooltip:Show()
		end
		return
	end

	local setOwner, setPoint, clearAllPoints = GameTooltip.SetOwner, GameTooltip.SetPoint, GameTooltip.ClearAllPoints

	GameTooltip.SetOwner = function() AnchorTooltip(row) end
	GameTooltip.SetPoint = E.noop
	GameTooltip.ClearAllPoints = E.noop

	local ok, err = pcall(onEnter, button, true)

	GameTooltip.SetOwner, GameTooltip.SetPoint, GameTooltip.ClearAllPoints = setOwner, setPoint, clearAllPoints

	if not ok then
		GameTooltip_Hide()
		E:Print(format('MinimapButtonGrabber: %s', tostring(err)))
	end
end

local function OnRowEnter(self)
	ForwardTooltip(self)
end

local function OnRowLeave(self)
	local button = self.button
	local onLeave = button and button:GetScript('OnLeave')
	if onLeave then
		pcall(onLeave, button)
	end

	GameTooltip_Hide()
end

local function CreateRow(i)
	local row = CreateFrame('Button', nil, MBG.ScrollFrame)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint('TOPLEFT', 4, -(i - 1) * ROW_HEIGHT)
	row:SetPoint('RIGHT', MBG.ScrollFrame, 'RIGHT', -4, 0)
	row:SetHighlightTexture(E.media.blankTex)
	row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.12)
	row:GetHighlightTexture():SetAllPoints()
	row:EnableMouseWheel(true)
	row:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp')
	row:SetScript('OnMouseWheel', OnRowsMouseWheel)
	row:SetScript('OnClick', ForwardClick)
	row:SetScript('OnEnter', OnRowEnter)
	row:SetScript('OnLeave', OnRowLeave)
	row.name = row:CreateFontString(nil, 'OVERLAY')
	row.name:FontTemplate(nil, 12)
	row.name:SetJustifyH('LEFT')
	row.name:SetPoint('LEFT', 8, 0)
	row.name:SetPoint('RIGHT', row, 'RIGHT', -30, 0)

	row.icon = row:CreateTexture(nil, 'ARTWORK')
	row.icon:SetSize(18, 18)
	row.icon:SetPoint('RIGHT', -6, 0)

	return row
end

local function GetButtonIcon(button)
	for i = 1, button:GetNumRegions() do
		local region = select(i, button:GetRegions())
		if region and region:GetObjectType() == 'Texture' then
			local texture = region:GetTexture()
			if texture and not (strfind(texture, 'Border') or strfind(texture, 'Background') or strfind(texture, 'AlphaMask')) then
				return region
			end
		end
	end
end

function MBG:LockButton(button)
	for i = 1, #buttonFunctions do
		button[buttonFunctions[i]] = E.noop
	end
end

function MBG:SkinButton(button)
	if not button or button.isSkinned then return end
	local name = button:GetName()
	if not name then return end

	button:SetParent(MBG.HiddenHolder)
	button:Hide()
	MBG:LockButton(button)

	local ok, err = pcall(function()
		button:SetPushedTexture(nil)
		button:SetHighlightTexture(nil)
		button:SetDisabledTexture(nil)

		button.__addonIndex = FindAddonForButton(button)
		button.__icon = GetButtonIcon(button)
	end)

	button.isSkinned = true
	tinsert(MBG.skinnedButtons, button)
	MBG.dirty = true

	if not ok then
		E:Print(format('MinimapButtonGrabber: %s (%s)', tostring(err), name))
	end
end

function MBG:GrabMinimapButtons()
	if not MBG.HiddenHolder then return end

	local buttons = ScanMinimapButtons()
	for i = 1, #buttons do
		local button = buttons[i]
		if not button.isSkinned then
			MBG:SkinButton(button)
		end
	end
end

function MBG:BuildRows()
	wipe(rowsList)
	for i = 1, #MBG.skinnedButtons do
		local button = MBG.skinnedButtons[i]
		local index = button.__addonIndex
		local label = index and (E:GetAddOnDisplayName(GetAddOnInfo(index)) or '') or (button:GetName() or '?')
		tinsert(rowsList, { label = label, name = strlower(label), iconRegion = button.__icon, button = button })
	end
	sort(rowsList, function(a, b) return a.name < b.name end)
	MBG:UpdateBadge()
end

function MBG:UpdateRows()
	if not MBG.Rows then return end

	local maxOffset = max(0, #rowsList - MAX_ROWS)
	MBG.offset = min(MBG.offset, maxOffset)

	E:SyncFauxScrollBar(_G['ElvUI_MinimapButtonGrabberScrollFrameScrollBar'], MBG.offset, maxOffset, ROW_HEIGHT)

	local showNames = ShowNames()

	for i = 1, MAX_ROWS do
		local row = MBG.Rows[i]
		local entry = rowsList[MBG.offset + i]
		row.button = entry and entry.button
		row.label = entry and entry.label

		if not entry then
			row:Hide()
		else
			row:Show()

			row.icon:SetTexture((entry.iconRegion and entry.iconRegion:GetTexture()) or FALLBACK_ICON)
			row.icon:SetTexCoord(unpack(E.TexCoords))
			row.icon:ClearAllPoints()

			if showNames then
				row.icon:Point('RIGHT', -6, 0)
				row.name:SetText(entry.label or '???')
				row.name:SetTextColor(unpack(E.media.rgbvaluecolor))
				row.name:Show()
			else
				row.icon:Point('CENTER', 0, 0)
				row.name:Hide()
			end
		end
	end
end

function MBG:UpdatePanelSize()
	if not MBG.Frame or not MBG.Measure then return end

	local width = ICON_ONLY_WIDTH

	if ShowNames() then
		width = MIN_PANEL_WIDTH

		for i = 1, #rowsList do
			MBG.Measure:SetText(rowsList[i].label or '')
			local w = MBG.Measure:GetStringWidth()
			if w then
				width = max(width, w + ROW_EXTRA)
			end
		end
	end

	if #rowsList > MAX_ROWS then
		width = width + SCROLLBAR_WIDTH
	end

	MBG.Frame:SetWidth(width)
end

function MBG:UpdateBadge()
	if MBG.BadgeText then
		MBG.BadgeText:SetText(#rowsList)
	end
end

function MBG:Refresh()
	if not MBG.Frame then return end

	local rows = min(#rowsList, MAX_ROWS)
	MBG.Frame:SetHeight(rows * ROW_HEIGHT + 8)

	local child = MBG.ScrollFrame and MBG.ScrollFrame.ScrollChildFrame
	if child then
		child:SetHeight(max(#rowsList * ROW_HEIGHT + 8, 1))
	end

	MBG:UpdateRows()
	MBG:UpdatePanelSize()
end

function MBG:Show()
	local db = GetDB()
	if not db or not db.enable then return end
	if not MBG.Frame then return end

	MBG.offset = 0
	MBG:GrabMinimapButtons()
	MBG:BuildRows()
	MBG.dirty = false
	MBG:UpdatePanelPosition()
	MBG.Frame:Show()
	MBG.Frame:Raise()
	MBG:Refresh()
end

function MBG:Hide()
	if MBG.Frame then
		MBG.Frame:Hide()
	end
end

function MBG:UpdateButtonState()
	if not MBG.Button then return end

	if MBG.Frame and MBG.Frame:IsShown() then
		MBG.Button:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	else
		MBG.Button:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end

	MBG:UpdateAlpha()
end

function MBG:Toggle()
	if MBG.Frame and MBG.Frame:IsShown() then
		MBG:Hide()
	else
		MBG:Show()
	end
end

function MBG:CreateButton()
	if MBG.Button then return end

	local button = CreateFrame('Button', 'ElvUI_MinimapButtonGrabberButton', Minimap)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetTemplate('Default')
	button:RegisterForClicks('LeftButtonUp')
	button:SetScript('OnClick', function() MBG:Toggle() end)

	local text = button:CreateFontString(nil, 'OVERLAY')
	text:FontTemplate(nil, 12, 'OUTLINE')
	text:SetAllPoints()
	text:SetJustifyH('CENTER')
	text:SetTextColor(1, 1, 1)
	MBG.Button = button
	MBG.BadgeText = text

	MBG:UpdateButtonPosition()
	MBG:UpdateBadge()
end

function MBG:UpdateAlpha()
	if not MBG.Button then return end

	local db = GetDB()
	if not db or not db.mouseover then
		MBG.Button:SetAlpha(1)
		return
	end

	local visible = (MBG.Frame and MBG.Frame:IsShown()) or MBG.Button:IsMouseOver() or (Minimap and Minimap:IsMouseOver())
	MBG.Button:SetAlpha(visible and 1 or 0)
end

local function OnFaderUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < 0.1 then return end

	self.elapsed = 0
	MBG:UpdateAlpha()
end

function MBG:UpdateMouseover()
	if not MBG.Button or not MBG.Fader then return end

	local db = GetDB()
	MBG.Fader:SetScript('OnUpdate', db and db.mouseover and OnFaderUpdate or nil)

	MBG:UpdateAlpha()
end

function MBG:UpdateSettings()
	MBG:UpdateButtonPosition()
	MBG:UpdateMouseover()
	MBG:Refresh()
end

function MBG:UpdateButtonPosition()
	if not MBG.Button then return end
	local db = GetDB()
	if not db then return end

	local position = db.position or 'TOPLEFT'
	MBG.Button:ClearAllPoints()
	MBG.Button:Point(position, Minimap, position, db.xOffset or 2, db.yOffset or -28)

	local difficulty = _G.MiniMapInstanceDifficulty
	if difficulty then
		MBG.Button:SetFrameLevel(difficulty:GetFrameLevel() + 2)
	end

	MBG:UpdatePanelPosition()
end

function MBG:UpdatePanelPosition()
	if not MBG.Frame or not MBG.Button then return end
	local db = GetDB()
	if not db then return end

	local position = db.position or 'TOPLEFT'
	local anchor = panelAnchors[position] or panelAnchors.TOPLEFT
	local point, relativePoint, x, y = anchor[1], anchor[2], anchor[3], anchor[4]

	MBG.tooltipSide = x > 0 and 'RIGHT' or 'LEFT'

	MBG.Frame:ClearAllPoints()
	MBG.Frame:Point(point, MBG.Button, relativePoint, x, y)
end

function MBG:CreateDropdown()
	if MBG.Frame then return end

	local frame = CreateFrame('Frame', 'ElvUI_MinimapButtonGrabber', Minimap)
	frame:SetFrameStrata('DIALOG')
	frame:SetFrameLevel(50)
	frame:SetTemplate('Transparent')
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetToplevel(true)
	frame:SetWidth(MIN_PANEL_WIDTH)
	MBG.Frame = frame
	MBG.Rows = {}
	MBG.offset = 0

	tinsert(_G.UISpecialFrames, 'ElvUI_MinimapButtonGrabber')

	local scrollFrame = CreateFrame('ScrollFrame', 'ElvUI_MinimapButtonGrabberScrollFrame', frame, 'FauxScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -4)
	scrollFrame:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -4, 4)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript('OnVerticalScroll', OnVerticalScroll)
	scrollFrame:SetScript('OnMouseWheel', OnRowsMouseWheel)
	MBG.ScrollFrame = scrollFrame

	local scrollBar = _G['ElvUI_MinimapButtonGrabberScrollFrameScrollBar']
	if scrollBar then
		S:HandleSirusScrollBar(scrollBar)
	end

	local watcher = CreateFrame('Frame')
	watcher:SetScript('OnEvent', function()
		if IsMouseInside(frame) or IsMouseInside(MBG.Button) then return end

		MBG:Hide()
	end)

	frame:SetScript('OnShow', function()
		watcher:RegisterEvent('GLOBAL_MOUSE_DOWN')
		MBG:UpdateButtonState()
	end)

	frame:SetScript('OnHide', function()
		watcher:UnregisterEvent('GLOBAL_MOUSE_DOWN')
		MBG:UpdateButtonState()
	end)

	local measure = frame:CreateFontString(nil, 'ARTWORK')
	measure:FontTemplate(nil, 12)
	measure:Hide()
	MBG.Measure = measure

	for i = 1, MAX_ROWS do
		MBG.Rows[i] = CreateRow(i)
	end

	MBG:UpdatePanelPosition()
end

function MBG:Initialize()
	local db = GetDB()
	if not db or not db.enable or not E.private.general.minimap.enable then return end

	MBG.skinnedButtons = {}
	MBG.dirty = false
	MBG.HiddenHolder = CreateFrame('Frame', nil, UIParent)
	MBG.HiddenHolder:SetAllPoints(Minimap)
	MBG.HiddenHolder:Hide()
	MBG.Fader = CreateFrame('Frame')
	MBG:CreateButton()
	MBG:CreateDropdown()
	MBG:GrabMinimapButtons()
	MBG:BuildRows()
	MBG:UpdateMouseover()

	E:ScheduleRepeatingTimer(function()
		MBG:GrabMinimapButtons()
		if MBG.dirty then
			MBG.dirty = false
			MBG:BuildRows()
			if MBG.Frame and MBG.Frame:IsShown() then
				MBG:Refresh()
			end
		end
	end, 5)
end

E:RegisterModule(MBG:GetName())
