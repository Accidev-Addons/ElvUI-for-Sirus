local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")

--Lua functions
--WoW API / Variables

function UF:Construct_ResurrectionIcon(frame)
	local holder = CreateFrame("Frame", nil, frame.RaisedElementParent)
	holder:OffsetFrameLevel(20, frame.RaisedElementParent)

	local tex = holder:CreateTexture(nil, "OVERLAY")
	tex:SetTexture([[Interface\AddOns\ElvUI\Core\Media\Textures\RaidIconRez]])
	tex:Point("CENTER", frame.Health, "CENTER")
	tex:Size(30)
	tex:Hide()

	return tex
end

function UF:Configure_ResurrectionIcon(frame)
	local RI = frame.ResurrectIndicator
	local db = frame.db

	if db.resurrectIcon.enable then
		if not frame:IsElementEnabled("ResurrectIndicator") then
			frame:EnableElement("ResurrectIndicator")
		end
		RI:Size(db.resurrectIcon.size)

		local attachPoint = self:GetObjectAnchorPoint(frame, db.resurrectIcon.attachToObject)
		RI:ClearAllPoints()
		RI:Point(db.resurrectIcon.attachTo, attachPoint, db.resurrectIcon.attachTo, db.resurrectIcon.xOffset, db.resurrectIcon.yOffset)
	else
		if frame:IsElementEnabled("ResurrectIndicator") then
			frame:DisableElement("ResurrectIndicator")
		end
	end
end