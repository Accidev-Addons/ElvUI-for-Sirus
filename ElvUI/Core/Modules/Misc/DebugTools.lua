local E, L, V, P, G = unpack(ElvUI)
local D = E:GetModule("DebugTools")
local S = E:GetModule("Skins")

--Lua functions
local format = string.format
local hooksecurefunc = hooksecurefunc
--WoW API / Variables
local GetCVarBool = GetCVarBool
local InCombatLockdown = InCombatLockdown
local ReloadUI = ReloadUI
local UIErrorsFrame = UIErrorsFrame

function D:ModifyErrorFrame()
	ScriptErrorsFrameScrollFrameText.cursorOffset = 0
	ScriptErrorsFrameScrollFrameText.cursorHeight = 0
	ScriptErrorsFrameScrollFrameText:SetScript("OnEditFocusGained", nil)

	hooksecurefunc("ScriptErrorsFrame_Update", function()
		if GetCVarBool("scriptErrors") then
			ScriptErrorsFrameScrollFrameText:HighlightText(0, 0)
		end
	end)

	-- Unhighlight text when focus is hit
	ScriptErrorsFrameScrollFrameText:HookScript("OnEscapePressed", function(self)
		self:HighlightText(0, 0)
	end)

	ScriptErrorsFrame:Size(500, 300)
	ScriptErrorsFrameScrollFrame:Size(455, 229)

	ScriptErrorsFrameScrollFrameText:Width(455)

	local BUTTON_WIDTH = 75
	local BUTTON_HEIGHT = 24
	local BUTTON_SPACING = 2

	-- Add a first button
	local firstButton = CreateFrame("Button", nil, ScriptErrorsFrame, "UIPanelButtonTemplate")
	firstButton:SetPoint("BOTTOM", -((BUTTON_WIDTH + BUTTON_WIDTH/2) + (BUTTON_SPACING * 4)), 8)
	firstButton:SetText(L["First"])
	firstButton:SetHeight(BUTTON_HEIGHT)
	firstButton:SetWidth(BUTTON_WIDTH)
	firstButton:SetScript("OnClick", function()
		ScriptErrorsFrame.index = 1
		ScriptErrorsFrame_Update()
	end)
	ScriptErrorsFrame.firstButton = firstButton

	local reloadButton = CreateFrame("Button", nil, ScriptErrorsFrame, "UIPanelButtonTemplate")
	reloadButton:SetPoint("BOTTOMRIGHT", firstButton, "BOTTOMLEFT", -BUTTON_SPACING, 0)
	reloadButton:SetText("R")
	reloadButton:SetHeight(BUTTON_HEIGHT)
	reloadButton:SetWidth(30)
	reloadButton:SetScript("OnClick", function()
		ReloadUI()
	end)
	ScriptErrorsFrame.reloadButton = reloadButton

	-- Also add a Last button for errors
	local lastButton = CreateFrame("Button", nil, ScriptErrorsFrame, "UIPanelButtonTemplate")
	lastButton:SetPoint("BOTTOMLEFT", ScriptErrorsFrame.next, "BOTTOMRIGHT", BUTTON_SPACING, 0)
	lastButton:SetHeight(BUTTON_HEIGHT)
	lastButton:SetWidth(BUTTON_WIDTH)
	lastButton:SetText(L["Last"])
	lastButton:SetScript("OnClick", function()
		ScriptErrorsFrame.index = #(ScriptErrorsFrame.order)
		ScriptErrorsFrame_Update()
	end)
	ScriptErrorsFrame.lastButton = lastButton

	ScriptErrorsFrame.previous:ClearAllPoints()
	ScriptErrorsFrame.previous:SetPoint("BOTTOMLEFT", firstButton, "BOTTOMRIGHT", BUTTON_SPACING, 0)
	ScriptErrorsFrame.previous:SetWidth(BUTTON_WIDTH)
	ScriptErrorsFrame.previous:SetHeight(BUTTON_HEIGHT)

	ScriptErrorsFrame.next:ClearAllPoints()
	ScriptErrorsFrame.next:SetPoint("BOTTOMLEFT", ScriptErrorsFrame.previous, "BOTTOMRIGHT", BUTTON_SPACING, 0)
	ScriptErrorsFrame.next:SetWidth(BUTTON_WIDTH)
	ScriptErrorsFrame.next:SetHeight(BUTTON_HEIGHT)

	ScriptErrorsFrame.close:ClearAllPoints()
	ScriptErrorsFrame.close:SetPoint("BOTTOMRIGHT", -8, 8)
	ScriptErrorsFrame.close:SetSize(75, BUTTON_HEIGHT)

	ScriptErrorsFrame.indexLabel:ClearAllPoints()
	ScriptErrorsFrame.indexLabel:SetPoint("BOTTOMLEFT", 0, 12)
