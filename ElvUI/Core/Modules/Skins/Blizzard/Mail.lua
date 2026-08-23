local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local function SkinSendMail()
	for i = 1, ATTACHMENTS_MAX_SEND do
		local btn = _G["SendMailAttachment"..i]
		if not btn.template then
			local icon = btn:GetNormalTexture()
			local iconTexture = icon and icon:GetTexture()

			btn:StripTextures()
			btn:SetTemplate()
			btn:StyleButton()

			if iconTexture then
				icon:SetTexture(iconTexture)
			end

			S:HandleIconBorder(btn.IconBorder)
			btn.template = true
		end

		local icon = btn:GetNormalTexture()
		if icon then
			icon:SetTexCoords()
			icon:SetInside()
		end

		local itemName = _G.GetSendMailItem(i)
		local quality = itemName and select(3, _G.GetItemInfo(itemName))
		if quality then
			local r, g, b = _G.GetItemQualityColor(quality)
			btn:SetBackdropBorderColor(r, g, b)
		else
			btn:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end
end

local function SkinOpenMail()
	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		local btn = _G["OpenMailAttachmentButton"..i]
		if not btn.template then
			local icon = btn.icon or btn.Icon
			local iconTexture = icon and icon:GetTexture()
			local r, g, b, a
			if icon then
				r, g, b, a = icon:GetVertexColor()
			end

			btn:StripTextures()
			btn:SetTemplate(nil, true)
			btn:StyleButton()

			if iconTexture then
				icon:SetTexture(iconTexture)
				if r and g and b then
					icon:SetVertexColor(r, g, b, a)
				end
			end

			S:HandleIconBorder(btn.IconBorder)
			btn.template = true
		end

		local icon = btn.icon or btn.Icon
		if icon then
			icon:SetTexCoords()
			icon:SetInside()
		end

		local openMailID = _G.InboxFrame.openMailID
		local itemLink = openMailID and openMailID ~= 0 and _G.GetInboxItemLink(openMailID, i)
		local quality = itemLink and select(3, _G.GetItemInfo(itemLink))
		if quality then
			local r, g, b = _G.GetItemQualityColor(quality)
			btn:SetBackdropBorderColor(r, g, b)
		else
			btn:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end
end

