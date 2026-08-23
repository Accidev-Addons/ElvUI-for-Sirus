local E, L, V, P, G = unpack(ElvUI)
local AB = E:GetModule('ActionBars')
local LSM = E.Libs.LSM

local _G = _G
local ipairs, next, gsub = ipairs, next, gsub

local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local hooksecurefunc = hooksecurefunc

local Masque = E.Masque
local MasqueGroup = Masque and Masque:Group('ElvUI', 'Totem Bar')

local bar = CreateFrame('Frame', 'ElvUI_TotemBar', E.UIParent, 'SecureHandlerStateTemplate')
bar:SetFrameStrata('MEDIUM')

local SLOT_BORDER_COLORS = {
	summon					= {r = 0, g = 0, b = 0},
	[_G.EARTH_TOTEM_SLOT]	= {r = 0.23, g = 0.45, b = 0.13},
	[_G.FIRE_TOTEM_SLOT]	= {r = 0.58, g = 0.23, b = 0.10},
	[_G.WATER_TOTEM_SLOT]	= {r = 0.19, g = 0.48, b = 0.60},
	[_G.AIR_TOTEM_SLOT]		= {r = 0.42, g = 0.18, b = 0.74}
}

local SLOT_EMPTY_TCOORDS = {
	[_G.EARTH_TOTEM_SLOT]	= {left = 0.52, right = 0.75, top = 0.01, bottom = 0.13},
	[_G.FIRE_TOTEM_SLOT]	= {left = 0.52, right = 0.76, top = 0.39, bottom = 0.51},
	[_G.WATER_TOTEM_SLOT]	= {left = 0.30, right = 0.54, top = 0.82, bottom = 0.93},
	[_G.AIR_TOTEM_SLOT]		= {left = 0.52, right = 0.75, top = 0.14, bottom = 0.26}
}

function AB:MultiCastFlyoutFrameOpenButton_Show(button, which, parent)
	local color = which == 'page' and SLOT_BORDER_COLORS.summon or SLOT_BORDER_COLORS[parent:GetID()]
	button:SetBackdropBorderColor(color.r, color.g, color.b)

	button:ClearAllPoints()
	if AB.db.totemBar.flyoutDirection == 'UP' then
		button:Point('BOTTOM', parent, 'TOP')
	else
		button:Point('TOP', parent, 'BOTTOM')
	end
end

function AB:MultiCastActionButton_Update(button)
	if InCombatLockdown() then
		AB.NeedsPositionAndSizeTotemBar = true
		AB:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		button:ClearAllPoints()
		button:SetAllPoints(button.slotButton)

		if button and not button.useMasque then
			AB:TrimIcon(button)
		end
	end
end

function AB:MultiCastSummonSpellButton_Update(summonButton)
	if InCombatLockdown() then
		AB.NeedsPositionAndSizeTotemBar = true
		AB:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	local slot1 = _G.MultiCastSlotButton1
	slot1:ClearAllPoints()
	slot1:Point('LEFT', summonButton, 'RIGHT', AB.db.totemBar.spacing, 0)
end

function AB:StyleTotemSlotButton(button, slot)
	if button.useMasque then return end

	local color = SLOT_BORDER_COLORS[slot]
	if color then
		button:SetBackdropBorderColor(color.r, color.g, color.b)
		button.ignoreBorderColors = true
	end
end

function AB:SkinMultiCastButton(button, noBackdrop, useMasque)
	if button.isSkinned then return end

	local name = button:GetName()
	local highlight = _G[name..'Highlight']
	local icon = _G[name.."Icon"] or button.icon or button.background
	local normal = _G[name..'NormalTexture']

	button.noBackdrop = noBackdrop
	button.useMasque = useMasque
	button.db = AB.db.totemBar

	if normal then normal:SetTexture(nil); normal:Hide(); normal:SetAlpha(0) end
	if button.overlay then button.overlay:SetTexture(nil); button.overlay:Hide(); button.overlay:SetAlpha(0) end
	if highlight then highlight:SetTexture(nil) end

	if not button.noBackdrop and not button.useMasque then
		button:SetTemplate()
	end

	if not useMasque then
		button:StyleButton()
		icon:SetDrawLayer('ARTWORK')
		icon:SetInside(button)

		AB:TrimIcon(button)
	else
		button:StyleButton(true, true, true)
	end

	if button.cooldown then
		E:RegisterCooldown(button.cooldown, 'actionbar')
	end

	button.parent = bar
	button.parentName = 'ElvUI_TotemBar'

	AB.handledbuttons[button] = true
	bar.buttons[button] = true
	button.isSkinned = true
