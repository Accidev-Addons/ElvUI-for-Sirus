local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local ipairs, unpack, select = ipairs, unpack, select
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local GetItemInfo = GetItemInfo
local GetItemInfoInstant = GetItemInfoInstant
local GetSpellInfo = GetSpellInfo
local SetPortraitToTexture = SetPortraitToTexture
local GetTradeSkillItemLink = GetTradeSkillItemLink
local GetTradeSkillNumReagents = GetTradeSkillNumReagents
local GetTradeSkillReagentInfo = GetTradeSkillReagentInfo
local GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
local GetTradeSkillLine = GetTradeSkillLine

local ART_PATH = [[Interface\AddOns\ElvUI\Core\Media\DragonUI\Professions\]]
local RING_TEXTURE = [[Interface\AddOns\ElvUI\Core\Media\DragonUI\Glyphs\ring-gold]]

local PROFESSION_KEYS = {
	["Алхимия"] = "alchemy", ["Alchemy"] = "alchemy",
	["Кузнечное дело"] = "blacksmithing", ["Blacksmithing"] = "blacksmithing",
	["Кулинария"] = "cooking", ["Cooking"] = "cooking",
	["Наложение чар"] = "enchanting", ["Enchanting"] = "enchanting",
	["Механика"] = "engineering", ["Инженерное дело"] = "engineering", ["Engineering"] = "engineering",
	["Рыбная ловля"] = "fishing", ["Fishing"] = "fishing",
	["Травничество"] = "herbalism", ["Herbalism"] = "herbalism",
	["Начертание"] = "inscription", ["Inscription"] = "inscription",
	["Ювелирное дело"] = "jewelcrafting", ["Jewelcrafting"] = "jewelcrafting",
	["Кожевничество"] = "leatherworking", ["Leatherworking"] = "leatherworking",
	["Горное дело"] = "mining", ["Выплавка металлов"] = "mining", ["Mining"] = "mining", ["Smelting"] = "mining",
	["Снятие шкур"] = "skinning", ["Skinning"] = "skinning",
	["Портняжное дело"] = "tailoring", ["Tailoring"] = "tailoring",
}

local function UpdateProfessionArt()
	local TradeSkillFrame = _G.TradeSkillFrame
	local key = PROFESSION_KEYS[GetTradeSkillLine()]

	local portrait = TradeSkillFrame.portrait
	if key and key ~= "generic" then
		portrait:SetTexture(ART_PATH.."icon-"..key)
		portrait:SetTexCoord(0, 1, 0, 1)
		portrait:SetAlpha(1)
		TradeSkillFrame.portraitRing:SetAlpha(1)
	else
		portrait:SetAlpha(0)
		TradeSkillFrame.portraitRing:SetAlpha(0)
	end
end

