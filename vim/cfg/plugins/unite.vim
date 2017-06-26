""" United drop-down menus
" SEE: http://bling.github.io/blog/2013/06/02/unite-dot-vim-the-plugin-you-didnt-know-you-need/

"" CHECK Unite main sources {{{1
call dein#add('Shougo/neomru.vim', {'lazy': 0,
  \ 'hook_add': "
\\n   let g:neomru#file_mru_path = $VPLUGS.'/mru_file'
\\n   let g:neomru#directory_mru_path = $VPLUGS.'/mru_dir'
\"})

call dein#add('Shougo/neoyank.vim', {'lazy': 0,
  \ 'hook_add': "
\\n   let g:neoyank#file = $VPLUGS.'/neoyank_hist'
\"})



"" CHECK Auxiliary sources {{{1
" ATTENTION: when unite.vim loads, 'on_source' will load all its plugins
"   -- TRY: add on_source: [...] to unite.vim
"   -- BUT? will it support sources loaded afterwards its loading?
" BAD: 'on_source' won't work when 'unite.vim' loaded on start and not lazy
"   => it _must_ be loaded for neoyank/neomru
call dein#add('Shougo/unite-outline', {'lazy': 0})
call dein#add('thinca/vim-unite-history', {'lazy': 0})
call dein#add('osyo-manga/unite-quickfix', {'lazy': 0})
call dein#add('tsukkee/unite-tag', {'lazy': 0})
call dein#add('Shougo/unite-build', {'lazy': 0})



"" CHECK Fast fuzzy access to List i-sources. Dependency of 'unite-*'. {{{1
" NOTE: [Unite]h help, -u outline, -n file/new
call dein#add('Shougo/unite.vim', {
  \ 'depends': 'neomru.vim',
  \ 'hook_post_source': 'call _cfg("unite/*.vim")',
  \ 'hook_add': _hcat('unite.add')})
