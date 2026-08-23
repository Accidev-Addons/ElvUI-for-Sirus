------------------------------------------------------------------------
-- Animation Functions
------------------------------------------------------------------------
local E, L, V, P, G = unpack(ElvUI)

local _G = _G
local next = next
local unpack, strsub = unpack, strsub

local function CreateRotator(obj, layer, texture)
	local region = obj:CreateTexture(nil, layer)
	region:SetTexture(texture)
	region:SetPoint("CENTER")

	local anim = region:CreateAnimationGroup()
	anim:SetLooping("REPEAT")
	region.Anim = anim

	local rotation = anim:CreateAnimation("Rotation")
	rotation:SetDuration(1)
	rotation:SetDegrees(-360)
	anim.Rotation = rotation

	return region
end

E.AnimMoveOut = function(out1) out1.parent:Hide() end
E.AnimElastic = {
	function(anim) anim:Stop() anim.elastic[2]:Play() end,
	function(anim) anim:Stop() if anim.loop then anim.elastic[1]:Play() end end,
	function(anim) anim:Stop() anim.elastic[4]:Play() end,
	function(anim) anim:Stop() if anim.loop then anim.elastic[3]:Play() end end
}

function E:FlashLoopFinished(requested)
	if not requested then self:Play() end
end

function E:SetUpAnimGroup(obj, animType, ...)
	if not animType then -- default it to something basic
		animType = "Flash"
	end

	local shortType = strsub(animType, 1, 5)
	if shortType == "Flash" then
		obj.anim = obj:CreateAnimationGroup("Flash")
		obj.anim.fadein = obj.anim:CreateAnimation("ALPHA", "FadeIn")
		obj.anim.fadein:SetChange(1)
		obj.anim.fadein:SetOrder(2)

		obj.anim.fadeout = obj.anim:CreateAnimation("ALPHA", "FadeOut")
		obj.anim.fadeout:SetChange(-1)
		obj.anim.fadeout:SetOrder(1)

		if animType == "FlashLoop" then
			obj.anim:SetScript("OnFinished", E.FlashLoopFinished)
		end
	elseif animType == "Elastic" then
		local width, height, duration, loop = ...
		local elastic = _G.CreateAnimationGroup(obj)
		obj.elastic = elastic

		for i = 1, 4 do
			local anim = elastic:CreateAnimation(i < 3 and "width" or "height")
			anim:SetChange((i==1 and width*0.45) or (i==2 and width) or (i==3 and height*0.45) or height)
			anim:SetEasing("inout-elastic")
			anim:SetDuration(duration)
			anim:SetScript("OnFinished", E.AnimElastic[i])
			anim.elastic = elastic
			anim.loop = loop

			elastic[i] = anim
		end
	elseif animType == "Spinner" then
		if not obj.Spinner then
			local spinner = obj:CreateTexture()
			spinner:SetTexture(E.Media.Textures.StreamFrame)
			spinner:SetPoint("CENTER")
			spinner:SetAlpha(0.5)
			obj.Spinner = spinner
		end

		if not obj.Circle then
			obj.Circle = CreateRotator(obj, "BORDER", E.Media.Textures.StreamCircle)
		end

		if not obj.Spark then
			obj.Spark = CreateRotator(obj, "OVERLAY", E.Media.Textures.StreamSpark)
		end
	else
		local x, y, duration, customName = ...
		local anim = obj:CreateAnimationGroup("Move_In")
		obj[customName or "anim"] = anim

		-- anim play will cause it to move
		anim.in1 = anim:CreateAnimation("Translation")
		anim.in1:SetDuration(0)
		anim.in1:SetOrder(1)
		anim.in1:SetOffset(x, y)

		anim.in2 = anim:CreateAnimation("Translation")
		anim.in2:SetDuration(duration)
		anim.in2:SetOrder(2)
		anim.in2:SetSmoothing("OUT")
		anim.in2:SetOffset(-x, -y)

		-- out animation to play backwards (to start position of anim play)
		anim.out1 = obj:CreateAnimationGroup("Move_Out")
		anim.out1:SetScript("OnFinished", E.AnimMoveOut)
		anim.out1.parent = obj

		anim.out2 = anim.out1:CreateAnimation("Translation")
		anim.out2:SetDuration(duration)
		anim.out2:SetOrder(1)
		anim.out2:SetSmoothing("IN")
		anim.out2:SetOffset(x, y)
	end
end

function E:Elasticize(obj, width, height)
	if not obj.elastic then
		E:SetUpAnimGroup(obj, "Elastic", width or obj:GetWidth(), height or obj:GetHeight(), 2, false)
	end

	obj.elastic[1]:Play()
	obj.elastic[3]:Play()
end

function E:StopElasticize(obj)
	if obj.elastic then
		obj.elastic[1]:Stop(true)
		obj.elastic[3]:Stop(true)
	end
end

function E:Flash(obj, duration, loop)
	if not obj.anim then
		E:SetUpAnimGroup(obj, loop and "FlashLoop" or "Flash")
	end

	if not obj.anim:IsPlaying() then
		obj.anim.fadein:SetDuration(duration)
		obj.anim.fadeout:SetDuration(duration)
		obj.anim:Play()
	end
end

function E:StopFlash(obj)
	if obj.anim and obj.anim:IsPlaying() then
		obj.anim:Stop()
	end
end

