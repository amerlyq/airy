" vim:fdm=marker:fdl=1

"{{{1 Motions ============================
NeoBundleLazy 'matchit.zip', { 'autoload' : { 'mappings' : ['%', 'g%'] }}
" Two-letters find on whole screen scope
" THINK as augment: https://github.com/rhysd/clever-f.vim
NeoBundle 'justinmk/vim-sneak'
" New motions [count]{ ,w ,b ,e } for n/o/v modes in camel_case
NeoBundleLazy 'bkad/CamelCaseMotion', { 'autoload': {
    \ 'mappings': '<Plug>' }}
" Readline style insertion
" http://www.vim.org/scripts/script.php?script_id=4359
NeoBundle 'tpope/vim-rsi'

"{{{1 Actions ============================
" ALT: 'tomtom/tcomment_vim'
NeoBundle 'tpope/vim-commentary'
" Automatic not-persistent closing statements
NeoBundle 'tpope/vim-endwise'
" Extend support for '.' command
NeoBundle 'tpope/vim-repeat'
" Use CTRL-A/X to increment dates, times, and more
NeoBundle 'tpope/vim-speeddating'
" Exchange text: cx{motion} on first, then cx{motion} on other.
"   cxx -- current line, X -- in Visual mode,  cxc -- clear pending exchange.
NeoBundle 'tommcdo/vim-exchange'
" Mappings to add empty lines or move/exchange/duplicate/fetch lines of text
" ALT NeoBundle 'tpope/vim-unimpaired'
" NeoBundle 'vim-scripts/LineJuggler'
NeoBundle 'kana/vim-niceblock'        " I,A,gI for all VISUAL like in V-BLOCK

"{{{1 Operators ============================
NeoBundle 'kana/vim-operator-user'         " = Dependency: vim-clang-format
NeoBundle 'rhysd/vim-operator-surround'    "q..[ai]..-- boundaries of motion
NeoBundleLazy 'kana/vim-operator-replace', {
      \ 'depends': 'kana/vim-operator-user',
      \ 'autoload': { 'mappings': [['nx', '<Plug>']] } }

"{{{1 Textobj ============================
NeoBundle 'kana/vim-textobj-user'          " = Dependency: vim-textobj-*
NeoBundle 'kana/vim-textobj-entire'        " ..[ai]G -- instead ggVG
NeoBundle 'kana/vim-textobj-fold'          " ..[ai]z
NeoBundle 'kana/vim-textobj-function'      " ..[ai][fF] (C/Java/Vimscript)
NeoBundle 'kana/vim-textobj-indent'        " ..[ai][iI] -- python-like indented
NeoBundle 'kana/vim-textobj-line'          " ..[ai]l -- line content only
NeoBundle 'kana/vim-textobj-syntax'        " ..[ai]h -- highlighted syntax region
NeoBundle 'coderifous/textobj-word-column.vim'  " ..[ai][cC] -- «smart» column

"" NOTE pairs by priority: ({["'<`
" ALT (more old and in jp) 'osyo-manga/vim-textobj-multiblock'
"  Add buffer local: let b:textobj_anyblock_buffer_local_blocks = [ ':', '*' ]
NeoBundle 'rhysd/vim-textobj-anyblock'     " ..[ai]b -- content of closest pair
NeoBundle 'thinca/vim-textobj-between'     " ..[ai]f..- between found symbols

NeoBundle 'beloglazov/vim-textobj-quotes'  " ..[ai]q -- any nearest quotes (OR: ..q)
NeoBundle 'saihoooooooo/vim-textobj-space' " ..[ai]s -- space between words, etc
NeoBundle 'vimtaku/vim-textobj-sigil'      " ..[ai]g -- for bash/perl $name{...}
" ALT 'sgur/vim-textobj-parameter', 'PeterRincker/vim-argumentative'
NeoBundle 'AndrewRadev/sideways.vim'       " ..[ai], and [<>], -- shift
" ALT 'airblade/vim-gitgutter' (git only, but much faster file save)
NeoBundle 'mhinz/vim-signify'              " ..[ai]S -- inside vcs area
