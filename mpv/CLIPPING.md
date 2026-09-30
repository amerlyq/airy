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

Pressing an export key for a different mode first switches previews.
Press it again after reviewing both ends to export.
Export is blocked while either preview is missing or failed.
An existing pair of visible previews in that mode allows immediate export.
Exports run asynchronously.

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
Resize reuses cached pixels.
An unavailable layout hides previews and blocks export until layout returns.
Failed conversion jobs do not restart on resize.
Change a mark or select a preview mode explicitly to retry.
File changes and clearing previews invalidate pending callbacks.
Completion of an older export does not clear a newer selection.

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
