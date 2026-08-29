-- vim:ft=lua:ts=2:sw=2:sts=2
--%USAGE:
--% * Clip video from between two marks '[' and ']'
--% * Seek to placed marks 'S-[' and 'S-]'
--% * Convert by 'r.ffmpeg <path> <beg> <end>' on 'y'
--%DEBUG: mpv --msg-level=all=info yourfile.mkv (or check ~/.cache/mpv/mpv.log)

local g = { A = 0.0, B = 0.0 }


-- ============================================================
-- Preview overlay module — insert after `local g = { A = 0.0, B = 0.0 }`
-- in the original script, before the "Behaviour" section.
-- ============================================================

local utils = require 'mp.utils'

local DEBUG = true -- set false to silence dbg() once stable

local function dbg(fmt, ...)
  if DEBUG then
    mp.msg.log("info", "[preview] " .. string.format(fmt, ...))
  end
end

local PREVIEW_WINDOW_S  = 2.0   -- seconds of copy-cut around each mark to sample
local PREVIEW_FRACTION  = 0.20 -- previews must reach this fraction of orig video size
local PAD               = 10
local SHRINK_STEP       = 0.05 -- how much to shrink video-margin-ratio per attempt
local MAX_SHRINK        = 0.5  -- don't reserve more than 50% of a dimension
local OVERLAY_ID = { A = 1, B = 2 }
local TMP = {
  A = { clip = "/tmp/mpv_preview_A.mkv", raw = "/tmp/mpv_preview_A.raw" },
  B = { clip = "/tmp/mpv_preview_B.mkv", raw = "/tmp/mpv_preview_B.raw" },
}

-- (no reservation/shrinking -- we only use slack that already exists)

-- Helpers
local function show_status(t, msg)
  mp.msg.log(t, msg)
  mp.osd_message(t .. ": " .. msg, 2)
end


-- ---- layout ---------------------------------------------------
-- Uses mpv's actual video-out rect (dwidth/dheight give window size;
-- osd-width/height already reflect any video-margin-ratio-* reservation,
-- since those margins are subtracted from the video's drawable area, not
-- from the OSD canvas -- so we compute displayed-video rect ourselves
-- against the POST-MARGIN osd size).

local function get_video_rect()
  local dims = mp.get_property_native("osd-dimensions")
  local vid_w = mp.get_property_native("width")
  local vid_h = mp.get_property_native("height")
  dbg("raw osd-dimensions = %s vid_w=%s vid_h=%s",
    dims and utils.format_json(dims) or "NIL", tostring(vid_w), tostring(vid_h))
  if not (dims and vid_w and vid_h and vid_w > 0 and vid_h > 0) then
    dbg("get_video_rect: bailing, missing/invalid property")
    return nil
  end
  -- osd-dimensions gives: w, h (full osd canvas) and ml, mr, mt, mb
  -- (margins already carved out of that canvas -- by our own
  -- video-margin-ratio-* AND by the OSC's own box-video reservation,
  -- whichever is larger/active). The video is displayed inside the
  -- REMAINING w-ml-mr by h-mt-mb rect, aspect-fit.
  local osd_w, osd_h = dims.w, dims.h
  local ml, mr, mt, mb = dims.ml or 0, dims.mr or 0, dims.mt or 0, dims.mb or 0
  if not (osd_w and osd_h and osd_w > 0 and osd_h > 0) then
    dbg("get_video_rect: bailing, bad osd_w/h in dims")
    return nil
  end

  local canvas_w = osd_w - ml - mr
  local canvas_h = osd_h - mt - mb
  if canvas_w <= 0 or canvas_h <= 0 then
    dbg("get_video_rect: bailing, non-positive canvas (%.1f x %.1f)", canvas_w, canvas_h)
    return nil
  end

  local vid_ar = vid_w / vid_h
  local canvas_ar = canvas_w / canvas_h

  local disp_w, disp_h
  if canvas_ar > vid_ar then
    disp_h = canvas_h; disp_w = disp_h * vid_ar
  else
    disp_w = canvas_w; disp_h = disp_w / vid_ar
  end

  -- extra slack beyond the aspect-fit video, WITHIN the already-reserved
  -- canvas (i.e. pillarbox/letterbox space mpv leaves automatically)
  local slack_x = canvas_w - disp_w
  local slack_y = canvas_h - disp_h

  dbg("rect canvas=%.1fx%.1f (ml=%.1f mr=%.1f mt=%.1f mb=%.1f) disp=%.1fx%.1f slack_x=%.1f slack_y=%.1f",
    canvas_w, canvas_h, ml, mr, mt, mb, disp_w, disp_h, slack_x, slack_y)

  return {
    osd_w = osd_w, osd_h = osd_h,
    canvas_w = canvas_w, canvas_h = canvas_h,
    ml = ml, mr = mr, mt = mt, mb = mb,
    vid_ar = vid_ar,
    disp_w = disp_w, disp_h = disp_h,
    -- video's top-left within the FULL osd canvas (for overlay coordinates)
    disp_x = ml + (canvas_w - disp_w) / 2,
    disp_y = mt + (canvas_h - disp_h) / 2,
    margin_x = slack_x,   -- pillarbox slack, within reserved canvas
    margin_y = slack_y,   -- letterbox slack, within reserved canvas
  }
