-- vim:ft=lua:ts=2:sw=2:sts=2

-- local wrt = io.write
-- io.write(os.capture('ls'))

-- ALT: pipe_from(...)C
function os.capture(cmd) --, raw
  local f = assert(io.popen(cmd, 'r'))
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


-- personal(m, accs[1])
function person(m, nm)
  return m:contain_cc(nm) + m:contain_to(nm) + m:contain_from(nm)
end

function filter(acc, m, nm, dst)
  local dst = acc[dst]
  m:contain_from(nm):move_messages(dst)
  m:contain_to(nm):move_messages(dst)
  m:contain_cc(nm):move_messages(dst)
  m:contain_field('sender', nm):move_messages(dst)
end

function mv_subj(acc, m, dst, patt)
  m:match_subject(patt):move_messages(acc[dst])
end

-- TEMP:FIXED: until I fix imapfilter code to support base64 match_subject
-- SEE: http://lua-users.org/wiki/BaseSixtyFour
-- REQ: https://github.com/lefcha/imapfilter/issues/127
-- SEE: https://maildrop.cc/
function mv_subj_any(acc, m, dst, tbl)
  for i, s in pairs(tbl) do
    m:contain_subject(s):move_messages(acc[dst])
  end
end


-- function deleteold(m, days)
--   todelete=m:is_older(days)-mine(m)
--   todelete:move_messages(acc['Trash'])
-- end

---------------------------------------------
-- SEE $ man imapfilter_config
options.create = false    -- create mailbox only if received hint from server
options.starttls = true   -- prefer tls over ssl
options.subscribe = true  -- set new mailboxes as active to be recognized
options.timeout = 30      -- wait server response
-- options.charset = 'UTF-8'

os.source('acc.lua')
---------------------------------------------
load('acc = ' .. accs[1])()  -- TEMP:REM
-- DEV: ignore inexistent files
os.source('acc/'..accs[1]..'.lua')

-- USE:DEBUG: get and print available mailboxes and folders
-- accs[1].INBOX:check_status()
-- mboxes, folders = acc:list_all()
-- table.foreach(mboxes, print)
-- table.foreach(folders, print)

-- Select all messages marked as spam and throw them away
-- msgs = account1.INBOX:match_header('^.+MailScanner.*Check: [Ss]pam.*$')
-- account1.INBOX:delete_messages(msgs)


-- SEE http://iranzo.github.io/blog/2015/08/28/filtering-email-with-imapfilter/

-- Move sent messages to INBOX to later sorting
-- FIND: how to keep messages both in 'Sent' and some other topical subdir of Inbox?
-- sent = acc['Sent']:select_all()
-- sent:move_messages(acc['INBOX'])

-- NEED:(pending) create online rules on server
-- All emails from case updates, bugzilla, etc to _pending
-- All emails containing ‘list’ or ‘bounces’ in from to _pending
-- All emails not containing me directly on CC or To, to _pending
-- pending = acc['INBOX/_pending']:select_all()
-- todos = pending + inbox -- USE todos everywhere next

-- spam = todos:contain_field('X-Spam-Score','*****')
-- spam:move_messages(acc['Spam'])

-- SEE: http://pcre.org/original/doc/html/

-- FIND: how to recursively select in Inbox/**
-- ALT: list all subdirs and compose total in cycle
