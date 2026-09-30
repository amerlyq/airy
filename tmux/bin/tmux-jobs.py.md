# Python executors

Requires Python 3.14 on POSIX.
Watch mode additionally requires Linux.
No third-party Python packages.

## Usage

```sh
printf 'first\0last' | ./tmux/bin/tmux-jobs.py -j4 -- printf '%s\n'
printf 'sleep 1\nfalse\n' | ./tmux/bin/tmux-jobs.py -1 -j2
./tmux/bin/tmux-jobs.py -c -s jobs </dev/null
./tmux/bin/tmux-jobs.py -C -s jobs </dev/null
./tmux/bin/tmux-jobs.py -k -s jobs
./tmux/bin/tmux-jobs.py -K -s jobs
./tmux/bin/tmux-jobs.py -s jobs </dev/null  # resume/recover

./ffmpeg/vcvt.py -d ./videos/
./ffmpeg/vcvt.py -j4 ./videos/
./ffmpeg/vcvt.py -i --encoder cpu -c32 input.mp4
./ffmpeg/vcvt.py -g -j1 input.mp4
find ./videos -name '*.mp4' -print0 | ./ffmpeg/vcvt.py -0
./ffmpeg/vcvt.py -w /cache/vd_cvt/todo
```

`vcvt.py` locates the sibling `tmux-jobs.py` automatically.
Installed copies may instead find `tmux-jobs.py` on PATH.
Both executables support `--help`.

## Queue architecture

State: `${XDG_CACHE_HOME:-$HOME/.cache}/tmux/<session>/python/`.
`jobs.sqlite3` is authoritative.
Legacy Bash queue files are neither read nor migrated.
Existing tmux sessions owned by another executor are rejected.
Use another `-s` / `--session` while a legacy session exists.

SQLite transactions persist queue claims plus outcomes.
WAL uses FULL synchronization.
Each job has a permanent ID.
Each execution attempt has a fresh fencing token.
Arguments are JSON arrays; only command mode invokes `bash -xec`.
Submission cwd plus environment are captured with each record.
The state directory is private because environment snapshots may contain credentials.

Two advisory locks have separate responsibilities:

- `launch.lock`: submissions, dispatch, control commands, coordinator startup/exit.
- `coordinator.lock`: one active coordinator per session.

Workers start without acquiring `launch.lock`.
This allows submitters to wait for their startup acknowledgement while holding it.
An idle worker clears its marker under `launch.lock`.
It releases `coordinator.lock` before releasing `launch.lock`.
This closes the enqueue-versus-idle-exit race.

Pane wrappers write outcomes directly to SQLite.
No completion event can disappear into an unread FIFO.
The coordinator polls at 200 ms intervals.
Pane identity plus attempt tokens let a restarted coordinator adopt surviving jobs.
Missing unfinished jobs are requeued on coordinator recovery.
Missing panes during normal execution become interrupted failures with rc=137.
Exact external signal status is not inferred.

Recovery is **at least once**, not exactly once.
A crash between external side effects and outcome commit may replay a job.
Jobs with irreversible effects must supply their own idempotency.
Jobs deliberately detaching descendants are outside executor lifecycle guarantees.

## Controls and observability

Default failure behavior follows `tmux-jobs.md`: strict blocking.
The Bash script's adaptive success-triggered failure release is intentionally omitted.
A failed pane occupies its slot until ENTER or `-c`.
Successful panes release slots automatically.
`-O` saves successful scrollback.
Error scrollback is saved under `err/`.

`-c` persists unattended continuation and resumes stopped work.
`-C` makes unreleased failures wait for ENTER.
`-k` stops dispatch but lets existing jobs finish.
Held failures still require ENTER or `-c` during graceful drain.
`-K` fences active attempts before killing their panes.
Unfinished jobs remain queued for an explicit restart.
Already-recorded failures are not requeued by `-K`.
Rerunning without stdin resumes pending work.
Explicit `-j` updates the live session limit.
Reducing it does not kill existing jobs.

`success.log` and `failure.log` are regenerable snapshots.
Format: `<exec_ts> <duration_s> <added_ts> <shell-display-argv>`.
Interrupted failures append `rc=137 interrupted`.
Embedded newlines are escaped for display.
The database retains exact arguments plus return codes.
Optional `dunstify` notifications report failures and completion.

