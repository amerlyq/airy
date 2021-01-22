" @license MIT, (c) amerlyq, 2015
if &cp||exists('g:loaded_dictl')|finish|else|let g:loaded_dictl=1|endif

" ALT:(https://github.com/szw/vim-dict) -- works only through curl, no rich text support.
" TODO
"   2016-07-20 [X] highlight all english [a-z] words by overriding syntax as in notches
"   [_] Jump to next rus/eng line/word (like spelling error -- but TL synonyms)
" IDEA
"   [_] Splits on right/left -- reuse choosing mechanism from tagbar
"   [_] Save previous screens/queues in tagstack -- to jump on g=/g] and <C-T>
"   [_] Autoderive
"     [_] if all(char(c)<0x7f) [EnRu,EnUk,EnEn] else [RuEn,UkEn,RuRu]
"     [_] Use 'r.y' yarxi backend, if some searched symbols are >\u3000
"   [_] Synchroniously set language by dbus on launch when using different shortcuts
"   [_] Reformat output to place main secton in beginning
"   [_] BUG: can't find anything on ':Dict разделять'

command! -nargs=? -range Dict :call dictl#get(<q-args>)

nnoremap <silent><unique> g=  :Dict <C-r><C-w><CR>
vnoremap <silent><unique> g=  :Dict <C-r>=GetVisualSelection(" ")<CR><CR>
