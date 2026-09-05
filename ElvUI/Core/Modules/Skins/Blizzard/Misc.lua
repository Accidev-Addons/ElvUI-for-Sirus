local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local next = next
local select = select
local type = type
local unpack = unpack

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local function GameMenuClearedHooks(button, script)
	if script == 'OnEnter' then
		button:HookScript('OnEnter', S.SetModifiedBackdrop)
	elseif script == 'OnLeave' then
		button:HookScript('OnLeave', S.SetOriginalBackdrop)
	elseif script == 'OnDisable' then
		button:HookScript('OnDisable', S.SetDisabledBackdrop)
	end
end

local function GameMenuSkinButton(button)
	if not button or button.isSkinned then return end

	S:HandleButton(button, nil, nil, nil, true)
	if button.backdrop then
		button.backdrop:SetInside(nil, 1, 1)
	end

	hooksecurefunc(button, 'SetScript', GameMenuClearedHooks)
end

local function GameMenuStyleButtons()
	local GameMenuFrame = _G.GameMenuFrame
	if not GameMenuFrame then return end

	for i = 1, GameMenuFrame:GetNumChildren() do
		local Button = select(i, GameMenuFrame:GetChildren())
		if Button.IsObjectType and Button:IsObjectType('Button') then
			GameMenuSkinButton(Button)
		end
	end

	if GameMenuFrame.ElvUI then
		GameMenuSkinButton(GameMenuFrame.ElvUI)
	end
end

S:AddCallback('Skin_GameMenu', function()

	local GameMenuFrame = _G.GameMenuFrame
	if not GameMenuFrame then return end

	GameMenuFrame:StripTextures()
	GameMenuFrame:SetTemplate('Transparent')

	local header = _G.GameMenuFrameHeader
	if header then
		header:SetTexture('')
		header:ClearAllPoints()
		header:Point('TOP', GameMenuFrame, 0, 7)
	end

	GameMenuStyleButtons()

	local editMode = _G.GameMenuButtonEditMode
	if editMode then
		editMode:Hide()
		editMode.Show = E.noop

		local keybindings = _G.GameMenuButtonKeybindings
		local uiOptions = _G.GameMenuButtonUIOptions
		if keybindings and uiOptions then
			keybindings:SetPoint('TOP', uiOptions, 'BOTTOM', 0, -1)
		end
	end

	if GameMenuFrame_UpdateVisibleButtons then
		hooksecurefunc('GameMenuFrame_UpdateVisibleButtons', GameMenuStyleButtons)
	end
end)

