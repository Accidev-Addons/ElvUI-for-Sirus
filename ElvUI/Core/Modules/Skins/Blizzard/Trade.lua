local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local select = select

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.trade then return end

	local TradeFrame = _G.TradeFrame
	if not TradeFrame then return end

	S:HandleSirusFrame(TradeFrame)

	if TradeFrame.Overlay then
		if TradeFrame.Overlay.portrait then TradeFrame.Overlay.portrait:SetAlpha(0) end
		if TradeFrame.Overlay.portraitFrame then TradeFrame.Overlay.portraitFrame:SetAlpha(0) end
	end

	if TradeRecipientBG then TradeRecipientBG:SetAlpha(0) end
	if TradeRecipientLeftBorder then TradeRecipientLeftBorder:Kill() end
	if TradeRecipientBotLeftCorner then TradeRecipientBotLeftCorner:Kill() end

	for _, inset in next, {
		TradeFrame.RecipientItemsInset,
		TradeFrame.PlayerItemsInset,
		TradeFrame.RecipientEnchantInset,
		TradeFrame.LeftInset,
		TradeFrame.PlayerInputMoneyInset,
		TradeFrame.RecipientMoneyInset,
	} do
		if inset then
			inset:StripTextures()
			if inset.NineSlice then inset.NineSlice:Hide() end
		end
	end

	if TradeRecipientMoneyBg then TradeRecipientMoneyBg:StripTextures() end

	S:HandleButton(TradeFrameTradeButton, true)
	S:HandleButton(TradeFrameCancelButton, true)

	for _, box in next, { TradePlayerInputMoneyFrameGold, TradePlayerInputMoneyFrameSilver, TradePlayerInputMoneyFrameCopper } do
		S:HandleEditBox(box)

		if box.backdrop then
			box.backdrop:ClearAllPoints()
			box.backdrop:SetPoint('TOPLEFT', box, 'TOPLEFT', -4, 0)
			box.backdrop:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', 4, 0)
		end
	end

	for i = 1, MAX_TRADE_ITEMS do
		local player = _G["TradePlayerItem"..i]
		local recipient = _G["TradeRecipientItem"..i]
		local playerButton = _G["TradePlayerItem"..i.."ItemButton"]
		local playerButtonIcon = _G["TradePlayerItem"..i.."ItemButtonIconTexture"]
		local recipientButton = _G["TradeRecipientItem"..i.."ItemButton"]
		local recipientButtonIcon = _G["TradeRecipientItem"..i.."ItemButtonIconTexture"]

		if player then player:StripTextures() end
		if recipient then recipient:StripTextures() end

		if playerButton then
			playerButton:StripTextures()
			playerButton:StyleButton()
			playerButton:SetTemplate("Default", true)
			playerButton:OffsetFrameLevel(-1)
		end
		if playerButtonIcon then
			playerButtonIcon:SetInside()
			playerButtonIcon:SetTexCoords()
		end

		if recipientButton then
			recipientButton:StripTextures()
			recipientButton:StyleButton()
			recipientButton:SetTemplate("Default", true)
			recipientButton:OffsetFrameLevel(-1)
		end
		if recipientButtonIcon then
			recipientButtonIcon:SetInside()
			recipientButtonIcon:SetTexCoords()
		end

		if playerButton then
			playerButton.bg = CreateFrame("Frame", nil, playerButton)
			playerButton.bg:SetTemplate("Transparent")
			playerButton.bg:Point("TOPLEFT", playerButton, "TOPRIGHT", 4, 0)
			playerButton.bg:Point("BOTTOMRIGHT", _G["TradePlayerItem"..i.."NameFrame"], "BOTTOMRIGHT", 0, 14)
			playerButton.bg:OffsetFrameLevel(-3, playerButton)
		end

		if recipientButton then
			recipientButton.bg = CreateFrame("Frame", nil, recipientButton)
			recipientButton.bg:SetTemplate("Transparent")
			recipientButton.bg:Point("TOPLEFT", recipientButton, "TOPRIGHT", 4, 0)
			recipientButton.bg:Point("BOTTOMRIGHT", _G["TradeRecipientItem"..i.."NameFrame"], "BOTTOMRIGHT", 0, 14)
			recipientButton.bg:OffsetFrameLevel(-3, recipientButton)
		end
	end

	for _, name in next, {
		"TradeHighlightPlayerTop", "TradeHighlightPlayerBottom", "TradeHighlightPlayerMiddle",
		"TradeHighlightRecipientTop", "TradeHighlightRecipientBottom", "TradeHighlightRecipientMiddle",
		"TradeHighlightPlayerEnchantTop", "TradeHighlightPlayerEnchantBottom", "TradeHighlightPlayerEnchantMiddle",
		"TradeHighlightRecipientEnchantTop", "TradeHighlightRecipientEnchantBottom", "TradeHighlightRecipientEnchantMiddle",
	} do
		local texture = _G[name]
		if texture then texture:SetTexture(0, 1, 0, 0.2) end
	end

	for _, frame in next, {
		TradeHighlightPlayer, TradeHighlightRecipient, TradeHighlightPlayerEnchant, TradeHighlightRecipientEnchant,
	} do
		if frame then frame:SetFrameStrata("HIGH") end
	end

	hooksecurefunc("TradeFrame_UpdatePlayerItem", function(id)
		local tradeItemButton = _G["TradePlayerItem"..id.."ItemButton"]
		local link = GetTradePlayerItemLink(id)

		if link then
			local tradeItemName = _G["TradePlayerItem"..id.."Name"]
			local quality = select(3, GetItemInfo(link))

			tradeItemName:SetTextColor(E:GetItemQualityColor(quality))

			if quality and quality > 1 then
				tradeItemButton:SetBackdropBorderColor(E:GetItemQualityColor(quality))
			else
				tradeItemButton:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		else
			tradeItemButton:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end)

	hooksecurefunc("TradeFrame_UpdateTargetItem", function(id)
		local tradeItemButton = _G["TradeRecipientItem"..id.."ItemButton"]
		local link = GetTradeTargetItemLink(id)

		if link then
			local tradeItemName = _G["TradeRecipientItem"..id.."Name"]
			local quality = select(3, GetItemInfo(link))

			tradeItemName:SetTextColor(E:GetItemQualityColor(quality))

			if quality and quality > 1 then
				tradeItemButton:SetBackdropBorderColor(E:GetItemQualityColor(quality))
			else
				tradeItemButton:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
		else
			tradeItemButton:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end)
end

S:AddCallback("Skin_Trade", LoadSkin)
