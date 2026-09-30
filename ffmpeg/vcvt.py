#!/usr/bin/env python3.14
"""AV1/HEVC conversion with atomic output publication and persistent tmux batches."""

from __future__ import annotations

import argparse
import ctypes
import errno
import fcntl
import json
import os
import re
import select
import shlex
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path

SELF = Path(__file__).resolve()
GENERATED = re.compile(r"_(?:va|[acnqv])\d+(?:_prev\d+)?$", re.I)
SCALE = (
    "scale=w='if(gt(iw,ih),min(iw,1920),min(iw,1080))':"
    "h='if(gt(iw,ih),min(ih,1080),min(ih,1920))':"
    "force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos"
)
SVT = (
    "tune=0:scd=1:keyint=5s:lookahead=120:enable-qm=1:qm-min=0:qm-max=15:"
    "enable-overlays=1:sharpness=1:enable-tf=0"
)


def run(argv, **kwargs):
    return subprocess.run(list(map(str, argv)), check=True, **kwargs)


def probe(path):
    result = run(
        [
            "ffprobe",
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=codec_name,width,height",
            "-of",
            "json",
            "-i",
            path,
        ],
        capture_output=True,
        text=True,
        timeout=60,
    )
    streams = json.loads(result.stdout).get("streams", [])
    if not streams or not streams[0].get("codec_name"):
        raise ValueError(f"no video stream: {path}")
    return streams[0]


def absolute(path):
    # Do not resolve symlinks: output belongs beside the submitted path.
    return Path(os.path.abspath(path))


def collect(paths, include_generated=False):
    seen = set()
    result = []
    for raw in paths:
        path = absolute(raw)
        if not path.exists():
            raise FileNotFoundError(path)
        candidates = sorted(path.rglob("*")) if path.is_dir() else [path]
        for item in candidates:
            if not item.is_file() or item.suffix.lower() not in (".mp4", ".webp"):
                continue
            if not include_generated and GENERATED.search(item.stem):
                continue
            if item not in seen:
                seen.add(item)
                result.append(item)
    return result


