local last_speed = 3.0 -- Universal fallback memory if currently at 1.0

-- Helper function to parse comma/space separated numbers into a sorted table
local function parse_speeds(str)
  local t = {}
  if not str or str == "" then return { 3, 9, 18 } end -- default fallback
  for val in string.gmatch(str, "([^,%s]+)") do
    local num = tonumber(val)
    if num then table.insert(t, num) end
  end
  table.sort(t)
  return t
end

local function toggle_speed()
  local current_speed = mp.get_property_number("speed") or 1.0

  if math.abs(current_speed - 1.0) > 0.01 then
    last_speed = current_speed
    mp.set_property("speed", 1.0)
    mp.osd_message("Speed: 1.0x")
  else
    mp.set_property("speed", last_speed)
    mp.osd_message("Speed: " .. last_speed .. "x")
  end
end

local function cycle_speed(speeds_str)
  local speeds = parse_speeds(speeds_str)
  local current_speed = mp.get_property_number("speed") or 1.0

  -- Use fallback memory if currently sitting at 1.0x
  local check_speed = math.abs(current_speed - 1.0) > 0.01 and current_speed or last_speed

  -- Explicitly default to the first element or a fallback value
  local target_speed = speeds[1]

  -- Find the next greater speed in the provided list
  for _, s in ipairs(speeds) do
    if s > (check_speed + 0.01) then
      target_speed = s
      break
    end
  end

  mp.set_property("speed", target_speed)
  last_speed = target_speed
  mp.osd_message("Speed: " .. target_speed .. "x")
end

mp.add_key_binding(nil, "toggle_speed", toggle_speed)
mp.add_key_binding(nil, "cycle_speed", cycle_speed)
