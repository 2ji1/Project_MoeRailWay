# Live Gesture Template Reselection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a completed endpoint head switch among straight, left-curve, and right-curve ghost geometry from the current pointer throughout one uninterrupted left drag.

**Architecture:** Preserve `TrackFieldView` rasterization, but keep `current_pointer_cell` semantically separate from historical crossed cells when routing through `TrackSystem`. `GridTrackRuntime` selects the nearest deterministic template target from the current pointer, rebuilds a changed selection from the exact gesture origin, and retains all existing atomic validation and suffix-extension behavior.

**Tech Stack:** Godot 4.7.1, typed GDScript, the existing prototype test runner and SceneTree integration runners.

**Spec:** `docs/superpowers/specs/2026-08-27-live-gesture-template-reselection-design.md`

## Global Constraints

- Work only in `D:\godot\MoeRailWay-worktrees\feature-live-gesture-template-reselection` on `feature/live-gesture-template-reselection`; never modify the primary `main` checkout during implementation.
- Use `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`; the required version is `4.7.1.stable.official.a13da4feb`.
- Preserve the exact gesture-origin snapshot, atomic last-valid retention, fixed-prefix identity, serial monotonicity, inventory accounting, locked geometry, and train-prepared geometry.
- Do not change visual styling, add free-form curve geometry, or add a production abstraction layer.
- The only allowed task files are the two documents named by this plan plus `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`, `godot-project-moe-rail-way/src/domain/track/track_system.gd`, `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`, and `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`.
- Stage only exact allowed paths. Finish the task with one focused commit, an independent specification review, an independent quality review, and a whole-branch review.

---

### Task 1: Reselect the Head Template from the Held Pointer

**Files:**
- Create: `docs/superpowers/specs/2026-08-27-live-gesture-template-reselection-design.md`
- Create: `docs/superpowers/plans/2026-08-27-live-gesture-template-reselection.md`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- Test: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- Test: `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`

**Interfaces:**
- Consumes: `TrackInputFrame.crossed_cells`, `TrackInputFrame.current_pointer_cell`, `TrackInputFrame.current_pointer_inside_grid`, the gesture-origin snapshot, and the existing deterministic target endpoints.
- Produces: `GridTrackRuntime.gesture_update(crossed_cells: Array[Vector2i], current_pointer_cell: Vector2i = Vector2i(-1, -1)) -> bool` with current-pointer template reselection and unchanged atomic candidate publication.

- [ ] **Step 1: Add the unit RED for one uninterrupted held gesture**

Add a test named `_test_current_pointer_reselects_completed_head_template_while_held` to `test_track_system_reservation.gd` and register it in `run()`. Build the existing five-cell right-curve fixture, release that construction gesture, begin one new gesture at its endpoint, then keep `left_held == true` and `left_released == false` for all of these pointer-only frames:

```gdscript
var left_near := Vector2i(3, 1)     # nearest to left target (3, 0), not an exact target
var straight_near := Vector2i(5, 1) # nearest to straight target (5, 2), not an exact target
var right_near := Vector2i(3, 3)    # nearest to right target (3, 4), not an exact target
```

After each frame, assert the published route is respectively:

```gdscript
[
    Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
    Vector2i(3, 1), Vector2i(3, 0),
]
[
    Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
    Vector2i(4, 2), Vector2i(5, 2),
]
[
    Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
    Vector2i(3, 3), Vector2i(3, 4),
]
```

Also assert capture remains active, inventory is unchanged across equal-length replacements, and no release occurs between the three selections. The production regression this test catches is removing current-pointer reselection or treating a non-target pointer as suffix input for the latched template.

- [ ] **Step 2: Add the real-input integration RED**

In `run_track_train_input_integration.gd`, use the existing `_deliver`, `_motion`, `_consume_view`, `_logical_to_viewport`, and `_record_cells` helpers. Create and finalize the same right curve, start a new left press at its endpoint, then deliver three separate `InputEventMouseMotion` events with `MOUSE_BUTTON_MASK_LEFT` to the centers of `(3, 1)`, `(5, 1)`, and `(3, 3)`. Consume and route each frame without releasing left. Assert the route after every frame matches the three literal arrays from Step 1 and print this success marker only after all assertions pass:

```gdscript
print("PASS: Endpoint reshape integration held pointer reselects live template")
```

- [ ] **Step 3: Run RED and verify the failure is causal**

Run:

```powershell
$Godot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
& $Godot --headless --path .\godot-project-moe-rail-way --script res://tests/run_all.gd
& $Godot --headless --path .\godot-project-moe-rail-way --script res://tests/integration/run_track_train_input_integration.gd
```

Expected: both commands exit nonzero because `(3, 1)` leaves the original right-curve route published. The failure must be an assertion mismatch, not a parse error or fixture setup error.

- [ ] **Step 4: Implement minimum GREEN**

Change `GridTrackRuntime.gesture_update` to accept the optional current pointer cell. Add one private helper that calculates Manhattan distance from the pointer to each entry in `_gesture_target_endpoints`; ties retain `_gesture_selected_template_index` when possible and otherwise use straight, left, right order. When the authoritative pointer chooses a different template, clear both next input-fact buffers and rebuild from `_gesture_origin_sequence`. A reselection frame discards cells before the newly selected exact target, preserves valid cells after that target as fresh suffix input, and discards the whole frame only when the newly selected exact target is absent. When the pointer retains the same template, preserve the existing exact-target reset and suffix accumulation rules. When the pointer is invalid, preserve the existing crossed-cell fallback.

Change `TrackSystem.apply_left_input` to call the runtime with both `gesture_cells` and the authoritative pointer cell, passing `Vector2i(-1, -1)` when the pointer is outside the grid. Do not move template choice into `TrackSystem` or `TrackFieldView`.

- [ ] **Step 5: Run focused GREEN**

Run the two commands from Step 3. Expected: both exit zero; the unit runner still prints `PASS: 19 prototype test suite(s)` and the input integration prints both the new marker and `PASS: track train input integration` without `ERROR:` output.

- [ ] **Step 6: Run the complete regression gate**

Run:

```powershell
$Scripts = @(
    'res://tests/run_all.gd',
    'res://tests/integration/run_session_shell_integration.gd',
    'res://tests/integration/run_logical_track_field_integration.gd',
    'res://tests/integration/run_track_train_input_integration.gd',
    'res://tests/integration/run_track_train_app_integration.gd'
)
foreach ($Script in $Scripts) {
    & $Godot --headless --path .\godot-project-moe-rail-way --script $Script
    if ($LASTEXITCODE -ne 0) { throw "Prototype gate failed: $Script" }
}
```

Expected: all five commands exit zero with the anchored suite and integration PASS markers and no error diagnostics.

- [ ] **Step 7: Stage exact paths and commit**

Verify `git status --short` contains only the six allowed files. Stage those exact paths and commit:

```powershell
git add -- docs/superpowers/specs/2026-08-27-live-gesture-template-reselection-design.md docs/superpowers/plans/2026-08-27-live-gesture-template-reselection.md godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd godot-project-moe-rail-way/src/domain/track/track_system.gd godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd
git commit -m "fix: reselect endpoint template while dragging"
```

- [ ] **Step 8: Pass independent reviews**

Provide the task brief, report, and full base-to-head diff package to an independent specification reviewer and an independent quality reviewer. Resolve every Critical or Important finding through a reviewed fix round. Then obtain a whole-branch review covering the complete `main..HEAD` range.
