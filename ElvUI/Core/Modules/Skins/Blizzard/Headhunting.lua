local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local ipairs = ipairs

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.headhunting then return end

	local HeadHuntingFrame = HeadHuntingFrame
	S:HandleSirusFrame(HeadHuntingFrame)

	for i = 1, 3 do
		local popup = HeadHuntingFrame["PopupFrame"..i]
		if popup then
			popup:SetTemplate("Transparent")
			if popup.Button1 then S:HandleButton(popup.Button1) end
		end
	end

	S:HandleSirusNavBar(HeadHuntingFrame.navBar)

	if HeadHuntingFrame.inset then HeadHuntingFrame.inset:StripTextures() end

	if HeadHuntingFrame.Container then
	S:HandleButton(HeadHuntingFrame.Container.HomeTab, true)
	if HeadHuntingFrame.Container.HomeTab:GetFontString() then
		HeadHuntingFrame.Container.HomeTab:GetFontString():FontTemplate()
	end

	S:HandleSirusTabs("HeadHuntingFrameTab", 4)
		S:HandleButton(HeadHuntingFrame.Container.AllTargetsTab, true)
		S:HandleButton(HeadHuntingFrame.Container.YouTargetsTab, true)
	end

	local function Panel_OnShow(self)
		for _, button in ipairs(HeadHuntingFrame.columnButtons) do
			if not button.isSkinned then
				button:StripTextures()
				button:SetTemplate("Default", true)
				button:StyleButton(nil, true)
				button.isSkinned = true
			end
		end
	end

	local HomePanel = HeadHuntingFrame.Container.HomePanel
	HomePanel:HookScript("OnShow", Panel_OnShow)
	S:HandleButton(HomePanel.SuggestionFrameRightTop.CenterDisplay.ButtonLeft)
	S:HandleButton(HomePanel.SuggestionFrameRightTop.CenterDisplay.ButtonRight)
	S:HandleButton(HomePanel.SuggestionFrameRightBottom.CenterDisplay.ButtonLeft)
	S:HandleButton(HomePanel.SuggestionFrameRightBottom.CenterDisplay.ButtonRight)

	local suggestionFrames = {
		HeadHuntingFrameContainerHomePanelSuggestionFrameLeftCenterDisplay,
		HeadHuntingFrameContainerHomePanelSuggestionFrameRightTopCenterDisplay,
		HeadHuntingFrameContainerHomePanelSuggestionFrameRightBottomCenterDisplay,
	}
	for _, frame in ipairs(suggestionFrames) do
		if frame and frame.Title and frame.Title.text then
			local fs = frame.Title.text
			local _, size, flags = fs:GetFont()
			fs:SetFont(E.media.normFont, size or 12, flags or "")
		end
	end

	local AllTargetsPanel = HeadHuntingFrame.Container.AllTargetsPanel
	AllTargetsPanel:HookScript("OnShow", Panel_OnShow)
	if AllTargetsPanel.ScrollFrame and AllTargetsPanel.ScrollFrame.Background then AllTargetsPanel.ScrollFrame.Background:SetAlpha(0) end
	if HeadHuntingFrameContainerAllTargetsPanelScrollFrameScrollBar then
		S:HandleSirusScrollBar(HeadHuntingFrameContainerAllTargetsPanelScrollFrameScrollBar)
	end
	if AllTargetsPanel.ScrollFrame and AllTargetsPanel.ScrollFrame.ShadowOverlay then AllTargetsPanel.ScrollFrame.ShadowOverlay:SetAlpha(0) end

	AllTargetsPanel.InfoFrame:SetTemplate("Transparent")
	if AllTargetsPanel.InfoFrame.BackgroundTile then AllTargetsPanel.InfoFrame.BackgroundTile:SetAlpha(0) end
	if AllTargetsPanel.InfoFrame.ShadowOverlay then AllTargetsPanel.InfoFrame.ShadowOverlay:SetAlpha(0) end
	if HeadHuntingFrameContainerAllTargetsPanelInfoFrameContainerScrollFrameScrollBar then
		S:HandleSirusScrollBar(HeadHuntingFrameContainerAllTargetsPanelInfoFrameContainerScrollFrameScrollBar)
	end

	local closeButton = select(3, AllTargetsPanel.InfoFrame:GetChildren())
	if closeButton then
		S:HandleCloseButton(closeButton)
		if closeButton.Corner then closeButton.Corner:SetAlpha(0) end
	end

	if AllTargetsPanel.ContractOnPlayer then AllTargetsPanel.ContractOnPlayer:StripTextures() end

	local YouTargetsPanel = HeadHuntingFrame.Container.YouTargetsPanel
	YouTargetsPanel:HookScript("OnShow", Panel_OnShow)

	S:HandleButton(YouTargetsPanel.SetRewardButton)
	if YouTargetsPanel.ScrollFrame and YouTargetsPanel.ScrollFrame.Background then YouTargetsPanel.ScrollFrame.Background:SetAlpha(0) end
	if HeadHuntingFrameContainerYouTargetsPanelScrollFrameScrollBar then
		S:HandleSirusScrollBar(HeadHuntingFrameContainerYouTargetsPanelScrollFrameScrollBar)
	end
	if YouTargetsPanel.ScrollFrame and YouTargetsPanel.ScrollFrame.ShadowOverlay then YouTargetsPanel.ScrollFrame.ShadowOverlay:SetAlpha(0) end

	YouTargetsPanel.DetailsFrame:SetTemplate("Transparent")
	if YouTargetsPanel.DetailsFrame.CloseCorner then YouTargetsPanel.DetailsFrame.CloseCorner:SetAlpha(0) end
	if YouTargetsPanel.DetailsFrame.Divider then YouTargetsPanel.DetailsFrame.Divider:SetAlpha(0) end
	S:HandleCheckBox(YouTargetsPanel.DetailsFrame.Container.NotifyWhenKilling)
	S:HandleCheckBox(YouTargetsPanel.DetailsFrame.Container.NotifyWhenComplete)
	S:HandleCloseButton(YouTargetsPanel.DetailsFrame.CloseButton)
	S:HandleButton(YouTargetsPanel.DetailsFrame.RemoveContractButton)

	local function SkinRewardFrame(frame)
		S:HandleSirusFrame(frame)
		S:HandleEditBox(frame.SearchFrame.SearchBox)
		S:HandleButton(frame.SearchFrame.SearchButton)
		frame.CentralContainer:StripTextures()
		if frame.CentralContainer.ScrollFrame and frame.CentralContainer.ScrollFrame.ShadowOverlay then frame.CentralContainer.ScrollFrame.ShadowOverlay:SetAlpha(0) end
		if _G[frame:GetName().."CentralContainerScrollFrameScrollBar"] then
			S:HandleSirusScrollBar(_G[frame:GetName().."CentralContainerScrollFrameScrollBar"])
		end
		S:HandleEditBox(frame.NumKills)
		S:HandleEditBox(frame.GoldPerKillsEditBox)
		S:HandleButton(frame.SetRewardButton)
	end

	SkinRewardFrame(YouTargetsPanel.SetRewardFrame)

	S:HandleEditBox(HeadHuntingFrame.Container.AllTargetsPanel.SearchFrame.SearchBox)
	S:HandleButton(HeadHuntingFrame.Container.AllTargetsPanel.SearchFrame.SearchButton)
	if HeadHuntingFrameContainerAllTargetsPanelFilterButton then
		HeadHuntingFrameContainerAllTargetsPanelFilterButton:StripTextures(true)
		S:HandleButton(HeadHuntingFrameContainerAllTargetsPanelFilterButton)
	end
	if HeadHuntingFrameContainerAllTargetsPanelFilterDropDownMenu then
		HeadHuntingFrameContainerAllTargetsPanelFilterDropDownMenu:StripTextures(true)
		S:HandleButton(HeadHuntingFrameContainerAllTargetsPanelFilterDropDownMenu)
	end

	if HeadHuntingSetRewardExternalFrame then
		HeadHuntingSetRewardExternalFrame:SetParent(UIParent)
		SkinRewardFrame(HeadHuntingSetRewardExternalFrame)
	end

	S:ApplyElvUIFont(HeadHuntingFrame)
	HeadHuntingFrame:HookScript("OnShow", function(self)
		S:ApplyElvUIFont(self)
	end)
end

S:AddCallback("Skin_Headhunting", LoadSkin)
