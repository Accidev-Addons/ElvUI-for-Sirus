local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight

local function GetStoreFrameScale()
	local parentScale = UIParent and UIParent:GetScale() or 1
	if parentScale > 0 and parentScale < 0.7 and (GetScreenWidth() >= 2560 or GetScreenHeight() >= 1440) then
		return 0.75
	end

	return parentScale
end

local function NormalizePKBTTextColors(frame)
	if not frame or not frame.GetObjectType then return end

	local objectType = frame:GetObjectType()
	if (objectType == "FontString" or objectType == "SimpleHTML") and frame.GetTextColor and frame.SetTextColor then
		local r, g, b = frame:GetTextColor()
		if r and g and b then

			local luminance = r * 0.3 + g * 0.6 + b * 0.1

			local mutedWarm = r > b and g >= 0.8 * r and b >= 0.7 * g
			if luminance < 0.4 or mutedWarm then
				frame:SetTextColor(1, 1, 1)
			end
		end
	end

	if frame.GetNumRegions then
		for i = 1, frame:GetNumRegions() do
			local region = select(i, frame:GetRegions())
			if region then NormalizePKBTTextColors(region) end
		end
	end

	if frame.GetNumChildren then
		for i = 1, frame:GetNumChildren() do
			local child = select(i, frame:GetChildren())
			if child then NormalizePKBTTextColors(child) end
		end
	end
end

local function ClearPKBTChrome(b)
	if not b then return end
	if b.Left then b.Left:SetAlpha(0) end
	if b.Right then b.Right:SetAlpha(0) end
	if b.Center then b.Center:SetAlpha(0) end
	if b.LeftHighlight then b.LeftHighlight:SetAlpha(0) end
	if b.RightHighlight then b.RightHighlight:SetAlpha(0) end
	if b.CenterHighlight then b.CenterHighlight:SetAlpha(0) end
	if b.SetNormalTexture then b:SetNormalTexture("") end
	if b.SetHighlightTexture then b:SetHighlightTexture("") end
	if b.SetPushedTexture then b:SetPushedTexture("") end
	if b.SetDisabledTexture then b:SetDisabledTexture("") end
	if b.Glow then b.Glow:Hide() end
end

local function HookClearPKBTChrome(btn)
	if btn._Elv_ClearHooks then return end
	btn._Elv_ClearHooks = true

	for _, method in ipairs({
		"SetThreeSliceAtlas", "SetNormalAtlas", "SetHighlightAtlas", "SetPushedAtlas",
		"SetCheckedAtlas", "SetDisabledAtlas", "UpdateButton",
	}) do
		if btn[method] then
			hooksecurefunc(btn, method, function(self) ClearPKBTChrome(self) end)
		end
	end

	btn:HookScript("OnShow", function(self)
		ClearPKBTChrome(self)
		S:ApplyElvUIFontForce(self)
	end)
end

local function ReskinPKBTButton(btn)
	if not btn or not btn.IsObjectType or not btn:IsObjectType("Button") then return end

	if not btn._Elv_BaseSkinned then

		for i = 1, (btn:GetNumRegions() or 0) do
			local r = select(i, btn:GetRegions())
			if r and r.IsObjectType and r:IsObjectType("Texture") then
				r:SetTexture()
				r:SetAlpha(0)
			end
		end

		S:HandleButton(btn, true)
		btn._Elv_BaseSkinned = true
	end

	ClearPKBTChrome(btn)

	S:ApplyElvUIFontForce(btn)

	HookClearPKBTChrome(btn)
end

local function SkinStoreCategoryButton(btn)
	if not btn or not btn.IsObjectType or not btn:IsObjectType("Button") then return end
	if btn._ElvCategorySkinned then return end
	btn._ElvCategorySkinned = true

	S:HandleButton(btn, false)
	ClearPKBTChrome(btn)
	S:ApplyElvUIFont(btn)
	HookClearPKBTChrome(btn)

	if btn.Icon then
		btn.Icon:SetTexCoord(unpack(E.TexCoords))
	end
	if btn.ButtonText then

		btn.ButtonText:FontTemplate(nil, nil, "OUTLINE")
	end
	if btn.NewIcon then btn.NewIcon:Hide() end
end

