local E = unpack(ElvUI)
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

local UPDATE_INTERVAL = 0.2

function NP:Clear_CustomTexts(frame)
	for _, text in pairs(frame.customTexts or {}) do
		frame:Untag(text)
		text.__previewUnit = nil
		text:SetText("")
		text:Hide()
	end
end

function NP:GetCustomTextAnchor(frame, point)
	local anchor = frame[point or "Health"]
	if point == "Frame" or not anchor then return frame end
	return anchor:IsShown() and anchor or frame.Health
end

function NP:GetTextLayerParent(frame, layer)
	frame.CustomTextParents = frame.CustomTextParents or {}

	local parent = frame.CustomTextParents[layer]
	if not parent then
		parent = CreateFrame("Frame", nil, frame)
		parent:SetAllPoints(frame)
		frame.CustomTextParents[layer] = parent
	end

	local castLevel = frame.CastBar and frame.CastBar:GetFrameLevel() or 0
	local baseLevel = math.max(frame:GetFrameLevel(), frame.Health:GetFrameLevel(), castLevel)
	parent:SetFrameLevel(baseLevel + E:GetDrawLayerLevel(layer))

	return parent
end

function NP:UpdateCustomTextMouseover(frame)
	local mouseover = frame.testUnitType or (frame.unit and UnitIsUnit and UnitIsUnit(frame.unit, "mouseover"))
	for _, text in pairs(frame.customTexts or {}) do
		if text.customMouseover then text:SetAlpha(mouseover and 1 or 0) end
	end
end

function NP:Configure_CustomTexts(frame)
	E.oUF.Tags:Attach(frame)
	frame.isNamePlate = true
	frame.customTexts = frame.customTexts or {}
	NP:Clear_CustomTexts(frame)

	local configs = self.db.units[frame.UnitType].customTexts or {}
	frame.customTextPool = frame.customTextPool or {}
	for name, text in pairs(frame.customTexts) do
		if not configs[name] or configs[name].enable == false then
			frame.customTexts[name] = nil
			text:ClearAllPoints()
			text:SetAlpha(1)
			text.frequentUpdates = nil
			text.customMouseover = nil
			table.insert(frame.customTextPool, text)
		end
	end
	local textParent
	for name, db in pairs(configs) do
		if db.enable ~= false then
			textParent = NP:GetTextLayerParent(frame, db.layer or "OVERLAY")
			local text = frame.customTexts[name] or table.remove(frame.customTextPool)
			if not text then
				text = textParent:CreateFontString(nil, "OVERLAY")
				text:SetWordWrap(false)
			end
			frame.customTexts[name] = text
			local anchor = NP:GetCustomTextAnchor(frame, db.attachTextTo or "Health")
			local font = db.font or self.db.font
			local size = db.size or self.db.fontSize or 12
			local outline = db.fontOutline or self.db.fontOutline or "OUTLINE"
			if text:GetParent() ~= textParent then text:SetParent(textParent) end
			text:FontTemplate(LSM:Fetch("font", font), size, outline)
			text:SetJustifyH(db.justifyH or "CENTER")
			text:ClearAllPoints()
			local point = db.position or db.justifyH or "CENTER"
			text:SetPoint(point, anchor, point, NP:Pixel(db.xOffset or 0), NP:Pixel(db.yOffset or 0))
			local tagFormat = db.text_format or ""
			text.customMouseover = tagFormat:find("%[mouseover%]") and true or nil
			if text.customMouseover then tagFormat = tagFormat:gsub("%[mouseover%]", "") end
			text.frequentUpdates = tagFormat ~= "" and UPDATE_INTERVAL or nil
			text.__previewUnit = frame.testUnitType and "player" or nil
			frame:Tag(text, tagFormat)
			text:SetAlpha(text.customMouseover and 0 or 1)
			text:Show()
			if frame.unit or text.__previewUnit then
				text:UpdateTag()
				if frame.testUnitType then
					if not text:GetText() or text:GetText() == "" then text:SetText(name) end
					frame:Untag(text)
					text.__previewUnit = nil
				end
			end
		end
	end
	NP:UpdateCustomTextMouseover(frame)
end
