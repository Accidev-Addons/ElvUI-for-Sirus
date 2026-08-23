local E, L, V, P, G = unpack(ElvUI)
local AB = E:GetModule('ActionBars')

local _G = _G
local next = next
local wipe = wipe
local gsub = gsub
local unpack = unpack
local tinsert = tinsert
local tconcat = table.concat
local CreateFrame = CreateFrame
local RegisterStateDriver = RegisterStateDriver
local InCombatLockdown = InCombatLockdown
local hooksecurefunc = hooksecurefunc
local C_Texture = C_Texture

AB.MICRO_CLASSIC = {}
AB.MICRO_BUTTONS = {}

for i, name in ipairs(_G.MICRO_BUTTONS) do
	AB.MICRO_BUTTONS[i] = name
end

do
	local meep = 12.125
	-- GuildMicroButton and StoreMicroButton have no art in MicroBar.tga, they keep the game icon
	AB.MICRO_OFFSETS = {
		CharacterMicroButton		= 0.07 / meep,
		SpellbookMicroButton		= 1.05 / meep,
		TalentMicroButton			= 2.04 / meep,
		AchievementMicroButton		= 3.03 / meep,
		QuestLogMicroButton			= 4.02 / meep,
		SocialsMicroButton			= 5.01 / meep,
		LFDMicroButton				= 6.00 / meep,
		EncounterJournalMicroButton	= 6.99 / meep,
		CollectionsMicroButton		= 7.98 / meep,
		MainMenuMicroButton			= 10 / meep,
	}
end

local microBar = CreateFrame('Frame', 'ElvUI_MicroBar', E.UIParent)
microBar:SetSize(100, 100)

local function onLeaveBar()
	return AB.db.microbar.mouseover and E:UIFrameFadeOut(microBar, 0.2, microBar:GetAlpha(), 0)
end

local watcher = 0
local function onUpdate(self, elapsed)
	if watcher > 0.1 then
		if not self:IsMouseOver() then
			self.IsMouseOvered = nil
			self:SetScript('OnUpdate', nil)
			onLeaveBar()
		end
		watcher = 0
	else
		watcher = watcher + elapsed
	end
end

local function onEnter(button)
	if AB.db.microbar.mouseover and not microBar.IsMouseOvered then
		microBar.IsMouseOvered = true
		microBar:SetScript('OnUpdate', onUpdate)
		E:UIFrameFadeIn(microBar, 0.2, microBar:GetAlpha(), AB.db.microbar.alpha)
	end

	if button:IsEnabled() == 1 then
		button:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	end

	-- when we skin it the normal isn't baked into the highlight texture so readd it
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal then
		normal:SetAlpha(1)
	end

	-- bag keybind support from actionbar module
	if E.private.actionbar.enable then
		AB:BindUpdate(button, 'MICRO')
	end
end

local function onLeave(button)
	if button:IsEnabled() == 1 then
		button:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end


function AB:GetMicroCoords(name)
	local button = _G[name]
	local atlas = button and button.textureName and 'UI-HUD-MicroMenu-'..button.textureName..'-Up'
	if atlas and C_Texture.HasAtlasInfo(atlas) then
		local info = C_Texture.GetAtlasInfo(atlas)
		if info and info.filename then
			return info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord, info.filename
		end
	end

	local offset = AB.MICRO_OFFSETS[name]
	if not offset then
		return 0.17, 0.87, 0.5, 0.908
	end

	return offset, offset + 0.065, 0.41, 0.72
end

