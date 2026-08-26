# Endpoint Track Reshaping Implementation Plan

**Date:** 2026-08-26

**Status:** Ready for independent specification review

**Implementation branch:** `feature/endpoint-track-reshaping`

**Verified base:** `47cbad829db0e4fac8aaf15c025189cbdd1aaef4` (`main`, `origin/main`)

**Godot baseline:** `4.7.1.stable.official.a13da4feb`

**Automated baseline:** `PASS: 19 prototype test suite(s)`

**Author:** `nvidia/nvidia-nemotron-3-ultra-550b-a55b`

---

## Preflight (Non-Mutating Verification)

All checks must pass before any implementation work begins. If any check fails, stop and report evidence.

- [ ] Primary `D:\godot\MoeRailWay` is a clean local `main` checkout (no untracked, staged, or divergent changes)
- [ ] Primary HEAD equals `47cbad829db0e4fac8aaf15c025189cbdd1aaef4`
- [ ] `origin/main` equals `47cbad829db0e4fac8aaf15c025189cbdd1aaef4`
- [ ] Feature branch is exactly `feature/endpoint-track-reshaping` descending from `0b165724fd7109997a9874bfc5d9c2db1e99aac5`
- [ ] Godot version is exactly `4.7.1.stable.official.a13da4feb`
- [ ] Baseline test command prints exactly `PASS: 19 prototype test suite(s)`

**Baseline test command:**
```powershell
D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe --headless --path "D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way" --script res://tests/run_all.gd
```

---

## Task 1: Template-Driven Mutable-Head Retirement and Gesture Primitives

### Scope
Replace the generic five-record horizon with template-driven mutable-head retirement. Add exact atomic runtime gesture `begin`/`update`/`finalize`/`abort` primitives.

### Files Allowlist
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd` (tests only)
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd` (only if resolver signature changes)

### RED: Focused Failing Tests (add to `test_grid_track_runtime.gd`)
- [ ] Five straight route records are **not** treated as a generic mutable five-record horizon
- [ ] A five-record L-shaped route still resolves as one `CURVE_3X3` with nominal length five
- [ ] A completed unlocked endpoint `CURVE_3X3` changes right-to-left, right-to-straight, and back again without changing fixed-prefix facts or inventory
- [ ] A single held gesture reshapes the head and appends post-target extension cells
- [ ] Intermediate cells between the old endpoint and selected target are control input and never become route records
- [ ] Re-entering a different target rebuilds from the gesture origin instead of composing edits
- [ ] Invalid bounds, overlap, anchor, duplicate, and inventory candidates preserve the last valid state exactly
- [ ] Left-drag plus right press restores the exact gesture-origin cells, pieces, serials, construction states, inventory, ledger, recovery, and observations
- [ ] Gesture abort consumes the right press, clears capture, and requires a fresh left press
- [ ] Locked and train-prepared geometry never changes under template selection

### GREEN: Minimum Implementation

#### `grid_track_runtime.gd` — Add gesture-origin snapshot and candidate staging
```gdscript
# New state fields
var _gesture_origin: Dictionary = null
var _last_valid_candidate: Dictionary = null
var _gesture_active := false
var _gesture_selected_target: Vector2i = Vector2i(-1, -1)
var _gesture_replacement_span: Array[int] = []  # route serials in the replacement span

# New methods
func gesture_begin(origin_endpoint: Vector2i) -> bool:
    """Capture exact gesture origin when a valid endpoint left press begins."""
    # Snapshot: route cells, inventory, geometry pieces, locked ledger, anchors,
    # recovery state, construction state, head template entry facts
    return true  # true if at least one legal operation exists

func gesture_update(pointer_cell: Vector2i, crossed_cells: Array[Vector2i]) -> void:
    """Stage one complete candidate from gesture origin.
    Rebuild: fixed prefix + selected template + valid extension after target.
    Validate and atomically publish if valid; else keep last valid candidate."""
    pass

func gesture_finalize() -> void:
    """Left release: finalize last valid candidate, discard transient gesture state."""
    pass

func gesture_abort() -> void:
    """Right press during gesture: atomically restore exact gesture origin."""
    pass

func _discover_editable_head_span() -> Dictionary:
    """Return {first_serial, last_serial, template_kind, entry_predecessor_cell, entry_heading}.
    Only geometry-unlocked records owned by the endpoint template plus incoming support."""
    pass

func _get_template_targets(entry_predecessor: Vector2i, entry_heading: Vector2i, owned_count: int) -> Dictionary:
    """Return {straight: Vector2i, left_curve: Vector2i, right_curve: Vector2i} deterministic target endpoints."""
    pass

func _retire_head_pieces_outside_span(active_end_serial: int) -> void:
    """Piece-aligned retirement: whole pieces not in endpoint template or incoming support become immutable ledger entries."""
    pass
```

