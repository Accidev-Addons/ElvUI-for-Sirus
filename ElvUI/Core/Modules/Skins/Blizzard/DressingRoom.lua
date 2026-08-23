local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

S:AddCallback("Skin_DressingRoom", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.dressingroom then return end

	S:HandleSirusFrame(DressUpFrame, true)

	if DressUpFrameMaximizeMinimizeFrame then
		S:HandleMaxMinFrame(DressUpFrameMaximizeMinimizeFrame)
	end

	for _, name in next, { "DressUpBackgroundTopLeft", "DressUpBackgroundTopRight", "DressUpBackgroundBotLeft", "DressUpBackgroundBotRight" } do
		local texture = _G[name]
		if texture then
			texture:SetDesaturated(true)
		end
	end

	if DressUpModelRotateLeftButton then
		S:HandleRotateButton(DressUpModelRotateLeftButton)
	end
	if DressUpModelRotateRightButton then
		S:HandleRotateButton(DressUpModelRotateRightButton)
	end

	S:HandleButton(DressUpFrameCancelButton)
	S:HandleButton(DressUpFrameResetButton)

	DressUpModel:CreateBackdrop("Default")
end)
