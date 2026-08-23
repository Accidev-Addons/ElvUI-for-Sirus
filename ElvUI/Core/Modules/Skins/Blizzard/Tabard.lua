local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local next = next

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.tabard then return end

	local TabardFrame = _G.TabardFrame

	S:HandleSirusFrame(TabardFrame)

	S:HandleButton(TabardFrameAcceptButton)
	S:HandleButton(TabardFrameCancelButton)

	S:HandleRotateButton(TabardCharacterModelRotateLeftButton)
	S:HandleRotateButton(TabardCharacterModelRotateRightButton)

	TabardFrameCostFrame:StripTextures()
	TabardFrameCustomizationFrame:StripTextures()
	TabardFrameMoneyInset:StripTextures()
	TabardFrameMoneyBg:StripTextures()

	TabardModel:SetTemplate()

	for _, frame in next, {
		TabardFrameEmblemTopRight,
		TabardFrameEmblemBottomRight,
		TabardFrameEmblemTopLeft,
		TabardFrameEmblemBottomLeft,
	} do
		frame:SetParent(TabardModel)
		frame.Show = nil
		frame:Show()
	end

	for i = 1, 5 do
		local button = _G["TabardFrameCustomization"..i]
		button:StripTextures()

		S:HandleNextPrevButton(_G["TabardFrameCustomization"..i.."LeftButton"])
		S:HandleNextPrevButton(_G["TabardFrameCustomization"..i.."RightButton"])
	end
end

S:AddCallback("Skin_Tabard", LoadSkin)
