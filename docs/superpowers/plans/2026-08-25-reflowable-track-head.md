# Reflowable Track-Head Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a five-record reflowable track head that keeps completed track solid, locks only deterministic whole pieces, and never changes geometry sampled by the train.

**Architecture:** Keep ordered route records and construction state independent from geometry state. `GridTrackRuntime` owns atomic reflow, immutable ledger preparation, exit-support dependencies, anchors, canonical distance ownership, and all geometry sampling; `TrackSystem` is its facade. `TrainSystem` owns nominal motion and the single pose-pair helper, while `SessionController` owns fixed-tick ordering, safe-return behavior, and snapshot/event publication.

**Tech Stack:** Godot 4.7.1, GDScript, custom `prototype_test.gd` unit suites, headless Godot scripts, Windows PowerShell.

**Spec:** `docs/superpowers/specs/2026-08-25-reflowable-track-head-design.md`

## Global Constraints

- Feature branch: `feature/reflowable-track-head`; feature worktree: `D:\godot\MoeRailWay-worktrees\feature-reflowable-track-head`.
- Primary workspace: `D:\godot\MoeRailWay`; never edit, stage, format, stash, reset, switch, or terminate a user-owned process there.
- Verified feature base: `fd5f87553556bf3ac7035bc5ae4a0995e37edbb5`; approved-design/current feature start: `0acb916b886484b8e41160373f0508142caad7a2`.
- Godot console executable: `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`; required version: `4.7.1.stable.official.a13da4feb`.
- The baseline is `PASS: 19 prototype test suite(s)` plus four standalone integrations: session-shell, logical-track-field, track-train-input, and track-train-app.
- Preserve one train, one endpoint-only route, integer inventory conservation, sequential construction/recovery, route serial identity, absolute nominal distance, deterministic curve downgrade, anchors, nominal motion, fixed-tick end priority, and random finite-lifetime warp-point premises.
- Do not add rerolls, reachability correction, route-aware warp RNG, branches, merges, pathfinding, pause/reverse, another train, production abstractions, or provisional/ghost styling. `RESERVED_GHOST`, `BUILDING`, and `BUILT` remain the only construction-driven visual states.
- Keep `SessionResult` reason-only. Do not modify `src/domain/session/session_result.gd` and do not add train pose to it.
- Do not add a script unless a task explicitly needs one. If a script is added or renamed, add and track its matching `.gd.uid`; this plan expects no new scripts.
- Terra writes and repairs every implementation, test, documentation, and other repository output. Sol performs independent code, specification, and quality reviews only. Each review correction is assigned to a fresh Terra output worker; Sol never applies repository edits. Reviews are process gates, not repository files. Execute this approved plan with `superpowers:subagent-driven-development`; do not ask for another execution-mode choice.

---

## Repository Map and Shared Interfaces

| Path | Responsibility after this feature |
|---|---|
| `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd` | Route transactions, five-record whole-piece horizon, immutable ledger, exit-support metadata, anchors, canonical boundary ownership, preparation, active geometry sampling. |
| `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd` | Ordered cell records, inventory, construction state, suffix removal; construction no longer sets geometry locks. |
| `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd` | Detached immutable piece values, including `exit_support_route_serial`. |
| `godot-project-moe-rail-way/src/domain/track/track_system.gd` | Domain facade forwarding preparation and canonical position/heading sampling. |
| `godot-project-moe-rail-way/src/domain/train/train_system.gd` | Nominal motion, activation-only departure, authoritative `{ position, heading }` pose capture. |
| `godot-project-moe-rail-way/src/domain/session/session_controller.gd` | Fixed tick, safe abort on failed prepare, pre-recovery pose cache, snapshot before completion result. |
| `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd` | Construction-state-only rendering and metadata-derived cancellation hover suppression. |
| `godot-project-moe-rail-way/tests/run_all.gd` | Registered 19-suite gate plus test-only `--suite=<file>`, unknown-suite, and unprepared-pose probe dispatch. |

The implementation must expose these exact interfaces before later tasks use them: `TrackGeometryPiece.exit_support_route_serial: int = -1`; `GridTrackRuntime.NOMINAL_BOUNDARY_EPSILON := 0.0001`, `prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool`, `get_pose_sample_at_distance(route_distance: float) -> Dictionary`, and domain-only `is_exit_support_route_serial(route_serial: int) -> bool`; `TrackSystem.prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool` and `TrackSystem.get_pose_sample_at_distance(route_distance: float) -> Dictionary`; and `TrainSystem.capture_pose(track_system: TrackSystemScript) -> Dictionary`. `TrackSystem` does not forward exit-support eligibility: presentation reads detached piece metadata, while runtime owns cancellation decisions. The two pose dictionaries have exactly `position: Vector2` and `heading: Vector2` entries.

## Command Setup

Run all commands from `D:\godot\MoeRailWay-worktrees\feature-reflowable-track-head` unless a command explicitly uses `-C D:\godot\MoeRailWay`.

```powershell
$ReflowGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$ReflowProject = '.\godot-project-moe-rail-way'
$ReflowFailurePattern = '(?m)^(?:FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)'
function Invoke-ReflowScript([string]$Script, [string]$ExpectedPass, [string[]]$UserArgs = @()) {
    $output = (& $ReflowGodot --headless --path $ReflowProject --script $Script -- @UserArgs 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    Write-Host $output
    if ($exitCode -ne 0) { throw "Godot failed ($exitCode): $Script" }
    if ($output -match $ReflowFailurePattern) { throw "Failure diagnostic in $Script" }
    if ([regex]::Matches($output, [regex]::Escape($ExpectedPass)).Count -ne 1) {
        throw "Expected exactly one marker '$ExpectedPass' from $Script"
    }
}
function Invoke-ReflowFocused([string]$Suite) {
    Invoke-ReflowScript 'res://tests/run_all.gd' 'PASS: 1 prototype test suite(s)' @("--suite=$Suite")
}
function Confirm-ReflowRedFocused([string]$Suite, [string]$ExpectedFailure) {
    $output = (& $ReflowGodot --headless --path $ReflowProject --script res://tests/run_all.gd -- "--suite=$Suite" 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    Write-Host $output
    if ($exitCode -eq 0) { throw "RED suite unexpectedly passed: $Suite" }
    if ($output -notmatch [regex]::Escape($ExpectedFailure)) { throw "RED evidence missing '$ExpectedFailure': $Suite" }
}
function Invoke-ReflowFullGate {
    $gates = @(
        @{ Script = 'res://tests/run_all.gd'; Pass = 'PASS: 19 prototype test suite(s)' },
        @{ Script = 'res://tests/integration/run_session_shell_integration.gd'; Pass = 'PASS: session shell lifecycle integration' },
        @{ Script = 'res://tests/integration/run_logical_track_field_integration.gd'; Pass = 'PASS: logical track field integration' },
        @{ Script = 'res://tests/integration/run_track_train_input_integration.gd'; Pass = 'PASS: track train input integration' },
        @{ Script = 'res://tests/integration/run_track_train_app_integration.gd'; Pass = 'PASS: track train app integration' }
    )
    foreach ($gate in $gates) {
        Invoke-ReflowScript $gate.Script $gate.Pass
    }
}
function Confirm-ReflowUnknownSuite {
    $output = (& $ReflowGodot --headless --path $ReflowProject --script res://tests/run_all.gd -- --suite=does-not-exist.gd 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    Write-Host $output
    if ($exitCode -eq 0 -or $output -notmatch 'Unknown prototype suite: does-not-exist.gd') {
        throw 'Unknown-suite selector did not reject its intentional invalid request'
    }
}
function Confirm-ReflowUnpreparedPoseProbe {
    $output = (& $ReflowGodot --headless --path $ReflowProject --script res://tests/run_all.gd -- --reflow-unprepared-pose-probe 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    Write-Host $output
    if ($exitCode -eq 0) { throw 'Unprepared pose probe unexpectedly succeeded' }
    if ($output -notmatch 'Locked geometry is required for pose sampling') {
        throw 'Unprepared pose probe did not report the exact locked-owner diagnostic'
    }
    if ($output -match 'POSE_FALLBACK') { throw 'Unprepared pose probe took a fallback sample' }
}
```

The expected full-gate anchors are exactly:

```text
PASS: 19 prototype test suite(s)
PASS: session shell lifecycle integration
PASS: logical track field integration
PASS: track train input integration
PASS: track train app integration
```

## Mandatory Non-Mutating Preflight

Run this before any implementation edit. It reads status and refs only; it must stop on any mismatch and must not attempt to clear primary changes.

```powershell
$Primary = 'D:\godot\MoeRailWay'
$Feature = 'D:\godot\MoeRailWay-worktrees\feature-reflowable-track-head'
$Base = 'fd5f87553556bf3ac7035bc5ae4a0995e37edbb5'
$FeatureStart = '0acb916b886484b8e41160373f0508142caad7a2'
$ExpectedGodot = '4.7.1.stable.official.a13da4feb'
function Normalize-ReflowPath([string]$value) {
    return [IO.Path]::GetFullPath(($value -replace '/', '\')).TrimEnd('\')
}
$FeaturePath = Normalize-ReflowPath ((Resolve-Path -LiteralPath $Feature).Path)

if ((git -C $Primary branch --show-current).Trim() -ne 'main') { throw 'STOP: primary is not main' }
if ((git -C $Primary status --porcelain=v1 -uall)) { throw 'STOP: primary is dirty or untracked' }
if ((git -C $Primary rev-parse --abbrev-ref '@{upstream}').Trim() -ne 'origin/main') { throw 'STOP: primary upstream is not origin/main' }
if ((git -C $Primary rev-parse HEAD).Trim() -ne $Base) { throw 'STOP: primary HEAD differs from pinned base' }
if ((git -C $Primary rev-parse origin/main).Trim() -ne $Base) { throw 'STOP: origin/main differs from pinned base' }
if ((git -C $Feature branch --show-current).Trim() -ne 'feature/reflowable-track-head') { throw 'STOP: feature branch mismatch' }
if ((Normalize-ReflowPath (git -C $Feature rev-parse --show-toplevel).Trim()) -ne $FeaturePath) { throw 'STOP: feature toplevel path mismatch' }
git -C $Feature merge-base --is-ancestor $Base HEAD
if ($LASTEXITCODE -ne 0) { throw 'STOP: feature is not based on pinned main' }
git -C $Feature merge-base --is-ancestor $FeatureStart HEAD
if ($LASTEXITCODE -ne 0) { throw 'STOP: approved design start is not in feature history' }
if ((git -C $Feature status --porcelain=v1 -uall)) { throw 'STOP: feature worktree is not clean' }
if ((& $ReflowGodot --version).Trim() -ne $ExpectedGodot) { throw 'STOP: Godot version mismatch' }
$worktree_porcelain = (git worktree list --porcelain | Out-String)
$worktree_entries = $worktree_porcelain -split "(?:\r?\n){2,}" | Where-Object { $_.Trim().Length -gt 0 }
$expected_worktree = $worktree_entries | Where-Object {
	$worktree_line = ($_ -split "\r?\n" | Where-Object { $_.StartsWith('worktree ') } | Select-Object -First 1)
	$worktree_line -and (Normalize-ReflowPath $worktree_line.Substring('worktree '.Length)) -eq $FeaturePath
}
if ($expected_worktree.Count -ne 1) { throw 'STOP: feature worktree entry is missing or duplicated' }
$expected_lines = $expected_worktree -split "\r?\n"
if ($expected_lines -notcontains 'branch refs/heads/feature/reflowable-track-head') { throw 'STOP: feature worktree branch entry mismatch' }
Write-Host $expected_worktree
```

Expected: primary is clean `main` at the pinned base, feature is clean on the pinned branch with both required ancestors, and Godot prints the required version. On any `STOP`, report the observed field and exit without modifying primary or feature state.

---

### Task 1: Atomic Reflow Horizon, Ledger, Support, and Construction Decoupling

**Files:**

- Modify: `godot-project-moe-rail-way/tests/run_all.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- Modify: `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`

**Interfaces:**

- Consumes: existing `TrackCellRecord.State`, `TrackCellSequence.start_building(route_serial)`, and `GridTrackRuntime.advance_construction(progress_cells)`.
- Produces: a focused suite selector, construction transitions that never lock geometry, a maximum-five whole-piece horizon, immutable ledger/support metadata, and atomic append/cancel transactions. This entire task commits only after all legacy construction/recovery tests use horizon-locked fixtures and the full gate is green.

**Same-commit fresh-Terra checkpoints:**

- **1A — selector and RED fixtures:** a fresh Terra worker inspects the clean Task 1 start, adds the focused-selector contract and construction/horizon/anchor/recovery test fixtures, and records only the specified RED evidence. It does not stage, commit, request review, or leave the Task 1 allowlist.
- **1B — clone, candidate, horizon, and support core:** a second fresh Terra worker first inspects 1A's inherited uncommitted diff, implements construction/geometry decoupling plus detached sequence/ledger candidate resolution, precommit validation, whole-piece horizon, and support metadata, then runs focused diagnostics. It does not stage, commit, or review.
- **1C — cancellation/recovery/anchor protection and green:** a third fresh Terra worker inspects the complete inherited Task 1 diff, completes cancellation and recovery transactions, runs the moved anchor regressions and exact legacy migrations, then runs the Task 1 focused/full gate, stages the Task 1 allowlist, creates the only Task 1 commit, and obtains both Sol reviews.

These checkpoints deliberately share one uncommitted Task 1 diff: removing construction locking cannot independently pass legacy recovery tests before replacement ledger locking exists. Fresh workers limit context while the single final commit preserves the required atomic, independently-green Task 1 boundary.

- [ ] **Step 1: Write the failing tests and selector contract**

Add the focused selector to `tests/run_all.gd`. In `test_track_cell_sequence.gd`, add `_test_start_building_does_not_lock_geometry()` to `run()` immediately before `return finish()`. In `test_grid_track_runtime.gd`, add `_test_built_head_reflows_without_geometry_lock()` and `_test_twenty_construction_steps_keep_completed_head_reflowable()` immediately before `return finish()`. The new selector must fail with a readable error when no registered suite file matches.

```gdscript
# test_track_cell_sequence.gd, run(): append before return finish().
_test_start_building_does_not_lock_geometry()

# test_grid_track_runtime.gd, run(): append before return finish().
_test_built_head_reflows_without_geometry_lock()
_test_twenty_construction_steps_keep_completed_head_reflowable()
```

```gdscript
# tests/run_all.gd: replace the existing `var failures` declaration through final `quit(1)` in `_run_suites` with this complete tail; keep the existing --track-invalid-probe branch above it unchanged.
var requested_suite := ""
for argument in OS.get_cmdline_user_args():
	if argument.begins_with("--suite="):
		requested_suite = argument.trim_prefix("--suite=")
var selected_suites := SUITES
if not requested_suite.is_empty():
	selected_suites = []
	for suite_script in SUITES:
		if suite_script.resource_path.get_file() == requested_suite:
			selected_suites.append(suite_script)
	if selected_suites.is_empty():
		push_error("Unknown prototype suite: " + requested_suite)
		quit(1)
		return
var failures := PackedStringArray()
for suite_script in selected_suites:
	var suite = suite_script.new()
	var suite_failures: PackedStringArray = suite.run()
	for failure in suite_failures:
		failures.append("%s: %s" % [suite_script.resource_path, failure])
if failures.is_empty():
	print("PASS: %d prototype test suite(s)" % selected_suites.size())
	quit(0)
	return
for failure in failures:
	push_error(failure)
print("FAIL: %d assertion(s)" % failures.size())
quit(1)
```

```gdscript
# test_track_cell_sequence.gd: add this preload beside existing preloads.
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")

func _test_start_building_does_not_lock_geometry() -> void:
	var sequence = TrackCellSequenceScript.new(Vector2i.ZERO, 3)
	assert_not_null(sequence.try_append_candidate(Vector2i(1, 0)), "Fixture record")
	var piece = TrackGeometryPieceScript.new()
	piece.group_id = 0
	piece.first_route_serial = 1
	piece.last_route_serial = 1
	piece.nominal_length_cells = 1
	piece.footprint_cells = [Vector2i(1, 0)]
	piece.centerline = PackedVector2Array([Vector2(20.0, 20.0), Vector2(60.0, 20.0)])
	sequence.apply_resolved_geometry([piece])
	sequence.start_building(1)
	var record = sequence.get_records()[0]
	assert_equal(record.state, TrackCellRecordScript.State.BUILDING, "Construction starts")
	assert_false(record.geometry_locked, "Construction state does not lock geometry")

# test_grid_track_runtime.gd: add this preload beside existing preloads.
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")

func _test_built_head_reflows_without_geometry_lock() -> void:
	var track = GridTrackRuntimeScript.new(Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_equal(track.append_cells([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]), 3, "Initial straights")
	assert_equal(track.advance_construction(3.0), 3.0, "Initial cells build")
	assert_false(track.get_geometry_pieces()[0].locked, "Built head is still provisional")
	assert_equal(track.append_cells([Vector2i(2,1), Vector2i(2,2)]), 2, "Turn completes")
	assert_equal(track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Built cells reclassify")
	for record in track.get_cell_records().slice(0, 3):
		assert_equal(record.state, TrackCellRecordScript.State.BUILT, "Reclassification keeps built state")

func _test_twenty_construction_steps_keep_completed_head_reflowable() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var additions := {
		0: Vector2i(0, 0), # B
		21: Vector2i(1, 0), # C
		42: Vector2i(2, 0), # D
		63: Vector2i(2, 1), # E
		84: Vector2i(2, 2), # F
	}
	var completion_ticks: Array[int] = []
	for input_tick in range(85):
		if additions.has(input_tick):
			assert_equal(track.append_cells([additions[input_tick]]), 1, "Accepted route cell at tick %d" % input_tick)
		var states_before = track.get_cell_records()
		track.advance_construction(1.0 / 20.0)
		var states_after = track.get_cell_records()
		for index in range(states_after.size()):
			if states_before[index].state != TrackCellRecordScript.State.BUILT and states_after[index].state == TrackCellRecordScript.State.BUILT:
				completion_ticks.append(input_tick)
	assert_equal(completion_ticks, [19, 40, 61, 82], "B through E each use 20 construction steps")
	assert_equal(track.get_cell_records()[4].state, TrackCellRecordScript.State.BUILDING, "F receives its same-tick first step")
	assert_equal(track.get_cell_records()[4].build_progress, 1.0 / 20.0, "F first step is one twentieth")
	assert_equal(track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "B through F resolves as 3x3")
	assert_false(track.get_geometry_pieces()[0].locked, "Completed B through E remains reflowable")
```

- [ ] **Step 2: Run focused RED evidence**

```powershell
Confirm-ReflowRedFocused 'test_track_cell_sequence.gd' 'Construction state does not lock geometry'
Confirm-ReflowRedFocused 'test_grid_track_runtime.gd' 'Built head is still provisional'
Confirm-ReflowUnknownSuite
```

Expected: the new sequence assertion fails because `start_building` marks every group record `geometry_locked`; the runtime assertion fails because construction locks the current piece. The selector itself must execute exactly one named suite.

- [ ] **Step 3: Implement the smallest GREEN change**

Remove the group-lock loop from `TrackCellSequence.start_building`; leave its group-id validation and `BUILDING` transition intact. Remove `_lock_piece_for_serial(target.route_serial)` from `GridTrackRuntime.advance_construction`. Do not add a replacement construction-time lock.

```gdscript
# track_cell_sequence.gd: replace the complete method.
func start_building(route_serial: int) -> void:
	for record in _records:
		if record.state == TrackCellRecordScript.State.BUILDING:
			return
	var target = null
	for record in _records:
		if record.route_serial == route_serial:
			target = record
			break
	if (
		target == null
		or target.state != TrackCellRecordScript.State.RESERVED_GHOST
		or target.geometry_group_id < 0
	):
		return
	target.state = TrackCellRecordScript.State.BUILDING
	target.build_progress = 0.0

# grid_track_runtime.gd
if target.state == TrackCellRecordScript.State.RESERVED_GHOST:
	_sequence.start_building(target.route_serial)
```

- [ ] **Step 4: Continue directly to the horizon/ledger migration below**

Removing construction locks intentionally invalidates legacy construction/recovery assertions until the horizon fixture and replacements below are complete. Do not run or claim a green suite at this boundary; the sole Task 1 GREEN gate is after the continuation’s legacy migration.

#### Task 1 continuation: whole-piece horizon, ledger, and exit-support cancellation

**Files:**

- Modify: `godot-project-moe-rail-way/tests/run_all.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`

**Interfaces:**

- Consumes: the construction-only state transitions above.
- Produces: `TrackGeometryPiece.exit_support_route_serial: int = -1`, `GridTrackRuntime` atomic route/cancel transactions, a stable maximum-five provisional suffix, and `GridTrackRuntime.is_exit_support_route_serial(route_serial) -> bool`.

- [ ] **Step 1: Write failing horizon, ledger, and cancellation tests**

In `test_grid_track_runtime.gd`, add the listed tests to `run()` immediately before `return finish()`, and add every fixture/serializer below before the existing `_make_three_by_three_curve_runtime()` method. The serializers deliberately compare values, never `RefCounted` identity. The two anchor tests are baseline regression protection: run them with the Task 1 focused GREEN/full gate after the real construction/horizon RED, and do not invent an anchor-only failing implementation step because the current authoritative-anchor behavior already passes its approved contract.

```gdscript
# test_grid_track_runtime.gd, run(): append before return finish().
_test_sixth_head_record_locks_whole_curve_and_supports_exit()
_test_support_piece_locks_later_without_mutating_predecessor_metadata()
_test_cancellation_rolls_back_exactly_when_support_is_in_suffix()
_test_cancel_from_inside_wholly_provisional_piece_removes_only_eligible_suffix()
_test_rejected_append_rolls_back_only_tentative_suffix()
_test_locked_prefix_and_provisional_suffix_are_contiguous()
_test_horizon_locks_complete_one_two_and_three_cell_pieces()
_test_rejected_eligible_cancel_restores_route_inventory_and_ledger()
_test_suffix_after_exit_support_remains_cancelable_and_support_expires_after_recovery()
_test_horizon_rejection_after_first_staged_ledger_piece_is_atomic()
_test_rejected_recovery_after_removal_is_atomic()
_test_successful_recovery_clears_active_anchor_observation()
_test_authoritative_anchor_failure_preserves_mixed_derived_contacts()
_test_contact_observations_follow_active_slice_not_ledger_history()
```

```gdscript
# test_grid_track_runtime.gd: add these preloads beside existing preloads.
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")

class _RejectingResolver extends TrackGeometryResolverScript:
	func resolve(
		_departure_cell: Vector2i,
		records: Array,
		_locked_pieces: Array,
		_anchors: Array,
		_grid_origin_units: Vector2,
		_grid_size: Vector2i,
		_cell_size_units: float
	) -> RefCounted:
		return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"test_reject")

class _RejectAfterFirstLedgerCandidateResolver extends TrackGeometryResolverScript:
	var resolve_calls_with_ledger := 0
	func resolve(
		departure_cell: Vector2i,
		records: Array,
		locked_pieces: Array,
		anchors: Array,
		grid_origin_units: Vector2,
		grid_size: Vector2i,
		cell_size_units: float
	) -> RefCounted:
		if not locked_pieces.is_empty():
			resolve_calls_with_ledger += 1
			return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"reject_after_first_ledger_candidate")
		return super.resolve(departure_cell, records, locked_pieces, anchors, grid_origin_units, grid_size, cell_size_units)