#### `track_cell_sequence.gd` — Support same-length template replacement
```gdscript
# Add method to replace cells in-place preserving serials, distances, build state
func replace_span_in_place(first_serial: int, last_serial: int, new_cells: Array[Vector2i]) -> bool:
    """Replace route cells for serials [first_serial..last_serial] with new_cells (same count).
    Preserves: route_serial, route_distance_start_cells, state, build_progress, inventory charge."""
    pass
```

#### Remove generic five-record horizon enforcement
- Remove `_count_provisional_records` > 5 loop in `_stage_horizon`
- Remove `provisional_count > 5` check in `_validate_candidate`
- Replace with `_retire_head_pieces_outside_span` called on gesture finalize and train preparation

### REGRESSION: Full Automated Gate
```powershell
D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe --headless --path "D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way" --script res://tests/run_all.gd
```
Must print exactly `PASS: 19 prototype test suite(s)`

### STAGING & COMMIT
```powershell
git add godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd
git add godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd
git add godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd
# Only if resolver changed:
# git add godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd
git commit -m "feat: template-driven mutable-head retirement and gesture primitives (Task 1)"
```

### INDEPENDENT REVIEWS
- [ ] Specification review by `gpt-5.6-sol` — verify all design clauses from §2–§6 covered
- [ ] Quality review by `gpt-5.6-sol` — verify no placeholders, exact signatures, atomic transactions

---

## Task 2: TrackInputFrame Extension and TrackSystem Endpoint-Only Gesture Lifecycle

### Scope
Extend `TrackInputFrame` with exact current pointer-cell/inside-grid facts. Update `TrackSystem` for endpoint-only fresh-press gesture lifecycle, right-press abort priority, ordinary right cancellation fallback, release, and train-safety capture termination.

### Files Allowlist
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd` (tests only)
- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd` (only where needed)

### RED: Focused Failing Tests
- [ ] Fresh left press starts head gesture only at active endpoint with at least one legal operation
- [ ] Press anywhere else discards crossed-cell buffer and does not start capture
- [ ] Held button after completed/rejected/aborted capture never starts new gesture (requires release+press)
- [ ] Active-gesture right press routes to runtime abort before ordinary cancellation (consumes right edge)
- [ ] Right press when no gesture active invokes ordinary ghost-suffix cancellation
- [ ] Left release finalizes last valid candidate, clears capture
- [ ] Train preparation ending gesture clears capture; held motion ignored until fresh press

### GREEN: Minimum Implementation