end

function D:PositionErrorFrame()
	if not UIErrorsFrame or UIErrorsFrame.mover then return end

	E:CreateMover(UIErrorsFrame, 'ErrorFrameMover', L["Error Text"], nil, nil, nil, 'ALL')
	UIErrorsFrame:SetAllPoints(UIErrorsFrame.mover)

	hooksecurefunc(UIErrorsFrame, 'SetPoint', function(frame, _, relativeTo)
		if relativeTo ~= frame.mover then
			frame:ClearAllPoints()
			frame:SetAllPoints(frame.mover)
		end
	end)
end

function D:ScriptErrorsFrame_UpdateButtons()
	local numErrors = #ScriptErrorsFrame.order
	local index = ScriptErrorsFrame.index
	if numErrors == 0 then
		ScriptErrorsFrame.firstButton:Disable()
		ScriptErrorsFrame.lastButton:Disable()
	else
		if index <= 1 then
			ScriptErrorsFrame.firstButton:Disable()
		else
			ScriptErrorsFrame.firstButton:Enable()
		end

		if index >= numErrors then
			ScriptErrorsFrame.lastButton:Disable()
		else
			ScriptErrorsFrame.lastButton:Enable()
		end
	end
end

function D:ScriptErrorsFrame_OnError(_, keepHidden)
	if keepHidden or D.MessagePrinted or not InCombatLockdown() or not GetCVarBool("scriptErrors") then return end

	E:Print(L["|cFFE30000Lua error recieved. You can view the error message when you exit combat."])
	D.MessagePrinted = true
end

function D:PLAYER_REGEN_ENABLED()
	if ScriptErrorsFrame then
		ScriptErrorsFrame:SetParent(E.UIParent)
	end
	D.MessagePrinted = nil
end

function D:PLAYER_REGEN_DISABLED()
	if ScriptErrorsFrame then
		ScriptErrorsFrame:SetParent(D.HideFrame)
	end
end

function D:TaintError(event, addonName, addonFunc)
	if not GetCVarBool("scriptErrors") or E.db.general.taintLog ~= true then return end

	if not ScriptErrorsFrame_OnError then
		LoadAddOn("Blizzard_DebugTools")
		if not ScriptErrorsFrame_OnError then return end
	end

	ScriptErrorsFrame_OnError(format(L["%s: %s tried to call the protected function '%s'."], event, addonName or "<name>", addonFunc or "<func>"), false)
end

function D:StaticPopup_Show(name)
	if name == "ADDON_ACTION_FORBIDDEN" and E.db.general.taintLog ~= true then
		StaticPopup_Hide(name)
	end
end

function D:SetupErrorFrame()
	D:ModifyErrorFrame()
	D:SecureHook("ScriptErrorsFrame_UpdateButtons")
	D:SecureHook("ScriptErrorsFrame_OnError")
end

function D:Initialize()
	D.Initialized = true
	D.HideFrame = CreateFrame("Frame")
	D.HideFrame:Hide()

	D:PositionErrorFrame()

	S:AddCallbackForAddon("Blizzard_DebugTools", "ElvUI_DebugTools", D.SetupErrorFrame, nil, nil, 1)

	D:SecureHook("StaticPopup_Show")
	D:RegisterEvent("PLAYER_REGEN_DISABLED")
	D:RegisterEvent("PLAYER_REGEN_ENABLED")
	D:RegisterEvent("ADDON_ACTION_BLOCKED", "TaintError")
	D:RegisterEvent("ADDON_ACTION_FORBIDDEN", "TaintError")
end

E:RegisterModule(D:GetName())