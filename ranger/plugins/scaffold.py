# SRC: https://codeberg.org/yuni/dotfiles/src/branch/master/config/ranger/plugins/scaffold.py
"""
With this plugin, you can mark certain directories as "scaffold", to denote
that they are a fixed part of your directory structure. The effect is that they
will be sorted first, and can be highlighted by a color scheme, using the key
'scaffold'.

New key bindings:

"++" marks a directory as a scaffold directory
"--" unmarks it again

"+2" marks a directory as a 2nd level scaffold directory
"""

# Load list of scaffold files from database
import os.path

import ranger.gui.context
import ranger.gui.widgets.browsercolumn
from ranger.api.commands import Command
from ranger.container.directory import Directory

TARGET_PATH = os.path.expanduser("~/.local/share/ranger/scaffolds")
TARGET_PATH2 = os.path.expanduser("~/.local/share/ranger/scaffolds2")


def set_scaffold_paths():
    if not os.path.exists(TARGET_PATH):
        open(TARGET_PATH, "w").close()
    if not os.path.exists(TARGET_PATH2):
        open(TARGET_PATH2, "w").close()
    ranger.scaffold_paths = [
        line.rstrip("\n") for line in open(TARGET_PATH).readlines()
    ]
    ranger.scaffold_paths2 = [
        line.rstrip("\n") for line in open(TARGET_PATH2).readlines()
    ]


set_scaffold_paths()

# Change sorting method so that scaffold files are displayed on top
old_sort_method = Directory.sort_dict["natural"]


def sort_method(path):
    try:
        key = old_sort_method(path)
        if path.path in ranger.scaffold_paths:
            key.insert(0, ("", 0))
            key.insert(1, ("", 0))
        elif path.path in ranger.scaffold_paths2:
            key.insert(0, ("", 0))
            key.insert(1, ("", 1))
        return key
    except:
        return 0


Directory.sort_dict["natural"] = sort_method

# Extend colorscheme
ranger.gui.context.CONTEXT_KEYS.append("scaffold")
ranger.gui.context.CONTEXT_KEYS.append("scaffold2")
ranger.gui.context.Context.scaffold = False


# Add commands to add/remove scaffold files
class scaffold_add(Command):
    def execute(self):
        if self.arg(1) == "2":
            path = TARGET_PATH2
        else:
            path = TARGET_PATH

        f = open(path, "r")
        files = f.read().rstrip("\n").split("\n")
        f.close()

        f = None

        for file in self.fm.thistab.get_selection():
            if file.path not in files:
                if not f:
                    f = open(path, "a")
                f.write(file.path)
                f.write("\n")

        if f is not None:
            f.close()

        set_scaffold_paths()


class scaffold_remove(Command):
    def execute(self):
        for path in (TARGET_PATH, TARGET_PATH2):
            f = open(path, "r")
            files = f.read().rstrip("\n").split("\n")
            f.close()

            new_files = list(files)
            for file in self.fm.thistab.get_selection():
                while file.path in new_files:
                    new_files.remove(file.path)

            if len(new_files) != len(files):
                f = open(path, "w")
                f.write("\n".join(new_files) + "\n")
                f.close()
        set_scaffold_paths()


# Bind those commands to keys
old_hook_init = ranger.api.hook_init


def hook_init(fm):
    if old_hook_init:
        old_hook_init(fm)
    fm.execute_console("map ++ chain scaffold_add; reset")
    fm.execute_console("map +2 chain scaffold_add 2; reset")
    fm.execute_console("map -- chain scaffold_remove; reset")


ranger.api.hook_init = hook_init

# Bind a hook that injects the "scaffold" color key
hook_before_drawing = ranger.gui.widgets.browsercolumn.hook_before_drawing


def hook_before_drawing__scaffold(drawn, this_color):
    if drawn.path in ranger.scaffold_paths:
        this_color.append("scaffold")
    if drawn.path in ranger.scaffold_paths2:
        this_color.append("scaffold2")
    return hook_before_drawing(drawn, this_color)


ranger.gui.widgets.browsercolumn.hook_before_drawing = hook_before_drawing__scaffold
