local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs
local next = next
local select = select
local type = type
local unpack = unpack
local floor = math.floor
local format = string.format
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

local TRACKER_MODULES = {
	"ScenarioObjectiveTracker",
	"QuestObjectiveTracker",
	"AchievementObjectiveTracker",
	"BattlePassQuestTracker",
	"ProfessionsRecipeTracker",
}

local TrackerTextColors = {
	Normal = { 1, 1, 1 },
	NormalHighlight = { 1, 0.80, 0.10 },
	Header = { 1, 0.80, 0.10 },
	HeaderHighlight = { 1, 1, 1 },
	Complete = { 0.60, 0.60, 0.60 },
}

local TrackerTimerColor = { 0.26, 0.42, 1 }

local TrackerModuleColors = {
	AchievementObjectiveTracker = { r = 0.6, g = 0.4, b = 0.9 },
	ProfessionsRecipeTracker = { r = 0.4, g = 0.7, b = 1 },
	BattlePassQuestTracker = { r = 1, g = 0.5, b = 0 },
}

local function ClearTrackerTexture(texture)
	if texture and texture.SetTexture then
		texture:SetTexture(E.ClearTexture)
	end
end

local function ColorTrackerText()
	local colors = _G.OBJECTIVE_TRACKER_COLOR
	if not colors then return end

	for key, color in next, TrackerTextColors do
		local style = colors[key]
		if style then
			style.r, style.g, style.b = color[1], color[2], color[3]
		end
	end
end

local function SetTrackerCollapseTexture(button, collapsed)
	if not button then return end

	local texture = collapsed and E.Media.Textures.Plus or E.Media.Textures.Minus

	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal then
		normal:SetTexture(texture)
		normal:SetTexCoord(0, 1, 0, 1)
		normal:SetInside(button, 0, 0)
	end

	local pushed = button.GetPushedTexture and button:GetPushedTexture()
	if pushed then
		pushed:SetTexture(texture)
		pushed:SetTexCoord(0, 1, 0, 1)
		pushed:SetInside(button, 0, 0)
		pushed:SetVertexColor(0.80, 0.80, 0.80)
	end
end

local function TrackerHeader_SetCollapsed(header, collapsed)
	SetTrackerCollapseTexture(header.MinimizeButton, collapsed)
end

local function SkinTrackerHeader(header, collapsed)
	if not header or header.isSkinned then return end

	ClearTrackerTexture(header.Background)
	ClearTrackerTexture(header.Shine)
	ClearTrackerTexture(header.Glow)

	ColorGold(header.Text)

	local minimize = header.MinimizeButton
	if minimize then
		minimize:Size(16)
		minimize:StyleButton(nil, true, true)

		SetTrackerCollapseTexture(minimize, collapsed)

		if header.SetCollapsed then
			hooksecurefunc(header, "SetCollapsed", TrackerHeader_SetCollapsed)
		end
	end

	local filter = header.FilterButton
	if filter then
		filter:Size(16)
		filter:StyleButton(nil, true, true)

		local normal = filter.NormalTexture
		if normal then
			normal:SetTexture(E.Media.Textures.Filter)
			normal:SetTexCoord(0, 1, 0, 1)
			normal:SetBlendMode("BLEND")
			normal:SetVertexColor(1, 1, 1)
			normal:SetInside(filter, 0, 0)
		end

		local pushed = filter.PushedTexture
		if pushed then
			pushed:SetTexture(E.Media.Textures.Filter)
			pushed:SetTexCoord(0, 1, 0, 1)
			pushed:SetBlendMode("BLEND")
			pushed:SetVertexColor(0.80, 0.80, 0.80)
			pushed:SetInside(filter, 0, 0)
		end

		local highlight = filter.HighlightTexture
		if highlight then
			highlight:SetTexture(E.ClearTexture)
		end
	end

	header.isSkinned = true
end

local function ItemButton_HotKeyShow(hotKey)
	local button = hotKey:GetParent()

	if button and button.rangeOverlay then
		button.rangeOverlay:Show()
	end
end

local function ItemButton_HotKeyHide(hotKey)
	local button = hotKey:GetParent()

	if button and button.rangeOverlay then
		button.rangeOverlay:Hide()
	end
end

local function ItemButton_HotKeyColor(hotKey, r, g, b)
	local button = hotKey:GetParent()
	if not button or not button.rangeOverlay then return end

	if r and g and b and r > 0.90 and g < 0.20 and b < 0.20 then
		button.rangeOverlay:SetVertexColor(0.80, 0.10, 0.10, 0.50)
	else
		button.rangeOverlay:SetVertexColor(0, 0, 0, 0)
	end
end

