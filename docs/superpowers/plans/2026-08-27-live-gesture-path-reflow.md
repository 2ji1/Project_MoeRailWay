# Live Gesture Path Reflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make an ordinary endpoint drag reversible so its visible ghost shrinks and rebranches with the still-held pointer, while preserving completed-head template reselection and every route invariant.

**Architecture:** `TrackFieldView` owns a loop-erased full-path snapshot for the current physical press and places that detached snapshot in `TrackInputFrame`; the physical press-origin cell is excluded from the array and is explicitly represented as the authoritative implicit prefix immediately before it. `TrackSystem` forwards the snapshot unchanged; `GridTrackRuntime` reconciles record identities against the current path, rebuilds every candidate from the gesture origin, and commits only a completely valid candidate. Completed-head template selection keeps the authoritative current-pointer rule, but its suffix is reconciled against the current full path and the implicit origin prefix instead of append-only history. While capture is active, construction advances only the shared route-serial frontier present in both the gesture origin and current candidate, including editable-template serials, and mirrors their state/progress into both origin and candidate; gesture-added suffix serials remain ghost-only until finalization. Coalesced old-release/fresh-press frames carry detached old-release facts separately from fresh facts and finalize the old runtime before beginning/updating the fresh gesture.

**Current canonical status:** Scoped implementation, manual acceptance, final review, and main integration are complete on `main` via PR #15 merge commit `92d0823090851aa8608b1a7d7d2e046d4ec6a667`. Task 5 evidence remains attributed to tested HEAD `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239` and Task 6 evidence to tested HEAD `be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f`. Clean-gated code/test candidate `e285c9fc9db0a591beac93c169e198c8f80afa89` has the leak diagnostic resolved; the primary `main` retest passed 19 prototype suites plus all four integrations with no `WARNING:` or `ERROR:` output. Feature-worktree cleanup remains pending.

**Tech Stack:** Godot `4.7.1.stable.official.a13da4feb`, typed GDScript, existing prototype test harness, PowerShell, Git worktrees.

**Spec:** `docs/superpowers/specs/2026-08-27-live-gesture-path-reflow-design.md`

## Global Constraints

- Work only in `D:\godot\MoeRailWay-worktrees\live-gesture-path-reflow` on `feature/live-gesture-path-reflow`, based on `1a0cd466287f81c3a413c773fd8974d5dbb72f08` plus the approved design commit.
- Keep `D:\godot\MoeRailWay` as a clean user playtest checkout of `main`; do not stage, format, reset, stash, copy, absorb, or otherwise alter primary-worktree changes.
- Do not terminate, reset, or repurpose a user-owned Godot or Steam editor process.
- Use only `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe` for automated Godot gates. Steam Godot `4.7.2` is unsupported.
- Preserve endpoint-only start, gesture-origin abort, atomic last-valid publication, inventory conservation, monotonic serial allocation, immutable locked/train-entered geometry, construction rate and ordering, recovery, cancellation, hover colors, and train sampling. During an active endpoint gesture, construction may advance only route serials present in both the gesture origin and current candidate, including editable-template serials; mirror each state/progress change by serial into the current candidate and gesture origin, keep gesture-added suffix serials `RESERVED_GHOST` until finalize, and keep recovery paused.
- For completed-template suffixes, use the selected target's most recent live-path occurrence; if absent, use index `-1` only when the target exactly equals the authoritative gesture press origin and the selected template remains the gesture-origin/current selected template (same-template continuation), then reconcile the entire live path; when the template changes, reconciliation starts empty even if the newly selected target equals the origin; otherwise use an empty suffix. Never infer a suffix from target/pointer absence or use an append-only, synthetic, or pointer-invalid fallback.
- Add no pathfinding, route graph, freehand spline, undo stack, new visual ghost treatment, generalized input framework, or production abstraction layer.
- Write agent-facing Markdown in English and user progress reports in Korean.
- Every task must show the focused RED, minimum GREEN, the full 19-suite and four-integration regression gate, exact-path staging, a focused commit, specification review, and quality review in that order.

## File Structure and Ownership

- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`: physical mouse capture, grid rasterization, and current full loop-erased gesture path.
- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`: detached per-frame facts, including `live_gesture_path`, optional old-release path/pointer facts, and explicit-release-snapshot discrimination.
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`: endpoint capture facade and forwarding of the authoritative path snapshot.
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`: origin-based candidate reconstruction, path-fact reconciliation, serial watermarking, validation, and atomic publication.
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`: real view-event path normalization tests.
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`: input-frame ownership and facade/runtime ordinary reflow tests.
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`: domain transaction, inventory, identity, invalid-candidate, abort, and completed-template suffix tests.
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`: causal PREPARING/RUNNING construction and recovery lifecycle tests.
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`: train/session lifecycle regression tests.
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`: real `InputEventMouseButton`/`InputEventMouseMotion` held-gesture acceptance.
- `godot-project-moe-rail-way/tests/manual/track_train_windows.md`: English Windows manual evidence only after the implementation and automated gates pass.

### Final quality-correction contract

The final quality correction is limited to this exact code/test allowlist:

- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`

No production or test path outside this list may be modified for the correction.

## Standard Commands

Use these exact PowerShell variables in every task:

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\live-gesture-path-reflow\godot-project-moe-rail-way'
```

Run one registered unit suite with:

```powershell
& $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd -- --suite=test_track_field_view_input.gd
if ($LASTEXITCODE -ne 0) { throw 'Focused suite failed' }
```

Run the complete regression gate with:

