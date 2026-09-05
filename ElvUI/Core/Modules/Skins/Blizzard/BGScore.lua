local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local format, split = string.format, string.split
local FauxScrollFrame_GetOffset = FauxScrollFrame_GetOffset
local GetBattlefieldScore = GetBattlefieldScore
local IsActiveBattlefieldArena = IsActiveBattlefieldArena

S:AddCallback("Skin_WorldStateScore", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.bgscore then return end

	WorldStateScoreFrame:StripTextures()
	WorldStateScoreFrame:CreateBackdrop("Transparent")
	WorldStateScoreFrame.backdrop:Point("TOPLEFT", 0, 0)
	WorldStateScoreFrame.backdrop:Point("BOTTOMRIGHT", 0, 8)

	WorldStateScoreFrame:EnableMouse(true)
	S:SetBackdropHitRect(WorldStateScoreFrame)

	S:HandleCloseButton(WorldStateScoreFrameCloseButton, WorldStateScoreFrame.backdrop)

	local container = _G.WorldStateScoreFrameContainer
	container:StripTextures()

	if container.Inset then
		container.Inset:StripTextures()
	end

	if _G.WorldStateScoreFrameContainerBattlegroundNameFrame then
		_G.WorldStateScoreFrameContainerBattlegroundNameFrame:StripTextures()
	end

	local allianceScore = _G.WorldStateScoreFrameContainerAllianceScore
	local hordeScore = _G.WorldStateScoreFrameContainerHordeScore

	if allianceScore then
		local icon = container:CreateTexture(nil, "ARTWORK")
		icon:SetTexture([[Interface\AddOns\ElvUI\Core\Media\Textures\AllianceLogoSmall]])
		icon:SetSize(36, 36)
		icon:SetPoint("RIGHT", allianceScore, "LEFT", -8, 0)
		container.allianceIcon = icon
	end

	if hordeScore then
		local icon = container:CreateTexture(nil, "ARTWORK")
		icon:SetTexture([[Interface\AddOns\ElvUI\Core\Media\Textures\HordeLogoSmall]])
		icon:SetSize(36, 36)
		icon:SetPoint("LEFT", hordeScore, "RIGHT", 8, 0)
		container.hordeIcon = icon
	end

	_G.WorldStateScoreFrameWinnerWreatchLeft:Kill()
	_G.WorldStateScoreFrameWinnerWreatchRight:Kill()

	_G.WorldStateScoreFrameWinnerGlow:ClearAllPoints()
	_G.WorldStateScoreFrameWinnerGlow:Point("BOTTOM", _G.WorldStateScoreFrameWinner, "TOP", 0, -59)
	_G.WorldStateScoreWinnerFrame:StripTextures()

	for i = 1, MAX_WORLDSTATE_SCORE_BUTTONS do
		local left = _G["WorldStateScoreButton"..i.."FactionLeft"]
		local right = _G["WorldStateScoreButton"..i.."FactionRight"]

		if left then left:SetTexture(E.media.blankTex) end
		if right then right:SetTexture(E.media.blankTex) end
	end

	local efficiency = _G.WorldStateScoreFrameEfficiencyEfficiencyBar
	if efficiency then
		efficiency:StripTextures()
		efficiency:SetStatusBarTexture(E.media.normTex)
		efficiency:CreateBackdrop("Transparent")
		E:RegisterStatusBar(efficiency)
	end

	S:HandleDropDownBox(_G.ScorePlayerDropDown)

	WorldStateScoreScrollFrame:StripTextures()
	S:HandleSirusScrollBar(WorldStateScoreScrollFrameScrollBar)

	WorldStateScoreFrameKB:StyleButton()
	WorldStateScoreFrameDeaths:StyleButton()
	WorldStateScoreFrameHK:StyleButton()
	WorldStateScoreFrameDamageDone:StyleButton()
	WorldStateScoreFrameHealingDone:StyleButton()
	WorldStateScoreFrameHonorGained:StyleButton()
	WorldStateScoreFrameName:StyleButton()
	WorldStateScoreFrameTeam:StyleButton()

	S:HandleButton(WorldStateScoreFrameLeaveButton)
	WorldStateScoreFrameLeaveButton:StripTextures()

	for i = 1, 3 do
		local tab = _G["WorldStateScoreFrameTab"..i]
		if tab then
			S:HandleSirusTab(tab, _G["WorldStateScoreFrameTab"..(i - 1)])
		end
	end

	local tab1 = _G.WorldStateScoreFrameTab1
	if tab1 then
		tab1:ClearAllPoints()
		tab1:SetPoint("TOPLEFT", WorldStateScoreFrame.backdrop or WorldStateScoreFrame, "BOTTOMLEFT", 10, 1)
	end

	WorldStateScoreScrollFrame:ClearAllPoints()
	WorldStateScoreScrollFrame:SetPoint("TOPLEFT", _G.WorldStateScoreButton1, "TOPLEFT", 0, 0)
	WorldStateScoreScrollFrame:SetPoint("BOTTOMRIGHT", _G.WorldStateScoreButton20, "BOTTOMRIGHT", 0, 0)

	WorldStateScoreScrollFrameScrollBar:ClearAllPoints()
	WorldStateScoreScrollFrameScrollBar:SetPoint("TOPLEFT", WorldStateScoreScrollFrame, "TOPRIGHT", 8, 0)
	WorldStateScoreScrollFrameScrollBar:SetPoint("BOTTOMLEFT", WorldStateScoreScrollFrame, "BOTTOMRIGHT", 8, -9)

	for i = 1, 5 do
		local column = _G["WorldStateScoreColumn"..i]
		if column then
			column:StyleButton()
		end
	end

	local myName = format("> %s <", E.myname)

	local function PositionRows()
		local prevRow
		for r = 1, MAX_WORLDSTATE_SCORE_BUTTONS do
			local rButton = _G["WorldStateScoreButton"..r]
			if not rButton then break end

			rButton:ClearAllPoints()

			if prevRow then
				rButton:SetPoint("TOPLEFT", prevRow, "BOTTOMLEFT", 0, 0)
			else
				local kb = _G["WorldStateScoreButton1KillingBlows"]
				if kb and kb.GetLeft and kb:GetLeft() then
					rButton:SetPoint("TOP", kb, "CENTER", 0, 8)
				elseif _G.WorldStateScoreFrameName then
					rButton:SetPoint("TOP", _G.WorldStateScoreFrameName, "BOTTOM", 0, -14)
				end

				if _G.WorldStateScoreFrameName then
					rButton:SetPoint("LEFT", _G.WorldStateScoreFrameName, "LEFT", -19, 0)
				end
			end

			prevRow = rButton
		end
	end

	hooksecurefunc("WorldStateScoreFrame_Update", function()
		local inArena = IsActiveBattlefieldArena()
		local offset = FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame)

		if container.allianceIcon then container.allianceIcon:SetShown(not inArena) end
		if container.hordeIcon then container.hordeIcon:SetShown(not inArena) end

		if not inArena and container.allianceIcon and allianceScore then
			local w = allianceScore:GetStringWidth()
			container.allianceIcon:ClearAllPoints()
			container.allianceIcon:SetPoint("RIGHT", allianceScore, "RIGHT", -(w + 8), 0)
		end

		if not inArena and container.hordeIcon and hordeScore then
			local w = hordeScore:GetStringWidth()
			container.hordeIcon:ClearAllPoints()
			container.hordeIcon:SetPoint("LEFT", hordeScore, "LEFT", w + 8, 0)
		end

		pcall(PositionRows)

		pcall(function()
			local numScores = GetNumBattlefieldScores()
			if numScores <= MAX_WORLDSTATE_SCORE_BUTTONS then return end

			local scrollBar = _G.WorldStateScoreScrollFrameScrollBar
			scrollBar:Show()

			local valueStep = 16
			local maxV = (numScores - MAX_WORLDSTATE_SCORE_BUTTONS) * valueStep

			local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
			if thumb and thumb:GetHeight() > 0 then
				local height = scrollBar:GetHeight()
				if height > 0 then
					local pos = (offset * valueStep / maxV) * (height - thumb:GetHeight()) - (height / 2)
					thumb:ClearAllPoints()
					thumb:SetPoint("CENTER", scrollBar, "CENTER", 0, pos)
				end
			end

			local _, currentMax = scrollBar:GetMaxMinValues()
			if currentMax ~= maxV then
				scrollBar:SetMinMaxValues(0, maxV)
			end
			pcall(function()
				if scrollBar:GetValue() ~= offset * valueStep then
					scrollBar:SetValue(offset * valueStep)
				end
			end)
		end)

		local _, name, faction, classToken, realm, classTextColor, nameText

		for i = 1, MAX_WORLDSTATE_SCORE_BUTTONS do
			name, _, _, _, _, faction, _, _, _, classToken = GetBattlefieldScore(offset + i)

			if name then
				name, realm = split("-", name, 2)

				if name == E.myname then
					name = myName
				end

				if realm then
					local color

					if inArena then
						if faction == 1 then
							color = "|cffffd100"
						else
							color = "|cff19ff19"
						end
					else
						if faction == 1 then
							color = "|cff00adf0"
						else
							color = "|cffff1919"
						end
					end

					name = format("%s|cffffffff - |r%s%s|r", name, color, realm)
				end

				classTextColor = E:ClassColor(classToken)

				nameText = _G["WorldStateScoreButton"..i.."NameText"]

				local nameFrame = _G["WorldStateScoreButton"..i.."Name"]
				local button = _G["WorldStateScoreButton"..i]
				local anchor = nameFrame or button
				if anchor then
					nameText:ClearAllPoints()
					if nameFrame then
						nameText:SetPoint("LEFT", nameFrame, "LEFT", 0, 0)
					else
						nameText:SetPoint("LEFT", button, "LEFT", 40, 0)
					end
					nameText:SetWidth(190)
					nameText:SetHeight(16)
					nameText:SetJustifyH("LEFT")
				end

				nameText:SetText(name)

				nameText:SetShadowColor(0, 0, 0, 1)
				nameText:SetShadowOffset(1, -1)

				if classTextColor then
					nameText:SetVertexColor(1, 1, 1)
					nameText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
				end
			end
		end
	end)
end)
