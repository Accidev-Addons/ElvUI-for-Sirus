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

local secureButtons = {}

local function ClosePopup()
    CloseDropDownMenus()
    PlaySound('UChatScrollButton')
end

local function CreateSecureMenuButton(name, actionType)
    local button = CreateFrame('Button', name, E.UIParent, 'SecureActionButtonTemplate')
    button:SetFrameStrata('TOOLTIP')
    button:Hide()

    button:SetAttribute('type', actionType)
    button:SetScript('PostClick', ClosePopup)

    secureButtons[#secureButtons + 1] = button

    return button
end

local function CreateSecurePromoteButton(name, role)
    local button = CreateSecureMenuButton(name, role)

    button:SetAttribute('unit', 'target')
    button:SetAttribute('action', 'toggle')

    return button
end

local function ReleaseButtons()
    for _, button in ipairs(secureButtons) do
        button:Hide()
        button:ClearAllPoints()
    end
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
    newButton:SetAllPoints(button)
    newButton:SetAttribute('unit', unit or 'target')

    CopyScript('OnEnter', button, newButton)
    CopyScript('OnLeave', button, newButton)

    newButton:SetScript('OnMouseDown', function() button:SetButtonState('PUSHED') end)
    newButton:SetScript('OnMouseUp', function() button:SetButtonState('NORMAL') end)

    newButton:Show()
end

local secureClearFocusButton = CreateSecureMenuButton('ElvUI_SecureClearFocusButton', 'macro')
secureClearFocusButton:SetAttribute('macrotext', '/clearfocus')

local menuButtons = {
    RAID_MAINTANK = CreateSecurePromoteButton('ElvUI_SecureTankButton', 'maintank'),
    RAID_MAINASSIST = CreateSecurePromoteButton('ElvUI_SecureAssistButton', 'mainassist'),
    CLEAR_FOCUS = secureClearFocusButton,
}

local function RefreshDropdown(button)
    if button == 'RAID_MAINTANK' or button == 'RAID_MAINASSIST' then
        UIDropDownMenu_Refresh(_G.UIDROPDOWNMENU_INIT_MENU, nil, 1)
    end
end

hooksecurefunc('UnitPopup_OnClick', function(self)
    RefreshDropdown(self.value)
end)

hooksecurefunc('UnitPopup_ShowMenu', function(_, _, unit)
    if _G.UIDROPDOWNMENU_MENU_LEVEL ~= 1 or InCombatLockdown() then return end

    ReleaseButtons()

    for i = 1, _G.UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G['DropDownList1Button'..i]
        local newButton = button and button:IsShown() and button.value and menuButtons[button.value]
        if newButton then
            SetButton(unit, button, newButton)
        end
    end
end)

hooksecurefunc('UnitPopup_HideButtons', function()
    local dropdownMenu = _G.UIDROPDOWNMENU_INIT_MENU

    if InCombatLockdown() then
        if dropdownMenu == _G.FocusFrameDropDown then return end

        local menu = _G.UnitPopupMenus[_G.UIDROPDOWNMENU_MENU_VALUE] or _G.UnitPopupMenus[dropdownMenu.which]
        for index, value in ipairs(menu) do
            if value == 'CLEAR_FOCUS' then
                _G.UnitPopupShown[_G.UIDROPDOWNMENU_MENU_LEVEL][index] = 0
            end
        end

        return
    end

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

    ReleaseButtons()
end)

local combatWatcher = CreateFrame('Frame')
combatWatcher:RegisterEvent('PLAYER_REGEN_DISABLED')
combatWatcher:SetScript('OnEvent', function()
    for _, button in ipairs(secureButtons) do
        if button:IsShown() then
            CloseDropDownMenus()
            break
        end
    end

    ReleaseButtons()
end)
