from ranger.api.commands import Command
from ranger.ext.shell_escape import shell_quote


# Need this in the end of ~/.bashrc or ~/.zshrc
#   function finish { tempfile='/tmp/aura/ranger_cwdir'; echo "$PWD" > "$tempfile"; }
# `trap finish EXIT
class cd_shelldir(Command):
    """:cd_shelldir
    Goes to path from /tmp/aura/ranger_cwdir
    """
    def execute(self):
        shelldir = '/tmp/aura/ranger_cwdir'
        try:
            fname = self.fm.confpath(shelldir)
            with open(fname, 'r') as f:
                self.fm.cd(f.readline().rstrip())
        except IOError:
            return self.fm.notify(shelldir, bad=True)

    def tab(self):
        return self._tab_directory_content()  # Generic function


class actualee(Command):
    FL = '/tmp/aura/ranger_list'
    """:actualee
    Use '~/.bin/actually' to apply secondary action to file/list
    """
    def execute(self):
        s = [f.path for f in self.fm.thisdir.files]
        index = s.index(self.fm.thisfile.path)
        with open(actualee.FL, 'w') as f:
            f.write("\n".join(s[index:] + s[:index]))

        if self.fm.thisfile.is_file:
            # if 'x' in file.get_permission_string():
            command = 'cd %d && actualee %f -l ' + actualee.FL
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
            return (start + program + ' ' for program \
                    in get_executables() if program.startswith(command))
        if position_of_last_space == len(command) - 1:
            selection = self.fm.thistab.get_selection()
            if len(selection) == 1:
                return self.line + selection[0].shell_escaped_basename + ' '
            else:
                return self.line + '%s '
        else:
            before_word, start_of_word = self.line.rsplit(' ', 1)
            return (before_word + ' ' + file.shell_escaped_basename \
                    for file in self.fm.thisdir.files \
                    if file.shell_escaped_basename.startswith(start_of_word))


class console(Command):
    """:console <command>

    Open the console with the given command.
    """
    def execute(self):
        position = None
        if self.arg(1)[0:2] == '-p':
            try:
                position = int(self.arg(1)[2:])
                self.shift()
            except:
                pass

        command = self.rest(1) + " " if position != 0 else ""
        self.fm.open_console(command, position=position)
        if not command:
            self.fm.ui.console.history_move(-self.quantifier)
