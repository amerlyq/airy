local options = require 'mp.options'

-- Define a custom flag. By default, it is 'no' (false)
local user_configs = { stitch = false }
-- Read variables passed from the command line (--script-opts)
options.read_options(user_configs, "hstack")

local G1 = "[vid1] copy [vo]; [aid1] anull [ao]"
local G2 = "[vid2] copy [vo]; [aid2] anull [ao]"

---------------------------------------------------------------- helpers

local function second_video_track()
    local n = 0
    for _, t in ipairs(mp.get_property_native("track-list") or {}) do
        if t.type == "video" then
            n = n + 1
            if n == 2 then return t end
        end
    end
end

local function has_vf(label)
    for _, f in ipairs(mp.get_property_native("vf") or {}) do
        if f.label == label then return true end
    end
    return false
end

local function set_graph(graph)
    mp.set_property("lavfi-complex", graph)
end

-- slow: re-decode from keyframe to current pos (fixes dav1d OBU errors after stitch change)
local function refresh()
    local pos = mp.get_property_number("time-pos")
    if pos then mp.commandv("seek", tostring(pos), "absolute+exact") end
end

---------------------------------------------------------------- offset

local offsets = {}       -- [slot] = offset_ms
local current_slot = 1

local function apply_offset()
    if has_vf("v_offset") then
        mp.commandv("vf", "remove", "@v_offset")
    end
    local ms = offsets[current_slot] or 0
    if ms ~= 0 then
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

---------------------------------------------------------------- stitch

local function apply_smart_hstack(force_enable)
    local h1 = mp.get_property_number("video-params/h")
    local t2 = second_video_track()
    local h2 = t2 and (t2["demux-h"] or t2["height"])

    if not (h1 and h2) then
        if not force_enable then
            mp.osd_message("Error: No external video track found")
        end
        return
    end

    local cur = mp.get_property("lavfi-complex") or ""

    if not force_enable and cur:find("hstack") then
        set_graph(G1)
        current_slot = 1
        mp.osd_message("Stitch Disabled (Showing Video 1)")
    elseif h1 == h2 then
        set_graph("[vid1][vid2]hstack[vo]; [aid1] anull [ao]")
    elseif h1 > h2 then
        set_graph(string.format(
            "[vid2]pad=eval=init:w=iw:h=%d:x=0:y=0[v2_p]; [vid1][v2_p]hstack[vo]; [aid1] anull [ao]", h1))
    else
        set_graph(string.format(
            "[vid1]pad=eval=init:w=iw:h=%d:x=0:y=0[v1_p]; [v1_p][vid2]hstack[vo]; [aid1] anull [ao]", h2))
    end
    refresh()
    apply_offset()
end

mp.register_event("file-loaded", function()
    current_slot = 1
    if user_configs.stitch then
        mp.add_timeout(0.2, function() apply_smart_hstack(true) end)
    end
end)

mp.add_forced_key_binding("b", "hstack-toggle", function() apply_smart_hstack(false) end)
mp.add_forced_key_binding("N", "hstack-enable", function() apply_smart_hstack(true) end)

---------------------------------------------------------------- switch

-- local function switch()
--     mp.command('cycle-values lavfi-complex "[vid2] copy [vo]; [aid2] anull [ao]" "[vid1] copy [vo]; [aid1] anull [ao]"')
--     mp.command('cycle-values force-media-title "(2) ${track-list/2/title}" "(1) ${filename}"')
--     -- mp.command('frame-back-step')
--     -- mp.command('frame-step')
--     -- mp.command('cycle-values vid 2 1')
--     -- mp.command('seek 0 relative+exact')
--     current_slot = (current_slot == 1) and 2 or 1
--     -- local off = (offsets[current_slot] or 0) / 1000
--     -- if off ~= 0 then
--     --     mp.commandv("seek", tostring(off), "relative+exact")
--     -- end
--     -- mp.osd_message(string.format("slot %d, offset %+dms", current_slot, offsets[current_slot] or 0))
--     apply_offset()
-- end

local function switch()
    local cur = mp.get_property("lavfi-complex") or ""
    local to2 = not cur:find("%[vid2%] copy", 1, false)  -- hstack or slot 1 -> slot 2
    local t2 = second_video_track()

    set_graph(to2 and G2 or G1)
    mp.set_property("force-media-title",
        to2 and ("(2) " .. ((t2 and (t2.title or t2["external-filename"])) or "video 2"))
             or ("(1) " .. (mp.get_property("filename") or "")))
    current_slot = to2 and 2 or 1
    apply_offset()
    mp.osd_message(string.format("slot %d, offset %+d ms", current_slot, offsets[current_slot] or 0))
end

mp.add_key_binding("v", "switch-v", switch)
mp.add_key_binding("n", "switch-n", switch)