end

-- Decide mode + preview size. If neither margin can hit PREVIEW_FRACTION of
-- original video size at current reservation, increase reservation and
-- recompute (iteratively) instead of falling back to overlap.
-- Instead of set_margins/clear_margins, calculate overlay positions directly
local function compute_layout()
  local dims = mp.get_property_native("osd-dimensions")
  if not dims then return nil end

  -- Get the source video dimensions
  local vid_w, vid_h
  pcall(function()
    vid_w = mp.get_property_number("width")
    vid_h = mp.get_property_number("height")
  end)

  -- Handle video rotation: if the container has 90/270° rotation,
  -- the display dimensions are swapped relative to the source.
  -- Without this, phone-recorded vertical videos (stored as rotated
  -- landscape) are misidentified as horizontal, distorting previews.
  local rot
  pcall(function() rot = mp.get_property_number("video-rotation") end)
  if rot and (rot == 90 or rot == 270) and vid_w and vid_h then
    vid_w, vid_h = vid_h, vid_w
  end

  -- Fallback if video params not available
  if not vid_w or not vid_h or vid_w <= 0 or vid_h <= 0 then
    if dims.w > dims.h then
      vid_w, vid_h = 1920, 1080
    else
      vid_w, vid_h = 1080, 1920
    end
  end

  local canvas_w = dims.w
  local canvas_h = dims.h
  local vid_aspect = vid_w / vid_h
  local is_vertical = vid_h > vid_w

  if is_vertical then
    -- Portrait source video: place previews on the right side
    local available_width = canvas_w - dims.ml - dims.mr
    -- Preview width is 30% of available width
    local preview_w = math.floor(available_width * PREVIEW_FRACTION)
    -- Calculate height preserving source aspect ratio
    -- For vertical video, height should be greater than width
    local preview_h = math.floor(preview_w / vid_aspect)

    -- If preview is too tall, constrain by height
    local max_preview_h = math.floor(canvas_h * 0.8)
    if preview_h > max_preview_h then
      preview_h = max_preview_h
      -- Maintain aspect ratio
      preview_w = math.floor(preview_h * vid_aspect)
    end

    local avail_width_for_disp = available_width - preview_w - PAD * 2
    local disp_w = avail_width_for_disp
    local disp_h = canvas_h - dims.mt - dims.mb

  return {
      mode = "right",
      ml = dims.ml,
      mr = dims.mr,
      mt = dims.mt,
      mb = dims.mb,
      canvas_w = dims.w,
      canvas_h = dims.h,
      disp_w = disp_w,
      disp_h = disp_h,
      vid_w = vid_w,
      vid_h = vid_h,
      vid_aspect = vid_aspect,
      margin_x = preview_w,
      margin_y = 0,
      is_vertical = is_vertical,
      preview_w = preview_w,
      preview_h = preview_h
    }
  else
    -- Landscape source video: place previews at top of window
    local available_height = canvas_h - dims.mt - dims.mb
    -- Preview height is 30% of available height (two previews side by side)
    local preview_h = math.floor(available_height * PREVIEW_FRACTION)
    -- Calculate width preserving source aspect ratio
    local preview_w = math.floor(preview_h * vid_aspect)

    -- If preview is too wide, constrain by width (each preview up to half canvas)
    local max_preview_w = math.floor((canvas_w - dims.ml - dims.mr - PAD) / 2)
    if preview_w > max_preview_w then
      preview_w = max_preview_w
      -- Maintain aspect ratio
      preview_h = math.floor(preview_w / vid_aspect)
    end

    -- Reserve space at top for previews; video displays below
    local avail_height_for_disp = available_height - preview_h - PAD * 2
    local disp_w = canvas_w - dims.ml - dims.mr
    local disp_h = avail_height_for_disp

    return {
      mode = "top",
      ml = dims.ml,
      mr = dims.mr,
      mt = dims.mt,
      mb = dims.mb,
      canvas_w = dims.w,
      canvas_h = dims.h,
      disp_w = disp_w,
      disp_h = disp_h,
      vid_w = vid_w,
      vid_h = vid_h,
      vid_aspect = vid_aspect,
      margin_x = 0,
      margin_y = preview_h,
      is_vertical = is_vertical,
      preview_w = preview_w,
      preview_h = preview_h
    }
  end
