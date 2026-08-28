# Task 5 Report: Coalesced Release Ordering and Template Replay

## Result

Current feature HEAD is `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239`, with the initial correction and both review rounds complete. The current final automated gate at this HEAD passed Godot `4.7.1.stable.official.a13da4feb`, all 19 prototype suites, all four standalone integrations, and the three current input-integration markers exactly once.

The initial automated Task 5 correction was committed on historical pre-review HEAD `85e579c2a64d05147d262f6ae320461259c11009` with commit subject:

```text
fix: order coalesced release and fresh press
```

No manual acceptance, status restoration, canonical design document, ledger, or primary-worktree change was performed.

## Current final automated gate (HEAD `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239`)

- Godot `4.7.1.stable.official.a13da4feb`.
- Full `res://tests/run_all.gd`: exit `0`, `PASS: 19 prototype test suite(s)`.
- `run_session_shell_integration.gd`, `run_logical_track_field_integration.gd`, `run_track_train_input_integration.gd`, and `run_track_train_app_integration.gd`: each exit `0`.
- Current input markers, each exactly once: `PASS: live ordinary ghost survives pending release fresh press`; `PASS: completed-template replay is idempotent`; `PASS: active outside release orders old finalize and fresh begin`.
- `git status` and `git diff --check` are clean; the report remains ignored and is not a tracked change.

## Initial Task 5 RED baseline (pre-correction)

The initial Task 5 RED work started from HEAD `f91f1c5993b5fb9ea1349a960be9b11a348cf2ba`. The failures below are pre-fix results and are not current gate results.

## RED evidence

The new causal tests were added before production edits. The pre-correction focused runs failed on the intended missing contracts:

- the view snapshot had no `has_explicit_release_snapshot` discriminator and no detached release buffer;
- the synthetic future-fact constructor call was rejected by the legacy twelve-argument constructor;
- the runtime replay case had no template-selection signature and therefore could not prove idempotence.

The first RED run also exposed the expected cascading fixture failures caused by the absent constructor interface. After the constructor-compatible test helper was isolated, the failures were limited to the missing release snapshot and replay behavior. The later correction and review-round results are reported separately below.

## Interface and algorithm

`TrackInputFrame` appends three optional constructor arguments after the existing live-path argument:

1. `release_live_gesture_path_value: Variant = null`
2. `left_release_pointer_cell_value: Vector2i = Vector2i(-1, -1)`
3. `left_release_pointer_inside_grid_value: bool = false`

`null` is the legacy discriminator; a typed empty array is an explicit empty release snapshot. The frame owns detached copies of both live and release arrays and exposes `has_explicit_release_snapshot`.

`TrackFieldView` snapshots the old release path and pointer immediately after release rasterization, before a fresh press clears active buffers. `consume_input_frame()` transfers both detached snapshots and clears the view release buffer. Abort, snapshot termination, completion, and consumed release paths clear live and release buffers; physical `_left_held` remains governed by the real release event.

`TrackSystem` first handles any latched old release. An active old runtime consumes explicit release facts, including an explicit empty path via `gesture_update([])` with the explicit release pointer, restoring the old gesture's origin before `gesture_finalize()`; no geometry is invented. Legacy ordinary releases preserve the old last-valid update behavior when facts exist, while a legacy combined release/fresh-held frame never routes fresh facts to the old runtime. Inactive, rejected, and train-terminated old state ignores geometry but clears its latch. The fresh press/begin/update phase runs only after this old phase.

`GridTrackRuntime` stores a detached `(live_path, current_pointer_cell)` signature only after a successful origin-equal, absent-target template change. Every subsequent identical snapshot still rebuilds, resolves, validates, and publishes through the normal transaction; the signature only suppresses implicit-origin suffix facts. A changed path or pointer can extend under the same selected template, and returning exactly to the signature reconciles the suffix away. Template-selection precedence and most-recent in-array target behavior remain unchanged; gesture cleanup clears the signature.

