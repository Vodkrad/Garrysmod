--@name Chat Flag Pole
--@author Jesus Christ
--@shared

local Flags = {
    mw2 = "https://i.imgur.com/CdJQDfJ.jpeg",
    belarus = "https://i.imgur.com/XUxgnEu.png",
    ukraine = "https://i.imgur.com/8fRiqWN.jpg",
    russia = "https://i.imgur.com/jR2vDAC.png",
    kazakstan = "https://i.imgur.com/X8qwcdG.png",
    ussr = "https://i.imgur.com/EoGidlr.png",
    american = "https://i.imgur.com/88D20j2.jpg",
    china = "https://i.imgur.com/K6EG35s.png",
    canada = "https://www.flagcolorcodes.com/data/flag-of-canada.png"
}

local GitBase = "https://raw.githubusercontent.com/Vodkrad/Garrysmod/main/Flags/"

if SERVER then

    print("Updated by stonerrabit do !flags for a list of commands")

    hook.add("PlayerSay", "flag_chat_command", function(ply, text)

        if ply ~= owner() then return end

        local lower = string.lower(text)

        if lower == "!flags" then
            print("Flags: mw2, belarus, ukraine, russia, kazakstan, ussr, american, china, canada")
            print("Commands:")
            print("!flag canada")
            print("!url https://image.png")
            print("!git bfg")
            print("!rotate")
            print("!resetrotate")
            print("!windspeed 5")
            return ""
        end

        if string.sub(lower, 1, 6) == "!flag " then

            local name = string.sub(lower, 7)

            if Flags[name] then

                net.start("change_flag")
                net.writeString(name)
                net.writeString(Flags[name])
                net.send()

                print("Loaded flag for everyone: " .. name)

            else

                print("Unknown flag: " .. name)

            end

            return ""
        end

        if string.sub(lower, 1, 5) == "!url " then

            local realURL = string.sub(text, 6)

            net.start("change_flag")
            net.writeString("custom")
            net.writeString(realURL)
            net.send()

            print("Loaded custom URL for everyone")

            return ""
        end

        if string.sub(lower, 1, 5) == "!git " then

            local file = string.sub(text, 6)

            -- AUTO ADD .PNG
            file = file .. ".png"

            local finalURL = GitBase .. file

            net.start("change_flag")
            net.writeString("git:" .. file)
            net.writeString(finalURL)
            net.send()

            print("Loaded github flag for everyone")
            print(finalURL)

            return ""
        end

        if lower == "!rotate" then

            net.start("rotate_image")
            net.send()

            print("Rotated image 90 degrees right")

            return ""
        end

        if lower == "!resetrotate" then

            net.start("reset_rotate_image")
            net.send()

            print("Image rotation reset")

            return ""
        end

        if string.sub(lower, 1, 11) == "!windspeed " then

            local amount = tonumber(string.sub(text, 12)) or 1

            net.start("set_windspeed")
            net.writeFloat(amount)
            net.send()

            print("Set windspeed to " .. amount)

            return ""
        end

    end)

end

if CLIENT then

    local FlagAng = Angle(180, 0, 0)

    local BoneScale = Vector(4, 0.0001, 0.0001)
    local BoneHeight = 1
    local Height = 80

    local BaseRotation = -90
    local ImageRotation = 0
    local WindSpeed = 1

    local CurrentName = "mw2"
    local CurrentURL = Flags.mw2

    local HFlagObbSize = Vector(
        1.000054359436,
        10.000041007996,
        80.000022888184
    )

    local FlagModel = "models/pac/jiggle/base_cloth_4.mdl"

    local mat = material.create("UnlitGeneric")
    mat:setInt("$flags", 256)

    local function applyImageRotation()

        local matrix = Matrix()

        matrix:translate(Vector(0.5, 0.5, 0))
        matrix:rotate(Angle(0, ImageRotation, 0))
        matrix:translate(Vector(-0.5, -0.5, 0))

        mat:setMatrix("$basetexturetransform", matrix)

    end

    local HPole = holograms.create(
        chip():localToWorld(Vector(0,0,42.231)),
        chip():getAngles(),
        "models/sprops/cylinders/size_1/cylinder_1_5x54.mdl",
        Vector(0.6,0.6,1.6)
    )

    HPole:setMaterial("gigaconvertedmats/building_template009e")
    HPole:setParent(chip())

    local HPoleCap = holograms.create(
        chip():localToWorld(Vector(0,0,86)),
        chip():getAngles(),
        "models/sprops/geometry/sphere_24.mdl",
        Vector(0.075,0.075,0.075)
    )

    HPoleCap:setMaterial("debug/env_cubemap_model")
    HPoleCap:setParent(chip())

    local HFlag = holograms.create(
        chip():localToWorld(Vector(0,-2,65)),
        chip():localToWorldAngles(Angle(0,0,BaseRotation)),
        FlagModel,
        Vector(1)
    )

    HFlag:setParent(chip())
    HFlag:setMaterial("brick/brick_model")

    for i = 0, HFlag:getBoneCount() - 1 do

        HFlag:manipulateBoneScale(i, BoneScale)
        HFlag:manipulateBonePosition(i, Vector(0,0,BoneHeight))

    end

    local function loadFlagTexture(name, url)

        CurrentName = name
        CurrentURL = url

        mat:setTextureURL("$basetexture", url, function(m, u, w, h, l)

            if not m then

                print("Failed to load image")
                print(url)

                return

            end

            l(0, 0, m:getWidth(), m:getHeight())

            applyImageRotation()

            HFlag:setMaterial("!" .. mat:getName())

            print("Loaded image: " .. CurrentName)

        end)

    end

    loadFlagTexture(CurrentName, CurrentURL)

    net.receive("change_flag", function()

        local name = net.readString()
        local url = net.readString()

        loadFlagTexture(name, url)

    end)

    net.receive("rotate_image", function()

        ImageRotation = ImageRotation + 90

        if ImageRotation >= 360 then
            ImageRotation = 0
        end

        applyImageRotation()

        HFlag:setMaterial("!" .. mat:getName())

    end)

    net.receive("reset_rotate_image", function()

        ImageRotation = 0

        applyImageRotation()

        HFlag:setMaterial("!" .. mat:getName())

    end)

    net.receive("set_windspeed", function()

        WindSpeed = net.readFloat()

    end)

    hook.add("drawhud", "flag_hud", function()

        render.setColor(Color(255,255,255))

        render.drawText(50,50,"Commands:",0)
        render.drawText(50,70,"!flags",0)
        render.drawText(50,90,"!flag canada",0)
        render.drawText(50,110,"!url https://image.png",0)
        render.drawText(50,130,"!git bfg",0)
        render.drawText(50,150,"!rotate",0)
        render.drawText(50,170,"!resetrotate",0)
        render.drawText(50,190,"!windspeed 5",0)
        render.drawText(50,210,"Current: "..CurrentName,0)
        render.drawText(50,230,"Rotation: "..ImageRotation,0)
        render.drawText(50,250,"WindSpeed: "..WindSpeed,0)

    end)

    timer.create("tick", 0.01, 0, function()

        local t = timer.curtime()

        HFlag:setPos(chip():localToWorld(Vector(
            math.sin(t * 2 * WindSpeed) * 2,
            math.sin(t * 3 * WindSpeed) * 2,
            (Height - HFlagObbSize.z / 4)
            + math.sin(t * 4 * WindSpeed) * 2
        )))

        HFlag:setAngles(
            chip():localToWorldAngles(
                FlagAng + Angle(
                    180,
                    math.sin(t * WindSpeed) * 45,
                    BaseRotation
                )
            )
        )

    end)

end
