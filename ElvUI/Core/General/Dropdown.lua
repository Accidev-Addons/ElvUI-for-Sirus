local E, L, V, P, G = unpack(ElvUI)

local _G = _G
local ipairs, select = ipairs, select

local CreateFrame = CreateFrame

local GetRaidRosterInfo = GetRaidRosterInfo
local InCombatLockdown = InCombatLockdown
local IsPartyLeader = IsPartyLeader
local IsRaidOfficer = IsRaidOfficer
local UIDropDownMenu_Refresh = UIDropDownMenu_Refresh

local hooksecurefunc = hooksecurefunc
local CloseDropDownMenus = CloseDropDownMenus
local PlaySound = PlaySound

local function ClosePopup()
    CloseDropDownMenus()
    PlaySound('UChatScrollButton')
end

local function CreateSecurePromoteButton(name, role)
    local button = CreateFrame('Button', name, E.UIParent, 'SecureActionButtonTemplate')
    button:SetFrameStrata('TOOLTIP')
    button:Hide()

    button:SetAttribute('type', role)
    button:SetAttribute('unit', 'target')
    button:SetAttribute('action', 'toggle')

    button:SetScript('PostClick', ClosePopup)

    button:RegisterEvent('PLAYER_REGEN_DISABLED')
    button:RegisterEvent('PLAYER_REGEN_ENABLED')

    button.role = role

    return button
end

local function CopyScript(scriptName, sourceButton, targetButton)
    local originalScript = sourceButton:GetScript(scriptName)
    targetButton:SetScript(scriptName, function(_, ...)
        if originalScript then
            originalScript(sourceButton, ...)
        end
    end)
end

local function SetButton(unit, button, newButton)
    if InCombatLockdown() then return end

    newButton:SetAllPoints(button)
    newButton:SetAttribute('unit', unit or 'target')

    CopyScript('OnEnter', button, newButton)
    CopyScript('OnLeave', button, newButton)

    newButton:SetScript('OnMouseDown', function() button:SetButtonState('PUSHED') end)
    newButton:SetScript('OnMouseUp', function() button:SetButtonState('NORMAL') end)

    newButton:SetScript('OnEvent', function(self, event)
        local isDisabled = event == 'PLAYER_REGEN_DISABLED'
        self:SetAttribute('type', isDisabled and nil or self.role)
        button:SetAlpha(isDisabled and 0.5 or 1)

        if not isDisabled and not _G.DropDownList1:IsShown() then
            self:Hide()
        end
    end)

    newButton:Show()
end

local secureTankButton = CreateSecurePromoteButton('ElvUI_SecureTankButton', 'maintank')
local secureAssistButton = CreateSecurePromoteButton('ElvUI_SecureAssistButton', 'mainassist')

local function RefreshDropdown(button)
    if button == 'RAID_MAINTANK' or button == 'RAID_MAINASSIST' then
        UIDropDownMenu_Refresh(_G.UIDROPDOWNMENU_INIT_MENU, nil, 1)
    end
end

hooksecurefunc('UnitPopup_OnClick', function(self)
    RefreshDropdown(self.value)
end)

hooksecurefunc('UnitPopup_ShowMenu', function(_, _, unit)
    if _G.UIDROPDOWNMENU_MENU_LEVEL ~= 1 then return end

    for i = 1, _G.UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G['DropDownList1Button'..i]
        if button and button:IsShown() then
            if button.value == 'RAID_MAINTANK' then
                SetButton(unit, button, secureTankButton)
            elseif button.value == 'RAID_MAINASSIST' then
                SetButton(unit, button, secureAssistButton)
            end
        end
    end
end)

hooksecurefunc('UnitPopup_HideButtons', function()
    local dropdownMenu = _G.UIDROPDOWNMENU_INIT_MENU
    if dropdownMenu.which ~= 'RAID' or not (IsPartyLeader() or IsRaidOfficer()) then return end

    for index, value in ipairs(_G.UnitPopupMenus[dropdownMenu.which]) do
        if value == 'RAID_MAINTANK' or value == 'RAID_MAINASSIST' then
            local role = select(10, GetRaidRosterInfo(dropdownMenu.userData))
            if role ~= value:sub(6) or not dropdownMenu.name then
                _G.UnitPopupShown[_G.UIDROPDOWNMENU_MENU_LEVEL][index] = 1
            end
        end
    end
end)

_G.DropDownList1:HookScript('OnHide', function()
    if InCombatLockdown() then return end

    secureTankButton:Hide()
    secureAssistButton:Hide()
end)