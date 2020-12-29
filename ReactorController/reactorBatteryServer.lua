--- Reactor Battery Server
--- @Tymec

local BATTERY_CELL_NAME = "thermalexpansion:storage_cell"
local BATTERY_HEIGHT = 3
local BATTERY_CAPACITY = 0

function update()
    fs.delete("startup")
    shell.run("pastebin get iV5zYGmw startup")
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

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function getEnergyCells()
    local periphs = peripheral.getNames()
    local energyCells = {}

    for i = 1, tablelength(periphs), 1 do
        if (string.match(periphs[i], BATTERY_CELL_NAME)) then
            local energyCapacity = peripheral.call(periphs[i], "getEnergyCapacity")
            local energyStored = peripheral.call(periphs[i], "getEnergyStored")
            logPrint(string.format("Energy Cell detected... ( ID: %d | Capacity: %d RF | Stored: %d RF )", i, energyCapacity, energyStored), "INFO", colors.cyan, false)

            local cellTable = {} 
            cellTable["name"] = periphs[i]
            cellTable["capacity"] = energyCapacity
            cellTable["stored"] = energyStored
            table.insert(energyCells, cellTable)
        end
    end
    energyCells["length"] = tablelength(energyCells)
    energyCells["height"] = BATTERY_HEIGHT
    energyCells["capacity"] = energyCells["length"] * energyCells["height"] * energyCells[1]["capacity"]
    return energyCells
end

function updateEnergyCells(cells)
    local updatedCells = cells
    for i = 1, cells["length"], 1 do
        local _n = cells[i]["name"]
        updatedCells[i]["stored"] = peripheral.call(_n, "getEnergyStored")
    end
    return updatedCells
end

function init()
    print("Waiting for Master to initialize...")
    rednet.open("left")
    rednet.host("batteryMonitor", "batteryMonitorServer")
    while (true) do
        local _s = rednet.broadcast("ping", "batteryMonitor")
        local id, msg, pro = rednet.receive(1)
        if (msg == "pong" and pro == "reactorMaster") then
            return id
        end
    end
end

-- MAIN
if (arg[1] == "update") then
    update()
end

local masterId = init()

--- Init cells
local cells = getEnergyCells()
logPrint(string.format("There are %d (%dx%d) energy cells connected to the battery.", (cells["height"] * cells["length"]), cells["length"], cells["height"]), "INFO", colors.orange, false)
logPrint("Reactor Battery Server is running...", nil, colors.green, true)
sleep(3)
shell.run("clear")

while (true) do
    --- Update energy cells
    local energyCells = updateEnergyCells(cells)

    --- Calculate average RF stored
    local avg = 0
    for i = 1, energyCells["length"], 1 do
        avg = avg + energyCells[i]["stored"]
    end
    avg = avg / energyCells["length"]
    energyCells["average"] = avg

    logPrint(string.format("Average energy stored: %d RF", avg), "INFO", colors.orange, false)
    
    --- Send data to master controller
    local success = rednet.send(masterId, energyCells, "batteryMonitor")
    logPrint(string.format("Rednet transmission %s", success and "was successful" or "failed"), nil, success and colors.green or colors.red, true)

    sleep(5)
end