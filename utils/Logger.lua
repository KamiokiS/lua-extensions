local Logger = {}

-- Настройки рисования
local DEFAULT_X, DEFAULT_Y = 10, 10
local LINE_HEIGHT = 14

-- Хранилище сообщений:
-- entriesMap[text] = entry
-- entriesList = { entry, entry, ... } — чтобы сохранить порядок добавления
local entriesMap = {}
local entriesList = {}

--- Логгирует сообщение. При повторном логгинге того же текста
--- увеличивает счётчик вместо добавления новой строки.
-- @param message  — любое значение, приводимое к строке
function Logger.log(message)
    local txt = tostring(message)
    local entry = entriesMap[txt]
    if entry then
        -- Увеличиваем счётчик повторов
        entry.count = entry.count + 1
    else
        -- Новое сообщение — создаём запись и сохраняем в списке
        entry = {
            text  = txt,
            count = 1,
            x     = DEFAULT_X,
            y     = DEFAULT_Y  -- мы перерасчитываем y в update()
        }
        entriesMap[txt] = entry
        table.insert(entriesList, entry)
    end
end

--- Очищает все накопленные сообщения
function Logger.Clear()
    entriesMap = {}
    entriesList = {}
end

--- Вызывается каждый кадр для вывода консоли
function Logger.update()
    local y = DEFAULT_Y
    for _, entry in ipairs(entriesList) do
        local display = entry.text
        if entry.count > 1 then
            display = string.format("%s (x%d)", entry.text, entry.count)
        end
        -- Рисуем и смещаемся вниз
        LUA.print(entry.x, y, display)
        y = y + LINE_HEIGHT
    end
end

return Logger
