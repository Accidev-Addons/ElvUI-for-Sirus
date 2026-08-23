local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local hooksecurefunc = hooksecurefunc

local function SkinTransmogSlotButton(button)
	if not button or button.isSkinned then return end
	button.isSkinned = true

	button:StripTextures()
	button:SetTemplate("Default")
	button:StyleButton()

	if button.Icon then
		button.Icon:SetTexCoords()
		button.Icon:SetInside()
	end
end

local function SkinOutfitEditFrame()
	local editFrame = _G.WardrobeOutfitEditFrame
	if not editFrame then return end

	editFrame:StripTextures()
	editFrame:SetTemplate("Transparent")

	if editFrame.Title then
		editFrame.Title:FontTemplate(nil, 13)
		editFrame.Title:SetTextColor(1, 1, 1)
	end

	S:HandleEditBox(editFrame.EditBox)
	S:HandleButton(editFrame.AcceptButton, true)
	S:HandleButton(editFrame.CancelButton, true)
	S:HandleButton(editFrame.DeleteButton, true)
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.wardrobe then return end

	local frame = _G.WardrobeFrame
	if not frame then return end

	S:HandleSirusFrame(frame)

	if frame.TitleText then
		frame.TitleText:FontTemplate(nil, 16)
		frame.TitleText:SetTextColor(1, 1, 1)
	end

	local transmogFrame = _G.WardrobeTransmogFrame
	if transmogFrame then
		transmogFrame:StripTextures()
		transmogFrame:SetTemplate("Transparent")

		if transmogFrame.OutfitDropDown then
			S:HandleDropDownBox(transmogFrame.OutfitDropDown, 188)

			if transmogFrame.OutfitDropDown.SaveButton then
				S:HandleButton(transmogFrame.OutfitDropDown.SaveButton, true)
			end
		end

		if transmogFrame.ModelFrame then
			transmogFrame.ModelFrame:SetTemplate("Default")

			local clearAll = transmogFrame.ModelFrame.ClearAllPendingButton
			if clearAll then
				S:HandleButton(clearAll, true)

				if clearAll.Icon then
					clearAll.Icon:SetAtlas("transmog-icon-revert-small", true)
					clearAll.Icon:SetInside()
				end
			end
		end

		for _, key in next, {
			"HeadButton", "ShoulderButton", "BackButton", "ChestButton", "ShirtButton",
			"TabardButton", "WristButton", "HandsButton", "WaistButton", "LegsButton",
			"FeetButton", "MainHandButton", "SecondaryHandButton", "RangedButton",
			"MainHandEnchantButton", "SecondaryHandEnchantButton",
		} do
			SkinTransmogSlotButton(transmogFrame[key])
		end

		if transmogFrame.ApplyButton then
			S:HandleButton(transmogFrame.ApplyButton, true)
		end
	end

	local helpFrame = _G.WardrobeFrameHelpFrame
	if helpFrame then
		helpFrame:StripTextures()
		helpFrame:SetTemplate("Transparent")

		if helpFrame.KnowledgeBaseButton then
			S:HandleButton(helpFrame.KnowledgeBaseButton, true)
		end
	end

	SkinOutfitEditFrame()

	if TransmogSlotButtonMixin and TransmogSlotButtonMixin.SetSelected then
		hooksecurefunc(TransmogSlotButtonMixin, "SetSelected", function(self, selected)
			if selected then
				self:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
			else
				self:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		end)
	end
end

S:AddCallback("Skin_Wardrobe", LoadSkin)
