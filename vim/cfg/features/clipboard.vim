"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq

" ATT: set g:clipboard before has('clipboard')
" ATT:NEED:(g:clipboard): vim > (6016ac27 of 20170627)
"   https://github.com/neovim/neovim/issues/6029
" ALT:DEV: https://neovim.io/doc/user/provider.html

"" FIXME: using default pref=xclip will break my remote clipboard
"" NOTE:(cache_enabled=0 .vs. -quiet): use single system-wide !xclip .vs. per-session
let g:clipboard = {
  \ 'name': 'xclip',
  \ 'copy': {
  \   '+': 'xci',
  \   '*': 'xclip -i -selection primary',
  \  },
  \ 'paste': {
  \   '+': 'xco',
  \   '*': 'xclip -o -selection primary',
  \ },
  \ 'cache_enabled': 0,
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
