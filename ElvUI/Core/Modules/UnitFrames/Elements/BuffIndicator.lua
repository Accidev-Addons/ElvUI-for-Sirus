local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")
local LSM = E.Libs.LSM

--Lua functions
local assert, select, pairs, unpack = assert, select, pairs, unpack
local tinsert, wipe = tinsert, wipe
--WoW API / Variables
local CreateFrame = CreateFrame
local CreateObjectPool = CreateObjectPool
local GetSpellInfo = GetSpellInfo

local function AuraWatchIconCreate(pool)
	local icon = CreateFrame("Frame", nil, pool.parent)

	icon.icon = icon:CreateTexture(nil, "BORDER")
	icon.icon:SetAllPoints(icon)

	local textParent = CreateFrame("Frame", nil, icon)
	textParent:OffsetFrameLevel(50, icon)
	icon.text = textParent:CreateFontString(nil, "BORDER")
	icon.text:FontTemplate()

	icon.border = icon:CreateTexture(nil, "BACKGROUND")
	icon.border:Point("TOPLEFT", -E.mult, E.mult)
	icon.border:Point("BOTTOMRIGHT", E.mult, -E.mult)
	icon.border:SetTexture(E.media.blankTex)
	icon.border:SetVertexColor(0, 0, 0)

	icon.cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	icon.cd:SetAllPoints(icon)
	icon.cd.noOCC = true
	icon.cd.noCooldownCount = true
	icon.cd:SetReverse(true)
	icon.cd:OffsetFrameLevel(nil, icon)

	icon.count = icon:CreateFontString(nil, "OVERLAY")
	icon.count:FontTemplate()

	return icon
end

local function AuraWatchIconRelease(_, icon)
	icon:SetScript("OnUpdate", nil)
	icon.timeLeft = nil
	icon.count:SetText()
	icon.text:SetText()
	icon:ClearAllPoints()
	icon:Hide()
end

function UF:Construct_AuraWatch(frame)
	local auras = CreateFrame("Frame", nil, frame)
	auras:OffsetFrameLevel(10, frame.RaisedElementParent)
	auras:SetInside(frame.Health)
	auras.presentAlpha = 1
	auras.missingAlpha = 0
	auras.strictMatching = false
	auras.icons = {}
	auras.pool = CreateObjectPool(AuraWatchIconCreate, AuraWatchIconRelease)
	auras.pool.parent = auras

	return auras
end

local counterOffsets = {
	["TOPLEFT"] = {6, 1},
	["TOPRIGHT"] = {-6, 1},
	["BOTTOMLEFT"] = {6, 1},
	["BOTTOMRIGHT"] = {-6, 1},
	["LEFT"] = {6, 1},
	["RIGHT"] = {-6, 1},
	["TOP"] = {0, 0},
	["BOTTOM"] = {0, 0}
}

local textCounterOffsets = {
	["TOPLEFT"] = {"LEFT", "RIGHT", -2, 0},
	["TOPRIGHT"] = {"RIGHT", "LEFT", 2, 0},
	["BOTTOMLEFT"] = {"LEFT", "RIGHT", -2, 0},
	["BOTTOMRIGHT"] = {"RIGHT", "LEFT", 2, 0},
	["LEFT"] = {"LEFT", "RIGHT", -2, 0},
	["RIGHT"] = {"RIGHT", "LEFT", 2, 0},
	["TOP"] = {"RIGHT", "LEFT", 2, 0},
	["BOTTOM"] = {"RIGHT", "LEFT", 2, 0}
}

function UF:UpdateAuraWatchFromHeader(group, petOverride)
	assert(self[group], "Invalid group specified.")
	group = self[group]
	for i = 1, group:GetNumChildren() do
		local frame = select(i, group:GetChildren())
		if frame and frame.Health then
			UF:UpdateAuraWatch(frame, petOverride, group.db)
		elseif frame then
			for n = 1, frame:GetNumChildren() do
				local child = select(n, frame:GetChildren())
				if child and child.Health then
					UF:UpdateAuraWatch(child, petOverride, group.db)
				end
			end
		end
	end
end