```powershell
$MoeRailScripts = @(
    'res://tests/run_all.gd',
    'res://tests/integration/run_session_shell_integration.gd',
    'res://tests/integration/run_logical_track_field_integration.gd',
    'res://tests/integration/run_track_train_input_integration.gd',
    'res://tests/integration/run_track_train_app_integration.gd'
)
foreach ($MoeRailScript in $MoeRailScripts) {
    & $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailScript
    if ($LASTEXITCODE -ne 0) { throw "Prototype gate failed: $MoeRailScript" }
}
```

Expected complete markers include exactly `PASS: 19 prototype test suite(s)`, `PASS: track train input integration`, and `PASS: track train app integration`, with process exit code `0` for all five commands.

---

### Task 1: Publish a Reversible Full Drag Path

**Files:**
- Modify: `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`
- Modify: `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`

**Interfaces:**
- Consumes: existing `GridPointerRasterizer.rasterize_motion(...) -> Array[Vector2i]`, endpoint press cell, and current capture lifecycle.
- Produces: `TrackInputFrame.live_gesture_path: Array[Vector2i]`; constructor parameter `live_gesture_path_value: Variant = null`; `TrackFieldView._live_gesture_path: Array[Vector2i]`; private `TrackFieldView._apply_live_gesture_cell(cell: Vector2i) -> void`.
- Compatibility: when `live_gesture_path_value == null`, `TrackInputFrame` duplicates `crossed_cells_value` into `live_gesture_path` for existing synthetic producers. `TrackFieldView` always passes its explicit snapshot, including an explicitly empty array.

- [ ] **Step 1: Add focused failing view and record tests**

Add these calls immediately after `_test_endpoint_reshape_consume_frame_carries_current_pointer_facts()` in `test_track_field_view_input.gd::run()`:

```gdscript
_test_live_gesture_path_backtracks_and_rebranches_while_held()
_test_live_gesture_path_returns_to_press_origin()
```

Add tests using the existing `_fixture`, `_button`, `_motion`, `_local_for_cell`, and `_deliver` helpers:

```gdscript
func _test_live_gesture_path_backtracks_and_rebranches_while_held() -> void:
	print("Live gesture path: held backtrack truncates and rebranches")
	var fixture := _fixture()
	var view = fixture.view
	var origin := _local_for_cell(view, Vector2i(0, 0))
	_deliver(view, _button(origin, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(3, 0))))
	var first = view.consume_input_frame()
	assert_equal(first.live_gesture_path, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "First held frame publishes the complete path")
	_deliver(view, _motion(_local_for_cell(view, Vector2i(1, 0))))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(1, 2))))
	var rebranched = view.consume_input_frame()
	assert_true(rebranched.left_held and not rebranched.left_released, "Rebranch remains in the same press")
	assert_equal(rebranched.live_gesture_path, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)], "Earlier suffix is replaced by the new branch")
	assert_equal(first.live_gesture_path, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "Consumed snapshots remain detached")
	fixture.parent.free()


func _test_live_gesture_path_returns_to_press_origin() -> void:
	print("Live gesture path: returning to press origin clears the path")
	var fixture := _fixture()
	var view = fixture.view
	var origin := _local_for_cell(view, Vector2i(0, 0))
	_deliver(view, _button(origin, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(2, 0))))
	view.consume_input_frame()
	_deliver(view, _motion(origin))
	var cleared = view.consume_input_frame()
	assert_true(cleared.left_held and not cleared.left_released, "Origin return remains held")
	assert_equal(cleared.live_gesture_path, [], "Origin return publishes an explicitly empty path")
	fixture.parent.free()
```

In `test_track_system_reservation.gd::_test_input_frame_owns_an_independent_cell_buffer`, construct one frame with an explicit live path, mutate both source arrays, and assert that `crossed_cells` and `live_gesture_path` remain detached. Also assert that a legacy constructor call with no final argument copies `crossed_cells` into `live_gesture_path`.

- [ ] **Step 2: Run both focused suites and verify RED**

```powershell
foreach ($Suite in @('test_track_field_view_input.gd', 'test_track_system_reservation.gd')) {
    & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd -- --suite=$Suite
    if ($LASTEXITCODE -eq 0) { throw "Expected RED did not occur: $Suite" }
}
```

Expected RED: `TrackInputFrame` has no `live_gesture_path` property and the view cannot publish a full reversible snapshot. Fix syntax or fixture errors until the failure is specifically the missing production behavior.

- [ ] **Step 3: Implement the detached input fact**

In `track_input_frame.gd`, add:

```gdscript
var live_gesture_path: Array[Vector2i]
```

Append this final constructor parameter without changing the order of any existing parameter:

```gdscript
live_gesture_path_value: Variant = null
```

After duplicating `crossed_cells`, initialize the new member with concrete prototype compatibility:

```gdscript
live_gesture_path = []
var source_path: Array = crossed_cells_value if live_gesture_path_value == null else live_gesture_path_value
for cell in source_path:
	live_gesture_path.append(Vector2i(cell))
```

- [ ] **Step 4: Implement loop-erased view ownership**

In `track_field_view.gd`, add `_live_gesture_path: Array[Vector2i] = []`. Clear it on `_begin_left_press`, after constructing the released frame in `consume_input_frame`, and in `_clear_view_capture_after_termination`.

Pass `_live_gesture_path` as the final `TrackInputFrameScript.new(...)` argument. Do not clear it on ordinary per-tick consumption while the button remains held.

For every `segment_cells` entry in `_rasterize_to`, preserve the existing `_crossed_cells` compatibility behavior and call:

```gdscript
func _apply_live_gesture_cell(cell: Vector2i) -> void:
	if cell == _left_press_cell:
		_live_gesture_path.clear()
		return
	var existing_index := _live_gesture_path.find(cell)
	if existing_index >= 0:
		_live_gesture_path.resize(existing_index + 1)
		return
	_live_gesture_path.append(cell)
```

