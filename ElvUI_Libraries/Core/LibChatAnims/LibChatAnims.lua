
local MAJOR, MINOR = "LibChatAnims", 10002 -- Bump minor on changes
local LCA = LibStub:NewLibrary(MAJOR, MINOR)
if not LCA then return end -- No upgrade needed

LCA.animations = LCA.animations or {} -- Animation storage
local anims = LCA.animations

local UIFrameFlashStop = UIFrameFlashStop

local function getAnim(region)
	local anim = anims[region]
	if not anim then
		anim = region:CreateAnimationGroup()

		local fade1 = anim:CreateAnimation("Alpha")
		fade1:SetDuration(1)
		fade1:SetChange(1)
		fade1:SetOrder(1)

		local fade2 = anim:CreateAnimation("Alpha")
		fade2:SetDuration(1)
		fade2:SetChange(-1)
		fade2:SetOrder(2)

		anims[region] = anim
	end

	return anim
end

local function startPulse(region)
	if not region then return end

	UIFrameFlashStop(region)

	local anim = getAnim(region)
	region:Show()
	region:SetAlpha(0)
	anim:SetLooping("REPEAT")
	anim:Play()
end

local function stopPulse(region, hide)
	if not region then return end

	UIFrameFlashStop(region)

	if anims[region] then
		anims[region]:Stop()
	end

	if hide then
		region:Hide()
	else
		region:SetAlpha(1)
		region:Show()
	end
end

local function chatTabOf(chatFrame)
	local name = chatFrame and chatFrame.GetName and chatFrame:GetName()
	return name and _G[name.."Tab"]
end

if FCF_StartAlertFlash then
	hooksecurefunc("FCF_StartAlertFlash", function(chatFrame)
		if chatFrame.minFrame then
			startPulse(chatFrame.minFrame.glow)
		end

		local chatTab = chatTabOf(chatFrame)
		if chatTab then
			startPulse(chatTab.glow)
		end
	end)
end

if FCF_StopAlertFlash then
	hooksecurefunc("FCF_StopAlertFlash", function(chatFrame)
		if chatFrame.minFrame then
			stopPulse(chatFrame.minFrame.glow, true)
		end

		local chatTab = chatTabOf(chatFrame)
		if chatTab then
			stopPulse(chatTab.glow, true)
		end
	end)
end

if FCFDockOverflowButton_UpdatePulseState then
	hooksecurefunc("FCFDockOverflowButton_UpdatePulseState", function(self)
		local tex = self.GetHighlightTexture and self:GetHighlightTexture()
		if not tex then return end

		if self.alerting then
			startPulse(tex)
		else
			stopPulse(tex)
		end
	end)
end

if FCFDockOverflowListButton_SetValue then
	hooksecurefunc("FCFDockOverflowListButton_SetValue", function(button)
		if button.alerting then
			startPulse(button.glow)
		else
			stopPulse(button.glow, true)
		end
	end)
end
