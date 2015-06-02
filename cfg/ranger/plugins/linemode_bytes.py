# Activate by ":linemode rot13" in ranger. Restore by 'Mf'.

import sys
import ranger.api
from ranger.core.linemode import LinemodeBase


@ranger.api.register_linemode
class BytesizeLinemode(LinemodeBase):
    name = "bytesize"

    def filetitle(self, file, metadata):
        """The left-aligned part of the line."""
        return file.relative_path

    def infostring(self, file, metadata):
        """The right-aligned part of the line."""
        if not file.is_directory:
            from subprocess import check_output
            # OR: du -b <file>
            fileinfo = check_output(['stat', '-c', '%s', file.path]).strip()
            if sys.version_info[0] >= 3:
                fileinfo = fileinfo.decode("utf-8")
            return fileinfo
        else:
            raise NotImplementedError