The rasterizer already supplies ordered orthogonally adjacent cells; do not add pathfinding or geometry decisions to the view.

- [ ] **Step 5: Run focused GREEN and the full regression gate**

Run both focused suites from Step 2 and require exit `0`. Then run the complete standard regression gate. Expected: both focused suites pass, the registered marker remains `PASS: 19 prototype test suite(s)`, and all four standalone integrations exit `0`.

- [ ] **Step 6: Stage only the Task 1 allowlist and commit**

```powershell
$Task1Paths = @(
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd',
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd'
)
git add -- $Task1Paths
git diff --cached --check
$Task1Actual = @(git diff --cached --name-only)
if (Compare-Object $Task1Paths $Task1Actual) { throw 'Task 1 staged path set mismatch' }
git commit -m 'feat: publish reversible live gesture path'
```

- [ ] **Step 7: Run independent specification review, then quality review**

Specification review checks the Task 1 commit against design sections 3.1, 3.2, and the `TrackFieldView`/`TrackInputFrame` responsibilities. It must reject geometry decisions in presentation, clearing the path during held per-tick consumption, missing release/termination cleanup, or aliased arrays. After specification approval, quality review checks typed GDScript, constructor compatibility, duplicate state, lifecycle leaks, focused-test causality, and exact diff scope. Resolve findings through a new RED/GREEN commit limited to the same allowlist, then repeat both reviews.

---

### Task 2: Rebuild Ordinary Candidates from the Current Path

**Files:**
- Modify: `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`

**Interfaces:**
- Consumes: `TrackInputFrame.live_gesture_path`, existing gesture origin, `_gesture_origin_sequence._next_route_serial`, and current-pointer template choice.
- Produces: `GridTrackRuntime.gesture_update(live_path: Array[Vector2i], current_pointer_cell: Vector2i = Vector2i(-1, -1)) -> bool`; private `_reconcile_gesture_input_facts(existing: Array[Dictionary], cells: Array[Vector2i]) -> Array[Dictionary]`.
- Invariant: the common path prefix retains serials; removed suffix serials are retired; newly branched cells receive serials above every previously published gesture serial.

- [ ] **Step 1: Add the facade RED for empty-departure reflow**

Add this call after `_test_endpoint_capture_appends_ordered_cells()` in `test_track_system_reservation.gd::run()`:

```gdscript
_test_ordinary_held_path_replaces_visible_candidate()
```

Add:

```gdscript
func _test_ordinary_held_path_replaces_visible_candidate() -> void:
	print("Live gesture path: ordinary held candidate reflows before release")
	var track = TrackSystemScript.new(_config(10))
	var first_path: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(TrackInputFrameScript.new(
		first_path, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, true, false, false, Vector2i(3, 0), true, first_path
	))
	var first_serials := track.get_cell_records().map(func(record): return record.route_serial)
	var replacement: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
	track.apply_left_input(TrackInputFrameScript.new(
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)], Vector2i(0, 0), true,
		Vector2i(-1, -1), false, false, true, false, false,
		Vector2i(1, 2), true, replacement
	))
	assert_equal(track.get_cell_records().map(func(record): return record.cell), replacement, "Held replacement removes the superseded ordinary suffix")
	assert_equal(track.get_available_track_cells(), 7, "Equal-length replacement preserves exact inventory")
	assert_equal(track.get_cell_records()[0].route_serial, first_serials[0], "Common path prefix retains identity")
	assert_true(track.get_cell_records()[1].route_serial > first_serials[-1], "New branch never reuses a removed serial")
	assert_true(track.is_left_capture_active() and track.is_runtime_gesture_active(), "Replacement remains held")
```

Add a second assertion sequence in the same test that sends an explicit empty authoritative path, expects no active route records and inventory `10`, then sends a new one-cell path and expects its serial to exceed every serial observed before the clear.

- [ ] **Step 2: Add runtime REDs for invalid recovery and exact abort**

In `test_grid_track_runtime.gd`, add calls near the existing ordinary-extension and abort tests:

```gdscript
_test_live_ordinary_path_reconciles_common_prefix_and_serial_watermark()
_test_invalid_live_rebranch_retains_last_valid_then_recovers()
```

The first test begins at an empty departure, calls `gesture_begin`, publishes `[RIGHT, RIGHT * 2, RIGHT * 3]`, then publishes `[RIGHT, RIGHT + DOWN, RIGHT + DOWN * 2]`. Assert current cells, exact inventory, common-prefix serial retention, fresh branch serials above the removed suffix, and successful publication of `[]` back to the origin.

The second test publishes a valid path, supplies a duplicate/self-overlapping path that must return `false` and preserve a deep value snapshot, then supplies a shorter valid path and requires `true`. Finish with `gesture_abort()` and compare records, pieces, inventory, ledger, recovery, contacts, and next-serial watermark against the gesture-origin contract already used by the existing abort serializer.

- [ ] **Step 3: Run focused suites and verify RED**

```powershell
foreach ($Suite in @('test_track_system_reservation.gd', 'test_grid_track_runtime.gd')) {
    & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd -- --suite=$Suite
    if ($LASTEXITCODE -eq 0) { throw "Expected RED did not occur: $Suite" }
}
```

Expected RED: the second held frame either retains the first candidate or tries to append the replacement to historical facts; an empty live path does not restore the origin candidate. Confirm no failure comes from malformed fixtures.

- [ ] **Step 4: Forward the authoritative full path**

In `track_system.gd::apply_left_input`, remove the construction of `gesture_cells` from per-frame `crossed_cells` plus pointer. While capture and runtime gesture are active, call:

