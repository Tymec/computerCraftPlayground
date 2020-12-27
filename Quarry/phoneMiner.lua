-- Phone Miner --

local SERVER_PORT = 420
local PHONE_PORT = 69

local modem = peripheral.wrap("back")
local size = vector.new()

if (#arg == 4) then
    size.x = tonumber(arg[1])
    size.y = tonumber(arg[2])
    size.z = tonumber(arg[3])
    heading = tonumber(arg[4])
else
    print("NO SIZE GIVEN")
    os.exit(1)
end

--local target = vector.new(gps.locate())--
local payloadMessage = string.format("%d %d %d %d %d",
    size.x, size.y, size.z,
    heading,
    1
)

print(string.format("Starting miner with size %dx%dx%d", size.x, size.y, size.z))
modem.transmit(SERVER_PORT, PHONE_PORT, payloadMessage)