## Historical verification (initial correction at `85e579c2a64d05147d262f6ae320461259c11009`; pre-review)

These focused and full-gate results belong to the initial correction before Fix rounds 1 and 2. They are retained as historical evidence; the current final gate is recorded above and again below.

Godot version at that historical run: `4.7.1.stable.official.a13da4feb`.

Focused GREEN commands:

- `res://tests/run_all.gd -- --suite=test_track_field_view_input.gd` — exit `0`, `PASS: 1 prototype test suite(s)`.
- `res://tests/run_all.gd -- --suite=test_track_system_reservation.gd` — exit `0`, `PASS: 1 prototype test suite(s)`.
- `res://tests/run_all.gd -- --suite=test_grid_track_runtime.gd` — exit `0`, `PASS: 1 prototype test suite(s)`.
- `res://tests/integration/run_track_train_input_integration.gd` — exit `0`.

Complete regression gate:

- `res://tests/run_all.gd` — exit `0`, `PASS: 19 prototype test suite(s)`.
- `run_session_shell_integration.gd` — exit `0`.
- `run_logical_track_field_integration.gd` — exit `0`.
- `run_track_train_input_integration.gd` — exit `0`.
- `run_track_train_app_integration.gd` — exit `0`.

The input integration emitted these required markers exactly once each:

- `PASS: live ordinary ghost survives pending release fresh press` — count `1`.
- `PASS: completed-template replay is idempotent` — count `1`.

The integration uses real `InputEventMouseButton`/`InputEventMouseMotion` delivery for release A to B, fresh press at B, follow-up held input, explicit empty/outside release, and completed-template replay.

## Exact changed paths

Only the eight Task 5 allowlisted paths were staged and committed:

- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`

`git diff --check` and the staged-path equality check passed before commit. The report itself is intentionally not part of the correction commit because Step 7 requires the staged set to equal the eight-file correction allowlist.

## Concerns and follow-up gates

- Manual Godot acceptance remains outstanding by instruction, including the ordinary figure sequence, RUNNING recovery, and terminal input lock.
- Specification and quality reviews remain separate Task 5 Step 8 gates.
- No canonical document amendment is required for this implementation; the existing Task 5 brief and amended design/plan already describe the interface and ordering contract. Manual/status evidence should be added only after the separate review and acceptance gates pass.

## Fix round 1: specification review findings

The specification review identified five evidence/compliance gaps. All were addressed within the same eight-file allowlist.

### RED

- With the empty-release guard restored, `test_track_system_reservation.gd` failed two causal assertions: the explicit empty release left the old endpoint stale, so the fresh press from the resulting origin did not capture or remain active.
- The replay test now asserts removal of the actually appended `(3,2)` suffix and inserts a resolver-rejection probe between identical snapshots. An early-return replay cache would fail this probe because it would return success without consulting validation.
- The real input integration now drives an origin-equal absent-target template change, identical replay, changed pointer/path extension, and return to the exact signature before release. Marker emission is conditional on all substantive states.
- The real input integration also routes an explicit empty release plus fresh press through an active runtime, and separately verifies an explicit outside release snapshot.
- View tests assert that non-release frames have `has_explicit_release_snapshot == false`; release frames retain the true discriminator.

### GREEN and full gate

The empty release now always calls old `gesture_update([])` before finalize. The resulting origin endpoint is authoritative for the fresh press. Focused suites all exited `0` with `PASS: 1 prototype test suite(s)`, and the track/train input integration exited `0`.

The complete rerun used Godot `4.7.1.stable.official.a13da4feb`: `PASS: 19 prototype test suite(s)` with exit `0`; session-shell, logical-field, track/train-input, and track/train-app standalone integrations each exited `0`. The coalesced and replay markers each occurred exactly once.

Fix round 1 is committed as `fix: honor empty release and replay evidence` at `b234bf2b13ce48a5f5724547f3a197a4584dcc05`. Manual acceptance and Step 8 reviews remain separate gates.

## Fix round 2: causal legacy and outside-release evidence

The scoped quality re-review identified two remaining evidence gaps. This round changes only the existing allowlisted tests and this ignored report.

### RED

- The pre-round-2 production/test baseline at `b234bf2b13ce48a5f5724547f3a197a4584dcc05` was behaviorally green, but was an evidence RED: the legacy final-record assertion could not distinguish wrong phase order, and the outside-release check never routed an active runtime. Because the reviewed production behavior was accepted, this round required no production-defect RED or production edit.
- The pre-round-2 legacy test asserted only final records, so a runtime could receive the fresh path before old finalization without being distinguished. The new capturing runtime fixture records phase, path, pointer, and pre-begin facade capture; its causal assertions were added and the focused reservation suite was rerun as the RED/GREEN checkpoint.
- The prior outside-release integration consumed an inactive view frame only. The new sequence seeds an active old runtime, delivers actual outside release events, coalesces a fresh press at the old origin and adjacent motion, and gates a substantive ordered result.

### GREEN and evidence

- `test_track_system_reservation.gd` now separately proves valid legacy construction, false release discriminator, old-path-only update, old finalize, old capture cleared before fresh begin, fresh begin at the finalized origin, and fresh path/pointer update with active/published state.
- `run_track_train_input_integration.gd` now routes actual `InputEventMouseButton` outside press/release plus fresh press/motion through an active `TrackSystem`; explicit empty release restores the old origin, invents no old cells, finalizes, and leaves the fresh gesture active. It emits `PASS: active outside release orders old finalize and fresh begin` exactly once.
- The template replay integration additionally asserts that the runtime recorded the origin-equal selection signature before identical replay, while preserving changed-motion extension and return-to-signature suffix removal.

Fix round 2 was committed as `test: prove legacy and outside release ordering` at `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239`. Manual acceptance, canonical documentation, and Step 8 review remain separate gates.

### Post-commit final gate

- Godot `4.7.1.stable.official.a13da4feb`, full `res://tests/run_all.gd` — exit `0`, `PASS: 19 prototype test suite(s)`.
- `run_session_shell_integration.gd`, `run_logical_track_field_integration.gd`, `run_track_train_input_integration.gd`, and `run_track_train_app_integration.gd` — each exit `0`.
- The input integration markers `PASS: live ordinary ghost survives pending release fresh press`, `PASS: completed-template replay is idempotent`, and `PASS: active outside release orders old finalize and fresh begin` each occurred exactly once.
- `git diff --check` passed; the commit staged exactly the two changed allowlisted test paths. The report remains ignored and unstaged by design.

## Final manual and review completion evidence — 2026-08-28

The earlier statements that manual acceptance and the scoped review remained
outstanding are historical statements for the earlier Task 5 checkpoints. They are
superseded for current status by the reviewed final evidence below without removing
the original RED and gate history.

At tested HEAD `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239`, the user explicitly
reported PASS for all three Task 5 acceptance groups: release A to fresh press B
ordering, completed-template replay idempotence, and the prior ordinary/RUNNING
recovery/terminal cases. Existing exact numeric evidence remains authoritative:
`18/18 -> 3/18 -> 18/18` at the press origin, equal-length rebranch `14/18 ->
14/18`, and the 18-cell/13-straight recovery sequence leaving 7 visible records at
`TRACK 11/18` before the direct endpoint drag produced 8 records at `TRACK 10/18`.
`SESSION COMPLETE — TRACK END REACHED` remained input-locked.

Sol approved the final Task 5 specification and quality reviews. The Task 5 scoped
implementation, review, and manual evidence are complete. The final clean gate and
any remaining review are still pending while the separate leak diagnostic is open;
main integration, publication, and primary-main retest remain pending.
