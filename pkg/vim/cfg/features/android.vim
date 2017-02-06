" Use mouse only for scrolling
set mouse=n
noremap  <LeftMouse> <Nop>
noremap  <2-MiddleMouse> <Nop>
inoremap <2-MiddleMouse> <Nop>
noremap  <3-MiddleMouse> <Nop>
inoremap <3-MiddleMouse> <Nop>
noremap  <4-MiddleMouse> <Nop>
inoremap <4-MiddleMouse> <Nop>

" It doesn't work anyways -- by ssh-ing in chroot without X
set clipboard= "empty

inoremap <unique> jj <Esc>
