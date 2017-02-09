let s:save_cpo = &cpo
set cpo&vim

" Variables  "{{{
"}}}

function! unite#sources#mycmd#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'mycmd',
      \ 'description' : 'My custom util commands',
      \ 'default_kind' : 'command',
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__Mycmd',
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  let path = expand('$VIMHOME/doc/commands.vim')
  let a:context.source__command = readfile(path)
endfunction "}}}


function! s:source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__Mycmd_Line display contained
      \ /.*/
      \ containedin=uniteSource__Mycmd
      \ contains=@uniteSource__Mycmd_Embed

  highlight default link uniteSource__Mycmd_Line Statement
  " let g = 'uniteSource__Mycmd_Embed'
  " try|exe 'syn include '.g.' syntax/vim.vim'      |catch/E403\|E484/|endtry
  " try|exe 'syn include '.g.' after/syntax/vim.vim'|catch/E403\|E484/|endtry
endfunction "}}}


function! s:source.gather_candidates(args, context) "{{{
  return map(copy(a:context.source__command), "{
        \ 'word' : v:val,
        \ 'action__command' : v:val.' ',
        \ 'source__command' : ':'.v:val,
        \ 'action__histadd' : 1,
        \}")
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
