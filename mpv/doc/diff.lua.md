BAD: I run 'mpv %s --external-file=%f --pause' to launch two files in mpv (original
and result of ffmpeg conversion), and then use "n" to cycle between two videos
to compare their quality and artifacts. The problem is -- the frame it shows
from two videos isn't exact, and in different timestamps of same video it may
drift by different number of frames, so exactly same frame is a rarity. How to
fix that? What to do differently?


**cause** (probably)
- not an mpv bug: 2 demuxers, 2 timelines → frames matched by pts only
- ffmpeg changed pts: fps conversion dup/drop (cfr), start_time shift (B-frame delay, edit list), timebase rounding
  → drift jumps at each dup/drop = "different number of frames at different timestamps"
- `lavfi-complex` switch rebuilds graph → flush → shows whichever frame arrives first (your "progresses on toggle" WTF)

**check first**
```
ffprobe -v error -select_streams v -show_entries stream=r_frame_rate,start_time,nb_frames -of csv=p=0 orig.mkv conv.mkv
```
- nb_frames differ → dup/drop → fix in ffmpeg, not mpv
- equal but start_time differs → constant offset → your nudge keys can fix that

**fix**, in order
1. ffmpeg side (the real fix) → 1:1 frame mapping
   - `-fps_mode passthrough` (old: `-vsync 0`), no `-r`, no `fps` filter
   - keep the original timebase/start_time where possible
2. mpv side → stop reconfiguring the graph on toggle
   - no `lavfi-complex`; `cycle vid` between tracks 1 and 2 → mpv does a refresh seek at the current pos
   - `--hr-seek=yes --hr-seek-framedrop=no`
   - untested with external files; probably exact if (1) holds
3. can't avoid dup/drop (e.g. deliberate fps change) → time-based sync is impossible
   - compare by frame index outside mpv: `select=eq(n\,N)` on both → PNG, or `blend=all_mode=difference`

**related** (expand if relevant)
- `setpts=N/FRAME_RATE/TB` rebase → breaks after seek (N isn't reset), skip
- constant `setpts` offset can't correct varying drift
- `pad` / `hstack` path has the same graph-rebuild issue on `b`
