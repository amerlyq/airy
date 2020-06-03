# ranger.vim
Ranger as vim filechooser


## Usage
Once you select one or more files, press enter (or move right) to quit ranger
and submit selected files into vim.


## Unique features
* Agenda: current file, working dir and last opened dirs
* Tabview: open ranger in sep tab to select files and return back
* Precmd: show only `messages.log*` files when investigating logs in vim
```
  au MyAutoCmd BufRead,BufNewFile messages.log*  let b:ranger_rangercmd = 'filter messages.log'
  # Or better assign it directly inside 'ftplugin/messages.vim'
```
* Options for finer configuration


## Installation
```
call dein#add('amerlyq/ranger.vim', {'lazy': 0, 'if': executable('ranger')})
```


## Supersedes
* https://github.com/francoiscabrol/ranger.vim

    Cons: uses system() and shell commands instead of vimscript, inflexible

* https://github.com/renyard/vim-rangerexplorer
* https://github.com/Mizuchi/vim-ranger

    Cons: naive, hardcoded

* https://github.com/vim-scripts/vim-ranger

    Cons: broken

* https://github.com/vim-scripts/Ranger.vim

    Alt: operators
    Cons: sloppy implementation

* https://github.com/koreyconway/ranger.vim
* https://github.com/iberianpig/ranger-explorer.vim

    Cons: simple, messy, don't work in neovim

* https://github.com/rafaqz/ranger.vim

    Todo: seize paste


## SEE
* https://github.com/mikezackles/vranger

    ++ integrates single vim session inside tmux into outer ranger
        ==> so, it's concept turned inside out
