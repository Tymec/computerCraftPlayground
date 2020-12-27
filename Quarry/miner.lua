--Client Mine--
 
local SLOT_COUNT = 16
local LAST_INV_SLOT = 14
local FUEL_CHEST = 15
local OUTPUT_CHEST = 16
 
local CLIENT_PORT = 96
local SERVER_PORT = 420
 
local modem = peripheral.wrap("right")
modem.open(SERVER_PORT)

-- HELPER
function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function parseParams(data)
    params = split(data, " ")
    out = {}
    out[1] = vector.new(params[1], params[2], params[3])
    out[2] = params[4]
    return out
end

function getItemIndex(itemName)
    for slot = 1, SLOT_COUNT, 1 do
        local item = turtle.getItemDetail(slot)
        if(item ~= nil) then
            if(item["name"] == itemName) then
                return slot
            end
        end
    end
end

function checkFuel()
    if (turtle.getFuelLevel() < 100) then
        turtle.select(FUEL_CHEST)
        turtle.digUp()
        turtle.placeUp()
        --Chest is deployed
 
        turtle.suckUp()
 
        while(true) do
            bucketIndex = getItemIndex("minecraft:lava_bucket")
            if (bucketIndex == nil) then
                turtle.suckUp()
                turtle.dropUp()
            else
                turtle.select(bucketIndex)
                turtle.refuel()
                turtle.dropUp()
                turtle.digUp()
                turtle.select(1)
                return true
            end
        end
    end
    return true
end

function isInventoryFull()
    if turtle.getItemCount(LAST_INV_SLOT) > 0 then
        return true
    end
    return false
end

function manageInventory()
    if not isInventoryFull() then
        return false
    end

    turtle.select(OUTPUT_CHEST)
    turtle.digUp()
    turtle.placeUp()
    --Chest is deployed

    for slot = 1, LAST_INV_SLOT, 1 do
        turtle.select(slot)
        turtle.dropUp()
    end

    turtle.select(OUTPUT_CHEST)
    turtle.digUp()
    turtle.select(1)
    return true
end

-- COCK
function getOrientation()
    loc1 = vector.new(gps.locate(2, false))
    if not turtle.forward() then
        for j=1,6 do
            if not turtle.forward() then
                turtle.dig()
            else 
                break 
            end
        end
    end
    loc2 = vector.new(gps.locate(2, false))
    heading = loc2 - loc1
    turtle.down()
    turtle.down()
    return ((heading.x + math.abs(heading.x) * 2) + (heading.z + math.abs(heading.z) * 3))
end
 
function turnToFaceHeading(heading, destinationHeading)
    if(heading > destinationHeading) then
        for t = 1, math.abs(destinationHeading - heading), 1 do 
            turtle.turnLeft()
        end
    elseif(heading < destinationHeading) then
        for t = 1, math.abs(destinationHeading - heading), 1 do 
            turtle.turnRight()
        end
    end
end
 
function setHeadingZ(zDiff, heading)
    local destinationHeading = heading
    if(zDiff < 0) then
        destinationHeading = 2
    elseif(zDiff > 0) then
        destinationHeading = 4
    end
    turnToFaceHeading(heading, destinationHeading)
 
    return destinationHeading
end
 
function setHeadingX(xDiff, heading)
    local destinationHeading = heading
    if(xDiff < 0) then
        destinationHeading = 1
    elseif(xDiff > 0) then
        destinationHeading = 3
    end
 
    turnToFaceHeading(heading, destinationHeading)
    return destinationHeading
end
 
function digAndMove(n)
    for x = 1, n, 1 do
        while(turtle.detect()) do
            turtle.dig()
        end
        turtle.forward()
        checkFuel()
    end
end
 
function digAndMoveDown(n)
    for y = 1, n, 1 do
        print(y)
        while(turtle.detectDown()) do
            turtle.digDown()
        end
        turtle.down()
        checkFuel()
    end
end
 
function digAndMoveUp(n)
    for y = 1, n, 1 do
        while(turtle.detectUp()) do
            turtle.digUp()
        end
        turtle.up()
        checkFuel()
    end
end
 
