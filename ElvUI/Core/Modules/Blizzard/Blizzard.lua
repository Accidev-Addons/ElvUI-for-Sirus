local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local next = next

local UIParent = UIParent
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local CreateFrame = CreateFrame
local GetRewardXP = GetRewardXP
local GetQuestLogRewardXP = GetQuestLogRewardXP
local IsAddOnLoaded = IsAddOnLoaded
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver

function BL:QuestXPPercent()
	if not E.db.general.questXPPercent then return end

	local unitXP, unitXPMax = UnitXP('player'), UnitXPMax('player')
	local xp = GetRewardXP() or GetQuestLogRewardXP()
	if xp and xp > 0 then
		local text = _G.QuestInfoXPFrameReceiveText:GetText()
		if text then _G.QuestInfoXPFrameReceiveText:SetFormattedText('%s (|cff4beb2c+%.2f%%|r)', text, (((unitXP + xp) / unitXPMax) - (unitXP / unitXPMax))*100) end
	end
end

function BL:ADDON_LOADED(_, addon)
	if addon == 'Blizzard_GuildBankUI' then
		BL.GuildBankHooked = true

		BL:ImproveGuildBank()
	elseif addon == 'Blizzard_TradeSkillUI' then
		BL.TradeSkillHooked = true
	end

	if BL.GuildBankHooked and BL.TradeSkillHooked then
		BL:UnregisterEvent('ADDON_LOADED')
	end
end

function BL:Initialize()
	BL.Initialized = true

	BL:EnhanceColorPicker()
	BL:AlertMovers()
	BL:HandleMiscFrames()
	BL:PositionCaptureBar()
	BL:PositionAlwaysUpFrame()

	BL:RegisterEvent('ADDON_LOADED')

	BL:PositionVehicleFrame()

	for _, addon in next, { 'Blizzard_GuildBankUI', 'Blizzard_TradeSkillUI' } do
		if IsAddOnLoaded(addon) then
			BL:ADDON_LOADED(nil, addon)
		end
	end

end

E:RegisterModule(BL:GetName())