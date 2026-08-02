import ranger.api
from ranger.container.fsobject import FileSystemObject
from ranger.core.linemode import LinemodeBase


@ranger.api.register_linemode
class XAttrLinemode(LinemodeBase):
    """list file attributes on a Linux second extended file system"""
    name = "xattr"

    def xattr_get(self, f: str) -> str:
        # XXX: lsattr != os.listxattr  (BAD: empty list)
        from subprocess import CalledProcessError, check_output
        try:
            xattr = check_output(['lsattr', '-d', f]).strip().split()[0]
        except (CalledProcessError, IndexError):
            raise NotImplementedError
        if not isinstance(xattr, str):
            xattr = xattr.decode("utf-8")
        return xattr

    def filetitle(self, f: FileSystemObject, metadata: object) -> str:
        return f.relative_path

    def infostring(self, f: FileSystemObject, metadata: object) -> str:
        return self.xattr_get(f.path)
