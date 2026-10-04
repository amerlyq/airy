-- Deterministic mpv callback harness; media mode executes the real FFmpeg argv.
local mode, source, position, direction, duration = table.unpack(arg)
local props = {
  path = source, ["working-directory"] = ".", ["time-pos"] = tonumber(position) or 20,
  duration = tonumber(duration) or 40, speed = 1.5, mute = "no", pause = "no",
  ["current-tracks/video"] = { ["ff-index"] = 0 },
}
local queue, timers, events, messages, errors, seeks = {}, {}, {}, {}, {}, {}
local last_message
package.preload["mp.utils"] = function()
  return {
    join_path = function(a, b) return a .. "/" .. b end,
    file_info = function(path)
      local file = io.open(path, "rb")
      if file then file:close(); return { is_file = true } end
    end,
  }
end
package.preload["mp.options"] = function() return { read_options = function() end } end
mp = {
  get_property = function(name) return props[name] end,
  get_property_number = function(name) return tonumber(props[name]) end,
  get_property_native = function(name) return props[name] end,
  set_property = function(name, value)
    assert(name == "pause", "scan must not change playback settings")
    props[name] = value
  end,
  commandv = function(cmd, value, absolute, exact)
    assert(cmd == "seek" and absolute == "absolute" and exact == "exact")
    seeks[#seeks + 1] = value
    props["time-pos"] = value
  end,
  command_native_async = function(command, callback)
    assert(command.playback_only and command.capture_stderr)
    local job = { args = command.args, callback = callback }
    queue[#queue + 1] = job
    return job
  end,
  abort_async_command = function(job) job.aborted = true end,
  add_timeout = function(_, fn)
    local timer = { fn = fn, kill = function(self) self.killed = true end }
    timers[#timers + 1] = timer
    return timer
  end,
  osd_message = function(text) last_message = text end,
  msg = { error = function(text) errors[#errors + 1] = text end },
  register_event = function(name, fn) events[name] = fn end,
  register_script_message = function(name, fn) messages[name] = fn end,
  add_key_binding = function() end,
}
dofile(arg[0]:gsub("tests/scene_driver.lua$", "scripts/sceneseeker.lua"))
local function option(args, key)
  for i, value in ipairs(args) do if value == key then return args[i + 1] end end
end
local function flush()
  local pending = timers; timers = {}
  for _, timer in ipairs(pending) do if not timer.killed then timer.fn() end end
end
local function result(times, status)
  local job = assert(table.remove(queue, 1))
  local start = tonumber(option(job.args, "-ss"))
  local lines = {}
  for _, t in ipairs(times or {}) do
    lines[#lines + 1] = string.format("[showinfo] pts_time:%.9f", t - start)
  end
  job.callback(true, { status = status or 0, stderr = table.concat(lines, "\n") })
  return job
end

if mode == "media" then
  messages["scan-" .. direction]()
  local windows = 0
  while #queue > 0 do
    local job = table.remove(queue, 1)
    local quoted = {}
    for _, value in ipairs(job.args) do
      quoted[#quoted + 1] = "'" .. tostring(value):gsub("'", "'\\''") .. "'"
    end
    local path = os.tmpname()
    local ok, _, code = os.execute(table.concat(quoted, " ") .. " 2>'" .. path .. "'")
    local file = assert(io.open(path, "rb"))
    local stderr = file:read("*a"); file:close(); os.remove(path)
    job.callback(true, { status = ok and 0 or code, stderr = stderr })
    flush()
    windows = windows + 1
    assert(windows < 100, "scan did not terminate")
  end
  assert(#errors == 0, table.concat(errors, "\n"))
  assert(#seeks > 0, last_message)
  print(string.format("%.9f %d", props["time-pos"], windows))
else
  messages["scan-forward"]()
  local old = assert(table.remove(queue, 1))
  messages["scan-forward"]()
  assert(old.aborted and #queue == 0)
  old.callback(true, { status = 0, stderr = "pts_time:1.5" })
  assert(#seeks == 0, "cancelled callback must not seek")

  messages["scan-backward"]()
  assert(not option(queue[1].args, "-frames:v"))
  result({ 13, 19 })
  assert(props["time-pos"] == 19, "backward must choose nearest, not first")
  messages["scan-forward"]()
  assert(option(queue[1].args, "-frames:v") == "1")
  result({ 20, 21 })
  assert(props["time-pos"] == 20, "forward must choose first")

  messages["scan-backward"]()
  result({}) -- Search must continue beyond the initial window.
  assert(props["time-pos"] == 12 and #timers == 1)
  flush(); result({ 7 })
  assert(props["time-pos"] == 7)

  messages["scan-forward"]()
  result({})
  messages["scan-forward"]() -- Cancel between windows.
  flush(); assert(#queue == 0)

  messages["scan-forward"]()
  old = assert(table.remove(queue, 1))
  messages["scan-backward"]() -- Opposite direction replaces the job.
  assert(old.aborted and #queue == 1)
  old.callback(true, { status = 1, stderr = "stale failure" })
  assert(#errors == 0)
  result({}, 1)
  assert(#errors == 1 and last_message:find("failed"))

  messages["scan-forward"]()
  old = assert(table.remove(queue, 1))
  events["start-file"]()
  assert(old.aborted)
  local count = #seeks
  old.callback(true, { status = 0, stderr = "pts_time:1.5" })
  assert(#seeks == count)
  props["current-tracks/video"].external = true
  messages["scan-forward"](); assert(#queue == 0)
  assert(props.speed == 1.5 and props.mute == "no" and props.pause == "yes")
  print("scene lifecycle: passed")
end
