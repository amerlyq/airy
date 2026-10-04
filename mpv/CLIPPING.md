# Clip previews

`[` / `]` set the requested range.
Thumbnails show the selected mode's first/last decoded video frames.
Labels contain the mode and requested mark time.
They do not imply that a stream-copy boundary lands exactly on that time.

| Key | Mode |
| --- | --- |
| `y` | copy |
| `Y` | smart |
| `Ctrl+y` | fast (Intel QSV) |
| `Alt+y` | cycle preview mode without exporting |

Each export key starts conversion immediately in its requested mode.
Preview generation never consumes or blocks an export request.
An unmarked beginning defaults to zero, unless restored from watch-later.
Use `Alt+y` to select the preview mode separately when reviewing endpoints.
Exports run asynchronously; repeated keys cannot submit duplicate active exports.
`ENCODING` means conversion started, not completion.
Blue `DONE` appears only after the converter exits successfully.
Errors appear in red.
Conversion failure retains the current previews.
`;` toggles OSC visibility through the preview handler.
Previews follow OSC's `never`/`always` visibility state.
One OSD text line is reserved above previews because bitmap overlays cover text.
Long diagnostic messages are shortened on screen; full details remain in the log.

`clip.lua` invokes `ffmpeg/run --preview-plan` through `r.ffmpeg`.
The planner uses the same codec/filter/muxer arguments as export.
It emits argv vectors rather than shell commands.

For a different installation, set this in `script-opts/clip.conf`:

```ini
converter=/data/aura/airy/ffmpeg/run
preview_mode=copy
preview_window_limit=30
```

Preview strategy:

- Copy: remux a short boundary window into the export's container.
  Preserve its automatic stream selection, including audio's timestamp effects.
- Fast: encode a short boundary window with the export's QSV settings.
- Smart: determine which operation owns each boundary in the full selection.
  Preview that operation rather than smart-cutting an unrelated short selection.
  Probe nearby keyframe packets without decoding the complete source.
- Decode the sample's first frame for A.
  Decode through sample EOF for B, including reordered/delayed frames.
  Retain only the last frame rather than guessing its timestamp.

Samples normally cover two seconds.
Empty samples retry with a larger window, up to `preview_window_limit`.
Decoding still needs the preceding keyframe for inter-frame codecs.
No whole-selection re-encode is performed to make previews of a long selection.

Copy previews can be compared pixel-for-pixel with the export.
Lossy previews preserve boundary frame selection.
Their compression can differ because short encodes have different rate-control history.
Smart concatenation still relies on source-compatible codec parameters.
Previewing endpoints does not validate every internal splice or audio continuity.
Smart mode rejects multiple video/audio streams instead of combining ambiguous probe results.
Fast mode reports QSV failures; it does not silently substitute software encoding.

Each pending job has private temporary files.
Mark changes immediately cancel obsolete work.
Only the affected boundary sample is rebuilt for ordinary copy/fast ranges.
Short ranges can affect both samples.
Smart mode rechecks the opposite boundary's conversion plan without removing its
image; an identical plan reuses the frame instead of encoding it again.
Resize reuses cached pixels.
An unavailable layout hides previews but does not block export.
Failed conversion jobs do not restart on resize.
Change a mark or select a preview mode explicitly to retry.
File changes and clearing previews invalidate pending callbacks.
Completion of an older export does not clear a newer selection.

## Scene navigation

`PgDn` searches forward from the current position.
`PgUp` searches backward for the nearest earlier boundary.
Press the same key again to cancel.
Press the opposite key to change direction from the displayed position.
Each detected boundary lands on the first frame of the new scene.
Playback remains paused.

Scanning uses a separate software-decoded FFmpeg process.
It does not change mpv's hardware decoding, video filters, speed, or mute state.
Every decoded frame is inspected at reduced spatial resolution.
Eight-second windows continue until a boundary or file endpoint is reached.
The displayed position advances between windows without playing audio.
Keyframe preroll is decoded to avoid losing transitions at window seams.
No clip is encoded or saved.
Only local files with a selected internal video track are supported.

Optional `script-opts/sceneseeker.conf`:

```ini
ffmpeg=ffmpeg
threshold=12
window=8
```

`threshold` is FFmpeg's `select` scene score multiplied by 100.
Lower values detect smaller image changes but can stop on motion or flashes.
Detection is heuristic; it does not guarantee every editorial cut.

## Verification

```sh
python3 -m unittest discover -s mpv/tests -v
CLIP_TEST_QSV=1 python3 -m unittest discover -s mpv/tests -v
```

Requires `ffmpeg`, `ffprobe`, `jq`, and Lua on `PATH`.
H.264 smart tests require `libx264`.
QSV tests require a working Intel GPU/driver.
The Lua harness exercises callback ordering without a display server.
Media tests compare real full exports with the generated boundary previews.
Scene tests cover known cuts, long GOPs, multiple windows, offset timestamps,
variable frame rates, direction changes, cancellation, and stale callbacks.
