local E = unpack(ElvUI)

E:AddLib('AceGUI', 'AceGUI-3.0')
E:AddLib('AceConfig', 'AceConfig-3.0-ElvUI')
E:AddLib('AceConfigDialog', 'AceConfigDialog-3.0-ElvUI')
E:AddLib('AceConfigRegistry', 'AceConfigRegistry-3.0-ElvUI')
E:AddLib('AceDBOptions', 'AceDBOptions-3.0')

local optionsMajors = {
	'AceGUI-3.0',
	'AceGUI-3.0-DropDown-ItemBase',
	'AceGUISharedMediaWidgets-1.0',
	'AceConfig-3.0-ElvUI',
	'AceConfigDialog-3.0-ElvUI',
	'AceConfigRegistry-3.0-ElvUI',
	'AceDBOptions-3.0',
}

local protected = LibStub and LibStub.ElvUIProtected
if protected then
	for _, major in ipairs(optionsMajors) do
		if LibStub.libs[major] then
			protected[major] = true
		end
	end
end
