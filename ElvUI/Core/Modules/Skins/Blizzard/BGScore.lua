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
		S:HandleTab(_G["WorldStateScoreFrameTab"..i])
		local tabText = _G["WorldStateScoreFrameTab"..i.."Text"]
		if tabText then
			tabText:Point("CENTER", 0, 2)
		end
	end

	WorldStateScoreFrameTab2:Point("LEFT", WorldStateScoreFrameTab1, "RIGHT", -15, 0)
	WorldStateScoreFrameTab3:Point("LEFT", WorldStateScoreFrameTab2, "RIGHT", -15, 0)

	WorldStateScoreScrollFrameScrollBar:Point("TOPLEFT", WorldStateScoreScrollFrame, "TOPRIGHT", 8, -21)
	WorldStateScoreScrollFrameScrollBar:Point("BOTTOMLEFT", WorldStateScoreScrollFrame, "BOTTOMRIGHT", 8, 38)

	for i = 1, 5 do
		local column = _G["WorldStateScoreColumn"..i]
		if column then
			column:StyleButton()
		end
	end

	local myName = format("> %s <", E.myname)

	hooksecurefunc("WorldStateScoreFrame_Update", function()
		local inArena = IsActiveBattlefieldArena()
		local offset = FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame)

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
				nameText:SetText(name)

				if classTextColor then
					nameText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
				end
			end
		end
	end)
end)