S:AddCallback('Skin_Misc', function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.misc then return end

	for i = 1, 4 do
		local staticPopup = _G['StaticPopup'..i]
		local itemFrame = _G['StaticPopup'..i..'ItemFrame']
		local itemFrameBox = _G['StaticPopup'..i..'EditBox']
		local itemFrameTexture = _G['StaticPopup'..i..'ItemFrameIconTexture']
		local itemFrameNormal = _G['StaticPopup'..i..'ItemFrameNormalTexture']
		local itemFrameName = _G['StaticPopup'..i..'ItemFrameNameFrame']
		local closeButton = _G['StaticPopup'..i..'CloseButton']
		local wideBox = _G['StaticPopup'..i..'WideEditBox']

		staticPopup:SetTemplate('Transparent')

		S:HandleEditBox(itemFrameBox)
		itemFrameBox.backdrop:Point('TOPLEFT', -2, -4)
		itemFrameBox.backdrop:Point('BOTTOMRIGHT', 2, 4)

		S:HandleEditBox(_G['StaticPopup'..i..'MoneyInputFrameGold'])
		S:HandleEditBox(_G['StaticPopup'..i..'MoneyInputFrameSilver'])
		S:HandleEditBox(_G['StaticPopup'..i..'MoneyInputFrameCopper'])
		for _, box in next, { _G['StaticPopup'..i..'MoneyInputFrameGold'], _G['StaticPopup'..i..'MoneyInputFrameSilver'], _G['StaticPopup'..i..'MoneyInputFrameCopper'] } do
			if box and box.backdrop then
				box.backdrop:ClearAllPoints()
				box.backdrop:SetPoint("TOPLEFT", box, "TOPLEFT", -4, 0)
				box.backdrop:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 4, 0)
			end
		end
		local moneyBg = _G['StaticPopup'..i..'MoneyBg']
		if moneyBg then moneyBg:Kill() end
		local moneyInset = _G['StaticPopup'..i..'MoneyInputFrameInset']
		if moneyInset then moneyInset:StripTextures() end
		local moneyInputFrame = _G['StaticPopup'..i..'MoneyInputFrame']
		if moneyInputFrame then moneyInputFrame:StripTextures() end

		for j = 1, itemFrameBox:GetNumRegions() do
			local region = select(j, itemFrameBox:GetRegions())
			if region and region:IsObjectType('Texture') then
				if region:GetTexture() == [[Interface\ChatFrame\UI-ChatInputBorder-Left]] or region:GetTexture() == [[Interface\ChatFrame\UI-ChatInputBorder-Right]] then
					region:Kill()
				end
			end
		end

		closeButton:StripTextures()
		S:HandleCloseButton(closeButton, staticPopup)

		local bar = staticPopup.bar
		if bar then
			bar:StripTextures()
			bar:SetStatusBarTexture(E.media.normTex)
			bar:SetStatusBarColor(0.8, 0.1, 0.1)
			bar:CreateBackdrop('Transparent')
			E:RegisterStatusBar(bar)

			bar:ClearAllPoints()
			bar:Point('TOPLEFT', staticPopup, 'BOTTOMLEFT', 0, -1)
			bar:Point('TOPRIGHT', staticPopup, 'BOTTOMRIGHT', 0, -1)

			if bar.timeText then
				bar.timeText:FontTemplate()
			end
		end

		itemFrame:GetNormalTexture():Kill()
		itemFrame:SetTemplate()
		itemFrame:StyleButton()

		hooksecurefunc('StaticPopup_Show', function(which, _, _, data)
			local info = _G.StaticPopupDialogs[which]
			if not info then return nil end

			closeButton:SetNormalTexture(E.ClearTexture)
			closeButton:SetPushedTexture(E.ClearTexture)

			if info.hasItemFrame then
				if data and type(data) == 'table' then
					if data.color then
						itemFrame:SetBackdropBorderColor(unpack(data.color))
					else
						itemFrame:SetBackdropBorderColor(1, 1, 1, 1)
					end
				end
			end

			if info.equipmentSetButton and staticPopup.slotStorage then
				for _, slot in next, staticPopup.slotStorage do
					if not slot.isSkinned then
						local iconFrame = slot.IconFrame
						iconFrame:GetNormalTexture():Kill()
						iconFrame:SetTemplate()
						iconFrame:StyleButton()
						iconFrame.IconBorder:Kill()
						iconFrame.icon:SetTexCoords()
						iconFrame.icon:SetInside()

						slot.NameFrame.Background:Kill()
						slot.NameFrame.Text:FontTemplate()

						slot.isSkinned = true
					end
				end
			end
		end)

		itemFrameTexture:SetTexCoords()
		itemFrameTexture:SetInside()

		itemFrameNormal:SetAlpha(0)
		itemFrameName:Kill()

		select(8, wideBox:GetRegions()):Hide()
		S:HandleEditBox(wideBox)
		wideBox:Height(22)

		for j = 1, 3 do
			S:HandleButton(_G['StaticPopup'..i..'Button'..j])
		end
	end

	S:SkinDropDownMenu('DropDownList')

	_G.TicketStatusFrameButton:SetTemplate('Transparent')
	_G.AutoCompleteBox:SetTemplate('Transparent')
	_G.ConsolidatedBuffsTooltip:SetTemplate('Transparent')

	_G.BasicScriptErrors:SetScale(E.global.general.UIScale)
	_G.BasicScriptErrors:SetTemplate('Transparent')
	S:HandleButton(_G.BasicScriptErrorsButton)

	local ReadyCheckFrame = _G.ReadyCheckFrame
	ReadyCheckFrame:EnableMouse(true)
	ReadyCheckFrame:SetTemplate('Transparent')

	S:HandleButton(_G.ReadyCheckFrameYesButton)
	_G.ReadyCheckFrameYesButton:SetParent(ReadyCheckFrame)
	_G.ReadyCheckFrameYesButton:ClearAllPoints()
	_G.ReadyCheckFrameYesButton:Point('TOPRIGHT', ReadyCheckFrame, 'CENTER', -3, -5)

	S:HandleButton(_G.ReadyCheckFrameNoButton)
	_G.ReadyCheckFrameNoButton:SetParent(ReadyCheckFrame)
	_G.ReadyCheckFrameNoButton:ClearAllPoints()
	_G.ReadyCheckFrameNoButton:Point('TOPLEFT', ReadyCheckFrame, 'CENTER', 4, -5)

	_G.ReadyCheckFrameText:SetParent(ReadyCheckFrame)
	_G.ReadyCheckFrameText:Point('TOP', 0, -15)
	_G.ReadyCheckFrameText:SetTextColor(1, 1, 1)

	_G.ReadyCheckListenerFrame:SetAlpha(0)

	_G.CoinPickupFrame:StripTextures()
	_G.CoinPickupFrame:SetTemplate('Transparent')

	S:HandleButton(_G.CoinPickupOkayButton)
	S:HandleButton(_G.CoinPickupCancelButton)

	_G.ZoneTextFrame:ClearAllPoints()
	_G.ZoneTextFrame:Point('TOP', 0, -128)

	local StackSplitFrame = _G.StackSplitFrame
	StackSplitFrame:SetTemplate('Transparent')
	StackSplitFrame:GetRegions():Hide()
	StackSplitFrame:SetFrameStrata('DIALOG')

	StackSplitFrame.bg1 = CreateFrame('Frame', nil, StackSplitFrame)
	StackSplitFrame.bg1:OffsetFrameLevel(-1)
	StackSplitFrame.bg1:SetTemplate('Transparent')
	StackSplitFrame.bg1:Point('TOPLEFT', 10, -15)
	StackSplitFrame.bg1:Point('BOTTOMRIGHT', -10, 55)

	S:HandleButton(_G.StackSplitOkayButton)
	S:HandleButton(_G.StackSplitCancelButton)

	_G.OpacityFrame:StripTextures()
	_G.OpacityFrame:SetTemplate('Transparent')

	S:HandleSliderFrame(_G.OpacityFrameSlider)

	_G.ChannelPullout:SetTemplate('Transparent')

	_G.ChannelPulloutBackground:Kill()

	S:HandleTab(_G.ChannelPulloutTab)
	_G.ChannelPulloutTab:Size(107, 26)
	_G.ChannelPulloutTabText:Point('LEFT', _G.ChannelPulloutTabLeft, 'RIGHT', 0, 4)

	S:HandleCloseButton(_G.ChannelPulloutCloseButton, _G.ChannelPullout)
	_G.ChannelPulloutCloseButton:Size(32)

	do
		local menuBackdrop = function(s)
			s:SetTemplate('Transparent')
		end

		local chatMenuBackdrop = function(s)
			s:SetTemplate('Transparent')

			s:ClearAllPoints()
			s:Point('BOTTOMLEFT', _G.ChatFrame1, 'TOPLEFT', 0, 30)
		end

		for index, menu in next, { _G.ChatMenu, _G.EmoteMenu, _G.LanguageMenu, _G.VoiceMacroMenu } do
			menu:StripTextures()

			if index == 1 then
				menu:HookScript('OnShow', chatMenuBackdrop)
			else
				menu:HookScript('OnShow', menuBackdrop)
			end

			local name = menu:GetName()
			for i = 1, menu:GetNumChildren() do
				local child = select(i, menu:GetChildren())
				if child:GetName() and child:GetName():find(name..'Button') then
					S:HandleButtonHighlight(child, unpack(E.media.rgbvaluecolor))
				end
			end
		end
	end

	local GhostFrame = _G.GhostFrame
	if GhostFrame then
		GhostFrame:StripTextures()
		GhostFrame:SetTemplate('Transparent')
		GhostFrame:StyleButton()

		local icon = _G.GhostFrameContentsFrameIcon
		if icon then
			icon:SetTexCoords()

			local iconBackdrop = CreateFrame('Frame', nil, GhostFrame)
			iconBackdrop:OffsetFrameLevel(-1)
			iconBackdrop:SetTemplate()
			iconBackdrop:SetOutside(icon)
		end
	end

	if E.locale == 'ruRU' then
		local DeclensionFrame = _G.DeclensionFrame
		DeclensionFrame:SetTemplate('Transparent')

		S:HandleNextPrevButton(_G.DeclensionFrameSetPrev, 'left')
		S:HandleNextPrevButton(_G.DeclensionFrameSetNext, 'right')
		S:HandleButton(_G.DeclensionFrameOkayButton)
		S:HandleButton(_G.DeclensionFrameCancelButton)

		_G.DeclensionFrameSet:Point('BOTTOM', 0, 40)
		_G.DeclensionFrameOkayButton:Point('RIGHT', DeclensionFrame, 'BOTTOM', -3, 19)
		_G.DeclensionFrameCancelButton:Point('LEFT', DeclensionFrame, 'BOTTOM', 3, 19)

		hooksecurefunc('DeclensionFrame_Update', function()
			for i = 1, _G.RUSSIAN_DECLENSION_PATTERNS do
				_G['DeclensionFrameDeclension'..i..'Edit']:SetTemplate('Default')
			end
		end)
	end
