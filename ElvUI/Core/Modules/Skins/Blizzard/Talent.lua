local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local C_Talent = C_Talent
local _G = _G
local unpack, pairs, ipairs, select = unpack, pairs, ipairs, select
local hooksecurefunc = hooksecurefunc
local GetGlyphSocketInfo = GetGlyphSocketInfo
local GetTalentTabInfo = GetTalentTabInfo

local GLYPH_ART = [[Interface\AddOns\ElvUI\Core\Media\DragonUI\Glyphs\]]

local TREE_W, TREE_TOP_H, TREE_BOT_H = 256, 256, 53
local TREE_H = TREE_TOP_H + TREE_BOT_H
local TREE_BOT_FILE_H = 128

local panelCorners = {"BackgroundTopLeft", "BackgroundTopRight", "BackgroundBottomLeft", "BackgroundBottomRight"}

local function KillPanelCorners(prefix)
	for _, corner in ipairs(panelCorners) do
		local piece = _G[prefix..corner]
		if piece then
			piece:SetTexture(nil)
			piece.SetTexture = E.noop
		end
	end
end

local function SkinIconHolder(holder, icon)
	holder:StripTextures()
	holder:CreateBackdrop()
	holder.backdrop:SetOutside(icon)
	holder:SetFrameLevel(holder:GetFrameLevel() + 1)

	icon:SetTexCoords()
end

local function LayoutTreeArt(top, bottom, background, boxW, boxH)
	if not (background and boxW and boxH and boxH > 0) then
		top:Hide()
		bottom:Hide()
		return
	end

	local base = [[Interface\TalentFrame\]]..background
	top:SetTexture(base.."-TopLeft")
	bottom:SetTexture(base.."-BottomLeft")

	local boxAspect = boxW / boxH
	local artAspect = TREE_W / TREE_H
	local x0, x1, y0, y1
	if boxAspect < artAspect then
		local stripW = TREE_H * boxAspect
		x0, x1 = (TREE_W - stripW) / 2, (TREE_W + stripW) / 2
		y0, y1 = 0, TREE_H
	else
		local stripH = TREE_W / boxAspect
		x0, x1 = 0, TREE_W
		y0 = (TREE_H - stripH) / 2
		y1 = y0 + stripH
	end

	local windowH = y1 - y0
	local topEnd = y1 < TREE_TOP_H and y1 or TREE_TOP_H
	if topEnd > y0 then
		top:SetHeight(boxH * (topEnd - y0) / windowH)
		top:SetTexCoord(x0 / TREE_W, x1 / TREE_W, y0 / TREE_TOP_H, topEnd / TREE_TOP_H)
		top:Show()
	else
		top:Hide()
	end

	if y1 > TREE_TOP_H then
		local botStart = y0 > TREE_TOP_H and y0 or TREE_TOP_H
		bottom:SetHeight(boxH * (y1 - botStart) / windowH)
		bottom:SetTexCoord(x0 / TREE_W, x1 / TREE_W, (botStart - TREE_TOP_H) / TREE_BOT_FILE_H, (y1 - TREE_TOP_H) / TREE_BOT_FILE_H)
		bottom:Show()
	else
		bottom:Hide()
	end
end

local GLOBE_FRAMES, GLOBE_COLS, GLOBE_FW, GLOBE_STRIDE, GLOBE_SHEET = 67, 11, 350, 352, 4096
local function GlobeCoord(i)
	local col = (i - 1) % GLOBE_COLS
	local row = math.floor((i - 1) / GLOBE_COLS)
	local x, y = col * GLOBE_STRIDE, 1 + row * GLOBE_STRIDE
	return x / GLOBE_SHEET, (x + GLOBE_FW) / GLOBE_SHEET, y / GLOBE_SHEET, (y + GLOBE_FW) / GLOBE_SHEET
end