end

function AB:MultiCastFlyoutFrame_ToggleFlyout(frame, which, parent)
	frame.top:SetTexture(nil)
	frame.middle:SetTexture(nil)

	local color = which == 'page' and SLOT_BORDER_COLORS.summon or SLOT_BORDER_COLORS[parent:GetID()]
	local useMasque = MasqueGroup and E.private.actionbar.masque.actionbars
	local numButtons, totalHeight = 0, 0

	local buttonWidth = AB.db.totemBar.flyoutSize
	local buttonHeight = (AB.db.totemBar.keepSizeRatio and AB.db.totemBar.flyoutSize) or AB.db.totemBar.flyoutHeight
	local buttonSpacing = AB.db.totemBar.flyoutSpacing

	for i, button in ipairs(frame.buttons) do
		if not button.isSkinned then
			AB:SkinMultiCastButton(button, nil, useMasque)

			-- these only need mouseover script, dont need the bind key script
			AB:HookScript(button, 'OnEnter', 'TotemBar_OnEnter')
			AB:HookScript(button, 'OnLeave', 'TotemBar_OnLeave')
		end

		if button:IsShown() then
			numButtons = numButtons + 1

			if not useMasque then
				button:SetBackdropBorderColor(color.r, color.g, color.b)
			end

			button:Size(buttonWidth, buttonHeight)
			button:ClearAllPoints()

			AB:TrimIcon(button, useMasque)

			local anchor = (i == 1 and parent) or frame.buttons[i - 1]
			if AB.db.totemBar.flyoutDirection == 'UP' then
				button:Point('BOTTOM', anchor, 'TOP', 0, buttonSpacing)
			else
				button:Point('TOP', anchor, 'BOTTOM', 0, -buttonSpacing)
			end

			totalHeight = totalHeight + button:GetHeight() + buttonSpacing
		end
	end

	if which == 'slot' then
		local tCoords = SLOT_EMPTY_TCOORDS[parent:GetID()]
		frame.buttons[1].icon:SetTexCoord(tCoords.left, tCoords.right, tCoords.top, tCoords.bottom)
	end

	local closeButton = _G.MultiCastFlyoutFrameCloseButton
	closeButton:SetBackdropBorderColor(color.r, color.g, color.b)

	frame:ClearAllPoints()
	closeButton:ClearAllPoints()
	if AB.db.totemBar.flyoutDirection == 'UP' then
		frame:Point('BOTTOM', parent, 'TOP')
		closeButton:Point('TOP', frame, 'TOP')
	else
		frame:Point('TOP', parent, 'BOTTOM')
		closeButton:Point('BOTTOM', frame, 'BOTTOM')
	end

	frame:Height(totalHeight + closeButton:GetHeight())
end

function AB:TotemButton_OnEnter()
	-- totem keybind support from actionbar module
	if E.private.actionbar.enable then
		AB:BindUpdate(self)
	end

	AB:TotemBar_OnEnter()
end

function AB:TotemButton_OnLeave()
	AB:TotemBar_OnLeave()
end

function AB:TotemBar_OnEnter()
	if bar.mouseover then
		local alpha = AB.db.totemBar.alpha
		E:UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), alpha)
	end
end

function AB:TotemBar_OnLeave()
	if bar.mouseover then
		E:UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0)
	end
end

