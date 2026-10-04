-- PgDn/PgUp: find the next/previous abrupt image change. Repeat to stop.
-- Scan decoded frames outside mpv: no hardware-download filter, playback-speed
-- changes, frame dropping, or polling of transient vf-metadata.
local utils = require 'mp.utils'
local opts = { ffmpeg = "ffmpeg", threshold = 12, window = 8 }
require('mp.options').read_options(opts, 'sceneseeker')

local function finite(n)
  return type(n) == "number" and n == n and math.abs(n) < math.huge
end
opts.threshold = finite(opts.threshold) and math.max(0.01, math.min(100, opts.threshold)) or 12
opts.window = finite(opts.window) and math.max(1, math.min(60, opts.window)) or 8
local EPSILON = 0.001
local active

local function message(text)
  mp.osd_message(text, 2)
end

local function stop(text)
  local scan = active
  active = nil -- Invalidate callbacks before requesting cancellation.
  if scan then
    if scan.handle then mp.abort_async_command(scan.handle) end
    if scan.timer then scan.timer:kill() end
  end
  if text then message(text) end
end

local function seek(t)
  mp.set_property("pause", "yes")
  mp.commandv("seek", t, "absolute", "exact")
end

local scan_window
scan_window = function(scan)
  if active ~= scan then return end
  local lo, hi
  if scan.direction == 1 then
    lo, hi = scan.cursor, math.min(scan.duration, scan.cursor + opts.window)
  else
    lo, hi = math.max(0, scan.cursor - opts.window), scan.cursor
  end
  if hi <= lo then stop("No further scene boundary"); return end

  -- Include previous frames even at window seams or a keyframe cut. With
  -- noaccurate_seek the decoder's keyframe preroll reaches the scene filter;
  -- negative timestamps are excluded only AFTER computing the scene score.
  -- Input -t counts from that earlier keyframe with noaccurate_seek. Trim by
  -- decoded timestamp instead, or long GOPs silently shorten the search.
  -- Integer seek origins avoid fractional -ss rounding in the stream timebase.
  local start = math.max(0, math.floor(lo - 1))
  local filter = string.format(
    "trim=end=%.9f,scale=320:-2,format=yuv420p,select='gte(scene,%.9f)*gte(t,%.9f)',showinfo=checksum=0",
    hi - start, opts.threshold / 100, lo - start)
  local args = { opts.ffmpeg, "-nostdin", "-hide_banner", "-nostats", "-loglevel", "info",
    "-noaccurate_seek", "-ss", string.format("%.9f", start),
    "-i", scan.path,
    "-map", scan.track, "-an", "-sn", "-dn", "-vf", filter,
    "-fps_mode", "passthrough" }
  -- Only stop early in the forward direction. Backward search needs the LAST
  -- boundary in the window, not the first one decoded in chronological order.
  if scan.direction == 1 then
    args[#args + 1], args[#args + 2] = "-frames:v", "1"
  end
  args[#args + 1], args[#args + 2], args[#args + 3] = "-f", "null", "-"
  message(string.format("Scene scan %s: %.1f–%.1fs (repeat key to stop)",
    scan.direction == 1 and "forward" or "backward", lo, hi))
  scan.handle = mp.command_native_async({
    name = "subprocess", args = args, playback_only = true,
    capture_stdout = false, capture_stderr = true,
  }, function(ok, result, err)
    scan.handle = nil
    if active ~= scan then return end
    if not ok or not result or result.status ~= 0 then
      mp.msg.error("Scene scan failed: " .. (result and (result.stderr or result.error_string) or err or "unknown error"))
      stop("Scene scan failed (see log)")
      return
    end
    local found
    for timestamp in (result.stderr or ""):gmatch("pts_time:([%d%.eE+%-]+)") do
      local relative = tonumber(timestamp)
      local t = relative and start + relative
      if finite(t) and t >= lo - EPSILON and t < hi
        and (t - scan.origin) * scan.direction > EPSILON then
        if not found or (t - found) * scan.direction < 0 then found = t end
      end
    end
    if found then
      stop()
      seek(found)
      message(string.format("Scene boundary: %.3fs", found))
      return
    end
    scan.cursor = scan.direction == 1 and hi or lo
    seek(scan.cursor)
    if scan.cursor <= 0 or scan.cursor >= scan.duration then
      stop("No further scene boundary")
    else
      -- Yield between windows so queued key presses can cancel immediately.
      scan.timer = mp.add_timeout(0, function()
        scan.timer = nil
        scan_window(scan)
      end)
    end
  end)
end

local function start(direction)
  if active then
    local previous_direction = active.direction
    stop("Scene scan stopped")
    if previous_direction == direction then return end
  end
  local path = mp.get_property("path")
  local position = mp.get_property_number("time-pos")
  local duration = mp.get_property_number("duration")
  if not path or not finite(position) or not finite(duration) or duration <= 0 then
    message("Scene scan needs a seekable video")
    return
  end
  if not path:match("^/") then
    path = utils.join_path(mp.get_property("working-directory") or ".", path)
  end
  local info = utils.file_info(path)
  local track = mp.get_property_native("current-tracks/video")
  if not info or not info.is_file or not track or track.external or track.image then
    message("Scene scan needs a local video track")
    return
  end
  local scan = {
    path = path, track = track["ff-index"] and ("0:" .. track["ff-index"]) or "0:v:0",
    origin = position, cursor = position, duration = duration, direction = direction,
  }
  -- Exclude the current boundary before forward early-exit can consume it.
  if direction == 1 then scan.cursor = position + EPSILON * 2 end
  active = scan
  mp.set_property("pause", "yes")
  scan_window(scan)
end

mp.register_script_message("scan-forward", function() start(1) end)
mp.register_script_message("scan-backward", function() start(-1) end)
-- Defaults only: respect input.conf instead of installing forced bindings.
mp.add_key_binding("PGDWN", "scan-forward-key", function() start(1) end)
mp.add_key_binding("PGUP", "scan-backward-key", function() start(-1) end)
for _, event in ipairs({ "start-file", "end-file", "shutdown" }) do
  mp.register_event(event, function() stop() end)
end
