local options = require 'mp.options'

-- Define a custom flag. By default, it is 'no' (false)
local user_configs = { stitch = false }
-- Read variables passed from the command line (--script-opts)
options.read_options(user_configs, "hstack")

-- ============================================================ DEBUG CONFIG
-- Set to true to enable verbose logging to console
-- Run mpv with --log-file=mpv.log to capture output
local DEBUG = true

local function log_debug(msg)
  if DEBUG then
    mp.msg.info("[diff.lua] " .. msg)
  end
end

-- ============================================================ DIMENSION CACHE
-- Store original video dimensions before any filter is applied
-- This prevents reading post-filter dimensions when in hstack mode
local orig_h1, orig_w1, orig_h2, orig_w2

local function cache_dimensions()
  orig_h1 = mp.get_property_number("video-params/h")
  orig_w1 = mp.get_property_number("video-params/w")
  local t2 = second_video_track()
  orig_h2 = t2 and (t2["demux-h"] or t2["height"])
  orig_w2 = t2 and (t2["demux-w"] or t2["width"])
  log_debug(string.format("cache_dimensions: h1=%s w1=%s h2=%s w2=%s",
    tostring(orig_h1), tostring(orig_w1), tostring(orig_h2), tostring(orig_w2)))
end

local function get_cached_dims()
  return orig_h1, orig_w1, orig_h2, orig_w2
end

-- ============================================================

local G1               = "[vid1] copy [vo]; [aid1] anull [ao]"
local G2               = "[vid2] copy [vo]; [aid2] anull [ao]"

---------------------------------------------------------------- waveform config

local waveform_enabled = false
local WAVE_H           = 80              -- height of the waveform bar (px)
local WAVE_MODE        = "cline"         -- p2p | cline | point | line
local WAVE_RATE        = 25              -- fps of the generated waveform video
local WAVE_COLOR1      = "0x00FF88@0.75" -- green  (vid1)
local WAVE_COLOR2      = "0x00CCFF@0.75" -- cyan   (vid2)
local WAVE_BG          = 0.35            -- opacity of the dark backdrop strip

---------------------------------------------------------------- helpers (MUST come before cache_dimensions)

local function second_video_track()
  local n = 0
  for _, t in ipairs(mp.get_property_native("track-list") or {}) do
    if t.type == "video" then
      n = n + 1
      if n == 2 then return t end
    end
  end
end

local function has_vf(label)
  for _, f in ipairs(mp.get_property_native("vf") or {}) do
    if f.label == label then return true end
  end
  return false
end

local function set_graph(graph)
  log_debug("Setting lavfi-complex graph:")
  log_debug(graph)
  mp.set_property("lavfi-complex", graph)
end

-- slow: re-decode from keyframe to current pos (fixes dav1d OBU errors after stitch change)
local function refresh()
  local pos = mp.get_property_number("time-pos")
  if pos then mp.commandv("seek", tostring(pos), "absolute+exact") end
end

---------------------------------------------------------------- DIMENSION CACHE (now safe to call second_video_track)

local orig_h1, orig_w1, orig_h2, orig_w2

local function cache_dimensions()
  orig_h1 = mp.get_property_number("video-params/h")
  orig_w1 = mp.get_property_number("video-params/w")
  local t2 = second_video_track()
  orig_h2 = t2 and (t2["demux-h"] or t2["height"])
  orig_w2 = t2 and (t2["demux-w"] or t2["width"])
  log_debug(string.format("cache_dimensions: h1=%s w1=%s h2=%s w2=%s",
    tostring(orig_h1), tostring(orig_w1), tostring(orig_h2), tostring(orig_w2)))
end

local function get_cached_dims()
  return orig_h1, orig_w1, orig_h2, orig_w2
end

---------------------------------------------------------------- video dimensions

local function get_video_w(slot)
  if slot == 1 then
    return mp.get_property_number("video-params/w")
  end
  local t2 = second_video_track()
  return t2 and (t2["demux-w"] or t2["width"])
end

local function get_video_h(slot)
  if slot == 1 then
    return mp.get_property_number("video-params/h")
  end
  local t2 = second_video_track()
  return t2 and (t2["demux-h"] or t2["height"])
