--[[
LibDualSpec-1.0 - Adds dual spec support to individual AceDB-3.0 databases
Copyright (C) 2009-2024 Adirelle

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Redistribution of a stand alone version is strictly prohibited without
      prior written authorization from the LibDualSpec project manager.
    * Neither the name of the LibDualSpec authors nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

local MAJOR, MINOR = "LibDualSpec-1.0", 25
assert(LibStub, MAJOR.." requires LibStub")
local lib, minor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.eventFrame = lib.eventFrame or CreateFrame("Frame")

lib.registry = lib.registry or {}
lib.options = lib.options or {}
lib.mixin = lib.mixin or {}
lib.upgrades = lib.upgrades or {}
lib.currentSpec = tonumber(lib.currentSpec) or 0

if minor and minor < 25 then
	lib.talentsLoaded, lib.talentGroup = nil, nil
	lib.specLoaded, lib.specGroup = nil, nil
	lib.eventFrame:UnregisterAllEvents()
	wipe(lib.options)
end

local registry = lib.registry
local options = lib.options
local mixin = lib.mixin
local upgrades = lib.upgrades

local AceDB3 = LibStub('AceDB-3.0', true)
local AceDBOptions3 = LibStub('AceDBOptions-3.0', true)
local AceConfigRegistry3 = LibStub('AceConfigRegistry-3.0', true) or LibStub('AceConfigRegistry-3.0-ElvUI', true)

local pcall, type, format = pcall, type, format
local C_Talent = _G.C_Talent
local GetActiveTalentGroup = _G.GetActiveTalentGroup
local GetNumTalentGroups = _G.GetNumTalentGroups
local GREEN_FONT_COLOR = _G.GREEN_FONT_COLOR

local MAX_SPECS = 10

local function GetNumSpecs()
	local num

	if C_Talent and C_Talent.GetNumTalentGroups then
		num = C_Talent.GetNumTalentGroups()
	elseif GetNumTalentGroups then
		num = GetNumTalentGroups()
	end

	if not num or num < 1 then num = 1 end
	if num > MAX_SPECS then num = MAX_SPECS end

	return num
end

local function GetCurrentSpec()
	if C_Talent and C_Talent.GetActiveTalentGroup then
		if C_Talent.IsSpecInfoLoaded and not C_Talent.IsSpecInfoLoaded() then
			return 0
		end

		return C_Talent.GetActiveTalentGroup() or 0
	end

	return (GetActiveTalentGroup and GetActiveTalentGroup()) or 0
end

local L_ENABLED = "Enable spec profiles"
local L_ENABLED_DESC = "When enabled, your profile will be set to the specified profile when you change talent set."
local L_CURRENT = "%s - Active"
local L_SPEC = "Talent set %d"

do
	local locale = GetLocale()
	if locale == "deDE" then
		L_ENABLED = "Spezialisierungsprofile aktivieren"
		L_ENABLED_DESC = "Falls diese Option aktiviert ist, wird dein Profil auf das angegebene Profil gesetzt, wenn du die Spezialisierung wechselst."
		L_CURRENT = "%s - Aktiv"
	elseif locale == "esES" or locale == "esMX" then
		L_ENABLED = "Activar perfiles de especialización"
		L_ENABLED_DESC = "Cuando está habilitado, su perfil se establecerá en el perfil especificado cuando cambie de especialización."
		L_CURRENT = "%s - Activo"
	elseif locale == "frFR" then
		L_ENABLED = "Activer les profils de spécialisation"
		L_ENABLED_DESC = "Lorsque cette option est activée, votre profil sera défini sur le profil spécifié lorsque vous changerez de spécialisation."
		L_CURRENT = "%s - Actifs"
	elseif locale == "itIT" then
		L_ENABLED = "Abilita i profili per la specializzazione"
		L_ENABLED_DESC = "Quando abilitato, il tuo profilo verrà impostato in base alla specializzazione usata."
		L_CURRENT = "%s - Attivi"
	elseif locale == "koKR" then
		L_ENABLED = "전문화 프로필 활성화"
		L_ENABLED_DESC = "활성화하면 전문화를 변경할 때 프로필이 지정된 프로필로 설정됩니다."
		L_CURRENT = "%s - 활성화"
	elseif locale == "ptBR" then
		L_ENABLED = "Ativar perfis de especialização"
		L_ENABLED_DESC = "Quando ativado, seu perfil será definido para o perfil especificado quando você alterar a especialização."
		L_CURRENT = "%s – ativo"
	elseif locale == "ruRU" then
		L_ENABLED = "Включить профили раскладки талантов"
		L_ENABLED_DESC = "Если включено, ваш профиль будет зависеть от выбранного набора талантов."
		L_CURRENT = "%s - активен"
		L_SPEC = "Набор талантов %d"
	elseif locale == "zhCN" then
		L_ENABLED = "启用专精配置文件"
		L_ENABLED_DESC = "当启用后，当切换专精时配置文件将设置为专精配置文件。"
		L_CURRENT = "%s - 开启"
	elseif locale == "zhTW" then
		L_ENABLED = "啟用專精設定檔"
		L_ENABLED_DESC = "當啟用後，當你切換專精時設定檔會設定為專精設定檔。"
		L_CURRENT = "%s - 啟動"
	end
end

local function GetSpecName(index)
	local getter = C_Talent and (C_Talent.GetTalentGroupSettings or C_Talent.GetTalentGroupNote)
	if getter then
		local ok, groupName = pcall(getter, index)
		if ok and type(groupName) == "string" and groupName ~= "" then
			return groupName
		end
	end

	return format(L_SPEC, index)
end

local points = {}
local function GetSpecPoints(index)
	local tab1, tab2, tab3 = 0, 0, 0

	if C_Talent and C_Talent.GetTalentGroupPointSpent then
		local ok, a, b, c = pcall(C_Talent.GetTalentGroupPointSpent, index)
		if ok then
			tab1, tab2, tab3 = a or 0, b or 0, c or 0
		end
	end

	points[1], points[2], points[3] = tab1, tab2, tab3

	local highPointsSpentIndex
	for treeIndex = 1, 3 do
		if points[treeIndex] > 0 and (not highPointsSpentIndex or points[treeIndex] > points[highPointsSpentIndex]) then
			highPointsSpentIndex = treeIndex
		end
	end

	if highPointsSpentIndex and GREEN_FONT_COLOR then
		points[highPointsSpentIndex] = GREEN_FONT_COLOR:WrapTextInColorCode(points[highPointsSpentIndex])
	end

	return format("|cffffffff%s / %s / %s|r", points[1], points[2], points[3])
end

function mixin:IsDualSpecEnabled()
	return lib.currentSpec > 0 and registry[self].db.char.enabled
end

function mixin:SetDualSpecEnabled(enabled)
	local db = registry[self].db.char
	db.enabled = not not enabled

	if enabled then
		local currentProfile = self:GetCurrentProfile()
		for i = 1, GetNumSpecs() do
			db[i] = db[i] or currentProfile
		end
	else
		for i = 1, MAX_SPECS do
			db[i] = nil
		end
	end

	self:CheckDualSpecState()
end

function mixin:GetDualSpecProfile(spec)
	return registry[self].db.char[spec or lib.currentSpec] or self:GetCurrentProfile()
end

function mixin:SetDualSpecProfile(profileName, spec)
	spec = spec or lib.currentSpec
	if spec < 1 or spec > GetNumSpecs() then return end

	registry[self].db.char[spec] = profileName
	self:CheckDualSpecState()
end

function mixin:CheckDualSpecState()
	if not registry[self].db.char.enabled then return end
	if lib.currentSpec == 0 then return end

	local profileName = self:GetDualSpecProfile()
	if profileName ~= self:GetCurrentProfile() then
		self:SetProfile(profileName)
	end
end

local function EmbedMixin(target)
	for k,v in next, mixin do
		rawset(target, k, v)
	end
end

local function UpgradeDatabase(target)
	if lib.currentSpec == 0 then
		upgrades[target] = true
		return
	end

	local db = target:GetNamespace(MAJOR, true)
	if db and db.char.profile then
		for i = 1, GetNumSpecs() do
			if i == lib.currentSpec then
				db.char[i] = target:GetCurrentProfile()
			else
				db.char[i] = db.char.profile
			end
		end
		db.char.profile = nil
		db.char.specGroup = nil
	end
end

function lib:OnProfileDeleted(event, target, profileName)
	local db = registry[target].db.char
	if not db.enabled then return end

	for i = 1, MAX_SPECS do
		if db[i] == profileName then
			db[i] = target:GetCurrentProfile()
		end
	end
end

function lib:_EnhanceDatabase(event, target)
	registry[target].db = target:GetNamespace(MAJOR, true) or target:RegisterNamespace(MAJOR)
	EmbedMixin(target)
	target:CheckDualSpecState()
end

function lib:EnhanceDatabase(target, name)
	AceDB3 = AceDB3 or LibStub('AceDB-3.0', true)
	if type(target) ~= "table" then
		error("Usage: LibDualSpec:EnhanceDatabase(target, name): target should be a table.", 2)
	elseif type(name) ~= "string" then
		error("Usage: LibDualSpec:EnhanceDatabase(target, name): name should be a string.", 2)
	elseif not AceDB3 or not AceDB3.db_registry[target] then
		error("Usage: LibDualSpec:EnhanceDatabase(target, name): target should be an AceDB-3.0 database.", 2)
	elseif target.parent then
		error("Usage: LibDualSpec:EnhanceDatabase(target, name): cannot enhance a namespace.", 2)
	elseif registry[target] then
		return
	end
	registry[target] = { name = name }
	UpgradeDatabase(target)
	lib:_EnhanceDatabase("EnhanceDatabase", target)
	target.RegisterCallback(lib, "OnDatabaseReset", "_EnhanceDatabase")
	target.RegisterCallback(lib, "OnProfileDeleted")
end

options.new = {
	name = "New",
	type = "input",
	order = 30,
	get = false,
	set = function(info, value)
		local db = info.handler.db
		if db:IsDualSpecEnabled() then
			db:SetDualSpecProfile(value, lib.currentSpec)
		else
			db:SetProfile(value)
		end
	end,
}

options.choose = {
	name = "Existing Profiles",
	type = "select",
	order = 40,
	get = "GetCurrentProfile",
	set = "SetProfile",
	values = "ListProfiles",
	arg = "common",
	disabled = function(info)
		return info.handler.db:IsDualSpecEnabled()
	end
}

options.enabled = {
	type = "toggle",
	name = "|cffffd200"..L_ENABLED.."|r",
	desc = L_ENABLED_DESC,
	descStyle = "inline",
	order = 41,
	width = "full",
	get = function(info) return info.handler.db:IsDualSpecEnabled() end,
	set = function(info, value) info.handler.db:SetDualSpecEnabled(value) end,
	disabled = function() return lib.currentSpec == 0 end,
}

for i = 1, MAX_SPECS do
	local specIndex = i
	options["specProfile" .. specIndex] = {
		type = "select",
		hidden = function()
			return specIndex > GetNumSpecs()
		end,
		name = function()
			local specName = GetSpecName(specIndex)
			return lib.currentSpec == specIndex and format(L_CURRENT, specName) or specName
		end,
		desc = function()
			return GetSpecPoints(specIndex)
		end,
		order = 41 + (specIndex / 100),
		get = function(info)
			return info.handler.db:GetDualSpecProfile(specIndex)
		end,
		set = function(info, value)
			info.handler.db:SetDualSpecProfile(value, specIndex)
		end,
		values = "ListProfiles",
		arg = "common",
		disabled = function(info) return not info.handler.db:IsDualSpecEnabled() end,
	}
end

function lib:EnhanceOptions(optionTable, target)
	AceDBOptions3 = AceDBOptions3 or LibStub('AceDBOptions-3.0', true)
	AceConfigRegistry3 = AceConfigRegistry3 or LibStub('AceConfigRegistry-3.0', true) or LibStub('AceConfigRegistry-3.0-ElvUI', true)
	if type(optionTable) ~= "table" then
		error("Usage: LibDualSpec:EnhanceOptions(optionTable, target): optionTable should be a table.", 2)
	elseif type(target) ~= "table" then
		error("Usage: LibDualSpec:EnhanceOptions(optionTable, target): target should be a table.", 2)
	elseif not AceDBOptions3 or not AceDBOptions3.optionTables[target] then
		error("Usage: LibDualSpec:EnhanceOptions(optionTable, target): optionTable is not an AceDBOptions-3.0 table.", 2)
	elseif optionTable.handler.db ~= target then
		error("Usage: LibDualSpec:EnhanceOptions(optionTable, target): optionTable must be the option table of target.", 2)
	elseif not registry[target] then
		error("Usage: LibDualSpec:EnhanceOptions(optionTable, target): EnhanceDatabase should be called before EnhanceOptions(optionTable, target).", 2)
	end

	options.new.name = optionTable.args.new.name
	options.new.desc = optionTable.args.new.desc
	options.choose.name = optionTable.args.choose.name
	options.choose.desc = optionTable.args.choose.desc

	if not optionTable.plugins then
		optionTable.plugins = {}
	end
	optionTable.plugins[MAJOR] = options
end

for target in next, registry do
	UpgradeDatabase(target)
	EmbedMixin(target)
	target:CheckDualSpecState()
	local optionTable = AceDBOptions3 and AceDBOptions3.optionTables[target]
	if optionTable then
		lib:EnhanceOptions(optionTable, target)
	end
end

do
	local function iterator(t, key)
		local data
		key, data = next(t, key)
		if key then
			return key, data.name
		end
	end

	function lib:IterateDatabases()
		return iterator, lib.registry
	end
end

local function RegisterAnyEvent(frame, event)
	pcall(frame.RegisterEvent, frame, event)

	if frame.RegisterCustomEvent and not frame:IsEventRegistered(event) then
		pcall(frame.RegisterCustomEvent, frame, event)
	end
end

local function eventHandler(self, event)
	local spec = GetCurrentSpec()
	lib.currentSpec = spec

	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent(event)
	end

	if spec > 0 and next(upgrades) then
		for target in next, upgrades do
			UpgradeDatabase(target)
		end
		wipe(upgrades)
	end

	for target in next, registry do
		target:CheckDualSpecState()
	end

	if AceConfigRegistry3 and next(registry) then
		for appName in AceConfigRegistry3:IterateOptionsTables() do
			AceConfigRegistry3:NotifyChange(appName)
		end
	end
end

lib.eventFrame:SetScript("OnEvent", eventHandler)

RegisterAnyEvent(lib.eventFrame, "PLAYER_ENTERING_WORLD")
RegisterAnyEvent(lib.eventFrame, "ACTIVE_TALENT_GROUP_CHANGED")
RegisterAnyEvent(lib.eventFrame, "PLAYER_TALENT_UPDATE_EX")

if IsLoggedIn() then
	eventHandler(lib.eventFrame, "PLAYER_LOGIN")
else
	lib.eventFrame:RegisterEvent("PLAYER_LOGIN")
end

