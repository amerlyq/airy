-- vim:ft=lua:ts=2:sw=2:sts=2
-- local wrt = io.write
-- io.write(os.capture('ls'))

-- ALT: pipe_from(...)C
function os.capture(cmd) --, raw
  local c = cmd:gsub('[\\]', '\\&')
  local f = assert(io.popen(c, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  -- if raw then return s end
  -- s = string.gsub(s, '^%s+', '')
  -- s = string.gsub(s, '%s+$', '')
  -- s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

function get_acc_passwd(muser)
  return os.capture(os.getenv('HOME')..'/.mutt/exe/pass '..muser)
end

-- return io.open(dir..'/'..file):read()
function os.source(file)
  -- local f = assert(loadfile(os.getenv('HOME')..'/.imapfilter/'..file))
  -- return f()
  return dofile(os.getenv('HOME')..'/.imapfilter/'..file)
end
