"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq

" if exists('$DISPLAY') && has('clipboard')
if has('clipboard')
  " set clipboard=unnamedplus,unnamed
  if v:version > 703 || (v:version == 703 && has('patch74'))
    set clipboard=unnamedplus
  else
    set clipboard=unnamed
  endif
endif

" https://neovim.io/doc/user/provider.html
" https://github.com/neovim/neovim/issues/6029
"   = seems like I need recent nvim for this to override defaults when xsel installed
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
