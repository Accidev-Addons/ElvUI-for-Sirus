local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")

--Lua functions
--WoW API / Variables

function UF:Construct_CombatIndicator(frame)
	local holder = CreateFrame("Frame", nil, frame.RaisedElementParent)
	holder:OffsetFrameLevel(20, frame.RaisedElementParent)

	return holder:CreateTexture(nil, "OVERLAY")
end

function UF:Configure_CombatIndicator(frame)
	if not frame.VARIABLES_SET then return end
	local Icon = frame.CombatIndicator
	local db = frame.db.CombatIcon

	Icon:ClearAllPoints()
	Icon:Point("CENTER", frame.Health, db.anchorPoint, db.xOffset, db.yOffset)
	Icon:Size(db.size)

	if db.defaultColor then
		Icon:SetVertexColor(1, 1, 1, 1)
		Icon:SetDesaturated(false)
	else
		Icon:SetVertexColor(db.color.r, db.color.g, db.color.b, db.color.a)
		Icon:SetDesaturated(true)
	end

	local textures = E.Media.CombatIcons
	if db.texture == "CUSTOM" and db.customTexture then
		Icon:SetTexture(db.customTexture)
		Icon:SetTexCoord(0, 1, 0, 1)
	elseif db.texture ~= "DEFAULT" and textures[db.texture] then
		Icon:SetTexture(textures[db.texture])
		Icon:SetTexCoord(0, 1, 0, 1)
	else
		Icon:SetTexture(textures.DEFAULT)
		Icon:SetTexCoord(.5, 1, 0, .49)
	end

	if db.enable and not frame:IsElementEnabled("CombatIndicator") then
		frame:EnableElement("CombatIndicator")
	elseif not db.enable and frame:IsElementEnabled("CombatIndicator") then
		frame:DisableElement("CombatIndicator")
	end
end