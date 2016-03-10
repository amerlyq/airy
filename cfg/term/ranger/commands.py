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
    acmd = 'ag --smart-case --group --color --hidden --search-zip'
    qarg = re.compile(r"""^(".*"|'.*')$""")

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
        patt = self._quot(self._arg(iarg))
        cmd = ' '.join([comm, patt] + self._sel())
        cmdl = [ag.editor, '-c', cmd, '-c', 'only']
        return (cmdl, '')

    def _aug_sh(self, iarg, flags=[]):
        patt = self._bare(self._arg(iarg))
        cmdl = ag.acmd.split() + flags + [patt]
        if '-g' not in flags:
            cmdl += self._sel()
        return (cmdl, '-p')

    def _choose(self):
        if self.arg(1) == '-v':
            return self._aug_vim(2, 'Ag')
        elif self.arg(1) == '-g':
            return self._aug_vim(2, 'AgGroup')
        elif self.arg(1) == '-l':
            return self._aug_sh(2, ['--files-with-matches'])
        elif self.arg(1) == '-f':
            return self._aug_sh(2, ['-g'])
        elif self.arg(1) == '-p':
            return self._aug_sh(2, [])
        else:
            return self._aug_sh(1, [])

    def execute(self):
        cmd, flags = self._choose()
        self.fm.execute_command(cmd, flags=flags)
        self.fm.notify(cmd)

    def tab(self):
        return ['{} {}'.format(self.arg(0), p)
                for p in reversed(ag_patterns)]


class doc(Command):
    lst = ['DEV', 'EXAMPLES', 'INFO', 'LIOR', 'NOTE', 'SYNERGY', 'TODO']
    ext = '.otl'
    loci = ['doc', 'docs', '']
    """:doc [<name>]
    Search and open appropriate metafile in one of choosen directories
    """

    def _nearest(self, fvalidate):
        for d in doc.loci:
            path = fs.join(self._dbase, d, self._dname)
            if fvalidate(path):
                return path

    def execute(self):
        self._dname = (self.arg(1) if self.arg(1) else doc.lst[0]) + doc.ext
        self._dbase = self.fm.thisdir.path
        path = self._nearest(fs.isfile)
        # WARNING: opens nested editor if file don't exists!
        # DEV: check if 'file-chooser' regime and touch file before open
        # if not fs.lexists(path):
        #     open(path, 'a').close()
        if path:
            self.fm.select_file(path)
            self.fm.move(right=1)
        else:
            path = self._nearest(lambda x: fs.isdir(fs.dirname(x)))
            self.fm.edit_file(path)

    def tab(self):
        return ['doc ' + nm for nm in doc.lst]


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
                self.fm.cd(f.readline().rstrip())
        except IOError:
            return self.fm.notify(cd_shelldir.lastdir, bad=True)

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


class nrenum(Command):
    bmrk = re.compile(r'(.*)\{(\d+)([^}]+?)(\d+)\}$')

    def execute(self):
        istotal = (self.arg(1)[0:2] == '-t')
        if istotal:
            self.shift()
        chg = int(self.arg(1)) if self.arg(1) else 1

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

        if state.endswith('#') and ready == total:
            state = state[:-1] + '$'
        elif state.endswith('$') and ready < total:
            state = state[:-1] + '#'

        nm = "{:s}{{{:d}{:s}{:d}}}".format(name, total, state, ready)
        return self.fm.execute_console('rename ' + nm)


class actualee(Command):
    FLS = fs.join('/tmp', os.getenv('USER'), 'ranger_list')
    """:actualee
    Use '~/.bin/actually' to apply secondary action to file/list
    """
    def execute(self):
        if self.arg(1) and self.arg(1)[0] == '-':
            flags = self.arg(1)
        else:
            flags = '-e'

        s = [f.path for f in self.fm.thisdir.files]
        index = s.index(self.fm.thisfile.path)
        with open(actualee.FLS, 'w') as f:
            f.write("\n".join(s[index:] + s[:index]))

        if self.fm.thisfile.is_file:
            # if 'x' in file.get_permission_string():
            command = 'cd %d && actualee ' + flags + ' %f -l ' + actualee.FLS
            command = self.fm.substitute_macros(command, escape=True)
            self.fm.execute_command(command)
        else:
            self.fm.move(right=1)

    def tab(self):
        return self._tab_directory_content()


# Load aliases to shell (setopt aliases?). Using ~/.zshenv will crash git commands
# NOTE: shell -r ... works w/o sourcing, as there are no 'sudo source'
#   FIXME: http://askubuntu.com/questions/20953/sudo-source-command-not-found
class shell(Command):
    escape_macros_for_shell = True

    def execute(self):
        if self.arg(1) and self.arg(1)[0] == '-':
            flags = self.arg(1)[1:]
            command = self.rest(2)
        else:
            flags = ''
            command = self.rest(1)

        if not command and 'p' in flags:
            command = 'cat %f'
        if command:
            if '%' in command:
                command = self.fm.substitute_macros(command, escape=True)

            if 'r' not in flags:
                command = "source ~/.shell/aliases && eval " + shell_quote(command)

            self.fm.execute_command(command, flags=flags)

    def tab(self):
        from ranger.ext.get_executables import get_executables
        if self.arg(1) and self.arg(1)[0] == '-':
            command = self.rest(2)
        else:
            command = self.rest(1)
        start = self.line[0:len(self.line) - len(command)]

        try:
            position_of_last_space = command.rindex(" ")
        except ValueError:
            return (start + program + ' ' for program in get_executables()
                    if program.startswith(command))
        if position_of_last_space == len(command) - 1:
            selection = self.fm.thistab.get_selection()
            if len(selection) == 1:
                return self.line + selection[0].shell_escaped_basename + ' '
            else:
                return self.line + '%s '
        else:
            before_word, start_of_word = self.line.rsplit(' ', 1)
            return (before_word + ' ' + file.shell_escaped_basename
                    for file in self.fm.thisdir.files
                    if file.shell_escaped_basename.startswith(start_of_word))


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
        if not command:
            self.fm.ui.console.history_move(-self.quantifier)


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
