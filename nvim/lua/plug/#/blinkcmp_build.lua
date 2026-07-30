local M = {}

-- ── file helpers ────────────────────────────────────────────────
local function read_line(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local line = f:read("*l")
  f:close()
  return line and vim.trim(line) or nil
end

local function write_line(path, line)
  local f = io.open(path, "w")
  if not f then return false end
  f:write(line, "\n")
  f:close()
  return true
end

-- ── git plumbing ────────────────────────────────────────────────
-- Resolve the real gitdir, following the submodule ".git" file if present.
local function resolve_gitdir(plugin_root)
  local dot_git = plugin_root .. "/.git"
  local stat = vim.uv.fs_stat(dot_git)
  if not stat then return nil end
  if stat.type == "directory" then return dot_git end

  local line = read_line(dot_git)
  local rel = line and line:match("^gitdir:%s*(.+)$")
  return rel and vim.fs.normalize(plugin_root .. "/" .. rel) or nil
end

-- Look up a ref's hash in packed-refs (used when it's not a loose ref file).
local function read_packed_ref(gitdir, ref)
  local ok, iter = pcall(io.lines, gitdir .. "/packed-refs")
  if not ok then return nil end
  for line in iter do
    local hash, name = line:match("^(%x+)%s+(.+)$")
    if name == ref then return hash end
  end
  return nil
end

-- Current commit hash HEAD points to (handles detached HEAD, loose refs, packed refs).
local function current_commit_hash(plugin_root)
  local gitdir = resolve_gitdir(plugin_root)
  if not gitdir then return nil end

  local head = read_line(gitdir .. "/HEAD")
  if not head then return nil end

  local ref = head:match("^ref:%s*(.+)$")
  if not ref then return head end -- detached HEAD: HEAD already holds the hash

  return read_line(gitdir .. "/" .. ref) or read_packed_ref(gitdir, ref)
end

-- ── build stamp ─────────────────────────────────────────────────
local function stamp_path()
  return vim.fn.stdpath("cache") .. "/blink_submodule_stamp"
end

local function stamped_hash()
  return read_line(stamp_path())
end

local function write_stamp(hash)
  return write_line(stamp_path(), hash)
end

-- ── plugin location ─────────────────────────────────────────────
local function blink_root()
  local init_file = vim.api.nvim_get_runtime_file("lua/blink/cmp/init.lua", false)[1]
  return init_file and vim.fn.fnamemodify(init_file, ":h:h:h:h") or nil
end

-- ── orchestration ───────────────────────────────────────────────
function M.build_if_needed()
  local blink = require("blink.cmp")
  local root = blink_root()
  if not root then return end

  local current = current_commit_hash(root)
  local stale = current and current ~= stamped_hash()

  if not blink.library_available() or stale then
    vim.notify("[blink.cmp] Building...", vim.log.levels.INFO)
    local ok = blink.build():pwait()
    if ok and current then
      write_stamp(current)
    end
  end
end

return M