local function GetBorderColor(quality)
	local color = quality and _G.BAG_ITEM_QUALITY_COLORS[quality]
	if color then
		return color.r, color.g, color.b
	end

	return unpack(E.media.bordercolor)
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.tradeskill then return end

	local TradeSkillFrame = _G.TradeSkillFrame
	if not (TradeSkillFrame and TradeSkillFrame.RecipeInset) then return end

	S:HandlePortraitFrame(TradeSkillFrame)
	S:HandleMaxMinFrame(_G.MaximizeMinimizeFrame)

	local portraitRing = TradeSkillFrame.portrait:GetParent():CreateTexture(nil, "OVERLAY")
	portraitRing:SetTexture(RING_TEXTURE)
	portraitRing:Size(100)
	portraitRing:Point("CENTER", TradeSkillFrame.portrait, "CENTER", 0, 0)
	portraitRing:SetAlpha(0)
	TradeSkillFrame.portraitRing = portraitRing

	TradeSkillFrame.RecipeInset:StripTextures()
	TradeSkillFrame.RecipeInset:CreateBackdrop("Transparent")
	TradeSkillFrame.DetailsInset:StripTextures()
	TradeSkillFrame.DetailsInset:CreateBackdrop("Transparent")

	local RankFrame = _G.TradeSkillRankFrame
	RankFrame:StripTextures()
	RankFrame:CreateBackdrop()
	RankFrame:SetStatusBarTexture(E.media.normTex)
	E:LockMethod(RankFrame, "SetStatusBarColor", 0.22, 0.39, 0.84)
	E:RegisterStatusBar(RankFrame)
	E:SetSmoothing(RankFrame, 1, true)

	S:HandleTab(TradeSkillFrame.LearnedTab)
	S:HandleTab(TradeSkillFrame.UnlearnedTab)

	S:HandleEditBox(TradeSkillFrame.SearchBox)
	S:HandleButton(TradeSkillFrame.FilterButton)
	S:HandleDropDownBox(_G.TradeSkillInvSlotDropDown, 140)
	S:HandleDropDownBox(_G.TradeSkillSubClassDropDown, 140)
	S:HandleCheckBox(_G.TradeSkillFrameAvailableFilterCheckButton)

	_G.TradeSkillHighlight:SetTexture(E.media.blankTex)
	_G.TradeSkillHighlight:SetBlendMode("BLEND")
	_G.TradeSkillHighlight:SetAlpha(0.35)

	_G.TradeSkillExpandButtonFrame:StripTextures()
	S:HandleCollapseExpandButton(_G.TradeSkillCollapseAllButton, "+")

	for i = 1, 25 do
		local skillButton = _G["TradeSkillSkill"..i]
		local skillButtonHighlight = _G["TradeSkillSkill"..i.."Highlight"]

		S:HandleCollapseExpandButton(skillButton, "+", nil, nil, 1)
		skillButton:SetFrameLevel(_G.TradeSkillHighlightFrame:GetFrameLevel() + 1)

		if skillButtonHighlight then
			E:LockMethod(skillButtonHighlight, "SetTexture", "")
		end
	end


	_G.TradeSkillListScrollFrame:StripTextures()
	S:HandleSirusScrollBar(_G.TradeSkillListScrollFrameScrollBar)

	local DetailScrollFrame = _G.TradeSkillDetailScrollFrame
	S:HandleSirusScrollBar(_G.TradeSkillDetailScrollFrameScrollBar)

	local ResultIcon = _G.TradeSkillSkillIcon
	ResultIcon:StyleButton(nil, true)
	ResultIcon:SetTemplate("Default")
	ResultIcon.IconBorder:SetAlpha(0)
	ResultIcon.ResultBorder:SetAlpha(0)

	_G.TradeSkillRequirementLabel:SetTextColor(1, 0.80, 0.10)

	for i = 1, 8 do
		local reagent = _G["TradeSkillReagent"..i]
		local icon = reagent.Icon
		local count = reagent.Count

		reagent:SetTemplate("Default")
		reagent:StyleButton(nil, true)

		icon.backdrop = CreateFrame("Frame", nil, reagent)
		icon.backdrop:SetTemplate()
		icon.backdrop:SetOutside(icon)

		icon:SetTexCoords()
		icon:SetDrawLayer("ARTWORK")
		icon:Size(E.PixelMode and 38 or 32)
		icon:Point("TOPLEFT", E.PixelMode and 1 or 4, -(E.PixelMode and 1 or 4))
		icon:SetParent(icon.backdrop)

		count:SetParent(icon.backdrop)
		count:SetDrawLayer("OVERLAY")

		reagent.Name:Point("LEFT", reagent.NameFrame, "LEFT", 20, 0)
		reagent.NameFrame:Kill()
	end

	local TrackButton = _G.TradeSkillTrackButton
	S:HandleCheckBox(TrackButton, true)
	TrackButton:Size(18)
	TrackButton:GetCheckedTexture():SetInside(TrackButton, 2, 2)

	S:HandleButton(_G.TradeSkillCreateAllButton)
	S:HandleButton(_G.TradeSkillCreateButton)
	S:HandleButton(_G.TradeSkillCancelButton)

	local InputBox = _G.TradeSkillInputBox
	S:HandleEditBox(InputBox)
	if InputBox.Left then InputBox.Left:SetAlpha(0) end
	if InputBox.Right then InputBox.Right:SetAlpha(0) end
	if InputBox.Middle then InputBox.Middle:SetAlpha(0) end
	S:HandleNextPrevButton(InputBox.IncrementButton)
	S:HandleNextPrevButton(InputBox.DecrementButton)

	local LinkButton = _G.TradeSkillLinkButton
	LinkButton:GetNormalTexture():SetTexCoord(6 / 32, 24 / 32, 12 / 32, 24 / 32)
	LinkButton:GetPushedTexture():SetTexCoord(6 / 32, 24 / 32, 14 / 32, 26 / 32)
	LinkButton:GetHighlightTexture():Kill()
	LinkButton:CreateBackdrop()
	LinkButton:SetSize(19, 14)
	LinkButton:ClearAllPoints()
	LinkButton:Point("LEFT", RankFrame, "RIGHT", 4, 0)

	S:SetUIPanelWindowInfo(TradeSkillFrame, "width")
	S:SetBackdropHitRect(TradeSkillFrame)

	DetailScrollFrame.Background:SetVertexColor(0.8, 0.8, 0.8)

	hooksecurefunc("TradeSkillFrame_Show", UpdateProfessionArt)
	hooksecurefunc("TradeSkillFrame_ToggleMode", function()
		S:SetUIPanelWindowInfo(TradeSkillFrame, "width")
	end)

	hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
		if ResultIcon:GetNormalTexture() then
			ResultIcon:SetAlpha(1)
			ResultIcon:GetNormalTexture():SetTexCoords()
			ResultIcon:GetNormalTexture():SetInside()
		else
			ResultIcon:SetAlpha(0)
		end

		local skillLink = GetTradeSkillItemLink(id)
		local r, g, b

		if skillLink then
			local quality = select(3, GetItemInfo(skillLink))

			if quality and quality > 1 then
				r, g, b = E:GetItemQualityColor(quality)

				ResultIcon:SetBackdropBorderColor(r, g, b)
				_G.TradeSkillSkillName:SetTextColor(r, g, b)
			else
				ResultIcon:SetBackdropBorderColor(GetBorderColor(quality))
				_G.TradeSkillSkillName:SetTextColor(1, 1, 1)
			end
		end

		for i = 1, GetTradeSkillNumReagents(id) do
			local _, _, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i)
			local reagentLink = GetTradeSkillReagentItemLink(id, i)

			if reagentLink then
				local reagent = _G["TradeSkillReagent"..i]
				local quality = select(3, GetItemInfo(reagentLink))

				if quality and quality > 1 then
					r, g, b = E:GetItemQualityColor(quality)

					reagent.Icon.backdrop:SetBackdropBorderColor(r, g, b)
					reagent:SetBackdropBorderColor(r, g, b)

					if playerReagentCount < reagentCount then
						reagent.Name:SetTextColor(0.5, 0.5, 0.5)
					else
						reagent.Name:SetTextColor(r, g, b)
					end
				else
					r, g, b = GetBorderColor(quality)
					reagent:SetBackdropBorderColor(r, g, b)
					reagent.Icon.backdrop:SetBackdropBorderColor(r, g, b)
				end
			end
		end
	end)
