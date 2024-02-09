from airy.api import ln, Pkg

Pkg("ncmpcpp")

# TODO: upgrade config to newest version
ln("config" , under="~/.config/ncmpcpp")
ln("bindings" , under="~/.config/ncmpcpp")
