# USAGE: :linemode <name>

import os
import re
from time import strftime, localtime

import ranger.api
from ranger.core.linemode import LinemodeBase


@ranger.api.register_linemode
class BytesizeLinemode(LinemodeBase):
    name = "bytesize"

    def filetitle(self, f, metadata):
        return f.relative_path

    def infostring(self, f, metadata):
        if not f.is_directory:
            return str(f.stat.st_size)
        else:
            raise NotImplementedError


@ranger.api.register_linemode
class LinksLinemode(LinemodeBase):
    name = "links"

    def filetitle(self, f, metadata):
        if not f.is_link:
            return f.relative_path
        try:
            dst = os.readlink(f.path)
        except:
            dst = '?'
        dst = re.sub('^' + re.escape(os.getenv('HOME')), '~', dst)
        return '{} → {}'.format(f.relative_path, dst)


@ranger.api.register_linemode
class ATimeLinemode(LinemodeBase):
    name = 'atime'

    def filetitle(self, f, metadata):
        return f.relative_path

    def infostring(self, f, metadata):
        return strftime('%Y-%m-%d %H:%M:%S', localtime(f.stat.st_atime))


@ranger.api.register_linemode
class CTimeLinemode(LinemodeBase):
    name = 'ctime'

    def filetitle(self, f, metadata):
        return f.relative_path

    def infostring(self, f, metadata):
        return strftime('%Y-%m-%d %H:%M:%S', localtime(f.stat.st_ctime))


@ranger.api.register_linemode
class MTimeLinemode(LinemodeBase):
    name = 'mtime'

    def filetitle(self, f, metadata):
        return f.relative_path

    def infostring(self, f, metadata):
        return strftime('%Y-%m-%d %H:%M:%S', localtime(f.stat.st_mtime))


@ranger.api.register_linemode
class XPermLinemode(LinemodeBase):
    name = "xperm"

    def filetitle(self, f, metadata):
        return f.relative_path

    def infostring(self, f, metadata):
        return f.get_permission_string()
