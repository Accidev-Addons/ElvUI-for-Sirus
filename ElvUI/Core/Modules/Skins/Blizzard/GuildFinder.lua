local E = unpack(ElvUI)
local S = E:GetModule("Skins")

local function UpdateCard(card)
	local pending = card:GetParent():GetParent().isPendingCards
	local classes = card.ClassesFrame
	if pending then
		classes:Hide()
	elseif classes:IsShown() then
		local count = (classes:GetWidth() - 2) / 20
		for i, button in ipairs(classes.Buttons) do
			button:SetShown(i <= count)
			if not button.elvGuildFinderSkinned then
				button:SetTemplate("Default")
				button.Icon:SetDrawLayer("ARTWORK")
				button.Icon:SetAlpha(1)
				button.Icon:SetInside(button, 1, 1)
				button.Icon:SetTexCoords()
				button.Icon:Show()
				button:EnableDrawLayer("ARTWORK")
				button.elvGuildFinderSkinned = true
			end
		end
	end

	local actions = pending or card.RequestJoin:IsShown() or card.RequestStatus:IsShown()
	local right = actions and -86 or -8
	classes:ClearAllPoints()
	classes:SetPoint("TOPRIGHT", card, "TOPRIGHT", right, -4)
	classes:SetHeight(18)
	card.Name:ClearAllPoints()
	card.Name:SetPoint("TOPLEFT", card, "TOPLEFT", 74, -6)
	if classes:IsShown() then
		card.Name:SetPoint("TOPRIGHT", classes, "TOPLEFT", -8, -2)
	else
		card.Name:SetPoint("TOPRIGHT", card, "TOPRIGHT", right, -6)
	end
	card.Description:ClearAllPoints()
	card.Description:SetPoint("TOPLEFT", card, "TOPLEFT", 74, -25)
	card.Description:SetPoint("TOPRIGHT", card, "TOPRIGHT", right, -25)
	card.Focus:ClearAllPoints()
	card.Focus:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 194, 6)
	card.Focus:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", right, 6)
end

local function SkinCard(card)
	if card.elvGuildFinderSkinned then return end
	card.elvGuildFinderSkinned = true
	card.Background:Hide()
	card.LogoBorder:Hide()
	card:SetTemplate("Default")
	card.HighlightBackground:SetTexture(E.media.normTex)
	card.HighlightBackground:SetVertexColor(1, 1, 1, .08)
	card.HighlightBackground:ClearAllPoints()
	card.HighlightBackground:SetInside()
	card.Name:FontTemplate(nil, 12)
	card.Name:SetHeight(16)
	card.Description:FontTemplate(nil, 11)
	card.Description:SetHeight(24)
	card.Description:SetJustifyV("TOP")
	card.Focus:FontTemplate(nil, 10)
	card.Focus:SetHeight(12)
	card.Focus:SetWordWrap(false)
	card.Focus:SetJustifyH("RIGHT")
	card.MemberCount:FontTemplate(nil, 11)
	card.MemberCount:ClearAllPoints()
	card.MemberCount:SetPoint("BOTTOMLEFT", 74, 6)
	card.MemberIcon:ClearAllPoints()
	card.MemberIcon:SetPoint("LEFT", card.MemberCount, "RIGHT", 3, 0)
	card.ItemLevel:FontTemplate(nil, 11)
	card.ItemLevel:ClearAllPoints()
	card.ItemLevel:SetPoint("LEFT", card.MemberIcon, "RIGHT", 6, 0)
	card.RequestStatus:FontTemplate(nil, 10)
	card.RequestStatus:ClearAllPoints()
	card.RequestStatus:SetPoint("RIGHT", -6, -7)
	card.RequestStatus:SetSize(72, 44)
	card.OfficersOnline:ClearAllPoints()
	card.OfficersOnline:SetPoint("BOTTOMRIGHT", card.EmblemBackground, "BOTTOMRIGHT", 3, -3)
	card.OfficersOnline:SetSize(18, 18)

	local join = card.RequestJoin
	join:StripTextures()
	local text = join:CreateFontString(nil, "OVERLAY")
	text:FontTemplate(nil, 18)
	text:SetText("+")
	text:SetAllPoints()
	join:SetFontString(text)
	S:HandleButton(join)
	join:ClearAllPoints()
	join:SetPoint("RIGHT", -10, 0)
	join:SetSize(60, 24)
	S:HandleCloseButton(card.RemoveButton)
	card.RemoveButton:ClearAllPoints()
	card.RemoveButton:SetPoint("TOPRIGHT", -2, -2)
	card.RemoveButton:SetSize(22, 22)
	hooksecurefunc(card, "UpdateCard", UpdateCard)
	if card.cardIndex then UpdateCard(card) end
end

local function SkinCards(list)
	for _, card in ipairs(list.ListScrollFrame.buttons) do
		SkinCard(card)
	end
end

