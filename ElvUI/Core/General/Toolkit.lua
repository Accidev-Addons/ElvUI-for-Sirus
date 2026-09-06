local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')
local NP = E:GetModule('NamePlates')

local _G = _G
local pairs, pcall, unpack = pairs, pcall, unpack
local strsub, type, next = strsub, type, next
local hooksecurefunc = hooksecurefunc
local getmetatable = getmetatable

local EnumerateFrames = EnumerateFrames
local CreateFrame = CreateFrame
local GetTime = GetTime

local backdropr, backdropg, backdropb, backdropa = 0, 0, 0, 1
local borderr, borderg, borderb, bordera = 0, 0, 0, 1

local StripTexturesBlizzFrames = {
	'Inset',
	'inset',
	'InsetFrame',
	'LeftInset',
	'RightInset',
	'BG',
	'border',
	'Border',
	'BorderFrame',
	'NineSlice',
	'bottomInset',
	'BottomInset',
	'bgLeft',
	'bgRight',
	'FilligreeOverlay',
	'PortraitOverlay',
	'ArtOverlayFrame',
	'Portrait',
	'portrait',
	'ScrollFrameBorder',
}

local SetTexCoords
do
	local left, right, top, bottom = unpack(E.TexCoords)

	SetTexCoords = function(frame)
		if not pcall(frame.SetTexCoord, frame, left, right, top, bottom) and not frame.retryTexCoord then
			frame.retryTexCoord = true
			E:Delay(1, SetTexCoords, frame)
		end
	end

	function E:GetTexCoords()
		return left, right, top, bottom
	end

	function E:UpdateTexCoords()
		local m = 0.04 * (E.db.general.cropIcon or 2)

		left, right, top, bottom = m, 1 - m, m, 1 - m

		E.TexCoords[1], E.TexCoords[2], E.TexCoords[3], E.TexCoords[4] = left, right, top, bottom
	end
end

function E:SetPointsRestricted(frame)
	if frame and not pcall(frame.GetPoint, frame) then
		return true
	end
end

local function BackdropFrameLevel(frame, level)
	frame:SetFrameLevel(level)

	if frame.oborder then frame.oborder:SetFrameLevel(level) end
	if frame.iborder then frame.iborder:SetFrameLevel(level) end
end

local function BackdropFrameLower(backdrop, parent)
	local level = parent:GetFrameLevel()
	local minus = level and (level - 1)
	if minus and (minus >= 0) then
		BackdropFrameLevel(backdrop, minus)
	else
		BackdropFrameLevel(backdrop, 0)
	end
end

local function GetTemplate(template, isUnitFrameElement)
	backdropa, bordera = 1, 1

	if template == 'ClassColor' then
		local color = E.myClassColor
		borderr, borderg, borderb = color.r, color.g, color.b
		backdropr, backdropg, backdropb = unpack(E.media.backdropcolor)
	elseif template == 'Transparent' then
		borderr, borderg, borderb = unpack(isUnitFrameElement and E.media.unitframeBorderColor or E.media.bordercolor)
		backdropr, backdropg, backdropb, backdropa = unpack(E.media.backdropfadecolor)
	else
		borderr, borderg, borderb = unpack(isUnitFrameElement and E.media.unitframeBorderColor or E.media.bordercolor)
		backdropr, backdropg, backdropb = unpack(E.media.backdropcolor)
	end
end

local function GetDebugName(frame)
	if frame.GetName then
		local name = frame:GetName()
		if name then return name end
	end

	for k, v in pairs(frame) do
		if type(v) == 'table' and v.GetName then
			local name = v:GetName()
			if name then return name end
		end
	end

	return 'Unknown'
end

local function GetChild(frame, child, index, debug)
	local name = frame and child and (frame.GetName and frame:GetName())
	if not name then return nil end
	if not index then index = '' end

	-- try keyed first
	local main = _G[name]
	local sub = main and main[child..index]
	if sub then return sub end

	-- if its not keyed try named
	return _G[name..child..index]
end

local function Size(frame, width, height, ...)
	local w = E:Scale(width, frame)
	frame:SetSize(w, (height and E:Scale(height, frame)) or w, ...)
end

local function Width(frame, width, ...)
	frame:SetWidth(E:Scale(width, frame), ...)
end

local function Height(frame, height, ...)
	frame:SetHeight(E:Scale(height, frame), ...)
end

local function OffsetFrameLevel(frame, offset, secondary)
	if not secondary then secondary = frame end

	local level = secondary:GetFrameLevel()
	frame:SetFrameLevel(level + (offset or 0))
