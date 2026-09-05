local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local getmetatable = getmetatable
local ipairs = ipairs
local unpack = unpack
local hooksecurefunc = hooksecurefunc
local GetAchievementNumCriteria = GetAchievementNumCriteria
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo
local CRITERIA_TYPE_ACHIEVEMENT = CRITERIA_TYPE_ACHIEVEMENT

local achievementSaturate = function(self)
	self:SetBackdropBorderColor(unpack(E.media.bordercolor))
end
local function skinAchievement(achievement, biggerIcon)
	if achievement.isSkinned then return end

	_G[achievement:GetName().."Background"]:Kill()
	achievement:StripTextures()
	achievement:SetTemplate("Default", true)
	achievement.icon:SetTemplate()
	achievement.icon:Size(biggerIcon and 54 or 36)
	achievement.icon:ClearAllPoints()
	achievement.icon:Point("TOPLEFT", biggerIcon and 8 or 6, biggerIcon and -7 or -6)
	achievement.icon.bling:SetTexture()
	achievement.icon.frame:SetTexture()
	achievement.icon.texture:SetTexCoords()
	achievement.icon.texture:SetInside()

	if achievement.highlight then
		achievement.highlight:StripTextures()
		achievement:HookScript("OnEnter", S.SetModifiedBackdrop)
		achievement:HookScript("OnLeave", S.SetOriginalBackdrop)
	end

	if achievement.label then
		achievement.label:SetTextColor(1, 1, 1)
	end

	if achievement.description then
		achievement.description:SetTextColor(.6, .6, .6)
		achievement.description.SetTextColor = E.noop
	end

	if achievement.hiddenDescription then
		achievement.hiddenDescription:SetTextColor(1, 1, 1)
	end

	if achievement.tracked then
		S:HandleCheckBox(achievement.tracked, true)
		achievement.tracked:Size(14)
		achievement.tracked:ClearAllPoints()
		achievement.tracked:Point("TOPLEFT", achievement.icon, "BOTTOMLEFT", 0, -2)
	end

	hooksecurefunc(achievement, "Saturate", achievementSaturate)
	hooksecurefunc(achievement, "Desaturate", achievementSaturate)

	achievement.isSkinned = true
end

S:AddCallback("Skin_AchievementUI_HybridScrollButton", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.achievement then return end

	hooksecurefunc("HybridScrollFrame_CreateButtons", function(frame, template)
		if template == "AchievementCategoryTemplate" then
			local function UpdateSelection()
				local selectedCategory = achievementFunctions and achievementFunctions.selectedCategory
				for _, button in ipairs(frame.buttons) do
					if button.isSkinned and button.backdrop then
						button.backdrop:SetBackdropColor(0, 0, 0, 0)
						button.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
						if selectedCategory and button.categoryID == selectedCategory then
							button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
						end
					end
				end
			end

			for _, button in ipairs(frame.buttons) do
				if not button.isSkinned then
					button:StripTextures(true)
					button:StyleButton()

					if button.SetHighlightTexture and button.CreateTexture then
						local hover = button:CreateTexture()
						hover:SetInside()
						hover:SetBlendMode("ADD")
						hover:SetTexture(1, 1, 1, 0.3)
						button:SetHighlightTexture(hover)
						button.hover = hover
					end

					button:CreateBackdrop("Transparent")
					button.isSkinned = true
				end
			end

			if _G.AchievementFrameCategories_Update and not frame.SelectionHooked then
				frame.SelectionHooked = true
				hooksecurefunc("AchievementFrameCategories_Update", function()
					UpdateSelection()
				end)
			end

			local scrollBar = AchievementFrameCategoriesContainerScrollBar
			if scrollBar and not scrollBar.SelectionHooked then
				scrollBar.SelectionHooked = true
				hooksecurefunc(scrollBar, "SetValue", function(self, value)
					C_Timer:After(0.05, UpdateSelection)
				end)
			end
		elseif template == "AchievementTemplate" then
			for _, achievement in ipairs(frame.buttons) do
				skinAchievement(achievement, true)
			end
		elseif template == "ComparisonTemplate" then
			for _, achievement in ipairs(frame.buttons) do
				skinAchievement(achievement.player)
				skinAchievement(achievement.friend)
			end
		elseif template == "StatTemplate" then
			for _, stats in ipairs(frame.buttons) do
				if not stats.isSkinned then
					stats:StyleButton()
					stats.isSkinned = true
				end
			end
		end
	end)
end)

