--- Reactor Phone Client
--- @Tymec

rednet.open("back")
rednet.host("reactorMaster", "reactorMasterServer")

local serverId = rednet.lookup("reactorMonitor")

if not serverId then
    print("Battery Monitor Server is offline...")
    return
end

local _i, _msg, _pro = rednet.receive(5)
if not _msg then
    term.setTextColor(color.red)
    print("Battery Monitor Server Error")
    return
end

if (_pro == "reactorMonitor") then
    rednet.send(serverId, "pong", "reactorMaster")
end

while (true) do
    local _, msg, pro = rednet.receive(1)
    if (pro == "reactorMonitor") then
        rednet.send(serverId, "setActive", "reactorMaster")
    end
end