end

local function Point(obj, arg1, arg2, arg3, arg4, arg5, ...)
	if not arg2 then arg2 = obj:GetParent() end

	if type(arg2)=='number' then arg2 = E:Scale(arg2, obj) end
	if type(arg3)=='number' then arg3 = E:Scale(arg3, obj) end
	if type(arg4)=='number' then arg4 = E:Scale(arg4, obj) end
	if type(arg5)=='number' then arg5 = E:Scale(arg5, obj) end

	obj:SetPoint(arg1, arg2, arg3, arg4, arg5, ...)
end

local function GrabPoint(obj, pointValue)
	if type(pointValue) == 'string' then
		local pointIndex = tonumber(pointValue) -- but why?
		if not pointIndex then
			for i = 1, obj:GetNumPoints() do
				local point, relativeTo, relativePoint, xOfs, yOfs = obj:GetPoint(i)
				if not point then
					break
				elseif point == pointValue then
					return point, relativeTo, relativePoint, xOfs, yOfs
				end
			end
		end

		pointValue = pointIndex -- convert it, if possible
	end

	return obj:GetPoint(pointValue)
end

local function NudgePoint(obj, xAxis, yAxis, noScale, pointValue, clearPoints)
	if not xAxis then xAxis = 0 end
	if not yAxis then yAxis = 0 end

	local x = (noScale and xAxis) or E:Scale(xAxis, obj)
	local y = (noScale and yAxis) or E:Scale(yAxis, obj)

	local point, relativeTo, relativePoint, xOfs, yOfs = GrabPoint(obj, pointValue)

	if clearPoints or E:SetPointsRestricted(obj) then
		obj:ClearAllPoints()
	end

	obj:SetPoint(point, relativeTo, relativePoint, xOfs + x, yOfs + y)
end

local function PointXY(obj, xOffset, yOffset, noScale, pointValue, clearPoints)
	local x = xOffset and ((noScale and xOffset) or E:Scale(xOffset, obj))
	local y = yOffset and ((noScale and yOffset) or E:Scale(yOffset, obj))

	local point, relativeTo, relativePoint, xOfs, yOfs = GrabPoint(obj, pointValue)

	if clearPoints or E:SetPointsRestricted(obj) then
		obj:ClearAllPoints()
	end

	obj:SetPoint(point, relativeTo, relativePoint, x or xOfs, y or yOfs)
end

local function SetOutside(obj, anchor, xOffset, yOffset, anchor2, noScale)
	if not anchor then anchor = obj:GetParent() end

	if not xOffset then xOffset = E.Border end
	if not yOffset then yOffset = E.Border end

	local x = (noScale and xOffset) or E:Scale(xOffset, obj)
	local y = (noScale and yOffset) or E:Scale(yOffset, obj)

	if E:SetPointsRestricted(obj) or obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -x, y)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', x, -y)
end

local function SetInside(obj, anchor, xOffset, yOffset, anchor2, noScale)
	if not anchor then anchor = obj:GetParent() end

	if not xOffset then xOffset = E.Border end
	if not yOffset then yOffset = E.Border end

	local x = (noScale and xOffset) or E:Scale(xOffset, obj)
	local y = (noScale and yOffset) or E:Scale(yOffset, obj)

	if E:SetPointsRestricted(obj) or obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', x, -y)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -x, y)
end

local function SetShown(frame, shown)
	if shown then
		frame:Show()
	else
		frame:Hide()
	end
end

local function SetEnabled(frame, enabled)
	if enabled then
		frame:Enable()
	else
		frame:Disable()
	end
end

local function GetDesaturation(frame)
    local r, g, b, a = frame:GetVertexColor()
    return r == .6 and g == .6 and b == .6 and a == .8
end

function E:SetForcedBorderColor(region, r, g, b, a)
	local fc = region.forcedBorderColors
	if not fc then
		fc = {}
		region.forcedBorderColors = fc
	end

	fc[1], fc[2], fc[3], fc[4] = r, g, b, a

	region:SetBackdropBorderColor(r, g, b, a)
end

function E:ClearForcedBorderColor(region, r, g, b, a)
	region.forcedBorderColors = nil

	region:SetBackdropBorderColor(r, g, b, a)
end

