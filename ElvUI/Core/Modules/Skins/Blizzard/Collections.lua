local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local ipairs = ipairs
local hooksecurefunc = hooksecurefunc

local function RestoreSummonIcon(button, iconKey, spellID, fallback)
	if not button then return end

	local texture = button[iconKey]
	if not texture or texture:GetTexture() then return end

	local spellIcon = spellID and select(3, GetSpellInfo(spellID))
	texture:SetTexture(spellIcon or fallback)
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.collections then return end

	S:HandleSirusTabs("CollectionsJournalTab", 5)
	S:HandlePortraitFrame(CollectionsJournal)

	S:HandleSirusNavBar(MountJournal.navBar)

	MountJournal.navBar:ClearAllPoints()
	MountJournal.navBar:SetPoint("TOPLEFT", 6, -22)

	S:HandleSirusSearchRow(MountJournal.searchBox, MountJournal.FilterButton)

	S:HandleSirusScrollFrame(MountJournal.ListScrollFrame)

	for _, button in ipairs(MountJournal.ListScrollFrame.buttons) do
		button.icon:Size(40)
		button.icon:SetDrawLayer("BORDER")
		S:HandleSirusIconButton(button, button.icon, button.iconBorder)

		local highlight = button:GetHighlightTexture()
		button:SetHighlightTexture(E.Media.Textures.Highlight)
		highlight:SetTexCoord(0, 1, 0, 1)
		highlight:SetVertexColor(1, 1, 1, .35)
		highlight:SetAllPoints()

		button.background:SetTexture()

		button.selectedTexture:SetTexture(E.Media.Textures.Highlight)
		button.selectedTexture:SetTexCoord(0, 1, 0, 1)
		button.selectedTexture:SetVertexColor(1, .8, .1, .35)
		button.selectedTexture:SetAllPoints()

		if button.favorite then button.favorite:SetParent(button.backdrop) end
	end

	for _, button in ipairs(MountJournal.CategoryScrollFrame.buttons) do
		button:SetHighlightTexture(E.Media.Textures.Highlight)
		button:GetHighlightTexture():SetVertexColor(1, 1, 1)
		button:GetHighlightTexture().SetAlpha = E.noop

		button.Background:SetTexture()

		if button.Icon then
			button.Icon:SetDrawLayer("BORDER")
			button.Icon:SetSize(41, 41)
			S:HandleSirusIconButton(button, button.Icon)
		end

		if button.categoryName then
			button.categoryName:Hide()
		end
		if not button.categoryText then
			button.categoryText = button:CreateFontString(nil, "BORDER")
			button.categoryText:SetPoint("LEFT", 62, 0)
			button.categoryText:SetJustifyH("LEFT")
			button.categoryText:SetFont(E.LSM:Fetch("font", E.db.general.font), E.db.general.fontSize)
			button.categoryText:SetTextColor(1, 1, 1)
		end
	end

	hooksecurefunc("MountJournal_CategoryDisplayButton", function(button, element)
		if not element then return end

		local highlight = button:GetHighlightTexture()
		highlight:SetTexCoord(0, 1, 0, 1)
		highlight:SetAllPoints()

		if button.Icon then
			button.Icon:SetTexture(element.icon)
			button.Icon:Show()
		end

		if button.categoryText then
			button.categoryText:SetText(element.text)
			button.categoryText:Show()
		end
	end)

	S:HandleSirusScrollFrame(MountJournal.CategoryScrollFrame)

	MountJournal.LeftInset:StripTextures()

	MountJournal.RightTopInset:StripTextures()

	MountJournal.RightBottomInset:StripTextures()

	MountJournal.MountCount:StripTextures()

	MountJournal.MountDisplay:StripTextures()

	MountJournal.MountDisplay.ShadowOverlay:Hide()

	S:HandleRotateButton(MountDisplayModelSceneRotateLeftButton)
	S:HandleRotateButton(MountDisplayModelSceneRotateRightButton)
	S:HandleCheckBox(MountDisplayModelSceneTogglePlayer)

	S:HandleItemButton(MountJournal.SummonRandomFavoriteButton)
	RestoreSummonIcon(MountJournal.SummonRandomFavoriteButton, "texture", 305495, "Interface\\Icons\\ACHIEVEMENT_GUILDPERK_MOUNTUP")

	S:HandleIcon(MountJournal.MountDisplay.ModelScene.InfoButton.Icon)
	S:HandleButton(MountJournal.MountDisplay.ModelScene.buyFrame.buyButton)

	S:HandleButton(MountJournal.MountButton, true)

	S:HandleButton(MountDisplayModelSceneEJFrameOpenEJButton)
	S:HandleButton(PetJournalPetDisplayModelSceneEJFrameOpenEJButton)

	S:HandleModelRotateButton(PetJournalPetDisplayModelSceneRotateLeftButton, 0.015625, 0.265625)
	S:HandleModelRotateButton(PetJournalPetDisplayModelSceneRotateRightButton, 0.578125, 0.828125)
	S:HandleButton(PetJournalSummonButton, true)

	S:HandleSirusScrollBar(PetJournalListScrollFrameScrollBar)

	S:HandleSirusSearchRow(PetJournalSearchBox, PetJournalFilterButton)

	for _, button in ipairs(PetJournal.ListScrollFrame.buttons) do
		local highlight = button:GetHighlightTexture()
		button:SetHighlightTexture(E.Media.Textures.Highlight)
		highlight:SetTexCoord(0, 1, 0, 1)
		highlight:SetVertexColor(1, 1, 1, .35)
		highlight:SetAllPoints()

		button.Background:SetTexture()

		button.Icon:SetDrawLayer("BORDER")
		S:HandleSirusIconButton(button, button.Icon, button.IconBorder)

		if button.DragButton and button.DragButton.Favorite then button.DragButton.Favorite:SetParent(button.backdrop) end
	end

	PetJournal.LeftInset:StripTextures()
	PetJournal.RightInset:StripTextures()
	PetJournal.PetDisplay:StripTextures()
	PetJournal.PetDisplay.ShadowOverlay:Hide()

	PetJournal.PetCount:StripTextures()

	S:HandleIcon(PetJournal.PetDisplay.InfoButton.Icon)
	S:HandleItemButton(_G.PetJournal.SummonRandomFavoritePetButton, true)
	RestoreSummonIcon(_G.PetJournal.SummonRandomFavoritePetButton, "IconTexture", 317619, "Interface\\Icons\\INV_Pet_BabyMoose")

		local WardrobeCollectionFrame = _G.WardrobeCollectionFrame
	if WardrobeCollectionFrame then
		if WardrobeCollectionFrame.ItemsTab then S:HandleSirusTab(WardrobeCollectionFrame.ItemsTab) end
		S:HandleSirusSearchRow(WardrobeCollectionFrame.SearchBox, WardrobeCollectionFrame.FilterButton)

		S:HandleDropDownBox(WardrobeCollectionFrame.FilterDropDown)

		local progressBar = WardrobeCollectionFrame.ProgressBar
		if progressBar then
			S:HandleSirusStatusBar(progressBar)
		end

		local itemsFrame = WardrobeCollectionFrame.ItemsCollectionFrame
		if itemsFrame then
			itemsFrame:StripTextures()
			itemsFrame:SetTemplate("Transparent")

			if itemsFrame.WeaponDropDown then
				S:HandleSirusDropDown(itemsFrame.WeaponDropDown, 190)
			end

			local paging = itemsFrame.PagingFrame
			if paging then
				S:HandleNextPrevButton(paging.PrevPageButton)
				S:HandleNextPrevButton(paging.NextPageButton)
			end

			for row = 1, 3 do
				for col = 1, 6 do
					local model = itemsFrame["ModelR"..row.."C"..col]
					if model and not model.isSkinned then
						if model.Overlay and model.Overlay.Border then model.Overlay.Border:SetAlpha(0) end
						if model.Overlay and model.Overlay.Highlight then model.Overlay.Highlight:SetTexture(1, 1, 1, 0.25) end

						model:CreateBackdrop("Default")
						model.backdrop:SetOutside(model)

						model.isSkinned = true
					end
				end
			end

			if itemsFrame.SlotsFrame and itemsFrame.SlotsFrame.Buttons then
				for _, button in ipairs(itemsFrame.SlotsFrame.Buttons) do
					if button and not button.isSkinned then
						button:CreateBackdrop("Default")
						button.backdrop:SetOutside(button)

						local normal = button:GetNormalTexture()
						if normal then
							local slotTexture = button.slot and select(2, GetInventorySlotInfo(button.slot))
							normal:SetTexture((button.isSmallButton and ENCHANT_EMPTY_SLOT_FILEDATAID) or slotTexture)
							normal:SetTexCoords()
							normal:SetDrawLayer("BORDER")
							normal:SetInside(button.backdrop)
						end

						local highlight = button:GetHighlightTexture()
						if highlight then
							button:SetHighlightTexture(E.Media.Textures.Highlight)
							highlight:SetTexCoord(0, 1, 0, 1)
							highlight:SetVertexColor(1, 1, 1, .35)
							highlight:SetInside(button.backdrop)
						end

						local selected = button.SelectedTexture
						if selected then
							selected:SetTexture()

							local function updateBorder()
								if selected:IsShown() then
									button.backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
								else
									button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
								end
							end

							hooksecurefunc(selected, "Show", updateBorder)
							hooksecurefunc(selected, "Hide", updateBorder)
							hooksecurefunc(selected, "SetShown", updateBorder)
							updateBorder()
						end

						button.isSkinned = true
					end
				end
			end
		end
	end
end

S:AddCallback("Skin_Collections", LoadSkin)

local function LoadToyBoxSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.toyCollection then return end

	S:HandleSirusTab(CollectionsJournalTab4)
	ToyBoxIconsFrameOverlayFrame:StripTextures()
	ToyBoxIconsFrame:StripTextures()
	ToyBoxIconsFrame:CreateBackdrop("Default")
	S:HandleButton(ToyBoxFilterButton)
	S:HandleEditBox(ToyBoxSearchBox)
	S:HandleNextPrevButton(ToyBoxPagingFrameNextPageButton, "right")
	S:HandleNextPrevButton(ToyBoxPagingFramePrevPageButton, "left")
	S:HandleStatusBar(ToyBoxProgressBar)

	ToyBoxIconsFrame:HookScript("OnShow", function(self)
		for i = 1, 18 do
			local button = _G["ToyBoxIconsFrameSpellButton" .. i]
			if button and button.Cooldown then
				E:RegisterCooldown(button.Cooldown)
			end
		end
	end)
end

S:AddCallback("Skin_ToyCollection", LoadToyBoxSkin)