-- vim:ft=lua:ts=2:sw=2:sts=2
--%USAGE:
--% * Mark '[' / ']' and seek to marks with 'S-[' / 'S-]'.
--% * Thumbnails show first/last frames for the selected copy/fast/smart mode.
--% * A different export key first switches previews; press again to export.
--% * Lossy boundary samples match frame selection, not full-encode compression.
--%DEBUG: mpv --msg-level=clip=debug yourfile.mkv

local g = { A = 0.0, B = 0.0 }
local utils = require 'mp.utils'
local options = { converter = "r.ffmpeg", preview_mode = "copy", preview_window_limit = 30 }
require('mp.options').read_options(options, 'clip')
local valid_mode = { copy = true, fast = true, smart = true }
local preview_mode = valid_mode[options.preview_mode] and options.preview_mode or "copy"
local OVERLAY_ID = { A = 1, B = 2 }
local PREVIEW_WINDOW_S = 2
local PREVIEW_FRACTION = 0.20
local PAD = 10
local previews = { A = { generation = 0 }, B = { generation = 0 } }
local jobs = {}
local mark_set = { A = false, B = false }
local previews_hidden = false

local function show_status(level, message)
  mp.msg.log(level, message)
  mp.osd_message(level .. ": " .. message, 2)
end

local function finite(t)
  return type(t) == "number" and t == t and math.abs(t) < math.huge
end

local function source_path()
  local path = mp.get_property("path")
  if not path then return nil end
  if not path:match("^/") and not path:match("^%a[%w+.-]*://") then
    path = utils.join_path(mp.get_property("working-directory"), path)
  end
  return path
end

-- Use display dimensions (rotation and sample aspect ratio already applied).
-- Keep both portrait thumbnails on screen, even in short windows.
local function preview_geometry(which)
  local dims = mp.get_property_native("osd-dimensions")
  local vw = mp.get_property_number("dwidth")
  local vh = mp.get_property_number("dheight")
  if not dims or not vw or not vh or vw <= 0 or vh <= 0 then return end
  local aw = dims.w - (dims.ml or 0) - (dims.mr or 0)
  local ah = dims.h - (dims.mt or 0) - (dims.mb or 0)
  local ratio = vw / vh
  local w, h, x, y
  if vh > vw then
    w = math.min(aw * PREVIEW_FRACTION, (dims.h - 3 * PAD) / 2 * ratio)
    h = w / ratio
    x = dims.w - w - PAD
    y = PAD + (which == 'B' and h + PAD or 0)
  else
    h = math.min(ah * PREVIEW_FRACTION, (dims.w - 3 * PAD) / 2 / ratio)
    w = h * ratio
    x = PAD + (which == 'B' and w + PAD or 0)
    y = PAD
  end
  if w < 16 or h < 16 then return end
  return math.floor(x), math.floor(y), math.floor(w), math.floor(h)
end

local function remove_overlay(which)
  previews[which].shown = false
  mp.command_native({ name = "overlay-remove", id = OVERLAY_ID[which] })
end

local function cleanup(job)
  if job then
    os.remove(job.clip)
    os.remove(job.clip .. ".segment.mp4")
    os.remove(job.raw)
    jobs[job] = nil
  end
end

-- Invalidate immediately, before debounce. Aborting is asynchronous: each job
-- owns separate files until its callback, so an old writer cannot corrupt a
-- newer thumbnail (or another mpv instance).
local function cancel_preview(which, discard)
  local state = previews[which]
  state.generation = state.generation + 1
  if state.timer then state.timer:kill(); state.timer = nil end
  if state.job and state.job.handle then mp.abort_async_command(state.job.handle) end
  state.job = nil
  remove_overlay(which)
  if discard then cleanup(state.cache); state.cache = nil end
end

local function display_preview(which)
  local state = previews[which]
  local cached = state.cache
  if previews_hidden or not cached then return end
  local x, y, w, h = preview_geometry(which)
  if not x then return end
  -- command_native returns nil,error on command failure; pcall alone misses it.
  local result, err = mp.command_native({
    name = "overlay-add", id = OVERLAY_ID[which], x = x, y = y,
    file = cached.raw, offset = 0, fmt = "bgra",
    w = cached.w, h = cached.h, stride = cached.w * 4, dw = w, dh = h,
  })
  state.shown = result ~= nil
  if not result then show_status("error", "preview: " .. tostring(err)) end
end

