" Join separetely quoted elements in array ['aaa', '"so', 'me"', 'bbb']
function! ag#bind#fix_fargs(args)
  if len(a:args) < 2 | return a:args | endif
  let a = a:args
  let lena = len(a)
  let i = 0
  while i < lena
    let j = 1
    while j < lena - i
      if (a[i] =~# '^".*[^"]$' && a[i+j] =~# '^[^"].*"$')
        \||(a[i] =~# "^'.*[^']$" && a[i+j] =~# "^[^'].*'$")
        for k in range(1, j)
          let a[i] .= ' '.remove(a, i+1)
        endfor
        let lena-=j
      endif
      let j += 1
    endwhile
    let i += 1
  endwhile
  return a
endfunction

" Tests: vader
" Execute (List ag#bind#fix_fargs):
"   AssertEqual ag#bind#fix_fargs(['singleword']), ['singleword']
"   AssertEqual ag#bind#fix_fargs(['raw', 'multi']), ['raw', 'multi']
"   AssertEqual ag#bind#fix_fargs(['"quoted', 'multi"']), ['"quoted multi"']
"   AssertEqual ag#bind#fix_fargs(["'squoted", "multi'"]), ["'squoted multi'"]
