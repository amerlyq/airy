from airy.api import ln, Pkg

Pkg("ncmpcpp")
# Aur("python-azlyrics-git")

# TODO: upgrade config to newest version
ln("config" , under="~/.config/ncmpcpp")
ln("bindings" , under="~/.config/ncmpcpp")
