-- vim:ft=lua:ts=2:sw=2:sts=2
--%USAGE:
--% * Clip video from between two marks '[' and ']'
--% * Seek to placed marks 'S-[' and 'S-]'
--% * Convert by 'r.ffmpeg <path> <beg> <end>' on 'y'
--%

local g = { A = 0.0, B = 0.0 }

-- Options
-- mp.set_property("hr-seek-framedrop", "no")
-- mp.set_property("options/keep-open", "always")
-- NOTE: always show OSD
-- mp.set_property("options/script-opts", "osc-layout=bottombar,osc-hidetimeout=-1")


-- Behaviour
-- Pause on open and eof
function on_loaded()
  -- mp.set_property("pause", "yes")
  g.B = mp.get_property_number("duration/full")
end
function on_eof()
    mp.msg.log("info", "playback reached end of file")
    mp.set_property("pause", "yes")
    mp.commandv("seek", 100, "absolute-percent", "exact")
end
mp.register_event("file-loaded", on_loaded)
mp.register_event("eof-reached", on_eof)

-- FIXED: show progressbar on startup
-- ALT:(mpv.conf): script-opts-add=osc-visibility=always
-- mp.register_event("file-loaded", function()
--     mp.commandv("script-message", "osc-visibility", "always", "no-osd")
--     -- local hasvid = mp.get_property_osd("video") ~= "no"
--     -- mp.commandv("script-message", "osc-visibility", (hasvid and "auto" or "always"), "no-osd")
--     -- mp.commandv("set", "options/osd-bar", (hasvid and "yes" or "no"))
-- end)


-- Helpers
local function show_status(t, msg)
  mp.msg.log(t, msg)
  mp.osd_message(t .. ": " .. msg, 2)
end


-- Implementation
-- at some later time, setting a/b markers might be used to visualize begin/end
-- mp.set_property("ab-loop-a", g.A)
-- mp.set_property("loop", 999)
function to_ffmpeg_sfx(t)
  -- ALT: os.date("%M:%S", g.A)
  return string.format("%02d:%02d.%d", math.floor(t/60), math.floor(t%60), math.floor((t-math.floor(t))*10))
end
function mark_update(m)
  show_status("info", string.format("[%s] dt=%4.3f  (%s - %s)",
    m, g.B - g.A, to_ffmpeg_sfx(g.A), to_ffmpeg_sfx(g.B)))
end
function h_mark_beg()
  g.A = mp.get_property_number("playback-time")
  -- print(g.A)
  g.B = math.max(g.A, g.B)
  -- HACK: loop the snippet; clear it manually
  mp.set_property("ab-loop-a", g.A)
  mp.set_property("ab-loop-b", g.B)
  mark_update('<')
end
function h_mark_end()
  g.B = mp.get_property_number("playback-time")
  -- print(g.B)
  g.A = math.min(g.A, g.B)
  mp.set_property("ab-loop-a", g.A)
  mp.set_property("ab-loop-b", g.B)
  mark_update('>')
end


-- function h_seek(pos) return loadstring([[return function()
--     mp.commandv("seek", ]] .. pos .. [[, "absolute", "exact")
-- end ]])(pos) end
function h_seek(begend,kfrxct)
  mp.set_property("pause", "yes")
  local ats, flg, m
  if (begend == 1) then ats,m=g.B,'>' else ats,m=g.A,'<' end
  if (kfrxct == 1) then flg="exact" else flg="keyframes" end
  mp.commandv("seek", ats, "absolute", flg)
  show_status("info", string.format("seek %s%4.3f (%s) -> got %4.3f",
    m, ats, flg, mp.get_property_number("playback-time")))
  if (begend == 1) then mp.set_property("ab-loop-b", "no") end
end

function h_write(mode)
  if g.B - g.A == 0 then
    show_status("error", "can't encode empty clip at=" .. g.A)
    return
  end
  show_status("info", string.format("encoding '%s' dt=%4.3f", mode, g.B - g.A))
  -- [_] BET: create hidden tmux session to allow parallel enconding

  mp.set_property("ab-loop-a", "no")
  mp.set_property("ab-loop-b", "no")
  local r = mp.command_native({
      name = "subprocess",
      playback_only = false,
      capture_stdout = true,
      capture_stderr = true,
      args = { "r.ffmpeg",
        tostring(mp.get_property_native("path")),
        tostring(g.A), tostring(g.B), mode
  }})
  if r.status == 0 then
    -- TODO: show how much time passed
    show_status("info", string.format("Success encoding: %d", r.status))
  else
    show_status("error", string.format("Failed(%d) encoding: %s", r.status, r.stderr))
  end
end

function h_move()
  show_status("info", "moving to...")
  -- FIXME if press <Esc> -- show "Cancelled"
  local res = utils.subprocess({
    cancellable = false, args = { "r.mpv-category",
      tostring(mp.get_property_native("path"))
  }})
  if res["error"] ~= nil then
    show_status("error", "Failed("..res["error"]..") moving: "..res["stdout"])
  else
    show_status("info", "Moved OK:"..res["stdout"])
    mp.commandv("playlist-next", "force")
  end
end

mp.add_key_binding("", "clip_write_fast", (function() return h_write('fast') end))  -- y
mp.add_key_binding("", "clip_write_copy", (function() return h_write('copy') end))  -- Y
mp.add_key_binding("", "clip_moving",   h_move)       -- m
mp.add_key_binding("", "clip_mark_beg", h_mark_beg)   -- [
mp.add_key_binding("", "clip_mark_end", h_mark_end)   -- ]
-- ALT: jump and mark to keyframe
mp.add_key_binding("", "clip_seek_beg", (function() return h_seek(0,1) end))  -- {
mp.add_key_binding("", "clip_seek_end", (function() return h_seek(1,1) end))  -- }
mp.add_key_binding("", "clip_seek_kfb", (function() return h_seek(0,0) end))  -- <
mp.add_key_binding("", "clip_seek_kfe", (function() return h_seek(1,0) end))  -- >


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