local function ItemButton_SetUp(button)
	S:UpdateTemplateScale(button)

	local icon = button.icon
	if icon then
		S:HandleIcon(icon)
		icon:SetInside()
	end
end

local function SkinTrackerItemButton(button)
	if not button or button.isSkinned then return end

	button:SetTemplate("Transparent")
	button:StyleButton()
	button:SetNormalTexture(E.ClearTexture)

	ItemButton_SetUp(button)

	if button.SetUp then
		hooksecurefunc(button, "SetUp", ItemButton_SetUp)
	end

	local cooldown = button.Cooldown
	if cooldown then
		cooldown:SetInside()
		E:RegisterCooldown(cooldown)
	end

	local count = button.Count
	if count then
		count:ClearAllPoints()
		count:Point("TOPLEFT", 1, -1)
		count:FontTemplate(nil, 12, "OUTLINE")
	end

	local hotKey = button.HotKey
	if hotKey then
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture(E.Media.Textures.White8x8)
		overlay:SetInside()
		overlay:SetVertexColor(0, 0, 0, 0)

		button.rangeOverlay = overlay

		hooksecurefunc(hotKey, "Show", ItemButton_HotKeyShow)
		hooksecurefunc(hotKey, "Hide", ItemButton_HotKeyHide)
		hooksecurefunc(hotKey, "SetVertexColor", ItemButton_HotKeyColor)

		ItemButton_HotKeyColor(hotKey, hotKey:GetTextColor())
		hotKey:SetAlpha(0)
	end

	button.isSkinned = true
end

local function SkinTrackerBar(bar, color)
	if not bar or bar.isSkinned then return end

	if bar.BarFrame then
		local parent = bar:GetParent()

		bar:ClearAllPoints()
		bar:Point("RIGHT", parent, "RIGHT", 15, 0)
		bar:Size(180, 15)
	end

	S:HandleStatusBar(bar, color, "Transparent")

	bar.isSkinned = true
end

local pendingItemButtons = {}

local function SkinPendingItemButtons()
	E:UnregisterEventForObject("PLAYER_REGEN_ENABLED", SkinPendingItemButtons, SkinPendingItemButtons)

	for button in next, pendingItemButtons do
		pendingItemButtons[button] = nil

		SkinTrackerItemButton(button)
	end
end

local function TrackerItemButton(_, block)
	local button = block and block.ItemButton
	if not button or button.isSkinned then return end

	if InCombatLockdown() then
		pendingItemButtons[button] = true

		E:RegisterEventForObject("PLAYER_REGEN_ENABLED", SkinPendingItemButtons, SkinPendingItemButtons)
	else
		SkinTrackerItemButton(button)
	end
end

local function TrackerProgressBar(module, key)
	local progressBars = module.usedProgressBars
	local progressBar = progressBars and progressBars[key]
	local bar = progressBar and progressBar.Bar
	if not bar then return end

	SkinTrackerBar(bar)

	local _, maxValue = bar:GetMinMaxValues()
	S:StatusBarColorGradient(bar, bar:GetValue(), maxValue)

	local label = bar.Label
	if label then
		label:ClearAllPoints()
		label:Point("CENTER", bar)
	end
end

local function TrackerTimerBar(module, key)
	local timerBars = module.usedTimerBars
	local timerBar = timerBars and timerBars[key]
	local bar = timerBar and timerBar.Bar

	SkinTrackerBar(bar, TrackerTimerColor)
end

local function TrackerBlockHighlight(block)
	local color = not block.isHighlighted and block.diffColor
	if color and block.HeaderText then
		block.HeaderText:SetTextColor(color.r, color.g, color.b)
	end
end

local function ApplyBlockColor(block, color)
	block.diffColor = color

	if not block.diffHooked then
		hooksecurefunc(block, "UpdateHighlight", TrackerBlockHighlight)
		block.diffHooked = true
	end

	if not block.isHighlighted then
		block.HeaderText:SetTextColor(color.r, color.g, color.b)
	end
end

local function TrackerQuestDifficulty(module, index)
	if not module.GetExistingBlock then return end

	local questLogIndex = GetQuestIndexForWatch(index)
	if not questLogIndex then return end

	local title, level, _, _, _, _, _, _, questID = GetQuestLogTitle(questLogIndex)
	if not title or not questID then return end

	local block = module:GetExistingBlock(questID)
	if not block or not block.HeaderText then return end

	ApplyBlockColor(block, GetQuestDifficultyColor(level or 0))
end

local function TrackerBlockColor(module, block)
	if not block or not block.HeaderText then return end

	local name = module.GetName and module:GetName()
	local color = name and TrackerModuleColors[name]
	if not color then return end

	ApplyBlockColor(block, color)
