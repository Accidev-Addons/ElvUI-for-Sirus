local E = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local ipairs = ipairs
local unpack = unpack
local hooksecurefunc = hooksecurefunc

local function SkinIcon(_, icon)
	icon:SetTemplate()
	icon.overlay:SetTemplate()
	icon.overlay.tex:SetInside()
	icon.tex:SetInside()
	icon.overlay.tex:SetTexCoord(unpack(E.TexCoords))
	icon.tex:SetTexCoord(unpack(E.TexCoords))
end

local function SkinBackdrop(bar)
	bar:SetTemplate('Transparent')
end

local function HookBar(bar)
	if bar.elvHooked then return end

	hooksecurefunc(bar, 'UpdateSingleIconLook', SkinIcon)
	hooksecurefunc(bar, 'UpdateBarBackdrop', SkinBackdrop)
	bar:UpdateBarLook()

	bar.elvHooked = true
end

function S:SexyCooldown()
	local SexyCooldown = _G.SexyCooldown

	for _, bar in ipairs(SexyCooldown.bars) do
		HookBar(bar)
	end

	hooksecurefunc(SexyCooldown, 'CreateBar', function(mod)
		HookBar(mod.bars[#mod.bars])
	end)
end

S:AddCallbackForAddon('SexyCooldown')
