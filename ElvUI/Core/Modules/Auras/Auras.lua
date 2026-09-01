local E, L, V, P, G = unpack(ElvUI)
local A = E:GetModule('Auras')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM
local ElvUF = E.oUF

local _G = _G
local unpack = unpack
local floor = math.floor
local huge = math.huge
local tinsert = tinsert
local sort = table.sort
local split = string.split

local UnitAura = UnitAura
local UnitIsUnit = UnitIsUnit
local GetCVar = GetCVar
local hooksecurefunc = hooksecurefunc
local strlower = strlower
local CancelItemTempEnchantment = CancelItemTempEnchantment
local CancelUnitBuff = CancelUnitBuff
local GetInventoryItemQuality = GetInventoryItemQuality
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local GameTooltip_Hide = GameTooltip_Hide
local GameTooltip = GameTooltip
local CreateFrame = CreateFrame
local GetTime = GetTime
local C_Timer = C_Timer

local TICK_INTERVAL = 0.1

local Masque = E.Masque or E.Libs.LBF
local MasqueGroupBuffs = Masque and Masque:Group('ElvUI', 'Buffs')
local MasqueGroupDebuffs = Masque and Masque:Group('ElvUI', 'Debuffs')

local DebuffColors = DebuffTypeColor

local DIRECTION_TO_POINT = {
	DOWN_RIGHT = 'TOPLEFT',
	DOWN_LEFT = 'TOPRIGHT',
	UP_RIGHT = 'BOTTOMLEFT',
	UP_LEFT = 'BOTTOMRIGHT',
	RIGHT_DOWN = 'TOPLEFT',
	RIGHT_UP = 'BOTTOMLEFT',
	LEFT_DOWN = 'TOPRIGHT',
	LEFT_UP = 'BOTTOMRIGHT',
}

local DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = 1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = -1,
	RIGHT_DOWN = 1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = -1,
}

local DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = -1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = 1,
	RIGHT_DOWN = -1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = 1,
}

local IS_HORIZONTAL_GROWTH = {
	RIGHT_DOWN = true,
	RIGHT_UP = true,
	LEFT_DOWN = true,
	LEFT_UP = true,
}

local MasqueButtonData = {
	Icon = nil,
	Highlight = nil,
	FloatingBG = nil,
	Cooldown = nil,
	Flash = nil,
	Pushed = nil,
	Normal = nil,
	Disabled = nil,
	Checked = nil,
	Border = nil,
	AutoCastable = nil,
	HotKey = nil,
	Count = false,
	Name = nil,
	Duration = false,
	AutoCast = nil,
}

local enchantableSlots = { [1] = 16, [2] = 17 }

local sortList, sortPool = {}, {}
local consolidateSortEntries, consolidateSortPool = {}, {}
local sortKey, sortReverse, sortSeparate = 'index', false, 0

local function AuraSort(a, b)
	if sortSeparate ~= 0 and a.isPlayer ~= b.isPlayer then
		return a.isPlayer == (sortSeparate > 0)
	end

	local av, bv = a[sortKey], b[sortKey]
	if av ~= bv then
		if sortReverse then
			return av > bv
		end

		return av < bv
	end

	return a.index < b.index
end

local CONSOLIDATED_PER_ROW = 4
local CONSOLIDATED_MAX_BUTTONS = 32

function A:MasqueData(texture, highlight)
	local data = E:CopyTable({}, MasqueButtonData)
	data.Icon = texture
	data.Highlight = highlight
	return data
end

function A:UpdateButton(button)
	local db = A.db[button.auraType]
	if button.statusBar and button.statusBar:IsShown() then
		local r, g, b
		if db.barColorGradient then
			r, g, b = ElvUF:ColorGradient(button.timeLeft, button.duration or 0, .8, 0, 0, .8, .8, 0, 0, .8, 0)
		else
			r, g, b = db.barColor.r, db.barColor.g, db.barColor.b
		end

		button.statusBar:SetStatusBarColor(r, g, b)
		button.statusBar:SetValue(button.timeLeft)
	end

	local threshold = db.fadeThreshold
	if threshold == -1 then
		return
	elseif button.timeLeft and button.timeLeft > threshold then
		E:StopFlash(button)
	else
		E:Flash(button, 1, true)
	end