```gdscript
var pointer_cell := input_frame.current_pointer_cell \
	if input_frame.current_pointer_inside_grid else Vector2i(-1, -1)
_runtime.gesture_update(input_frame.live_gesture_path, pointer_cell)
```

Call it even when the path snapshot is empty so a held return to the press origin can refund the full gesture-owned route. Preserve release finalization and all capture-latch ordering.

- [ ] **Step 5: Reconcile path facts in the runtime**

Rename the `gesture_update` parameter from `crossed_cells` to `live_path` and remove the early `live_path.is_empty()` rejection. Update all local scans and target-index calculations to use `live_path`.

Add:

```gdscript
func _reconcile_gesture_input_facts(
	existing: Array[Dictionary],
	cells: Array[Vector2i]
) -> Array[Dictionary]:
	var common_count := 0
	while (
		common_count < existing.size()
		and common_count < cells.size()
		and Vector2i(existing[common_count]["cell"]) == cells[common_count]
	):
		common_count += 1
	var reconciled: Array[Dictionary] = existing.slice(0, common_count).duplicate(true)
	for index in range(common_count, cells.size()):
		reconciled = _append_new_gesture_input_fact(reconciled, cells[index])
	return reconciled
```

For ordinary extension, replace append-only iteration with:

```gdscript
next_ordinary_input_facts = _reconcile_gesture_input_facts(
	_gesture_ordinary_input_facts,
	live_path
)
```

Allow an empty ordinary fact list to stage and publish the exact origin sequence. Keep `_advance_gesture_serial_watermark(candidate_sequence)` after a valid commit so later branches allocate above removed candidates. Do not renumber fixed-origin records or mutate the origin route contents.

- [ ] **Step 6: Migrate direct runtime tests to full-path semantics**

Within the Task 2 allowlisted `test_grid_track_runtime.gd`, update every multi-frame direct `gesture_update` fixture so each call supplies the complete current live path, not just the newest delta. Single-frame fixtures remain unchanged. Do not weaken expected cells, inventory, invalid-candidate equality, abort, lock, anchor, or train-preparation assertions.

- [ ] **Step 7: Run focused GREEN and the full regression gate**

Run both focused suites from Step 3 and then the complete standard regression gate. Expected: live ordinary reflow passes; all historical ordinary, completed-template, abort, lock, preparation, construction, recovery, and integration evidence remains green.

- [ ] **Step 8: Stage only the Task 2 allowlist and commit**

```powershell
$Task2Paths = @(
    'godot-project-moe-rail-way/src/domain/track/track_system.gd',
    'godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd'
)
git add -- $Task2Paths
git diff --cached --check
$Task2Actual = @(git diff --cached --name-only)
if (Compare-Object $Task2Paths $Task2Actual) { throw 'Task 2 staged path set mismatch' }
git commit -m 'fix: rebuild ordinary ghost from held path'
```

- [ ] **Step 9: Run independent specification review, then quality review**

Specification review checks design sections 3.3, 3.6, 4, and the `TrackSystem`/`GridTrackRuntime` responsibilities. It must reject delta accumulation, failure to publish an empty path, serial reuse, fixed-origin identity drift, non-atomic mutation, or changes to resolver/train/hover behavior. Quality review then checks the reconciliation common-prefix boundary, deep copies, empty arrays, watermark advancement, invalid-candidate rollback, stale state after abort/finalize, and all direct-test migrations. Resolve findings with a fresh focused RED where behavior changes, commit only Task 2 paths, and repeat both reviews.

---

### Task 3: Reconcile Completed-Template Suffixes and Prove Real Input

**Files:**
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- Test: `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`

**Interfaces:**
- Consumes: Task 1 full live path, Task 2 `_reconcile_gesture_input_facts`, existing `_template_index_from_pointer`, `_gesture_target_endpoints`, and `_gesture_selected_template_index`.
- Produces: one current template-owned suffix fact list reconciled against the complete path after the selected target's most recent occurrence, with the physical press origin treated as an implicit index `-1` only when it is exactly the selected target.

- [ ] **Step 1: Add a focused template-suffix RED**

In `test_track_system_reservation.gd`, add a held completed-head scenario that:

1. creates and finalizes the existing right `CURVE_3X3` fixture;
2. begins one new endpoint press;
3. publishes the straight template plus `[Vector2i(6, 2), Vector2i(7, 2)]` using a full live path;
4. remains held and supplies a shorter full path ending at `Vector2i(6, 2)`;
5. asserts that `Vector2i(7, 2)` disappears and exactly one inventory cell is refunded; and
6. supplies a rebranched template/suffix path and asserts fresh non-reused serials.

Specify the RUNNING-state recovery case for the actual-event integration in Step 2: start with `18` inventory cells, build `13` straight records, construct/lock/sample the train, recover the rear prefix to `7` records and `11` available cells, press the current endpoint of the resulting three-record straight editable head, and drag to an adjacent valid cell. Before release, require an eighth record/current endpoint and `10` available cells. This case must specifically exercise the selected target equal to the physical press origin, which is implicit rather than present in `live_gesture_path`.

Name the test `_test_completed_template_suffix_backtracks_while_held` and print `Live gesture path: completed template suffix backtracks while held`.

In `test_grid_track_runtime.gd`, add `_test_live_template_suffix_reconciles_from_current_path()` beside the existing target re-entry test. Create the existing completed right-curve fixture, begin at its endpoint, publish a full path containing the straight target plus two suffix cells, then publish a shorter full path containing the same target plus only the first suffix cell. Assert that the second suffix cell disappears, one inventory cell is refunded, the surviving suffix serial is unchanged, and capture remains active. This is the domain-level RED that must fail before changing suffix ownership.

- [ ] **Step 2: Add the real-event integration RED**

