local E, L, V, P, G = unpack(ElvUI)
local CH = E:GetModule('Chat')

local next, type, format, random = next, type, format, random
local gmatch, strlower, strmatch, strsub = gmatch, strlower, strmatch, strsub

local MEDIA = [[Interface\AddOns\ElvUI\Core\Media\ChatLogos\]]
local DEFAULT_SIZE = 32

-- размер иконки: число = квадрат, 'высота:ширина' если нет. Не указан — 32.
local SIZE = {
	Apolexis    = '24:58',
	ElvBlue     = '13:25',
	eye2        = 25,
	gyiffay     = 24,
	KolbaskaSir = 24,
	marazmat    = 24,
	meat        = '20:40',
	spokes      = 24,
	thorncrown  = 28,
	tokyo       = 24,
}

local SETS = {
	Elv  = 'ElvBlue ElvGreen ElvMelon ElvOrange ElvPink ElvPurple ElvRainbow ElvRed ElvYellow',
	pepe = 'pepeShy pepeLove pepeLove2 pepeWTF pepeHaha pepeSmile pepeSmile2 pepeKid pepeChrist',
}

local REALMS = {
	Sirus = {
		angrybird   = 'Pain Масстаунт',
		Apolexis    = 'Apolexis Алексей',
		da1mon12    = 'Zippio Даймон Худший',
		Elv         = 'Пьяная Шутка',
		eye2        = 'Акация',
		gbutterfly  = 'Колючая Колючка',
		gyiffay     = 'Dadbod Furryfetish Gyiffay Hairybear Locktober',
		kaiden      = 'Kaiden',
		kirin       = 'Taumard Реинбоу Рейнбоу Рэинбоу Рэйнбоу',
		KolbaskaSir = 'Антидонат Сырсколбасой',
		lunt        = 'Lyntuk',
		marazmat    = 'Marazmat Totemoffnet Дилетантище Нехоли',
		meat        = 'Miasii',
		ori         = 'Пристика',
		pepe        = 'Cureit Root Выстрелбелка Наглость Тридвараз Тымолодец Lambargyni',
		spokes      = 'Andrewka Andrewkaa Spokes',
		thorncrown  = 'Kwxsq Lomael Mirias',
		tokyo       = 'Afkposlefk Горящий Планета Темныи Токио',
	},
	Neverest = {
		butterfly2 = 'Koluchka Беспокойная Калючка Колючка',
		Elv        = 'Шутка',
		pepe       = 'Murr',
		skull2     = 'Oldpain Pain Пеин Пейн Пэин',
		zuman1     = 'Zuman Зуман Зумаэль',
	},
	Soulseeker = {
		Elv          = 'Fxpw Шутка',
		mottidowerro = 'Mottidowerro Mottyoka',
		pepe         = 'Выстрелбелка',
	},
	any = {
		-- иконка = 'Имена через пробел' — сработает на любом реалме
	},
}

local lookup, cache, pool = nil, {}, {}

local function Texture(file)
	local str = cache[file]
	if not str then
		local size = SIZE[file] or DEFAULT_SIZE
		str = format('|T%s%s:%s|t', MEDIA, file, type(size) == 'number' and size..':'..size or size)
		cache[file] = str
	end

	return str
end

local function Build()
	lookup = {}

	local realm = E.myrealm or ''
	realm = strmatch(realm, '^Proxy%a*%s+(.+)$') or realm
	realm = strmatch(realm, '^(%a+)') or realm

	for _, list in next, { REALMS[realm], REALMS.any } do
		for icon, names in next, list do
			for name in gmatch(names, '%S+') do
				lookup[strlower(name)] = icon
			end
		end
	end

	REALMS = nil -- таблицы чужих реалмов больше не нужны
end

local function GetChatIcon(name)
	if not name or name == '' or strsub(name, 1, 2) == '0x' then return end
	if not lookup then Build() end

	local icon = lookup[strlower(name)]
	if not icon then return end

	local set = SETS[icon]
	if set then
		local list = pool[icon]
		if not list then
			list = {}
			for entry in gmatch(set, '%S+') do
				list[#list + 1] = entry
			end

			pool[icon] = list
		end

		icon = list[random(#list)]
	end

	return Texture(icon)
end

CH:AddPluginIcons(GetChatIcon)
