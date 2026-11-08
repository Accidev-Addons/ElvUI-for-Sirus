local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local LSM = E.Libs.LSM

local _G = _G
local ipairs = ipairs
local unpack = unpack

local strsub = strsub
local hooksecurefunc = hooksecurefunc
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemTexture = GetInventoryItemTexture
local GetItemInfo = GetItemInfo
local C_Timer = C_Timer
local GetTalentTabInfo = GetTalentTabInfo
local GLYPHTYPE_MAJOR = GLYPHTYPE_MAJOR

local Slots = {
	"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
	"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
	"MainHandSlot", "SecondaryHandSlot", "RangedSlot"
}

local itemLevelExcluded = { ShirtSlot = true, TabardSlot = true }

local function UpdateItemLevel(button, quality, itemLevel)
	local text = button.ItemLevel
	if not text then return end

	local db = E.db.general.characterInfo
	text:ClearAllPoints()
	text:SetPoint(db.itemLevelPosition, button, db.itemLevelXOffset, db.itemLevelYOffset)
	text:FontTemplate(LSM:Fetch("font", db.font), db.fontSize, db.fontOutline)

	if db.showItemLevel and itemLevel then
		if db.itemLevelQualityColor and quality then
			text:SetTextColor(E:GetItemQualityColor(quality))
		else
			text:SetTextColor(1, 1, 1)
		end
		text:SetText(itemLevel)
	else
		text:SetText("")
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.inspect then return end

	S:HandleSirusFrame(InspectFrame)

	S:HandleSirusTabs("InspectFrameTab", 5)

	InspectPaperDollFrame:StripTextures()

	InspectModelFrame:CreateBackdrop()
	InspectModelFrame.backdrop:SetOutside(InspectModelFrameBackgroundOverlay)
	InspectModelFrame:DisableDrawLayer("OVERLAY")
	InspectItemLevelFrame.ilvlbackground:SetAlpha(0)
	InspectItemLevelFrame:Point("BOTTOM", InspectModelFrame, "BOTTOM", 0, 40)

	if InspectPaperDollFrame.ViewButton then
		S:HandleButton(InspectPaperDollFrame.ViewButton)
	end

	for _, slot in ipairs(Slots) do
		local frame = _G["Inspect" .. slot]
		if frame then
			frame:StripTextures()
			frame:OffsetFrameLevel(2)
			frame:CreateBackdrop("Default")
			frame.backdrop:SetAllPoints()
			frame:StyleButton()

			local icon = _G["Inspect" .. slot .. "IconTexture"]
			if icon then
				icon:SetTexCoords()
				icon:SetInside()
			end

			if not itemLevelExcluded[slot] then
				frame.ItemLevel = frame:CreateFontString(nil, "OVERLAY")
			end
		end
	end

	local styleButton
	do
		local MAX_SOCKET_RETRIES = 20

		local function awaitCache(button)
			button.awaitingCache = nil

			if InspectFrame.unit then
				styleButton(button)
			end
		end

		styleButton = function(button)
			local slotName = strsub(button:GetName(), 8)
			if InspectFrame.unit then
				button.lastLink = GetInventoryItemLink(InspectFrame.unit, button:GetID())

				if S:HandleSirusEquipmentSocketInfo(button, button:GetID(), S.EquipmentSlotAnchors[slotName], slotName, InspectFrame.unit) then
					S:RetrySocketInfo(button, MAX_SOCKET_RETRIES, 0.5, function()
						if not InspectFrame.unit then return false end

						return S:HandleSirusEquipmentSocketInfo(button, button:GetID(), S.EquipmentSlotAnchors[slotName], slotName, InspectFrame.unit)
					end)
				end
			end

			S:UpdateBlackDiamondHighlight(button, InspectFrame.unit and button.lastLink)

			local quality, itemLevel, _
			if button.hasItem and button.lastLink then
				_, _, quality, itemLevel = GetItemInfo(button.lastLink)
				if not quality and not button.awaitingCache then
					button.awaitingCache = true
					E:Delay(0.1, awaitCache, button)
				end
			end

			if quality and quality > 1 then
				button.backdrop:SetBackdropBorderColor(E:GetItemQualityColor(quality))
			else
				button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end

			S:UpdateEquipmentGradient(button, slotName, quality)
			UpdateItemLevel(button, quality, itemLevel)
		end
	end

	S.UpdateInspectEquipment = function()
		if not InspectFrame:IsShown() then return end

		for _, slot in ipairs(Slots) do
			styleButton(_G["Inspect"..slot])
		end
		S:UpdateModelBackground(InspectModelFrame, InspectFrame.unit)
	end

	hooksecurefunc("InspectPaperDollItemSlotButton_Update", styleButton)

	local function RefreshChangedSlots()
		local unit = InspectFrame.unit
		if not unit or not InspectFrame:IsShown() then return end

		for _, slot in ipairs(Slots) do
			local button = _G["Inspect"..slot]
			local slotID = button:GetID()
			local texture = GetInventoryItemTexture(unit, slotID)

			if GetInventoryItemLink(unit, slotID) ~= button.lastLink or (texture and texture ~= button.lastTexture) then
				button.lastTexture = texture

				if not S.socketRetries[button] then
					InspectPaperDollItemSlotButton_Update(button)
				end
			end
		end
	end

	local refreshTicker
	local function WatchInspectData()
		if refreshTicker then refreshTicker:Cancel() end

		for _, slot in ipairs(Slots) do
			local button = _G["Inspect"..slot]
			button.lastTexture = nil
			S:ResetSocketRetry(button)
		end

		refreshTicker = C_Timer:NewTicker(0.2, RefreshChangedSlots, 50)
	end

	hooksecurefunc("InspectFrame_UnitChanged", WatchInspectData)
	InspectFrame:HookScript("OnShow", WatchInspectData)
	hooksecurefunc("SetPaperDollBackground", function(model, unit)
		if model == InspectModelFrame then
			S:UpdateModelBackground(model, unit)
		end
	end)

	if InspectModelFrameControlFrameRotateLeftButton then
		S:HandleRotateButton(InspectModelFrameControlFrameRotateLeftButton)
	end
	if InspectModelFrameControlFrameRotateRightButton then
		S:HandleRotateButton(InspectModelFrameControlFrameRotateRightButton)
	end

	InspectPVPFrame:StripTextures()

	S:HandleSirusTabs("InspectPVPFrameTab", 3)
	S:HandleButton(InspectPVPFrame.ToggleStatisticsButton)

	local pvpService = InspectPVPFrame.Service
	local pvpRating = InspectPVPFrame.Rating

	for _, subFrame in next, { pvpService, pvpRating, InspectPVPFrame.Statistics } do
		if subFrame and subFrame.Inset then
			subFrame.Inset:StripTextures()
			subFrame.Inset:CreateBackdrop("Transparent")
			subFrame.Inset.backdrop:SetAllPoints()
		end
	end

	if pvpService and pvpService.Container and pvpService.Container.LaurelBackground then
		pvpService.Container.LaurelBackground:Hide()
	end

	if pvpRating and pvpRating.Container then
		for _, key in next, { "Background", "Divider" } do
			local object = pvpRating.Container[key]
			if object then object:Hide() end
		end
	end

	local statsScrollFrame = InspectBattlegroundStatisticsScrollFrame
	if statsScrollFrame then
		statsScrollFrame:StripTextures()
		statsScrollFrame:CreateBackdrop("Transparent")
		statsScrollFrame.backdrop:Point("TOPLEFT", 1, -1)
		statsScrollFrame.backdrop:Point("BOTTOMRIGHT", -8, 1)
		S:HandleSirusScrollBar(InspectBattlegroundStatisticsScrollFrameScrollBar)
	end

	statsScrollFrame:HookScript("OnShow", function(frame)
		for _, button in ipairs(frame.buttons) do
			if not button.isSkinned then
				button:SetTemplate("Transparent")

				button.Background:SetDrawLayer("BORDER")
				button.Background:SetInside()
				button.Background:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 1, 1, 1, 1)
				for _, region in next, { button:GetRegions() } do
					if region:IsObjectType("FontString") then
						region:SetDrawLayer("ARTWORK")
					end
				end

				S:HandleSirusToggle(button.TogglePlus, E.Media.Textures.Plus)
				S:HandleSirusToggle(button.ToggleMinus, E.Media.Textures.Minus)

				button.isSkinned = true
			end
		end
	end)

	local ladder = InspectPVPFrame.Ladder
	if ladder then
		if ladder.CentralContainer then
			ladder.CentralContainer:StripTextures()
			ladder.CentralContainer:CreateBackdrop("Transparent")
			ladder.CentralContainer.backdrop:Point("TOPLEFT", 2, -2)
			ladder.CentralContainer.backdrop:Point("BOTTOMRIGHT", -2, 2)
		end

		local scrollFrame = ladder.CentralContainer.ScrollFrame
		scrollFrame.ShadowOverlay:StripTextures()
		S:HandleSirusScrollBar(scrollFrame.ScrollBar)

		hooksecurefunc(ladder, "InitializeScrollFrame", function()
			S:ApplyElvUIFont(scrollFrame.ScrollChild)
		end)

		for i = 1, 4 do
			local tab = ladder["RightTab"..i]
			tab:GetRegions():Hide()
			tab:SetTemplate()
			tab:StyleButton(nil, true)
			tab.Icon:SetTexCoord(unpack(E.TexCoords))
			tab.Icon:SetInside()
		end

		if ladder.TopContainer and ladder.TopContainer.StatisticsFrame then
			ladder.TopContainer.StatisticsFrame:StripTextures()
			ladder.TopContainer.StatisticsFrame:CreateBackdrop("Transparent")
			ladder.TopContainer.StatisticsFrame.backdrop:Point("TOPLEFT", 3, -3)
			ladder.TopContainer.StatisticsFrame.backdrop:Point("BOTTOMRIGHT", -3, 3)
			S:ApplyElvUIFont(ladder.TopContainer)
		end
	end

	for i = 1, MAX_ARENA_TEAMS do
		local frame = _G["InspectPVPTeam" .. i]
		if frame then
			frame:StripTextures()
			frame:CreateBackdrop("Transparent")
			frame.backdrop:Point("TOPLEFT", 9, -6)
			frame.backdrop:Point("BOTTOMRIGHT", -24, -5)
			S:SetBackdropHitRect(frame)
		end
	end

	InspectTalentFrame:StripTextures()
	for i = 1, MAX_TALENT_TABS do
		local headerTab = _G["InspectTalentFrameTab" .. i]
		if headerTab then
			headerTab:StripTextures()
			headerTab:CreateBackdrop("Default", true)
			headerTab.backdrop:Point("TOPLEFT", 2, -7)
			headerTab.backdrop:Point("BOTTOMRIGHT", 1, -1)
			S:SetBackdropHitRect(headerTab)

			headerTab:HookScript("OnEnter", S.SetModifiedBackdrop)
			headerTab:HookScript("OnLeave", S.SetOriginalBackdrop)
		end
	end

	for i = 1, MAX_NUM_TALENTS do
		local talent = _G["InspectTalentFrameTalent" .. i]
		if talent then
			local icon = _G["InspectTalentFrameTalent" .. i .. "IconTexture"]
			local rank = _G["InspectTalentFrameTalent" .. i .. "Rank"]

			talent:StripTextures()
			talent:SetTemplate("Default")
			talent:StyleButton()

			if icon then
				icon:SetDrawLayer("ARTWORK")
				S:StyleTalentIcon(talent, icon)
			end

			if talent.RankBorder then talent.RankBorder:SetAlpha(0) end

			if rank then
				rank:ClearAllPoints()
				rank:Point("CENTER", talent, "BOTTOMRIGHT", -3, 3)
				rank:FontTemplate()
			end
		end
	end

	InspectTalentFrameScrollFrame:StripTextures()
	InspectTalentFrameScrollFrame:CreateBackdrop("Transparent")
	InspectTalentFrameScrollFrame.backdrop:Point("TOPLEFT", -1, 1)
	InspectTalentFrameScrollFrame.backdrop:Point("BOTTOMRIGHT", 5, -4)
	S:HandleSirusScrollBar(InspectTalentFrameScrollFrameScrollBar)

	InspectTalentFramePointsBar:StripTextures()

	local glyphFrame = _G.InspectGlyphFrame
	glyphFrame:StripTextures()
	glyphFrame:CreateBackdrop("Transparent")
	glyphFrame.backdrop:SetAllPoints(glyphFrame.background)
	S:CreateGlyphTreeArt(glyphFrame)

	local function UpdateGlyphSocket(glyph)
		S:UpdateGlyphSocket(glyph, glyph.glyphType == GLYPHTYPE_MAJOR, glyph.spell ~= nil, 0.79)
	end

	local glyphGlobes = {}
	for i = 1, 6 do
		local glyph = _G["InspectGlyphFrameGlyph"..i]
		S:HandleGlyphSocket(glyph, glyphGlobes)
		hooksecurefunc(glyph, "UpdateSlot", UpdateGlyphSocket)
		UpdateGlyphSocket(glyph)
	end
	S:AnimateGlyphGlobes(glyphFrame, glyphGlobes)

	hooksecurefunc(glyphFrame, "UpdateGlyphs", function()
		local bestPoints, bestBackground = 0, nil
		for i = 1, 3 do
			local _, _, points, background = GetTalentTabInfo(i, true, nil, InspectTalentFrame.talentGroup)
			if (points or 0) > bestPoints then bestPoints, bestBackground = points, background end
		end

		S:LayoutGlyphTreeArt(glyphFrame, bestBackground, glyphFrame.background:GetWidth() - 2, glyphFrame.background:GetHeight() - 2)
	end)

	if InspectGuildFrame then
		local guildBG = _G.InspectGuildFrameBG
		if guildBG then guildBG:SetTexture() end
	end

	hooksecurefunc("InspectGuildFrame_Update", function()
		local emblem = _G.InspectGuildFrameEmblem
		if emblem then
			emblem:SetTexture("Interface\\GuildFrame\\GuildEmblemsLG_01")
			emblem:Show()
		end
	end)
end

S:AddCallback("Skin_Inspect", LoadSkin)
