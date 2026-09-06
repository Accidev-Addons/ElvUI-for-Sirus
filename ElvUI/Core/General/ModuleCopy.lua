local E, L, V, P, G = unpack(ElvUI)
local MC = E:GetModule('ModuleCopy')

local pairs, next, type = pairs, next, type
local format, error = format, error
-- GLOBALS: ElvDB

--This table to reserve settings names in E.global.profileCopy. Used in export/imports functions
--Plugins can add own values for their internal settings for safechecks here
MC.InternalOptions = {
	selected = true,
	movers = true,
}

local ToggleSkins -- so it can call itself
ToggleSkins = function(tbl, key, value)
	if key ~= 'selected' then
		local setting = tbl[key]
		if type(setting) == 'table' then
			for subkey in pairs(setting) do
				ToggleSkins(setting, subkey, value)
			end
		else
			tbl[key] = value
		end
	end
end

local function DefaultOptions(tbl, section, pluginSection)
	if pluginSection then
		if not tbl[pluginSection] then
			tbl[pluginSection] = {}
		end
		if not tbl[pluginSection][section] then
			tbl[pluginSection][section] = {}
		end
	elseif not tbl[section] then
		tbl[section] = {}
	end
end

local function DefaultMovers(tbl, section, subSection)
	if not tbl[section] then
		tbl[section] = {}
	end

	if subSection and tbl[section][subSection] == nil then
		tbl[section][subSection] = false
	end
end