class _RejectAfterRecoveryRemovalResolver extends TrackGeometryResolverScript:
	func resolve(
		departure_cell: Vector2i,
		records: Array,
		locked_pieces: Array,
		anchors: Array,
		grid_origin_units: Vector2,
		grid_size: Vector2i,
		cell_size_units: float
	) -> RefCounted:
		if records.size() == 5 and not locked_pieces.is_empty():
			return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"reject_after_recovery_removal")
		return super.resolve(departure_cell, records, locked_pieces, anchors, grid_origin_units, grid_size, cell_size_units)

func _reflow_runtime() -> GridTrackRuntimeScript:
	return GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)

func _reflow_curve_cells() -> Array[Vector2i]:
	return [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]

func _record_values(records: Array) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for record in records:
		values.append({
			"serial": record.route_serial,
			"cell": record.cell,
			"distance": record.route_distance_start_cells,
			"state": record.state,
			"progress": record.build_progress,
			"group": record.geometry_group_id,
			"locked": record.geometry_locked,
		})
	return values

func _piece_values(pieces: Array) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for piece in pieces:
		values.append({
			"serials": Vector2i(piece.first_route_serial, piece.last_route_serial),
			"kind": piece.kind,
			"distance": piece.absolute_start_distance_cells,
			"length": piece.nominal_length_cells,
			"footprint": piece.footprint_cells,
			"centerline": piece.centerline,
			"active_start": piece.active_local_start_cells,
			"active_end": piece.active_local_end_cells,
			"locked": piece.locked,
			"support": piece.exit_support_route_serial,
		})
	return values

func _recovery_observation_values(track: GridTrackRuntimeScript) -> Dictionary:
	return {
		"records": _record_values(track.get_cell_records()),
		"inventory": track.get_available_track_cells(),
		"pieces": _piece_values(track.get_geometry_pieces()),
		"built_end": track.get_built_end_distance_cells(),
		"recovered_cells_by_piece": track._recovered_cells_by_piece.duplicate(true),
		"recovered_end_distance_cells": track._recovered_end_distance_cells,
		"contact_observations": track.get_contact_observations().duplicate(true),
	}

func _piece_containing(pieces: Array, route_serial: int):
	for piece in pieces:
		if piece.contains_serial(route_serial):
			return piece
	return null

func _assert_record_piece_sync(track: GridTrackRuntimeScript) -> void:
	var pieces = track.get_geometry_pieces()
	for record in track.get_cell_records():
		var owners: Array = []
		for piece in pieces:
			if piece.contains_serial(record.route_serial):
				owners.append(piece)
		assert_equal(owners.size(), 1, "Every active record has exactly one owning piece")
		if owners.size() == 1:
			var owner = owners[0]
			assert_equal(record.geometry_group_id, owner.group_id, "Record group matches owning piece")
			assert_equal(record.geometry_locked, owner.locked, "Record lock matches owning piece")

func _assert_locked_prefix_through(pieces: Array, target_serial: int) -> void:
	var reached_target := false
	var saw_provisional := false
	for piece in pieces:
		if piece.locked:
			assert_false(saw_provisional, "No interior locked island exists")
		else:
			saw_provisional = true
		if not reached_target:
			assert_true(piece.locked, "Every predecessor through the required owner is locked")
			if piece.contains_serial(target_serial):
				reached_target = true
	assert_true(reached_target, "Required owner exists in the active piece sequence")

func _test_sixth_head_record_locks_whole_curve_and_supports_exit() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Five-cell curve")
	assert_equal(track.advance_construction(5.0), 5.0, "Head can already be built")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "G appends")
	var pieces = track.get_geometry_pieces()
	assert_true(pieces[0].locked, "B through F locks as one ledger piece")
	assert_equal(pieces[0].exit_support_route_serial, 6, "G serial is exit support")
	var support_piece = _piece_containing(pieces, 6)
	assert_not_null(support_piece, "G has active geometry")
	if support_piece != null:
		assert_false(support_piece.locked, "Support geometry remains independently provisional")
	var locked_ghost_track = _reflow_runtime()
	locked_ghost_track.append_cells(_reflow_curve_cells())
	locked_ghost_track.append_cells([Vector2i(2, 3)])
	assert_equal(locked_ghost_track.get_cell_records()[0].state, TrackCellRecordScript.State.RESERVED_GHOST, "Locked record can remain a construction ghost")
	assert_false(locked_ghost_track.cancel_ghost_suffix(Vector2i(0, 0)), "Locked non-support ghost cannot cancel")
	assert_false(locked_ghost_track.cancel_ghost_suffix(Vector2i(2, 3)), "Exit-support ghost cannot cancel")

func _test_support_piece_locks_later_without_mutating_predecessor_metadata() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	var predecessor_before = _piece_values(track.get_geometry_pieces())[0]
	assert_equal(track.append_cells([
		Vector2i(2, 4), Vector2i(2, 5), Vector2i(2, 6),
		Vector2i(3, 6), Vector2i(4, 6),
	]), 5, "Five-record continuation exceeds the head horizon")
	var support_piece = _piece_containing(track.get_geometry_pieces(), 6)
	assert_not_null(support_piece, "G still has a piece")
	if support_piece != null:
		assert_true(support_piece.locked, "Support piece later locks by ordinary horizon enforcement")
		var predecessor = _piece_containing(track.get_geometry_pieces(), 1)
		assert_not_null(predecessor, "Original locked predecessor survives")
		if predecessor != null:
			assert_equal(support_piece.centerline[0], predecessor.centerline[-1], "Continuation from fixed G stitches position")
			assert_true(support_piece.sample_nominal(0.0).heading.dot(predecessor.sample_nominal(float(predecessor.nominal_length_cells)).heading) > 0.999, "Continuation from fixed G stitches heading")
	_assert_record_piece_sync(track)
	assert_equal(_piece_values(track.get_geometry_pieces())[0]["support"], predecessor_before["support"], "Predecessor support metadata remains immutable")

func _test_cancellation_rolls_back_exactly_when_support_is_in_suffix() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	var before_records = _record_values(track.get_cell_records())
	var before_inventory = track.get_available_track_cells()
	var before_pieces = _piece_values(track.get_geometry_pieces())
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 3)), "Support target is ineligible")
	assert_equal(_record_values(track.get_cell_records()), before_records, "Records unchanged")
	assert_equal(track.get_available_track_cells(), before_inventory, "Inventory unchanged")
	assert_equal(_piece_values(track.get_geometry_pieces()), before_pieces, "Ledger geometry unchanged")

func _test_cancel_from_inside_wholly_provisional_piece_removes_only_eligible_suffix() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Curve head appends")
	var target = track.get_cell_records()[2]
	assert_true(track.cancel_ghost_suffix(target.cell), "Target inside provisional curve is legal")
	assert_equal(track.get_cell_records().size(), 2, "Target-to-end suffix is removed")
	assert_equal(track.get_available_track_cells(), track.get_total_track_cells() - 2, "Refund is exact")

func _test_rejected_append_rolls_back_only_tentative_suffix() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	var records_before = _record_values(track.get_cell_records())
	var pieces_before = _piece_values(track.get_geometry_pieces())
	var inventory_before = track.get_available_track_cells()
	track._resolver = _RejectingResolver.new()
	assert_equal(track.append_cells([Vector2i(2, 3)]), 0, "Resolver-rejected tentative continuation rejects")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Valid prefix serials stay intact")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Last valid geometry stays intact")
	assert_equal(track.get_available_track_cells(), inventory_before, "Tentative inventory rolls back")

func _test_locked_prefix_and_provisional_suffix_are_contiguous() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	var saw_provisional := false
	for piece in track.get_geometry_pieces():
		if not piece.locked:
			saw_provisional = true
		else:
			assert_false(saw_provisional, "No interior locked island")

func _test_horizon_locks_complete_one_two_and_three_cell_pieces() -> void:
	var fixtures: Array[Array] = [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4)],
		_reflow_curve_cells() + [Vector2i(2, 3)],
	]
	var kinds := [TrackGeometryPieceScript.Kind.CURVE_1X1, TrackGeometryPieceScript.Kind.CURVE_2X2, TrackGeometryPieceScript.Kind.CURVE_3X3]
	for index in range(fixtures.size()):
		var track = _reflow_runtime()
		assert_equal(track.append_cells(fixtures[index]), fixtures[index].size(), "Fixture appends")
		assert_equal(track.get_geometry_pieces()[0].kind, kinds[index], "Fixture resolves requested curve kind")
		assert_true(track.get_geometry_pieces()[0].locked, "Horizon exits only at whole piece boundary")
		_assert_record_piece_sync(track)

func _test_rejected_eligible_cancel_restores_route_inventory_and_ledger() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	var records_before = _record_values(track.get_cell_records())
	var inventory_before = track.get_available_track_cells()
	var pieces_before = _piece_values(track.get_geometry_pieces())
	track._resolver = _RejectingResolver.new()
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 0)), "Resolver-rejected eligible suffix cancel fails")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Cancel failure restores records")
	assert_equal(track.get_available_track_cells(), inventory_before, "Cancel failure restores inventory")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Cancel failure restores ledger-observable geometry")

func _test_suffix_after_exit_support_remains_cancelable_and_support_expires_after_recovery() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3), Vector2i(2, 4)])
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 4)), "Suffix strictly after support remains eligible")
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 3)), "Active support remains ineligible")
	track.advance_construction(5.0)
	track.recover_behind(5.0)
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 3)), "Pruned predecessor releases former support eligibility")

func _test_horizon_rejection_after_first_staged_ledger_piece_is_atomic() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Initial five-record candidate prefix resolves")
	var records_before = _record_values(track.get_cell_records())
	var inventory_before = track.get_available_track_cells()
	var pieces_before = _piece_values(track.get_geometry_pieces())
	var resolver = _RejectAfterFirstLedgerCandidateResolver.new()
	track._resolver = resolver
	assert_equal(track.append_cells([Vector2i(2, 3)]), 0, "Post-ledger resolution rejects append")
	assert_equal(resolver.resolve_calls_with_ledger, 1, "Failure occurs after exactly one staged ledger candidate")
	assert_equal(_record_values(track.get_cell_records()), records_before, "No partial record commit")
	assert_equal(track.get_available_track_cells(), inventory_before, "No partial inventory commit")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "No partial ledger expansion")
	track._resolver = TrackGeometryResolverScript.new()
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Subsequent valid append remains legal")
	assert_equal(track.get_cell_records()[-1].route_serial, 6, "Rejected append did not consume route serial")

func _test_rejected_recovery_after_removal_is_atomic() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Recovery fixture curve appends")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Recovery fixture support appends")
	assert_equal(track.advance_construction(6.0), 6.0, "Recovery fixture builds sequentially")
	track.set_contact_anchors([RouteContactAnchorScript.new(&"recovery_active_b", Vector2i(0, 0))])
	var before = _recovery_observation_values(track)
	var before_contacts: Array = before["contact_observations"]
	assert_equal(before_contacts.size(), 1, "Active B anchor publishes one observation before rejected recovery")
	assert_true(before_contacts[0].contact_possible and before_contacts[0].contacted, "Active B anchor is true before rejected recovery")
	track._resolver = _RejectAfterRecoveryRemovalResolver.new()
	assert_equal(track.recover_behind(1.0), 0, "Post-removal resolver rejection returns no recovered cells")
	assert_equal(_recovery_observation_values(track), before, "Recovery rejection preserves records, inventory, pieces, ledger support, recovered map/end, contacts, active ends, and built end")
	var after = track.get_contact_observations()
	assert_equal(after.size(), 1, "Rejected recovery retains the active B anchor observation")
	assert_true(after[0].contact_possible and after[0].contacted, "Rejected recovery retains active B true/true observation")

func _test_successful_recovery_clears_active_anchor_observation() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Control recovery curve appends")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Control recovery support appends")
	assert_equal(track.advance_construction(6.0), 6.0, "Control recovery builds sequentially")
	track.set_contact_anchors([RouteContactAnchorScript.new(&"recovery_active_b", Vector2i(0, 0))])
	var before = track.get_contact_observations()
	assert_equal(before.size(), 1, "Control has one active B anchor observation")
	assert_true(before[0].contact_possible and before[0].contacted, "Control active B anchor begins true/true")
	assert_equal(track.recover_behind(1.0), 1, "Successful recovery removes B")
	var after = track.get_contact_observations()
	assert_equal(after.size(), 1, "Recovered anchor remains authoritative as an observation")
	assert_false(after[0].contact_possible or after[0].contacted, "Recovered B leaves the active slice and publishes false/false")

class _RejectAnchorReresolutionResolver extends TrackGeometryResolverScript:
	var reject_anchor_reresolution := false
	func resolve(
		departure_cell: Vector2i,
		records: Array,
		locked_pieces: Array,
		anchors: Array,
		grid_origin_units: Vector2,
		grid_size: Vector2i,
		cell_size_units: float
	) -> RefCounted:
		if reject_anchor_reresolution and not anchors.is_empty():
			return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"injected_anchor_reresolution_reject")
		return super.resolve(departure_cell, records, locked_pieces, anchors, grid_origin_units, grid_size, cell_size_units)

func _test_authoritative_anchor_failure_preserves_mixed_derived_contacts() -> void:
	var track = _reflow_runtime()
	var resolver = _RejectAnchorReresolutionResolver.new()
	track._resolver = resolver
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Initial valid geometry is accepted")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Initial ledger geometry is accepted")
	var records_before = _record_values(track.get_cell_records())
	var pieces_before = _piece_values(track.get_geometry_pieces())
	resolver.reject_anchor_reresolution = true
	var anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"still_contacted", Vector2i(0, 0)),
		RouteContactAnchorScript.new(&"unsatisfied", Vector2i(0, 2)),
	]
	track.set_contact_anchors(anchors)
	var observations = track.get_contact_observations()
	assert_equal(_record_values(track.get_cell_records()), records_before, "Anchor failure preserves records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Injected anchor failure preserves ledger-observable geometry")
	assert_equal(observations.size(), 2, "Both authoritative anchors publish observations")
	assert_equal(observations[0].anchor_id, &"still_contacted", "First authoritative anchor identity is copied")
	assert_equal(observations[0].cell, Vector2i(0, 0), "First authoritative anchor cell is copied")
	assert_equal(observations[1].anchor_id, &"unsatisfied", "Second authoritative anchor identity is copied")
	assert_equal(observations[1].cell, Vector2i(0, 2), "Second authoritative anchor cell is copied")
	assert_true(observations[0].contact_possible and observations[0].contacted, "Still-contacted anchor stays true")
	assert_false(observations[1].contact_possible or observations[1].contacted, "Unsatisfied anchor is false")

func _test_contact_observations_follow_active_slice_not_ledger_history() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	track.advance_construction(6.0)
	track.recover_behind(1.0)
	track.set_contact_anchors([RouteContactAnchorScript.new(&"recovered", Vector2i(0, 0))])
	assert_false(track.get_contact_observations()[0].contacted, "Recovered slice does not contact")