#### `track_input_frame.gd` — Add pointer facts
```gdscript
class_name TrackInputFrame
extends RefCounted

var crossed_cells: Array[Vector2i]
var left_press_cell: Vector2i
var left_press_inside_grid: bool
var right_press_cell: Vector2i
var right_press_inside_grid: bool
var left_pressed: bool
var left_held: bool
var left_released: bool
var right_pressed: bool

# NEW: Exact current pointer facts for hover and gesture eligibility
var current_pointer_cell: Vector2i = Vector2i(-1, -1)
var current_pointer_inside_grid: bool = false

func _init(
    crossed_cells_value: Array[Vector2i] = [],
    left_press_cell_value: Vector2i = Vector2i(-1, -1),
    left_press_inside_grid_value: bool = false,
    right_press_cell_value: Vector2i = Vector2i(-1, -1),
    right_press_inside_grid_value: bool = false,
    left_pressed_value: bool = false,
    left_held_value: bool = false,
    left_released_value: bool = false,
    right_pressed_value: bool = false,
    current_pointer_cell_value: Vector2i = Vector2i(-1, -1),
    current_pointer_inside_grid_value: bool = false
) -> void:
    crossed_cells = crossed_cells_value.duplicate()
    left_press_cell = left_press_cell_value
    left_press_inside_grid = left_press_inside_grid_value
    right_press_cell = right_press_cell_value
    right_press_inside_grid = right_press_inside_grid_value
    left_pressed = left_pressed_value
    left_held = left_held_value
    left_released = left_released_value
    right_pressed = right_pressed_value
    current_pointer_cell = current_pointer_cell_value
    current_pointer_inside_grid = current_pointer_inside_grid_value

static func empty() -> TrackInputFrame:
    return load("res://src/domain/track/track_input_frame.gd").new()
```

#### `track_system.gd` — Enforce endpoint-only gesture start and routing
```gdscript
# Replace apply_left_input and apply_right_input with:

func apply_right_input(input_frame: TrackInputFrameScript) -> bool:
    assert(input_frame != null, "Track input frame is required")
    if not input_frame.right_pressed:
        return false
    
    # Priority 1: Active head gesture abort
    if _left_capture_active and _runtime.gesture_is_active():
        _runtime.gesture_abort()
        _left_capture_active = false
        return true  # Consumed right press
    
    # Priority 2: Ordinary right-click suffix cancellation
    _left_capture_active = false
    if input_frame.right_press_inside_grid:
        _runtime.cancel_ghost_suffix(input_frame.right_press_cell)
    return true

func apply_left_input(input_frame: TrackInputFrameScript) -> void:
    assert(input_frame != null, "Track input frame is required")
    
    # Fresh press: start gesture only from active endpoint with legal operation
    if input_frame.left_pressed:
        var can_start := (
            input_frame.left_press_inside_grid
            and input_frame.left_press_cell == _runtime.get_endpoint_cell()
            and _runtime.gesture_has_legal_operation(input_frame.left_press_cell)
        )
        _left_capture_active = can_start
        if can_start:
            _runtime.gesture_begin(input_frame.left_press_cell)
    
    # Active gesture: route cursor updates to runtime
    if _left_capture_active and _runtime.gesture_is_active():
        _runtime.gesture_update(input_frame.current_pointer_cell, input_frame.crossed_cells)
    
    # Release: finalize gesture
    if input_frame.left_released:
        if _left_capture_active and _runtime.gesture_is_active():
            _runtime.gesture_finalize()
        _left_capture_active = false
```

### REGRESSION: Full Automated Gate
Same command as Task 1. Must print exactly `PASS: 19 prototype test suite(s)`

### STAGING & COMMIT
```powershell
git add godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd
git add godot-project-moe-rail-way/src/domain/track/track_input_frame.gd
git add godot-project-moe-rail-way/src/domain/track/track_system.gd
# Only if needed:
# git add godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd
git commit -m "feat: endpoint-only gesture lifecycle and right-press abort priority (Task 2)"
```

### INDEPENDENT REVIEWS
- [ ] Specification review by `gpt-5.6-sol` — verify §4, §7, §9 input ordering
- [ ] Quality review by `gpt-5.6-sol` — verify exact frame fields, no command framework

---

## Task 3: TrackFieldView Capture and Hover Observations

### Scope
Update `TrackFieldView` capture and hover observations. Add separate `hover_extend_cell` (green) and existing `hover_cancel_cell` (gold); green wins overlap; only actionable endpoint is green; running does not suppress; complete/outside clears; pointer target motion before preset endpoint is control rather than construction.