function E:StartSpinner(obj, left, top, right, bottom, size, r, g, b)
	if not obj.Spinner then
		E:SetUpAnimGroup(obj, "Spinner")
	end

	obj.Spark:Size(size or 48)
	obj.Spinner:Size(size or 48)
	obj.Circle:Size(size or 48)
	obj.Circle:SetVertexColor(r or 1, g or 0.82, b or 0)

	obj:ClearAllPoints()

	if top or bottom or left or right then
		obj:Point("TOPLEFT", left or 0, top or 0)
		obj:Point("BOTTOMRIGHT", right or 0, bottom or 0)
	else
		obj:SetAllPoints()
	end

	if not obj.Circle.Anim:IsPlaying() then
		obj.Circle.Anim:Play()
		obj.Spark.Anim:Play()
		obj:Show()
	end
end

function E:StopSpinner(obj)
	if obj.Circle and obj.Circle.Anim:IsPlaying() then
		obj.Circle.Anim:Stop()
		obj.Spark.Anim:Stop()
		obj:Hide()
	end
end

local FADEFRAMES, FADEMANAGER = {}, CreateFrame("FRAME")
FADEMANAGER.delay = 0.05

function E:UIFrameFade_OnUpdate(elapsed)
	FADEMANAGER.timer = (FADEMANAGER.timer or 0) + elapsed

	if FADEMANAGER.timer > FADEMANAGER.delay then
		FADEMANAGER.timer = 0

		for frame, info in next, FADEFRAMES do
			local timeToFade = info.timeToFade

			-- Reset the timer if there isn't one, this is just an internal counter
			if frame:IsVisible() then
				info.fadeTimer = (info.fadeTimer or 0) + (elapsed + FADEMANAGER.delay)
			else
				info.fadeTimer = (timeToFade or 0) + 1
			end

			-- If the fadeTimer is less then the desired fade time then set the alpha otherwise hold the fade state, call the finished function, or just finish the fade
			if timeToFade and timeToFade > 0 and info.fadeTimer < timeToFade then
				if info.mode == "IN" then
					frame:SetAlpha((info.fadeTimer / timeToFade) * info.diffAlpha + info.startAlpha)
				else
					frame:SetAlpha(((timeToFade - info.fadeTimer) / timeToFade) * info.diffAlpha + info.endAlpha)
				end
			else
				frame:SetAlpha(info.endAlpha)

				-- If there is a fadeHoldTime then wait until its passed to continue on
				if info.fadeHoldTime and info.fadeHoldTime > 0 then
					info.fadeHoldTime = info.fadeHoldTime - elapsed
				else
					-- Complete the fade and call the finished function if there is one
					E:UIFrameFadeRemoveFrame(frame)

					if info.finishedFunc then
						if info.finishedArgs then
							info.finishedFunc(unpack(info.finishedArgs))
						else -- optional method
							info.finishedFunc(info.finishedArg1, info.finishedArg2, info.finishedArg3, info.finishedArg4, info.finishedArg5)
						end

						if not info.finishedFuncKeep then
							info.finishedFunc = nil
						end
					end
				end
			end
		end

		if not next(FADEFRAMES) then
			FADEMANAGER:SetScript("OnUpdate", nil)
		end
	end
end

-- Generic fade function
function E:UIFrameFade(frame, info)
	if not frame then return end

	if not info.mode then
		info.mode = "IN"
	end

	if info.mode == "IN" then
		if not info.startAlpha then info.startAlpha = 0 end
		if not info.endAlpha then info.endAlpha = 1 end
		if not info.diffAlpha then info.diffAlpha = info.endAlpha - info.startAlpha end
	else
		if not info.startAlpha then info.startAlpha = 1 end
		if not info.endAlpha then info.endAlpha = 0 end
		if not info.diffAlpha then info.diffAlpha = info.startAlpha - info.endAlpha end
	end

	frame.fadeInfo = info
	frame:SetAlpha(info.startAlpha)

	if not FADEFRAMES[frame] then
		FADEFRAMES[frame] = info -- read below comment
		FADEMANAGER:SetScript("OnUpdate", E.UIFrameFade_OnUpdate)
	else
		FADEFRAMES[frame] = info -- keep these both, we need this updated in the event its changed to another ref from a plugin or sth, don't move it up!
	end
end

local function SimpleFade(frame, mode, timeToFade, startAlpha, endAlpha)
	if not frame then return end

	if frame.FadeObject then
		frame.FadeObject.fadeTimer = nil
	else
		frame.FadeObject = {}
	end

	frame.FadeObject.mode = mode
	frame.FadeObject.timeToFade = timeToFade
	frame.FadeObject.startAlpha = startAlpha
	frame.FadeObject.endAlpha = endAlpha
	frame.FadeObject.diffAlpha = (mode == "IN" and endAlpha - startAlpha) or startAlpha - endAlpha

	E:UIFrameFade(frame, frame.FadeObject)
end

function E:UIFrameFadeIn(frame, timeToFade, startAlpha, endAlpha)
	SimpleFade(frame, "IN", timeToFade, startAlpha, endAlpha)
end

function E:UIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
	SimpleFade(frame, "OUT", timeToFade, startAlpha, endAlpha)
end

function E:UIFrameFadeRemoveFrame(frame)
	if frame and FADEFRAMES[frame] then
		if frame.FadeObject then
			frame.FadeObject.fadeTimer = nil
		end

		FADEFRAMES[frame] = nil
	end
end
