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




-- Добавление новой анимации
function Tween.to(obj, target, duration, easing)
    table.insert(Tween.animations, {
        obj = obj,
        start = { x = obj.x, y = obj.y },
        target = target,
        duration = duration,
        elapsed = 0,
        easing = easing or function(t) return t end -- линейное изменение по умолчанию

    })
end

-- Обновление анимаций (вызывается каждый кадр)
function Tween.update(dt)
    for i = #Tween.animations, 1, -1 do
        local anim = Tween.animations[i]
        anim.elapsed = anim.elapsed + dt

        local t = math.min(anim.elapsed / anim.duration, 1)
        local easedT = anim.easing(t)

        anim.obj.x = anim.start.x + (anim.target.x - anim.start.x) * easedT
        anim.obj.y = anim.start.y + (anim.target.y - anim.start.y) * easedT

        if t >= 1 then
            table.remove(Tween.animations, i)
        end
    end
    -- Logger.log(#Tween.animations)
end


return Tween