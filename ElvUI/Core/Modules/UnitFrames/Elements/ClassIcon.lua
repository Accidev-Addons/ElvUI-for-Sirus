local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")
local ElvUF = E.oUF

local select, unpack = select, unpack

local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS

local function Update(self, _, unit)
	local element = self.ClassIcon
	local coords = UnitIsPlayer(unit) and CLASS_ICON_TCOORDS[select(2, UnitClass(unit))]

	if coords then
		element:SetTexCoord(unpack(coords))
		element:Show()
	else
		element:Hide()
	end
end

local function Enable(self)
	if self.ClassIcon then
		return true
	end
end

local function Disable(self)
	self.ClassIcon:Hide()
end

ElvUF:AddElement("ClassIcon", Update, Enable, Disable)

function UF:Construct_ClassIcon(frame)
	local icon = frame.RaisedElementParent:CreateTexture(nil, "ARTWORK")
	icon:SetTexture([[Interface\WorldStateFrame\Icons-Classes]])
	icon:Hide()

	return icon
end

function UF:Configure_ClassIcon(frame)
	local db = frame.db.classIcon

	if db.enable then
		if not frame:IsElementEnabled("ClassIcon") then
			frame:EnableElement("ClassIcon")
		end

		local icon = frame.ClassIcon
		icon:Size(db.size)
		icon:ClearAllPoints()
		icon:Point("CENTER", frame, "TOP", db.xOffset, db.yOffset)
	elseif frame:IsElementEnabled("ClassIcon") then
		frame:DisableElement("ClassIcon")
	end
end