local function SkinInboxItems()
	for i = 1, INBOXITEMS_TO_DISPLAY do
		local item = _G["MailItem"..i]
		if not item then return end
		item:StripTextures()

		local btn = item.Button
		if not btn.template then
			local icon = btn.icon or btn.Icon
			local iconTexture = icon and icon:GetTexture()

			btn:StripTextures()
			btn:SetTemplate(nil, true)
			btn:StyleButton()

			if icon and iconTexture then
				icon:SetTexture(iconTexture)
			end

			S:HandleIconBorder(btn.IconBorder)
			btn.template = true
		end

		local icon = btn.icon or btn.Icon
		if icon then
			icon:SetDrawLayer("BORDER")
			icon:SetTexCoords()
			icon:SetInside()

			if btn.index and item:IsShown() then
				local packageIcon, stationeryIcon, _, _, _, _, _, _, _, _, _, _, isGM = GetInboxHeaderInfo(btn.index)
				if packageIcon or stationeryIcon then
					icon:SetTexture(packageIcon or stationeryIcon)
				end

				if isGM then
					btn:SetBackdropBorderColor(0, 0.56, 0.94)
				else
					local r, g, b
					if packageIcon then
						local itemLink = _G.GetInboxItemLink(btn.index, 1)
						local quality = itemLink and select(3, _G.GetItemInfo(itemLink))
						if quality then
							r, g, b = _G.GetItemQualityColor(quality)
						end
					end

					if r then
						btn:SetBackdropBorderColor(r, g, b)
					else
						btn:SetBackdropBorderColor(unpack(E.media.bordercolor))
					end
				end
			end
		end

		if item.DeleteButton then
			item.DeleteButton:SetShown(not not (btn.index and _G.InboxItemCanDelete(btn.index)))
		end
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.mail then return end

	local MailFrame = _G.MailFrame
	S:HandleSirusFrame(MailFrame)

	local inbox = _G.InboxFrame
	if not inbox then return end

	if inbox.LeftContainer then
		inbox.LeftContainer:StripTextures()
		if inbox.LeftContainer.ShadowOverlay then inbox.LeftContainer.ShadowOverlay:Hide() end
		if inbox.LeftContainer.ClassLogo then inbox.LeftContainer.ClassLogo:Kill() end
	end

	if inbox.RightContainer then
		inbox.RightContainer:StripTextures()
		if inbox.RightContainer.ShadowOverlay then inbox.RightContainer.ShadowOverlay:Hide() end
		if inbox.RightContainer.FactionLogo then inbox.RightContainer.FactionLogo:Kill() end
	end

	if inbox.WaitFrame then inbox.WaitFrame:StripTextures() end
	if _G.InboxTooMuchMail then _G.InboxTooMuchMail:StripTextures() end

	MailFrame:EnableMouseWheel(true)
	MailFrame:SetScript("OnMouseWheel", function(_, delta)
		if delta > 0 then
			if _G.InboxPrevPageButton:IsEnabled() == 1 then
				_G.InboxPrevPage()
			end
		elseif _G.InboxNextPageButton:IsEnabled() == 1 then
			_G.InboxNextPage()
		end
	end)

	local function DeleteMail_OnClick(self)
		local index = self.mailButton.index
		if index and _G.InboxItemCanDelete(index) then
			local popup = _G.StaticPopup_Show("FAST_DELETE_MAIL")
			if popup then popup.data = index end
		end
	end

	for i = 1, _G.INBOXITEMS_TO_DISPLAY do
		local item = _G["MailItem"..i]
		if item then
			item:CreateBackdrop("Default")
			item.backdrop:Point("TOPLEFT", 45, 0)
			item.backdrop:Point("BOTTOMRIGHT", 0, 0)

			if item.Button then
				item.Button:Size(45)
				item.Button:ClearAllPoints()
				item.Button:Point("LEFT", item, -1, 0)
			end

			if item.ExpireTime then
				item.ExpireTime:Point("TOPRIGHT", -4, -5)
			end

			local deleteButton = _G.CreateFrame("Button", "$parentDeleteButton", item)
			deleteButton:Size(16)
			deleteButton:Point("BOTTOMRIGHT", -4, 5)
			deleteButton.mailButton = item.Button
			deleteButton:SetScript("OnClick", DeleteMail_OnClick)
			deleteButton:Hide()

			deleteButton.Texture = deleteButton:CreateTexture(nil, "OVERLAY")
			deleteButton.Texture:Size(12)
			deleteButton.Texture:Point("CENTER")
			deleteButton.Texture:SetTexture(E.Media.Textures.Close)

			item.DeleteButton = deleteButton
		end
	end

	S:HandleNextPrevButton(_G.InboxPrevPageButton, nil, nil, true)
	_G.InboxPrevPageButton:StripTexts()
	_G.InboxPrevPageButton:Size(28)
	_G.InboxPrevPageButton:Point("BOTTOMLEFT", 8, 8)

	S:HandleNextPrevButton(_G.InboxNextPageButton, nil, nil, true)
	_G.InboxNextPageButton:StripTexts()
	_G.InboxNextPageButton:Size(28)
	_G.InboxNextPageButton:Point("BOTTOMRIGHT", -8, 8)

	S:HandleSirusTab(_G.MailFrameTab1)
	S:HandleSirusTab(_G.MailFrameTab2, _G.MailFrameTab1)

	_G.SendMailScrollFrame:StripTextures(true)
	_G.SendMailScrollFrame:SetTemplate()

	S:HandleSirusScrollBar(_G.SendMailScrollFrame.ScrollBar)

	S:HandleEditBox(_G.SendMailNameEditBox)
	S:HandleEditBox(_G.SendMailSubjectEditBox)
	S:HandleEditBox(_G.SendMailMoneyGold)
	S:HandleEditBox(_G.SendMailMoneySilver)
	S:HandleEditBox(_G.SendMailMoneyCopper)
	for _, box in next, { _G.SendMailMoneyGold, _G.SendMailMoneySilver, _G.SendMailMoneyCopper } do
		if box and box.backdrop then
			box.backdrop:ClearAllPoints()
			box.backdrop:SetPoint("TOPLEFT", box, "TOPLEFT", -4, 0)
			box.backdrop:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 4, 0)
		end
	end
	_G.SendMailMoneyBg:Kill()
	_G.SendMailMoneyInset:StripTextures()

	_G.SendMailNameEditBox:ClearAllPoints()
	_G.SendMailNameEditBox:Point("TOPLEFT", _G.SendMailFrame, "TOPLEFT", 90, -30)
	_G.SendMailNameEditBox:Width(109)
	_G.SendMailNameEditBox:Height(18)

	_G.SendMailSubjectEditBox:Point("TOPLEFT", _G.SendMailNameEditBox, "BOTTOMLEFT", 0, -10)
	_G.SendMailSubjectEditBox:Width(214)
	_G.SendMailSubjectEditBox:Height(18)

	_G.SendMailFrame:StripTextures()
	if _G.SendMailFrame.Content then _G.SendMailFrame.Content:StripTextures() end

	SkinSendMail()
	SkinOpenMail()
	SkinInboxItems()

	hooksecurefunc("SendMailFrame_Update", SkinSendMail)
	hooksecurefunc("OpenMail_Update", SkinOpenMail)
	hooksecurefunc("InboxFrame_Update", SkinInboxItems)

	S:HandleButton(_G.SendMailMailButton, true)
	S:HandleButton(_G.SendMailCancelButton, true)

	S:HandleRadioButton(_G.SendMailSendMoneyButton)
	S:HandleRadioButton(_G.SendMailCODButton)
	_G.SendMailSendMoneyButton:ClearAllPoints()
	_G.SendMailSendMoneyButton:SetPoint("TOPLEFT", _G.SendMailMoney, "TOPRIGHT", 16, 18)
	_G.SendMailCODButton:ClearAllPoints()
	_G.SendMailCODButton:SetPoint("TOPLEFT", _G.SendMailSendMoneyButton, "BOTTOMLEFT", 0, -4)

	_G.OpenMailFrame:StripTextures(true)
	_G.OpenMailFrame:SetTemplate("Transparent")
	if _G.OpenMailFrameInset then _G.OpenMailFrameInset:Kill() end

	local openMailCloseButton = _G.OpenMailFrame and _G.OpenMailFrame.CloseButton
	if openMailCloseButton then
		S:HandleCloseButton(openMailCloseButton)
	end
	S:HandleButton(_G.OpenMailReportSpamButton, true)
	S:HandleButton(_G.OpenMailReplyButton, true)
	S:HandleButton(_G.OpenMailDeleteButton, true)
	S:HandleButton(_G.OpenMailCancelButton, true)
	S:HandleButton(_G.OpenAllMailButton, true)
	S:HandleButton(_G.UpdateMailButton, true)

	S:HandleNextPrevButton(_G.AdditionalMailFunctionalButton, nil, nil, true)
	_G.AdditionalMailFunctionalButton:Size(28)
	_G.AdditionalMailFunctionalButton:Point("LEFT", _G.OpenAllMailButton, "RIGHT", 4, 0)

	_G.InboxFrame:StripTextures()

	_G.OpenMailScrollFrame:StripTextures(true)
	_G.OpenMailScrollFrame:SetTemplate()

	S:HandleSirusScrollBar(_G.OpenMailScrollFrame.ScrollBar)

	_G.InvoiceTextFontNormal:FontTemplate(nil, 13)
	_G.MailTextFontNormal:FontTemplate(nil, 13)
	_G.InvoiceTextFontNormal:SetTextColor(1, 1, 1)
	_G.MailTextFontNormal:SetTextColor(1, 1, 1)
	_G.OpenMailArithmeticLine:Kill()

	if _G.OpenMailHorizontalBarLeft then _G.OpenMailHorizontalBarLeft:Kill() end
	if _G.OpenMailHorizontalBarRight then _G.OpenMailHorizontalBarRight:Kill() end

	_G.OpenMailLetterButton:StripTextures()
	_G.OpenMailLetterButton:SetTemplate(nil, true)
	_G.OpenMailLetterButton:StyleButton()
	_G.OpenMailLetterButtonIconTexture:SetTexCoords()
	_G.OpenMailLetterButtonIconTexture:SetInside()

	_G.OpenMailMoneyButton:StripTextures()
	_G.OpenMailMoneyButton:SetTemplate(nil, true)
	_G.OpenMailMoneyButton:StyleButton()
	_G.OpenMailMoneyButtonIconTexture:SetTexCoords()
	_G.OpenMailMoneyButtonIconTexture:SetInside()

	_G.StationeryPopupFrame:StripTextures(true)
	_G.StationeryPopupFrame:SetTemplate("Transparent")
	_G.StationeryPopupScrollFrame:StripTextures()

	S:HandleButton(_G.StationeryPopupOkayButton, true)
	S:HandleButton(_G.StationeryPopupCancelButton, true)

	for i = 1, STATIONERYITEMS_TO_DISPLAY do
		local btn = _G["StationeryPopupButton"..i]
		if not btn.template then
			btn:StripTextures()
			btn:SetTemplate(nil, true)
			btn:StyleButton()
			btn.template = true
		end

		local icon = _G["StationeryPopupButton"..i.."Icon"]
		if icon then
			icon:SetTexCoords()
			icon:SetInside()
		end
	end
end

S:AddCallback("Skin_Mail", LoadSkin)
