-- vim:ft=lua:ts=2:sw=2:sts=2
-- personal(m, accs[1])

-- TEMP:FIXED: until I fix imapfilter code to support base64 match_subject
-- SEE: http://lua-users.org/wiki/BaseSixtyFour
-- REQ: https://github.com/lefcha/imapfilter/issues/127
-- SEE: https://maildrop.cc/
function mv_from(acc, m, dst, tbl)
  for i, v in pairs(tbl) do
    m:contain_from(v):move_messages(acc[dst])
  end
end
function mv_subj(acc, m, dst, tbl)
  for i, v in pairs(tbl) do
    m:contain_subject(v):move_messages(acc[dst])
  end
end

function mv_subj_rgx(acc, m, dst, patt)
  m:match_subject(patt):move_messages(acc[dst])
end

function addr_person(m, nm)
  return m:contain_cc(nm) + m:contain_to(nm) + m:contain_from(nm) + m:contain_field('sender', nm)
end

function mv_any_addr(acc, m, nm, dst)
  addr_person(m, nm):move_messages(acc[dst])
end

-- function deleteold(m, days)
--   todelete=m:is_older(days)-mine(m)
--   todelete:move_messages(acc['Trash'])
-- end
