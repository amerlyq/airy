import ranger.api
from ranger.core.linemode import LinemodeBase


@ranger.api.register_linemode
class XAttrLinemode(LinemodeBase):
    """list file attributes on a Linux second extended file system"""
    name = "xattr"

    def xattr_get(self, f):
        # XXX: lsattr != os.listxattr  (BAD: empty list)
        from subprocess import check_output, CalledProcessError
        try:
            xattr = check_output(['lsattr', '-d', f]).strip().split()[0]
        except (CalledProcessError, IndexError):
            raise NotImplementedError
        if not isinstance(xattr, str):
            xattr = xattr.decode("utf-8")
        return xattr

    def filetitle(self, f, metadata):
        return f.relative_path

    def infostring(self, f, metadata):
        return self.xattr_get(f.path)
