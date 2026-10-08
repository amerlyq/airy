"""On-demand cProfile capture for ranger's main thread."""

import cProfile
import io
import os
import pstats
import sys
import time

from ranger.api.commands import Command


_PROFILER = None
_PROFILE_PATH = None
_TRACER = None
_TRACE_PATH = None
_TRACE_LINES = {}
_TRACE_EDGES = {}
_TRACE_STACK = []
_TRACE_CURRENT = None
_TRACE_LAST_NS = 0


def _profile_dir():
    root = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    path = os.path.join(root, "ranger", "profiles")
    os.makedirs(path, exist_ok=True)
    return path


def _latest_profile():
    root = _profile_dir()
    paths = [
        os.path.join(root, name)
        for name in os.listdir(root)
        if name.endswith(".prof")
    ]
    return max(paths, key=os.path.getmtime) if paths else None


def _markdown_report(path, limit=25):
    stats = pstats.Stats(path)
    lines = [
        "# Ranger performance profile",
        "",
        f"Profile: `{path}`",
        f"Total calls: `{stats.total_calls}`",
        f"Total time: `{stats.total_tt:.3f}s`",
    ]

    def table(title, sort_key):
        stats.sort_stats(sort_key)
        result = [
            "",
            f"## Top {limit} by {title}",
            "",
            "| cumulative | self | calls | location |",
            "|---:|---:|---:|---|",
        ]
        for func in stats.fcn_list[:limit]:
            cc, nc, tt, ct, _ = stats.stats[func]
            filename, lineno, name = func
            location = f"`{filename}:{lineno} ({name})`"
            result.append(f"| {ct:.3f}s | {tt:.3f}s | {cc}/{nc} | {location} |")
        return result

    lines.extend(table("cumulative time", "cumulative"))
    lines.extend(table("self time", "tottime"))
    lines.extend(("", "Cumulative time includes callees.", "Self time excludes callees."))
    return "\n".join(lines) + "\n"


def _trace_name(frame):
    return (frame.f_code.co_filename, frame.f_code.co_firstlineno, frame.f_code.co_name)


def _trace_label(item):
    filename, lineno, name = item
    return f"`{filename}:{lineno} ({name})`"


def _line_trace(frame, event, arg):
    global _TRACE_CURRENT, _TRACE_LAST_NS
    now = time.perf_counter_ns()
    if _TRACE_CURRENT is not None:
        key = _TRACE_CURRENT
        _TRACE_LINES[key] = _TRACE_LINES.get(key, 0) + now - _TRACE_LAST_NS
    _TRACE_LAST_NS = now
    if event == "call":
        key = _trace_name(frame)
        if _TRACE_STACK:
            edge = (_TRACE_STACK[-1], key)
            _TRACE_EDGES[edge] = _TRACE_EDGES.get(edge, 0) + 1
        _TRACE_STACK.append(key)
        _TRACE_CURRENT = (frame.f_code.co_filename, frame.f_lineno, frame.f_code.co_name)
    elif event == "line":
        _TRACE_CURRENT = (frame.f_code.co_filename, frame.f_lineno, frame.f_code.co_name)
    elif event == "return":
        if _TRACE_STACK:
            _TRACE_STACK.pop()
        _TRACE_CURRENT = _TRACE_STACK[-1] if _TRACE_STACK else None
    return _line_trace


def _trace_report(path, limit=40):
    lines = [
        "# Ranger line-trace profile",
        "",
        f"Trace: `{path}`",
        "",
        "## Slow lines",
        "",
        "| time | location |",
        "|---:|---|",
    ]
    for key, ns in sorted(_TRACE_LINES.items(), key=lambda x: x[1], reverse=True)[:limit]:
        lines.append(f"| {ns / 1e9:.6f}s | {_trace_label(key)} |")
    lines.extend(("", "## Call edges", "", "| calls | caller → callee |", "|---:|---|"))
    edges = sorted(_TRACE_EDGES.items(), key=lambda x: x[1], reverse=True)[:limit]
    for (caller, callee), calls in edges:
        lines.append(f"| {calls} | {_trace_label(caller)} → {_trace_label(callee)} |")
    return "\n".join(lines) + "\n"


