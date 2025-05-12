local PathManager = {}

-- Конфигурация по умолчанию
local config = {
    root = "assets/",
    sprite = { dir = "sprites/", ext = ".png" },
    music = { dir = "music/", ext = ".mp3" }
}

-- Настройка конфигурации
function PathManager.setup(custom_config)
    for k, v in pairs(custom_config or {}) do
        config[k] = v
    end
end

-- Основная функция построения пути
local function build_path(category, ...)
    local parts = {...}
    local category_cfg = config[category]
    
    if not category_cfg then
        error("Unknown category: " .. tostring(category))
    end
    
    -- Если передано несколько частей - соединяем через /
    -- Если одна часть - используем как есть
    local filename = #parts > 0 and table.concat(parts, "/") or ""
    
    return config.root 
        .. category_cfg.dir 
        .. filename 
        .. (filename ~= "" and category_cfg.ext or "")
end

-- Автоматическое создание методов для каждой категории
for category in pairs(config) do
    if type(config[category]) == "table" then
        PathManager[category] = function(...)
            return build_path(category, ...)
        end
    end
end

return PathManager