In `run_track_train_input_integration.gd`, use the existing `_deliver`, `_button`, `_motion`, `_logical_to_viewport`, `view`, and `track` fixtures. Before release, perform:

```gdscript
await _deliver(_button(origin_position, MOUSE_BUTTON_LEFT, true))
await _deliver(_motion(first_endpoint_position, MOUSE_BUTTON_MASK_LEFT))
var first_frame = view.consume_input_frame()
track.apply_left_input(first_frame)
await _deliver(_motion(backtrack_position, MOUSE_BUTTON_MASK_LEFT))
await _deliver(_motion(opposite_endpoint_position, MOUSE_BUTTON_MASK_LEFT))
var replacement_frame = view.consume_input_frame()
track.apply_left_input(replacement_frame)
```

Use cells that form a valid first L path and, after crossing an earlier gesture cell, a valid opposite L path. Assert all of these before sending a left release:

- both frames have `left_held == true` and `left_released == false`;
- `replacement_frame.live_gesture_path` omits the superseded suffix;
- current track records equal the replacement path;
- current inventory equals total inventory minus replacement length;
- facade and runtime captures remain active; and
- the first detached frame still contains its original path.

Print exactly `PASS: live ordinary ghost follows held rebranch` when this complete block passes.

The same integration must include the recovery-state event sequence from Step 1, using actual `InputEventMouseButton` and `InputEventMouseMotion` instances while the session is RUNNING. Assert the recovered setup (`7` records, `11` available), the three-record editable head, the endpoint press, the adjacent drag, and the pre-release eighth record/current endpoint with `10` available. A direct `gesture_update` call cannot substitute for this event coverage.

- [ ] **Step 3: Run focused unit and integration commands and verify RED**

```powershell
foreach ($Suite in @('test_track_system_reservation.gd', 'test_grid_track_runtime.gd')) {
    & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd -- --suite=$Suite
    if ($LASTEXITCODE -eq 0) { throw "Expected RED did not occur: $Suite" }
}
& $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_track_train_input_integration.gd
if ($LASTEXITCODE -eq 0) { throw 'Expected integration RED did not occur' }
```

Expected RED: the completed-template suffix retains the longer historical suffix or the real-event replacement does not publish before release. The new integration marker must be absent.

- [ ] **Step 4: Reconcile only the current selected-target suffix**

In `grid_track_runtime.gd::gesture_update`, find the most recent occurrence of the authoritative selected target in `live_path`. Build `current_suffix_cells` from cells after that index. If the target is absent from `live_path` but exactly equals the authoritative gesture press origin, treat the origin as the implicit occurrence at index `-1` only when the selected template remains the gesture-origin/current selected template (same-template continuation), and reconcile the entire `live_path` as `current_suffix_cells`. When the selected template changes, reconciliation starts from an empty fact list even if the newly selected target equals the origin. For every other absent target, use an empty suffix. Do not add an append-only, synthetic, or pointer-invalid fallback. Replace all append-only `next_suffix_input_facts` branches with `_reconcile_gesture_input_facts(_gesture_suffix_input_facts, current_suffix_cells)`.

When the selected template changes, do not retain facts from the previous template even if cell values share a prefix; start reconciliation from an empty fact list so a superseded template-owned serial is never reassigned under the new template. Preserve exact current-pointer tie behavior and candidate validation.

- [ ] **Step 5: Run focused GREEN and the full regression gate**

Run both unit suites and the input integration from Step 3; require the new exact PASS marker once. Then run the complete standard regression gate. Expected: 19 suites and four integrations pass without warnings or errors.

- [ ] **Step 6: Stage only the Task 3 allowlist and commit**

```powershell
$Task3Paths = @(
    'godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd',
    'godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd'
)
git add -- $Task3Paths
git diff --cached --check
$Task3Actual = @(git diff --cached --name-only)
if (Compare-Object $Task3Paths $Task3Actual) { throw 'Task 3 staged path set mismatch' }
git commit -m 'fix: reflow held template suffix from current path'
```

- [ ] **Step 7: Run independent specification review, then quality review**

Specification review checks design section 3.5 and required evidence 8-13, including actual Godot input objects, the RUNNING-state post-recovery sequence, and pre-release observation. Quality review checks most-recent target indexing, implicit-origin index `-1` handling, template changes with empty reconciliation, serial retirement, pointer-near-target behavior, suffix refund, and exact integration marker cardinality. Resolve any finding within the Task 3 allowlist through RED/GREEN and repeat both reviews.

---

### Task 4: Manual Acceptance, Final Evidence, and Branch Gate

**Files:**
- Modify: `godot-project-moe-rail-way/tests/manual/track_train_windows.md`
- Modify: `docs/superpowers/specs/2026-08-27-live-gesture-path-reflow-design.md`

**Interfaces:**
- Consumes: reviewed Task 1-3 commits and the exact manual acceptance sequence in design section 7, including the required RUNNING-state recovery case.
- Produces: English manual evidence tied to the tested feature commit and a design status that names that commit without claiming `main` integration before it occurs. The recovery failure observed before this amendment remains a required fix; this documentation amendment does not mark the design Implemented or accepted.

- [ ] **Step 1: Re-run the clean feature gate before manual playtest**

Require `git status --short` to be empty. Run the complete standard regression gate and record the full feature `HEAD`, Godot version, `PASS: 19 prototype test suite(s)`, all four integration results, and the new live-rebranch marker.

- [ ] **Step 2: Run the visible Windows acceptance without touching the user editor**

Launch a separate test-owned Godot `4.7.1` playtest from the feature worktree or the repository's approved disposable playtest launcher. Do not attach to, terminate, reset, or reuse the user's existing Godot window. Perform the manual steps in design section 7, including the empty-departure reproduction, ordinary backtrack/rebranch before release, completed-head suffix shortening, exact inventory observation, right-click origin restoration, and the 18-inventory/13-straight/construct-lock-sample/recover-to-7-and-11/three-record-head/adjacent-drag recovery sequence before release.

