# Live Gesture Path Reflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make an ordinary endpoint drag reversible so its visible ghost shrinks and rebranches with the still-held pointer, while preserving completed-head template reselection and every route invariant.

**Architecture:** `TrackFieldView` owns a loop-erased full-path snapshot for the current physical press and places that detached snapshot in `TrackInputFrame`; the physical press-origin cell is excluded from the array and is explicitly represented as the authoritative implicit prefix immediately before it. `TrackSystem` forwards the snapshot unchanged; `GridTrackRuntime` reconciles record identities against the current path, rebuilds every candidate from the gesture origin, and commits only a completely valid candidate. Completed-head template selection keeps the authoritative current-pointer rule, but its suffix is reconciled against the current full path and the implicit origin prefix instead of append-only history.

**Tech Stack:** Godot `4.7.1.stable.official.a13da4feb`, typed GDScript, existing prototype test harness, PowerShell, Git worktrees.

**Spec:** `docs/superpowers/specs/2026-08-27-live-gesture-path-reflow-design.md`

## Global Constraints

- Work only in `D:\godot\MoeRailWay-worktrees\live-gesture-path-reflow` on `feature/live-gesture-path-reflow`, based on `1a0cd466287f81c3a413c773fd8974d5dbb72f08` plus the approved design commit.
- Keep `D:\godot\MoeRailWay` as a clean user playtest checkout of `main`; do not stage, format, reset, stash, copy, absorb, or otherwise alter primary-worktree changes.
- Do not terminate, reset, or repurpose a user-owned Godot or Steam editor process.
- Use only `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe` for automated Godot gates. Steam Godot `4.7.2` is unsupported.
- Preserve endpoint-only start, gesture-origin abort, atomic last-valid publication, inventory conservation, monotonic serial allocation, immutable locked/train-entered geometry, construction, recovery, cancellation, hover colors, and train sampling.
- For completed-template suffixes, use the selected target's most recent live-path occurrence; if absent, use index `-1` only when the target exactly equals the authoritative gesture press origin and then reconcile the entire live path; otherwise use an empty suffix. Never infer a suffix from target/pointer absence or use an append-only, synthetic, or pointer-invalid fallback.
- Add no pathfinding, route graph, freehand spline, undo stack, new visual ghost treatment, generalized input framework, or production abstraction layer.
- Write agent-facing Markdown in English and user progress reports in Korean.
- Every task must show the focused RED, minimum GREEN, the full 19-suite and four-integration regression gate, exact-path staging, a focused commit, specification review, and quality review in that order.

## File Structure and Ownership

- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`: physical mouse capture, grid rasterization, and current full loop-erased gesture path.
- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`: detached per-frame facts, including `live_gesture_path`.
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`: endpoint capture facade and forwarding of the authoritative path snapshot.
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`: origin-based candidate reconstruction, path-fact reconciliation, serial watermarking, validation, and atomic publication.
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`: real view-event path normalization tests.
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`: input-frame ownership and facade/runtime ordinary reflow tests.
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`: domain transaction, inventory, identity, invalid-candidate, abort, and completed-template suffix tests.
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`: real `InputEventMouseButton`/`InputEventMouseMotion` held-gesture acceptance.
- `godot-project-moe-rail-way/tests/manual/track_train_windows.md`: English Windows manual evidence only after the implementation and automated gates pass.

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

Specification review checks design sections 3.3, 3.5, 4, and the `TrackSystem`/`GridTrackRuntime` responsibilities. It must reject delta accumulation, failure to publish an empty path, serial reuse, fixed-origin identity drift, non-atomic mutation, or changes to resolver/train/hover behavior. Quality review then checks the reconciliation common-prefix boundary, deep copies, empty arrays, watermark advancement, invalid-candidate rollback, stale state after abort/finalize, and all direct-test migrations. Resolve findings with a fresh focused RED where behavior changes, commit only Task 2 paths, and repeat both reviews.

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

In `grid_track_runtime.gd::gesture_update`, find the most recent occurrence of the authoritative selected target in `live_path`. Build `current_suffix_cells` from cells after that index. If the target is absent from `live_path` but exactly equals the authoritative gesture press origin, treat the origin as the implicit occurrence at index `-1` and reconcile the entire `live_path` as `current_suffix_cells`. For every other absent target, use an empty suffix. Do not add an append-only, synthetic, or pointer-invalid fallback. Replace all append-only `next_suffix_input_facts` branches with `_reconcile_gesture_input_facts(_gesture_suffix_input_facts, current_suffix_cells)`.

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

Specification review checks design section 3.4 and required evidence 8-13, including actual Godot input objects, the RUNNING-state post-recovery sequence, and pre-release observation. Quality review checks most-recent target indexing, implicit-origin index `-1` handling, template changes with empty reconciliation, serial retirement, pointer-near-target behavior, suffix refund, and exact integration marker cardinality. Resolve any finding within the Task 3 allowlist through RED/GREEN and repeat both reviews.

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

- [ ] **Step 5: Obtain final independent specification and quality reviews**

Final specification review reads the approved design, this plan, every feature commit after base `1a0cd466287f81c3a413c773fd8974d5dbb72f08`, automated outputs, and manual evidence. Final quality review inspects all production and test diffs for correctness, maintainability, prototype concreteness, test validity, serial/inventory safety, lifecycle cleanup, and absence of unrelated changes. Any finding requires a focused RED/GREEN fix commit, complete regression rerun, affected manual rerun, evidence update, and both final reviews again.

- [ ] **Step 6: Report the clean reviewed feature HEAD and apply the main-first publication policy**

Require clean feature and primary worktrees, verified `main == origin/main`, and the reviewed full `FEATURE_SHA`. Under the repository's active main-first policy, push `feature/live-gesture-path-reflow`, open a pull request targeting `main`, merge with a merge commit, fast-forward the primary `main`, rerun the complete standard regression gate in `D:\godot\MoeRailWay`, and only then remove the feature worktree and local/remote feature branches. Stop and report evidence on any dirty, divergent, review, CI, merge, or primary-retest mismatch; never clear the mismatch automatically.