local function SkinStoreSubCategoryButton(btn)
	if not btn or not btn.IsObjectType or not btn:IsObjectType("Button") then return end
	if btn._ElvSubCategorySkinned then return end
	btn._ElvSubCategorySkinned = true

	S:HandleButton(btn, false)
	ClearPKBTChrome(btn)
	S:ApplyElvUIFont(btn)
	HookClearPKBTChrome(btn)

	if btn.ButtonText then

		btn.ButtonText:FontTemplate(nil, nil, "OUTLINE")
	end
	if btn.NewIcon then btn.NewIcon:Hide() end
end

local function SkinStoreBagButton(btn)
	if not btn or not btn.IsObjectType or not btn:IsObjectType("CheckButton") then return end
	if btn._ElvBagSkinned then return end
	btn._ElvBagSkinned = true

	local function clearChrome(b)
		if b.SetPushedTexture then b:SetPushedTexture("") end
		if b.SetDisabledTexture then b:SetDisabledTexture("") end
		if b.SetHighlightTexture then b:SetHighlightTexture("") end
		if b.SetCheckedTexture then b:SetCheckedTexture("") end
		if b.SetDisabledCheckedTexture then b:SetDisabledCheckedTexture("") end
	end

	clearChrome(btn)

	if not btn._ElvBagHooked then
		btn._ElvBagHooked = true
		for _, method in ipairs({ "SetPushedAtlas", "SetDisabledAtlas", "SetHighlightAtlas", "SetCheckedAtlas", "SetDisabledCheckedAtlas" }) do
			if btn[method] then
				hooksecurefunc(btn, method, function(self) clearChrome(self) end)
			end
		end
	end
end

local function SkinStoreTabButton(btn)
	if not btn or not btn.IsObjectType or not btn:IsObjectType("Button") then return end

	local function clearChrome(b)
		if b.Left then b.Left:SetAlpha(0) end
		if b.Center then b.Center:SetAlpha(0) end
		if b.Right then b.Right:SetAlpha(0) end
		if b.LeftHighlight then b.LeftHighlight:SetAlpha(0) end
		if b.RightHighlight then b.RightHighlight:SetAlpha(0) end
		if b.CenterHighlight then b.CenterHighlight:SetAlpha(0) end
		if b.SetNormalTexture then b:SetNormalTexture("") end
		if b.SetHighlightTexture then b:SetHighlightTexture("") end
		if b.SetPushedTexture then b:SetPushedTexture("") end
		if b.SetDisabledTexture then b:SetDisabledTexture("") end
	end

	S:HandleButton(btn, false)
	clearChrome(btn)
	S:ApplyElvUIFont(btn)

	if not btn._Elv_TabHooked then
		btn._Elv_TabHooked = true
		if btn.SetThreeSliceAtlas then
			hooksecurefunc(btn, "SetThreeSliceAtlas", function(self) clearChrome(self) end)
		end
		if btn.SetNormalAtlas then
			hooksecurefunc(btn, "SetNormalAtlas", function(self) clearChrome(self) end)
		end
		if btn.SetHighlightAtlas then
			hooksecurefunc(btn, "SetHighlightAtlas", function(self) clearChrome(self) end)
		end
		if btn.SetPushedAtlas then
			hooksecurefunc(btn, "SetPushedAtlas", function(self) clearChrome(self) end)
		end
		btn:HookScript("OnShow", function(self)
			clearChrome(self)
			S:ApplyElvUIFont(self)
		end)
	end
end

