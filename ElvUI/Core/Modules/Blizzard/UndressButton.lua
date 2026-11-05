local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')
local S = E:GetModule('Skins')

local _G = _G
local CreateFrame = CreateFrame
local PlaySound = PlaySound

local function UndressButton_OnClick()
	_G.DressUpModel:Undress()
	PlaySound('gsTitleOptionOK')
end

function BL:UndressButtonToggle()
	local button = BL.UndressButton
	local enabled = E.db.general.undressButton

	if not button then
		if not enabled then return end

		button = CreateFrame('Button', 'DressUpFrame_UndressButton', _G.DressUpFrame, 'UIPanelButtonTemplate')
		button:Size(80, 22)
		button:SetText(L["Undress"])
		button:SetScript('OnClick', UndressButton_OnClick)

		if E.private.skins.blizzard.enable and E.private.skins.blizzard.dressingroom then
			S:HandleButton(button)
			button:Point('RIGHT', _G.DressUpFrameResetButton, 'LEFT', -3, 0)
		else
			button:Point('RIGHT', _G.DressUpFrameResetButton, 'LEFT', 2, 0)
		end

		BL.UndressButton = button
	end

	button:SetShown(enabled)
end