end

function A:CreateIcon(button)
	local header = button:GetParent()

	button.header = header
	button.filter = header.filter
	button.auraType = (header.filter == 'HELPFUL' and 'buffs') or 'debuffs'

	button.name = button:GetName()

	button.texture = button:CreateTexture(nil, 'ARTWORK')
	button.texture:SetInside()

	button.count = button:CreateFontString(nil, 'OVERLAY')
	button.count:FontTemplate()

	button.text = button:CreateFontString(nil, 'OVERLAY')
	button.text:FontTemplate()

	button.highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	button.highlight:SetTexture(1, 1, 1, .45)
	button.highlight:SetInside()

	button.statusBar = CreateFrame('StatusBar', nil, button)
	button.statusBar:OffsetFrameLevel(nil, button)
	button.statusBar:SetFrameStrata(button:GetFrameStrata())
	button.statusBar:SetMinMaxValues(0, 1)
	button.statusBar:SetValue(0)
	button.statusBar:CreateBackdrop()

	button:RegisterForClicks('RightButtonUp')

	button:SetScript('OnClick', A.Button_OnClick)
	button:SetScript('OnEnter', A.Button_OnEnter)
	button:SetScript('OnLeave', A.Button_OnLeave)

	-- support cooldown override
	if not button.isRegisteredCooldown then
		button.CooldownOverride = 'auras'
		button.isRegisteredCooldown = true
		button.forceEnabled = true
		button.showSeconds = true

		if not E.RegisteredCooldowns.auras then E.RegisteredCooldowns.auras = {} end
		tinsert(E.RegisteredCooldowns.auras, button)
	end

	A:Update_CooldownOptions(button)
	A:UpdateIcon(button)
end

function A:UpdateTexture(button) -- self here can be the header from UpdateMasque calling this function
	local db = A.db[button.auraType]
	local width, height = db.size, (db.keepSizeRatio and db.size) or db.height

	if db.keepSizeRatio then
		button.texture:SetTexCoords()
	else
		local left, right, top, bottom = E:CropRatio(width, height)
		button.texture:SetTexCoord(left, right, top, bottom)
	end
end

function A:UpdateIcon(button, update)
	local db = A.db[button.auraType]

	local width, height = db.size, (db.keepSizeRatio and db.size) or db.height
	if update then
		button:SetWidth(width)
		button:SetHeight(height)
	elseif button.header.MasqueGroup then
		local data = A:MasqueData(button.texture, button.highlight)
		button.header.MasqueGroup:AddButton(button, data)
	elseif not button.template then
		button:SetTemplate()
	end

	if button.texture then
		A:UpdateTexture(button)
	end

	if button.count then
		button.count:ClearAllPoints()
		button.count:Point('BOTTOMRIGHT', db.countXOffset, db.countYOffset)
		button.count:FontTemplate(LSM:Fetch('font', db.countFont), db.countFontSize, db.countFontOutline)
	end

	if button.text then
		button.text:ClearAllPoints()
		button.text:Point('TOP', button, 'BOTTOM', db.timeXOffset, db.timeYOffset)
		button.text:FontTemplate(LSM:Fetch('font', db.timeFont), db.timeFontSize, db.timeFontOutline)
	end

	if button.statusBar then
		E:SetSmoothing(button.statusBar, db.smoothbars)

		local pos, iconSize = db.barPosition, db.size - (E.Border * 2)
		local onTop, onBottom, onLeft = pos == 'TOP', pos == 'BOTTOM', pos == 'LEFT'
		local barSpacing = db.barSpacing + (E.PixelMode and 1 or 3)
		local barSize = db.barSize + (E.PixelMode and 0 or 2)
		local isHorizontal = onTop or onBottom

		button.statusBar:ClearAllPoints()
		button.statusBar:Size(isHorizontal and iconSize or barSize, isHorizontal and barSize or iconSize)
		button.statusBar:Point(E.InversePoints[pos], button, pos, isHorizontal and 0 or (onLeft and -barSpacing or barSpacing), not isHorizontal and 0 or (onTop and barSpacing or -barSpacing))
		button.statusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db.barTexture))
		button.statusBar:SetOrientation(isHorizontal and 'HORIZONTAL' or 'VERTICAL')
		button.statusBar:SetRotatesTexture(not isHorizontal)
	end
