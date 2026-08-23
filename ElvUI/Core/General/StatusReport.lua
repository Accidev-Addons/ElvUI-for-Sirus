local E, L, V, P, G = unpack(ElvUI)
local LSM = E.Libs.LSM

local wipe, sort, unpack = wipe, sort, unpack
local next, pairs, tinsert = next, pairs, tinsert

local CreateFrame = CreateFrame
local GetRealZoneText = GetRealZoneText

local GetCVarBool = GetCVarBool
local GetAddOnInfo = GetAddOnInfo
local GetNumAddOns = GetNumAddOns

local UNKNOWN = UNKNOWN
local YES, NO = YES, NO

E.Status_Addons = {
	ElvUI = true,
	ElvUI_Options = true,
	ElvUI_Libraries = true
}

E.Status_Bugsack = {
	['!BugGrabber'] = true,
	BugSack = true
}

function E:AreOtherAddOnsEnabled()
	local EP, addons, bugs, plugins = E.Libs.EP.plugins

	local addon = E.Status_Addons
	local bugsack = E.Status_Bugsack

	for i = 1, GetNumAddOns() do
		local name = GetAddOnInfo(i)
		if not addon[name] and E:IsAddOnEnabled(name) then
			if EP[name] then
				plugins = true
			elseif bugsack[name] then
				bugs = true
			else
				addons = true
			end
		end
	end

	return addons, bugs, plugins
end

function E:GetDisplayMode()
	if not GetCVarBool('gxWindow') then
		return L["Fullscreen"]
	end

	return GetCVarBool('gxMaximize') and L["Windowed (Maximized)"] or L["Windowed"]
end

local function GetSpecName()
	return E.SpecName[E.myspecID]
end

function E:CreateStatusContent(num, width, parent, anchorTo, content)
	if not content then content = CreateFrame('Frame', nil, parent) end
	content:SetSize(width, (num * 20) + ((num-1)*5)) --20 height and 5 spacing
	content:SetPoint('TOP', anchorTo, 'BOTTOM')

	local font = LSM:Fetch('font', 'Expressway')
	for i = 1, num do
		if not content['Line'..i] then
			local line = CreateFrame('Frame', nil, content)
			line:SetSize(width, 20)

			local text = line:CreateFontString(nil, 'ARTWORK')
			text:SetAllPoints()
			text:SetJustifyH('LEFT')
			text:SetJustifyV('MIDDLE')
			text:FontTemplate(font, 14, 'OUTLINE')
			line.Text = text

			if i == 1 then
				line:SetPoint('TOP', content, 'TOP')
			else
				line:SetPoint('TOP', content['Line'..(i-1)], 'BOTTOM', 0, -5)
			end

			content['Line'..i] = line
		end
	end

	return content
end

local function CloseClicked()
	if E.StatusReportToggled then
		E.StatusReportToggled = nil
		E:ToggleOptions()
	end
end

function E:CreateStatusSection(width, height, headerWidth, headerHeight, parent, anchor1, anchorTo, anchor2, yOffset)
	local parentWidth, parentHeight = parent:GetSize()

	if width > parentWidth then parent:Width(width + 25) end
	if height then parent:SetHeight(parentHeight + height) end

	local section = CreateFrame('Frame', nil, parent)
	section:SetSize(width, height or 0)
	section:SetPoint(anchor1, anchorTo, anchor2, 0, yOffset)

	local header = CreateFrame('Frame', nil, section)
	header:SetSize(headerWidth or width, headerHeight)
	header:SetPoint('TOP', section)
	section.Header = header

	local font = LSM:Fetch('font', 'Expressway')
	local text = section.Header:CreateFontString(nil, 'ARTWORK')
	text:SetPoint('TOP')
	text:SetPoint('BOTTOM')
	text:SetJustifyH('CENTER')
	text:SetJustifyV('MIDDLE')
	text:FontTemplate(font, 18, 'OUTLINE')
	section.Header.Text = text

	local leftDivider = section.Header:CreateTexture(nil, 'ARTWORK')
	leftDivider:SetHeight(8)
	leftDivider:SetPoint('LEFT', section.Header, 'LEFT', 5, 0)
	leftDivider:SetPoint('RIGHT', section.Header.Text, 'LEFT', -5, 0)
	leftDivider:SetTexture([[Interface\Tooltips\UI-Tooltip-Border]])
	leftDivider:SetTexCoord(0.81, 0.94, 0.5, 1)
	section.Header.LeftDivider = leftDivider

	local rightDivider = section.Header:CreateTexture(nil, 'ARTWORK')
	rightDivider:SetHeight(8)
	rightDivider:SetPoint('RIGHT', section.Header, 'RIGHT', -5, 0)
	rightDivider:SetPoint('LEFT', section.Header.Text, 'RIGHT', 5, 0)
	rightDivider:SetTexture([[Interface\Tooltips\UI-Tooltip-Border]])
	rightDivider:SetTexCoord(0.81, 0.94, 0.5, 1)
	section.Header.RightDivider = rightDivider

	return section