def encoder(args):
    choice = args.encoder or os.environ.get("use")
    if choice is None:
        if not args.g:
            choice = "cpu"
        elif Path("/dev/nvidia0").exists():
            choice = "nv"
        elif Path("/sys/module/i915").exists() or Path("/sys/module/xe").exists():
            choice = "qsv"
        else:
            raise ValueError("no GPU found; use --encoder to select explicitly")
    if choice not in ("cpu", "nv", "qsv"):
        raise ValueError("encoder must be cpu, nv or qsv")
    quality = (
        args.c
        if args.c is not None
        else int(os.environ.get("qa", 32 if choice == "cpu" else 28))
    )
    limit = 63 if choice == "cpu" else 51
    if not 0 <= quality <= limit or (choice == "qsv" and quality == 0):
        raise ValueError(f"quality outside supported range for {choice}")
    tag = (
        "a"
        if args.a
        else os.environ.get("ifx", {"cpu": "v", "nv": "n", "qsv": "q"}[choice])
    )
    if not re.fullmatch("[A-Za-z]+", tag):
        raise ValueError("ifx must contain only letters")
    args.encoder, args.c, args.tag = choice, quality, tag
    if not args.j:
        args.j = (
            max(1, (os.process_cpu_count() or 1) // 16)
            if choice == "cpu"
            else {"nv": 5, "qsv": 1}[choice]
        )


def command(args, source, output, concat=False):
    cmd = ["ffmpeg", "-hide_banner", "-nostdin", "-n"]
    if concat:
        cmd += ["-f", "concat", "-safe", "0"]
    cmd += ["-i", str(source), "-map", "0:v:0", "-map", "0:a?", "-map_metadata", "0"]
    if concat:
        cmd += ["-fps_mode", "vfr"]
    # Software scaling keeps orientation/aspect behavior identical across backends.
    if args.encoder == "cpu":
        cmd += [
            "-vf",
            SCALE + ",format=yuv420p10le",
            "-c:v",
            "libsvtav1",
            "-preset",
            "4",
            "-crf",
            str(args.c),
            "-pix_fmt",
            "yuv420p10le",
            "-svtav1-params",
            SVT,
        ]
    elif args.encoder == "nv":
        cmd += [
            "-vf",
            SCALE + ",format=p010le",
            "-c:v",
            "hevc_nvenc",
            "-preset",
            "p7",
            "-profile:v",
            "main10",
            "-multipass",
            "qres",
            "-rc",
            "vbr",
            "-cq",
            str(args.c),
            "-maxrate",
            "8M",
            "-bufsize",
            "16M",
            "-rc-lookahead",
            "48",
            "-spatial_aq",
            "1",
            "-aq-strength",
            "8",
            "-g",
            "30",
            "-bf",
            "4",
            "-b_ref_mode",
            "middle",
        ]
    else:
        cmd += [
            "-vf",
            SCALE + ",format=nv12",
            "-c:v",
            "hevc_qsv",
            "-preset",
            "slow",
            "-global_quality",
            str(args.c),
        ]
    return cmd + ["-c:a", "copy", "-movflags", "+faststart", str(output)]


@contextmanager
def output_lock(output):
    # Lock files persist: unlinking a flock inode permits simultaneous holders.
    path = output.parent / ("." + output.name + ".lock")
    with path.open("a") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        yield


def sync_directory(directory):
    fd = os.open(directory, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def publish(temporary, output):
    """Keep old output until new output is complete; retain numbered backups."""
    if os.path.lexists(output):
        index = 1
        while True:
            backup = output.with_name(f"{output.stem}_prev{index}{output.suffix}")
            try:
                os.link(output, backup, follow_symlinks=False)
                break
            except FileExistsError:
                index += 1
        print(f"[backup] {backup}", flush=True)
    os.replace(temporary, output)
    sync_directory(output.parent)


def move_no_replace(source, destination):
    """Never overwrite an archive entry, including across filesystems."""
    try:
        os.link(source, destination, follow_symlinks=False)
    except OSError as error:
        if error.errno != errno.EXDEV:
            raise
        if source.is_symlink():
            os.symlink(os.readlink(source), destination)
        else:
            with tempfile.TemporaryDirectory(
                prefix=".vcvt-move-", dir=destination.parent
            ) as folder:
                copy = Path(folder) / source.name
                shutil.copy2(source, copy)
                with copy.open("rb") as handle:
                    os.fsync(handle.fileno())
                os.link(copy, destination)
    sync_directory(destination.parent)
    source.unlink()
    sync_directory(source.parent)


def archive(source, output):
    directory = source.parent.parent / "done"
    directory.mkdir(exist_ok=True)
    if source.is_symlink():
        raise ValueError(f"archiving symlink inputs is unsupported: {source}")
    destinations = [directory / source.name, directory / output.name]
    for target in destinations:
        if os.path.lexists(target):
            raise FileExistsError(f"archive collision: {target}")
    move_no_replace(source, destinations[0])
    try:
        move_no_replace(output, destinations[1])
    except BaseException:
        move_no_replace(destinations[0], source)
        raise


@contextmanager
def webp_source(source):
    """libwebp utilities preserve animated WebP frame durations."""
    with tempfile.TemporaryDirectory(prefix="vcvt-webp-") as folder:
        directory = Path(folder)
        info = run(["webpinfo", source], capture_output=True, text=True).stdout
        durations = [int(value) for value in re.findall(r"Duration:\s*(\d+)", info)]
        if not durations:
            yield source, False
            return
        run(["anim_dump", "-pam", "-folder", directory, "-prefix", "f_", source])
        frames = sorted(directory.glob("f_*.pam"))
        if len(frames) != len(durations):
            raise ValueError("WebP frame count does not match duration count")
        # Relative generated names contain no quoting-sensitive characters.
        lines = ["ffconcat version 1.0"]
        for frame, duration in zip(frames, durations, strict=True):
            lines += [
                f"file '{frame.name}'",
                "option framerate 1000",
                f"duration {max(1, duration) / 1000:.3f}",
            ]
        lines.append(f"file '{frames[-1].name}'")
        lines.append("option framerate 1000")
        manifest = directory / "frames.ffconcat"
        manifest.write_text("\n".join(lines) + "\n")
        yield manifest, True


def convert(args, source):
    output = source.with_name(f"{source.stem}_{args.tag}{args.c}.mp4")
    if args.d:
        if source.suffix.lower() == ".webp":
            print(f"[WebP frames] {source}")
        print(shlex.join(command(args, source, output)))
        if args.D:
            print(f"[archive after success] {source.parent.parent / 'done'}")
        return
    if args.D and source.is_symlink():
        raise ValueError(f"archiving symlink inputs is unsupported: {source}")
    with output_lock(output):
        before = source.stat()
        with tempfile.TemporaryDirectory(prefix=".vcvt-", dir=output.parent) as folder:
            temporary = Path(folder) / output.name
            if source.suffix.lower() == ".webp":
                with webp_source(source) as (input_path, concat):
                    cmd = command(args, input_path, temporary, concat)
                    if args.x:
                        print(shlex.join(cmd), flush=True)
                    run(cmd)
            else:
                cmd = command(args, source, temporary)
                if args.x:
                    print(shlex.join(cmd), flush=True)
                run(cmd)
            info = probe(temporary)
            expected = "av1" if args.encoder == "cpu" else "hevc"
            if temporary.stat().st_size == 0 or info["codec_name"] != expected:
                raise ValueError(f"invalid encoder output: {temporary}")
            after = source.stat()
            if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) != (
                after.st_dev,
                after.st_ino,
                after.st_size,
                after.st_mtime_ns,
            ):
                raise ValueError(f"input changed during conversion: {source}")
            with temporary.open("rb") as handle:
                os.fsync(handle.fileno())
            publish(temporary, output)
        if args.D:
            archive(source, output)
        print(f"[converted] {output}", flush=True)


def executor():
    sibling = SELF.parent.parent / "tmux" / "bin" / "tmux-jobs.py"
    if sibling.is_file():
        return [sys.executable, str(sibling)]
    if found := shutil.which("tmux-jobs.py"):
        return [found]
    raise FileNotFoundError("tmux-jobs.py not found beside repository or on PATH")


def enqueue(args, files):
    cmd = executor() + ["-s", args.session, "-j", str(args.j)]
    if args.w:
        cmd += ["--unique"]
    if args.O:
        cmd += ["-O"]
    if args.d:
        cmd += ["-n"]
    cmd += [
        "--",
        sys.executable,
        str(SELF),
        "-i",
        "--encoder",
        args.encoder,
        "-c",
        str(args.c),
    ]
    if args.a:
        cmd += ["-a"]
    if args.D:
        cmd += ["-D"]
    if args.x:
        cmd += ["-x"]
    # Protect even filenames beginning with '-' (all paths are absolute too).
    cmd += ["--"]
    run(
        cmd,
        input=b"".join(os.fsencode(path) + b"\0" for path in files),
        cwd=str(files[0].parent) if args.w else None,
    )


def eligible(files, dry=False):
    # Dry run needs no media tools and performs no filesystem mutation.
    return [
        path
        for path in files
        if dry or path.suffix.lower() == ".webp" or probe(path)["codec_name"] != "av1"
    ]


def watch(args):
    if len(args.paths) > 1:
        raise ValueError("-w accepts one directory")
    todo = absolute(args.paths[0] if args.paths else "/cache/vd_cvt/todo")
    if not todo.is_dir():
        raise NotADirectoryError(todo)
    queue = todo.parent / "queue"
    args.D = True
    if args.d:
        files = collect([todo] + ([queue] if queue.exists() else []))
        for path in files:
            print(f"[watch enqueue after close] {path}")
        return
    if not sys.platform.startswith("linux"):
        raise ValueError("watch mode requires Linux inotify")
    queue.mkdir(exist_ok=True)
    # Install watch before scanning backlog. Events arriving during scan stay queued.
    libc = ctypes.CDLL(None, use_errno=True)
    libc.inotify_init1.argtypes = [ctypes.c_int]
    libc.inotify_add_watch.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_uint32]
    fd = libc.inotify_init1(os.O_NONBLOCK | os.O_CLOEXEC)
    if fd < 0:
        raise OSError(ctypes.get_errno(), "inotify_init1")
    try:
        if (
            libc.inotify_add_watch(fd, os.fsencode(todo), 0x8 | 0x80 | 0x400 | 0x800)
            < 0
        ):
            raise OSError(ctypes.get_errno(), "inotify_add_watch")
        # Single watcher owns moves and submissions for this layout.
        with (queue / ".vcvt-watch.lock").open("a") as handle:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            backlog = eligible(collect([queue]))
            if backlog:
                enqueue(args, backlog)
            pending = {
                path: (path.stat().st_size, path.stat().st_mtime_ns, time.monotonic())
                for path in collect([todo])
                if path.parent == todo
            }
            ready = set()
            while True:
                if select.select([fd], [], [], 0.5)[0]:
                    data = os.read(fd, 1024 * 1024)
                    offset = 0
                    while offset < len(data):
                        _, mask, _, length = struct.unpack_from("iIII", data, offset)
                        name = os.fsdecode(
                            data[offset + 16 : offset + 16 + length].split(b"\0")[0]
                        )
                        offset += 16 + length
                        if mask & (0x400 | 0x800 | 0x8000):
                            raise RuntimeError("watched directory disappeared")
                        if mask & 0x4000:
                            raise RuntimeError(
                                "inotify overflow; restart watcher to rescan backlog"
                            )
                        if name and not name.startswith(".") and mask & (0x8 | 0x80):
                            ready.add(todo / name)
                # Existing backlog has no close event: require unchanged size/mtime.
                for path, (size, mtime, since) in list(pending.items()):
                    if not path.exists():
                        del pending[path]
                        continue
                    stat = path.stat()
                    if (size, mtime) != (stat.st_size, stat.st_mtime_ns):
                        pending[path] = (
                            stat.st_size,
                            stat.st_mtime_ns,
                            time.monotonic(),
                        )
                    elif time.monotonic() - since >= args.settle:
                        ready.add(path)
                for path in sorted(ready):
                    pending.pop(path, None)
                    if (
                        path.exists()
                        and path.is_file()
                        and not path.is_symlink()
                        and eligible(collect([path]))
                    ):
                        target = queue / path.name
                        move_no_replace(path, target)
                        # If submission fails, target stays in queue for restart recovery.
                        enqueue(args, [target])
                ready.clear()
    finally:
        os.close(fd)


