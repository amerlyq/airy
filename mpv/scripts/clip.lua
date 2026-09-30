-- vim:ft=lua:ts=2:sw=2:sts=2
-- '[' / ']' mark the range. Export keys select a mode before exporting.
-- Preview commands come from ffmpeg/run; only short boundary samples are made.
-- Lossy samples match frame selection, not full-encode compression.
-- Debug: mpv --msg-level=clip=debug FILE

local utils = require 'mp.utils'
local options = { converter = "r.ffmpeg", preview_mode = "copy", preview_window_limit = 30 }
require('mp.options').read_options(options, 'clip')

local NEXT_MODE = { copy = "fast", fast = "smart", smart = "copy" }
local WINDOW, DEBOUNCE, PAD = 2, 0.15, 10
local state = {
  mode = NEXT_MODE[options.preview_mode] and options.preview_mode or "copy",
  hidden = false, revision = 0,
}
-- Each boundary owns its mark, pending work, cached frame and display state.
local edges = { { name = "A", id = 1, time = 0 }, { name = "B", id = 2, time = 0 } }
local jobs = {} -- Includes cancelled processes until their completion callbacks.

local function status(level, message)
  mp.msg.log(level, message)
  mp.osd_message(level .. ": " .. message, 2)
end

local function finite(value)
  return type(value) == "number" and value == value and math.abs(value) < math.huge
end

if not finite(options.preview_window_limit) then options.preview_window_limit = 30 end
options.preview_window_limit = math.max(WINDOW, options.preview_window_limit)

local function timestamp(t)
  return string.format("%02d:%02d.%d", math.floor(t / 60), math.floor(t % 60),
    math.floor((t - math.floor(t)) * 10))
end

local function source_path()
  local path = mp.get_property("path")
  if path and not path:match("^/") and not path:match("^%a[%w+.-]*://") then
    path = utils.join_path(mp.get_property("working-directory") or ".", path)
  end
  return path
end

local function valid_range()
  return finite(edges[1].time) and finite(edges[2].time)
    and edges[1].time >= 0 and edges[2].time > edges[1].time
end

-- Normalize mpv API errors and nonzero process exits in one place.
local function subprocess(args, playback_only, callback)
  return mp.command_native_async({
    name = "subprocess", args = args, playback_only = playback_only,
    capture_stdout = true, capture_stderr = true,
  }, function(ok, result, err)
    if ok and result and result.status == 0 then callback(result); return end
    local message = result and result.stderr
    if not message or message == "" then message = result and result.error_string end
    if not message or message == "" then message = err end
    if not message or message == "" then
      message = "subprocess failed (status " .. tostring(result and result.status) .. ")"
    end
    callback(nil, message)
  end)
end

-- dwidth/dheight include rotation and sample aspect ratio.
local function geometry(edge)
  local dims = mp.get_property_native("osd-dimensions")
  local vw, vh = mp.get_property_number("dwidth"), mp.get_property_number("dheight")
  if not dims or not vw or not vh or vw <= 0 or vh <= 0 then return end
  local aw = dims.w - (dims.ml or 0) - (dims.mr or 0)
  local ah = dims.h - (dims.mt or 0) - (dims.mb or 0)
  local ratio, w, h, x, y = vw / vh
  if vh > vw then
    w = math.min(aw * 0.20, (dims.h - 3 * PAD) / 2 * ratio)
    h = w / ratio
    x, y = dims.w - w - PAD, PAD + (edge.id - 1) * (h + PAD)
  else
    h = math.min(ah * 0.20, (dims.w - 3 * PAD) / 2 / ratio)
    w = h * ratio
    x, y = PAD + (edge.id - 1) * (w + PAD), PAD
  end
  if w < 16 or h < 16 then return end
  return math.floor(x), math.floor(y), math.floor(w), math.floor(h)
end

local function remove_overlay(edge)
  if edge.shown then mp.command_native({ name = "overlay-remove", id = edge.id }) end
  edge.shown = false
end

local function remove_samples(job)
  os.remove(job.clip)
  os.remove(job.clip .. ".segment.mp4")
end

local function dispose(job)
  if not job then return end
  remove_samples(job)
  os.remove(job.raw)
  jobs[job] = nil
end

