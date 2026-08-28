local E, L, V, P, G = unpack(ElvUI)
local MBG = E:GetModule('MinimapButtonGrabber')
local MM = E:GetModule('Minimap')

local _G = _G

local ceil, ipairs, select, strfind, strsub, tinsert, unpack, wipe =
	math.ceil, ipairs, select, strfind, strsub, tinsert, unpack, wipe

local CreateFrame = CreateFrame
local Minimap = _G.Minimap

local minimapFrames = {}

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
	Minimap = true,
	MinimapBackdrop = true,
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

local visibleButtons = {}

local function OnEnter()
	if not MBG.mouseover then return end

	E:UIFrameFadeIn(MBG.frame, 0.1, MBG.frame:GetAlpha(), MBG.maxAlpha)
end

local function OnLeave()
	if not MBG.mouseover then return end

	E:UIFrameFadeOut(MBG.frame, 0.1, MBG.frame:GetAlpha(), 0)
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

local function FixDBMButton()
	local button = _G.DBMMinimapButton
	if not button then return end

	if button:GetScript('OnMouseDown') then
		button:SetScript('OnMouseDown', nil)
		button:SetScript('OnMouseUp', nil)
	end
end

function MBG:LockButton(button)
	for i = 1, #buttonFunctions do
		button[buttonFunctions[i]] = E.noop
	end
end

function MBG:UnlockButton(button)
	for i = 1, #buttonFunctions do
		button[buttonFunctions[i]] = nil
	end
end

function MBG:CheckVisibility()
	local updateLayout

	for _, button in ipairs(MBG.skinnedButtons) do
		if button:IsVisible() and button.__hidden then
			button.__hidden = false
			updateLayout = true
		elseif not button:IsVisible() and not button.__hidden then
			button.__hidden = true
			updateLayout = true
		end
	end

	return updateLayout
end

function MBG:GetVisibleList()
	wipe(visibleButtons)

	for _, button in ipairs(MBG.skinnedButtons) do
		if button:IsVisible() then
			tinsert(visibleButtons, button)
		end
	end

	return visibleButtons
end

local function SkinButtonRegions(button)
	local name = button:GetName()

	for i = 1, button:GetNumRegions() do
		local region = select(i, button:GetRegions())

		if not region.__grabberSkinned and region:GetObjectType() == 'Texture' then
			region.__grabberSkinned = true

			local texture = region:GetTexture()

			if texture and (strfind(texture, 'Border') or strfind(texture, 'Background') or strfind(texture, 'AlphaMask')) then
				region:SetTexture(nil)
			elseif not (texture and strfind(texture, 'White8x8')) then
				if name == 'BagSync_MinimapButton' then
					region:SetTexture([[Interface\AddOns\BagSync\media\icon]])
				elseif name == 'DBMMinimapButton' then
					region:SetTexture([[Interface\Icons\INV_Helmet_87]])
				elseif name == 'OutfitterMinimapButton' then
					if texture == [[Interface\Addons\Outfitter\Textures\MinimapButton]] then
						region:SetTexture(nil)
					end
				elseif name == 'SmartBuff_MiniMapButton' then
					region:SetTexture([[Interface\Icons\Spell_Nature_Purge]])
				elseif name == 'VendomaticButtonFrame' then
					region:SetTexture([[Interface\Icons\INV_Misc_Rabbit_2]])
				end

				region:ClearAllPoints()
				region:SetInside()
				region:SetTexCoord(unpack(E.TexCoords))
				button:HookScript('OnLeave', function() region:SetTexCoord(unpack(E.TexCoords)) end)

				region:SetDrawLayer('ARTWORK')
				region.SetPoint = E.noop
				region.ClearAllPoints = E.noop
				region.SetAllPoints = E.noop
			end
		end
	end
end

function MBG:SkinMinimapButton(button)
	if not button or button.isSkinned then return end
	if not IsMinimapButton(button) then return end

	button:SetPushedTexture(nil)
	button:SetHighlightTexture(nil)
	button:SetDisabledTexture(nil)

	SkinButtonRegions(button)

	button:SetParent(MBG.frame)
	button:SetFrameLevel(MBG.frame:GetFrameLevel() + 5)
	button:SetTemplate()

	MBG:LockButton(button)

	button:SetScript('OnDragStart', nil)
	button:SetScript('OnDragStop', nil)

	button:HookScript('OnEnter', OnEnter)
	button:HookScript('OnLeave', OnLeave)

	button.__hidden = not button:IsVisible()
	button.isSkinned = true
	tinsert(MBG.skinnedButtons, button)

	MBG.needUpdate = true
end

function MBG:GrabMinimapButtons()
	FixDBMButton()

	for _, frame in ipairs(minimapFrames) do
		if frame then
			for i = 1, frame:GetNumChildren() do
				local object = select(i, frame:GetChildren())

				if object then
					MBG:SkinMinimapButton(object)
				end
			end
		end
	end

	if _G.AtlasButton then MBG:SkinMinimapButton(_G.AtlasButton) end
	if _G.FishingBuddyMinimapButton then MBG:SkinMinimapButton(_G.FishingBuddyMinimapButton) end
	if _G.HealBot_MMButton then MBG:SkinMinimapButton(_G.HealBot_MMButton) end

	for _, button in ipairs(MBG.skinnedButtons) do
		SkinButtonRegions(button)
	end

	if MBG.needUpdate or MBG:CheckVisibility() then
		MBG:UpdateLayout()
	end
end

