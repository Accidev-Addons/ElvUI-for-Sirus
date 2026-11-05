local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')

local _G = _G
local next = next

local SharedXML_Model_OnMouseDown = SharedXML_Model_OnMouseDown
local SharedXML_Model_OnMouseUp = SharedXML_Model_OnMouseUp
local SharedXML_Model_OnMouseWheel = SharedXML_Model_OnMouseWheel
local SharedXML_Model_OnUpdate = SharedXML_Model_OnUpdate
local SharedXML_Model_Reset = SharedXML_Model_Reset
local SharedXML_Model_StartPanning = SharedXML_Model_StartPanning
local SharedXML_Model_StopPanning = SharedXML_Model_StopPanning

local MAX_ZOOM = 2.8

local function OnMouseDown(model, button)
	if button == 'RightButton' and not model.mouseDown then
		SharedXML_Model_StartPanning(model)
	else
		SharedXML_Model_OnMouseDown(model, button)
	end
end

local function OnMouseUp(model, button)
	if button == 'RightButton' and model.panning then
		SharedXML_Model_StopPanning(model)
	elseif model.mouseDown then
		SharedXML_Model_OnMouseUp(model, button)
	end
end

local function OnUpdate(model, elapsed)
	if model.mouseDown or model.panning then
		SharedXML_Model_OnUpdate(model, elapsed)
	end
end

local function OnHide(model)
	if model.panning then
		SharedXML_Model_StopPanning(model)
	end

	model.mouseDown = false
	SharedXML_Model_Reset(model)
end

function BL:ModelControls()
	if not E.private.general.modelControls then return end

	for _, name in next, { 'PetModelFrame', 'PetStableModel', 'CompanionModelFrame' } do
		local model = _G[name]
		if model then
			model.minZoom = _G.MODELFRAME_MIN_ZOOM
			model.maxZoom = MAX_ZOOM
			model.defaultRotation = _G.MODELFRAME_DEFAULT_ROTATION

			model:EnableMouse(true)
			model:EnableMouseWheel(true)
			model:SetScript('OnMouseDown', OnMouseDown)
			model:SetScript('OnMouseUp', OnMouseUp)
			model:SetScript('OnMouseWheel', SharedXML_Model_OnMouseWheel)
			model:HookScript('OnUpdate', OnUpdate)
			model:HookScript('OnHide', OnHide)
		end
	end
end
