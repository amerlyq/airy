local THRESHOLD = 12
local SCAN_SPEED = 2.0
local BACKWARD_SEEK = 6.0
local IGNORE_NEAR_START = 0.4
local SCD_FILTER = "scd_filter"

local is_scanning = false
local start_time = 0
local target_direction = 1
local loop_timer = nil
local last_detected_boundary = nil
local last_score_time = 0

local original_speed = 1.0
local original_mute = "no"

local function filter_exists(label)
    for _, f in ipairs(mp.get_property_native("vf") or {}) do
        if f.label == label then
            return true
        end
    end
    return false
end

local function remove_filter()
    if filter_exists(SCD_FILTER) then
        mp.commandv("vf", "remove", "@" .. SCD_FILTER)
    end
end

local function terminate_and_restore(target_time, cancelled)
    if not is_scanning then return end
    is_scanning = false

    if loop_timer then
        loop_timer:kill()
        loop_timer = nil
    end

    remove_filter()
    mp.set_osd_ass(0, 0, "")

    mp.set_property_number("speed", original_speed)
    mp.set_property("mute", original_mute)
    mp.set_property("pause", "yes")

    if target_time and not cancelled then
        mp.commandv("seek", target_time, "absolute", "exact")
        mp.osd_message("Scene Boundary Found")
    else
        mp.osd_message("Scene Scan Cancelled")
    end
end

local function scd_score()
    local m = mp.get_property_native("vf-metadata/@" .. SCD_FILTER)
    local s = m and m["lavfi.scd.score"] or "0"
    return tonumber(s) or 0, tostring(s)
end

local function process_scan_tick()
    if not is_scanning then return end

    local t = mp.get_property_number("time-pos") or 0
    local score, score_str = scd_score()

    mp.set_osd_ass(0, 0, string.format(
        "{\\an7}{\\fs24}{\\b1}%s\\nSCD: %s / %d",
        target_direction == 1 and "Scanning Forward..." or "Scanning Backward...",
        score_str,
        THRESHOLD
    ))

    if score >= THRESHOLD
        and math.abs(t - start_time) > IGNORE_NEAR_START
        and math.abs(t - last_score_time) > IGNORE_NEAR_START
    then
        last_score_time = t

        if target_direction == 1 then
            terminate_and_restore(t, false)
            return
        elseif t < start_time - IGNORE_NEAR_START then
            last_detected_boundary = t
        end
    end

    if target_direction == -1 and t >= start_time - 0.05 then
        terminate_and_restore(last_detected_boundary, false)
    end
end

local function start_scan_playback()
    if not is_scanning then return end

    local filter_string =
        "@" .. SCD_FILTER .. ":lavfi=[hwdownload,format=nv12,scdet=s=1:t="
        .. tostring(THRESHOLD) .. "]"

    mp.commandv("vf", "append", filter_string)
    mp.set_property_number("speed", SCAN_SPEED)
    mp.set_property("pause", "no")

    loop_timer = mp.add_periodic_timer(0.01, process_scan_tick)
end

local function initiate_scan(direction)
    -- Second press cancels and restores speed/mute.
    if is_scanning then
        terminate_and_restore(nil, true)
        return
    end

    is_scanning = true
    target_direction = direction
    start_time = mp.get_property_number("time-pos") or 0
    last_detected_boundary = nil
    last_score_time = 0

    original_speed = mp.get_property_number("speed") or 1.0
    original_mute = mp.get_property("mute") or "no"

    mp.set_property("pause", "yes")
    mp.set_property("mute", "yes")

    remove_filter()

    if direction == 1 then
        mp.osd_message("Searching Forward...")
        start_scan_playback()
    else
        mp.osd_message("Searching Backward...")

        local rewind_target = math.max(0, start_time - BACKWARD_SEEK)
        mp.commandv("seek", rewind_target, "absolute", "exact")

        mp.add_timeout(0.2, start_scan_playback)
    end
end

mp.add_forced_key_binding("PGDWN", "scan-forward-key", function()
    initiate_scan(1)
end, {repeatable = false})

mp.add_forced_key_binding("PGUP", "scan-backward-key", function()
    initiate_scan(-1)
end, {repeatable = false})

mp.register_script_message("scan-forward", function()
    initiate_scan(1)
end)

mp.register_script_message("scan-backward", function()
    initiate_scan(-1)
end)

mp.register_event("shutdown", function()
    terminate_and_restore(nil, true)
end)