end)

S:AddCallback('Skin_TimerTracker', function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.misc then return end

	local function SkinTimerBar(timer)
		local bar = timer and timer.bar
		if not bar or bar.isSkinned then return end

		bar:StripTextures()
		bar:SetStatusBarTexture(E.media.normTex)
		bar:SetStatusBarColor(0.8, 0.1, 0.1)
		bar:CreateBackdrop('Transparent')
		E:RegisterStatusBar(bar)

		if bar.timeText then
			bar.timeText:FontTemplate()
		end

		bar.isSkinned = true
	end

	local function SkinAllTimers()
		local tracker = _G.TimerTracker
		if tracker and tracker.timerList then
			for _, timer in next, tracker.timerList do
				SkinTimerBar(timer)
			end
		end
	end

	SkinAllTimers()

	pcall(hooksecurefunc, 'TimerTracker_OnEvent', function(self)
		if self and self.timerList then
			for _, timer in next, self.timerList do
				SkinTimerBar(timer)
			end
		end
	end)

	pcall(hooksecurefunc, 'StartTimer_OnShow', SkinAllTimers)

	pcall(function()
		local tracker = _G.TimerTracker
		if tracker then
			tracker:HookScript('OnEvent', SkinAllTimers)
		end
	end)

	local function SkinReadyButton()
		local ready = _G.TimerTracker_ReadyStatusButton
		if not ready or ready.isSkinned then return end

		if ready.Background then ready.Background:Kill() end
		if ready.Glow then ready.Glow:Kill() end
		ready:SetTemplate('Transparent')

		if ready.HighlightTexture then
			ready.HighlightTexture:SetTexture(E.media.blankTex)
			ready.HighlightTexture:SetVertexColor(1, 1, 1, 0.15)
			ready.HighlightTexture:SetInside()
		end

		if ready.Selection then
			ready.Selection:SetTexture(E.media.blankTex)
			ready.Selection:SetVertexColor(0, 1, 0)
			ready.Selection:SetInside()
		end

		if ready.ReadyText then ready.ReadyText:FontTemplate(nil, 20, 'OUTLINE') end
		if ready.ReadyTextDescription then ready.ReadyTextDescription:FontTemplate() end

		ready.isSkinned = true
	end

	SkinReadyButton()

	pcall(function()
		local ready = _G.TimerTracker_ReadyStatusButton
		if ready then
			ready:HookScript('OnShow', SkinReadyButton)
		end
	end)
end)

