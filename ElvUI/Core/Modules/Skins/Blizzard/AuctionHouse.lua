local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local next, pairs, unpack = next, pairs, unpack
local ipairs = ipairs
local hooksecurefunc = hooksecurefunc

local function SkinFilterButton(Button)
	if Button.ClearFiltersButton then
		S:HandleCloseButton(Button.ClearFiltersButton)
	end

	S:HandleButton(Button)
end

local function HandleSearchBarFrame(Frame)
	SkinFilterButton(Frame.FilterButton)

	S:HandleButton(Frame.SearchButton)
	S:HandleEditBox(Frame.SearchBox)
	S:HandleButton(Frame.FavoritesSearchButton)
	Frame.FavoritesSearchButton:Size(22)
end

local function HandleListIcon(frame)
	if not frame.tableBuilder then return end

	for i = 1, 22 do
		local row = frame.tableBuilder.rows[i]
		if row then
			for j = 1, 4 do
				local cell = row.cells and row.cells[j]
				if cell and cell.Icon then
					if not cell.IsSkinned then
						S:HandleIcon(cell.Icon)

						if cell.IconBorder then
							cell.IconBorder:Kill()
						end

						cell.IsSkinned = true
					end
				end
			end
		end
	end
end

local function HandleSummaryIcon(child)
	if child.Icon then
		if not child.IsSkinned then
			S:HandleIcon(child.Icon)

			if child.IconBorder then
				child.IconBorder:Kill()
			end

			child.IsSkinned = true
		end
	end
end

local function HandleSummaryIcons(frame)
	if not frame.ScrollFrame or not frame.ScrollFrame.buttons then return end

	for _, child in ipairs(frame.ScrollFrame.buttons) do
		HandleSummaryIcon(child)
	end
end

local function SkinItemDisplay(frame)
	if not frame or not frame.ItemDisplay then return end

	local ItemDisplay = frame.ItemDisplay
	ItemDisplay:StripTextures()
	ItemDisplay:CreateBackdrop("Transparent")
	ItemDisplay.backdrop:Point("TOPLEFT", 3, -3)
	ItemDisplay.backdrop:Point("BOTTOMRIGHT", -3, 0)

	S:ApplyElvUIFontForce(ItemDisplay)

	local ItemButton = ItemDisplay.ItemButton
	if not ItemButton then return end

	if ItemButton.CircleMask then ItemButton.CircleMask:Hide() end
	if ItemButton.SetAttribute then ItemButton:SetAttribute("useCircularIconBorder", false) end

	if ItemButton.Icon then S:HandleIcon(ItemButton.Icon, true) end
	if ItemButton.IconBorder and ItemButton.Icon and ItemButton.Icon.backdrop then
		S:HandleIconBorder(ItemButton.IconBorder, ItemButton.Icon.backdrop)
		ItemButton.IconBorder:Kill()
	end

	local highlight = ItemButton.GetHighlightTexture and ItemButton:GetHighlightTexture()
	if highlight then highlight:Hide() end
end

local function HandleHeaders(frame)
	if frame.ScrollFrame then
		S:ApplyElvUIFontForce(frame.ScrollFrame)
	end

	local headerContainer = frame.HeaderContainer
	local maxHeaders = headerContainer and headerContainer:GetNumChildren() or 0
	for i = 1, maxHeaders do
		local header = select(i, headerContainer:GetChildren())
		if not header.IsSkinned then
			header:DisableDrawLayer("BACKGROUND")

			if not header.backdrop then
				header:CreateBackdrop("Transparent")
			end

			header.IsSkinned = true
		end

		if header.backdrop then
			header.backdrop:Point("BOTTOMRIGHT", i < maxHeaders and -5 or 0, -2)
		end
	end

	HandleListIcon(frame)
end

local function HandleAuctionButtons(button)
	S:HandleButton(button)
	button:Size(22)
end

