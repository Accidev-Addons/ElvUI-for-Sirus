local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

S:AddCallback("Skin_MirrorTimers", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.mirrorTimers then return end

	for i = 1, MIRRORTIMER_NUMTIMERS do
		local frame = _G["MirrorTimer"..i]
		local statusBar = frame.StatusBar

		frame.Border:Kill()
		frame.Background:Kill()
		frame.TextBorder:Kill()

		frame:Size(222, 18)

		statusBar:SetInside(frame)
		statusBar:CreateBackdrop()
		statusBar:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(statusBar)

		frame.Text:FontTemplate()
		frame.Text:ClearAllPoints()
		frame.Text:Point("CENTER", statusBar)

		hooksecurefunc(frame, "Setup", function(self, timer, value, maxvalue, paused, label)
			self.__elvLabel = label
			self.StatusBar.BarTexture:SetTexture(E.media.normTex)

			local color = _G.MirrorTimerColors[timer]
			if color then
				self.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
			end
		end)

		hooksecurefunc(frame, "UpdateStatusBarValue", function(self)
			local value = self.StatusBar:GetValue()
			local sec = math.floor(value)

			if sec ~= self.__elvSec then
				self.__elvSec = sec

				if value > 0 then
					self.Text:SetFormattedText("%s (%d:%02d)", self.__elvLabel or "", value / 60, value % 60)
				else
					self.Text:SetFormattedText("%s (0:00)", self.__elvLabel or "")
				end
			end
		end)
	end

	E:CreateMover(_G.MirrorTimerContainer, "MirrorTimerMover", L["MirrorTimer"], nil, nil, nil, "ALL,SOLO")
end)