end

function E:CreateStatusFrame()
	--Main frame
	local StatusFrame = CreateFrame('Frame', 'ElvUIStatusReport', E.UIParent)
	StatusFrame:SetPoint('CENTER', E.UIParent, 'CENTER')
	StatusFrame:SetFrameStrata('HIGH')
	StatusFrame:CreateBackdrop('Transparent', nil, true)
	StatusFrame.backdrop:SetBackdropColor(0, 0, 0, 0.6)
	StatusFrame:SetMovable(true)
	StatusFrame:SetSize(0, 35)
	StatusFrame:Hide()

	--Plugin frame
	local PluginFrame = CreateFrame('Frame', 'ElvUIStatusPlugins', StatusFrame)
	PluginFrame:SetPoint('TOPLEFT', StatusFrame, 'TOPRIGHT', E:Scale(E.Border * 2 + 1), 0)
	PluginFrame:SetFrameStrata('HIGH')
	PluginFrame:CreateBackdrop('Transparent', nil, true)
	PluginFrame.backdrop:SetBackdropColor(0, 0, 0, 0.6)
	PluginFrame:SetSize(0, 25)
	StatusFrame.PluginFrame = PluginFrame

	--Close button and script to retoggle the options.
	StatusFrame:CreateCloseButton()
	StatusFrame.CloseButton:HookScript('OnClick', CloseClicked)

	--Title logo (drag to move frame)
	local titleLogoFrame = CreateFrame('Frame', nil, StatusFrame)
	titleLogoFrame:SetPoint('CENTER', StatusFrame, 'TOP')
	titleLogoFrame:SetSize(240, 80)
	titleLogoFrame:EnableMouse(true)
	titleLogoFrame:RegisterForDrag('LeftButton')
	titleLogoFrame:SetScript('OnDragStart', function() StatusFrame:StartMoving(); StatusFrame:SetUserPlaced(false) end)
	titleLogoFrame:SetScript('OnDragStop', function() StatusFrame:StopMovingOrSizing() end)
	StatusFrame.TitleLogoFrame = titleLogoFrame

	local LogoTop = StatusFrame.TitleLogoFrame:CreateTexture(nil, 'ARTWORK')
	LogoTop:SetPoint('CENTER', titleLogoFrame, 'TOP', 0, -36)
	LogoTop:SetTexture(E.Media.Textures.LogoTopSmall)
	LogoTop:SetSize(128, 64)
	titleLogoFrame.LogoTop = LogoTop

	local LogoBottom = StatusFrame.TitleLogoFrame:CreateTexture(nil, 'ARTWORK')
	LogoBottom:SetPoint('CENTER', titleLogoFrame, 'TOP', 0, -36)
	LogoBottom:SetTexture(E.Media.Textures.LogoBottomSmall)
	LogoBottom:SetSize(128, 64)
	titleLogoFrame.LogoBottom = LogoBottom

	--Sections
	StatusFrame.Section1 = E:CreateStatusSection(300, 125, nil, 30, StatusFrame, 'TOP', StatusFrame, 'TOP', -30)
	StatusFrame.Section2 = E:CreateStatusSection(300, 150, nil, 30, StatusFrame, 'TOP', StatusFrame.Section1, 'BOTTOM', 0)
	StatusFrame.Section3 = E:CreateStatusSection(300, 185, nil, 30, StatusFrame, 'TOP', StatusFrame.Section2, 'BOTTOM', 0)

	PluginFrame.SectionP = E:CreateStatusSection(280, nil, nil, 30, PluginFrame, 'TOP', PluginFrame, 'TOP', -10)

	--Section content
	StatusFrame.Section1.Content = E:CreateStatusContent(4, 260, StatusFrame.Section1, StatusFrame.Section1.Header)
	StatusFrame.Section2.Content = E:CreateStatusContent(5, 260, StatusFrame.Section2, StatusFrame.Section2.Header)
	StatusFrame.Section3.Content = E:CreateStatusContent(7, 260, StatusFrame.Section3, StatusFrame.Section3.Header)

	--Content lines
	StatusFrame.Section2.Content.Line1.Text:SetFormattedText('%s: |cff4beb2c%s (build %s)|r', L["Version of WoW"], E.wowpatch, E.wowbuild)
	StatusFrame.Section2.Content.Line2.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Client Language"], E.locale)

	local factionTag = E:GetModule('DataTexts').GetPlayerFaction()
	local factionText = (factionTag and _G['FACTION_'..factionTag:upper()]) or E.myLocalizedFaction or E.myfaction

	StatusFrame.Section3.Content.Line1.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Realm"], E.myrealm)
	StatusFrame.Section3.Content.Line2.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Faction"], factionText)
	StatusFrame.Section3.Content.Line3.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Race"], E.myLocalizedRace or E.myrace)
	StatusFrame.Section3.Content.Line4.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Class"], E.myLocalizedClass or E.ClassName[E.myclass])

	return StatusFrame