local function SkinStoreRowButton(row)
	if not row then return end
	if row._ElvRowSkinned then return end
	row._ElvRowSkinned = true

	if row.BackgroundLeft then row.BackgroundLeft:SetAlpha(0) end
	if row.BackgroundRight then row.BackgroundRight:SetAlpha(0) end
	if row.BackgroundCenter then row.BackgroundCenter:SetAlpha(0) end
	if row.NineSliceSelection then row.NineSliceSelection:Hide() end
	if row.NineSliceHighlight then row.NineSliceHighlight:Hide() end

	row:CreateBackdrop("Transparent")

	local ht = (row.GetHighlightTexture and row:GetHighlightTexture()) or row.HighlightTexture
	if not ht then
		ht = row:CreateTexture(nil, "HIGHLIGHT")
		ht:SetAllPoints(row)
		row:SetHighlightTexture(ht)
	end
	ht:SetTexture(E.Media.Textures.Highlight)
	ht:SetTexCoord(0, 1, 0, 1)
	ht:SetVertexColor(1, 1, 1, 0.25)

	S:ApplyElvUIFont(row)

	for i = 1, (row:GetNumChildren() or 0) do
		local child = select(i, row:GetChildren())
		if child then
			S:ApplyElvUIFont(child)
			if child.Icon then
				S:HandleIcon(child.Icon)
				child.Icon:SetTexCoord(unpack(E.TexCoords))
			end
			if child.Border then child.Border:SetAlpha(0) end
			if child.IconBorder then child.IconBorder:SetAlpha(0) end
			if child.Price then child.Price:StripTextures() end
		end
	end
end

local function SkinStoreFilterEditBox(editbox)
	if not editbox or not editbox.IsObjectType or not editbox:IsObjectType("EditBox") then return end
	if editbox._ElvFilterEditBoxSkinned then return end
	editbox._ElvFilterEditBoxSkinned = true

	S:HandleEditBox(editbox)

	if editbox.BackgroundLeft then editbox.BackgroundLeft:SetAlpha(0) end
	if editbox.BackgroundRight then editbox.BackgroundRight:SetAlpha(0) end
	if editbox.BackgroundCenter then editbox.BackgroundCenter:SetAlpha(0) end

	if editbox.ClearButton then
		if editbox.ClearButton.SetHighlightTexture then editbox.ClearButton:SetHighlightTexture("") end
		if editbox.ClearButton.SetPushedTexture then editbox.ClearButton:SetPushedTexture("") end
		if editbox.ClearButton.SetDisabledTexture then editbox.ClearButton:SetDisabledTexture("") end
	end

	S:ApplyElvUIFont(editbox)
end

local function SkinStoreList(view)
	if not view then return end

	local list = view.List
	if list then
		if not list._ElvSkinned then
			list._ElvSkinned = true
			list:StripTextures(true)
			list:CreateBackdrop("Transparent")
		end
		if list.Scroll then
			if list.Scroll.ScrollBar then
				S:HandleSirusScrollBar(list.Scroll.ScrollBar)
			end
			for _, row in ipairs(list.Scroll.buttons or {}) do
				SkinStoreRowButton(row)
			end
		end
		S:ApplyElvUIFont(list)
	end

	local filter = view.Filter
	if filter then
		if not filter._ElvSkinned then
			filter._ElvSkinned = true
			filter:StripTextures(true)

			if filter.NineSliceInset then filter.NineSliceInset:Hide() end
			filter:CreateBackdrop("Transparent")
		end
		if filter.Scroll then

			if filter.Scroll.ScrollBar then
				S:HandleSirusScrollBar(filter.Scroll.ScrollBar)
			end
			local scrollChild = filter.Scroll.ScrollChild
			if scrollChild then
				if scrollChild.ResetButton then ReskinPKBTButton(scrollChild.ResetButton) end
				for i = 1, (scrollChild:GetNumChildren() or 0) do
					local child = select(i, scrollChild:GetChildren())
					if child then
						if child.IsObjectType and child:IsObjectType("CheckButton") then
							S:HandleCheckBox(child)
						elseif child.IsObjectType and child:IsObjectType("EditBox") then
							SkinStoreFilterEditBox(child)
						end
						S:ApplyElvUIFont(child)
					end
				end
			end
		end
		S:ApplyElvUIFont(filter)
	end

	local header = view.PageHeader
	if header then
		if not header._ElvSkinned then
			header._ElvSkinned = true
			header:StripTextures(true)
			header:CreateBackdrop("Transparent")
		end
		if header.RefreshButton then ReskinPKBTButton(header.RefreshButton) end
		if header.Title then header.Title:FontTemplate(nil, 18, "OUTLINE") end
		S:ApplyElvUIFont(header)
	end
end

