local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local hooksecurefunc = _G.hooksecurefunc

local numSlots = _G.NUM_PET_STABLE_SLOTS or 10

local function UpdateSlotBorder(slot)
	local backdrop = slot and slot.backdrop
	if not backdrop then return end

	if slot.Checked and slot.Checked:IsShown() then
		backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	else
		backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

local function SkinSlot(slot)
	if not slot or slot.elvStableSlot then return end
	slot.elvStableSlot = true

	local icon = slot.IconTexture or slot.icon
	local background = slot.Background
	local border = slot.Border

	if background then background:SetAlpha(0) end
	if border then border:SetAlpha(0) end

	slot:CreateBackdrop('Default')
	slot:StyleButton()

	if icon then
		icon:SetInside(slot)
		icon:SetParent(slot.backdrop)
		icon:SetDrawLayer('ARTWORK')
		icon:SetTexCoords()
	end

	UpdateSlotBorder(slot)
end

local function UpdateAllBorders()
	UpdateSlotBorder(_G.PetStableCurrentPet)

	for i = 1, numSlots do
		UpdateSlotBorder(_G['PetStableStabledPet'..i])
	end
end

S:AddCallback('Skin_Stable', function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.stable then return end

	local frame = _G.PetStableFrame
	if not frame then return end

	S:HandleSirusFrame(frame, true)

	if frame.BottomInset then
		frame.BottomInset:StripTextures()
		S:HandleInsetFrame(frame.BottomInset)
	end

	S:HandleRotateButton(_G.PetStableModelRotateLeftButton)
	S:HandleRotateButton(_G.PetStableModelRotateRightButton)
	S:HandleButton(_G.PetStablePurchaseButton)

	SkinSlot(_G.PetStableCurrentPet)

	for i = 1, numSlots do
		SkinSlot(_G['PetStableStabledPet'..i])
	end

	local moneyBg = _G.PetStableMoneyBg
	if moneyBg then moneyBg:Kill() end

	local infoBlock = _G.PetStablePetInfoBlock
	local nameText = _G.PetStableNameText
	local levelText = _G.PetStableLevelText

	if infoBlock and nameText then
		nameText:ClearAllPoints()
		nameText:Point('TOPLEFT', infoBlock, 'TOPLEFT', 8, -8)
	end

	if infoBlock and levelText then
		levelText:ClearAllPoints()
		levelText:Point('BOTTOMLEFT', infoBlock, 'BOTTOMLEFT', 8, 2)
	end

	S:ApplyElvUIFont(frame)

	hooksecurefunc('PetStable_Update', UpdateAllBorders)

	hooksecurefunc('SetItemButtonTexture', function(button)
		if button and button.elvStableSlot and button.IconTexture then
			button.IconTexture:SetTexCoords()
		end
	end)
end)