def parser():
    p = argparse.ArgumentParser(description=__doc__)
    for flag, help_text in [
        ("A", "attach to tmux session"),
        ("a", "use a output tag"),
        ("d", "dry run; no filesystem changes"),
        ("g", "select GPU encoder"),
        ("i", "convert serially without tmux"),
        ("O", "capture successful panes"),
        ("D", "archive input/output to ../done after success"),
        ("w", "watch todo directory; implies -D"),
        ("x", "print commands"),
    ]:
        p.add_argument("-" + flag, action="store_true", help=help_text)
    p.add_argument("-c", type=int, help="encoder quality")
    p.add_argument("-j", type=int, default=0, help="concurrency; 0=auto, 1=serial")
    p.add_argument(
        "-0", dest="nul", action="store_true", help="NUL-delimited stdin paths"
    )
    p.add_argument("--encoder", choices=["cpu", "nv", "qsv"])
    p.add_argument("--session", default="vcvt")
    p.add_argument(
        "--settle", type=float, default=5, help="watch backlog stability seconds"
    )
    p.add_argument("paths", nargs="*")
    return p


def main(argv=None):
    p = parser()
    args = p.parse_args(argv)
    if args.j < 0 or args.settle <= 0:
        p.error("-j must be nonnegative; --settle must be positive")
    if args.A:
        return subprocess.call(["tmux", "attach-session", "-t", "=" + args.session])
    encoder(args)
    if args.w:
        watch(args)
        return 0
    paths = args.paths
    if not paths:
        if sys.stdin.isatty():
            p.error("provide files, directories or stdin paths")
        paths = [
            os.fsdecode(item)
            for item in sys.stdin.buffer.read().split(b"\0" if args.nul else b"\n")
            if item
        ]
    files = eligible(collect(paths, include_generated=args.i), dry=args.d)
    if not files:
        print("No non-AV1 MP4/WebP inputs.", file=sys.stderr)
        return 0
    if args.i or args.j == 1 or (len(files) == 1 and not args.w):
        failures = 0
        for source in files:
            try:
                convert(args, source)
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                failures += 1
                print(f"vcvt.py: {source}: {error}", file=sys.stderr)
        return int(bool(failures))
    enqueue(args, files)
    return 0


if __name__ == "__main__":
    # tmux wrapper sends TERM to the whole process group. Let Python unwind temps.
    def stop(signum, frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGHUP, stop)
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"vcvt.py: {error}", file=sys.stderr)
        sys.exit(1)
