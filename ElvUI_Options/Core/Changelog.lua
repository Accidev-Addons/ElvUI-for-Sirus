local E, _, V, P, G = unpack(ElvUI)
local _, L = unpack(E.Config)

local ACH = E.Libs.ACH
local format, tinsert = format, tinsert
local tconcat = table.concat

E.Changelog = {
    {
       version = '9.09.01',
       date = '25.09.2026',
       entries = {
          {
             title = 'Добавлено',
             items = {
                'Интеграция Sirus Nameplates: бафы, дебафы и эффекты контроля теперь отображаются вместе с плашками ElvUI.',
                'В информацию о сборке добавлены разработчики Sirus.',
             },
          },
          {
             title = 'Изменено',
             items = {
                'Настройки аур ElvUI убраны, чтобы не было двух разных мест для одной настройки.',
                'Тестовая плашка в настройках ElvUI теперь полностью повторяет обычные плашки игроков и сразу реагирует на изменения.',
                'Обновлена система подсветки.',
                'Обновлены ссылки на Discord и GitHub сборки.',
             },
          },
          {
             title = 'Исправлено',
             items = {
                'Исправлена совместимость версий ElvUI и ElvUI_Libraries.',
                'Исправлена подсветка кнопок на панелях.',
                'Исправлена двойная подсветка предметов при распылении.',
                'Устранено накопление лишних рамок и текстур при использовании подсветки.',
                'Исправлено отображение вкладок WeakAuras при изменении размера окна.',
                'Рамка заданий в режиме фиксаторов теперь правильно показывает высоту списка заданий.',
                'Имя существа на плашке теперь сразу окрашивается в нужный цвет в зависимости от реакции.',
             },
          },
       },
    },
}

local function BuildPage()
    local page = ACH:Group(L["Whats New"], nil, 5)

    for index, release in ipairs(E.Changelog) do
       local title = format('|cff1784d1%s|r', release.version)
       if release.date then
          title = format('%s|cff888888 - %s|r', title, release.date)
       end

       local lines = {}

       for _, section in ipairs(release.entries) do
          tinsert(lines, format('|cffffd100%s|r', section.title))

          for _, entry in ipairs(section.items) do
             tinsert(lines, format('— %s', entry))
          end

          tinsert(lines, '')
       end

       local group = ACH:Group(title, nil, index)
       group.inline = true
       group.args.string = ACH:Description(tconcat(lines, '|n'), 1, 'medium')

       page.args['release' .. index] = group
    end

    E.Options.args.changelog = page
end

local ok, err = pcall(BuildPage)
if not ok then
    E:Print(format('|cffff0000ElvUI|r: %s', err))
end