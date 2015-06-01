# MPogoda's dotfiles #

## About ##

Dotfiles, gathered from pieces of other people' dotfiles all around the world.
Currently, it holds configuration files for:
  * [VIm](http://vim.org)
  * [XMonad](http://xmonad.org)
  * [XMobar](http://projects.haskell.org/xmobar)
  * [Zsh](http://zsh.org)
  * [git](http://git-scm.com)
  * [tmux](http://tmux.sourceforge.net)
  * [xterm](http://invisible-island.net/xterm/)
  * [Tig](http://jonas.nitro.dk/tig)
  * etc

Although they all present in this repo, they are (mostly) not interdependent.

## Dependencies ##

 * VIm 7+
 * git v1.7.11+ (for push.default = simple)
 * [xkb-switch](https://github.com/ierton/xkb-switch). Used by vim-xkbswitch
   plugin
 * [clang](http://clang.llvm.org). Used by clang_complete pluging
 * [Exuberant ctags 5.5](http://ctags.sourceforge.net). Used by vim/tagbar
 * [ag](https://github.com/ggreer/the_silver_searcher). Used by vim/unite and
   vim/ag.

## Vim plugins ##

For managing plugins for VIm, [neoBundle](https://github.com/Shougo/neobundle.vim/) is
used.
And, NeoBundle is managed by itself, so chicken-egg problem arises.
Because of that small shell script is provided for installation.

Updating vim-bundles is simple:
```
vim +NeoBundleUpdate
```

## Installation ##

```
git clone git://github.com/MPogoda/dotfiles.git
# edit dotfiles/vim/bundles.vim if you want to
pushd
sh path/to/dotfiles/install.sh
popd
```

## Thanks to ##
  * [sunaku's .vim](https://github.com/sunaku/.vim)
  * [zsh-lovers config](http://grml.org/zsh)
