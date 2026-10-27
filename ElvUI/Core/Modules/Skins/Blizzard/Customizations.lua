local _G = _G
local E = unpack(_G.ElvUI)
local S = E:GetModule('Skins')

local GameTooltip = _G.GameTooltip
local ipairs = ipairs
local select = select
local format = string.format
local hooksecurefunc = _G.hooksecurefunc

local function RefreshButton(button)
	button.Left:SetAlpha(0)
	button.Right:SetAlpha(0)
	button.Center:SetAlpha(0)

	button:SetNormalTexture('')
	button:SetHighlightTexture('')
	button:SetPushedTexture('')
	button:SetDisabledTexture('')

	S:ApplyElvUIFontForce(button)
end

local function ReskinButton(button)
	if not button or not button.IsObjectType or not button:IsObjectType('Button') then return end

	if not button.elvChromeSkinned then
		button.elvChromeSkinned = true

		S:HandleButton(button, true)

		for i = 1, (button:GetNumRegions() or 0) do
			local region = select(i, button:GetRegions())
			if region and region.IsObjectType and region:IsObjectType('Texture') then
				region:SetAlpha(0)
			end
		end

		hooksecurefunc(button, 'UpdateButton', RefreshButton)
	end

	RefreshButton(button)
end

local function UpdateRowBorder(row)
	local backdrop = row and row.backdrop
	if not backdrop then return end

	if row.NineSliceSelection:IsShown() then
		backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	elseif row.NineSliceActive:IsShown() then
		backdrop:SetBackdropBorderColor(0, 1, 0)
	elseif row.NineSliceHighlight:IsShown() then
		backdrop:SetBackdropBorderColor(1, .82, 0)
	else
		backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

local function RowStateChanged(state)
	UpdateRowBorder(state:GetParent())
end

local function HideRowPlate(state)
	if _G.NineSliceUtil and _G.NineSliceUtil.HideLayout then
		_G.NineSliceUtil.HideLayout(state)
	end

	state:SetAlpha(0)
end

local function Trim(value)
	if type(value) ~= 'string' then return value end

	while true do
		local trimmed = value:gsub('%s+$', ''):gsub('|n$', '')
		if trimmed == value then break end

		value = trimmed
	end

	return (value:gsub('^%s+', ''))
end