local function SkinStoreDialog(dialog)
	if not dialog or not dialog.IsObjectType or not dialog:IsObjectType("Frame") then return end
	if dialog._ElvDialogSkinned then return end
	dialog._ElvDialogSkinned = true

	dialog:StripTextures(true)

	if dialog.NineSlice then dialog.NineSlice:Hide() end
	if dialog.Background then dialog.Background:SetAlpha(0) end
	if dialog.VignetteTopLeft then dialog.VignetteTopLeft:SetAlpha(0) end
	if dialog.VignetteTopRight then dialog.VignetteTopRight:SetAlpha(0) end
	if dialog.VignetteBottomLeft then dialog.VignetteBottomLeft:SetAlpha(0) end
	if dialog.VignetteBottomRight then dialog.VignetteBottomRight:SetAlpha(0) end

	if dialog.TitleContainer then
		dialog.TitleContainer:StripTextures(true)
		if dialog.TitleContainer.TitleText then
			dialog.TitleContainer.TitleText:FontTemplate(nil, 18, "OUTLINE")
			dialog.TitleContainer.TitleText:SetTextColor(unpack(E.media.rgbvaluecolor))
		end
	end

	if dialog.CloseButton then S:HandleCloseButton(dialog.CloseButton) end

	dialog:SetTemplate("Transparent")

	for _, key in ipairs({ "PurchaseButton", "BuyButton", "ActionButton", "AgreeButton", "InviteButton", "InfoButton", "OkButton", "CancelButton", "AcceptButton", "BackButton", "DetailsButton" }) do
		local btn = dialog[key]

		if btn then ReskinPKBTButton(btn) end
	end

	S:ApplyElvUIFont(dialog)
	NormalizePKBTTextColors(dialog)

	if not dialog._ElvDialogHooked then
		dialog._ElvDialogHooked = true
		dialog:HookScript("OnShow", function(self)
			NormalizePKBTTextColors(self)
		end)
	end
end

