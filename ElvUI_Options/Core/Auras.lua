local E, _, V, P, G = unpack(ElvUI)
local C, L = unpack(E.Config)
local A = E:GetModule('Auras')
local ACH = E.Libs.ACH
local ACD = E.Libs.AceConfigDialog

local next, pairs, ipairs = next, pairs, ipairs
local tremove, tinsert, tconcat = tremove, tinsert, table.concat
local format, gsub, match, strsplit = string.format, string.gsub, string.match, strsplit
local CopyTable = CopyTable
local GetCVar = GetCVar

local DebuffColors = DebuffTypeColor

local SharedOptions = {
	showDuration = ACH:Toggle(L["Duration Enable"], nil, 1),
	smoothbars = ACH:Toggle(L["Smooth Bars"], L["Bars will transition smoothly."], 2),
	keepSizeRatio = ACH:Toggle(L["Keep Size Ratio"], nil, 3),
	spacer1 = ACH:Spacer(5, 'full'),

	growthDirection = ACH:Select(L["Growth Direction"], L["The direction the auras will grow and then the direction they will grow after they reach the wrap after limit."], 10, C.Values.GrowthDirection),
	sortMethod = ACH:Select(L["Sort Method"], L["Defines how the group is sorted."], 11, { INDEX = L["Index"], TIME = L["Time"], NAME = L["Name"] }),
	sortDir = ACH:Select(L["Sort Direction"], L["Defines the sort order of the selected sort method."], 12, { ['+'] = L["Ascending"], ['-'] = L["Descending"] }),
	seperateOwn = ACH:Select(L["Separate"], L["Indicate whether buffs you cast yourself should be separated before or after."], 13, { [-1] = L["Other's First"], [0] = L["No Sorting"], [1] = L["Your Auras First"] }),

	size = ACH:Range(L["Size"], L["Set the size of the individual auras."], 20, { min = 10, max = 80, step = 1 }),
	height = ACH:Range(L["Height"], L["Set the size of the individual auras."], 21, { min = 10, max = 80, step = 1 }),
	wrapAfter = ACH:Range(L["Wrap After"], L["Begin a new row or column after this many auras."], 22, { min = 1, max = 32, step = 1 }),
	maxWraps = ACH:Range(L["Max Wraps"], L["Limit the number of rows or columns."], 23, { min = 1, max = 32, step = 1 }),
	horizontalSpacing = ACH:Range(L["Horizontal Spacing"], nil, 24, { min = -5, max = 50, step = 1 }),
	verticalSpacing = ACH:Range(L["Vertical Spacing"], nil, 25, { min = -5, max = 50, step = 1 }),
	fadeThreshold = ACH:Range(L["Fade Threshold"], L["Threshold before the icon will fade out and back in. Set to -1 to disable."], 26, { min = -1, max = 30, step = 1 }),

	statusBar = ACH:Group(L["Statusbar"], nil, -3),
	timeGroup = ACH:Group(L["Time Text"], nil, -2),
	countGroup = ACH:Group(L["Count Text"], nil, -1),
}

SharedOptions.timeGroup.args.timeFont = ACH:SharedMediaFont(L["Font"], nil, 1)
SharedOptions.timeGroup.args.timeFontOutline = ACH:FontFlags(L["Font Outline"], L["Set the font outline."], 2)
SharedOptions.timeGroup.args.timeFontSize = ACH:Range(L["Font Size"], nil, 3, C.Values.FontSize)
SharedOptions.timeGroup.args.timeXOffset = ACH:Range(L["X-Offset"], nil, 4, { min = -60, max = 60, step = 1 })
SharedOptions.timeGroup.args.timeYOffset = ACH:Range(L["Y-Offset"], nil, 5, { min = -60, max = 60, step = 1 })

SharedOptions.countGroup.args.countFont = ACH:SharedMediaFont(L["Font"], nil, 1)
SharedOptions.countGroup.args.countFontOutline = ACH:FontFlags(L["Font Outline"], L["Set the font outline."], 2)
SharedOptions.countGroup.args.countFontSize = ACH:Range(L["Font Size"], nil, 3, C.Values.FontSize)
SharedOptions.countGroup.args.countXOffset = ACH:Range(L["X-Offset"], nil, 4, { min = -60, max = 60, step = 1 })
SharedOptions.countGroup.args.countYOffset = ACH:Range(L["Y-Offset"], nil, 5, { min = -60, max = 60, step = 1 })

