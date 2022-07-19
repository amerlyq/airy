from just.airy import M
# pkgs = ["neovim"]
pkgs = []

# VIZ. $ nvr to talk to vim from inside ranger
aurs = ["neovim-git", "neovim-remote", "code-minimap-bin"]


# DEPS:(aur/python-lsp-all):
#   python-pylsp-rope ALSO: pip install pylsp-autoimport && auri python-autoimport
pkgs += ["python-pylint", "python-lsp-server", "python-lsp-black"]
aurs += ["python-pylsp-mypy", "python-pyls-isort"]  # python-lsp-isort
# pip_inst pyls-isort

pkgs += ["lua-language-server"]

## ALT: don't use symlinks -- always copy whole file, and then install it by PKGBUILD
links = [(Path.cwd(), "~/.config/nvim")]

# TODO: mkdir /@/audit/$HOST/vim
