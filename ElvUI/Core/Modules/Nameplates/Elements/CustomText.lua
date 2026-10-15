local E = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

-- Reuse the unit-frame tag engine, including ElvUI and third-party tags.
-- Only copy tag methods: a nameplate is not a spawned oUF unit frame.
function NP:Clear_CustomTexts(frame)
	for _, text in pairs(frame.customTexts or {}) do
		frame:Untag(text)
		text:SetText("")
		text:Hide()
	end
end

function NP:Configure_CustomTexts(frame)
	-- Libraries finish loading before ElvUI: their Private table is already gone.
	E.oUF.Tags:Attach(frame)
	frame.isNamePlate = true
	frame.customTexts = frame.customTexts or {}
	NP:Clear_CustomTexts(frame)

	local configs = self.db.units[frame.UnitType].customTexts
	for name, db in pairs(configs or {}) do
		if db.enable ~= false then
			local text = frame.customTexts[name]
			if not text then
				text = frame:CreateFontString(nil, "OVERLAY")
				text:SetWordWrap(false)
				frame.customTexts[name] = text
			end
			local anchor = frame[db.attachTextTo or "Health"] or frame.Health
			text:FontTemplate(LSM:Fetch("font", db.font), db.size, db.fontOutline)
			text:SetJustifyH(db.justifyH or "CENTER")
			text:ClearAllPoints()
			text:SetPoint(db.position or "CENTER", anchor, db.position or "CENTER", NP:Pixel(db.xOffset or 0), NP:Pixel(db.yOffset or 0))
			text.frequentUpdates = 0.2
			frame:Tag(text, db.text_format or "")
			text:Show()
			if frame.unit then text:UpdateTag() end
		end
	end
end