```

- [ ] **Step 2: Run focused RED evidence**

```powershell
Confirm-ReflowRedFocused 'test_grid_track_runtime.gd' 'exit_support_route_serial'
```

Expected: horizon does not yet lock at six records, `exit_support_route_serial` does not exist, and support cancellation currently succeeds.

- [ ] **Step 3: Implement the atomic minimal GREEN behavior**

Add `exit_support_route_serial` to `TrackGeometryPiece` and copy it in `duplicate_piece`. In `GridTrackRuntime`, create detached candidate ledger/piece arrays; never mutate `_locked_ledger` or `_pieces` until resolving, whole-piece horizon locking, continuity validation, and support derivation all succeed. Lock the earliest provisional whole piece repeatedly until no more than five provisional records remain. If the just-locked piece required its immediate successor for terminal tangent/midpoint, store that successor serial; otherwise keep `-1`. Retain the current authoritative `set_contact_anchors`, copied-anchor ownership, and `_active_piece_contacts_cell` active-slice behavior unchanged; this task's new anchor fixtures are regression protection for the transaction refactor, not authorization for a separate anchor production change or commit.

Implement these exact internal methods in `grid_track_runtime.gd`; all are private except `is_exit_support_route_serial(route_serial: int) -> bool`, and none creates a new class or presentation state: `_duplicate_pieces(source: Array[TrackGeometryPieceScript]) -> Array[TrackGeometryPieceScript]`; `_resolve_candidate(sequence: TrackCellSequenceScript, ledger: Array[TrackGeometryPieceScript]) -> RefCounted`; `_count_provisional_records(pieces: Array[TrackGeometryPieceScript], records: Array[TrackCellRecordScript]) -> int`; `_earliest_provisional_piece(pieces: Array[TrackGeometryPieceScript]) -> TrackGeometryPieceScript`; `_exit_support_serial(piece: TrackGeometryPieceScript, records: Array[TrackCellRecordScript]) -> int`; `_stage_horizon(sequence: TrackCellSequenceScript, ledger: Array[TrackGeometryPieceScript]) -> RefCounted`; and `_commit_candidate(sequence: TrackCellSequenceScript, ledger: Array[TrackGeometryPieceScript], resolution: RefCounted) -> void`.

Implement `TrackCellSequence.duplicate_sequence() -> TrackCellSequenceScript` and `TrackCellSequence.replace_with(source: TrackCellSequenceScript) -> void` in the Task 1 allowlist. `duplicate_sequence` copies every scalar (`_departure_cell`, inventory totals, next serial, next nominal distance, active predecessor), duplicates each record, and rebuilds `_active_cells` from those records. `replace_with` assigns exactly those copied values and records; it neither allocates inventory nor renumbers serials. `GridTrackRuntime` creates a duplicate before each append/cancel mutation, applies the candidate mutation only to that duplicate, and calls `_resolve_candidate` with its active predecessor/records, detached candidate ledger, current copied anchors, and the runtime grid fields.

`_stage_horizon` resolves first, then repeatedly counts only records owned by unlocked pieces. Store that count before looking for an earliest piece: a count of zero returns the accepted resolution immediately, and a count of one through five returns it without locking. While the count exceeds five, it takes the earliest unlocked piece, duplicates it into the candidate ledger with `locked = true`, records its immediate active successor serial as `exit_support_route_serial` only when that successor supplied the exit tangent/midpoint, and resolves again. It returns a rejected resolution on any invalid resolution, missing whole piece, discontinuity, or unresolved support. Before calling `_commit_candidate`, run one precommit validator that resolves the candidate and validates continuity, exact one-piece ownership for every active record, synchronized group/lock assignments, support references, and prune/recovered bounds. `_commit_candidate(...)->void` is therefore infallible: it only replaces already-validated `_sequence`, `_locked_ledger`, and `_pieces` together and applies the already-computed record group/lock values. Cancellation reads either the final owning piece or this synchronized flag, and the tests assert both agree. A rejected validation leaves all three old values, recovered bookkeeping, and inventory unchanged. `is_exit_support_route_serial` scans only active ledger entries and returns true only for a matching nonnegative support serial.

Make `recover_behind(cutoff_distance_cells)` the same detached transaction. Duplicate the sequence, locked ledger, pieces, `_recovered_cells_by_piece`, `_recovered_end_distance_cells`, and contact-observation inputs; stage eligible one-cell removal/refund only on those copies; re-resolve and validate continuity, ownership, support/prune lifecycle, recovered-cell bookkeeping, active slice ends, absolute built end, anchor-derived contacts, and inventory conservation; then atomically replace sequence, ledger, pieces, recovered map, end distance, contacts, and inventory. If the injected post-removal resolver rejects, return `0` and retain the complete serialized pre-recovery state. The test serializer must deep-copy and compare public records/inventory/pieces/built end plus `_recovered_cells_by_piece`, `_recovered_end_distance_cells`, and current contact observations; it sets an authoritative anchor on active B and proves its true/true observation survives rejection byte-for-value. A separate successful-recovery control using the same anchor proves that once B leaves the active slice, its retained authoritative observation becomes false/false. Do not mutate or refund in place before this validation.

In `track_geometry_piece.gd`, add `var exit_support_route_serial: int = -1` and copy it in `duplicate_piece()`. In `cancel_ghost_suffix`, find the target index before mutation; reject if the target is absent, any target-to-end record is not `RESERVED_GHOST`, any owning final piece/its synchronized `geometry_locked` flag is locked, or any serial is an active exit support. Otherwise remove the complete candidate suffix, require `_stage_horizon` to return an accepted resolution, then commit the duplicate sequence/ledger/pieces through `_commit_candidate`. No ineligible record is skipped; a failed candidate leaves serialized records, pieces, and inventory equal to their pre-call values. Keep later suffix cancellation legal when it excludes the support serial, and make a former support legal again only after the dependent ledger entry is fully recovered and pruned.

- [ ] **Step 4: Complete recovery/cancellation/anchor/legacy migration, then run focused GREEN and the full required regression gate**

Checkpoint 1C begins after 1B's geometry/support core compiles, with this separate recovery RED:

```powershell
Confirm-ReflowRedFocused 'test_grid_track_runtime.gd' 'Post-removal resolver rejection returns no recovered cells'
```

Before the gate, make these exact legacy migrations. In `test_grid_track_runtime.gd`, replace `_test_construction_locks_piece_and_builds_one_cell_atomically` with the Task 1 built-but-provisional reflow test; replace `_test_construction_excess_and_group_assignment` assertions that expect `geometry_locked` with sequential `BUILDING`/`BUILT` progress assertions; replace `_test_cancellation_stops_at_locked_piece` with B–F plus G, asserting that G is the exit support and cannot cancel; replace `_test_recovery_keeps_group_ids_unique` with a B–F/G fixture, build and recover B then assert the surviving locked ledger and any successor retain distinct groups without construction assigning locks; replace `_test_locked_endpoint_rejects_disconnected_rebranch` with B–F/G, cancel only a suffix beyond G, then prove a disconnected append rejects while the locked curve endpoint and its support continuity remain intact. Retain partial-recovery/no-renormalization tests by first creating the B–F plus G horizon-locked fixture. Keep the existing authoritative-anchor production path; run the moved mixed-anchor injected-rejection and recovered-active-slice tests to prove the candidate/ledger refactor leaves its copied anchors, preserved geometry, and per-anchor current observations correct. In `test_track_system_construction_recovery.gd`, replace `_test_fractional_construction_locks_and_builds_atomically` and `_test_locked_piece_rejects_reflow_and_cancellation`: assert construction leaves the 3x3 head unlocked, then append G to obtain the ledger lock before testing immutability/cancellation; update both recovery tests to use that B–F/G ledger fixture. In `test_track_cell_sequence.gd`, keep direct rollback guards but replace all construction-lock expectations with `geometry_locked == false` until runtime horizon lock assignment. In `test_track_geometry_resolver.gd`, retain resolver-only locked-slice tests and add the support metadata copy/active-slice serialization checks; it must not imply that construction creates a ledger. In `test_track_train_app_composition.gd`, change `_test_standard_curve_intervals_and_integer_hud` so construction first proves the B–F curve remains unlocked; append G before asserting the now-horizon-locked curve cannot reflow, and defer its running snapshot to Task 2’s prepared pose-pair migration. These replacements keep recovery one-cell-at-a-time, absolute distance, and inventory conservation covered without construction-start locking.

```powershell
Invoke-ReflowFocused 'test_grid_track_runtime.gd'
Invoke-ReflowFocused 'test_track_system_construction_recovery.gd'
Invoke-ReflowFocused 'test_track_geometry_resolver.gd'
Invoke-ReflowFocused 'test_track_train_app_composition.gd'
Invoke-ReflowFullGate
```

Expected: the straddling `B..F`/`G` fixture locks the five-record curve atomically; support cancellation is a no-op; later independent support locking preserves predecessor metadata; all full-gate PASS anchors appear.

- [ ] **Step 5: Stage the complete Task 1 allowlist and commit**

```powershell
git add -- `
  godot-project-moe-rail-way/tests/run_all.gd `
  godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd `
  godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd `
  godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd `
  godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd `
  godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd `
  godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd `
  godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd `
  godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd
git diff --cached --check
git diff --cached --name-only
git commit -m "feat: add atomic reflowable track-head ledger"
```

- [ ] **Step 6: Obtain independent Sol reviews**

Request a Sol specification review against spec Sections 1, 3–5, 8–10, 12, and 14, then a separate Sol quality review focusing on construction/geometry decoupling, anchor-regression preservation, legacy-test migration, transaction rollback, ledger copying, support lifecycle, deterministic ordering, record/piece synchronization, and fixture validity. A fresh Terra worker resolves findings using this complete Task 1 allowlist, reruns focused tests and the full gate, then repeats both Sol reviews.

### Task 2: Canonical Preparation, Train Sampling, and Session Tick Safety

**Files:**

- Modify: `godot-project-moe-rail-way/tests/run_all.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- Modify: `godot-project-moe-rail-way/src/domain/train/train_system.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_train_system.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd`
- Modify: `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- Modify: `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`

**Interfaces:**

- Consumes: Task 1 immutable ledger and its retained active-slice anchor observations.
- Produces: `GridTrackRuntime.prepare_for_train_sampling(current_distance, through_distance) -> bool`, `TrackSystem` forwarding methods, shared inclusive-epsilon owner selection, and `TrainSystem.capture_pose(track_system) -> Dictionary`.

- [ ] **Step 1: Write the deterministic controller prepare-call RED micro-cycle**

In `test_session_controller.gd`, add the following subclass and one test call immediately before `return finish()`. This is intentionally the first Task 2 test edit: a subclass may declare a method not yet present in `TrackSystem`, so the current code compiles and the unique assertion fails solely because the current controller does not call it.

```gdscript
# test_session_controller.gd: add beside the existing helpers, then append the test call in run().
class TogglePrepareTrackSystem extends TrackSystemScript:
	var allow_prepare := true
	var prepare_calls := 0
	func prepare_for_train_sampling(_current_distance: float, _through_distance: float) -> bool:
		prepare_calls += 1
		return allow_prepare

func _test_controller_requests_prepare_once_before_departure() -> void:
	var config = _config(5.0, 1, 1.0, 10.0)
	var track = TogglePrepareTrackSystem.new(config)
	var train = TrainSystemScript.new(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	controller.advance_tick(_draw_frame([Vector2i(1, 0)]))
	assert_equal(track.prepare_calls, 1, "Controller requests prepare exactly once before departure")

# run(): append before return finish().
_test_controller_requests_prepare_once_before_departure()
```

- [ ] **Step 2: Capture the deterministic controller RED**

```powershell
Confirm-ReflowRedFocused 'test_session_controller.gd' 'Controller requests prepare exactly once before departure'
```

Expected: the current controller never invokes the subclass method, so the unique assertion reports `0` rather than `1`. This RED does not depend on a missing parser symbol, a locked-owner assertion, or a runtime resolver outcome.

- [ ] **Step 3: Add only the production API surface needed for the behavior fixtures**

Add the exact compile/API surface declaration `GridTrackRuntime.NOMINAL_BOUNDARY_EPSILON := 0.0001` (as `const NOMINAL_BOUNDARY_EPSILON := 0.0001` in `grid_track_runtime.gd`) and declared methods with these exact signatures: `GridTrackRuntime.prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool`; `GridTrackRuntime.get_pose_sample_at_distance(route_distance: float) -> Dictionary`; `TrackSystem.prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool`; `TrackSystem.get_pose_sample_at_distance(route_distance: float) -> Dictionary`; and `TrainSystem.capture_pose(track_system: TrackSystemScript) -> Dictionary`. For this intentionally incomplete surface cycle only, the runtime preparation stub returns `true` without mutation and the new pose helper delegates to the existing sampler; Step 6 uses the already-declared constant and replaces both methods with locked-only behavior. Wire `SessionController` to call `track_system.prepare_for_train_sampling` exactly once in the `PREPARING_DEPARTURE` departure micro-cycle immediately before its existing state transition, deliberately leaving the current `RUNNING` path without a preparation call. The preceding Step 2 RED then turns green, and Step 9's `Running failure attempts preparation once` is guaranteed to fail after its fixture reaches `RUNNING`. Do not claim Task 2 GREEN or run the full gate yet: boundary ownership, rollback, locked-only sampling, and safe-return behavior are still absent.

After that API surface is present, replace only the subclass body from Step 1 with the following complete behavior before writing the later controller tests:

```gdscript
class TogglePrepareTrackSystem extends TrackSystemScript:
	var allow_prepare := true
	var prepare_calls := 0
	var pose_sample_calls := 0
	var recovery_calls := 0
	func prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool:
		prepare_calls += 1
		if not allow_prepare:
			return false
		return super.prepare_for_train_sampling(current_distance, through_distance)
	func get_pose_sample_at_distance(route_distance: float) -> Dictionary:
		pose_sample_calls += 1
		return super.get_pose_sample_at_distance(route_distance)
	func recover_behind(route_distance_cells: float) -> int:
		recovery_calls += 1
		return super.recover_behind(route_distance_cells)
```

- [ ] **Step 4: Write failing boundary, rollback, invalid-probe, and pose tests**

In `test_grid_track_runtime.gd`, add the first five tests and both fixture helpers below to `run()` before `return finish()`. The test reuses Task 1's `_piece_containing`, `_record_values`, `_piece_values`, `_assert_locked_prefix_through`, and `_RejectAfterFirstLedgerCandidateResolver`. In `test_train_system.gd`, add `_test_capture_pose_is_the_only_pair_sampler()` to `run()` before `return finish()` and `const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")` beside existing preloads. In `test_track_system_construction_recovery.gd`, add `_test_facade_forwards_prepare_before_pose_capture()` to `run()` before `return finish()`.

```gdscript
# test_grid_track_runtime.gd, run(): append before return finish().
_test_prepare_and_pose_share_inclusive_boundary_owner()
_test_prepare_transaction_rejects_after_staging_without_mutation()
_test_zero_extent_internal_wait_does_not_lock_successor_reflow()
_test_departure_forward_boundary_and_route_end_ownership()
_test_two_sided_outside_epsilon_stitch_continuity()

# test_train_system.gd and test_track_system_construction_recovery.gd, respectively.
_test_capture_pose_is_the_only_pair_sampler()
_test_facade_forwards_prepare_before_pose_capture()
```

```gdscript
 # test_grid_track_runtime.gd
func _boundary_runtime() -> GridTrackRuntimeScript:
	var track = _reflow_runtime()
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1),
	]), 4, "Boundary fixture appends")
	assert_equal(track.advance_construction(4.0), 4.0, "Boundary fixture builds")
	assert_equal(track.get_geometry_pieces().size(), 2, "Boundary fixture has predecessor and successor")
	return track

func _canonical_test_distance(distance: float, boundary: float, epsilon: float) -> float:
	return boundary if absf(distance - boundary) <= epsilon else distance

func _test_prepare_and_pose_share_inclusive_boundary_owner() -> void:
	var probe = _boundary_runtime()
	var boundary: float = probe.get_geometry_pieces()[0].absolute_start_distance_cells + float(probe.get_geometry_pieces()[0].nominal_length_cells)
	var epsilon := GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON
	var distances := [boundary - epsilon, boundary, boundary + epsilon, boundary - epsilon * 1.01, boundary + epsilon * 1.01]
	var owner_indexes := [0, 0, 0, 0, 1]
	var local_distances := [boundary, boundary, boundary, boundary - epsilon * 1.01, epsilon * 1.01]
	for index in range(distances.size()):
		var track = _boundary_runtime()
		var distance: float = distances[index]
		var canonical := _canonical_test_distance(distance, boundary, epsilon)
		assert_true(track.prepare_for_train_sampling(distance, distance), "Preparation succeeds at %s" % distance)
		var expected_owner = track.get_geometry_pieces()[owner_indexes[index]]
		assert_true(expected_owner.locked, "Prepared owner is locked")
		_assert_locked_prefix_through(track.get_geometry_pieces(), expected_owner.last_route_serial)
		assert_true(is_equal_approx(canonical - expected_owner.absolute_start_distance_cells, local_distances[index]), "Canonical local distance has the expected owner-relative value")
		var expected = expected_owner.sample_nominal(canonical - expected_owner.absolute_start_distance_cells)
		var pose = track.get_pose_sample_at_distance(distance)
		assert_true(pose.position.is_equal_approx(expected.position), "Pose uses canonical prepared owner")
		assert_true(pose.heading.is_equal_approx(expected.heading), "Heading uses canonical prepared owner")

func _test_prepare_transaction_rejects_after_staging_without_mutation() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Prepare fixture appends")
	var records_before = _record_values(track.get_cell_records())
	var inventory_before = track.get_available_track_cells()
	var pieces_before = _piece_values(track.get_geometry_pieces())
	var resolver = _RejectAfterFirstLedgerCandidateResolver.new()
	track._resolver = resolver
	assert_false(track.prepare_for_train_sampling(0.0, 1.0), "Preparation rejects only after ledger staging")
	assert_equal(resolver.resolve_calls_with_ledger, 1, "Prepare reached its staged-ledger re-resolution")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Prepare failure restores records")
	assert_equal(track.get_available_track_cells(), inventory_before, "Prepare failure restores inventory")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Prepare failure restores ledger-visible pieces")

func _test_two_sided_outside_epsilon_stitch_continuity() -> void:
	var track = _boundary_runtime()
	var predecessor = track.get_geometry_pieces()[0]
	var boundary: float = predecessor.absolute_start_distance_cells + float(predecessor.nominal_length_cells)
	var epsilon := GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON
	var before_distance := boundary - epsilon * 1.01
	var after_distance := boundary + epsilon * 1.01
	assert_true(track.prepare_for_train_sampling(before_distance, after_distance), "Forward interval prepares both outside-epsilon owners")
	_assert_locked_prefix_through(track.get_geometry_pieces(), track.get_geometry_pieces()[1].last_route_serial)
	var before = track.get_pose_sample_at_distance(before_distance)
	var after = track.get_pose_sample_at_distance(after_distance)
	assert_true(before.heading.is_equal_approx(after.heading), "Two-sided stitch heading remains approximately continuous")
	var separation := before.position.distance_to(after.position)
	var nominal_travel_upper_bound := epsilon * 2.02 * 40.0
	assert_true(separation > 0.0, "Two-sided samples remain spatially distinct")
	assert_true(separation <= nominal_travel_upper_bound, "Two-sided samples stay within their known nominal travel bound")

func _test_zero_extent_internal_wait_does_not_lock_successor_reflow() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]), 3, "Three-straight boundary fixture appends")
	assert_equal(track.advance_construction(1.0), 1.0, "Only B builds to the internal boundary")
	assert_equal(track.get_built_end_distance_cells(), 1.0, "Built endpoint is exactly the zero-forward boundary")
	var before_prepare_successor = _piece_containing(track.get_geometry_pieces(), 2)
	assert_not_null(before_prepare_successor, "Successor owning C and D exists before prepare")
	assert_equal(track.get_cell_records()[1].state, TrackCellRecordScript.State.RESERVED_GHOST, "C remains a ghost before zero-extent prepare")
	assert_equal(track.get_cell_records()[2].state, TrackCellRecordScript.State.RESERVED_GHOST, "D remains a ghost before zero-extent prepare")
	if before_prepare_successor != null:
		assert_false(before_prepare_successor.locked, "Successor owning C and D is provisional before prepare")
	assert_true(track.prepare_for_train_sampling(1.0, 1.0), "Wait preparation succeeds")
	assert_equal(track.get_built_end_distance_cells(), 1.0, "Zero-forward prepare does not advance built endpoint")
	var predecessor = _piece_containing(track.get_geometry_pieces(), 1)
	var second_straight = _piece_containing(track.get_geometry_pieces(), 2)
	assert_not_null(predecessor, "Boundary predecessor exists")
	assert_not_null(second_straight, "Second straight exists")
	if predecessor != null:
		assert_true(predecessor.locked, "Zero-extent wait locks only the predecessor")
		_assert_locked_prefix_through(track.get_geometry_pieces(), predecessor.last_route_serial)
	if second_straight != null:
		assert_false(second_straight.locked, "Zero-extent wait leaves later records provisional")
	assert_equal(track.get_cell_records()[1].state, TrackCellRecordScript.State.RESERVED_GHOST, "Zero-extent wait leaves C ghost")
	assert_equal(track.get_cell_records()[2].state, TrackCellRecordScript.State.RESERVED_GHOST, "Zero-extent wait leaves D ghost")
	assert_equal(track.append_cells([Vector2i(3, 0), Vector2i(3, 1)]), 2, "Turn records after the locked boundary append")
	var reflowed = _piece_containing(track.get_geometry_pieces(), 3)
	assert_not_null(reflowed, "Provisional D through F span exists")
	if reflowed != null:
		assert_equal(reflowed.kind, TrackGeometryPieceScript.Kind.CURVE_2X2, "D through F reflows as 2x2 without crossing locked B")
		assert_false(reflowed.locked, "Reflowed future curve remains provisional before entry")

func _test_departure_forward_boundary_and_route_end_ownership() -> void:
	var departure_track = _reflow_runtime()
	departure_track.append_cells([Vector2i(0, 0)])
	departure_track.advance_construction(1.0)
	assert_true(departure_track.prepare_for_train_sampling(0.0, 0.0), "Departure prepares existing entry piece")
	assert_true(_piece_containing(departure_track.get_geometry_pieces(), 1).locked, "Departure entry locks")
	var boundary_track = _reflow_runtime()
	boundary_track.append_cells([Vector2i(0, 0), Vector2i(1, 0)])
	boundary_track.advance_construction(2.0)
	assert_true(boundary_track.prepare_for_train_sampling(1.0, 1.1), "Forward interval enters successor")
	assert_true(_piece_containing(boundary_track.get_geometry_pieces(), 2).locked, "Forward boundary locks successor")
	_assert_locked_prefix_through(boundary_track.get_geometry_pieces(), 2)
	var route_end_track = _reflow_runtime()
	route_end_track.append_cells([Vector2i(0, 0)])
	route_end_track.advance_construction(1.0)
	assert_true(route_end_track.prepare_for_train_sampling(1.0, 1.0), "Route end prepares predecessor")
	assert_equal(route_end_track.get_geometry_pieces().size(), 1, "Route end never invents successor")

# test_train_system.gd
func _test_capture_pose_is_the_only_pair_sampler() -> void:
	var train = TrainSystemScript.new(1.0)
	var config = _config()
	var track = TrackSystemScript.new(config)
	track.apply_left_input(TrackInputFrameScript.new([
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)
	], Vector2i(0, 0), true, Vector2i(-1, -1), false, true, true, false, false))
	track.advance_construction(4.0)
	var pieces = track.get_geometry_pieces()
	var boundary: float = pieces[0].absolute_start_distance_cells + float(pieces[0].nominal_length_cells)
	var epsilon := GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON
	assert_true(track.prepare_for_train_sampling(boundary + epsilon, boundary + epsilon), "Prepared at inclusive boundary")
	train.depart(boundary + epsilon)
	var pose = train.capture_pose(track)
	assert_true(pose.has("position") and pose.has("heading"), "Typed pose pair keys")
	var expected = pieces[0].sample_nominal(float(pieces[0].nominal_length_cells))
	assert_true(pose.position.is_equal_approx(expected.position), "Pair uses canonical facade sample")
	assert_true(pose.heading.is_equal_approx(expected.heading), "Pair heading uses canonical facade sample")

# test_track_system_construction_recovery.gd
func _test_facade_forwards_prepare_before_pose_capture() -> void:
	var track_system = _curve_track()
	track_system.advance_construction(5.0)
	assert_true(track_system.prepare_for_train_sampling(1.0, 1.0), "Facade prepares predecessor at boundary")
	var pose = track_system.get_pose_sample_at_distance(1.0)
	assert_true(pose.has("position") and pose.has("heading"), "Facade returns pose pair")
```

Add this narrow subprocess probe. It is not a suite and therefore does not alter the 19-suite PASS contract.

```gdscript
# tests/unit/test_grid_track_runtime.gd: add beside run(), not inside run().
func run_unprepared_pose_probe() -> bool:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Probe fixture appends provisional head")
	var pose = track.get_pose_sample_at_distance(0.0) # Must assert "Locked geometry is required for pose sampling" before sampling.
	if pose.is_empty():
		return false
	print("POSE_FALLBACK") # Reached only if production incorrectly sampled provisional geometry.
	return true

# tests/run_all.gd: add this preload beside SUITES and this dispatch before the --suite selector.
const GridTrackRuntimeSuiteScript = preload("res://tests/unit/test_grid_track_runtime.gd")

for argument in OS.get_cmdline_user_args():
	if argument == "--reflow-unprepared-pose-probe":
		print("REFLOW_UNPREPARED_POSE_PROBE_BEGIN")
		if not GridTrackRuntimeSuiteScript.new().run_unprepared_pose_probe():
			quit(1)
			return
		quit(0)
		return
```