end

---------------------------------------------------------------- waveform filter-graph helpers

local function sw_filter(w, color)
  return string.format(
    "showwaves=s=%dx%d:mode=%s:rate=%d:colors=%s:scale=sqrt",
    w, WAVE_H, WAVE_MODE, WAVE_RATE, color)
end

-- Single-video waveform graph  (slot = 1 or 2)
--
--   [aidN] ─┬─ [ao]  (playback)
--            └─ showwaves ─► [wave]
--
--   color(black@bg) ──────────────────────┐
--   [vidN] ──── overlay(bg at bottom) ─── overlay(wave at bottom) ─► [vo]
--
local function build_single_wave(slot)
  local vid = (slot == 1) and "[vid1]" or "[vid2]"
  local aid = (slot == 1) and "[aid1]" or "[aid2]"
  local col = (slot == 1) and WAVE_COLOR1 or WAVE_COLOR2
  local w   = get_video_w(slot) or 1920
  local h   = get_video_h(slot) or 1080
  local y   = h - WAVE_H

  log_debug(string.format("build_single_wave(slot=%d): w=%d h=%d y=%d", slot, w, h, y))

  return string.format(
    "%s asplit=2 [ao][a_vis]; "
    .. "[a_vis] %s [wave]; "
    .. "color=c=black@%.2f:s=%dx%d:r=%d [bg]; "
    .. "%s[bg] overlay=x=0:y=%d:format=auto:shortest=1 [vbg]; "
    .. "[vbg][wave] overlay=x=0:y=%d:format=auto:shortest=1 [vo]",
    aid, sw_filter(w, col),
    WAVE_BG, w, WAVE_H, WAVE_RATE,
    vid, y, y)
end

-- hstack waveform graph  (both tracks visible, both waveforms)
--
--   [aid1] ─┬─ [ao]
--            └─ showwaves(green)  ─► overlay on vid1
--   [aid2] ─── showwaves(cyan)   ─► overlay on vid2
--   vid1_final + vid2_final ─► hstack ─► [vo]
--
-- KEY FIX: Pad BOTH videos to same size FIRST, then apply waveforms, then hstack
-- Uses CACHED original dimensions, not current video-params
local function build_hstack_wave(h1, h2, w1, w2)
  log_debug(string.format("build_hstack_wave: h1=%d h2=%d w1=%d w2=%d", h1, h2, w1, w2))

  local pad_section, v1_src, v2_src

  if h1 == h2 then
    pad_section = ""
    v1_src = "[vid1]"
    v2_src = "[vid2]"
    log_debug("  -> heights equal, no padding needed")
  elseif h1 > h2 then
    pad_section = string.format("[vid2] pad=eval=init:w=iw:h=%d:x=0:y=0 [v2_p]; ", h1)
    v1_src = "[vid1]"
    v2_src = "[v2_p]"
    log_debug(string.format("  -> h1 > h2, padding vid2 to %d", h1))
  else
    pad_section = string.format("[vid1] pad=eval=init:w=iw:h=%d:x=0:y=0 [v1_p]; ", h2)
    v1_src = "[v1_p]"
    v2_src = "[vid2]"
    log_debug(string.format("  -> h2 > h1, padding vid1 to %d", h2))
  end

  local y1 = h1 - WAVE_H
  local y2 = h2 - WAVE_H

  -- Build the graph:
  -- 1. Pad videos to same height (if needed)
  -- 2. Split audio for playback + visualization
  -- 3. Apply waveforms to each padded video
  -- 4. hstack the waveform-overlaid videos
  local graph = string.format(
  -- padding (if needed)
    "%s"
    -- audio routing
    .. "[aid1] asplit=2 [ao][a1_vis]; "
    .. "[a1_vis] %s [w1]; "
    .. "[aid2] %s [w2]; "
    -- waveform for vid1
    .. "color=c=black@%.2f:s=%dx%d:r=%d [bg1]; "
    .. "%s[bg1] overlay=x=0:y=%d:format=auto:shortest=1 [v1bg]; "
    .. "[v1bg][w1] overlay=x=0:y=%d:format=auto:shortest=1 [v1f]; "
    -- waveform for vid2
    .. "color=c=black@%.2f:s=%dx%d:r=%d [bg2]; "
    .. "%s[bg2] overlay=x=0:y=%d:format=auto:shortest=1 [v2bg]; "
    .. "[v2bg][w2] overlay=x=0:y=%d:format=auto:shortest=1 [v2f]; "
    -- combine
    .. "[v1f][v2f] hstack [vo]",
    pad_section,
    sw_filter(w1, WAVE_COLOR1),
    sw_filter(w2, WAVE_COLOR2),
    WAVE_BG, w1, WAVE_H, WAVE_RATE, v1_src, y1, y1,
    WAVE_BG, w2, WAVE_H, WAVE_RATE, v2_src, y2, y2)

  return graph
