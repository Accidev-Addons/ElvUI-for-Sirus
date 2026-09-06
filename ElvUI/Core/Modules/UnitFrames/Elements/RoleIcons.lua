local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")

--Lua functions
local random = math.random
--WoW API / Variables
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local InCombatLockdown = InCombatLockdown
local UnitGUID = UnitGUID
local UnitIsConnected = UnitIsConnected

function UF:Construct_RoleIcon(frame)
	local tex = frame.RaisedElementParent.TextureParent:CreateTexture(nil, "ARTWORK")
	tex:Size(17)
	tex:Point("BOTTOM", frame.Health, "BOTTOM", 0, 2)
	tex.Override = UF.UpdateRoleIcon
	frame:RegisterEvent("PARTY_MEMBER_ENABLE", UF.UpdateRoleIcon, true)
	frame:RegisterEvent("PARTY_MEMBER_DISABLE", UF.UpdateRoleIcon, true)
	frame:RegisterEvent("RAID_ROSTER_UPDATE", UF.UpdateRoleIcon, true)

	return tex
end

local roleIconTextures = {
	TANK = E.Media.Textures.Tank,
	HEALER = E.Media.Textures.Healer,
	DAMAGER = E.Media.Textures.DPS
}

function UF:UpdateRoleIcon(event)
	local lfdrole = self.GroupRoleIndicator
	if not self.db then return end
	local db = self.db.roleIcon

	if (not db) or (db and not db.enable) then
		lfdrole:Hide()
		return
	end

	local isTank, isHealer, isDamage = UnitGroupRolesAssigned(self.unit)
	local role = isTank and "TANK" or isHealer and "HEALER" or isDamage and "DAMAGER" or "NONE"
	if role == "NONE" then
		role = E.GroupRoles[UnitGUID(self.unit)] or "NONE"
	end
	if self.isForced and role == "NONE" then
		local rnd = random(1, 3)
		role = rnd == 1 and "TANK" or (rnd == 2 and "HEALER" or (rnd == 3 and "DAMAGER"))
	end

	-- [SIRUS] Roster updates must keep roles hidden throughout combat.
	local shouldHide = db.combatHide and InCombatLockdown()

	if (self.isForced or UnitIsConnected(self.unit)) and ((role == "DAMAGER" and db.damager) or (role == "HEALER" and db.healer) or (role == "TANK" and db.tank)) then
		lfdrole:SetTexture(roleIconTextures[role])
		if not shouldHide then
			lfdrole:Show()
		else
			lfdrole:Hide()
		end
	else
		lfdrole:Hide()
	end
end

function UF:Configure_RoleIcon(frame)
	local role = frame.GroupRoleIndicator
	local db = frame.db

	if db.roleIcon.enable then
		frame:EnableElement("GroupRoleIndicator")
		local attachPoint = self:GetObjectAnchorPoint(frame, db.roleIcon.attachTo)

		role:ClearAllPoints()
		role:Point(db.roleIcon.position, attachPoint, db.roleIcon.position, db.roleIcon.xOffset, db.roleIcon.yOffset)
		role:Size(db.roleIcon.size)

		if db.roleIcon.combatHide then
			frame:RegisterEvent("PLAYER_REGEN_ENABLED", UF.UpdateRoleIcon, true)
			frame:RegisterEvent("PLAYER_REGEN_DISABLED", UF.UpdateRoleIcon, true)
		else
			frame:UnregisterEvent("PLAYER_REGEN_ENABLED", UF.UpdateRoleIcon)
			frame:UnregisterEvent("PLAYER_REGEN_DISABLED", UF.UpdateRoleIcon)
		end
	else
		frame:DisableElement("GroupRoleIndicator")
		role:Hide()
		--Unregister combat hide events
		frame:UnregisterEvent("PLAYER_REGEN_ENABLED", UF.UpdateRoleIcon)
		frame:UnregisterEvent("PLAYER_REGEN_DISABLED", UF.UpdateRoleIcon)
	end
end