-- vim:ft=lua:ts=2:sw=2:sts=2
-- '[' / ']' mark the range. Export keys start conversion immediately.
-- Preview commands come from ffmpeg/run; only short boundary samples are made.
-- Lossy samples match frame selection, not full-encode compression.
-- Debug: mpv --msg-level=clip=debug FILE

local utils = require 'mp.utils'
-- Inclusive frame ranges around each boundary's "0" frame.
BEG_FRAME_RANGE = { -2, 2 }
END_FRAME_RANGE = { -3, 1 }
local options = { converter = "r.ffmpeg", preview_mode = "copy", preview_window_limit = 30,
  beg_frame_first = BEG_FRAME_RANGE[1], beg_frame_last = BEG_FRAME_RANGE[2],
  end_frame_first = END_FRAME_RANGE[1], end_frame_last = END_FRAME_RANGE[2],
  -- Default frames from the marked time to the actual clipping time (ffmpeg vs mpv discrepancy).
  framesnum_offset_beg = -2, framesnum_offset_end = -3,
  -- Beg row decoded from the source at exact frame times; false = converter sample (see source_args).
  beg_source = true }
require('mp.options').read_options(options, 'clip')

local NEXT_MODE = { copy = "fast", fast = "smart", smart = "copy" }
local WINDOW, DEBOUNCE, PAD = 2, 0.15, 10
local state = {
  mode = NEXT_MODE[options.preview_mode] and options.preview_mode or "copy",
  hidden = false, revision = 0, loop = false,
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
local function frame_limit(value, default, lo, hi)
  return finite(value) and math.max(lo, math.min(hi, math.floor(value))) or default
end
local ranges = {
  { first = frame_limit(options.beg_frame_first, -2, -15, 0), last = frame_limit(options.beg_frame_last, 2, 0, 15) },
  { first = frame_limit(options.end_frame_first, -3, -15, 0), last = frame_limit(options.end_frame_last, 1, 0, 15) },
}
-- One shared grid: the "0" frames of both rows sit in the same column.
local grid_first = math.min(ranges[1].first, ranges[2].first)
local grid_count = 1 + math.max(ranges[1].last, ranges[2].last) - grid_first
-- "inner" frames come from the clip itself (beg: forward, end: backward),
-- "outer" frames from the source beyond it (beg: before, end: after).
local function inner_count(edge) return 1 + (edge.id == 1 and ranges[1].last or -ranges[2].first) end
local function outer_count(edge) return edge.id == 1 and -ranges[1].first or ranges[2].last end
-- One id per (edge, frame): beg 1..grid_count, end grid_count+1..2*grid_count (mpv allows 0..63).
local function overlay_id(edge, index)
  return (edge.id - 1) * grid_count + index - grid_first + 1
end

-- Frames to move from the marked time to the actual clipping time.
local function offset_option(value, default) return finite(value) and math.floor(value) or default end
local default_offset_beg = offset_option(options.framesnum_offset_beg, -2)
local default_offset_end = offset_option(options.framesnum_offset_end, -3)
local framesnum_offset_beg, framesnum_offset_end = default_offset_beg, default_offset_end
local function frames_offset(edge) return edge.id == 1 and framesnum_offset_beg or framesnum_offset_end end
local function fps()
  local v = mp.get_property_number("container-fps") or mp.get_property_number("estimated-vf-fps")
  return finite(v) and v > 0 and v or nil
end
local function frame_duration() local f = fps(); return f and 1 / f end

-- Per-file video frame times (absolute pts, ascending) from ffprobe: mpv exposes no frame
-- time list, and this makes frame-in-second and whole-frame offsets exact for VFR too.
-- Until loaded (or without ffprobe/local file) everything falls back to constant fps.
local pts_map -- { pts = {...}, start = container start_time }
local function lower_bound(list, x) -- first index with list[i] >= x (#list + 1 if none)
  local lo, hi = 1, #list + 1
  while lo < hi do
    local mid = math.floor((lo + hi) / 2)
    if list[mid] < x then lo = mid + 1 else hi = mid end
  end
  return lo
end
-- Index of the frame displayed at mpv time t (nearest, within ~half a frame).
local function map_index(t)
  local m = pts_map
  if not m or not finite(t) then return end
  local x, i = t + m.start, nil
  local best, dist = nil, (frame_duration() or 0.02) * 0.45
  i = lower_bound(m.pts, x)
  for _, k in ipairs({ i - 1, i }) do
    local p = m.pts[k]
    if p and math.abs(p - x) <= dist then best, dist = k, math.abs(p - x) end
  end
  return best
end

-- Actual clipping time: used by previews and export (the loop uses raw marks).
local function etime(edge)
  local t, off = edge.time, frames_offset(edge)
  if off ~= 0 then
    local i = map_index(t)
    local p = i and pts_map.pts[math.max(1, math.min(#pts_map.pts, i + off))]
    t = p and (p - pts_map.start) or (t + off * (frame_duration() or 0))
  end
  local duration = mp.get_property_number("duration")
  if finite(duration) then t = math.min(t, duration) end
  return math.max(0, t)
end

-- "MM:SS.FF": FF is the 0-based index of the frame inside its integer second, the first one
-- being the first frame with pts >= that second. :frame-step then moves FF (or the seconds).
local function ms_text(t) -- ## ALT (old format, now only the no-fps fallback): MM:SS.mmm
  t = math.floor(t * 1000 + 0.5) / 1000
  return string.format("%02d:%02d.%03d", math.floor(t / 60), math.floor(t % 60),
    math.floor((t - math.floor(t)) * 1000 + 1e-6))
end
local function frame_text(sec, ff)
  local f = fps()
  local digits = f and math.max(2, #tostring(math.ceil(f) - 1)) or 2
  return string.format("%02d:%02d.%0" .. digits .. "d", math.floor(sec / 60), sec % 60, ff)
end
local function timestamp(t)
  local i = map_index(t)
  if i then
    local m = pts_map
    local sec = math.floor(m.pts[i] - m.start + 1e-5)
    return frame_text(sec, i - lower_bound(m.pts, m.start + sec - 1e-5))
  end
  local f = fps()
  if not f then return ms_text(t) end
  local sec = math.floor(t + 1e-6)
  return frame_text(sec, math.max(0, math.floor(t * f + 0.5) - math.ceil(sec * f - 1e-6)))
end
-- A length in the same notation (FF = whole frames beyond the seconds; constant fps).
local function duration_text(d)
  local f = fps()
  if not f then return ms_text(d) end
  local sec = math.floor(d + 1e-6)
  local ff = math.floor((d - sec) * f + 0.5)
  if ff >= math.ceil(f) then sec, ff = sec + 1, 0 end
  return frame_text(sec, ff)
end

local function source_path()
  local path = mp.get_property("path")
  if path and not path:match("^/") and not path:match("^%a[%w+.-]*://") then
    path = utils.join_path(mp.get_property("working-directory") or ".", path)
  end
  return path
end

local function valid_range()
  local a, b = etime(edges[1]), etime(edges[2])
  return finite(a) and finite(b) and a >= 0 and b > a
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
  -- Fixed grid: one row per edge, one column per frame index (the "0" frames align).
  h = math.min(h, (dims.h - top - 2 * PAD) / 2, (dims.w - (grid_count + 1) * PAD) / grid_count / ratio)
  local w = h * ratio
  local x = PAD + ((index or 0) - grid_first) * (w + PAD)
  local y = top + (edge.id - 1) * (h + PAD)
  -- PREV: toggle layout to top-left or top-right for vertical windows
  -- local count = 2 + last_frame - first_frame
  -- local columns = math.max(1, math.min(count, math.floor((dims.w - PAD) / (w + PAD))))
  -- local rows = math.ceil(count / columns)
  -- h = math.min(h, (dims.h - top - rows * PAD) / rows,
  --   (dims.w - (columns + 1) * PAD) / columns / ratio)
  -- w = h * ratio
  -- local slot = edge.id == 1 and 0 or 1 + (index or 0) - first_frame
  -- local x = PAD + (slot % columns) * (w + PAD)
  -- local y = top + math.floor(slot / columns) * (h + PAD)
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

-- drawtext/drawbox pieces shared by every preview command; `n` = frame number in the filter.
-- ## ALT label: frame number round(t*fps) instead of MM:SS.FF (a bare integer, no seconds):
-- ##   tostring(math.floor(t * fps() + 0.5))
local function stamp_of(t) return (timestamp(t):gsub(":", "\\:")) end
local function edge_label(job)
  if job.edge.id == 1 then return "[" .. stamp_of(job.a) end
  return stamp_of(job.b) .. "]"
end
local function text_filter(job, text, n, corner)
  return string.format("drawtext=text='%s':x=%s:y=%s:fontsize=%d:fontcolor=%s:borderw=2:bordercolor=black:enable='eq(n,%d)'",
    text, corner and "w-tw-10" or "10", corner and "10" or "h-th-10", math.max(12, math.floor(job.h * 0.14)),
    corner and "0x00FF00" or "white", n)
end
local function box_filter(job, n)
  return string.format("drawbox=x=0:y=0:w=iw:h=ih:color=0x00FF00:t=%d:enable='eq(n,%d)'",
    math.max(2, math.floor(job.h * 0.025)), n)
end

local function decode_args(job)
  local edge = job.edge
  local beg = edge.id == 1
  local inner, outer = inner_count(edge), outer_count(edge)
  local scale = string.format("scale=%d:%d", job.w, job.h)
  -- Inner frames: beg reads the sample forward, end reads it reversed (nearest first).
  local filter = scale .. (beg and "" or (",reverse,trim=end_frame=" .. inner))
    .. "," .. box_filter(job, 0) .. "," .. text_filter(job, edge_label(job), 0)
  if job.offset ~= 0 then filter = filter .. "," .. text_filter(job, string.format("%+d", job.offset), 0, true) end
  for i = 1, inner - 1 do
    filter = filter .. "," .. text_filter(job, string.format("%+d", beg and i or -i), i)
  end
  local args = { "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-copyts",
    "-i", job.clip }
  local function append(values)
    for _, value in ipairs(values) do args[#args + 1] = value end
  end
  if outer > 0 and job.anchor then
    job.context_start = math.max(0, math.floor(job.anchor) - 1)
    append({ "-ss", tostring(job.context_start) })
    -- PERF: beg uses `reverse`, which only emits at input EOF: without -t the whole
    -- rest of the file is decoded (measured 14s vs 0.2s). End has no reverse, -frames:v stops it.
    if beg then append({ "-t", tostring(job.anchor - job.context_start + 0.5) }) end
    append({ "-i", job.path })
  end
  append({ "-map", "0:v:0", "-an", "-sn", "-dn", "-vf", filter,
    "-pix_fmt", "bgra", "-fps_mode", "passthrough", "-frames:v", tostring(inner),
    "-f", "rawvideo", job.raw })
  if outer > 0 and job.anchor then
    -- Source context only: these frames are outside the converted clip.
    local context
    if beg then
      context = string.format("select='lt(t,%.9f)',%s,reverse,trim=end_frame=%d",
        job.absolute_anchor - 0.000002, scale, outer)
      for i = 1, outer do context = context .. "," .. text_filter(job, string.format("%+d", -i), i - 1) end
    else
      context = string.format("select='gt(t,%.9f)',%s", job.absolute_anchor + 0.000002, scale)
      for i = 1, outer do context = context .. "," .. text_filter(job, "+" .. i, i - 1) end
    end
    append({ "-map", "1:" .. job.source_track, "-an", "-sn", "-dn", "-vf", context,
      "-pix_fmt", "bgra", "-fps_mode", "passthrough", "-frames:v", tostring(outer),
      "-f", "rawvideo", job.after })
  end
  return args
end

-- Index complete raw frames without copying or launching per-frame decoders.
local function retain_frame(job)
  local edge = job.edge
  local beg = edge.id == 1
  local info, bytes = utils.file_info(job.raw), job.w * job.h * 4
  if info and info.size == 0 then return nil, "empty" end
  if not info or info.size < bytes or info.size % bytes ~= 0 then
    return nil, "incomplete raw frame"
  end
  job.frames = {}
  for i = 0, math.min(info.size / bytes, inner_count(edge)) - 1 do
    job.frames[#job.frames + 1] = { index = beg and i or -i, file = job.raw, offset = i * bytes }
  end
  if outer_count(edge) > 0 then
    if not job.anchor then return nil, "cannot locate boundary output frame in source" end
    local after = utils.file_info(job.after)
    if not after or after.size % bytes ~= 0 then return nil, "incomplete context frame" end
    for i = 0, math.min(outer_count(edge), after.size / bytes) - 1 do
      job.frames[#job.frames + 1] = { index = beg and -(i + 1) or i + 1, file = job.after, offset = i * bytes }
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
    if #job.frames < inner_count(job.edge) + outer_count(job.edge) then
      local info = utils.file_info(job.raw)
      if info.size / (job.w * job.h * 4) < inner_count(job.edge) and retry_empty(job) then return end
    end
    publish(job)
  end, function(err)
    -- Audio may outlast video, leaving the initial sample without a video track.
    return (err:find("does not contain any stream", 1, true)
      or err:find("matches no streams", 1, true)) and retry_empty(job)
  end)
end

-- Boundary packet: latest PTS for the end edge, earliest for the beg edge.
local function extreme(edge, t, best)
  return not best or (edge.id == 1 and t < best or edge.id == 2 and t > best)
end

local function execute_plan(job, commands, index)
  if index > #commands then decode_job(job); return end
  local command = commands[index]
  local seek
  if outer_count(job.edge) > 0 and index == 1 then
    -- muxer timestamps precede container timestamp normalization. Track the
    -- boundary emitted video packet (end: last, beg: first), including
    -- reordered frames beyond the mark.
    for i, value in ipairs(command) do if value == "-ss" then seek = tonumber(command[i + 1]) end end
    if not seek and job.edge.id == 1 then seek = 0 end -- Unseeked beg starts at the source start.
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
          if finite(t) and extreme(job.edge, t, last) then last = t end
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
            if finite(t) and extreme(job.edge, t, last) then last = t end
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
      mp.msg.debug("preview[" .. job.edge.name .. "] source anchor: mux=" .. tostring(last) ..
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

-- Beg row straight from the source around the actual clip start: each frame is addressed
-- by its own pts, so every offset press shifts the row by exactly one frame.
-- ## ALT (options.beg_source=false): converter sample + source context. Shows what the mode
-- ##   really produces, but copy mode starts at a keyframe, so "0" need not sit at `a` and the
-- ##   context frames are anchored on the first muxed packet instead -> offsets looked inert.
local function source_args(job)
  local first, last = ranges[1].first, ranges[1].last
  local fd = frame_duration() or 0.04
  local m, i = pts_map, map_index(job.a)
  local lo, hi, n0, total
  if i then
    local lo_i, hi_i = math.max(1, i + first), math.min(#m.pts, i + last)
    lo, hi = m.pts[lo_i] - m.start - 0.0004, m.pts[hi_i] - m.start + 0.0004
    n0, total = i - lo_i, hi_i - lo_i + 1
  else -- no frame map (yet): constant frame rate guess
    n0 = math.min(-first, math.max(0, math.floor(job.a / fd + 0.5)))
    lo, hi, total = job.a - (n0 + 0.5) * fd, job.a + (last + 0.5) * fd, n0 + 1 + last
  end
  -- Without -copyts, t restarts at the -ss point; -t keeps the read short.
  local seek = math.max(0, lo - 1)
  local filter = string.format("select='between(t,%.6f,%.6f)',scale=%d:%d,%s,%s", lo - seek, hi - seek,
    job.w, job.h, box_filter(job, n0), text_filter(job, edge_label(job), n0))
  if job.offset ~= 0 then filter = filter .. "," .. text_filter(job, string.format("%+d", job.offset), n0, true) end
  for k = 0, total - 1 do
    if k ~= n0 then filter = filter .. "," .. text_filter(job, string.format("%+d", k - n0), k) end
  end
  return { "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
    "-ss", tostring(seek), "-t", tostring(hi - seek + 0.5), "-i", job.path,
    "-map", "0:v:0", "-an", "-sn", "-dn", "-vf", filter, "-pix_fmt", "bgra",
    "-fps_mode", "passthrough", "-frames:v", tostring(total), "-f", "rawvideo", job.raw }, n0
end

local function source_job(job)
  local args, n0 = source_args(job)
  run_job(job, args, function()
    local info, bytes = utils.file_info(job.raw), job.w * job.h * 4
    if not info or info.size < bytes or info.size % bytes ~= 0 then
      fail(job.edge, info and info.size == 0 and "no video frame near beg" or "incomplete raw frame")
      return
    end
    job.frames = {}
    for k = 0, info.size / bytes - 1 do
      job.frames[#job.frames + 1] = { index = k - n0, file = job.raw, offset = k * bytes }
    end
    publish(job)
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
  local a, b = etime(edges[1]), etime(edges[2])
  local job = {
    edge = edge, path = path, a = a, b = b, mode = state.mode, offset = frames_offset(edge),
    raw = raw, after = raw .. ".after", stats = raw .. ".stats",
    clip = raw .. "." .. ext, window = WINDOW,
    limit = math.min(b - a, options.preview_window_limit),
    w = math.max(1, math.floor(w * factor)), h = math.max(1, math.floor(h * factor)),
  }
  edge.job, jobs[job] = job, true
  if edge.id == 1 and options.beg_source then job.source = true; source_job(job) else sample_job(job) end
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
  if not job or job.path ~= source_path() then return false end
  local a, b = etime(edges[1]), etime(edges[2])
  local unchanged
  if job.source then
    unchanged = job.a == a -- beg source row ignores the mode and the other edge
  elseif job.mode ~= state.mode then
    return false
  elseif state.mode ~= "smart" then
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
        and (edge.id == 1 and cached.a or cached.b) == etime(edge)
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

-- Looping is a switch over the markers: toggling never touches edge times.
-- Raw marker times (wysiwyg in mpv); offsets only compensate the ffmpeg cut discrepancy.
local function apply_loop()
  mp.set_property("ab-loop-a", state.loop and edges[1].time or "no")
  mp.set_property("ab-loop-b", state.loop and edges[2].time or "no")
end

local function toggle_loop()
  state.loop = not state.loop
  apply_loop()
  status("info", "loop " .. (state.loop and "on" or "off"))
end

local function show_duration()
  mp.set_property("osd-align-x", "left")
  mp.set_property("osd-align-y", "top")
  mp.osd_message("duration: " .. duration_text(etime(edges[2]) - etime(edges[1])), 999999)
end

local function mark(edge)
  local t = mp.get_property_number("playback-time")
  if not finite(t) or t < 0 then return end
  edge.time, edge.marked = t, true
  -- Unmarked end = EOF, so beg alone is a valid range and previews at once.
  if edge.id == 1 and not edges[2].marked and edges[2].time <= t then
    local duration = mp.get_property_number("duration")
    if finite(duration) and duration > t then edges[2].time = duration end
  end
  local other = edges[3 - edge.id]
  other.time = edge.id == 1 and math.max(t, other.time) or math.min(t, other.time)
  state.loop = true
  apply_loop()
  refresh_previews(edge)
  show_duration()
end

-- Shift one edge's actual clipping time by whole frames (loop is unaffected).
local function shift_offset(edge, delta)
  if not frame_duration() then status("error", "unknown frame rate"); return end
  if edge.id == 1 then framesnum_offset_beg = framesnum_offset_beg + delta
  else framesnum_offset_end = framesnum_offset_end + delta end
  refresh_previews(edge)
  if edges[1].marked or edges[2].marked then show_duration() end
end

local function seek(edge, mode)
  mp.set_property("pause", "yes")
  mp.commandv("seek", edge.time, "absolute", mode)
  status("info", string.format("seek %s %s (%s)", edge.name, timestamp(edge.time), mode))
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
  local a, b = etime(edges[1]), etime(edges[2])
  status("info", string.format("ENCODING %s dt=%s", mode, duration_text(b - a)))
  subprocess({ options.converter, path, tostring(a), tostring(b), mode },
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

-- Async: ffprobe reads every video packet time (may take a while for big files).
local function load_pts_map(path)
  pts_map = nil
  if not path or path:match("^%a[%w+.-]*://") then return end
  subprocess({ "ffprobe", "-v", "error", "-select_streams", "v:0",
    "-show_entries", "packet=pts_time:format=start_time", "-of", "compact", path },
    false, function(result, err)
      if path ~= source_path() then return end
      if not result then mp.msg.warn("frame map unavailable: " .. tostring(err)); return end
      local pts, start = {}, 0
      for line in (result.stdout or ""):gmatch("[^\r\n]+") do
        local p = tonumber(line:match("^packet|pts_time=([%d.eE+%-]+)"))
        if p then pts[#pts + 1] = p else start = tonumber(line:match("^format|start_time=([%d.eE+%-]+)")) or start end
      end
      if #pts == 0 then return end
      table.sort(pts)
      pts_map = { pts = pts, start = start }
      mp.msg.debug("frame map: " .. #pts .. " frames, start " .. start)
      if edges[1].marked or edges[2].marked then refresh_previews() end
    end)
end

-- Register callbacks only after every helper is defined.
mp.register_event("file-loaded", function()
  local a, loop_b = mp.get_property_number("ab-loop-a"), mp.get_property_number("ab-loop-b")
  local b = loop_b or mp.get_property_number("duration/full") or mp.get_property_number("duration")
  state.loop = finite(a) or finite(loop_b)
  framesnum_offset_beg, framesnum_offset_end = default_offset_beg, default_offset_end
  load_pts_map(source_path())
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
  clip_toggle_loop = toggle_loop,
  clip_offset_beg_dec = function() shift_offset(edges[1], -1) end,
  clip_offset_beg_inc = function() shift_offset(edges[1], 1) end,
  clip_offset_end_dec = function() shift_offset(edges[2], -1) end,
  clip_offset_end_inc = function() shift_offset(edges[2], 1) end,
}
for name, callback in pairs(bindings) do mp.add_key_binding("", name, callback) end
