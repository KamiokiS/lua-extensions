local ScreenShake = {
    -- Текущие смещения
    offset = { x = 0, y = 0 },
    -- Внутренние параметры
    _timeLeft = 0,
    _duration = 0,
    _magnitude = 0,
}

-- Начать дрожание экрана
-- duration: длительность в секундах
-- magnitude: максимальное смещение в пикселях
function ScreenShake:start(duration, magnitude)
    self._duration = duration
    self._timeLeft  = duration
    self._magnitude = magnitude
end

-- Обновление модуля, вызывается в системном update(dt)
function ScreenShake:update(dt)
    if self._timeLeft > 0 then
        self._timeLeft = self._timeLeft - dt
        local progress = self._timeLeft / self._duration
        -- текущая сила дрожания, затухает к нулю
        local mag = self._magnitude * progress
        -- случайный угол в радианах
        local angle = math.random() * 2 * math.pi
        -- смещения по x и y
        self.offset.x = math.cos(angle) * mag
        self.offset.y = math.sin(angle) * mag
    else
        -- сброс смещения
        self.offset.x = 0
        self.offset.y = 0
    end
end

-- Получить текущее смещение экрана
function ScreenShake:getOffset()
    return self.offset.x, self.offset.y
end

-- пример использования:

-- Базовый draw
-- function Entity:draw()
--   if self.img then
--     local ox, oy = ScreenShake:getOffset()
--     Image.draw(self.img, self.x + ox, self.y + oy)
--   else
--     screen.drawRect(self.x, self.y, self.width, self.height, Color.new(255,255,255))
--   end
-- end

return ScreenShake