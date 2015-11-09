" Add ranger as a file chooser in vim
"
" If you add this code to the .vimrc, ranger can be started using the command
" ":RagerChooser" or the keybinding "<leader>r". Once you select one or more
" files, press enter (or move right) and ranger will quit again and vim will
" open the selected files.

function! RangeChooser()
    let temp = tempname()
    exec 'Silent ranger --choosefiles=' . shellescape(temp)
    if !filereadable(temp) | redraw! | return | endif
    let names = readfile(temp)
    if empty(names) | redraw! | return | endif
" Edit the first item.
    exec 'edit ' . fnameescape(names[0])
" Add any remaning items to the arg list/buffer list.
    for name in names[1:]
        exec 'argadd ' . fnameescape(name)
    endfor
    redraw!
endfunction

command! -bar RangerChooser call RangeChooser()
