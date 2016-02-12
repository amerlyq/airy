let s:save_cpo = &cpo
set cpo&vim

" Variables  "{{{
"}}}

function! unite#sources#mpd_history#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'mpd/history',
      \ 'description' : 'Mpd playback history log',
      \ 'default_kind' : 'command',
      \ 'max_candidates' : 100,
      \ 'sorters' : 'sorter_reverse',
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__MpdHistory',
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  let path = expand('$HOME/.mpd/history')
  let a:context.source__command = readfile(path)
endfunction "}}}


function! s:source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__MpdHistory_Date display contained /[^|]\+\ze|/
      \ containedin=uniteSource__MpdHistory
      \ nextgroup=uniteSource__MpdHistory_Marker
  syntax match uniteSource__MpdHistory_Marker display contained /|/
      \ containedin=uniteSource__MpdHistory
      \ nextgroup=uniteSource__MpdHistory_Name
  syntax match uniteSource__MpdHistory_Name display contained /|\zs.*$/
      \ containedin=uniteSource__MpdHistory

  highlight default link uniteSource__MpdHistory_Date Comment
  highlight default link uniteSource__MpdHistory_Marker Statement
  highlight default link uniteSource__MpdHistory_Name Normal
endfunction "}}}

comm! -bang -nargs=? PutL
      \ call append(line('.'), [substitute(<q-args>,'^[^|]\+|\s\+','','')])
      \ | exec "norm!j".(<bang>0?'^': '>>>>')

function! s:source.gather_candidates(args, context) "{{{
  let header = ['', ' <<<= Current =>>>  | '
        \ . join(systemlist('mpc current -f "%title%"'))]
  return map(copy(a:context.source__command) + header, "{
        \ 'word' : v:val,
        \ 'action__command' : 'PutL ' . v:val,
        \ 'action__histadd' : 0,
        \}")
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
