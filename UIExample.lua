--@name Simple UI API Test
--@owneronly
--@client

if player() ~= owner() then return end

enableHud(owner(), true)

local UI = {}

UI.open = false
UI.draggingSlider = nil
UI.elements = {}

UI.w = 380
UI.h = 250

local rw, rh = render.getResolution()
UI.x = (rw - UI.w) / 2
UI.y = (rh - UI.h) / 2

UI.fontTitle = render.createFont("Roboto", 22, 700, true)
UI.fontText = render.createFont("Roboto", 16, 500, true)
UI.fontSmall = render.createFont("Roboto", 14, 500, true)

function UI.inBox(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function UI.outline(x, y, w, h, t)
    t = t or 1
    render.drawRect(x, y, w, t)
    render.drawRect(x, y + h - t, w, t)
    render.drawRect(x, y, t, h)
    render.drawRect(x + w - t, y, t, h)
end

function UI.addButton(id, text, x, y, w, h, callback)
    UI.elements[id] = {
        type = "button",
        text = text,
        x = x,
        y = y,
        w = w,
        h = h,
        callback = callback
    }
end

function UI.addSlider(id, text, x, y, w, min, max, value, callback)
    UI.elements[id] = {
        type = "slider",
        text = text,
        x = x,
        y = y,
        w = w,
        h = 35,
        min = min,
        max = max,
        value = value,
        callback = callback
    }
end

function UI.setSliderValue(e, mx)
    local frac = math.clamp((mx - (UI.x + e.x)) / e.w, 0, 1)
    local newValue = math.floor(e.min + frac * (e.max - e.min) + 0.5)

    if newValue ~= e.value then
        e.value = newValue

        if e.callback then
            e.callback(newValue)
        end
    end
end

function UI.drawButton(e)
    local x = UI.x + e.x
    local y = UI.y + e.y

    render.setColor(Color(35, 110, 55, 255))
    render.drawRect(x, y, e.w, e.h)

    render.setColor(Color(120, 255, 150))
    UI.outline(x, y, e.w, e.h, 2)

    render.setFont(UI.fontText)
    render.setColor(Color(255, 255, 255))
    render.drawText(x + e.w / 2, y + e.h / 2 - 8, e.text, 1)
end

function UI.drawSlider(e)
    local x = UI.x + e.x
    local y = UI.y + e.y

    render.setFont(UI.fontText)
    render.setColor(Color(255, 255, 255))
    render.drawText(x + e.w / 2, y - 22, e.text .. ": " .. e.value, 1)

    render.setColor(Color(45, 45, 45, 255))
    render.drawRect(x, y + 12, e.w, 6)

    local frac = (e.value - e.min) / (e.max - e.min)
    local knobX = x + frac * e.w

    render.setColor(Color(120, 255, 150))
    render.drawRect(x, y + 12, knobX - x, 6)

    render.setColor(Color(230, 230, 230))
    render.drawRect(knobX - 5, y + 4, 10, 22)
end

function UI.draw()
    if not UI.open then return end

    render.setColor(Color(15, 15, 15, 235))
    render.drawRect(UI.x, UI.y, UI.w, UI.h)

    render.setColor(Color(70, 220, 100, 255))
    UI.outline(UI.x, UI.y, UI.w, UI.h, 2)

    render.setFont(UI.fontTitle)
    render.setColor(Color(120, 255, 150))
    render.drawText(UI.x + UI.w / 2, UI.y + 16, "UI API TEST", 1)

    render.setColor(Color(255, 80, 80))
    render.drawRect(UI.x + UI.w - 30, UI.y + 8, 22, 22)

    render.setFont(UI.fontText)
    render.setColor(Color(255, 255, 255))
    render.drawText(UI.x + UI.w - 19, UI.y + 11, "X", 1)

    for _, e in pairs(UI.elements) do
        if e.type == "button" then
            UI.drawButton(e)
        elseif e.type == "slider" then
            UI.drawSlider(e)
        end
    end

    render.setFont(UI.fontSmall)
    render.setColor(Color(180, 180, 180))
    render.drawText(UI.x + UI.w / 2, UI.y + UI.h - 25, "Shift + G to open/close", 1)
end

function UI.click(mx, my)
    if UI.inBox(mx, my, UI.x + UI.w - 30, UI.y + 8, 22, 22) then
        UI.open = false
        UI.draggingSlider = nil
        input.enableCursor(false)
        return
    end

    for id, e in pairs(UI.elements) do
        local x = UI.x + e.x
        local y = UI.y + e.y

        if e.type == "button" then
            if UI.inBox(mx, my, x, y, e.w, e.h) then
                if e.callback then
                    e.callback()
                end
                return
            end
        elseif e.type == "slider" then
            if UI.inBox(mx, my, x, y, e.w, e.h) then
                UI.draggingSlider = id
                UI.setSliderValue(e, mx)
                return
            end
        end
    end
end

-- =========================
-- MAKE YOUR UI HERE
-- =========================

UI.addButton("testButton", "Test Button", 35, 75, 310, 42, function()
    print(Color(100, 255, 100), "Button pressed")
end)

UI.addSlider("testSlider", "Test Slider", 35, 160, 310, 0, 100, 50, function(value)
    print(Color(100, 255, 100), "Slider value: " .. value)
end)

-- =========================
-- HOOKS
-- =========================

hook.add("inputPressed", "SimpleUI_Open", function(key)
    if key == KEY.G and input.isKeyDown(KEY.LSHIFT) then
        UI.open = not UI.open
        input.enableCursor(UI.open)

        if not UI.open then
            UI.draggingSlider = nil
        end
    end
end)

hook.add("inputPressed", "SimpleUI_Click", function(key)
    if not UI.open or key ~= MOUSE.LEFT then return end

    local mx, my = input.getCursorPos()
    UI.click(mx, my)
end)

hook.add("inputReleased", "SimpleUI_Release", function(key)
    if key == MOUSE.LEFT then
        UI.draggingSlider = nil
    end
end)

hook.add("think", "SimpleUI_DragSlider", function()
    if not UI.open or not UI.draggingSlider then return end

    local e = UI.elements[UI.draggingSlider]
    if not e then return end

    local mx, my = input.getCursorPos()
    UI.setSliderValue(e, mx)
end)

hook.add("drawhud", "SimpleUI_Draw", function()
    UI.draw()
end)