end

function A:SetAuraTime(button, expiration, duration, modRate)
	local oldEnd = button.endTime
	button.expiration = expiration
	button.endTime = expiration
	button.duration = duration
	button.modRate = modRate or 1

	if oldEnd ~= button.endTime then
		if button.statusBar:IsShown() then
			button.statusBar:SetMinMaxValues(0, duration)
		end
		button.nextUpdate = 0
	end

	A:UpdateTime(button, expiration, modRate)
end

function A:ClearAuraTime(button, expired)
	button.expiration = nil
	button.endTime = nil
	button.duration = nil
	button.modRate = nil
	button.timeLeft = nil

	button.text:SetText('')

	E:StopFlash(button)

	if not expired and button.statusBar:IsShown() then
		button.statusBar:SetMinMaxValues(0, 1)
		button.statusBar:SetValue(1)

		local db = A.db[button.auraType]
		if db.barColorGradient then -- value 1 is just green
			button.statusBar:SetStatusBarColor(0, .8, 0)
		else
			button.statusBar:SetStatusBarColor(db.barColor.r, db.barColor.g, db.barColor.b)
		end
	end
end

function A:UpdateAura(button, index)
	local name, _, icon, count, dispelType, duration, expiration, caster = UnitAura('player', index, button.filter)
	if not name then return end

	local db = A.db[button.auraType]

	if button.consolidateStyled then
		button.consolidateStyled = nil
		A:UpdateIcon(button, true)
	end

	button:Show()
	button.text:SetShown(db.showDuration)
	button.statusBar:SetShown((db.barShow and duration > 0) or (db.barShow and db.barNoDuration and duration == 0))
	button.count:SetText(not count or count <= 1 and '' or count)
	button.texture:SetTexture(icon)
	button.auraIndex = index

	local dtype = dispelType or 'none'
	if button.debuffType ~= dtype then
		local debuffColor = button.filter == 'HARMFUL' and A.db.colorDebuffs and DebuffColors[dtype]
		local color = debuffColor or E.db.general.bordercolor
		if debuffColor then
			E:SetForcedBorderColor(button, color.r, color.g, color.b)
			E:SetForcedBorderColor(button.statusBar.backdrop, color.r, color.g, color.b)
		else
			E:ClearForcedBorderColor(button, color.r, color.g, color.b)
			E:ClearForcedBorderColor(button.statusBar.backdrop, color.r, color.g, color.b)
		end
		button.debuffType = dtype
	end

	if duration > 0 and expiration then
		A:SetAuraTime(button, expiration, duration)
	else
		A:ClearAuraTime(button)
	end
end

function A:UpdateTempEnchant(button, index, expiration)
	local db = A.db[button.auraType]

	if button.consolidateStyled then
		button.consolidateStyled = nil
		A:UpdateIcon(button, true)
	end

	button.count:SetText('')
	button.text:SetShown(db.showDuration)
	button.statusBar:SetShown((db.barShow and expiration) or (db.barShow and db.barNoDuration and not expiration))

	if expiration then
		button.texture:SetTexture(GetInventoryItemTexture('player', index))

		local quality = A.db.colorEnchants and GetInventoryItemQuality('player', index)
		local r, g, b = E:GetItemQualityColor(quality and quality > 1 and quality)

		E:SetForcedBorderColor(button, r, g, b)
		E:SetForcedBorderColor(button.statusBar.backdrop, r, g, b)

		local remaining = (expiration * 0.001) or 0
		A:SetAuraTime(button, remaining + GetTime(), (remaining <= 3600 and remaining > 1800) and 3600 or (remaining <= 1800 and remaining > 600) and 1800 or 600)
	else
		A:ClearAuraTime(button)
	end
end

function A:Update_CooldownOptions(button)
	E:Cooldown_Options(button, A.db.cooldown, button)
end

function A:SetTooltip(button)
	if button.auraIndex then
		GameTooltip:SetUnitAura('player', button.auraIndex, button.filter)
	elseif button.enchantIndex then
		GameTooltip:SetInventoryItem('player', enchantableSlots[button.enchantIndex])
	end
end

