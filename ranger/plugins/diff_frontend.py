from ranger.api.commands import Command

## USAGE:
# # MAYBE:(impossible?)
# # ALT: arg to ':map' to specify right column text
# # ALT: embed comment into command, likewise 'map key cmd  # desc'
# # ALT:TRY: filter-out '\s*#\s.*$' from ':df' arguments to simulate comments
# map dfb df -w binwalk -WiU
# map dfc df -w cmp -l
# map dfd df -w diff -rU0
# map dfD df -w diff -rwEZB
# map dfe df -w delta
# map dfg df -w git diff --no-index --
# map dfG df -w git diff --no-index --stat --
# map dfh df dhex
# map dfr df -w r.diff-fs
# map dfR df -w r.diff-fs -d
# map dfs df -w rsync -av --out-format=%%i|%%f --delete --dry-run --
# map dft df -w difft
# map dfz df -w r.diff-fs -s
# map dfZ df -w r.diff-fs -S
# map dfu df -w diff -rU5
# map dfv df nvim -d
# # BUG:FIXME: ':df' splits any command by space, ignoring quoting
# map dfV df nvim -c 'exe"DirDiff\x20".join(argv())' --


class df(Command):
    def execute(self) -> int | None:  # pyright: ignore[reportIncompatibleMethodOverride]
        fls = None
        flags = ""
        if self.arg(1) and self.arg(1)[0] == "-":
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
        # DEV: df multiselection to multiselection
        #   => treat like dirs %d %D compare with only selected files
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
            cmd += [f.path + ("/" if f.is_directory else "") for f in fls]
            print(cmd)
            # cmd += [" && printf '\033[31;40;1same\033[m '"]
            self.fm.execute_command(cmd, flags=flags)