function moveTo(coords, heading)
    local currX, currY, currZ = gps.locate()
    local xDiff, yDiff, zDiff = coords.x - currX, coords.y - currY, coords.z - currZ
    print(string.format("Distances from start: %d %d %d", xDiff, yDiff, zDiff))
 
    --    -x = 1
    --    -z = 2
    --    +x = 3
    --    +z = 4
 
 
    -- Move to X start
    heading = setHeadingX(xDiff, heading)
    digAndMove(math.abs(xDiff))
 
    -- Move to Z start
    heading = setHeadingZ(zDiff, heading)
    digAndMove(math.abs(zDiff))
 
    -- Move to Y start
    if(yDiff < 0) then    
        digAndMoveDown(math.abs(yDiff))
    elseif(yDiff > 0) then
        digAndMoveUp(math.abs(yDiff))
    end
 
 
    return heading
end

-- END OF COCK
modem.transmit(SERVER_PORT, CLIENT_PORT, "CLIENT_DEPLOYED")
event, side, senderChannel, replyChannel, msg, distance = os.pullEvent("modem_message")
data = parseParams(msg)
print(string.format("Starting miner with size %dx%dx%d", data[1].x, data[1].y, data[1].z))
 
-- Refuel
checkFuel()

-- Get heading
local startPosition = vector.new(gps.locate())
local finalHeading = moveTo(startPosition, getOrientation())

local NORTH_HEADING = tonumber(data[2])
-- Turn to face North
turnToFaceHeading(finalHeading, NORTH_HEADING)
finalHeading = NORTH_HEADING
-- Now in Starting Position--

-- MINING HELPER
function detectAndDig()
    while(turtle.detect()) do
        turtle.dig()
        turtle.digUp()
    end
end

function forward()
    detectAndDig()
    turtle.forward()
end

function leftTurn()
    turtle.turnLeft()
    detectAndDig()
    turtle.forward()
    turtle.turnLeft()
end

function rightTurn()
    turtle.turnRight()
    detectAndDig()
    turtle.forward()
    turtle.turnRight()
end

function dropTier(heading)
    turtle.turnRight()
    turtle.turnRight()
    turtle.digDown()
    turtle.down()
    return flipDirection(heading)
end

function flipDirection(heading)
    return ((heading + 1) % 4) + 1
end

function turnAround(tier, heading)
    if(tier % 2 == 1) then
        if(heading == 2 or heading == 3) then
            rightTurn()
        elseif(heading == 1 or heading == 4) then
            leftTurn()
        end
    else
        if(heading == 2 or heading == 3) then
            leftTurn()
        elseif(heading == 1 or heading == 4) then
            rightTurn()
        end
    end
 
    return flipDirection(heading)
end


function mine(width, height, depth, heading)
    for tier = 1, height, 1 do
        for col = 1, width, 1 do
            for row = 1, depth - 1, 1 do
                if(not checkFuel()) then
                    print("Turtle is out of fuel, powering down...")
                    return
                end
                manageInventory()
                forward()
            end
            if(col ~= width) then
                heading = turnAround(tier, heading)
            end
        end
        if(tier ~= height) then
            heading = dropTier(heading)
        end
    end
 
    return heading
end

local size = data[1]
finishedHeading = mine(size.x, size.y, size.z, finalHeading)

function returnTo(coords, heading)
    local currX, currY, currZ = gps.locate()
    local xDiff, yDiff, zDiff = coords.x - currX, coords.y - currY, coords.z - currZ
    print(string.format("Distances from end: %d %d %d", xDiff, yDiff, zDiff))
 
    -- Move to Y start
    if(yDiff < 0) then    
        digAndMoveDown(math.abs(yDiff))
    elseif(yDiff > 0) then
        digAndMoveUp(math.abs(yDiff))
    end
 
    -- Move to X start
    heading = setHeadingX(xDiff, heading)
    digAndMove(math.abs(xDiff))
 
    -- Move to Z start
    heading = setHeadingZ(zDiff, heading)
    digAndMove(math.abs(zDiff))
 
    return heading
end

returnTo(startPosition, finishedHeading)

modem.transmit(SERVER_PORT, CLIENT_PORT, "cum")
local finishedPosition = gps.locate()
while (true) do
    modem.transmit(SERVER_PORT, CLIENT_PORT, string.format("Computer %d finished at %dx%dx%d", os.getComputerID(), finishedPosition.x, finishedPosition.y, finishedPosition.z))
    sleep(15)
end