-- tween.lua
local Tween = {}

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

function TweenInstance:Kill()
    self.isDead = true  -- Помечаем твин для удаления
    return self
end

function TweenInstance:update(dt)
    self.elapsed = self.elapsed + dt
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
    self.elapsed = self.duration  -- Устанавливаем время в конец
    self:update(0)  -- Принудительно обновляем состояние до конечного
    self:Kill()  -- Удаляем твин
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
        
        -- Если твин помечен как "убитый"
        if anim.isDead then
            table.remove(Tween.animations, i)
        else
            local isCompleted = anim:update(dt)
            
            if isCompleted then
                if anim.onComplete then
                    anim.onComplete()
                end
                table.remove(Tween.animations, i)
            end
        end
    end
end



return Tween