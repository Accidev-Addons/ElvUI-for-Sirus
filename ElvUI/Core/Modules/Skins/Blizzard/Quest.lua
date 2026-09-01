local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs
local next = next
local select = select
local type = type
local unpack = unpack
local gsub = string.gsub
local GetItemInfo = GetItemInfo
local GetMoney = GetMoney
local GetQuestItemLink = GetQuestItemLink
local GetQuestLogItemLink = GetQuestLogItemLink
local GetQuestLogRequiredMoney = GetQuestLogRequiredMoney
local GetQuestLogTitle = GetQuestLogTitle
local GetQuestMoneyToGet = GetQuestMoneyToGet
local GetSpellCooldown = GetSpellCooldown
local GetTime = GetTime
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown

local MAX_NUM_ITEMS = MAX_NUM_ITEMS or 10
local MAX_NUM_QUESTS = MAX_NUM_QUESTS or 32
local MAX_OBJECTIVES = MAX_OBJECTIVES or 10
local MAX_REPUTATIONS = MAX_REPUTATIONS or 10
local MAX_REQUIRED_ITEMS = MAX_REQUIRED_ITEMS or 6

local ITEM_WIDTH, ITEM_HEIGHT = 143, 40

local QuestTextColors = {
	["000000"] = "ffffff",
	["414141"] = "7b8489",
}

local requiredMoneyText

local function ColorWhite(text)
	if text then text:SetTextColor(1, 1, 1) end
end

local function ColorGold(text)
	if text then text:SetTextColor(1, 0.80, 0.10) end
end

local function ColorGrey(text)
	if text then text:SetTextColor(0.6, 0.6, 0.6) end
end

local function ColorMoney(text, required)
	if not text or not required or required <= 0 then return end

	if required > GetMoney() then
		ColorGrey(text)
	else
		ColorGold(text)
	end
end

local function GetRequiredMoneyText()
	if requiredMoneyText then return requiredMoneyText end

	local frame = _G.QuestInfoRequiredMoneyFrame
	if frame and frame.GetRegions then
		for _, region in next, { frame:GetRegions() } do
			if region and region.GetObjectType and region:GetObjectType() == "FontString" then
				requiredMoneyText = region
				break
			end
		end
	end

	if not requiredMoneyText then
		requiredMoneyText = _G.QuestInfoRequiredMoneyText
	end

	return requiredMoneyText
end

local function Quest_ReplaceColor(color)
	return "|cFF"..(QuestTextColors[color] or color)
end

local function Quest_SetFormattedText(button, textFormat, text, skip)
	if skip or not textFormat or not text or text == "" then return end

	local colorText, colorCount = gsub(textFormat, "|c[fF][fF](%x%x%x%x%x%x)", Quest_ReplaceColor)
	if colorCount > 0 then
		button:SetFormattedText(colorText, text, true)
	end
end

local function Quest_SetText(button, text)
	if not text or text == "" then return end

	local colorText, colorCount = gsub(text, "|c[fF][fF](%x%x%x%x%x%x)", Quest_ReplaceColor)
	if colorCount > 0 then
		button:SetFormattedText("%s", colorText, true)
	end
end

local function SkinInset(inset)
	if not inset or inset.isSkinned then return end

	inset:StripTextures()
	inset:SetTemplate("Transparent")

	inset.isSkinned = true
end

local function SkinScrollChild(child)
	if child then child:StripTextures() end
end

local function SkinQuestItem(item)
	if not item or item.isSkinned then return end

	local name = item.GetName and item:GetName()
	local icon = item.Icon or (name and _G[name.."IconTexture"])
	local count = item.Count or (name and _G[name.."Count"])

	item:StripTextures()
	item:SetTemplate("Default")
	item:StyleButton()
	item:Size(ITEM_WIDTH, ITEM_HEIGHT)
	item:OffsetFrameLevel(2)

	if icon then
		icon:Size(E.PixelMode and 38 or 32)
		icon:SetDrawLayer("OVERLAY")
		icon:Point("TOPLEFT", E.PixelMode and 1 or 4, -(E.PixelMode and 1 or 4))
		S:HandleIcon(icon)
	end

	if count then
		count:SetParent(item)
		count:SetDrawLayer("OVERLAY")
	end

	item.isSkinned = true
end

