-- Headless mpv API harness. "frames" executes real FFmpeg; "lifecycle" controls
-- callback ordering to exercise cancellation without timing-dependent sleeps.
local mode, source, destination, first, last = table.unpack(arg)
local converter = arg[0]:gsub("mpv/tests/clip_driver.lua$", "ffmpeg/run")
local props = {
  path = source, ["working-directory"] = ".",
  dwidth = 160, dheight = 90, duration = 24,
  ["osd-dimensions"] = { w = 800, h = 450, ml = 0, mr = 0, mt = 0, mb = 0 },
}
local queue, timers, events, observers, bindings, messages = {}, {}, {}, {}, {}, {}
local overlays, errors, calls, paths, commands = {}, {}, {}, {}, {}
local function read(path)
  local f = io.open(path, "rb")
  if not f then return end
  local data = f:read("*a"); f:close()
  return data
end
local function write(path, data)
  local f = assert(io.open(path, "wb")); assert(f:write(data)); assert(f:close())
end
local function file_info(path)
  local f = io.open(path, "rb")
  if not f then return end
  local size = f:seek("end"); f:close()
  return { size = size, is_file = true }
end
local function quote(s) return "'" .. tostring(s):gsub("'", "'\\''") .. "'" end
local function option(args, key)
  for i, value in ipairs(args) do if value == key then return args[i + 1] end end
end
package.preload["mp.utils"] = function()
  return { file_info = file_info, join_path = function(a, b) return a .. "/" .. b end }
end
package.preload["mp.options"] = function()
  return { read_options = function(opts) opts.converter = converter end }
