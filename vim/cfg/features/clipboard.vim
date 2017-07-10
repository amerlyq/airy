"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq

" ATT: set g:clipboard before has('clipboard')
" ATT:NEED:(g:clipboard): vim > (6016ac27 of 20170627)
"   https://github.com/neovim/neovim/issues/6029
" ALT:DEV: https://neovim.io/doc/user/provider.html
let g:clipboard = {
  \ 'name': 'xsel-remote',
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

" BAD: has('clipboard') needs to access provider => shows errmsg
"   E.G. system w/o my 'xsel-remote' wrapper installed (ubuntu chroot / android)
"   FIX: if (path/to/xsel == "/usr/bin/xsel" && exists('$DISPLAY') && has('clipboard')
if has('clipboard')
  " set clipboard=unnamedplus,unnamed
  if v:version > 703 || (v:version == 703 && has('patch74'))
    set clipboard=unnamedplus
  else
    set clipboard=unnamed
  endif
endif
