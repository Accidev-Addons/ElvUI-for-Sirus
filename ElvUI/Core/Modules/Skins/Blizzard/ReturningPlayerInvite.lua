local E = unpack(ElvUI)
local S = E:GetModule("Skins")

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.friends then return end

	local toggle = _G.ReturningPlayerInviteToggleButton
	if toggle and not toggle.elvReturningPlayerSkinned then
		local icon = toggle.Icon
		local texture = icon and icon:GetTexture()
		toggle:StripTextures()
		toggle:SetTemplate("Default")
		toggle:StyleButton()
		if icon then
			icon:SetTexture(texture and texture ~= E.ClearTexture and texture ~= "" and texture or [[Interface\Icons\SOR-mail]])
			icon:SetDrawLayer("ARTWORK")
			toggle:EnableDrawLayer("ARTWORK")
			icon:SetVertexColor(1, 1, 1)
			icon:Show()
			icon:SetAlpha(1)
			icon:SetTexCoords()
			icon:SetInside()
		end
		toggle.elvReturningPlayerSkinned = true
	end

	local frame = _G.ReturningPlayerInviteFrame
	if not frame or frame.elvReturningPlayerSkinned then return end
	frame.elvReturningPlayerSkinned = true

	frame:StripTextures()
	frame:SetTemplate("Transparent")
	if _G.ReturningPlayerInviteFrameCloseButton then
		S:HandleCloseButton(_G.ReturningPlayerInviteFrameCloseButton)
	end
	if frame.RefreshButton then S:HandleButton(frame.RefreshButton) end
	if frame.GetLinkButton then S:HandleButton(frame.GetLinkButton) end

	local list = frame.List
	local scroll = list and list.ScrollFrame
	if list then
		list:StripTextures()
		list:SetTemplate("Default")
	end
	if scroll and scroll.scrollBar then S:HandleSirusScrollBar(scroll.scrollBar) end
	if frame.Link and frame.Link.URL then
		S:HandleEditBox(frame.Link.URL)
		frame.Link.URL:SetHeight(24)
	end

	local function SkinCandidates()
		for _, button in ipairs(scroll and scroll.buttons or {}) do
			if not button.elvReturningPlayerSkinned then
				local highlight = button:GetHighlightTexture()
				if highlight then highlight:SetTexture(E.Media.Textures.Highlight) end
				button.elvReturningPlayerSkinned = true
			end
			S:ApplyElvUIFont(button)
		end
	end

	if frame.UpdateCandidateList then hooksecurefunc(frame, "UpdateCandidateList", SkinCandidates) end
	if frame.Update then
		hooksecurefunc(frame, "Update", function()
			if frame.ErrorText then frame.ErrorText:FontTemplate() end
		end)
	end
	frame:HookScript("OnShow", SkinCandidates)
	S:ApplyElvUIFont(frame)
	SkinCandidates()
end

S:AddCallback("Skin_ReturningPlayerInvite", LoadSkin)