end

local function FormatTrackerCooldown(seconds)
	if not seconds or seconds <= 0 then return end

	local days = floor(seconds / 86400)
	local hours = floor((seconds % 86400) / 3600)
	local minutes = floor((seconds % 3600) / 60)

	if days > 0 then
		return format(L["%d d. %d h."], days, hours)
	elseif hours > 0 then
		return format(L["%d h. %d min."], hours, minutes)
	end

	return format(L["%d min."], minutes)
end

local function TrackerCooldownTick(line, timeLeft, isFinished)
	if isFinished then
		if line.UpdateModule then
			line:UpdateModule()
		end

		return
	end

	local text = FormatTrackerCooldown(timeLeft)
	if text and line.Text then
		line.Text:SetFormattedText("|cffffffff%s|r %s", L["CD:"], text)
	end
end

local function TrackerRecipeCooldown(module, recipeID, isRecraft)
	if type(recipeID) ~= "number" or not module.GetExistingBlock then return end

	local tradeSkill = _G.C_TradeSkillUI
	if not tradeSkill or not tradeSkill.GetRecipeCooldown then return end

	local seconds = tradeSkill.GetRecipeCooldown(recipeID)

	local start, duration = GetSpellCooldown(recipeID)
	if start and duration and start > 0 and duration > 60 then
		local remaining = start + duration - GetTime()
		if remaining > 0 then
			seconds = remaining
		end
	end

	local text = FormatTrackerCooldown(seconds)
	if not text then return end

	local block = module:GetExistingBlock(isRecraft and -recipeID or recipeID)
	if not block or not block.AddObjective or not block.HeaderText then return end

	local lines = block.usedLines
	if lines then
		for key, line in next, lines do
			if block.FreeLine then
				block:FreeLine(line)
			else
				lines[key] = nil
				line:Hide()
			end
		end
	end

	block.lastRegion = block.HeaderText
	block.height = block.HeaderText:GetHeight() or 0

	local colors = _G.OBJECTIVE_TRACKER_COLOR
	local label = format("|cffffffff%s|r %s", L["CD:"], text)
	local line = block:AddObjective("cooldown", label, nil, nil, _G.OBJECTIVE_DASH_STYLE_HIDE, colors and colors.TimeLeft)

	if line then
		if line.Icon then
			line.Icon:Hide()
		end

		if line.SetCountdown then
			line:SetCountdown(seconds, 1, TrackerCooldownTick)
		end
	end

	block:SetHeight(block.height)
end

local function SkinTrackerModule(module)
	if not module or module.isSkinned then return end

	SkinTrackerHeader(module.Header, module.isCollapsed)

	local name = module.GetName and module:GetName()
	local moduleColor = name and TrackerModuleColors[name]
	if moduleColor and module.Header and module.Header.Text then
		module.Header.Text:SetTextColor(moduleColor.r, moduleColor.g, moduleColor.b)
	end

	if module.AddBlock then
		hooksecurefunc(module, "AddBlock", TrackerItemButton)
		hooksecurefunc(module, "AddBlock", TrackerBlockColor)
	end

	if module.GetProgressBar then
		hooksecurefunc(module, "GetProgressBar", TrackerProgressBar)
	end

	if module.GetTimerBar then
		hooksecurefunc(module, "GetTimerBar", TrackerTimerBar)
	end

	module.isSkinned = true
end

local function LoadTrackerSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.quest then return end

	ColorTrackerText()

	local tracker = _G.ObjectiveTrackerFrame
	if not tracker then return end

	local nineSlice = tracker.NineSlice
	if nineSlice then
		nineSlice:StripTextures()
		nineSlice:CreateBackdrop("Transparent")
	end

	local scrollFrame = tracker.ScrollFrame
	if scrollFrame and scrollFrame.ScrollBar then
		S:HandleSirusScrollBar(scrollFrame.ScrollBar)
	end

	SkinTrackerHeader(tracker.Header, tracker.isCollapsed)

	for _, name in ipairs(TRACKER_MODULES) do
		SkinTrackerModule(_G[name])
	end

	local questModule = _G.QuestObjectiveTracker
	if questModule and questModule.UpdateSingle then
		hooksecurefunc(questModule, "UpdateSingle", TrackerQuestDifficulty)
	end

	local recipeModule = _G.ProfessionsRecipeTracker
	if recipeModule and recipeModule.AddRecipe and recipeModule.GetExistingBlock then
		hooksecurefunc(recipeModule, "AddRecipe", TrackerRecipeCooldown)
	end
end

S:AddCallback("Skin_ObjectiveTracker", LoadTrackerSkin)