function MBG:UpdateLayout()
	if #MBG.skinnedButtons == 0 then return end

	local db = E.db.general.minimapButtonGrabber
	local spacing = (db.backdrop and (E.Border + db.backdropSpacing) or E.Spacing)

	local buttons = MBG:GetVisibleList()

	if #buttons == 0 then
		MBG.frame:Size(db.buttonSize + (spacing * 2))
		MBG.frame.backdrop:Hide()
		MBG.needUpdate = false
		return
	end

	local numButtons = #buttons
	local buttonsPerRow = db.buttonsPerRow
	local numRows = ceil(numButtons / buttonsPerRow)

	if buttonsPerRow > numButtons then
		buttonsPerRow = numButtons
	end

	local barWidth = (db.buttonSize * buttonsPerRow) + (db.buttonSpacing * (buttonsPerRow - 1)) + spacing * 2
	local barHeight = (db.buttonSize * numRows) + (db.buttonSpacing * (numRows - 1)) + spacing * 2

	MBG.frame:Size(barWidth, barHeight)
	MBG.frame.mover:Size(barWidth, barHeight)

	if db.backdrop then
		MBG.frame.backdrop:Show()
	else
		MBG.frame.backdrop:Hide()
	end

	local verticalGrowth = (db.growFrom == 'TOPLEFT' or db.growFrom == 'TOPRIGHT') and 'DOWN' or 'UP'
	local horizontalGrowth = (db.growFrom == 'TOPLEFT' or db.growFrom == 'BOTTOMLEFT') and 'RIGHT' or 'LEFT'

	for i, button in ipairs(buttons) do
		MBG:UnlockButton(button)

		button:Size(db.buttonSize)
		button:ClearAllPoints()

		if i == 1 then
			local x, y
			if db.growFrom == 'TOPLEFT' then
				x, y = spacing, -spacing
			elseif db.growFrom == 'TOPRIGHT' then
				x, y = -spacing, -spacing
			elseif db.growFrom == 'BOTTOMLEFT' then
				x, y = spacing, spacing
			else
				x, y = -spacing, spacing
			end

			button:Point(db.growFrom, MBG.frame, db.growFrom, x, y)
		elseif (i - 1) % buttonsPerRow == 0 then
			if verticalGrowth == 'DOWN' then
				button:Point('TOP', buttons[i - buttonsPerRow], 'BOTTOM', 0, -db.buttonSpacing)
			else
				button:Point('BOTTOM', buttons[i - buttonsPerRow], 'TOP', 0, db.buttonSpacing)
			end
		elseif horizontalGrowth == 'RIGHT' then
			button:Point('LEFT', buttons[i - 1], 'RIGHT', db.buttonSpacing, 0)
		elseif horizontalGrowth == 'LEFT' then
			button:Point('RIGHT', buttons[i - 1], 'LEFT', -db.buttonSpacing, 0)
		end

		MBG:LockButton(button)
	end

	MBG.needUpdate = false
end

function MBG:UpdatePosition()
	local db = E.db.general.minimapButtonGrabber.insideMinimap

	MBG.frame:ClearAllPoints()

	if db.enable then
		MBG.frame:Point(db.position, Minimap, db.position, db.xOffset, db.yOffset)

		E:DisableMover(MBG.frame.mover.name)
	else
		MBG.frame:SetAllPoints(MBG.frame.mover)

		E:EnableMover(MBG.frame.mover.name)
	end
end

function MBG:UpdateAlpha()
	local db = E.db.general.minimapButtonGrabber

	MBG.maxAlpha = db.alpha

	if not db.mouseover then
		MBG.frame:SetAlpha(MBG.maxAlpha)
	end
end

function MBG:ToggleMouseover()
	local db = E.db.general.minimapButtonGrabber

	MBG.mouseover = db.mouseover

	MBG.frame:EnableMouse(db.mouseover)
	MBG.frame:SetAlpha(db.mouseover and 0 or db.alpha)
end

function MBG:UpdateSettings()
	if not MBG.Initialized then return end

	MBG:ToggleMouseover()
	MBG:UpdateAlpha()
	MBG:UpdatePosition()
	MBG:UpdateLayout()
end

function MBG:Initialize()
	if not E.private.general.minimapButtonGrabber.enable then return end
	if not E.private.general.minimap.enable then return end

	local db = E.db.general.minimapButtonGrabber
	local spacing = (db.backdrop and (E.Border + db.backdropSpacing) or E.Spacing)

	MBG.skinnedButtons = {}

	if _G.Minimap then tinsert(minimapFrames, _G.Minimap) end
	if _G.MinimapBackdrop then tinsert(minimapFrames, _G.MinimapBackdrop) end
	if _G.MinimapCluster then tinsert(minimapFrames, _G.MinimapCluster) end

	local frame = CreateFrame('Frame', 'ElvUI_MinimapButtonGrabber', E.UIParent)
	frame:Size(db.buttonSize + (spacing * 2))
	frame:Point('TOPRIGHT', MM.MapHolder or Minimap, 'BOTTOMRIGHT', 0, 1)
	frame:SetFrameStrata('MEDIUM')
	frame:SetClampedToScreen(true)
	frame:CreateBackdrop()
	frame:SetScript('OnEnter', OnEnter)
	frame:SetScript('OnLeave', OnLeave)
	MBG.frame = frame

	frame.backdrop:SetInside(frame, E.Spacing, E.Spacing)
	frame.backdrop:Hide()

	E:CreateMover(frame, 'MinimapButtonGrabberMover', L["Minimap Button Grabber"], nil, nil, nil, 'ALL,GENERAL', function() return E.db.general.minimapButtonGrabber.insideMinimap.enable end, 'maps,minimap,buttonGrabber', true)

	MBG.Initialized = true

	MBG:ToggleMouseover()
	MBG:UpdateAlpha()
	MBG:UpdatePosition()
	MBG:GrabMinimapButtons()

	MBG.GrabTimer = MBG:ScheduleRepeatingTimer('GrabMinimapButtons', 5)
end

E:RegisterModule(MBG:GetName())