local function cancel(edge, discard)
  if edge.timer then edge.timer:kill(); edge.timer = nil end
  if edge.job and edge.job.handle then mp.abort_async_command(edge.job.handle) end
  -- Never delete a running process's files. Its stale callback owns cleanup.
  edge.job = nil
  remove_overlay(edge)
  if discard then
    dispose(edge.cache)
    edge.cache, edge.error = nil, nil
  end
end

local function render(edge)
  local cached = edge.cache
  if state.hidden or not cached then return end
  local x, y, w, h = geometry(edge)
  if not x then remove_overlay(edge); return end
  local result, err = mp.command_native({
    name = "overlay-add", id = edge.id, x = x, y = y, file = cached.raw,
    offset = 0, fmt = "bgra", w = cached.w, h = cached.h,
    stride = cached.w * 4, dw = w, dh = h,
  })
  if not result then remove_overlay(edge) end
  edge.shown = result ~= nil
  edge.error = not result and ("overlay: " .. tostring(err)) or nil
  if edge.error then status("error", edge.error) end
end

local function fail(edge, message)
  dispose(edge.job)
  edge.job, edge.error = nil, message
  status("error", "preview[" .. edge.name .. "]: " .. message)
end

local function run_job(job, args, next_step, on_error)
  mp.msg.debug("preview[" .. job.edge.name .. "]: " .. table.concat(args, " "))
  job.handle = subprocess(args, true, function(result, err)
    job.handle = nil
    if job.edge.job ~= job then dispose(job); return end
    if not result then
      if not on_error or not on_error(err) then fail(job.edge, err) end
      return
    end
    next_step(result)
  end)
end

