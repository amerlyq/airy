-- vim:ft=lua:ts=2:sw=2:sts=2
-- Clip video from between two marks '[' and ']'
-- Seek to placed marks 'S-[' and 'S-]'
-- Convert by 'r.ffmpeg <path> <beg> <end>' on 'y'

local utils = require 'mp.utils'

clip_begin = 0.0
clip_end   = mp.get_property_native("length") or 0.0


-- Options
mp.set_property("hr-seek-framedrop", "no")
mp.set_property("options/keep-open", "always")
-- alas, the following setting seems to not take effect - needs
-- to be specified on the command line of mpv, instead:
mp.set_property("options/script-opts", "osc-layout=bottombar,osc-hidetimeout=-1")


-- Behaviour
function on_eof()
    mp.msg.log("info", "playback reached end of file")
    mp.set_property("pause", "yes")
    mp.commandv("seek", 100, "absolute-percent", "exact")
end
mp.register_event("eof-reached", on_eof)
-- Pause on open
-- function on_loaded() mp.set_property("pause", "yes") end
-- mp.register_event("file-loaded", on_loaded)

-- mp.osd_message("loaded", 3)
do return end

-- Implementation
function clip_rangemessage()
    local duration = clip_end - clip_begin
    local message = ""
    message = message .. "begin=" .. string.format("%4.3f", clip_begin) .. "s "
    message = message .. "end=" .. string.format("%4.3f", clip_end) .. "s "
    message = message .. "duration=" .. string.format("% 4.3f", duration) .. "s "
    return message
end

function clip_rangeinfo()
    local message = clip_rangemessage()
    mp.msg.log("info", message)
    mp.osd_message(message, 5)
end

function clip_mark_begin_handler()
    pt = mp.get_property_native("playback-time")

    -- at some later time, setting a/b markers might be used to visualize begin/end
    -- mp.set_property("ab-loop-a", pt)
    -- mp.set_property("loop", 999)

    clip_begin = pt
    if clip_begin > clip_end then
        clip_end = clip_begin
    end

    clip_rangeinfo()
end

function clip_mark_end_handler()
    pt = mp.get_property_native("playback-time")

    -- at some later time, setting a/b markers might be used to visualize begin/end
    -- mp.set_property("ab-loop-b", pt)
    -- mp.set_property("loop", 999)

    clip_end = pt
    if clip_end < clip_begin then
        clip_begin = clip_end
    end

    clip_rangeinfo()
end


function clip_write_handler()
    fname = "clip_13444.mp4"
    local duration = clip_end - clip_begin
    if duration == 0 then
        message = "clip_write: empty clip at=" .. clip_begin
        mp.osd_message(message, 3)
        return
    end

    local srcname = mp.get_property_native("path")

    local message = clip_rangemessage()
    message = message .. "writing excerpt of source file '" .. srcname .. "'\n"
    message = message .. "to destination file '" .. fname .. "'"
    mp.msg.log("info", message)
    mp.osd_message(message, 10)

    local p = {}
    p["cancellable"] = false
    p["args"] = {}
    p["args"][1] = "echo"  -- r.ffmpeg
    p["args"][2] = tostring(clip_begin)
    p["args"][3] = tostring(duration)
    p["args"][4] = tostring(srcname)
    p["args"][5] = tostring(fname)

    local res = utils.subprocess(p)

    if (res["error"] ~= nil) then
        local message = "failed to run clip_copy\nerror message: " .. res["error"]
        message = message .. "\nstatus = " .. res["status"] .. "\nstdout = " .. res["stdout"]
        mp.msg.log("error", message)
        mp.osd_message(message, 10)
    else
        mp.msg.log("info", "excerpt '" .. fname .. "' written.")
        message = message .. "... done."
        mp.osd_message(message, 10)
    end

    -- mp.commandv("run", "jimbobexcerpt_copy", clip_begin, duration, srcname, fname)
end

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


function h_seek(pos) return loadstring([[-- return function()
    mp.commandv("seek", ]] .. pos .. [[, "absolute", "exact")
end ]])(pos) end


function clip_test(kevent)
    mp.msg.log("info", tostring(kevent))
    for k,v in pairs(kevent) do
        mp.msg.log("info", "kevent[" .. k .. "] = " .. tostring(v))
    end

    mp.commandv("seek", 0.0, "absolute", "exact")
end

--
mp.add_key_binding("[", "clip_mark_begin", clip_mark_begin_handler)
mp.add_key_binding("]", "clip_mark_end", clip_mark_end_handler)
mp.add_key_binding("shift+[", "clip_seek_begin", h_seek(clip_begin))
mp.add_key_binding("shift+]", "clip_seek_end", h_seek(clip_end))
mp.add_key_binding("y", "clip_write", clip_write_handler)

mp.add_key_binding("right", "clip_frame_forward", clip_frame_forward, { repeatable = true; complex = true })

-- mp.add_key_binding("shift+mouse_btn3", "clip_test", clip_test, { repeatable = false; complex = true })
-- mp.add_key_binding("shift+mouse_btn4", "clip_test", clip_test, { repeatable = false; complex = true })
-- mp.add_key_binding("y", "clip_test", clip_test, { repeatable = false; complex = true })

return clip
