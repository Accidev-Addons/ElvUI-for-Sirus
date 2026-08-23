local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local ipairs = ipairs
local find = string.find
local hooksecurefunc = hooksecurefunc

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
	if thumb then thumb:SetWidth(8) end

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

function S:ApplyElvUIFont(frame)
	if not frame or not frame.GetNumRegions then return end

	for i = 1, frame:GetNumRegions() do
		local region = select(i, frame:GetRegions())
		if region and region.GetObjectType and region:GetObjectType() == "FontString" then
			local _, size, flags = region:GetFont()
			if region.FontTemplate then
				region:FontTemplate(nil, size and size >= 1 and size or nil, flags)
			elseif region.SetFont then
				region:SetFont(E.media.normFont or select(1, GameFontNormal:GetFont()), (size and size >= 1) and size or 12, flags or "")
			end
		end
	end

	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		if child then
			S:ApplyElvUIFont(child)
		end
	end
end