Godot 4.7.1 treats a failed `assert` as a diagnostic/precondition, not as process termination. The Task 2 production method must therefore assert and explicitly return `{}` before `sample_nominal` on every missing or unlocked owner:

```gdscript
func get_pose_sample_at_distance(route_distance: float) -> Dictionary:
	var canonical = _canonical_distance_and_owner(route_distance)
	var owner = canonical.piece
	assert(owner != null, "Geometry owner is required for pose sampling")
	if owner == null:
		return {}
	assert(owner.locked, "Locked geometry is required for pose sampling")
	if not owner.locked:
		return {}
	return owner.sample_nominal(canonical.distance - owner.absolute_start_distance_cells)
```

The probe returns `false` only for the required rejected empty pose, so `run_all.gd` exits `1`; it prints `POSE_FALLBACK` and returns `true` only if provisional geometry was incorrectly sampled, so `run_all.gd` exits `0` and `Confirm-ReflowUnpreparedPoseProbe` fails. The wrapper requires the nonzero rejected-sample exit, the exact `Locked geometry is required for pose sampling` diagnostic, and absence of `POSE_FALLBACK`.

The five expected local distances are deliberate: `boundary - epsilon`, exact `boundary`, and `boundary + epsilon` all canonicalize to the exact boundary and belong to the predecessor; only values just outside epsilon retain their original predecessor/successor side.

- [ ] **Step 5: Run focused behavior RED evidence**

```powershell
Confirm-ReflowRedFocused 'test_grid_track_runtime.gd' 'Zero-extent wait locks only the predecessor'
```

Expected: after the API surface exists, its incomplete behavior still fails the ownership/rollback fixture. The second marker proves the behavior RED is not merely a missing-symbol parser diagnostic.

- [ ] **Step 6: Implement the smallest complete Task 2 behavior**

Create one private runtime helper used by preparation, position sampling, and heading sampling. Canonicalize only ownership/sample lookup; do not alter monotonic nominal motion distance. Preparation has two explicit stages: first, canonical ownership and positive interval overlap select one farthest required active owner; second, starting immediately after the existing active locked prefix frontier, stage every intervening provisional whole piece in route order through that farthest owner. A candidate may never lock a later owner while leaving a provisional predecessor, so its active locked pieces are always one contiguous prefix. At an internal zero-length boundary the farthest owner is the predecessor; at departure it is the entry piece. Commit only after resolution/continuity succeeds.

Use the Step 3-declared `NOMINAL_BOUNDARY_EPSILON := 0.0001` and add one private `GridTrackRuntime._canonical_distance_and_owner(route_distance: float) -> Dictionary` helper. It scans every active nominal boundary, replaces a distance whose absolute difference is less than or equal to epsilon with that boundary, and then selects the predecessor at an internal exact boundary; outside epsilon it leaves the raw distance on its original side. The returned dictionary has only `distance` and `piece` keys. Both `get_position_at_distance_cells` and `get_heading_at_distance_cells` delegate to the new `get_pose_sample_at_distance(route_distance: float) -> Dictionary`; that method uses this helper, requires its owner to be locked, and returns only the owner’s `sample_nominal(canonical_distance - owner.absolute_start_distance_cells)` pair.

Implement `prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool` as a candidate-ledger transaction using Task 1's duplicate/resolve/commit functions. Canonicalize both endpoints with the same shared helper, then determine the farthest required owner before staging: an equal canonical point selects its canonical owner; a forward interval selects the last active piece whose nominal interval has strictly positive-length intersection with `[canonical_current, canonical_through]`. Starting after the existing active locked-prefix frontier (or at the first active piece when none is locked), duplicate and stage every provisional whole piece in route order through that farthest owner, resolving/validating the complete candidate before the infallible commit. A required owner that is already within the locked prefix stages nothing. This makes a zero-extent internal boundary choose and lock only its predecessor, while a point just outside epsilon on the successor side or a forward interval that positively enters the successor selects that successor and, on a fresh runtime, locks its predecessor and itself as one prefix. Departure selects the existing entry piece; active route end selects only its existing predecessor. Rejecting resolution, continuity, ownership, or prefix validation rolls back every candidate ledger change and returns false. `TrackSystem.prepare_for_train_sampling` and `get_pose_sample_at_distance` forward directly to runtime. `TrainSystem.capture_pose(track_system: TrackSystemScript) -> Dictionary` returns that facade pair; `get_position` and `get_heading` extract its two fields, and `depart` remains activation-only.

- [ ] **Step 7: Continue directly to the session migration below**

The locked-only sampler intentionally makes pre-existing direct-sampling suites incomplete until the controller and every legacy caller are migrated in the continuation. Do not run or claim a green gate at this boundary; the sole Task 2 GREEN gate is after the continuation’s legacy migration.

#### Task 2 continuation: Session safe-return tick flow and terminal snapshot pose

**Additional session-only files:**

These are the only extra paths introduced by this continuation. The complete Task 2 allowlist remains the parent Task 2 **Files** block and its Step 12 exact staging command; do not stage this continuation separately.

- Modify: `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`

**Interfaces:**

- Consumes: the Task 2 preparation/capture API above.
- Produces: a cached post-motion pose for `SessionSnapshot`, deterministic no-publication safe return on prepare failure, and terminal ordering where the snapshot precedes `session_completed`/reason-only `SessionResult`.

- [ ] **Step 8: Write failing fixed-tick tests**

In `test_session_controller.gd`, add the test double, `_snapshot_values`, and all three tests below. Register the three tests in `run()` before `return finish()`. The fixture retains both `track` and `train` through its existing dictionary; no production getter is added.

```gdscript
# test_session_controller.gd, run(): append before return finish().
_test_prepare_failure_keeps_preparing_snapshot_and_time_unchanged()
_test_prepare_failure_keeps_running_without_recovery_or_events()
_test_terminal_snapshot_pose_precedes_reason_only_result_after_full_recovery()
```

```gdscript
# test_session_controller.gd
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")

# Replace the existing helper signature/body only in its recovery-lag argument.
func _config(
	duration_seconds: float = 2.5,
	ticks_per_second: int = 2,
	train_speed_cells: float = 0.25,
	build_cells_per_second: float = 0.5,
	total_cells: int = 8,
	recovery_lag: int = 1
) -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		1, duration_seconds, ticks_per_second,
		train_speed_cells, total_cells, recovery_lag, 1.0, build_cells_per_second, 1,
		Vector2(240.0, 160.0), Vector2i(6, 4), 40.0, Vector2.ZERO,
		&"controller_departure", Vector2(20.0, 20.0), Vector2i(0, 0)
	)

func _snapshot_values(snapshot) -> Dictionary:
	var records: Array[Dictionary] = []
	for record in snapshot.get_cell_records():
		records.append({"serial": record.route_serial, "state": record.state, "progress": record.build_progress})
	return {
		"state": snapshot.get_state(), "elapsed": snapshot.get_elapsed_ticks(),
		"remaining": snapshot.get_remaining_ticks(), "distance": snapshot.get_train_route_distance_cells(),
		"position": snapshot.get_train_position(), "heading": snapshot.get_train_heading(), "records": records,
	}

func _test_prepare_failure_keeps_preparing_snapshot_and_time_unchanged() -> void:
	var config = _config(5.0, 1, 1.0, 10.0)
	var track = TogglePrepareTrackSystem.new(config)
	var train = TrainSystemScript.new(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	track.allow_prepare = false
	var before = _snapshot_values(controller.get_snapshot())
	var pose_calls_before = track.pose_sample_calls
	var recovery_calls_before = track.recovery_calls
	controller.advance_tick(_draw_frame([Vector2i(1, 0)]))
	assert_equal(controller.get_state(), SessionControllerScript.State.PREPARING_DEPARTURE, "Preparing remains")
	assert_equal(_snapshot_values(controller.get_snapshot()), before, "Prior snapshot values remain cached")
	assert_equal(train.get_route_distance_cells(), 0.0, "No departure or advance")
	assert_equal(track.get_cell_records()[0].state, TrackCellRecordScript.State.BUILT, "Earlier construction phase remains committed")
	assert_equal(track.prepare_calls, 1, "Preparation was attempted once")
	assert_equal(track.pose_sample_calls, pose_calls_before, "Preparing failure performs no pose capture")
	assert_equal(track.recovery_calls, recovery_calls_before, "Preparing failure performs no recovery")

func _test_prepare_failure_keeps_running_without_recovery_or_events() -> void:
	var config = _config(5.0, 1, 0.25, 10.0)
	var track = TogglePrepareTrackSystem.new(config)
	var train = TrainSystemScript.new(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
	assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Fixture reaches running")
	track.allow_prepare = false
	var events: Array[String] = []
	controller.snapshot_published.connect(func(_snapshot): events.append("snapshot"))
	controller.session_completed.connect(func(_result): events.append("result"))
	var before = _snapshot_values(controller.get_snapshot())
	var distance_before = train.get_route_distance_cells()
	var elapsed_before = controller.get_snapshot().get_elapsed_ticks()
	var remaining_before = controller.get_snapshot().get_remaining_ticks()
	var pose_calls_before = track.pose_sample_calls
	var recovery_calls_before = track.recovery_calls
	var prepare_calls_before = track.prepare_calls
	controller.advance_tick()
	assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Running remains")
	assert_equal(_snapshot_values(controller.get_snapshot()), before, "No snapshot publication")
	assert_equal(events, [], "No completion or snapshot event")
	assert_equal(train.get_route_distance_cells(), distance_before, "Running distance remains unchanged")
	assert_equal(track.prepare_calls, prepare_calls_before + 1, "Running failure attempts preparation once")
	assert_equal(track.pose_sample_calls, pose_calls_before, "Running failure performs no pose capture")
	assert_equal(track.recovery_calls, recovery_calls_before, "Running failure performs no recovery")
	assert_equal(controller.get_snapshot().get_elapsed_ticks(), elapsed_before, "Running failure does not advance elapsed time")
	assert_equal(controller.get_snapshot().get_remaining_ticks(), remaining_before, "Running failure does not consume remaining time")
	track.allow_prepare = true
	controller.advance_tick()
	assert_equal(controller.get_snapshot().get_elapsed_ticks(), elapsed_before + 1, "Next successful tick advances elapsed exactly once")
	assert_equal(controller.get_snapshot().get_remaining_ticks(), remaining_before - 1, "Next successful tick consumes remaining exactly once")
	assert_equal(track.pose_sample_calls, pose_calls_before + 1, "Only the successful tick captures a running pose")
	assert_equal(track.recovery_calls, recovery_calls_before + 1, "Only the successful tick recovers")

func _test_terminal_snapshot_pose_precedes_reason_only_result_after_full_recovery() -> void:
	var config = _config(5.0, 1, 1.0, 10.0, 1, 0)
	var track = TogglePrepareTrackSystem.new(config)
	track.apply_left_input(_draw_frame([Vector2i(1, 0)]))
	track.advance_construction(1.0)
	var train = TrainSystemScript.new(1.0)
	var expected_pose = track.get_geometry_pieces()[0].sample_nominal(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	var events: Array[String] = []
	var terminal_snapshots: Array = []
	controller.snapshot_published.connect(func(snapshot):
		events.append("snapshot")
		terminal_snapshots.append(snapshot)
	)
	controller.session_completed.connect(func(result):
		events.append("result")
		assert_equal(result.get_reason(), SessionResultScript.Reason.TRACK_END_REACHED, "Reason unchanged")
	)
	controller.advance_tick()
	assert_equal(events, ["snapshot", "result"], "Snapshot publishes first")
	assert_equal(terminal_snapshots.size(), 1, "Terminal tick publishes exactly one snapshot")
	assert_equal(track.get_cell_records().size(), 0, "Zero recovery lag prunes the final piece")
	if terminal_snapshots.size() == 1:
		var terminal_snapshot = terminal_snapshots[0]
		assert_true(terminal_snapshot.get_train_position().is_equal_approx(expected_pose.position), "Pre-recovery pose retained")
		assert_true(terminal_snapshot.get_train_heading().is_equal_approx(expected_pose.heading), "Pre-recovery heading retained")
```

- [ ] **Step 9: Run focused session RED evidence**

```powershell
Confirm-ReflowRedFocused 'test_session_controller.gd' 'Running failure attempts preparation once'
```

Expected: after the Step 3 API surface is present but before the Step 10 fixed-tick implementation, the current RUNNING tick omits the required second preparation call, so the guaranteed assertion `Running failure attempts preparation once` fails. This marker is the exact test failure message, not a method-name substring; it does not depend on parser output, resolver behavior, or a locked-owner diagnostic.

- [ ] **Step 10: Implement the smallest GREEN tick flow**

Store only the temporary/post-motion pose in controller fields; never alter `SessionResult`. The failed-prepare branch must return before recovery, timer, state transition, `_complete`, or `_publish_snapshot`.

Add controller field `_cached_tick_pose: Dictionary = {"position": Vector2.ZERO, "heading": Vector2.RIGHT}` and private `_prepare_or_abort(current_distance: float, through_distance: float) -> bool`, which returns the facade’s Boolean unchanged. It contains no `assert(false)` or fallback sample path. After input/construction, a satisfied preparing state first prepares `[0.0, min(speed-per-tick, built-end)]`; on false it returns from `advance_tick` before `depart`, without changing state. On true it calls `depart(0.0)`, takes one temporary departure-point safety capture that is not published, changes to `RUNNING`, advances nominal motion, then calls `capture_pose` once and stores that post-motion pair. A running state uses `[train distance, min(train distance + speed-per-tick, built-end)]`; false returns before motion/recovery/timer/state/event/snapshot, while true advances and captures exactly once. Only after capture does recovery run; then `_create_snapshot` consumes `_cached_tick_pose` rather than re-sampling geometry.

Pass `_cached_tick_pose.position` and `.heading` into the existing `SessionSnapshotScript.new(...)` constructor after recovery. On a terminal tick, publish this pose-bearing snapshot before emitting `session_completed`; leave `SessionResultScript.new(reason, total, elapsed, remaining)` unchanged. A debug-only diagnostic may record a false preparation result, but it must not abort the deterministic test or release path.

- [ ] **Step 11: Migrate every legacy direct sampler, then run focused GREEN and the full required regression gate**

Before the gate, migrate each current direct sampler by name. In `test_train_system.gd`, in `_test_nominal_progress_and_sampling_delegate_to_track` call `track.prepare_for_train_sampling(0.5, 0.5)` after the train advances to `0.5`, then compare one `capture_pose` pair and the position/heading convenience accessors; in `_test_recovery_preserves_absolute_train_distance`, prepare `(before, before)` before the final absolute-position assertion. In `test_track_system_construction_recovery.gd`, change `_test_recovery_refunds_one_cell_without_renormalizing_geometry` to B–F/G, call `prepare_for_train_sampling(0.5, 4.5)` before the two initial samples and once again before each post-recovery sample. In `test_nominal_train_motion.gd`, make `_test_five_cell_curve_matches_five_straight_cell_time` prepare both tracks at `2.5`; make `_test_position_and_heading_are_continuous_across_piece_boundaries` use `edge = GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON * 1.01`, prepare each `[boundary - edge, boundary + edge]` interval, and compare the two true-side samples with approximate vector/nominal-separation assertions; and make `_test_recovery_preserves_absolute_train_distance` prepare `(3.0, 3.0)` before both samples. In `test_grid_track_runtime.gd`, use B–F/G then prepare `(0.5, 4.5)` in `_test_partial_recovery_preserves_locked_curve_sampling`, `(1.5, 1.5)` in `_test_recovery_preserves_surviving_predecessor_geometry`, and `(1.5, 1.5)` independently in both tracks in `_test_runtime_applies_nonzero_grid_origin_to_sampling`. In `test_track_train_session_controller.gd`, update `_test_departure_transition_moves_from_departure_center`, `_test_recovery_refund_is_not_spendable_until_next_tick`, and `_test_regular_expiry_wins_a_same_tick_track_end_tie` to inspect controller snapshots emitted after controller-owned preparation, not runtime geometry methods. In `test_track_train_app_composition.gd`, change `_snapshot(config, track, state, true)` to call `assert_true(track.prepare_for_train_sampling(train_distance, train_distance))`, then construct `var snapshot_train = TrainSystemScript.new(1.0)`, call `snapshot_train.depart(train_distance)`, and obtain exactly one `snapshot_train.capture_pose(track)` dictionary for the snapshot position/heading; in `_test_standard_curve_intervals_and_integer_hud`, use B–F/G to make the direct running snapshot's owner legitimately locked. This migration is mandatory because `get_position_at_distance_cells`, `get_heading_at_distance_cells`, `TrainSystem.get_position`, and `TrainSystem.get_heading` now require the shared locked owner.

```powershell
Invoke-ReflowFocused 'test_session_controller.gd'
Invoke-ReflowFocused 'test_grid_track_runtime.gd'
Invoke-ReflowFocused 'test_track_system_construction_recovery.gd'
Invoke-ReflowFocused 'test_train_system.gd'
Invoke-ReflowFocused 'test_nominal_train_motion.gd'
Invoke-ReflowFocused 'test_track_train_session_controller.gd'
Invoke-ReflowFocused 'test_track_train_app_composition.gd'
Confirm-ReflowUnpreparedPoseProbe
Invoke-ReflowFullGate
```

Expected: both safe-return states preserve their previous snapshot and all prohibited fields, terminal pose survives final-piece pruning, snapshot event precedes result event, and all full-gate anchors pass.

- [ ] **Step 12: Stage the complete Task 2 allowlist and commit**

```powershell
git add -- `
  godot-project-moe-rail-way/tests/run_all.gd `
  godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd `
  godot-project-moe-rail-way/src/domain/track/track_system.gd `
  godot-project-moe-rail-way/src/domain/train/train_system.gd `
  godot-project-moe-rail-way/src/domain/session/session_controller.gd `
  godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd `
  godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd `
  godot-project-moe-rail-way/tests/unit/test_train_system.gd `
  godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd `
  godot-project-moe-rail-way/tests/unit/test_session_controller.gd `
  godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd `
  godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd
git diff --cached --check
git diff --cached --name-only
git commit -m "feat: prepare and publish locked train poses safely"
```

- [ ] **Step 13: Obtain independent Sol reviews**

Request a Sol specification review against spec Sections 3.2, 6, 7, 9, 12, and 14, then a separate Sol quality review of epsilon ownership, every migrated direct sampler, state transitions, cached pose ownership, terminal recovery, and preservation of `SessionResult`. A fresh Terra worker resolves findings only through this merged Task 2 allowlist, reruns focused tests/full gate, then repeats both Sol reviews.

### Task 3: Rendering, Multi-Frame Input, and Windows Evidence

**Files:**

- Modify: `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- Modify: `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- Modify: `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd`
- Modify: `godot-project-moe-rail-way/tests/manual/track_train_windows.md`

**Interfaces:**

- Consumes: Task 1 detached piece `exit_support_route_serial`, record states, and Task 2 snapshots.
- Produces: solid rendering for `BUILT` intervals even when their geometry reflows; cancellation hover based on construction state plus support metadata, with no new visual style.

- [ ] **Step 1: Write failing view tests**

In `test_track_field_view_input.gd`, add all four tests to `run()` before `return finish()`, add `GridTrackRuntimeScript` and `TrackGeometryPieceScript` beside existing preloads, and add the complete snapshot/piece/runtime helpers below before the first test. Task 1 remains the domain authority for right-click no-op assertions; the input integration below dispatches the real right click for the active support. These view tests prove the affordance is absent before that input reaches the domain.

```gdscript
# test_track_field_view_input.gd, run(): append before return finish().
_test_built_reflow_interval_stays_solid_without_provisional_style()
_test_ordinary_provisional_ghost_keeps_cancel_hover()
_test_locked_non_support_ghost_has_no_cancel_hover()
_test_exit_support_ghost_has_no_cancel_hover()
```

