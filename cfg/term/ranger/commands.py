from ranger.api.commands import Command
from ranger.ext.shell_escape import shell_quote

import re
import os
from os import path as fs

ag_patterns = []


class ag(Command):
    """:ag 'regex'

    Looks for a string in all marked paths or current dir
    """
    editor = os.getenv('EDITOR') or 'vim'
    acmd = 'ag --smart-case --group --color --hidden'  # --search-zip
    qarg = re.compile(r"""^(".*"|'.*')$""")
    # THINK:USE: set_clipboard on each direct ':ag' search? So I could find in vim easily

    def _sel(self):
        d = self.fm.thisdir
        if d.marked_items:
            return [f.relative_path for f in d.marked_items]
        if d.files_all and (len(d.files_all) != len(d.files)):
            return [f.relative_path for f in d.files]
        return []

    def _arg(self, i=1):
        if self.rest(i):
            ag_patterns.append(self.rest(i))
        return ag_patterns[-1] if ag_patterns else ''

    def _quot(self, patt):
        return patt if ag.qarg.match(patt) else shell_quote(patt)

    def _bare(self, patt):
        return patt[1:-1] if ag.qarg.match(patt) else patt

    def _aug_vim(self, iarg, comm='Ag'):
        if self.arg(iarg) == '-Q':
            self.shift()
            comm = 'sil AgSet def.e.literal 1|' + comm
        # patt = self._quot(self._arg(iarg))
        patt = self._arg(iarg)  # No need to quote in new ag.vim
        # FIXME:(add support)  'AgPaths' + self._sel()
        cmd = ' '.join([comm, patt])
        cmdl = [ag.editor, '-c', cmd, '-c', 'only']
        return (cmdl, '')

    def _aug_sh(self, iarg, flags=[]):
        if self.arg(iarg) == '-Q':
            self.shift()
            flags = ['--literal'] + flags
        patt = self._bare(self._arg(iarg))
        cmdl = ag.acmd.split() + flags + [patt]
        if '-g' not in flags:
            cmdl += self._sel()
        return (cmdl, '-p')

    def _choose(self):
        if self.arg(1) == '-v':
            return self._aug_vim(2, 'Ag')
        elif self.arg(1) == '-g':
            return self._aug_vim(2, 'sil AgView grp|Ag')
        elif self.arg(1) == '-l':
            return self._aug_sh(2, ['--files-with-matches', '--count'])
        elif self.arg(1) == '-p':  # paths
            return self._aug_sh(2, ['-g'])
        elif self.arg(1) == '-f':
            return self._aug_sh(2, [])
        elif self.arg(1) == '-r':
            return self._aug_sh(2, ['--files-with-matches'])
        else:
            return self._aug_sh(1, [])

    def _catch(self, cmd):
        from subprocess import check_output, CalledProcessError
        try:
            out = check_output(cmd)
        except CalledProcessError:
            return None
        else:
            return out[:-1].decode('utf-8').splitlines()

    # DEV
    # NOTE: regex becomes very big for big dirs
    # BAD: flat ignores 'filter' for nested dirs
    def _filter(self, lst, thisdir):
        # filter /^rel_dir/ on lst
        # get leftmost path elements
        # make regex '^' + '|'.join(re.escape(nm)) + '$'
        thisdir.temporary_filter = re.compile(file_with_matches)
        thisdir.refilter()

        for f in thisdir.files_all:
            if f.is_directory:
                # DEV: each time filter-out one level of files from lst
                self._filter(lst, f)

    def execute(self):
        cmd, flags = self._choose()
        # self.fm.notify(cmd)
        # TODO:ENH: cmd may be [..] -- no need to shell_escape
        if self.arg(1) != '-r':
            self.fm.execute_command(cmd, flags=flags)
        else:
            self._filter(self._catch(cmd))

    def tab(self):
        return ['{} {}'.format(self.arg(0), p)
                for p in reversed(ag_patterns)]


