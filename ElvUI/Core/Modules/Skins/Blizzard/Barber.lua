local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local hooksecurefunc = hooksecurefunc

local function SkinOption(frame)
	if not frame.IsSkinned then
		if frame.Background then frame.Background:SetAlpha(0) end
		if frame.Highlight then frame.Highlight:SetAlpha(0) end

		S:HandleNextPrevButton(frame.DecrementButton)
		S:HandleNextPrevButton(frame.IncrementButton)

		if frame.Label then
			frame.Label:FontTemplate()
		end

		frame.IsSkinned = true
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.barber then return end

	local BarberFrame = _G.CustomBarberShopFrame
	if not BarberFrame then return end

	S:HandleButton(BarberFrame.AcceptButton, true, nil, nil, true, nil, nil, nil, true)
	S:HandleButton(BarberFrame.CancelButton, true, nil, nil, true, nil, nil, nil, true)
	S:HandleButton(BarberFrame.ResetButton, true, nil, nil, true, nil, nil, nil, true)

	local CharFrame = _G.CharCustomizeFrame
	if CharFrame then
		if CharFrame.RandomizeAppearanceButton then
			S:HandleButton(CharFrame.RandomizeAppearanceButton, nil, nil, nil, true)
		end

		if CharFrame.SmallButtons then
			for _, button in next, {
				CharFrame.SmallButtons.ResetCameraButton,
				CharFrame.SmallButtons.ZoomOutButton,
				CharFrame.SmallButtons.ZoomInButton,
				CharFrame.SmallButtons.RotateLeftButton,
				CharFrame.SmallButtons.RotateRightButton,
			} do
				if button then
					S:HandleButton(button, nil, nil, nil, true)
				end
			end
		end

		hooksecurefunc(CharCustomizeOptionSelectionFrameMixin, "SetupOption", SkinOption)
	end
end

S:AddCallbackForAddon("Blizzard_BarbershopUI", "Skin_Blizzard_BarbershopUI", LoadSkin)
