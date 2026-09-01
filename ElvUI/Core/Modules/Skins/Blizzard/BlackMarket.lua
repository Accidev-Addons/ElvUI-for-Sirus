local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local hooksecurefunc = hooksecurefunc

local function SkinItemRows()
	local scrollFrame = _G.BlackMarketScrollFrame
	if not scrollFrame then return end

	for _, button in pairs(scrollFrame.buttons or {}) do
		if button and not button.ElvSkinned then

			local iconTex = button.Item and button.Item.IconTexture
			local iconPath = iconTex and iconTex.GetTexture and iconTex:GetTexture()

			button:StripTextures()
			S:HandleButton(button)

			if button.Item then
				S:HandleItemButton(button.Item)
				if iconTex and iconPath then
					iconTex:SetTexture(iconPath)
				end
			end

			button.ElvSkinned = true
		end
	end
end

local function SkinMoneyFrame(mf)
	if not mf or mf.ElvSkinned then return end
	mf.ElvSkinned = true

	mf:StripTextures()
	mf:CreateBackdrop("Transparent")
	mf.backdrop:SetAllPoints()

	for _, coin in pairs({"Gold", "Silver", "Copper"}) do
		local button = mf[coin.."Button"]
		if button then
			button:StripTextures()
			button:SetTemplate(nil, nil, nil, nil, nil, nil, nil, true)
			button:StyleButton()
		end
	end
end

local function ApplySkin()
	local frame = _G.BlackMarketFrame
	if not frame or frame.ElvSkinned then return end
	frame.ElvSkinned = true

	frame:StripTextures()

	if frame.art then
		frame.art:StripTextures()
		frame.art:SetAlpha(0)
	end

	-- Kill the sign texture overlay
	if frame.Artwork then
		frame.Artwork:StripTextures()
		frame.Artwork:SetAlpha(0)
	end

	frame:SetTemplate("Transparent")

	local inset = _G.BlackMarketFrameInset
	if inset then
		inset:StripTextures()
		inset:SetTemplate("Transparent")
	end

	S:HandleCloseButton(frame.CloseButton)

	local moneyBorder = _G.BlackMarketFrameMoneyFrameBorder
	if moneyBorder then
		moneyBorder:StripTextures()
		moneyBorder:SetTemplate("Transparent")
	end

	SkinMoneyFrame(_G.BlackMarketMoneyFrame)

	S:HandleButton(frame.BidButton)

	local bidGold = _G.BlackMarketBidPriceGold
	if bidGold then
		S:HandleEditBox(bidGold)
		bidGold.backdrop:ClearAllPoints()
		bidGold.backdrop:Point("TOPLEFT", -4, 0)
		bidGold.backdrop:Point("BOTTOMRIGHT", 4, 0)
	end

	local bidPrice = _G.BlackMarketBidPrice
	if bidPrice then
		bidPrice:StripTextures()
		bidPrice:CreateBackdrop("Transparent")

		if bidPrice.MoneyBg then
			bidPrice.MoneyBg:Kill()
		end

		if bidPrice.MoneyInputFrameInset then
			bidPrice.MoneyInputFrameInset:StripTextures()
		end
	end

	for _, colName in pairs({"ColumnName", "ColumnLevel", "ColumnType", "ColumnDuration", "ColumnHighBidder", "ColumnCurrentBid"}) do
		local col = frame[colName]
		if col then
			S:HandleButton(col)
		end
	end

	local scrollFrame = _G.BlackMarketScrollFrame
	if scrollFrame then
		scrollFrame:StripTextures()

		if scrollFrame.scrollBar then
			S:HandleSirusScrollBar(scrollFrame.scrollBar)
		end

		hooksecurefunc(scrollFrame, "update", SkinItemRows)
		SkinItemRows()
	end

	if frame.HotDeal then
		local hotDeal = frame.HotDeal

		local iconTex = hotDeal.Item and hotDeal.Item.IconTexture
		local iconPath = iconTex and iconTex.GetTexture and iconTex:GetTexture()

		hotDeal:StripTextures()

		if hotDeal.Item then
			S:HandleItemButton(hotDeal.Item)
			if iconTex and iconPath then
				iconTex:SetTexture(iconPath)
			end
		end

		SkinMoneyFrame(hotDeal.BlackMarketHotItemBidPrice)
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable then return end

	if _G.BlackMarketFrame then
		ApplySkin()
	else
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_LOGIN")
		f:SetScript("OnEvent", function(self)
			if _G.BlackMarketFrame then
				ApplySkin()
				self:UnregisterAllEvents()
			end
		end)
	end
end

S:AddCallback("Skin_BlackMarket", LoadSkin)