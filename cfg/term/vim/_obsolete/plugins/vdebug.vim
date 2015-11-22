" Vdebug {{{
" Depends on http://code.activestate.com/komodo/remotedebugging/
" Maped permanently only "run":<F5> and "set_breakpoint":<F10>.
" All others are mapped only while Vdebug is run, restoring origin on stop.
" To stop debugging, press <F6>. Press again to close the dbg interface.
" Run: :Vdebug in one window, and then $ make vdbg in another
" curl 'http://code.activestate.com/komodo/remotedebugging/' | sed -n '/.*\(Komodo-PythonRemoteDebugging-.*-linux-x86_64\.tar\.gz\).*/{p;q}'
let g:vdebug_keymap = {
    \    "run" : "<F5>",
    \    "run_to_cursor" : "<F1>",
    \    "step_over" : "<F2>",
    \    "step_into" : "<F3>",
    \    "step_out" : "<F4>",
    \    "close" : "<F6>",
    \    "detach" : "<F7>",
    \    "set_breakpoint" : "<F10>",
    \    "get_context" : "<F11>",
    \    "eval_under_cursor" : "<F12>",
    \    "eval_visual" : "\e",
    \ }
" let g:vdebug_features['max_depth'] = 2048