--Default template for a config group for a single module.
--Contains header, general group toggle (shown only if the setting actually exists) and imports button.
--Usage as seen in ElvUI_Options\modulecopy.lua
function MC:CreateModuleConfigGroup(Name, section, pluginSection)
	local config = {
		order = 10,
		type = 'group',
		name = Name,
		args = {
			general = {
				order = 1,
				type = 'toggle',
				name = function()
					E.Options.args.profiles.args.modulecopy.args.import.func = function()
						E.PopupDialogs.MODULE_COPY_CONFIRM.text = format(L["You are going to copy settings for |cffD3CF00\"%s\"|r from |cff4beb2c\"%s\"|r profile to your current |cff4beb2c\"%s\"|r profile. Are you sure?"], Name, E.global.profileCopy.selected, ElvDB.profileKeys[E.mynameRealm])
						E.PopupDialogs.MODULE_COPY_CONFIRM.OnAccept = function()
							MC:ImportFromProfile(section, pluginSection)
						end
						E:StaticPopup_Show('MODULE_COPY_CONFIRM')
					end

					E.Options.args.profiles.args.modulecopy.args.export.func = function()
						E.PopupDialogs.MODULE_COPY_CONFIRM.text = format(L["You are going to copy settings for |cffD3CF00\"%s\"|r from your current |cff4beb2c\"%s\"|r profile to |cff4beb2c\"%s\"|r profile. Are you sure?"], Name, ElvDB.profileKeys[E.mynameRealm], E.global.profileCopy.selected)
						E.PopupDialogs.MODULE_COPY_CONFIRM.OnAccept = function()
							MC:ExportToProfile(section, pluginSection)
						end
						E:StaticPopup_Show('MODULE_COPY_CONFIRM')
					end

					local selection = (pluginSection and E.global.profileCopy[pluginSection]) or E.global.profileCopy
					E.Options.args.profiles.args.modulecopy.args.clear.func = function() ToggleSkins(selection, section, false) end
					E.Options.args.profiles.args.modulecopy.args.select.func = function() ToggleSkins(selection, section, true) end

					return L["General"]
				end,
			},
		},
	}

	DefaultOptions(G.profileCopy, section, pluginSection) -- defaults
	DefaultOptions(E.global.profileCopy, section, pluginSection) -- from profile

	if pluginSection then
		config.args.general.hidden = function(info) return E.global.profileCopy[pluginSection][section][ info[#info] ] == nil end
		config.get = function(info) return E.global.profileCopy[pluginSection][section][ info[#info] ] end
		config.set = function(info, value) E.global.profileCopy[pluginSection][section][ info[#info] ] = value end
	else
		config.args.general.hidden = function(info) return E.global.profileCopy[section][ info[#info] ] == nil end
		config.get = function(info) return E.global.profileCopy[section][ info[#info] ] end
		config.set = function(info, value) E.global.profileCopy[section][ info[#info] ] = value end
	end

	return config
end

function MC:CreateMoversConfigGroup()
	local config = {
		header = E.Libs.ACH:Header(function()
			E.Options.args.profiles.args.modulecopy.args.import.func = function()
				E.PopupDialogs.MODULE_COPY_CONFIRM.text = format(L["You are going to copy settings for |cffD3CF00\"%s\"|r from |cff4beb2c\"%s\"|r profile to your current |cff4beb2c\"%s\"|r profile. Are you sure?"], L["Movers"], E.global.profileCopy.selected, ElvDB.profileKeys[E.mynameRealm])
				E.PopupDialogs.MODULE_COPY_CONFIRM.OnAccept = function()
					MC:CopyMovers('import')
				end
				E:StaticPopup_Show('MODULE_COPY_CONFIRM')
			end

			E.Options.args.profiles.args.modulecopy.args.export.func = function()
				E.PopupDialogs.MODULE_COPY_CONFIRM.text = format(L["You are going to copy settings for |cffD3CF00\"%s\"|r from your current |cff4beb2c\"%s\"|r profile to |cff4beb2c\"%s\"|r profile. Are you sure?"], L["Movers"], ElvDB.profileKeys[E.mynameRealm], E.global.profileCopy.selected)
				E.PopupDialogs.MODULE_COPY_CONFIRM.OnAccept = function()
					MC:CopyMovers('export')
				end
				E:StaticPopup_Show('MODULE_COPY_CONFIRM')
			end

			E.Options.args.profiles.args.modulecopy.args.clear.func = function() ToggleSkins(E.global.profileCopy, 'movers', false) end
			E.Options.args.profiles.args.modulecopy.args.select.func = function() ToggleSkins(E.global.profileCopy, 'movers', true) end

			return L["On screen positions for different elements."]
		end, 0)
	}

	DefaultMovers(G.profileCopy, 'movers')
	DefaultMovers(E.global.profileCopy, 'movers')

	for moverName, data in pairs(E.CreatedMovers) do
		DefaultMovers(G.profileCopy, 'movers', moverName)
		DefaultMovers(E.global.profileCopy, 'movers', moverName)

		config[moverName] = {
			order = 1,
			type = 'toggle',
			name = data.mover.textString,
			get = function() return E.global.profileCopy.movers[moverName] end,
			set = function(_, value) E.global.profileCopy.movers[moverName] = value end
		}
	end

	for moverName, data in pairs(E.DisabledMovers) do
		DefaultMovers(G.profileCopy, 'movers', moverName)
		DefaultMovers(E.global.profileCopy, 'movers', moverName)

		config[moverName] = {
			order = 1,
			type = 'toggle',
			name = data.mover.textString,
			get = function() return E.global.profileCopy.movers[moverName] end,
			set = function(_, value) E.global.profileCopy.movers[moverName] = value end
		}
	end
	return config
end

local function CopyDetached(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = type(value) == 'table' and CopyDetached(value) or value
	end
	local meta = getmetatable(source)
	if type(meta) == 'table' then setmetatable(copy, meta) end
	return copy
end

function MC:CopyTable(CopyFrom, CopyTo, CopyDefault, module)
	if not (CopyFrom and CopyTo and CopyDefault) or CopyFrom == CopyTo then return end

	if module == true then
		-- Detach aliases left by older copies before merging into the destination.
		local copy = CopyDetached(CopyTo)
		E:CopyTable(copy, CopyDefault)
		E:CopyTable(copy, CopyFrom)
		for key, value in pairs(copy) do CopyTo[key] = value end
		return
	elseif type(module) ~= 'table' then
		return
	end

	-- [SIRUS] Defaults and the selection template also cover empty destinations.
	if module.general == nil or (not CopyDefault.general and module.general) then
		for key, value in pairs(CopyTo) do
			if type(value) ~= 'table' and CopyDefault[key] == nil then
				CopyTo[key] = nil
			end
		end
		for key, value in pairs(CopyDefault) do
			if type(value) ~= 'table' then
				local newValue = CopyFrom[key]
				if newValue == nil then newValue = value end
				CopyTo[key] = type(newValue) == 'table' and E:CopyTable({}, newValue) or newValue
			end
		end
	end

	for key, selected in pairs(module) do
		if selected and type(CopyDefault[key]) == 'table' then
			local source, destination = MC:TablesExist(CopyFrom[key], CopyTo[key], CopyDefault[key])
			CopyTo[key] = destination
			MC:CopyTable(source, destination, CopyDefault[key], selected)
		end
	end
end

--[[
	* Valid copy templates should be as follows:
		E.global.profileCopy[YourOptionGroupName] = {
			[SubGroupName1] = true,
			[SubGroupName2] = true,
			...
		}
	* For example:
		E.global.profileCopy.auras = {
			general = true,
			buffs = true,
			debuffs = true,
			cooldown = true,
		}
	* 'general' key can refer to a similar named subtable or all non-table variables inside your group
	* If you leave the table as E.global.profileCopy[YourOptionGroupName] = {}, this will result in no valid copy template error.
	* If set to E.global.profileCopy[YourOptionGroupName] = true, then this will copy everything without selecting any particular subcategory from your settings table.
	* Plugins can use 'pluginSection' argument to determain their own table if they keep settings apart from core ElvUI settings.
	-- Examples S&L uses 'sle' table, MerathilisUI uses 'mui' table, BenikUI uses 'benikui' and core table
]]

function MC:TablesExist(CopyFrom, CopyTo, CopyDefault)
	if not CopyFrom and CopyDefault then CopyFrom = E:CopyTable({}, CopyDefault) end
	if CopyDefault and (not CopyTo or CopyTo == CopyDefault) then CopyTo = E:CopyTable({}, CopyDefault) end
	return CopyFrom, CopyTo
end

function MC:ImportFromProfile(section, pluginSection)
	--Some checks for the occasion someone passes wrong stuff
	if not section then error('No profile section provided. Usage MC:ImportFromProfile("section")') end
	if not pluginSection and MC.InternalOptions[section] then error(format('Section name could not be "%s". This name is reserved for internal setting', section)) end
	if pluginSection and (MC.InternalOptions[pluginSection] and MC.InternalOptions[pluginSection][section]) then error(format('Section name for plugin group "%s" could not be "%s". This name is reserved for internal setting', pluginSection, section)) end

	local module = pluginSection and E.global.profileCopy[pluginSection][section] or E.global.profileCopy[section]
	if not module then error(format('Provided section name "%s" does not have a template for profile copy.', section)) end
	--Starting digging through the settings
	local selected = ElvDB.profiles[E.global.profileCopy.selected]
	local CopyFrom = pluginSection and ((selected and selected[pluginSection] and selected[pluginSection][section]) or P[pluginSection][section]) or (selected and selected[section])
	local CopyTo = pluginSection and (E.db[pluginSection] and E.db[pluginSection][section]) or (not pluginSection and E.db[section])
	local CopyDefault = pluginSection and P[pluginSection][section] or P[section]
	--Making sure tables actually exist in profiles (e.g absent values in ElvDB.profiles are for default values)
	CopyFrom, CopyTo = MC:TablesExist(CopyFrom, CopyTo, CopyDefault)
	if type(module) == 'table' and next(module) then --This module is not an empty table
		MC:CopyTable(CopyFrom, CopyTo, CopyDefault, module)
	elseif type(module) == 'boolean' then --Copy over entire section of profile subgroup
		MC:CopyTable(CopyFrom, CopyTo, CopyDefault, module)
	else
		error(format('Provided section name "%s" does not have a valid copy template.', section))
	end
	if pluginSection then
		E.db[pluginSection] = E.db[pluginSection] or {}
		E.db[pluginSection][section] = CopyTo
	else
		E.db[section] = CopyTo
	end
	E:StaggeredUpdateAll()
end

function MC:ExportToProfile(section, pluginSection)
	--Some checks for the occasion someone passes wrong stuff
	if not section then error('No profile section provided. Usage MC:ExportToProfile("section")') end
	if not pluginSection and MC.InternalOptions[section] then error(format('Section name could not be "%s". This name is reserved for internal setting', section)) end
	if pluginSection and (MC.InternalOptions[pluginSection] and MC.InternalOptions[pluginSection][section]) then error(format('Section name for plugin group "%s" could not be "%s". This name is reserved for internal setting', pluginSection, section)) end

	local module = pluginSection and E.global.profileCopy[pluginSection][section] or E.global.profileCopy[section]
	if not module then error(format('Provided section name "%s" does not have a template for profile copy.', section)) end
	--Making sure tables actually exist
	if not ElvDB.profiles[E.global.profileCopy.selected] then ElvDB.profiles[E.global.profileCopy.selected] = {} end -- profile not created yet
	if not pluginSection and not ElvDB.profiles[E.global.profileCopy.selected][section] then ElvDB.profiles[E.global.profileCopy.selected][section] = {} end
	if pluginSection then
		if not ElvDB.profiles[E.global.profileCopy.selected][pluginSection] then ElvDB.profiles[E.global.profileCopy.selected][pluginSection] = {} end
		if not ElvDB.profiles[E.global.profileCopy.selected][pluginSection][section] then ElvDB.profiles[E.global.profileCopy.selected][pluginSection][section] = {} end
	end
	--Starting digging through the settings
	local CopyFrom = pluginSection and (E.db[pluginSection] and E.db[pluginSection][section]) or (not pluginSection and E.db[section])
	local CopyTo = pluginSection and ElvDB.profiles[E.global.profileCopy.selected][pluginSection][section] or ElvDB.profiles[E.global.profileCopy.selected][section]
	local CopyDefault = pluginSection and P[pluginSection][section] or P[section]
	CopyFrom, CopyTo = MC:TablesExist(CopyFrom, CopyTo, CopyDefault)
	if type(module) == 'table' and next(module) then --This module is not an empty table
		MC:CopyTable(CopyFrom, CopyTo, CopyDefault, module)
	elseif type(module) == 'boolean' then --Copy over entire section of profile subgroup
		MC:CopyTable(CopyFrom, CopyTo, CopyDefault, module)
	else
		error(format('Provided section name "%s" does not have a valid copy template.', section))
	end
	local selected = ElvDB.profiles[E.global.profileCopy.selected]
	if pluginSection then
		selected[pluginSection][section] = CopyTo
	else
		selected[section] = CopyTo
	end
end

function MC:CopyMovers(mode)
	if not E.db.movers then E.db.movers = {} end --Nothing was moved in cutrrent profile
	if not ElvDB.profiles[E.global.profileCopy.selected] then ElvDB.profiles[E.global.profileCopy.selected] = {} end -- profile not created yet
	if not ElvDB.profiles[E.global.profileCopy.selected].movers then ElvDB.profiles[E.global.profileCopy.selected].movers = {} end --Nothing was moved in selected profile
	local CopyFrom, CopyTo
	if mode == 'export' then
		CopyFrom, CopyTo = E.db.movers, ElvDB.profiles[E.global.profileCopy.selected].movers
	else
		CopyFrom, CopyTo = ElvDB.profiles[E.global.profileCopy.selected].movers or {}, E.db.movers
	end

	for moverName in pairs(E.CreatedMovers) do
		if E.global.profileCopy.movers[moverName] then
			CopyTo[moverName] = CopyFrom[moverName]
		end
	end
	E:SetMoversPositions()
end

function MC:Initialize()
	MC.Initialized = true
end

E:RegisterModule(MC:GetName())
