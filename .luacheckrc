std = "lua51"

globals = {
	"ElvUI",
}

local function addGlobals(file)
	local chunk = loadfile(file)
	if chunk then
		for _, name in ipairs(chunk()) do
			globals[#globals + 1] = name
		end
	end
end

addGlobals("luacheck/globals.lua")
addGlobals("luacheck/curated.lua")

-- No strict line-length policy for this codebase.
max_line_length = false

-- Vendored third-party libraries are not linted.
exclude_files = {
	"ElvUI_Libraries/",
	"ElvUI_Options/Libraries/",
	".luarocks/",
}

ignore = {
	"211",
	"212",
	"213",
	-- Shadowing is endemic in a fork this size and is not actionable here.
	"421",
	"422",
	"423",
	"431",
	"432",
	"433",
	-- Mixed indentation across vendored libraries.
	"621",
}