```gdscript
# test_track_field_view_input.gd: add beside the existing preloads.
const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")

# Add these helpers below the existing test helpers. Do not retain the old
# `_view_b_through_f_curve_piece()` helper: a hand-authored already-curved
# snapshot cannot prove a runtime reflow.
func _runtime_piece_for_serial(
	pieces: Array[TrackGeometryPieceScript], route_serial: int
) -> TrackGeometryPieceScript:
	for piece in pieces:
		if piece.contains_serial(route_serial):
			return piece
	return null

func _runtime_record_for_serial(
	records: Array[TrackCellRecordScript], route_serial: int
) -> TrackCellRecordScript:
	for record in records:
		if record.route_serial == route_serial:
			return record
	return null

func _view_interval_for_serial(observation: Dictionary, route_serial: int) -> Dictionary:
	for interval in observation.get("intervals", []):
		if interval.get("route_serial", -1) == route_serial:
			return interval
	return {}

func _points_materially_differ(first: PackedVector2Array, second: PackedVector2Array) -> bool:
	if first.size() != second.size():
		return true
	for index in range(first.size()):
		if first[index].distance_to(second[index]) >= 1.0:
			return true
	return false

func _view_straight_piece(route_serial: int, cell: Vector2i) -> TrackGeometryPieceScript:
	var piece = TrackGeometryPieceScript.new()
	piece.group_id = route_serial
	piece.kind = TrackGeometryPieceScript.Kind.STRAIGHT
	piece.first_route_serial = route_serial
	piece.last_route_serial = route_serial
	piece.nominal_length_cells = 1
	piece.absolute_start_distance_cells = float(route_serial - 1)
	piece.footprint_cells = [cell]
	var center := Vector2((float(cell.x) + 0.5) * 40.0, (float(cell.y) + 0.5) * 40.0)
	piece.centerline = PackedVector2Array([center - Vector2(20.0, 0.0), center])
	piece.active_local_end_cells = 1.0
	return piece

func _view_snapshot(records: Array[TrackCellRecordScript], pieces: Array[TrackGeometryPieceScript]) -> SessionSnapshotScript:
	return SessionSnapshotScript.new(
		1, 0, 1, 60, true, SessionControllerScript.State.PREPARING_DEPARTURE,
		records, pieces
	)

func _built_runtime_straight_head() -> GridTrackRuntimeScript:
	var runtime = GridTrackRuntimeScript.new(Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_equal(runtime.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	]), 3, "B through D begin as actual runtime straights")
	assert_equal(runtime.advance_construction(3.0), 3.0, "B through D are built before the turn exists")
	return runtime

func _exit_support_runtime() -> GridTrackRuntimeScript:
	var runtime = GridTrackRuntimeScript.new(Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_equal(runtime.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "B through F curve fixture appends")
	assert_equal(runtime.append_cells([Vector2i(2, 3)]), 1, "Distinct G continues F direction")
	return runtime

func _test_built_reflow_interval_stays_solid_without_provisional_style() -> void:
	var fixture := _fixture()
	var runtime := _built_runtime_straight_head()
	var initially_built_serials := [1, 2, 3]
	var before_records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var before_pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	fixture.view.present(_view_snapshot(before_records, before_pieces))
	var before_observation: Dictionary = fixture.view.get_render_observation()
	var before_points_by_serial: Dictionary = {}
	for route_serial in initially_built_serials:
		var before_record := _runtime_record_for_serial(before_records, route_serial)
		var before_owner := _runtime_piece_for_serial(before_pieces, route_serial)
		assert_not_null(before_record, "Built serial %d exists before the turn" % route_serial)
		assert_not_null(before_owner, "Built serial %d has an actual runtime owner before the turn" % route_serial)
		if before_record != null:
			assert_equal(before_record.route_serial, route_serial, "Initial record serial is preserved")
			assert_equal(before_record.state, TrackCellRecordScript.State.BUILT, "Initial serial %d is built" % route_serial)
			assert_false(before_record.geometry_locked, "Initial serial %d remains provisional" % route_serial)
		if before_owner != null:
			assert_equal(before_owner.kind, TrackGeometryPieceScript.Kind.STRAIGHT, "Initial serial %d has a straight runtime owner" % route_serial)
			assert_false(before_owner.locked, "Initial serial %d owner is provisional" % route_serial)
		var before_interval := _view_interval_for_serial(before_observation, route_serial)
		assert_false(before_interval.is_empty(), "The view captures actual serial %d before reflow" % route_serial)
		if not before_interval.is_empty():
			assert_equal(before_interval.route_serial, route_serial, "Initial rendered serial is preserved")
			assert_equal(before_interval.state, TrackCellRecordScript.State.BUILT, "Initial built serial uses solid render state")
			assert_false(before_interval.locked, "Initial rendered serial is provisional, not a style")
			before_points_by_serial[route_serial] = before_interval.points

	assert_equal(runtime.append_cells([
		Vector2i(2, 1), Vector2i(2, 2),
	]), 2, "E and F make the same B through D serials reclassify through the runtime")
	var after_records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var after_pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	var after_owner := _runtime_piece_for_serial(after_pieces, 1)
	assert_not_null(after_owner, "B retains one runtime owner after reflow")
	if after_owner == null:
		fixture.parent.free()
		return
	assert_equal(after_owner.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Runtime reclassifies B through F as a 3x3 curve")
	assert_equal(after_owner.first_route_serial, 1, "Reflow curve still owns B")
	assert_equal(after_owner.last_route_serial, 5, "Reflow curve now owns B through F")
	assert_false(after_owner.locked, "Reflowed owner remains provisional")
	fixture.view.present(_view_snapshot(after_records, after_pieces))
	var after_observation: Dictionary = fixture.view.get_render_observation()
	var geometry_materially_reflowed := false
	for route_serial in initially_built_serials:
		var record := _runtime_record_for_serial(after_records, route_serial)
		var owner := _runtime_piece_for_serial(after_pieces, route_serial)
		assert_not_null(record, "Built serial %d survives runtime reflow" % route_serial)
		assert_not_null(owner, "Built serial %d retains a runtime owner after reflow" % route_serial)
		if record != null:
			assert_equal(record.route_serial, route_serial, "Reflow preserves serial identity")
			assert_equal(record.state, TrackCellRecordScript.State.BUILT, "Runtime reflow preserves built state for serial %d" % route_serial)
			assert_false(record.geometry_locked, "Runtime reflow does not lock serial %d" % route_serial)
		if owner != null:
			assert_equal(owner.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Reflowed serial %d belongs to the curve" % route_serial)
			assert_false(owner.locked, "Reflowed serial %d owner remains provisional" % route_serial)
		var after_interval := _view_interval_for_serial(after_observation, route_serial)
		assert_false(after_interval.is_empty(), "The view captures actual serial %d after reflow" % route_serial)
		if not after_interval.is_empty():
			assert_equal(after_interval.route_serial, route_serial, "Reflowed rendered serial is preserved")
			assert_equal(after_interval.state, TrackCellRecordScript.State.BUILT, "Reflowed built serial remains in the solid render state")
			assert_false(after_interval.locked, "Reflowed built serial has no provisional render style")
			if before_points_by_serial.has(route_serial):
				var before_points: PackedVector2Array = before_points_by_serial[route_serial]
				geometry_materially_reflowed = geometry_materially_reflowed or _points_materially_differ(before_points, after_interval.points)
	assert_true(geometry_materially_reflowed, "Runtime reflow materially changes rendered centerline points while built serials stay solid")
	fixture.parent.free()

func _test_ordinary_provisional_ghost_keeps_cancel_hover() -> void:
	var fixture := _fixture()
	var ghost = TrackCellRecordScript.new(6, Vector2i(3, 2), 5.0)
	ghost.state = TrackCellRecordScript.State.RESERVED_GHOST
	fixture.view.present(_view_snapshot([ghost], [_view_straight_piece(6, ghost.cell)]))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(3, 2), "Ordinary provisional ghost has cancel hover")
	fixture.parent.free()

func _test_locked_non_support_ghost_has_no_cancel_hover() -> void:
	var fixture := _fixture()
	var ghost = TrackCellRecordScript.new(6, Vector2i(3, 2), 5.0)
	ghost.state = TrackCellRecordScript.State.RESERVED_GHOST
	ghost.geometry_locked = true
	var locked_piece = _view_straight_piece(6, ghost.cell)
	locked_piece.locked = true
	fixture.view.present(_view_snapshot([ghost], [locked_piece]))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Locked non-support ghost has no hover")
	fixture.parent.free()

func _test_exit_support_ghost_has_no_cancel_hover() -> void:
	var fixture := _fixture()
	var runtime = _exit_support_runtime()
	var records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	assert_equal(records.size(), 6, "Snapshot contains active B through G records")
	var predecessor = null
	var support_owner = null
	for piece in pieces:
		if piece.contains_serial(1):
			predecessor = piece
		if piece.contains_serial(6):
			support_owner = piece
	assert_not_null(predecessor, "B through F predecessor piece exists")
	assert_not_null(support_owner, "G has its own detached active piece")
	if predecessor != null:
		assert_true(predecessor.locked, "Horizon locks B through F")
		assert_equal(predecessor.exit_support_route_serial, 6, "Locked predecessor names G as support")
	if support_owner != null:
		assert_false(support_owner.locked, "G support piece remains provisional")
	var support_owners := 0
	for piece in pieces:
		if piece.contains_serial(6):
			support_owners += 1
	assert_equal(support_owners, 1, "G has exactly one owning detached piece")
	fixture.view.present(_view_snapshot(records, pieces))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 140.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i.ZERO), Vector2i(-1, -1), "Support has no hover")
	fixture.parent.free()
```

Add the following physical multi-frame integration flow. Add the stated preload beside the existing preloads, and place the flow in `_run()` after the existing corner fixture.

```gdscript
# run_track_train_input_integration.gd
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")

var reflow_track = TrackSystemScript.new(config)
await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
await _consume(shell, reflow_track)
await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 180.0)), MOUSE_BUTTON_MASK_LEFT))
var reflow_frame = await _consume(shell, reflow_track)
_assert_equal(reflow_frame.crossed_cells, [Vector2i(5, 3), Vector2i(5, 4)], "Second frame emits only cells not consumed by the first frame")
_assert_equal(reflow_track.advance_construction(5.0), 5.0, "Head completes without geometry locking")
_assert_equal(reflow_track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Completed head reflows as curve")
await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 220.0)), MOUSE_BUTTON_MASK_LEFT))
var support_frame = await _consume(shell, reflow_track)
_assert_equal(support_frame.crossed_cells, [Vector2i(5, 5)], "Third frame appends G as exit support along F's direction")
var support_count := reflow_track.get_cell_records().size()
var g_viewport_position := _logical_to_viewport(view, Vector2(220.0, 220.0))
await _release(shell, reflow_track, g_viewport_position)
_assert_true(not reflow_track._left_capture_active, "Releasing G clears left capture before the support right-click")
await _deliver(_button(g_viewport_position, MOUSE_BUTTON_RIGHT, true))
await _consume(shell, reflow_track)
_assert_equal(reflow_track.get_cell_records().size(), support_count, "Right-clicking exit support is a no-op")
_assert_equal(reflow_track.get_endpoint_cell(), Vector2i(5, 5), "Exit support remains endpoint")
```

Add terminal publication ordering to the real-app integration without changing production code.

```gdscript
# run_track_train_app_integration.gd, PresetFixture
var event_order: Array[String] = []

# compose_preset_fixture(), after fixture.controller is assigned
fixture.controller.snapshot_published.connect(func(_snapshot): fixture.event_order.append("snapshot"))
app.session_result_presented.connect(func(_result): fixture.event_order.append("result"))

# assert_centered_preset_end_to_end(), after the existing result assertions
_assert_equal(fixture.event_order.slice(-2), ["snapshot", "result"], "Terminal snapshot publishes before result")
```

Do not edit the manual evidence in this step. Step 7 appends one new dated English evidence section only after the launcher/manual observation succeeds; it must cover the B–F/G slow route, solid B–E while F builds and reclassifies, G hover/right-click no-op, extension from G, entry without jump, rejected append preservation, and terminal snapshot before overlay. Do not rewrite the historical 2026-08-24 observations.

- [ ] **Step 2: Run focused RED evidence**

```powershell
Confirm-ReflowRedFocused 'test_track_field_view_input.gd' 'Support has no hover'
```

Expected: current `_is_cancelable_cell` checks only `RESERVED_GHOST`, so both a locked ghost and an exit-support ghost receive a hover affordance. The real integration right-click remains a no-op through Task 1’s runtime eligibility transaction.

When this new real-runtime reflow test is added during a review-fix flow against already-GREEN production, prove that the test is sensitive instead of calling the pre-existing GREEN result sufficient. Make the following **local, temporary presentation-only mutation** in `track_field_view.gd` inside `_build_intervals`, run the focused view suite, require the exact `Initial built serial uses solid render state` failure, then restore the exact original `"state": record.state,` line before any GREEN run, staging, or commit. Never commit the mutation.

```gdscript
# Temporary mutation-check only. Replace the existing interval dictionary entry:
"state": (
	TrackCellRecordScript.State.RESERVED_GHOST
	if not owner.locked else record.state
),

# Restore before GREEN/staging/commit:
"state": record.state,
```

This mutation changes only the view's observed presentation state for provisional owners; it does not alter runtime resolution, records, inventory, or construction. The reflow test must fail because B is actually `BUILT` while its owner remains provisional. After restoring, require `git diff -- godot-project-moe-rail-way/src/presentation/track/track_field_view.gd` to be empty before proceeding.

- [ ] **Step 3: Implement the smallest GREEN behavior and keep the added integration assertions**

Keep `_draw` state branches unchanged. Add a detached-piece metadata lookup only to cancellation eligibility.

```gdscript
func _is_cancelable_cell(cell: Vector2i) -> bool:
	for record in _presented_cells:
		if record.cell == cell:
			if record.state != TrackCellRecordScript.State.RESERVED_GHOST:
				return false
			for piece in _presented_pieces:
				if piece.contains_serial(record.route_serial) and (piece.locked or record.geometry_locked):
					return false
				if piece.exit_support_route_serial == record.route_serial:
					return false
			return true
	return false
```

Do not add a color, icon, line pattern, HUD text, or new render-observation style field. Retain the existing `BUILT`/`BUILDING`/`RESERVED_GHOST` draw branches.

- [ ] **Step 4: Run focused GREEN and the full required regression gate**

```powershell
Invoke-ReflowFocused 'test_track_field_view_input.gd'
Invoke-ReflowScript 'res://tests/integration/run_track_train_input_integration.gd' 'PASS: track train input integration'
Invoke-ReflowScript 'res://tests/integration/run_track_train_app_integration.gd' 'PASS: track train app integration'
Invoke-ReflowFullGate
```

Expected: built intervals are still solid while unlocked geometry may reflow; ordinary ghost suffixes hover; support ghosts and locked ghosts do not hover; all full-gate anchors pass.

#### Task 3 Safety Ledger Ruling

**Ruling — seal the tested Task 3 source, then use a preserved, task-owned local-`main` wrapper with a sanitized child Git environment.** The unchanged editor launcher deliberately accepts only a clean `main` worktree tracking `origin/main` at divergence `0/0` and archives only committed `HEAD`; a dirty feature branch is therefore not a valid launcher source. The implementation commit is the durable tested source, while the later evidence-only commit must never be represented as the source that was playtested. The wrapper’s bare origin receives the verified commit only through local sanitized `fetch`, never an outward push. **Cost if wrong:** bypassing the launcher’s branch/HEAD contract, inheriting Git routing/config injection, treating a reparse-point or identity-mismatched wrapper as preserved, or deleting an identity-lost wrapper can misrepresent uncommitted source as tested or destroy evidence; weakening those controls invalidates the launcher’s HEAD-only, source-preservation, and diagnostics guarantees.

The final Task 3 allowlist remains exactly the five paths in the parent **Files** block. The normal Task 3 sequence deliberately has two focused commits: the four implementation/test paths first, then the manual-evidence path only. Do not stage the plan, any other documentation, or any unrelated path in either commit. The task-owned wrapper is preserved at handoff; this Task does not authorize its cleanup, worktree cleanup, branch deletion, remote mutation, copy-back, process enumeration, process termination, or timeout termination.

#### Task 3 Git and Wrapper Safety Helpers

Run this block before the revised sequence’s first Git command. `Assert-Task3CleanGitEnvironment` is the launcher’s exact routing/config-injection preflight. `Invoke-Task3FeatureGit` gives every feature Git command immediate captured exit-code enforcement without mutating its environment. `Invoke-Task3WrapperGit` is the only helper permitted for wrapper mutations: it starts a child `ProcessStartInfo`, removes every inherited `GIT_*` variable, sets only child-local `GIT_CONFIG_NOSYSTEM=1` and `GIT_CONFIG_GLOBAL=NUL`, captures stdout/stderr, and throws on a nonzero result. Neither helper mutates the parent environment.

