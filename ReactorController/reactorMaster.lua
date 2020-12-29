--- Reactor Master
--- @Tymec

local SERVER_PORT = 8008
local CLIENT_PORT = 10

function update()
    fs.delete("startup")
    shell.run("pastebin get AP68hSEe startup")
    os.reboot()
end

function logPrint(msg, _t, _c, _i)
    if not _i then
        local _ct = os.time()
        local _ft = textutils.formatTime(_ct, true)
        term.setTextColor(colors.white)
        print(string.format("[%s] [%s]", _ft, _t))
    end
    term.setTextColor(_c)
    print(string.format("%s", msg))
    --- local _o = string.format("[%s] [%s] \n%s", _ft, _t, msg)
    --- print(_o)
end

function init()
    local monitorId, batteryId = nil

    print("Initializing...")
    rednet.open("back")
    rednet.host("reactorMaster", "reactorMasterServer")

    -- Check if all packages are installed
    shell.run("pastebin get UxweEuqf surface")

    while (not (monitorId and batteryId)) do
        local id, msg, pro = rednet.receive(1)

        if (pro == "reactorMonitor" and not monitorId) then
            monitorId = id
            local success = rednet.send(monitorId, "pong", "reactorMaster")
            logPrint(string.format("Reactor Monitor initialization %s...", success and "was successful" or "failed"), "INFO", colors.orange, true)
        elseif (pro == "batteryMonitor" and not batteryId) then
            batteryId = id
            local success = rednet.send(batteryId, "pong", "reactorMaster")
            logPrint(string.format("Battery Monitor initialization %s...", success and "was successful" or "failed"), "INFO", colors.orange, true)
        end
    end
    return monitorId, batteryId
end

function read(reactorId, batteryId)
    local monitorData, batteryData = nil
    local userTerminate = false

    while (not (monitorData and batteryData)) do

        -- NOTE: need to create a new function for receive and keep a persistent variable holding received data
        -- Wait for either user terminate or receive to finish
        -- parallel.waitForAny()
        local id, msg, pro = rednet.receive(1)

        if (pro == "reactorMonitor" and not monitorData) then
            monitorData = msg
        elseif (pro == "batteryMonitor" and not batteryData) then
            batteryData = msg
        end
    end
    logPrint("Reactor Monitor data received...\nBattery Monitor data received...", "INFO", colors.green, false)
    return monitorData, batteryData
end

function sendCmd(id, msg)
    rednet.send(id, msg, "reactorMaster")
end

function updateReactor(reactorData, batteryData, id, threshold)
    local reactorBuffer = reactorData["energyStored"] / reactorData["energyCapacity"]
    local batteryStorage = batteryData["average"]

    if (reactorBuffer < threshold['min']) then
        sendCmd(id["reactor"], "setActive true")
    elseif (reactorBuffer > threshold['max']) then
        sendCmd(id["reactor"], "setActive false")
    end
end

function initMonitor(w, h)
    local monitor = peripheral.wrap("right")

    monitor.clear()
    monitor.setTextScale(0.5)
    term.redirect(monitor)

    local surface = dofile("surface")
    local screen = surface.create(w, h, colors.blue)
    return surface, screen
end

function render(screen, reactorData, batteryData)

end

-- MAIN
if (arg[1] == "update") then
    update()
end

local reactorId, batteryId = init()
local surface, screen = initMonitor((15 * 4), (10 * 3))
local manualMode = false

while (true) do
    -- in case one of the computers went restarted
    rednet.broadcast("pong", "reactorMaster")

    local reactorData, batteryData = read(reactorId, batteryId)
    if (not manualMode and (type(reactorData) == "table") and (type(batteryData) == "table")) then
        updateReactor(reactorData, batteryData, {reactor=reactorId, battery=batteryId}, {min=.2, max=.8})
    end
    
    render(screen)
end

--- Wait for data from reactor and energy cell computers
--- Send data to reactor computer depending on energy cell power
--- Display data on monitor