end


local function preview_geometry(which, layout)
  -- Use the preview dimensions calculated in compute_layout
  local pw = layout.preview_w
  local ph = layout.preview_h

  if layout.mode == "right" then
    -- Previews on the right side of the video
    -- OLD: Position relative to the displayed video area
    -- Previews anchored to the right edge of the mpv window (canvas)
    local px = layout.canvas_w - layout.preview_w - PAD
    local py = layout.mt

    -- For vertical video, stack previews vertically
    if which == 'A' then
      return math.floor(px), math.floor(py), pw, ph
    else
      -- Preview B goes below preview A
      return math.floor(px), math.floor(py + ph + PAD), pw, ph
    end
  else
    -- -- Previews at top of window (horizontal video)
    -- local px = layout.ml
    -- local py = layout.mt
    -- Previews anchored to the top of the mpv window (canvas)
    local px = layout.ml
    local py = 0

    if which == 'A' then
      return math.floor(px), math.floor(py), pw, ph
    else
      return math.floor(px + pw + PAD), math.floor(py), pw, ph
    end
  end
end

-- ---- overlay lifecycle ---------------------------------------

local active_overlay = { A = false, B = false }
local mark_set = { A = false, B = false }
local previews_hidden = false

-- Helper: read osc-visibility from either native property or script-opts
local function read_osc_visibility()
  local vis
  pcall(function() vis = mp.get_property_native("osc-visibility") end)
  if not vis then
    pcall(function() vis = mp.get_property_native("script-opts/osc-visibility") end)
  end
  return vis or "auto"
end

-- Check initial osc-visibility
pcall(function()
  if read_osc_visibility() == "never" then
    previews_hidden = true
  end
end)

-- generation counter: bumped on every preview_cut(which) call. An in-flight
-- async chain captures its generation at start; if a newer call for the same
-- 'which' has started by the time it finishes, it's obsolete and must not
-- touch the overlay (prevents flicker/wrong-placement from rapid resize
-- events firing several overlapping preview_cut chains).
local generation = { A = 0, B = 0 }

local function overlay_remove(which)
  if active_overlay[which] then
    pcall(mp.command_native, { name = "overlay-remove", id = OVERLAY_ID[which] })
    active_overlay[which] = false
  end
end

