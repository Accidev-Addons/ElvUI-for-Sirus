local E, L, V, P, G = unpack(ElvUI)
local AM = E:GetModule('AddonManager')
local S = E:GetModule('Skins')

local _G = _G

local CreateFrame = CreateFrame
local GetAddOnDependencies = GetAddOnDependencies
local GetAddOnInfo = GetAddOnInfo
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local GetAddOnMetadata = GetAddOnMetadata
local GetNumAddOns = GetNumAddOns
local EnableAddOn = EnableAddOn
local DisableAddOn = DisableAddOn
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsAddOnLoadOnDemand = IsAddOnLoadOnDemand
local ReloadUI = ReloadUI
local SetCursor = SetCursor
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

local GameTooltip = GameTooltip
local GameTooltip_Hide = GameTooltip_Hide

local floor, format, gmatch, max, min, sort, strfind, strlower, strsplit, strsub, tinsert, unpack, wipe =
	floor, format, gmatch, math.max, math.min, sort, strfind, strlower, strsplit, strsub, tinsert, unpack, wipe

local FRAME_WIDTH = 660
local FRAME_HEIGHT = 480
local MIN_WIDTH = 660
local MIN_HEIGHT = 480
local MAX_WIDTH = 1400
local MAX_HEIGHT = 900
local ROW_HEIGHT = 22
local MIN_ROWS = 16
local MAX_ROWS = 40

local SEPARATORS = {'_', '.', '-'}

local visible = {}
local collapsed = {}
local sortTitles = {}

local function OnVerticalScroll(_, offset)
	AM.offset = floor((offset / ROW_HEIGHT) + 0.5)
	AM:UpdateRows()
end