S:AddCallback("Skin_ChooseItem", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.chooseitem then return end

	local ChooseItemFrame = _G.ChooseItemFrame
	if not ChooseItemFrame then return end

	local function SkinOption(opt)
		if opt.isSkinned then return end

		if opt.ArtBackground then opt.ArtBackground:Kill() end

		if opt.Header then
			if opt.Header.Background then opt.Header.Background:Kill() end
			if opt.Header.Text then
				opt.Header.Text:SetTextColor(1, 0.82, 0)
				opt.Header.Text:ClearAllPoints()
				if opt.RoleBackground then
					opt.Header.Text:Point("BOTTOM", opt.RoleBackground, "TOP", 0, 5)
				end
			end
		end

		opt:CreateBackdrop("Transparent")
		opt.backdrop:Point("TOPLEFT", 5, -5)
		opt.backdrop:Point("BOTTOMRIGHT", -5, 5)

		S:HandleSirusButton(opt.OptionButton)

		if opt.Item then
			if opt.Item.Icon then
				S:HandleSirusIconButton(opt.Item, opt.Item.Icon)
			end
			if opt.Item.IconBorder then opt.Item.IconBorder:Kill() end
			if opt.Item.glow then opt.Item.glow:Kill() end
		end

		S:ApplyElvUIFont(opt)

		opt.isSkinned = true
	end

	local function SkinFrame()
		if ChooseItemFrame.isSkinned then return end

		ChooseItemFrame:StripTextures()
		ChooseItemFrame:CreateBackdrop("Transparent")
		ChooseItemFrame.backdrop:Point("TOPLEFT", 15, -8)
		ChooseItemFrame.backdrop:Point("BOTTOMRIGHT", -15, 15)

		S:HandleSirusCloseButton(ChooseItemFrame.CloseButton)
		S:ApplyElvUIFont(ChooseItemFrame)

		for _, opt in ipairs(ChooseItemFrame.itemOptions) do
			SkinOption(opt)
		end

		ChooseItemFrame.isSkinned = true
	end

	ChooseItemFrame:HookScript("OnShow", SkinFrame)

	if ChooseItemFrame.Update then
		hooksecurefunc(ChooseItemFrame, "Update", function(self)
			for _, opt in ipairs(self.itemOptions) do
				SkinOption(opt)
			end
		end)
	elseif _G.ChooseItemFrameMixin and _G.ChooseItemFrameMixin.Update then
		hooksecurefunc(_G.ChooseItemFrameMixin, "Update", function(self)
			for _, opt in ipairs(self.itemOptions) do
				SkinOption(opt)
			end
		end)
	end
end)

