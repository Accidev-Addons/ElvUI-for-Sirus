local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')
local TT = E:GetModule('Tooltip')

local _G = _G
local next = next
local hooksecurefunc = hooksecurefunc

local function RestyleTooltip(tt)
	if tt.restyling or not tt.template then return end

	tt.restyling = true
	TT:SetStyle(tt)
	tt.restyling = nil
end

local function ResetBackdropColor(tt, r, g, b)
	local color = _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR
	if color and r == color.r and g == color.g and b == color.b then
		RestyleTooltip(tt)
	end
end

local function ResetBorderColor(tt, r, g, b)
	local color = _G.TOOLTIP_DEFAULT_COLOR
	if color and r == color.r and g == color.g and b == color.b then
		RestyleTooltip(tt)
	end
end

function S:StyleTooltips()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.tooltip) then return end

	for _, tt in next, {
		_G.ItemRefTooltip,
	} do
		if TT:IsHooked(tt, 'OnSizeChanged') then return end
		TT:SecureHookScript(tt, 'OnSizeChanged', 'SetStyle')
	end

	for _, tt in next, {
		_G.AutoCompleteBox,
		_G.ConsolidatedBuffsTooltip,
		_G.DataTextTooltip,
		_G.FriendsTooltip,
		_G.GameTooltip,
		_G.ItemRefTooltip,
		_G.ItemRefShoppingTooltip1,
		_G.ItemRefShoppingTooltip2,
		_G.ItemRefShoppingTooltip3,
		_G.ShoppingTooltip1,
		_G.ShoppingTooltip2,
		_G.ShoppingTooltip3,
		_G.WorldMapTooltip,
		_G.WorldMapCompareTooltip1,
		_G.WorldMapCompareTooltip2,
		_G.WorldMapCompareTooltip3,
		-- ours
		E.ConfigTooltip,
		E.SpellBookTooltip,
		-- libs
		_G.LibDBIconTooltip,
	} do
		if TT:IsHooked(tt, 'OnShow') then return end
		TT:SecureHookScript(tt, 'OnShow', 'SetStyle')
	end
end

function S:TooltipFrames()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.tooltip) then return end

	S:StyleTooltips()
	S:HandleCloseButton(_G.ItemRefCloseButton)

	for _, tt in next, { _G.GameTooltip, _G.ItemRefTooltip, _G.WorldMapTooltip } do
		hooksecurefunc(tt, 'SetBackdropColor', ResetBackdropColor)
		hooksecurefunc(tt, 'SetBackdropBorderColor', ResetBorderColor)
	end

	-- Skin GameTooltip Status Bar
	_G.GameTooltipStatusBar:SetStatusBarTexture(E.media.normTex)
	_G.GameTooltipStatusBar:CreateBackdrop('Transparent')
	_G.GameTooltipStatusBar:ClearAllPoints()
	_G.GameTooltipStatusBar:Point('TOPLEFT', _G.GameTooltip, 'BOTTOMLEFT', E.Border, -(E.Spacing * 3))
	_G.GameTooltipStatusBar:Point('TOPRIGHT', _G.GameTooltip, 'BOTTOMRIGHT', -E.Border, -(E.Spacing * 3))
	E:RegisterStatusBar(_G.GameTooltipStatusBar)

	-- Tooltip Styling
	TT:SecureHook('GameTooltip_ShowStatusBar') -- Skin Status Bars
end

S:AddCallback('TooltipFrames')