local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs
local unpack = unpack

local strsub = strsub
local hooksecurefunc = hooksecurefunc
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local UnitGUID = UnitGUID
local C_Timer = C_Timer
local GetTalentTabInfo = GetTalentTabInfo
local GLYPHTYPE_MAJOR = GLYPHTYPE_MAJOR

local Slots = {
	"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
	"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
	"MainHandSlot", "SecondaryHandSlot", "RangedSlot"
}

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
		end
	end

	local styleButton
	local MAX_CACHE_RETRIES = 10
	local inspectGeneration = 0

	local function CancelCacheRetry(button, reset)
		if button.cacheRetryTimer then
			E:CancelTimer(button.cacheRetryTimer)
			button.cacheRetryTimer = nil
		end
		if reset then
			button.cacheRetryCount = 0
			button.cacheRetryGUID, button.cacheRetryLink = nil, nil
		end
	end

	local function ScheduleCacheRetry(button, delay)
		if button.cacheRetryTimer or (button.cacheRetryCount or 0) >= MAX_CACHE_RETRIES then return end
		button.cacheRetryCount = (button.cacheRetryCount or 0) + 1
		local generation, guid, link = inspectGeneration, button.cacheRetryGUID, button.lastLink
		local timer
		timer = E:ScheduleTimer(function()
			if button.cacheRetryTimer ~= timer then return end
			button.cacheRetryTimer = nil
			local unit = InspectFrame.unit
			if generation ~= inspectGeneration or not InspectFrame:IsShown() or not unit
				or UnitGUID(unit) ~= guid or GetInventoryItemLink(unit, button:GetID()) ~= link then return end
			styleButton(button)
		end, delay)
		button.cacheRetryTimer = timer
	end

	styleButton = function(button)
		local unit = InspectFrame.unit
		local guid = unit and UnitGUID(unit)
		if not InspectFrame:IsShown() or not guid then
			CancelCacheRetry(button, true)
			return
		end

		local link = GetInventoryItemLink(unit, button:GetID())
		if button.cacheRetryGUID ~= guid or button.cacheRetryLink ~= link then
			CancelCacheRetry(button, true)
			button.cacheRetryGUID, button.cacheRetryLink = guid, link
		end
		button.lastLink = link

		local slotName = strsub(button:GetName(), 8)
		local dataPending = S:HandleSirusEquipmentSocketInfo(button, button:GetID(), S.EquipmentSlotAnchors[slotName], slotName, unit)
		S:UpdateBlackDiamondHighlight(button, link)

		local quality
		if button.hasItem and link then
			quality = select(3, GetItemInfo(link))
		end
		if button.hasItem and link and not quality then
			ScheduleCacheRetry(button, 0.1)
		elseif dataPending then
			ScheduleCacheRetry(button, 0.5)
		else
			CancelCacheRetry(button, false)
			button.cacheRetryCount = 0
		end

		if quality and quality > 1 then
			button.backdrop:SetBackdropBorderColor(E:GetItemQualityColor(quality))
		else
			button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end

	hooksecurefunc("InspectPaperDollItemSlotButton_Update", styleButton)

	local function RefreshChangedSlots()
		local unit = InspectFrame.unit
		if not unit or not InspectFrame:IsShown() then return end

		for _, slot in ipairs(Slots) do
			local button = _G["Inspect"..slot]
			if GetInventoryItemLink(unit, button:GetID()) ~= button.lastLink then
				InspectPaperDollItemSlotButton_Update(button)
			end
		end
	end

	local refreshTicker
	local function StopInspectData()
		inspectGeneration = inspectGeneration + 1
		if refreshTicker then
			refreshTicker:Cancel()
			refreshTicker = nil
		end
		for _, slot in ipairs(Slots) do
			local button = _G["Inspect"..slot]
			if button then CancelCacheRetry(button, true) end
		end
	end

	local function WatchInspectData()
		StopInspectData()
		if not InspectFrame:IsShown() or not InspectFrame.unit then return end
		for _, slot in ipairs(Slots) do
			local button = _G["Inspect"..slot]
			if button then styleButton(button) end
		end
		refreshTicker = C_Timer:NewTicker(0.2, RefreshChangedSlots, 25)
	end

	hooksecurefunc("InspectFrame_UnitChanged", WatchInspectData)
	InspectFrame:HookScript("OnShow", WatchInspectData)
	InspectFrame:HookScript("OnHide", StopInspectData)

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
				icon:SetInside()
				icon:SetTexCoords()
				icon:SetDrawLayer("ARTWORK")
			end

			if rank then
				rank:SetFont(E.LSM:Fetch("font", E.db.general.font), 12, "OUTLINE")
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
