local E, L = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local abs = abs
local UnitIsUnit = UnitIsUnit
local hooksecurefunc = hooksecurefunc

local Minimap_SetPing = Minimap_SetPing

local GetCVar = GetCVar

local MINIMAPPING_FADE_TIMER = MINIMAPPING_FADE_TIMER

do
	local slider = _G.SpellOverlay_SpellHighlightAlphaSlider
	if slider and not slider.value then
		slider.value = tonumber(GetCVar('spellActivationButtonOpacity')) or 1
	end
end

local DURABILITY_SCALE = 0.6

local function Durability_SetScale(frame)
	if abs(frame:GetScale() - DURABILITY_SCALE) > 0.001 then
		frame:SetScaleBase(DURABILITY_SCALE)
	end
end

local function Durability_SetPoint(frame, _, relativeTo)
	local minimap = _G.Minimap
	if relativeTo == minimap then return end

	local offset = (_G.DurabilityShield:IsShown() or _G.DurabilityOffWeapon:IsShown() or _G.DurabilityRanged:IsShown()) and -7 or 8

	frame:ClearAllPointsBase()
	frame:SetPointBase('RIGHT', minimap, 'RIGHT', E:Scale(offset), 0)
end

function BL:HandleMiscFrames()
	-- fix minimap ping
	_G.MinimapPing:HookScript('OnUpdate', function(self)
		if self.fadeOut or self.timer > MINIMAPPING_FADE_TIMER then
			Minimap_SetPing(_G.Minimap:GetPingPosition())
		end
	end)

	-- fix quest log frame level issues
	_G.QuestLogFrame:HookScript('OnShow', function()
		local questFrame = _G.QuestLogFrame:GetFrameLevel()
		local controlPanel = _G.QuestLogControlPanel:GetFrameLevel()
		local scrollFrame = _G.QuestLogDetailScrollFrame:GetFrameLevel()

		if questFrame >= controlPanel then
			_G.QuestLogControlPanel:SetFrameLevel(questFrame + 1)
		end
		if questFrame >= scrollFrame then
			_G.QuestLogDetailScrollFrame:SetFrameLevel(questFrame + 1)
		end
	end)

	-- hide ready check if you are the initiator
	_G.ReadyCheckFrame:HookScript('OnShow', function(self)
		if UnitIsUnit('player', self.initiator) then
			self:Hide()
		end
	end)

	-- durability frame
	local durability = _G.DurabilityFrame
	durability:SetFrameStrata('HIGH')
	durability:SetScaleBase(DURABILITY_SCALE)

	_G.DurabilityWeapon:Point('RIGHT', _G.DurabilityWrists, 'LEFT', 6, 0)
	_G.DurabilityShield:Point('LEFT', _G.DurabilityWrists, 'RIGHT', -6, 10)
	_G.DurabilityOffWeapon:Point('LEFT', _G.DurabilityWrists, 'RIGHT', -6, 0)
	_G.DurabilityRanged:Point('TOP', _G.DurabilityShield, 'BOTTOM', -1, 0)

	hooksecurefunc(durability, 'SetScale', Durability_SetScale)
	hooksecurefunc(durability, 'SetPoint', Durability_SetPoint)
	Durability_SetPoint(durability)

	-- kill the ui scale option
	_G.VideoOptionsResolutionPanelUseUIScale:Kill()
	_G.VideoOptionsResolutionPanelUIScaleSlider:Kill()

	-- gm ticket status
	_G.TicketStatusFrame:ClearAllPoints()
	_G.TicketStatusFrame:SetPoint('TOPLEFT', E.UIParent, 'TOPLEFT', 250, -5)

	E:CreateMover(_G.TicketStatusFrame, 'GMMover', L["GM Ticket Frame"])

	-- df ui bag bar
	if _G.BagsBar then
		_G.BagsBar:Kill()
	end

	-- df ui status tracking bars (reputation, experience)
	if _G.StatusTrackingBarManager then
		_G.StatusTrackingBarManager:Kill()
	end

	-- fix lfr browse frame taint
	_G.LFRParentFrame:HookScript('OnHide', function()
		_G.LFRBrowseFrame.timeToClear = nil
	end)
end