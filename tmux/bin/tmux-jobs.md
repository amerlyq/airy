## tmux-jobs stateful behavior

### Modes

- Default mode queues stdin records.
- xargs-mode runs:

tmux-jobs -j4 -- prog fixed-args...

- cmd-mode runs NUL-delimited commands through:

bash -xec "$cmd"

- -n prints decoded jobs.
- -n creates no queue, session, or log state.

### Session state

State lives under:

${XDG_CACHE_HOME:-$HOME/.cache}/tmux/<session>/

Files:

queue.txt
queue.txt.lock
inflight
success.log
failure.log
keepgoing
stop
coordinator.lock
events.fifo
sem.fifo
panes/

### Queue records

Each queued record is:

<added_ts> <cmd-args...>

added_ts is Unix seconds when enqueue occurs.

Queue writes use flock.

Queue records preserve shell-escaped command arguments.

### Coordinator

One detached coordinator runs per session.

coordinator.lock prevents duplicate coordinators.

Coordinator:

- Recovers inflight into queue.txt on startup.
- Claims queue records under flock.
- Moves claimed records to inflight.
- Starts at most -jN job panes.
- Waits for event FIFO records.
- Releases one slot per terminal job event.
- Starts one replacement job per released slot.
- Exits when queue is empty and no jobs remain.

### Running jobs

Every job gets its own tmux pane.

Pane title:

job <id>: <last-argument>

Successful panes close normally.

Failed panes stay visible until:

- ENTER is pressed.
- -c enables unattended continuation.
- -K kills them.

### Event protocol

Job panes write events to events.fifo.

Success:

<job_id> done 0 <exec_ts> <duration_s>

Failure notification:

<job_id> fail <rc> <exec_ts> <duration_s>

Failure terminal completion:

<job_id> done <rc> <exec_ts> <duration_s>

Pane death:

<job_id> dead <rc> <exec_ts> 0

exec_ts is captured immediately before command execution.

duration_s is measured by the job pane.

### Failure behavior

Default mode is interactive.

A failed pane:

- Captures pane output.
- Writes an error log.
- Writes one failure.log entry.
- Removes its record from inflight.
- Keeps its worker slot occupied.
- Waits for ENTER.
- Emits done after ENTER.
- Frees one slot.
- Allows one queued job to start.

This limits unattended failure growth to at most -jN simultaneous failed panes.

Successful jobs continue filling available slots.

### Failure logs

Success format:

<exec_ts> <duration_s> <added_ts> <cmd-args...>

Failure format:

<exec_ts> <duration_s> <added_ts> <cmd-args...>

Interrupted jobs append:

<exec_ts> <duration_s> <added_ts> <cmd-args...> rc=<rc> interrupted

### Control flags

-c:

- Enables unattended continuation.
- Unblocks all failed panes.
- Failed panes are killed after terminal event.
- Future failures continue automatically.
- Restarts coordinator if queue or inflight state remains.

-C:

- Disables unattended continuation.
- Future failures wait for ENTER.
- Existing failed panes remain governed by their current state.

-k:

- Sets graceful stop.
- Current jobs finish.
- No new queued jobs start.
- Queue remains intact.
- Inflight remains intact.
- Rerunning resumes work.

-K:

- Sets graceful stop state.
- Kills active job panes.
- Kills coordinator pane.
- Preserves queue and inflight state.
- Rerunning recovers unfinished jobs.

### Pane death

A tmux pane-died hook emits a dead event.

For interrupted jobs:

- Return code is recorded.
- Job is written to failure.log.
- Inflight record is removed.
- Slot is released.
- Job is not automatically requeued.
- User can manually add it again.

### Notifications

Failure notifications occur on failure events.

Completion notification occurs when coordinator finishes all available work.

Diagnostics print in coordinator pane:

- Job start.
- Event receipt.
- Failure.
- Completion.
- Queue depth.
- Slot state.