```powershell
function Assert-Task3CleanGitEnvironment {
  $exactNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($name in @(
    'GIT_DIR','GIT_WORK_TREE','GIT_COMMON_DIR','GIT_INDEX_FILE',
    'GIT_OBJECT_DIRECTORY','GIT_ALTERNATE_OBJECT_DIRECTORIES','GIT_NAMESPACE',
    'GIT_CEILING_DIRECTORIES','GIT_DISCOVERY_ACROSS_FILESYSTEM',
    'GIT_CONFIG','GIT_CONFIG_PARAMETERS','GIT_CONFIG_COUNT','GIT_CONFIG_SYSTEM',
    'GIT_CONFIG_GLOBAL','GIT_CONFIG_NOSYSTEM','GIT_EXEC_PATH','GIT_PREFIX',
    'GIT_INTERNAL_SUPER_PREFIX'
  )) { $exactNames.Add($name) | Out-Null }
  foreach ($keyObject in @([Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Process).Keys | Sort-Object)) {
    $key = [string]$keyObject
    if ($exactNames.Contains($key) -or
      $key.StartsWith('GIT_CONFIG_KEY_',[StringComparison]::OrdinalIgnoreCase) -or
      $key.StartsWith('GIT_CONFIG_VALUE_',[StringComparison]::OrdinalIgnoreCase)) {
      throw "STOP: prohibited Git environment variable: $key"
    }
  }
}

function Invoke-Task3GitProcess {
  param([string]$WorkingDirectory, [string[]]$Arguments, [bool]$SanitizeChildGit)
  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $Task3GitExecutable
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  if ($SanitizeChildGit) {
    foreach ($keyObject in @($psi.Environment.Keys)) {
      if (([string]$keyObject).StartsWith('GIT_',[StringComparison]::OrdinalIgnoreCase)) {
        $psi.Environment.Remove([string]$keyObject) | Out-Null
      }
    }
    $psi.Environment['GIT_CONFIG_NOSYSTEM'] = '1'
    $psi.Environment['GIT_CONFIG_GLOBAL'] = 'NUL'
  }
  foreach ($argument in $Arguments) { $psi.ArgumentList.Add($argument) }
  $process = [Diagnostics.Process]::Start($psi)
  if ($null -eq $process) { throw "STOP: Git process did not start: $($Arguments -join ' ')" }
  try {
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdoutTask, $stderrTask))
    $result = [pscustomobject]@{ ExitCode = $process.ExitCode; Stdout = $stdoutTask.Result; Stderr = $stderrTask.Result }
    if ($result.ExitCode -ne 0) { throw "STOP: Git failed ($($result.ExitCode)): $($Arguments -join ' '); $($result.Stderr)" }
    return $result
  }
  finally { $process.Dispose() }
}

function Invoke-Task3FeatureGit { param([string[]]$Arguments) return Invoke-Task3GitProcess -WorkingDirectory $Task3FeatureRoot -Arguments $Arguments -SanitizeChildGit $false }
function Invoke-Task3WrapperGit { param([string]$WorkingDirectory, [string[]]$Arguments) return Invoke-Task3GitProcess -WorkingDirectory $WorkingDirectory -Arguments $Arguments -SanitizeChildGit $true }
function Get-Task3Lines([string]$Text) { return @($Text -split "`r?`n" | Where-Object { $_ -ne '' }) }
function Get-Task3CanonicalPath([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  $volumeRoot = [IO.Path]::GetPathRoot($full)
  if ($full.Equals($volumeRoot,[StringComparison]::OrdinalIgnoreCase)) { return $volumeRoot }
  return $full.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
}
function Get-Task3DirectoryIdentity([string]$Path) {
  $canonical = Get-Task3CanonicalPath $Path
  $result = Invoke-Task3Native -Executable $Task3FsutilExecutable -Arguments @('file','queryfileid',$canonical) -WorkingDirectory $canonical
  $matches = [regex]::Matches($result.Stdout,'(?i)0x[0-9a-f]{32}')
  if ($matches.Count -ne 1) { throw "STOP: unexpected fsutil identity output for $canonical" }
  return "$([IO.Path]::GetPathRoot($canonical).ToUpperInvariant())|$($matches[0].Value.ToLowerInvariant())"
}
function Invoke-Task3Native {
  param([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory)
  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $Executable; $psi.WorkingDirectory = $WorkingDirectory; $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
  foreach ($argument in $Arguments) { $psi.ArgumentList.Add($argument) }
  $process = [Diagnostics.Process]::Start($psi)
  if ($null -eq $process) { throw "STOP: native process did not start: $Executable" }
  try {
    $stdoutTask = $process.StandardOutput.ReadToEndAsync(); $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit(); [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdoutTask, $stderrTask))
    $result = [pscustomobject]@{ ExitCode = $process.ExitCode; Stdout = $stdoutTask.Result; Stderr = $stderrTask.Result }
    if ($result.ExitCode -ne 0) { throw "STOP: native command failed ($($result.ExitCode)): $Executable $($Arguments -join ' '); $($result.Stderr)" }
    return $result
  }
  finally { $process.Dispose() }
}
function Assert-Task3ExistingOrdinaryPathChain([string]$Path, [string]$Boundary) {
  $canonicalPath = Get-Task3CanonicalPath $Path; $canonicalBoundary = Get-Task3CanonicalPath $Boundary
  $prefix = $canonicalBoundary
  if (-not $prefix.EndsWith([IO.Path]::DirectorySeparatorChar) -and -not $prefix.EndsWith([IO.Path]::AltDirectorySeparatorChar)) { $prefix += [IO.Path]::DirectorySeparatorChar }
  if ($canonicalPath -ne $canonicalBoundary -and -not $canonicalPath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw "STOP: path escapes boundary: $canonicalPath" }
  if (-not (Test-Path -LiteralPath $canonicalPath)) { throw "STOP: path missing: $canonicalPath" }
  $current = $canonicalPath
  while ($true) {
    if (([IO.File]::GetAttributes($current)).HasFlag([IO.FileAttributes]::ReparsePoint)) { throw "STOP: reparse point in path chain: $current" }
    if ($current.Equals($canonicalBoundary,[StringComparison]::OrdinalIgnoreCase)) { break }
    $parent = [IO.Path]::GetDirectoryName($current)
    if ([string]::IsNullOrEmpty($parent) -or $parent.Equals($current,[StringComparison]::OrdinalIgnoreCase)) { throw "STOP: boundary was not reached from: $canonicalPath" }
    $current = Get-Task3CanonicalPath $parent
  }
  return $canonicalPath
}
function Assert-Task3TempParentOutsideRepositoryIdentity([string]$TempParent, [string]$RepositoryIdentity) {
  $cursor = Get-Task3CanonicalPath $TempParent
  while ($true) {
    if ((Get-Task3DirectoryIdentity $cursor) -ceq $RepositoryIdentity) { throw "STOP: temp parent ancestor resolves to repository identity: $cursor" }
    $parent = [IO.Path]::GetDirectoryName($cursor)
    if ([string]::IsNullOrEmpty($parent) -or $parent.Equals($cursor,[StringComparison]::OrdinalIgnoreCase)) { break }
    $cursor = Get-Task3CanonicalPath $parent
  }
}
function Assert-Task3OwnedWrapper([bool]$RequireExists) {
  Assert-Task3ExistingOrdinaryPathChain $Task3TempParent ([IO.Path]::GetPathRoot($Task3TempParent)) | Out-Null
  if ((Get-Task3DirectoryIdentity $Task3TempParent) -cne $Task3CapturedTempParentIdentity) { throw 'STOP: task wrapper parent identity changed' }
  if ([IO.Path]::GetDirectoryName($Task3Wrapper) -cne $Task3TempParent) { throw 'STOP: task wrapper immediate parent changed' }
  if ([IO.Path]::GetFileName($Task3Wrapper) -notmatch '^moerail-task3-playtest-[0-9a-f]{32}$') { throw 'STOP: task wrapper leaf is not owned' }
  $exists = Test-Path -LiteralPath $Task3Wrapper
  if ($exists -ne $RequireExists) { throw "STOP: task wrapper existence mismatch: $Task3Wrapper" }
  if ($RequireExists) {
    Assert-Task3ExistingOrdinaryPathChain $Task3Wrapper $Task3TempParent | Out-Null
    if ((Get-Task3DirectoryIdentity $Task3Wrapper) -cne $Task3CapturedWrapperIdentity) { throw 'STOP: task wrapper identity changed' }
  }
}
function Assert-Task3WrapperDescendants {
  Assert-Task3OwnedWrapper $true
  $directories = @($Task3Wrapper); $index = 0
  while ($index -lt $directories.Count) {
    $directory = $directories[$index]
    if (([IO.File]::GetAttributes($directory)).HasFlag([IO.FileAttributes]::ReparsePoint)) { throw "STOP: reparse point in task wrapper: $directory" }
    try { $children = [IO.Directory]::GetFileSystemEntries($directory) }
    catch { throw "STOP: failed to enumerate task wrapper descendant ${directory}: $($_.Exception.Message)" }
    foreach ($child in $children) {
      $attributes = [IO.File]::GetAttributes($child)
      if ($attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) { throw "STOP: reparse point in task wrapper descendant: $child" }
      if ($attributes.HasFlag([IO.FileAttributes]::Directory)) { $directories += $child }
    }
    $index++
  }
}
function Assert-Task3CapturedWrapperDirectory([string]$Path, [string]$CapturedIdentity, [string]$Label) {
  if ([string]::IsNullOrWhiteSpace($CapturedIdentity)) { throw "STOP: $Label identity was not captured" }
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw "STOP: $Label directory is missing" }
  Assert-Task3ExistingOrdinaryPathChain $Path $Task3Wrapper | Out-Null
  if ((Get-Task3DirectoryIdentity $Path) -cne $CapturedIdentity) { throw "STOP: $Label identity changed" }
}
function Assert-Task3WrapperState([bool]$RequireBare, [bool]$RequireClone) {
  Assert-Task3WrapperDescendants
  if ($RequireBare) { Assert-Task3CapturedWrapperDirectory $Task3BareOrigin $Task3CapturedBareIdentity 'task bare origin' }
  if ($RequireClone) { Assert-Task3CapturedWrapperDirectory $Task3LauncherRepository $Task3CapturedCloneIdentity 'task launcher clone' }
}
function Get-Task3CapturedIdentityText([string]$Identity) {
  if ([string]::IsNullOrWhiteSpace($Identity)) { return '<not-captured>' }
  return $Identity
}
function Write-Task3WrapperFailureMarker {
  try {
    Assert-Task3WrapperState $true $true
    Write-Host "TASK3_PRESERVED_WRAPPER: $Task3Wrapper"
  }
  catch {
    Write-Host "TASK3_WRAPPER_IDENTITY_LOST: last-known-wrapper=$Task3Wrapper captured-parent=$(Get-Task3CapturedIdentityText $Task3CapturedTempParentIdentity) captured-root=$(Get-Task3CapturedIdentityText $Task3CapturedWrapperIdentity) captured-bare=$(Get-Task3CapturedIdentityText $Task3CapturedBareIdentity) captured-clone=$(Get-Task3CapturedIdentityText $Task3CapturedCloneIdentity)"
  }
}
function Get-Task3CapturedDirectoryIdentityOrReport([string]$Path) {
  try { return Get-Task3DirectoryIdentity $Path }
  catch { Write-Task3WrapperFailureMarker; throw }
}
function Assert-Task3WrapperStateOrReport([bool]$RequireBare, [bool]$RequireClone) {
  try { Assert-Task3WrapperState $RequireBare $RequireClone }
  catch { Write-Task3WrapperFailureMarker; throw }
}
function Invoke-Task3GuardedWrapperGit {
  param([string]$WorkingDirectory, [string[]]$Arguments, [bool]$RequireBare, [bool]$RequireClone)
  Assert-Task3WrapperStateOrReport $RequireBare $RequireClone
  return Invoke-Task3WrapperGit -WorkingDirectory $WorkingDirectory -Arguments $Arguments
}
```

- [ ] **Step 5: Establish pre-Git identity gates and seal the automated-GREEN implementation**

Before any Git command, run the exact ambient-variable rejection above, resolve the two executables, and prove that the feature and primary chains are ordinary. Capture their identities. The task wrapper is created later only below an ordinary system temp parent whose entire path chain reaches the volume root without a reparse point and whose ancestor identities contain neither repository identity.

```powershell
Assert-Task3CleanGitEnvironment
$Task3GitExecutable = (Get-Command git.exe -ErrorAction Stop).Source
$Task3FsutilExecutable = (Get-Command fsutil.exe -ErrorAction Stop).Source
$Task3FeatureRoot = (Resolve-Path -LiteralPath 'D:\godot\MoeRailWay-worktrees\feature-reflowable-track-head').Path
$Task3PrimaryRoot = (Resolve-Path -LiteralPath 'D:\godot\MoeRailWay').Path
Assert-Task3ExistingOrdinaryPathChain $Task3FeatureRoot ([IO.Path]::GetPathRoot($Task3FeatureRoot)) | Out-Null
Assert-Task3ExistingOrdinaryPathChain $Task3PrimaryRoot ([IO.Path]::GetPathRoot($Task3PrimaryRoot)) | Out-Null
$Task3FeatureIdentity = Get-Task3DirectoryIdentity $Task3FeatureRoot
$Task3PrimaryIdentity = Get-Task3DirectoryIdentity $Task3PrimaryRoot
$Task3FeatureTopLevel = Get-Task3CanonicalPath (Invoke-Task3FeatureGit @('rev-parse','--show-toplevel')).Stdout.Trim()
if ($Task3FeatureTopLevel -ne (Get-Task3CanonicalPath $Task3FeatureRoot)) { throw 'STOP: feature worktree identity mismatch' }
$Task3ExpectedFeatureBranch = 'feature/reflowable-track-head'
if ((Invoke-Task3FeatureGit @('branch','--show-current')).Stdout.Trim() -ne $Task3ExpectedFeatureBranch) { throw 'STOP: feature branch mismatch' }
$Task3Base = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
$Task3CodePaths = @(
  'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
  'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd',
  'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd',
  'godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd'
)
$Task3ManualPath = 'godot-project-moe-rail-way/tests/manual/track_train_windows.md'
$Task3Unstaged = Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--name-only')).Stdout | Sort-Object
if (Compare-Object $Task3Unstaged ($Task3CodePaths | Sort-Object)) { throw 'STOP: Task 3 unstaged paths differ from the four implementation/test paths' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--cached','--name-only')).Stdout).Count -ne 0) { throw 'STOP: index is not empty before Task 3 staging' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--name-only','--',$Task3ManualPath)).Stdout).Count -ne 0) { throw 'STOP: manual evidence changed before launcher success' }
Invoke-Task3FeatureGit -Arguments (@('add','--') + $Task3CodePaths) | Out-Null
Invoke-Task3FeatureGit @('diff','--cached','--check') | Out-Null
$Task3Staged = Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--cached','--name-only')).Stdout | Sort-Object
if (Compare-Object $Task3Staged ($Task3CodePaths | Sort-Object)) { throw 'STOP: staged Task 3 implementation path set is not exact' }
Invoke-Task3FeatureGit @('commit','-m','feat: preserve solid reflow rendering and support hover rules') | Out-Null
$Task3TestedImplementationSha = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3TestedImplementationSha + '^'))).Stdout.Trim() -ne $Task3Base) { throw 'STOP: implementation parent differs from TASK3_BASE' }
if ((Invoke-Task3FeatureGit @('rev-parse','--verify',('refs/heads/' + $Task3ExpectedFeatureBranch))).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'STOP: verified feature branch does not name tested implementation SHA' }
$Task3ImplementationPaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',($Task3Base + '..' + $Task3TestedImplementationSha))).Stdout | Sort-Object
if (Compare-Object $Task3ImplementationPaths ($Task3CodePaths | Sort-Object)) { throw 'STOP: durable implementation commit path set is not exact' }
Invoke-Task3FeatureGit @('diff','--check',($Task3Base + '..' + $Task3TestedImplementationSha)) | Out-Null
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: implementation commit did not leave a clean worktree' }
Write-Host "TASK3_BASE: $Task3Base"
Write-Host "TASK3_TESTED_IMPLEMENTATION_SHA: $Task3TestedImplementationSha"
```

Expected: the four code/test paths are the only durable implementation diff and commit as `feat: preserve solid reflow rendering and support hover rules`. Retain `TASK3_TESTED_IMPLEMENTATION_SHA`; it is the only feature SHA that the later manual evidence may call tested.

- [ ] **Step 6: Materialize the preserved local-`main` wrapper and run the manual editor play**

Verify exact GUI Godot through the captured native helper. Only then create the wrapper, capture its root/bare/clone identities, and use `Invoke-Task3WrapperGit` for its bare-repository initialization, local fetch, and clone. The helper receives `TASK3_TESTED_IMPLEMENTATION_SHA` into `refs/heads/main` without contacting or changing the actual `origin/main`; it receives no other heads ref. Before every wrapper mutation or safety read, enumerate every existing wrapper descendant, reject reparse points, and revalidate captured parent/root/bare/clone identities. Compare committed objects only: clean tracked state, project tree OIDs, and four exact code-path blob OIDs. Ignored/generated files are deliberately excluded from these object comparisons; the unchanged launcher independently verifies the clone’s working bytes against its pinned tracked manifest.

```powershell
$Task3ExpectedGodot = '4.7.1.stable.official.a13da4feb'
$Task3EditorGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe'
$Task3GodotVersionResult = Invoke-Task3Native -Executable $Task3EditorGodot -Arguments @('--version') -WorkingDirectory $Task3FeatureRoot
$Task3GodotVersionLines = @(Get-Task3Lines $Task3GodotVersionResult.Stdout)
if ($Task3GodotVersionLines.Count -ne 1 -or $Task3GodotVersionLines[0].Trim() -ne $Task3ExpectedGodot -or -not [string]::IsNullOrWhiteSpace($Task3GodotVersionResult.Stderr)) { throw 'STOP: exact GUI Godot version output mismatch' }
$Task3TempParent = Get-Task3CanonicalPath ([IO.Path]::GetTempPath())
Assert-Task3ExistingOrdinaryPathChain $Task3TempParent ([IO.Path]::GetPathRoot($Task3TempParent)) | Out-Null
Assert-Task3TempParentOutsideRepositoryIdentity $Task3TempParent $Task3FeatureIdentity
Assert-Task3TempParentOutsideRepositoryIdentity $Task3TempParent $Task3PrimaryIdentity
$Task3CapturedTempParentIdentity = Get-Task3DirectoryIdentity $Task3TempParent
$Task3Wrapper = Get-Task3CanonicalPath (Join-Path $Task3TempParent ("moerail-task3-playtest-" + [Guid]::NewGuid().ToString('N')))
$Task3BareOrigin = Join-Path $Task3Wrapper 'tested-origin.git'
$Task3LauncherRepository = Join-Path $Task3Wrapper 'launcher-repository'
Assert-Task3OwnedWrapper $false
New-Item -ItemType Directory -LiteralPath $Task3Wrapper -ErrorAction Stop | Out-Null
$Task3CapturedWrapperIdentity = Get-Task3CapturedDirectoryIdentityOrReport $Task3Wrapper
Assert-Task3WrapperStateOrReport $false $false
Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3Wrapper -Arguments @('init','--bare',$Task3BareOrigin) -RequireBare $false -RequireClone $false | Out-Null
$Task3CapturedBareIdentity = Get-Task3CapturedDirectoryIdentityOrReport $Task3BareOrigin
Assert-Task3WrapperStateOrReport $true $false
Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3BareOrigin -Arguments @('fetch','--no-tags',$Task3FeatureRoot,($Task3TestedImplementationSha + ':refs/heads/main')) -RequireBare $true -RequireClone $false | Out-Null
Assert-Task3WrapperStateOrReport $true $false
if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3BareOrigin -Arguments @('rev-parse','refs/heads/main') -RequireBare $true -RequireClone $false).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'STOP: local origin main SHA mismatch' }
$Task3BareHeads = Get-Task3Lines (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3BareOrigin -Arguments @('for-each-ref','--format=%(refname) %(objectname)','refs/heads') -RequireBare $true -RequireClone $false).Stdout | Sort-Object
if (Compare-Object $Task3BareHeads @("refs/heads/main $Task3TestedImplementationSha")) { throw 'STOP: task-owned bare origin contains a head other than tested main' }
Assert-Task3WrapperStateOrReport $true $false
if (Test-Path -LiteralPath $Task3LauncherRepository) { throw 'STOP: task launcher clone target already exists' }
Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3Wrapper -Arguments @('clone','--no-local','--branch','main','--single-branch',$Task3BareOrigin,$Task3LauncherRepository) -RequireBare $true -RequireClone $false | Out-Null
$Task3CapturedCloneIdentity = Get-Task3CapturedDirectoryIdentityOrReport $Task3LauncherRepository
Assert-Task3WrapperStateOrReport $true $true
if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse','--is-inside-work-tree') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne 'true') { throw 'STOP: launcher repository is not a worktree' }
if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('branch','--show-current') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne 'main') { throw 'STOP: launcher repository branch is not main' }
if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse','--abbrev-ref','@{upstream}') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne 'origin/main') { throw 'STOP: launcher repository upstream is not origin/main' }
if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-list','--left-right','--count','@{upstream}...HEAD') -RequireBare $true -RequireClone $true).Stdout -notmatch '^\s*0\s+0\s*$') { throw 'STOP: launcher repository divergence is not 0/0' }
if ((Get-Task3Lines (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('status','--porcelain=v1','-uall') -RequireBare $true -RequireClone $true).Stdout).Count -ne 0) { throw 'STOP: launcher repository is not clean' }
if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse','HEAD') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'STOP: launcher repository HEAD SHA mismatch' }
$Task3CloneOrigin = Get-Task3CanonicalPath (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('remote','get-url','origin') -RequireBare $true -RequireClone $true).Stdout.Trim()
if ($Task3CloneOrigin -ne $Task3BareOrigin) { throw 'STOP: launcher repository origin is not the task-owned bare origin' }
$Task3ProjectTreeSpec = $Task3TestedImplementationSha + ':godot-project-moe-rail-way'
$Task3FeatureProjectTree = (Invoke-Task3FeatureGit @('rev-parse',$Task3ProjectTreeSpec)).Stdout.Trim()
$Task3CloneProjectTree = (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse',('HEAD:godot-project-moe-rail-way')) -RequireBare $true -RequireClone $true).Stdout.Trim()
if ($Task3FeatureProjectTree -ne $Task3CloneProjectTree) { throw 'STOP: launcher project tree OID differs from tested source' }
foreach ($Task3CodePath in $Task3CodePaths) {
  $Task3FeatureBlob = (Invoke-Task3FeatureGit @('rev-parse',($Task3TestedImplementationSha + ':' + $Task3CodePath))).Stdout.Trim()
  $Task3CloneBlob = (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse',('HEAD:' + $Task3CodePath)) -RequireBare $true -RequireClone $true).Stdout.Trim()
  if ($Task3FeatureBlob -ne $Task3CloneBlob) { throw "STOP: exact-path blob OID mismatch: $Task3CodePath" }
}
Assert-Task3WrapperStateOrReport $true $true
Write-Host "TASK3_PRESERVED_WRAPPER: $Task3Wrapper"
```

Run the unchanged launcher from the clone. `Invoke-Task3Launcher` intentionally returns process-start, stdout, stderr, and nonzero exit results as data instead of throwing, so every started launch reaches the post-launch identity/source checks. It never enumerates or terminates a process.

```powershell
function Invoke-Task3Launcher {
  param([string]$LauncherPath, [string]$RepositoryRoot, [string]$GodotExecutable)
  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = (Get-Command pwsh.exe -ErrorAction Stop).Source
  $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
  foreach ($argument in @('-NoProfile','-File',$LauncherPath,'-RepositoryRoot',$RepositoryRoot,'-GodotExecutable',$GodotExecutable)) { $psi.ArgumentList.Add($argument) }
  try { $process = [Diagnostics.Process]::Start($psi) }
  catch { return [pscustomobject]@{ Started = $false; ExitCode = $null; Stdout = ''; Stderr = $_.Exception.Message } }
  if ($null -eq $process) { return [pscustomobject]@{ Started = $false; ExitCode = $null; Stdout = ''; Stderr = 'PowerShell launcher process did not start' } }
  try {
    $stdoutTask = $process.StandardOutput.ReadToEndAsync(); $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit(); [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdoutTask, $stderrTask))
    return [pscustomobject]@{ Started = $true; ExitCode = $process.ExitCode; Stdout = $stdoutTask.Result; Stderr = $stderrTask.Result }
  }
  finally { $process.Dispose() }
}

Assert-Task3WrapperStateOrReport $true $true
$Task3Launcher = Join-Path $Task3LauncherRepository 'godot-project-moe-rail-way\tools\playtest\launch_editor_playtest.ps1'
$Task3LauncherResult = Invoke-Task3Launcher -LauncherPath $Task3Launcher -RepositoryRoot $Task3LauncherRepository -GodotExecutable $Task3EditorGodot
$Task3LauncherOutput = $Task3LauncherResult.Stdout + $Task3LauncherResult.Stderr
Write-Host $Task3LauncherOutput
```

Interact only with the launched editor/game window. Perform the slow B–F/G route and observe solid B–E while F builds and reclassifies. Verify the synchronized G support has neither cancel hover nor right-click cancellation, and that its route-end and inventory HUD values remain unchanged; then extend from G by one ordinary `RESERVED_GHOST` suffix cell H. Hover H to show the normal cancel affordance, right-click H, and directly observe successful cancellation of H only: the endpoint returns from H to G and the integer inventory HUD increases by exactly one cell. Record the literal before/after HUD values, not an inferred count. This ordinary H success case is separate from the G support no-op.

The Windows observation scope ends with the direct B–F/G/H presentation and input cases above: enter track without a jump, verify rejected input preserves the last valid route, and verify the terminal snapshot appears before the result overlay. The same-serial provisional-to-lock-to-recovery lifecycle is not a manual timing or screenshot gate; the correction-only `test_grid_track_runtime.gd` lifecycle test below is its sole required proof. Allow the editor to exit naturally. After it exits, type the exact confirmation only if every listed direct observation occurred.