end

-- hstack WITHOUT waveforms (original logic, but with proper padding)
local function build_hstack_plain(h1, h2, w1, w2)
  log_debug(string.format("build_hstack_plain: h1=%d h2=%d w1=%d w2=%d", h1, h2, w1, w2))

  if h1 == h2 then
    log_debug("  -> heights equal, no padding")
    return "[vid1][vid2]hstack[vo]; [aid1] anull [ao]"
  elseif h1 > h2 then
    log_debug(string.format("  -> h1 > h2, padding vid2 to %d", h1))
    return string.format(
      "[vid2]pad=eval=init:w=iw:h=%d:x=0:y=0[v2_p]; "
      .. "[vid1][v2_p]hstack[vo]; [aid1] anull [ao]", h1)
  else
    log_debug(string.format("  -> h2 > h1, padding vid1 to %d", h2))
    return string.format(
      "[vid1]pad=eval=init:w=iw:h=%d:x=0:y=0[v1_p]; "
      .. "[v1_p][vid2]hstack[vo]; [aid1] anull [ao]", h2)
  end
end

---------------------------------------------------------------- state helpers

local function is_hstack()
  local g = mp.get_property("lavfi-complex") or ""
  return g:find("hstack") ~= nil
end

---------------------------------------------------------------- offset

local offsets = {} -- [slot] = offset_ms
local current_slot = 1

local function apply_offset()
  if has_vf("v_offset") then
    mp.commandv("vf", "remove", "@v_offset")
  end
  local ms = offsets[current_slot] or 0
  if ms ~= 0 then
    -- slow: local expr = string.format("(PTS-STARTPTS)%+.6f/TB", ms / 1000)
    -- WTF: progresses on toggle
    local expr = string.format("PTS%+.6f/TB", ms / 1000)
    mp.commandv("vf", "add", "@v_offset:lavfi=[setpts='" .. expr .. "']")
  end
end

local function nudge(delta_ms)
  offsets[current_slot] = (offsets[current_slot] or 0) + delta_ms
  apply_offset()
  mp.osd_message(string.format("slot %d offset = %+d ms",
    current_slot, offsets[current_slot]))
end

---------------------------------------------------------------- stitch  (forward-declared for toggle_waveform)

local apply_smart_hstack

apply_smart_hstack = function(force_enable)
  -- When in hstack mode, use CACHED dimensions, not current video-params
  -- (because video-params reflect the hstack output, not the original inputs)
  local h1, w1, h2, w2

  if is_hstack() then
    h1, w1, h2, w2 = get_cached_dims()
    log_debug(string.format("apply_smart_hstack: using CACHED dims h1=%s w1=%s h2=%s w2=%s",
      tostring(h1), tostring(w1), tostring(h2), tostring(w2)))
  else
    h1 = mp.get_property_number("video-params/h")
    w1 = mp.get_property_number("video-params/w")
    local t2 = second_video_track()
    h2 = t2 and (t2["demux-h"] or t2["height"])
    w2 = t2 and (t2["demux-w"] or t2["width"])
    log_debug(string.format("apply_smart_hstack: using CURRENT dims h1=%s w1=%s h2=%s w2=%s",
      tostring(h1), tostring(w1), tostring(h2), tostring(w2)))
  end

  if not (h1 and h2 and w1 and w2) then
    if not force_enable then
      mp.osd_message("Error: No external video track found")
    end
    log_debug("  -> missing dimensions, returning")
    return
  end

  if not force_enable and is_hstack() then
    log_debug("  -> disabling hstack, showing single video 1")
    set_graph(waveform_enabled and build_single_wave(1) or G1)
    current_slot = 1
    mp.osd_message("Stitch Disabled (Showing Video 1)")
  else
    if waveform_enabled then
      log_debug("  -> enabling hstack with waveforms")
      set_graph(build_hstack_wave(h1, h2, w1, w2))
    else
      log_debug("  -> enabling hstack without waveforms")
      set_graph(build_hstack_plain(h1, h2, w1, w2))
    end
  end
  refresh()
  apply_offset()
