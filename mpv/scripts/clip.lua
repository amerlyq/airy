-- vim:ft=lua:ts=2:sw=2:sts=2
-- '[' / ']' mark the range. Export keys start conversion immediately.
-- Preview commands come from ffmpeg/run; only short boundary samples are made.
-- Lossy samples match frame selection, not full-encode compression.
-- Debug: mpv --msg-level=clip=debug FILE

local utils = require 'mp.utils'
-- Inclusive frame offsets around the actual last decoded output frame.
END_FRAME_RANGE = { -3, 1 }
local options = { converter = "r.ffmpeg", preview_mode = "copy", preview_window_limit = 30,
  end_frame_first = END_FRAME_RANGE[1], end_frame_last = END_FRAME_RANGE[2] }
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

-- Bitmap overlays always cover mpv's text OSD. Keep one text line above them.
local function osd_metrics()
  local dims = mp.get_property_native("osd-dimensions")
  local scale = mp.get_property_native("osd-scale-by-window") == false and 1
    or (dims and dims.h or 720) / 720
  local font = (mp.get_property_number("osd-font-size") or 30)
    * (mp.get_property_number("osd-scale") or 1) * scale
  local margin = (mp.get_property_number("osd-margin-y") or 16) * scale
  return font, math.ceil(margin + font * 1.5 + PAD), dims
end

local function status(level, message)
  mp.msg.log(level == "done" and "info" or level, message)
  local font, _, dims = osd_metrics()
  local text = level .. ": " .. message:gsub("%s+", " ")
  local limit = math.max(20, math.floor(((dims and dims.w or 1280) - 40) / (font * 0.65)))
  if #text > limit then text = text:sub(1, limit - 10) .. "... (log)" end
  local color = ({ error = "0080FF", done = "FF8000" })[level] -- ASS uses BGR.
  if color then
    local ass = mp.get_property_osd("osd-ass-cc/0")
    local literal = mp.get_property_osd("osd-ass-cc/1")
    text = ass .. "{\\1c&H" .. color .. "&}" .. literal .. text .. ass .. "{\\r}" .. literal
  end
  mp.osd_message(text, color and 8 or 3)
end

local function finite(value)
  return type(value) == "number" and value == value and math.abs(value) < math.huge
end

if not finite(options.preview_window_limit) then options.preview_window_limit = 30 end
options.preview_window_limit = math.max(WINDOW, options.preview_window_limit)
local first_frame = finite(options.end_frame_first) and math.max(-15, math.min(0, math.floor(options.end_frame_first))) or -3
local last_frame = finite(options.end_frame_last) and math.max(0, math.min(15, math.floor(options.end_frame_last))) or 1
local function overlay_id(edge, index)
  if edge.id == 1 or index == 0 then return edge.id end
  return 3 + index - first_frame - (index > 0 and 1 or 0)
end

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
local function geometry(edge, index)
  local dims = mp.get_property_native("osd-dimensions")
  local vw, vh = mp.get_property_number("dwidth"), mp.get_property_number("dheight")
  if not dims or not vw or not vh or vw <= 0 or vh <= 0 then return end
  local aw = dims.w - (dims.ml or 0) - (dims.mr or 0)
  local ah = dims.h - (dims.mt or 0) - (dims.mb or 0)
  local _, top = osd_metrics()
  local ratio = vw / vh
  local h = vh > vw and aw * 0.20 / ratio or ah * 0.20
  local w = h * ratio
  local count = 2 + last_frame - first_frame
  local columns = math.max(1, math.min(count, math.floor((dims.w - PAD) / (w + PAD))))
  local rows = math.ceil(count / columns)
  h = math.min(h, (dims.h - top - rows * PAD) / rows,
    (dims.w - (columns + 1) * PAD) / columns / ratio)
  w = h * ratio
  local slot = edge.id == 1 and 0 or 1 + (index or 0) - first_frame
  local x = PAD + (slot % columns) * (w + PAD)
  local y = top + math.floor(slot / columns) * (h + PAD)
  if w < 16 or h < 16 then return end
  return math.floor(x), math.floor(y), math.floor(w), math.floor(h)
end

local function remove_overlay(edge)
  for _, id in ipairs(edge.overlays or {}) do
    mp.command_native({ name = "overlay-remove", id = id })
  end
  edge.overlays = {}
  edge.shown = false
end

local function remove_samples(job)
  os.remove(job.clip)
  os.remove(job.clip .. ".segment.mp4")
  os.remove(job.stats)
end

local function dispose(job)
  if not job then return end
  remove_samples(job)
  os.remove(job.raw)
  if job.after then os.remove(job.after) end
  jobs[job] = nil
