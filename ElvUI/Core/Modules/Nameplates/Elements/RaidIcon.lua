local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule("NamePlates")

--Lua functions
--WoW API / Variables

function NP:Construct_RaidIcon(frame)
	local holder = CreateFrame("Frame", nil, frame)
	holder:Hide()

	local icon = holder:CreateTexture(nil, "OVERLAY")
	icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
	icon:Hide()

	return icon
end

function NP:Update_RaidIcon(frame)
	local icon = frame.RaidIcon
	if not icon then return end

	if not frame.RaidIconType then
		icon:Hide()
		icon:GetParent():Hide()
		return
	end

	SetRaidTargetIconTexture(icon, frame.RaidIconIndex or 1)
	icon:Show()
	icon:GetParent():Show()

	local db = self.db.units[frame.UnitType].raidTargetIndicator

	icon:SetSize(db.size, db.size)

	icon:ClearAllPoints()
	if frame.Health:IsShown() then
		icon:SetPoint(E.InversePoints[db.position], frame.Health, db.position, db.xOffset, db.yOffset)
	else
		icon:SetPoint("BOTTOM", frame, "TOP", 0, 15)
	end
end