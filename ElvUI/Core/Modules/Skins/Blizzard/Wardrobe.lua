local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack, ipairs = unpack, ipairs
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local GetInventoryItemID = GetInventoryItemID

local LCG = E.Libs.CustomGlow

local function ShowPendingGlow(button)
	LCG.PixelGlow_Start(button, nil, 8, 0.2, 8, 1, 0, 0, false, "Wardrobe")
end

local function HidePendingGlow(button)
	LCG.PixelGlow_Stop(button, "Wardrobe")
end

local function UpdateSlotBorder(button)
	if button.SelectedTexture:IsShown() then
		button:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	elseif button.StatusBorder:IsShown() then
		button:SetBackdropBorderColor(1, .5, 1)
	else
		button:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

local function SkinTransmogSlotButton(button)
	if not button or button.isSkinned then return end
	button.isSkinned = true

	button.Border:Kill()
	button.StatusBorder:SetAlpha(0)
	button.SelectedTexture:SetAlpha(0)

	button:SetTemplate("Default")
	button:StyleButton()

	button.Icon:SetTexCoords()
	button.Icon:SetInside()
	button.NoItemTexture:SetAllPoints(button.Icon)

	button.PendingFrame.Glow:Kill()
	button.PendingFrame.Ants:Kill()
	button.PendingFrame:HookScript("OnShow", function() ShowPendingGlow(button) end)
	button.PendingFrame:HookScript("OnHide", function() HidePendingGlow(button) end)

	hooksecurefunc(button, "SetSelected", UpdateSlotBorder)
	hooksecurefunc(button, "Update", UpdateSlotBorder)
	UpdateSlotBorder(button)
end

local function RefreshEmptySlots(_, _, itemID)
	for _, button in ipairs(_G.WardrobeTransmogFrame.SlotButtons) do
		if button:IsShown() and not button.Icon:GetTexture() and GetInventoryItemID("player", button.slotID) == itemID then
			button:Update()
		end
	end
end

local function WatchItemData(transmogFrame)
	local watcher = CreateFrame("Frame")
	watcher:SetScript("OnEvent", RefreshEmptySlots)

	transmogFrame:HookScript("OnShow", function() watcher:RegisterEvent("ITEM_DATA_LOAD_RESULT") end)
	transmogFrame:HookScript("OnHide", function() watcher:UnregisterEvent("ITEM_DATA_LOAD_RESULT") end)

	if transmogFrame:IsShown() then
		watcher:RegisterEvent("ITEM_DATA_LOAD_RESULT")
	end
end

local function SkinOutfitButton(button)
	if button.isSkinned then return end
	button.isSkinned = true

	button.Highlight:SetTexture(E.Media.Textures.Highlight)
	button.Highlight:SetVertexColor(1, 1, 1, .35)
	button.Selection:SetTexture(E.Media.Textures.Highlight)
	button.Selection:SetVertexColor(1, .8, .1, .35)
end

local function SkinOutfitFrame()
	local outfitFrame = _G.WardrobeOutfitFrame
	if not outfitFrame then return end

	outfitFrame:StripTextures()
	outfitFrame:SetTemplate("Transparent")

	hooksecurefunc(outfitFrame, "Update", function(self)
		for _, button in ipairs(self.Buttons) do
			SkinOutfitButton(button)
		end
	end)

	hooksecurefunc(outfitFrame, "Toggle", function(self)
		if self.dropDown and self.dropDown.backdrop then
			self:Point("TOPLEFT", self.dropDown.backdrop, "BOTTOMLEFT", 0, -2)
		end
	end)
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

local function SkinHelpButton()
	local helpButton = _G.WardrobeCollectionFrame and _G.WardrobeCollectionFrame.HelpButton
	if not helpButton then return end

	S:HandleButton(helpButton)

	hooksecurefunc(_G.WardrobeFrame, "SetShowHelpFrame", function(_, show)
		helpButton.Icon:SetRotation(show and S.ArrowRotation.left or S.ArrowRotation.right)
	end)
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

		local dropDown = transmogFrame.OutfitDropDown
		if dropDown then
			S:HandleDropDownBox(dropDown, 188)
			_G.WardrobeOutfitDropDownText:Point("LEFT", dropDown.backdrop, "LEFT", 6, 0)

			local button = _G.WardrobeOutfitDropDownButton
			button.SetPoint = nil
			button:ClearAllPoints()
			button:Point("RIGHT", dropDown, "RIGHT", -10, -2)
			button.SetPoint = E.noop

			if dropDown.SaveButton then
				S:HandleButton(dropDown.SaveButton, true)
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

		for _, button in ipairs(transmogFrame.SlotButtons or {}) do
			SkinTransmogSlotButton(button)
		end

		WatchItemData(transmogFrame)

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

	SkinHelpButton()
	SkinOutfitFrame()
	SkinOutfitEditFrame()
end

S:AddCallback("Skin_Wardrobe", LoadSkin)
