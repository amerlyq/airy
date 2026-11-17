# Clip previews

`[` / `]` set the requested range.
Thumbnails show the selected mode's first/last decoded video frames.
Labels contain the mode and requested mark time.
They do not imply that a stream-copy boundary lands exactly on that time.

The end preview shows frame offsets `-3, -2, -1, 0, +1` by default.
`0` remains the actual last decoded output frame, not the frame at the `]` mark.
Only `0` has the mode/timestamp label; its neighbors show signed indexes.
Negative offsets come from the converted boundary sample.
Positive offsets are following source frames outside the clip, not promised export content.
Unavailable neighbors are omitted rather than duplicated (EOF, a short selection,
or a short smart-cut boundary segment).
All end frames are extracted together in one FFmpeg command per sample attempt.
The grid wraps to fit the window and keeps the OSD text line clear.

Edit `END_FRAME_RANGE = { -3, 1 }` near the top of `scripts/clip.lua` to change
the global default, or override it with the options below.
The range must include zero; each side is limited to 15 frames.

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
end_frame_first=-3
end_frame_last=1
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
  Retain the requested tail frames rather than guessing their timestamps.
  Track source timestamps during the sample conversion to locate following
  source frames without guessing FPS or confusing container timestamp offsets.

Samples normally cover two seconds.
Empty samples retry with a larger window, up to `preview_window_limit`.
Sparse end samples also expand when more preceding frames are needed.
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


=============

The log shows why the previews were wrong, and I've patched `clip.lua`; I haven't run the patch in mpv, only syntax-checked it.

**Root cause (from your log)**
- Your file has container `start_time` 0.062s, about 1.5 frames at 24 fps. mpv marks sit on the frame grid, while ffmpeg and the anchor time are `pts - 0.062`.
- `map_index` added `start` to the mark, landed half a frame off the grid, and its 0.45-frame tolerance made it return nil. Every row was then silently built from the constant-fps fallback, shifted by about 1.5 frames against the borders and `anchor`. That is the wrong beg and end.
- Converting the anchor to mpv time, every `anchor-mark` becomes a whole number of frames. Before, they were 1.5, 4.5 and so on.
- For your first export the converter emitted about 6 frames after the end mark; for the final one about 3. The old row showed only +2, so the tail was invisible.
- The first beg anchor was 99.333, exactly the mark. After you stepped one frame back, the clip still started at 99.333.

**Changes in clip.lua**
- **Shift calibration:** the shift between mpv time and pts is now calibrated once per file, choosing the container start or 0 by which fits the pts grid. Debug line: `frame map: mpv shift=...`.
- **Frame snapping:** `map_index` now picks the frame covering the time (floor), not the nearest. `etime` snaps to a frame pts even with offset 0. A half-frame mark is a seek target (your log has `Backstep failed`, so this probably happens when stepping back), and it now resolves to the frame on screen and exports at an exact frame time.
- **Fallback fix:** the fallback path now converts between the mpv and ffmpeg domains.
- **End row:** `END_FRAME_RANGE` is now `{-3, 6}`. The old `{-3, 2}` is kept as `## ALT`.
- **Overflow warning:** if the export reaches beyond the row, you get an OSD warning, `export end includes N frame(s) beyond the preview row`.
- **Debug line:** `anchor-mark` is now in mpv time and should print whole frames. If it prints `.5` again, the two domains are still mixed, so send me that log.

**Reading the borders**
- Orange frames are in the exported file but outside your marks. For beg that is the hidden preroll; for end it is the tail frames.
- Step the end offset left until the orange tail is as short as you accept.
- Expect the orange tail not to reach zero in copy mode, because `-to` cuts on DTS. Probably this tail is what makes jump-to-end briefly show 23.979s or 23.958s before settling at 23.917s: the container counts it but the player hides it. That one is a hypothesis, not confirmed.

**Not changed**
- The per-video constant for the end: ffprobe reported reorder delay 5, while your log shows about 3 to 6 extra frames depending on the mark. The log hint `reorder delay N frames` is only a ceiling.
- The layout is now 10 columns wide, so previews are smaller. If that's too small, tell me whether to shrink the beg side instead.

`diff.lua` is unchanged since my last message, with `n` leaving split for video 1.


==============

Status: the sandbox has ffmpeg, so I'm checking whether the 2-second preview sample really has the same first and last frames as the full copy export. Then I'll revert the row to `{-3, 2}`.

`clip.lua` is updated and the rows are back to `{-3, 2}`. The preview method checked out against real ffmpeg output. I have not run the new label or the map-wait change in mpv.

**Correction to my last message.** log2 shows the calibration kept shift = 0.062, so my "mpv time has no start offset" theory was wrong. The real cause in log1 was marks that were off the frame grid by half a frame. Those are seek targets after the failed frame-back-step. They made `map_index` return nil and the rows silently fell back to the constant-fps guess. In log2 the marks are on the grid and every `anchor-mark` is a whole number of frames.

**Does the preview match the file?**
- I built a synthetic H.264 file with B-frames, a GOP of 72 and an audio/video start offset. I cut it 30 times with the same `-ss`/`-to` copy command as `r.ffmpeg`.
- In all 30 runs, the first frame of the 2-second beg sample matched the first frame of the full export, and the last frame of the end sample matched the last frame of the full export.
- The copy export starts at the keyframe before your mark, and the end tail was 1–5 frames, varying with the mark. That matches your 1–3, rarely 5.
- So the boundary shown in the preview is the real one, as long as the mark is a real frame.

**Stepping.** The offset keys step through real source frames: the row moves exactly one frame per press. The tail frame count jumps in packet steps; I think that is the DTS cut, and the synthetic test agrees. The border colours show it:
- Green is the "0" frame (your mark).
- Orange is in the file but outside your marks.
- Blue is not in the file.
- Nothing is dimmed.

**New in `clip.lua`:**
- **"in file" label:** the "0" frame now carries an orange `in file: +N` (end) or `in file: -N` (beg) in its top-left corner. N is the number of frames the export holds outside your marks, and it is exact even when more frames exist than the 6-column row can draw. The goal is `+0` on the end and no unwanted preroll on the beg.
- **Warning:** the OSD warning appears only when the row can't show all of them.
- **Wait for the frame map:** previews now wait for the ffprobe frame map before rendering. The first row in log2 was drawn from the constant-fps guess and then re-drawn about 1.5 frames shifted once the map arrived. If ffprobe fails, or the file is a URL, it falls back to the guess as before.
- **Speed:** unchanged. The converter plan only runs on the 2-second window, and the preview is 6 decoded frames.

**One thing worth checking.** In log2 your final end mark 123.229333 still has `+1` extra frame, 123.271, which is the first frame of the next clip. Step the end one frame left and watch whether the label drops to `in file: +0`.
