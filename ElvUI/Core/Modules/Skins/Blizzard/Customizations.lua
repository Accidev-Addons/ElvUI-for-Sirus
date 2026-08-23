local _G = _G
local E = unpack(_G.ElvUI)
local S = E:GetModule('Skins')

local ipairs = ipairs
local select = select
local hooksecurefunc = _G.hooksecurefunc

local chromeMethods = {
	'SetThreeSliceAtlas',
	'SetNormalAtlas',
	'SetHighlightAtlas',
	'SetPushedAtlas',
	'SetDisabledAtlas',
	'UpdateButton',
}

local function ClearChrome(button)
	if button.Left then button.Left:SetAlpha(0) end
	if button.Right then button.Right:SetAlpha(0) end
	if button.Center then button.Center:SetAlpha(0) end
	if button.Glow then button.Glow:Hide() end

	if button.SetNormalTexture then button:SetNormalTexture('') end
	if button.SetHighlightTexture then button:SetHighlightTexture('') end
	if button.SetPushedTexture then button:SetPushedTexture('') end
	if button.SetDisabledTexture then button:SetDisabledTexture('') end
end

local function ChromeOnShow(button)
	ClearChrome(button)
	S:ApplyElvUIFontForce(button)
end

local function ReskinButton(button)
	if not button or not button.IsObjectType or not button:IsObjectType('Button') then return end

	if not button.elvChromeSkinned then
		button.elvChromeSkinned = true

		for i = 1, (button:GetNumRegions() or 0) do
			local region = select(i, button:GetRegions())
			if region and region.IsObjectType and region:IsObjectType('Texture') then
				region:SetTexture()
				region:SetAlpha(0)
			end
		end

		S:HandleButton(button, true)

		for _, method in ipairs(chromeMethods) do
			if button[method] then
				hooksecurefunc(button, method, ClearChrome)
			end
		end

		button:HookScript('OnShow', ChromeOnShow)
	end

	ClearChrome(button)
	S:ApplyElvUIFontForce(button)
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

local function SkinItemRow(row)
	if not row or row.elvRowSkinned then return end
	row.elvRowSkinned = true

	row.BackgroundLeft:SetAlpha(0)
	row.BackgroundRight:SetAlpha(0)
	row.BackgroundCenter:SetAlpha(0)
	row.Border:SetAlpha(0)

	row:CreateBackdrop('Transparent')
	row.backdrop:Point('TOPLEFT', 2, -2)
	row.backdrop:Point('BOTTOMRIGHT', -2, 2)

	for _, state in ipairs({ row.NineSliceHighlight, row.NineSliceSelection, row.NineSliceActive }) do
		state:SetAlpha(0)
		state:HookScript('OnShow', RowStateChanged)
		state:HookScript('OnHide', RowStateChanged)
	end

	UpdateRowBorder(row)

	S:HandleIcon(row.Icon, true)
	if row.Icon.backdrop then
		row.Icon:SetParent(row.Icon.backdrop)
	end

	S:ApplyElvUIFont(row)
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
	local buttons = frame.RightPanel.ItemList.Scroll.buttons
	if not buttons then return end

	for _, row in ipairs(buttons) do
		SkinItemRow(row)
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
