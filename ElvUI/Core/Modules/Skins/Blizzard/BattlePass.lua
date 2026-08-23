local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G

local function GetBattlePassFrameScale()
	local parentScale = E.global.general.UIScale or (UIParent and UIParent:GetScale()) or 1
	if parentScale > 0 and parentScale < 0.7 and (GetScreenWidth() >= 2560 or GetScreenHeight() >= 1440) then
		return 0.75
	end

	return parentScale
end

local function StyleTutorialButton(btn)
	if not btn then
		return
	end
	if btn.backdrop then
		btn.backdrop:Hide()
	end
	if btn.HelpI then
		btn.HelpI:SetAllPoints(btn)
		btn.HelpI:SetDrawLayer("ARTWORK")
		btn.HelpI:SetVertexColor(1, 1, 1)
	end
	local ht = (btn.GetHighlightTexture and btn:GetHighlightTexture()) or btn.HighlightTexture
	if not ht then
		ht = btn:CreateTexture(nil, "HIGHLIGHT")
		ht:SetAllPoints(btn)
		btn.HighlightTexture = ht
	end
	S:HandleButtonHighlight(ht, 1, 1, 1, 0.25)
	if btn.SetHitRectInsets then
		btn:SetHitRectInsets(4, 4, 4, 4)
	end
end

local function CleanPageButton(btn)
	if not btn then
		return
	end
	S:HandleButton(btn)

	if btn.SetNormalTexture then
		btn:SetNormalTexture("")
	end
	if btn.SetPushedTexture then
		btn:SetPushedTexture("")
	end
	if btn.GetHighlightTexture then
		local ht = btn:GetHighlightTexture()
		if ht then
			ht:SetTexture()
			ht:SetAlpha(0)
		end
		btn:SetHighlightTexture("")
	end

	if btn.Background then
		btn.Background:SetTexture(0, 0, 0, 0)
		btn.Background:SetAlpha(0)
	end
	if btn.DisabledBackground then
		btn.DisabledBackground:SetTexture(0, 0, 0, 0)
		btn.DisabledBackground:SetAlpha(0)
	end

	for i = 1, (btn:GetNumRegions() or 0) do
		local region = select(i, btn:GetRegions())
		if region and region.IsObjectType and region:IsObjectType("Texture") then
			region:SetTexture()
			region:SetAlpha(0)
		end
	end

	btn:HookScript("OnShow", function(self)
		if self.GetHighlightTexture then
			local ht = self:GetHighlightTexture()
			if ht then
				ht:SetTexture()
				ht:SetAlpha(0)
			end
		end
		if self.Background then
			self.Background:SetTexture(0, 0, 0, 0)
			self.Background:SetAlpha(0)
		end
		if self.DisabledBackground then
			self.DisabledBackground:SetTexture(0, 0, 0, 0)
			self.DisabledBackground:SetAlpha(0)
		end
		for i = 1, (self:GetNumRegions() or 0) do
			local r = select(i, self:GetRegions())
			if r and r.IsObjectType and r:IsObjectType("Texture") then
				r:SetTexture()
				r:SetAlpha(0)
			end
		end
	end)
end

