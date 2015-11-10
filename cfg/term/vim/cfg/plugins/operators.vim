" vim:fdm=marker:fdl=1

"{{{1 Motions ============================
" Two-letters find on whole screen scope
NeoBundle 'justinmk/vim-sneak'
" New motions [count]{ ,w ,b ,e } for n/o/v modes in camel_case
NeoBundle 'bkad/CamelCaseMotion'
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

"{{{1 Textobj ============================
NeoBundle 'kana/vim-operator-user'              " = Dependency: vim-clang-format
NeoBundle 'kana/vim-textobj-user'               " = Dependency: vim-textobj-*
NeoBundle 'kana/vim-textobj-entire'             " ..[ai]e -- instead ggVG
NeoBundle 'kana/vim-textobj-fold'               " ..[ai]z
NeoBundle 'kana/vim-textobj-function'           " ..[ai][fF] (C/Java/Vimscript)
NeoBundle 'kana/vim-textobj-indent'             " ..[ai][iI]
NeoBundle 'kana/vim-textobj-line'               " ..[ai]l
NeoBundle 'kana/vim-textobj-syntax'             " ..[ai]y
NeoBundle 'coderifous/textobj-word-column.vim'  " ..[ai][cC]<[IA]>
NeoBundle 'rhysd/vim-operator-surround'         "q..[ai]..
NeoBundle 'beloglazov/vim-textobj-quotes'       " ..[ai]q -- any nearest quotes (OR: ..q)
NeoBundle 'saihoooooooo/vim-textobj-space'      " ..[ai]Q -- space between words, etc
NeoBundle 'vimtaku/vim-textobj-sigil'           " ..[ai]G
" ALT: 'sgur/vim-textobj-parameter', 'PeterRincker/vim-argumentative'
NeoBundle 'AndrewRadev/sideways.vim'            " ..[ai], and [<>], -- shift