-- ---- core: cut a short window, decode boundary frame, overlay ----

local function preview_cut(which)
  dbg("preview_cut(%s) called, g.A=%.3f g.B=%.3f", which, g.A, g.B)
  local path = mp.get_property_native("path")
  if not path then
    dbg("preview_cut(%s): no path, bailing", which)
    return
  end

  generation[which] = generation[which] + 1
  local my_gen = generation[which]
  dbg("preview_cut(%s): generation=%d", which, my_gen)

  local layout = compute_layout()
  if not layout then
    show_status("warn", "preview: layout not ready")
    dbg("preview_cut(%s): compute_layout returned nil", which)
    return
  end
  local x, y, w, h = preview_geometry(which, layout)
  dbg("preview_cut(%s): mode=%s x=%d y=%d w=%d h=%d", which, layout.mode, x, y, w, h)
  if w < 16 or h < 16 then
    dbg("preview_cut(%s): w/h too small, bailing", which)
    return
  end

  local tmp = TMP[which]
  local cut_args
  if which == 'A' then
    -- A is decoded directly below; no temporary clip or re-encode is needed.
    cut_args = {}
  else
    local ss = math.max(0, g.B - PREVIEW_WINDOW_S)
    cut_args = { "-ss", tostring(ss), "-i", path,
                 "-t", tostring(PREVIEW_WINDOW_S), "-codec", "copy", tmp.clip }
    -- NOTE: using -t (duration) not -to, since -to's reference point (absolute
    -- vs relative-to-ss) varies across ffmpeg versions. -t is unambiguous:
    -- always "duration from this -ss point," which is what we want here.
  end

  local cut_full
  if which == 'A' then
    -- Use a cheap FFmpeg probe as the async handoff; the actual A frame is
    -- decoded directly from the source below.
    cut_full = { "ffmpeg", "-hide_banner", "-version" }
  else
    local full_cut_args = { "-y", "-hide_banner", "-loglevel", "error" }
    for _, v in ipairs(cut_args) do table.insert(full_cut_args, v) end
    cut_full = (function()
      local a = { "ffmpeg" }
      for _, v in ipairs(full_cut_args) do table.insert(a, v) end
      return a
    end)()
  end
  dbg("preview_cut(%s): cut cmd = %s", which, table.concat(cut_full, " "))

  mp.command_native_async({
    name = "subprocess", playback_only = false,
    capture_stdout = true, capture_stderr = true,
    args = cut_full
  }, function(ok, res)
    dbg("preview_cut(%s): cut result ok=%s status=%s stderr=%s", which,
      tostring(ok), tostring(res and res.status), tostring(res and res.stderr))
    if not ok or res == nil or res.status ~= 0 then
      show_status("error", "preview[" .. which .. "] cut failed: " ..
        ((res and res.stderr) or "unknown"))
      return
    end
    if my_gen ~= generation[which] then
      dbg("preview_cut(%s): superseded (gen %d != current %d) after cut, abandoning",
        which, my_gen, generation[which])
      return
    end

    -- which frame within the short clip: 'A' -> first frame, 'B' -> last frame
    local frame_flag
    local decode_input = tmp.clip
    if which == 'A' then
      -- The stream-copied temporary file can contain packets before g.A.
      -- Decode the original at the selected timestamp so the preview matches
      -- the first frame mpv displays after opening the copied clip.
      frame_flag = { "-ss", tostring(math.max(0, g.A)) }
      decode_input = path
    else
      frame_flag = { "-sseof", "-0.05" }
    end

    local label
    if which == 'A' then
      label = to_ffmpeg_sfx(g.A)
    else
      label = to_ffmpeg_sfx(g.B)
    end
    -- Colons are option separators in the drawtext filter, so escape them.
    local drawtext_label = label:gsub(":", "\\:")
    local preview_filter = string.format(
      "scale=%d:%d,drawtext=text='%s':x=10:y=h-th-10:fontsize=%d:fontcolor=white:borderw=2:bordercolor=black",
      w, h, drawtext_label, math.max(12, math.floor(h * 0.14)))

    local stride = w * 4
    local decode_args = { "ffmpeg", "-y", "-hide_banner", "-loglevel", "error" }
    if which == 'A' then
      -- Output-side seek makes this decoded frame timestamp-accurate.
      table.insert(decode_args, "-i")
      table.insert(decode_args, decode_input)
      table.insert(decode_args, frame_flag[1])
      table.insert(decode_args, frame_flag[2])
    else
      table.insert(decode_args, frame_flag[1])
      table.insert(decode_args, frame_flag[2])
      table.insert(decode_args, "-i")
      table.insert(decode_args, decode_input)
    end
    table.insert(decode_args, "-vframes")
    table.insert(decode_args, "1")
    table.insert(decode_args, "-vf")
    table.insert(decode_args, preview_filter)
    table.insert(decode_args, "-pix_fmt")
    table.insert(decode_args, "bgra")
    table.insert(decode_args, "-f")
    table.insert(decode_args, "rawvideo")
    table.insert(decode_args, tmp.raw)

    dbg("preview_cut(%s): decode cmd = %s", which, table.concat(decode_args, " "))

    mp.command_native_async({
      name = "subprocess", playback_only = false,
      capture_stdout = true, capture_stderr = true,
      args = decode_args
    }, function(ok2, res2)
      dbg("preview_cut(%s): decode result ok=%s status=%s stderr=%s", which,
        tostring(ok2), tostring(res2 and res2.status), tostring(res2 and res2.stderr))
      if not ok2 or res2 == nil or res2.status ~= 0 then
        show_status("error", "preview[" .. which .. "] decode failed: " ..
          ((res2 and res2.stderr) or "unknown"))
        return
      end
      if my_gen ~= generation[which] then
        dbg("preview_cut(%s): superseded (gen %d != current %d) after decode, abandoning",
          which, my_gen, generation[which])
        return
      end

      -- sanity: confirm the raw file actually exists and is the expected size
      -- before handing its path to overlay-add. A short/missing/mismatched
      -- file is a strong candidate for crashing mpv's overlay code, since
      -- overlay-add reads `stride*h` bytes from it unconditionally.
      local finfo = utils.file_info(tmp.raw)
      local expect_bytes = stride * h
      dbg("preview_cut(%s): raw file info = %s expect_bytes=%d", which,
        finfo and utils.format_json(finfo) or "NIL", expect_bytes)
      if not finfo or finfo.size ~= expect_bytes then
        dbg("preview_cut(%s): raw file size mismatch/missing, ABORTING overlay-add", which)
        show_status("error", "preview[" .. which .. "] raw file bad, skipping overlay")
        return
      end

      -- re-fetch layout/geometry: window may have resized during the two
      -- async round-trips; stale x/y/w/h would misplace or wrong-size overlay
      local layout2 = compute_layout()
      if not layout2 then
        dbg("preview_cut(%s): layout2 nil after decode, bailing", which)
        return
      end
      local x2, y2, w2, h2 = preview_geometry(which, layout2)
      if w2 ~= w or h2 ~= h then
        dbg("preview_cut(%s): size drifted (%d,%d)->(%d,%d), skipping this frame",
          which, w, h, w2, h2)
        return
      end

      -- Don't add overlay if previews have been hidden (osc-visibility=never)
      if previews_hidden then
        dbg("preview_cut(%s): previews hidden, not adding overlay", which)
        return
      end

      local ov_id = OVERLAY_ID[which]
      dbg("preview_cut(%s): overlay-add id=%d x=%d y=%d file=%s w=%d h=%d stride=%d dw=%d dh=%d",
        which, ov_id, x2, y2, tmp.raw, w2, h2, stride, w2, h2)

      local ok3, err3 = pcall(mp.command_native, {
        name = "overlay-add",
        id = ov_id,
        x = x2,
        y = y2,
        file = tmp.raw,
        offset = 0,
        fmt = "bgra",
        w = w2,
        h = h2,
        stride = stride,
        dw = w2,   -- explicit: docs default dw/dh to w/h if omitted, but
        dh = h2,   -- named-arg command warns not to rely on defaults either
      })
      if not ok3 then
        dbg("preview_cut(%s): overlay-add THREW: %s", which, tostring(err3))
        show_status("error", "overlay-add failed: " .. tostring(err3))
        return
      end
      active_overlay[which] = true
      dbg("preview_cut(%s): overlay-add OK", which)
    end)
  end)
