Time = {}

local lastTime = os.clock()

-- функция, возвращающая dt и обновляющая lastTime
function Time.getDeltaTime()
    local now = os.clock()
    local dt = now - lastTime
    lastTime = now
    -- при желании можно сразу ограничить максимум, 
    -- чтобы избежать слишком больших скачков:
    -- if dt > 0.1 then dt = 0.1 end  
    return dt
end

return Time