function AB:PositionAndSizeTotemBar()
	if InCombatLockdown() then
		AB.NeedsPositionAndSizeTotemBar = true
		AB:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	local barFrame = _G.MultiCastActionBarFrame
	local numActiveSlots = barFrame.numActiveSlots
	local buttonSpacing = AB.db.totemBar.spacing

	local buttonWidth = AB.db.totemBar.buttonSize
	local buttonHeight = (AB.db.totemBar.keepSizeRatio and AB.db.totemBar.buttonSize) or AB.db.totemBar.buttonHeight
	local useMasque = MasqueGroup and E.private.actionbar.masque.actionbars

	local mainWidth = (buttonWidth * (2 + numActiveSlots)) + (buttonSpacing * (2 + numActiveSlots - 1))
	bar:Width(mainWidth)
	barFrame:Width(mainWidth)
	bar:Height(buttonHeight)
	barFrame:Height(buttonHeight)

	bar.mouseover = AB.db.totemBar.mouseover

	local fadeAlpha = bar.mouseover and 0 or AB.db.totemBar.alpha
	bar:SetAlpha(fadeAlpha)

	local visibility = gsub(AB.db.totemBar.visibility, '[\n\r]', '')
	RegisterStateDriver(bar, 'visibility', visibility)

	local summonButton = _G.MultiCastSummonSpellButton
	summonButton:ClearAllPoints()
	summonButton:Point('BOTTOMLEFT')
	summonButton:Size(buttonWidth, buttonHeight)

	for i = 1, numActiveSlots do
		local button = _G['MultiCastSlotButton'..i]
		local actionButton = _G['MultiCastActionButton'..i]
		local lastButton = _G['MultiCastSlotButton'..i - 1]

		button:Size(buttonWidth, buttonHeight)
		button:ClearAllPoints()

		actionButton:SetSize(button:GetSize()) -- these need to match for icon trim setting
		AB:TrimIcon(actionButton, useMasque)

		if i == 1 then
			button:Point('LEFT', summonButton, 'RIGHT', buttonSpacing, 0)
		else
			button:Point('LEFT', lastButton, 'RIGHT', buttonSpacing, 0)
		end
	end

	local recallButton = _G.MultiCastRecallSpellButton
	recallButton:Size(buttonWidth, buttonHeight)
	AB:MultiCastRecallSpellButton_Update()

	AB:TrimIcon(summonButton, useMasque)
	AB:TrimIcon(recallButton, useMasque)

	_G.MultiCastFlyoutFrameCloseButton:Width(buttonWidth)
	_G.MultiCastFlyoutFrameOpenButton:Width(buttonWidth)
end

function AB:UpdateTotemBindings()
	local font = LSM:Fetch('font', AB.db.totemBar.font)
	local size, outline = AB.db.totemBar.fontSize, AB.db.totemBar.fontOutline

	local summon = _G.MultiCastSummonSpellButton
	local summonHotKey = summon.HotKey or _G.MultiCastSummonSpellButtonHotKey
	summonHotKey:FontTemplate(font, size, outline)
	summonHotKey:SetTextColor(1, 1, 1)
	AB:FixKeybindText(summon)

	local recall = _G.MultiCastRecallSpellButton
	local recallHotKey = recall.HotKey or _G.MultiCastRecallSpellButtonHotKey
	recallHotKey:FontTemplate(font, size, outline)
	recallHotKey:SetTextColor(1, 1, 1)
	AB:FixKeybindText(recall)

	for i = 1, 12 do
		local button = _G['MultiCastActionButton'..i]
		local hotkey = button.HotKey or _G['MultiCastActionButton'..i..'HotKey']
		hotkey:FontTemplate(font, size, outline)
		hotkey:SetTextColor(1, 1, 1)
		AB:FixKeybindText(button)
	end
end

function AB:MultiCastRecallSpellButton_Update(button)
	if InCombatLockdown() then
		AB.NeedsRecallButtonUpdate = true
		AB:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	if not button then button = _G.MultiCastRecallSpellButton end

	local activeSlots = _G.MultiCastActionBarFrame.numActiveSlots
	if button and activeSlots and activeSlots > 0 then
		button:ClearAllPoints()
		button:Point('LEFT', _G['MultiCastSlotButton'..activeSlots], 'RIGHT', AB.db.totemBar.spacing, 0)
	end
end

function AB:MultiCastFlyoutFrameStyle(button, rotate)
	button:SetTemplate()
	button:StyleButton()

	button.normalTexture:ClearAllPoints()
	button.normalTexture:SetPoint('CENTER')
	button.normalTexture:SetSize(16, 16)
	button.normalTexture:SetTexture(E.Media.Textures.ArrowUp)
	button.normalTexture:SetTexCoord(0, 1, 0, 1)
	hooksecurefunc(button.normalTexture, 'SetTexCoord', function(texture, left, right, top, bottom)
		if left ~= 0 or right ~= 1 or top ~= 0 or bottom ~= 1 then
			texture:SetTexCoord(0, 1, 0, 1)
		end
	end)

	button:HookScript('OnEnter', AB.TotemBar_OnEnter)
	button:HookScript('OnLeave', AB.TotemBar_OnLeave)

	if rotate then
		button.normalTexture:SetRotation(3.14)
		button.normalTexture:SetSize(22, 22)
	end

	bar.buttons[button] = true
end

