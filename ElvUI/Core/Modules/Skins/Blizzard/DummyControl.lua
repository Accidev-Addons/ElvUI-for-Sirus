local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.dummycontrol then return end

	local frame = _G.DummyControlFrame
	if not frame then return end

	S:HandleSirusFrame(frame)

	for _, record in ipairs({ frame.Info.RecordLatest, frame.Info.RecordBest }) do
		if record then
			if record.Label then
				local _, size, flags = record.Label:GetFont()
				record.Label:SetFont(E.media.normFont, size or 12, flags or "")
				record.Label:SetTextColor(1, 0.82, 0)
			end
			if record.Damage then
				local _, size, flags = record.Damage:GetFont()
				record.Damage:SetFont(E.media.normFont, size or 12, flags or "")
				record.Damage:SetTextColor(1, 1, 1)
			end
			if record.NoRecord then
				local _, size, flags = record.NoRecord:GetFont()
				record.NoRecord:SetFont(E.media.normFont, size or 12, flags or "")
				record.NoRecord:SetTextColor(0.6, 0.6, 0.6)
			end
			if record.SpecIcon then
				record.SpecIcon:SetTexCoord(unpack(E.TexCoords))
				record.SpecIcon:CreateBackdrop("Default")
			end
		end
	end

	if frame.StartButton then
		S:HandleButton(frame.StartButton, true)
		if frame.StartButton.ButtonText then
			local _, size, flags = frame.StartButton.ButtonText:GetFont()
			frame.StartButton.ButtonText:SetFont(E.media.normFont, size or 12, flags or "")
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
			local _, size, flags = options.Auras:GetFont()
			options.Auras:SetFont(E.media.normFont, size or 12, flags or "")
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
					local _, size, flags = dd.Label:GetFont()
					dd.Label:SetFont(E.media.normFont, size or 12, flags or "")
					dd.Label:SetTextColor(1, 0.82, 0)
				end
				if dd.Text then
					local _, size, flags = dd.Text:GetFont()
					dd.Text:SetFont(E.media.normFont, size or 12, flags or "")
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
					local _, size, flags = cb.ButtonText:GetFont()
					cb.ButtonText:SetFont(E.media.normFont, size or 12, flags or "")
					cb.ButtonText:SetTextColor(1, 1, 1)
				end
			end
		end
	end

	S:ApplyElvUIFont(frame)
end

S:AddCallback("Skin_DummyControl", LoadSkin)