`--unique` suppresses identical argv/cwd submissions while pending.
Ordinary submissions preserve duplicates as separate job IDs.
Watch mode uses `--unique` to avoid resubmitting pending queue files on restart.

## Conversion behavior

Dependencies: FFmpeg plus ffprobe.
Animated WebP additionally uses `webpinfo` plus `anim_dump`.
SVT tuning requires an FFmpeg/SVT build supporting the original script's parameters.
GPU encoding requires the corresponding FFmpeg encoder plus working drivers.

Directories expand recursively.
MP4 matching is case-insensitive.
WebP inputs are supported in batches too.
Generated `_v32`, `_n28`, `_q28`, `_a32`-style files are excluded from discovery.
Explicit `-i` permits generated filenames as inputs.
AV1 MP4 inputs are skipped.
Symlink inputs retain their submitted location for output placement.

One eligible input runs directly.
`-i` or `-j1` runs serially.
Larger batches enqueue through the Python executor.
Watch arrivals always enqueue, including with `-j1`.
Batch submission success means acceptance, not eventual encoding success.
Use tmux panes or queue logs for asynchronous outcomes.

CPU uses libsvtav1 with the original perceptual tuning.
NVIDIA uses hevc_nvenc.
Intel uses hevc_qsv; this fixes the Bash GPU-selection typo.
All backends share software scaling for reproducible orientation/aspect behavior.
Landscape fits within 1920x1080.
Portrait fits within 1080x1920.
Audio streams are copied.
The first video stream is encoded.
Subtitles and data streams are not copied.
WebP alpha is not retained in MP4.

Quality defaults: CPU 32; GPU 28.
Output tags: CPU `v`; NVIDIA `n`; Intel `q`; `-a` overrides to `a`.
`use`, `qa`, and `ifx` environment defaults remain supported.
`--encoder` makes backend choice explicit.
Automatic concurrency retains the original CPU-count/16 heuristic.
This is not a hard encoder thread limit.

Each conversion writes into a private temporary directory beside its output.
ffprobe checks the resulting video codec before publication.
This is container/stream validation, not a full decode verification.
Input identity, size, and modification time must remain unchanged.
The completed file is fsynced before atomic replacement.
Previous output survives failed conversions.
Successful replacements retain `_prev1`, `_prev2`, ... backups.
Persistent hidden lock files serialize writers to the same output path.

`-D` archives source plus output to `../done/` only after publication.
Archive moves refuse collisions.
Cross-filesystem moves stage a complete copy before publication.
The first move is rolled back if the second raises an ordinary error.
Archiving two files is not atomic across a machine crash; inspect both directories after one.
Symlink inputs cannot be archived.

Watch mode creates `queue/` beside `todo/`.
It watches close-write plus moved-in events without newline filename parsing.
Existing todo files must remain unchanged for `--settle` seconds (default 5).
Stability is a heuristic: paused writers can appear complete.
For reliable producer handoff, write under a temporary name outside `todo/`, close it, then rename it into `todo/`.
Queue backlog is submitted on watcher startup.
Submission failure preserves the moved queue file for recovery.
Only one watcher may own a queue directory.
Watch overflow exits with an explicit error; restarting rescans backlog.

Dry runs perform no state writes.
They skip codec probing, so printed candidates may include AV1 files.
Watch dry runs print backlog once, then exit.

## Verification

```sh
python3.14 -m unittest discover -s tmux/bin -p 'test_*.py'
python3.14 -m unittest discover -s ffmpeg -p 'test_*.py'
```

Unit tests cover argv preservation, recovery fencing, failure holds, transaction rollback,
deduplication, context restoration, safe output publication, archive rollback and dry runs.
External command behavior is mocked where binaries are unavailable.

API references:

- [tmux manual: direct multi-argument execution and pane commands](https://man.openbsd.org/tmux.1)
- [FFmpeg codec options](https://ffmpeg.org/ffmpeg-codecs.html)
- [ffprobe structured output](https://ffmpeg.org/ffprobe.html)