end

mp.register_event("file-loaded", function()
  current_slot = 1
  cache_dimensions()
  if user_configs.stitch then
    mp.add_timeout(0.2, function() apply_smart_hstack(true) end)
  end
end)

mp.add_forced_key_binding("b", "hstack-toggle", function() apply_smart_hstack(false) end)
mp.add_forced_key_binding("N", "hstack-enable", function() apply_smart_hstack(true) end)

---------------------------------------------------------------- waveform toggle

local function toggle_waveform()
  waveform_enabled = not waveform_enabled
  log_debug("toggle_waveform: " .. (waveform_enabled and "ON" or "OFF"))
  mp.osd_message("Waveform: " .. (waveform_enabled and "ON" or "OFF"))

  if is_hstack() then
    apply_smart_hstack(true)
  elseif current_slot == 2 then
    set_graph(waveform_enabled and build_single_wave(2) or G2)
  else
    set_graph(waveform_enabled and build_single_wave(1) or G1)
  end
  refresh()
end

---------------------------------------------------------------- switch

-- local function switch()
--     mp.command('cycle-values lavfi-complex "[vid2] copy [vo]; [aid2] anull [ao]" "[vid1] copy [vo]; [aid1] anull [ao]"')
--     mp.command('cycle-values force-media-title "(2) ${track-list/2/title}" "(1) ${filename}"')
--     -- mp.command('frame-back-step')
--     -- mp.command('frame-step')
--     -- mp.command('cycle-values vid 2 1')
--     -- mp.command('seek 0 relative+exact')
--     current_slot = (current_slot == 1) and 2 or 1
--     -- local off = (offsets[current_slot] or 0) / 1000
--     -- if off ~= 0 then
--     --     mp.commandv("seek", tostring(off), "relative+exact")
--     -- end
--     -- mp.osd_message(string.format("slot %d, offset %+dms", current_slot, offsets[current_slot] or 0))
--     apply_offset()
-- end

local function switch()
  if is_hstack() then
    log_debug("switch: in hstack mode, ignoring")
    return
  end

  local t2 = second_video_track()
  local going_to_2 = (current_slot ~= 2)

  log_debug(string.format("switch: current_slot=%d going_to_2=%s", current_slot, tostring(going_to_2)))

  if going_to_2 then
    set_graph(waveform_enabled and build_single_wave(2) or G2)
    mp.set_property("force-media-title",
      "(2) " .. ((t2 and (t2.title or t2["external-filename"])) or "video 2"))
    current_slot = 2
  else
    set_graph(waveform_enabled and build_single_wave(1) or G1)
    mp.set_property("force-media-title",
      "(1) " .. (mp.get_property("filename") or ""))
    current_slot = 1
  end
  apply_offset()
  mp.osd_message(string.format("slot %d, offset %+d ms%s",
    current_slot, offsets[current_slot] or 0,
    waveform_enabled and " [wave]" or ""))
end

mp.add_key_binding("v", "switch-v", switch)
mp.add_key_binding("n", "switch-n", switch)
mp.add_key_binding("M", "switch-M", switch)
mp.add_key_binding("w", "waveform-toggle", toggle_waveform)

mp.add_key_binding("-", "offset-minus", function() nudge(-1) end)
mp.add_key_binding("=", "offset-plus", function() nudge(1) end)
-- mp.add_key_binding("+", "offset-plus", function() nudge(1) end)
mp.add_key_binding("0", "offset-clear", function()
  offsets[current_slot] = 0
  apply_offset()
  mp.osd_message("slot " .. current_slot .. " offset cleared")
end)
