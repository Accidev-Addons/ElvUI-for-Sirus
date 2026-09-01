local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.deathRecap then return end

	local frame = _G.DeathRecapFrame
	if not frame then return end

	frame:StripTextures()
	frame:SetTemplate("Transparent")

	S:HandleCloseButton(frame.CloseXButton, frame)
	S:HandleButton(frame.CloseButton)
	S:HandleButton(frame.HeadHuntingButton)

	for _, entry in ipairs(frame.DeathRecapEntry) do
		local spellInfo = entry.SpellInfo

		spellInfo.IconBorder:Kill()
		S:HandleIcon(spellInfo.Icon, true)
	end

	S:ApplyElvUIFontForce(frame)
end

S:AddCallback("Skin_DeathRecap", LoadSkin)
