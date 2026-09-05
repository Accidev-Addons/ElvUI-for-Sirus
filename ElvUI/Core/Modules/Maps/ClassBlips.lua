local _G = _G
local E = unpack(_G.ElvUI)
local CB = E:GetModule('ClassBlips')

local UnitClass = _G.UnitClass
local UnitInParty = _G.UnitInParty
local MAX_PARTY_MEMBERS = _G.MAX_PARTY_MEMBERS
local MAX_RAID_MEMBERS = _G.MAX_RAID_MEMBERS

local UPDATE_INTERVAL = 0.5
local BLIP_RAID_Y_OFFSET = 0.5
local BLIP_TEX_COORDS = {
	WARRIOR = {0, 0.125, 0, 0.25},
	PALADIN = {0.125, 0.25, 0, 0.25},
	HUNTER = {0.25, 0.375, 0, 0.25},
	ROGUE = {0.375, 0.5, 0, 0.25},
	PRIEST = {0.5, 0.625, 0, 0.25},
	DEATHKNIGHT = {0.625, 0.75, 0, 0.25},
	SHAMAN = {0.75, 0.875, 0, 0.25},
	MAGE = {0.875, 1, 0, 0.25},
	WARLOCK = {0, 0.125, 0.25, 0.5},
	DRUID = {0.25, 0.375, 0.25, 0.5},
}

local function UpdateIcon(frame, raid)
	local unit = frame.unit
	if not unit then return end

	local _, class = UnitClass(unit)
	local coords = class and BLIP_TEX_COORDS[class]
	if not coords then return end

	local inParty = not raid or UnitInParty(unit)
	if frame.blipClass == class and frame.blipInParty == inParty then return end
	frame.blipClass, frame.blipInParty = class, inParty

	if inParty then
		frame.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	else
		frame.icon:SetTexCoord(coords[1], coords[2], coords[3] + BLIP_RAID_Y_OFFSET, coords[4] + BLIP_RAID_Y_OFFSET)
	end
end

local function CreateUpdater(partyPrefix, raidPrefix)
	return function(self, elapsed)
		if not self.blipInitialized then
			self.blipInitialized = true
			self.blipElapsed = UPDATE_INTERVAL
		else
			self.blipElapsed = (self.blipElapsed or 0) + elapsed
		end

		if self.blipElapsed < UPDATE_INTERVAL then return end
		self.blipElapsed = 0

		for i = 1, MAX_PARTY_MEMBERS do
			local frame = _G[partyPrefix..i]
			if frame and frame:IsShown() then
				UpdateIcon(frame)
			end
		end

		for i = 1, MAX_RAID_MEMBERS do
			local frame = _G[raidPrefix..i]
			if frame and frame:IsShown() then
				UpdateIcon(frame, true)
			end
		end
	end
end

local function SetupUnits(prefix, count, size, texture, raid)
	for i = 1, count do
		local frame = _G[prefix..i]
		if frame and frame.icon then
			frame.icon:SetTexture(texture)
			frame:Size(size)
			UpdateIcon(frame, raid)
		end
	end
end

function CB.Initialize()
	local texture = E.Media.Textures.PartyRaidBlips

	local minimap = _G.Minimap
	if minimap and minimap.SetClassBlipTexture then
		minimap:SetClassBlipTexture(texture)
	end

	SetupUnits('WorldMapParty', MAX_PARTY_MEMBERS, 24, texture)
	SetupUnits('WorldMapRaid', MAX_RAID_MEMBERS, 24, texture, true)

	if _G.WorldMapButton then
		_G.WorldMapButton:HookScript('OnUpdate', CreateUpdater('WorldMapParty', 'WorldMapRaid'))
	end

	if _G.BattlefieldMinimap then
		SetupUnits('BattlefieldMinimapParty', MAX_PARTY_MEMBERS, 16, texture)
		SetupUnits('BattlefieldMinimapRaid', MAX_RAID_MEMBERS, 16, texture, true)
		_G.BattlefieldMinimap:HookScript('OnUpdate', CreateUpdater('BattlefieldMinimapParty', 'BattlefieldMinimapRaid'))
	end
end

E:RegisterModule(CB:GetName())