If a separate safe playtest cannot be launched without interfering with the user-owned editor, stop and request the user to execute the exact acceptance sequence on a reviewed candidate; do not mark manual acceptance passed from automated evidence alone.

- [ ] **Step 3: Write exact English evidence**

Append a dated section to `tests/manual/track_train_windows.md` containing:

- exact feature `HEAD`;
- exact Godot version;
- whether the run was test-agent-owned or user-observed;
- each acceptance action and its observed result;
- visible inventory before, during, after rebranch, and after abort;
- confirmation that the replacement appeared before left release;
- the RUNNING-state recovery result: eighth record/current endpoint and `10` available before release, or the exact failure without upgrading it to PASS;
- confirmation that no user-owned editor was terminated or reset; and
- any limitation or failed observation without upgrading it to PASS.

Change the design status to `Implemented on feature branch; pending main integration` and add the reviewed feature commit SHA only after the manual sequence passes.

- [ ] **Step 4: Validate documentation and commit**

```powershell
rg -n 'TBD|TODO|PLACEHOLDER' docs/superpowers/specs/2026-08-27-live-gesture-path-reflow-design.md godot-project-moe-rail-way/tests/manual/track_train_windows.md
git diff --check
$Task4Paths = @(
    'godot-project-moe-rail-way/tests/manual/track_train_windows.md',
    'docs/superpowers/specs/2026-08-27-live-gesture-path-reflow-design.md'
)
git add -- $Task4Paths
git diff --cached --check
$Task4Actual = @(git diff --cached --name-only)
if (Compare-Object $Task4Paths $Task4Actual) { throw 'Task 4 staged path set mismatch' }
git commit -m 'docs: record live gesture path acceptance'
```

- [x] **Step 5: Obtain final independent specification and quality reviews**

Final specification review read the approved design, this plan, every feature commit after base `1a0cd466287f81c3a413c773fd8974d5dbb72f08`, automated outputs, and manual evidence. Final quality review inspected all production and test diffs for correctness, maintainability, prototype concreteness, test validity, serial/inventory safety, lifecycle cleanup, and absence of unrelated changes. Both reviews passed before integration.

- [x] **Step 6: Report the clean reviewed feature HEAD and apply the main-first publication policy**

The reviewed feature was integrated under the active main-first policy through PR #15 merge commit `92d0823090851aa8608b1a7d7d2e046d4ec6a667`. The primary `main` retest passed 19 prototype suites plus all four standalone integrations with no `WARNING:` or `ERROR:` output. Feature-worktree and branch cleanup remains pending as a separate gate.

---

### Task 5: Correct coalesced release ordering and template replay idempotence

**Status:** Completed and integrated on `main` via PR #15 merge commit `92d0823090851aa8608b1a7d7d2e046d4ec6a667`; manual and scoped specification/quality review evidence is recorded at the historical tested HEAD. The primary `main` retest passed 19 prototype suites plus all four integrations with no `WARNING:` or `ERROR:` output. Feature-worktree cleanup remains pending.

**Exact code/test allowlist:**

- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`

No production or test path outside this list may be modified for this correction. Do not add a generalized input queue or framework, pathfinding, route graph, spline, or unrelated behavior.

**Required contracts:**

- `TrackInputFrame` adds optional `release_live_gesture_path`, `left_release_pointer_cell`, and `left_release_pointer_inside_grid` constructor facts plus an observable/derived explicit-release-snapshot flag. Legacy constructors and synthetic combined frames remain compatible.
- `TrackFieldView` captures detached old-release full-path and pointer facts immediately after release rasterization, before fresh-press cleanup. Fresh live path/pointer facts remain separate and authoritative for the new press; release, outside-grid, empty-origin, abort, train termination, and session completion cleanup clear the correct buffers.
- `TrackSystem` handles only combined old-release/fresh-held-press frames as two ordered phases: explicit old release updates/finalizes an active old runtime before fresh begin/update; inactive, rejected, or train-terminated old state ignores old geometry facts but clears its latch; synthetic combined frames without an explicit snapshot preserve last-valid finalize compatibility and never apply fresh facts to the old runtime.
- `GridTrackRuntime` records the successful origin-equal absent-target template-selection signature, revalidates identical held snapshots without suffix or validation bypass, permits changed later same-template implicit-origin continuation, and removes that implicit suffix when returning to the signature. In-array most-recent target precedence remains authoritative; template changes reconcile from empty.

- [ ] **Step 1: Add the focused RED matrix before production changes**

Add tests for every required boundary:

1. Move release A to B, then issue a fresh press at B in one coalesced frame; prove old finalization consumes A's detached facts and fresh capture starts from B without cross-contamination.
2. Supply an explicit empty release path and an explicit outside-grid release pointer; prove empty is authoritative, outside does not invent path cells, and fresh facts are not applied to the old runtime.
3. Cover active old runtime, inactive/rejected old state, and train-terminated old state; prove only active explicit old release mutates/finalizes geometry and all old latches clear.
4. Cover ordinary release, empty return-to-origin, fresh held follow-up, and release/abort/train/session termination cleanup for both live and release buffers.
5. Select an origin-equal absent target on a template-change frame; prove empty suffix plus a detached selection signature.
6. Replay the identical held path/pointer; prove the same candidate is rebuilt and revalidated without suffix growth or lock/recovery/validation bypass.
7. Change the later path or pointer under the same template; prove implicit-origin continuation can extend, then return to the selection signature and prove the implicit suffix is removed.
8. Re-enter an in-array target and change templates; prove most-recent in-array occurrence wins and template changes reconcile from empty.
9. Construct a legacy `TrackInputFrame` without release facts and combine an old release with a fresh held press; prove the legacy constructor remains valid, the explicit-release-snapshot discriminator is false, fresh live path/pointer facts are never applied to the old runtime, the old last-valid candidate finalizes compatibly, the old latch/capture clears, and the fresh eligible press begins and updates normally. This test must fail causally before the correction because the missing discriminator/order allows either old-state contamination or an incomplete old finalization.

- [ ] **Step 2: Run the focused suites and verify RED**

Run the affected unit suites and real-event integration with the exact Godot variables from the standard commands. Each new case must fail for the intended missing ordering or replay behavior, not malformed fixtures. The integration must use actual `InputEventMouseButton` and `InputEventMouseMotion` delivery for release A, fresh press B, explicit empty/outside release, and the completed-template replay sequence.

Focused GREEN expectation: after the correction, the legacy combined-frame case passes all seven assertions in item 9—constructor compatibility, discriminator false, no fresh-fact application to old runtime, compatible old last-valid finalization, old latch/capture clearing, and fresh eligible begin/update—while the explicit-snapshot path continues to finalize the old runtime before fresh begin/update.

- [ ] **Step 3: Implement detached release facts and constructor compatibility**

Add the optional `TrackInputFrame` facts and explicit-release-snapshot discrimination. Update `TrackFieldView` to snapshot old release path/pointer immediately after rasterization and before fresh press buffers clear. Preserve detached array ownership and all ordinary, outside-grid, origin-return, abort, train-termination, and session-completion cleanup.

- [ ] **Step 4: Implement ordered facade processing**

In `TrackSystem`, detect only the combined old-release/fresh-held-press case. For an active old runtime with an explicit snapshot, call old `gesture_update` with old facts, finalize the last valid candidate, and clear old latch/capture before fresh begin/update. For inactive, rejected, or train-terminated old state, ignore old geometry facts but clear its latch. For legacy synthetic combined frames without an explicit snapshot, retain compatibility finalization and never route fresh facts to the old runtime.

- [ ] **Step 5: Implement template replay signature reconciliation**

In `GridTrackRuntime`, store the detached successful template-selection signature only for the origin-equal absent-target template-change case. Identical held snapshots must rebuild and validate normally without adding suffix facts. A changed later path/pointer may enter the same-template implicit-origin rule; returning to the signature removes that suffix. Keep in-array most-recent precedence, empty reconciliation on template changes, and all existing locks, recovery, atomic publication, and validation.

- [ ] **Step 6: Run focused GREEN and the complete regression gate**

Run every RED matrix unit suite and the real-event integration, then the full `PASS: 19 prototype test suite(s)` plus all four standalone integrations. Require the coalesced release and replay markers exactly once. Run the affected Windows manual sequence again in a separate test-owned Godot 4.7.1 process, including the ordinary figures, RUNNING recovery before terminal completion, and terminal input lock. Do not restore the implemented status until the manual rerun passes.

- [ ] **Step 7: Stage and commit only the correction allowlist**

```powershell
$Task5Paths = @(
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd',
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
    'godot-project-moe-rail-way/src/domain/track/track_system.gd',
    'godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd'
)
git add -- $Task5Paths
git diff --cached --check
$Task5Actual = @(git diff --cached --name-only)
if (Compare-Object $Task5Paths $Task5Actual) { throw 'Task 5 staged path set mismatch' }
git commit -m 'fix: order coalesced release and fresh press'
```

- [x] **Step 8: Repeat scoped reviews and affected manual evidence**

Specification review checks the coalesced release contract, explicit empty/outside facts, active/inactive/train-terminated ordering, constructor compatibility, and template replay rules. Quality review checks detached ownership, stale-buffer cleanup, legacy synthetic compatibility, signature equality, no early-return cache, exact validation on replay, and exact allowlist scope. This scoped review and affected manual evidence are complete at the reviewed feature HEAD. PR #15 merged the reviewed slice into `main` at `92d0823090851aa8608b1a7d7d2e046d4ec6a667`, and the primary `main` retest passed 19 prototype suites plus all four integrations with no `WARNING:` or `ERROR:` output. Feature-worktree cleanup remains pending.

---

### Task 6: Continue Origin-Owned Construction During a Held Gesture

**Status:** Completed and integrated on `main` via PR #15 merge commit `92d0823090851aa8608b1a7d7d2e046d4ec6a667`; the Task 6 Sol specification/quality approvals and user manual PASS remain attributed to tested HEAD `be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f`. The primary `main` retest passed 19 prototype suites plus all four integrations with no `WARNING:` or `ERROR:` output. Feature-worktree cleanup remains pending.

**Files:**
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- Test: `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`

**Purpose:** Correct the construction lifecycle exposed by the live gesture manual
failure. An active endpoint edit must not freeze the already-reserved route. The
construction frontier is defined by route identity, not by whether a record lies in
the editable template span: every serial present in the gesture origin may continue
at the existing rate and order. Only serials introduced by the held candidate and
absent from the origin remain ghost-only until finalization.

**Interfaces:**
- Consumes `_gesture_active`, `_gesture_origin_sequence`, the current candidate
  sequence, route serial/state/build-progress fields, `advance_construction`,
  `recover_behind`, and existing train-preparation sampling/lock state.
- Produces origin-owned construction progress mirrored by route serial into both the
  current candidate and gesture origin, ghost-only gesture-added suffixes, paused
  recovery, and unchanged inventory, lock, train-sampling, and construction timing
  contracts.

- [ ] **Step 1: Write the focused RED tests before changing production code**

  Add the smallest deterministic route fixture that leaves a previously finalized
  route partially constructed, begins an endpoint gesture, updates a valid candidate,
  and advances construction while the gesture remains held. Assert the following
  exact expectations:

  - A two-cell origin route is advanced by `1.5`: the first serial is `BUILT`, the
    second is `BUILDING` at `0.5`, and the built/reserved distances are `1.0`/`2.0`.
  - After a held endpoint update adds a new candidate suffix, call active
    `advance_construction(2.0)` when only `0.5` remains on the origin route. The
    method must return exactly `0.5`, the next origin serial must become `BUILT`,
    built/reserved distances must become `2.0`/`3.0`, and the leftover `1.5` budget
    must not transition the gesture-added serial: it remains `RESERVED_GHOST` with
    build progress `0.0`. The current implementation returns `0.0` and leaves the
    old built/progress frontier unchanged, so this assertion must fail RED.
  - Use a longer origin sequence with a partially built first serial and enough
    budget to cross at least two origin-serial boundaries. Assert that consumption
    follows route order and the configured per-tick rate: each earlier serial reaches
    `BUILT` before the next serial advances, the final origin serial receives only
    the remaining budget, and the returned consumed amount equals the budget used
    through the origin frontier rather than any suffix work.
  - Reflow an existing five-record editable template after partial construction.
    Serials from the gesture origin, including those inside the editable span, keep
    advancing. Build an exact `{route_serial: {state, build_progress}}` map and
    assert equality for every shared origin serial in the current candidate and
    gesture origin after each held reflow. A suffix serial absent from the origin
    remains `RESERVED_GHOST` with progress `0.0`.
  - After abort, assert that the restored route's serial map equals the latest
    mirrored origin map, not the stale pre-tick map. After finalize, assert that the
    origin-owned serial map is retained and the new suffix remains ghost-only during
    the held edit; only a subsequent post-release tick may advance that suffix.
  - Submit a rejected held update and assert that the last-valid candidate, the
    gesture-origin serial map, the current shared serial map, inventory, and
    lock/ledger observations are unchanged from the immediately preceding valid
    tick.
  - `recover_behind` continues to return `0` while the gesture is active, including
    while origin-owned construction advances.
  - Capture inventory and lock/ledger snapshots before the active construction tick
    and assert they are byte-for-byte unchanged afterward. In the session-controller
    fixture, record the causal calls and assert the order is input application,
    construction advance, then train preparation/sampling; no train sample may
    observe a candidate before the construction step has completed.
  - In the active-gesture train-sampling fixture, assert that overlapping sampling
    terminates the gesture before immutable sampling, while non-overlapping sampling
    preserves the active capture and locks only complete geometry pieces. Both paths
    must retain the origin/current shared serial map and leave gesture-added suffixes
    unbuilt.

- [ ] **Step 2: Run the focused RED gate**

  Run the four affected unit suites and the real-input integration script before
  modifying production code. The new construction-frontier assertions must fail
  because the current runtime's active-gesture early return consumes no progress;
  unrelated existing assertions must remain green. Record the failure marker and
  the unchanged built/reserved measurements in the task evidence.

- [ ] **Step 3: Implement the minimum runtime correction**

  Keep the configured construction rate, sequential route order, and existing
  inventory accounting. Replace only the active-gesture construction decision:
  derive the frontier from route serials present in both `_gesture_origin_sequence`
  and the current candidate, advance the first eligible unbuilt origin serial in
  the current candidate, and never transition a serial absent from the origin out
  of `RESERVED_GHOST`. Return only the amount consumed by shared origin work; any
  input budget left after that frontier is exhausted is discarded for this active
  tick and must not be applied to a suffix.
  Mirror each changed origin serial's exact state and build progress by serial into
  both the current candidate and `_gesture_origin_sequence` before the next held
  update. Leave piece ownership, inventory, geometry locks, ledger semantics, train
  preparation, and sampling order unchanged. Keep `recover_behind` paused while
  active, and ensure later update/abort starts from the mirrored origin state.

- [ ] **Step 4: Run minimum GREEN, full regression, and lifecycle evidence**

  Rerun the focused four unit suites and integration until the new assertions pass,
  then run the complete `PASS: 19 prototype test suite(s)` gate and all four
  standalone integrations. Require evidence that construction continues during a
  held gesture, returned consumption stops at the origin frontier even when input
  budget is larger than the remaining origin work, multiple serial boundaries retain
  order/rate, editable-template serials retain progress through reflow, and exact
  serial maps survive valid reflow, abort, finalize, and rejected updates. Also
  require unchanged inventory and lock/ledger snapshots, the causal
  input-to-construction-to-train order, active-gesture overlap/non-overlap sampling
  behavior, suffix serials remaining ghost-only until release, and paused recovery.

- [ ] **Step 5: Stage and commit only the correction allowlist**

```powershell
$Task6Paths = @(
    'godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd',
    'godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/unit/test_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd'
)
git add -- $Task6Paths
git diff --cached --check
$Task6Actual = @(git diff --cached --name-only)
if (Compare-Object $Task6Paths $Task6Actual) { throw 'Task 6 staged path set mismatch' }
git commit -m 'fix: continue origin-owned construction during gestures'
```

- [ ] **Step 6: Run independent specification and quality reviews**

  Specification review checks design sections 3.4, 3.6, 4, and Section 5's
  `GridTrackRuntime` responsibility, plus required
  evidence 17-19. Quality review checks route-serial frontier membership, editable-span
  reflow, exact origin/current state-progress mirroring, suffix ghost-only behavior,
  abort/finalize timing, paused recovery, and preservation of locks, inventory, and
  train sampling. Any finding must be resolved with a new focused RED/GREEN commit
  inside the six-path allowlist, followed by the full regression gate.
