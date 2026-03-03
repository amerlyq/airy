from airy.api import Aur, Pkg, ln

# MAYBE: "code-minimap-bin" for minimap.vim

# VIZ. $ nvr to talk to vim from inside ranger
Pkg("neovim")
Pkg("tree-sitter-cli")
# Aur("neovim-git")
Aur("neovim-remote")


# DEPS:(aur/python-lsp-all):
#   python-pylsp-rope ALSO: pip install pylsp-autoimport && auri python-autoimport
Pkg("python-pylint")
Pkg("python-lsp-server")
Pkg("python-lsp-black")
Aur("python-pylsp-mypy")
Aur("python-pyls-isort")  # ALT: python-lsp-isort
Aur("python-lsp-ruff")  # CASE: auto-remove unused imports
Pkg("ruff")  # CASE: native "ruff server"
Aur("basedpyright-bin")  # CASE: go-to-def better works with generics than jedi regexes
Aur("python-pylsp-rope")  # CASE: auto-add imports during completion

Pkg("lua-language-server")


## ALT: don't use symlinks -- always copy whole file, and then install it by PKGBUILD
ln(".", under="~/.config/nvim")

# TODO: mkdir /@/audit/$HOST/vim
# mkdir -p ~/.cache/nvim/spell
# src='http://ftp.vim.org/pub/vim/runtime/spell'
# for nm in {ru,en,uk}.utf-8.{spl,sug}; do
#     wget "$src/$nm" -O ~/.cache/nvim/spell/"$nm"
# done