function AB:CreateTotemBar()
	AB.TotemBar = bar -- Initialized

	bar:Size(200, 30)
	bar:Point('BOTTOM', E.UIParent, 0, 250)
	bar.buttons = {}

	local barFrame = _G.MultiCastActionBarFrame
	barFrame:SetScript('OnUpdate', nil)
	barFrame:SetScript('OnShow', nil)
	barFrame:SetScript('OnHide', nil)
	barFrame:SetParent(bar)

	function AB:ReanchorTotemBar()
		local frame = _G.MultiCastActionBarFrame

		if InCombatLockdown() then
			AB.NeedsTotemBarReanchor = true
			AB:RegisterEvent('PLAYER_REGEN_ENABLED')
			return
		end

		AB.NeedsTotemBarReanchor = nil

		if frame:GetParent() ~= bar then
			frame:SetParent(bar)
		end

		if frame.ClearAllPointsBase then
			frame:ClearAllPointsBase()
			frame:SetPointBase('BOTTOMLEFT', bar, 'BOTTOMLEFT', 0, 0)
		else
			frame:ClearAllPoints()
			frame:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', 0, 0)
		end
	end

	AB:ReanchorTotemBar()

	hooksecurefunc(barFrame, 'SetParent', function(_, parent)
		if parent ~= bar then
			AB:ReanchorTotemBar()
		end
	end)
	hooksecurefunc(barFrame, 'SetPoint', function(_, _, anchor)
		if anchor ~= bar then
			AB:ReanchorTotemBar()
		end
	end)

	AB:MultiCastFlyoutFrameStyle(_G.MultiCastFlyoutFrameCloseButton, true)
	AB:MultiCastFlyoutFrameStyle(_G.MultiCastFlyoutFrameOpenButton)

	for i = 1, MAX_TOTEMS do
		local button = _G['MultiCastSlotButton'..i]
		button.icon = button.background
		AB:SkinMultiCastButton(button, nil, MasqueGroup and E.private.actionbar.masque.actionbars)
	end

	local isShaman = E.myclass == 'SHAMAN'
	for i = 1, 12 do
		local name = 'MultiCastActionButton'..i
		local button = _G[name]
		local hotkey = button.HotKey or _G[name..'HotKey']

		if isShaman then
			button:SetAttribute("type2", "destroytotem")
			button:SetAttribute("*totem-slot*", _G.TOTEM_PRIORITIES[i])
		end

		AB:SkinMultiCastButton(button, true, MasqueGroup and E.private.actionbar.masque.actionbars)

		hooksecurefunc(hotkey, 'SetVertexColor', function(hk, r, g, b)
			if r ~= 1 or g ~= 1 or b ~= 1 then
				hk:SetVertexColor(1, 1, 1)
			end
		end)
		button.keyBoundTarget = button.buttonType .. button.buttonIndex
	end

	local summonButton = _G.MultiCastSummonSpellButton
	AB:SkinMultiCastButton(summonButton)
	summonButton.keyBoundTarget = summonButton.buttonType..'1'

	local spellButton = _G.MultiCastRecallSpellButton
	AB:SkinMultiCastButton(spellButton)
	spellButton.keyBoundTarget = spellButton.buttonType..'1'

	for button in next, bar.buttons do
		button:HookScript('OnEnter', AB.TotemButton_OnEnter)
		button:HookScript('OnLeave', AB.TotemButton_OnLeave)
	end

	hooksecurefunc(spellButton, 'SetPoint', function(button, point, attachTo, anchorPoint, xOffset, yOffset)
		if InCombatLockdown() then
			AB.NeedsRecallButtonUpdate = true
			AB:RegisterEvent('PLAYER_REGEN_ENABLED')
		elseif xOffset ~= AB.db.totemBar.spacing or button:GetPoint(2) then
			button:ClearAllPoints()
			button:SetPoint(point, attachTo, anchorPoint, AB.db.totemBar.spacing, yOffset)
		end
	end)

	AB:UpdateTotemBindings()

	AB:SecureHook('MultiCastRecallSpellButton_Update')
	AB:SecureHook('MultiCastSummonSpellButton_Update')
	AB:SecureHook('MultiCastFlyoutFrameOpenButton_Show')
	AB:SecureHook('MultiCastActionButton_Update')
	AB:SecureHook('MultiCastFlyoutFrame_ToggleFlyout')
	AB:SecureHook('MultiCastSlotButton_Update', 'StyleTotemSlotButton')

	AB:HookScript(_G.MultiCastActionBarFrame, 'OnEnter', 'TotemBar_OnEnter')
	AB:HookScript(_G.MultiCastActionBarFrame, 'OnLeave', 'TotemBar_OnLeave')

	AB:HookScript(_G.MultiCastFlyoutFrame, 'OnEnter', 'TotemBar_OnEnter')
	AB:HookScript(_G.MultiCastFlyoutFrame, 'OnLeave', 'TotemBar_OnLeave')

	E:CreateMover(bar, 'TotemBarMover', L["Totem Bar"], nil, nil, nil, nil, nil, 'actionbar,totemBar')
end