```powershell
$Task3ObservationPassed = $false
$Task3PostLaunchFailures = [Collections.Generic.List[string]]::new()
if ($Task3LauncherResult.Started) {
  try {
    Assert-Task3WrapperStateOrReport $true $true
    if ((Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'feature HEAD changed' }
    if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'feature worktree is dirty' }
    if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse','HEAD') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'launcher HEAD changed' }
    if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('branch','--show-current') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne 'main') { throw 'launcher branch changed' }
    if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse','--abbrev-ref','@{upstream}') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne 'origin/main') { throw 'launcher upstream changed' }
    if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-list','--left-right','--count','@{upstream}...HEAD') -RequireBare $true -RequireClone $true).Stdout -notmatch '^\s*0\s+0\s*$') { throw 'launcher divergence changed' }
    if ((Get-Task3Lines (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('status','--porcelain=v1','-uall') -RequireBare $true -RequireClone $true).Stdout).Count -ne 0) { throw 'launcher repository is dirty' }
    if ((Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3BareOrigin -Arguments @('rev-parse','refs/heads/main') -RequireBare $true -RequireClone $true).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'local origin main changed' }
    $Task3PostLaunchHeads = Get-Task3Lines (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3BareOrigin -Arguments @('for-each-ref','--format=%(refname) %(objectname)','refs/heads') -RequireBare $true -RequireClone $true).Stdout | Sort-Object
    if (Compare-Object $Task3PostLaunchHeads @("refs/heads/main $Task3TestedImplementationSha")) { throw 'local origin heads changed' }
    if ((Invoke-Task3FeatureGit @('rev-parse',$Task3ProjectTreeSpec)).Stdout.Trim() -ne (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse','HEAD:godot-project-moe-rail-way') -RequireBare $true -RequireClone $true).Stdout.Trim()) { throw 'project tree OID changed' }
    foreach ($Task3CodePath in $Task3CodePaths) {
      if ((Invoke-Task3FeatureGit @('rev-parse',($Task3TestedImplementationSha + ':' + $Task3CodePath))).Stdout.Trim() -ne (Invoke-Task3GuardedWrapperGit -WorkingDirectory $Task3LauncherRepository -Arguments @('rev-parse',('HEAD:' + $Task3CodePath)) -RequireBare $true -RequireClone $true).Stdout.Trim()) { throw "exact-path blob OID changed: $Task3CodePath" }
    }
  }
  catch { $Task3PostLaunchFailures.Add($_.Exception.Message) }
  $Task3Observation = Read-Host 'Type TASK3_MANUAL_OBSERVATION_CONFIRMED only after all required observations'
  $Task3ObservationPassed = $Task3Observation -ceq 'TASK3_MANUAL_OBSERVATION_CONFIRMED'
}
$Task3LauncherPassed = $Task3LauncherResult.Started -and $Task3LauncherResult.ExitCode -eq 0 -and
  [regex]::Matches($Task3LauncherOutput, '(?m)^PASS: editor playtest completed\s*$').Count -eq 1 -and
  [regex]::Matches($Task3LauncherOutput, '(?m)^DIAGNOSTICS_SCANNED:\s+\d+\s*$').Count -eq 1
if (-not $Task3LauncherPassed -or -not $Task3ObservationPassed -or $Task3PostLaunchFailures.Count -ne 0) {
  Write-Task3WrapperFailureMarker
  throw "STOP: manual launcher/observation/check gate failed; tested SHA=$Task3TestedImplementationSha; exit=$($Task3LauncherResult.ExitCode); started=$($Task3LauncherResult.Started); post-launch=$($Task3PostLaunchFailures -join '; ')"
}
```

On any launcher start, exit, marker, observation, or post-launch check failure, do not edit `track_train_windows.md`, do not create the evidence commit, and do not write PASS evidence. Keep the durable implementation commit and report `TASK3_TESTED_IMPLEMENTATION_SHA`, launcher output/exit/start state, and all check failures. `Write-Task3WrapperFailureMarker` reports `TASK3_PRESERVED_WRAPPER` only after full captured-identity and descendant validation; otherwise it reports the English `TASK3_WRAPPER_IDENTITY_LOST` marker with the last-known wrapper path and every captured identity. Do not delete the wrapper or any launcher-owned mirror/remnant.

- [ ] **Step 7: Append successful manual evidence and create the evidence-only commit**

Proceed only when Step 6’s launcher, manual observation, and post-launch checks all passed. Append one dated English section to `track_train_windows.md`—without rewriting the 2026-08-24 history—recording the actual local date, `TASK3_TESTED_IMPLEMENTATION_SHA` explicitly labeled **Durable tested implementation SHA**, the exact Godot version, launcher exit `0`, the exact `PASS: editor playtest completed` marker, and the observed `DIAGNOSTICS_SCANNED: <count>` line. The direct-observation list must separately record: B–F reclassification with solid built B–E; G's no-hover/no-op with unchanged route/end and inventory HUD values; H's ordinary provisional hover and successful one-cell cancellation with the literal one-cell inventory refund; G extension; rejected-input preservation; entry without jump; and terminal snapshot before overlay. Do not use automation results or inferred counts as substitutes for these observations, and do not describe the following evidence commit SHA as tested source. The separate same-serial recovery lifecycle is automated evidence and must not be restated as a manual observation.

Stage and commit only the manual evidence path, then require a distinct direct child of the tested implementation SHA with no other changed path and a clean worktree:

```powershell
Assert-Task3WrapperStateOrReport $true $true
Invoke-Task3FeatureGit @('add','--',$Task3ManualPath) | Out-Null
Invoke-Task3FeatureGit @('diff','--cached','--check') | Out-Null
$Task3EvidenceStaged = Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--cached','--name-only')).Stdout | Sort-Object
if (Compare-Object $Task3EvidenceStaged @($Task3ManualPath)) { throw 'STOP: evidence commit path set is not exact' }
Invoke-Task3FeatureGit @('commit','-m','test: record reflowable track head Windows playtest') | Out-Null
$Task3EvidenceCommitSha = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ($Task3EvidenceCommitSha -eq $Task3TestedImplementationSha) { throw 'STOP: evidence commit SHA did not advance' }
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3EvidenceCommitSha + '^'))).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'STOP: evidence commit is not a direct child of tested implementation' }
$Task3EvidencePaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$Task3EvidenceCommitSha)).Stdout | Sort-Object
if (Compare-Object $Task3EvidencePaths @($Task3ManualPath)) { throw 'STOP: evidence commit changed a non-manual path' }
Invoke-Task3FeatureGit @('diff','--check',($Task3TestedImplementationSha + '..' + $Task3EvidenceCommitSha)) | Out-Null
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: evidence commit did not leave a clean worktree' }
Write-Host "TASK3_EVIDENCE_COMMIT_SHA: $Task3EvidenceCommitSha"
Assert-Task3WrapperStateOrReport $true $true
Write-Host "TASK3_PRESERVED_WRAPPER: $Task3Wrapper"
```

Expected: `TASK3_TESTED_IMPLEMENTATION_SHA` remains the already-playtested four-path implementation commit; the second commit records only successful manual evidence, and the preserved wrapper remains available for inspection without any cleanup action.

- [ ] **Step 8: Obtain independent Sol reviews over the complete Task 3 range**

For the final Task 3 review, the complete immutable range is exactly `94faa243f761d19a9459328f22792fa9e4f1dc3e..HEAD`; do not replace this full review base with a later documentation bridge or a scoped correction base. Request a Sol specification review against spec Sections 1, 5, 10, 12, and 14, then a separate Sol quality review for detached observation use, hover correctness, event timing, multi-frame physical input, the two-commit evidence boundary, sanitized local-origin launcher safety, ordinary-path/identity preservation, manual evidence integrity, no leaked domain mutation, and absence of provisional visual styling. Classify each documentation bridge commit separately from the five-path Task 3 outputs (`track_field_view.gd`, the three tests/integrations, and `track_train_windows.md`) rather than silently narrowing or blending the range. The normal Task 3 delivery contains the two focused commits above, while the final Task 3 allowlist remains unchanged. If either review rejects coverage or manual-observation evidence without a production blob change, follow the focused correction flow below rather than relabeling an evidence commit as tested source. Assign every accepted finding to a fresh Terra output worker using that allowlist only; rerun focused tests, both integrations, the full gate, and any affected manual play, then repeat both Sol reviews.

#### Task 3 Sol-review coverage correction after the reviewed evidence head

This correction is authorized only after the current reviewed Task 3 evidence head `cf4deb70aeb0d9e58dc90bf6fb2bdbaf4adf7e4a`. Its scope is limited to the real-runtime view test and the direct Windows evidence required above; do not modify `track_field_view.gd`, the integrations, or any domain/runtime file. Before this correction starts, the controller must commit this canonical plan correction as one documentation-only child of `cf4deb70aeb0d9e58dc90bf6fb2bdbaf4adf7e4a` and record that documentation SHA as `TASK3_CORRECTION_BASE` in the ignored ledger. It is a scoped fix-packaging bridge only, never the adjusted or complete Task 3 review base; the complete review base remains `94faa243f761d19a9459328f22792fa9e4f1dc3e`. The test-only and manual-only correction commits then follow `TASK3_CORRECTION_BASE`. The final Task 3 allowlist is unchanged.

- [ ] **Step 9: Prove the durable tested runtime is unchanged, replace the tautological test, and make one test-only correction commit**

The durable tested implementation is exactly `f72534e7e6aa6398b7071b8489d3b779e3d6cc66`. It remains the tested runtime source only if the production `track_field_view.gd` blob at `TASK3_CORRECTION_BASE` and at the new test-only correction commit equals its blob at that SHA. The test in Step 1 must replace the committed hand-authored already-curved snapshot test: it must use the actual B–D straight then E–F turn runtime transition, capture view observations both times, and run the local mutation check in Step 2 when the unmutated suite is already GREEN.

```powershell
# Run the Task 3 Git and Wrapper Safety Helpers block first. This is the
# correction-only bootstrap; it deliberately performs no staging or commit.
Assert-Task3CleanGitEnvironment
$Task3GitExecutable = (Get-Command git.exe -ErrorAction Stop).Source
$Task3FsutilExecutable = (Get-Command fsutil.exe -ErrorAction Stop).Source
$Task3FeatureRoot = (Resolve-Path -LiteralPath 'D:\godot\MoeRailWay-worktrees\feature-reflowable-track-head').Path
$Task3PrimaryRoot = (Resolve-Path -LiteralPath 'D:\godot\MoeRailWay').Path
Assert-Task3ExistingOrdinaryPathChain $Task3FeatureRoot ([IO.Path]::GetPathRoot($Task3FeatureRoot)) | Out-Null
Assert-Task3ExistingOrdinaryPathChain $Task3PrimaryRoot ([IO.Path]::GetPathRoot($Task3PrimaryRoot)) | Out-Null
$Task3FeatureIdentity = Get-Task3DirectoryIdentity $Task3FeatureRoot
$Task3PrimaryIdentity = Get-Task3DirectoryIdentity $Task3PrimaryRoot
$Task3ExpectedFeatureBranch = 'feature/reflowable-track-head'
if ((Invoke-Task3FeatureGit @('branch','--show-current')).Stdout.Trim() -ne $Task3ExpectedFeatureBranch) { throw 'STOP: correction feature branch mismatch' }

$Task3ReviewedEvidenceHead = 'cf4deb70aeb0d9e58dc90bf6fb2bdbaf4adf7e4a'
$Task3DurableTestedImplementationSha = 'f72534e7e6aa6398b7071b8489d3b779e3d6cc66'
$Task3ProductionPath = 'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd'
$Task3CorrectionTestPath = 'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd'
$Task3ManualPath = 'godot-project-moe-rail-way/tests/manual/track_train_windows.md'
$Task3CodePaths = @(
  'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
  'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd',
  'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd',
  'godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd'
)
$Task3CorrectionBase = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3CorrectionBase + '^'))).Stdout.Trim() -ne $Task3ReviewedEvidenceHead) { throw 'STOP: correction must start at the doc-only TASK3_CORRECTION_BASE directly after the reviewed evidence head' }
$Task3CorrectionBasePaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$Task3CorrectionBase)).Stdout
if (Compare-Object $Task3CorrectionBasePaths @('docs/superpowers/plans/2026-08-25-reflowable-track-head.md')) { throw 'STOP: TASK3_CORRECTION_BASE is not documentation-only canonical plan correction' }
$Task3DurableProductionBlob = (Invoke-Task3FeatureGit @('rev-parse',($Task3DurableTestedImplementationSha + ':' + $Task3ProductionPath))).Stdout.Trim()
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3CorrectionBase + ':' + $Task3ProductionPath))).Stdout.Trim() -ne $Task3DurableProductionBlob) { throw 'STOP: TASK3_CORRECTION_BASE changed the durable tested production blob' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: correction starts from a dirty worktree' }
```

Replace only the old fake curve helper/test with Step 1's exact runtime transition test. If the unmutated focused suite is already GREEN, run the Step 2 temporary presentation mutation, require the named failure, restore `track_field_view.gd`, and verify it has no diff before GREEN. Then run the focused view suite and the full regression gate. Stage only the view test and commit it as `test: strengthen real-runtime reflow view evidence`.

```powershell
Invoke-ReflowFocused 'test_track_field_view_input.gd'
Invoke-ReflowFullGate
Invoke-Task3FeatureGit @('add','--',$Task3CorrectionTestPath) | Out-Null
Invoke-Task3FeatureGit @('diff','--cached','--check') | Out-Null
$Task3CorrectionStaged = Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--cached','--name-only')).Stdout | Sort-Object
if (Compare-Object $Task3CorrectionStaged @($Task3CorrectionTestPath)) { throw 'STOP: reflow correction commit is not test-only' }
Invoke-Task3FeatureGit @('commit','-m','test: strengthen real-runtime reflow view evidence') | Out-Null
$Task3CorrectionTestSha = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3CorrectionTestSha + '^'))).Stdout.Trim() -ne $Task3CorrectionBase) { throw 'STOP: test correction is not a direct child of TASK3_CORRECTION_BASE' }
$Task3CorrectionPaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$Task3CorrectionTestSha)).Stdout | Sort-Object
if (Compare-Object $Task3CorrectionPaths @($Task3CorrectionTestPath)) { throw 'STOP: test correction changed a non-test path' }
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3CorrectionTestSha + ':' + $Task3ProductionPath))).Stdout.Trim() -ne $Task3DurableProductionBlob) { throw 'STOP: test correction changed the durable tested production blob' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: test correction did not leave a clean worktree' }
Write-Host "TASK3_CORRECTION_TEST_SHA: $Task3CorrectionTestSha"
Write-Host "TASK3_DURABLE_TESTED_IMPLEMENTATION_SHA: $Task3DurableTestedImplementationSha"
```

- [ ] **Step 10: Re-observe the correction-only Windows cases and make one manual-only correction commit**

Continue the Step 9 PowerShell session; if a new session is necessary, rerun the complete correction-only bootstrap at the start of Step 9 before using any `Task3` variable or helper. Before the launcher starts, require `HEAD == TASK3_CORRECTION_TEST_SHA`, a clean feature worktree, and the identical production blob at `HEAD` and `f72534e7e6aa6398b7071b8489d3b779e3d6cc66`. Set `TASK3_TESTED_IMPLEMENTATION_SHA` to that durable SHA and execute the complete existing Step 6 task-owned local-origin wrapper procedure against that SHA, including the sanitized child Git environment, no-reparse descendant scans, captured identities, clean local `main` clone, source tree/blob equality, and post-launch validation. Do not weaken or bypass the launcher.

For this correction-only wrapper run, bind the feature head before launch and make one narrow post-launch substitution: require the feature worktree still names the bound test-correction head, rather than requiring it to equal the older durable tested source. Keep every clone/bare/source check pinned to `TASK3_TESTED_IMPLEMENTATION_SHA`.

```powershell
$Task3ManualCorrectionHead = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ($Task3ManualCorrectionHead -ne $Task3CorrectionTestSha) { throw 'STOP: manual correction must launch from the test-only correction head' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: manual correction starts from a dirty worktree' }
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3ManualCorrectionHead + ':' + $Task3ProductionPath))).Stdout.Trim() -ne $Task3DurableProductionBlob) { throw 'STOP: manual correction cannot reuse durable tested SHA after a production blob change' }
$Task3TestedImplementationSha = $Task3DurableTestedImplementationSha

# In Step 6's post-launch checks, replace only this original check:
# if ((Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim() -ne $Task3TestedImplementationSha) { throw 'feature HEAD changed' }
# with this correction-head stability check:
if ((Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim() -ne $Task3ManualCorrectionHead) { throw 'feature correction HEAD changed' }
```

The direct observation gate is the complete Step 6 list excluding recovery-frame capture: it includes the distinct G support no-op and H ordinary-hover/successful one-cell refund. If any launcher, identity, source, marker, or direct observation requirement fails, do not edit the manual record or create a correction commit; preserve the wrapper and report the failure. The same-serial recovery lifecycle is gated only by the correction-only runtime test below.

Only after success, append one dated English correction section to `track_train_windows.md` with the literal route/end and inventory values observed for G and H. It must identify `f72534e7e6aa6398b7071b8489d3b779e3d6cc66` as **Durable tested implementation SHA**, identify the test-only correction SHA as coverage-only, and never call either correction commit tested source. Stage only the manual record and commit it as `test: expand reflowable track head Windows evidence`.

```powershell
Invoke-Task3FeatureGit @('add','--',$Task3ManualPath) | Out-Null
Invoke-Task3FeatureGit @('diff','--cached','--check') | Out-Null
$Task3ManualCorrectionStaged = Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--cached','--name-only')).Stdout | Sort-Object
if (Compare-Object $Task3ManualCorrectionStaged @($Task3ManualPath)) { throw 'STOP: Windows correction commit is not manual-only' }
Invoke-Task3FeatureGit @('commit','-m','test: expand reflowable track head Windows evidence') | Out-Null
$Task3ManualCorrectionSha = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3ManualCorrectionSha + '^'))).Stdout.Trim() -ne $Task3CorrectionTestSha) { throw 'STOP: manual correction is not a direct child of test correction' }
$Task3ManualCorrectionPaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$Task3ManualCorrectionSha)).Stdout | Sort-Object
if (Compare-Object $Task3ManualCorrectionPaths @($Task3ManualPath)) { throw 'STOP: manual correction changed a non-manual path' }
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3ManualCorrectionSha + ':' + $Task3ProductionPath))).Stdout.Trim() -ne $Task3DurableProductionBlob) { throw 'STOP: manual correction changed the durable tested production blob' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: manual correction did not leave a clean worktree' }
Write-Host "TASK3_MANUAL_CORRECTION_SHA: $Task3ManualCorrectionSha"
```

Append a dated English entry to the ignored `.superpowers/sdd/2026-08-25-reflowable-track-head/task-3-report.md` before re-review. Attribute the correction to the Sol Task 3 review rejection; record the immutable complete review base `94faa243f761d19a9459328f22792fa9e4f1dc3e`, the separate `TASK3_CORRECTION_BASE` documentation bridge SHA, test-only correction SHA, manual-only correction SHA, durable tested implementation SHA, matching production blob proof, the new direct G/H observations, and repeated gates. Amend or explicitly retract both earlier report claims that overstate input-integration coverage: it covers only physical B–F/G through the support right-click no-op; G extension and the rejected non-endpoint append are direct manual observations, not changed input-integration coverage. Record the subsequent same-serial recovery-lifecycle correction as automated evidence with its verified `RECOVERY_GATE_AMENDMENT_SHA`, `RECOVERY_ORACLE_FIX_SHA`, runtime-captured `TASK3_RECOVERY_AUTOMATION_BASE`, sensitivity RED, focused/full GREEN, and direct-child test-only SHA; do not represent it as a manual observation. Do not attribute the strengthened tests or manual evidence to the original tested-source commit, and do not label either correction commit as the source launched by the wrapper.

- [ ] **Step 11: Repeat both Sol reviews over the unchanged complete Task 3 review range**

Review exactly `94faa243f761d19a9459328f22792fa9e4f1dc3e..HEAD` through the final correction commit; never substitute `TASK3_CORRECTION_BASE` or narrow the range to the latest correction commit. Classify each documentation bridge separately from the five-path Task 3 outputs, including the two-document `RECOVERY_GATE_AMENDMENT_SHA`, plan-only `RECOVERY_ORACLE_FIX_SHA`, and the runtime-captured plan-only `TASK3_RECOVERY_AUTOMATION_BASE`, then review every Task 3 output across the complete range. The specification review must verify the actual runtime straight-to-curve test transition and `BUILT` render state, plus the automated B–F provisional-to-lock-to-cutoff-`1`/`2`/`3` lifecycle with G appended only after preparation. The quality review must verify both temporary mutation sensitivity REDs, the restored durable production blob before GREEN/staging, distinct G/H cancellation observations, literal one-cell inventory refund, the automated post-prepare group-id/immutable-ledger oracle, B–F active-slice/contiguity/conservation recovery assertions, persistent provisional G suffix, durable-SHA attribution, wrapper safety, unchanged production blob, and report retraction of the two overstated integration claims. If a later correction changes the production blob, stop treating `f72534e7e6aa6398b7071b8489d3b779e3d6cc66` as tested and return to the full durable implementation/launcher sequence with a new tested SHA.

#### Task 3 automated same-serial recovery-lifecycle correction after the view-test correction

This correction supersedes only the Windows three-frame recovery requirement in Steps 6 and 10. It does not revise the immutable complete Task 3 review base `94faa243f761d19a9459328f22792fa9e4f1dc3e`, the durable tested implementation SHA `f72534e7e6aa6398b7071b8489d3b779e3d6cc66`, or the classification of `b70a8e0ad68a76508178f4f23e47c03a02e7c6e0` as the existing test-only real-runtime view correction. The known documentation graph is fixed: `RECOVERY_GATE_AMENDMENT_SHA` is `72d7473ffbf200c0e37b2d559f86890dbef0f503`, a direct child of `b70a8e0ad68a76508178f4f23e47c03a02e7c6e0` changing exactly the canonical plan and design; `RECOVERY_ORACLE_FIX_SHA` is `ed47d8b34f6bdc6ff3e285a219f52324dbb86c8d`, a direct child of that gate amendment changing exactly the canonical plan. The current ancestry-alignment documentation commit is intentionally not hardcoded: Step 12 captures it at runtime as `TASK3_RECOVERY_AUTOMATION_BASE` only after proving that the clean current `HEAD` is a plan-only direct child of `RECOVERY_ORACLE_FIX_SHA` with subject `docs: align reflow recovery correction ancestry`. The one forthcoming test-only correction must then be its direct child. Record all three bridge identities in the ignored ledger/report. This automation correction does not require a launcher run, a manual record edit, or a manual-evidence commit.

