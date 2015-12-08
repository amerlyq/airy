"{{{1 Tab/Space ============================
set grepformat=%f:%l:%c:%m
if executable('ag')
  set grepprg=ag\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow
elseif executable('ack')
  set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
else
  set grepprg=internal  " Use vimgrep.
  " set grepprg=grep\ -inH " Use grep.
endif

if exists('&regexpengine')  " Use old regexp engine.
  " set regexpengine=1
  " Doxygen syntax highlighting. Very slow on \c, \b. So set those:
  set regexpengine=1          " Do not use NFA because doxygen style will be slow
  let g:load_doxygen_syntax=1 " Load doxygen syntax by default
  " manually: set syn=cpp.doxygen
endif

"{{{1 Ctags ============================
set tags=./tags,tags,*/tags,~/.cache/vim/tags
set tagbsearch      " Use a binary search (need sorted tags file!)
"" TODO Make tags placed in .git/tags file available in all levels of a repository
" let gitroot = substitute(system('git rev-parse --show-toplevel'), '[\n\r]', '', 'g')
" if gitroot != ''
"     let &tags = &tags . ',' . gitroot . '/.git/tags'
" endif

"{{{1 Ctags/Mappings ============================
" Generate 'tags' file: DEPRECATEDBY easytags
"" TODO -- generate tags into .git/ OR .hg/ if exists
if executable('ctags-exuberant')
  nnoremap <silent> <F1> :!ctags'-exuberant --recurse<CR>
else
  nnoremap <silent> <F1> :!ctags --recurse<CR>
endif

if executable('cscope')
  " ATTENTION: w/o compression, because CCTree use outdated format
  nnoremap <silent> <S-F1> :!cscope -bcqR<CR>
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
