from airy.api import Pkg, cp

Pkg("dictd")

## OR:
# Aur("goldendict-webengine-git")
# Aur("goldendict-enruen-content")



cp("cfg/colorit.conf", under="/etc/dict")
cp("cfg/dict.conf", under="/etc/dict")
cp("cfg/dict_fallbacks.conf", under="/etc/dict")
cp("cfg/dictd.conf", under="/etc/dict")
cp("cfg/dictd.order", under="/etc/dict")
cp("cfg/dictdconfig.alias", under="/etc/dict")
cp("cfg/site.info", under="/etc/dict")

# sudo mkdir -p /usr/share/dictd
# sudo chown "${USER}:users" /usr/share/dictd
# rsync -e ssh -avhP lcloud:/me/_pj-data/dict/dicts/ /usr/share/dictd
# ./scripts/indexate $(cfgOpt r && echo -r)

cp("dictd.service", under="/etc/systemd/system")
# sudo systemctl enable --now dictd.service