**Ruling — manual playback states cannot prove the same reflow candidate's lifecycle.** A visible recovery frame shows only a recovered route suffix and current HUD state; it cannot simultaneously prove that those exact serials previously formed the provisional `CURVE_3X3`, were locked as one whole prepared ledger piece, and retained immutable geometry through the observed refund. Those states are mutually exclusive in a single manual frame. **Cost if wrong:** a manual three-frame sequence can appear to prove one-cell recovery while silently combining different route candidates or missing a changed ledger identity, causing the review to accept a lifecycle regression that only deterministic serial-level automation can expose.

- [ ] **Step 12: Add the automated B–F lifecycle test, prove sensitivity, and make one test-only correction commit**

The permanent correction allowlist is exactly:

```text
godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd
```

Temporary mutation of `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd` is authorized only for the sensitivity RED below. Restore its exact pre-mutation blob before every GREEN command, staging command, or commit; no durable production edit is expected or permitted.

```powershell
# Run the Task 3 Git and Wrapper Safety Helpers block first.
$Task3ViewCorrectionSha = 'b70a8e0ad68a76508178f4f23e47c03a02e7c6e0'
$RECOVERY_GATE_AMENDMENT_SHA = '72d7473ffbf200c0e37b2d559f86890dbef0f503'
$RECOVERY_ORACLE_FIX_SHA = 'ed47d8b34f6bdc6ff3e285a219f52324dbb86c8d'
$Task3RecoveryAlignmentSubject = 'docs: align reflow recovery correction ancestry'
$Task3RecoveryRuntimePath = 'godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd'
$Task3RecoveryTestPath = 'godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd'
$Task3RecoveryGateAmendmentParent = (Invoke-Task3FeatureGit @('rev-parse',($RECOVERY_GATE_AMENDMENT_SHA + '^'))).Stdout.Trim()
if ($Task3RecoveryGateAmendmentParent -ne $Task3ViewCorrectionSha) { throw 'STOP: RECOVERY_GATE_AMENDMENT_SHA is not a direct child of the existing test-only view correction' }
$Task3RecoveryGateAmendmentPaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$RECOVERY_GATE_AMENDMENT_SHA)).Stdout | Sort-Object
if (Compare-Object $Task3RecoveryGateAmendmentPaths @('docs/superpowers/plans/2026-08-25-reflowable-track-head.md','docs/superpowers/specs/2026-08-25-reflowable-track-head-design.md')) { throw 'STOP: RECOVERY_GATE_AMENDMENT_SHA did not change exactly the two canonical paths' }
$Task3RecoveryOracleFixParent = (Invoke-Task3FeatureGit @('rev-parse',($RECOVERY_ORACLE_FIX_SHA + '^'))).Stdout.Trim()
if ($Task3RecoveryOracleFixParent -ne $RECOVERY_GATE_AMENDMENT_SHA) { throw 'STOP: RECOVERY_ORACLE_FIX_SHA is not a direct child of RECOVERY_GATE_AMENDMENT_SHA' }
$Task3RecoveryOracleFixPaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$RECOVERY_ORACLE_FIX_SHA)).Stdout | Sort-Object
if (Compare-Object $Task3RecoveryOracleFixPaths @('docs/superpowers/plans/2026-08-25-reflowable-track-head.md')) { throw 'STOP: RECOVERY_ORACLE_FIX_SHA is not plan-only' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: recovery automation bootstrap starts from a dirty worktree' }
$TASK3_RECOVERY_AUTOMATION_BASE = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ((Invoke-Task3FeatureGit @('rev-parse',($TASK3_RECOVERY_AUTOMATION_BASE + '^'))).Stdout.Trim() -ne $RECOVERY_ORACLE_FIX_SHA) { throw 'STOP: TASK3_RECOVERY_AUTOMATION_BASE is not a direct child of RECOVERY_ORACLE_FIX_SHA' }
$Task3RecoveryAutomationBasePaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$TASK3_RECOVERY_AUTOMATION_BASE)).Stdout | Sort-Object
if (Compare-Object $Task3RecoveryAutomationBasePaths @('docs/superpowers/plans/2026-08-25-reflowable-track-head.md')) { throw 'STOP: TASK3_RECOVERY_AUTOMATION_BASE is not plan-only' }
if ((Invoke-Task3FeatureGit @('log','-1','--format=%s',$TASK3_RECOVERY_AUTOMATION_BASE)).Stdout.Trim() -ne $Task3RecoveryAlignmentSubject) { throw 'STOP: TASK3_RECOVERY_AUTOMATION_BASE has the wrong ancestry-alignment subject' }
$Task3RecoveryDurableBlob = (Invoke-Task3FeatureGit @('rev-parse',('f72534e7e6aa6398b7071b8489d3b779e3d6cc66:' + $Task3RecoveryRuntimePath))).Stdout.Trim()
$Task3RecoveryOriginalRuntimeBlob = (Invoke-Task3FeatureGit @('rev-parse',($TASK3_RECOVERY_AUTOMATION_BASE + ':' + $Task3RecoveryRuntimePath))).Stdout.Trim()
if ($Task3RecoveryOriginalRuntimeBlob -ne $Task3RecoveryDurableBlob) { throw 'STOP: recovery automation base changed the durable production blob' }
```

In `test_grid_track_runtime.gd`, add `_test_prepared_built_curve_recovers_same_serials_without_ledger_mutation()` to `run()`. The fixture first uses only B–F: append `[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]`, build all five records, and save a detached geometry-value dictionary for its one provisional `CURVE_3X3`. Prepare B–F before appending any successor, then capture the immutable ledger oracle from the prepared piece. That post-prepare oracle contains `group_id`, `kind`, `first_route_serial`, `last_route_serial`, `nominal_length_cells`, `absolute_start_distance_cells`, `footprint_cells`, `centerline`, and `exit_support_route_serial`; it deliberately excludes only `active_local_start_cells` and `active_local_end_cells`. Append G only after that capture, so serial 6 remains a genuine `RESERVED_GHOST`, provisional, unlocked suffix and cannot be confused with B–F's preparation or immutable ledger identity.

```gdscript
func _test_prepared_built_curve_recovers_same_serials_without_ledger_mutation() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "B through F append as one route candidate")
	assert_equal(track.advance_construction(5.0), 5.0, "B through F are built before preparation")
	var provisional = track.get_geometry_pieces()[0]
	assert_equal(provisional.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Built B through F is a provisional 3x3 curve")
	assert_false(provisional.locked, "Built B through F remains provisional before preparation")
	var pre_prepare_geometry = _geometry_values(provisional)
	assert_true(track.prepare_for_train_sampling(0.0, 0.0), "Prepare locks the complete B through F owner")
	var prepared = track.get_geometry_pieces()[0]
	assert_true(prepared.locked, "Prepared B through F curve is whole-piece locked")
	assert_equal(_geometry_values(prepared), pre_prepare_geometry, "Preparation preserves B through F geometry")
	assert_equal(prepared.exit_support_route_serial, -1, "Prepared B through F has no successor support")
	var immutable_ledger = _immutable_ledger_values(prepared)
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "G appends only after B through F preparation")
	for cutoff in [1, 2, 3]:
		var before_inventory := track.get_available_track_cells()
		assert_equal(track.recover_behind(float(cutoff)), 1, "Cutoff %d recovers exactly one B through F serial" % cutoff)
		assert_equal(track.get_available_track_cells(), before_inventory + 1, "Cutoff %d refunds exactly one inventory cell" % cutoff)
		var pieces = track.get_geometry_pieces()
		assert_equal(pieces.size(), 2, "Cutoff %d retains locked B through F and provisional G pieces" % cutoff)
		var active = pieces[0]
		var g_piece = pieces[1]
		assert_true(active.locked, "Surviving B through F slice remains locked at cutoff %d" % cutoff)
		assert_equal(_immutable_ledger_values(active), immutable_ledger, "Cutoff %d preserves B through F ledger identity and geometry" % cutoff)
		assert_equal(active.active_local_start_cells, float(cutoff), "Active slice start advances by one at cutoff %d" % cutoff)
		assert_equal(active.active_local_end_cells, 5.0, "Active slice end remains the B through F nominal end")
		assert_equal(g_piece.first_route_serial, 6, "G remains the successor serial at cutoff %d" % cutoff)
		assert_equal(g_piece.last_route_serial, 6, "G remains one nominal route record at cutoff %d" % cutoff)
		assert_false(g_piece.locked, "G remains a provisional suffix at cutoff %d" % cutoff)
		_assert_locked_prefix_then_provisional(pieces, "Cutoff %d keeps locked B through F before provisional G" % cutoff)
		var records = track.get_cell_records()
		assert_equal(records.size(), 6 - cutoff, "Cutoff %d retains exactly the B through F suffix plus G" % cutoff)
		for index in range(5 - cutoff):
			assert_equal(records[index].route_serial, cutoff + index + 1, "Cutoff %d retains the expected B through F serial" % cutoff)
			assert_equal(records[index].state, TrackCellRecordScript.State.BUILT, "Surviving B through F serial stays built")
			assert_true(records[index].geometry_locked, "Surviving B through F serial stays locked")
		assert_equal(records[-1].route_serial, 6, "G remains the active route endpoint serial")
		assert_equal(records[-1].state, TrackCellRecordScript.State.RESERVED_GHOST, "G remains a genuine provisional ghost suffix")
		assert_false(records[-1].geometry_locked, "G record remains unlocked")
		_assert_conservation(track, "Cutoff %d conserves the B through F route inventory" % cutoff)

func _geometry_values(piece: TrackGeometryPieceScript) -> Dictionary:
	return {
		"kind": piece.kind,
		"first_route_serial": piece.first_route_serial,
		"last_route_serial": piece.last_route_serial,
		"nominal_length_cells": piece.nominal_length_cells,
		"absolute_start_distance_cells": piece.absolute_start_distance_cells,
		"footprint_cells": piece.footprint_cells.duplicate(),
		"centerline": piece.centerline.duplicate(),
		"exit_support_route_serial": piece.exit_support_route_serial,
	}

func _immutable_ledger_values(piece: TrackGeometryPieceScript) -> Dictionary:
	var values = _geometry_values(piece)
	values["group_id"] = piece.group_id
	return values

func _assert_locked_prefix_then_provisional(pieces: Array[TrackGeometryPieceScript], message: String) -> void:
	assert_equal(pieces.size(), 2, message)
	if pieces.size() != 2:
		return
	assert_true(pieces[0].locked, message)
	assert_false(pieces[1].locked, message)
	assert_equal(pieces[0].last_route_serial + 1, pieces[1].first_route_serial, message)
	var saw_provisional := false
	for piece in pieces:
		if not piece.locked:
			saw_provisional = true
		else:
			assert_false(saw_provisional, message)
```

The fixture must additionally assert after each cutoff that the surviving B–F record serials are exactly `cutoff + 1` through `5`, all are `BUILT`, and all have `geometry_locked == true`; G is exactly serial `6`, `RESERVED_GHOST`, and unlocked. The prepared B–F exit-support value is intentionally `-1`: G is appended only after `prepare_for_train_sampling(0.0, 0.0)`, so this case proves that the already-prepared candidate retains both its original no-support metadata and its post-prepare `group_id` through recovery while G remains a distinct provisional suffix.

Because the current implementation is expected to be GREEN before this coverage is added, make the test sensitivity explicit. Temporarily change only the `ledger_piece.locked = true` assignment inside `GridTrackRuntime.prepare_for_train_sampling` to `ledger_piece.locked = false`, run the focused suite, and require the exact RED marker `Prepared B through F curve is whole-piece locked`. Reverse that exact one-line mutation immediately. Before GREEN, require both the original blob and no production diff:

```powershell
Confirm-ReflowRedFocused 'test_grid_track_runtime.gd' 'Prepared B through F curve is whole-piece locked'
if ((Invoke-Task3FeatureGit @('hash-object',$Task3RecoveryRuntimePath)).Stdout.Trim() -ne $Task3RecoveryOriginalRuntimeBlob) { throw 'STOP: temporary recovery mutation did not restore the exact production blob' }
$Task3RecoveryRuntimeDiff = (Invoke-Task3FeatureGit @('diff','--',$Task3RecoveryRuntimePath)).Stdout
if ($Task3RecoveryRuntimeDiff.Trim().Length -ne 0) { throw 'STOP: temporary recovery mutation left a production diff' }
Invoke-ReflowFocused 'test_grid_track_runtime.gd'
Invoke-ReflowFullGate
```

Stage only the new runtime test. The resulting correction is test-only and must retain the durable production blob; do not stage the temporary mutation, manual record, report, plan, design, integration, or any production path.

```powershell
Invoke-Task3FeatureGit @('add','--',$Task3RecoveryTestPath) | Out-Null
Invoke-Task3FeatureGit @('diff','--cached','--check') | Out-Null
$Task3RecoveryStaged = Get-Task3Lines (Invoke-Task3FeatureGit @('diff','--cached','--name-only')).Stdout | Sort-Object
if (Compare-Object $Task3RecoveryStaged @($Task3RecoveryTestPath)) { throw 'STOP: same-serial recovery correction is not test-only' }
Invoke-Task3FeatureGit @('commit','-m','test: cover reflowable curve recovery lifecycle') | Out-Null
$Task3RecoveryCorrectionSha = (Invoke-Task3FeatureGit @('rev-parse','HEAD')).Stdout.Trim()
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3RecoveryCorrectionSha + '^'))).Stdout.Trim() -ne $TASK3_RECOVERY_AUTOMATION_BASE) { throw 'STOP: same-serial recovery correction is not a direct child of TASK3_RECOVERY_AUTOMATION_BASE' }
$Task3RecoveryPaths = Get-Task3Lines (Invoke-Task3FeatureGit @('diff-tree','--no-commit-id','--name-only','-r',$Task3RecoveryCorrectionSha)).Stdout | Sort-Object
if (Compare-Object $Task3RecoveryPaths @($Task3RecoveryTestPath)) { throw 'STOP: same-serial recovery correction changed a non-test path' }
if ((Invoke-Task3FeatureGit @('rev-parse',($Task3RecoveryCorrectionSha + ':' + $Task3RecoveryRuntimePath))).Stdout.Trim() -ne $Task3RecoveryDurableBlob) { throw 'STOP: same-serial recovery correction changed the durable production blob' }
if ((Get-Task3Lines (Invoke-Task3FeatureGit @('status','--porcelain=v1','-uall')).Stdout).Count -ne 0) { throw 'STOP: same-serial recovery correction did not leave a clean worktree' }
Write-Host "TASK3_RECOVERY_AUTOMATION_CORRECTION_SHA: $Task3RecoveryCorrectionSha"
```

Append an English entry to the ignored `task-3-report.md` before the repeated reviews. It must record the verified `RECOVERY_GATE_AMENDMENT_SHA` two-path bridge, `RECOVERY_ORACLE_FIX_SHA` plan-only bridge, runtime-captured `TASK3_RECOVERY_AUTOMATION_BASE` plan-only bridge, the new direct-child test-only SHA, the unchanged durable runtime blob, the temporary mutation RED marker, the focused/full GREEN anchors, the post-prepare B–F `group_id` oracle, and the separately verified G serial-6 provisional suffix. State that manual recovery frames were removed because they cannot prove the mutually exclusive same-candidate lifecycle. Do not launch the wrapper or create a manual commit for this automation-only correction.

## Final Feature Verification and Handoff

- [ ] Re-run the non-mutating preflight, except require feature `HEAD` to be a descendant of `0acb916b886484b8e41160373f0508142caad7a2`; still require the primary workspace to remain clean `main` at `fd5f87553556bf3ac7035bc5ae4a0995e37edbb5` and make no primary edits.
- [ ] Run `Invoke-ReflowFullGate` and retain the five PASS anchors.
- [ ] Run `git diff --check`, `git status --short`, `git log --oneline fd5f87553556bf3ac7035bc5ae4a0995e37edbb5..HEAD`, and `git diff --name-only fd5f87553556bf3ac7035bc5ae4a0995e37edbb5..HEAD` in the feature worktree. Require a clean feature worktree. The final feature-history allowlist is deliberately broader than any one task staging allowlist: it permits the approved spec `docs/superpowers/specs/2026-08-25-reflowable-track-head-design.md`, this plan `docs/superpowers/plans/2026-08-25-reflowable-track-head.md`, plus every exact path in the three task staging allowlists below—Task 1: `tests/run_all.gd`, `src/domain/track/track_cell_sequence.gd`, `src/domain/track/grid_track_runtime.gd`, `src/domain/track/track_geometry_piece.gd`, `tests/unit/test_track_cell_sequence.gd`, `tests/unit/test_grid_track_runtime.gd`, `tests/unit/test_track_system_construction_recovery.gd`, `tests/unit/test_track_geometry_resolver.gd`, `tests/smoke/test_track_train_app_composition.gd`; Task 2: `src/domain/track/grid_track_runtime.gd`, `src/domain/track/track_system.gd`, `src/domain/train/train_system.gd`, `src/domain/session/session_controller.gd`, `tests/run_all.gd`, `tests/unit/test_grid_track_runtime.gd`, `tests/unit/test_track_system_construction_recovery.gd`, `tests/unit/test_train_system.gd`, `tests/unit/test_nominal_train_motion.gd`, `tests/unit/test_session_controller.gd`, `tests/unit/test_track_train_session_controller.gd`, `tests/smoke/test_track_train_app_composition.gd`; Task 3: `src/presentation/track/track_field_view.gd`, `tests/unit/test_track_field_view_input.gd`, `tests/integration/run_track_train_input_integration.gd`, `tests/integration/run_track_train_app_integration.gd`, `tests/manual/track_train_windows.md`. Prefix every non-doc path with `godot-project-moe-rail-way/` when comparing `git diff --name-only` output; reject any other changed history path.
- [ ] Obtain a final independent Sol specification review against every section of `docs/superpowers/specs/2026-08-25-reflowable-track-head-design.md`, then a final independent Sol quality review of the final feature `HEAD`. A fresh Terra output worker resolves each accepted finding with focused commits and affected gates before the final reviews repeat.
- [ ] Record `FEATURE_SHA` with `git rev-parse HEAD` only after all gates and reviews pass. Stop at this clean feature `HEAD` with evidence. Do not merge, push, open a pull request, create a tag, synchronize primary `main`, remove a worktree, delete a branch, or perform cleanup.

## Plan Self-Review

| Approved specification coverage | Implementing task(s) |
|---|---|
| Construction/geometry separation, five-cell whole-piece horizon, solid built reflow | 1, 3 |
| Ledger determinism, exit support, atomic route/cancel rollback, recovery | 1; Task 3 correction Step 12 re-proves the same B–F lifecycle through preparation and sequential recovery |
| Authoritative anchors and derived active contacts | 1 regression protection |
| Epsilon ownership, prepare API, pose pair, no provisional sampling | 2 |
| Prepare-false safe return, tick order, terminal snapshot/result order | 2 |
| Endpoint-only multiframe input, hover/cancel behavior, manual Windows evidence | 3; manual evidence excludes same-candidate recovery proof |
| Inventory, serial, nominal motion, game premises, fixed-tick priorities | 1–3 full gates and final review |

The plan contains three implementation tasks, defines every interface before a later task consumes it, uses no new scripts, keeps `SessionResult` unchanged, and scopes every commit to exact paths. Tasks 1 and 2 each reach their one implementation commit after the complete 19-suite/four-integration gate is green; Task 3 first reaches its four-path durable implementation commit at that gate, then records only successful launcher/manual evidence in its second focused commit. The existing `b70a8e0ad68a76508178f4f23e47c03a02e7c6e0` correction remains test-only. The subsequent automation correction adds only `test_grid_track_runtime.gd` after verifying the fixed `b70a8e0ad68a76508178f4f23e47c03a02e7c6e0` → `72d7473ffbf200c0e37b2d559f86890dbef0f503` → `ed47d8b34f6bdc6ff3e285a219f52324dbb86c8d` documentation ancestry and capturing the current plan-only direct child of `ed47d8b34f6bdc6ff3e285a219f52324dbb86c8d` as `TASK3_RECOVERY_AUTOMATION_BASE`. It then requires sensitivity RED, restored-production-blob check, focused/full GREEN, and a test-only direct child of that captured base; it replaces impossible manual recovery lifecycle proof without relabeling any correction as tested production source or replacing the immutable complete Task 3 review base `94faa243f761d19a9459328f22792fa9e4f1dc3e`. Before execution, scan this plan with:

```powershell
$hangul_marker = [string]([char]0xD55C) + [string]([char]0xAE00)
$marker_pattern = ('TO' + 'DO|TB' + 'D|FIX' + 'ME|place' + 'holder|implement' + ' later|fill in' + ' details|' + $hangul_marker)
rg -n -i $marker_pattern docs\superpowers\plans\2026-08-25-reflowable-track-head.md
```

Expected: no matches. Confirm the plan contains only English agent-facing prose and that every task includes RED evidence, minimal GREEN, focused tests, full regression, exact staging, focused commit, and both independent Sol review gates.