function AB:RestoreMicroTextures(button)
	local textureName = button.textureName
	if not textureName then return end

	-- повтор LoadMicroButtonTextures без записи button.textureName: её потом читают
	-- секьюрные SetNormal/SetPushed, и тейнт уходит вплоть до CastSpell в книге заклинаний
	local prefix = 'UI-HUD-MicroMenu-'
	button:SetNormalAtlas(prefix..textureName..'-Up')
	button:SetPushedAtlas(prefix..textureName..'-Down')
	button:SetDisabledAtlas(prefix..textureName..'-Disabled')
	button:SetHighlightAtlas(prefix..textureName..'-Mouseover')

	if button.Background then button.Background:SetAtlas(prefix..'ButtonBG-Up', true) end
	if button.PushedBackground then button.PushedBackground:SetAtlas(prefix..'ButtonBG-Down', true) end

	for _, key in next, { 'Background', 'PushedBackground', 'Shadow', 'PushedShadow' } do
		local region = button[key]
		if region then
			region:SetAlpha(0)
		end
	end

	for _, getter in next, { 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' } do
		local texture = button[getter] and button[getter](button)
		if texture then
			texture:SetInside(button.backdrop)
		end
	end

	return true
end

function AB:HandleMicroTextures(button, name)
	if AB:RestoreMicroTextures(button) then return end

	local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
	if highlight then
		highlight:SetTexture(1, 1, 1, 0.2)
	end

	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if not normal then -- no pushed yet either, probably character
		local pushed = button.GetPushedTexture and button:GetPushedTexture()
		if not pushed then
			button:SetPushedTexture(E.Media.Textures.White8x8)

			pushed = button.GetPushedTexture and button:GetPushedTexture()
			pushed:SetDrawLayer('OVERLAY', 1)
			pushed:SetAlpha(0.2)
			pushed:SetInside()
		end

		local color = E.media.rgbvaluecolor
		if color then
			pushed:SetVertexColor(color.r, color.g, color.b)
		end
	else
		local character = name == 'CharacterMicroButton' and E.Media.Textures.Black8x8
		local stock = AB.MICRO_CLASSIC[name] -- classic default icons from the game
		local pushed = button.GetPushedTexture and button:GetPushedTexture()
		if stock then
			normal:SetTexture(stock.normal)
			pushed:SetTexture(character or stock.pushed)
		elseif character then
			normal:SetTexture()
			pushed:SetTexture(character)
		end

		if character then
			pushed:SetDrawLayer('OVERLAY', 1)
			pushed:SetBlendMode('ADD')
			pushed:SetAlpha(0.25)
		end

		normal:SetInside(button.backdrop)
		pushed:SetInside(button.backdrop)

		local color = E.media.rgbvaluecolor
		if color then
			pushed:SetVertexColor(color.r * 1.5, color.g * 1.5, color.b * 1.5)
		end

		local disabled = button.GetDisabledTexture and button:GetDisabledTexture()
		if disabled then
			disabled:SetTexture(stock and stock.normal)
			disabled:SetDesaturated(true)
			disabled:SetInside(button.backdrop)
		end
	end
end

function AB:HandleMicroButton(button, name)
	if not button then return end

	button:SetTemplate()
	button:SetParent(microBar)
	button:HookScript('OnEnter', onEnter)
	button:HookScript('OnLeave', onLeave)
	button:SetHitRectInsets(0, 0, 0, 0)

	for _, key in next, { 'Background', 'PushedBackground', 'Shadow', 'PushedShadow' } do
		local region = button[key]
		if region then
			region:SetAlpha(0)
		end
	end

	local pushed = button.GetPushedTexture and button:GetPushedTexture()
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	AB.MICRO_CLASSIC[name] = {
		pushed = pushed and pushed:GetTexture(),
		normal = normal and normal:GetTexture()
	}

	AB:UpdateMicroButtonTexture(name)
end

function AB:UpdateMicroBarVisibility()
	local visibility = (AB.db.microbar.enabled and gsub(AB.db.microbar.visibility, '[\n\r]', '')) or 'hide'
	if visibility == microBar.visibilityString then return end

	if InCombatLockdown() then
		AB.NeedsUpdateMicroBarVisibility = true
		AB:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end

	microBar.visibilityString = visibility
	RegisterStateDriver(microBar.visibility, 'visibility', visibility)
end

do
	local buttons = {}
	function AB:ShownMicroButtons()
		wipe(buttons)

		for _, name in next, AB.MICRO_BUTTONS do
			local button = _G[name]
			if button and button:IsShown() then
				tinsert(buttons, name)
			end
		end

		return buttons
	end
end

function AB:UpdateMicroButtons()
	local db = AB.db.microbar
	microBar.db = db

	microBar.backdrop:SetShown(db.backdrop)
	microBar.backdrop:ClearAllPoints()

	AB:MoverMagic(microBar)

	local btns = AB:ShownMicroButtons()
	db.buttons = #btns
	microBar.buttonKey = tconcat(btns, ',')

	local buttonsPerRow = db.buttonsPerRow
	local backdropSpacing = db.backdropSpacing

	local _, horizontal, anchorUp, anchorLeft = AB:GetGrowth(db.point)
	local lastButton, anchorRowButton = microBar
	for i, name in next, btns do
		local button = _G[name]

		local columnIndex = i - buttonsPerRow
		local columnName = btns[columnIndex]
		local columnButton = _G[columnName]

		button.db = db

		if i == 1 or i == buttonsPerRow then
			anchorRowButton = button
		end

		button.handleBackdrop = true -- keep over HandleButton
		AB:HandleButton(microBar, button, i, lastButton, columnButton)

		lastButton = button
	end

	microBar:SetAlpha((db.mouseover and not microBar.IsMouseOvered and 0) or db.alpha)

	AB:HandleBackdropMultiplier(microBar, backdropSpacing, db.buttonSpacing, db.widthMult, db.heightMult, anchorUp, anchorLeft, horizontal, lastButton, anchorRowButton)
	AB:HandleBackdropMover(microBar, backdropSpacing)

	if microBar.mover then
		if AB.db.microbar.enabled then
			E:EnableMover(microBar.mover.name)
		else
			E:DisableMover(microBar.mover.name)
		end
	end

	AB:UpdateMicroBarVisibility()
end

function AB:MicroButtons_Update()
	if tconcat(AB:ShownMicroButtons(), ',') ~= microBar.buttonKey then
		AB:UpdateMicroButtons()
	end
end

function AB:UpdateMicroButtonTexture(name)
	local button = _G[name]
	if not button then return end

	AB:HandleMicroTextures(button, name)
end

function AB:HandleCharacterPortrait()
	self.Portrait:SetInside()
end

function AB:SetupMicroBar()
	microBar:CreateBackdrop(AB.db.transparent and 'Transparent', nil, nil, nil, nil, nil, nil, nil, 0)
	microBar:Point('TOPLEFT', E.UIParent, 'TOPLEFT', 4, -48)
	microBar:EnableMouse(false)

	microBar.visibility = CreateFrame('Frame', nil, E.UIParent, 'SecureHandlerStateTemplate')
	microBar.visibility:SetScript('OnShow', function() microBar:Show() end)
	microBar.visibility:SetScript('OnHide', function() microBar:Hide() end)

	for _, name in next, AB.MICRO_BUTTONS do
		local button = _G[name]
		if button then
			AB:HandleMicroButton(button, name)

			if name == 'MainMenuMicroButton' then
				hooksecurefunc(button, 'SetHighlightTexture', function()
					AB:UpdateMicroButtonTexture(name)
				end)
			elseif name == 'CharacterMicroButton' then
				if button.Portrait then
					button.Portrait:SetInside()
				end

				if button.SetPushed then hooksecurefunc(button, 'SetPushed', AB.HandleCharacterPortrait) end
				if button.SetNormal then hooksecurefunc(button, 'SetNormal', AB.HandleCharacterPortrait) end
			end
		end
	end

	-- With this method we might don't taint anything. Instead of using :Kill()
	local MenuPerformanceBar = _G.MainMenuBarPerformanceBar
	if MenuPerformanceBar then
		MenuPerformanceBar:SetAlpha(0)
		MenuPerformanceBar:Kill()
	end

	AB:SecureHook('UpdateMicroButtons', 'MicroButtons_Update')

	E:CreateMover(microBar, 'MicrobarMover', L["Micro Bar"], nil, nil, nil, 'ALL,ACTIONBARS', nil, 'actionbar,microbar')
end