end

-- ---- debounce wrapper (avoid firing ffmpeg on every tiny nudge) ----

local debounce_timers = { A = nil, B = nil }
local DEBOUNCE_S = 0.15

local function preview_cut_debounced(which)
  if previews_hidden then
    dbg("preview_cut_debounced(%s): hidden, skipping", which)
    return
  end
  if debounce_timers[which] then
    debounce_timers[which]:kill()
  end
  debounce_timers[which] = mp.add_timeout(DEBOUNCE_S, function()
    debounce_timers[which] = nil
    preview_cut(which)
  end)
end

-- ---- reposition on window resize (content unchanged, just re-run) ----

local resize_timer = nil
mp.observe_property("osd-dimensions", "native", function()
  if suppress_resize_handler then
    dbg("osd-dimensions fired but suppressed (self-triggered by apply_reserve)")
    return
  end
  if resize_timer then resize_timer:kill() end
  resize_timer = mp.add_timeout(0.35, function()
    resize_timer = nil
    if active_overlay.A then preview_cut('A') end
    if active_overlay.B then preview_cut('B') end
  end)
end)

-- Hide previews when osc-visibility=never, show again when restored
local function on_osc_visibility_change()
  local vis = read_osc_visibility()
  dbg("osc-visibility: %s", vis)
  if vis == "never" then
    previews_hidden = true
    preview_hide()
  elseif previews_hidden then
    previews_hidden = false
    if mark_set.A then preview_cut('A') end
    if mark_set.B then preview_cut('B') end
  end
