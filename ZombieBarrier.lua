--@name Zombie Forcefield
--@server

local radius = 500
local barrelModel = "models/props_c17/oildrum001_explosive.mdl"

local triggered = {}
local circleHolos = {}

local scanDelay = 0.5
local zombieCooldown = 4
local maxBarrelsPerScan = 2

local function isZombie(ent)
    if not ent or not ent:isValid() then return false end

    local class = string.lower(ent:getClass())

    return string.find(class, "zombie")
        or string.find(class, "zombine")
        or string.find(class, "headcrab")
        or string.find(class, "fastzombie")
        or string.find(class, "poisonzombie")
end

local function removeCircle()
    for _, holo in pairs(circleHolos) do
        if holo and holo:isValid() then
            holo:remove()
        end
    end

    circleHolos = {}
end

local function createCircle()
    removeCircle()

    local center = chip():getPos()
    local segments = 48

    for i = 1, segments do
        local a1 = math.rad((i / segments) * 360)
        local a2 = math.rad(((i + 1) / segments) * 360)

        local p1 = center + Vector(math.cos(a1) * radius, math.sin(a1) * radius, 4)
        local p2 = center + Vector(math.cos(a2) * radius, math.sin(a2) * radius, 4)

        local mid = (p1 + p2) / 2
        local dir = p2 - p1
        local length = dir:getLength()

        local holo = hologram.create(
            mid,
            dir:getAngle(),
            "models/holograms/cube.mdl",
            Vector(length / 13, 0.08, 0.02)
        )

        holo:setColor(Color(255, 0, 0, 180))
        holo:setMaterial("models/debug/debugwhite")

        table.insert(circleHolos, holo)
    end
end

local function explodeZombie(zombie)
    if not zombie or not zombie:isValid() then return end

    local pos = zombie:getPos()

    local barrel = prop.create(
        pos + Vector(0, 0, 35),
        Angle(0, 0, 0),
        barrelModel,
        true
    )

    if barrel and barrel:isValid() then
        timer.simple(0.15, function()
            if barrel and barrel:isValid() then
                barrel:ignite(1)
                barrel:applyDamage(9999)
            end
        end)
    end
end

hook.add("PlayerSay", "radius_command", function(ply, text)
    if ply ~= owner() then return end

    local args = string.explode(" ", text)

    if args[1] == "!radius" then
        local amount = tonumber(args[2])

        if not amount then
            print("Usage: !radius amount")
            return ""
        end

        radius = math.clamp(amount, 100, 5000)
        createCircle()

        print("Radius set to " .. radius)
        return ""
    end
end)

timer.create("zombie_scan", scanDelay, 0, function()
    local center = chip():getPos()
    local found = find.inSphere(center, radius)

    local spawnedThisScan = 0

    for _, ent in pairs(found) do
        if spawnedThisScan >= maxBarrelsPerScan then return end

        if isZombie(ent) and not triggered[ent] then
            triggered[ent] = true
            spawnedThisScan = spawnedThisScan + 1

            explodeZombie(ent)

            timer.simple(zombieCooldown, function()
                triggered[ent] = nil
            end)
        end
    end
end)

createCircle()

print("Zombie Barrel Circle Loaded")
print("Use !radius amount")
