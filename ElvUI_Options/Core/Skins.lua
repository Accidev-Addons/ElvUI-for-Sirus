local E, _, V, P, G = unpack(ElvUI)
local C, L = unpack(E.Config)
local BL = E:GetModule('Blizzard')
local ACH = E.Libs.ACH

local pairs = pairs
local format = format

local toggles = {
	achievement = L["ACHIEVEMENTS"],
	auctionhouse = L["AUCTIONS"],
	bags = L["Bags"],
	bgmap = L["BG Map"],
	bgscore = L["BG Score"],
	binding = L["KEY_BINDINGS"],
	blizzardOptions = L["INTERFACE_OPTIONS"],
	character = L["Character Frame"],
	chooseitem = L["Choose Item"],
	debug = L["Debug Tools"],
	dressingroom = L["DRESSUP_FRAME"],
	friends = format('%s & %s', L["Friends"], L["Guild"]),
	gossip = L["Gossip Frame"],
	guild = L["Guild"],
	guildregistrar = L["Guild Registrar"],
	help = L["Help Frame"],
	inspect = L["Inspect"],
	itembrowser = L["Item Browser"],
	loot = L["Loot Frame"],
	macro = L["MACROS"],
	mail = L["Mail Frame"],
	merchant = L["Merchant Frame"],
	mirrorTimers = L["Mirror Timers"],
	misc = L["Misc Frames"],
	petition = L["Petition Frame"],
	quest = L["Quest Frames"],
	raid = L["Raid Frame"],
	socket = L["Socket Frame"],
	spellbook = L["SPELLBOOK"],
	stable = L["Stable"],
	store = L["Store"],
	tabard = L["Tabard Frame"],
	talent = L["TALENTS"],
	taxi = L["FLIGHT_MAP"],
	timemanager = L["TIMEMANAGER_TITLE"],
	toast = L["Toasts"],
	tooltip = L["Tooltip"],
	trade = L["TRADE"],
	tradeskill = L["TRADESKILLS"],
	trainer = L["Trainer Frame"],
	tutorial = L["Tutorials"],
	worldState = L["World State"],
	worldmap = L["WORLD_MAP"],
	arena = L["Arena"],
	arenaregistrar = L["Arena Registrar"],
	alertframes = L["Alert Frames"],
	barber = BARBERSHOP,
	battlePass = L["Battle Pass"],
	calendar = L["Calendar"],
	collections = L["Collections"],
	customizations = L["Customizations"],
	dummycontrol = L["Dummy Control"],
	encounterjournal = L["Encounter Journal"],
	gbank = GUILD_BANK,
	gmchat = GM_CHAT,
	hardcore = L["Hardcore"],
	headhunting = L["Headhunting"],
	lfd = LOOKING_FOR_DUNGEON,
	lfr = L["Raid Finder"],
	legacyCollection = L["Legacy Collection"],
	lootCasePreview = L["Loot Case Preview"],
	pvp = L["PvP"],
	roulette = L["Roulette"],
	toyCollection = L["Toy Collection"],
	wardrobe = L["Wardrobe"],
}

local function ToggleSkins(value)
	E.ShowPopup = true
	E.private.skins.blizzard.enable = value

	for key in pairs(E.private.skins.blizzard) do
		if key ~= 'enable' then
			E.private.skins.blizzard[key] = value
		end
	end
end

local Skins = ACH:Group(L["Skins"], nil, 2, 'tab')
E.Options.args.skins = Skins

Skins.args.intro = ACH:Description(L["SKINS_DESC"], 0)
Skins.args.general = ACH:MultiSelect(L["General"], nil, 1, nil, nil, nil, function(_, key) if key == 'blizzardEnable' then return E.private.skins.blizzard.enable else return E.private.skins[key] end end, function(_, key, value) if key == 'blizzardEnable' then E.private.skins.blizzard.enable = value else E.private.skins[key] = value end E.ShowPopup = true end)
Skins.args.general.values = { blizzardEnable = L["Blizzard"], ace3Enable = 'Ace3', libDropdown = L["Library Dropdown"], checkBoxSkin = L["CheckBox Skin"], parchmentRemoverEnable = L["Parchment Remover"] }
Skins.args.general.sortByValue = true
Skins.args.general.customWidth = 140

Skins.args.disableBlizzardSkins = ACH:Execute(L["Disable Blizzard Skins"], nil, 2, function() ToggleSkins(false) end)
Skins.args.enableBlizzardSkins = ACH:Execute(L["Enable Blizzard Skins"], nil, 3, function() ToggleSkins(true) end)

Skins.args.blizzard = ACH:MultiSelect(L["Blizzard"], L["TOGGLESKIN_DESC"], -1, nil, nil, nil, function(_, key) return E.private.skins.blizzard[key] end, function(_, key, value) E.private.skins.blizzard[key] = value; E.ShowPopup = true end)
Skins.args.blizzard.sortByValue = true
Skins.args.blizzard.values = toggles
