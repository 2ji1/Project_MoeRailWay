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
        @{ Script = 'res://tests/integration/run_session_shell_integration.gd'; Pass = 'PASS: session shell integration' },
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
PASS: session shell integration
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

Add declared methods with these exact signatures: `GridTrackRuntime.prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool`; `GridTrackRuntime.get_pose_sample_at_distance(route_distance: float) -> Dictionary`; `TrackSystem.prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool`; `TrackSystem.get_pose_sample_at_distance(route_distance: float) -> Dictionary`; and `TrainSystem.capture_pose(track_system: TrackSystemScript) -> Dictionary`. For this intentionally incomplete surface cycle only, the runtime preparation stub returns `true` without mutation and the new pose helper delegates to the existing sampler; Step 6 replaces both with locked-only behavior. Wire `SessionController` to call `track_system.prepare_for_train_sampling` exactly once in the `PREPARING_DEPARTURE` departure micro-cycle immediately before its existing state transition, deliberately leaving the current `RUNNING` path without a preparation call. The preceding Step 2 RED then turns green, and Step 9's `Running failure attempts preparation once` is guaranteed to fail after its fixture reaches `RUNNING`. Do not claim Task 2 GREEN or run the full gate yet: boundary ownership, rollback, locked-only sampling, and safe-return behavior are still absent.

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
	assert_true(is_equal_approx(before.position.distance_to(after.position), epsilon * 2.02 * 40.0), "Two-sided samples retain the expected nominal separation")

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
func run_unprepared_pose_probe() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Probe fixture appends provisional head")
	track.get_pose_sample_at_distance(0.0) # Must assert "Locked geometry is required for pose sampling" before sampling.
	print("POSE_FALLBACK") # Reached only if production incorrectly sampled provisional geometry.

# tests/run_all.gd: add this preload beside SUITES and this dispatch before the --suite selector.
const GridTrackRuntimeSuiteScript = preload("res://tests/unit/test_grid_track_runtime.gd")

for argument in OS.get_cmdline_user_args():
	if argument == "--reflow-unprepared-pose-probe":
		print("REFLOW_UNPREPARED_POSE_PROBE_BEGIN")
		GridTrackRuntimeSuiteScript.new().run_unprepared_pose_probe()
		quit(0)
		return
