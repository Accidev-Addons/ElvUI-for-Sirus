local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.macro then return end

	S:HandleSirusFrame(MacroFrame)

	S:HandleSirusScrollFrame(MacroButtonScrollFrame, true)
	S:HandleSirusScrollFrame(MacroFrameScrollFrame)
	S:HandleSirusScrollFrame(MacroPopupScrollFrame)

	local buttons = {
		"MacroDeleteButton", "MacroNewButton", "MacroExitButton", "MacroEditButton",
		"MacroPopupOkayButton", "MacroPopupCancelButton"
	}
	for i = 1, #buttons do
		S:HandleSirusButton(_G[buttons[i]], true)
	end

	for i = 1, 2 do
		local tab = _G["MacroFrameTab"..i]
		if tab then
			S:HandleSirusTab(tab, i > 1 and _G["MacroFrameTab"..(i - 1)])
			tab:Height(22)
		end
	end

	MacroFrameTextBackground:StripTextures()
	MacroFrameTextBackground:CreateBackdrop("Default")
	MacroFrameTextBackground.backdrop:Point("TOPLEFT", 6, -3)
	MacroFrameTextBackground.backdrop:Point("BOTTOMRIGHT", -2, 3)

	MacroEditButton:ClearAllPoints()
	MacroEditButton:Point("BOTTOMLEFT", MacroFrameSelectedMacroButton, "BOTTOMRIGHT", 10, 0)

	MacroFrameSelectedMacroButton:StripTextures()
	MacroFrameSelectedMacroButton:StyleButton(nil, true)
	MacroFrameSelectedMacroButton:GetNormalTexture():SetTexture(nil)
	MacroFrameSelectedMacroButton:SetTemplate("Default")
	MacroFrameSelectedMacroButtonIcon:SetTexCoords()
	MacroFrameSelectedMacroButtonIcon:SetInside()

	for i = 1, MAX_ACCOUNT_MACROS do
		local button = _G["MacroButton"..i]
		local buttonIcon = _G["MacroButton"..i.."Icon"]

		if button then
			button:StripTextures()
			button:StyleButton(nil, true)
			button:SetTemplate("Default", true)
		end

		if buttonIcon then
			buttonIcon:SetTexCoords()
			buttonIcon:SetInside()
		end
	end

	S:HandleIconSelectionFrame(MacroPopupFrame, NUM_MACRO_ICONS_SHOWN, "MacroPopupButton", "MacroPopup")
	MacroPopupFrame.BorderBox:StripTextures()
	S:HandleEditBox(MacroPopupSearchBox)
end

S:AddCallback("Skin_Macro", LoadSkin)
