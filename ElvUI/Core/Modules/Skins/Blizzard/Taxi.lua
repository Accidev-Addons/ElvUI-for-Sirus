local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

--Lua functions
--WoW API / Variables

S:AddCallback("Skin_Taxi", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.taxi then return end

	TaxiFrame:StripTextures()

	TaxiFrame:CreateBackdrop("Transparent")
	TaxiFrame.backdrop:Point("TOPLEFT", 11, -12)
	TaxiFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetUIPanelWindowInfo(TaxiFrame, "width")
	S:SetBackdropHitRect(TaxiFrame)

	TaxiFramePortrait:Kill()

	S:HandleCloseButton(TaxiFrameCloseButton, TaxiFrame.backdrop)

	TaxiRouteMap:CreateBackdrop("Default")
end)