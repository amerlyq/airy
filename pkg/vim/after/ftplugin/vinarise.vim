" Amer chg for mappings
nmap <buffer> V             <Plug>(vinarise_edit_with_vim)
nmap <buffer> q             <Plug>(vinarise_hide)
nmap <buffer> Q             <Plug>(vinarise_exit)

nmap <buffer> l             <Plug>(vinarise_next_column)
nmap <buffer> h             <Plug>(vinarise_prev_column)
nmap <buffer> j             <Plug>(vinarise_next_line)
nmap <buffer> k             <Plug>(vinarise_prev_line)

nmap <buffer> <C-f>         <Plug>(vinarise_next_screen)
nmap <buffer> <C-b>         <Plug>(vinarise_prev_screen)
nmap <buffer> <PageDown>    <Plug>(vinarise_next_screen)
nmap <buffer> <PageUp>      <Plug>(vinarise_prev_screen)
nmap <buffer> <C-d>         <Plug>(vinarise_next_half_screen)
nmap <buffer> <C-u>         <Plug>(vinarise_prev_half_screen)

nmap <buffer> <C-g>         <Plug>(vinarise_print_current_position)

nmap <buffer> r             <Plug>(vinarise_change_current_address)
nmap <buffer> R             <Plug>(vinarise_overwrite_from_current_address)
nmap <buffer> gG            <Plug>(vinarise_move_by_input_address)
nmap <buffer> go            <Plug>(vinarise_move_by_input_offset)
nmap <buffer> gg            <Plug>(vinarise_move_to_first_address)
nmap <buffer> G             <Plug>(vinarise_move_to_last_address)

nmap <buffer> 0             <Plug>(vinarise_line_first_address)
nmap <buffer> ^             <Plug>(vinarise_line_first_address)
nmap <buffer> $             <Plug>(vinarise_line_last_address)

" Conflicst with mine
" nmap <buffer> gh          <Plug>(vinarise_line_first_address)
" nmap <buffer> gl          <Plug>(vinarise_line_last_address)

nmap <buffer> g/             <Plug>(vinarise_search_binary)
nmap <buffer> g?             <Plug>(vinarise_search_binary_reverse)
nmap <buffer> /            <Plug>(vinarise_search_string)
nmap <buffer> ?            <Plug>(vinarise_search_string_reverse)
nmap <buffer> e/            <Plug>(vinarise_search_regexp)

nmap <buffer> n             <Plug>(vinarise_search_last_pattern)
nmap <buffer> N             <Plug>(vinarise_search_last_pattern_reverse)
nmap <buffer> E             <Plug>(vinarise_change_encoding)

nmap <buffer> <C-l>         <Plug>(vinarise_redraw)
nmap <buffer> g<C-l>        <Plug>(vinarise_reload)
nmap <buffer> B             <Plug>(vinarise_bitmapview)
nmap <buffer> w             <Plug>(vinarise_next_skip)
nmap <buffer> b             <Plug>(vinarise_prev_skip)