class doc(Command):
    lst = {'d': 'DEV', 'e': 'EXAMPLES', 'i': 'INFO', 'h': 'HACK',
           'g': 'LEGEND', 'l': 'LIOR', 'n': 'NOTE',
           's': 'SYNERGY', 't': 'TODO'}
    ext = ['.nou', '.otl', '.txt', '']
    loci = ['doc', 'docs', '']
    """:doc [<name>]
    Search and open appropriate metafile in one of choosen directories
    """

    # TODO: find existing file with any extension.
    # NEED: priority if exists multiple files with same extension
    # -- Though ext=.nou is preferred and default when creating new file.
    def _nearest(self, pwd, nm, fvalidate):
        for d in doc.loci:
            for e in doc.ext:
                path = fs.join(pwd, d, nm + e)
                if fvalidate(path):
                    return path

    def execute(self):
        nm = self.arg(1) if self.arg(1) else doc.lst['t']
        pwd = self.fm.thisdir.path
        path = self._nearest(pwd, nm, fs.isfile)
        # WARNING: opens nested editor if file don't exists!
        # DEV: check if 'file-chooser' regime and touch file before open
        # if not fs.lexists(path):
        #     open(path, 'a').close()
        if path:
            self.fm.select_file(path)
            self.fm.move(right=1)
        else:
            path = self._nearest(pwd, nm, lambda x: fs.isdir(fs.dirname(x)))
            self.fm.edit_file(path)

    def tab(self):
        return ['doc ' + nm for nm in doc.lst.values()]


# Need this in the end of ~/.bashrc or ~/.zshrc
#   function finish { tempfile='/tmp/aura/ranger_cwdir'; echo "$PWD" > "$tempfile"; }
# `trap finish EXIT
class cd_shelldir(Command):
    lastdir = fs.join(os.getenv('TMPDIR') or '/tmp', 'ranger_cwdir')
    """:cd_shelldir
    Goes to path from /tmp/<username>/ranger_cwdir
    """
    def execute(self):
        try:
            fname = self.fm.confpath(cd_shelldir.lastdir)
            with open(fname, 'r') as f:
                path = f.readline().rstrip()
        except IOError:
            return self.fm.notify(cd_shelldir.lastdir, bad=True)

        # FIXED: expanded pwd symlink teleporting
        if path != fs.realpath(self.fm.thisdir.path):
            self.fm.cd(path)

    def tab(self):
        return self._tab_directory_content()  # Generic function


# Auto cd
class cda(Command):
    def execute(self):
        if self.arg(1) and self.arg(1)[0] == '-':
            # flags = self.arg(1)[1:]
            path = self.rest(2)
        else:
            # flags = ''
            path = self.rest(1)

        if path[0:1] == '~':
            path = fs.expanduser(path)
        if not fs.exists(path):
            return self.fm.notify("No such: " + path, bad=True)

        if fs.isdir(path):
            self.fm.cd(path)
        elif fs.isfile(path):
            self.fm.select_file(path)


class df(Command):
    def execute(self):
        fls = None
        flags = ""
        if self.arg(1) and self.arg(1)[0] == '-':
            flags = self.arg(1)
            self.shift()
        cmd = self.rest(1).split()

        cidx = list(self.fm.tabs).index(self.fm.current_tab)
        # Cross-tab compare specified tab
        if self.quantifier is not None:
            tidx = self.quantifier
        else:
            tidx = (cidx + 1) % len(self.fm.tabs)
        ctab = self.fm
        ttab = list(self.fm.tabs.values())[tidx]
        csel = len(ctab.thisdir.marked_items)
        tsel = len(ttab.thisdir.marked_items)

        # DEV: df cidx!=tidx: search file with same name in tidx
        #   -- if no such file == show error
        #   BUT: then can't compare different names in tabs fast
        #       -- 'cause need to 'vsel' them before compare
        if cidx == tidx and csel == 0:
            self.fm.notify("curr_tab: select targets to compare", bad=True)
        elif cidx != tidx and csel == 0 and tsel == 0:
            fls = [ctab.thisfile, ttab.thisfile]
        elif cidx == tidx or tsel == 0:
            if csel == 1:
                # Gliding diff in curr_tab
                fls = [ctab.thisdir.marked_items[0], ctab.thisfile]
            elif csel == 2:
                fls = ctab.thisdir.marked_items
            else:
                self.fm.notify("curr_tab: select only one or two files", bad=True)
        elif cidx != tidx:
            if csel == 0 and tsel == 1:
                fls = [ctab.thisfile, ttab.thisdir.marked_items[0]]
            elif csel == 0 and tsel > 1:
                self.fm.notify("next_tab: select only one or zero files", bad=True)
            elif csel == 1 and tsel == 1:
                fls = [t.thisdir.marked_items[0] for t in [ctab, ttab]]
            else:
                self.fm.notify("TBD: uncompatible selection", bad=True)

        if not fls:
            return 1
        elif fls[0] == fls[1]:
            self.fm.notify("Err: refuse to compare the same file", bad=True)
            return 2
        else:
            # DEV: substitute python-like placeholders -> {}, {1}, {2}
            #   else -> append filelist
            cmd += [f.path for f in fls]
            self.fm.execute_command(cmd, flags=flags)


