-- Run from the repository root with Lua 5.1; no WoW client is required.
local total = 0
local function eq(actual, expected, label)
	assert(actual == expected, (label or 'value')..': expected '..tostring(expected)..', got '..tostring(actual))
end
local function test(name, fn)
	fn()
	total = total + 1
	print('PASS '..name)
end
local function read(path)
	local file = assert(io.open(path, 'rb'))
	local source = file:read('*a'):gsub('\r\n', '\n')
	file:close()
	return source
end
local function section(path, first, last)
	local source = read(path)
	local start = assert(source:find(first, 1, true), first)
	local finish = assert(source:find(last, start + #first, true), last)
	return source:sub(start, finish - 1)
end
local function run(source, env, ...)
	setmetatable(env, {__index = _G})
	local chunk = assert(loadstring(source, 'performance-module'))
	setfenv(chunk, env)
	return chunk(...)
end
local function wipe(tbl)
	for key in pairs(tbl) do tbl[key] = nil end
end
local function frame()
	local f = {scripts = {}, shown = true}
	function f:SetScript(name, fn) self.scripts[name] = fn end
	function f:HookScript(name, fn)
		local previous = self.scripts[name]
		self.scripts[name] = function(self, ...)
			if previous then previous(self, ...) end
			fn(self, ...)
		end
	end
	function f:Show()
		if self.shown then return end
		self.shown = true
		if self.scripts.OnShow then self.scripts.OnShow(self) end
	end
	function f:Hide()
		if not self.shown then return end
		self.shown = false
		if self.scripts.OnHide then self.scripts.OnHide(self) end
	end
	function f:IsShown() return self.shown end
	function f:IsVisible() return self.shown end
	function f:RegisterEvent() end
	function f:UnregisterEvent() end
	function f:UnregisterAllEvents() end
	function f:tick(elapsed)
		if self.shown and self.scripts.OnUpdate then self.scripts.OnUpdate(self, elapsed) end
	end
	return f
end
local function band(a, b)
	local value, place = 0, 1
	while a > 0 and b > 0 do
		if a % 2 == 1 and b % 2 == 1 then value = value + place end
		a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
	end
	return value
end
local libPath = 'ElvUI_Libraries/Core/oUF_Plugins/oUF_HealComm4/LibHealComm-4.0/LibHealComm-4.0.lua'
local healPath = 'ElvUI_Libraries/Core/oUF_Plugins/oUF_HealComm4/oUF_HealComm4.lua'
local auraPath = 'ElvUI/Core/Modules/Nameplates/Elements/Auras.lua'
local function pending(kind, records, variable)
	local p = {bitType = kind, endTime = 20, tickInterval = 2, hasVariableTicks = variable}
	for _, record in ipairs(records) do
		local index = #p + 1
		p[record[1]] = index
		for i = 1, 5 do p[index + i - 1] = record[i] end
	end
	return p
end
local function healAPI(data)
	local lib = {}
	local env = {HealComm = lib, pendingHeals = data, playerGUID = 'player', GetTime = function() return 10 end,
		band = band, DIRECT_HEALS = 1, BOMB_HEALS = 2, CHANNEL_HEALS = 4, HOT_HEALS = 8,
		floor = math.floor, min = math.min}
	run(section(libPath, 'local function filterData(', '-- Healing class data'), env)
	return lib
end

test('indexed heal queries preserve target, caster, time and stack filtering', function()
	local data = {
		player = {direct = pending(1, {{'a', 100, 2, 15, 0}, {'b', 70, 1, 15, 0}})},
		other = {bomb = pending(2, {{'a', 50, 1, 12, 0}}),
			hot = pending(8, {{'a', 10, 2, 18, 4}, {'b', 30, 1, 18, 4}})}
	}
	local api = healAPI(data)
	eq(api:GetHealAmount('a', 15), 330)
	eq(api:GetHealAmount('b', 15), 190)
	eq(api:GetHealAmount('missing', 15), nil)
	eq(api:GetHealAmount('a', 1), 200)
	eq(api:GetHealAmount('a', 15, nil, 'player'), 200)
	eq(api:GetOthersHealAmount('a', 15), 130)
	eq(api:GetCasterHealAmount('player', 15), 270)
	eq(api:GetHealAmount('a', 15, 14), 90)
end)

test('variable ticks, expired heals, missing caster and caster totals remain correct', function()
	local data = {other = {
		hot = pending(8, {{'a', {10, 20, 30}, 2, 16, 3}}, true),
		channel = pending(4, {{'a', 5, 1, 18, 4}}),
		expired = pending(8, {{'a', 1000, 1, 9, 4}})
	}}
	local api = healAPI(data)
	eq(api:GetHealAmount('a', 15), 140)
	eq(api:GetHealAmount('a', 15, 14), 70)
	eq(api:GetCasterHealAmount('other', 15), 140)
	eq(api:GetHealAmount('a', 15, nil, 'missing'), nil)
	eq(api:GetCasterHealAmount('missing', 15), nil)
end)

test('large indexed queries visit one target per matching spell', function()
	local data = {}
	for caster = 1, 8 do
		data[caster] = {}
		for spell = 1, 3 do
			local records = {}
			for i = 1, 40 do records[i] = {'raid'..i, 100, 1, 20, 0} end
			data[caster][spell] = pending(1, records)
		end
	end
	local source = section(libPath, 'local function filterData(', '-- Healing class data')
	local before = source:sub(1, assert(source:find('local guid = pending[i]', 1, true)) - 1)
	local _, newlines = before:gsub('\n', '')
	local visits, api = 0, healAPI(data)
	debug.sethook(function(_, line)
		if line == newlines + 1 and debug.getinfo(2, 'S').source == 'performance-module' then visits = visits + 1 end
	end, 'l')
	for i = 1, 40 do eq(api:GetHealAmount('raid'..i, 1), 2400) end
	debug.sethook()
	eq(visits, 960, 'target record visits')
end)

test('indexed and original linear traversal agree across deterministic mixed heal records', function()
	local source = section(libPath, 'local function filterData(', '-- Healing class data')
	local first = assert(source:find('\t\t\tlocal first, last = 1, #(pending)', 1, true))
	local last = assert(source:find('\t\t\t\tlocal guid = pending[i]', first, true))
	local linearSource = source:sub(1, first - 1)..'\t\t\tfor i=1, #(pending), 5 do\n'..source:sub(last)
	local random = 12345
	local function pick(n) random = (random * 16807) % 2147483647; return random % n + 1 end
	for scenario = 1, 60 do
		local data = {}
		for caster = 1, 4 do
			local spells = {}; data[caster == 1 and 'player' or tostring(caster)] = spells
			for spell = 1, 4 do
				local kind = 2 ^ (spell - 1)
				local records = {}
				local variable = spell == 4 and pick(2) == 1
				for target = 1, 8 do
					if pick(3) ~= 1 then
						local amount = variable and {pick(100), pick(100), pick(100)} or pick(100)
						records[#records + 1] = {'unit'..target, amount, pick(3), pick(24), 3}
					end
				end
				spells[spell] = pending(kind, records, variable)
			end
		end
		local optimized, reference = healAPI(data), {}
		run(linearSource, {HealComm = reference, pendingHeals = data, playerGUID = 'player',
			GetTime = function() return 10 end, band = band, DIRECT_HEALS = 1, BOMB_HEALS = 2,
			CHANNEL_HEALS = 4, HOT_HEALS = 8, floor = math.floor, min = math.min})
		for target = 1, 9 do
			local guid, flags, horizon = 'unit'..target, pick(15), pick(30)
			eq(optimized:GetHealAmount(guid, flags, horizon), reference:GetHealAmount(guid, flags, horizon))
			eq(optimized:GetHealAmount(guid, flags), reference:GetHealAmount(guid, flags))
			eq(optimized:GetOthersHealAmount(guid, flags, horizon), reference:GetOthersHealAmount(guid, flags, horizon))
			eq(optimized:GetCasterHealAmount('player', flags, horizon), reference:GetCasterHealAmount('player', flags, horizon))
		end
	end
end)

local function healModule()
	local api, callbacks, driver, element = {}, {}, nil, nil
	local calls, guidCalls, posts = 0, 0, 0
	local now, modifier, health, maxHealth = 0, 1, 50, 200
	local values = {}
	local guids = {player = 'player'}
	function api:GetHealModifier() return modifier end
	function api:GetHealAmount(_, _, _, caster) calls = calls + 1; return caster and 20 or 60 end
	function api.RegisterCallback(_, event, fn) callbacks[event] = fn end
	function api.UnregisterCallback(_, event) callbacks[event] = nil end
	local ouf = {AddElement = function(_, _, path, enable, disable) element = {path = path, enable = enable, disable = disable} end}
	run(read(healPath), {wipe = wipe, LibStub = function() return api end,
		CreateFrame = function() driver = frame(); return driver end,
		GetTime = function() return now end,
		UnitGUID = function(unit) guidCalls = guidCalls + 1; return guids[unit] end,
		UnitHealth = function() return health end, UnitHealthMax = function() return maxHealth end,
		UnitGetTotalAbsorbs = function() return 10 end, UnitGetTotalHealAbsorbs = function() return 0 end}, 'test', {oUF = ouf})
	local function add(unit)
		local f = frame(); f.unit = unit; guids[unit] = unit
		f.HealCommBar = {PostUpdate = function(_, _, myHeal, otherHeal)
			posts = posts + 1; values.myHeal, values.otherHeal = myHeal, otherHeal
		end}
		element.enable(f)
		return f
	end
	return {callbacks = callbacks, driver = driver, element = element, add = add,
		counts = function() return calls, guidCalls, posts end,
		reset = function() calls, guidCalls, posts = 0, 0, 0 end,
		time = function(value) now = value end, modifier = function(value) modifier = value end,
		guid = function(unit, value) guids[unit] = value end, values = values,
		health = function(value, maximum) health, maxHealth = value, maximum or maxHealth end}
end

test('HealComm callbacks coalesce GUIDs and update each matching frame once', function()
	local m = healModule()
	local targets = {}
	for i = 1, 40 do m.add('raid'..i); targets[i] = 'raid'..i end
	local callback = m.callbacks.HealComm_HealStarted
	callback('HealComm_HealStarted', 'caster', 1, 1, 0, unpack(targets))
	callback('HealComm_HealStarted', 'caster', 1, 1, 0, unpack(targets))
	eq(select(3, m.counts()), 0)
	m.driver:tick(0.016)
	local calls, guids, posts = m.counts()
	eq(calls, 80); eq(posts, 40)
	-- One registry pass plus two GUID reads per updated frame, not targets x frames.
	eq(guids, 120); eq(m.driver:IsShown(), false)
end)

test('health and absorb geometry reuse raw healing without caching clipped amounts', function()
	local m = healModule(); local f = m.add('raid1')
	m.element.path(f, 'ForceUpdate', f.unit)
	eq(select(1, m.counts()), 2)
	m.element.path(f, 'UNIT_HEALTH', f.unit)
	m.element.path(f, 'UNIT_ABSORB_AMOUNT_CHANGED', f.unit)
	eq(select(1, m.counts()), 2)
	m.time(0.11); m.element.path(f, 'UNIT_HEALTH', f.unit)
	eq(select(1, m.counts()), 4)
	m.guid(f.unit, 'replacement'); m.element.path(f, 'UNIT_HEALTH', f.unit)
	eq(select(1, m.counts()), 6)
	f.HealCommTimeframe = 1
	m.element.path(f, 'UNIT_HEALTH', f.unit); m.element.path(f, 'UNIT_HEALTH', f.unit)
	eq(select(1, m.counts()), 10)
end)

test('geometry cache stores unclipped and unmodified heal amounts', function()
	local m = healModule(); local f = m.add('raid1')
	f.HealCommBar.maxOverflow = 1
	m.health(195); m.element.path(f, 'ForceUpdate', f.unit)
	eq(m.values.myHeal, 5); eq(m.values.otherHeal, 0)
	m.health(50); m.element.path(f, 'UNIT_HEALTH', f.unit)
	eq(m.values.myHeal, 20); eq(m.values.otherHeal, 40)
	m.modifier(0.5); m.element.path(f, 'UNIT_ABSORB_AMOUNT_CHANGED', f.unit)
	eq(m.values.myHeal, 10); eq(m.values.otherHeal, 20)
	eq(select(1, m.counts()), 2)
end)

test('same-GUID frames all update and callbacks queued during a flush survive', function()
	local m = healModule(); local a, b, alias = m.add('raid1'), m.add('raid2'), m.add('target')
	m.guid('target', 'raid1')
	local oldPost = a.HealCommBar.PostUpdate
	local queued = false
	a.HealCommBar.PostUpdate = function(...)
		oldPost(...)
		if not queued then
			queued = true
			m.callbacks.HealComm_ModifierChanged('HealComm_ModifierChanged', 'raid2')
		end
	end
	m.callbacks.HealComm_ModifierChanged('HealComm_ModifierChanged', 'raid1')
	m.driver:tick(0.016); eq(select(3, m.counts()), 2); eq(m.driver:IsShown(), true)
	m.driver:tick(0.016); eq(select(3, m.counts()), 3); eq(m.driver:IsShown(), false)
	eq(alias.HealCommBar.healCacheValid, true); eq(b.HealCommBar.healCacheValid, true)
end)

test('queued changes invalidate geometry cache; hidden, rebound and disabled frames are safe', function()
	local m = healModule(); local a, b = m.add('raid1'), m.add('raid2')
	m.element.path(a, 'ForceUpdate', a.unit); m.reset()
	m.callbacks.HealComm_ModifierChanged('HealComm_ModifierChanged', 'raid1')
	m.element.path(a, 'UNIT_HEALTH', a.unit)
	eq(select(1, m.counts()), 2)
	m.guid(a.unit, 'new-guid'); b:Hide()
	m.driver:tick(0.016)
	eq(select(3, m.counts()), 1)
	m.callbacks.HealComm_ModifierChanged('HealComm_ModifierChanged', 'new-guid')
	m.element.disable(a); m.element.disable(b)
	eq(m.driver:IsShown(), false)
	eq(next(m.callbacks), nil)
end)

local function auraModule()
	local np, driver = {}, nil
	local now, timeCalls, enabled, textUpdates = 0, 0, false, 0
	local e = {Libs = {}, DebuffColors = {none = {r = 1, g = 1, b = 1}},
		GetModule = function() return np end,
		Cooldown_TimerEnabled = function() return enabled end,
		Cooldown_OnUpdate = function(icon, elapsed)
			if icon.nextUpdate > 0 then icon.nextUpdate = icon.nextUpdate - elapsed; return end
			textUpdates = textUpdates + 1; icon.nextUpdate = 0.1
		end}
	local stopTimer, startTimer, renderIcon = run(read(auraPath)..'\nreturn StopAuraTimer, StartAuraTimer, RenderAuraIcon', {ElvUI = {e}, GetSpellInfo = function(id) return tostring(id) end,
		GetTime = function() timeCalls = timeCalls + 1; return now end,
		CreateFrame = function() driver = frame(); return driver end})
	local function icon()
		local button = frame(); button.valueCalls, button.textCalls = 0, 0
		button.text = {SetText = function() button.textCalls = button.textCalls + 1 end}
		function button:SetValue() self.valueCalls = self.valueCalls + 1 end
		function button:SetMinMaxValues() end
		function button:SetID() end
		-- Exercise the same lifecycle hooks installed by Construct_AuraIcon.
		local hooks = section(auraPath, '\tbutton:HookScript("OnHide", StopAuraTimer)', '\n\tbutton.bg =')
		run('return function(button)\n'..hooks..'\nend', {StopAuraTimer = stopTimer, StartAuraTimer = startTimer})(button)
		return button
	end
	return {np = np, driver = driver, icon = icon, renderIcon = renderIcon,
		style = function(button, duration, expiry) np:StyleAura(button, 1, nil, 1, nil, duration, expiry, false, 1, 'Aura') end,
		time = function(value) now = value end, enabled = function(value) enabled = value end,
		resetTimeCalls = function() timeCalls = 0 end,
		counts = function() return timeCalls, textUpdates end}
end

test('aura scheduler shares time reads and clears disabled text once', function()
	local m = auraModule(); local icons = {}
	for i = 1, 240 do icons[i] = m.icon(); m.style(icons[i], 100, 100) end
	m.resetTimeCalls()
	for i = 1, 60 do m.time(i / 60); m.driver:tick(1 / 60) end
	eq(select(1, m.counts()), 60)
	for _, icon in ipairs(icons) do eq(icon.textCalls, 1); eq(icon.valueCalls, 61) end
	m.enabled(true); m.driver:tick(0.016)
	eq(select(2, m.counts()), 240)
	m.driver:tick(0.016); eq(select(2, m.counts()), 240)
	m.enabled(false); m.driver:tick(0.016)
	for _, icon in ipairs(icons) do eq(icon.textCalls, 2); icon:Hide() end
	eq(m.driver:IsShown(), false)
end)

test('aura timers stop on hide/expiry/no-duration and resume on show', function()
	local m = auraModule(); local icon = m.icon(); m.style(icon, 10, 10)
	icon:Hide(); eq(m.driver:IsShown(), false)
	icon:Show(); eq(m.driver:IsShown(), true)
	m.time(11); m.driver:tick(0.016)
	eq(icon:IsShown(), false); eq(m.driver:IsShown(), false)
	m.time(0); m.style(icon, 10, 10); m.style(icon, 0, 0)
	eq(m.driver:IsShown(), false)
	m.renderIcon({icon}, 1, 1, nil, 1, nil, 10, 10, false, 1, 'Preview', true)
	icon:Hide(); icon:Show(); eq(m.driver:IsShown(), false)
end)

local function bubbles()
	local module, timer, now, scans = {}, nil, 0, 0
	local children, skinned = {}, {}
	local general = {chatBubbles = 'backdrop', chatBubbleName = false}
	local world = {GetChildren = function() scans = scans + 1; return unpack(children) end}
	function module:ScheduleRepeatingTimer(callback) timer = {callback = callback}; return timer end
	function module:CancelTimer(t) t.cancelled = true end
	local e = {private = {general = general}, Libs = {}, GetModule = function() return module end}
	run(read('ElvUI/Core/Modules/Misc/ChatBubbles.lua'), {ElvUI = {e},
		RAID_CLASS_COLORS = {PRIEST = {}}, WorldFrame = world, wipe = wipe,
		CreateFrame = frame, GetTime = function() return now end, min = math.min, max = math.max})
	function module:IsChatBubble(f) return f.bubble end
	function module:SkinBubble(f) f.isSkinnedElvUI = true; skinned[f] = true end
	module:LoadChatBubbles()
	return {module = module, general = general, skinned = skinned,
		children = function(value) children = value end,
		tick = function(value, message)
			now = value
			if message then module.BubbleFrame.scripts.OnEvent(module.BubbleFrame, 'CHAT_MSG_SAY', 'message') end
			if timer and not timer.cancelled then timer.callback() end
		end,
		scans = function() return scans end, timer = function() return timer end}
end

test('chat flood has one throttled scanner; idle scans still detect replaced children', function()
	local m = bubbles()
	for i = 0, 599 do m.tick(i / 60, true) end
	assert(m.scans() <= 101, 'chat flood must not scan every rendered frame')
	eq(m.module.BubbleFrame.scripts.OnUpdate, nil)
	local before = m.scans()
	for i = 1, 600 do m.tick(10 + i / 60) end
	assert(m.scans() - before <= 30, 'idle scan rate must return to 2/sec after the active window')
	m.children({{bubble = false}}); m.tick(21)
	local replacement = {bubble = true}; m.children({replacement}); m.tick(22)
	eq(m.skinned[replacement], true)
	local old = m.timer(); m.module:LoadChatBubbles(); eq(old.cancelled, true)
	m.general.chatBubbles = 'disabled'; local current = m.timer(); m.module:LoadChatBubbles()
	eq(current.cancelled, true)
end)

local function inspect()
	local now, scans, id, shown, guid, link, available, socketPending = 0, 0, 0, true, 'a', 'item:1', false, false
	local timers, hooks, frameHooks = {}, {}, {}
	local button = {hasItem = true, GetID = function() return 1 end, GetName = function() return 'InspectHeadSlot' end,
		backdrop = {SetBackdropBorderColor = function() end}}
	local env = {Slots = {'HeadSlot'}, InspectHeadSlot = button,
		InspectFrame = {unit = 'target', IsShown = function() return shown end,
			HookScript = function(_, event, fn) frameHooks[event] = fn end},
		strsub = string.sub, UnitGUID = function() return guid end,
		GetInventoryItemLink = function() return link end,
		GetItemInfo = function() if available then return nil, nil, 4 end end,
		hooksecurefunc = function(name, fn) hooks[name] = fn end,
		S = {EquipmentSlotAnchors = {}, HandleSirusEquipmentSocketInfo = function() scans = scans + 1; return socketPending end,
			UpdateBlackDiamondHighlight = function() end}}
	env._G = env
	env.E = {media = {bordercolor = {1, 1, 1}}, GetItemQualityColor = function() return 1, 1, 1 end,
		CancelTimer = function(_, handle) timers[handle] = nil end,
		ScheduleTimer = function(_, fn, delay) id = id + 1; timers[id] = {time = now + delay, fn = fn}; return id end}
	env.C_Timer = {NewTicker = function() return {Cancel = function() end} end}
	run(section('ElvUI/Core/Modules/Skins/Blizzard/Inspect.lua', '\tlocal styleButton\n', '\tif InspectModelFrameControlFrameRotateLeftButton'), env)
	return {button = button, hooks = hooks, frameHooks = frameHooks,
		style = function() hooks.InspectPaperDollItemSlotButton_Update(button) end,
		scans = function() return scans end,
		available = function(value) available = value end, socketPending = function(value) socketPending = value end,
		shown = function(value) shown = value end, guid = function(value) guid = value end, link = function(value) link = value end,
		timerCount = function() local n = 0; for _ in pairs(timers) do n = n + 1 end; return n end,
		advance = function()
			local first, value
			for key, t in pairs(timers) do if not value or t.time < value.time then first, value = key, t end end
			if not value then return false end
			now = value.time; timers[first] = nil; value.fn(); return true
		end}
end

test('inspect missing item cache stops after ten retries and external refresh cannot restart it', function()
	local m = inspect(); m.style()
	for _ = 1, 100 do if not m.advance() then break end end
	eq(m.scans(), 11); eq(m.timerCount(), 0)
	m.style(); eq(m.timerCount(), 0)
	m.link('item:2'); m.style(); eq(m.timerCount(), 1)
	m.available(true); m.advance(); eq(m.timerCount(), 0)
end)

test('inspect socket retries are bounded and hide/unit changes cancel stale work', function()
	local m = inspect(); m.available(true); m.socketPending(true); m.style()
	for _ = 1, 100 do if not m.advance() then break end end
	eq(m.scans(), 11); eq(m.timerCount(), 0)
	m.guid('b'); m.style(); eq(m.timerCount(), 1)
	m.shown(false); m.frameHooks.OnHide(); eq(m.timerCount(), 0)
	local before = m.scans(); m.style(); eq(m.scans(), before)
	m.shown(true); m.frameHooks.OnShow(); eq(m.timerCount(), 1)
	m.guid('c'); m.advance(); eq(m.scans(), before + 1); eq(m.timerCount(), 0)
	m.hooks.InspectFrame_UnitChanged(); eq(m.timerCount(), 1)
end)

print(('All %d performance regression tests passed.'):format(total))
