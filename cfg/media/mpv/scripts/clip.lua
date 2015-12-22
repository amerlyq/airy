-- vim:ft=lua:ts=2:sw=2:sts=2
-- Clip video from between two marks '[' and ']'
-- Seek to placed marks 'S-[' and 'S-]'
-- Convert by 'r.ffmpeg <path> <beg> <end>' on 'y'

local utils = require 'mp.utils'
local g = { A = 0.0, B = mp.get_property_native("length") or 0.0 }

-- Options
mp.set_property("hr-seek-framedrop", "no")
mp.set_property("options/keep-open", "always")
-- alas, the following setting seems to not take effect - needs
-- to be specified on the command line of mpv, instead:
mp.set_property("options/script-opts", "osc-layout=bottombar,osc-hidetimeout=-1")


-- Behaviour
-- Pause on open and eof
function on_loaded() mp.set_property("pause", "yes") end
function on_eof()
    mp.msg.log("info", "playback reached end of file")
    mp.set_property("pause", "yes")
    mp.commandv("seek", 100, "absolute-percent", "exact")
end
-- mp.register_event("file-loaded", on_loaded)
mp.register_event("eof-reached", on_eof)


-- Helpers
local function nm(m) return 'clip_'..m end
local function show_status(t, msg)
  mp.msg.log(t, msg)
  mp.osd_message(t .. ": " .. msg, 2)
end


-- Implementation
-- at some later time, setting a/b markers might be used to visualize begin/end
-- mp.set_property("ab-loop-a", g.A)
-- mp.set_property("loop", 999)
function mark_update(m)
  show_status("info", string.format("[%s] % 4.3f  (%s - %s)",
    m, g.B - g.A, os.date("%M:%S", g.A), os.date("%M:%S", g.B)))
end
function h_mark_beg()
  g.A = mp.get_property_native("playback-time")
  g.B = math.max(g.A, g.B)
  mark_update('A')
end
function h_mark_end()
  g.B = mp.get_property_native("playback-time")
  g.A = math.min(g.A, g.B)
  mark_update('B')
end


-- function h_seek(pos) return loadstring([[return function()
--     mp.commandv("seek", ]] .. pos .. [[, "absolute", "exact")
-- end ]])(pos) end
function h_seek_beg()
  mp.set_property("pause", "yes")
  mp.commandv("seek", g.A, "absolute", "exact")
end
function h_seek_end()
  mp.set_property("pause", "yes")
  mp.commandv("seek", g.B, "absolute", "exact")
end

function h_write()
  if g.B - g.A == 0 then
    show_status("error", "can't encode empty clip at=" .. g.A)
    return
  end
  show_status("info", "sent to encoding")
  local res = utils.subprocess({
    cancellable = false, args = { "r.ffmpeg",
      tostring(mp.get_property_native("path")),
      tostring(g.A), tostring(g.B)
  }})
  if res["error"] ~= nil then
    show_status("error", "Failed("..res["error"]..") encoding: "..res["stdout"])
  else
    show_status("info", "Success encoding: "..res["stdout"])
  end
end

mp.add_forced_key_binding("y", nm("write"), h_write)
mp.add_forced_key_binding("[", nm("mark_beg"), h_mark_beg)
mp.add_forced_key_binding("]", nm("mark_end"), h_mark_end)
mp.add_forced_key_binding("{", nm("seek_beg"), h_seek_beg)
mp.add_forced_key_binding("}", nm("seek_end"), h_seek_end)


-- mp.osd_message("loaded", 3)
do return end -- Hack to return from script


-- assume some plausible frame time until property "fps" is set.
frame_time = 24.0 / 1001.0

function clip_fps_changed(name)
    ft = mp.get_property_native("fps")
    if ft ~= nil and ft > 0.0 then
        frame_time = 1.0 / ft
        -- mp.msg.log("info", "fps property changed to " .. ft .. " frame_time=" .. frame_time .. "s")
    end
end
mp.observe_property("fps", native, clip_fps_changed)


-- seeking
seek_account = 0.0
seek_keyframe = true

function clip_seek()
    local abs_sa = math.abs(seek_account)
    if abs_sa < (frame_time / 2.0) then
        seek_account = 0.0
        return -- no seek required
    end

    -- mp.msg.log("info", "seek_account = " .. seek_account)
    if (abs_sa >= 10.0) then
        -- for seeks above 10 seconds, always use coarse keyframe seek
        seek_account = 0.0
        mp.commandv("seek", seek_account, "relative", "keyframes")
        return
    end

    if ((abs_sa > 0.5) or seek_keyframe) then
        -- for small seeks, use exact seek (unless instructed otherwise by user)
        local s = seek_account
        seek_account = 0.0

        local mode = "exact"
        if seek_keyframe then
            mode = "keyframes"
        end

        mp.commandv("seek", s, "relative", mode)
        return
    end

    -- for tiny seeks, use frame steps
    local s = frame_time
    if (seek_account < 0.0) then
        s = -s
        mp.commandv("frame_back_step")
    else
        mp.commandv("frame_step")
    end
    seek_account = seek_account - s;
end

-- we have clip_seek called both periodically and
-- upon the display of yet another frame - this allows
-- to make "framewise" stepping with autorepeating keys to
-- work as smooth as possible
clip_seek_timer = mp.add_periodic_timer(0.1, clip_seek)
mp.register_event("tick", clip_seek)
-- (I have experimented with stopping the timer when possible,
--  but this didn't work out for strange reasons, got error
--  messages from the event loop.)


function check_key_release(kevent)
    -- mp.msg.log("info", tostring(kevent))
    -- for k,v in pairs(kevent) do
    --  mp.msg.log("info", "kevent[" .. k .. "] = " .. tostring(v))
    -- end

    if kevent["event"] == "up" then
        -- mp.msg.log("info", "key up detected")

        -- key was released, so we should immediately stop to do any seeking
        seek_account = 0.0

        -- and do a "zero-seek" to reset mpv's internal frame step counter:
        mp.commandv("seek", 0.0, "relative", "exact")
        mp.set_property("pause", "yes")
        return true
    end
    return false
end

function clip_frame_forward(kevent)
    if check_key_release(kevent) then
        return
    end

    seek_keyframe = false
    seek_account = seek_account + frame_time
end


-- mp.add_key_binding("right", "clip_frame_forward", clip_frame_forward, { repeatable = true; complex = true })

function clip_test(kevent)
    mp.msg.log("info", tostring(kevent))
    for k,v in pairs(kevent) do
        mp.msg.log("info", "kevent[" .. k .. "] = " .. tostring(v))
    end
    mp.commandv("seek", 0.0, "absolute", "exact")
end
mp.add_key_binding("y", "clip_test", clip_test, { repeatable = false; complex = true })