S:AddCallback("Skin_ItemBrowser", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.itembrowser then return end

	local ItemBrowser = _G.ItemBrowser
	if not ItemBrowser then return end

	S:HandleSirusFrame(ItemBrowser)

	if ItemBrowser.inset then
		ItemBrowser.inset:StripTextures()
		if ItemBrowser.inset.NineSlice then ItemBrowser.inset.NineSlice:Hide() end
	end

	if ItemBrowser.SearchBox then
		S:HandleEditBox(ItemBrowser.SearchBox)
		if ItemBrowser.SearchBox.clearButton then
			S:HandleCloseButton(ItemBrowser.SearchBox.clearButton)
		end
	end

	if ItemBrowser.SearchProgressBar then
		ItemBrowser.SearchProgressBar:StripTextures()
		ItemBrowser.SearchProgressBar:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(ItemBrowser.SearchProgressBar)
	end

	local Scroll = ItemBrowser.Scroll
	if Scroll then
		if Scroll.Background then Scroll.Background:SetAlpha(0) end
		if Scroll.ScrollBar then
			S:HandleSirusScrollBar(Scroll.ScrollBar)
		end
	end

	local function SkinHeader(header)
		if not header or header.isSkinned then return end

		header:StripTextures()
		header:SetTemplate("Transparent")

		if header.ButtonText then
			header.ButtonText:SetTextColor(1, 0.82, 0)
		end

		header.isSkinned = true
	end

	local function SkinRow(row)
		if not row or row.isSkinned then return end

		row:StripTextures()
		row:SetTemplate("Default", true)
		row:StyleButton(nil, true)

		if row.cells then
			for _, cell in ipairs(row.cells) do
				if cell.Border then
					cell.Border:SetTexture()
					cell.Border:Hide()
				end
				if cell.Icon then
					cell.Icon:SetDrawLayer("BORDER")
					cell.Icon:SetTexCoords()
					cell.Icon:SetSize(34, 34)
					cell.Icon:CreateBackdrop("Default")
					if cell.Icon.backdrop then
						cell.Icon.backdrop:SetOutside(cell.Icon)
					end
				end
			end
		end

		row.isSkinned = true
	end

	local function SkinList()
		if ItemBrowser.HeaderHolder then
			for i = 1, ItemBrowser.HeaderHolder:GetNumChildren() do
				SkinHeader(select(i, ItemBrowser.HeaderHolder:GetChildren()))
			end
		end

		if Scroll and Scroll.buttons then
			for _, row in ipairs(Scroll.buttons) do
				SkinRow(row)
			end
		end
	end

	if ItemBrowser.UpdateResultList then
		hooksecurefunc(ItemBrowser, "UpdateResultList", SkinList)
	end
	SkinList()

	S:HandleSirusTabs("ItemBrowserTab", 4)

	S:ApplyElvUIFont(ItemBrowser)
	ItemBrowser:HookScript("OnShow", function(self)
		S:ApplyElvUIFont(self)
	end)
end)