local function HandleStoreFrame()
	local f = _G.StoreFrame
	if not f then return end

	if not f._ElvMainSkinned then
		f._ElvMainSkinned = true

		f:StripTextures(true)
		if f.NineSlice then f.NineSlice:Hide() end
		if f.DecorOverlay then f.DecorOverlay:Hide() end
		if f.TopTileStreaks then f.TopTileStreaks:SetAlpha(0) end

		f:CreateBackdrop("Transparent")

		if f.CloseButton then S:HandleCloseButton(f.CloseButton) end

		if f.TitleContainer then
			f.TitleContainer:StripTextures(true)
			if f.TitleContainer.TitleText then
				f.TitleContainer.TitleText:FontTemplate(nil, 20, "OUTLINE")
				f.TitleContainer.TitleText:SetTextColor(unpack(E.media.rgbvaluecolor))
			end
		end
	end

	local top = f.TopPanel
	if top then
		if not top._ElvSkinned then
			top._ElvSkinned = true
			top:StripTextures(true)
			top:CreateBackdrop("Transparent")
		end

		if top.AccountPanel then
			local portrait = top.AccountPanel.PortraitContainer
			if portrait and portrait.Ring then
				portrait.Ring:SetAlpha(0)
			end
			S:ApplyElvUIFont(top.AccountPanel)
		end

		for _, panel in ipairs({ top.BalancePanel, top.VotePanel }) do
			if panel then
				if panel.Divider then panel.Divider:Hide() end
				if panel.Button then ReskinPKBTButton(panel.Button) end
				if panel.BrowseButton then SkinStoreBagButton(panel.BrowseButton) end
				S:ApplyElvUIFont(panel)
			end
		end

		for _, panel in ipairs({ top.LoyalityPanel, top.ReferralPanel }) do
			if panel then
				if panel.Divider then panel.Divider:Hide() end
				if panel.StatusBar then S:HandleStatusBar(panel.StatusBar) end
				if panel.BrowseButton then SkinStoreBagButton(panel.BrowseButton) end
				if panel.AddButton then ReskinPKBTButton(panel.AddButton) end
				S:ApplyElvUIFont(panel)
			end
		end
	end

	local left = f.LeftPanel
	if left then
		if left.NavPanel then
			local nav = left.NavPanel
			if not nav._ElvSkinned then
				nav._ElvSkinned = true
				nav:StripTextures(true)

				if nav.NineSliceInset then nav.NineSliceInset:Hide() end
				nav:CreateBackdrop("Transparent")
			end
			S:ApplyElvUIFont(nav)
		end

		if left.PremiumPanel then
			local premium = left.PremiumPanel
			if not premium._ElvSkinned then
				premium._ElvSkinned = true
				premium:StripTextures(true)
				if premium.NineSliceInset then premium.NineSliceInset:Hide() end
				premium:CreateBackdrop("Transparent")
			end
			if premium.Purchase then ReskinPKBTButton(premium.Purchase) end
		end

		if left.SubscriptionTracker then
			local tracker = left.SubscriptionTracker
			if not tracker._ElvSkinned then
				tracker._ElvSkinned = true
				tracker:StripTextures(true)
				tracker:CreateBackdrop("Transparent")
			end
			if tracker.Artwork then tracker.Artwork:Hide() end
			if tracker.ActionButton then ReskinPKBTButton(tracker.ActionButton) end
			S:ApplyElvUIFont(tracker)
		end
	end

	local content = f.Content
	if content then
		if not content._ElvSkinned then
			content._ElvSkinned = true
			content:StripTextures(true)
			if content.NineSliceInset then content.NineSliceInset:Hide() end
			content:CreateBackdrop("Transparent")
		end
		S:ApplyElvUIFont(content)
	end

	for _, dialog in ipairs({ f.LinkDialog, f.AgreementDialog, f.ReferralInviteDialog, f.PremiumPurchaseDialog, f.ProductPurchaseDialogSecondary }) do
		SkinStoreDialog(dialog)
	end

	if f.dialogFramePool then
		for dialog in f.dialogFramePool:EnumerateActive() do
			SkinStoreDialog(dialog)
		end
	end

	local promo = _G.PromoCodeFrame
	if promo and not promo._ElvSkinned then
		promo._ElvSkinned = true
		promo:StripTextures(true)
		if promo.NineSlice then promo.NineSlice:Hide() end
		if promo.Background then promo.Background:SetAlpha(0) end
		promo:SetTemplate("Transparent")
		if promo.CloseButton then S:HandleCloseButton(promo.CloseButton) end
		if promo.Content then
			if promo.Content.Code and promo.Content.Code.EditBox then
				S:HandleEditBox(promo.Content.Code.EditBox)
			end
			if promo.Content.ActionButton then ReskinPKBTButton(promo.Content.ActionButton) end
			if promo.Content.Scroll and promo.Content.Scroll.ScrollBar then
				S:HandleSirusScrollBar(promo.Content.Scroll.ScrollBar)
			end
			S:ApplyElvUIFont(promo.Content)
			NormalizePKBTTextColors(promo)
		end
	end

	NormalizePKBTTextColors(f)
end