local function HandleSellFrame(frame)
	frame:StripTextures()

	local ItemDisplay = frame.ItemDisplay
	if not ItemDisplay then return end
	ItemDisplay:StripTextures()
	ItemDisplay:SetTemplate("Transparent")

	local ItemButton = ItemDisplay.ItemButton
	if not ItemButton then return end
	if ItemButton.IconMask then ItemButton.IconMask:Hide() end
	if ItemButton.EmptyBackground then ItemButton.EmptyBackground:Hide() end

	if ItemButton.SetPushedTexture then ItemButton:SetPushedTexture(E.ClearTexture) end
	if ItemButton.Highlight then
		ItemButton.Highlight:SetTexture(1, 1, 1, .25)
		if ItemButton.Icon then ItemButton.Highlight:SetAllPoints(ItemButton.Icon) end
	end

	if ItemButton.Icon then S:HandleIcon(ItemButton.Icon, true) end

	if frame.QuantityInput then
		S:ApplyElvUIFontForce(frame.QuantityInput)
		if frame.QuantityInput.InputBox then S:HandleEditBox(frame.QuantityInput.InputBox) end
		if frame.QuantityInput.MaxButton then S:HandleButton(frame.QuantityInput.MaxButton) end
	end

	if frame.PriceInput and frame.PriceInput.MoneyInputFrame then
		S:ApplyElvUIFontForce(frame.PriceInput.MoneyInputFrame)
		if frame.PriceInput.MoneyInputFrame.GoldBox then S:HandleEditBox(frame.PriceInput.MoneyInputFrame.GoldBox) end
		if frame.PriceInput.MoneyInputFrame.SilverBox then S:HandleEditBox(frame.PriceInput.MoneyInputFrame.SilverBox) end
	end

	if ItemButton.IconBorder and ItemButton.Icon and ItemButton.Icon.backdrop then
		S:HandleIconBorder(ItemButton.IconBorder, ItemButton.Icon.backdrop)
	end

	if frame.SecondaryPriceInput and frame.SecondaryPriceInput.MoneyInputFrame then
		S:ApplyElvUIFontForce(frame.SecondaryPriceInput.MoneyInputFrame)
		if frame.SecondaryPriceInput.MoneyInputFrame.GoldBox then S:HandleEditBox(frame.SecondaryPriceInput.MoneyInputFrame.GoldBox) end
		if frame.SecondaryPriceInput.MoneyInputFrame.SilverBox then S:HandleEditBox(frame.SecondaryPriceInput.MoneyInputFrame.SilverBox) end
	end

	if frame.Duration and frame.Duration.Dropdown then
		S:HandleDropDownBox(frame.Duration.Dropdown)
	end

	local BuyoutModeCheckButton = frame.BuyoutModeCheckButton or _G.AuctionHouseFrameItemSellFrameBuyoutModeCheckButton
	if BuyoutModeCheckButton then
		S:HandleCheckBox(BuyoutModeCheckButton)
	end

	if frame.PostButton then S:HandleButton(frame.PostButton) end
end

local function HandleSellList(frame, hasHeader, fitScrollBar)
	frame:StripTextures()

	if frame.RefreshFrame then
		HandleAuctionButtons(frame.RefreshFrame.RefreshButton)
	end

	local ScrollBar = frame.ScrollFrame and frame.ScrollFrame.scrollBar
	if ScrollBar then
		S:HandleSirusScrollBar(ScrollBar)
	end

	if fitScrollBar and ScrollBar then
		ScrollBar:ClearAllPoints()
		ScrollBar:Point("TOPRIGHT", frame, -6, -16)
		ScrollBar:Point("BOTTOMRIGHT", frame, -6, 16)
	end

	if hasHeader then
		frame.ScrollFrame:SetTemplate("Transparent")

		hooksecurefunc(frame, "RefreshScrollFrame", HandleHeaders)
	else
		hooksecurefunc(frame, "RefreshScrollFrame", HandleSummaryIcons)
	end
end

local function HandleTabs(arg1)
	local frame = _G.AuctionHouseFrame
	if not arg1 or arg1 ~= frame then return end

	local lastTab
	for index, tab in next, frame.Tabs do
		local blizzTab = tab == _G.AuctionHouseFrameBuyTab or tab == _G.AuctionHouseFrameSellTab or tab == _G.AuctionHouseFrameAuctionsTab
		if blizzTab then
			S:HandleSirusTab(tab, lastTab)

			if index == 1 then
				tab:ClearAllPoints()
				tab:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", -3, -32)
			end
		end

		lastTab = tab
	end
end

