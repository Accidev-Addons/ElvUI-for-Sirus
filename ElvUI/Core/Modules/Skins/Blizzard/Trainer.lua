local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.trainer then return end

	local ClassTrainerFrame = _G.ClassTrainerFrame
	S:HandleSirusFrame(ClassTrainerFrame)

	if ClassTrainerFrame.ListInset then ClassTrainerFrame.ListInset:StripTextures() end
	if ClassTrainerFrame.DetailsInset then ClassTrainerFrame.DetailsInset:StripTextures() end

	ClassTrainerExpandButtonFrame:StripTextures()

	S:HandleSirusButton(ClassTrainerFrame.FilterButton, true)

	local dropDown = ClassTrainerFrame.FilterDropDownMenu
	if dropDown then
		S:HandleDropDownBox(dropDown)
	end

	ClassTrainerListScrollFrame:StripTextures()
	S:HandleSirusScrollBar(ClassTrainerListScrollFrame.ScrollBar)

	ClassTrainerDetailScrollFrame:StripTextures()
	S:HandleSirusScrollBar(ClassTrainerDetailScrollFrame.ScrollBar)

	ClassTrainerSkillHighlight:SetTexture(E.Media.Textures.Highlight)
	ClassTrainerSkillHighlight:SetAlpha(0.35)

	ClassTrainerSkillIcon:StripTextures()
	ClassTrainerSkillIcon:StyleButton(nil, true)
	ClassTrainerSkillIcon:SetTemplate("Default")

	S:HandleCollapseExpandButton(ClassTrainerCollapseAllButton, "+", nil, nil, 1)

	for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
		local skillButton = _G["ClassTrainerSkill"..i]
		local highlight = _G["ClassTrainerSkill"..i.."Highlight"]

		S:HandleCollapseExpandButton(skillButton, "+", nil, nil, 1)

		if highlight then
			highlight:SetTexture("")
			highlight.SetTexture = E.noop
		end
	end

	S:HandleSirusButton(ClassTrainerCancelButton)
	S:HandleSirusButton(ClassTrainerTrainButton)

	ClassTrainerMoneyBg:StripTextures()

	hooksecurefunc("ClassTrainer_SetSelection", function()
		local skillIcon = ClassTrainerSkillIcon:GetNormalTexture()
		if skillIcon then
			skillIcon:SetInside()
			skillIcon:SetTexCoords()
		end
	end)
end

S:AddCallbackForAddon("Blizzard_TrainerUI", "Skin_Blizzard_TrainerUI", LoadSkin)
