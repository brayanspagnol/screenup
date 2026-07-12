local mp = require("mp")

local hide_timer = nil
local animation_timer = nil
local last_mouse = nil
local visible = false
local opacity = 0
local target_opacity = 0

local ANIMATION_STEP = 0.18
local ANIMATION_INTERVAL = 0.016

local function zone_for_mouse()
    local width = mp.get_property_number("osd-width", 0)

    if not last_mouse or width <= 0 then
        return "center"
    end

    -- Controls are rendered at 18%, 50% and 82%. These boundaries use
    -- the halfway points between them, so the pause area is truly central.
    if last_mouse.x < width * 0.34 then
        return "left"
    elseif last_mouse.x > width * 0.66 then
        return "right"
    end

    return "center"
end

local function ass_escape(text)
    return text:gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}")
end

local function alpha_from_opacity(value)
    local alpha = math.max(0, math.min(255, math.floor(255 - (value * 255))))
    return string.format("&H%02X&", alpha)
end

local function draw_button(x, y, symbol, icon_size, alpha)
    local symbol_y = y

    return string.format(
        "{\\an5\\pos(%d,%d)\\fnDejaVu Sans\\fs%d\\b1\\bord0\\shad0\\1a%s\\1c&HFFFFFF&}%s",
        x,
        symbol_y,
        icon_size,
        alpha,
        ass_escape(symbol)
    )
end

local function render_overlay()
    local width = mp.get_property_number("osd-width", 0)
    local height = mp.get_property_number("osd-height", 0)

    if width <= 0 or height <= 0 then
        return
    end

    local icon_size = math.max(56, math.min(88, math.floor(math.min(width, height) * 0.26)))
    local y = math.floor(height / 2)
    local paused = mp.get_property_bool("pause", false)
    local center_symbol = paused and "▶" or "Ⅱ"
    local alpha = alpha_from_opacity(opacity)
    local ass = table.concat({
        draw_button(math.floor(width * 0.18), y, "‹‹", icon_size, alpha),
        draw_button(math.floor(width * 0.50), y, center_symbol, icon_size, alpha),
        draw_button(math.floor(width * 0.82), y, "››", icon_size, alpha),
    }, "\n")

    mp.set_osd_ass(width, height, ass)
    visible = true
end

local function clear_overlay()
    local width = mp.get_property_number("osd-width", 0)
    local height = mp.get_property_number("osd-height", 0)
    mp.set_osd_ass(width, height, "")
    visible = false
end

local function stop_animation()
    if animation_timer then
        animation_timer:kill()
        animation_timer = nil
    end
end

local function animate_overlay()
    local delta = target_opacity - opacity

    if math.abs(delta) <= ANIMATION_STEP then
        opacity = target_opacity
        render_overlay()

        if opacity <= 0 then
            clear_overlay()
        end

        stop_animation()
        return
    end

    if delta > 0 then
        opacity = opacity + ANIMATION_STEP
    else
        opacity = opacity - ANIMATION_STEP
    end

    render_overlay()
end

local function start_animation(target)
    target_opacity = target
    stop_animation()
    animation_timer = mp.add_periodic_timer(ANIMATION_INTERVAL, animate_overlay)
    animate_overlay()
end

local function schedule_hide()
    if hide_timer then
        hide_timer:kill()
    end

    hide_timer = mp.add_timeout(2.4, function()
        start_animation(0)
    end)
end

local function show_overlay()
    last_mouse = mp.get_property_native("mouse-pos")
    start_animation(1)
    schedule_hide()
end

local function click_overlay()
    last_mouse = mp.get_property_native("mouse-pos")
    local zone = zone_for_mouse()

    if zone == "left" then
        mp.commandv("seek", "-10", "relative", "keyframes")
    elseif zone == "right" then
        mp.commandv("seek", "10", "relative", "keyframes")
    else
        mp.commandv("cycle", "pause")
    end

    start_animation(1)
    schedule_hide()
end

mp.add_forced_key_binding("mouse_move", "screenup-show-controls", show_overlay)
mp.add_forced_key_binding("MBTN_LEFT", "screenup-click-controls", click_overlay)

mp.observe_property("pause", "bool", function()
    if visible then
        render_overlay()
    end
end)