class rprofile(Command):
    """:rprofile <start|stop|toggle>"""

    def execute(self):
        global _PROFILER, _PROFILE_PATH
        global _TRACER, _TRACE_PATH, _TRACE_LINES, _TRACE_EDGES
        global _TRACE_STACK, _TRACE_CURRENT, _TRACE_LAST_NS
        action = self.arg(1) or "toggle"
        if action == "toggle":
            action = "stop" if _PROFILER is not None else "start"

        if action == "start":
            if _PROFILER is not None:
                return self.fm.notify("rprofile: already running")
            stamp = time.strftime("%Y%m%d-%H%M%S")
            _PROFILE_PATH = os.path.join(_profile_dir(), f"ranger-{stamp}.prof")
            _PROFILER = cProfile.Profile()
            _PROFILER.enable()
            return self.fm.notify(f"rprofile: recording {_PROFILE_PATH}")

        if action == "stop":
            if _PROFILER is None:
                return self.fm.notify("rprofile: not running")
            profiler, path = _PROFILER, _PROFILE_PATH
            _PROFILER = _PROFILE_PATH = None
            profiler.disable()
            profiler.dump_stats(path)
            report_path = path + ".txt"
            stream = io.StringIO()
            pstats.Stats(profiler, stream=stream).sort_stats("cumulative").print_stats(80)
            with open(report_path, "w") as report:
                report.write(stream.getvalue())
            return self.fm.notify(f"rprofile: wrote {path} and {report_path}")

        if action == "report":
            if _PROFILER is not None:
                return self.fm.notify("rprofile: stop recording first", bad=True)
            path = _PROFILE_PATH or _latest_profile()
            if path is None:
                return self.fm.notify("rprofile: no profile found", bad=True)
            text = _markdown_report(path)
            report_path = path + ".md"
            with open(report_path, "w") as report:
                report.write(text)
            try:
                self.fm.set_clipboard(text.encode("utf-8"))
                copied = "; copied to clipboard"
            except Exception:
                copied = ""
            return self.fm.notify(f"rprofile: wrote {report_path}{copied}")

        if action == "trace":
            subaction = self.arg(2) or "toggle"
            if subaction == "toggle":
                subaction = "stop" if _TRACER is not None else "start"
            if subaction == "start":
                if _TRACER is not None:
                    return self.fm.notify("rprofile: line trace already running")
                stamp = time.strftime("%Y%m%d-%H%M%S")
                _TRACE_PATH = os.path.join(_profile_dir(), f"ranger-{stamp}.trace")
                _TRACE_LINES = {}
                _TRACE_EDGES = {}
                _TRACE_STACK = []
                _TRACE_CURRENT = None
                _TRACE_LAST_NS = time.perf_counter_ns()
                _TRACER = _line_trace
                sys.settrace(_TRACER)
                return self.fm.notify(f"rprofile: line tracing {_TRACE_PATH}")
            if subaction == "stop":
                if _TRACER is None:
                    return self.fm.notify("rprofile: line trace not running")
                sys.settrace(None)
                trace_path = _TRACE_PATH
                _TRACER = _TRACE_PATH = None
                text = _trace_report(trace_path)
                report_path = trace_path + ".md"
                with open(report_path, "w") as report:
                    report.write(text)
                try:
                    self.fm.set_clipboard(text.encode("utf-8"))
                    copied = "; copied to clipboard"
                except Exception:
                    copied = ""
                return self.fm.notify(f"rprofile: wrote {report_path}{copied}")
            return self.fm.notify("rprofile: trace use start, stop, or toggle", bad=True)

        return self.fm.notify("rprofile: use start, stop, toggle, or report", bad=True)
