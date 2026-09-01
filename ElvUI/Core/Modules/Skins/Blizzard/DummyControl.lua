local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.dummycontrol then return end

	local frame = _G.DummyControlFrame
	if not frame then return end

	S:HandleSirusFrame(frame)

	for _, record in ipairs({ frame.Info.RecordLatest, frame.Info.RecordBest }) do
		if record then
			if record.Label then
				record.Label:SetTextColor(1, 0.82, 0)
			end
			if record.Damage then
				record.Damage:SetTextColor(1, 1, 1)
			end
			if record.NoRecord then
				record.NoRecord:SetTextColor(0.6, 0.6, 0.6)
			end
			if record.SpecIcon then
				record.SpecIcon:SetTexCoords()
				record.SpecIcon:CreateBackdrop("Default")
			end
		end
	end

	if frame.StartButton then
		S:HandleButton(frame.StartButton, true)
		if frame.StartButton.ButtonText then
			frame.StartButton.ButtonText:SetTextColor(1, 1, 1)
		end
	end

	local options = frame.Options
	if options then

		if options.Inset then
			S:HandleInsetFrame(options.Inset)
			options.Inset:SetTemplate("Transparent")
		end

		if options.Auras then
			options.Auras:SetTextColor(1, 0.82, 0)
		end

		for _, key in ipairs({
			"DummyModeDropdown", "DummyHealthDropdown", "StartDelayDropdown",
			"BloodlustDropdown", "AlchemyPotionDropdown", "FoodBuffDropdown",
			"DemonBuffDropdown",
		}) do
			local dd = options[key]
			if dd then
				for _, texture in ipairs({ dd.Left, dd.Right, dd.Middle }) do
					if texture then texture:SetAlpha(0) end
				end
				dd:CreateBackdrop("Default")
				if dd.Label then
					dd.Label:SetTextColor(1, 0.82, 0)
				end
				if dd.Text then
					dd.Text:SetTextColor(1, 1, 1)
				end
				if dd.Button then
					S:HandleNextPrevButton(dd.Button, "down", nil, true)
				end
			end
		end

		for _, key in ipairs({
			"MortalCheckButton", "AlchemyFlaskCheckButton", "ReplenishManaCheckButton",
			"DummyDebuffsCheckButton", "ShatteringThrowDebuffCheckButton",
			"HunterMarkImprovedDebuffCheckButton", "LadderCheckButton",
		}) do
			local cb = options[key]
			if cb then
				S:HandleCheckBox(cb)
				if cb.ButtonText then
					cb.ButtonText:SetTextColor(1, 1, 1)
				end
			end
		end
	end

	S:ApplyElvUIFont(frame)
end

S:AddCallback("Skin_DummyControl", LoadSkin)
