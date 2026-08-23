local E, L, V, P, G = unpack(ElvUI)
local DB = E:GetModule('DataBars')

local format = format
local ipairs = ipairs
local pcall = pcall

local CreateFrame = CreateFrame
local UnitIsPVP = UnitIsPVP
local GameTooltip = GameTooltip
local TogglePVPUIFrame = TogglePVPUIFrame
local GetRatedBattlegroundRankInfo = (C_PvP and C_PvP.GetRatedBattlegroundRankInfo) or GetRatedBattlegroundRankInfo

local PVP_YOUR_RATING = PVP_YOUR_RATING
local RBG_SCORE_TOOLTIP_RANK = RBG_SCORE_TOOLTIP_RANK
local RATED_BATTLEGROUND_LABEL = RATED_BATTLEGROUND_LABEL
local RATED_BATTLEGROUND_NORANK = RATED_BATTLEGROUND_NORANK
local RATED_BATTLEGROUND_TOOLTIP_NEXTRANK = RATED_BATTLEGROUND_TOOLTIP_NEXTRANK

local MAX_RBG_RANK = 14
local HonorEvents = { 'PLAYER_ENTERING_WORLD', 'PLAYER_FLAGS_CHANGED', 'UNIT_FACTION', 'PLAYER_BATTLEGROUND_STATS_UPDATE' }
local eventFrame

local function RegisterHonorEvents()
	if not eventFrame then return end

	for _, event in ipairs(HonorEvents) do
		pcall(eventFrame.RegisterEvent, eventFrame, event)

		if eventFrame.RegisterCustomEvent and not eventFrame:IsEventRegistered(event) then
			pcall(eventFrame.RegisterCustomEvent, eventFrame, event)
		end
	end
end

local function UnregisterHonorEvents()
	if not eventFrame then return end

	for _, event in ipairs(HonorEvents) do
		pcall(eventFrame.UnregisterEvent, eventFrame, event)

		if eventFrame.UnregisterCustomEvent then
			pcall(eventFrame.UnregisterCustomEvent, eventFrame, event)
		end
	end
end

local function GetHonorInfo()
	local title, base, rank, _, cur, _, _, _, max = GetRatedBattlegroundRankInfo()

	title, base, rank = title or RATED_BATTLEGROUND_NORANK, base or 0, rank or 0
	cur, max = cur or 0, max or 0

	if cur < base then cur = base end

	if rank >= MAX_RBG_RANK or max <= base then
		return title, rank, cur, max, 1, 1, true
	end

	return title, rank, cur, max, cur - base, max - base, false
end

function DB:HonorBar_Update(event, unit)
	local bar = DB.StatusBars.Honor
	if not bar or not bar.db then return end
	if event == 'UNIT_FACTION' and unit ~= 'player' then return end

	DB:SetVisibility(bar)

	if not bar.db.enable or bar:ShouldHide() then return end

	local color = DB.db.colors.honor
	bar:SetStatusBarColor(color.r, color.g, color.b, color.a)

	local title, rank, cur, max, value, range, maxRank = GetHonorInfo()
	local percent, remaining = value / range * 100, max - cur

	bar:SetMinMaxValues(0, range)
	bar:SetValue(value)

	local displayString, textFormat = '', bar.db.textFormat

	if textFormat ~= 'NONE' then
		if maxRank then
			displayString = title
		elseif textFormat == 'PERCENT' then
			displayString = format('%d%%', percent)
		elseif textFormat == 'CURMAX' then
			displayString = format('%d - %d', cur, max)
		elseif textFormat == 'CURPERC' then
			displayString = format('%d - %d%%', cur, percent)
		elseif textFormat == 'CUR' then
			displayString = format('%d', cur)
		elseif textFormat == 'REM' then
			displayString = format('%d', remaining)
		elseif textFormat == 'CURREM' then
			displayString = format('%d - %d', cur, remaining)
		elseif textFormat == 'CURPERCREM' then
			displayString = format('%d - %d%% (%d)', cur, percent, remaining)
		end

		if bar.db.showRank then
			displayString = format('%s %d : %s', L["Rank"], rank, displayString)
		end
	end

	bar.text:SetText(displayString)
end

function DB:HonorBar_OnEnter()
	if self.db.mouseover then
		E:UIFrameFadeIn(self, 0.4, self:GetAlpha(), 1)
	end

	local title, rank, cur, max, value, range, maxRank = GetHonorInfo()

	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, 'ANCHOR_CURSOR', 0, -4)

	GameTooltip:AddLine(RATED_BATTLEGROUND_LABEL)
	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine(PVP_YOUR_RATING..':', format(RBG_SCORE_TOOLTIP_RANK, title, rank), 1, 1, 1)

	if not maxRank then
		local percent, remaining = value / range * 100, max - cur

		GameTooltip:AddDoubleLine(RATED_BATTLEGROUND_TOOLTIP_NEXTRANK, format(' %d / %d (%d%%)', cur, max, percent), 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Remaining:"], format(' %d (%d%% - %d '..L["Bars"]..')', remaining, 100 - percent, 20 * (range - value) / range), 1, 1, 1)
	end

	GameTooltip:Show()
end

function DB:HonorBar_OnClick()
	TogglePVPUIFrame()
end

function DB:HonorBar_Toggle()
	local bar = DB.StatusBars.Honor
	bar.db = DB.db.honor

	if bar.db.enable then
		E:EnableMover(bar.holder.mover.name)

		RegisterHonorEvents()

		DB:HonorBar_Update()
	else
		E:DisableMover(bar.holder.mover.name)

		UnregisterHonorEvents()

		DB:SetVisibility(bar)
	end
end

function DB:HonorBar()
	local Honor = DB:CreateBar('ElvUI_HonorBar', 'Honor', DB.HonorBar_Update, DB.HonorBar_OnEnter, DB.HonorBar_OnClick, {'TOPRIGHT', E.UIParent, 'TOPRIGHT', -3, -283})
	DB:CreateBarBubbles(Honor)

	Honor.ShouldHide = function()
		return (DB.db.honor.hideOutsidePvP and not UnitIsPVP('player')) or (DB.db.honor.hideBelowMaxLevel and not E:XPIsLevelMax())
	end

	eventFrame = CreateFrame('Frame')
	eventFrame:SetScript('OnEvent', function(_, event, unit) DB:HonorBar_Update(event, unit) end)

	E:CreateMover(Honor.holder, 'HonorBarMover', L["Honor Bar"], nil, nil, nil, nil, nil, 'databars,honor')

	DB:HonorBar_Toggle()
end
