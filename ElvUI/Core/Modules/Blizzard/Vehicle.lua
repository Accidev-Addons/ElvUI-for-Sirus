local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local GetVehicleUIIndicator = GetVehicleUIIndicator
local GetVehicleUIIndicatorSeat = GetVehicleUIIndicatorSeat

local hooked
local SetVehiclePoint

local function Vehicle_Regen()
	E:UnregisterEventForObject('PLAYER_REGEN_ENABLED', Vehicle_Regen, Vehicle_Regen)

	SetVehiclePoint()
end

function SetVehiclePoint()
	local indicator = _G.VehicleSeatIndicator
	if InCombatLockdown() and indicator:IsProtected() then
		E:RegisterEventForObject('PLAYER_REGEN_ENABLED', Vehicle_Regen, Vehicle_Regen)

		return
	end

	local clearAllPoints = indicator.ClearAllPointsBase or indicator.ClearAllPoints
	local setPoint = indicator.SetPointBase or indicator.SetPoint
	local mover = indicator.mover

	clearAllPoints(indicator)

	if mover then
		setPoint(indicator, 'TOPLEFT', mover, 'TOPLEFT', 0, 0)
	else
		setPoint(indicator, 'TOPRIGHT', _G.MinimapCluster, 'BOTTOMRIGHT', 0, 0)
	end
end

function BL:SetVehiclePosition(_, relativeTo)
	local mover = _G.VehicleSeatIndicator.mover
	if mover and relativeTo ~= mover then
		SetVehiclePoint()
	end
end

function BL:SetUpVehicle()
	local size = E.db.general.vehicleSeatIndicatorSize
	_G.VehicleSeatIndicator:Size(size)

	if not self then return end -- this is vehicleIndicatorID

	local _, numIndicators = GetVehicleUIIndicator(self)
	if numIndicators then
		local fourth = size * 0.25
		for i = 1, numIndicators do
			local button = _G['VehicleSeatIndicatorButton'..i]
			if button then
				local _, x, y = GetVehicleUIIndicatorSeat(self, i)
				button:ClearAllPoints()
				button:Point('CENTER', button:GetParent(), 'TOPLEFT', x * size, -y * size)
				button:Size(fourth)
			end
		end
	end
end

function BL:UpdateVehicleFrame()
	BL.SetUpVehicle(_G.VehicleSeatIndicator.currSkin)
end

function BL:PositionVehicleFrame()
	local indicator = _G.VehicleSeatIndicator
	if not hooked then
		hooksecurefunc(indicator, 'SetPoint', BL.SetVehiclePosition)
		hooksecurefunc('VehicleSeatIndicator_SetUpVehicle', BL.SetUpVehicle)

		SetVehiclePoint()
		indicator:Size(E.db.general.vehicleSeatIndicatorSize)

		E:CreateMover(indicator, 'VehicleSeatMover', L["Vehicle Seat Frame"], nil, nil, nil, nil, nil, 'general,blizzardImprovements')
		hooked = true
	end

	BL:UpdateVehicleFrame()
end
