from airy.api import Pkg

# WTF: original youtube-dl-git REQ tons of haskell-*
Pkg("yt-dlp")
Pkg("python-curl_cffi")  # REF: https://github.com/yt-dlp/yt-dlp#impersonation
Pkg("python-mutagen")
Aur("gallery-dl-bin")
