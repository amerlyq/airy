import ranger.api
from ranger.api.commands import Command
import sys

old_hook_init = ranger.api.hook_init


# BAD: on btrfs partition linemode refreshed only after cursor moves
class xattr(Command):
    """:xattr [-+=!][aAcCdDeijsStTu] <file>

    Change file attributes on a Linux file system
    """

    def xattr_set(self, mode, f):
        if not isinstance(f, list):
            f = [f]
        # XXX: chattr != os.setxattr
        self.fm.execute_command(['chattr', mode] + f)

    def xattr_toggle(self, value, files):
        from ranger.container.fsobject import FileSystemObject
        xattr_get = FileSystemObject.linemode_dict['xattr'].xattr_get
        for f in (files if isinstance(files, list) else [files]):
            try:
                cv = xattr_get(f)
            except NotImplementedError as e:
                return self.fm.notify(e, bad=True)
            for c in value:
                t = '-' if c in cv else '+'
                self.xattr_set(t + c, f)

    def execute(self):
        if not self.arg(1) or not self.arg(1)[1:]:
            return self.fm.notify("Need xattr value: '+-=[...]'", bad=True)

        mod = self.arg(1)[0]
        value = self.arg(1)[1:]
        import shlex
        files = shlex.split(self.rest(2))

        for c in value:
            if c not in 'aAcCdDeijsStTu':
                return self.fm.notify("Wrong xattr value", bad=True)

        if files:
            files = [self.fm.substitute_macros(f, escape=False) for f in files]
        else:
            cdir = self.fm.thisdir
            if cdir.marked_items:
                files = [f.relative_path for f in cdir.marked_items]
            else:
                files = [cdir.thisfile]

        if mod in '+-=':
            self.xattr_set(mod + value, files)
        elif mod == '!':
            self.xattr_toggle(value, files)
        else:
            return self.fm.notify("Wrong xattr modifier", bad=True)


def hook_init(fm):
    old_hook_init(fm)
    fm.commands.load_commands_from_module(sys.modules[__name__])

ranger.api.hook_init = hook_init