S:AddCallbackForAddon("Blizzard_AchievementUI", "Skin_Blizzard_AchievementUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.achievement then return end

	local frames = {
		"AchievementFrame",
		"AchievementFrameSummary",
		"AchievementFrameSummaryCategoriesHeader",
		"AchievementFrameSummaryAchievementsHeader",
		"AchievementFrameStatsBG",
		"AchievementFrameAchievements",
		"AchievementFrameComparison",
		"AchievementFrameComparisonHeader",
		"AchievementFrameComparisonSummaryPlayer",
		"AchievementFrameComparisonSummaryFriend"
	}

	for _, frame in ipairs(frames) do
		_G[frame]:StripTextures(true)
	end

	local nonameFrames = {
		"AchievementFrameStats",
		"AchievementFrameSummary",
		"AchievementFrameAchievements",
		"AchievementFrameComparison"
	}

	for _, frame in ipairs(nonameFrames) do
		frame = _G[frame]
		for i = 1, frame:GetNumChildren() do
			local child = select(i, frame:GetChildren())
			if child and not child:GetName() then
				child:SetBackdrop(nil)
			end
		end
	end

	local function updatePanelInfo(self)
		if self == AchievementFrameComparison then
			if AchievementFrame.isComparison then
				AchievementFrame:Width(863)
			else
				AchievementFrame:Width(737)
			end
		end

		S:SetUIPanelWindowInfo(AchievementFrame, "xoffset", 11, nil, true)
		S:SetUIPanelWindowInfo(AchievementFrame, "yoffset", -12, nil, true)
		S:SetUIPanelWindowInfo(AchievementFrame, "width", nil, -11)
	end

	AchievementFrame:HookScript("OnShow", updatePanelInfo)
	AchievementFrameComparison:HookScript("OnShow", updatePanelInfo)
	AchievementFrameComparison:HookScript("OnHide", updatePanelInfo)

	S:HandleCloseButton(AchievementFrameCloseButton, AchievementFrame.backdrop)

	S:HandleDropDownBox(AchievementFrameFilterDropDown)

	S:HandleSirusScrollBar(AchievementFrameCategoriesContainerScrollBar)
	S:HandleSirusScrollBar(AchievementFrameAchievementsContainerScrollBar)
	S:HandleSirusScrollBar(AchievementFrameStatsContainerScrollBar)
	S:HandleSirusScrollBar(AchievementFrameComparisonContainerScrollBar)
	S:HandleSirusScrollBar(AchievementFrameComparisonStatsContainerScrollBar)

	AchievementFrameHeaderTitle:SetParent(AchievementFrame)
	AchievementFrameHeaderTitle:ClearAllPoints()
	AchievementFrameHeaderTitle:Point("TOPLEFT", -29, -9)

	AchievementFrameHeaderPoints:SetParent(AchievementFrame)
	AchievementFrameHeaderPoints:ClearAllPoints()
	AchievementFrameHeaderPoints:Point("LEFT", AchievementFrameHeaderTitle, "RIGHT", 2, 0)

	AchievementFrameHeaderShield:SetParent(AchievementFrame)

	AchievementFrameHeader:Hide()
	AchievementFrameHeader.Show = E.noop

	AchievementFrame:Size(737, 485)
	AchievementFrame:SetTemplate("Transparent")

	AchievementFrameFilterDropDown:Point("TOPRIGHT", AchievementFrame, "TOPRIGHT", -21, -5)

	AchievementFrameCategories:SetTemplate("Default")
	AchievementFrameCategories:Point("TOPLEFT", 8, -35)
	AchievementFrameCategories:Point("BOTTOMLEFT", 21, 8)

	AchievementFrameCategoriesContainerScrollBar:Point("TOPLEFT", AchievementFrameCategoriesContainer, "TOPRIGHT", 3, -14)
	AchievementFrameCategoriesContainerScrollBar:Point("BOTTOMLEFT", AchievementFrameCategoriesContainer, "BOTTOMRIGHT", 3, 14)

	AchievementFrameSummaryAchievements:Point("TOPLEFT", 5, -10)
	AchievementFrameSummaryAchievements:Point("TOPRIGHT", -5, -30)

	AchievementFrameAchievements:SetTemplate("Transparent")

	AchievementFrameAchievementsContainer:Point("TOPLEFT", 2, -2)
	AchievementFrameAchievementsContainer:Point("BOTTOMRIGHT", -2, 4)

	AchievementFrameAchievementsContainerScrollBar:Point("TOPLEFT", AchievementFrameAchievementsContainer, "TOPRIGHT", 5, -17)
	AchievementFrameAchievementsContainerScrollBar:Point("BOTTOMLEFT", AchievementFrameAchievementsContainer, "BOTTOMRIGHT", 5, 15)

	AchievementFrameStats:SetTemplate("Transparent")

	AchievementFrameStatsContainerScrollBar:Point("TOPLEFT", AchievementFrameStatsContainer, "TOPRIGHT", 3, -16)
	AchievementFrameStatsContainerScrollBar:Point("BOTTOMLEFT", AchievementFrameStatsContainer, "BOTTOMRIGHT", 3, 14)

	AchievementFrameComparison:SetTemplate("Transparent")

	AchievementFrameComparisonHeader:Point("BOTTOMRIGHT", AchievementFrameComparison, "TOPRIGHT", 50, -1)

	AchievementFrameComparison:Point("TOPLEFT", AchievementFrameCategories, "TOPRIGHT", 3, 0)

	AchievementFrameComparisonSummary:Height(30)
	AchievementFrameComparisonSummary:Point("TOPLEFT", 4, -2)

	AchievementFrameComparisonContainer:Point("TOPLEFT", AchievementFrameComparisonSummary, "BOTTOMLEFT", 0, -3)

	AchievementFrameComparisonContainerScrollBar:Point("TOPLEFT", AchievementFrameComparisonSummary, "TOPRIGHT", 9, -17)
	AchievementFrameComparisonContainerScrollBar:Point("BOTTOMLEFT", AchievementFrameComparisonContainer, "BOTTOMRIGHT", 9, 14)

	AchievementFrameComparisonStatsContainer:Point("TOPLEFT", 5, -3)

	AchievementFrameComparisonStatsContainerScrollBar:Point("TOPLEFT", AchievementFrameComparisonStatsContainer, "TOPRIGHT", 3, -16)
	AchievementFrameComparisonStatsContainerScrollBar:Point("BOTTOMLEFT", AchievementFrameComparisonStatsContainer, "BOTTOMRIGHT", 3, 14)

	AchievementFrameAchievementsContainerScrollBar.Show = function(self)
		AchievementFrameAchievements:SetWidth(500)
		for _, button in ipairs(AchievementFrameAchievements.buttons) do
			button:SetWidth(496)
		end
		getmetatable(self).__index.Show(self)
	end

	AchievementFrameAchievementsContainerScrollBar.Hide = function(self)
		AchievementFrameAchievements:SetWidth(521)
		for _, button in ipairs(AchievementFrameAchievements.buttons) do
			button:SetWidth(517)
		end
		getmetatable(self).__index.Hide(self)
	end

	AchievementFrameStatsContainerScrollBar.Show = function(self)
		AchievementFrameStats:SetWidth(500)
		for _, button in ipairs(AchievementFrameStats.buttons) do
			button:SetWidth(494)
		end
		getmetatable(self).__index.Show(self)
	end

	AchievementFrameStatsContainerScrollBar.Hide = function(self)
		AchievementFrameStats:SetWidth(521)
		for _, button in ipairs(AchievementFrameStats.buttons) do
			button:SetWidth(515)
		end
		getmetatable(self).__index.Hide(self)
	end

	AchievementFrameComparisonContainerScrollBar.Hide = function(self)
		AchievementFrameComparison:SetWidth(647)
		AchievementFrameComparisonSummaryPlayer:SetWidth(519)
		for _, button in ipairs(AchievementFrameComparisonContainer.buttons) do
			button:SetWidth(637)
			button.player:SetWidth(519)
		end
		getmetatable(self).__index.Hide(self)
	end

	AchievementFrameComparisonStatsContainerScrollBar.Hide = function(self)
		AchievementFrameComparison:SetWidth(647)
		for _, button in ipairs(AchievementFrameComparisonStatsContainer.buttons) do
			button:SetWidth(637)
		end
		getmetatable(self).__index.Hide(self)
	end

	local function categoriesContainerScripts()
		AchievementFrameCategoriesContainerScrollBar.Show = function(self)
			ACHIEVEMENTUI_CATEGORIESWIDTH = 176

			AchievementFrameCategories:SetWidth(176)
			AchievementFrameCategoriesContainer:GetScrollChild():SetWidth(176)

			AchievementFrameAchievements:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 24, 0)
			AchievementFrameStats:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 24, 0)
			AchievementFrameComparison:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 24, 0)

			for _, button in ipairs(AchievementFrameCategoriesContainer.buttons) do
				AchievementFrameCategories_DisplayButton(button, button.element)
			end
			getmetatable(self).__index.Show(self)
		end

		AchievementFrameCategoriesContainerScrollBar.Hide = function(self)
			ACHIEVEMENTUI_CATEGORIESWIDTH = 197

			AchievementFrameCategories:SetWidth(197)
			AchievementFrameCategoriesContainer:GetScrollChild():SetWidth(197)

			AchievementFrameAchievements:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 3, 0)
			AchievementFrameStats:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 3, 0)
			AchievementFrameComparison:SetPoint("TOPLEFT", "$parentCategories", "TOPRIGHT", 3, 0)

			for _, button in ipairs(AchievementFrameCategoriesContainer.buttons) do
				AchievementFrameCategories_DisplayButton(button, button.element)
			end
			getmetatable(self).__index.Hide(self)
		end
	end

	if AchievementFrameCategoriesContainer.update then
		categoriesContainerScripts()
	else
		AchievementFrameCategories:HookScript("OnEvent", categoriesContainerScripts)
	end

	for i = 1, 2 do
		local tab = _G["AchievementFrameTab"..i]
		if tab then
			S:HandleTab(tab)
			tab.text:SetPoint("CENTER", 0, 2)
		end
	end

	AchievementFrameTab1:Point("BOTTOMLEFT", AchievementFrame, "BOTTOMLEFT", 0, -30)
	AchievementFrameTab2:Point("LEFT", AchievementFrameTab1, "RIGHT", -15, 0)

	local sbcR, sbcG, sbcB = 4/255, 179/255, 30/255

	local function skinStatusBar(bar)
		bar:StripTextures()
		bar:SetStatusBarTexture(E.media.normTex)
		bar:SetStatusBarColor(sbcR, sbcG, sbcB)
		bar:CreateBackdrop("Default")
		E:RegisterStatusBar(bar)

		local barName = bar:GetName()
		local title = _G[barName.."Title"]
		local label = _G[barName.."Label"]
		local text = _G[barName.."Text"]

		if title then
			title:Point("LEFT", 4, 0)
		end

		if label then
			label:Point("LEFT", 4, 0)
		end

		if text then
			text:Point("RIGHT", -4, 0)
		end
	end

	skinStatusBar(AchievementFrameSummaryCategoriesStatusBar)
	skinStatusBar(AchievementFrameComparisonSummaryPlayerStatusBar)
	skinStatusBar(AchievementFrameComparisonSummaryFriendStatusBar)
	AchievementFrameComparisonSummaryFriendStatusBar.text:ClearAllPoints()
	AchievementFrameComparisonSummaryFriendStatusBar.text:SetPoint("CENTER")

	for i = 1, 8 do
		local frame = _G["AchievementFrameSummaryCategoriesCategory"..i]
		local button = _G["AchievementFrameSummaryCategoriesCategory"..i.."Button"]
		local highlight = _G["AchievementFrameSummaryCategoriesCategory"..i.."ButtonHighlight"]
		local middle = _G["AchievementFrameSummaryCategoriesCategory"..i.."ButtonHighlightMiddle"]

		skinStatusBar(frame)
		button:StripTextures()
		highlight:StripTextures()

		middle:SetTexture(1, 1, 1, 0.3)
		middle:SetAllPoints(frame)
	end

	for i = 1, 20 do
		_G["AchievementFrameStatsContainerButton"..i]:StyleButton()
		_G["AchievementFrameStatsContainerButton"..i.."BG"]:SetTexture(1, 1, 1, 0.2)
		_G["AchievementFrameStatsContainerButton"..i.."HeaderLeft"]:Kill()
		_G["AchievementFrameStatsContainerButton"..i.."HeaderRight"]:Kill()
		_G["AchievementFrameStatsContainerButton"..i.."HeaderMiddle"]:Kill()

		local frame = _G["AchievementFrameComparisonStatsContainerButton"..i]
		frame:StripTextures()
		frame:StyleButton()
		_G["AchievementFrameComparisonStatsContainerButton"..i.."BG"]:SetTexture(1, 1, 1, 0.2)
		_G["AchievementFrameComparisonStatsContainerButton"..i.."HeaderLeft"]:Kill()
		_G["AchievementFrameComparisonStatsContainerButton"..i.."HeaderRight"]:Kill()
		_G["AchievementFrameComparisonStatsContainerButton"..i.."HeaderMiddle"]:Kill()
	end

	hooksecurefunc("AchievementFrameSummary_UpdateAchievements", function()
		local frame, prevFrame

		for i = 1, ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS do
			frame = _G["AchievementFrameSummaryAchievement"..i]

			skinAchievement(frame)

			if i ~= 1 then
				prevFrame = _G["AchievementFrameSummaryAchievement"..(i-1)]
				frame:Point("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -1)
				frame:Point("TOPRIGHT", prevFrame, "BOTTOMRIGHT", 0, 1)
			end

			frame:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end)

	hooksecurefunc("AchievementButton_GetProgressBar", function(index)
		local frame = _G["AchievementFrameProgressBar"..index]

		if frame and not frame.skinned then
			frame:StripTextures()
			frame:SetTemplate("Default")
			frame:Height(frame:GetHeight() + (E.Border + E.Spacing))
			frame:SetStatusBarTexture(E.media.normTex)
			frame:SetStatusBarColor(sbcR, sbcG, sbcB)
			frame:GetStatusBarTexture():SetInside()
			E:RegisterStatusBar(frame)

			frame.text:Point("CENTER", 0, -1)
			frame.text:SetJustifyH("CENTER")

			if index > 1 then
				frame:Point("TOP", _G["AchievementFrameProgressBar"..index-1], "BOTTOM", 0, -5)
				frame.SetPoint = E.noop
			end

			frame.skinned = true
		end
	end)

	hooksecurefunc("AchievementObjectives_DisplayCriteria", function(objectivesFrame, id)
		local numCriteria = GetAchievementNumCriteria(id)
		local textStrings, metas = 0, 0

		for i = 1, numCriteria do
			local _, criteriaType, completed, _, _, _, _, assetID = GetAchievementCriteriaInfo(id, i)

			if criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetID then
				metas = metas + 1
				local metaCriteria = AchievementButton_GetMeta(metas)

				metaCriteria:Height(21)
				metaCriteria:StyleButton()
				metaCriteria.border:Kill()
				metaCriteria.icon:SetTexCoords()
				metaCriteria.icon:Point("TOPLEFT", 2, -2)
				metaCriteria.label:Point("LEFT", 26, 0)

				if objectivesFrame.completed and completed then
					metaCriteria.label:SetShadowOffset(0, 0)
					metaCriteria.label:SetTextColor(1, 1, 1, 1)
				elseif completed then
					metaCriteria.label:SetShadowOffset(1, -1)
					metaCriteria.label:SetTextColor(0, 1, 0, 1)
				else
					metaCriteria.label:SetShadowOffset(1, -1)
					metaCriteria.label:SetTextColor(.6, .6, .6, 1)
				end
			elseif criteriaType ~= 1 then
				textStrings = textStrings + 1
				local criteria = AchievementButton_GetCriteria(textStrings)

				if objectivesFrame.completed and completed then
					criteria.name:SetTextColor(1, 1, 1, 1)
					criteria.name:SetShadowOffset(0, 0)
				elseif completed then
					criteria.name:SetTextColor(0, 1, 0, 1)
					criteria.name:SetShadowOffset(1, -1)
				else
					criteria.name:SetTextColor(.6, .6, .6, 1)
					criteria.name:SetShadowOffset(1, -1)
				end
			end
		end
	end)

	hooksecurefunc("AchievementObjectives_DisplayProgressiveAchievement", function(objectivesFrame, id)
		local mini

		for i = 1, 12 do
			mini = _G["AchievementFrameMiniAchievement"..i]

			if mini and not mini.isSkinned then
				local icon = _G["AchievementFrameMiniAchievement"..i.."Icon"]
				local points = _G["AchievementFrameMiniAchievement"..i.."Points"]
				local border = _G["AchievementFrameMiniAchievement"..i.."Border"]
				local shield = _G["AchievementFrameMiniAchievement"..i.."Shield"]

				mini:SetTemplate()
				mini:SetBackdropColor(0, 0, 0, 0)
				mini:Size(32)

				if i == 1 then
					mini:Point("TOPLEFT", 6, -4)
				elseif i == 7 then
					mini:Point("TOPLEFT", AchievementFrameMiniAchievement1, "BOTTOMLEFT", 0, -20)
				else
					mini:Point("TOPLEFT", _G["AchievementFrameMiniAchievement"..i - 1], "TOPRIGHT", 10, 0)
				end
				mini.SetPoint = E.noop

				icon:SetTexCoords()
				icon:SetInside()

				points:Point("BOTTOMRIGHT", -8, -15)
				points:SetTextColor(1, 0.80, 0.10)

				border:Kill()
				shield:Kill()

				mini.isSkinned = true
			end
		end
	end)
end)

