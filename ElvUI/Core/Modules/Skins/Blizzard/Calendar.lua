local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.calendar then return end
	local frames = {
		"CalendarFrame",
	}

	for _, frame in pairs(frames) do
		_G[frame]:StripTextures()
	end

	CalendarFrame:CreateBackdrop("Transparent")
	CalendarFrame.backdrop:Point("TOPLEFT", 1, -2)
	CalendarFrame.backdrop:Point("BOTTOMRIGHT", -2, -7)

	CalendarFrame:EnableMouseWheel(true)
	CalendarFrame:SetScript("OnMouseWheel", function(_, value)
		if value > 0 then
			if CalendarPrevMonthButton:IsEnabled() == 1 then
				CalendarPrevMonthButton_OnClick()
			end
		else
			if CalendarNextMonthButton:IsEnabled() == 1 then
				CalendarNextMonthButton_OnClick()
			end
		end
	end)

	S:HandleCloseButton(CalendarCloseButton)
	CalendarCloseButton:Point("TOPRIGHT", CalendarFrame, "TOPRIGHT", -4, -4)

	S:HandleNextPrevButton(CalendarPrevMonthButton)
	S:HandleNextPrevButton(CalendarNextMonthButton)

	do
		local frame = CalendarFilterFrame
		local button = CalendarFilterButton

		frame:StripTextures()
		frame:Width(155)

		_G[frame:GetName().."Text"]:ClearAllPoints()
		_G[frame:GetName().."Text"]:Point("RIGHT", button, "LEFT", -2, 0)

		button:ClearAllPoints()
		button:Point("RIGHT", frame, "RIGHT", -10, 3)
		hooksecurefunc(button, "SetPoint", function(self, point, attachTo, anchorPoint, xOffset, yOffset)
			if point ~= "RIGHT" or attachTo ~= frame or anchorPoint ~= "RIGHT" or xOffset ~= -10 or yOffset ~= 3 then
				self:ClearAllPoints()
				self:SetPoint("RIGHT", frame, "RIGHT", -10, 3)
			end
		end)

		S:HandleNextPrevButton(button)

		frame:CreateBackdrop("Default")
		frame.backdrop:Point("TOPLEFT", 20, 2)
		frame.backdrop:Point("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	end

	local bg = CreateFrame("Frame", "CalendarFrameBackdrop", CalendarFrame)
	bg:SetTemplate("Default")
	bg:SetOutside(CalendarDayButton1, 3, 3, CalendarDayButton42)

	CalendarContextMenu:SetTemplate("Default")
	hooksecurefunc(CalendarContextMenu, "SetBackdropColor", function(self, r, g, b, a)
		local r2, g2, b2, a2 = unpack(E["media"].backdropfadecolor)
		if r ~= r2 or g ~= g2 or b ~= b2 or a ~= a2 then
			self:SetBackdropColor(r2, g2, b2, a2)
		end
	end)
	hooksecurefunc(CalendarContextMenu, "SetBackdropBorderColor", function(self, r, g, b)
		local r2, g2, b2 = unpack(E["media"].bordercolor)
		if r ~= r2 or g ~= g2 or b ~= b2 then
			self:SetBackdropBorderColor(r2, g2, b2)
		end
	end)

	CalendarInviteStatusContextMenu:SetTemplate("Default")
	hooksecurefunc(CalendarInviteStatusContextMenu, "SetBackdropColor", function(self, r, g, b, a)
		local r2, g2, b2, a2 = unpack(E["media"].backdropfadecolor)
		if r ~= r2 or g ~= g2 or b ~= b2 or a ~= a2 then
			self:SetBackdropColor(r2, g2, b2, a2)
		end
	end)
	hooksecurefunc(CalendarInviteStatusContextMenu, "SetBackdropBorderColor", function(self, r, g, b)
		local r2, g2, b2 = unpack(E["media"].bordercolor)
		if r ~= r2 or g ~= g2 or b ~= b2 then
			self:SetBackdropBorderColor(r2, g2, b2)
		end
	end)

	for i=1, 7 do
		_G["CalendarContextMenuButton"..i]:StyleButton()
	end

	for i = 1, 42 do
		local button = _G["CalendarDayButton" .. i]
		local eventTexture = _G["CalendarDayButton" .. i .. "EventTexture"]
		local overlayFrame = _G["CalendarDayButton" .. i .. "OverlayFrame"]
		button:SetFrameLevel(button:GetFrameLevel() + 1)
		button:Size(91 - E.Border)
		button:SetTemplate("Default", nil, true)
		button:SetBackdropColor(0, 0, 0, 0)
		button:GetNormalTexture():SetInside()
		button:GetNormalTexture():SetDrawLayer("BACKGROUND")
		button:GetHighlightTexture():SetInside()
		button:GetHighlightTexture():SetTexture(1, 1, 1, 0.3)
		eventTexture:SetInside()
		overlayFrame:SetInside()

		for j = 1, 4 do
			local EventButton = _G["CalendarDayButton" .. i .. "EventButton" .. j]
			EventButton:StripTextures()
			EventButton:StyleButton()
		end

		button:ClearAllPoints()
		if(i == 1) then
			button:SetPoint("TOPLEFT", CalendarWeekday1Background, "BOTTOMLEFT", 0, 0)
		elseif(mod(i, 7) == 1) then
			button:SetPoint("TOPLEFT", _G["CalendarDayButton" .. (i - 7)], "BOTTOMLEFT", 0, -E.Border)
		else
			button:SetPoint("TOPLEFT", _G["CalendarDayButton" .. (i - 1)], "TOPRIGHT", E.Border, 0)
		end
	end

	CalendarTodayFrame:StripTextures()
	CalendarTodayFrame:SetTemplate("Default")
	CalendarTodayFrame:Size(CalendarDayButton1:GetWidth(), CalendarDayButton1:GetHeight())
	CalendarTodayFrame:SetBackdropBorderColor(unpack(E["media"].rgbvaluecolor))
	local value = E.db["general"].valuecolor
	CalendarTodayFrame:SetBackdropColor(value.r, value.g, value.b, 0.5)
	CalendarTodayFrame:HookScript("OnUpdate", function(self) self:SetAlpha(CalendarTodayTextureGlow:GetAlpha()) end)
	CalendarTodayFrame:CreateShadow()
	CalendarTodayFrame.shadow:SetBackdropBorderColor(unpack(E["media"].rgbvaluecolor))

	CalendarCreateEventFrame:StripTextures()
	CalendarCreateEventFrame:SetTemplate("Transparent")
	CalendarCreateEventFrame:Point("TOPLEFT", CalendarFrame, "TOPRIGHT", 2, -24)
	CalendarCreateEventTitleFrame:StripTextures()

	S:HandleButton(CalendarCreateEventCreateButton, true)
	S:HandleButton(CalendarCreateEventMassInviteButton, true)
	S:HandleButton(CalendarCreateEventInviteButton, true)
	CalendarCreateEventInviteButton:Point("TOPLEFT", CalendarCreateEventInviteEdit, "TOPRIGHT", 4, 1)
	CalendarCreateEventInviteEdit:Width(CalendarCreateEventInviteEdit:GetWidth() - 2)

	CalendarCreateEventInviteList:StripTextures()
	CalendarCreateEventInviteList:SetTemplate("Default")

	S:HandleEditBox(CalendarCreateEventInviteEdit)
	S:HandleEditBox(CalendarCreateEventTitleEdit)
	S:HandleDropDownBox(CalendarCreateEventTypeDropDown, 120)

	CalendarCreateEventDescriptionContainer:StripTextures()
	CalendarCreateEventDescriptionContainer:SetTemplate("Default")

	S:HandleCloseButton(CalendarCreateEventCloseButton)

	S:HandleCheckBox(CalendarCreateEventLockEventCheck)

	S:HandleDropDownBox(CalendarCreateEventHourDropDown, 68)
	S:HandleDropDownBox(CalendarCreateEventMinuteDropDown, 68)
	S:HandleDropDownBox(CalendarCreateEventAMPMDropDown, 68)
	S:HandleDropDownBox(CalendarCreateEventRepeatOptionDropDown, 120)
	CalendarCreateEventIcon:SetTexCoords()
	hooksecurefunc(CalendarCreateEventIcon, "SetTexCoord", function(self, left, right, top, bottom)
		local left2, right2, top2, bottom2 = E:GetTexCoords()
		if left ~= left2 or right ~= right2 or top ~= top2 or bottom ~= bottom2 then
			self:SetTexCoords()
		end
	end)

	CalendarCreateEventInviteListSection:StripTextures()

	CalendarClassButtonContainer:HookScript("OnShow", function()
		for i, class in ipairs(CLASS_SORT_ORDER) do
			local button = _G["CalendarClassButton"..i]
			button:StripTextures()
			button:CreateBackdrop("Default")
			button:Size(23)

			local tcoords = CLASS_ICON_TCOORDS[class]
			local buttonIcon = button:GetNormalTexture()
			buttonIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			buttonIcon:SetTexCoord(tcoords[1] + 0.015, tcoords[2] - 0.02, tcoords[3] + 0.018, tcoords[4] - 0.02)
		end

		CalendarClassButton1:Point("TOPLEFT", CalendarClassButtonContainer, "TOPLEFT", 2, 0)

		CalendarClassTotalsButton:StripTextures()
		CalendarClassTotalsButton:CreateBackdrop("Default")
		CalendarClassTotalsButton:Size(23)
	end)

	CalendarTexturePickerFrame:StripTextures()
	CalendarTexturePickerTitleFrame:StripTextures()

	CalendarTexturePickerFrame:SetTemplate("Transparent")
	CalendarTexturePickerFrame:Point("TOPRIGHT", CalendarFrame, "TOPRIGHT", 640, -22)

	S:HandleSirusScrollBar(CalendarTexturePickerScrollBar)
	S:HandleButton(CalendarTexturePickerAcceptButton, true)
	S:HandleButton(CalendarTexturePickerCancelButton, true)
	S:HandleButton(CalendarCreateEventInviteButton, true)
	S:HandleButton(CalendarCreateEventRaidInviteButton, true)

	for i=1, 16 do
		_G["CalendarTexturePickerScrollFrameButton"..i]:StyleButton()
	end

	CalendarMassInviteFrame:StripTextures()
	CalendarMassInviteFrame:SetTemplate("Transparent")
	CalendarMassInviteFrame:ClearAllPoints()
	CalendarMassInviteFrame:SetPoint("TOPLEFT", CalendarCreateEventFrame, "TOPRIGHT", 25, 0)

	CalendarMassInviteTitleFrame:StripTextures()

	S:HandleCloseButton(CalendarMassInviteCloseButton)
	S:HandleButton(CalendarMassInviteGuildAcceptButton)

	S:HandleDropDownBox(CalendarMassInviteGuildRankMenu, 130)

	S:HandleEditBox(CalendarMassInviteGuildMinLevelEdit)
	S:HandleEditBox(CalendarMassInviteGuildMaxLevelEdit)

	CalendarViewRaidFrame:StripTextures()
	CalendarViewRaidFrame:SetTemplate("Transparent")
	CalendarViewRaidFrame:Point("TOPLEFT", CalendarFrame, "TOPRIGHT", 1, -2)
	CalendarViewRaidTitleFrame:StripTextures()
	S:HandleCloseButton(CalendarViewRaidCloseButton)

	CalendarViewHolidayFrame:StripTextures(true)
	CalendarViewHolidayFrame:SetTemplate("Transparent")
	CalendarViewHolidayFrame:Point("TOPLEFT", CalendarFrame, "TOPRIGHT", 1, -2)
	CalendarViewHolidayTitleFrame:StripTextures()
	S:HandleCloseButton(CalendarViewHolidayCloseButton)

	CalendarViewEventFrame:StripTextures()
	CalendarViewEventFrame:SetTemplate("Transparent")
	CalendarViewEventFrame:Point("TOPLEFT", CalendarFrame, "TOPRIGHT", 1, -2)
	CalendarViewEventTitleFrame:StripTextures()
	CalendarViewEventDescriptionContainer:StripTextures()
	CalendarViewEventDescriptionContainer:SetTemplate("Transparent")
	CalendarViewEventInviteList:StripTextures()
	CalendarViewEventInviteList:SetTemplate("Transparent")
	CalendarViewEventInviteListSection:StripTextures()
	S:HandleCloseButton(CalendarViewEventCloseButton)
	S:HandleSirusScrollBar(CalendarViewEventInviteListScrollFrameScrollBar)

	CalendarEventPickerFrame:StripTextures()
	CalendarEventPickerTitleFrame:StripTextures()

	CalendarEventPickerFrame:SetTemplate("Transparent")

	S:HandleSirusScrollBar(CalendarEventPickerScrollBar)
	S:HandleButton(CalendarEventPickerCloseButton, true)

	S:HandleSirusScrollBar(CalendarCreateEventDescriptionScrollFrameScrollBar)
	S:HandleSirusScrollBar(CalendarCreateEventInviteListScrollFrameScrollBar)
	S:HandleSirusScrollBar(CalendarViewEventDescriptionScrollFrameScrollBar)
end

S:AddCallback("Skin_Calendar", LoadSkin)