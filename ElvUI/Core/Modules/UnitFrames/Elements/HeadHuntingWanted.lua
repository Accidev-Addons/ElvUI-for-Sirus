local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")

local ipairs = ipairs
local tinsert = tinsert
local pcall = pcall

local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local IsHeadHuntingWanted = C_Unit and C_Unit.IsHeadHuntingWanted

local WANTED_MODEL = "SPELLS/DarkmoonVengeance_Impact_Head.m2"

local frames = {}

local function PostUpdate(frame, event)
	if event == "OnShow" or event == "PLAYER_TARGET_CHANGED" then
		UF:Update_HeadHuntingWanted(frame)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function()
	for _, frame in ipairs(frames) do
		UF:Update_HeadHuntingWanted(frame)
	end
end)

if IsHeadHuntingWanted and eventFrame.RegisterCustomEvent then
	pcall(eventFrame.RegisterCustomEvent, eventFrame, "UNIT_HEADHUNTING_WANTED")
end

function UF:Construct_HeadHuntingWanted(frame)
	frame.PostUpdate = PostUpdate

	local wanted = CreateFrame("PlayerModel", nil, frame.RaisedElementParent)
	wanted:Size(100)
	wanted:Point("CENTER", frame.Health)
	wanted:Hide()

	tinsert(frames, frame)

	return wanted
end

function UF:Update_HeadHuntingWanted(frame)
	local wanted = frame.HeadHuntingWantedFrame
	if not wanted then return end

	local db = frame.db
	local unit = frame.unit

	if db and db.headHuntingWanted and db.headHuntingWanted.enable and IsHeadHuntingWanted
	and unit and UnitExists(unit) and UnitIsPlayer(unit) and IsHeadHuntingWanted(unit) then
		wanted:SetModel(WANTED_MODEL)
		wanted:SetPosition(3, 0, 1.9)
		wanted:Show()
	else
		wanted:Hide()
	end
end

function UF:Configure_HeadHuntingWanted(frame)
	local wanted = frame.HeadHuntingWantedFrame
	if not wanted then return end

	wanted:ClearAllPoints()
	wanted:Point("CENTER", frame.Health)

	UF:Update_HeadHuntingWanted(frame)
end
