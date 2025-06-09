-- tween.lua
local Tween = {}

local function removeTweenFromGlobal(tween)
    for i = #Tween.animations, 1, -1 do
        if Tween.animations[i] == tween then
            table.remove(Tween.animations, i)
            break
        end
    end
end

-- Хранилище активных анимаций
Tween.animations = {}


-- Стандартные easing-функции внутри библиотеки
Tween.easing = {
    linear = function(t) return t end, --наименее ресурсозатратная
    quadIn = function(t) return t * t end,
    quadOut = function(t) return 1 - (1 - t)^2 end,
    quadInOut = function(t)
        if t < 0.5 then
            return 2 * t * t
        else
            return 1 - (-2 * t + 2)^2 / 2
        end
    end,
    cubicIn = function(t) return t^3 end,
    cubicOut = function(t) return 1 - (1 - t)^3 end,
    cubicInOut = function(t)
        if t < 0.5 then
            return 4 * t^3
        else
            return 1 - (-2 * t + 2)^3 / 2
        end
    end,
    elasticOut = function(t) --более ресурсозатратная
        local c4 = (2 * math.pi) / 3
        return t == 0 and 0 or t == 1 and 1 or 2^(-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
    end,
    bounceIn = function(t)
        return 1 - Tween.easing.bounceOut(1 - t)
    end,
    bounceOut = function(t) --более ресурсозатратная
        if t < 1/2.75 then
            return 7.5625 * t * t
        elseif t < 2/2.75 then
            t = t - 1.5/2.75
            return 7.5625 * t * t + 0.75
        elseif t < 2.5/2.75 then
            t = t - 2.25/2.75
            return 7.5625 * t * t + 0.9375
        else
            t = t - 2.625/2.75
            return 7.5625 * t * t + 0.984375
        end
    end
}

-- Класс для управления последовательностями анимаций
local Sequence = {}
Sequence.__index = Sequence

function Sequence.new()
    local self = setmetatable({}, Sequence)
    self.elements = {}      -- Список элементов (твины/задержки)
    self.currentTime = 0    -- Текущее время в последовательности
    self.duration = 0       -- Общая длительность последовательности
    self.isDead = false     -- Флаг завершения
    self.onComplete = nil   -- Callback при завершении
    self.isPaused = false
    self.isSequence = true
    return self
end

function Sequence:Append(tween)
    local startTime = self.duration
    local element = {
        type = "tween",
        tween = tween,
        startTime = startTime,
        duration = tween.duration,
        completed = false
    }
    table.insert(self.elements, element)
    self.duration = self.duration + tween.duration
    removeTweenFromGlobal(tween)
    return self
end

function Sequence:Join(tween)
    if #self.elements == 0 then
        return self:Append(tween)
    end
    local lastElement = self.elements[#self.elements]
    local element = {
        type = "tween",
        tween = tween,
        startTime = lastElement.startTime,
        duration = tween.duration,
        completed = false
    }
    table.insert(self.elements, element)
    local endTime = element.startTime + element.duration
    if endTime > self.duration then
        self.duration = endTime
    end
    removeTweenFromGlobal(tween)
    return self
end

function Sequence:AppendInterval(delay)
    local element = {
        type = "delay",
        startTime = self.duration,
        duration = delay
    }
    table.insert(self.elements, element)
    self.duration = self.duration + delay
    return self
end

function Sequence:OnComplete(callback)
    self.onComplete = callback
    return self
end

function Sequence:update(dt)
    if self.isDead or self.isPaused then return end
    self.currentTime = self.currentTime + dt

    -- Обновляем элементы последовательности
    for _, element in ipairs(self.elements) do
        if element.type == "tween" and not element.completed then
            local elapsed = self.currentTime - element.startTime
            if elapsed >= element.duration then
                -- Завершаем элемент (работает для твина и последовательности)
                element.tween:Complete()
                element.completed = true
            elseif elapsed > 0 then
                -- Обновление для последовательности
                if element.tween.isSequence then
                    element.tween.currentTime = math.min(elapsed, element.tween.duration)
                    element.tween:update(0)
                -- Обновление для обычного твина
                else
                    element.tween.elapsed = elapsed
                    element.tween:update(0)
                end
            end
        end
    end

    
    -- Проверка завершения всей последовательности
    if self.currentTime >= self.duration then
        if self.onComplete then
            self.onComplete()
        end
        self.isDead = true
    end
end

function Sequence:Kill(complete)
    if self.isDead then return end
    self.isDead = true
    removeTweenFromGlobal(self)
    
    -- Убиваем все вложенные твины
    for _, element in ipairs(self.elements) do
        if element.type == "tween" and not element.tween.isDead then
            element.tween:Kill(false)
        end
    end
    
    if complete and self.onComplete then
        self.onComplete()
    end
end

function Sequence:Complete()
    if self.isDead then return end
    self.isDead = true
    self.currentTime = self.duration
    
    -- Завершаем все вложенные твины
    for _, element in ipairs(self.elements) do
        if element.type == "tween" and not element.completed then
            element.tween:Complete()
        end
    end
    
    if self.onComplete then
        self.onComplete()
    end
    removeTweenFromGlobal(self)
end

function Sequence:Rewind()
    self.currentTime = 0
    for _, element in ipairs(self.elements) do
        if element.type == "tween" then
            element.tween:Rewind()
        end
        element.completed = false
    end
end

function Sequence:Pause()
    self.isPaused = true
end

function Sequence:Play()
    self.isPaused = false
end

function Tween.Sequence()
    local seq = Sequence.new()
    table.insert(Tween.animations, seq)
    return seq
end

-- Внутренний класс для анимации
local TweenInstance = {}
TweenInstance.__index = TweenInstance

function TweenInstance.new(obj, target, duration)
    local self = setmetatable({}, TweenInstance)
    
    self.obj = obj
    self.start = {}
    self.target = {}
    self.duration = duration
    self.elapsed = 0
    self.easing = Tween.easing.linear
    self.isRelative = false
    self.onComplete = nil
    self.isDead = false
    self.isTween = true
    
    -- Инициализируем стартовые значения и целевые значения
    for key, value in pairs(target) do
        self.start[key] = obj[key]
        self.target[key] = value
    end
    
    return self
end

function TweenInstance:SetRelative()
    self.isRelative = true
    return self
end

function TweenInstance:SetEase(easing)
    self.easing = easing
    return self
end

function TweenInstance:OnComplete(callback)
    self.onComplete = callback
    return self
end

function TweenInstance:Kill(complete)
    if complete then
        self:Complete()
    else
        self.isDead = true
    end
    return self
end


function TweenInstance:update(dt)
    if dt > 0 then
        self.elapsed = self.elapsed + dt
    end
    local t = math.min(self.elapsed / self.duration, 1)
    local easedT = self.easing(t)
    
    for key, targetValue in pairs(self.target) do
        local startValue = self.start[key]
        local finalValue = self.isRelative and (startValue + targetValue) or targetValue
        self.obj[key] = startValue + (finalValue - startValue) * easedT
    end
    
    return t >= 1
end

-- Внутри класса TweenInstance
function TweenInstance:Complete()
    self.elapsed = self.duration
    self:update(0)
    if self.onComplete then
        self.onComplete()
    end
    self.isDead = true
    return self
end

function TweenInstance:Rewind()
    self.elapsed = 0
    self:update(0)
    return self
end

-- Основной метод для произвольных свойств
function Tween.to(obj, target, duration)
    local instance = TweenInstance.new(obj, target, duration)
    table.insert(Tween.animations, instance)
    return instance
end

-- Специализированные методы для конкретных свойств
function Tween.MoveX(obj, x, duration)
    return Tween.to(obj, {x = x}, duration)
end

function Tween.MoveY(obj, y, duration)
    return Tween.to(obj, {y = y}, duration)
end

function Tween.Move(obj, x, y, duration)
    return Tween.to(obj, {x = x, y = y}, duration)
end

function Tween.ScaleX(obj, scaleX, duration)
    return Tween.to(obj, {scaleX = scaleX}, duration)
end

function Tween.ScaleY(obj, scaleY, duration)
    return Tween.to(obj, {scaleY = scaleY}, duration)
end

function Tween.Scale(obj, scale, duration)
    return Tween.to(obj, {scale = scale}, duration)
end

function Tween.Alpha(obj, alpha, duration)
    return Tween.to(obj, {alpha = alpha}, duration)
end

function Tween.Rotation(obj, rotation, duration)
    return Tween.to(obj, {rotation = rotation}, duration)
end

-- Глобальные методы управления твинами
function Tween.KillAll()
    Tween.animations = {}
end

function Tween.update(dt)
    for i = #Tween.animations, 1, -1 do
        local anim = Tween.animations[i]
        if anim.isDead then
            table.remove(Tween.animations, i)
        else
            if anim.isSequence then
                anim:update(dt)
            elseif anim.isTween then
                local isCompleted = anim:update(dt)
                if isCompleted then
                    if anim.onComplete then
                        anim.onComplete()
                    end
                    anim.isDead = true
                end
            end
        end
    end
end

return Tween