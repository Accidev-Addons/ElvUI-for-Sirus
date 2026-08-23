local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.encounterjournal then return end

	local EncounterJournal = EncounterJournal
	S:HandlePortraitFrame(EncounterJournal)

	S:HandleEditBox(EncounterJournal.searchBox)

	EncounterJournal.searchBox.searchPreviewContainer:StripTextures()

	for i = 1, 5 do
		local button = EncounterJournal.searchBox["sbutton"..i]
		S:HandleButton(button)
		button.icon:SetTexCoord(unpack(E.TexCoords))

		if i ~= 1 then
			button:Point("TOPLEFT",  EncounterJournal.searchBox["sbutton"..i-1], "BOTTOMLEFT", 0, -E.Border)
			button:Point("TOPRIGHT", EncounterJournal.searchBox["sbutton"..i-1] , "BOTTOMRIGHT", 0, -E.Border)
		end
	end

	S:HandleButton(EncounterJournalSearchBox.showAllResults)
	EncounterJournalSearchBox.showAllResults:Point("TOP", EncounterJournal.searchBox.sbutton5, "BOTTOM", 0, -E.Border)

	EncounterJournal.searchResults:StripTextures()
	EncounterJournal.searchResults:CreateBackdrop()
	if EncounterJournalSearchResultsCloseButton then
		S:HandleCloseButton(EncounterJournalSearchResultsCloseButton)
	end
	S:HandleSirusScrollBar(EncounterJournal.searchResults.scrollFrame.scrollBar)

	S:HandleSirusNavBar(EncounterJournal.navBar)

	EncounterJournal.inset:StripTextures()

	EncounterJournal.instanceSelect:StripTextures(true)

	local function SkinTierTab(tab)
		tab:StripTextures(nil, true)
		tab.grayBox:SetAlpha(0)

		tab:SetTemplate("Default", true)

		tab:HookScript("OnEnter", S.SetModifiedBackdrop)
		tab:HookScript("OnLeave", S.SetOriginalBackdrop)

		if tab:GetFontString() then
			tab:GetFontString():FontTemplate()
		end
	end

	SkinTierTab(EncounterJournal.instanceSelect.suggestTab)
	SkinTierTab(EncounterJournal.instanceSelect.dungeonsTab)
	SkinTierTab(EncounterJournal.instanceSelect.raidsTab)
	SkinTierTab(EncounterJournal.instanceSelect.LootJournalTab)

	S:HandleDropDownBox(EncounterJournal.instanceSelect.tierDropDown)

	S:HandleSirusScrollBar(EncounterJournal.instanceSelect.scroll.ScrollBar)

	EncounterJournal.encounter.instance.loreBG:SetSize(350, 256)
	EncounterJournal.encounter.instance.loreBG:SetPoint("TOP", 0, -45)
	EncounterJournal.encounter.instance.loreBG:SetTexCoord(0.06, 0.71, 0.08, 0.582)
	EncounterJournal.encounter.instance.loreBG:CreateBackdrop()
	EncounterJournal.encounter.instance.title:SetPoint("TOP", 0, -65)
	EncounterJournal.encounter.instance.titleBG:SetPoint("TOP", EncounterJournal.encounter.instance.loreBG)

	EncounterJournal.encounter.instance.mapButton:StripTextures()
	EncounterJournal.encounter.instance.mapButton:ClearAllPoints()
	EncounterJournal.encounter.instance.mapButton:Point("BOTTOMLEFT", EncounterJournal.encounter.instance.loreBG.backdrop, 5, 5)
	EncounterJournal.encounter.instance.mapButton:StripTextures()
	S:HandleButton(EncounterJournal.encounter.instance.mapButton)

	S:HandleSirusScrollBar(EncounterJournal.encounter.instance.loreScroll.ScrollBar)
	EncounterJournal.encounter.instance.loreScroll.child.lore:SetTextColor(1, 1, 1)

	EncounterJournal.encounter.info:StripTextures(nil, true)

	local function SkinEncounterTab(tab)
		tab:Size(48)
		tab:SetTemplate("Default", true)

		tab:SetNormalTexture("")
		tab:SetPushedTexture("")
		tab:SetHighlightTexture("")
		tab:SetDisabledTexture("")

		tab.unselected:SetAllPoints()
		tab.selected:SetAllPoints()

		tab:HookScript("OnEnter", S.SetModifiedBackdrop)
		tab:HookScript("OnLeave", S.SetOriginalBackdrop)
	end

	SkinEncounterTab(EncounterJournal.encounter.info.overviewTab)
	EncounterJournal.encounter.info.overviewTab:Point("TOPLEFT", EncounterJournal.encounter.info, "TOPRIGHT", 9, -35)
	SkinEncounterTab(EncounterJournal.encounter.info.lootTab)
	EncounterJournal.encounter.info.lootTab:Point("TOP", EncounterJournal.encounter.info.overviewTab, "BOTTOM", 0, -1)
	SkinEncounterTab(EncounterJournal.encounter.info.bossTab)
	EncounterJournal.encounter.info.bossTab:Point("TOP", EncounterJournal.encounter.info.lootTab, "BOTTOM", 0, -1)
	SkinEncounterTab(EncounterJournal.encounter.info.modelTab)
	EncounterJournal.encounter.info.modelTab:Point("TOP", EncounterJournal.encounter.info.bossTab, "BOTTOM", 0, -1)

	S:HandleSirusScrollBar(EncounterJournal.encounter.info.bossesScroll.ScrollBar)
	EncounterJournal.encounter.info.bossesScroll.child.description:SetTextColor(1, 1, 1)

	S:HandleButton(EncounterJournal.encounter.info.difficulty, true)
	S:HandleButton(EncounterJournal.encounter.info.reset)

	S:HandleSirusScrollBar(EncounterJournal.encounter.info.detailsScroll.ScrollBar)
	EncounterJournal.encounter.info.detailsScroll.child.description:SetTextColor(1, 1, 1)
	S:HandleSirusScrollBar(EncounterJournal.encounter.info.overviewScroll.ScrollBar)
	EncounterJournal.encounter.info.overviewScroll.child.loreDescription:SetTextColor(1, 1, 1)

	S:HandleButton(EncounterJournal.encounter.info.lootScroll.filter, true)
	S:HandleButton(EncounterJournal.encounter.info.lootScroll.slotFilter, true)

	S:HandleSirusScrollBar(EncounterJournal.encounter.info.lootScroll.scrollBar)

	for i = 1, #EncounterJournal.encounter.info.lootScroll.buttons do
		local item = EncounterJournal.encounter.info.lootScroll.buttons[i]
		item.icon:SetDrawLayer("BORDER")
		S:HandleSirusIconButton(item, item.icon, item.IconBorder)

		item.bossTexture:SetAlpha(0)
		item.bosslessTexture:SetAlpha(0)

		item.armorType:SetTextColor(1, 1, 1)
		item.slot:SetTextColor(1, 1, 1)
		item.boss:SetTextColor(1, 1, 1)
	end

	S:HandleButton(EncounterJournalSuggestFrameSuggestion1Button)
	S:HandleButton(EncounterJournalSuggestFrameSuggestion2CenterDisplayButton)
	S:HandleButton(EncounterJournalSuggestFrameSuggestion3CenterDisplayButton)
	S:HandleNextPrevButton(EncounterJournalSuggestFrameSuggestion1PrevButton)
	S:HandleNextPrevButton(EncounterJournalSuggestFrameSuggestion1NextButton)

	if EncounterJournalSuggestFrameSuggestion1CenterDisplayTitle and EncounterJournalSuggestFrameSuggestion1CenterDisplayTitle.text then
		local fs = EncounterJournalSuggestFrameSuggestion1CenterDisplayTitle.text
		local _, size, flags = fs:GetFont()
		fs:SetFont(E.media.normFont, size or 12, flags or "")
	end

	S:HandleSirusTabs("EncounterJournalTab", 4)

	hooksecurefunc("EncounterJournal_ListInstances", function()
		local scrollFrame = EncounterJournal.instanceSelect.scroll.child

		local index = 1
		local instanceButton = scrollFrame["instance"..index]

		while instanceButton do
			if not instanceButton.isSkinned then
				S:HandleButton(instanceButton)

				instanceButton.bgImage:SetInside()
				instanceButton.bgImage:SetTexCoord(.08, .6, .08, .6)
				instanceButton.bgImage:SetDrawLayer("BORDER")

				instanceButton.name:SetTextColor(1, 1, 1)

				instanceButton.isSkinned = true
			end

			index = index + 1
			instanceButton = scrollFrame["instance"..index]
		end

		for i = 1, index - 1 do
			local instance = scrollFrame["instance"..i]
			if instance and instance.Unavailable and instance.Unavailable.Text then
				local text = instance.Unavailable.Text
				if text.FontTemplate then
					text:FontTemplate()
				elseif text.SetFont then
					local _, size, flags = text:GetFont()
					text:SetFont(E.media.normFont, size or 12, flags or "")
				end
			end
		end
	end)

	hooksecurefunc("EncounterJournal_DisplayInstance", function(instanceID)

		local bossIndex = 1
		local bossButton = _G["EncounterJournalBossButton"..bossIndex]
		while bossButton do
			if not bossButton.isSkinned then
				S:HandleButton(bossButton)
				bossButton:SetTemplate("Transparent")

				bossButton.creature:ClearAllPoints()
				bossButton.creature:Point("TOPLEFT", 1, -4)

				bossButton.text:SetTextColor(1, 1, 1)

				bossButton.isSkinned = true
			end

			bossIndex = bossIndex + 1
			bossButton = _G["EncounterJournalBossButton"..bossIndex]
		end
	end)

	hooksecurefunc("EncounterJournal_ToggleHeaders", function()
		local headerCount = 1
		local header = _G["EncounterJournalInfoHeader"..headerCount]
		while header do
			if not header.isSkinned then
				header.descriptionBG:SetAlpha(0)
				header.descriptionBGBottom:SetAlpha(0)

				for i = 4, 18 do
					select(i, header.button:GetRegions()):SetTexture()
				end

				S:HandleButton(header.button)
				header.button:SetTemplate("Transparent")

				header.button.title:SetTextColor(unpack(E.media.rgbvaluecolor))
				header.button.title.SetTextColor = E.noop
				header.button.expandedIcon:SetTextColor(1, 1, 1)
				header.button.expandedIcon.SetTextColor = E.noop

				header.description:SetTextColor(1, 1, 1)
				header.description.SetTextColor = E.noop

				header.isSkinned = true
			end

			headerCount = headerCount + 1
			header = _G["EncounterJournalInfoHeader"..headerCount]
		end
	end)

	hooksecurefunc("EncounterJournal_SetBullets", function(object)
		local parent = object:GetParent()
		if parent and parent.Bullets then
			for _, bullet in pairs(parent.Bullets) do
				if not bullet.isSkinned then
					bullet.Text:SetTextColor(1, 1, 1)
					bullet.isSkinned = true
				end
			end
		end
	end)

	S:ApplyElvUIFont(EncounterJournal)
	EncounterJournal:HookScript("OnShow", function(self)
		S:ApplyElvUIFont(self)
	end)
end

S:AddCallback("Skin_EncounterJournal", LoadSkin)
