local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs
local unpack = unpack

local GetInventoryItemID = GetInventoryItemID
local GetItemInfo = GetItemInfo

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
	do
		local function awaitCache(button)
			if InspectFrame.unit then
				styleButton(button)
			end
		end

		styleButton = function(button)
			if button.hasItem then
				local itemID = GetInventoryItemID(InspectFrame.unit, button:GetID())
				if itemID then
					local _, _, quality = GetItemInfo(itemID)
					if not quality and quality > 1 then
						E:Delay(0.1, awaitCache, button)
						return
					elseif quality and quality > 1 then
						button.backdrop:SetBackdropBorderColor(E:GetItemQualityColor(quality))
						return
					end
				end
			end

			button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end

	hooksecurefunc("InspectPaperDollItemSlotButton_Update", styleButton)

	if InspectModelFrameControlFrameRotateLeftButton then
		S:HandleRotateButton(InspectModelFrameControlFrameRotateLeftButton)
	end
	if InspectModelFrameControlFrameRotateRightButton then
		S:HandleRotateButton(InspectModelFrameControlFrameRotateRightButton)
	end

	InspectPVPFrame:StripTextures()

	S:HandleSirusTabs("InspectPVPFrameTab", 3)

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

	hooksecurefunc("InspectBattlegroundStatisticsScrollFrame_OnShow", function()
		if not statsScrollFrame or not statsScrollFrame.buttons then return end

		for _, button in ipairs(statsScrollFrame.buttons) do
			if not button.isSkinned then
				button:StripTextures()
				button:CreateBackdrop("Default")
				button.backdrop:Point("TOPLEFT", 1, -1)
				button.backdrop:Point("BOTTOMRIGHT", -1, 1)

				for i = 1, 10 do
					local statFrame = button["StatFrame" .. i]
					if statFrame then statFrame:StripTextures() end
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

		if ladder.ScrollFrame then
			ladder.ScrollFrame:StripTextures()
			S:HandleSirusScrollBar(ladder.ScrollFrame.ScrollBar)
		end

		if ladder.TopContainer and ladder.TopContainer.StatisticsFrame then
			ladder.TopContainer.StatisticsFrame:StripTextures()
			ladder.TopContainer.StatisticsFrame:CreateBackdrop("Transparent")
			ladder.TopContainer.StatisticsFrame.backdrop:Point("TOPLEFT", 3, -3)
			ladder.TopContainer.StatisticsFrame.backdrop:Point("BOTTOMRIGHT", -3, 3)
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

	if InspectGlyphFrame then
		InspectGlyphFrame:StripTextures()

		for i = 1, 6 do
			local glyph = _G["InspectGlyphFrameGlyph" .. i]
			if glyph then
				glyph:StripTextures()
				glyph:CreateBackdrop("Default")
				glyph.backdrop:SetAllPoints()
				glyph:StyleButton()

				if glyph.glyph then
					glyph.glyph:SetTexCoords()
					glyph.glyph:SetInside()
					glyph.glyph:SetDrawLayer("ARTWORK")
				end
			end
		end
	end

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