local function OnMouseWheel(_, delta)
	local maxOffset = max(0, #visible - AM.NumRows)
	AM.offset = min(max(0, (AM.offset or 0) - delta * 3), maxOffset)
	AM:UpdateRows()
end

local function AddonExists(name)
	if not name or name == '' then return false end
	local _, _, _, _, _, reason = GetAddOnInfo(name)
	return reason ~= 'MISSING'
end

local function SpecialCaseName(name)
	if not name then return name end

	local partOf = GetAddOnMetadata(name, 'X-Part-Of')
	if partOf and partOf ~= '' then
		return partOf .. '_' .. name
	end

	if name == 'DBM-Core' then
		return 'DBM'
	elseif strfind(name, 'DBM%-') then
		return name:gsub('DBM%-', 'DBM_')
	elseif strfind(name, 'CT_') then
		return name:gsub('CT_', 'CT-')
	elseif name == 'ShadowedUF_Options' then
		return 'ShadowedUnitFrames_Options'
	end

	local first = strsub(name, 1, 1)
	if first == '+' or first == '!' or first == '_' then
		return strsub(name, 2)
	end

	return name
end

local function StripColorCodes(text)
	if not text then return '' end
	return text:gsub('|[cC]%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('|n', '')
end

local function MatchesSearch(index)
	local query = AM.searchText
	if not query or query == '' then return true end

	local name, title = GetAddOnInfo(index)
	local display = name and E:GetAddOnDisplayName(name) or ''
	local author = name and GetAddOnMetadata(name, 'Author') or ''

	return strfind(strlower(display) .. ' ' .. strlower(title or '') .. ' ' .. strlower(author or ''), query, 1, true) ~= nil
end

function AM:BuildList()
	wipe(visible)
	wipe(sortTitles)

	local query = AM.searchText
	local searching = query and query ~= ''

	local num = GetNumAddOns()

	local allNames = {}
	local allSpecial = {}
	local allDisplay = {}

	for i = 1, num do
		local raw = GetAddOnInfo(i)
		allNames[i] = raw
		allSpecial[i] = SpecialCaseName(raw)
		allDisplay[i] = E:GetAddOnDisplayName(raw)
		sortTitles[i] = strlower(StripColorCodes(select(2, GetAddOnInfo(i)) or ''))
	end

	local prefixToParent = {}

	for i = 1, num do
		local special = allSpecial[i]
		if special then
			prefixToParent[special] = i
		end
	end

	local parentOf = {}
	local parentChildren = {}

	for i = 1, num do
		local partOf = GetAddOnMetadata(allNames[i], 'X-Part-Of')
		if partOf and partOf ~= '' then
			for j = 1, num do
				if allNames[j] == partOf or allSpecial[j] == partOf then
					parentOf[i] = j
					if not parentChildren[j] then parentChildren[j] = {} end
					tinsert(parentChildren[j], i)
					break
				end
			end
		end

		if not parentOf[i] then
			local special = allSpecial[i]
			if special then
				local matchedPrefix = nil

				for _, sep in ipairs(SEPARATORS) do
					local p = strsplit(sep, special)
					if p and p ~= special and p ~= '' and prefixToParent[p] then
						matchedPrefix = p
						break
					end
				end

				if not matchedPrefix then
					for j = 2, #special do
						local prev = strsub(special, j - 1, j - 1)
						local c = strsub(special, j, j)
						if prev >= 'a' and prev <= 'z' and c >= 'A' and c <= 'Z' then
							local p = strsub(special, 1, j - 1)
							if p ~= '' and prefixToParent[p] then
								matchedPrefix = p
								break
							end
						end
					end
				end

				if matchedPrefix then
					local pi = prefixToParent[matchedPrefix]
					if pi and pi ~= i then
						parentOf[i] = pi
						if not parentChildren[pi] then parentChildren[pi] = {} end
						tinsert(parentChildren[pi], i)
					end
				end
			end
		end
	end

	local ordered = {}
	local byKey = {}
	local standalone = {}

	for i = 1, num do
		if parentChildren[i] then
			local key = strlower(allDisplay[i])
			local group = byKey[key]
			if not group then
				group = { name = allDisplay[i], members = {} }
				byKey[key] = group
				tinsert(ordered, group)
			end
			tinsert(group.members, i)
			sort(parentChildren[i], function(a, b) return sortTitles[a] < sortTitles[b] end)
			for _, child in ipairs(parentChildren[i]) do
				tinsert(group.members, child)
			end
		elseif not parentOf[i] then
			tinsert(standalone, i)
		end
	end

	sort(ordered, function(a, b) return strlower(a.name) < strlower(b.name) end)
	sort(standalone, function(a, b) return sortTitles[a] < sortTitles[b] end)

	if searching then
		local matches = {}
		for _, group in ipairs(ordered) do
			for _, index in ipairs(group.members) do
				if MatchesSearch(index) then tinsert(matches, index) end
			end
		end
		for _, index in ipairs(standalone) do
			if MatchesSearch(index) then tinsert(matches, index) end
		end
		sort(matches, function(a, b) return sortTitles[a] < sortTitles[b] end)
		for _, index in ipairs(matches) do
			tinsert(visible, { kind = 'addon', index = index, indent = 0 })
		end
		return
	end

	local merged = {}

	for _, group in ipairs(ordered) do
		tinsert(merged, { kind = 'group', name = group.name, members = group.members, sortKey = strlower(group.name) })
	end

	for _, index in ipairs(standalone) do
		tinsert(merged, { kind = 'addon', index = index, indent = 0, sortKey = sortTitles[index] })
	end

	sort(merged, function(a, b) return a.sortKey < b.sortKey end)

	for _, entry in ipairs(merged) do
		entry.sortKey = nil
		tinsert(visible, entry)
		if entry.kind == 'group' and not collapsed[entry.name] then
			for _, index in ipairs(entry.members) do
				tinsert(visible, { kind = 'addon', index = index, indent = 1 })
			end
		end
	end
end

function AM:ToggleGroup(name)
	collapsed[name] = not collapsed[name]
	AM:BuildList()
	AM:UpdateRows()
end

function AM:ToggleGroupAll(entry)
	if not entry or entry.kind ~= 'group' then return end

	local allEnabled = true
	for _, index in ipairs(entry.members) do
		local _, _, _, enabled = GetAddOnInfo(index)
		if enabled ~= 1 then
			allEnabled = false
			break
		end
	end

	local newState = not allEnabled

	for _, index in ipairs(entry.members) do
		local name = GetAddOnInfo(index)
		if name then
			if newState then
				AM:EnableWithDependencies(name)
			else
				DisableAddOn(name)
			end
		end
	end

	AM:Refresh()
end

function AM:Refresh()
	AM:UpdateRows()
	AM:UpdateStatus()

	if not E:StaticPopup_FindVisible('ADDONMANAGER_RL') then
		E:StaticPopup_Show('ADDONMANAGER_RL')
	end
end

function AM:EnableWithDependencies(name)
	local cache = {}
	local function EnableRecurse(addon)
		if cache[addon] then return end
		cache[addon] = true

		local deps = { GetAddOnDependencies(addon) }
		for i = 1, #deps do
			local dep = deps[i]
			if AddonExists(dep) then
				EnableRecurse(dep)
			end
		end

		local embeds = GetAddOnMetadata(addon, 'X-Embeds')
		if embeds then
			for embed in gmatch(embeds, '[^%s,]+') do
				if AddonExists(embed) then
					EnableRecurse(embed)
				end
			end
		end

		EnableAddOn(addon)
	end

	EnableRecurse(name)
end

function AM:ToggleAddon(check)
	local row = check:GetParent()
	local entry = row.entry
	if not entry or entry.kind ~= 'addon' then return end

	local name = GetAddOnInfo(entry.index)
	if not name then return end

	if check:GetChecked() then
		AM:EnableWithDependencies(name)
	else
		DisableAddOn(name)
	end

	AM:Refresh()
end

local function GetStatusInfo(index)
	local name, _, _, enabled, loadable, reason = GetAddOnInfo(index)
	local loaded = name and IsAddOnLoaded(name)
	local onDemand = name and IsAddOnLoadOnDemand(name)

	if loaded then
		return L['Loaded'], { r = 0.2, g = 1, b = 0.2 }
	elseif reason == 'DISABLED' then
		return L['Disabled'], { r = 0.62, g = 0.62, b = 0.62 }
	elseif reason then
		return _G['ADDON_'..reason] or reason, { r = 1, g = 0.5, b = 0 }
	elseif enabled == 1 and onDemand then
		return L['Load On Demand'], { r = 0, g = 0.62, b = 0.87 }
	elseif enabled == 1 then
		return L['Enabled'], { r = 0.6, g = 0.8, b = 1 }
	else
		return L['Disabled'], { r = 0.62, g = 0.62, b = 0.62 }
	end
end

function AM:UpdateRows()
	if not AM.Rows or AM.updatingRows then return end
	AM.updatingRows = true

	local maxOffset = max(0, #visible - AM.NumRows)
	AM.offset = min(AM.offset or 0, maxOffset)

	E:SyncFauxScrollBar(_G['ElvUI_AddonManagerScrollFrameScrollBar'], AM.offset, maxOffset, ROW_HEIGHT)

	for i = 1, AM.NumRows do
		local row = AM.Rows[i]
		local entry = visible[AM.offset + i]
		row.entry = entry

		if not entry then
			row:Hide()
		else
			row:Show()
			row:SetHeight(ROW_HEIGHT)

			if entry.kind == 'group' then
				row.groupName:Show()
				row.expand:Show()
				row.groupCheck:Show()
				row.check:Hide()
				row.addonName:Hide()
				row.status:Hide()
				row.memory:Hide()

				local isCollapsed = collapsed[entry.name]
				row.expand:SetTexture(isCollapsed and E.Media.Textures.Plus or E.Media.Textures.Minus)
				row.groupName:SetText(format('%s (%d)', entry.name, #entry.members))

				local allEnabled = true
				for _, index in ipairs(entry.members) do
					local _, _, _, enabled = GetAddOnInfo(index)
					if enabled ~= 1 then
						allEnabled = false
						break
					end
				end
				row.groupCheck:SetChecked(allEnabled)
			else
				row.groupName:Hide()
				row.expand:Hide()
				row.groupCheck:Hide()
				row.check:Show()
				row.addonName:Show()
				row.status:Show()
				row.memory:Show()

				local index = entry.index
				local _, title, _, enabled = GetAddOnInfo(index)

				local indent = entry.indent or 0
				row.check:ClearAllPoints()
				row.check:SetPoint('LEFT', 8 + indent * 14, 0)
				row.addonName:ClearAllPoints()
				row.addonName:SetPoint('LEFT', 30 + indent * 14, 0)

				local statusText, statusColor = GetStatusInfo(index)
				row.status:SetText(statusText or '')
				row.status:SetTextColor(statusColor.r, statusColor.g, statusColor.b)

				row.check:Enable()
				row.check:SetChecked(enabled == 1)

				local mem = GetAddOnMemoryUsage(index)
				if mem > 0 then
					row.memory:SetText(format('%.1f MiB', mem / 1024))
					row.memory:SetTextColor(0.5, 0.5, 0.5)
				else
					row.memory:SetText('')
				end

				row.addonName:SetText(title or '???')
				row.addonName:SetTextColor(1, 1, 1)
			end
		end
	end

	AM.updatingRows = false
end

function AM:UpdateStatus()
	if not AM.Status then return end

	local total = GetNumAddOns()
	local loaded = 0
	local mem = 0
	for i = 1, total do
		local name = GetAddOnInfo(i)
		if name and IsAddOnLoaded(name) then
			loaded = loaded + 1
		end
		mem = mem + GetAddOnMemoryUsage(i)
	end

	AM.Status:SetText(format('%s: |cff00ff00%d|r/%d | %s: |cff00b3ff%.1f|r MiB', L['Loaded'], loaded, total, L['Memory Usage'], mem / 1024))
end

function AM:ShowTooltip(index, owner)
	local name, title, notes, enabled, loadable, reason = GetAddOnInfo(index)
	if not name then return end

	GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT')
	GameTooltip:AddLine(title or name, 1, 0.78, 0)

	local author = GetAddOnMetadata(name, 'Author')
	if author then
		GameTooltip:AddLine(format('%s: %s', L['Author'], author), 1, 1, 1)
	end

	local version = GetAddOnMetadata(name, 'Version')
	if version then
		GameTooltip:AddLine(format('%s: %s', L['Version'], version), 1, 1, 1)
	end

	if notes and notes ~= '' then
		GameTooltip:AddLine(notes, 1, 1, 1)
	end

	local statusText, statusColor = GetStatusInfo(index)
	if statusText then
		GameTooltip:AddLine(format('%s: %s', L['Status'], statusText), statusColor.r, statusColor.g, statusColor.b)
	end

	local deps = { GetAddOnDependencies(index) }
	if #deps > 0 then
		local parts = {}
		for i = 1, #deps do
			local dep = deps[i]
			if dep and dep ~= '' then
				local _, _, _, depEnabled = GetAddOnInfo(dep)
				local color = depEnabled == 1 and '|cff00ff00' or '|cff9d9d9d'
				tinsert(parts, format('%s%s|r', color, dep))
			end
		end
		if #parts > 0 then
			GameTooltip:AddLine(format('%s: %s', L['Dependencies'], table.concat(parts, ', ')), 1, 1, 1)
		end
	end

	local mem = GetAddOnMemoryUsage(index)
	GameTooltip:AddLine(format('%s: |cff8080ff%.1f|r MiB', L['Memory Usage'], mem / 1024), 1, 1, 1)

	GameTooltip:Show()
end

local function CreateRow(i)
	local row = CreateFrame('Button', nil, AM.ScrollFrame)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint('TOPLEFT', 4, -(i - 1) * ROW_HEIGHT)
	row:SetPoint('RIGHT', AM.ScrollFrame, 'RIGHT', -20, 0)
	row:SetScript('OnClick', function(self)
		local entry = self.entry
		if entry and entry.kind == 'group' then
			AM:ToggleGroup(entry.name)
		end
	end)
	row:SetScript('OnEnter', function(self)
		local entry = self.entry
		if entry and entry.kind == 'addon' then
			AM:ShowTooltip(entry.index, self)
		end
	end)
	row:SetScript('OnLeave', function() GameTooltip_Hide() end)
	row:EnableMouseWheel(true)
	row:SetScript('OnMouseWheel', OnMouseWheel)

	row:SetHighlightTexture(E.media.blankTex)
	row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.12)
	row:GetHighlightTexture():SetAllPoints()

	row.groupCheck = CreateFrame('CheckButton', nil, row)
	row.groupCheck:SetSize(16, 16)
	row.groupCheck:SetPoint('LEFT', 8, 0)
	S:HandleCheckBox(row.groupCheck)
	row.groupCheck:SetScript('OnClick', function(self)
		local entry = self:GetParent().entry
		if entry and entry.kind == 'group' then
			AM:ToggleGroupAll(entry)
		end
	end)
	row.groupCheck:Hide()

	row.expand = row:CreateTexture(nil, 'OVERLAY')
	row.expand:SetSize(12, 12)
	row.expand:SetPoint('LEFT', 30, 0)

	row.groupName = row:CreateFontString(nil, 'OVERLAY')
	row.groupName:FontTemplate(nil, 12, 'OUTLINE')
	row.groupName:SetJustifyH('LEFT')
	row.groupName:SetPoint('LEFT', 46, 0)
	row.groupName:SetTextColor(1, 0.82, 0)

	row.check = CreateFrame('CheckButton', nil, row)
	row.check:SetSize(16, 16)
	row.check:SetPoint('LEFT', 8, 0)
	S:HandleCheckBox(row.check)
	row.check:SetScript('OnClick', function(self) AM:ToggleAddon(self) end)
	row.check:SetScript('OnEnter', function(self)
		local entry = self:GetParent().entry
		if entry and entry.kind == 'addon' then
			AM:ShowTooltip(entry.index, self:GetParent())
		end
	end)
	row.check:SetScript('OnLeave', function() GameTooltip_Hide() end)

	row.addonName = row:CreateFontString(nil, 'OVERLAY')
	row.addonName:FontTemplate(nil, 12)
	row.addonName:SetJustifyH('LEFT')
	row.addonName:SetPoint('LEFT', 30, 0)

	row.memory = row:CreateFontString(nil, 'OVERLAY')
	row.memory:FontTemplate(nil, 11)
	row.memory:SetJustifyH('RIGHT')
	row.memory:SetPoint('RIGHT', -6, 0)

	row.status = row:CreateFontString(nil, 'OVERLAY')
	row.status:FontTemplate(nil, 11)
	row.status:SetJustifyH('RIGHT')
	row.status:SetPoint('RIGHT', row.memory, 'LEFT', -10, 0)

	return row
end

function AM:UpdateLayout()
	local frame = AM.Frame
	if not frame or not AM.ScrollFrame then return end

	local numRows = max(MIN_ROWS, min(MAX_ROWS, floor((frame:GetHeight() - 114) / ROW_HEIGHT)))
	if numRows == AM.NumRows and AM.Rows[numRows] then return end

	for i = #AM.Rows + 1, numRows do
		AM.Rows[i] = CreateRow(i)
	end
	for i = numRows + 1, #AM.Rows do
		AM.Rows[i]:Hide()
	end

	AM.NumRows = numRows
	AM:UpdateRows()
end

function AM:CreateWindow()
	if AM.Frame then return end

	local frame = CreateFrame('Frame', 'ElvUI_AddonManager', E.UIParent)
	frame:SetFrameStrata('DIALOG')
	frame:SetFrameLevel(50)
	frame:SetPoint('CENTER')
	frame:SetTemplate('Transparent')
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
	frame:SetMaxResize(MAX_WIDTH, MAX_HEIGHT)
	frame:EnableMouse(true)
	frame:SetToplevel(true)
	frame:SetScript('OnMouseDown', function() frame:StartMoving() end)
	frame:SetScript('OnMouseUp', function()
		frame:StopMovingOrSizing()
		local size = E.global.addonManager.windowSize
		size.width = frame:GetWidth()
		size.height = frame:GetHeight()
	end)
	frame:SetScript('OnHide', function() frame:StopMovingOrSizing() end)
	frame:SetScript('OnSizeChanged', function() AM:UpdateLayout() end)
	frame:EnableMouseWheel(true)
	frame:SetScript('OnMouseWheel', OnMouseWheel)
	AM.Frame = frame
	AM.Rows = {}
	AM.NumRows = MIN_ROWS

	local size = E.global.addonManager.windowSize
	frame:SetSize(max(MIN_WIDTH, min(MAX_WIDTH, size.width)), max(MIN_HEIGHT, min(MAX_HEIGHT, size.height)))

	frame:CreateCloseButton(16, -6)
	tinsert(_G.UISpecialFrames, 'ElvUI_AddonManager')

	local sizer = CreateFrame('Frame', 'ElvUI_AddonManagerSizer', frame)
	sizer:SetSize(25, 25)
	sizer:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
	sizer:EnableMouse(true)
	sizer:SetScript('OnMouseDown', function() frame:StartSizing('BOTTOMRIGHT') end)
	sizer:SetScript('OnMouseUp', function() frame:StopMovingOrSizing() end)
	sizer:SetScript('OnEnter', function() SetCursor('UI-Cursor-Size') end)
	sizer:SetScript('OnLeave', function() SetCursor(nil) end)

	local line1 = sizer:CreateTexture(nil, 'OVERLAY')
	line1:SetSize(14, 14)
	line1:SetPoint('BOTTOMRIGHT', -8, 8)
	line1:SetTexture('Interface\\Tooltips\\UI-Tooltip-Border')
	local x = 0.1 * 14 / 17
	line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

	local line2 = sizer:CreateTexture(nil, 'OVERLAY')
	line2:SetSize(8, 8)
	line2:SetPoint('BOTTOMRIGHT', -8, 8)
	line2:SetTexture('Interface\\Tooltips\\UI-Tooltip-Border')
	x = 0.1 * 8 / 17
	line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

	local title = frame:CreateFontString(nil, 'OVERLAY')
	title:FontTemplate(nil, 13, 'OUTLINE')
	title:SetPoint('TOP', frame, 'TOP', 0, -8)
	title:SetText(L['Addons'])
	frame.Title = title

	local function CreateActionButton(text, parentPoint, x, y, onClick, width)
		local button = CreateFrame('Button', nil, frame)
		button:SetSize(width or 130, 22)
		button:SetPoint(parentPoint, frame, parentPoint, x, y)
		button:SetScript('OnClick', onClick)
		S:HandleButton(button)

		local textString = button:CreateFontString(nil, 'OVERLAY')
		textString:FontTemplate(nil, 12)
		textString:SetPoint('CENTER')
		textString:SetText(text)
		button:SetFontString(textString)

		return button
	end

	local function SetAllAddons(enable)
		for i = 1, GetNumAddOns() do
			local name = GetAddOnInfo(i)
			if enable then
				EnableAddOn(name)
			else
				DisableAddOn(name)
			end
		end

		AM:Refresh()
	end

	local enableAll = CreateActionButton(L['Enable All'], 'TOPLEFT', 14, -36, function() SetAllAddons(true) end)
	local disableAll = CreateActionButton(L['Disable All'], 'TOPLEFT', 150, -36, function() SetAllAddons() end)

	local reloadButton = CreateActionButton(L['Reload UI'], 'TOPRIGHT', -14, -36, function()
		if InCombatLockdown() then
			E:Print(L['You are in combat. Cannot reload UI right now.'])
		else
			ReloadUI()
		end
	end, 220)

	frame.enableAll, frame.disableAll, frame.reloadButton = enableAll, disableAll, reloadButton

	AM.searchText = ''

	local searchBox = CreateFrame('EditBox', 'ElvUI_AddonManagerSearchBox', frame)
	searchBox:SetSize(130, 20)
	searchBox:SetPoint('TOPLEFT', frame, 'TOPLEFT', 288, -36)
	searchBox:SetAutoFocus(false)
	searchBox:SetScript('OnEscapePressed', function(self)
		self:SetText('')
		self:ClearFocus()
	end)
	searchBox:SetScript('OnEnterPressed', function(self)
		self:ClearFocus()
	end)
	searchBox:HookScript('OnTextChanged', function(self)
		AM.searchText = strlower(self:GetText())
		AM.offset = 0
		AM:BuildList()
		AM:UpdateRows()
	end)
	S:HandleEditBox(searchBox, nil, true)
	searchBox:FontTemplate()
	frame.searchBox = searchBox

	local panel = CreateFrame('Frame', nil, frame)
	panel:SetPoint('TOPLEFT', frame, 'TOPLEFT', 14, -66)
	panel:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -14, 40)
	panel:SetTemplate('Transparent')
	frame.Panel = panel

	local scrollFrame = CreateFrame('ScrollFrame', 'ElvUI_AddonManagerScrollFrame', panel, 'FauxScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', panel, 'TOPLEFT', 4, -4)
	scrollFrame:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -4, 4)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript('OnVerticalScroll', OnVerticalScroll)
	scrollFrame:SetScript('OnMouseWheel', OnMouseWheel)
	AM.ScrollFrame = scrollFrame

	local scrollBar = _G['ElvUI_AddonManagerScrollFrameScrollBar']
	if scrollBar then
		S:HandleSirusScrollBar(scrollBar)
	end

	AM:UpdateLayout()

	local status = frame:CreateFontString(nil, 'OVERLAY')
	status:FontTemplate(nil, 11)
	status:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 14, 10)
	status:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -14, 10)
	status:SetJustifyH('CENTER')
	AM.Status = status
