# Task 6 Report: Origin-Owned Construction During a Held Gesture

## Result

Task 6 is complete on `feature/live-gesture-path-reflow`. The tested implementation
HEAD is `be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f`. The full automated gate passed
with Godot `4.7.1.stable.official.a13da4feb`: `PASS: 19 prototype test suite(s)`
plus all four registered standalone integrations. Sol approved the specification and
quality reviews. The user then manually passed the active-gesture construction case
at the same tested HEAD.

The feature branch is not yet ready for main integration: the final clean gate and
remaining review are pending while the separate leak diagnostic is open. This report
does not claim push, pull request, merge, primary-main retest, or worktree cleanup.

## Diagnosis

The manual failure was a domain-state pause, not a presentation-only pause. The
session tick first applies the held endpoint input, then calls construction advance,
then continues through the existing train/recovery lifecycle. Before Task 6,
`GridTrackRuntime.advance_construction` returned `0.0` whenever `_gesture_active` was
true (`grid_track_runtime.gd`, the active-gesture guard around the former lines
454-456). Therefore a fresh held endpoint extension left the already-reserved route's
`BUILT`/`BUILDING` state and build progress unchanged on every tick. The view merely
drew the unchanged domain snapshot: `TrackFieldView` copied record state/progress and
rendered `BUILT` as solid geometry and `BUILDING` as the progressive built prefix.

The existing guard intentionally paused both construction and recovery during a held
gesture. Existing tests asserted that behavior, so they could not detect the new
requirement that already-reserved route work must continue while the endpoint geometry
is being edited.

## Canonical contract

The canonical design and plan now define a route-identity construction frontier:

- Construction may advance only route serials present in both the detached
  gesture-origin sequence and the current candidate.
- The frontier includes serials inside an editable completed-head template. Template
  replacement may reflow cells or geometry while retaining those route serials.
- Every changed origin-owned serial mirrors its exact state and build progress into
  the current candidate and gesture origin before the next held update.
- Gesture-added suffix serials absent from the origin remain `RESERVED_GHOST` with
  progress `0.0` until finalization, even when the construction input budget exceeds
  the remaining origin work.
- Existing construction rate/order, inventory accounting, geometry locks, ledger
  semantics, train preparation/sampling order, and paused recovery remain unchanged.

The canonical documentation amendments were committed as:

- `3278bf3` — define the origin-owned construction frontier.
- `bb37c30` — tighten held construction evidence and add Task 6.
- `faaefbf` — track the expanded evidence set through evidence 17-19.

## TDD RED evidence

The focused RED reproduced the old guard's behavior. A two-cell origin route was
advanced by `1.5`, leaving the second origin serial `BUILDING` at `0.5`. A held
endpoint update added one suffix serial. Calling `advance_construction(0.5)` while
the gesture remained active was expected to consume `0.5` and complete the origin
serial, but the old implementation returned `0.0` and left the frontier unchanged.

The correction RED matrix also required an oversized budget: when only `0.5`
remained on the origin route, `advance_construction(2.0)` had to return exactly
`0.5`; the remaining `1.5` could not build the suffix, which had to remain
`RESERVED_GHOST` at progress `0.0`. Longer fixtures crossed multiple origin serial
boundaries and required route order and configured rate preservation. Additional RED
expectations covered editable-template reflow, exact serial maps, abort/finalize,
rejected updates, inventory and lock/ledger stability, causal session ordering, and
active-gesture train sampling.

## Implementation and correction rounds

The implementation/fix commits were:

- `87f63e0` — advance construction through origin-owned serials during an active
  gesture, mirror state/progress into origin and candidate, and add focused lifecycle
  and real-input evidence.
- `271e874` — tighten serial-map, reflow, rejection, abort/finalize, inventory,
  lock/ledger, session-order, and train-sampling evidence.
- `be18f1f` — enforce exact candidate/origin consumed-progress continuity so a
  mismatch cannot publish a partially mirrored construction state.

The runtime correction keeps recovery paused during active capture. It advances only
the shared origin frontier, returns only progress consumed by that frontier, and
leaves leftover budget unapplied to gesture-added suffixes. Existing train
preparation behavior remains authoritative: overlapping active gesture geometry is
terminated before immutable sampling, while non-overlapping preparation preserves the
active capture and locks only complete geometry pieces.

## Automated verification

At tested HEAD `be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f`:

- Godot `4.7.1.stable.official.a13da4feb`.
- Full `res://tests/run_all.gd`: exit `0`, `PASS: 19 prototype test suite(s)`.
- All four standalone integrations exited `0`:
  `run_session_shell_integration.gd`, `run_logical_track_field_integration.gd`,
  `run_track_train_input_integration.gd`, and `run_track_train_app_integration.gd`.
- Focused evidence covered origin-frontier progress, oversized-budget cutoff,
  multiple serial boundaries, editable-template reflow, exact origin/current maps,
  rejected-update retention, abort/finalize state, paused recovery, unchanged
  inventory and lock/ledger observations, causal input-to-construction-to-train
  order, and active-gesture train sampling behavior.

## Review and manual acceptance

Sol approved both the independent specification review and quality review for Task 6.
The user manual PASS at tested HEAD `be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f`
confirmed the intended visible behavior: after releasing a track gesture, the user
started a new held endpoint extension while construction was still progressing;
already-reserved route records continued solidifying visibly from the rear, while the
newly dragged suffix remained a ghost until release. The manual run used Godot
`4.7.1.stable.official.a13da4feb`.

The user also verified that rear recovery remained paused while the left-button
extension was held and resumed after release under the existing session lifecycle.
This recovery pause/resume observation is manual evidence for the preserved lifecycle
contract, not a claim that the separate leak diagnostic is closed.

No user-owned editor was terminated, reset, or interacted with. The detailed dated
manual evidence is recorded in
`godot-project-moe-rail-way/tests/manual/track_train_windows.md`.

## Task 6 allowlist

The implementation correction was limited to the planned runtime and five test paths:

- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`

This report, the progress ledger, the canonical design, and the manual record are
evidence/status artifacts only. Main integration and publication remain separate
approval gates.
