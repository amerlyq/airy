"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq

" ATT:NEED:(g:clipboard): vim > (6016ac27 of 20170627)
"   https://github.com/neovim/neovim/issues/6029
" ALT:DEV: https://neovim.io/doc/user/provider.html
let g:clipboard = {
  \ 'name': 'ssh-xsel',
  \ 'copy': {
  \   '+': 'xsel --nodetach -b -i',
  \   '*': 'xsel --nodetach -p -i',
  \  },
  \ 'paste': {
  \   '+': 'xsel -b -o',
  \   '*': 'xsel -p -o',
  \ },
  \ 'cache_enabled': 1,
  \}

" if exists('$DISPLAY') && has('clipboard')
" BAD: has('clipboard') need to access provider => shows message
"   TEMP:FIX: place after g:clipboard
if has('clipboard')
  " set clipboard=unnamedplus,unnamed
  if v:version > 703 || (v:version == 703 && has('patch74'))
    set clipboard=unnamedplus
  else
    set clipboard=unnamed
  endif
endif
