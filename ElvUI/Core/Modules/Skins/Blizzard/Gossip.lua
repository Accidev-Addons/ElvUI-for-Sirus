local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local gsub = gsub
local hooksecurefunc = hooksecurefunc

local GossipTextColors = {
	["000000"] = "ffffff",
	["414141"] = "7b8489",
}

local function Gossip_SetTextColor(text, r, g, b)
	if r ~= 1 or g ~= 1 or b ~= 1 then
		text:SetTextColor(1, 1, 1)
	end
end

local function Gossip_ReplaceColor(color)
	return "|cFF" .. (GossipTextColors[color] or color)
end

local function Gossip_SetFormattedText(button, textFormat, text, skip)
	if skip or not text or text == "" then return end

	local colorText, colorCount = gsub(textFormat, "|c[fF][fF](%x%x%x%x%x%x)", Gossip_ReplaceColor)
	if colorCount > 0 then
		button:SetFormattedText(colorText, text, true)
	end
end

local function Gossip_SetText(button, text)
	if not text or text == "" then return end

	local colorText, colorCount = gsub(text, "|c[fF][fF](%x%x%x%x%x%x)", Gossip_ReplaceColor)
	if colorCount > 0 then
		button:SetFormattedText("%s", colorText, true)
	end
end

local function ItemTextPage_SetTextColor(pageText, r, g, b)
	if r ~= 1 or g ~= 1 or b ~= 1 then
		pageText:SetTextColor(1, 1, 1)
	end
end

local function GossipFrameUpdateHook()
	if not GossipFrame or not GossipFrame.buttonIndex then return end

	for i = 1, GossipFrame.buttonIndex do
		local button = _G["GossipTitleButton" .. i]
		if button and button:IsShown() then
			local fontString = button:GetFontString()
			if fontString then
				fontString:SetTextColor(1, 1, 1)

				local text = fontString:GetText()
				if text then
					local colorText = gsub(text, "|c[fF][fF]000000", "|cffffffff")
					if colorText ~= text then
						fontString:SetText(colorText)
					end
				end
			end
		end
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.gossip then return end

	S:HandleSirusFrame(GossipFrame)

	GossipFrameGreetingPanel:StripTextures()

	GossipGreetingText:SetTextColor(1, 1, 1)

	S:HandleSirusScrollFrame(GossipGreetingScrollFrame)

	GossipGreetingScrollFrame:SetPoint("TOPLEFT", GossipFrame, "TOPLEFT", 6, -44)
	GossipGreetingScrollFrame:SetHeight(414)
	if GossipGreetingScrollChildFrame then
		GossipGreetingScrollChildFrame:SetHeight(414)
	end

	S:HandleSirusButton(GossipFrameGreetingGoodbyeButton, true)

	for i = 1, NUMGOSSIPBUTTONS do
		local button = _G["GossipTitleButton"..i]
		if button and not button.isSkinned then
			S:HandleButtonHighlight(button)

			local fontString = button:GetFontString()
			if fontString then
				fontString:SetTextColor(1, 1, 1)
				hooksecurefunc(fontString, "SetTextColor", Gossip_SetTextColor)

				Gossip_SetText(button, button:GetText())
				hooksecurefunc(button, "SetText", Gossip_SetText)
				hooksecurefunc(button, "SetFormattedText", Gossip_SetFormattedText)
			end

			button.isSkinned = true
		end
	end

	hooksecurefunc("GossipFrameUpdate", GossipFrameUpdateHook)

	S:HandleSirusFrame(ItemTextFrame)

	ItemTextFramePageBg:Kill()

	for _, material in next, { ItemTextMaterialTopLeft, ItemTextMaterialTopRight, ItemTextMaterialBotLeft, ItemTextMaterialBotRight } do
		material:Kill()
	end

	S:HandleSirusScrollFrame(ItemTextScrollFrame)

	ItemTextPageText:SetTextColor(1, 1, 1)
	hooksecurefunc(ItemTextPageText, "SetTextColor", ItemTextPage_SetTextColor)

	S:HandleNextPrevButton(ItemTextPrevPageButton)
	S:HandleNextPrevButton(ItemTextNextPageButton)
end

S:AddCallback("Skin_Gossip", LoadSkin)
