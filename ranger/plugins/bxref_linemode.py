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


# SEE:
@ranger.api.register_linemode
class BTimeXrefLinemode(LinemodeBase):
    name = 'bxref'

    def to_z85(self, ts):
        from subprocess import run, CalledProcessError
        try:
            bts = int(ts).to_bytes(4, byteorder='big')
            z85ts = run(['basenc', '--z85'], input=bts, check=True, capture_output=True)
            z85ts = z85ts.stdout.strip().decode('utf-8')[::-1]
        except (CalledProcessError, IndexError):
            raise NotImplementedError
        return z85ts

    def filetitle(self, f, metadata):
        return f.relative_path

    def infostring(self, f, metadata):
        # BUG: .st_birthtime is still not available on Linux for Python libs
        #   FROM: https://www.manongdao.com/q-2465.html
        # FAIL: on ext4 birth ~=~ change time, and "modify" is much older
        # return '⌇' + self.to_z85(f.stat.st_birthtime)
        return '⌇' + self.to_z85(f.stat.st_mtime)
