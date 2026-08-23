local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.help then return end

	S:HandleFrame(HelpFrame, true)
	S:HandleCloseButton(HelpFrameCloseButton)
	S:HandleFrame(HelpFrameHeader, true)

	local btn
	for i = 1, 16 do
		btn = _G["HelpFrameButton"..i]
		if btn then
			S:HandleButton(btn)
			btn:StripTextures(nil, true)
			if btn.icon then btn.icon:SetAlpha(1) end
		end
	end

	local handledButtons = {
		"HelpFrameAccountSecurityTwoFA",
		"HelpFrameSupportSubmitSuggestion",
		"HelpFrameSupportItemRestoration",
		"HelpFrameSupportBugReport",
	}
	for i = 1, #handledButtons do
		btn = _G[handledButtons[i]]
		if btn then
			S:HandleButton(btn)
			btn:StripTextures(nil, true)
			if btn.icon then btn.icon:SetAlpha(1) end
		end
	end

	local ticketFrame = select(3, HelpFrameTicket:GetChildren())
	if ticketFrame then
		ticketFrame:StripTextures()
		ticketFrame:CreateBackdrop("Transparent")
	end

	if HelpFrameCharacterStuckHearthstone and HelpFrameCharacterStuckHearthstone.IconTexture then
		S:HandleIcon(HelpFrameCharacterStuckHearthstone.IconTexture)
	end

	if HelpFrameKnowledgebaseScrollFrameScrollBar then
		S:HandleSirusScrollBar(HelpFrameKnowledgebaseScrollFrameScrollBar)
	end
	if HelpFrameKnowledgebaseScrollFrame2ScrollBar then
		S:HandleSirusScrollBar(HelpFrameKnowledgebaseScrollFrame2ScrollBar)
	end

	if HelpFrameMainInset then HelpFrameMainInset:Hide() end
	if HelpFrameLeftInset then HelpFrameLeftInset:Hide() end

	S:HandleEditBox(HelpFrameKnowledgebaseSearchBox)
	S:HandleButton(HelpFrameKnowledgebaseSearchButton)
	S:HandleButton(GMChatOpenLog)
	S:HandleButton(HelpFrameCharacterStuckStuck)
	S:HandleButton(HelpFrameTicketSubmit)
	S:HandleButton(HelpFrameTicketCancel)
	S:HandleSirusScrollBar(HelpFrameTicketScrollFrameScrollBar)
end

S:AddCallback("Skin_Help", LoadSkin)
