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
" DEV: use async exec instead of system()
if executable('ctags') || executable('ctags-exuberant')
  let s:ctags = 'ctags --recurse'
  if executable('ctags-exuberant')| let s:ctags .=' --exuberant'  |en
  if filereadable('.ignore')| let s:ctags .=' --exclude=@.ignore' |en
  command -bar -range -nargs=0 TagsGen
    \ if $HOME !~# '^'.getcwd()|call system(s:ctags)
    \ |else|echom "Prevented gen tags in $HOME or below"|en
  nnoremap <unique><silent> <S-F1> :<C-u>TagsGen<CR>
endif

""" NOTE: smart tags generation (for C/C++ only)
command -bar -range -nargs=0 Ctags
  \ call system("q.callgraph-find-src -CL . | q.callgraph-tags-cpp > tags")

" ATTENTION: w/o compression, because CCTree use outdated format
if executable('cscope')
  let s:cscope = 'cscope -bcqR'
  command -bar -range -nargs=0 CCgen call system(s:cscope)
  " nnoremap <unique><silent> <S-F1> :<C-u>CCgen<CR>
endif

" Show list of tags when there more then one entry.
" -- Same, Preview, Split --//--  Close preview:  C-w z, C-w C-z
noremap <unique> g]   g<C-]>
noremap <unique> z]   <C-w>g}
noremap <unique> gz]  <C-w>vg<C-]>
noremap <unique> g<C-]>   g]
" NOTE: undo '<C-t>' by moving one tag forward. Use '0' to jump to newest tag.
noremap <unique> g<C-t>   :<C-u><C-r>=v:count1<CR>tag<CR>
noremap <unique> g[   :<C-u><C-r>=v:count1<CR>tnext<CR>
" noremap <C-]> g<C-]>
" ALSO:  Use [I or ]I -- to show matches of current work in this file