end

function AM:Show()
	if not E.private.general.addonManager then return end
	if not AM.Frame then AM:CreateWindow() end

	if _G.GameMenuFrame and _G.GameMenuFrame:IsShown() then
		HideUIPanel(_G.GameMenuFrame)
	end
	if _G.AddOnList and _G.AddOnList:IsShown() then
		HideUIPanel(_G.AddOnList)
	end

	AM:BuildList()
	AM.offset = 0
	UpdateAddOnMemoryUsage()
	AM.Frame:Show()
	AM.Frame:Raise()
	AM:UpdateRows()
	AM:UpdateStatus()
end

function AM:Hide()
	if AM.Frame then AM.Frame:Hide() end
end

function AM:Toggle()
	if AM.Frame and AM.Frame:IsShown() then
		AM:Hide()
	else
		AM:Show()
	end
end

function AM:PositionGameMenuButton()
	local frame = _G.GameMenuFrame
	local button = frame and frame.AddonManagerButton
	if not (frame and button and button.replacingAddons) then return end

	local elvui = frame.ElvUI
	if elvui then
		elvui:ClearAllPoints()
		elvui:Point('TOPLEFT', button, 'BOTTOMLEFT', 0, -1)

		local _, _, _, _, offY = _G.GameMenuButtonLogout:GetPoint()
		_G.GameMenuButtonLogout:ClearAllPoints()
		_G.GameMenuButtonLogout:Point('TOPLEFT', elvui, 'BOTTOMLEFT', 0, offY)
	end