end

-- FAIL: doesn't seem to work; was forced to change keybinding
pcall(function() mp.observe_property("osc-visibility", "native", on_osc_visibility_change) end)
pcall(function() mp.observe_property("script-opts/osc-visibility", "native", on_osc_visibility_change) end)

-- ---- clear overlays when marks are cleared / clip written ----

local function preview_hide()
  overlay_remove('A')
  overlay_remove('B')
end

local function preview_clear()
  preview_hide()
  mark_set.A = false
  mark_set.B = false
end


-- Toggle previews + osc-visibility via keybinding (';' key)
mp.register_script_message("clip_toggle_previews", function()
  if previews_hidden then
    previews_hidden = false
    pcall(function() mp.commandv("set", "osc-visibility", "always") end)
    if mark_set.A then preview_cut('A') end
    if mark_set.B then preview_cut('B') end
  else
    previews_hidden = true
    pcall(function() mp.commandv("set", "osc-visibility", "never") end)
    preview_hide()
  end
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
  g.A = mp.get_property_number("playback-time")
  -- print(g.A)
  g.B = math.max(g.A, g.B)
  -- HACK: loop the snippet; clear it manually
  mp.set_property("ab-loop-a", g.A)
  mp.set_property("ab-loop-b", g.B)
  mark_update('<')
  mark_set.A = true
  update_duration_overlay()
  preview_cut_debounced('A')
end
function h_mark_end()
  g.B = mp.get_property_number("playback-time")
  -- print(g.B)
  g.A = math.min(g.A, g.B)
  mp.set_property("ab-loop-a", g.A)
  mp.set_property("ab-loop-b", g.B)
  mark_update('>')
  mark_set.B = true
  update_duration_overlay()
  preview_cut_debounced('B')
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
      -- BET? wrap in tmux BUT I won't be able to read errors on FAIL
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
  preview_clear()
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
