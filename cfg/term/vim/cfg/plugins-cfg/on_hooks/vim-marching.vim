" clang コマンドの設定
"let g:marching_clang_command = "C:/clang.exe"

" オプションを追加する
" filetype=cpp に対して設定する場合
let g:marching#clang_command#options = {
\   "cpp" : "-std=gnu++1y"
\}

" インクルードディレクトリのパスを設定
"let g:marching_include_paths = [
"\   "C:/MinGW/lib/gcc/mingw32/4.6.2/include/c++"
"\   "C:/cpp/boost"
"\]

" neocomplete.vim と併用して使用する場合
let g:marching_enable_neocomplete = 1

if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif

let g:neocomplete#force_omni_input_patterns.cpp =
    \ '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'

" オムニ補完時に補完ワードを挿入したくない場合
imap <buffer> <C-x><C-o> <Plug>(marching_start_omni_complete)

" キャッシュを削除してからオムに補完を行う
imap <buffer> <C-x><C-x><C-o> <Plug>(marching_force_start_omni_complete)


" 非同期ではなくて、同期処理でコード補完を行う場合
" この設定の場合は vimproc.vim に依存しない
" let g:marching_backend = "sync_clang_command"

