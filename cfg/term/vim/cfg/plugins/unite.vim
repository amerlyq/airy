""" United drop-down menus
" SEE: http://bling.github.io/blog/2013/06/02/unite-dot-vim-the-plugin-you-didnt-know-you-need/

"" CHECK Unite main sources {{{1
call dein#add('Shougo/neomru.vim', {'on_if': 1})
call dein#add('Shougo/neoyank.vim', {'on_if': 1, 'on_source': 'unite.vim'})



"" CHECK Auxiliary sources {{{1
" ATTENTION: when unite.vim loads, 'on_source' will load all its plugins
"   -- TRY: add on_source: [...] to unite.vim
"   -- BUT? will it support sources loaded afterwards its loading?
call dein#add('Shougo/unite-outline', {'on_source': 'unite.vim'})
call dein#add('thinca/vim-unite-history', {'on_source': 'unite.vim'})
call dein#add('osyo-manga/unite-quickfix', {'on_source': 'unite.vim'})
call dein#add('tsukkee/unite-tag', {'on_source': 'unite.vim'})
call dein#add('Shougo/unite-build', {'on_source': 'unite.vim'})



"" CHECK Fast fuzzy access to List i-sources. Dependency of 'unite-*'. {{{1
" NOTE: [Unite]h help, -u outline, -n file/new
call dein#add('Shougo/unite.vim', {
  \ 'depends': 'neomru.vim',
  \ 'hook_source': 'call _cfg("unite/*.vim")',
  \ 'hook_add': _hcat('unite.add')})
