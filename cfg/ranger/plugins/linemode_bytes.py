# Activate by ":linemode rot13" in ranger. Restore by 'Mf'.

import sys
import ranger.api
from ranger.core.linemode import LinemodeBase


@ranger.api.register_linemode
class BytesizeLinemode(LinemodeBase):
    name = "bytesize"
    # uses_metadata = True
    # required_metadata = ["title"]

    def filetitle(self, fl, metadata):
        """The left-aligned part of the line."""
        return fl.relative_path

    def infostring(self, fl, metadata):
        """The right-aligned part of the line."""
        if not fl.is_directory:
            from subprocess import check_output
            # OR: du -b <fl>
            fileinfo = check_output(['stat', '-c', '%s', fl.path]).strip()
            if sys.version_info[0] >= 3:
                fileinfo = fileinfo.decode("utf-8")
            return fileinfo
        else:
            raise NotImplementedError