local function SetTemplate(frame, template, glossTex, ignoreUpdates, forcePixelMode, isUnitFrameElement, isNamePlateElement, noScale)
	GetTemplate(template, isUnitFrameElement)

	local keepr, keepg, keepb, keepa
	if frame.ignoreBorderColors and not frame.forcedBorderColors then
		keepr, keepg, keepb, keepa = frame:GetBackdropBorderColor()
	end

	frame.template = template or 'Default'
	frame.glossTex = glossTex
	frame.ignoreUpdates = ignoreUpdates
	frame.forcePixelMode = forcePixelMode
	frame.isUnitFrameElement = isUnitFrameElement
	frame.isNamePlateElement = isNamePlateElement

	if template == 'NoBackdrop' then
		frame:SetBackdrop(nil)
	else
		local edgeSize = 1

		frame:SetBackdrop({
			edgeFile = E.media.blankTex,
			bgFile = glossTex and (type(glossTex) == 'string' and glossTex or E.media.glossTex) or E.media.blankTex,
			edgeSize = noScale and edgeSize or E:PixelSize(edgeSize, frame)
		})

		if frame.callbackBackdropColor then
			frame:callbackBackdropColor()
		else
			frame:SetBackdropColor(backdropr, backdropg, backdropb, frame.customBackdropAlpha or (template == 'Transparent' and backdropa) or 1)
		end

		local notPixelMode = not isUnitFrameElement and not isNamePlateElement and not E.PixelMode
		local notThinBorders = (isUnitFrameElement and not UF.thinBorders) or (isNamePlateElement and not NP.thinBorders)
		if (notPixelMode or notThinBorders) and not forcePixelMode then
			local backdrop = {
				edgeFile = E.media.blankTex,
				edgeSize = noScale and 1 or E:PixelSize(1, frame)
			}

			local level = frame:GetFrameLevel()
			if not frame.iborder then
				local border = CreateFrame('Frame', nil, frame)
				border:SetBackdrop(backdrop)
				border:SetBackdropBorderColor(0, 0, 0, 1)
				border:SetFrameLevel(level)
				border:SetInside(frame, 1, 1, nil, noScale)
				frame.iborder = border
			end

			if not frame.oborder then
				local border = CreateFrame('Frame', nil, frame)
				border:SetBackdrop(backdrop)
				border:SetBackdropBorderColor(0, 0, 0, 1)
				border:SetFrameLevel(level)
				border:SetOutside(frame, 1, 1, nil, noScale)
				frame.oborder = border
			end
		end
	end

	if frame.forcedBorderColors then
		borderr, borderg, borderb, bordera = unpack(frame.forcedBorderColors)
	elseif keepr then
		borderr, borderg, borderb, bordera = keepr, keepg, keepb, keepa
	end

	frame:SetBackdropBorderColor(borderr, borderg, borderb, bordera)

	if not frame.ignoreUpdates then
		if frame.isUnitFrameElement then
			E.unitFrameElements[frame] = true
		else
			E.frames[frame] = true
		end
	end
end

local function CreateBackdrop(frame, template, glossTex, ignoreUpdates, forcePixelMode, isUnitFrameElement, isNamePlateElement, noScale, allPoints, frameLevel)
	local parent = (frame.IsObjectType and frame:IsObjectType('Texture') and frame:GetParent()) or frame
	local backdrop = frame.backdrop or CreateFrame('Frame', nil, parent)
	if not frame.backdrop then frame.backdrop = backdrop end

	backdrop:SetTemplate(template, glossTex, ignoreUpdates, forcePixelMode, isUnitFrameElement, isNamePlateElement, noScale)

	if allPoints then
		if allPoints == true then
			backdrop:SetAllPoints()
		else
			backdrop:SetAllPoints(allPoints)
		end
	else
		if forcePixelMode then
			backdrop:SetOutside(frame, 1, 1, nil, noScale)
		else
			local border = (isUnitFrameElement and UF.BORDER) or (isNamePlateElement and NP.BORDER)
			backdrop:SetOutside(frame, border, border, nil, noScale)
		end
	end

	if frameLevel then
		if frameLevel == true then
			BackdropFrameLevel(backdrop, parent:GetFrameLevel())
		else
			BackdropFrameLevel(backdrop, frameLevel)
		end
	else
		BackdropFrameLower(backdrop, parent)
	end
end

