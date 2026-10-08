# This plugin adds the sorting algorithm called 'random'.  To enable it, type
# ":set sort=random" or create a key binding with ":map oz set sort=random"

import os
import re

from ranger.container.directory import Directory
from ranger.container.fsobject import FileSystemObject

Directory.sort_dict["from_end"] = lambda x: x.relative_path[::-1]
Directory.sort_dict["name_len"] = lambda x: (len(x.relative_path), x.relative_path)
Directory.sort_dict["lctime"] = lambda x: -(os.lstat(x.path).st_ctime or 1)

_TOKEN = r"(?:\d+m\d+s\d+|v\d+|prev\d+)"
_CLIP_SUFFIX = re.compile(_TOKEN + r"(?:_" + _TOKEN + r")*$")
_SIZECLIPS_CACHE: dict[str, dict[str, int]] = {}


def _dir_sizes(path: str) -> dict[str, int]:
    directory = os.path.dirname(path)
    if directory not in _SIZECLIPS_CACHE:
        try:
            with os.scandir(directory) as entries:
                sizes = {}
                for entry in entries:
                    if entry.is_dir():
                        continue
                    stem = os.path.splitext(entry.name)[0]
                    sizes[stem] = max(sizes.get(stem, 0), entry.stat().st_size)
                _SIZECLIPS_CACHE[directory] = sizes
        except OSError:
            _SIZECLIPS_CACHE[directory] = {}
    return _SIZECLIPS_CACHE[directory]


def sort_sizeclips(x: FileSystemObject) -> tuple[int, str, int, int, str]:
    stem, _ = os.path.splitext(x.basename)
    match = _CLIP_SUFFIX.search(stem)
    if match:
        primary = stem[: match.start()].rstrip("_")
        clip = True
    else:
        primary = stem
        clip = False
    sizes = _dir_sizes(x.path)
    primary_size = sizes.get(primary, 0)
    size = sizes.get(stem, getattr(x, "size", 0) or 0)
    return (-primary_size, primary.casefold(), int(clip), -size if clip else 0, x.basename.casefold())


Directory.sort_dict["sizeclips"] = sort_sizeclips

# TODO:ALSO:(o,|o.): use rest/tail after _any_ punct symbol
# THINK: how to sort mixed dir with both "a-b" and "b" -- mix or separate
#   t = nm(x).rpartition('-');


def sort_suffix(x: FileSystemObject, s: str, longest: bool = False) -> str:
    nm = x.relative_path
    t = nm.partition(s) if longest else nm.rpartition(s)
    return t[2] if t[1] else ""


Directory.sort_dict["suffix--"] = lambda x: sort_suffix(x, "-", longest=True)
Directory.sort_dict["suffix-"] = lambda x: sort_suffix(x, "-", longest=False)
Directory.sort_dict["suffix__"] = lambda x: sort_suffix(x, "_", longest=True)
Directory.sort_dict["suffix_"] = lambda x: sort_suffix(x, "_", longest=False)

# from subprocess import check_output
# def sort_dir_size(path):
#     cmd = ('du -bs' + path).split()
#     return check_output(cmd).decode('utf-8').rstrip().split()[1]
# Directory.sort_dict['dir_size'] = sort_dir_size
