local DELAY = 1
local SLOT_COUNT = 16
local LAST_INV_SLOT = 15
local BLOCK_TO_PLACE = "minecraft:netherrack"

function isInventoryFull()
    if (turtle.getItemCount(LAST_INV_SLOT) > 0) then
        return true
    end
    return false
end

function emptyInventory(blockToKeep)
    for slot = 1, SLOT_COUNT, 1 do
        local item = turtle.getItemDetail(slot)
        if (item ~= nil) then
            if (item["name"] ~= blockToKeep) then
                turtle.select(slot)
                turtle.dropUp()
            end
        end
    end
end

function checkInventory(blockToKeep)
    -- Check if inventory is full
    if (isInventoryFull()) then
        emptyInventory(blockToKeep)
    end

    -- Check if out of blocks to place
    if (getItemIndex(blockToKeep) == nil) then
        emptyInventory(blockToKeep)
        turtle.turnRight()
        turtle.turnRight()
        turtle.select(1)
        if (turtle.suck(64)) then
            turtle.turnRight()
            turtle.turnRight()
        else
            turtle.turnRight()
            turtle.turnRight()
            print("Out of blocks to place...")
            return nil
        end
    end
    return true
end

function getItemIndex(itemName)
    for slot = 1, SLOT_COUNT, 1 do
        local item = turtle.getItemDetail(slot)
        if (item ~= nil) then
            if (item["name"] == itemName) then
                return slot
            end
        end
    end
    return nil
end

while (true) do
    if not (checkInventory(BLOCK_TO_PLACE)) then
        return
    end

    local blockIndex = getItemIndex(BLOCK_TO_PLACE)
    turtle.select(blockIndex)
    turtle.place()
    redstone.setAnalogOutput("right", 15)

    sleep(DELAY)
    redstone.setAnalogOutput("right", 0)
    turtle.dig()
end