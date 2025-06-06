-- Fader.lua
local Fader = {
    active = false,
    startAlpha = 0,
    currentAlpha = 0,
    targetAlpha = 0,
    duration = 0,
    elapsed = 0,
    color = Color.new(0, 0, 0, 255),
    callback = nil
}

function Fader.start(targetAlpha, duration, color)
    -- Остановить предыдущую анимацию если была активна
    if Fader.active then
        Fader.active = false
    end
    
    -- Установка параметров
    Fader.startAlpha = Fader.currentAlpha
    Fader.targetAlpha = targetAlpha
    Fader.duration = duration
    Fader.elapsed = 0
    Fader.color = color or Color.new(0, 0, 0, 255)
    Fader.active = true
    
    -- Возвращаем таблицу с методом для callback
    return {
        OnComplete = function(self, cb)
            Fader.callback = cb
        end
    }
end

function Fader.update(deltaTime)
    if not Fader.active then return end
    
    Fader.elapsed = Fader.elapsed + deltaTime
    local progress = math.min(Fader.elapsed / Fader.duration, 1.0)
    
    Fader.currentAlpha = Fader.startAlpha + (Fader.targetAlpha - Fader.startAlpha) * progress
    
    if progress >= 1.0 then
        Fader.active = false
        local cb = Fader.callback -- Сохраняем callback во временную переменную
        Fader.callback = nil       -- Сбрасываем до вызова
        if cb then
            cb()                   -- Вызываем callback
        end
    end
end

function Fader.draw()
    if Fader.currentAlpha > 0 then
        local r, g, b = Color.get(Fader.color, "R"), Color.get(Fader.color, "G"), Color.get(Fader.color, "B")
        local fadeColor = Color.new(r, g, b, Fader.currentAlpha)
        screen.drawRect(0, 0, 480, 272, fadeColor)
    end
end

return Fader