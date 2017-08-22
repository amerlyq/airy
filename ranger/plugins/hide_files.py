### Hide directories (unless show_hidden) ###

import os
import ranger.container.directory
old_accept_file = ranger.container.directory.accept_file

HIDE_FILES = [os.path.abspath(path) for path in (
    "/boot", "/cdrom", "/root",
    # "/srv", "/mnt", "~/SIM-GBS-ROOT", "~/tizen_secos"
)]


# Define a new one
def custom_accept_file(file, filters):
    if not file.fm.settings.show_hidden and file.path in HIDE_FILES:
        return False
    else:
        return old_accept_file(file, filters)


# Overwrite the old function
import ranger.container.directory
ranger.container.directory.accept_file = custom_accept_file
