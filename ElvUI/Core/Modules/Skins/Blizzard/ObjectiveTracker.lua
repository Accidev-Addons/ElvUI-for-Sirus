local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs
local next = next
local type = type
local floor = math.floor
local format = string.format
local GetQuestLogTitle = GetQuestLogTitle
local GetSpellCooldown = GetSpellCooldown
local GetTime = GetTime
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown

local function ColorGold(text)
	if text then text:SetTextColor(1, 0.80, 0.10) end
end

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

	S:HandleStatusBar(bar, color, "Transparent")

	bar.isSkinned = true
end

local function SkinTrackerAffix(affix)
	local portrait = affix.Portrait
	S:HandleIcon(portrait)

	if affix.isSkinned then return end

	ClearTrackerTexture(affix.Border)

	affix:SetTemplate("Transparent")
	portrait:SetInside()

	affix.isSkinned = true
end

local function TrackerChallengeAffixes(block)
	for affix in next, block.affixPool.activeObjects do
		SkinTrackerAffix(affix)
	end
end

local function SkinTrackerChallengeMode(block)
	if block.isSkinned then return end

	ClearTrackerTexture(block.Timer)

	local statusBar = block.StatusBar
	SkinTrackerBar(statusBar, TrackerTimerColor)

	statusBar.SilverTexture:SetTexture(E.Media.Textures.White8x8)
	statusBar.GoldTexture:SetTexture(E.Media.Textures.White8x8)

	ColorGold(block.Level)

	hooksecurefunc(block, "SetUpAffixes", TrackerChallengeAffixes)

	block.isSkinned = true
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

local function TrackerProgressValue(progressBar)
	local bar = progressBar.Bar
	local _, maxValue = bar:GetMinMaxValues()

	S:StatusBarColorGradient(bar, bar:GetValue(), maxValue)
end

local function TrackerProgressBar(module, key)
	local progressBars = module.usedProgressBars
	local progressBar = progressBars and progressBars[key]
	local bar = progressBar and progressBar.Bar
	if not bar then return end

	SkinTrackerBar(bar)

	local label = bar.Label
	if label then
		label:ClearAllPoints()
		label:Point("CENTER", bar)
	end

	if not progressBar.valueHooked then
		progressBar.valueHooked = true

		if progressBar.SetValue then
			hooksecurefunc(progressBar, "SetValue", TrackerProgressValue)
		end

		if progressBar.SetPercent then
			hooksecurefunc(progressBar, "SetPercent", TrackerProgressValue)
		end
	end

	TrackerProgressValue(progressBar)
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

	if module.ChallengeModeBlock then
		SkinTrackerChallengeMode(module.ChallengeModeBlock)
	end

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
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.objectiveTracker then return end

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