-- NUL-delimited argv vectors, terminated by empty arguments. Reject trailing
-- garbage/truncated plans before executing anything. Never evaluate shell text.
local function parse_plan(data)
  if type(data) ~= "string" or data:sub(-2) ~= "\0\0" then return end
  local commands, command = {}, {}
  for value in data:gmatch("(.-)%z") do
    if value == "" then
      if #command == 0 then return end
      commands[#commands + 1], command = command, {}
    else
      command[#command + 1] = value
    end
  end
  if #commands > 0 and #command == 0 then return commands end
end

local function decode_args(job)
  local label = string.format("%s %s %s", job.mode, job.edge.name,
    timestamp(job.edge.id == 1 and job.a or job.b)):gsub(":", "\\:")
  local filter = string.format(
    "scale=%d:%d,drawtext=text='%s':x=10:y=h-th-10:fontsize=%d:fontcolor=white:borderw=2:bordercolor=black",
    job.w, job.h, label, math.max(12, math.floor(job.h * 0.14)))
  local args = { "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
    "-i", job.clip, "-an", "-sn", "-dn", "-vf", filter,
    "-pix_fmt", "bgra", "-fps_mode", "passthrough" }
  if job.edge.id == 1 then args[#args + 1] = "-frames:v"; args[#args + 1] = "1" end
  args[#args + 1], args[#args + 2], args[#args + 3] = "-f", "rawvideo", job.raw
  return args
end

-- Collapse raw output to one complete frame. B includes decoder-delayed frames.
local function retain_frame(job)
  local info, bytes = utils.file_info(job.raw), job.w * job.h * 4
  if info and info.size == 0 then return nil, "empty" end
  if not info or info.size < bytes or info.size % bytes ~= 0 then
    return nil, "incomplete raw frame"
  end
  local input, err = io.open(job.raw, "rb")
  if not input then return nil, err end
  local offset = job.edge.id == 1 and 0 or info.size - bytes
  local positioned = input:seek("set", offset)
  local data = positioned and input:read(bytes)
  input:close()
  if not data or #data ~= bytes then return nil, "short raw frame" end
  local output
  output, err = io.open(job.raw, "wb")
  if not output then return nil, err end
  local written = output:write(data)
  local closed = output:close()
  if not written or not closed then return nil, "could not cache raw frame" end
  return true
end

local sample_job
local function retry_empty(job)
  if job.window >= job.limit then return false end
  job.window = math.min(job.limit, job.window * 4)
  sample_job(job)
  return true
end

local function decode_job(job)
  run_job(job, decode_args(job), function()
    local ok, err = retain_frame(job)
    if not ok then
      if err == "empty" and retry_empty(job) then return end
      fail(job.edge, err == "empty" and "no video frame in boundary sample" or err)
      return
    end
    remove_samples(job)
    jobs[job] = nil
    local edge = job.edge
    dispose(edge.cache)
    edge.job, edge.cache, edge.error = nil, job, nil
    render(edge)
  end, function(err)
    -- Audio may outlast video, leaving the initial sample without a video track.
    return err:find("does not contain any stream", 1, true) and retry_empty(job)
  end)
end

local function execute_plan(job, commands, index)
  if index > #commands then decode_job(job); return end
  run_job(job, commands[index], function() execute_plan(job, commands, index + 1) end)
end

sample_job = function(job)
  remove_samples(job)
  run_job(job, { options.converter, "--preview-plan", job.edge.name, job.path,
    tostring(job.a), tostring(job.b), job.mode, job.clip, tostring(job.window),
  }, function(result)
    local commands = parse_plan(result.stdout)
    if not commands then fail(job.edge, "invalid converter preview plan"); return end
    execute_plan(job, commands, 1)
  end)
end

local function start_preview(edge)
  if state.hidden or not edge.marked or edge.job or edge.timer or edge.error then return end
  local _, _, w, h = geometry(edge)
  if not w or not valid_range() then return end -- Layout observers retry later.
  local path = source_path()
  local info, ext = path and utils.file_info(path), path and path:match("%.([^./]+)$")
  if not info or not info.is_file or not ext then
    fail(edge, "preview requires a local file with a container extension")
    return
  end
  local ok, raw = pcall(os.tmpname)
  if not ok or not raw then fail(edge, tostring(raw)); return end
  local factor = math.min(1, 640 / math.max(w, h))
  local job = {
    edge = edge, path = path, a = edges[1].time, b = edges[2].time, mode = state.mode,
    raw = raw, clip = raw .. "." .. ext, window = WINDOW,
    limit = math.min(edges[2].time - edges[1].time, options.preview_window_limit),
    w = math.max(1, math.floor(w * factor)), h = math.max(1, math.floor(h * factor)),
  }
  edge.job, jobs[job] = job, true
  sample_job(job)
end

local function show_previews()
  for _, edge in ipairs(edges) do
    if edge.cache then render(edge) else start_preview(edge) end
  end
end

local function refresh_previews()
  state.revision = state.revision + 1
  for _, edge in ipairs(edges) do
    cancel(edge, true)
    if edge.marked and not state.hidden then
      edge.timer = mp.add_timeout(DEBOUNCE, function()
        edge.timer = nil
        start_preview(edge)
      end)
    end
  end
end

local function clear_previews()
  state.revision = state.revision + 1
  for _, edge in ipairs(edges) do edge.marked = false; cancel(edge, true) end
end

local function set_hidden(hidden)
  if state.hidden == hidden then return end
  state.hidden = hidden
  if hidden then
    for _, edge in ipairs(edges) do cancel(edge, false) end
  else
    show_previews()
  end
end

local function select_mode(mode)
  if not NEXT_MODE[mode] then status("error", "unknown clip mode: " .. tostring(mode)); return end
  state.mode, state.hidden = mode, false
  for _, edge in ipairs(edges) do edge.marked = true end
  refresh_previews()
  mp.commandv("script-message", "osc-visibility", "always")
  status("info", "Previewing " .. mode .. "; review both ends before exporting")
end

local function mark(edge)
  local t = mp.get_property_number("playback-time")
  if not finite(t) or t < 0 then return end
  edge.time, edge.marked = t, true
  local other = edges[3 - edge.id]
  other.time = edge.id == 1 and math.max(t, other.time) or math.min(t, other.time)
  mp.set_property("ab-loop-a", edges[1].time)
  mp.set_property("ab-loop-b", edges[2].time)
  refresh_previews()
  mp.set_property("osd-align-x", "left")
  mp.set_property("osd-align-y", "top")
  mp.osd_message("duration: " .. timestamp(edges[2].time - edges[1].time), 999999)
end

local function seek(edge, mode)
  mp.set_property("pause", "yes")
  mp.commandv("seek", edge.time, "absolute", mode)
  status("info", string.format("seek %s %.3f (%s)", edge.name, edge.time, mode))
  if edge.id == 2 then mp.set_property("ab-loop-b", "no") end
end

local function export(mode)
  if state.writing or state.moving then status("warn", "file operation already running"); return end
  local path = source_path()
  if not path or not valid_range() then status("error", "clip needs a valid nonempty range"); return end
  if mode ~= state.mode or state.hidden or not edges[1].marked or not edges[2].marked then
    select_mode(mode)
    return
  end
  for _, edge in ipairs(edges) do
    if edge.error then
      status("error", "preview[" .. edge.name .. "] failed; reselect the mode to retry")
      return
    end
    if not edge.shown then status("warn", "Wait for both " .. mode .. " previews before exporting"); return end
  end
  local revision = state.revision
  state.writing = true
  status("info", string.format("encoding '%s' dt=%.3f", mode, edges[2].time - edges[1].time))
  mp.set_property("ab-loop-a", "no")
  mp.set_property("ab-loop-b", "no")
  subprocess({ options.converter, path, tostring(edges[1].time), tostring(edges[2].time), mode },
    false, function(result, err)
      state.writing = false
      if not result then status("error", "Failed encoding: " .. err); return end
      status("info", "Success encoding: " .. mode)
      if path == source_path() and revision == state.revision then clear_previews() end
    end)
end

local function move_file()
  if state.writing or state.moving then status("warn", "file operation already running"); return end
  local path = source_path()
  if not path then return end
  local revision = state.revision
  state.moving = true
  status("info", "moving to...")
  subprocess({ "r.mpv-category", path }, false, function(result, err)
    state.moving = false
    if not result then status("error", "Failed moving: " .. err); return end
    status("info", "Moved OK: " .. (result.stdout or ""))
    if path == source_path() and revision == state.revision then mp.commandv("playlist-next", "force") end
  end)
end

-- Register callbacks only after every helper is defined.
mp.register_event("file-loaded", function()
  local a = mp.get_property_number("ab-loop-a")
  local b = mp.get_property_number("ab-loop-b") or mp.get_property_number("duration/full")
    or mp.get_property_number("duration")
  edges[1].time = finite(a) and math.max(0, a) or 0
  edges[2].time = finite(b) and math.max(edges[1].time, b) or edges[1].time
  local duration = mp.get_property_number("duration")
  mp.set_property("loop-file", finite(duration) and duration > 0 and duration < 40 and "inf" or "no")
end)
mp.register_event("start-file", clear_previews)
mp.register_event("end-file", clear_previews)
mp.register_event("shutdown", function()
  clear_previews()
  for job in pairs(jobs) do
    if job.handle then mp.abort_async_command(job.handle) end
    dispose(job)
  end
end)
mp.observe_property("eof-reached", "bool", function(_, eof)
  if eof then mp.set_property("pause", "yes") end
end)
mp.observe_property("osd-dimensions", "native", show_previews)
mp.observe_property("video-out-params", "native", show_previews)
local function observe_visibility()
  local vis = mp.get_property("user-data/osc/visibility") or mp.get_property("script-opts/osc-visibility")
  if vis then set_hidden(vis == "never") end
end
mp.observe_property("user-data/osc/visibility", "string", observe_visibility)
mp.observe_property("script-opts/osc-visibility", "string", observe_visibility)
mp.register_script_message("clip_toggle_previews", function()
  set_hidden(not state.hidden)
  mp.commandv("script-message", "osc-visibility", state.hidden and "never" or "always")
end)
mp.register_script_message("clip_preview_mode", select_mode)

local bindings = {
  clip_write_copy = function() export("copy") end,
  clip_write_fast = function() export("fast") end,
  clip_write_smart = function() export("smart") end,
  clip_cycle_preview_mode = function() select_mode(NEXT_MODE[state.mode]) end,
  clip_clear_preview = clear_previews,
  clip_moving = move_file,
  clip_mark_beg = function() mark(edges[1]) end,
  clip_mark_end = function() mark(edges[2]) end,
  clip_seek_beg = function() seek(edges[1], "exact") end,
  clip_seek_end = function() seek(edges[2], "exact") end,
  clip_seek_kfb = function() seek(edges[1], "keyframes") end,
  clip_seek_kfe = function() seek(edges[2], "keyframes") end,
}
for name, callback in pairs(bindings) do mp.add_key_binding("", name, callback) end
