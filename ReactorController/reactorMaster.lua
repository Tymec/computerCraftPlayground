--- Reactor Master
--- @Tymec

local INTERNAL_BUFFER_MAX = 10000000
local EXTERNAL_BUFFER_SIZE = 33
local MIN_THRESHOLD = .3
local MAX_THRESHOLD = .8
local SERVER_PORT = 8008
local CLIENT_PORT = 10

local monitor = peripheral.wrap("right")
local modem = peripheral.wrap("back")

print("Reactor Controller is On...")

monitor.clear()

---while (true) do
---    event, side, xPos, yPos = os.pullEvent("monitor_touch")
---    monitor.clear()
---    monitor.setCursorPos(xPos, yPos)
---    monitor.write(side)
---    sleep(.5)
---end

--- Wait for data from reactor and energy cell computers
--- Send data to reactor computer depending on energy cell power
--- Display data on monitor

sleep(5)