### Files Allowlist
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd` (tests only)
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`

### RED: Focused Failing Tests
- [ ] `hover_extend_cell` (green) appears on active endpoint when fresh left gesture may legally begin
- [ ] `hover_cancel_cell` (gold) appears on cell whose clicked-to-end suffix is eligible for ordinary right-click cancellation
- [ ] When both observations identify the same endpoint, green has visual priority
- [ ] Right-click eligibility still exists when green wins (color priority ≠ input behavior)
- [ ] No green hover on arbitrary empty, built, locked, train-occupied, or non-endpoint route cells
- [ ] Running train does not suppress endpoint hover
- [ ] Both hover observations clear when pointer is outside grid or session is complete
- [ ] Locked endpoint may still be green when it has a legal adjacent extension
- [ ] Endpoint with neither editable template nor legal inventory-funded adjacent extension is not green
- [ ] Pointer target motion before preset endpoint is control input, not construction

### GREEN: Minimum Implementation

#### `track_field_view.gd` — Add hover_extend_cell and update render observation
```gdscript
# Add new field
var _hover_extend_cell := INVALID_CELL

# Update get_render_observation():
func get_render_observation() -> Dictionary:
    # ... existing fields ...
    return {
        # ... existing ...
        "hover_extend_cell": Vector2i(_hover_extend_cell),
        "hover_cancel_cell": Vector2i(_hover_cancel_cell),
    }

# Update _update_hover_cell():
func _update_hover_cell(local_position: Vector2) -> void:
    if _presented_state == SessionControllerScript.State.COMPLETED:
        _clear_hover_cells()
        return
    var mapping := _map_local_to_grid(local_position)
    if not mapping.inside_grid:
        _clear_hover_cells()
        return
    
    var extend_cell := _get_gesture_start_endpoint()
    var cancel_cell := _get_cancelable_hover_cell(mapping.cell)
    
    var extend_changed := _hover_extend_cell != extend_cell
    var cancel_changed := _hover_cancel_cell != cancel_cell
    
    _hover_extend_cell = extend_cell
    _hover_cancel_cell = cancel_cell
    
    if extend_changed or cancel_changed:
        queue_redraw()

func _get_gesture_start_endpoint() -> Vector2i:
    """Return active endpoint if a fresh left gesture may legally begin there."""
    if _presented_state == SessionControllerScript.State.COMPLETED:
        return INVALID_CELL
    var endpoint := _get_valid_start_cell()
    if endpoint == INVALID_CELL:
        return INVALID_CELL
    # Check: at least one legal template replacement OR legal adjacent extension with inventory
    if _has_editable_template_at(endpoint) or _has_legal_adjacent_extension(endpoint):
        return endpoint
    return INVALID_CELL

func _get_cancelable_hover_cell(pointer_cell: Vector2i) -> Vector2i:
    """Return pointer cell if its clicked-to-end suffix is cancelable."""
    if not _is_cancelable_cell(pointer_cell):
        return INVALID_CELL
    return pointer_cell

func _clear_hover_cells() -> void:
    var changed := false
    if _hover_extend_cell != INVALID_CELL:
        _hover_extend_cell = INVALID_CELL
        changed = true
    if _hover_cancel_cell != INVALID_CELL:
        _hover_cancel_cell = INVALID_CELL
        changed = true
    if changed:
        queue_redraw()

# Update _draw() to render green hover_extend_cell with priority over gold hover_cancel_cell
func _draw() -> void:
    # ... existing draw code ...
    
    # Draw hover_cancel_cell (gold) first
    if _hover_cancel_cell != INVALID_CELL and _grid_size.x > 0 and _grid_size.y > 0:
        var cell_size := Vector2(
            _grid_rect.size.x / float(_grid_size.x),
            _grid_rect.size.y / float(_grid_size.y)
        )
        var hover_rect := Rect2(_grid_rect.position + Vector2(_hover_cancel_cell) * cell_size, cell_size)
        draw_rect(hover_rect, HOVER_COLOR, false, 3.0, true)
    
    # Draw hover_extend_cell (green) on top — wins visual priority
    if _hover_extend_cell != INVALID_CELL and _grid_size.x > 0 and _grid_size.y > 0:
        var cell_size := Vector2(
            _grid_rect.size.x / float(_grid_size.x),
            _grid_rect.size.y / float(_grid_size.y)
        )
        var extend_rect := Rect2(_grid_rect.position + Vector2(_hover_extend_cell) * cell_size, cell_size)
        var EXTEND_HOVER_COLOR := Color(0.2, 0.85, 0.3, 0.72)  # Green
        draw_rect(extend_rect, EXTEND_HOVER_COLOR, false, 3.0, true)
    
    # ... rest of draw ...
```

