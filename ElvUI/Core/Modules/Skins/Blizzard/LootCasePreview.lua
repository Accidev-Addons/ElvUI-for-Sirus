local _G = _G
local E = unpack(_G.ElvUI)
local S = E:GetModule('Skins')

local ipairs = ipairs
local hooksecurefunc = _G.hooksecurefunc

local function SkinRows(frame)
	local buttons = frame.ScrollFrame and frame.ScrollFrame.buttons
	if not buttons then return end

	for _, button in ipairs(buttons) do
		if not button.isSkinned then
			button.Background:SetAlpha(0)

			button:CreateBackdrop('Transparent')
			button.backdrop:Point('TOPLEFT', 42, 0)
			button.backdrop:Point('BOTTOMRIGHT', 0, 0)

			S:HandleIcon(button.Icon, true)

			button.HighlightTexture:SetTexture(E.media.blankTex)
			button.HighlightTexture:SetVertexColor(1, 1, 1, 0.12)
			button.HighlightTexture:ClearAllPoints()
			button.HighlightTexture:SetAllPoints(button)

			button.isSkinned = true
		end
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.lootCasePreview then return end

	local frame = _G.LootCasePreviewFrame
	if not frame then return end

	S:HandlePortraitFrame(frame, true)

	if frame.NineSlice then frame.NineSlice:Hide() end
	if frame.portraitFrame then frame.portraitFrame:SetAlpha(0) end

	local portrait = frame.portrait or (frame.PortraitOverlay and frame.PortraitOverlay.portrait)
	if portrait then
		portrait:SetAlpha(1)
		portrait:SetTexCoords()
		portrait:Size(38)
		portrait:ClearAllPoints()
		portrait:Point('TOPLEFT', frame, 'TOPLEFT', 10, -10)
	end

	if frame.ItemName and portrait then
		frame.ItemName:ClearAllPoints()
		frame.ItemName:Point('LEFT', portrait, 'RIGHT', 8, 0)
	end

	S:HandleSirusScrollFrame(frame.ScrollFrame)

	SkinRows(frame)
	hooksecurefunc(frame, 'SetNumDisplayed', function() SkinRows(frame) end)
end

S:AddCallback('Skin_LootCasePreview', LoadSkin)
