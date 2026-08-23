local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local ipairs = ipairs
local hooksecurefunc = hooksecurefunc

local TOAST_CLOSE_TEXTURE = [[Interface\AddOns\ElvUI\Core\Media\Textures\Close]]

local function SkinToastCloseButton(f)
	if not f then return end

	local closeButton = f.CloseButton or f.closeButton
	if not closeButton then
		for _, child in ipairs({ f:GetChildren() }) do
			if child and child.GetObjectType and child:GetObjectType() == 'Button' then
				closeButton = child
				break
			end
		end
	end
	if not closeButton then return end

	closeButton:StripTextures()

	local texture = closeButton.Texture
	if not texture then
		texture = closeButton:CreateTexture(nil, 'OVERLAY')
		texture:Point('CENTER')
		texture:Size(12)
		closeButton.Texture = texture
	end

	texture:SetTexture(TOAST_CLOSE_TEXTURE)
	texture:SetTexCoord(0, 1, 0, 1)
	texture:SetVertexColor(1, 1, 1)
	texture:Show()

	if not closeButton._elvToastHoverHooked then
		closeButton._elvToastHoverHooked = true
		closeButton:HookScript('OnEnter', function()
			if closeButton.Texture then closeButton.Texture:SetVertexColor(unpack(E.media.rgbvaluecolor)) end
		end)
		closeButton:HookScript('OnLeave', function()
			if closeButton.Texture then closeButton.Texture:SetVertexColor(1, 1, 1) end
		end)
	end
end

local function SkinToast(f)
	if not f or f.isSkinned then return end
	f.isSkinned = true

	f:SetBackdrop(nil)
	f:SetTemplate('Transparent')

	if f.Icon then
		S:HandleIcon(f.Icon, true)
	end

	if f.glow then
		f.glow:Hide()
	end

	if f.TitleText then
		f.TitleText:FontTemplate()
	end
	if f.BodyText then
		f.BodyText:FontTemplate(nil, nil, 'OUTLINE')
	end

	SkinToastCloseButton(f)
end

local function SkinActiveToasts(anchor)
	if not anchor or not anchor.activeToasts then return end
	for _, toastFrame in ipairs(anchor.activeToasts) do
		SkinToast(toastFrame)
	end
end

local function SkinToastMoveFrame()
	local moveFrame = _G.SocialToastAnchorFrame and _G.SocialToastAnchorFrame.MoveFrame
	if not moveFrame or moveFrame.isSkinned then return end
	moveFrame.isSkinned = true

	moveFrame:StripTextures()
	moveFrame:SetTemplate('Transparent')

	if moveFrame.Text then
		moveFrame.Text:FontTemplate()
		moveFrame.Text:SetTextColor(1, 1, 1)
	end
end

local function SkinBNToast()
	local toast = _G.BNToastFrame
	if not toast or toast.isSkinned then return end
	toast.isSkinned = true

	toast:SetBackdrop(nil)
	toast:SetTemplate('Transparent')

	if _G.BNToastFrameIconTexture then
		S:HandleIcon(_G.BNToastFrameIconTexture, true)
	end

	if _G.BNToastFrameCloseButton then
		S:HandleCloseButton(_G.BNToastFrameCloseButton)
	end

	for _, name in next, { 'BNToastFrameTopLine', 'BNToastFrameBottomLine', 'BNToastFrameDoubleLine' } do
		local fontString = _G[name]
		if fontString then
			fontString:FontTemplate()
		end
	end
end

local function SkinStoreToast()
	local toast = _G.StoreToastFrame
	if not toast or toast.isSkinned then return end
	toast.isSkinned = true

	toast:SetBackdrop(nil)
	toast:SetTemplate('Transparent')

	if toast.Glow then
		toast.Glow:Kill()
	end

	SkinToastCloseButton(toast)
end

local function CreateToastMover()
	if E.CreatedMovers.SocialToastMover then return true end

	local anchor = _G.SocialToastAnchorFrame
	if not anchor then return false end

	anchor:ClearAllPoints()
	anchor:Point('BOTTOMLEFT', E.UIParent, 'BOTTOMLEFT', 4, 240)

	local ok = pcall(E.CreateMover, E, anchor, 'SocialToastMover', L['Toasts'])
	if not ok or not anchor.mover then return false end

	anchor.mover:Size(anchor:GetSize())

	if not anchor._elvToastSetPointHooked then
		anchor._elvToastSetPointHooked = true
		hooksecurefunc(anchor, 'SetPoint', function(frame, _, relativeTo)
			if relativeTo ~= frame.mover then
				frame:ClearAllPoints()
				frame:Point('TOPLEFT', frame.mover, 'TOPLEFT')
			end
		end)
	end

	return true
end

S:AddCallback("Skin_Toast", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.toast then return end

	if not CreateToastMover() then
		local frame = CreateFrame('Frame')
		frame:RegisterEvent('PLAYER_ENTERING_WORLD')
		frame:SetScript('OnEvent', function()
			frame:UnregisterEvent('PLAYER_ENTERING_WORLD')
			CreateToastMover()
		end)
	end

	if SocialToastSystemMixin and SocialToastSystemMixin.ShowToast then
		hooksecurefunc(SocialToastSystemMixin, 'ShowToast', function(self, toastFrame)
			SkinToast(toastFrame or self.activeToasts[#self.activeToasts])
		end)
	end

	if SocialToastAnchorFrame then
		if not SocialToastAnchorFrame._elvToastHooked then
			SocialToastAnchorFrame._elvToastHooked = true
			hooksecurefunc(SocialToastAnchorFrame, 'ShowToast', function(self)
				SkinActiveToasts(self)
			end)
		end

		SkinActiveToasts(SocialToastAnchorFrame)
	end

	if AlertFrame_ShowNewAlert then
		hooksecurefunc('AlertFrame_ShowNewAlert', function(frame)
			if frame and frame.TitleText and frame.BodyText then
				SkinToast(frame)
			end
		end)
	end

	if SocialToastMoveFrameMixin and SocialToastMoveFrameMixin.OnShow then
		hooksecurefunc(SocialToastMoveFrameMixin, 'OnShow', function()
			SkinToastMoveFrame()
		end)
	end

	SkinToastMoveFrame()
	SkinBNToast()
	SkinStoreToast()
end)
