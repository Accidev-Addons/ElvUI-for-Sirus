local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local tonumber = tonumber
local match = string.match
--WoW API / Variables

S:AddCallback("Skin_Alerts", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.alertframes then return end

	S:RawHook("AchievementAlertFrame_GetAlertFrame", function()
		local frame = S.hooks.AchievementAlertFrame_GetAlertFrame()

		if frame and not frame.isSkinned then
			local name = frame:GetName()

			frame:DisableDrawLayer("OVERLAY")

			frame:CreateBackdrop("Transparent")
			frame.backdrop:Point("TOPLEFT", 0, -6)
			frame.backdrop:Point("BOTTOMRIGHT", 0, 6)

			S:SetBackdropHitRect(frame)

			_G[name.."Background"]:SetTexture(nil)
			_G[name.."Unlocked"]:SetTextColor(1, 1, 1)

			local icon = _G[name.."Icon"]
			icon:DisableDrawLayer("BACKGROUND")
			icon:DisableDrawLayer("OVERLAY")

			icon.texture:ClearAllPoints()
			icon.texture:Point("LEFT", frame, 13, 0)
			icon.texture:SetTexCoords()

			icon:CreateBackdrop("Default")
			icon.backdrop:SetOutside(icon.texture)

			frame.isSkinned = true

			if tonumber(match(name, "(%d+)$")) == MAX_ACHIEVEMENT_ALERTS then
				S:Unhook("AchievementAlertFrame_GetAlertFrame")
			end
		end

		return frame
	end, true)

	local frame = DungeonCompletionAlertFrame1
	frame:DisableDrawLayer("BORDER")
	frame:DisableDrawLayer("OVERLAY")

	frame:CreateBackdrop("Transparent")
	frame.backdrop:Point("TOPLEFT", 0, -6)
	frame.backdrop:Point("BOTTOMRIGHT", 0, 6)

	S:SetBackdropHitRect(frame)

	frame.dungeonTexture:ClearAllPoints()
	frame.dungeonTexture:Point("LEFT", 13, 0)
	frame.dungeonTexture:Size(42)
	frame.dungeonTexture:SetTexCoords()

	frame.dungeonTexture.backdrop = CreateFrame("Frame", "$parentDungeonTextureBackground", frame)
	frame.dungeonTexture.backdrop:SetTemplate("Default")
	frame.dungeonTexture.backdrop:SetOutside(frame.dungeonTexture)
	frame.dungeonTexture.backdrop:SetFrameLevel(0)

	frame.glowFrame:DisableDrawLayer("OVERLAY")

	for i = 1, 4 do
		local button = _G["LootAlertButton"..i]

		button:DisableDrawLayer("OVERLAY")
		button.Background:SetAlpha(0)
		button.IconBorder:SetAlpha(0)

		button:CreateBackdrop("Transparent")
		button.backdrop:Point("TOPLEFT", 14, -15)
		button.backdrop:Point("BOTTOMRIGHT", -16, 11)

		S:SetBackdropHitRect(button)

		local iconBackdrop = CreateFrame("Frame", nil, button)
		iconBackdrop:SetTemplate("Default")
		iconBackdrop:SetOutside(button.Icon)

		button.Icon:SetTexCoords()
		button.Icon:SetParent(iconBackdrop)
		button.Count:SetParent(iconBackdrop)

		hooksecurefunc(button.ItemName, "SetTextColor", function(_, r, g, b)
			iconBackdrop:SetBackdropBorderColor(r, g, b)
		end)
	end
end)

S:AddCallback("Skin_BossBanner", function()
	if not E.private.skins.blizzard.enable then return end

	for _, name in next, { "BossBannerOverlay", "BossBanner" } do
		local frame = _G[name]
		if frame then
			S:ApplyElvUIFont(frame)
			frame:HookScript("OnShow", function(self)
				S:ApplyElvUIFont(self)
			end)
		end
	end
end)