local function BuildSourceText(row)
	local description = Trim(row.description)
	local sourceText = Trim(row.sourceText)
	local lines = {}

	if description and description ~= '' then
		lines[#lines + 1] = format('|cffffffff%s|r', description)
	end

	if sourceText and sourceText ~= '' then
		lines[#lines + 1] = format('|cffffcc00%s|r', sourceText)
	end

	return #lines > 0 and table.concat(lines, '\n') or nil
end

local function CreatePanel(name, level, width, fontSize)
	local parent = _G.CustomizationsCollectionFrame or _G.UIParent
	local panel = CreateFrame('Frame', name, parent)
	panel:SetFrameStrata('TOOLTIP')
	panel:SetFrameLevel(level)
	panel:SetSize(width, 40)
	panel:SetClampedToScreen(true)
	panel:Hide()

	panel.customBackdropAlpha = .9
	panel:SetTemplate('Transparent')

	panel.text = panel:CreateFontString(nil, 'OVERLAY')
	panel.text:SetJustifyH('LEFT')
	panel.text:SetWordWrap(true)
	panel.text:FontTemplate(nil, fontSize, 'OUTLINE')
	panel.text:SetPoint('TOPLEFT', 8, -8)
	panel.text:SetPoint('TOPRIGHT', -8, -8)

	return panel
end

local sourcePanel
local function GetSourcePanel()
	if not sourcePanel then
		sourcePanel = CreatePanel('ElvUICustomizationsSourcePanel', 700, 380, 12)

		local frame = _G.CustomizationsCollectionFrame
		if frame then
			frame:HookScript('OnHide', function() sourcePanel:Hide() end)
		end
	end

	return sourcePanel
end

local function HideSourceTooltip()
	if sourcePanel then sourcePanel:Hide() end
end

local function ShowSourceTooltip(row, indicator)
	local text = BuildSourceText(row)
	local panel = GetSourcePanel()

	if not text then
		panel:Hide()
		return
	end

	panel.text:SetText(text)
	panel:SetHeight(math.max(24, math.ceil(panel.text:GetStringHeight() or 0) + 16))
	panel:ClearAllPoints()
	panel:SetPoint('TOPRIGHT', indicator, 'TOPLEFT', -8, 2)
	panel:Show()

	if panel:GetLeft() and panel:GetLeft() < 0 then
		panel:ClearAllPoints()
		panel:SetPoint('TOPLEFT', indicator, 'BOTTOMRIGHT', 8, 2)
	end
end

local function StyleSourceIndicator(row)
	local indicator = row and row.SourceIndicator
	if not indicator then return end

	indicator:SetAlpha(1)
	indicator:SetFrameLevel(row:GetFrameLevel() + 20)

	if indicator.Icon then
		indicator.Icon:SetDesaturated(false)
		indicator.Icon:SetVertexColor(1, 1, 1)
		indicator.Icon:SetAlpha(1)
	end

	if indicator.IconHighlight then
		indicator.IconHighlight:SetDesaturated(false)
		indicator.IconHighlight:SetAlpha(.5)
	end
end

local function SkinSourceIndicator(row)
	local indicator = row.SourceIndicator
	if not indicator or indicator.elvSourceSkinned then return end
	indicator.elvSourceSkinned = true

	indicator:EnableMouse(true)
	StyleSourceIndicator(row)

	indicator:HookScript('OnEnter', function(self)
		GameTooltip:Hide()

		ShowSourceTooltip(row, self)
	end)

	indicator:HookScript('OnLeave', HideSourceTooltip)
end

local PLATE_COLLECTED = { 0, 0, 0, .8 }
local PLATE_MISSING = { .22, .22, .22, .9 }
local MISSING_DIM = .65

local function IsRowCollected(row)
	local collection = _G.C_CustomizationsCollection
	local id = row.GetID and row:GetID()
	local count = collection and collection.GetNumCustomizations and collection.GetNumCustomizations()

	if not count or not id or id < 1 or id > count then return end

	return collection.IsCustomizationCollected(id) == true
end

local function GetRowPlate(row)
	local plate = row.elvPlate
	if not plate then
		plate = row:CreateTexture(nil, 'BACKGROUND')
		plate:SetPoint('TOPLEFT', 2, -2)
		plate:SetPoint('BOTTOMRIGHT', -2, 2)
		row.elvPlate = plate
	end

	return plate
end

local function ApplyRowState(row, available)
	if not row.elvCollection then return end

	if available == nil then
		available = IsRowCollected(row)
	end

	if available == nil then return end

	local plate = available and PLATE_COLLECTED or PLATE_MISSING
	GetRowPlate(row):SetTexture(plate[1], plate[2], plate[3], plate[4])

	local color = available and 1 or MISSING_DIM

	row.Icon:SetDesaturated(not available)
	row.Icon:SetVertexColor(color, color, color)

	row.Name:SetAlpha(1)
	row.Name:SetTextColor(color, color, color, 1)

	row.Amount:SetAlpha(1)
	row.Amount:SetTextColor(color, color, color, 1)

	StyleSourceIndicator(row)
end

local function RaiseRowText(row)
	if row.elvTextHolder then return end

	local holder = CreateFrame('Frame', nil, row)
	holder:SetAllPoints(row)
	holder:SetFrameLevel(row:GetFrameLevel() + 30)
	row.elvTextHolder = holder

	row.Name:SetParent(holder)
	row.Amount:SetParent(holder)
end

local function SkinItemRow(row, collection)
	if not row then return end

	row.elvCollection = collection

	if not row.elvStateHooked then
		row.elvStateHooked = true

		hooksecurefunc(row, 'SetAvailable', ApplyRowState)
	end

	if row.elvRowSkinned then return end
	row.elvRowSkinned = true

	row.BackgroundLeft:SetAlpha(0)
	row.BackgroundRight:SetAlpha(0)
	row.BackgroundCenter:SetAlpha(0)
	row.Border:SetAlpha(0)

	row:CreateBackdrop('Transparent', nil, true)
	row.backdrop:Point('TOPLEFT', 2, -2)
	row.backdrop:Point('BOTTOMRIGHT', -2, 2)
	row.backdrop:SetBackdropColor(0, 0, 0, 0)

	for _, state in ipairs({ row.NineSliceHighlight, row.NineSliceSelection, row.NineSliceActive }) do
		HideRowPlate(state)
		state:EnableMouse(false)
		state:HookScript('OnShow', function(self)
			HideRowPlate(self)
			RowStateChanged(self)
		end)
		state:HookScript('OnHide', RowStateChanged)
	end

	UpdateRowBorder(row)

	S:HandleIcon(row.Icon, true)
	if row.Icon.backdrop then
		row.Icon:SetParent(row.Icon.backdrop)
	end

	SkinSourceIndicator(row)

	S:ApplyElvUIFont(row)
	RaiseRowText(row)
end

local function SkinModelRow(row)
	if not row or row.elvRowSkinned then return end
	row.elvRowSkinned = true

	row.Background:SetAlpha(0)

	row:CreateBackdrop('Transparent')
	row.backdrop:Point('TOPLEFT', 8, -8)
	row.backdrop:Point('BOTTOMRIGHT', -8, 8)

	S:ApplyElvUIFont(row)
end

local function SkinCategoryButton(button)
	if not button or button.elvCategorySkinned then return end
	button.elvCategorySkinned = true

	S:ApplyElvUIFont(button)
end

local function SkinCategoryButtons(frame)
	for _, button in ipairs(frame.categoryButtons) do
		SkinCategoryButton(button)
	end
end

local function SkinSubCategoryButtons(frame)
	for _, button in ipairs(frame.subCategoryButtons) do
		SkinCategoryButton(button)
	end
end

local function SkinItemRows(frame)
	local buttons = frame and frame.RightPanel.ItemList.Scroll.buttons
	if not buttons then return end

	local collection = frame == _G.CustomizationsCollectionFrame

	for _, row in ipairs(buttons) do
		SkinItemRow(row, collection)
		ApplyRowState(row)
	end
end

local function SkinModelRows(frame)
	local buttons = frame.RightPanel.ModelList.Scroll.buttons
	if not buttons then return end

	for _, row in ipairs(buttons) do
		SkinModelRow(row)
	end
end

local function ClearFilterHighlight(button)
	button:SetHighlightTexture('')
end

local function SkinFilterRow(frame)
	local editBox = frame.RightPanel.FilterEditBox
	local filterButton = frame.RightPanel.FilterDropdownButton

	S:HandleSirusSearchRow(editBox)

	editBox.BackgroundLeft:SetAlpha(0)
	editBox.BackgroundRight:SetAlpha(0)
	editBox.BackgroundCenter:SetAlpha(0)

	local clearButton = editBox.ClearButton
	if clearButton then
		clearButton:SetHighlightTexture('')
		clearButton:SetPushedTexture('')
		clearButton:SetDisabledTexture('')
	end

	S:ApplyElvUIFont(editBox)

	S:HandleButton(filterButton)
	filterButton:Size(editBox:GetHeight())
	filterButton:HookScript('OnMouseDown', ClearFilterHighlight)
	filterButton:HookScript('OnMouseUp', ClearFilterHighlight)
end

local function SkinStorePanel(frame)
	local top = frame.TopPanel
	if not top then return end

	local balance = top.BalancePanel
	for _, panel in ipairs({ balance.CurrencyBonus, balance.CurrencyVote }) do
		if panel.Divider then panel.Divider:Hide() end

		ReskinButton(panel.Button)
		S:ApplyElvUIFont(panel)
	end

	local rollable = top.RollableInfo
	rollable.Timer:FontTemplate(nil, 16, 'OUTLINE')
	ReskinButton(rollable.RefreshButton)
end

local function SkinScreen(frame)
	if not frame or frame.elvScreenSkinned then return end
	frame.elvScreenSkinned = true

	local bottom = frame.BottomPanel
	bottom.CustomizationName:FontTemplate(nil, 20, 'OUTLINE')

	ReskinButton(bottom.CloseButton)
	ReskinButton(bottom.StoreButton)
	ReskinButton(bottom.ToggleModeButton)
	ReskinButton(bottom.CustomizationActionButton)
	ReskinButton(bottom.SpecialAnimationButton)

	for _, check in ipairs({ bottom.DressStateButton, bottom.WeaponStateButton, bottom.FormStateButton }) do
		S:HandleCheckBox(check)
		S:ApplyElvUIFont(check)

		local native = check.GetFontString and check:GetFontString()
		if native and native ~= check.ButtonText then
			native:SetAlpha(0)
		end
	end

	frame.LeftPanel.SubCategoryPanel.CategoryName:FontTemplate(nil, 16, 'OUTLINE')

	local itemList = frame.RightPanel.ItemList
	itemList.SubCategoryName:FontTemplate(nil, 16, 'OUTLINE')
	S:HandleSirusScrollFrame(itemList.Scroll)

	local modelList = frame.RightPanel.ModelList
	modelList.SubCategoryName:FontTemplate(nil, 16, 'OUTLINE')
	modelList.Background:SetAlpha(0)

	if modelList.NineSlice then modelList.NineSlice:Hide() end

	modelList:CreateBackdrop('Transparent')
	S:HandleSirusScrollFrame(modelList.Scroll)

	SkinFilterRow(frame)
	SkinStorePanel(frame)

	SkinCategoryButtons(frame)
	SkinSubCategoryButtons(frame)
	SkinItemRows(frame)
	SkinModelRows(frame)

	hooksecurefunc(frame, 'UpdateCategories', SkinCategoryButtons)
	hooksecurefunc(frame, 'UpdateSubCategories', SkinSubCategoryButtons)
	hooksecurefunc(frame, 'UpdateCustomizationItemList', SkinItemRows)
	hooksecurefunc(frame, 'UpdateCustomizationModelList', SkinModelRows)
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.customizations then return end

	SkinScreen(_G.CustomizationsCollectionFrame)
	SkinScreen(_G.CustomizationsStoreFrame)
end

S:AddCallback('Skin_Customizations', LoadSkin)