end

function AM:SetupGameMenu()
	if not E.private.general.addonManager then return end

	local frame = _G.GameMenuFrame
	if not frame or frame.AddonManagerButton then return end

	local button = CreateFrame('Button', 'ElvUI_GameMenuAddonsButton', frame, 'GameMenuButtonTemplate')
	button:SetScript('OnClick', function() AM:Toggle() end)
	button:SetText(L['Addons'])
	frame.AddonManagerButton = button

	local addons = _G.GameMenuButtonAddons
	if addons then
		local point, relTo, relPoint, xOfs, yOfs = addons:GetPoint()
		button:Size(addons:GetSize())
		button:Point(point or 'TOPLEFT', relTo or frame, relPoint or 'TOPLEFT', xOfs or 0, yOfs or 0)

		addons:Hide()
		addons.Show = E.noop
		button.replacingAddons = true

		AM:PositionGameMenuButton()
		hooksecurefunc(E, 'PositionGameMenuButton', AM.PositionGameMenuButton)
	else
		if frame.ElvUI then
			button:Point('TOPLEFT', frame.ElvUI, 'BOTTOMLEFT', 0, -1)
		else
			button:Point('TOPLEFT', frame, 'TOPLEFT', 0, 0)
		end
	end

	if GameMenuFrame_UpdateVisibleButtons then
		hooksecurefunc('GameMenuFrame_UpdateVisibleButtons', function()
			local b = frame.AddonManagerButton
			if b and _G.GameMenuButtonLogout then
				frame:Height(frame:GetHeight() + _G.GameMenuButtonLogout:GetHeight() - 4)
			end
		end)
	end
end

function AM:Initialize()
	if not E.private.general.addonManager then return end

	E.global.addonManager = E.global.addonManager or {}
	E.global.addonManager.collapsed = E.global.addonManager.collapsed or {}
	E.global.addonManager.windowSize = E.global.addonManager.windowSize or { width = FRAME_WIDTH, height = FRAME_HEIGHT }
	collapsed = E.global.addonManager.collapsed

	E.PopupDialogs.ADDONMANAGER_RL = {
		text = L['ADDONMANAGER_RELOAD'],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = ReloadUI,
		whileDead = 1,
		hideOnEscape = false,
	}

	AM:SetupGameMenu()
end

E:RegisterModule(AM:GetName())
