--- AceConfig-3.0 wrapper library.
-- Provides an API to register an options table with the config registry.
-- @class file
-- @name AceConfig-3.0
-- @release $Id$

--[[
AceConfig-3.0

Very light wrapper library that combines all the AceConfig subcomponents into one more easily used whole.

]]

local cfgreg = LibStub("AceConfigRegistry-3.0-ElvUI")

local MAJOR, MINOR = "AceConfig-3.0-ElvUI", 4
local AceConfig = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfig then return end

--TODO: local cfgdlg = LibStub("AceConfigDialog-3.0", true)

-- Lua APIs
local pcall, error = pcall, error

-- -------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options, skipValidation)
--
-- - appName - (string) application name
-- - options - table or function ref, see AceConfigRegistry

--- Register a option table with the AceConfig registry.
-- @paramsig appName, options [, skipValidation]
-- @param appName The application name for the config table.
-- @param options The option table (or a function to generate one on demand).  http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- @usage
-- local AceConfig = LibStub("AceConfig-3.0")
function AceConfig:RegisterOptionsTable(appName, options, skipValidation)
	local ok,msg = pcall(cfgreg.RegisterOptionsTable, self, appName, options, skipValidation)
	if not ok then error(msg, 2) end
end