local buffs = {}
function UF:UpdateAuraWatch(frame, petOverride, db)
	wipe(buffs)
	local auras = frame.AuraWatch
	db = db and db.buffIndicator or frame.db.buffIndicator

	if not db.enable then
		auras:Hide()
		return
	else
		auras:Show()
	end

	if frame.unit == "pet" and not petOverride then
		local petWatch = E.global.unitframe.buffwatch.PET or {}
		for _, value in pairs(petWatch) do
			tinsert(buffs, value)
		end
	else
		local buffWatch = not db.profileSpecific and (E.global.unitframe.buffwatch[E.myclass] or {}) or (E.db.unitframe.filters.buffwatch or {})
		for _, value in pairs(buffWatch) do
			tinsert(buffs, value)
		end
	end

	auras.pool:ReleaseAll()
	wipe(auras.icons)

	local unitframeFont = LSM:Fetch("font", E.db.unitframe.font)

	for i = 1, #buffs do
		if buffs[i].id then
			local name, _, image = GetSpellInfo(buffs[i].id)
			if name then
				local icon = auras.pool:Acquire()
				icon.name = name
				icon.image = image
				icon.spellID = buffs[i].id
				icon.anyUnit = buffs[i].anyUnit
				icon.style = buffs[i].style
				icon.onlyShowMissing = buffs[i].onlyShowMissing
				icon.presentAlpha = icon.onlyShowMissing and 0 or 1
				icon.missingAlpha = icon.onlyShowMissing and 1 or 0
				icon.textThreshold = buffs[i].textThreshold or -1
				icon.displayText = buffs[i].displayText
				icon.decimalThreshold = buffs[i].decimalThreshold
				icon.size = db.size + (buffs[i].sizeOffset or 0)

				icon:Width(icon.size)
				icon:Height(icon.size)
				--Protect against missing .point value
				if not buffs[i].point then buffs[i].point = "TOPLEFT" end

				icon:ClearAllPoints()
				icon:Point(buffs[i].point or "TOPLEFT", frame.Health, buffs[i].point or "TOPLEFT", buffs[i].xOffset, buffs[i].yOffset)

				if icon.style == "coloredIcon" then
					icon.icon:SetTexture(E.media.blankTex)

					if buffs[i].color then
						icon.icon:SetVertexColor(buffs[i].color.r, buffs[i].color.g, buffs[i].color.b)
					else
						icon.icon:SetVertexColor(0.8, 0.8, 0.8)
					end
					icon.icon:Show()
					icon.border:Show()
					icon.cd:SetAlpha(1)
				elseif icon.style == "texturedIcon" then
					icon.icon:SetVertexColor(1, 1, 1)
					--icon.icon:SetTexCoord(.18, .82, .18, .82)
					icon.icon:SetTexCoords()
					icon.icon:SetTexture(icon.image)
					icon.icon:Show()
					icon.border:Show()
					icon.cd:SetAlpha(1)
				else
					icon.border:Hide()
					icon.icon:Hide()
					icon.cd:SetAlpha(0)
				end

				if icon.displayText then
					icon.text:Show()
					local r, g, b = 1, 1, 1
					if buffs[i].textColor then
						r, g, b = buffs[i].textColor.r, buffs[i].textColor.g, buffs[i].textColor.b
					end

					icon.text:SetTextColor(r, g, b)
				else
					icon.text:Hide()
				end

				icon.count:ClearAllPoints()
				if icon.displayText then
					local point, anchorPoint, x, y = unpack(textCounterOffsets[buffs[i].point])
					icon.count:Point(point, icon.text, anchorPoint, x, y)
				else
					icon.count:Point("CENTER", unpack(counterOffsets[buffs[i].point]))
				end

				icon.count:FontTemplate(unitframeFont, db.fontSize, E.db.unitframe.fontOutline)
				icon.text:FontTemplate(unitframeFont, db.fontSize, E.db.unitframe.fontOutline)
				icon.text:ClearAllPoints()
				icon.text:Point(buffs[i].point, icon, buffs[i].point)

				if buffs[i].enabled then
					auras.icons[buffs[i].id] = icon
					if auras.watched then
						auras.watched[buffs[i].id] = icon
					end
				else
					if auras.watched then
						auras.watched[buffs[i].id] = nil
					end
					auras.pool:Release(icon)
				end
			end
		end
	end

	if frame.AuraWatch.Update then
		frame.AuraWatch.Update(frame)
	end
end