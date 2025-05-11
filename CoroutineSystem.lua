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
        waitValue = nil
    })
    return co
end

function CoroutineSystem.Update()
    CoroutineSystem._frameCount = CoroutineSystem._frameCount + 1
    CoroutineSystem._timer = os.clock()

    for i = #CoroutineSystem._active, 1, -1 do
        local entry = CoroutineSystem._active[i]
        local shouldResume = false

        -- Проверка условий ожидания
        if entry.waitType == "seconds" then
            shouldResume = CoroutineSystem._timer >= entry.waitValue
        elseif entry.waitType == "frames" then
            shouldResume = CoroutineSystem._frameCount >= entry.waitValue
        elseif entry.waitType == "coroutine" then
            shouldResume = coroutine.status(entry.waitValue) == "dead"
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

-- Новый метод: ожидание другой корутины
local function WaitForCoroutine(co)
    return coroutine.yield("coroutine", co)
end

return {
    Start = CoroutineSystem.Start,
    Update = CoroutineSystem.Update,
    WaitForSeconds = WaitForSeconds,
    WaitForFrames = WaitForFrames,
    WaitForEndOfFrame = WaitForEndOfFrame,
    WaitForCoroutine = WaitForCoroutine
}