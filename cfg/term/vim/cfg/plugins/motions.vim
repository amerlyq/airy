""" Motions

"" STD plugin for matching pairs/triples of block expr
call dein#add('matchit.zip', {'frozen': 1,
  \ 'on_map': [['nvo', '%', 'g%', '[%', ']%'], ['v', 'a%']] })


"" Readline style motions in insert and cmdline
" SEE: http://www.vim.org/scripts/script.php?script_id=4359
" DEV:TODO: replace by own -- to confront with ZSH, <C-f>, etc
" NOTE: Direct key mappings have no sense of being lazy
call dein#add('tpope/vim-rsi', {'lazy': 0})


"" Motions in _camel_case_ or CamelCase for all modes
" ALT:CHECK: - (compare code) https://github.com/machakann/vim-textobj-delimited
call dein#add('bkad/CamelCaseMotion', {'on_map': '<Plug>CamelCaseMotion_'})
" DEPRECATED:
"   - (inferior) lucapette/vim-textobj-underscore


"" Two-letters find on whole screen scope
call dein#add('justinmk/vim-sneak', {
  \ 'on_map': '<Plug>Sneak',
  \ 'depends': 'tpope/vim-repeat'})
" DEPRECATED:
"   - (bloated) Lokaltog/vim-easymotion
"   - (altered) https://github.com/rhysd/clever-f.vim