```

The Task 2 production method must enforce its locked-owner precondition before calling `sample_nominal`: `assert(owner.locked, "Locked geometry is required for pose sampling")`. `Confirm-ReflowUnpreparedPoseProbe` requires nonzero exit, that exact diagnostic, and absence of `POSE_FALLBACK`.

The five expected local distances are deliberate: `boundary - epsilon`, exact `boundary`, and `boundary + epsilon` all canonicalize to the exact boundary and belong to the predecessor; only values just outside epsilon retain their original predecessor/successor side.

- [ ] **Step 5: Run focused behavior RED evidence**

```powershell
Confirm-ReflowRedFocused 'test_grid_track_runtime.gd' 'Zero-extent wait locks only the predecessor'
```

Expected: after the API surface exists, its incomplete behavior still fails the ownership/rollback fixture. The second marker proves the behavior RED is not merely a missing-symbol parser diagnostic.

- [ ] **Step 6: Implement the smallest complete Task 2 behavior**

Create one private runtime helper used by preparation, position sampling, and heading sampling. Canonicalize only ownership/sample lookup; do not alter monotonic nominal motion distance. Preparation has two explicit stages: first, canonical ownership and positive interval overlap select one farthest required active owner; second, starting immediately after the existing active locked prefix frontier, stage every intervening provisional whole piece in route order through that farthest owner. A candidate may never lock a later owner while leaving a provisional predecessor, so its active locked pieces are always one contiguous prefix. At an internal zero-length boundary the farthest owner is the predecessor; at departure it is the entry piece. Commit only after resolution/continuity succeeds.

Add the exact constant `NOMINAL_BOUNDARY_EPSILON := 0.0001` and one private `GridTrackRuntime._canonical_distance_and_owner(route_distance: float) -> Dictionary` helper. It scans every active nominal boundary, replaces a distance whose absolute difference is less than or equal to epsilon with that boundary, and then selects the predecessor at an internal exact boundary; outside epsilon it leaves the raw distance on its original side. The returned dictionary has only `distance` and `piece` keys. Both `get_position_at_distance_cells` and `get_heading_at_distance_cells` delegate to the new `get_pose_sample_at_distance(route_distance: float) -> Dictionary`; that method uses this helper, requires its owner to be locked, and returns only the owner’s `sample_nominal(canonical_distance - owner.absolute_start_distance_cells)` pair.

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

# Add these helpers below the existing test helpers.
func _view_b_through_f_curve_piece() -> TrackGeometryPieceScript:
	var piece = TrackGeometryPieceScript.new()
	piece.group_id = 0
	piece.kind = TrackGeometryPieceScript.Kind.CURVE_3X3
	piece.first_route_serial = 1
	piece.last_route_serial = 5
	piece.nominal_length_cells = 5
	piece.absolute_start_distance_cells = 0.0
	piece.footprint_cells = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2)]
	piece.centerline = PackedVector2Array([Vector2(20.0, 20.0), Vector2(60.0, 20.0), Vector2(100.0, 20.0), Vector2(140.0, 60.0), Vector2(140.0, 100.0)])
	piece.active_local_end_cells = 5.0
	return piece

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
	var built = TrackCellRecordScript.new(1, Vector2i(1, 0), 0.0)
	built.state = TrackCellRecordScript.State.BUILT
	var curve = _view_b_through_f_curve_piece()
	fixture.view.present(_view_snapshot([built], [curve]))
	var intervals: Array = fixture.view.get_render_observation().get("intervals", [])
	var interval: Dictionary = intervals[0]
	assert_equal(interval.state, TrackCellRecordScript.State.BUILT, "Built state remains authoritative")
	assert_true(interval.locked == false, "Provisionality is metadata, not ghost state")
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

Do not edit the manual evidence in this step. Step 5 appends one new dated English evidence section only after the launcher/manual observation succeeds; it must cover the B–F/G slow route, solid B–E while F builds and reclassifies, G hover/right-click no-op, extension from G, entry without jump, rejected append preservation, and terminal snapshot before overlay. Do not rewrite the historical 2026-08-24 observations.

- [ ] **Step 2: Run focused RED evidence**

```powershell
Confirm-ReflowRedFocused 'test_track_field_view_input.gd' 'Support has no hover'
```

Expected: current `_is_cancelable_cell` checks only `RESERVED_GHOST`, so both a locked ghost and an exit-support ghost receive a hover affordance. The real integration right-click remains a no-op through Task 1’s runtime eligibility transaction.

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

- [ ] **Step 5: Perform the Windows manual play after automated GREEN**

Run `pwsh -NoProfile -File .\godot-project-moe-rail-way\tools\playtest\launch_editor_playtest.ps1` in the feature worktree; interact only with the launched editor/game window. Only after a successful observation, append the new dated English evidence section with actual date, feature `HEAD`, Godot version, observed route results, launcher exit `0`, `PASS: editor playtest completed`, and `DIAGNOSTICS_SCANNED:`. If launch, observation, or any marker is absent, stop without editing a PASS/pending manual record, committing, or terminating another user's editor process.

- [ ] **Step 6: Stage exactly the Task 3 allowlist and create the focused commit**

```powershell
git add -- `
  godot-project-moe-rail-way/src/presentation/track/track_field_view.gd `
  godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd `
  godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd `
  godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd `
  godot-project-moe-rail-way/tests/manual/track_train_windows.md
git diff --cached --check
git diff --cached --name-only
git commit -m "feat: preserve solid reflow rendering and support hover rules"
```

- [ ] **Step 7: Obtain independent Sol reviews**

Request a Sol specification review against spec Sections 1, 5, 10, 12, and 14, then a separate Sol quality review for detached observation use, hover correctness, event timing, multi-frame physical input, manual evidence integrity, no leaked domain mutation, and absence of provisional visual styling. Assign every accepted finding to a fresh Terra output worker using this allowlist only; rerun focused tests, both integrations, the full gate, and affected manual play, then repeat both Sol reviews.

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
| Ledger determinism, exit support, atomic route/cancel rollback, recovery | 1 |
| Authoritative anchors and derived active contacts | 1 regression protection |
| Epsilon ownership, prepare API, pose pair, no provisional sampling | 2 |
| Prepare-false safe return, tick order, terminal snapshot/result order | 2 |
| Endpoint-only multiframe input, hover/cancel behavior, manual Windows evidence | 3 |
| Inventory, serial, nominal motion, game premises, fixed-tick priorities | 1–3 full gates and final review |

The plan contains three implementation tasks, defines every interface before a later task consumes it, uses no new scripts, keeps `SessionResult` unchanged, and scopes every commit to exact paths. Every task reaches its only commit after its complete 19-suite/four-integration gate is green. Before execution, scan this plan with:

```powershell
$hangul_marker = [string]([char]0xD55C) + [string]([char]0xAE00)
$marker_pattern = ('TO' + 'DO|TB' + 'D|FIX' + 'ME|place' + 'holder|implement' + ' later|fill in' + ' details|' + $hangul_marker)
rg -n -i $marker_pattern docs\superpowers\plans\2026-08-25-reflowable-track-head.md
```

Expected: no matches. Confirm the plan contains only English agent-facing prose and that every task includes RED evidence, minimal GREEN, focused tests, full regression, exact staging, focused commit, and both independent Sol review gates.
