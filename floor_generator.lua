--@name Floor Generator Safe Spawn
--@author ChatGPT

-- Commands:
-- !generate width length
-- !removefloor

-- NOTE:
-- Starfall props do not have setScale().
-- This version spawns real colliding floor plates slowly to avoid burst errors.

if SERVER then

    local MODEL = "models/sprops/rectangles/size_10/rect_480x480x3.mdl"
    local TILE_SIZE = 480

    local MAX_TILES = 120

    -- Keep this at 1 if your server has strict prop burst limits
    local SPAWN_PER_BATCH = 1
    local BATCH_DELAY = 0.35

    local floorProps = {}
    local queue = {}
    local queueIndex = 1
    local spawning = false

    local function say(msg)
        print("[Floor Generator] " .. msg)
    end

    local function splitText(text)
        local args = {}

        for word in string.gmatch(text, "%S+") do
            table.insert(args, word)
        end

        return args
    end

    local function clearFloor()
        spawning = false
        queue = {}
        queueIndex = 1

        for _, ent in ipairs(floorProps) do
            if ent and ent:isValid() then
                ent:remove()
            end
        end

        floorProps = {}
    end

    local function spawnNext()
        if not spawning then return end

        local spawned = 0

        while spawned < SPAWN_PER_BATCH and queueIndex <= #queue do
            local data = queue[queueIndex]
            queueIndex = queueIndex + 1

            local plate = prop.create(data.pos, data.ang, MODEL, true)

            if plate and plate:isValid() then
                plate:setFrozen(true)
                table.insert(floorProps, plate)
            end

            spawned = spawned + 1
        end

        if queueIndex <= #queue then
            timer.simple(BATCH_DELAY, spawnNext)
        else
            spawning = false
            say("Floor finished.")
        end
    end

    local function generateFloor(width, length)
        clearFloor()

        width = math.floor(tonumber(width) or 1)
        length = math.floor(tonumber(length) or 1)

        width = math.max(width, 1)
        length = math.max(length, 1)

        local total = width * length

        if total > MAX_TILES then
            say("Too many tiles. Max is " .. MAX_TILES .. ".")
            return
        end

        local chipEnt = chip()
        local basePos = chipEnt:getPos()
        local baseAng = chipEnt:getAngles()

        local forward = baseAng:getForward()
        local right = baseAng:getRight()

        local startX = -((width - 1) * TILE_SIZE) / 2
        local startY = -((length - 1) * TILE_SIZE) / 2

        queue = {}
        queueIndex = 1

        for x = 1, width do
            for y = 1, length do
                local offset =
                    right * (startX + ((x - 1) * TILE_SIZE)) +
                    forward * (startY + ((y - 1) * TILE_SIZE))

                table.insert(queue, {
                    pos = basePos + offset,
                    ang = Angle(0, baseAng.yaw, 0)
                })
            end
        end

        spawning = true
        say("Generating colliding floor " .. width .. " x " .. length .. "...")

        timer.simple(0.1, spawnNext)
    end

    hook.add("PlayerSay", "floor_generator_chat", function(ply, text)
        if ply ~= owner() then return end

        local args = splitText(string.lower(text))

        if args[1] == "!generate" then
            generateFloor(args[2], args[3])
            return ""
        end

        if args[1] == "!removefloor" then
            clearFloor()
            say("Floor removed.")
            return ""
        end
    end)

    hook.add("Removed", "floor_generator_cleanup", function()
        clearFloor()
    end)

    say("Loaded. Use !generate width length")

end
