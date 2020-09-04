""" Mark-up / highlight

"" HACK jap ranobe translation/formatting {{{1
call dein#add('amerlyq/forestanza.vim', {
  \ 'on_ft': 'forestanza'})



" Maybe useful in combo with: {{{1
"   chikatoike/concealedyank.vim
"   switchr
"" HACK notes/outline
call dein#add('amerlyq/nou.vim', {
  \ 'on_ft': 'nou',
  \ 'depends': 'vim-textobj-user'})



"" TODO:REMOVE obsolete outliner {{{1
" call dein#add('vimoutliner/vimoutliner', {
"   \ 'on_ft': 'votl'})



"" JSON Highlight and indent {{{1
call dein#add('elzr/vim-json', {
  \ 'on_ft': 'json'})



"" YAML Highlight and indent {{{1
" SEE:THINK: https://github.com/lmeijvogel/vim-yaml-helper
call dein#add('mrk21/yaml-vim', {
  \ 'on_ft': 'yaml'})



" ALT: repo = 'rcmdnk/vim-markdown' {{{1
call dein#add('tpope/vim-markdown', {
  \ 'on_ft': 'markdown'})



" cespare/vim-toml:  # TODO:REMOVE
"   \ 'on_ft': toml



call dein#add('Matt-Deacalion/vim-systemd-syntax', {
  \ 'on_ft': 'systemd'})



" 'on_path': 'tmux.*conf'
call dein#add('zaiste/tmux.vim', {
  \ 'on_ft': 'tmux'})


" REF: https://github.com/gu-fan/riv.vim
" HELP: :RivInstruction | :RivQuickStart | :RivPrimer | :RivSpecification
" DEBUG: :RivReload
" let proj1 = { 'path': '~/Dropbox/rst', }
" let g:riv_projects = [proj1]
call dein#add('gu-fan/riv.vim', {
  \ 'on_ft': 'rst'})



call dein#add('aklt/plantuml-syntax')
  " \ 'on_ft': 'plantuml'})
" OLD:NICE:IDEA:(plain text) https://github.com/scrooloose/vim-slumlord
" NICE: https://github.com/previm/previm
" ALSO: https://wiki.archlinux.org/index.php/List_of_applications/Utilities#UML_modelers
call dein#add('weirongxu/plantuml-previewer.vim', {
  \ 'depends': ['tyru/open-browser.vim', 'aklt/plantuml-syntax']})