end

local function cancel(edge, discard, keep_visible)
  if edge.timer then edge.timer:kill(); edge.timer = nil end
  if edge.job and edge.job.handle then mp.abort_async_command(edge.job.handle) end
  -- Never delete a running process's files. Its stale callback owns cleanup.
  edge.job = nil
  if not keep_visible then remove_overlay(edge) end
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
  remove_overlay(edge)
  local err
  for _, frame in ipairs(cached.frames) do
    x, y, w, h = geometry(edge, frame.index)
    local id = overlay_id(edge, frame.index)
    local _
    _, err = mp.command_native({
      name = "overlay-add", id = id, x = x, y = y, file = frame.file,
      offset = frame.offset, fmt = "bgra", w = cached.w, h = cached.h,
      stride = cached.w * 4, dw = w, dh = h,
    })
    if err then break end
    edge.overlays[#edge.overlays + 1] = id
  end
  if err then remove_overlay(edge) end
  edge.shown = err == nil
  edge.error = err and ("overlay: " .. tostring(err)) or nil
  if edge.error then status("error", edge.error) end
end

local function fail(edge, message)
  dispose(edge.job)
  if edge.cache and edge.cache.recheck then
    remove_overlay(edge)
    dispose(edge.cache)
    edge.cache = nil
  end
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

-- Compare actual conversion operations independently of private temp names.
local function plan_key(job, commands)
  local parts = {}
  for _, command in ipairs(commands) do
    for _, value in ipairs(command) do
      if value == job.clip then value = "<sample>"
      elseif value == job.clip .. ".segment.mp4" then value = "<segment>" end
      parts[#parts + 1] = value
    end
    parts[#parts + 1] = ""
  end
  return table.concat(parts, "\0")
end

local function decode_args(job)
  local label = string.format("%s %s %s", job.mode, job.edge.name,
    timestamp(job.edge.id == 1 and job.a or job.b)):gsub(":", "\\:")
  local function text_filter(text, n)
    return string.format("drawtext=text='%s':x=10:y=h-th-10:fontsize=%d:fontcolor=white:borderw=2:bordercolor=black%s",
      text, math.max(12, math.floor(job.h * 0.14)), n and (":enable='eq(n," .. n .. ")'") or "")
  end
  local scale = string.format("scale=%d:%d", job.w, job.h)
  local filter = scale .. "," .. text_filter(label)
  local args = { "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-copyts",
    "-i", job.clip }
  local function append(values)
    for _, value in ipairs(values) do args[#args + 1] = value end
  end
  if job.edge.id == 2 then
    filter = scale .. ",reverse,trim=end_frame=" .. (1 - first_frame) .. "," .. text_filter(label, 0)
    for i = -1, first_frame, -1 do filter = filter .. "," .. text_filter(tostring(i), -i) end
    if last_frame > 0 and job.anchor then
      job.context_start = math.max(0, math.floor(job.anchor) - 1)
      append({ "-ss", tostring(job.context_start), "-i", job.path })
    end
  end
  append({ "-map", "0:v:0", "-an", "-sn", "-dn", "-vf", filter,
    "-pix_fmt", "bgra", "-fps_mode", "passthrough", "-frames:v",
    tostring(job.edge.id == 1 and 1 or 1 - first_frame), "-f", "rawvideo", job.raw })
  if job.edge.id == 2 and last_frame > 0 and job.anchor then
    -- Source context only: these frames are outside the converted clip.
    local context = string.format("select='gt(t,%.9f)',%s", job.absolute_anchor + 0.000002, scale)
    for i = 1, last_frame do context = context .. "," .. text_filter("+" .. i, i - 1) end
    append({ "-map", "1:" .. job.source_track, "-an", "-sn", "-dn", "-vf", context,
      "-pix_fmt", "bgra", "-fps_mode", "passthrough", "-frames:v", tostring(last_frame),
      "-f", "rawvideo", job.after })
  end
  return args
end

-- Index complete raw frames without copying or launching per-frame decoders.
local function retain_frame(job)
  local info, bytes = utils.file_info(job.raw), job.w * job.h * 4
  if info and info.size == 0 then return nil, "empty" end
  if not info or info.size < bytes or info.size % bytes ~= 0 then
    return nil, "incomplete raw frame"
  end
  job.frames = {}
  for i = 0, math.min(info.size / bytes - 1, job.edge.id == 1 and 0 or -first_frame) do
    job.frames[#job.frames + 1] = { index = -i, file = job.raw, offset = i * bytes }
  end
  if job.edge.id == 2 and last_frame > 0 then
    if not job.anchor then return nil, "cannot locate final output frame in source" end
    local after = utils.file_info(job.after)
    if not after or after.size % bytes ~= 0 then return nil, "incomplete context frame" end
    for i = 1, math.min(last_frame, after.size / bytes) do
      job.frames[#job.frames + 1] = { index = i, file = job.after, offset = (i - 1) * bytes }
    end
  end
  return true
end

local sample_job
local function retry_empty(job)
  if job.window >= job.limit then return false end
  job.window = math.min(job.limit, job.window * 4)
  sample_job(job)
  return true
end

local function publish(job)
  remove_samples(job)
  jobs[job] = nil
  local edge = job.edge
  dispose(edge.cache)
  edge.job, edge.cache, edge.error = nil, job, nil
  render(edge)
end

local function decode_job(job)
  run_job(job, decode_args(job), function()
    local ok, err = retain_frame(job)
    if not ok then
      if err == "empty" and retry_empty(job) then return end
      fail(job.edge, err == "empty" and "no video frame in boundary sample" or err)
      return
    end
    if job.edge.id == 2 and #job.frames < 1 - first_frame + last_frame then
      local info = utils.file_info(job.raw)
      if info.size / (job.w * job.h * 4) < 1 - first_frame and retry_empty(job) then return end
    end
    publish(job)
  end, function(err)
    -- Audio may outlast video, leaving the initial sample without a video track.
    return (err:find("does not contain any stream", 1, true)
      or err:find("matches no streams", 1, true)) and retry_empty(job)
  end)
end

local function execute_plan(job, commands, index)
  if index > #commands then decode_job(job); return end
  local command = commands[index]
  local seek
  if job.edge.id == 2 and last_frame > 0 and index == 1 then
    -- muxer timestamps precede container timestamp normalization. Track the
    -- last emitted video packet, including reordered frames beyond the mark.
    for i, value in ipairs(command) do if value == "-ss" then seek = tonumber(command[i + 1]) end end
    if not seek then fail(job.edge, "preview plan lacks source seek timestamp"); return end
    command = { (table.unpack or unpack)(command) }
    table.insert(command, 2, "-debug_ts")
    local output = table.remove(command)
    for _, value in ipairs({ "-stats_enc_pre:v:0", job.stats,
      "-stats_enc_pre_fmt:v:0", "{ptsi} {tbi}", output }) do command[#command + 1] = value end
  end
  run_job(job, command, function(result)
    if seek then
      local last, packets, pending = nil, {}, {}
      for line in (result.stderr or ""):gmatch("[^\r\n]+") do
        local track = line:match("%[vist#0:(%d+)/")
        if track then
          local t = tonumber(line:match("pkt_pts_time:([%d.eE+%-]+)"))
          if line:find("demuxer ->", 1, true) then pending[track] = t end
          if line:find("demuxer+ffmpeg ->", 1, true) then
            local offset = tonumber(line:match("off_time:([%d.eE+%-]+)"))
            if finite(t) and pending[track] and offset then
              packets[#packets + 1] = { t = t, source = pending[track] + offset + seek,
                absolute = pending[track], track = track }
            end
          end
        end
        if line:find("[vost#", 1, true) and line:find("muxer <-", 1, true) then
          local t = tonumber(line:match("pts_time:([%d.eE+%-]+)"))
          if finite(t) and (not last or t > last) then last = t end
        end
      end
      -- Encoders can quantize output PTS to their own frame-rate timebase.
      -- Use the decoder PTS attached to frames actually submitted for encoding.
      local stats = io.open(job.stats, "rb")
      if stats then
        last = nil
        for line in stats:lines() do
          local pts, num, den = line:match("^([%d%-]+) (%d+)/(%d+)$")
          if pts and tonumber(den) > 0 then
            local t = tonumber(pts) * tonumber(num) / tonumber(den)
            if finite(t) and (not last or t > last) then last = t end
          end
        end
        stats:close()
      end
      -- Match the emitted packet to its original source PTS. Adding -ss to
      -- a mux timestamp alone can be off by a container timebase tick (MKV).
      local match, distance
      if last then
        for _, packet in ipairs(packets) do
          local delta = math.abs(packet.t - last)
          if not distance or delta < distance then match, distance = packet, delta end
        end
      end
      job.anchor = match and distance < 0.002 and match.source or nil
      job.absolute_anchor = match and match.absolute
      job.source_track = match and match.track
      mp.msg.debug("preview[B] source anchor: mux=" .. tostring(last) ..
        " delta=" .. tostring(distance) .. " source=" .. tostring(job.anchor))
    end
    execute_plan(job, commands, index + 1)
  end)
end

sample_job = function(job)
  remove_samples(job)
  run_job(job, { options.converter, "--preview-plan", job.edge.name, job.path,
    tostring(job.a), tostring(job.b), job.mode, job.clip, tostring(job.window),
  }, function(result)
    local commands = parse_plan(result.stdout)
    if not commands then fail(job.edge, "invalid converter preview plan"); return end
    local key = plan_key(job, commands)
    -- A larger window cannot add predecessors beyond a short smart segment.
    if job.frames and job.plan == key then publish(job); return end
    job.plan, job.frames = key, nil
    local edge, cached = job.edge, job.edge.cache
    if cached and cached.plan == job.plan then
      cached.a, cached.b, cached.limit = job.a, job.b, job.limit
      cached.recheck = nil
      edge.job, edge.error = nil, nil
      dispose(job)
      render(edge)
      return
    end
    -- The opposite boundary can change for short ranges or smart-cut plans.
    -- Keep its old image during planning, but never retain a known-stale image.
    remove_overlay(edge)
    dispose(cached)
    edge.cache = nil
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
    raw = raw, after = raw .. ".after", stats = raw .. ".stats",
    clip = raw .. "." .. ext, window = WINDOW,
    limit = math.min(edges[2].time - edges[1].time, options.preview_window_limit),
    w = math.max(1, math.floor(w * factor)), h = math.max(1, math.floor(h * factor)),
  }
  edge.job, jobs[job] = job, true
  sample_job(job)
end

local function show_previews()
  for _, edge in ipairs(edges) do
    if edge.cache then render(edge) end
    if not edge.cache or edge.cache.recheck then start_preview(edge) end
  end
end

local function unchanged_sample(edge)
  if edge.error then return false end
  local job = edge.job or edge.cache
  if not job or job.mode ~= state.mode or job.path ~= source_path() then return false end
  local a, b = edges[1].time, edges[2].time
  local unchanged
  if state.mode ~= "smart" then
    if edge.id == 1 then
      unchanged = job.a == a and math.min(job.b, a + job.window) == math.min(b, a + job.window)
    else
      unchanged = job.b == b and math.max(job.a, b - job.window) == math.max(a, b - job.window)
    end
  end
  if unchanged then
    -- A pending empty-sample retry must respect the new selection limits.
    job.a, job.b = a, b
    job.limit = math.min(b - a, options.preview_window_limit)
  end
  return unchanged
end

local function refresh_previews(changed)
  state.revision = state.revision + 1
  for _, edge in ipairs(edges) do
    if not (changed and edge ~= changed and valid_range() and unchanged_sample(edge)) then
      local cached = edge.cache
      local keep = changed and edge ~= changed and valid_range() and cached
        and cached.mode == state.mode and cached.path == source_path()
        and (edge.id == 1 and cached.a or cached.b) == edge.time
      if keep then cached.recheck = true end
      cancel(edge, not keep, keep)
      edge.error = nil
      if edge.marked and not state.hidden then
        edge.timer = mp.add_timeout(DEBOUNCE, function()
          edge.timer = nil
          start_preview(edge)
        end)
      end
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
  status("info", "Previewing " .. mode .. "; export keys start conversion")
end

local function mark(edge)
  local t = mp.get_property_number("playback-time")
  if not finite(t) or t < 0 then return end
  edge.time, edge.marked = t, true
  local other = edges[3 - edge.id]
  other.time = edge.id == 1 and math.max(t, other.time) or math.min(t, other.time)
  mp.set_property("ab-loop-a", edges[1].time)
  mp.set_property("ab-loop-b", edges[2].time)
  refresh_previews(edge)
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
  -- Export intent is never consumed by mode switching or preview readiness.
  -- A missing A mark uses the file-loaded default (zero or watch-later A).
  -- Keep the current previews untouched, including on conversion failure.
  local revision = state.revision
  state.writing = true
  status("info", string.format("ENCODING %s dt=%.3f", mode, edges[2].time - edges[1].time))
  mp.set_property("ab-loop-a", "no")
  mp.set_property("ab-loop-b", "no")
  subprocess({ options.converter, path, tostring(edges[1].time), tostring(edges[2].time), mode },
    false, function(result, err)
      state.writing = false
      if not result then status("error", "FAILED " .. mode .. ": " .. err); return end
      status("done", "DONE " .. mode)
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
local function observe_visibility(_, vis)
  if vis then set_hidden(vis == "never") end
end
mp.observe_property("user-data/osc/visibility", "string", observe_visibility)
for _, property in ipairs({ "osd-font-size", "osd-scale", "osd-margin-y", "osd-scale-by-window" }) do
  mp.observe_property(property, "native", show_previews)
end
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