function A:Button_OnLeave()
	GameTooltip_Hide()
end

function A:Button_OnEnter()
	if self.consolidated then
		local holder = self.header and self.header.consolidatedHolder
		if holder then
			holder.hideTimer = 0
			holder:Show()
		end

		return
	end

	local db = A.db[self.auraType]
	GameTooltip:SetOwner(self, db.tooltipAnchorType or 'ANCHOR_BOTTOMLEFT', db.tooltipAnchorX or -5, db.tooltipAnchorY or-5)

	A:SetTooltip(self)
end

function A:Button_OnClick()
	if self.enchantIndex then
		CancelItemTempEnchantment(self.enchantIndex)
	elseif self.auraIndex then
		CancelUnitBuff('player', self.auraIndex, self.filter)
	end
end

function A:UpdateTime(button, expiration, modRate)
	button.timeLeft = (expiration - GetTime()) / (modRate or 1)

	if button.timeLeft < 0.1 then
		A:ClearAuraTime(button, true)
	else
		A:UpdateButton(button)
	end
end

function A:Button_Tick(button)
	local xpr = button.endTime
	if xpr then
		E.Cooldown_OnUpdate(button, TICK_INTERVAL)
	end

	if GameTooltip:IsOwned(button) then
		A:SetTooltip(button)
	end

	if xpr then
		A:UpdateTime(button, xpr, button.modRate)
	end
end

function A:Header_Tick(header)
	local buttons = header.buttons
	if not buttons then return end

	for i = 1, #buttons do
		local button = buttons[i]
		if button:IsShown() then
			A:Button_Tick(button)
		end
	end

	if header.consolidatedHolder and header.consolidatedHolder:IsShown() then
		for i = 1, #header.consolidated do
			local button = header.consolidated[i]
			if button:IsShown() then
				A:Button_Tick(button)
			end
		end
	end

	if header.consolidateExit and header.consolidateExit <= GetTime() then
		A:UpdateAllAuras(header)
	end
end

function A:Header_StopTicker(header)
	if header.ticker then
		header.ticker:Cancel()
		header.ticker = nil
	end
end

function A:Header_StartTicker(header)
	if header.ticker then return end

	header.ticker = C_Timer:NewTicker(TICK_INTERVAL, function()
		A:Header_Tick(header)
	end)
end

function A:Header_OnShow()
	A:Header_StartTicker(self)
end

function A:Header_OnHide()
	A:Header_StopTicker(self)
end

