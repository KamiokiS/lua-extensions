local CoroutineSystem = {
    _active = {},
    _timer = 0,
    _frameCount = 0
}


function CoroutineSystem.Start(func)
    local co = coroutine.create(func)
    table.insert(CoroutineSystem._active, {
        coroutine = co,
        waitType = nil,
        waitValue = 0
    })
    return co
end

-- Обновление состояния корутин (вызывать каждый кадр)
function CoroutineSystem.Update()
    CoroutineSystem._frameCount = CoroutineSystem._frameCount + 1
    CoroutineSystem._timer = os.clock()

    for i = #CoroutineSystem._active, 1, -1 do
        local entry = CoroutineSystem._active[i]
        local shouldResume = false

        if entry.waitType == "seconds" then
            shouldResume = CoroutineSystem._timer >= entry.waitValue
        elseif entry.waitType == "frames" then
            shouldResume = CoroutineSystem._frameCount >= entry.waitValue
        else
            shouldResume = true
        end

        if shouldResume then
            local success, waitType, waitValue = coroutine.resume(entry.coroutine)
            
            if not success then
                print("Coroutine error: " .. tostring(waitType))
                table.remove(CoroutineSystem._active, i)
            elseif coroutine.status(entry.coroutine) == "dead" then
                table.remove(CoroutineSystem._active, i)
            else
                entry.waitType = waitType
                entry.waitValue = waitValue
            end
        end
    end
end

-- Методы ожидания
local function WaitForSeconds(seconds)
    return coroutine.yield("seconds", os.clock() + seconds)
end

local function WaitForFrames(frames)
    return coroutine.yield("frames", CoroutineSystem._frameCount + frames)
end

local function WaitForEndOfFrame()
    return coroutine.yield("frames", CoroutineSystem._frameCount + 1)
end

return {
    -- Системные методы
    Start = CoroutineSystem.Start,
    Update = CoroutineSystem.Update,
    
    -- Методы ожидания
    WaitForSeconds = WaitForSeconds,
    WaitForFrames = WaitForFrames,
    WaitForEndOfFrame = WaitForEndOfFrame
}