local function SkinSpecTabs(frame)
	if not frame.specTabs then return end

	for _, tab in ipairs(frame.specTabs) do
		if not tab.isSkinned then
			tab:GetRegions():Hide()
			tab:SetTemplate()
			tab:StyleButton(nil, true)
			tab:GetHighlightTexture().SetTexture = E.noop
			tab:GetCheckedTexture().SetTexture = E.noop
			tab:GetNormalTexture():SetInside()
			tab:GetNormalTexture():SetTexCoords()

			tab.isSkinned = true
		end

		if tab.EtherealBorder and tab.EtherealBorder:IsShown() then
			tab:SetBackdropBorderColor(0.64, 0.19, 0.79)
			tab.EtherealBorder:Hide()
		end
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	local PlayerTalentFrame = _G.PlayerTalentFrame
	S:HandlePortraitFrame(PlayerTalentFrame)

	PlayerTalentFrameTitleGlowLeft:SetAlpha(0)
	PlayerTalentFrameTitleGlowRight:SetAlpha(0)
	PlayerTalentFrameTitleGlowCenter:SetAlpha(0)

	hooksecurefunc(PlayerTalentFrameTitleGlowCenter, "SetTexture", function(_, texture)
		if texture == "Interface\\TalentFrame\\TalentFrame-Horizontal-purple" then
			PlayerTalentFrame:SetBackdropBorderColor(0.64, 0.19, 0.79)
		else
			PlayerTalentFrame:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end)

	if PlayerTalentFrameInset then
		PlayerTalentFrameInset:StripTextures()
	end
	PlayerTalentFrameTalents:StripTextures()

	S:HandleButton(PlayerTalentFrameActivateButton)

	S:HandleButton(PlayerTalentFrameToggleSummariesButton, true)

	local importButton = PlayerTalentFrameImportFrameButton
	if importButton then
		importButton:StripTextures()
		S:HandleButton(importButton)

		local importIcon = importButton:CreateTexture(nil, "ARTWORK")
		importIcon:Size(16)
		importIcon:Point("CENTER")
		importIcon:SetTexture(E.Media.Textures.ArrowUp)
		importIcon:SetRotation(S.ArrowRotation.down)
	end

	local LinkButton = _G.PlayerTalentLinkButton
	LinkButton:SetNormalTexture("")
	LinkButton:SetPushedTexture("")
	LinkButton:GetHighlightTexture():Kill()
	S:HandleButton(LinkButton)
	LinkButton:SetSize(24, 24)
	LinkButton:ClearAllPoints()
	LinkButton:SetPoint("RIGHT", PlayerTalentFrameImportFrameButton, "LEFT", -2, 0)

	local chainIcon = LinkButton:CreateTexture(nil, "ARTWORK")
	chainIcon:SetTexture([[Interface\Buttons\UI-LinkProfession-Up]])
	chainIcon:SetTexCoord(6 / 32, 24 / 32, 12 / 32, 24 / 32)
	chainIcon:Size(18, 12)
	chainIcon:Point("CENTER")

	local function StripTalentFramePanelTextures(object)
		for i = 1, object:GetNumRegions() do
			local region = select(i, object:GetRegions())
			if region:GetObjectType() == "Texture" then
				if region:GetName() and region:GetName():find("Branch") then
					region:SetDrawLayer("OVERLAY")
				else
					region:SetTexture(nil)
				end
			end
		end
	end

	for i = 1, 3 do
		local panel = _G["PlayerTalentFramePanel"..i]
		local summary = _G["PlayerTalentFramePanel"..i.."Summary"]
		local summaryIcon = _G["PlayerTalentFramePanel"..i.."SummaryIcon"]
		local header = _G["PlayerTalentFramePanel"..i.."HeaderIcon"]
		local headerIcon = _G["PlayerTalentFramePanel"..i.."HeaderIconIcon"]
		local headerText = _G["PlayerTalentFramePanel"..i.."HeaderIconPointsSpent"]

		local activeBonus = _G["PlayerTalentFramePanel"..i.."SummaryActiveBonus1"]
		local activeBonusIcon = _G["PlayerTalentFramePanel"..i.."SummaryActiveBonus1Icon"]
		local arrow = _G["PlayerTalentFramePanel"..i.."Arrow"]
		local tab = _G["PlayerTalentFrameTab"..i]

		StripTalentFramePanelTextures(panel)

		panel:CreateBackdrop("Transparent")
		panel.backdrop:Point("TOPLEFT", 4, -4)
		panel.backdrop:Point("BOTTOMRIGHT", -4, 4)

		KillPanelCorners("PlayerTalentFramePanel"..i)

		local artTop = panel:CreateTexture(nil, "BORDER")
		artTop:Point("TOPLEFT", panel.backdrop, 1, -1)
		artTop:Point("TOPRIGHT", panel.backdrop, -1, -1)
		artTop:SetVertexColor(0.9, 0.9, 0.9)

		local artBottom = panel:CreateTexture(nil, "BORDER")
		artBottom:Point("TOPLEFT", artTop, "BOTTOMLEFT")
		artBottom:Point("TOPRIGHT", artTop, "BOTTOMRIGHT")
		artBottom:SetVertexColor(0.9, 0.9, 0.9)

		panel.specArtTop, panel.specArtBottom = artTop, artBottom

		local background = select(4, GetTalentTabInfo(i))
		LayoutTreeArt(artTop, artBottom, background, panel:GetWidth() - 8, panel:GetHeight() - 8)

		summary:StripTextures()
		summary:CreateBackdrop()
		summary:SetFrameLevel(summary:GetFrameLevel() + 2)

		summaryIcon:SetTexCoords()

		SkinIconHolder(header, headerIcon)
		header:Point("TOPLEFT", panel, "TOPLEFT", 4, -4)

		headerIcon:Size(E.PixelMode and 34 or 30)
		headerIcon:Point("TOPLEFT", E.PixelMode and 1 or 4, -(E.PixelMode and 1 or 4))

		headerText:FontTemplate(nil, 13, "OUTLINE")
		headerText:Point("BOTTOMRIGHT", header, "BOTTOMRIGHT", 125, 11)

		SkinIconHolder(activeBonus, activeBonusIcon)

		arrow:SetFrameLevel(arrow:GetFrameLevel() + 2)

		for j = 1, 4 do
			local summaryBonus = _G["PlayerTalentFramePanel"..i.."SummaryBonus"..j]
			local summaryBonusIcon = _G["PlayerTalentFramePanel"..i.."SummaryBonus"..j.."Icon"]

			SkinIconHolder(summaryBonus, summaryBonusIcon)
		end

		S:HandleSirusTab(tab)
	end

	local talentTabs = {}
	for i = 1, 3 do
		talentTabs[i] = _G["PlayerTalentFrameTab"..i]
	end
	S:HandleSirusTabFlow(talentTabs, "PlayerTalentFrame_UpdateTabs")

	hooksecurefunc("PlayerTalentFramePanel_UpdateSummary", function(self)
		if self.Summary then
			if PlayerTalentFrame.primaryTree and self.talentTree == PlayerTalentFrame.primaryTree then
				self.Summary.backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
			else
				self.Summary.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		end
	end)

	local function setHighlightTexture(self, texPath)
		if texPath ~= "" then self:SetHighlightTexture("") end
	end
	local function setPushedTexture(self, texPath)
		if texPath ~= "" then self:SetPushedTexture("") end
	end

	local function TalentButtons(i, j)
		local button = _G["PlayerTalentFramePanel"..i.."Talent"..j]
		button:StripTextures()
		button:CreateBackdrop()
		button:StyleButton()

		hooksecurefunc(button, "SetHighlightTexture", setHighlightTexture)
		button:GetHighlightTexture():SetAllPoints()
		hooksecurefunc(button, "SetPushedTexture", setPushedTexture)
		button:GetPushedTexture():SetAllPoints()
		button:GetPushedTexture():SetTexCoords()
		button:SetNormalTexture("")

		button.icon:SetTexCoords()
		button.icon:SetAllPoints()

		button.Rank:FontTemplate()
	end

	for i = 1, 3 do
		for j = 1, 40 do
			TalentButtons(i, j)
		end
	end

	PlayerTalentFramePanel2SummaryRoleIcon2:Kill()
	PlayerTalentFramePetShadowOverlay:Kill()

	PlayerTalentFrame:HookScript("OnShow", function(self)
		SkinSpecTabs(self)
	end)
	hooksecurefunc("PlayerTalentFrame_UpdateSpecTabs", SkinSpecTabs)

	local offset
	local function UpdatePanelWidth(numTalentGroups)
		if not numTalentGroups then
			numTalentGroups = (C_Talent and C_Talent.GetNumTalentGroups and C_Talent.GetNumTalentGroups()) or 1
		end

		if offset and numTalentGroups <= 1 then
			S:SetUIPanelWindowInfo(PlayerTalentFrame, "width")
			offset = nil
		elseif not offset and numTalentGroups > 1 then
			S:SetUIPanelWindowInfo(PlayerTalentFrame, "width", nil, 31)
			offset = true
		end
	end

	UpdatePanelWidth()

	hooksecurefunc("PlayerTalentFrame_UpdateSpecs", function(_, numTalentGroups)
		UpdatePanelWidth(numTalentGroups)
	end)

	PlayerTalentFramePetTalents:StripTextures()

	PlayerTalentFramePetModel:CreateBackdrop("Transparent")
	PlayerTalentFramePetModel:Height(319)

	PlayerTalentFramePetModelRotateLeftButton:Kill()
	PlayerTalentFramePetModelRotateRightButton:Kill()

	S:HandleButton(PlayerTalentFrameLearnButton, true)
	S:HandleButton(PlayerTalentFrameBackButton, true)
	S:HandleButton(PlayerTalentFrameScreenshotButton, true)
	S:HandleButton(PlayerTalentFrameResetButton, true)
	S:HandleButton(PlayerTalentFrameResetTalentGroupButton, true)

	local specPurchaseButton = PlayerTalentFrameSpecPurchaseButton
	if specPurchaseButton then
		specPurchaseButton:StripTextures()
		specPurchaseButton:SetTemplate("Default")
		specPurchaseButton:StyleButton()

		hooksecurefunc("PlayerTalentFrame_UpdateSpecs", function()
			local button = PlayerTalentFrameSpecPurchaseButton
			local icon = button and (button.icon or button.IconTexture)
			if not icon and button then
				for i = 1, button:GetNumRegions() do
					local region = select(i, button:GetRegions())
					if region:GetObjectType() == "Texture" and region:GetTexture() then
						icon = region
						break
					end
				end
			end
			if icon then
				icon:SetInside()
				icon:SetTexCoords()
			end
		end)
	end

	PlayerTalentFramePetInfo:StripTextures()
	PlayerTalentFramePetInfo:CreateBackdrop()
	PlayerTalentFramePetInfo.backdrop:SetOutside(PlayerTalentFramePetIcon)
	PlayerTalentFramePetInfo:SetFrameLevel(PlayerTalentFramePetInfo:GetFrameLevel() + 1)
	PlayerTalentFramePetInfo:ClearAllPoints()
	PlayerTalentFramePetInfo:Point("BOTTOMLEFT", PlayerTalentFramePetModel, "TOPLEFT", -3, 9)

	PlayerTalentFramePetIcon:SetTexCoords()

	PlayerTalentFramePetDiet:StripTextures()
	PlayerTalentFramePetDiet:CreateBackdrop()
	PlayerTalentFramePetDiet:Point("TOPRIGHT", 2, -2)
	PlayerTalentFramePetDiet:Size(40)

	PlayerTalentFramePetDiet.icon = PlayerTalentFramePetDiet:CreateTexture(nil, "OVERLAY")
	PlayerTalentFramePetDiet.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTraining")
	PlayerTalentFramePetDiet.icon:SetAllPoints()
	PlayerTalentFramePetDiet.icon:SetTexCoords()

	PlayerTalentFramePetTypeText:Point("BOTTOMRIGHT", -45, 10)

	StripTalentFramePanelTextures(PlayerTalentFramePetPanel)

	KillPanelCorners("PlayerTalentFramePetPanel")

	SkinIconHolder(PlayerTalentFramePetPanelHeaderIcon, PlayerTalentFramePetPanelHeaderIconIcon)
	PlayerTalentFramePetPanelHeaderIcon:Point("TOPLEFT", PlayerTalentFramePetPanel, "TOPLEFT", 5, -5)

	PlayerTalentFramePetPanelHeaderIconIcon:Size(E.PixelMode and 46 or 42)
	PlayerTalentFramePetPanelHeaderIconIcon:Point("TOPLEFT", E.PixelMode and 0 or 3, E.PixelMode and 0 or -3)

	local petPoints = select(4, PlayerTalentFramePetPanelHeaderIcon:GetRegions())
	petPoints:FontTemplate(nil, 13, "OUTLINE")
	petPoints:ClearAllPoints()
	petPoints:Point("BOTTOMRIGHT", PlayerTalentFramePetPanelHeaderIcon, "BOTTOMRIGHT", 150, 15)

	PlayerTalentFramePetPanelArrow:SetFrameStrata("HIGH")

	PlayerTalentFramePetPanel:CreateBackdrop("Transparent")
	PlayerTalentFramePetPanel.backdrop:Point("TOPLEFT", 4, -4)
	PlayerTalentFramePetPanel.backdrop:Point("BOTTOMRIGHT", -4, 4)

	PlayerTalentFramePetPanel:HookScript("OnShow", function()
		for i = 1, GetNumTalents(1, false, true) do
			local button = _G["PlayerTalentFramePetPanelTalent"..i]
			local icon = _G["PlayerTalentFramePetPanelTalent"..i.."IconTexture"]
			if not button.isSkinned then

				button:StripTextures()
				button:CreateBackdrop()
				button:StyleButton()
				button:SetFrameLevel(button:GetFrameLevel() + 1)

				button.SetHighlightTexture = E.noop
				button:GetHighlightTexture():SetAllPoints(icon)
				button.SetPushedTexture = E.noop
				local gpt = button:GetPushedTexture()
				if gpt then
					gpt:SetAllPoints(icon)

					button:GetPushedTexture():SetTexCoords()
				end
				local gnt = button:GetNormalTexture()
				if gnt then

					button:GetNormalTexture():SetTexCoords()
				end
				icon:SetTexCoords()
				icon:SetAllPoints()

				if button.Rank then
					button.Rank:FontTemplate(nil, 12, "OUTLINE")
					button.Rank:ClearAllPoints()
					button.Rank:Point("BOTTOMRIGHT", 9, -12)
				end

				button.isSkinned = true
			end
		end
	end)

	PlayerGlyphPreviewFrame:StripTextures()
	PlayerGlyphPreviewFrame:SetTemplate("Transparent")
	PlayerGlyphPreviewFrameHbar:Hide()

	local slots = {
		"MajorSlot1",
		"MajorSlot2",
		"MajorSlot3",
		"MinorSlot1",
		"MinorSlot2",
		"MinorSlot3"
	}

	for i = 1, #slots do
		local slot = PlayerGlyphPreviewFrame[slots[i]]
		slot:CreateBackdrop()
		slot.backdrop:SetOutside(slot.Icon)
		slot.Icon:SetTexCoords()
		slot.NameFrame:SetAlpha(0)
	end

	local glyphGlobes = {}

	local function UpdateGlyphSocket(sock)
		if not sock.Globe then return end

		local talentGroup = _G.PlayerTalentFrame and _G.PlayerTalentFrame.talentGroup
		local enabled, glyphType, glyphSpell = GetGlyphSocketInfo(sock:GetID(), talentGroup)
		if not glyphType then return end

		local major = glyphType == 1
		local base = major and 80 or 66
		sock.Globe:SetTexture(GLYPH_ART..(major and "globe-health" or "globe-mana"))
		sock.Globe:Size(base)
		sock.Shadow:Size(base * 1.9)
		sock.Gloss:Size(base * 1.2)
		sock.GoldRing:Size(major and 118 or 100)

		local lit = (enabled and glyphSpell) and true or false
		sock.Globe:SetDesaturated(not lit)
		sock.Globe:SetAlpha(lit and 1 or 0.45)
		sock.Gloss:SetAlpha(lit and 0.8 or 0.5)
		sock.GoldRing:SetDesaturated(not lit)
		sock.GoldRing:SetAlpha(lit and 1 or 0.7)
	end

	local function UpdateGlyphBackground()
		local GlyphFrame = _G.GlyphFrame
		if not (GlyphFrame and GlyphFrame.treeArtTop) then return end

		local talentGroup = _G.PlayerTalentFrame and _G.PlayerTalentFrame.talentGroup
		local bestPoints, bestBackground = -1, nil
		for i = 1, 3 do
			local _, _, points, background = GetTalentTabInfo(i, nil, nil, talentGroup)
			if (points or 0) > bestPoints then bestPoints, bestBackground = points or 0, background end
		end

		LayoutTreeArt(GlyphFrame.treeArtTop, GlyphFrame.treeArtBottom, bestBackground, GlyphFrame:GetWidth(), GlyphFrame:GetHeight())
	end

	local function SkinGlyphFrame()
		local GlyphFrame = _G.GlyphFrame
		if not GlyphFrame or GlyphFrame.isSkinned then return end

		if not GlyphFrame.requiredLevelFrames then
			GlyphFrame.requiredLevelFrames = {}
			for i = 1, 6 do
				local requiredLevel = GlyphFrame["RequiredLevelGlyph"..i]
				if requiredLevel then GlyphFrame.requiredLevelFrames[i] = requiredLevel end
			end
		end

		if GlyphFrame.glow then GlyphFrame.glow:SetAlpha(0) end
		if GlyphFrame.background then GlyphFrame.background:SetAlpha(0) end

		GlyphFrame:CreateBackdrop("Transparent")

		local treeTop = GlyphFrame:CreateTexture(nil, "BORDER")
		treeTop:Point("TOPLEFT", GlyphFrame.backdrop, 1, -1)
		treeTop:Point("TOPRIGHT", GlyphFrame.backdrop, -1, -1)
		treeTop:SetVertexColor(0.7, 0.7, 0.7)

		local treeBottom = GlyphFrame:CreateTexture(nil, "BORDER")
		treeBottom:Point("TOPLEFT", treeTop, "BOTTOMLEFT")
		treeBottom:Point("TOPRIGHT", treeTop, "BOTTOMRIGHT")
		treeBottom:SetVertexColor(0.7, 0.7, 0.7)

		GlyphFrame.treeArtTop, GlyphFrame.treeArtBottom = treeTop, treeBottom

		local specButton = GlyphFrame.SpecButton
		if specButton then
			if specButton.specRing then specButton.specRing:SetAlpha(0) end
			if specButton.specIcon then
				specButton.specIcon:SetTexCoord(0, 1, 0, 1)
				specButton.specIcon:Size(103)

				local ring = specButton:CreateTexture(nil, "OVERLAY")
				ring:SetTexture(GLYPH_ART.."ring-gold")
				ring:Size(166)
				ring:Point("CENTER", specButton.specIcon, "CENTER", 0, 0)
			end
		end

		for i = 1, 6 do
			local glyph = _G["GlyphFrameGlyph"..i]
			if glyph then
				if glyph.background then glyph.background:SetAlpha(0) end
				if glyph.ring then glyph.ring:SetAlpha(0) end

				glyph.Shadow = glyph:CreateTexture(nil, "BACKGROUND", nil, -2)
				glyph.Shadow:SetTexture(GLYPH_ART.."shadow")
				glyph.Shadow:Point("CENTER")

				glyph.Globe = glyph:CreateTexture(nil, "BACKGROUND", nil, -1)
				glyph.Globe:Point("CENTER")
				glyph.Globe:SetTexCoord(GlobeCoord(1))
				glyphGlobes[#glyphGlobes + 1] = glyph.Globe

				glyph.Gloss = glyph:CreateTexture(nil, "ARTWORK", nil, 3)
				glyph.Gloss:SetTexture(GLYPH_ART.."orbgloss")
				glyph.Gloss:Point("CENTER")

				glyph.GoldRing = glyph:CreateTexture(nil, "OVERLAY")
				glyph.GoldRing:SetTexture(GLYPH_ART.."ring-gold")
				glyph.GoldRing:Point("CENTER")

				UpdateGlyphSocket(glyph)
			end

			local requiredLevel = GlyphFrame["RequiredLevelGlyph"..i]
			if requiredLevel then
				if requiredLevel.levelOverlay then requiredLevel.levelOverlay:SetAlpha(0) end
				if requiredLevel.LevelText then requiredLevel.LevelText:SetTextColor(0.7, 0.7, 0.7) end
			end
		end

		local animElapsed, animIndex = 0, 1
		GlyphFrame:HookScript("OnUpdate", function(_, elapsed)
			animElapsed = animElapsed + elapsed
			if animElapsed < 0.033 then return end
			animElapsed = 0

			animIndex = animIndex % GLOBE_FRAMES + 1
			local l, r, t, b = GlobeCoord(animIndex)
			for k = 1, #glyphGlobes do
				glyphGlobes[k]:SetTexCoord(l, r, t, b)
			end
		end)

		UpdateGlyphBackground()

		GlyphFrame.isSkinned = true
	end

	hooksecurefunc("GlyphFrameGlyph_UpdateSlot", UpdateGlyphSocket)

	hooksecurefunc("PlayerTalentFrame_Update", function()
		for i = 1, 3 do
			local panel = _G["PlayerTalentFramePanel"..i]
			if panel and panel.specArtTop then
				LayoutTreeArt(panel.specArtTop, panel.specArtBottom, select(4, GetTalentTabInfo(i)), panel:GetWidth() - 8, panel:GetHeight() - 8)
			end
		end
	end)

	SkinGlyphFrame()

	hooksecurefunc("PlayerTalentFrame_ShowGlyphFrame", function()
		local frame = _G.GlyphFrame
		if frame then
			if not frame.requiredLevelFrames then
				frame.requiredLevelFrames = {}
			end
			SkinGlyphFrame()
			UpdateGlyphBackground()
		end
	end)

		PlayerTalentPopupFrame:StripTextures()
		PlayerTalentPopupFrame.BG:StripTextures()
		PlayerTalentPopupFrame.BorderBox:StripTextures()

		PlayerTalentPopupFrame.ScrollFrame:StripTextures()

		PlayerTalentPopupFrame:CreateBackdrop("Transparent")
		S:HandleButton(PlayerTalentPopupFrameOkayButton)
		S:HandleButton(PlayerTalentPopupFrameCancelButton)
		S:HandleEditBox(PlayerTalentPopupFrameEditBox)
		S:HandleEditBox(PlayerTalentPopupFrameSearchBox)
		S:HandleSirusScrollBar(PlayerTalentPopupFrameScrollFrameScrollBar)
		for _,v in pairs(PlayerTalentPopupFrame.buttons) do
			v:StripTextures()

			v:StyleButton(nil, true)

			v:SetTemplate("Default", true)
			v.Icon:SetTexCoords()
			v.Icon:SetInside()

		end

end

S:AddCallback("Skin_Talent", LoadSkin)