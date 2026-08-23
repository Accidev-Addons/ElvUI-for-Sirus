local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local hooksecurefunc = hooksecurefunc

local function SkinRouletteRewardButton(button)
	if not button or button.isSkinned then return end
	button.isSkinned = true

	button.Background:SetDrawLayer("BORDER")
	button.Background:SetInside()
	button.Border:SetAlpha(0)
	button:SetTemplate()

	local r, g, b = button.Border:GetVertexColor()
	button:SetBackdropBorderColor(r, g, b)

	if button.OverlayFrame and button.OverlayFrame.ChildFrame and button.OverlayFrame.ChildFrame.ItemName then
		button.OverlayFrame.ChildFrame.ItemName:FontTemplate(nil, 12, "NONE")
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.roulette then return end

	local frame = _G.Custom_RouletteFrame
	if not frame then return end

	frame:SetParent(UIParent)
	frame:SetScale(0.75)
	frame:SetFrameStrata("HIGH")

	local nineSliceInset = _G.Custom_RouletteFrameNineSliceInset
	if nineSliceInset then nineSliceInset:StripTextures() end

	frame:StripTextures(true)
	frame:SetTemplate("Transparent")
	frame:SetSize(804, 600)

	local closeBtn = frame.CloseButton or _G.Custom_RouletteFrameCloseButton
	if closeBtn then
		S:HandleCloseButton(closeBtn)
	end

	if frame.HeaderFrame then
		if frame.HeaderFrame.Background then frame.HeaderFrame.Background:Hide() end
		frame.HeaderFrame:SetPoint("TOP", 0, 6)
		if frame.HeaderFrame.TitleText then
			frame.HeaderFrame.TitleText:FontTemplate(nil, 18, "NONE")
		end
	end

	if frame.ToggleCurrencyFrame then
		if frame.ToggleCurrencyFrame.Background then
			frame.ToggleCurrencyFrame.Background:SetTexture(E.Media.Textures.Highlight)
			frame.ToggleCurrencyFrame.Background:SetTexCoord(1, 0, 1, 0)
			frame.ToggleCurrencyFrame.Background:SetAlpha(0.3)
		end

		local function OnEnter(button)
			button.Text:SetTextColor(1, 1, 1)
		end

		local function OnLeave(button)
			if not button.active then
				button.Text:SetTextColor(unpack(E.media.rgbvaluecolor))
			end
		end

		local function OnClick(self)
			for _, button in pairs(self:GetParent().currencyButtons) do
				if button.active then
					button.Text:SetTextColor(1, 1, 1)
				else
					button.Text:SetTextColor(unpack(E.media.rgbvaluecolor))
				end
			end
		end

		local function SkinRouletteCurrencyButton(button)
			if not button or not button.Text then return end

			button.Text:FontTemplate(nil, 14, "NONE")

			if button:GetID() == frame.selectedCurrency then
				button.Text:SetTextColor(1, 1, 1)
				button.active = true
			else
				button.Text:SetTextColor(unpack(E.media.rgbvaluecolor))
			end

			button:HookScript("OnEnter", OnEnter)
			button:HookScript("OnLeave", OnLeave)
			button:HookScript("OnClick", OnClick)

			button:SetFrameLevel(frame.ToggleCurrencyFrame:GetFrameLevel() + 3)
		end

		SkinRouletteCurrencyButton(frame.ToggleCurrencyFrame.CurrencyBonus)
		SkinRouletteCurrencyButton(frame.ToggleCurrencyFrame.CurrencyLuckCoins)

		if frame.ToggleCurrencyFrame.CurrencySelector then
			local selector = frame.ToggleCurrencyFrame.CurrencySelector

			if selector.Selector then
				selector.Selector:SetSize(200, 48)
				selector.Selector:ClearAllPoints()
				selector.Selector:SetPoint("CENTER")
				selector.Selector:SetTexture(E.Media.Textures.Highlight)
				selector.Selector:SetVertexColor(unpack(E.media.rgbvaluecolor))
				selector.Selector:SetTexCoord(1, 0, 1, 0)
				selector.Selector:SetAlpha(0.5)
			end

			selector:SetFrameLevel(frame.ToggleCurrencyFrame:GetFrameLevel() + 1)
		end
	end

	if frame.OverlayFrame then
		frame.OverlayFrame:SetPoint("CENTER", -2, 140)

		if frame.OverlayFrame.Background then frame.OverlayFrame.Background:SetAlpha(0) end

		if frame.OverlayFrame.ArtOverlay then
			frame.OverlayFrame.ArtOverlay:StripTextures()

			local lineTexture = frame.OverlayFrame.ArtOverlay:CreateTexture()
			lineTexture:Size(3, 122)
			lineTexture:SetPoint("CENTER")
			lineTexture:SetTexture(0.8, 0, 0)
		end
	end

	local skipAnimation = _G.Custom_RouletteFrameSkipAnimation
	if skipAnimation then
		S:HandleCheckBox(skipAnimation)
	end

	if frame.SpinButton then
		frame.SpinButton:StripTextures(true)
		frame.SpinButton:SetHeight(48)
		frame.SpinButton:SetPoint("CENTER", 0, 44)
		S:HandleButton(frame.SpinButton)
	end

	for i = 1, #frame.itemButtons do
		local button = frame.itemButtons[i]
		if button and button.OverlayFrame and button.OverlayFrame.ChildFrame and button.OverlayFrame.ChildFrame.ItemName then
			button.OverlayFrame.ChildFrame.ItemName:FontTemplate(nil, 12, "NONE")
		end
	end

	if frame.RewardItemsFrame then
		frame.RewardItemsFrame:SetHeight(304)

		if frame.RewardItemsFrame.TitleFrame then
			if frame.RewardItemsFrame.TitleFrame.Background then
				frame.RewardItemsFrame.TitleFrame.Background:SetTexture(E.Media.Textures.Highlight)
				frame.RewardItemsFrame.TitleFrame.Background:SetTexCoord(1, 0, 1, 0)
				frame.RewardItemsFrame.TitleFrame.Background:SetAlpha(0.3)
			end

			if frame.RewardItemsFrame.TitleFrame.Text then
				frame.RewardItemsFrame.TitleFrame.Text:FontTemplate(nil, 16, "NONE")
				frame.RewardItemsFrame.TitleFrame.Text:SetTextColor(1, 1, 1)
			end
		end
	end

	for i = 1, #frame.rewardButtons do
		SkinRouletteRewardButton(frame.rewardButtons[i])
	end

	if RouletteFrameMixin and RouletteFrameMixin.Initialize then
		hooksecurefunc(RouletteFrameMixin, "Initialize", function(self)
			for i = 1, #self.rewardButtons do
				SkinRouletteRewardButton(self.rewardButtons[i])
			end
		end)
	end
end

S:AddCallback("Skin_Roulette", LoadSkin)
