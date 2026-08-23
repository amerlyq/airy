-- Package incapsulation
local P = {}
clip = P

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
        -- no seek required
        return
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

function clip_frame_back(kevent)
    if check_key_release(kevent) then
        return
    end

    seek_keyframe = false
    seek_account = seek_account - frame_time
end

function clip_keyframe_forward(kevent)
    if check_key_release(kevent) then
        return
    end

    seek_keyframe = true
    seek_account = seek_account + 0.1
end

function clip_keyframe_back(kevent)
    if check_key_release(kevent) then
        return
    end

    seek_keyframe = true
    seek_account = seek_account - 0.1
end

function clip_seek_begin_handler()
    mp.commandv("seek", clip_begin, "absolute", "exact")
end

function clip_seek_end_handler()
    mp.commandv("seek", clip_end, "absolute", "exact")
end

-- zooming and panning

clip_zoom = 0.0
clip_zoom_increment_factor = 2 ^ 0.25

clip_pan_x = 0.0
clip_pan_y = 0.0

function clip_set_pan()
    local max_pan = 0.5 - (1.0 / ((clip_zoom+1.0)*2.0))

    if (clip_pan_x < -max_pan) then
        clip_pan_x = -max_pan
    end

    if (clip_pan_x > max_pan) then
        clip_pan_x = max_pan
    end

    if (clip_pan_y < -max_pan) then
        clip_pan_y = -max_pan
    end

    if (clip_pan_y > max_pan) then
        clip_pan_y = max_pan
    end

    mp.set_property("video-pan-x", clip_pan_x)
    mp.set_property("video-pan-y", clip_pan_y)
end

function clip_pan_right()
    clip_pan_x = clip_pan_x - (1.0 / (16*(clip_zoom+1.0)))
    clip_set_pan()
end

function clip_pan_left()
    clip_pan_x = clip_pan_x + (1.0 / (16*(clip_zoom+1.0)))
    clip_set_pan()
end

function clip_pan_down()
    clip_pan_y = clip_pan_y - (1.0 / (16*(clip_zoom+1.0)))
    clip_set_pan()
end

function clip_pan_up()
    clip_pan_y = clip_pan_y + (1.0 / (16*(clip_zoom+1.0)))
    clip_set_pan()
end

function clip_zoominfo()
    local message = "Zoom factor = " .. string.format("%4.2f", 1.0+clip_zoom)
    mp.osd_message(message, 3)
end

function clip_zoom_in()
    clip_zoom = ((1.0 + clip_zoom) * clip_zoom_increment_factor) - 1.0
    if (clip_zoom > 15.0) then
        clip_zoom = 15.0
    end

    local i = math.floor(clip_zoom+0.5)

    if (i >= 1 and math.abs(clip_zoom - i) < 0.01) then
        -- snap to integer zoom factors when less than 1% away from them
        clip_zoom = i
    end

    clip_set_pan()
    mp.set_property("video-zoom", clip_zoom)

    clip_zoominfo()
end

function clip_zoom_out()
    clip_zoom = ((1.0 + clip_zoom) / clip_zoom_increment_factor) - 1.0
    if (clip_zoom < 0.0) then
        clip_zoom = 0.0
    end

    local i = math.floor(clip_zoom+0.5)

    if (i >= 1 and math.abs(clip_zoom - i) < 0.01) then
        -- snap to integer zoom factors when less than 1% away from them
        clip_zoom = i
    end

    clip_set_pan()
    mp.set_property("video-zoom", clip_zoom)

    clip_zoominfo()
end


-- things to do whenever a new file was loaded:

function clip_on_loaded()
    -- pause play right after loading a file
    mp.set_property("pause", "yes")

    clip_zoom = 0.0
    mp.set_property("video-zoom", clip_zoom)

    clip_pan_x = 0.0
    clip_pan_y = 0.0
    clip_set_pan()
end

mp.register_event("file-loaded", clip_on_loaded)

--

function clip_test(kevent)
    mp.msg.log("info", tostring(kevent))
    for k,v in pairs(kevent) do
        mp.msg.log("info", "kevent[" .. k .. "] = " .. tostring(v))
    end

    mp.commandv("seek", 0.0, "absolute", "exact")

end

--

mp.add_key_binding("shift+right", "clip_keyframe_forward", clip_keyframe_forward, { repeatable = true; complex = true })
mp.add_key_binding("shift+left", "clip_keyframe_back", clip_keyframe_back, { repeatable = true; complex = true })
mp.add_key_binding("right", "clip_frame_forward", clip_frame_forward, { repeatable = true; complex = true })
mp.add_key_binding("left", "clip_frame_back", clip_frame_back, { repeatable = true; complex = true })

-- mp.add_key_binding("shift+mouse_btn3", "clip_test", clip_test, { repeatable = false; complex = true })
-- mp.add_key_binding("shift+mouse_btn4", "clip_test", clip_test, { repeatable = false; complex = true })
-- mp.add_key_binding("y", "clip_test", clip_test, { repeatable = false; complex = true })


return clip