S:AddCallbackForAddon("Blizzard_AchievementUI", "Skin_Sirus_AchievementUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.achievement then return end

	if AchievementFrameFilterDropDown then
		AchievementFrameFilterDropDown:ClearAllPoints()
		AchievementFrameFilterDropDown:Point("TOPLEFT", AchievementFrame, "TOPLEFT", 220, -6)
	end

	if AchievementFrame.searchBox then
		S:HandleEditBox(AchievementFrame.searchBox)
		if AchievementFrame.searchBox.backdrop then
			AchievementFrame.searchBox.backdrop:Point("TOPLEFT", AchievementFrame.searchBox, "TOPLEFT", -3, -3)
			AchievementFrame.searchBox.backdrop:Point("BOTTOMRIGHT", AchievementFrame.searchBox, "BOTTOMRIGHT", 0, 3)
		end
		AchievementFrame.searchBox:ClearAllPoints()
		AchievementFrame.searchBox:Point("TOPLEFT", AchievementFrame, "TOPLEFT", 604, -6)
		AchievementFrame.searchBox:Size(107, 25)
	end

	if AchievementFrame.searchResults then
		AchievementFrame.searchResults:StripTextures()
		AchievementFrame.searchResults:CreateBackdrop("Transparent")
	end

	if AchievementFrame.searchPreviewContainer then
		AchievementFrame.searchPreviewContainer:StripTextures()
		AchievementFrame.searchPreviewContainer:ClearAllPoints()
		AchievementFrame.searchPreviewContainer:Point("TOPLEFT", AchievementFrame, "TOPRIGHT", 2, -1)
	end

	local function SkinSearchButton(self)
		self:StripTextures()

		if self.icon then
			S:HandleIcon(self.icon)
		end

		self:CreateBackdrop("Transparent")
		self:SetHighlightTexture(E.Media.Textures.Highlight)

		local hl = self:GetHighlightTexture()
		if hl then
			hl:SetVertexColor(1, 1, 1, 0.3)
			hl:Point("TOPLEFT", 1, -1)
			hl:Point("BOTTOMRIGHT", -1, 1)
		end
	end

	local previewContainer = AchievementFrame.searchPreviewContainer
	if previewContainer then
		for i = 1, 5 do
			local preview = previewContainer["searchPreview"..i]
			if preview then SkinSearchButton(preview) end
		end

		if previewContainer.showAllSearchResults then
			SkinSearchButton(previewContainer.showAllSearchResults)
		end
	end

	hooksecurefunc("AchievementFrame_UpdateFullSearchResults", function()
		local numResults = GetNumFilteredAchievements()

		local scrollFrame = AchievementFrame.searchResults and AchievementFrame.searchResults.scrollFrame
		if not scrollFrame then return end

		local offset = HybridScrollFrame_GetOffset(scrollFrame)
		local results = scrollFrame.buttons
		local result, index

		for i = 1, #results do
			result = results[i]
			index = offset + i

			if index <= numResults then
				if not result.styled then
					result:SetNormalTexture("")
					result:SetPushedTexture("")
					if result:GetRegions() then result:GetRegions():SetAlpha(0) end

					if result.resultType then result.resultType:SetTextColor(1, 1, 1) end
					if result.path then result.path:SetTextColor(1, 1, 1) end

					result.styled = true
				end

				if result.icon and result.icon:GetTexCoord() == 0 then
					result.icon:SetTexCoords()
				end
			end
		end
	end)

	local searchScrollFrame = AchievementFrame.searchResults and AchievementFrame.searchResults.scrollFrame
	if searchScrollFrame and searchScrollFrame.update then
		hooksecurefunc(searchScrollFrame, "update", function(self)
			for i = 1, #self.buttons do
				local result = self.buttons[i]
				if result.icon and result.icon:GetTexCoord() == 0 then
					result.icon:SetTexCoords()
				end
			end
		end)
	end

	if AchievementFrame.searchResults and AchievementFrame.searchResults.closeButton then
		S:HandleCloseButton(AchievementFrame.searchResults.closeButton)
	end

	if AchievementFrameSearchResultsScrollFrameScrollBar then
		S:HandleSirusScrollBar(AchievementFrameSearchResultsScrollFrameScrollBar)
	end
end)