local function preview_cut(which)
  local state = previews[which]
  if previews_hidden or not mark_set[which] or state.job or state.timer then return end
  local _, _, w, h = preview_geometry(which)
  if not w then return end -- osd-dimensions observer retries once layout exists.
  local path = source_path()
  local info = path and utils.file_info(path)
  local ext = path and path:match("%.([^./]+)$")
  if not info or not info.is_file or not ext then
    show_status("warn", "preview requires a local file with a container extension")
    return
  end
  if not finite(g.A) or not finite(g.B) or g.A < 0 or g.B <= g.A then return end
  local ok, raw = pcall(os.tmpname)
  if not ok then show_status("error", "preview: " .. tostring(raw)); return end
  local factor = math.min(1, 640 / math.max(w, h))
  local job = {
    raw = raw, clip = raw .. "." .. ext, generation = state.generation,
    path = path, a = g.A, b = g.B, mode = preview_mode,
    w = math.max(1, math.floor(w * factor)), h = math.max(1, math.floor(h * factor)),
  }
  state.job = job
  jobs[job] = true
  local function current()
    return state.job == job and state.generation == job.generation
  end
  local function fail(message)
    if current() then
      state.job = nil
      show_status("error", "preview[" .. which .. "]: " .. message)
    end
    cleanup(job)
  end
  local function run(args, next_step, on_error)
    mp.msg.debug("preview[" .. which .. "]: " .. table.concat(args, " "))
    job.handle = mp.command_native_async({
      name = "subprocess", playback_only = true,
      capture_stdout = true, capture_stderr = true, args = args,
    }, function(success, result, err)
      job.handle = nil
      if not current() then cleanup(job); return end
      if not success or not result or result.status ~= 0 then
        local message = (result and result.stderr and result.stderr ~= "" and result.stderr)
          or (result and result.error_string) or err or "subprocess failed"
        if on_error and on_error(message) then return end
        fail(message)
        return
      end
      next_step(result)
    end)
  end

  local sample
  sample = function(window)
    os.remove(job.clip)
    os.remove(job.clip .. ".segment.mp4")
    local function retry_empty()
      local limit = math.min(job.b - job.a, math.max(PREVIEW_WINDOW_S, options.preview_window_limit))
      if window >= limit then return false end
      sample(math.min(limit, window * 4))
      return true
    end
    local function decode()
      local label = string.format("%s %s %s", job.mode, which,
        to_ffmpeg_sfx(which == 'A' and job.a or job.b)):gsub(":", "\\:")
      local filter = string.format(
        "scale=%d:%d,drawtext=text='%s':x=10:y=h-th-10:fontsize=%d:fontcolor=white:borderw=2:bordercolor=black",
        job.w, job.h, label, math.max(12, math.floor(job.h * 0.14)))
      local args = { "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
        "-i", job.clip, "-an", "-sn", "-dn", "-vf", filter,
        "-pix_fmt", "bgra", "-fps_mode", "passthrough" }
      if which == 'A' then
        args[#args + 1] = "-frames:v"; args[#args + 1] = "1"
      end
      args[#args + 1] = "-f"; args[#args + 1] = "rawvideo"
      args[#args + 1] = job.raw
      run(args, function()
        local size = utils.file_info(job.raw)
        local bytes = job.w * job.h * 4
        if size and size.size == 0 then
          -- Sparse/VFR video or audio extending beyond video: widen until a
          -- frame exists, without guessing a frame duration from nominal FPS.
          if retry_empty() then return end
        end
        if not size or size.size < bytes or size.size % bytes ~= 0 then
          fail("no complete video frame in " .. job.mode .. " boundary sample")
          return
        end
        -- B is the last decoded frame, including delayed/reordered frames.
        -- Keep only that frame in the cache; do not reverse full-size video.
        local input, read_err = io.open(job.raw, "rb")
        if not input then fail(read_err); return end
        local offset = which == 'A' and 0 or size.size - bytes
        local positioned = input:seek("set", offset)
        local data = positioned and input:read(bytes)
        input:close()
        if not data or #data ~= bytes then fail("short raw frame"); return end
        local output, write_err = io.open(job.raw, "wb")
        if not output then fail(write_err); return end
        local written = output:write(data)
        local closed = output:close()
        if not written or not closed then fail("could not cache raw frame"); return end
        os.remove(job.clip)
        os.remove(job.clip .. ".segment.mp4")
        state.job = nil
        cleanup(state.cache)
        state.cache = job
        display_preview(which)
      end, function(message)
        -- A sample in an audio-only tail can have no video stream at all.
        return message:find("does not contain any stream", 1, true) and retry_empty()
      end)
    end
    -- The converter owns muxer, stream selection, GOP splitting and encoders.
    -- Its NUL protocol keeps filenames out of shell command strings.
    run({ options.converter, "--preview-plan", which, job.path,
      tostring(job.a), tostring(job.b), job.mode, job.clip, tostring(window),
    }, function(result)
      local commands, command = {}, {}
      for value in (result.stdout or ""):gmatch("(.-)%z") do
        if value == "" then
          if #command > 0 then commands[#commands + 1] = command; command = {} end
        else
          command[#command + 1] = value
        end
      end
      if #commands == 0 or #command ~= 0 then fail("invalid converter preview plan"); return end
      local function execute(index)
        if index > #commands then decode(); return end
        run(commands[index], function() execute(index + 1) end)
      end
      execute(1)
    end)
  end
  sample(PREVIEW_WINDOW_S)
end

local function refresh_previews()
  for _, which in ipairs({ 'A', 'B' }) do
    cancel_preview(which, true)
    if mark_set[which] and not previews_hidden then
      previews[which].timer = mp.add_timeout(0.15, function()
        previews[which].timer = nil
        preview_cut(which)
      end)
    end
  end
end

local function preview_hide()
  for _, which in ipairs({ 'A', 'B' }) do cancel_preview(which, false) end
end

local function preview_clear()
  for _, which in ipairs({ 'A', 'B' }) do
    mark_set[which] = false
    cancel_preview(which, true)
  end
end

local function preview_show()
  for _, which in ipairs({ 'A', 'B' }) do
    if previews[which].cache then display_preview(which) else preview_cut(which) end
  end
end

mp.observe_property("osd-dimensions", "native", preview_show)
mp.observe_property("video-out-params", "native", preview_show)
mp.register_event("start-file", preview_clear)
mp.register_event("end-file", preview_clear)
mp.register_event("shutdown", function()
  preview_clear()
  for job in pairs(jobs) do
    if job.handle then mp.abort_async_command(job.handle) end
    cleanup(job)
  end
end)

local function on_osc_visibility_change()
  local vis = mp.get_property("user-data/osc/visibility")
    or mp.get_property("script-opts/osc-visibility")
  if not vis then return end
  previews_hidden = vis == "never"
  if previews_hidden then preview_hide() else preview_show() end
end
mp.observe_property("user-data/osc/visibility", "string", on_osc_visibility_change)
mp.observe_property("script-opts/osc-visibility", "string", on_osc_visibility_change)

mp.register_script_message("clip_toggle_previews", function()
  previews_hidden = not previews_hidden
  mp.commandv("script-message", "osc-visibility", previews_hidden and "never" or "always")
  if previews_hidden then preview_hide() else preview_show() end
end)

local function select_preview_mode(mode)
  if not valid_mode[mode] then show_status("error", "unknown clip mode: " .. tostring(mode)); return end
  preview_mode = mode
  previews_hidden = false
  mp.commandv("script-message", "osc-visibility", "always")
  mark_set.A, mark_set.B = true, true
  refresh_previews()
  show_status("info", "Previewing " .. mode .. "; review both ends before exporting")
end
mp.register_script_message("clip_preview_mode", select_preview_mode)
mp.add_key_binding("", "clip_cycle_preview_mode", function()
  select_preview_mode(({ copy = "fast", fast = "smart", smart = "copy" })[preview_mode])
end)


-- Options
-- mp.set_property("hr-seek-framedrop", "no")
-- mp.set_property("options/keep-open", "always")
-- NOTE: always show OSD / BAD: no effect? - should use mpv cmdline of mpv instead?
-- mp.set_property("options/script-opts", "osc-layout=bottombar,osc-hidetimeout=-1")


-- Behaviour
-- Pause on open and eof
function on_loaded()
  -- mp.set_property("pause", "yes")
  -- watch-later restores ab-loop-a/b before file-loaded, so use those
  -- values when reopening a video.  Fall back to the full file range when
  -- no loop was saved for this file.
  g.A = mp.get_property_number("ab-loop-a") or 0.0
  g.B = mp.get_property_number("ab-loop-b") or mp.get_property_number("duration/full")
    or mp.get_property_number("duration") or g.A

  local duration = mp.get_property_number("duration")
  if duration and duration < 40 and duration > 0 then
      mp.set_property("loop-file", "inf")
  else
      mp.set_property("loop-file", "no")
  end
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


-- Implementation
-- at some later time, setting a/b markers might be used to visualize begin/end
-- mp.set_property("ab-loop-a", g.A)
-- mp.set_property("loop", 999)
function to_ffmpeg_sfx(t)
  -- ALT: os.date("%M:%S", g.A)
  return string.format("%02d:%02d.%d", math.floor(t/60), math.floor(t%60), math.floor((t-math.floor(t))*10))
end
function update_duration_overlay()
  mp.set_property("osd-align-x", "left")
  mp.set_property("osd-align-y", "top")
  mp.osd_message(string.format("duration: %s", to_ffmpeg_sfx(math.max(0, g.B - g.A))), 999999)
end
function mark_update(m)
  show_status("info", string.format("[%s] dt=%4.3f  (%s - %s)",
    m, g.B - g.A, to_ffmpeg_sfx(g.A), to_ffmpeg_sfx(g.B)))
end
function h_mark_beg()
  local t = mp.get_property_number("playback-time")
  if not finite(t) or t < 0 then return end
  g.A = t
  -- print(g.A)
  g.B = math.max(g.A, g.B)
  -- HACK: loop the snippet; clear it manually
  mp.set_property("ab-loop-a", g.A)
  mp.set_property("ab-loop-b", g.B)
  mark_update('<')
  mark_set.A = true
  update_duration_overlay()
  refresh_previews()
end
function h_mark_end()
  local t = mp.get_property_number("playback-time")
  if not finite(t) or t < 0 then return end
  g.B = t
  -- print(g.B)
  g.A = math.min(g.A, g.B)
  mp.set_property("ab-loop-a", g.A)
  mp.set_property("ab-loop-b", g.B)
  mark_update('>')
  mark_set.B = true
  update_duration_overlay()
  refresh_previews()
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

local writing = false
function h_write(mode)
  if writing then show_status("warn", "clip export already running"); return end
  local path = source_path()
  if not path or not finite(g.A) or not finite(g.B) or g.A < 0 or g.B <= g.A then
    show_status("error", "clip needs a valid nonempty range")
    return
  end
  if mode ~= preview_mode or previews_hidden or not mark_set.A or not mark_set.B then
    select_preview_mode(mode)
    return
  end
  if not previews.A.shown or not previews.B.shown then
    show_status("warn", "Wait for both " .. mode .. " previews before exporting")
    return
  end
  local generation = previews.A.generation
  writing = true
  show_status("info", string.format("encoding '%s' dt=%4.3f", mode, g.B - g.A))

  mp.set_property("ab-loop-a", "no")
  mp.set_property("ab-loop-b", "no")
  mp.command_native_async({
      name = "subprocess",
      playback_only = false,
      capture_stdout = true,
      capture_stderr = true,
      args = { options.converter,
        path,
        tostring(g.A), tostring(g.B), mode
  }}, function(ok, result, err)
    writing = false
    if ok and result and result.status == 0 then
      show_status("info", "Success encoding: " .. mode)
      if path == source_path() and generation == previews.A.generation then preview_clear() end
    else
      show_status("error", "Failed encoding: " .. ((result and result.stderr) or err or "unknown"))
    end
  end)
end

function h_move()
  local utils = require 'mp.utils'
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

mp.add_key_binding("", "clip_write_copy", (function() return h_write('copy') end))  -- y  # OLD=x
mp.add_key_binding("", "clip_write_fast", (function() return h_write('fast') end))  -- Y
mp.add_key_binding("", "clip_write_smart", (function() return h_write('smart') end))  -- C-y
mp.add_key_binding("", "clip_clear_preview", preview_clear)                             -- C-l
mp.add_key_binding("", "clip_moving",   h_move)       -- m
mp.add_key_binding("", "clip_mark_beg", h_mark_beg)   -- [  # OLD=i
mp.add_key_binding("", "clip_mark_end", h_mark_end)   -- ]  # OLD=o
-- ALT: jump and mark to keyframe
mp.add_key_binding("", "clip_seek_beg", (function() return h_seek(0,1) end))  -- {  # OLD=S-i
mp.add_key_binding("", "clip_seek_end", (function() return h_seek(1,1) end))  -- }  # OLD=S-o
mp.add_key_binding("", "clip_seek_kfb", (function() return h_seek(0,0) end))  -- <  # OLD=S-Left
mp.add_key_binding("", "clip_seek_kfe", (function() return h_seek(1,0) end))  -- >  # OLD=S-Right


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