end
mp = {
  msg = {
    debug = function() end,
    log = function(level, message)
      if level == "error" then errors[#errors + 1] = message end
    end,
  },
  get_property = function(name) return props[name] end,
  get_property_native = function(name) return props[name] end,
  get_property_number = function(name) return tonumber(props[name]) end,
  set_property = function(name, value) props[name] = value end,
  commandv = function(...) commands[#commands + 1] = { ... } end,
  osd_message = function() end,
  observe_property = function(name, _, fn) observers[name] = fn end,
  register_event = function(name, fn) events[name] = fn end,
  add_key_binding = function(_, name, fn) bindings[name] = fn end,
  register_script_message = function(name, fn) messages[name] = fn end,
  add_timeout = function(_, fn)
    local timer = { fn = fn, kill = function(self) self.killed = true end }
    timers[#timers + 1] = timer
    return timer
  end,
  abort_async_command = function(job) job.aborted = true end,
  command_native_async = function(command, callback)
    calls[#calls + 1] = command.args
    local job = { command = command, callback = callback }
    queue[#queue + 1] = job
    if command.args[1] == "ffmpeg" then paths[command.args[#command.args]] = true end
    return job
  end,
  command_native = function(command)
    if command.name == "overlay-remove" then overlays[command.id] = nil; return end
    assert(command.name == "overlay-add", "unexpected synchronous command")
    if props.overlay_error then return nil, "overlay test failure" end
    command.data = assert(read(command.file))
    assert(#command.data == command.w * command.h * 4, "invalid raw frame")
    overlays[command.id] = command
    -- Real mpv returns no value for overlay-add, not an empty node map.
    return nil
  end,
}
local script = arg[0]:gsub("tests/clip_driver.lua$", "scripts/clip.lua")
dofile(script)
events["file-loaded"]()
local function mark(which, t)
  props["playback-time"] = t
  bindings["clip_mark_" .. which]()
end
local function flush_timers()
  local pending = timers; timers = {}
  for _, t in ipairs(pending) do if not t.killed then t.fn() end end
end
local function complete()
  local job = table.remove(queue, 1)
  if not job then return false end
  if job.aborted then job.callback(false, nil, "aborted"); return true end
  local args = job.command.args
  if mode == "frames" then
    local quoted = {}
    for _, value in ipairs(args) do quoted[#quoted + 1] = quote(value) end
    local errfile = os.tmpname()
    local outfile = os.tmpname()
    local ok, _, status = os.execute(table.concat(quoted, " ") .. " 2>" .. quote(errfile)
      .. " >" .. quote(outfile))
    local stderr = read(errfile); os.remove(errfile)
    local stdout = read(outfile); os.remove(outfile)
    job.callback(true, { status = ok and 0 or status, stderr = stderr, stdout = stdout })
  elseif args[2] == "--preview-plan" then
    local command = { "ffmpeg", "-ss", args[5], "-to", args[6], "-i", args[4], args[8] }
    job.callback(true, { status = 0, stdout = table.concat(command, "\0") .. "\0\0" })
  elseif option(args, "-f") == "rawvideo" then
    local w, h = option(args, "-vf"):match("scale=(%d+):(%d+)")
    local bytes = tonumber(w) * tonumber(h) * 4
    write(args[#args], string.rep("a", bytes) ..
      (option(args, "-frames:v") and "" or string.rep("b", bytes)))
    job.callback(true, { status = 0 })
  else
    job.callback(true, { status = 0 })
  end
  return true
end
local function drain()
  flush_timers()
  local count = 0
  while complete() do count = count + 1; assert(count < 100) end
end
local function cleanup_check()
  events["end-file"]()
  drain()
  assert(not next(overlays))
  for path in pairs(paths) do assert(not file_info(path), "leaked " .. path) end
end

if mode == "frames" then
  mark("beg", tonumber(first)); mark("end", tonumber(last))
  drain()
  if #errors > 0 then
    for _, err in ipairs(errors) do io.stderr:write(err .. "\n") end
    cleanup_check()
    os.exit(1)
  end
  for id, which in ipairs({ "A", "B" }) do
    local overlay = assert(overlays[id], "missing " .. which)
    write(destination .. "/" .. which .. ".raw", overlay.data)
    print(which, overlay.w, overlay.h)
  end
  cleanup_check()
else
  -- Cancel after decode was submitted but before its callback.
  mark("beg", 5); flush_timers(); assert(complete()); assert(complete())
  local obsolete = queue[1]
  mark("beg", 7)
  assert(obsolete.aborted)
  local errors_before = #errors
  obsolete.callback(true, { status = 1, stderr = "stale error" })
  assert(#errors == errors_before and not next(overlays))
  drain()
  assert(overlays[1])
  mark("end", 16); drain()
  assert(overlays[2].data:sub(1, 1) == "b", "B must use last frame")
  assert(overlays[1].y >= 48, "reserve one OSD line above bitmap previews")
  -- Resize reuses the cached pixels, including portrait layout.
  local count = #calls
  props["osd-dimensions"].w = 400
  props.dwidth = 90; props.dheight = 160
  observers["osd-dimensions"]()
  assert(#calls == count)
  assert(overlays[2].y + overlays[2].dh <= props["osd-dimensions"].h)
  -- Hide/show caches; clearing must kill the pending debounce.
  messages.clip_toggle_previews(); assert(not next(overlays))
  messages.clip_toggle_previews(); assert(overlays[1] and #calls == count)
  -- The OSC property reports the state set by the toggle, not another toggle.
  observers["user-data/osc/visibility"]("user-data/osc/visibility", "always")
  messages.clip_toggle_previews()
  observers["user-data/osc/visibility"]("user-data/osc/visibility", "never")
  assert(not next(overlays))
  messages.clip_toggle_previews()
  observers["user-data/osc/visibility"]("user-data/osc/visibility", "always")
  assert(overlays[1] and #calls == count)
  mark("beg", 8); bindings.clip_clear_preview(); drain()
  assert(#calls == count and not next(overlays))
  -- Layout unavailable on marking: observer retries after layout appears.
  props["osd-dimensions"] = nil
  mark("beg", 9); drain(); assert(#calls == count)
  props["osd-dimensions"] = { w = 800, h = 450 }
  observers["osd-dimensions"](); drain(); assert(overlays[1])
  -- Normal API command failures return nil,error rather than throwing.
  props.overlay_error = true
  observers["osd-dimensions"]()
  assert(errors[#errors]:find("overlay test failure"))
  assert(not next(overlays), "failed overlay updates must remove stale images")
  props.overlay_error = false
  -- Export must be asynchronous; failure must retain previews.
  mark("end", 16); drain()
  bindings.clip_write_copy()
  local export = table.remove(queue, 1)
  assert(export.command.args[1] == converter)
  export.callback(true, { status = 1, stderr = "export test failure" })
  assert(overlays[1])
  -- A different export key selects previews first, never starts a full encode.
  bindings.clip_write_fast()
  assert(not next(overlays) and #queue == 0)
  bindings.clip_write_fast()
  assert(#queue == 0)
  drain()
  assert(overlays[1] and overlays[2])
  bindings.clip_write_fast()
  export = table.remove(queue, 1)
  assert(export.command.args[5] == "fast" and export.command.args[2] ~= "--preview-plan")
  export.callback(true, { status = 0 })
  assert(not next(overlays))
  -- File change invalidates a pending job before even its cut callback.
  mark("beg", 10); flush_timers()
  events["start-file"](); drain()
  assert(not next(overlays))
  -- Reject an entire malformed plan before executing even its valid prefix.
  mark("beg", 5); flush_timers()
  local plan = assert(table.remove(queue, 1))
  count = #calls
  plan.callback(true, { status = 0, stdout = "ffmpeg\0valid-prefix\0\0truncated" })
  assert(#calls == count and errors[#errors]:find("invalid converter preview plan"))
  observers["osd-dimensions"](); drain()
  assert(#calls == count, "resize must not restart a failed pipeline")
  -- Explicit mode selection retries a failed preview.
  messages.clip_preview_mode("fast"); drain()
  assert(overlays[1] and overlays[2])
  -- Losing layout revokes export readiness without throwing away cached pixels.
  count = #calls
  props["osd-dimensions"] = nil
  observers["osd-dimensions"]()
  assert(not next(overlays))
  bindings.clip_write_fast(); assert(#calls == count)
  props["osd-dimensions"] = { w = 800, h = 450 }
  observers["osd-dimensions"]()
  assert(overlays[1] and overlays[2] and #calls == count)
  -- Completing an older export must preserve a newer selection.
  bindings.clip_write_fast()
  export = assert(table.remove(queue, 1))
  mark("beg", 6); drain()
  local newer = assert(overlays[1])
  export.callback(true, { status = 0 })
  assert(overlays[1] == newer and overlays[2])
  -- EOF is an observed property, not an mpv event.
  props.pause = "no"
  observers["eof-reached"]("eof-reached", true)
  assert(props.pause == "yes")
  -- Moving is asynchronous; process exit failures must not advance playback.
  bindings.clip_moving()
  local moving = assert(table.remove(queue, 1))
  count = #commands
  moving.callback(true, { status = 1, stderr = "move test failure" })
  assert(#commands == count and errors[#errors]:find("move test failure"))
  bindings.clip_moving()
  moving = assert(table.remove(queue, 1))
  props.path = source .. ".next"
  moving.callback(true, { status = 0 })
  assert(#commands == count, "old move must not advance a different source")
  props.path = source
  cleanup_check()
  print("clip lifecycle: passed")
end
