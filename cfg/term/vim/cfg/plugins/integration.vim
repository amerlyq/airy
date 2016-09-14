""" Apps

"" CHECK: Ultimate hex-editing system {{{1
" - depends on hexript for some optional scripts
" - (now that repo rbtnn/hexript.vim don't exists?)
" THINK hook_add = 'let g:vinarise_enable_auto_detect = 1'
" EXPL:(lazy) don't detects binary file or large file automatically.
call dein#add('Shougo/vinarise.vim', {
  \ 'on_cmd': ['Vinarise', 'VinariseDump'],
  \ 'hook_source': "
\\n   let g:vinarise_enable_auto_detect = 0
\\n   let g:vinarise_detect_large_file_size  =  0
\\n   let g:vinarise_objdump_command = 'objdump'
\\n   let g:vinarise_no_default_keymappings = 1
\"})



"" CHECK: Integration of python notebooks {{{1
" OR wilywampa/vim-ipython
" BUG: don't work with system-wide python
" call dein#add('wmvanvliet/vim-ipython', {
"   \ 'if': executable('ipython'),
"   \ 'on_ft': 'python'})



"" HACK: forked for rich formatting, syntax HL, shorcuts {{{1
" Use '!dict' translations from inside vim
call dein#add('amerlyq/dictl.vim', {
  \ 'if': executable('dict'),
  \ 'on_map': [['nx', 'g=']],
  \ 'on_cmd': 'Dict'})



"" CHECK Recursive diff for dirs {{{1
" USAGE:<buffer>: <CR>/o, [nx, s], [uxiaq]
call dein#add('will133/vim-dirdiff', {
  \ 'on_cmd': 'DirDiff'})



""" Web

" W3m from vim {{{1
" yuratomo/w3m.vim: {}
" hook_add = 'nnoremap W     :<C-u>W3m<Space><C-r>+'
"
" Get page content by :e http://... w/o netrw {{{1
" repo = 'lambdalisue/vim-protocol'
" on_path = '^https\?://'
"
" Viewing man in vim -- good, but no colors in git lg1, need to investigate {{{1
" rkitover/vimpager: {}