local function HookStore()

	local storeFrame = _G.StoreFrame
	if storeFrame then
		if not S._Elv_StoreInstanceHooked then
			S._Elv_StoreInstanceHooked = true

			hooksecurefunc(storeFrame, "UpdateCategoryButtons", function(self)
				for _, button in ipairs(self.categoryButtons or {}) do
					SkinStoreCategoryButton(button)
				end
			end)

			hooksecurefunc(storeFrame, "ShowDialogWidget", function(self, widgetType, parent, preShowCallback)
				local dialog = self:GetDialogWidget(widgetType)
				if dialog then SkinStoreDialog(dialog) end
			end)

			hooksecurefunc(storeFrame, "ShowGenericDialog", function(self)
				if self.dialogFramePool then
					for dialog in self.dialogFramePool:EnumerateActive() do
						SkinStoreDialog(dialog)
					end
				end
			end)
		end

		local itemListView = storeFrame.ItemListView
		if itemListView and not S._Elv_StoreListViewHooked then
			S._Elv_StoreListViewHooked = true

			local function SkinListView(self)
				SkinStoreList(self)
			end

			hooksecurefunc(itemListView, "UpdateViewTable", SkinListView)
			hooksecurefunc(itemListView, "OnItemScrollUpdate", SkinListView)
			hooksecurefunc(itemListView, "OnShow", SkinListView)

			hooksecurefunc(itemListView, "UpdateFilters", SkinListView)
		end

		local pageCollections = storeFrame.Content and storeFrame.Content.PageCollections
		if pageCollections and not S._Elv_StoreTabsHooked then
			S._Elv_StoreTabsHooked = true
			hooksecurefunc(pageCollections, "UpdateTabs", function(self)
				for _, btn in pairs(self.tabButtons or {}) do
					if btn then SkinStoreTabButton(btn) end
				end
			end)
		end

		local specialOffer = storeFrame.Content and storeFrame.Content.PageMain and storeFrame.Content.PageMain.SpecialPanel and storeFrame.Content.PageMain.SpecialPanel.Banner and storeFrame.Content.PageMain.SpecialPanel.Banner.Offer
		if specialOffer and not S._Elv_StoreSpecialOfferHooked then
			S._Elv_StoreSpecialOfferHooked = true
			hooksecurefunc(specialOffer, "OnShow", function(self)
				if self.PurchaseButton then ReskinPKBTButton(self.PurchaseButton) end
				if self.DetailsButton then ReskinPKBTButton(self.DetailsButton) end
				if self.ActionButton then ReskinPKBTButton(self.ActionButton) end
			end)
		end

		local refundView = storeFrame.RefundView
		if refundView and not S._Elv_StoreRefundHooked then
			S._Elv_StoreRefundHooked = true
			hooksecurefunc(refundView, "OnShow", function(self)
				if self.RefundButton then ReskinPKBTButton(self.RefundButton) end
				if self.Scroll then
					for _, row in ipairs(self.Scroll.buttons or {}) do
						if not row._ElvRefundRowSkinned then
							row._ElvRefundRowSkinned = true
							row:StripTextures()
							row:CreateBackdrop("Transparent")
							if row.CheckButton then S:HandleCheckBox(row.CheckButton) end
							if row.Item and row.Item.Icon then S:HandleIcon(row.Item.Icon) end
							if row.Price then row.Price:StripTextures() end
							S:ApplyElvUIFont(row)
						end
					end
				end
			end)
		end
	end

	if _G.StoreCategorySubMenuMixin and not S._Elv_StoreSubMenuHooked then
		S._Elv_StoreSubMenuHooked = true

		hooksecurefunc(_G.StoreCategorySubMenuMixin, "UpdateSubCategories", function(self)
			for _, button in ipairs(self.subCategoryButtons or {}) do
				SkinStoreSubCategoryButton(button)
			end
		end)
	end

	if _G.StoreRecommendationMixin and not S._Elv_StoreRecommendationHooked then
		S._Elv_StoreRecommendationHooked = true
		hooksecurefunc(_G.StoreRecommendationMixin, "OnShow", function(self)
			if self.PurchaseButton then ReskinPKBTButton(self.PurchaseButton) end
			if self.DetailsButton then ReskinPKBTButton(self.DetailsButton) end
		end)
	end
end

local function SafeSkinCall(fn, ...)
	if not fn then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		local handler = geterrorhandler()
		if handler then handler(err) end
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.store then return end

	local function ApplySkin()
		StoreFrame:HookScript("OnShow", function()
			StoreFrame:SetScale(GetStoreFrameScale())
		end)
		StoreFrame:EnableMouse(true)
		StoreFrame:SetMovable(true)
		StoreFrame:RegisterForDrag("LeftButton")
		StoreFrame:SetScript("OnDragStart", function(self)
			self:StartMoving()
		end)
		StoreFrame:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			local frame_x, frame_y = self:GetCenter()
			frame_x = frame_x*UIParent:GetScale() - GetScreenWidth() / 2
			frame_y = frame_y*UIParent:GetScale() - GetScreenHeight() / 2
			self:ClearAllPoints()
			self:SetPoint("CENTER", UIParent, "CENTER", frame_x, frame_y)
		end)

		SafeSkinCall(HandleStoreFrame)
		SafeSkinCall(HookStore)
		StoreFrame:HookScript("OnShow", function()
			SafeSkinCall(HandleStoreFrame)
		end)
	end

	if _G.StoreFrame then
		ApplySkin()
	else
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_LOGIN")
		f:SetScript("OnEvent", function(self)
			if _G.StoreFrame then
				ApplySkin()
				self:UnregisterAllEvents()
			end
		end)
	end
end

S:AddCallback("Skin_Store", LoadSkin)