local function ReskinPKBTButton(btn, noBackdrop)
	if not btn or not btn.IsObjectType or not btn:IsObjectType("Button") then
		return
	end

	local function clearChrome(b)
		if b.Left then
			b.Left:SetAlpha(0)
		end
		if b.Right then
			b.Right:SetAlpha(0)
		end
		if b.Center then
			b.Center:SetAlpha(0)
		end
		if b.LeftHighlight then
			b.LeftHighlight:SetAlpha(0)
		end
		if b.RightHighlight then
			b.RightHighlight:SetAlpha(0)
		end
		if b.CenterHighlight then
			b.CenterHighlight:SetAlpha(0)
		end
		if b.SetNormalTexture then
			b:SetNormalTexture("")
		end
		if b.SetHighlightTexture then
			b:SetHighlightTexture("")
		end
		if b.SetPushedTexture then
			b:SetPushedTexture("")
		end
		if b.SetDisabledTexture then
			b:SetDisabledTexture("")
		end

		if b.Glow then
			b.Glow:Hide()
		end
	end

	if not btn._Elv_BaseSkinned then

		for i = 1, (btn:GetNumRegions() or 0) do
			local r = select(i, btn:GetRegions())
			if r and r.IsObjectType and r:IsObjectType("Texture") then
				r:SetTexture()
				r:SetAlpha(0)
			end
		end

		S:HandleButton(btn, true, nil, false, noBackdrop)
		btn._Elv_BaseSkinned = true
	end

	clearChrome(btn)

	S:ApplyElvUIFontForce(btn)

	if not btn._Elv_ClearHooks then
		btn._Elv_ClearHooks = true
		if btn.SetThreeSliceAtlas then
			hooksecurefunc(btn, "SetThreeSliceAtlas", function(self)
				clearChrome(self)
			end)
		end
		if btn.SetNormalAtlas then
			hooksecurefunc(btn, "SetNormalAtlas", function(self)
				clearChrome(self)
			end)
		end
		if btn.SetHighlightAtlas then
			hooksecurefunc(btn, "SetHighlightAtlas", function(self)
				clearChrome(self)
			end)
		end
		if btn.SetPushedAtlas then
			hooksecurefunc(btn, "SetPushedAtlas", function(self)
				clearChrome(self)
			end)
		end

		if btn.UpdateButton then
			hooksecurefunc(btn, "UpdateButton", function(self)
				clearChrome(self)
			end)
		end
		btn:HookScript("OnShow", function(self)
			clearChrome(self)
			S:ApplyElvUIFontForce(self)
		end)
	end
end

local function SkinQuestActionButton(questFrame)
	if not questFrame or not questFrame.ActionButton then return end

	ReskinPKBTButton(questFrame.ActionButton)
end

