local K = require'keys.bind'.K

--Buffers save/close/exit
-- [_] THINK:MAYBE: replace by "set autowriteall"
K('i', ',s', '<Esc>:update<CR>')
K('nx', ',s', ':<C-U>update<CR>')

-- " FIXED:(E173):SEE http://vim.1045645.n5.nabble.com/Re-how-to-suppress-quot-E173-1-more-file-to-edit-quot-td5716336.html#a5716344
-- " ALT: if argc()>1|sil blast|sil bfirst|en
-- set noconfirm   " abort action on unsaved for Qfast to work
vim.cmd [[com! -bar Qfast try|sil quit|catch/:E37/|conf quit
  \|catch/:E173/|try|sil qall|catch/E37/|conf qall|endt|endt]]

K('nx', ',d', ':<C-U>Qfast<CR>')
K('nx', ',x', function()
  vim.cmd([[exe (bufnr('%') == bufnr('$') ? 'bprev' : 'bnext') .'|bdelete '. bufnr('%')]])
end)


--HACK: chord for ",s" to prevent ttimeout affecting this keybiding
--SRC: https://www.reddit.com/r/vim/comments/ufgrl8/journey_to_the_ultimate_imap_jk_esc/
--ALT: inoremap <expr> , {->execute("let g:esc_last=reltime()").","}()
--   vim.keymap.set('i', ',', "EscStoreTime(',')", { expr = true, silent = true })
vim.cmd [[
let g:esc_last=reltime()

fun! EscStoreTime(key)
  let g:esc_last=reltime()
  return a:key
endf

fun! EscOrKey(key)
  let l:dt=reltimefloat(reltime(g:esc_last))
  echom l:dt
  return (l:dt<0.15 && l:dt>0.004) ? "\b\e" : a:key
endf

inoremap <silent><expr> k EscStoreTime('k')
inoremap <silent><expr> j EscOrKey('j')
]]
