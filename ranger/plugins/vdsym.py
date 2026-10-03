"""VD symlink search and replacement command."""

from __future__ import annotations

import os
import re
from collections.abc import Sequence
from fnmatch import fnmatch
from os import path as fs

from ranger.api.commands import Command
from ranger.config.commands import delete as _default_delete
from ranger.ext.shell_escape import shell_quote


class vdsym(Command):
    """:vdsym [-a] [-b] [-c] [-d] [-g] [-i] [-j] [-l] [-n] [-p] [-v] [-y]

    Search VD files and their symlink dashboards.
    """

    data_roots = ("/media/pro/vd", "/cache/vd", "/media/hpx/vd_ssdt5")
    view_root = "/d/irome/view"
    _path_cache: dict[str, tuple[dict[str, int], list[str], dict[str, list[str]]]] = {}
    _dir_cache: dict[str, dict[str, tuple[int, list[str], list[str]]]] = {}
    _pics_cache_key: object = None
    _pics_cache: list[str] = []

    def _args(self) -> tuple[set[str], list[str]]:
        import shlex

        long_flags = {
            "autojump1": "a",
            "basename": "b",
            "clipboard": "c",
            "dashboard": "d",
            "glob": "g",
            "ignore-case": "i",
            "jump": "j",
            "links-only": "l",
            "multiple": "m",
            "numeric": "n",
            "open": "o",
            "print": "p",
            "replace": "R",
            "refresh": "q",
            "rescan": "Q",
            "selection": "s",
            "view": "v",
            "xclip": "x",
            "yanked": "y",
        }
        groups = {
            "action": {
                "dashboard": "d",
                "jump": "j",
                "autojump1": "a",
                "open": "o",
                "print": "p",
                "replace": "R",
                "rotate": "r",
                "xclip": "x",
                "refresh": "q",
                "rescan": "Q",
            },
            "source": {
                "basename": "b",
                "clipboard": "c",
                "selection": "s",
                "yanked": "y",
            },
            "target": {"clipboard": "c", "yanked": "y", "selection": "s"},
            "modifiers": {
                "glob": "g",
                "numeric": "n",
                "ignore-case": "i",
                "links-only": "l",
                "view": "v",
            },
        }
        tokens = shlex.split(self.rest(1))
        filtered: list[str] = []
        skip = False
        for index, token in enumerate(tokens):
            if skip:
                skip = False
                continue
            if token.startswith("--dashboard="):
                filtered.append(token)
                continue
            if token in ("-d", "--dashboard") and index + 1 < len(tokens):
                if not tokens[index + 1].startswith("-"):
                    skip = True
            filtered.append(token)
        tokens = filtered
        flags: set[str] = set()
        names: list[str] = []
        separator = False
        for token in tokens:
            if not separator and token == "--":
                separator = True
            elif not separator and token.startswith("--"):
                option = token[2:].split("=", 1)[0]
                value = token.split("=", 1)[1] if "=" in token else None
                if option in groups and value is not None:
                    for item in value.split(","):
                        flags.add(groups[option][item])
                else:
                    flags.add(long_flags[option])
            elif not separator and token.startswith("-"):
                flags.update(token[1:])
            else:
                names.append(token)
                separator = True
        return flags, names

    def _name(self) -> str:
        names = self._names()
        return names[0] if names else ""

    def _names(self) -> list[str]:
        import subprocess

        flags, arguments = self._args()
        if arguments:
            return [fs.basename(argument) for argument in arguments]
        if "s" in flags:
            selection = self.fm.thistab.get_selection()
            return [entry.basename for entry in selection]
        if "c" in flags:
            clipboard = subprocess.run(
                ["xco"], stdout=subprocess.PIPE, text=True, check=False
            ).stdout
            return [fs.basename(line) for line in clipboard.splitlines()]
        if "b" in flags:
            return [self.fm.thisfile.basename]
        return []

    def _paths(self, flags: set[str]) -> list[str]:
        if "s" in flags:
            return [fs.abspath(entry.path) for entry in self.fm.thistab.get_selection()]
        if "y" in flags:
            return [fs.abspath(entry.path) for entry in self.fm.copy_buffer]
        return []

    def _replace_links(self, flags: set[str]) -> None:
        source = fs.abspath(self.fm.thisfile.path)
        targets = self._paths(flags)
        if not fs.isfile(source) or len(targets) != 1 or not fs.isfile(targets[0]):
            self.fm.notify(
                "Need one existing cursor file and one yanked file.", bad=True
            )
            return
        target = targets[0]
        links = []
        for root in self.data_roots + (self.view_root,):
            if not fs.isdir(root):
                continue
            for directory, dirnames, filenames in os.walk(root):
                entries = dirnames + filenames
                dirnames[:] = [
                    entry
                    for entry in dirnames
                    if not fs.islink(fs.join(directory, entry))
                ]
                links.extend(
                    fs.join(directory, entry)
                    for entry in entries
                    if fs.islink(fs.join(directory, entry))
                    and fs.realpath(fs.join(directory, entry)) == source
                )
        self._ask_replace(links, source, target, False)

    def _replace_links_confirmed(
        self, answer: str, source: str, target: str, links: list[str]
    ) -> None:
        answer = answer.lower()
        if answer in ("q", "n"):
            return
        if answer == "l":
            output = "\n".join(
                f"{link} -> {os.readlink(link)}" for link in links if fs.lexists(link)
            )
            self.fm.execute_command("printf '%s\\n' " + shell_quote(output), flags="-w")
            self._ask_replace(links, source, target, False)
            return
        self._replace_links_now(links, source, target, answer == "a")

    def _ask_replace(
        self, links: list[str], source: str, target: str, automatic: bool
    ) -> None:
        if not links:
            return
        link, *remaining = links
        if automatic:
            self._replace_one(link, source, target)
            self._ask_replace(remaining, source, target, True)
            return
        self.fm.ui.console.ask(
            f"Replace ({len(links)} remaining): {link} -> {os.readlink(link)}? (y/n/q/a/l)",
            lambda answer: self._replace_one_answer(
                answer, link, remaining, source, target
            ),
            ("y", "Y", "n", "N", "q", "Q", "a", "A", "l", "L"),
        )

    def _replace_one_answer(
        self, answer: str, link: str, remaining: list[str], source: str, target: str
    ) -> None:
        answer = answer.lower()
        if answer == "l":
            output = "\n".join(
                f"{item} -> {os.readlink(item)}"
                for item in [link] + remaining
                if fs.lexists(item)
            )
            self.fm.execute_command("printf '%s\\n' " + shell_quote(output), flags="-w")
            self._ask_replace([link] + remaining, source, target, False)
        elif answer in ("y", "a"):
            self._replace_one(link, source, target)
            self._ask_replace(remaining, source, target, answer == "a")
        elif answer == "n":
            self._ask_replace(remaining, source, target, False)

    def _replace_links_now(
        self, links: list[str], source: str, target: str, automatic: bool
    ) -> None:
        for link in links:
            self._replace_one(link, source, target)

    def _replace_one(self, link: str, source: str, target: str) -> None:
        if not fs.islink(link) or fs.realpath(link) != source:
            return
        directory = fs.dirname(link)
        new_link = fs.join(directory, fs.basename(target))
        if (
            fs.lexists(new_link)
            and (
                not fs.islink(new_link) or fs.realpath(new_link) != fs.realpath(target)
            )
            and new_link != link
        ):
            self.fm.notify(f"Collision: {new_link}", bad=True)
            return
        if fs.lexists(new_link) and fs.realpath(new_link) == fs.realpath(target):
            if new_link != link:
                os.unlink(link)
            return
        temporary = fs.join(directory, f".{fs.basename(target)}.vdsym-{os.getpid()}")
        try:
            os.symlink(fs.relpath(target, directory), temporary)
            os.replace(temporary, new_link)
            if new_link != link:
                os.unlink(link)
        except OSError as error:
            self.fm.notify(error, bad=True)
            if fs.lexists(temporary):
                os.unlink(temporary)

    def _dashboard_root(self) -> str | None:
        import shlex

        tokens = shlex.split(self.rest(1))
        for token in tokens:
            if token.startswith("--dashboard="):
                return token.split("=", 1)[1]
        for index, token in enumerate(tokens[:-1]):
            if token in ("-d", "--dashboard") and not tokens[index + 1].startswith("-"):
                return tokens[index + 1]
        return None

    def _matches_fd(self) -> list[str]:
        import subprocess

        flags, _ = self._args()
        roots = (self.view_root,) if "v" in flags else (self.view_root,) + self.data_roots
        names = self._names()
        roots = tuple(root for root in roots if fs.isdir(root))
        if not roots or not names:
            return []
        paths = []
        path_seen = set()
        fd_flags = ["fd", "--absolute-path", "--print0", "--glob"]
        if "i" in flags:
            fd_flags.append("--ignore-case")
        for raw_name in names:
            name = raw_name
            if "n" in flags:
                name = re.sub(r"\.html$", "", name)
                if match := re.fullmatch(r"(\d+)-0*(\d+)", name):
                    name = rf"{match[1]}-{match[2]}"
            pattern = f"*{name}*" if "g" in flags else name
            try:
                result = subprocess.run(
                    fd_flags + [pattern, *roots],
                    stdout=subprocess.PIPE,
                    check=False,
                )
            except OSError:
                return self._matches_slow()
            for path in result.stdout.decode().split("\0"):
                if path and path not in path_seen:
                    path_seen.add(path)
                    paths.append(path)
        try:
            result = subprocess.run(
                ["fd", "--absolute-path", "--print0", "--type", "l", ".", *roots],
                stdout=subprocess.PIPE,
                check=False,
            )
        except OSError:
            return self._matches_slow()
        for path in result.stdout.decode().split("\0"):
            if path and path not in path_seen:
                path_seen.add(path)
                paths.append(path)
        return self._filter_matches(paths)

    def _filter_matches(self, paths: list[str]) -> list[str]:
        flags, _ = self._args()
        ignorecase = "i" in flags
        names = self._names()
        matches = []
        seen = set()
        for raw_name in names:
            name = raw_name
            if "n" in flags:
                name = re.sub(r"\.html$", "", name)
                if match := re.fullmatch(r"(\d+)-0*(\d+)", name):
                    name = rf"{match[1]}-{match[2]}"
            needle = name.casefold() if ignorecase else name
            pattern = f"*{needle}*" if "g" in flags else needle
            for path in paths:
                is_link = fs.islink(path)
                if "l" in flags and not is_link:
                    continue
                candidates = [fs.basename(path)]
                if is_link:
                    candidates.append(fs.basename(os.readlink(path)))
                if path not in seen and any(
                    fnmatch(candidate.casefold() if ignorecase else candidate, pattern)
                    for candidate in candidates
                ):
                    seen.add(path)
                    matches.append(path)
        return matches

    def _matches(self) -> list[str]:
        flags, _ = self._args()
        roots = (self.view_root,) if "v" in flags else (self.view_root,) + self.data_roots
        if "Q" in flags:
            self._dir_cache.clear()
        if "q" in flags or "Q" in flags:
            self._prefill_fd(roots)
        paths = []
        deferred = {}
        for root in roots:
            normal, lazy = self._cached_root(root, "Q" in flags)
            paths.extend(normal)
            deferred.update(lazy)
        paths.extend(self._expand_deferred(deferred))
        return self._filter_matches(paths)

    def _prefill_fd(self, roots: tuple[str, ...]) -> None:
        import subprocess

        roots = tuple(root for root in roots if fs.isdir(root))
        if not roots:
            return
        try:
            result = subprocess.run(
                ["fd", "--absolute-path", "--print0", ".", *roots],
                stdout=subprocess.PIPE,
                check=False,
            )
        except OSError:
            return
        entries: dict[str, list[str]] = {root: [] for root in roots}
        for path in result.stdout.decode().split("\0"):
            if not path:
                continue
            parent = fs.dirname(path)
            if parent in entries:
                entries[parent].append(path)
        for root in roots:
            mtimes = {}
            for directory in (root, *entries):
                if directory.startswith(root) and fs.isdir(directory):
                    try:
                        mtimes[directory] = os.stat(directory).st_mtime_ns
                    except OSError:
                        pass
            for directory, paths in entries.items():
                if directory.startswith(root):
                    self._dir_cache.setdefault(directory, (mtimes.get(directory, 0), paths, []))

    def _cached_root(self, root: str, force: bool) -> tuple[list[str], dict[str, list[str]]]:
        cache = {} if force else self._dir_cache.setdefault(root, {})
        normal = [root]
        deferred: dict[str, list[str]] = {}
        visited = set()
        stack = [root]
        while stack:
            directory = stack.pop()
            visited.add(directory)
            try:
                mtime = os.stat(directory).st_mtime_ns
            except OSError:
                continue
            cached = cache.get(directory)
            if cached and cached[0] == mtime:
                entries, lazy = cached[1:]
                stack.extend(
                    path for path in entries
                    if fs.isdir(path) and not fs.islink(path)
                )
            else:
                entries, lazy = [], []
                try:
                    for entry in os.scandir(directory):
                        path = entry.path
                        if entry.is_dir(follow_symlinks=False):
                            entries.append(path)
                            stack.append(path)
                        else:
                            relative = fs.relpath(path, root).split(os.sep)
                            if any(
                                part.endswith("-pics") or "-pics-" in part
                                for part in relative[:-1]
                            ):
                                lazy.append(path)
                            else:
                                entries.append(path)
                except OSError:
                    continue
                cache[directory] = (mtime, entries, lazy)
            normal.extend(entries)
            if lazy:
                deferred[directory] = lazy
        for directory in set(cache) - visited:
            del cache[directory]
        return normal, deferred

    def _expand_deferred(self, deferred: dict[str, list[str]]) -> list[str]:
        names = self._names()
        numeric = tuple(sorted({
            match[1]
            for name in names
            if (match := re.match(r"(\d+)", name))
        }))
        key = (numeric, tuple(sorted((directory, tuple(paths)) for directory, paths in deferred.items())))
        if key != self._pics_cache_key:
            self._pics_cache_key = key
            self._pics_cache = [
                path
                for pics_dir, paths in deferred.items()
                if fs.basename(pics_dir).split("-", 1)[0] in numeric
                for path in paths
            ]
        return self._pics_cache

    def _matches_slow(self) -> list[str]:
        flags, _ = self._args()
        paths = []
        roots = (self.view_root,) if "v" in flags else (self.view_root,) + self.data_roots
        for root in roots:
            if not fs.isdir(root):
                continue
            for directory, dirnames, filenames in os.walk(root):
                entries = filenames + dirnames
                dirnames[:] = [
                    entry
                    for entry in dirnames
                    if not fs.islink(fs.join(directory, entry))
                ]
                paths.extend(fs.join(directory, entry) for entry in entries)
        return self._filter_matches(paths)

    def _dashboard(self, matches: list[str]) -> str:
        root = self._dashboard_root()
        dest = (
            fs.join(root, self._name())
            if root is not None
            else fs.join("/t/bnm", self.fm.thisfile.relative_path)
        )
        os.makedirs(dest, exist_ok=True)
        for source in matches:
            link = fs.join(dest, source.lstrip("/").replace("/", "⁄"))
            if fs.lexists(link):
                continue
            os.symlink(source, link)
        self.fm.cd(dest)
        return dest

    def _yank(self, matches: list[str]) -> None:
        import subprocess

        subprocess.run(["xci"], input="\n".join(matches), text=True, check=False)

    def _jump(self, matches: list[str]) -> None:
        current = self.fm.thisfile.path
        rotate = "r" in self._args()[0]
        if rotate and current in matches:
            target = matches[(matches.index(current) + 1) % len(matches)]
        else:
            dashboard_match = next(
                (
                    fs.join(self.fm.thisdir.path, entry.basename)
                    for entry in self.fm.thisdir.files
                    if entry.is_link and fs.realpath(entry.path) == fs.realpath(current)
                ),
                None,
            )
            target = dashboard_match or matches[0]
        self.fm.select_file(target)
        if "o" in self._args()[0]:
            self.fm.move(right=1)
        if len(matches) > 1:
            position = next(
                index
                for index, match in enumerate(matches)
                if match == target or fs.realpath(match) == fs.realpath(target)
            )
            self.fm.notify(f"MULTI ({position + 1}/{len(matches)})")

    def execute(self) -> None:
        flags, _ = self._args()
        if ("q" in flags or "Q" in flags) and not flags.intersection("ad jopxR".replace(" ", "")):
            self._matches()
            self.fm.notify("Cache refreshed.")
            return
        if "R" in flags:
            self._replace_links(flags)
            return
        names = self._names()
        if len(names) > 1 and "m" not in flags:
            self.fm.notify("Source has multiple needles; use --multiple.", bad=True)
            return
        if not names:
            self.fm.notify(
                "Use --basename, --clipboard, or an explicit name.",
                duration=1,
                bad=True,
            )
            return
        matches = self._matches()
        if not matches and "a" not in flags and "p" not in flags:
            self.fm.notify(f"No matches for '{self._name()}'.", duration=1, bad=True)
            return
        if "a" in flags:
            if not matches:
                self.fm.notify(
                    f"No matches for '{self._name()}'.", duration=1, bad=True
                )
            elif len(matches) == 1:
                self._jump(matches)
            else:
                self._dashboard(matches)
            return
        if "x" in flags:
            self._yank(matches)
            return
        if "d" in flags:
            self._dashboard(matches)
            return
        if "p" in flags:
            if "r" in flags and matches:
                current = self.fm.thisfile.path
                if current in matches:
                    matches = [matches[(matches.index(current) + 1) % len(matches)]]
                else:
                    matches = [matches[0]]
            needle = self._name()
            if "n" in flags:
                needle = re.sub(r"\.html$", "", needle)
                if match := re.fullmatch(r"(\d+)-0*(\d+)", needle):
                    needle = rf"{match[1]}-{match[2]}"
            pattern = re.compile(
                re.escape(needle), re.IGNORECASE if "i" in flags else 0
            )

            def highlight(value: str) -> str:
                return pattern.sub(lambda match: f"\\033[31;1m{match[0]}\\033[m", value)

            if matches:
                lines = []
                for match in matches:
                    line = highlight(match)
                    if fs.islink(match):
                        line += f"  ->  {highlight(os.readlink(match))}"
                    lines.append(line)
                output = "\\n".join(lines)
            else:
                output = "\\033[31;40;1mnotfound\\033[m "
            self.fm.execute_command(
                "printf '%b\\n' " + shell_quote(output) + "; read -k 1",
                flags="-w",
            )
            return
        if "j" in flags:
            self._jump(matches)
            return
        self.fm.select_file(matches[0])
        if "o" in flags:
            self.fm.move(right=1)


# OR: map dD eval fm.set_clipboard(fm.thisfile.basename.encode('utf-8')); cmd('delete')
class delete(_default_delete):
    """:delete

    Copy selected file names to the clipboard before deleting them.
    Deletion is skipped when clipboard copy fails.
    """

    def _copy_names(self, names: Sequence[str]) -> bool:
        import subprocess

        try:
            process = subprocess.run(
                ["xci"],
                input="\n".join(names),
                text=True,
                capture_output=True,
                check=False,
            )
        except OSError:
            return False
        return process.returncode == 0

    def _delete_with_clipboard(self, files: Sequence[str]) -> None:
        names = [fs.basename(file) for file in files]
        if self._copy_names(names):
            self._original_delete(files)
        else:
            self.fm.notify("Could not copy file name to clipboard", bad=True)

    def execute(self) -> None:
        if not hasattr(self.fm, "_airy_original_delete"):
            self.fm._airy_original_delete = self.fm.delete
        self._original_delete = self.fm._airy_original_delete
        self.fm.delete = self._delete_with_clipboard
        super().execute()