local function SkinDropdown(dropdown, width, x)
	S:HandleDropDownBox(dropdown, width)
	dropdown:ClearAllPoints()
	dropdown:SetPoint("TOPLEFT", dropdown:GetParent(), "TOPLEFT", x, -20)
	dropdown:SetHeight(20)
	dropdown.backdrop:ClearAllPoints()
	dropdown.backdrop:SetPoint("TOPLEFT", 0, 0)
	dropdown.backdrop:SetPoint("TOPRIGHT", -4, 0)
	dropdown.backdrop:SetHeight(20)
	local button = dropdown.Button
	E:UnlockPoints(button)
	button:ClearAllPoints()
	button:SetPoint("RIGHT", dropdown.backdrop, "RIGHT", -2, 0)
	button:SetSize(16, 16)
	E:LockPoints(button)
	dropdown.Text:ClearAllPoints()
	dropdown.Text:SetPoint("LEFT", dropdown.backdrop, "LEFT", 8, 0)
	dropdown.Text:SetPoint("RIGHT", button, "LEFT", -2, 0)
	dropdown.Label:ClearAllPoints()
	dropdown.Label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 5)
	dropdown.Label:SetWidth(width)
	dropdown.Label:FontTemplate(nil, 11)
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.guild then return end
	local frame = _G.LookingForGuildFrame
	if not frame or frame.elvGuildFinderSkinned then return end
	frame.elvGuildFinderSkinned = true
	S:HandlePortraitFrame(frame)
	frame.TabardOverlay:Hide()
	frame.InsetFrame:StripTextures()
	frame.InsetFrame:ClearAllPoints()
	frame.InsetFrame:SetPoint("TOPLEFT", 8, -108)
	frame.InsetFrame:SetPoint("BOTTOMRIGHT", -8, 10)
	frame.InsetFrame.GuildDescription:ClearAllPoints()
	frame.InsetFrame.GuildDescription:SetPoint("TOPLEFT", 20, -20)
	frame.InsetFrame.GuildDescription:SetPoint("BOTTOMRIGHT", -20, 20)
	frame.TutorialButton:ClearAllPoints()
	frame.TutorialButton:SetPoint("TOPLEFT", 6, -2)
	frame.TutorialButton:SetSize(28, 28)

	local options = frame.OptionsList
	options:ClearAllPoints()
	options:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -49)
	options:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -14, -103)
	SkinDropdown(options.FilterDropdown, 136, 0)
	SkinDropdown(options.SizeDropdown, 116, 144)
	for i, role in ipairs({"Tank", "Healer", "Dps"}) do
		local button = options[role.."RoleFrame"]
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", options, "TOPLEFT", 268 + (i - 1) * 40, -13)
		button:SetSize(30, 30)
		button.Icon:ClearAllPoints()
		button.Icon:SetAllPoints()
		S:HandleCheckBox(button.CheckBox)
		button.CheckBox:ClearAllPoints()
		button.CheckBox:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -4, -7)
		button.CheckBox:SetSize(22, 22)
	end
	S:HandleEditBox(options.SearchBox)
	options.SearchBox:ClearAllPoints()
	options.SearchBox:SetPoint("TOPLEFT", options, "TOPLEFT", 396, 0)
	options.SearchBox:SetPoint("TOPRIGHT", options, "TOPRIGHT", -4, 0)
	options.SearchBox:SetHeight(22)
	S:HandleButton(options.Search)
	options.Search:ClearAllPoints()
	options.Search:SetPoint("TOPLEFT", options.SearchBox, "BOTTOMLEFT", -4, -6)
	options.Search:SetPoint("TOPRIGHT", options.SearchBox, "BOTTOMRIGHT", 4, -6)
	options.Search:SetHeight(22)

	for i, tab in ipairs({frame.SearchTab, frame.PendingTab}) do
		tab:GetRegions():Hide()
		tab:StyleButton()
		tab:SetTemplate("Default", true)
		tab.Icon:SetInside()
		tab.Icon:SetTexCoords()
		if i == 1 then
			tab:ClearAllPoints()
			tab:SetPoint("TOPLEFT", frame, "TOPRIGHT", -E.Border, -36)
		end
	end

	for _, list in ipairs({frame.GuildCards, frame.PendingGuildCards}) do
		list:ClearAllPoints()
		list:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -108)
		list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, 10)
		S:HandleSirusScrollBar(list.ListScrollFrame.scrollBar)
		hooksecurefunc(list, "RefreshLayout", SkinCards)
		SkinCards(list)
	end

	local dialog = frame.RequestToJoinFrame
	dialog:StripTextures()
	dialog:SetTemplate("Transparent")
	dialog.BG:Hide()
	S:HandleButton(dialog.Apply)
	S:HandleButton(dialog.Cancel)
	dialog.MessageFrame:StripTextures()
	dialog.MessageFrame.MessageScroll:StripTextures()
	dialog.MessageFrame.MessageScroll:CreateBackdrop("Default")
	S:HandleSirusScrollBar(_G.LookingForGuildFrameRequestToJoinFrameMessageFrameMessageScrollScrollBar)
	S:ApplyElvUIFont(frame)

	frame:HookScript("OnShow", function(self)
		if IsInGuild() then
			self:UnregisterEvent("PLAYER_GUILD_UPDATE")
		else
			self:RegisterEvent("PLAYER_GUILD_UPDATE")
		end
	end)
end

S:AddCallback("Skin_GuildFinder", LoadSkin)