### REGRESSION: Full Automated Gate
Same command. Must print exactly `PASS: 19 prototype test suite(s)`

### STAGING & COMMIT
```powershell
git add godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd
git add godot-project-moe-rail-way/src/presentation/track/track_field_view.gd
git commit -m "feat: dual hover observations with green extend priority (Task 3)"
```

### INDEPENDENT REVIEWS
- [ ] Specification review by `gpt-5.6-sol` — verify §8 hover contract
- [ ] Quality review by `gpt-5.6-sol` — verify green/gold rendering, no geometry decisions in view

---

## Task 4: Tick Ordering and Train-Preparation Safety Integration

### Scope
Integrate tick ordering and train-preparation safety through `SessionController` and the existing runtime/system bridge. Prove gesture abort precedes preparation, preparation freezes overlapping last-valid geometry, held motion cannot mutate afterward, and regressions remain green.

### Files Allowlist
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd` (tests only)
- `godot-project-moe-rail-way/tests/unit/test_train_system.gd` (only where needed)
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd` (only where needed)
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`

### RED: Focused Failing Tests
- [ ] Gesture abort (right press) precedes preparation in same tick
- [ ] Preparation freezes overlapping last-valid candidate geometry before sampling
- [ ] Held motion after preparation cannot mutate geometry
- [ ] Abort restores gesture origin; preparation then operates on restored route
- [ ] Running-state endpoint hover remains green when gesture can start
- [ ] Full tick ordering: right abort → ordinary right cancel → fresh left gesture → gesture candidate → left release → construction advance → train prepare → train advance/sample → recovery → snapshot

### GREEN: Minimum Implementation

#### `session_controller.gd` — Enforce authoritative tick ordering (§9)
```gdscript
func advance_tick(input_frame: TrackInputFrameScript = null) -> void:
    if _state == State.READY or _state == State.COMPLETED:
        return
    var frame: TrackInputFrameScript = (
        input_frame if input_frame != null else TrackInputFrameScript.empty()
    )
    
    # 1. Right press + active head gesture → abort gesture, consume right press
    var right_consumed := false
    if frame.right_pressed and _track_system.left_capture_active() and _track_system.runtime_gesture_is_active():
        _track_system.runtime_gesture_abort()
        _track_system.set_left_capture_active(false)
        right_consumed = true
    
    # 2. Otherwise ordinary right-click suffix cancellation
    if not right_consumed:
        var right_won := _track_system.apply_right_input(frame)
        # apply_right_input handles the rest
    
    # 3. Fresh left gesture only from active endpoint (handled in TrackSystem.apply_left_input)
    _track_system.apply_left_input(frame)
    
    # 4. Gesture candidate staging already applied in apply_left_input
    
    # 5. Left release finalizes in TrackSystem
    
    # 6. Advance ordinary construction
    _track_system.advance_construction(_construction_cells_per_tick)
    
    # 7. Prepare geometry for train sampling, ending overlapping active gesture before locking
    var track_end_requested := false
    if _state == State.PREPARING_DEPARTURE:
        if _track_system.get_built_end_distance_cells() + DISTANCE_EPSILON >= float(_start_config.departure_required_built_cells):
            var departure_through := minf(
                _start_config.train_speed_cells_per_second * _seconds_per_tick,
                _track_system.get_built_end_distance_cells()
            )
            # Preparation will end overlapping gesture internally
            if not _prepare_or_abort(0.0, departure_through):
                return
            _train_system.depart(0.0)
            _train_system.capture_pose(_track_system)
            _state = State.RUNNING
            track_end_requested = _train_system.advance_tick(_track_system, _seconds_per_tick)
            _cached_tick_pose = _train_system.capture_pose(_track_system)
    elif _state == State.RUNNING:
        var current_distance := _train_system.get_route_distance_cells()
        var through_distance := minf(
            current_distance + _start_config.train_speed_cells_per_second * _seconds_per_tick,
            _track_system.get_built_end_distance_cells()
        )
        # Preparation will end overlapping gesture internally
        if not _prepare_or_abort(current_distance, through_distance):
            return
        track_end_requested = _train_system.advance_tick(_track_system, _seconds_per_tick)
        _cached_tick_pose = _train_system.capture_pose(_track_system)
    
    # 8. Recovery and snapshot
    if _state == State.RUNNING:
        _track_system.recover_behind(
            _train_system.get_route_distance_cells() - float(_start_config.recovery_lag_cells)
        )
        _elapsed_ticks = mini(_total_ticks, _elapsed_ticks + 1)
        _remaining_ticks = _total_ticks - _elapsed_ticks
        if _remaining_ticks == 0:
            _complete(SessionResultScript.Reason.REGULAR_TIME_EXPIRED)
        elif track_end_requested:
            _complete(SessionResultScript.Reason.TRACK_END_REACHED)
        else:
            _publish_snapshot()