end

local function pluginSort(a, b)
	local A, B = a.title or a.name, b.title or b.name
	if A and B then
		return E:StripString(A) < E:StripString(B)
	end
end

local pluginData = {}
function E:UpdateStatusFrame()
	local StatusFrame = E.StatusFrame
	local PluginFrame = StatusFrame.PluginFrame

	--Section headers
	local valueColor = E.media.hexvaluecolor
	StatusFrame.Section1.Header.Text:SetFormattedText('%s%s|r', valueColor, L["AddOn Info"])
	StatusFrame.Section2.Header.Text:SetFormattedText('%s%s|r', valueColor, L["WoW Info"])
	StatusFrame.Section3.Header.Text:SetFormattedText('%s%s|r', valueColor, L["Character Info"])

	StatusFrame.Section1.Content.Line3.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Recommended Scale"], E:PixelBestSize())
	StatusFrame.Section1.Content.Line4.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["UI Scale Is"], E.global.general.UIScale)

	local PluginSection = PluginFrame.SectionP
	PluginSection.Header.Text:SetFormattedText('%s%s|r', valueColor, L["Plugins"])

	StatusFrame.Section1.Content.Line1.Text:SetFormattedText('%s: |cff%s%.2f|r', L["Version of ElvUI"], (E.recievedOutOfDateMessage and 'ff3333') or (E.updateRequestTriggered and 'ff9933') or '33ff33', E.version)

	local addons, bugs, plugins = E:AreOtherAddOnsEnabled()
	local addonsColor, addonsText
	if not addons and not plugins and bugs then
		addonsColor, addonsText = '33ff33', L["Debug"]
	elseif not addons and plugins then
		addonsColor, addonsText = 'ff9933', L["Plugins"]
	elseif addons then
		addonsColor, addonsText = 'ff3333', YES
	else
		addonsColor, addonsText = '33ff33', NO
	end
	StatusFrame.Section1.Content.Line2.Text:SetFormattedText('%s: |cff%s%s|r', L["Other AddOns Enabled"], addonsColor, addonsText)

	if plugins then
		wipe(pluginData)
		for _, data in pairs(E.Libs.EP.plugins) do
			if data and not data.isLib then
				tinsert(pluginData, data)
			end
		end

		if next(pluginData) then
			sort(pluginData, pluginSort)

			local count = #pluginData
			local width = PluginSection:GetWidth()
			PluginSection.Content = E:CreateStatusContent(count, width, PluginSection, PluginSection.Header, PluginSection.Content)

			for i=1, count do
				local data = pluginData[i]
				local color = data.old and 'ff3333' or '33ff33'
				PluginSection.Content['Line'..i].Text:SetFormattedText('%s |cff888888v|r|cff%s%s|r', data.title or data.name, color, data.version)
			end

			PluginFrame.SectionP:SetHeight(count * 20)
			PluginFrame:SetHeight(PluginSection.Content:GetHeight() + 50)
			PluginFrame:Show()
		else
			PluginFrame:Hide()
		end
	else
		PluginFrame:Hide()
	end

	local Section2 = StatusFrame.Section2
	Section2.Content.Line3.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Display Mode"], E:GetDisplayMode())
	Section2.Content.Line4.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Resolution"], E.resolution)

	local isHD = E:IsHDPatch()
	Section2.Content.Line5.Text:SetFormattedText('%s: |cff%s%s|r', L["HD Interface Patch"], isHD and 'ff3333' or '33ff33', isHD and YES or NO)

	local Section3 = StatusFrame.Section3
	Section3.Content.Line5.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Level"], E.mylevel)
	Section3.Content.Line6.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Zone"], GetRealZoneText() or UNKNOWN)
	Section3.Content.Line7.Text:SetFormattedText('%s: |cff4beb2c%s|r', L["Specialization"], GetSpecName() or UNKNOWN)

	local content = Section3.Content
	local children = {content:GetChildren()}
	local lastChild

	for _, child in ipairs(children) do
		if child:IsShown() then
			if not lastChild or (child:GetBottom() < lastChild:GetBottom()) then
				lastChild = child
			end
		end
	end

	if lastChild then
		local bottom = lastChild:GetBottom()
		local top = StatusFrame:GetTop()
		if bottom and top then
			local padding = 20
			StatusFrame:SetHeight(top - bottom + padding)
		end
	end

	StatusFrame.TitleLogoFrame.LogoTop:SetVertexColor(unpack(E.media.rgbvaluecolor))
end

function E:ShowStatusReport()
	if not E.StatusFrame then
		E.StatusFrame = E:CreateStatusFrame()
	end

	if not E.StatusFrame:IsShown() then
		E:UpdateStatusFrame()
		E.StatusFrame:Raise() --Set framelevel above everything else
		E.StatusFrame:Show()
	else
		E.StatusFrame:Hide()
	end
end
