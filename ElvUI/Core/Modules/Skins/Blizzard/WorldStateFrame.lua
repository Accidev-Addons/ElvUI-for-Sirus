local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local ipairs, unpack = ipairs, unpack

local function DeferCaptureBarWork(func)
	return function(id)
		C_Timer:After(0, function()
			local bar = _G["WorldStateCaptureBar"..id]
			if bar and bar.CanChangeProtectedState and not bar:CanChangeProtectedState() then return end

			func(id)
		end)
	end
end

S:AddCallback("Skin_WorldStateFrame", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.worldState then return end

	local function captureBarCreate(id)
		local bar = _G["WorldStateCaptureBar"..id]
		local leftBar = _G["WorldStateCaptureBar"..id.."LeftBar"]
		local rightBar = _G["WorldStateCaptureBar"..id.."RightBar"]
		local middleBar = _G["WorldStateCaptureBar"..id.."MiddleBar"]

		for i = 1, bar:GetNumRegions() do
			local region = select(i, bar:GetRegions())
			if region:GetObjectType() == "Texture" and not region:GetName() then
				region:SetTexture(nil)
			end
		end

		_G["WorldStateCaptureBar"..id.."LeftLine"]:SetTexture(nil)
		_G["WorldStateCaptureBar"..id.."RightLine"]:SetTexture(nil)

		_G["WorldStateCaptureBar"..id.."LeftIconHighlight"]:SetTexture(nil)
		_G["WorldStateCaptureBar"..id.."RightIconHighlight"]:SetTexture(nil)

		_G["WorldStateCaptureBar"..id.."Indicator"]:StripTextures()

		bar:Size(173, 16)
		bar:CreateBackdrop("Default")

		leftBar:Size(85, 16)
		leftBar:SetPoint("LEFT", 0, 0)
		leftBar:SetTexture(E.media.glossTex)
		leftBar:SetTexCoord(1, 0, 1, 0)
		leftBar:SetVertexColor(0, .44, .87)

		bar.leftBarIcon = bar:CreateTexture("$parentLeftBarIcon", "ARTWORK")
		bar.leftBarIcon:SetTexture([[Interface\AddOns\ElvUI\Core\Media\Textures\AllianceLogoSmall]])
		bar.leftBarIcon:SetPoint("RIGHT", bar, "LEFT", 0, 0)
		bar.leftBarIcon:SetSize(32, 32)

		rightBar:Size(85, 16)
		rightBar:SetPoint("RIGHT", 0, 0)
		rightBar:SetTexture(E.media.glossTex)
		rightBar:SetTexCoord(1, 0, 1, 0)
		rightBar:SetVertexColor(.77, .12, .23)

		bar.rightBarIcon = bar:CreateTexture("$parentRightBarIcon", "ARTWORK")
		bar.rightBarIcon:SetTexture([[Interface\AddOns\ElvUI\Core\Media\Textures\HordeLogoSmall]])
		bar.rightBarIcon:SetPoint("LEFT", bar, "RIGHT", 0, 0)
		bar.rightBarIcon:Size(32)

		middleBar:Size(25, 16)
		middleBar:SetTexture(E.media.glossTex)
		middleBar:SetTexCoord(1, 0, 1, 0)
		middleBar:SetVertexColor(1, 1, 1)

		bar.spark = CreateFrame("Frame", "$parentSpark", bar)
		bar.spark:SetTemplate("Default", true)
		bar.spark:Size(4, 18)
	end

	local topCenter = _G.WorldStateTopCenterFrame
	if topCenter then
		local barColors = { { 0, .44, .87 }, { .77, .12, .23 } }

		for id, bar in ipairs({ topCenter.LeftBar, topCenter.RightBar }) do
			bar.BG:SetTexture(E.ClearTexture)
			bar.BorderLeft:SetTexture(E.ClearTexture)
			bar.BorderRight:SetTexture(E.ClearTexture)
			bar.BorderCenter:SetTexture(E.ClearTexture)
			bar.SubLayer.Spark:SetTexture(E.ClearTexture)

			bar:CreateBackdrop("Transparent")

			bar.BarFillTexture:SetTexture(E.media.normTex)
			bar.BarFillTexture:SetTexCoord(0, 1, 0, 1)
			bar.BarFillTexture:SetVertexColor(unpack(barColors[id]))
			bar.BarFillTexture:Height(bar:GetHeight() - 2)

			bar.SubLayer.Label:FontTemplate()
		end

		topCenter.TimeLeft:FontTemplate()
		topCenter.BottomLabel:FontTemplate()
	end

	local numSkinnedCaptureBars = 0

	local function captureBarSkinsUpdate()
		local numFrames = _G.NUM_EXTENDED_UI_FRAMES or 0

		if numSkinnedCaptureBars >= numFrames then return end

		for id = numSkinnedCaptureBars + 1, numFrames do
			local bar = _G["WorldStateCaptureBar"..id]
			if not bar then return end

			DeferCaptureBarWork(captureBarCreate)(id)
			numSkinnedCaptureBars = id
		end
	end

	hooksecurefunc('WorldStateAlwaysUpFrame_Update', function()
		if numSkinnedCaptureBars < (_G.NUM_EXTENDED_UI_FRAMES or 0) then
			C_Timer:After(0, captureBarSkinsUpdate)
		end
	end)
end)