do
	local notBarShow = function(info) local db = E.db.auras[info[#info-2]] if db then return not db.barShow end end
	SharedOptions.statusBar.args.barShow = ACH:Toggle(L["Enable"], nil, 1)
	SharedOptions.statusBar.args.barNoDuration = ACH:Toggle(L["No Duration"], nil, 2, nil, nil, nil, nil, nil, notBarShow)
	SharedOptions.statusBar.args.barTexture = ACH:SharedMediaStatusbar(L["Texture"], nil, 3, nil, nil, nil, notBarShow)
	SharedOptions.statusBar.args.barColor = ACH:Color(L.COLOR, nil, 4, true, nil, nil, nil, notBarShow)
	SharedOptions.statusBar.args.barColorGradient = ACH:Toggle(L["Color by Value"], nil, 5, nil, nil, nil, nil, nil, notBarShow)
	SharedOptions.statusBar.args.barPosition = ACH:Select(L["Position"], nil, 6, { TOP = L["Top"], BOTTOM = L["Bottom"], LEFT = L["Left"], RIGHT = L["Right"] }, nil, nil, nil, nil, notBarShow)
	SharedOptions.statusBar.args.barSize = ACH:Range(L["Size"], nil, 7, { min = 1, max = 10, step = 1 }, nil, nil, nil, notBarShow)
	SharedOptions.statusBar.args.barSpacing = ACH:Range(L["Spacing"], nil, 8, { min = -10, max = 10, step = 1 }, nil, nil, nil, notBarShow)
end

local Auras = ACH:Group(L["BUFFOPTIONS_LABEL"], nil, 2, 'tab', function(info) return E.private.auras[info[#info]] end, function(info, value) E.private.auras[info[#info]] = value; E.ShowPopup = true end)
E.Options.args.auras = Auras

Auras.args.intro = ACH:Description(L["AURAS_DESC"], 0)
Auras.args.enable = ACH:Toggle(L["Enable"], nil, 1)
Auras.args.buffsHeader = ACH:Toggle(L["Buffs"], nil, 2, nil, nil, 80)
Auras.args.debuffsHeader = ACH:Toggle(L["Debuffs"], nil, 3, nil, nil, 80)
Auras.args.disableBlizzard = ACH:Toggle(L["Disabled Blizzard"], nil, 4, nil, nil, 140)
Auras.args.cooldownShortcut = ACH:Execute(L["Cooldown Text"], nil, 5, function() E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'cooldown', 'auras') end)

Auras.args.colorGroup = ACH:MultiSelect(L["Colors"], nil, 6, { colorEnchants = L["Color Enchants"], colorDebuffs = L["Color Debuffs"] }, nil, nil, function(_, key) return E.db.auras[key] end, function(_, key, value) E.db.auras[key] = value end)

do
	Auras.args.debuffColors = ACH:Group(L["Debuff Colors"], nil, 7, nil, function(info) local t, d = E.db.general.debuffColors[info[#info]], P.general.debuffColors[info[#info]] return t.r, t.g, t.b, 1, d.r, d.g, d.b, 1 end, function(info, r, g, b) E:UpdateDispelColor(info[#info], r, g, b) end)
	Auras.args.debuffColors.args.spacer1 = ACH:Spacer(10, 'full')
	Auras.args.debuffColors.inline = true

	local order = { none = 0, Magic = 1, Curse = 2, Disease = 3, Poison = 4 }
	for key in next, DebuffColors do
		if key ~= '' then -- this is a reference to none
			Auras.args.debuffColors.args[key] = ACH:Color(L[key == 'none' and 'None' or key], nil, order[key] or -1, nil, 120)
		end
	end
end

Auras.args.buffs = ACH:Group(L["Buffs"], nil, 10, nil, function(info) return E.db.auras.buffs[info[#info]] end, function(info, value) E.db.auras.buffs[info[#info]] = value; A:UpdateHeader(A.BuffFrame) end, function() return not E.private.auras.buffsHeader end)
Auras.args.buffs.args = CopyTable(SharedOptions)
do
	local consolidateDisabled = function() return GetCVar('consolidateBuffs') ~= '1' end
	local consolidateGroup = ACH:Group(L["Consolidate Buffs"], nil, -4)
	consolidateGroup.args.description = ACH:Description(L["Buff consolidation is toggled by the 'Consolidate Buffs' checkbox in the game's Interface options."], 1)
	consolidateGroup.args.consolidateMax = ACH:Range(L["Max Consolidated"], L["Maximum amount of consolidated buffs shown in the popup."], 2, { min = 4, max = 32, step = 1 }, nil, nil, nil, consolidateDisabled)
	consolidateGroup.args.consolidateDirection = ACH:Select(L["Consolidate Direction"], L["The direction the consolidated buffs will grow."], 3, C.Values.GrowthDirection, nil, nil, nil, nil, consolidateDisabled)
	consolidateGroup.args.consolidateSize = ACH:Range(L["Consolidate Size"], L["Set the size of the icons in the consolidated buffs popup."], 4, { min = 12, max = 64, step = 1 }, nil, nil, nil, consolidateDisabled)

	Auras.args.buffs.args.consolidateGroup = consolidateGroup
end

Auras.args.buffs.args.size.name = function() return E.db.auras.buffs.keepSizeRatio and L["Size"] or L["Width"] end
Auras.args.buffs.args.height.hidden = function() return E.db.auras.buffs.keepSizeRatio end
Auras.args.buffs.args.keepSizeRatio.set = function(_, value) E.db.auras.buffs.keepSizeRatio = value if not value then E.db.auras.buffs.height = E.db.auras.buffs.size end A:UpdateHeader(A.BuffFrame) end
Auras.args.buffs.args.statusBar.args.barColor.get = function() local t = E.db.auras.buffs.barColor local d = P.auras.buffs.barColor return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a end
Auras.args.buffs.args.statusBar.args.barColor.set = function(_, r, g, b) local t = E.db.auras.buffs.barColor t.r, t.g, t.b = r, g, b end
Auras.args.buffs.args.statusBar.args.barColor.disabled = function() return not E.db.auras.buffs.barShow or E.db.auras.buffs.barColorGradient end

Auras.args.debuffs = ACH:Group(L["Debuffs"], nil, 11, nil, function(info) return E.db.auras.debuffs[info[#info]] end, function(info, value) E.db.auras.debuffs[info[#info]] = value; A:UpdateHeader(A.DebuffFrame) end, function() return not E.private.auras.debuffsHeader end)
Auras.args.debuffs.args = CopyTable(SharedOptions)
Auras.args.debuffs.args.size.name = function() return E.db.auras.debuffs.keepSizeRatio and L["Size"] or L["Width"] end
Auras.args.debuffs.args.height.hidden = function() return E.db.auras.debuffs.keepSizeRatio end
Auras.args.debuffs.args.keepSizeRatio.set = function(_, value) E.db.auras.debuffs.keepSizeRatio = value if not value then E.db.auras.debuffs.height = E.db.auras.debuffs.size end A:UpdateHeader(A.DebuffFrame) end
Auras.args.debuffs.args.statusBar.args.barColor.get = function() local t = E.db.auras.debuffs.barColor local d = P.auras.debuffs.barColor return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a end
Auras.args.debuffs.args.statusBar.args.barColor.set = function(_, r, g, b) local t = E.db.auras.debuffs.barColor t.r, t.g, t.b = r, g, b end
Auras.args.debuffs.args.statusBar.args.barColor.disabled = function() return not E.db.auras.debuffs.barShow or E.db.auras.debuffs.barColorGradient end

local carryFilterFrom, carryFilterTo

local function filterMatch(s, v)
	local m1, m2, m3, m4 = '^'..v..'$', '^'..v..',', ','..v..'$', ','..v..','
	return (match(s, m1) and m1) or (match(s, m2) and m2) or (match(s, m3) and m3) or (match(s, m4) and v..',')
end

local function filterPriority(auraType, value, remove, movehere)
	if not auraType or not value then return end
	local filter = E.db.auras[auraType] and E.db.auras[auraType].priority
	if not filter then return end
	local found = filterMatch(filter, E:EscapeString(value))
	if found and movehere then
		local tbl, sv, sm = {strsplit(',', filter)}
		for i in ipairs(tbl) do
			if tbl[i] == value then sv = i elseif tbl[i] == movehere then sm = i end
			if sv and sm then break end
		end
		tremove(tbl, sm)
		tinsert(tbl, sv, movehere)
		E.db.auras[auraType].priority = tconcat(tbl, ',')
	elseif found and remove then
		E.db.auras[auraType].priority = gsub(filter, found, '')
	elseif not found and not remove then
		E.db.auras[auraType].priority = (filter == '' and value) or (filter..','..value)
	end
end

local function UpdateAuraFrames()
	if A.BuffFrame then A:UpdateAllAuras(A.BuffFrame) end
	if A.DebuffFrame then A:UpdateAllAuras(A.DebuffFrame) end
end

local function GetFilterGroup(auraType)
	return {
		order = 30,
		type = 'group',
		name = L["Filters"],
		guiInline = true,
		args = {
			jumpToFilter = {
				order = 1,
				type = 'execute',
				name = L["Filters Page"],
				desc = L["Shortcut to global filters."],
				func = function() ACD:SelectGroup('ElvUI', 'filters') end
			},
			specialFilters = {
				order = 2,
				type = 'select',
				sortByValue = true,
				name = L["Add Special Filter"],
				desc = L["These filters don't use a list of spells like the regular filters. Instead they use the WoW API and some code logic to determine if an aura should be allowed or blocked."],
				values = function()
					local filters = {}
					local list = E.global.unitframe.specialFilters
					if not (list and next(list)) then return filters end
					for filter in pairs(list) do
						filters[filter] = L[filter]
					end
					return filters
				end,
				set = function(_, value)
					filterPriority(auraType, value)
					UpdateAuraFrames()
				end
			},
			filter = {
				order = 3,
				type = 'select',
				name = L["Add Regular Filter"],
				desc = L["These filters use a list of spells to determine if an aura should be allowed or blocked. The content of these filters can be modified in the 'Filters' section of the config."],
				values = function()
					local filters = {}
					local list = E.global.unitframe.aurafilters
					if not (list and next(list)) then return filters end
					for filter in pairs(list) do
						filters[filter] = filter
					end
					return filters
				end,
				set = function(_, value)
					filterPriority(auraType, value)
					UpdateAuraFrames()
				end
			},
			resetPriority = {
				order = 4,
				type = 'execute',
				name = L["Reset Priority"],
				desc = L["Reset filter priority to the default state."],
				func = function()
					E.db.auras[auraType].priority = P.auras[auraType].priority
					UpdateAuraFrames()
				end
			},
			filterPriority = {
				order = 5,
				type = 'multiselect',
				dragdrop = true,
				name = L["Filter Priority"],
				dragOnLeave = E.noop,
				dragOnEnter = function(info)
					carryFilterTo = info.obj.value
				end,
				dragOnMouseDown = function(info)
					carryFilterFrom, carryFilterTo = info.obj.value, nil
				end,
				dragOnMouseUp = function()
					filterPriority(auraType, carryFilterTo, nil, carryFilterFrom)
					carryFilterFrom, carryFilterTo = nil, nil
				end,
				dragOnClick = function()
					filterPriority(auraType, carryFilterFrom, true)
				end,
				stateSwitchGetText = function(_, text)
					local SF, localized = E.global.unitframe.specialFilters[text], L[text]
					local blockText = SF and localized and text:match('^block') and localized:gsub('^%[.-]%s?', '')
					return (blockText and format('|cFF999999%s|r %s', L["BLOCK"], blockText)) or localized or text
				end,
				values = function()
					local str = E.db.auras[auraType].priority
					if str == '' then return {} end
					return {strsplit(',', str)}
				end,
				get = function(_, value)
					local str = E.db.auras[auraType].priority
					if str == '' then return end
					local tbl = {strsplit(',', str)}
					return tbl[value]
				end,
				set = function()
					UpdateAuraFrames()
				end
			},
			spacer1 = {
				order = 6,
				type = 'description',
				name = L["Use drag and drop to rearrange filter priority or right click to remove a filter."]
			}
		}
	}
end

Auras.args.buffs.args.filtersGroup = GetFilterGroup('buffs')
Auras.args.debuffs.args.filtersGroup = GetFilterGroup('debuffs')

Auras.args.masqueGroup = ACH:Group(L["Masque"], nil, 13, nil, nil, nil, function() return not E.Masque or not E.private.auras.enable end)
Auras.args.masqueGroup.args.masque = ACH:MultiSelect(L["Masque Support"], L["Allow Masque to handle the skinning of this element."], 10, { buffs = L["Buffs"], debuffs = L["Debuffs"] }, nil, nil, function(_, key) return E.private.auras.masque[key] end, function(_, key, value) E.private.auras.masque[key] = value; E.ShowPopup = true end)
