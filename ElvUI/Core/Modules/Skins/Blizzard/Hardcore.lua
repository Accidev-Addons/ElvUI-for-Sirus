local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.hardcore then return end

	local HardcoreFrame = HardcoreFrame
	S:HandleSirusFrame(HardcoreFrame)

	S:HandleButton(HardcoreFrame.SuggestTab, true)
	S:HandleButton(HardcoreFrame.ChallengeListTab, true)
	S:HandleButton(HardcoreFrame.ParticipantsTab, true)
	S:HandleButton(HardcoreFrame.LadderTab, true)

	S:HandleSirusTabs("HardcoreFrameTab", 4)

	S:HandleButton(HardcoreFrame.SuggestFrame.Suggestion2.CenterDisplay.Button)
	S:HandleButton(HardcoreFrame.SuggestFrame.Suggestion3.CenterDisplay.Button)

	for i = 1, 3 do
		local title = _G["HardcoreFrameSuggestFrameSuggestion"..i.."CenterDisplayTitle"]
		if title and title.Text then
			local fs = title.Text
			local _, size, flags = fs:GetFont()
			fs:SetFont(E.media.normFont, size or 12, flags or "")
		end
	end

	if HardcoreFrame.ParticipantsFrame and HardcoreFrame.ParticipantsFrame.FilterButton then
		HardcoreFrame.ParticipantsFrame.FilterButton:StripTextures(true)
		S:HandleButton(HardcoreFrame.ParticipantsFrame.FilterButton)
	end
	if HardcoreFrame.LadderFrame and HardcoreFrame.LadderFrame.FilterButton then
		HardcoreFrame.LadderFrame.FilterButton:StripTextures(true)
		S:HandleButton(HardcoreFrame.LadderFrame.FilterButton)
	end

	local function SkinTableHeader(header)
		if not header or header.isSkinned then return end

		for _, texture in pairs({ header.LeftHighLight, header.MiddleHighLight, header.RightHighLight }) do
			if texture then
				texture:SetTexture()
				texture:Hide()
			end
		end

		S:HandleButton(header)
		S:ApplyElvUIFont(header)
	end

	local function SkinTableHeaders(panel)
		local container = panel.HeaderContainer
		if not container then return end

		for i = 1, container:GetNumChildren() do
			SkinTableHeader(select(i, container:GetChildren()))
		end
	end

	for _, panel in pairs({ HardcoreFrame.ParticipantsFrame, HardcoreFrame.LadderFrame }) do
		if panel and panel.ScrollFrame then
			S:HandleSirusScrollBar(panel.ScrollFrame.scrollBar)
		end
		if panel and panel.Refresh then
			hooksecurefunc(panel, "Refresh", SkinTableHeaders)
			SkinTableHeaders(panel)
		end
		if panel and panel.SearchFrame and panel.SearchFrame.SearchBox then
			S:HandleEditBox(panel.SearchFrame.SearchBox)
		end
		if panel and panel.FilterDropDown then
			S:HandleDropDownBox(panel.FilterDropDown)
		end
	end

	S:HandleSirusNavBar(HardcoreFrame.navBar)

	local ChallengeList = HardcoreFrame.ChallengeListFrame
	if ChallengeList and ChallengeList.ScrollFrame then
		S:HandleSirusScrollBar(ChallengeList.ScrollFrame.scrollBar)

		local function SkinChallengeRow(frame)
			if not frame or frame.isSkinned then return end

			local button = frame.Button
			if button then
				for _, texture in pairs({ button.BorderLeft, button.BorderRight, button.BorderMiddle, button.LeftShadow, button.IconBorder }) do
					if texture then
						texture:SetTexture()
						texture:Hide()
					end
				end

				button:SetTemplate("Default", true)
				button:StyleButton(nil, true)

				if button.Icon then
					button.Icon:SetDrawLayer("BORDER")
					button.Icon:SetTexCoord(unpack(E.TexCoords))

					local iconBackdrop = CreateFrame("Frame", nil, button)
					iconBackdrop:SetPoint("LEFT", button, "LEFT", 12, 0)
					iconBackdrop:SetSize(44, 44)
					iconBackdrop:SetTemplate("Default", true)
					iconBackdrop:SetFrameLevel(button:GetFrameLevel() + 2)
					button.Icon:SetParent(iconBackdrop)
					button.Icon:SetAllPoints(iconBackdrop)
				end

				if button.Name then
					local _, size, flags = button.Name:GetFont()
					button.Name:SetFont(E.media.normFont, size or 12, flags or "")
					button.Name:SetTextColor(1, 1, 1)
				end
			end

			local info = frame.InfoFrame
			if info then
				if info.Border then info.Border:Hide() end
				if info.Background then info.Background:Hide() end

				if info.LeftFrame then
					info.LeftFrame:StripTextures()
					info.LeftFrame:SetTemplate("Transparent")
					if info.LeftFrame.ScrollFrame and info.LeftFrame.ScrollFrame.ScrollBar then
						S:HandleSirusScrollBar(info.LeftFrame.ScrollFrame.ScrollBar)
					end
				end

				if info.RightFrame then
					info.RightFrame:StripTextures()
					info.RightFrame:SetTemplate("Transparent")

					for i = 1, 3 do
						local tab = info.RightFrame["TabButton"..i]
						if tab and not tab.isSkinned then
							tab:StripTextures()
							tab:SetTemplate("Default", true)
							tab:StyleButton(nil, true)
							if tab.Text then
								local _, size, flags = tab.Text:GetFont()
								tab.Text:SetFont(E.media.normFont, size or 12, flags or "")
								tab.Text:SetTextColor(1, 0.82, 0)
							end
							tab.isSkinned = true
						end
					end

					if info.RightFrame.StartButton and not info.RightFrame.StartButton.isSkinned then
						S:HandleButton(info.RightFrame.StartButton)
						if info.RightFrame.StartButton.Glow then
							info.RightFrame.StartButton.Glow:Hide()
						end
					end
				end
			end

			frame.isSkinned = true
		end

		local function SkinChallengeRows()
			for _, button in ipairs(ChallengeList.ScrollFrame.buttons) do
				SkinChallengeRow(button)
			end
		end

		if ChallengeList.Refresh then
			hooksecurefunc(ChallengeList, "Refresh", SkinChallengeRows)
		end
		SkinChallengeRows()
	end

	S:ApplyElvUIFont(HardcoreFrame)
	HardcoreFrame:HookScript("OnShow", function(self)
		S:ApplyElvUIFont(self)
	end)
end

S:AddCallback("Skin_Hardcore", LoadSkin)