"" CHECK open URI or search. Combinable with vim-quickrun ? {{{1
" NOTE:(opinion) curr overkill for me -- as most of feas impl'ed in qute
" BUG: sometimes works in same thread, loading CPU. TEMP:FIX: ./setup -U vim
" ALT:CHG: r.b --target tab "$@" BUT how to choose target window (named)?
call dein#add('tyru/open-browser.vim', {
  \ 'on_map': '<Plug>(openbrowser-',
  \ 'on_cmd': 'OpenBrowserSmartSearch',
  \ 'hook_source': "
\\n   let g:openbrowser_use_vimproc = 1
\\n   let g:openbrowser_no_default_menus = 1
\\n   let g:openbrowser_force_foreground_after_open = 1
\\n   let g:openbrowser_browser_commands = [
\   {'background': 0, 'name': 'r.b', 'args': ['{browser}', '{uri}']},
\   {'background': 1, 'name': 'firefox', 'args': ['{browser}', '{uri}']},
\   {'background': 0, 'name': 'w3m', 'args': ['{browser}', '{uri}']}
\ ]
\", 'hook_add': "
\\n   let g:netrw_nogx = 1
\\n   nmap gx <Plug>(openbrowser-smart-search)
\\n   vmap gx <Plug>(openbrowser-smart-search)
\"})



""" Services

" lyokha/vim-xkbswitch:  # HACK: replace by dbus-messages
"   description: Auto-switch for english/custom pair of langs on mode change {{{1
" \ 'on_cmd': EnableXkbSwitch
" filetypes: [tex, latex, bib, markdown, votl, txt]
" lazy: 0  # BUG:FIXME: no Lazy -- vim will pause 'ENTER on file open'
" let neobundle#'hook_source': _hcat('xkbswitch.src')



"" CHECK Search/preview unicode characters. Useful for font pictures. {{{1
call dein#add('chrisbra/unicode.vim', {
  \ 'build': 'sh -c "mkdir -p autoload/unicode && cd autoload/unicode &&
  \     wget -c http://www.unicode.org/Public/UNIDATA/UnicodeData.txt"',
  \ 'on_cmd': ['Digraphs', 'SearchUnicode', 'UnicodeName',
  \             'UnicodeTable', 'DownloadUnicode'],
  \ 'on_map': [['n', '<C-X><C-G>', '<C-X><C-Z>', '<F4>']]})



"" Show RGB color conversion table
call dein#add('guns/xterm-color-table.vim', {
  \ 'on_cmd': 'XtermColorTable',
  \ 'hook_source': "
\\n   let g:XtermColorTableDefaultOpen = 'tabnew'
\"})



"" CHECK Docs online searcher in one button for word under cursor {{{1
" ALT: vim-ref (similar?)
"   - Keithbsmiley/investigate.vim
"   - powerman/vim-plugin-viewdoc
call dein#add('KabbAmine/zeavim.vim', {
  \ 'if': executable('zeal'),
  \ 'on_map': ['<Plug>ZV', '<Plug>Zeavim'],
  \ 'hook_source': "let g:zv_disable_mapping = 1",
  \ 'hook_add': "
\\n   nmap <unique> <silent> g?  <Plug>Zeavim
\\n   vmap <unique> <silent> g?  <Plug>ZVVisSelection
\\n   nmap <unique> <silent> [Frame]zd <Plug>ZVKeyDocset
\\n   nmap <unique> <silent> [Frame]zk <Plug>ZVKeyword
\"})
" let g:zv_file_types = {'python' : 'python 3'}
" let g:zv_docsets_dir = has('unix') ?
"             \ '~/Important!/docsets_Zeal/' :
"             \ 'Z:/myUser/Important!/docsets_Zeal/'



"" CHECK Edit and save encrypted '*.gpg' files in-place {{{1
" HACK -- load-on-demand by calling non-existent command
" BUG: seems like can't do it lazy?
"   ALT: rewrite to more lightweight
" external_\ 'on_cmd': gpg
" filename_patterns: ['\.gpg$', '\.asc$', '\.pgp$']
" explorer: '.*\.\(gpg\|asc\|pgp\)$'
" explorer: 1
call dein#add('jamessan/vim-gnupg', {
  \ 'on_ft': 'gpg',
  \ 'on_cmd': ['GnuPG'],
  \ 'hook_post_source': "silent! exe 'do GnuPG BufReadCmd '",
  \ 'hook_source': "
\\n   let g:GPGDebugLevel = 1000
\\n   let g:GPGDebugLog = 'gpglog'
\"})
" fun! hooks.on_post_source(bundle)
"   " edit  " Re-read buffer to initiate GnuPG autocommands
"   " silent! exe 'doautocmd BufReadCmd' expand('%')
"   " silent! exe 'doautocmd FileReadCmd' expand('%')
" endf



""" VCS

"" CHECK:  WTF?
call dein#add('tpope/vim-git')



"" Github Issues {{{1
" FIXME:REQ: ssh credentials
" explorer: COMMIT_EDITMSG
" \ 'on_map': co, cc, <CR>
" BUG: if use simply "python"?
" XXX: lazy is conflicting with committia? Why?
" let g:github_upstream_issues = 1
"" USE:(encrypt): printf '<token>' | gpg -eo '<path>.gpg'
call dein#add('jaxbot/github-issues.vim', {
  \ 'if': 'has("python2")',
  \ 'on_cmd': ['Gissues', 'Giadd', 'Gmiles'],
  \ 'hook_source': "
\\n   let g:gissues_lazy_load = 1
\\n   let g:gissues_async_omni = 1
\\n   let s:p = expand('~/.cache/airy/gpg/github-token.gpg')
\\n   let s:cmd = 'gpg --use-agent --quiet --batch --decrypt '.shellescape(s:p)
\\n   let g:github_access_token = system(s:cmd)
\"})



"" Multiwindow diff/note regime for git commit/[--amend] {{{1
" ATTENTION: for reword you need option:  .gitconfig/[commit]/verbose=true
" FIXME:REQ: multicolumn has bug
"   let g:committia_use_singlecolumn = 1
"   let g:committia_min_window_width = 160
" EXPL: If no commit message, start with insert mode
call dein#add('rhysd/committia.vim', {
  \ 'hook_source': "
\\n   let g:committia_hooks = {}
\\n   let g:committia_open_only_vim_starting = 1
\\n   fun! g:committia_hooks.edit_open(info)
\\n     setl spell
\\n     if a:info.vcs ==# 'git' && getline(1) ==# '' | startinsert | end
\\n     imap <buffer><C-j> <Plug>(committia-scroll-diff-down-half)
\\n     imap <buffer><C-k> <Plug>(committia-scroll-diff-up-half)
\\n   endf
\"})



"" CHECK Git-frontend, overhaul {{{1
" BUG:(lazy) v +Gitv  -- Not a git repository
" BUG:(non-lazy) :Gitv -- tries to open current dir instead of file
" TODO: use more often, analyze more of help
" ALT: lambdalisue/vim-gita
"   SEE: https://lambdalisue.github.io/vimconf2015/#1
"   ALSO: http://b.hatena.ne.jp/heavenshell/vim/git/
" EXPL:(post-hook) Check if already inside some repository
call dein#add('tpope/vim-fugitive', {
  \ 'augroup': 'fugitive',
  \ 'on_cmd': ['Git', 'Gstatus', 'Gdiff', 'Glog',
  \   'Gbrowse', 'Gblame', 'Gwrite'],
  \ 'hook_post_source': "call fugitive#detect(expand('%:p'))",
  \ 'hook_add': "
\\n   autocmd BufReadPost fugitive://* setl bufhidden=delete
\\n   nnoremap <silent><unique> [Git]s :Gstatus<CR>
\\n   nnoremap <silent><unique> [Git]l :Glog<CR>
\\n   nnoremap <silent><unique> [Git]d :Gdiff<CR>
\\n   nnoremap <silent><unique> [Git]w :Gwrite<CR>
\\n   nnoremap <silent><unique> [Git]b :Gblame<CR>
\"})



"" CHECK See git tree and current file history for repo {{{1
" TODO: use more often, analyze more of help
"   <cr>: view commit, <C-n/p>: jump to next/prev commit and <cr>.
"   o: <cr> with split, O: tab, s: vsplit
"   co: checkout, S: diffstat, yc: copy SHA
"   x/X: next/previous branching point
" CHG: \ 'on_map': [ [Git]v, [Git]V ] -- file/full view
call dein#add('gregsexton/gitv', {
  \ 'on_cmd': 'Gitv',
  \ 'depends': 'vim-fugitive',
  \ 'hook_add': "
\\n   nnoremap <silent><unique> [Git]v :Gitv! --all<CR>
\\n   xnoremap <silent><unique> [Git]v :Gitv! --all<CR>
\\n   nnoremap <silent><unique> [Git]V :Gitv  --all<CR>
\"})



" TRY Manipulate Gist in vim {{{1
" repo = 'lambdalisue/vim-gista'
" on_map = {n = '<Plug>'}
" hook_add = '''
"   let g:gista#github_user = 'Shougo'
"   let g:gista#directory = expand('$CACHE/gista')
" '''


" HACK: adding syntax highlight
call dein#add('amerlyq/vim-tshark', {
  \ 'on_ft': 'tshark',
  \ 'hook_source': "
\\n   let g:tshark_nested_folds = 1
\\n   let g:tshark_detail_opts = '-V -x -t r'
\\n   let g:tshark_summary_opts = '-t r'
\"})