end

local function UpdateOutputIcon(button)
	local texture
	if button.craftedType == "spell" then
		texture = select(3, GetSpellInfo(button.spellID))
	elseif button.itemID then
		texture = select(5, GetItemInfoInstant(button.itemID))
	end

	SetPortraitToTexture(button.Icon, "")
	button.Icon:SetTexture(texture or [[Interface\Icons\INV_Misc_QuestionMark]])
	button.Icon:SetTexCoords()
end

local function SkinReagentSlots(form)
	for _, slot in ipairs(form.reagentSlots) do
		local button = slot.Button
		if not button.isSkinned then
			S:HandleItemButton(button, true)
			S:HandleIconBorder(button.IconBorder)
		end
	end
end

local function LoadInspectRecipeSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.tradeskill then return end

	local InspectRecipeFrame = _G.InspectRecipeFrame
	if not (InspectRecipeFrame and InspectRecipeFrame.SchematicForm) then return end

	S:HandleSirusFrame(InspectRecipeFrame)

	local SchematicForm = InspectRecipeFrame.SchematicForm
	SchematicForm.NineSlice:Hide()
	SchematicForm:CreateBackdrop("Transparent")
	SchematicForm.Background:SetVertexColor(0.8, 0.8, 0.8)

	S:HandleCheckBox(SchematicForm.TrackRecipeCheckbox)

	local OutputIcon = SchematicForm.OutputIcon
	OutputIcon:SetAttribute("useCircularIconBorder", false)
	S:HandleIcon(OutputIcon.Icon, true)
	S:HandleIconBorder(OutputIcon.IconBorder, OutputIcon.Icon.backdrop)

	hooksecurefunc(OutputIcon, "UpdateOutputInfo", UpdateOutputIcon)
	hooksecurefunc(SchematicForm, "Init", SkinReagentSlots)
end

S:AddCallback("Skin_Tradeskill", LoadSkin)
S:AddCallback("Skin_InspectRecipe", LoadInspectRecipeSkin)
