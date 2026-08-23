local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")

function UF:Construct_SummonIcon(frame)
	local tex = frame.RaisedElementParent.TextureParent:CreateTexture(nil, "OVERLAY")
	tex:Size(32)
	tex:Point("BOTTOM", frame.Health, "BOTTOM", 0, 2)
	tex:Hide()

	return tex
end

function UF:Configure_SummonIcon(frame)
	local SummonIndicator = frame.SummonIndicator
	local db = frame.db

	if db.summonIcon.enable then
		if not frame:IsElementEnabled("SummonIndicator") then
			frame:EnableElement("SummonIndicator")
		end

		local attachPoint = self:GetObjectAnchorPoint(frame, db.summonIcon.attachToObject)
		SummonIndicator:ClearAllPoints()
		SummonIndicator:Point(db.summonIcon.attachTo, attachPoint, db.summonIcon.attachTo, db.summonIcon.xOffset, db.summonIcon.yOffset)
		SummonIndicator:Size(db.summonIcon.size)
	else
		if frame:IsElementEnabled("SummonIndicator") then
			frame:DisableElement("SummonIndicator")
		end
	end
end