local function HandleBattlePassFrame()
	if not _G.BattlePassFrame then
		return
	end

	local f = _G.BattlePassFrame

	f:StripTextures(true)
	f:SetTemplate("NoBackdrop")
	if f.NineSlice then
		f.NineSlice:Hide()
	end
	f:CreateBackdrop("Transparent")
	if f.backdrop then
		f.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
	end

	if not f._Elv_ScaleHooked then
		f._Elv_ScaleHooked = true
		f:HookScript("OnShow", function(self)
			self:SetScale(GetBattlePassFrameScale())
		end)
	end

	if f.Inset then
		if f.Inset.NineSlice then
			f.Inset.NineSlice:Hide()
		end
		if f.Inset.Top then
			f.Inset.Top:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.Middle then
			f.Inset.Middle:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.Bottom then
			f.Inset.Bottom:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.NineSliceBorder then
			f.Inset.NineSliceBorder:Hide()
		end
		if f.Inset.NineSliceGlow then
			f.Inset.NineSliceGlow:Hide()
		end
		if f.Inset.ShadowLeft then
			f.Inset.ShadowLeft:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.ShadowRight then
			f.Inset.ShadowRight:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.VignetteTopRight then
			f.Inset.VignetteTopRight:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.VignetteBottomLeft then
			f.Inset.VignetteBottomLeft:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.VignetteBottomRight then
			f.Inset.VignetteBottomRight:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.ArtworkBottomLeft then
			f.Inset.ArtworkBottomLeft:SetTexture(0, 0, 0, 0)
		end
		if f.Inset.DecorOverlay then
			f.Inset.DecorOverlay:Hide()
		end
	end

	if f.CloseButton then
		S:HandleCloseButton(f.CloseButton)
	end

	if f.TopPanel then
		if f.TopPanel.SeasonTimer then
			local st = f.TopPanel.SeasonTimer
			if st.TimeLeft then
				st.TimeLeft:FontTemplate(nil, 18, "NONE")
			end
			if st.TimeLeftLabel then
				st.TimeLeftLabel:FontTemplate(nil, 12, "NONE")
			end
		end

		if f.TopPanel.ExperiencePanel then
			local ep = f.TopPanel.ExperiencePanel
			if ep.PurchaseButton then
				CleanPageButton(ep.PurchaseButton)
			end
			if ep.StatusBar then
				S:HandleStatusBar(ep.StatusBar)
				if ep.StatusBar.Background then
					ep.StatusBar.Background:SetTexture(nil)
					ep.StatusBar.Background:SetAlpha(0)
				end
				if ep.StatusBar.Overlay then
					ep.StatusBar.Overlay:SetTexture(nil)
					ep.StatusBar.Overlay:SetAlpha(0)
				end
			end
		end

		if f.TopPanel.RewardPageButton then
			CleanPageButton(f.TopPanel.RewardPageButton)
		end
		if f.TopPanel.QuestPageButton then
			CleanPageButton(f.TopPanel.QuestPageButton)
		end
		if f.TopPanel.Tutorial then
			StyleTutorialButton(f.TopPanel.Tutorial)
		end
	end

	S:ApplyElvUIFont(f.TopPanel)

	if f.Content and f.Content.QuestPage and not f.Content.QuestPage._Elv_FontHooked then
		f.Content.QuestPage._Elv_FontHooked = true
		hooksecurefunc(f.Content.QuestPage, "UpdateQuestHolders", function(self)
			S:ApplyElvUIFont(self)
			for _, holder in next, self.questHolders do
				if holder and holder.questFrames then
					for _, questFrame in ipairs(holder.questFrames) do
						SkinQuestActionButton(questFrame)
					end
				end
			end
		end)
	end
	if _G.BattlePassQuestHolderMixin and _G.BattlePassQuestHolderMixin.UpdateQuests and not S._Elv_QuestHolderFontsHooked then
		S._Elv_QuestHolderFontsHooked = true
		hooksecurefunc(_G.BattlePassQuestHolderMixin, "UpdateQuests", function(self)
			S:ApplyElvUIFont(self)
			if self.questFrames then
				for _, questFrame in ipairs(self.questFrames) do
					SkinQuestActionButton(questFrame)
				end
			end
		end)
	end
	if _G.BattlePassQuestMixin and not S._Elv_QuestActionButtonsHooked then
		S._Elv_QuestActionButtonsHooked = true
		hooksecurefunc(_G.BattlePassQuestMixin, "UpdateActionButton", function(self)
			if self.ActionButton then
				ReskinPKBTButton(self.ActionButton)
			end
		end)
	end

	if f.Content and f.Content.MainPage then
		local main = f.Content.MainPage

		if _G.BattlePassLevelCardMixin and not S._Elv_LevelCardButtonsHooked then
			S._Elv_LevelCardButtonsHooked = true
			hooksecurefunc(_G.BattlePassLevelCardMixin, "SetTypeState", function(self)
					local freeButton = self.FreeFrame and self.FreeFrame.ActionButton
					local premButton = self.PremiumFrame and self.PremiumFrame.ActionButton
					if freeButton then
						ReskinPKBTButton(freeButton)
					end
					if premButton then
						ReskinPKBTButton(premButton)
					end
				end)
				hooksecurefunc(_G.BattlePassLevelCardMixin, "SetState", function(self)
					if self.SetScript then
						self:SetScript("OnUpdate", nil)
					end
					local fb = self.FreeFrame and self.FreeFrame.ActionButton
					local pb = self.PremiumFrame and self.PremiumFrame.ActionButton
					if fb then
						ReskinPKBTButton(fb)
						fb:Show()
					end
					if pb then
						ReskinPKBTButton(pb)
						pb:Show()
					end
				end)
				hooksecurefunc(_G.BattlePassLevelCardMixin, "OnLeave", function(self)
					local fb = self.FreeFrame and self.FreeFrame.ActionButton
					local pb = self.PremiumFrame and self.PremiumFrame.ActionButton
					if fb then
						ReskinPKBTButton(fb)
						fb:Show()
					end
					if pb then
						ReskinPKBTButton(pb)
						pb:Show()
					end
				end)
		end

		if main.ScrollFrame and main.ScrollFrame.buttons then
			for _, card in ipairs(main.ScrollFrame.buttons) do
				local fb = card.FreeFrame and card.FreeFrame.ActionButton
				local pb = card.PremiumFrame and card.PremiumFrame.ActionButton
				if fb then
					ReskinPKBTButton(fb)
				end
				if pb then
					ReskinPKBTButton(pb)
				end
			end
		end
		if main.ScrollFrame and main.ScrollFrame.ScrollBar then
			S:HandleSirusScrollBar(main.ScrollFrame.ScrollBar)
		end
		if main.ExperienceScrollFrame and main.ExperienceScrollFrame.ScrollChild and
			main.ExperienceScrollFrame.ScrollChild.ExperienceStatusBar then
			local esb = main.ExperienceScrollFrame.ScrollChild.ExperienceStatusBar
			S:HandleStatusBar(esb)
			if esb.Background then
				esb.Background:SetTexture(nil)
				esb.Background:SetAlpha(0)
			end
			if esb.Overlay then
				esb.Overlay:SetTexture(nil)
				esb.Overlay:SetAlpha(0)
			end
		end

		if main.TakeAllRewardsCheckButton then
			S:HandleCheckBox(main.TakeAllRewardsCheckButton)
			local cb = main.TakeAllRewardsCheckButton
			local function FixDuplicateLabel()
				local first
				for i = 1, (cb:GetNumRegions() or 0) do
					local r = select(i, cb:GetRegions())
					if r and r:GetObjectType() == "FontString" then
						local txt = r.GetText and r:GetText()
						if txt and txt ~= "" then
							if first then
								if r.Hide then
									r:Hide()
								end
							else
								first = r
								if r.Show then
									r:Show()
								end
								local _, size, flags = r:GetFont()
								r:SetFont(E.media.normFont or (select(1, GameFontNormal:GetFont())),
									size and size >= 1 and size or 12,
									flags or "")
							end
						end
					end
				end
			end
			FixDuplicateLabel()
			if not cb._Elv_FixDuplicateHooked then
				cb._Elv_FixDuplicateHooked = true
				cb:HookScript("OnShow", FixDuplicateLabel)
			end
		end

		if main.PurchasePremiumButton then
			ReskinPKBTButton(main.PurchasePremiumButton)
		end
		S:ApplyElvUIFont(main)
	end

	if f.Content and f.Content.QuestPage and f.Content.QuestPage.ScrollFrame and f.Content.QuestPage.ScrollFrame.ScrollBar then
		S:HandleSirusScrollBar(f.Content.QuestPage.ScrollFrame.ScrollBar)
	end
	if f.Content and f.Content.QuestPage then
		S:ApplyElvUIFont(f.Content.QuestPage)
	end

	if f.PurchasePremiumDialog then
		local d = f.PurchasePremiumDialog
		S:HandleFrame(d)
		if d.CloseButton then
			S:HandleCloseButton(d.CloseButton)
		end
		if d.PurchaseButton then

			ReskinPKBTButton(d.PurchaseButton)
		end
		S:ApplyElvUIFont(d)
	end

	if f.PurchaseExperienceDialog then
		local d = f.PurchaseExperienceDialog
		S:HandleFrame(d)
		if d.CloseButton then
			S:HandleCloseButton(d.CloseButton)
		end
		if d.PurchaseButton then
			CleanPageButton(d.PurchaseButton)
		end
		if d.OptionAmount then
			S:HandleEditBox(d.OptionAmount)
			if d.OptionAmount.Left then
				d.OptionAmount.Left:SetAlpha(0)
			end
			if d.OptionAmount.Right then
				d.OptionAmount.Right:SetAlpha(0)
			end
			if d.OptionAmount.Center then
				d.OptionAmount.Center:SetAlpha(0)
			end
			for i = 1, (d.OptionAmount:GetNumRegions() or 0) do
				local r = select(i, d.OptionAmount:GetRegions())
				if r and r.IsObjectType and r:IsObjectType("Texture") then
					r:SetTexture()
					r:SetAlpha(0)
				end
			end
		end

		if d.NineSlice then
			d.NineSlice:Hide()
		end
		if d.Background then
			d.Background:SetTexture(0, 0, 0, 0)
			d.Background:SetAlpha(0)
		end
		if d.VignetteTopLeft then
			d.VignetteTopLeft:SetTexture(0, 0, 0, 0)
			d.VignetteTopLeft:SetAlpha(0)
		end
		if d.VignetteTopRight then
			d.VignetteTopRight:SetTexture(0, 0, 0, 0)
			d.VignetteTopRight:SetAlpha(0)
		end

		if d.OptionAmount then
			local inc = d.OptionAmount.IncrementButton
			local dec = d.OptionAmount.DecrementButton
			if inc and inc.IsObjectType and inc:IsObjectType("Button") then
				if S.HandleNextPrevButton then
					S:HandleNextPrevButton(inc)
				else
					S:HandleButton(inc)
				end
				if S.SetNextPrevButtonDirection then
					S:SetNextPrevButtonDirection(inc, "right")
				end
				if inc.ClearAllPoints then
					inc:ClearAllPoints()
				end
				if inc.SetPoint then
					inc:SetPoint("RIGHT", d.OptionAmount, "RIGHT", -14, -2)
				end
				if inc.SetSize then
					inc:SetSize(18, 18)
				end
				if d.OptionAmount.GetFrameLevel then
					inc:SetFrameLevel(d.OptionAmount:GetFrameLevel() + 2)
				end
				if inc.Show then
					inc:Show()
				end
			end
			if dec and dec.IsObjectType and dec:IsObjectType("Button") then
				if S.HandleNextPrevButton then
					S:HandleNextPrevButton(dec)
				else
					S:HandleButton(dec)
				end
				if S.SetNextPrevButtonDirection then
					S:SetNextPrevButtonDirection(dec, "left")
				end
				if dec.ClearAllPoints then
					dec:ClearAllPoints()
				end
				if dec.SetPoint then
					dec:SetPoint("LEFT", d.OptionAmount, "LEFT", 14, -2)
				end
				if dec.SetSize then
					dec:SetSize(18, 18)
				end
				if d.OptionAmount.GetFrameLevel then
					dec:SetFrameLevel(d.OptionAmount:GetFrameLevel() + 2)
				end
				if dec.Show then
					dec:Show()
				end
			end
		end
	end

	if f.PurchaseLevelExperienceDialog then
		local d = f.PurchaseLevelExperienceDialog
		d:StripTextures(true)
		d:SetTemplate("Transparent")
		if d.CloseButton then
			S:HandleCloseButton(d.CloseButton)
		end
		if d.PurchaseButton then
			ReskinPKBTButton(d.PurchaseButton)
		end
		S:ApplyElvUIFont(d)
	end

	if f.QuestActionDialog then
		local d = f.QuestActionDialog
		d:StripTextures(true)
		d:SetTemplate("Transparent")
		if d.NineSlice then
			d.NineSlice:Hide()
		end
		if d.SetBackdropBorderColor then
			d:SetBackdropBorderColor(0, 0, 0, 0)
		end
		if d.backdrop and d.backdrop.SetBackdropBorderColor then
			d.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
		end
		if d.OkButton then
			ReskinPKBTButton(d.OkButton)
		end
		if d.CancelButton then
			ReskinPKBTButton(d.CancelButton)
		end
		S:ApplyElvUIFont(d)
	end

	if f.ItemRewardFrame then
		local d = f.ItemRewardFrame
		d:StripTextures(true)
		d:SetTemplate("Transparent")
		if d.CloseButton then
			S:HandleCloseButton(d.CloseButton)
		end
		S:ApplyElvUIFont(d)
	end

	if f.AlertFrame then
		local d = f.AlertFrame
		d:StripTextures(true)
		d:SetTemplate("Transparent")
		S:ApplyElvUIFont(d)
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.battlePass then
		return
	end

	if _G.BattlePassFrame then
		HandleBattlePassFrame()
	else
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_LOGIN")
		f:SetScript("OnEvent", function(self)
			if _G.BattlePassFrame then
				HandleBattlePassFrame()
				self:UnregisterAllEvents()
			end
		end)
	end
end

S:AddCallback("Skin_BattlePass", LoadSkin)