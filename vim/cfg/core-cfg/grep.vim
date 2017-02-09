"{{{1 Tab/Space ============================
" set grepformat=%f:%l:%c:%m
" if executable('ag')
"   set grepprg=ag\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow
" elseif executable('ack')
"   set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
" else
"   set grepprg=internal  " Use vimgrep.
"   " set grepprg=grep\ -inH " Use grep.
" endif

" if exists('&regexpengine')  " Use old regexp engine.
"   " set regexpengine=1
"   " Doxygen syntax highlighting. Very slow on \c, \b. So set those:
"   set regexpengine=1          " Do not use NFA because doxygen style will be slow
"   let g:load_doxygen_syntax=1 " Load doxygen syntax by default
"   " manually: set syn=cpp.doxygen
" endif

"{{{1 Ctags/Mappings ============================

"" TODO Make tags placed in .git/tags file available in all levels of a repository
" --> This idea is compatible with nou.vim concept of cross-links
" let gitroot = substitute(system('git rev-parse --show-toplevel'), '[\n\r]', '', 'g')
" if gitroot != ''
"     let &tags = &tags . ',' . gitroot . '/.git/tags'
" endif

" Generate 'tags' file: MAYBE:(deprecated by) easytags
"" TODO -- generate tags into .git/ OR .hg/ if exists
" TODO:CHG: replace by concrete 'r.*' scripts
if executable('ctags') || executable('ctags-exuberant')
  let s:ctags = 'ctags --recurse'
  if executable('ctags-exuberant') | let s:ctags .= '--exuberant' | endif
  command -bar -range -nargs=0 TagsGen call system(s:ctags)
  nnoremap <silent> <F1> :<C-u>TagsGen<CR>
endif

" ATTENTION: w/o compression, because CCTree use outdated format
if executable('cscope')
  let s:cscope = 'cscope -bcqR'
  command -bar -range -nargs=0 CCgen call system(s:cscope)
  nnoremap <silent> <S-F1> :<C-u>CCgen<CR>
endif

" Show list of tags when there more then one entry.
" -- Same, Preview, Split --//--  Close preview:  C-w z, C-w C-z
noremap <unique> g]   g<C-]>
noremap <unique> z]   <C-w>g}
noremap <unique> gz]  <C-w>vg<C-]>
noremap <unique> g<C-]>   g]
noremap <unique> g[   :<C-u><C-r>=v:count1<CR>tnext<CR>
" noremap <C-]> g<C-]>
" ALSO:  Use [I or ]I -- to show matches of current work in this file