```

#### `grid_track_runtime.gd` — Train preparation ends overlapping gesture
```gdscript
func prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool:
    # If active gesture overlaps preparation range, preserve last valid candidate, end gesture, then prepare
    if _gesture_active and _gesture_overlaps_preparation(current_distance, through_distance):
        if _last_valid_candidate != null:
            _restore_last_valid_candidate()
        _gesture_active = false
        _gesture_origin = null
        # Gesture ended; continue with normal preparation
    # ... existing preparation logic ...
```

### REGRESSION: Full Automated Gate
Same command. Must print exactly `PASS: 19 prototype test suite(s)`

### STAGING & COMMIT
```powershell
git add godot-project-moe-rail-way/tests/unit/test_session_controller.gd
git add godot-project-moe-rail-way/src/domain/session/session_controller.gd
# Only if needed:
# git add godot-project-moe-rail-way/tests/unit/test_train_system.gd
# git add godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd
git commit -m "feat: tick ordering and train-preparation safety integration (Task 4)"
```

### INDEPENDENT REVIEWS
- [ ] Specification review by `gpt-5.6-sol` — verify §5.4, §9 tick ordering
- [ ] Quality review by `gpt-5.6-sol` — verify no double-consumption of right press

---

## Task 5: Full Gates, Manual Scenario, Evidence, Reviews, Clean Feature HEAD

### Scope
Run full automated and standalone integration gates. Execute approved Windows Godot manual scenario. Append English evidence only to `tests/manual/track_train_windows.md`. Obtain final independent spec/code/quality reviews. Report clean feature HEAD. No merge, push, PR, tag, or cleanup without separate authorization.

### Files Allowlist
- `godot-project-moe-rail-way/tests/manual/track_train_windows.md` (append evidence only)
- No production code changes

### AUTOMATED GATES
```powershell
# Full suite
D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe --headless --path "D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way" --script res://tests/run_all.gd