function A:Header_OnEvent(event, unit, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		A:UpdateAllAuras(self)
	elseif (event == 'UNIT_AURA' or event == 'UNIT_INVENTORY_CHANGED') and unit == 'player' then
		A:UpdateAllAuras(self)
	end
end

function A:UpdateMasque(header)
	if header.MasqueGroup then
		header.MasqueGroup:ReSkin()
		for i = 1, #header.buttons do
			A:UpdateTexture(header.buttons[i])
		end
	end
end

function A:UpdateAllAuras(header)
    if not header or not header.buttons then return end
    if not A.db or not A.db[header.auraType] then return end

    for i = 1, #header.buttons do
        header.buttons[i].auraIndex = nil
        header.buttons[i].enchantIndex = nil
        header.buttons[i].consolidated = nil
    end

	local buttonIndex = 1

	-- Handle weapon enchants for buffs
	if header.filter == 'HELPFUL' then
		local hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()

		if hasMainHandEnchant and header.buttons[buttonIndex] then
			local button = header.buttons[buttonIndex]
			button.enchantIndex = 1
			button:Show()
			A:UpdateTempEnchant(button, 16, mainHandExpiration)
			buttonIndex = buttonIndex + 1
		end

		if hasOffHandEnchant and header.buttons[buttonIndex] then
			local button = header.buttons[buttonIndex]
			button.enchantIndex = 2
			button:Show()
			A:UpdateTempEnchant(button, 17, offHandExpiration)
			buttonIndex = buttonIndex + 1
		end
	end

	local consolidate = header.consolidatedHolder and GetCVar('consolidateBuffs') == '1'
	local consolidatedMap
	local numConsolidated = 0

	if header.consolidatedHolder then
		wipe(header.consolidatedList)
		header.consolidateExit = nil
	end

	if consolidate then
		consolidatedMap = {}

		local now = GetTime()
		local cIndex = 1
		while true do
			local name, _, _, _, _, duration, expiration, _, _, shouldConsolidate = UnitAura('player', cIndex, 'HELPFUL')
			if not name then break end

			if shouldConsolidate then
				local exitTime
				if duration and duration > 30 and expiration and expiration > 0 then
					exitTime = expiration - max(10, duration / 10)
				end

				if not exitTime or exitTime > now then
					tinsert(header.consolidatedList, cIndex)
					consolidatedMap[cIndex] = true

					if exitTime and (not header.consolidateExit or exitTime < header.consolidateExit) then
						header.consolidateExit = exitTime
					end
				end
			end

			cIndex = cIndex + 1
		end

		numConsolidated = #header.consolidatedList
		if numConsolidated > 0 then
			header.consolidateButton = header.buttons[buttonIndex]
			if header.consolidateButton then
				buttonIndex = buttonIndex + 1
			else
				numConsolidated = 0
			end
		end
	end

	-- Scan all auras
	local db = A.db[header.auraType]
	local priority = (db and db.priority and db.priority ~= '') and { split(',', db.priority) } or nil

	local method = db.sortMethod
	sortKey = (method == 'TIME' and 'expiration') or (method == 'NAME' and 'name') or 'index'
	sortReverse = db.sortDir == '-'
	sortSeparate = tonumber(db.seperateOwn) or 0

	wipe(sortList)

	if buttonIndex <= #header.buttons then
		local index = 1
		while true do
			local name, _, _, _, debuffType, duration, expirationTime, caster, isStealable, _, spellID = UnitAura('player', index, header.filter)
			if not name then break end

			local isPlayer = caster == 'player' or caster == 'vehicle'

			local allow = true
			if priority then
				local isUnit = caster and UnitIsUnit('player', caster)
				local noDuration = (not duration or duration == 0)
				local canDispell = (header.filter == 'HELPFUL' and isStealable) or (header.filter == 'HARMFUL' and debuffType and E:IsDispellableByMe(debuffType))
				allow = UF:CheckFilter(name, caster, spellID, true, isPlayer, isUnit, true, noDuration, canDispell, unpack(priority))
			end

			if allow and not (consolidatedMap and consolidatedMap[index]) then
				local slot = #sortList + 1
				local entry = sortPool[slot]
				if not entry then
					entry = {}
					sortPool[slot] = entry
				end

				entry.index = index
				entry.name = name
				entry.expiration = (expirationTime and expirationTime > 0) and expirationTime or huge
				entry.isPlayer = isPlayer

				sortList[slot] = entry
			end

			index = index + 1
		end

		if sortSeparate ~= 0 or sortReverse or sortKey ~= 'index' then
			sort(sortList, AuraSort)
		end

		for i = 1, #sortList do
			local button = header.buttons[buttonIndex]
			if not button then break end

			A:UpdateAura(button, sortList[i].index)
			buttonIndex = buttonIndex + 1
		end
	end

	-- Hide unused buttons
	for i = buttonIndex, #header.buttons do
		header.buttons[i]:Hide()
		header.buttons[i].auraIndex = nil
		header.buttons[i].enchantIndex = nil
	end

	A:UpdateConsolidate(header, numConsolidated)

	-- Position buttons
	A:PositionButtons(header)
end

function A:UpdateConsolidate(header, numConsolidated)
	local holder = header.consolidatedHolder
	if not holder then return end

	local db = A.db.buffs
	local button = header.consolidateButton

	if numConsolidated == 0 then
		if button then
			button.consolidated = nil

			if button.consolidateStyled then
				button.consolidateStyled = nil
				A:UpdateIcon(button, true)
			end

			header.consolidateButton = nil
		end

		holder:Hide()
		return
	end

	A:ClearAuraTime(button)
	button.consolidated = true
	button.consolidateStyled = true
	button.auraIndex = nil
	button.enchantIndex = nil

	local iconWidth = db.size
	local iconHeight = (db.keepSizeRatio and iconWidth) or db.height
	button:SetSize(iconWidth, iconHeight)

	local left, right, top, bottom = 0.1, 0.4, 0.2, 0.8
	if not db.keepSizeRatio then
		local ratio = iconWidth / iconHeight
		if ratio > 1 then
			local trim = (bottom - top) * (1 - 1 / ratio) * 0.5
			top, bottom = top + trim, bottom - trim
		elseif ratio < 1 then
			local trim = (right - left) * (1 - ratio) * 0.5
			left, right = left + trim, right - trim
		end
	end

	button.texture:SetTexture([[Interface\Buttons\BuffConsolidation]])
	button.texture:SetTexCoord(left, right, top, bottom)
	button.count:SetText(numConsolidated)
	button.statusBar:Hide()
	button:Show()

	local list = header.consolidatedList

	if sortSeparate ~= 0 or sortReverse or sortKey ~= 'index' then
		wipe(consolidateSortEntries)
		for i = 1, #list do
			local cIndex = list[i]
			local name, _, _, _, _, _, expiration, caster = UnitAura('player', cIndex, 'HELPFUL')
			local entry = consolidateSortPool[i]
			if not entry then
				entry = {}
				consolidateSortPool[i] = entry
			end
			entry.index = cIndex
			entry.name = name or ''
			entry.expiration = (expiration and expiration > 0) and expiration or huge
			entry.isPlayer = caster == 'player' or caster == 'vehicle'
			consolidateSortEntries[i] = entry
		end
		sort(consolidateSortEntries, AuraSort)
		for i = 1, #consolidateSortEntries do
			list[i] = consolidateSortEntries[i].index
		end
	end

	local maxButtons = math.min(db.consolidateMax or CONSOLIDATED_MAX_BUTTONS, CONSOLIDATED_MAX_BUTTONS)
	local shown = 0
	for i = 1, math.min(#list, maxButtons) do
		local popupButton = header.consolidated[i]
		if not popupButton then break end
		shown = shown + 1
		A:UpdateAura(popupButton, list[i])
		popupButton.statusBar:Hide()
	end

	for i = shown + 1, #header.consolidated do
		header.consolidated[i]:Hide()
	end

	local size = db.consolidateSize or 24
	local popupHeight = (db.keepSizeRatio and size) or (size * db.height / db.size)
	local hSpacing = db.horizontalSpacing
	local vSpacing = db.verticalSpacing
	local direction = db.consolidateDirection or 'RIGHT_DOWN'
	local point = DIRECTION_TO_POINT[direction]
	local isHorizontal = IS_HORIZONTAL_GROWTH[direction]
	local hMult = DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[direction]
	local vMult = DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[direction]

	local rows = math.ceil(shown / CONSOLIDATED_PER_ROW)
	local cols = math.min(shown, CONSOLIDATED_PER_ROW)
	if not isHorizontal then
		cols, rows = rows, cols
	end

	local pad = E.Border + 2
	holder:SetSize(cols * size + (cols - 1) * hSpacing + pad * 2, rows * popupHeight + (rows - 1) * vSpacing + pad * 2)

	for i = 1, shown do
		local popupButton = header.consolidated[i]
		popupButton:SetSize(size, popupHeight)

		local wrap = floor((i - 1) / CONSOLIDATED_PER_ROW)
		local slot = (i - 1) % CONSOLIDATED_PER_ROW
		local row, col
		if isHorizontal then
			row, col = wrap, slot
		else
			col, row = wrap, slot
		end

		popupButton:ClearAllPoints()
		popupButton:Point(point, holder, point, (col * (size + hSpacing) + pad) * hMult, (row * (popupHeight + vSpacing) + pad) * vMult)
	end

	local upFirst = direction == 'UP_RIGHT' or direction == 'UP_LEFT'
	local leftFirst = direction == 'LEFT_DOWN' or direction == 'LEFT_UP'

	local holderPoint, buttonPoint
	if upFirst then
		holderPoint = leftFirst and 'BOTTOMRIGHT' or 'BOTTOMLEFT'
		buttonPoint = leftFirst and 'TOPRIGHT' or 'TOPLEFT'
	else
		holderPoint = leftFirst and 'TOPRIGHT' or 'TOPLEFT'
		buttonPoint = leftFirst and 'BOTTOMRIGHT' or 'BOTTOMLEFT'
	end

	holder:ClearAllPoints()
	holder:Point(holderPoint, button, buttonPoint, 0, 0)
	holder:SetFrameStrata(button:GetFrameStrata())
	holder:SetFrameLevel(button:GetFrameLevel() + 5)
end

function A:PositionButtons(header)
	if not header or not header.buttons then return end
	if not header.auraType or not A.db or not A.db[header.auraType] then return end

	local db = A.db[header.auraType]
	local width, height = db.size, (db.keepSizeRatio and db.size) or db.height
	local point = DIRECTION_TO_POINT[db.growthDirection]
	local wrapAfter = db.wrapAfter or 8
	local maxWraps = db.maxWraps or 5
	local hSpacing = db.horizontalSpacing
	local vSpacing = db.verticalSpacing
	local isHorizontal = IS_HORIZONTAL_GROWTH[db.growthDirection]
	local hMult = DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[db.growthDirection]
	local vMult = DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[db.growthDirection]

	local visibleIndex = 0
	for i = 1, #header.buttons do
		local button = header.buttons[i]
		if button:IsShown() then
			local wrap = floor(visibleIndex / wrapAfter)
			if wrap >= maxWraps then
				button:Hide()
			else
				button:ClearAllPoints()

				local row, col
				if isHorizontal then
					row, col = wrap, visibleIndex % wrapAfter
				else
					col, row = wrap, visibleIndex % wrapAfter
				end

				local xOffset = col * (width + hSpacing) * hMult
				local yOffset = row * (height + vSpacing) * vMult

				button:Point(point, header, point, xOffset, yOffset)
				visibleIndex = visibleIndex + 1
			end
		end
	end
end

function A:UpdateHeader(header)
	if not E.private.auras.enable then return end

	local db = A.db[header.auraType]
	local width, height = db.size, (db.keepSizeRatio and db.size) or db.height

	E:UpdateClassColor(db.barColor)

	-- Calculate actual rows/columns needed based on button count
	local iconsPerRow = db.wrapAfter or 8
	local maxButtons = iconsPerRow * (db.maxWraps or 5)

	local numRows = math.ceil(maxButtons / iconsPerRow)  -- Calculate rows needed

	-- Calculate and set header size based on growth direction
	local headerWidth, headerHeight

	if IS_HORIZONTAL_GROWTH[db.growthDirection] then
		-- Horizontal: iconsPerRow wide, numRows tall
		headerWidth = (width * iconsPerRow) + (db.horizontalSpacing * (iconsPerRow - 1))
		headerHeight = (height * numRows) + (db.verticalSpacing * (numRows - 1))
	else
		-- Vertical: numRows wide, iconsPerRow tall
		headerWidth = (width * numRows) + (db.horizontalSpacing * (numRows - 1))
		headerHeight = (height * iconsPerRow) + (db.verticalSpacing * (iconsPerRow - 1))
	end

	header:SetSize(headerWidth, headerHeight)

	if header.buttons then
		for i = #header.buttons + 1, maxButtons do
			local button = CreateFrame('Button', header.name..'Button'..i, header)
			button:SetID(i)
			button:Hide()
			A:CreateIcon(button)
			header.buttons[i] = button
		end

		for i = 1, #header.buttons do
			local button = header.buttons[i]
			if button then
				A:Update_CooldownOptions(button)
				A:UpdateIcon(button, true)
			end
		end

		if header.consolidated then
			for i = 1, #header.consolidated do
				local button = header.consolidated[i]
				if button then
					A:Update_CooldownOptions(button)
					A:UpdateIcon(button, true)
				end
			end
		end
	end

	if header.MasqueGroup then
		A:UpdateMasque(header)
	end

	A:UpdateAllAuras(header)
end

function A:CreateAuraHeader(filter)
	local name, auraType = filter == 'HELPFUL' and 'ElvUIPlayerBuffs' or 'ElvUIPlayerDebuffs', filter == 'HELPFUL' and 'buffs' or 'debuffs'

	local header = CreateFrame('Frame', name, E.UIParent)
	header:SetClampedToScreen(true)
	header:SetSize(200, 200)
	header:Show()

	header.filter = filter
	header.auraType = auraType
	header.name = name

	header.buttons = {}

	local db = A.db[auraType]
	local numButtons = (db.wrapAfter or 8) * (db.maxWraps or 5)

	for i = 1, numButtons do
		local button = CreateFrame('Button', name .. 'Button' .. i, header)
		button:SetID(i)
		button:Hide()
		A:CreateIcon(button)
		header.buttons[i] = button
	end

	if filter == 'HELPFUL' then
		header.consolidatedList = {}

		local holder = CreateFrame('Frame', name .. 'ConsolidatedHolder', header)
		holder:SetClampedToScreen(true)
		holder:SetTemplate()
		holder:EnableMouse(true)
		holder:Hide()
		holder.filter = header.filter
		holder.auraType = header.auraType

		holder:SetScript('OnUpdate', function(hldr, elapsed)
			if hldr:IsMouseOver(2, -2, -2, 2) or (header.consolidateButton and header.consolidateButton:IsMouseOver(2, -2, -2, 2)) then
				hldr.hideTimer = 0
			else
				hldr.hideTimer = (hldr.hideTimer or 0) + elapsed
				if hldr.hideTimer > 0.3 then
					hldr:Hide()
				end
			end
		end)

		header.consolidatedHolder = holder
		header.consolidated = {}

		for i = 1, CONSOLIDATED_MAX_BUTTONS do
			local button = CreateFrame('Button', name .. 'ConsolidatedButton' .. i, holder)
			button:SetID(i)
			button:Hide()
			A:CreateIcon(button)
			header.consolidated[i] = button
		end
	end

	-- Register events
	header:RegisterEvent('UNIT_AURA')
	header:RegisterEvent('UNIT_INVENTORY_CHANGED')
	header:RegisterEvent('PLAYER_ENTERING_WORLD')

	header:HookScript('OnEvent', A.Header_OnEvent)
	header:SetScript('OnShow', A.Header_OnShow)
	header:SetScript('OnHide', A.Header_OnHide)

	if filter == 'HELPFUL' then
		if MasqueGroupBuffs and E.private.auras.masque.buffs then
			header.MasqueGroup = MasqueGroupBuffs
		end
	elseif MasqueGroupDebuffs and E.private.auras.masque.debuffs then
		header.MasqueGroup = MasqueGroupDebuffs
	end

	header:Show()

	A:Header_StartTicker(header)

	return header
end

function A:Initialize()
	if E.private.auras.disableBlizzard then
		BuffFrame:Kill()
		TemporaryEnchantFrame:Kill()

		if _G.DebuffFrame then
			_G.DebuffFrame:Kill()
		end

		if ConsolidatedBuffs then
			ConsolidatedBuffs:Kill()
		end
	end

	if not E.private.auras.enable then return end

	A.Initialized = true
	A.db = E.db.auras
	E.myguid = E.myguid or UnitGUID('player') -- Ensure we have the player's GUID

	local xoffset = -(6 + E.Border)

	if E.private.auras.buffsHeader then
		A.BuffFrame = A:CreateAuraHeader('HELPFUL')
		A:UpdateHeader(A.BuffFrame)

		A.BuffFrame:ClearAllPoints()
		A.BuffFrame:Point('TOPRIGHT', _G.ElvUI_MinimapHolder or _G.Minimap, 'TOPLEFT', xoffset, -E.Spacing)

		E:CreateMover(A.BuffFrame, 'BuffsMover', L["Player Buffs"], nil, nil, nil, nil, nil, 'auras,buffs')

		hooksecurefunc('SetCVar', function(cvar)
			if cvar and strlower(cvar) == 'consolidatebuffs' and A.BuffFrame then
				A:UpdateAllAuras(A.BuffFrame)
			end
		end)
	end

	if E.private.auras.debuffsHeader then
		A.DebuffFrame = A:CreateAuraHeader('HARMFUL')
		A:UpdateHeader(A.DebuffFrame)

		A.DebuffFrame:ClearAllPoints()
		A.DebuffFrame:Point('BOTTOMRIGHT', _G.ElvUI_MinimapHolder or _G.Minimap, 'BOTTOMLEFT', xoffset, E.Spacing)

		E:CreateMover(A.DebuffFrame, 'DebuffsMover', L["Player Debuffs"], nil, nil, nil, nil, nil, 'auras,debuffs')
	end
end

E:RegisterModule(A:GetName())