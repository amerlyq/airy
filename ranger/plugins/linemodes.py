# USAGE: :linemode <name>

import os
import re
from time import localtime, strftime

import ranger.api
from ranger.container.fsobject import FileSystemObject
from ranger.core.linemode import LinemodeBase

# IDEA: line-count with cached !wc -l results


@ranger.api.register_linemode
class BytesizeLinemode(LinemodeBase):
    name = "bytesize"

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        return f.relative_path

    def infostring(self, f: FileSystemObject, metadata: object) -> str:
        if not f.is_directory:
            return str(f.stat.st_size)
        else:
            raise NotImplementedError


@ranger.api.register_linemode
class HexsizeLinemode(LinemodeBase):
    name = "hexsize"

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        return f.relative_path

    def infostring(self, f: FileSystemObject, metadata: object) -> str:
        if not f.is_directory:
            return "%06x" % f.stat.st_size
        else:
            raise NotImplementedError


@ranger.api.register_linemode
class LinksLinemode(LinemodeBase):
    name = "links"

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        if not f.is_link:
            return f.relative_path
        try:
            dst = os.readlink(f.path)
        except:
            dst = "?"
        dst = re.sub("^" + re.escape(os.getenv("HOME")), "~", dst)
        return f"{f.relative_path} → {dst}"


@ranger.api.register_linemode
class ATimeLinemode(LinemodeBase):
    name = "atime"

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        return f.relative_path

    def infostring(self, f: FileSystemObject, metadata: object) -> str:
        return strftime("%Y-%m-%d %H:%M:%S", localtime(f.stat.st_atime))


@ranger.api.register_linemode
class CTimeLinemode(LinemodeBase):
    name = "ctime"

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        return f.relative_path

    def infostring(self, f: FileSystemObject, metadata: object) -> str:
        return strftime("%Y-%m-%d %H:%M:%S", localtime(f.stat.st_ctime))


@ranger.api.register_linemode
class MTimeLinemode(LinemodeBase):
    name = "mtime"

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        return f.relative_path

    def infostring(self, f: FileSystemObject, metadata: object) -> str:
        return strftime("%Y-%m-%d %H:%M:%S", localtime(f.stat.st_mtime))


@ranger.api.register_linemode
class XPermLinemode(LinemodeBase):
    name = "xperm"

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        return f.relative_path

    def infostring(self, f: FileSystemObject, metadata: object) -> str:
        return f.get_permission_string()
