" Fix for autocomplete issue with <Plug>
function! Multiple_cursors_before()
    exe 'NeoCompleteLock'
    "echo 'Disabled autocomplete'
endfunction

function! Multiple_cursors_after()
    exe 'NeoCompleteUnlock'
    "echo 'Enabled autocomplete'
    "exe 'visual'
endfunction