# Standalone integration
D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe --headless --path "D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way" --script res://tests/integration/run_track_train_input_integration.gd
```
Both must print `PASS` with exit code 0.

### MANUAL SCENARIO (Windows, Godot 4.7.1.stable.official.a13da4feb)
Perform and record each step in English under `tests/manual/track_train_windows.md`:

1. [ ] Build a straight approach and form a completed unlocked right-turn `3x3` curve at the route endpoint
2. [ ] Press the endpoint and drag to the left-turn target; observe immediate solid left-curve replacement
3. [ ] Without releasing, enter the straight target and continue beyond it; observe immediate straight replacement followed by continuous extension
4. [ ] Repeat the gesture, change the head, append cells, and right-click while still holding left; observe exact restoration to the pre-gesture route and inventory
5. [ ] Start the train and verify that an actionable endpoint retains green hover while the train is running
6. [ ] Verify that ordinary cancelable non-endpoint ghost cells retain the existing gold hover
7. [ ] Verify that an endpoint satisfying both extend and cancel eligibility renders green and that right-click still performs the eligible action
8. [ ] Allow the train to approach the edited span; verify that geometry freezes before sampling and cannot be moved by continued held motion

**Evidence format (append to `tests/manual/track_train_windows.md`):**
```markdown
## Task 5 endpoint-track-reshaping evidence — 2026-08-26

**Durable tested implementation SHA:** `<feature branch HEAD>`
**Godot:** `4.7.1.stable.official.a13da4feb`

### Direct observations
- Step 1: ...
- Step 2: ...
...
```

### FINAL INDEPENDENT REVIEWS
- [ ] Specification review by `gpt-5.6-sol` — full design coverage (§1–§12)
- [ ] Code review by `gpt-5.6-sol` — no placeholders, exact signatures, allowlists respected, `git diff --check` clean
- [ ] Quality review by `gpt-5.6-sol` — atomic transactions, conservation invariants, detached observations

### REPORT
- [ ] Feature HEAD SHA: `<commit-sha>`
- [ ] Path: `D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping`
- [ ] Task count: 5
- [ ] Self-review: PASS/FAIL with concerns
- [ ] Concerns: (list any)

---

## Self-Review Checklist (Complete Before Final Report)

### Spec Coverage
- [ ] All §2–§6 design clauses implemented (curve meaning, terminology, gesture contract, mutability, record identity)
- [ ] All §7 right-click abort behavior implemented
- [ ] All §8 hover contract implemented (dual observations, green priority, running not suppressed, complete/outside clears)
- [ ] All §9 tick ordering implemented (right abort → ordinary cancel → fresh left → gesture → release → construction → prepare → train → recovery)
- [ ] All §10 component responsibilities respected
- [ ] All §11 automated evidence items have RED tests
- [ ] All §12 manual acceptance steps testable

### Placeholders
- [ ] No `TODO`, `FIXME`, `XXX`, `...`, `pass`, or incomplete implementations
- [ ] All method signatures exact, no `Variant` where concrete type known
- [ ] All constants named, no magic numbers

### Cross-Task Interface Consistency
- [ ] `TrackInputFrame.current_pointer_cell` / `current_pointer_inside_grid` used consistently by Task 2, 3
- [ ] `GridTrackRuntime.gesture_begin/update/finalize/abort` called correctly by Task 2, 4
- [ ] `TrackFieldView._hover_extend_cell` / `_hover_cancel_cell` rendered correctly by Task 3
- [ ] `SessionController` tick ordering matches §9 exactly

### Allowlists
- [ ] Each task touches only its declared files
- [ ] No modifications to `TrackGeometryResolver` unless signature change required
- [ ] No modifications to `TrackCellRecord`, `TrackGeometryPiece`, `SessionStartConfig`, `SessionSnapshot`, `SessionResult`, `TrainSystem`, `LogicalTrackField`, `GridPointerRasterizer`, `RouteContactAnchor`

### Git Hygiene
- [ ] `git diff --check` passes (no whitespace errors)
- [ ] Each task staged with exact paths only
- [ ] Each task committed with focused message

---

## Concerns (if any)
- None identified at plan time. Record any discovered during implementation.
