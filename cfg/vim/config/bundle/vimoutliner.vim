"Common Plugins ***************************************************
" This setting loads the checkboxes, tags and smart_paste plugins as default.
let g:vo_modules_load = "checkbox:tags:smart_paste:format:clock"
":math:newhoist" (extracting tree in ./ folder in temp file)
"Uncomment and set to 1 to debug hoisting
"let g:hoistParanoia=0
let g:use_space_colon = 0

"User Preferences ***************************************************
let maplocalleader = ",,"   " this is prepended to VO key mappings

"setlocal ignorecase           " searches ignore case
"setlocal smartcase            " searches use smart case
"setlocal wrapmargin=5
"setlocal tw=78
"setlocal tabstop=4            " tabstop and shiftwidth must match
"setlocal shiftwidth=4         " values from 2 to 8 work well
"setlocal background=dark      " for dark backgrounds
"setlocal nowrap

"Extra mappings *****************************************************
"This mapping is fold-level and fold-state dependent
"map <S-Down> dd p
"map <S-Up> dd <up>P