local function QuestQualityColors(frame, text, link)
	if not frame or not frame.SetBackdropBorderColor then return end

	S:UpdateTemplateScale(frame)

	local quality = link and select(3, GetItemInfo(link))

	if quality and quality > 1 then
		local r, g, b = E:GetItemQualityColor(quality)

		frame:SetBackdropBorderColor(r, g, b)
		if text then text:SetTextColor(r, g, b) end
	else
		frame:SetBackdropBorderColor(unpack(E.media.bordercolor))
		ColorWhite(text)
	end
end

local function FixItemLayout(prefix, numItems)
	for i = 1, numItems do
		local item = _G[prefix..i]

		if item and item:IsShown() then
			item:Size(ITEM_WIDTH, ITEM_HEIGHT)

			local icon = item.Icon or _G[prefix..i.."IconTexture"]
			if icon then
				icon:Size(E.PixelMode and 38 or 32)
				icon:Point("TOPLEFT", E.PixelMode and 1 or 4, -(E.PixelMode and 1 or 4))
			end

			local point, relativeTo, relativePoint, _, y = item:GetPoint()
			if point and relativePoint == "TOPRIGHT" then
				item:Point(point, relativeTo, relativePoint, 4, y)
			end
		end
	end
end

local function StackItemCount(count)
	if not count then return end

	local text = count:GetText()
	if not text then return end

	local stacked, replaced = gsub(text, " / ", "\n")
	if replaced > 0 then
		count:SetText(stacked)
	end
end

local function ColorObjectives()
	for i = 1, MAX_OBJECTIVES do
		local objective = _G["QuestInfoObjective"..i]

		if objective and objective:IsShown() then
			local r = objective:GetTextColor()

			if r > 0.15 and r < 0.3 then
				ColorGold(objective)
			elseif r < 0.1 then
				ColorGrey(objective)
			end
		end
	end
end

local function ColorRequiredItems()
	for i = 1, MAX_OBJECTIVES do
		local item = _G["QuestRequiredItem"..i]

		if item and item:IsShown() then
			QuestQualityColors(item, _G["QuestRequiredItem"..i.."Name"], item.hyperlink)
			StackItemCount(_G["QuestRequiredItem"..i.."Count"])
		end
	end
end

local function ColorRewardItems(skip)
	local questLog = _G.QuestInfoFrame and _G.QuestInfoFrame.questLog
	local getLink = (questLog and GetQuestLogItemLink) or GetQuestItemLink

	for i = 1, MAX_NUM_ITEMS do
		local item = _G["QuestInfoItem"..i]

		if item and item ~= skip then
			local link = item.type and getLink and getLink(item.type, item:GetID())

			QuestQualityColors(item, _G["QuestInfoItem"..i.."Name"], link)
		end
	end
end