local function CreateShadow(frame, size, pass)
	if not pass and frame.shadow then return end
	if not size then size = 3 end

	backdropr, backdropg, backdropb, borderr, borderg, borderb = 0, 0, 0, 0, 0, 0

	local offset = (E.PixelMode and size) or (size + 1)
	local shadow = CreateFrame('Frame', nil, frame)
	shadow:SetFrameLevel(1)
	shadow:SetFrameStrata(frame:GetFrameStrata())
	shadow:SetOutside(frame, offset, offset, nil, true)
	shadow:SetBackdrop({edgeFile = E.Media.Textures.GlowTex, edgeSize = size})
	shadow:SetBackdropColor(backdropr, backdropg, backdropb, 0)
	shadow:SetBackdropBorderColor(borderr, borderg, borderb, 0.9)

	if pass then
		return shadow
	else
		frame.shadow = shadow
	end
end

local function Kill(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(E.HiddenFrame)
	else
		object.Show = object.Hide
	end

	object:Hide()
end

local STRIP_TEX = 'Texture'
local STRIP_FONT = 'FontString'
local function StripRegion(which, object, kill, zero)
	if kill then
		object:Kill()
	elseif zero then
		object:SetAlpha(0)
	elseif which == STRIP_TEX then
		object:SetTexture(E.ClearTexture)
	elseif which == STRIP_FONT then
		object:SetText('')
	end
end

local function StripType(which, object, kill, zero)
	if object:IsObjectType(which) then
		StripRegion(which, object, kill, zero)
	else
		if which == STRIP_TEX then
			local FrameName = object.GetName and object:GetName()
			for _, Blizzard in pairs(StripTexturesBlizzFrames) do
				local BlizzFrame = object[Blizzard] or (FrameName and _G[FrameName..Blizzard])
				if BlizzFrame and BlizzFrame.StripTextures then
					BlizzFrame:StripTextures(kill, zero)
				end
			end
		end

		if object.GetNumRegions then
			for _, region in next, { object:GetRegions() } do
				if region and region.IsObjectType and region:IsObjectType(which) then
					StripRegion(which, region, kill, zero)
				end
			end
		end
	end
end

local function StripTextures(object, kill, zero)
	StripType(STRIP_TEX, object, kill, zero)
end

local function StripTexts(object, kill, zero)
	StripType(STRIP_FONT, object, kill, zero)
end

local function ValidFontSize(size)
	return type(size) == 'number' and size == size and size >= 0.1
end

local function FontTemplate(fs, font, size, style, skip)
	if not skip then -- ignore updates from UpdateFontTemplates
		fs.font, fs.fontSize, fs.fontStyle = font, size, style
	end

	-- grab values from profile before conversion
	if not style then style = E.db.general.fontStyle or P.general.fontStyle end
	-- 3.3.5a SetFont errors out on 0/negative/NaN and renders nothing on sub-pixel sizes
	if not ValidFontSize(size) then
		local profileSize = E.db.general.fontSize
		size = (ValidFontSize(profileSize) and profileSize) or P.general.fontSize
	end
	if style == 'NONE' then style = '' end -- none isnt a real style

	local shadow = strsub(style, 0, 6) == 'SHADOW'
	if shadow then style = strsub(style, 7) end -- shadow isnt a real style

	fs:SetShadowColor(0, 0, 0, (shadow and (style == '' and 1 or 0.6)) or 0)
	fs:SetShadowOffset((shadow and 1) or 0, (shadow and -1) or 0)

	fs:SetFont(font or E.media.normFont, size, style)

	E.texts[fs] = true
end

local function StyleButton(button, noHover, noPushed, noChecked)
	if button.SetHighlightTexture and button.CreateTexture and not button.hover and not noHover then
		button:SetHighlightTexture(E.media.blankTex)

		local hover = button:GetHighlightTexture()
		hover:SetInside()
		hover:SetBlendMode('ADD')
		hover:SetTexture(1, 1, 1, .3)
		button.hover = hover
	end

	if button.SetPushedTexture and button.CreateTexture and not button.pushed and not noPushed then
		button:SetPushedTexture(E.media.blankTex)

		local pushed = button:GetPushedTexture()
		pushed:SetInside()
		pushed:SetBlendMode('ADD')
		pushed:SetTexture(0.9, 0.8, 0.1, 0.3)
		button.pushed = pushed
	end

	if button.SetCheckedTexture and button.CreateTexture and not button.checked and not noChecked then
		button:SetCheckedTexture(E.media.blankTex)

		local checked = button:GetCheckedTexture()
		checked:SetInside()
		checked:SetBlendMode('ADD')
		checked:SetTexture(1, 1, 1, 0.3)
		button.checked = checked
	end

	local name = button.GetName and button:GetName()
	local cooldown = name and _G[name..'Cooldown']
	if cooldown then
		cooldown:ClearAllPoints()
		cooldown:SetInside(button, 0, 0)
	end
end

local CreateCloseButton
do
	local CloseButtonOnClick = function(btn) btn:GetParent():Hide() end
	local CloseButtonOnEnter = function(btn) if btn.Texture then btn.Texture:SetVertexColor(unpack(E.media.rgbvaluecolor)) end end
	local CloseButtonOnLeave = function(btn) if btn.Texture then btn.Texture:SetVertexColor(1, 1, 1) end end
	CreateCloseButton = function(frame, size, offset, texture, backdrop)
		if frame.CloseButton then return end

		local CloseButton = CreateFrame('Button', nil, frame)
		CloseButton:Size(size or 16)
		CloseButton:Point('TOPRIGHT', offset or -6, offset or -6)
		if backdrop then
			CloseButton:CreateBackdrop(nil, true)
		end

		CloseButton.Texture = CloseButton:CreateTexture(nil, 'OVERLAY')
		CloseButton.Texture:SetAllPoints()
		CloseButton.Texture:SetTexture(texture or E.Media.Textures.Close)

		CloseButton:SetScript('OnClick', CloseButtonOnClick)
		CloseButton:SetScript('OnEnter', CloseButtonOnEnter)
		CloseButton:SetScript('OnLeave', CloseButtonOnLeave)

		frame.CloseButton = CloseButton
	end
end

local function SwipeOnUpdate(self)
	if GetTime() >= self.expires then
		self.swipe:Hide()
		self:Hide()
	end
end

local function OnCooldownSet(self, start, duration)
	local updater = self._elvSwipeUpdater
	if not updater then return end

	if start and start > 0 and duration and duration > 0.1 and start + duration > GetTime() then
		updater.expires = start + duration
		updater.swipe:Show()
		updater:Show()
	else
		updater.swipe:Hide()
		updater:Hide()
	end
end

local function SetSwipeColor(self, r, g, b, a)
	local updater = self._elvSwipeUpdater
	if not updater then
		updater = CreateFrame('Frame', nil, self)
		updater:Hide()
		updater:SetScript('OnUpdate', SwipeOnUpdate)
		updater:SetScript('OnShow', SwipeOnUpdate)

		local swipe = self:CreateTexture(nil, 'BACKGROUND', nil, -5)
		swipe:SetAllPoints(self)
		swipe:SetTexture(E.Media.Textures.White8x8)
		swipe:SetBlendMode('ADD')
		swipe:Hide()
		updater.swipe = swipe
		self._elvSwipeUpdater = updater
		hooksecurefunc(self, 'SetCooldown', OnCooldownSet)
	end

	updater.swipe:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
end

E.UpdateCooldownSwipe = OnCooldownSet

local CooldownProto = getmetatable(CreateFrame('Cooldown', nil, UIParent)).__index
if not CooldownProto.SetSwipeColor then
	CooldownProto.SetSwipeColor = SetSwipeColor
end

local API = {
	Kill = Kill,
	Size = Size,
	Point = Point,
	Width = Width,
	Height = Height,
	PointXY = PointXY,
	GrabPoint = GrabPoint,
	NudgePoint = NudgePoint,
	SetEnabled = SetEnabled,
	GetDesaturation = GetDesaturation,
	SetOutside = SetOutside,
	SetInside = SetInside,
	SetShown = SetShown,
	SetTemplate = SetTemplate,
	CreateBackdrop = CreateBackdrop,
	CreateShadow = CreateShadow,
	FontTemplate = FontTemplate,
	StripTextures = StripTextures,
	StripTexts = StripTexts,
	StyleButton = StyleButton,
	OffsetFrameLevel = OffsetFrameLevel,
	CreateCloseButton = CreateCloseButton,
	SetTexCoords = SetTexCoords,
	GetDebugName = GetDebugName,
	GetChild = GetChild,
}

local function addapi(object)
	local mk = getmetatable(object).__index
	for method, func in next, API do
		if not object[method] then
			mk[method] = func
		end
	end
end

local handled = { Frame = true }
local object = CreateFrame('Frame')
addapi(object)
addapi(object:CreateTexture())
addapi(object:CreateFontString())

object = EnumerateFrames()
while object do
	local objType = object:GetObjectType()
	if not handled[objType] then
		addapi(object)
		handled[objType] = true
	end

	object = EnumerateFrames(object)
end

addapi(_G.GameFontNormal) --Add API to `CreateFont` objects without actually creating one
addapi(CreateFrame('Cooldown')) -- register our new Cooldown methods too