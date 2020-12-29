--- Reactor Server
--- @Tymec

local reactor = peripheral.wrap("back")

function update()
    fs.delete("startup")
    shell.run("pastebin get U340PWxt startup")
    os.reboot()
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
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
    print("Waiting for Master to initialize...")
    rednet.open("top")
    rednet.host("reactorMonitor", "reactorMonitorServer")

    -- Check if all packages are installed
    shell.run("pastebin get 1UxUTKi4 toboolean")

    while (true) do
        local _s = rednet.broadcast("ping", "reactorMonitor")
        local id, msg, pro = rednet.receive(1)
        if (msg == "pong" and pro == "reactorMaster") then
            return id
        end
    end
end

function updateReactor()
    local data = {}

    data["doEjectFuel"] = reactor.doEjectFuel()
    data["doEjectWaste"] = reactor.doEjectWaste()
    data["active"] = reactor.getActive()
    data["isActivelyCooled"] = reactor.isActivelyCooled()
    data["mbIsPaused"] = reactor.mbIsPaused()
    
    data["casingTemperature"] = reactor.getCasingTemperature()
    data["controlRodsLevels"] = reactor.getControlRodsLevels()
    data["numberOfControlRods"] = reactor.getNumberOfControlRods()
    data["wasteAmount"] = reactor.getWasteAmount()

    data["coolantAmount"] = reactor.getCoolantAmount()
    data["coolantAmountMax"] = reactor.getCoolantAmountMax()
    data["coolantFluidStats"] = reactor.getCoolantFluidStats()
    data["coolantType"] = reactor.getCoolantType()

    data["energyCapacity"] = reactor.getEnergyCapacity()
    data["energyProducedLastTick"] = reactor.getEnergyProducedLastTick()
    data["energyStats"] = reactor.getEnergyStats()
    data["energyStored"] = reactor.getEnergyStored()
    
    data["fuelAmount"] = reactor.getFuelAmount()
    data["fuelAmountMax"] = reactor.getFuelAmountMax()
    data["fuelConsumedLastTick"] = reactor.getFuelConsumedLastTick()
    data["fuelReactivity"] = reactor.getFuelReactivity()
    data["fuelStats"] = reactor.getFuelStats()
    data["fuelTemperature"] = reactor.getFuelTemperature()

    return data
end

-- MAIN
if (arg[1] == "update") then
    update()
end

local tb = dofile("toboolean")
local masterId = init()

--- Init reactor
while(true) do
    local reactorData = updateReactor()

    logPrint(string.format("Energy stored: %d RF", reactor.getEnergyStored()), "INFO", colors.orange, false)
    local success = rednet.send(masterId, reactorData, "reactorMonitor")
    logPrint(string.format("Rednet transmission %s", success and "was successful" or "failed"), nil, success and colors.green or colors.red, true)

    local id, msg, pro = rednet.receive(1)
    if (id == masterId and pro == "reactorMaster") then
        local params = split(msg, " ")
        if (tablelength(params) == 2) then
            local cmd, arg = params[1], params[2]
            if (cmd == "setActive") then
                reactor.setActive(tb(arg))
                logPrint(string.format("Rednet request: setActive(%s)", arg), "INFO", colors.yellow, false)
                rednet.send(masterId, string.format("Reactor active: %s", arg), "reactorMonitor")
            elseif (cmd == "setAllControlRodLevels") then
                reactor.setAllControlRodLevels(tonumber(arg))
                logPrint(string.format("Rednet request: setAllControlRodLevels(%s)", arg), "INFO", colors.yellow, false)
                rednet.send(masterId, string.format("Reactor allControlRodLevels: %s", arg), "reactorMonitor")
            end
        end
    end
end
