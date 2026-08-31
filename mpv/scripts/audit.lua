-- SUM: Append an audit record for every file played by mpv.

local msg = require "mp.msg"
local utils = require "mp.utils"

local current = nil
local records = {}

local CHUNK_SIZE = 32768
local NR_SAMPLES = 4

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function calc_identity_key(filepath)
    local file = io.open(filepath, "rb")
    if not file then return nil end

    local size = file:seek("end")
    if not size then file:close(); return nil end
    if size == 0 then
        file:close()
        return "0_empty"
    end

    file:close()

    local perl = [[
        $file = shift;
        $chunk = 32768;
        $n = 4;
        open my $f, "<:raw", $file or exit 1;
        $size = -s $f;
        exit 0 if !$size;
        $last = $size - $chunk;
        if ($last <= $chunk * $n) {
            while (read($f, $buf, $chunk)) { print $buf; }
        } else {
            for ($i = 0; $i <= $n; $i++) {
                seek($f, int($last * $i / $n), 0);
                read($f, $buf, $chunk);
                print $buf;
            }
        }
    ]]
    local pipeline = string.format("perl -e %s %s | xxhsum -H3 -",
        shell_quote(perl), shell_quote(filepath))
    local result = utils.subprocess({
        args = { "sh", "-c", pipeline },
        capture_stdout = true,
    })
    if result.status ~= 0 or not result.stdout then return nil end

    -- xxhsum -H3 emits: XXH3_<hex>  stdin
    local hash = result.stdout:match("^XXH3_([%da-fA-F]+)")
    if not hash then return nil end
    return string.format("%d_%s", size, hash:lower())
end

local function audit_directory()
    local hostname = os.getenv("HOSTNAME")
    if not hostname or hostname == "" then
        hostname = os.getenv("HOST")
        if not hostname or hostname == "" then
            msg.warn("HOSTNAME and HOST are not set; trying /etc/hostname")
            local file = io.open("/etc/hostname", "r")
            if file then
                hostname = file:read("*a")
                file:close()
            end
        end
    end
    if not hostname or hostname:gsub("%s+", "") == "" then
        msg.error("host is unknown; HOSTNAME, HOST, and /etc/hostname are unavailable or empty")
        hostname = "unknown"
    end
    hostname = hostname:gsub("%s+$", "")
    hostname = hostname:gsub("[^%w%._-]", "_")
    local directory = string.format("/d/audit/%s/mpv/%s", hostname,
        os.date("%Y"))

    local ok, _, code = os.execute("mkdir -p " .. shell_quote(directory))
    if not ok and code ~= 0 then
        msg.error("could not create audit directory: " .. directory)
        return nil
    end
    return directory .. "/" .. os.date("%Y-%m-%d")
end

local function resolve_path(path)
    if not path or path == "" then return nil end
    -- URLs and already-absolute paths are already resolved enough for the log.
    if path:match("^[%a][%w+.-]*://") or path:sub(1, 1) == "/" then
        return path
    end

    local working_directory = mp.get_property("working-directory")
    if working_directory then
        return utils.join_path(working_directory, path)
    end
    return path
end

local function finish_current()
    if not current then return end
    local filepath = resolve_path(current.path)
    if filepath then
        local identity = current.identity or "-"
        local record = records[identity]
        if not record then
            record = { timestamp = current.timestamp, duration = 0,
                filepath = filepath, identity = identity }
            records[identity] = record
        end
        record.duration = record.duration + math.max(0, mp.get_time() - current.started)
        record.filepath = filepath
    end
    current = nil
end

mp.register_event("file-loaded", function()
    finish_current()
    current = {
        path = mp.get_property("path"),
        timestamp = os.time(),
        started = mp.get_time(),
    }
    current.identity = calc_identity_key(resolve_path(current.path)) or "-"
end)

mp.register_event("end-file", finish_current)
mp.register_event("shutdown", function()
    finish_current()

    local filename = audit_directory()
    if not filename then return end

    local output = io.open(filename, "a")
    if not output then
        msg.error("could not open audit log: " .. filename)
        return
    end

    for _, record in pairs(records) do
        output:write(string.format("%d\t%d\t%s\t%s\n", record.timestamp,
            math.floor(record.duration), record.identity, record.filepath))
    end
    output:close()
end)
