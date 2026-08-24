local options = require 'mp.options'

-- Define a custom flag. By default, it is 'no' (false)
local user_configs = {
    stitch = false
}
-- Read variables passed from the command line (--script-opts)
options.read_options(user_configs, "hstack")

-- Persistent cache for track dimensions
local native_h1 = nil
local native_h2 = nil

-- Capture track dimensions safely
local function initialize_dimensions()
    native_h1 = mp.get_property_number("video-params/h")
    native_h2 = nil

    local track_list = mp.get_property_native("track-list") or {}
    local video_track_count = 0

    for _, track in ipairs(track_list) do
        if track.type == "video" then
            video_track_count = video_track_count + 1
            if video_track_count == 2 then
                native_h2 = track["demux-h"] or track["height"]
                break
            end
        end
    end
    return (native_h1 ~= nil and native_h2 ~= nil)
end

-- Core layout function
local function apply_smart_hstack(force_enable)
    local has_two_tracks = initialize_dimensions()

    if not has_two_tracks then
        if not force_enable then
            mp.osd_message("Error: No external video track found")
        end
        return false
    end

    local current_filter = mp.get_property("lavfi-complex") or ""

    -- Toggle logic (unless force_enable is true for startup)
    if not force_enable and current_filter:find("hstack") then
        mp.set_property("lavfi-complex", "[vid1] copy [vo]")
        mp.osd_message("Stitch Disabled (Showing Video 1)")
    else
        if native_h1 == native_h2 then
            -- Zero Performance Cost: Perfect native height match
            mp.set_property("lavfi-complex", "[vid1][vid2]hstack[vo]")
        elseif native_h1 > native_h2 then
            -- Pad smaller Video 2 up to Video 1 height with zero per-frame cost
            mp.set_property("lavfi-complex", string.format("[vid2]pad=eval=init:w=iw:h=%d:x=0:y=0[v2_p]; [vid1][v2_p]hstack[vo]", native_h1))
        else
            -- Pad smaller Video 1 up to Video 2 height with zero per-frame cost
            mp.set_property("lavfi-complex", string.format("[vid1]pad=eval=init:w=iw:h=%d:x=0:y=0[v1_p]; [v1_p][vid2]hstack[vo]", native_h2))
        end
    end
    return true
end

-- Startup Handler
mp.register_event("file-loaded", function()
    native_h1 = nil
    native_h2 = nil

    -- ONLY auto-activate on startup if the user explicitly provided our custom flag
    if user_configs.stitch then
        mp.add_timeout(0.2, function()
            apply_smart_hstack(true)
        end)
    end
end)

-- Bind manual toggle to the 'b' key (always works when 2 tracks exist)
mp.add_forced_key_binding("b", "smart_hstack_toggle", function()
    apply_smart_hstack(false)
end)



-----------------------------------------------------------------

local offsets = {}       -- [slot] = offset_ms, slot is 1 or 2
local current_slot = 1

local function apply_offset()
    local ms = offsets[current_slot] or 0
    if ms == 0 then
        pcall(function() mp.commandv("vf", "remove", "@v_offset") end)
    else
        -- slow: local expr = string.format("(PTS-STARTPTS)%+.6f/TB", ms / 1000)
        -- WTF: progresses on toggle
        local expr = string.format("PTS%+.6f/TB", ms / 1000)
        mp.commandv("vf", "add", "@v_offset:lavfi=[setpts='" .. expr .. "']")
    end
end

local function nudge(delta_ms)
    offsets[current_slot] = (offsets[current_slot] or 0) + delta_ms
    apply_offset()
    mp.osd_message(string.format("slot %d offset = %+d ms", current_slot, offsets[current_slot]))
end

mp.add_key_binding("-", "offset-minus", function() nudge(-1) end)
mp.add_key_binding("=", "offset-plus", function() nudge(1) end)
-- mp.add_key_binding("+", "offset-plus", function() nudge(1) end)
mp.add_key_binding("0", "offset-clear", function()
    offsets[current_slot] = 0
    apply_offset()
    mp.osd_message("slot " .. current_slot .. " offset cleared")
end)

mp.add_key_binding("v", "toggle-slot-and-offset", function()
    mp.command('cycle-values lavfi-complex "[vid2] copy [vo]; [aid2] anull [ao]" "[vid1] copy [vo]; [aid1] anull [ao]"')
    mp.command('cycle-values force-media-title "(2) ${track-list/2/title}" "(1) ${filename}"')
    -- mp.command('frame-back-step')
    -- mp.command('frame-step')
    -- mp.command('cycle-values vid 2 1')
    -- mp.command('seek 0 relative+exact')
    current_slot = (current_slot == 1) and 2 or 1
    -- local off = (offsets[current_slot] or 0) / 1000
    -- if off ~= 0 then
    --     mp.commandv("seek", tostring(off), "relative+exact")
    -- end
    -- mp.osd_message(string.format("slot %d, offset %+dms", current_slot, offsets[current_slot] or 0))
    apply_offset()
end)
