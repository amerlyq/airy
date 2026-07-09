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
Aur("python-pylsp-mypy")
Aur("python-lsp-ruff")  # CASE: auto-remove unused imports
Pkg("ruff")  # CASE: native "ruff server"
# Pkg("python-lsp-black")
# Aur("python-pyls-isort")  # ALT: python-lsp-isort
Aur("basedpyright-bin")  # CASE: go-to-def better works with generics than jedi regexes
Aur("python-pylsp-rope")  # CASE: auto-add imports during completion
Aur("opengrep-bin")  # CASE: Find bug variants with patterns that look like source code.
Aur("refurb-git")  # CASE: modernizing Python codebases


Pkg("lua-language-server")


## 1. Install globally isolated CLI tools used by nvim-lint
# uv tool install semgrep
# uv tool install refurb
## 2. Install workspace refactoring LSPs into your active virtual environment
## (This ensures Rope understands your project's local dependency layout)
# uv pip install python-lsp-server pylsp-rope
## 3. Install the Rust-powered Basilisk binary globally or in your tool path
# # (Check https://github.com/Nimblesite/Basilisk instructions for your OS)
# uv tool install basilisk-code-actions
# cargo install basilisk-cli
# cargo install --git https://github.com/Nimblesite/Basilisk --bin basilisk-cli [--force] basilisk-cli
## OR:
# pipx install python-lsp-server --include-deps
# pipx inject python-lsp-server pylsp-rope


## ALT: don't use symlinks -- always copy whole file, and then install it by PKGBUILD
ln(".", under="~/.config/nvim")

# TODO: mkdir /@/audit/$HOST/vim
# mkdir -p ~/.cache/nvim/spell
# src='http://ftp.vim.org/pub/vim/runtime/spell'
# for nm in {ru,en,uk}.utf-8.{spl,sug}; do
#     wget "$src/$nm" -O ~/.cache/nvim/spell/"$nm"
# done
