local E, L, V, P, G = unpack(ElvUI)

--Locked Settings, These settings are stored for your character only regardless of profile options.

V.general = {
	loot = true,
	lootRoll = true,
	normTex = "ElvUI Norm",
	glossTex = "ElvUI Norm",
	dmgfont = "Expressway",
	namefont = "Expressway", -- (PT Sans) some dont render for mail room quest
	chatBubbles = "backdrop",
	chatBubbleFont = "PT Sans Narrow",
	chatBubbleFontSize = 12,
	chatBubbleFontOutline = "NONE",
	chatBubbleName = false,
	replaceBubbleFont = true,
	nameplateFont = "PT Sans Narrow",
	nameplateFontSize = 9,
	nameplateFontOutline = "OUTLINE",
	pixelPerfect = true,
	replaceNameFont = true,
	replaceCombatFont = true,
	replaceCombatText = false,
	replaceNameplateFont = true,
	replaceBlizzFonts = true,
	blizzardFontSize = false,
	noFontScale = false,
	totemTracker = true,
	addonManager = true,
	minimapButtonGrabber = {
		enable = true,
		mouseover = false,
		showNames = true,
		position = 'TOPRIGHT',
		xOffset = -3,
		yOffset = -30,
	},
	classColors = false,
	minimap = {
		enable = true,
		hideCalendar = true,
		hideTracking = false,
	},
	queueStatus = true,
	classColorMentionsSpeech = true,
	raidUtility = true,
}

V.bags = {
	enable = true,
	bagBar = false
}

V.nameplates = {
	enable = true,
}

V.auras = {
	enable = true,
	disableBlizzard = true,
	buffsHeader = true,
	debuffsHeader = true,
	masque = {
		buffs = false,
		debuffs = false,
	}
}

V.chat = {
	enable = true
}

V.skins = {
	ace3Enable = true,
	libDropdown = true,
	checkBoxSkin = true,
	parchmentRemoverEnable = false,
	blizzard = {
		enable = true,
		achievement = true,
		alertframes = true,
		arena = true,
		arenaregistrar = true,
		auctionhouse = true,
		bags = true,
		barber = true,
		battlePass = true,
		bgmap = true,
		bgscore = true,
		binding = true,
		blizzardOptions = true,
		calendar = true,
		character = true,
		chooseitem = true,
		collections = true,
		customizations = true,
		debug = true,
		dressingroom = true,
		dummycontrol = true,
		encounterjournal = true,
		friends = true,
		gbank = true,
		gmchat = true,
		gossip = true,
		guild = true,
		guildregistrar = true,
		hardcore = true,
		headhunting = true,
		help = true,
		inspect = true,
		itembrowser = true,
		lfd = true,
		lfr = true,
		legacyCollection = true,
		loot = true,
		lootCasePreview = true,
		macro = true,
		mail = true,
		merchant = true,
		mirrorTimers = true,
		misc = true,
		petition = true,
		pvp = true,
		quest = true,
		raid = true,
		roulette = true,
		socket = true,
		spellbook = true,
		stable = true,
		store = true,
		tabard = true,
		talent = true,
		taxi = true,
		timemanager = true,
		toast = true,
		tooltip = true,
		toyCollection = true,
		trade = true,
		tradeskill = true,
		trainer = true,
		tutorial = true,
		wardrobe = true,
		worldState = true,
		worldmap = true,
	}
}

V.tooltip = {
	enable = true,
}

V.unitframe = {
	enable = true,
	disabledBlizzardFrames = {
		player = true,
		target = true,
		focus = true,
		boss = true,
		arena = true,
		party = true,
	}
}

V.actionbar = {
	enable = true,
	masque = {
		actionbars = false,
		petBar = false,
		stanceBar = false,
	}
}

V.worldmap = {
	enable = true
}