local function LoadSkin()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.auctionhouse) then return end

	local Frame = _G.AuctionHouseFrame
	if not Frame then return end

	S:HandleSirusFrame(Frame)
	Frame:Width(810)

	if PanelTemplates_SetNumTabs then
		hooksecurefunc("PanelTemplates_SetNumTabs", HandleTabs)
	end
	HandleTabs(Frame)

	HandleSearchBarFrame(Frame.SearchBar)
	Frame.MoneyFrameBorder:StripTextures()
	Frame.MoneyFrameInset:StripTextures()

	local Categories = Frame.CategoriesList
	Categories:StripTextures()
	Categories.NineSlice:SetTemplate("Transparent")
	Categories.NineSlice:SetInside(Categories)

	if Categories.ScrollFrame then
		Categories.ScrollFrame:StripTextures()

		local CategoriesScrollBar = Categories.ScrollFrame.scrollBar or _G.AuctionHouseFrameCategoriesListScrollFrameScrollBar
		if CategoriesScrollBar then
			S:HandleSirusScrollBar(CategoriesScrollBar)
		end
	end

	hooksecurefunc("FilterButton_SetUp", function(button)
		if not button then return end

		if button.NormalTexture then
			button.NormalTexture:SetAlpha(0)
		end

		local r, g, b = unpack(E.media.rgbvaluecolor)
		if button.SelectedTexture then
			button.SelectedTexture:SetTexture(r, g, b, .25)
		end

		if button.HighlightTexture then
			button.HighlightTexture:SetTexture(1, 1, 1, .1)
		end
	end)

	local Browse = Frame.BrowseResultsFrame

	S:ApplyElvUIFontForce(Browse)
	Browse:HookScript("OnShow", function(self)
		S:ApplyElvUIFontForce(self)
	end)

	local BrowseList = Browse.ItemList
	BrowseList:StripTextures()
	hooksecurefunc(BrowseList, "RefreshScrollFrame", HandleHeaders)
	local BrowseScrollFrame = BrowseList.ScrollFrame
	if BrowseScrollFrame then
		S:ApplyElvUIFontForce(BrowseScrollFrame)
	end
	BrowseList:HookScript("OnShow", function(self)
		if self.ScrollFrame then
			S:ApplyElvUIFontForce(self.ScrollFrame)
		end
	end)
	local BrowseScrollBar = BrowseList.ScrollFrame and BrowseList.ScrollFrame.scrollBar
	if BrowseScrollBar then
		S:HandleSirusScrollBar(BrowseScrollBar)
	end
	BrowseList:SetTemplate("Transparent")
	if BrowseScrollBar then
		BrowseScrollBar:ClearAllPoints()
		BrowseScrollBar:Point("TOPRIGHT", BrowseList, -6, -16)
		BrowseScrollBar:Point("BOTTOMRIGHT", BrowseList, -6, 16)
	end

	local CommoditiesBuyFrame = Frame.CommoditiesBuyFrame
	CommoditiesBuyFrame.BuyDisplay:StripTextures()
	S:HandleButton(CommoditiesBuyFrame.BackButton)

	local CommoditiesBuyList = Frame.CommoditiesBuyFrame.ItemList
	CommoditiesBuyList:StripTextures()
	CommoditiesBuyList:SetTemplate("Transparent")
	if CommoditiesBuyList.RefreshFrame and CommoditiesBuyList.RefreshFrame.RefreshButton then
		S:HandleButton(CommoditiesBuyList.RefreshFrame.RefreshButton)
	end
	local CommoditiesBuyScrollBar = CommoditiesBuyList.ScrollFrame and CommoditiesBuyList.ScrollFrame.scrollBar
	if CommoditiesBuyScrollBar then
		S:HandleSirusScrollBar(CommoditiesBuyScrollBar)
	end

	local BuyDisplay = Frame.CommoditiesBuyFrame.BuyDisplay
	S:HandleEditBox(BuyDisplay.QuantityInput.InputBox)
	S:HandleButton(BuyDisplay.BuyButton)

	SkinItemDisplay(BuyDisplay)

	local ItemBuyFrame = Frame.ItemBuyFrame
	S:HandleButton(ItemBuyFrame.BackButton)
	S:HandleButton(ItemBuyFrame.BuyoutFrame.BuyoutButton)

	SkinItemDisplay(ItemBuyFrame)

	local ItemBuyList = ItemBuyFrame.ItemList
	ItemBuyList:StripTextures()
	ItemBuyList:SetTemplate("Transparent")
	local ItemBuyScrollBar = ItemBuyList.ScrollFrame and ItemBuyList.ScrollFrame.scrollBar
	if ItemBuyScrollBar then
		S:HandleSirusScrollBar(ItemBuyScrollBar)
	end
	S:HandleButton(ItemBuyList.RefreshFrame.RefreshButton)
	hooksecurefunc(ItemBuyList, "RefreshScrollFrame", HandleHeaders)

	local ItemBuyBidFrame = ItemBuyFrame.BidFrame
	S:HandleButton(ItemBuyBidFrame.BidButton)
	ItemBuyBidFrame.BidButton:ClearAllPoints()
	ItemBuyBidFrame.BidButton:Point("LEFT", ItemBuyBidFrame.BidAmount, "RIGHT", 2, -2)

	if ItemBuyBidFrame.BidAmount then
		S:HandleEditBox(ItemBuyBidFrame.BidAmount.gold)
		S:HandleEditBox(ItemBuyBidFrame.BidAmount.silver)
	end

	local SellFrame = Frame.ItemSellFrame
	HandleSellFrame(SellFrame)
	Frame.ItemSellFrame:SetTemplate("Transparent")

	local ItemSellList = Frame.ItemSellList
	HandleSellList(ItemSellList, true, true)

	local CommoditiesSellFrame = Frame.CommoditiesSellFrame
	HandleSellFrame(CommoditiesSellFrame)

	local CommoditiesSellList = Frame.CommoditiesSellList
	HandleSellList(CommoditiesSellList, true)

	local AuctionsFrame = _G.AuctionHouseFrameAuctionsFrame
	AuctionsFrame:StripTextures()
	SkinItemDisplay(AuctionsFrame)
	if AuctionsFrame.BuyoutFrame and AuctionsFrame.BuyoutFrame.BuyoutButton then
		S:HandleButton(AuctionsFrame.BuyoutFrame.BuyoutButton)
	end

	local CommoditiesList = AuctionsFrame.CommoditiesList
	HandleSellList(CommoditiesList, true)
	if CommoditiesList.RefreshFrame and CommoditiesList.RefreshFrame.RefreshButton then
		S:HandleButton(CommoditiesList.RefreshFrame.RefreshButton)
	end

	local AuctionsList = AuctionsFrame.ItemList
	HandleSellList(AuctionsList, true)
	if AuctionsList.RefreshFrame and AuctionsList.RefreshFrame.RefreshButton then
		S:HandleButton(AuctionsList.RefreshFrame.RefreshButton)
	end

	local AuctionsFrameTabs = {
		AuctionsFrame.AuctionsTab,
		AuctionsFrame.BidsTab,
	}

	for _, tab in pairs(AuctionsFrameTabs) do
		if tab then
			S:HandleTab(tab)
		end
	end

	local SummaryList = AuctionsFrame.SummaryList
	HandleSellList(SummaryList)
	SummaryList:SetTemplate("Transparent")
	if SummaryList.ScrollFrame then
		S:ApplyElvUIFontForce(SummaryList.ScrollFrame)
	end
	SummaryList:HookScript("OnShow", function(self)
		if self.ScrollFrame then
			S:ApplyElvUIFontForce(self.ScrollFrame)
		end
	end)
	if AuctionsFrame.CancelAuctionButton then
		S:HandleButton(AuctionsFrame.CancelAuctionButton)
	end

	if SummaryList.ScrollFrame and SummaryList.ScrollFrame.scrollBar then
		SummaryList.ScrollFrame.scrollBar:ClearAllPoints()
		SummaryList.ScrollFrame.scrollBar:Point("TOPRIGHT", SummaryList, -5, -20)
		SummaryList.ScrollFrame.scrollBar:Point("BOTTOMRIGHT", SummaryList, -5, 20)
	end

	local AllAuctionsList = AuctionsFrame.AllAuctionsList
	HandleSellList(AllAuctionsList, true, true)
	S:HandleButton(AllAuctionsList.RefreshFrame.RefreshButton)

	local BidsList = AuctionsFrame.BidsList
	HandleSellList(BidsList, true, true)
	S:HandleButton(BidsList.RefreshFrame.RefreshButton)

	local BidFrame = AuctionsFrame.BidFrame
	S:HandleButton(BidFrame.BidButton)

	if BidFrame.BidAmount then
		S:HandleEditBox(BidFrame.BidAmount.gold)
		S:HandleEditBox(BidFrame.BidAmount.silver)
	end

	if Frame.BuyDialog then
		Frame.BuyDialog:StripTextures()
		Frame.BuyDialog:SetTemplate("Transparent")
		if Frame.BuyDialog.BuyNowButton then S:HandleButton(Frame.BuyDialog.BuyNowButton) end
		if Frame.BuyDialog.CancelButton then S:HandleButton(Frame.BuyDialog.CancelButton) end
	end

	local multisellFrame = _G.AuctionHouseMultisellProgressFrame
	if multisellFrame then
		multisellFrame:StripTextures()
		multisellFrame:SetTemplate("Transparent")

		local progressBar = multisellFrame.ProgressBar
		if progressBar then
			progressBar:StripTextures()
			progressBar:CreateBackdrop(nil, nil, nil, nil, nil, nil, nil, nil, true)
			progressBar:SetStatusBarTexture(E.media.normTex)

			if progressBar.Text then
				progressBar.Text:ClearAllPoints()
				progressBar.Text:Point("BOTTOM", progressBar, "TOP", 0, 5)
			end

			if multisellFrame.CancelButton then S:HandleCloseButton(multisellFrame.CancelButton) end
			if progressBar.Icon then
				S:HandleIcon(progressBar.Icon)

				progressBar.IconBackdrop = CreateFrame("Frame", "$parentIconBackdrop", progressBar)
				progressBar.IconBackdrop:OffsetFrameLevel(nil, progressBar)
				progressBar.IconBackdrop:SetOutside(progressBar.Icon)
				progressBar.IconBackdrop:SetTemplate()
			end
		end
	end
end

S:AddCallback("Skin_Blizzard_AuctionUI", LoadSkin)
