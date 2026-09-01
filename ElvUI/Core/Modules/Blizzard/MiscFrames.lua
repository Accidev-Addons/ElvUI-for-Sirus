local E, L = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
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
	_G.DurabilityFrame:SetFrameStrata('HIGH')
	_G.DurabilityFrame:SetScale(0.6)

	if _G.DurabilityFrame.BreakFromFrameManager then
		_G.DurabilityFrame:BreakFromFrameManager()
	end

	if _G.DurabilityFrame.systemInfo then
		_G.DurabilityFrame.systemInfo.isInDefaultPosition = false
	end

	_G.DurabilityWeapon:Point('RIGHT', _G.DurabilityWrists, 'LEFT', 6, 0)
	_G.DurabilityShield:Point('LEFT', _G.DurabilityWrists, 'RIGHT', -6, 10)
	_G.DurabilityOffWeapon:Point('LEFT', _G.DurabilityWrists, 'RIGHT', -6, 0)
	_G.DurabilityRanged:Point('TOP', _G.DurabilityShield, 'BOTTOM', -1, 0)

	hooksecurefunc(_G.DurabilityFrame, 'SetPoint', function(self, _, point)
		if point ~= Minimap then
			self:ClearAllPoints()

			if _G.DurabilityShield:IsShown() or _G.DurabilityOffWeapon:IsShown() or _G.DurabilityRanged:IsShown() then
				self:Point('RIGHT', Minimap, 'RIGHT', -7, 0)
			else
				self:Point('RIGHT', Minimap, 'RIGHT', 8, 0)
			end
		end
	end)

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

    -- fix lfd cooldown frame taint
	do
		local handler = _G.LFDQueueFrameCooldownFrame:GetScript('OnEvent') or LFDQueueFrameRandomCooldownFrame_OnEvent

		if handler then
			_G.LFDQueueFrameCooldownFrame:SetScript('OnEvent', function(self, event, unit, ...)
				if event == 'UNIT_AURA' and not unit then return end
				handler(self, event, unit, ...)
			end)
		end
	end
end