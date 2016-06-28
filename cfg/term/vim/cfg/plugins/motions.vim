""" Motions

"" STD plugin for matching pairs/triples of block expr {{{1
call dein#add('matchit.zip', {'frozen': 1,
  \ 'on_map': [['nvo', '%', 'g%', '[%', ']%'], ['v', 'a%']],
  \ 'hook_post_source': 'sil! exe "doautocmd Filetype" &filetype'})


"" Readline style motions in insert and cmdline {{{1
" SEE: http://www.vim.org/scripts/script.php?script_id=4359
" DEV:TODO: replace by own -- to confront with ZSH, <C-f>, etc
" NOTE: Direct key mappings have no sense of being lazy
call dein#add('tpope/vim-rsi')


"" Motions in _camel_case_ or CamelCase for all modes {{{1
" ALT:CHECK: - (compare code) https://github.com/machakann/vim-textobj-delimited
" NOT:(needless loading): camelcasemotion#CreateMotionMappings('<leader>')
" DEPRECATED:
"   - (inferior) lucapette/vim-textobj-underscore
call dein#add('bkad/CamelCaseMotion', {
  \ 'on_map': '<Plug>CamelCaseMotion_'})

if dein#tap('CamelCaseMotion')
  for c in split('w b e ge')
    call Map_nxo('<Leader>'.c, '<Plug>CamelCaseMotion_'.c)
    call Map_nxo('i<Leader>'.c, '<Plug>CamelCaseMotion_i'.c, 'ox')
  endfor
endif


"" Two-letters find on whole screen scope {{{1
" DEPRECATED:
"   - (bloated) Lokaltog/vim-easymotion
"   - (altered) https://github.com/rhysd/clever-f.vim
call dein#add('justinmk/vim-sneak', {
  \ 'on_map': '<Plug>Sneak',
  \ 'depends': 'vim-repeat',
  \ 'hook_source': 'source $DEINHOOKS/vim-sneak.vim'})