class nrenum(Command):
    bmrk = re.compile(r'(.*)\{(\d+)([^}]+?)(\d+)\}$')

    def execute(self):
        istotal = (self.arg(1)[0:2] == '-t')
        if istotal:
            self.shift()
        chg = int(self.arg(1)) if self.arg(1) else 1
        if self.quantifier is not None:
            chg *= self.quantifier

        m = nrenum.bmrk.match(self.fm.thisfile.relative_path)
        if not m:
            return

        name, state = m.group(1), m.group(3)
        total, ready = int(m.group(2)), int(m.group(4))

        if ready == total:
            if state.startswith('@'):
                ready += chg if not istotal else 0
                total += chg if chg > 0 else 0
        elif ready > total:
            if state.startswith('@'):
                total = ready if chg > 0 else total
        elif ready < total:
            if istotal:
                total += chg
            else:
                ready += chg

        if ready < 0:
            ready = 0
        if total < 0:
            total = 0

        if state.endswith('#') and ready == total:
            state = state[:-1] + '$'
        elif state.endswith('$') and ready < total:
            state = state[:-1] + '#'

        nm = "{:s}{{{:d}{:s}{:d}}}".format(name, total, state, ready)
        return self.fm.execute_console('rename ' + nm)


class actualee(Command):
    FLST = fs.join('/tmp', os.getenv('USER'), 'ranger_list')
    """:actualee
    Use '~/.bin/actually' to apply secondary action to file/list
    """
    def execute(self):
        cmd = ['actualee']

        if self.arg(1) and self.arg(1)[0] == '-':
            cmd += [self.arg(1)]
            self.shift()
        else:
            cmd += ['-e']

        s = [f.path for f in self.fm.thisdir.files]
        index = s.index(self.fm.thisfile.path)
        with open(actualee.FLST, 'w') as f:
            f.write("\n".join(s[index:] + s[:index]))
            cmd += ['-l']

        if self.fm.thisfile.is_file:
            cmd += [self.fm.thisfile.path]
            cmd += [actualee.FLST]
            # if 'x' in file.get_permission_string():
            self.fm.execute_command(cmd)
        else:
            self.fm.move(right=1)

    def tab(self):
        return self._tab_directory_content()


class console(Command):
    """:console <command>

    Open the console with the given command.
    """
    def execute(self):
        pos = None
        if self.arg(1)[0:2] == '-p':
            try:
                pos = int(self.arg(1)[2:])
                self.shift()
            except:
                pass

        command = self.rest(1)
        if pos is None or int(pos) > len(command):
            command += " "
        self.fm.open_console(command, position=pos)
        if not command and self.quantifier is not None:
            self.fm.ui.console.history_move(-self.quantifier)


class flat_inode(Command):
    """:flat_inode [-t] [<[fdl]>] [<level>]

    Set/Toggle inode flattened view
        <quantifier> augments missing argument: level or [fdl] bitmask
    """
    def q_inode_mask(self, q):
        return '' if q is None else ('f' if q & 0x1 else '') + \
            ('d' if q & 0x2 else '') + ('l' if q & 0x4 else '')

    def q_flat(self, q):
        return -1 if self.quantifier is None else self.quantifier

    def execute(self):
        toggle = self.arg(1) == '-t'
        if toggle:
            self.shift()

        if re.match('^-?\d+$', self.arg(1)):
            t = self.arg(2) or self.q_inode_mask(self.quantifier)
            q = self.arg(1)
        else:
            t = self.arg(1)
            q = self.arg(2) or self.q_flat(self.quantifier)

        if toggle and q == self.fm.thisdir.flat \
           and self.fm.thisdir.inode_type_filter:
            t, q = '', 0

        self.fm.notify(self.fm.thisdir.inode_type_filter)
        cmd = 'chain filter_inode_type ' + t + '; flat ' + str(q)
        self.fm.execute_console(cmd)

    def tab(self):
        return ['flat_inode ' + t for t in 'dfl']


class edit(Command):
    """:edit <filename>

    Opens the specified file in vim
    """

    def execute(self):
        if not self.arg(1):
            self.fm.edit_file(self.fm.thisfile.path)
        elif '.' == self.rest(1):
            self.fm.edit_file('')
        else:
            self.fm.edit_file(self.rest(1))

    def tab(self):
        return self._tab_directory_content()


class unfilter(Command):
    def unfilter(self, d):
        # BAD: d.files_all == None ???
        # [self.unfilter(f) for f in d.files_all if f.is_directory]
        d.filter = None
        d.refilter()
        # for f in d.files_all:
        #     if f.is_directory:
        #         self.unfilter(f)

    def execute(self):
        self.unfilter(self.fm.thisdir)


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
