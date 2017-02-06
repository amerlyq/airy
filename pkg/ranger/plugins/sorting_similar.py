# This plugin adds the sorting algorithm called 'random'.  To enable it, type
# ":set sort=random" or create a key binding with ":map oz set sort=random"


from ranger.container.directory import Directory

from random import random
def sort_from_end(path):
    return random()
Directory.sort_dict['from_end'] = sort_from_end

# from subprocess import check_output
# def sort_dir_size(path):
#     cmd = ('du -bs' + path).split()
#     return check_output(cmd).decode('utf-8').rstrip().split()[1]
# Directory.sort_dict['dir_size'] = sort_dir_size
