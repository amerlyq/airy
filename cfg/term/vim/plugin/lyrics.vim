if &cp||exists('g:loaded_lyrics')|finish|else|let g:loaded_lyrics=1|endif


comm! -bar -nargs=0  LyricsFormat  call lyrics#cfg()
comm! -bar -nargs=0  LyricsLoad    call lyrics#load()

comm! -bang -bar -nargs=0 -range=%  LyricsSortLn
      \ call lyrics#lsort(<bang>0, <line1>, <line2>)

comm! -bar -nargs=0 -range=%  LyricsJoin
      \ call lyrics#join(<line1>, <line2>)

comm! -bar -nargs=0 -range=%  LyricsSplit
      \ call lyrics#split(<line1>, <line2>)

comm! -bang -bar -nargs=0 -range=%  LyricsShuffle
      \ call lyrics#shuffle(<bang>0, <line1>, <line2>)