local function UpdateCollapseIcon(button)
	if not button or not button.GetNormalTexture then return end

	local normal = button:GetNormalTexture()
	if not normal then return end

	local pushed = button.GetPushedTexture and button:GetPushedTexture()
	local index = button.GetID and button:GetID()
	local isHeader, isCollapsed

	if index and index > 0 then
		isHeader, isCollapsed = select(5, GetQuestLogTitle(index))
	end

	if isHeader then
		local texture = isCollapsed and E.Media.Textures.Plus or E.Media.Textures.Minus

		normal:SetTexture(texture)
		if pushed then pushed:SetTexture(texture) end
	else
		normal:SetTexture(0, 0, 0, 0)
		if pushed then pushed:SetTexture(0, 0, 0, 0) end
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.quest then return end

	if QuestLogFrame then
		S:HandleSirusFrame(QuestLogFrame)
		S:SetUIPanelWindowInfo(QuestLogFrame, "width")

		SkinInset(QuestLogFrame.InsetLeft or _G.QuestLogFrameInsetLeft)
		SkinInset(QuestLogFrame.InsetRight or _G.QuestLogFrameInsetRight)
	end

	if QuestLogCount then
		QuestLogCount:StripTextures()
		QuestLogCount:CreateBackdrop("Transparent")

		hooksecurefunc("QuestLog_UpdateQuestCount", function()
			local point, relativeTo, relativePoint, _, y = QuestLogCount:GetPoint()
			if point then
				QuestLogCount:Point(point, relativeTo, relativePoint, 12, y)
			end
		end)
	end

	if EmptyQuestLogFrame then EmptyQuestLogFrame:StripTextures() end
	if QuestLogNoQuestsText then ColorWhite(QuestLogNoQuestsText) end

	S:HandleSirusScrollFrame(QuestLogScrollFrame)

	if QuestLogDetailScrollFrame then QuestLogDetailScrollFrame:StripTextures() end
	SkinScrollChild(QuestLogDetailScrollChildFrame)

	local function RefreshQuestLogDetail()
		local bar = QuestLogDetailScrollFrame and (QuestLogDetailScrollFrame.ScrollBar or QuestLogDetailScrollFrameScrollBar)
		if bar then
			S:HandleSirusScrollBar(bar)
		end

		S:UpdateTemplateScale(QuestLogFrameAbandonButton)
		S:UpdateTemplateScale(QuestLogFrameTrackButton)
		S:UpdateTemplateScale(QuestLogFramePushQuestButton)
		S:UpdateTemplateScale(QuestLogFrameCancelButton)
	end
	RefreshQuestLogDetail()

	if QuestLogFrame then QuestLogFrame:HookScript("OnShow", RefreshQuestLogDetail) end
	if QuestLogDetailFrame then QuestLogDetailFrame:HookScript("OnShow", RefreshQuestLogDetail) end

	if QuestLogFrameShowMapButton then
		QuestLogFrameShowMapButton:StripTextures()
		S:HandleButton(QuestLogFrameShowMapButton)

		local text = QuestLogFrameShowMapButton.text
		if text then
			text:ClearAllPoints()
			text:SetPoint("CENTER")
			QuestLogFrameShowMapButton:Size(text:GetWidth() + 32, 22)
		end
	end

	S:HandleSirusButton(QuestLogFrameAbandonButton)
	S:HandleSirusButton(QuestLogFrameTrackButton)
	S:HandleSirusButton(QuestLogFramePushQuestButton)
	S:HandleSirusButton(QuestLogFrameCancelButton)

	if QuestLogSkillHighlight then
		QuestLogSkillHighlight:SetTexture(E.Media.Textures.Highlight)
		QuestLogSkillHighlight:SetAlpha(0.35)
	end

	if QuestLogScrollFrame and QuestLogScrollFrame.buttons then
		for _, questLogTitle in ipairs(QuestLogScrollFrame.buttons) do
			if not questLogTitle.isSkinned then
				questLogTitle.SetNormalAtlas = E.noop
				questLogTitle.SetPushedAtlas = E.noop
				S:HandleCollapseExpandButton(questLogTitle, "+")
			end

			UpdateCollapseIcon(questLogTitle)
		end

		hooksecurefunc("QuestLogTitleButton_Resize", UpdateCollapseIcon)
	end

	if QuestLogDetailFrame then
		S:HandleSirusFrame(QuestLogDetailFrame)
		S:SetUIPanelWindowInfo(QuestLogDetailFrame, "width")

		SkinInset(QuestLogDetailFrame.Inset or _G.QuestLogDetailFrameInset)
	end

	if QuestFrame then
		S:HandleSirusFrame(QuestFrame)
		S:SetUIPanelWindowInfo(QuestFrame, "width")

		SkinInset(QuestFrame.Inset or _G.QuestFrameInset)
	end

	for _, panel in next, { QuestFrameDetailPanel, QuestFrameProgressPanel, QuestFrameRewardPanel, QuestFrameGreetingPanel } do
		if panel then
			panel:StripTextures(true)
		end
	end

	S:HandleSirusButton(QuestFrameAcceptButton)
	S:HandleSirusButton(QuestFrameCompleteButton)
	S:HandleSirusButton(QuestFrameCompleteQuestButton)
	S:HandleSirusButton(QuestFrameDeclineButton)
	S:HandleSirusButton(QuestFrameGoodbyeButton)
	S:HandleSirusButton(QuestFrameCancelButton)
	S:HandleSirusButton(QuestFrameGreetingGoodbyeButton, true)

	S:HandleSirusScrollFrame(QuestDetailScrollFrame)
	S:HandleSirusScrollFrame(QuestProgressScrollFrame)
	S:HandleSirusScrollFrame(QuestRewardScrollFrame)
	S:HandleSirusScrollFrame(QuestGreetingScrollFrame)

	SkinScrollChild(QuestDetailScrollChildFrame)
	SkinScrollChild(QuestProgressScrollChildFrame)
	SkinScrollChild(QuestRewardScrollChildFrame)
	SkinScrollChild(QuestGreetingScrollChildFrame)

	if QuestGreetingFrameHorizontalBreak then
		QuestGreetingFrameHorizontalBreak:Kill()
	end

	if GreetingText then
		ColorWhite(GreetingText)
		GreetingText.SetTextColor = E.noop
	end

	if CurrentQuestsText then
		ColorGold(CurrentQuestsText)
		CurrentQuestsText.SetTextColor = E.noop
	end

	if AvailableQuestsText then
		ColorGold(AvailableQuestsText)
		AvailableQuestsText.SetTextColor = E.noop
	end

	for i = 1, MAX_NUM_QUESTS do
		local button = _G["QuestTitleButton"..i]

		if button and not button.isSkinned then
			S:HandleButtonHighlight(button)

			local fontString = button:GetFontString()
			if fontString then
				ColorWhite(fontString)

				Quest_SetText(button, button:GetText())
				hooksecurefunc(button, "SetText", Quest_SetText)
				hooksecurefunc(button, "SetFormattedText", Quest_SetFormattedText)
			end

			button.isSkinned = true
		end
	end

	if QuestInfoItemHighlight then QuestInfoItemHighlight:StripTextures() end

	ColorWhite(QuestInfoTimerText)
	ColorWhite(QuestInfoAnchor)

	for i = 1, MAX_NUM_ITEMS do
		SkinQuestItem(_G["QuestInfoItem"..i])
	end

	for i = 1, MAX_REQUIRED_ITEMS do
		SkinQuestItem(_G["QuestProgressItem"..i])
	end

	for i = 1, MAX_OBJECTIVES do
		SkinQuestItem(_G["QuestRequiredItem"..i])
	end

	hooksecurefunc("QuestFrameProgressItems_Update", function()
		ColorGold(QuestProgressTitleText)
		ColorWhite(QuestProgressText)
		ColorGold(QuestProgressRequiredItemsText)
		ColorMoney(QuestProgressRequiredMoneyText, GetQuestMoneyToGet())

		for i = 1, MAX_REQUIRED_ITEMS do
			local item = _G["QuestProgressItem"..i]

			if item then
				local link = item.type and GetQuestItemLink(item.type, item:GetID())

				QuestQualityColors(item, _G["QuestProgressItem"..i.."Name"], link)
			end
		end

		FixItemLayout("QuestProgressItem", MAX_REQUIRED_ITEMS)
	end)

	hooksecurefunc("QuestInfoItem_OnClick", function(frame)
		if frame.type ~= "choice" then return end

		S:UpdateTemplateScale(frame)
		frame:SetBackdropBorderColor(1, 0.80, 0.10)
		ColorGold(_G[frame:GetName().."Name"])

		ColorRewardItems(frame)
	end)

	hooksecurefunc("QuestInfo_Display", function()
		ColorGold(QuestInfoTitleHeader)
		ColorGold(QuestInfoDescriptionHeader)
		ColorGold(QuestInfoObjectivesHeader)
		ColorGold(QuestInfoRewardsHeader)

		ColorWhite(QuestInfoDescriptionText)
		ColorWhite(QuestInfoObjectivesText)
		ColorWhite(QuestInfoGroupSize)
		ColorWhite(QuestInfoRewardText)
		ColorWhite(QuestInfoTimerText)
		ColorWhite(QuestInfoAnchor)

		ColorWhite(QuestInfoItemChooseText)
		ColorWhite(QuestInfoItemReceiveText)
		ColorWhite(QuestInfoSpellLearnText)
		ColorWhite(QuestInfoHonorFrameReceiveText)
		ColorWhite(QuestInfoArenaPointsFrameReceiveText)
		ColorWhite(QuestInfoTalentFrameReceiveText)
		ColorWhite(QuestInfoXPFrameReceiveText)
		ColorWhite(_G.QuestInfoPlayerTitleFrameReceiveText)
		ColorWhite(QuestInfoReputationText)

		for i = 1, MAX_REPUTATIONS do
			ColorWhite(_G["QuestInfoReputation"..i.."Faction"])
		end

		ColorMoney(GetRequiredMoneyText(), GetQuestLogRequiredMoney())

		ColorObjectives()
		ColorRequiredItems()
		ColorRewardItems()

		FixItemLayout("QuestInfoItem", MAX_NUM_ITEMS)
		FixItemLayout("QuestRequiredItem", MAX_OBJECTIVES)
	end)

	hooksecurefunc("QuestInfo_ShowRewards", function()
		ColorRewardItems()

		FixItemLayout("QuestInfoItem", MAX_NUM_ITEMS)
	end)

	hooksecurefunc("QuestInfo_ShowObjectives", function()
		ColorObjectives()
		ColorRequiredItems()

		FixItemLayout("QuestRequiredItem", MAX_OBJECTIVES)
	end)

	hooksecurefunc("QuestInfo_ShowRequiredMoney", function()
		ColorMoney(GetRequiredMoneyText(), GetQuestLogRequiredMoney())
	end)
end

S:AddCallback("Skin_Quest", LoadSkin)
