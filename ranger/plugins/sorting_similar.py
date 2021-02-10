# This plugin adds the sorting algorithm called 'random'.  To enable it, type
# ":set sort=random" or create a key binding with ":map oz set sort=random"

from os import path as fs

from ranger.container.directory import Directory

Directory.sort_dict["from_end"] = lambda x: x.relative_path[::-1]
Directory.sort_dict["name_len"] = lambda x: (len(x.relative_path), x.relative_path)

# TODO:ALSO:(o,|o.): use rest/tail after _any_ punct symbol
# THINK: how to sort mixed dir with both "a-b" and "b" -- mix or separate
#   t = nm(x).rpartition('-');


def sort_suffix(x, s, longest=False):
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
