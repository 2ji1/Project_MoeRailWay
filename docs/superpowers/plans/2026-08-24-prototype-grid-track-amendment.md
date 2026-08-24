# Prototype Grid Track Amendment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver `prototype-m4` by replacing `prototype-m3` freeform track drawing with endpoint-only grid-cell reservation, deterministic curve fitting, per-cell construction and recovery, and continuous nominal-distance train movement.

**Architecture:** Preserve `PrototypeApp`, fixed-tick `SessionController`, seeded departure selection, detached snapshots, and the existing logical-field presentation boundary. Introduce focused cell-sequence and geometry-resolver domain units, then migrate `TrackSystem` and `TrainSystem` from continuous polyline accounting to exact integer cell ownership while retaining continuous centerline sampling for train presentation.

**Tech Stack:** Godot `4.7.1.stable.official.a13da4feb`, GDScript, Godot Resource and scene files, existing native `SceneTree` test harness, PowerShell, Git

**Spec:** `docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md`

## Global Constraints

- Immutable code baseline is local `Prototyping` commit `67518fc8dc4c106dfc6e20f901bcb2ef832efcb5`, accepted tag `prototype-m3`.
- Implementation starts from one reviewed documentation-adoption commit supplied as `MOERAIL_GRID_DOCS_SHA`. It must be the direct child of the immutable code baseline and change exactly the eleven documentation paths listed in the preflight.
- Implement on `proto/03-grid-track-amendment` in an isolated worktree. Never implement in the primary worktree.
- Never branch from `main` or `Development`, and never merge `Prototyping` wholesale into `Development`.
- Branch creation, implementation, commit, integration, tag, push, PR, and cleanup remain separate gates. This document update authorizes none of them by itself.
- Preserve all primary-worktree user changes. Do not stage, format, reset, copy, or absorb them.
- Target Windows PC, mouse-only input, the existing `1280x720` logical viewport, and supported 16:9 windows from `960x540` through `1920x1080`.
- Use `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe` and require version `4.7.1.stable.official.a13da4feb`.
- Run Godot with normal access to `user://logs`. A logging-denial signal 11 is an environment failure, not a project regression.
- Do not terminate, reconfigure, or reuse a user-owned Godot or Steam editor process.
- Preserve the accepted 14-suite `prototype-m3` behavior until the task that explicitly replaces each route contract.
- Use fixed ticks as domain truth. Do not use `Timer`, `_process(delta)`, wall-clock APIs, variable delta, physics bodies, or callback order.
- Preserve the selected departure-candidate RNG rule and the one-shot session completion order.
- Use one ordered nonbranching route, one train, one endpoint, no pathfinding, no branches, no merges, and no reversing.
- Inventory ownership uses integer cells. Every unique accepted route cell costs one exactly once; every canceled or recovered cell refunds one exactly once.
- Curve sizes own exactly `1`, `3`, and `5` route cells for `1x1`, `2x2`, and `3x3` pieces. Geometry reclassification has no inventory surcharge.
- Unlocked ghost geometry may reflow. A piece locks when construction starts on its first cell and never changes afterward.
- Only `BUILT` cells are traversable. `BUILDING` remains blocked until progress reaches `1.0`.
- Train speed and route time use nominal cells per second. A five-cell curve takes the same time as five straight cells.
- Runtime warp generation and cargo remain out of scope. This branch supplies the route-contact anchor contract only and never rerolls or corrects supplied anchor cells.
- Paid demolition, crossings, cash mutation, hazards, durability, contracts, credit, fleet, train purchases, and office upgrades remain out of scope.
- Add no third-party add-ons, test frameworks, custom art, custom fonts, or final audio.
- Every new tracked `.gd` file has exactly one matching `.gd.uid` sidecar.
- Use explicit `preload` dependencies so a fresh tree does not depend on an existing global class cache.
- Agent-facing Markdown is English. Korean user-review documents stay under `docs/briefings/ko` and name the English plan and spec as canonical.
- Each task ends with RED evidence, minimal GREEN implementation, full headless regression, one focused commit, specification review, and separate quality review.

## Approved Defaults

| Owner | Field | Default | Validation |
|---|---|---:|---|
| `LogicalTrackField` | `grid_cell_size_units` | `40.0` | `> 0.0` |
| `LogicalTrackField` | `COMPACT` grid | `22 x 10` | fits `900 x 420` |
| `LogicalTrackField` | `STANDARD` grid | `30 x 14` | fits `1200 x 560` |
| `LogicalTrackField` | `EXPANSIVE` grid | `36 x 16` | fits `1500 x 700` |
| `LogicalTrackField` | `CUSTOM` initial grid | `30 x 14` | positive integers fitting the custom field |
| `SessionStartConfig` | centered grid origin | `COMPACT (10, 10)`, `STANDARD (0, 0)`, `EXPANSIVE (30, 30)` | derived once and shared by input, geometry, and rendering |
| `TrackInventoryBalance` | `total_track_cells` | `18` | `> 0` |
| `TrackInventoryBalance` | `recovery_lag_cells` | `6` | `>= 0` and `< total_track_cells` |
| `TrackInventoryBalance` | `urgent_warning_seconds` | `3.0` | `> 0.0` |
| `TrackConstructionBalance` | `build_cells_per_second` | `3.0` | `> 0.0` |
| `TrainBalance` | `speed_cells_per_second` | `1.5` | `> 0.0` |
| `DepartureBalance` | `required_built_cells` | `9` | `1..total_track_cells` |

The values preserve the accepted `prototype-m3` time ratios with a `40.0`-unit cell. They are prototype tuning values; integer ownership and nominal-distance meanings are invariants.

## Supersession and Deletion Ledger

This ledger is part of the executable plan. An implementer must not restore a deleted contract merely because it remains visible in the historical `prototype-m3` plan or tag.

### Historical material retained, not re-executed

- `docs/superpowers/plans/2026-08-16-prototype-track-train.md` remains the evidence record for delivered `prototype-m3`; its Tasks 1-9 and amendment gates are not a second active plan.
- Seeded departure-candidate selection, logical viewport mapping, GUI event buffering principles, fixed-tick session lifecycle, editor-mirror safety, detached snapshots, and one-shot result ordering are reused from `prototype-m3` and are not replanned from zero.

### Active contracts removed or replaced

- Removed continuous `PackedVector2Array` route ownership and absolute Euclidean-length inventory from active authority; replaced by ordered unique `Vector2i` cells and exact integer conservation.
- Removed arbitrary sampled freehand segments, diagonal shortcuts, endpoint-radius sampling, field-edge segment clipping, intersection clearance, and projection tie rules; replaced by buffered crossed-cell order, orthogonal adjacency, grid bounds, unique-cell rejection, and footprint resolution.
- Removed `total_units`, `recovery_distance_units`, `speed_units_per_second`, `required_built_units`, `endpoint_grab_radius_units`, `route_hit_radius_units`, `minimum_sample_distance_units`, and `intersection_clearance_units` after the final migration task.
- Removed partial-segment construction and partial-segment rear recovery; replaced by per-cell build progress, atomic `BUILT` transition, and one-cell refund events.
- Removed raw polyline rendering as route authority; replaced by detached cell and resolved-piece observations. Primitive polylines remain only as a renderer for deterministic piece centerlines.
- Removed the historical blanket ban on warp-owned paths from route validation. This plan adds only generic contact anchors; `proto/04-warp-cargo` owns warp runtime files.
- Removed detailed paid-demolition geometry from the historical track design's active future authority. `proto/05-risk-investment` must define cell-based paid actions in its own specification.
- Replaced the gameplay specification's active freeform-length track subsection with the approved grid-cell summary and removed its continuous-position paid-demolition rule; the future Risk Investment specification now owns that detail.

### Downstream duplicate work deleted from the strategy

- Inserted `proto/03-grid-track-amendment` and shifted Warp Cargo through Playtest Ready to `proto/04` through `proto/08`.
- Deleted any implication that Warp Cargo may choose, correct, or regenerate route geometry. It generates random cells and consumes `RouteContactAnchor` only.
- Deleted any implication that Risk Investment may redefine base cell ownership, curve fitting, construction, train sampling, or free recovery. It may only add paid actions and hazards over these contracts.
- No detailed `proto/03+` implementation-plan file existed on the audited `prototype-m3` baseline, so no downstream plan file was deleted. This ledger records the strategy-scope deletions that actually occurred.

### Existing test behavior removed during migration

- Rewrite `tests/unit/test_track_system_reservation.gd`; remove assertions for raw distance, diagonal sampling, float clipping, projection epsilon ties, and continuous intersection clearance.
- Rewrite `tests/unit/test_track_system_construction_recovery.gd`; remove float32 recovery exceptions, interpolated cut points, and partial scalar refunds.
- Rewrite `tests/unit/test_train_system.gd`; remove dependence on arbitrary sampled vertices while preserving inactive, continuous-position, heading, and built-end behavior.
- Rewrite grid-sensitive portions of `tests/unit/test_track_train_session_controller.gd`, `tests/unit/test_track_field_view_input.gd`, `tests/integration/run_track_train_input_integration.gd`, `tests/integration/run_track_train_app_integration.gd`, and `tests/smoke/test_track_train_app_composition.gd`.
- Preserve non-route assertions in those files: dependency copying, resize mapping, fixed-tick ordering, result priority, post-completion inertness, and deterministic departure selection.

## Development Session Preflight

- [ ] **Step 1: Verify the reviewed documentation-adoption base and protect the primary workspace**

Run from `D:\godot\MoeRailWay`:

```powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailCodeBase = '67518fc8dc4c106dfc6e20f901bcb2ef832efcb5'
$MoeRailDocsSha = $env:MOERAIL_GRID_DOCS_SHA
if ($MoeRailDocsSha -notmatch '^[0-9a-fA-F]{40}$') {
    throw 'MOERAIL_GRID_DOCS_SHA must be the reviewed full documentation commit SHA.'
}
$MoeRailDocsSha = (git -C $MoeRailPrimary rev-parse $MoeRailDocsSha).Trim()
$MoeRailActualBase = (git -C $MoeRailPrimary rev-parse Prototyping).Trim()
if ($MoeRailActualBase -ne $MoeRailDocsSha) {
    throw "Prototyping does not equal reviewed docs commit: $MoeRailActualBase"
}
$MoeRailDocsParent = (git -C $MoeRailPrimary rev-parse "$MoeRailDocsSha^").Trim()
if ($MoeRailDocsParent -ne $MoeRailCodeBase) {
    throw "Docs commit is not the direct child of prototype-m3: $MoeRailDocsParent"
}
$MoeRailExpectedDocs = @(
    'docs/briefings/ko/2026-08-15-prototype-development-strategy-briefing.md',
    'docs/briefings/ko/2026-08-15-warp-rail-prototype-design.md',
    'docs/briefings/ko/2026-08-16-prototype-track-train-design-briefing.md',
    'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md',
    'docs/briefings/ko/2026-08-24-prototype-grid-track-amendment-plan-briefing.md',
    'docs/superpowers/plans/2026-08-16-prototype-track-train.md',
    'docs/superpowers/plans/2026-08-24-prototype-grid-track-amendment.md',
    'docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md',
    'docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md',
    'docs/superpowers/specs/2026-08-16-prototype-track-train-design.md',
    'docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md'
) | Sort-Object
$MoeRailActualDocs = @(
    git -C $MoeRailPrimary diff --name-only $MoeRailCodeBase $MoeRailDocsSha
) | Sort-Object
if (Compare-Object $MoeRailExpectedDocs $MoeRailActualDocs) {
    throw 'Reviewed documentation commit has an unexpected path set.'
}
git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all
git -C $MoeRailPrimary diff --check
```

Expected: `Prototyping` equals the reviewed documentation commit, that commit is a one-commit documentation-only child of accepted `prototype-m3`, and its path set equals the eleven-file allowlist. Record the status output in the ignored task ledger. Do not modify any displayed primary path. If the primary state is neither clean nor identical to the user-reviewed planning snapshot, stop for user review.

- [ ] **Step 2: Create the isolated feature worktree**

```powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment'
$MoeRailBranch = 'proto/03-grid-track-amendment'
$MoeRailDocsSha = $env:MOERAIL_GRID_DOCS_SHA
if (Test-Path -LiteralPath $MoeRailFeature) {
    throw "Feature worktree already exists: $MoeRailFeature"
}
if (git -C $MoeRailPrimary branch --list $MoeRailBranch) {
    throw "Feature branch already exists: $MoeRailBranch"
}
git -C $MoeRailPrimary worktree add $MoeRailFeature -b $MoeRailBranch $MoeRailDocsSha
git -C $MoeRailFeature status --short --branch
```

Expected: clean `proto/03-grid-track-amendment` at the reviewed documentation-adoption commit whose parent is `67518fc8...`.

- [ ] **Step 3: Run the accepted baseline suite**

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment\godot-project-moe-rail-way'
& $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd
if ($LASTEXITCODE -ne 0) { throw "Baseline failed: $LASTEXITCODE" }
```

Expected: `PASS: 14 prototype test suite(s)` and exit `0`. A failure stops implementation.

## Target File Map

### Create

- `godot-project-moe-rail-way/src/domain/track/track_cell_record.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_record.gd.uid`
- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd.uid`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd.uid`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd.uid`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolution.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolution.gd.uid`
- `godot-project-moe-rail-way/src/domain/track/route_contact_anchor.gd`
- `godot-project-moe-rail-way/src/domain/track/route_contact_anchor.gd.uid`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd.uid`
- `godot-project-moe-rail-way/src/domain/train/nominal_train_motion.gd`
- `godot-project-moe-rail-way/src/domain/train/nominal_train_motion.gd.uid`
- `godot-project-moe-rail-way/src/presentation/track/grid_pointer_rasterizer.gd`
- `godot-project-moe-rail-way/src/presentation/track/grid_pointer_rasterizer.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd`
- `godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_grid_pointer_rasterizer.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_pointer_rasterizer.gd.uid`

### Modify

- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/data/track_inventory_balance.tres`
- `godot-project-moe-rail-way/data/track_construction_balance.tres`
- `godot-project-moe-rail-way/data/train_balance.tres`
- `godot-project-moe-rail-way/data/departure_balance.tres`
- `godot-project-moe-rail-way/src/config/track_inventory_balance.gd`
- `godot-project-moe-rail-way/src/config/track_construction_balance.gd`
- `godot-project-moe-rail-way/src/config/train_balance.gd`
- `godot-project-moe-rail-way/src/config/departure_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/domain/train/train_system.gd`
- `godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd`
- `godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/fixtures/invalid_track_train_balance.tres`
- `godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_departure_selection.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_train_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
- `godot-project-moe-rail-way/tests/unit/test_train_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- `godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd`
- `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`
- `godot-project-moe-rail-way/tests/manual/track_train_windows.md`

### Explicitly unchanged

- `godot-project-moe-rail-way/src/domain/random/session_rng.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd`
- `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd`
- `godot-project-moe-rail-way/tests/support/prototype_test.gd`
- all files under future warp, cargo, risk, economy, contract, credit, fleet, and office ownership

Any required path outside this map stops the task for plan amendment and user review.

## Public Interfaces

Cross-script types use explicit preloads.

Final `SessionStartConfig` grid surface after Task 8:

```gdscript
var seed: int
var session_duration_seconds: float
var simulation_ticks_per_second: int
var train_speed_cells_per_second: float
var total_track_cells: int
var recovery_lag_cells: int
var urgent_warning_seconds: float
var build_cells_per_second: float
var departure_required_built_cells: int
var logical_field_size: Vector2
var grid_size: Vector2i
var grid_cell_size_units: float
var grid_origin_units: Vector2
var departure_candidate_id: StringName
var departure_position: Vector2
var departure_cell: Vector2i

func _init(
    seed_value: int,
    duration_seconds: float,
    ticks_per_second: int,
    train_speed_cells_value: float = 0.0,
    total_track_cells_value: int = 0,
    recovery_lag_cells_value: int = 0,
    urgent_warning_value: float = 0.0,
    build_cells_value: float = 0.0,
    departure_required_cells_value: int = 0,
    logical_field_size_value: Vector2 = Vector2.ZERO,
    grid_size_value: Vector2i = Vector2i.ZERO,
    grid_cell_size_value: float = 0.0,
    grid_origin_value: Vector2 = Vector2.ZERO,
    departure_candidate_id_value: StringName = StringName(),
    departure_position_value: Vector2 = Vector2.ZERO,
    departure_cell_value: Vector2i = Vector2i(-1, -1)
) -> void
```

The first three parameters remain source-compatible with foundation and session-shell callers.

`TrackCellRecord`:

```gdscript
class_name TrackCellRecord
extends RefCounted

enum State { RESERVED_GHOST, BUILDING, BUILT }

var route_serial: int
var cell: Vector2i
var route_distance_start_cells: float
var state: State
var build_progress: float
var geometry_group_id: int
var geometry_locked: bool

func duplicate_record() -> TrackCellRecord
```

`TrackCellSequence`:

```gdscript
class_name TrackCellSequence
extends RefCounted

func _init(departure_cell: Vector2i, total_track_cells: int) -> void
func try_append_candidate(cell: Vector2i) -> Variant
func rollback_last_unlocked_ghost(expected_route_serial: int) -> void
func append_candidates(cells: Array[Vector2i]) -> int
func cancel_ghost_suffix(cell: Vector2i) -> int
func apply_resolved_geometry(pieces: Array[TrackGeometryPiece]) -> void
func start_building(route_serial: int) -> void
func add_build_progress(amount: float) -> float
func complete_building() -> void
func recover_eligible_cells(cutoff_distance_cells: float) -> Array[TrackCellRecord]
func get_departure_cell() -> Vector2i
func get_endpoint_cell() -> Vector2i
func get_records() -> Array[TrackCellRecord]
func get_available_track_cells() -> int
func get_total_track_cells() -> int
func is_conservation_valid() -> bool
```

`RouteContactAnchor`:

```gdscript
class_name RouteContactAnchor
extends RefCounted

var anchor_id: StringName
var cell: Vector2i

func _init(id: StringName, grid_cell: Vector2i) -> void
func duplicate_anchor() -> RouteContactAnchor
```

`TrackGeometryPiece`:

```gdscript
class_name TrackGeometryPiece
extends RefCounted

enum Kind { STRAIGHT, CURVE_1X1, CURVE_2X2, CURVE_3X3 }

var group_id: int
var kind: Kind
var first_route_serial: int
var last_route_serial: int
var nominal_length_cells: int
var absolute_start_distance_cells: float
var footprint_cells: Array[Vector2i]
var centerline: PackedVector2Array
var locked: bool
var active_local_start_cells: float
var active_local_end_cells: float

func contains_serial(route_serial: int) -> bool
func contacts_cell(
    cell: Vector2i,
    grid_origin_units: Vector2,
    cell_size_units: float
) -> bool
func sample_nominal(local_distance_cells: float) -> Dictionary
func duplicate_active_slice(
    local_start_cells: float,
    local_end_cells: float
) -> TrackGeometryPiece
func duplicate_piece() -> TrackGeometryPiece
```

`TrackGeometryResolver`:

```gdscript
class_name TrackGeometryResolver
extends RefCounted

func resolve(
    departure_cell: Vector2i,
    records: Array[TrackCellRecord],
    locked_pieces: Array[TrackGeometryPiece],
    anchors: Array[RouteContactAnchor],
    grid_origin_units: Vector2,
    grid_size: Vector2i,
    cell_size_units: float
) -> TrackGeometryResolution
```

`TrackGeometryResolution`:

```gdscript
class_name TrackGeometryResolution
extends RefCounted

var is_valid: bool
var pieces: Array[TrackGeometryPiece]
var rejected_route_serial: int
var reason: StringName

static func accepted(value: Array[TrackGeometryPiece]) -> TrackGeometryResolution
static func rejected(route_serial: int, reason_value: StringName) -> TrackGeometryResolution
func duplicate_resolution() -> TrackGeometryResolution
```

`GridTrackRuntime` is the concrete grid-route core. It owns `TrackCellSequence`, `TrackGeometryResolver`, unlocked pieces, the persistent locked-piece ledger, anchors, construction progress, and centerline sampling:

```gdscript
func _init(
    departure_cell: Vector2i,
    total_track_cells: int,
    grid_origin_units: Vector2,
    grid_size: Vector2i,
    cell_size_units: float
) -> void
func append_cells(cells: Array[Vector2i]) -> int
func cancel_ghost_suffix(cell: Vector2i) -> bool
func set_contact_anchors(anchors: Array[RouteContactAnchor]) -> void
func advance_construction(progress_cells: float) -> float
func recover_behind(cutoff_distance_cells: float) -> int
func get_endpoint_cell() -> Vector2i
func get_cell_records() -> Array[TrackCellRecord]
func get_geometry_pieces() -> Array[TrackGeometryPiece]
func get_built_end_distance_cells() -> float
func get_reserved_end_distance_cells() -> float
func get_available_track_cells() -> int
func get_total_track_cells() -> int
func get_grid_origin_units() -> Vector2
func get_position_at_distance_cells(route_distance_cells: float) -> Vector2
func get_heading_at_distance_cells(route_distance_cells: float) -> Vector2
func get_contact_observations() -> Array[Dictionary]
```

After Task 7, `TrackSystem` is a compatibility facade that validates `SessionStartConfig`, translates `TrackInputFrame`, and delegates to this runtime.

`NominalTrainMotion`:

```gdscript
class_name NominalTrainMotion
extends RefCounted

func _init(speed_cells_per_second: float) -> void
func depart(route_distance_cells: float = 0.0) -> void
func advance(built_end_distance_cells: float, seconds_per_tick: float) -> bool
func is_active() -> bool
func get_route_distance_cells() -> float
```

`GridPointerRasterizer`:

```gdscript
class_name GridPointerRasterizer
extends RefCounted

func rasterize_motion(
    from_logical: Vector2,
    to_logical: Vector2,
    grid_rect: Rect2,
    grid_size: Vector2i,
    previous_cell: Vector2i
) -> Array[Vector2i]
```

The rasterizer returns only newly crossed in-bounds cells after `previous_cell`, in physical crossing order. A simultaneous corner crossing uses the motion segment's dominant axis, then horizontal-first for an exact tie.

`TrackSystem` remains the controller-facing facade:

```gdscript
func _init(start_config: SessionStartConfig) -> void
func apply_right_input(input_frame: TrackInputFrame) -> bool
func apply_left_input(input_frame: TrackInputFrame) -> void
func set_contact_anchors(anchors: Array[RouteContactAnchor]) -> void
func advance_construction(progress_cells: float) -> float
func recover_behind(cutoff_distance_cells: float) -> int
func get_cell_records() -> Array[TrackCellRecord]
func get_geometry_pieces() -> Array[TrackGeometryPiece]
func get_endpoint_cell() -> Vector2i
func get_built_end_distance_cells() -> float
func get_reserved_end_distance_cells() -> float
func get_available_track_cells() -> int
func get_total_track_cells() -> int
func get_grid_origin_units() -> Vector2
func get_position_at_distance_cells(route_distance_cells: float) -> Vector2
func get_heading_at_distance_cells(route_distance_cells: float) -> Vector2
func get_contact_observations() -> Array[Dictionary]
```

`TrackSystem` owns a persistent locked-piece ledger. A locked piece keeps its full original serial range, absolute start distance, and centerline until its final cell is recovered. `get_geometry_pieces()` returns detached active-slice observations whose `active_local_start_cells` and `active_local_end_cells` clip presentation to surviving cells. Train sampling uses the full locked ledger, so partial rear recovery never changes surviving positions or headings.

`TrackInputFrame` replaces arbitrary route samples with cell commands:

```gdscript
var crossed_cells: Array[Vector2i]
var left_press_cell: Vector2i
var left_press_inside_grid: bool
var right_press_cell: Vector2i
var right_press_inside_grid: bool
var left_pressed: bool
var left_held: bool
var left_released: bool
var right_pressed: bool

func _init(
    crossed_cells_value: Array[Vector2i] = [],
    left_press_cell_value: Vector2i = Vector2i(-1, -1),
    left_press_inside_grid_value: bool = false,
    right_press_cell_value: Vector2i = Vector2i(-1, -1),
    right_press_inside_grid_value: bool = false,
    left_pressed_value: bool = false,
    left_held_value: bool = false,
    left_released_value: bool = false,
    right_pressed_value: bool = false
) -> void

static func empty() -> TrackInputFrame
```

The constructor defensively duplicates `crossed_cells_value`; `empty()` returns a new frame with an independent empty array.

`TrainSystem` preserves the accepted argument order:

```gdscript
func _init(speed_cells_per_second: float) -> void
func depart(route_distance_cells: float = 0.0) -> void
func advance_tick(track_system: TrackSystem, seconds_per_tick: float) -> bool
func is_active() -> bool
func get_route_distance_cells() -> float
func get_position(track_system: TrackSystem) -> Vector2
func get_heading(track_system: TrackSystem) -> Vector2
```

`SessionController` preserves its concrete dependency constructor and result ordering:

```gdscript
func _init(
    start_config: SessionStartConfig,
    track_system: TrackSystem,
    train_system: TrainSystem
) -> void
func start() -> void
func advance_tick(input_frame: TrackInputFrame = null) -> void
func get_snapshot() -> SessionSnapshot
func get_state() -> State
```

`SessionSnapshot` replaces polyline and float-inventory observations with defensive copies:

```gdscript
func get_cell_records() -> Array[TrackCellRecord]
func get_geometry_pieces() -> Array[TrackGeometryPiece]
func get_contact_observations() -> Array[Dictionary]
func get_built_end_distance_cells() -> float
func get_available_track_cells() -> int
func get_total_track_cells() -> int
func get_grid_origin_units() -> Vector2
func get_departure_built_cells() -> int
func get_departure_required_cells() -> int
func get_built_distance_ahead_cells() -> float
func get_train_route_distance_cells() -> float
func get_train_position() -> Vector2
func get_train_heading() -> Vector2
func get_estimated_track_end_seconds() -> float
func is_track_end_warning_urgent() -> bool
func get_selected_departure_candidate_id() -> StringName
func get_departure_cell() -> Vector2i
```

Every array getter recursively duplicates its records, pieces, dictionaries, and nested arrays before returning.

### Task 7 Cutover Clarifications

1. **Locked-ledger ownership:** `TrackSystem` owns exactly one `GridTrackRuntime` facade object. The runtime is the sole internal owner of the persistent locked-piece ledger. No duplicate ledger is permitted.

2. **`SessionSnapshot` construction:** The exact typed constructor is:

```gdscript
func _init(
    total_ticks_value: int,
    elapsed_ticks_value: int,
    remaining_ticks_value: int,
    ticks_per_second_value: int,
    has_track_train_data_value: bool = false,
    state_value: int = 0,
    cell_records_value: Array[TrackCellRecord] = [],
    geometry_pieces_value: Array[TrackGeometryPiece] = [],
    contact_observations_value: Array[Dictionary] = [],
    built_end_distance_cells_value: float = 0.0,
    available_track_cells_value: int = 0,
    total_track_cells_value: int = 0,
    grid_origin_units_value: Vector2 = Vector2.ZERO,
    departure_built_cells_value: int = 0,
    departure_required_cells_value: int = 0,
    built_distance_ahead_cells_value: float = 0.0,
    train_active_value: bool = false,
    train_route_distance_cells_value: float = 0.0,
    train_position_value: Vector2 = Vector2.ZERO,
    train_heading_value: Vector2 = Vector2.RIGHT,
    estimated_track_end_seconds_value: float = 0.0,
    track_end_warning_urgent_value: bool = false,
    selected_departure_candidate_id_value: StringName = StringName(),
    departure_cell_value: Vector2i = Vector2i(-1, -1)
) -> void
```

The constructor recursively copies every array, record, piece, dictionary, and nested array argument.

3. **Render observation:** `TrackFieldView.get_render_observation()` returns exactly `logical_size`, `grid_rect`, `cells`, `pieces`, `contacts`, `intervals`, `selected_departure_id`, `selected_departure_position`, `train_active`, `train_position`, `train_heading`, and `hover_cancel_cell`. Every composite value is detached. Each interval dictionary contains exactly `route_serial`, `piece_group_id`, `state`, `build_progress`, `nominal_start_cells`, `nominal_end_cells`, `points`, and `locked`.

4. **Right-input consumption:** `apply_right_input()` returns `true` for every `right_pressed` edge, including an outside-grid edge or a miss. Cancellation is attempted only for an inside-grid cell. The return value means that the edge consumed the frame, so buffered left input is ignored for that frame. Every right edge also terminates the `TrackSystem` left capture; held-left cells remain ignored until a new valid `left_pressed` edge starts another capture.

5. **Left capture:** Left capture begins only when `left_pressed` is inside the grid and `left_press_cell` equals the current endpoint. Buffered crossings are processed only while capture is active. Release-frame crossings are processed before capture is cleared. An invalid initial press discards the buffer and does not begin capture.

6. **Preset coverage:** Unit and smoke tests cover `STANDARD`. Both required real-app integration runners cover `COMPACT` and `EXPANSIVE`.

7. **Curve intervals:** Presentation joins a piece serial range to its cell records and emits one interval dictionary per nominal cell. A `CURVE_3X3` therefore exposes five intervals. Rendering and tests consume the same detached interval observations. Each interval's nominal offset is `record.route_distance_start_cells - owner.absolute_start_distance_cells`, never a subtraction of route serials, so cancellation gaps do not collapse later intervals.

8. **Composition snapping regression:** `PrototypeApp` stores `grid_cell_center(departure_cell)` as the runtime departure position without mutating the authored marker. The accepted Task 1 test at `tests/unit/test_departure_selection.gd` joins the Task 7 allowlist and replaces its transitional authored-position expectation with runtime snapping and source-node immutability assertions.

9. **Post-recovery continuation:** Route serials are monotonic identities and cancellation never reuses them. When recovery removes an earlier cell from locked geometry, a refunded cell appended on the next tick may resolve to an unlocked successor whose recomputed start differs from the locked predecessor's immutable end. After sorting active pieces by route order, `TrackGeometryResolver` considers an unlocked successor only when it follows the locked predecessor in that active order and `successor.absolute_start_distance_cells` equals `predecessor.absolute_start_distance_cells + predecessor.nominal_length_cells` within epsilon. It stitches only if the original endpoints already match or the gap vector points forward and is collinear within epsilon with both the predecessor's final tangent and successor's initial tangent; otherwise runtime continuity rejects the branch. It changes only the successor's first centerline point and never mutates locked geometry. `src/domain/track/track_geometry_resolver.gd` joins the Task 7 allowlist.

10. **Editor composition verification:** Non-`@tool` app and session scripts instantiate as placeholders inside an editor process. The editor gate therefore invokes the existing `tests/integration/run_track_train_app_integration.gd` runner as an external fresh headless harness for composition snapping and source-node immutability. The gate requires exit code `0`, the runner's PASS marker, and no `SCRIPT ERROR`, `Parse Error`, or `FAIL:` diagnostic. No production script becomes `@tool`, and no new harness file is added.

These rulings resolve Task 7 ambiguity and verified cutover regressions without pulling Task 8 cleanup forward.

## Task 1: Add Grid Configuration and Coordinate Mapping

**Files:**

- Modify the configuration, `SessionStartConfig`, `LogicalTrackField`, fixture, and configuration-test paths listed in the target map.

**Interfaces:**

- Produces: validated `grid_cell_size_units: float`, `grid_size: Vector2i`, derived `grid_origin_units: Vector2`, integer inventory/build/departure fields, `get_grid_rect()`, `logical_to_grid_cell(position)`, and `grid_cell_center(cell)`.
- Preserves through Task 7: all existing legacy Resource fields, writers, the full 16-position `SessionStartConfig` constructor, and the three-argument constructor call. Task 8 removes them only after every caller is migrated.

- [ ] **Step 1: Write the failing grid-configuration tests**

Add assertions equivalent to:

```gdscript
func test_grid_defaults_and_mapping() -> void:
    var field := LogicalTrackFieldScript.new()
    assert_equal(field.get_grid_size(), Vector2i(30, 14), "STANDARD grid")
    assert_equal(field.get_grid_cell_size_units(), 40.0, "Cell size")
    assert_equal(field.get_grid_rect().position, Vector2.ZERO, "STANDARD origin")
    assert_equal(field.logical_to_grid_cell(Vector2(0.0, 0.0)), Vector2i(0, 0), "Origin cell")
    assert_equal(field.grid_cell_center(Vector2i(29, 13)), Vector2(1180.0, 540.0), "Final center")

func test_centered_preset_origins_are_explicit() -> void:
    var field := LogicalTrackFieldScript.new()
    field.size_preset = LogicalTrackFieldScript.SizePreset.COMPACT
    assert_equal(field.get_grid_rect().position, Vector2(10.0, 10.0), "COMPACT origin")
    assert_equal(field.grid_cell_center(Vector2i(0, 0)), Vector2(30.0, 30.0), "COMPACT first center")
    field.size_preset = LogicalTrackFieldScript.SizePreset.EXPANSIVE
    assert_equal(field.get_grid_rect().position, Vector2(30.0, 30.0), "EXPANSIVE origin")
    assert_equal(field.grid_cell_center(Vector2i(0, 0)), Vector2(50.0, 50.0), "EXPANSIVE first center")

func test_grid_balance_rejects_noninteger_ownership() -> void:
    var balance := PrototypeBalanceScript.new()
    balance.track_inventory_balance.total_track_cells = 0
    assert_has_message(validator.validate(balance), "total_track_cells must be > 0")
```

Register any new suite in `tests/run_all.gd`.

- [ ] **Step 2: Run RED**

Run the baseline headless command. Expected: failure because grid properties and mapping methods do not exist.

- [ ] **Step 3: Implement the minimal validated grid configuration**

Use exact active fields:

```gdscript
# track_inventory_balance.gd
@export var total_track_cells := 18
@export var recovery_lag_cells := 6
@export var urgent_warning_seconds := 3.0

# track_construction_balance.gd
@export var build_cells_per_second := 3.0

# train_balance.gd
@export var speed_cells_per_second := 1.5

# departure_balance.gd
@export var required_built_cells := 9

# logical_track_field.gd
@export var grid_cell_size_units := 40.0
@export_range(1, 100, 1) var custom_grid_columns := 30
@export_range(1, 100, 1) var custom_grid_rows := 14
```

Add square-grid mapping with one centered grid rectangle. Presets use exact grid counts from Approved Defaults; `CUSTOM` uses `custom_grid_columns` and `custom_grid_rows` and rejects any product that does not fit at `grid_cell_size_units`. Compute `grid_origin_units` once from that rectangle and copy it into `SessionStartConfig`; all later domain geometry consumes the copy rather than recomputing or assuming zero. Preserve the current editor behavior that rescales authored `Marker2D` candidate source positions proportionally when logical field size changes. Snap only the copied runtime departure record to the nearest in-bounds grid cell during `PrototypeApp` composition; do not mutate the authored node during composition.

Add the new grid fields after the existing 16 positional constructor parameters and preserve every legacy field as read/write migration data until Task 8. This keeps all 14 baseline suites green while the new grid components are still isolated.

- [ ] **Step 4: Run GREEN and regressions**

Expected: all registered suites pass; non-grid session-shell compatibility remains green.

- [ ] **Step 5: Commit and review**

```powershell
$MoeRailTaskPaths = @(
    'godot-project-moe-rail-way/data/departure_balance.tres',
    'godot-project-moe-rail-way/data/prototype_balance.tres',
    'godot-project-moe-rail-way/data/track_construction_balance.tres',
    'godot-project-moe-rail-way/data/track_inventory_balance.tres',
    'godot-project-moe-rail-way/data/train_balance.tres',
    'godot-project-moe-rail-way/src/app/prototype_app.gd',
    'godot-project-moe-rail-way/src/config/departure_balance.gd',
    'godot-project-moe-rail-way/src/config/prototype_balance.gd',
    'godot-project-moe-rail-way/src/config/prototype_config_validator.gd',
    'godot-project-moe-rail-way/src/config/track_construction_balance.gd',
    'godot-project-moe-rail-way/src/config/track_inventory_balance.gd',
    'godot-project-moe-rail-way/src/config/train_balance.gd',
    'godot-project-moe-rail-way/src/domain/session/session_start_config.gd',
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd',
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn',
    'godot-project-moe-rail-way/tests/fixtures/invalid_track_train_balance.tres',
    'godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres',
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd',
    'godot-project-moe-rail-way/tests/unit/test_config_validator.gd',
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_config_validator.gd'
) | Sort-Object
git add -- $MoeRailTaskPaths
$MoeRailStaged = @(git diff --cached --name-only) | Sort-Object
$MoeRailUnexpected = @($MoeRailStaged | Where-Object { $_ -notin $MoeRailTaskPaths })
if ($MoeRailUnexpected.Count -ne 0) {
    throw "Unexpected staged path: $($MoeRailUnexpected -join ', ')"
}
git commit -m "feat: define grid track configuration"
```

Run fresh specification and quality reviews before Task 2.

## Task 2: Implement Exact Cell Sequence and Inventory Ownership

**Files:**

- Create `track_cell_record.gd`, `track_cell_sequence.gd`, their UID sidecars, and `test_track_cell_sequence.gd` with its UID.
- Modify `tests/run_all.gd`.

**Interfaces:**

- Consumes: snapped departure cell and `total_track_cells` from Task 1.
- Produces: `TrackCellRecord` plus the departure, append, rollback, cancellation, observation, and integer-conservation subset of `TrackCellSequence`. Task 4 adds geometry assignment, construction, and recovery after the geometry types exist.

- [ ] **Step 1: Write the failing sequence suite**

Cover these exact cases:

```gdscript
func test_append_charges_each_unique_orthogonal_cell_once() -> void:
    var route := TrackCellSequenceScript.new(Vector2i(0, 0), 4)
    assert_equal(route.append_candidates([Vector2i(1, 0), Vector2i(2, 0)]), 2, "Two cells accepted")
    assert_equal(route.get_available_track_cells(), 2, "Two cells remain")
    assert_equal(route.append_candidates([Vector2i(2, 1)]), 1, "Turn cell accepted")
    assert_equal(route.get_available_track_cells(), 1, "One cell remains")
    assert_true(route.is_conservation_valid(), "Integer conservation")

func test_append_stops_before_diagonal_duplicate_or_exhausted_cell() -> void:
    var route := TrackCellSequenceScript.new(Vector2i(0, 0), 2)
    assert_equal(route.append_candidates([Vector2i(1, 1)]), 0, "Diagonal rejected")
    assert_equal(route.append_candidates([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]), 2, "Inventory clips third cell")
    assert_equal(route.get_endpoint_cell(), Vector2i(2, 0), "Endpoint after clip")
    assert_equal(route.get_available_track_cells(), 0, "Inventory exhausted")

func test_cancel_unlocked_ghost_suffix_refunds_once() -> void:
    var route := TrackCellSequenceScript.new(Vector2i(0, 0), 4)
    route.append_candidates([Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)])
    assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 2, "Two ghost cells canceled")
    assert_equal(route.get_available_track_cells(), 3, "Canceled cells refunded")
    assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 0, "Repeated cancel is inert")

func test_tentative_append_can_roll_back_exactly_once() -> void:
    var route := TrackCellSequenceScript.new(Vector2i(0, 0), 2)
    var record: TrackCellRecord = route.try_append_candidate(Vector2i(1, 0))
    assert_true(record != null, "Tentative cell accepted")
    route.rollback_last_unlocked_ghost(record.route_serial)
    assert_equal(route.get_available_track_cells(), 2, "Rollback refunds tentative cell")
    route.rollback_last_unlocked_ghost(record.route_serial)
    assert_equal(route.get_available_track_cells(), 2, "Repeated rollback is inert")
```

- [ ] **Step 2: Run RED**

Expected: preload or symbol failure for the new cell types.

- [ ] **Step 3: Implement immutable observations and exact conservation**

Store mutable authoritative records privately and return `duplicate_record()` copies. Use integer accounting only. Give accepted cells monotonically increasing identity serials that never renumber after recovery, plus an integer-valued absolute nominal start distance that continues from the retained endpoint after cancellation and never renormalizes after rear recovery. Reject the candidate that first violates adjacency, uniqueness, or inventory and every candidate after it in that input buffer. `cancel_ghost_suffix()` rejects a target when that target or any later cell belongs to a locked geometry piece.

- [ ] **Step 4: Run GREEN and regressions**

Expected: the new sequence suite and all existing suites pass.

- [ ] **Step 5: Commit and review**

```powershell
git add godot-project-moe-rail-way/src/domain/track/track_cell_record.gd godot-project-moe-rail-way/src/domain/track/track_cell_record.gd.uid godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd.uid godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd.uid godot-project-moe-rail-way/tests/run_all.gd
git commit -m "feat: add exact track cell ownership"
```

Run fresh specification and quality reviews before Task 3.

## Task 3: Resolve Curves and Mandatory Contact Anchors

**Files:**

- Create `track_geometry_piece.gd`, `track_geometry_resolver.gd`, `track_geometry_resolution.gd`, `route_contact_anchor.gd`, their UID sidecars, and `test_track_geometry_resolver.gd` with its UID.
- Modify `tests/run_all.gd`.

**Interfaces:**

- Consumes: detached route-cell records plus the authoritative centered-grid origin and mapping from Tasks 1-2.
- Produces: deterministic pieces, nominal sampling, footprint coverage, and generic contact-anchor observations.

- [ ] **Step 1: Write the failing curve suite**

Use route fixtures equivalent to:

```gdscript
const STRAIGHT := TrackGeometryPieceScript.Kind.STRAIGHT
const CURVE_1X1 := TrackGeometryPieceScript.Kind.CURVE_1X1
const CURVE_2X2 := TrackGeometryPieceScript.Kind.CURVE_2X2
const CURVE_3X3 := TrackGeometryPieceScript.Kind.CURVE_3X3
const DEPARTURE := Vector2i(-1, 0)

var resolver := TrackGeometryResolverScript.new()

func test_curve_growth_reclassifies_without_changing_cell_count() -> void:
    var four := records_for([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)])
    var result := resolver.resolve(Vector2i(-1, 0), four, [], [], Vector2.ZERO, Vector2i(8, 8), 40.0)
    assert_true(result.is_valid, "Four-cell route resolves")
    assert_piece_kinds(result.pieces, [STRAIGHT, CURVE_2X2])
    assert_equal(total_nominal_cells(result.pieces), 4, "Four nominal cells")

    var five := records_for([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)])
    result = resolver.resolve(Vector2i(-1, 0), five, [], [], Vector2.ZERO, Vector2i(8, 8), 40.0)
    assert_piece_kinds(result.pieces, [CURVE_3X3])
    assert_equal(total_nominal_cells(result.pieces), 5, "Five nominal cells")

func test_overlapping_curves_downgrade_both() -> void:
    var result := resolver.resolve(DEPARTURE, close_double_turn_records(), [], [], Vector2.ZERO, Vector2i(12, 12), 40.0)
    assert_true(result.is_valid, "Double turn resolves")
    assert_equal(curve_sizes(result.pieces), [1, 1], "Both curves downgrade until ownership is disjoint")

func test_anchor_forces_centerline_contact() -> void:
    var anchor := RouteContactAnchorScript.new(&"warp_d", Vector2i(2, 1))
    var result := resolver.resolve(DEPARTURE, abcde_records(), [], [anchor], Vector2.ZERO, Vector2i(8, 8), 40.0)
    assert_true(result.is_valid, "Anchored route resolves")
    assert_true(piece_covering_serial(result.pieces, 3).contacts_cell(anchor.cell, Vector2.ZERO, 40.0), "Centerline contacts anchor")
    assert_equal(piece_covering_serial(result.pieces, 3).kind, CURVE_2X2, "Anchor selects the largest contacting curve")

func test_nonzero_grid_origin_translates_every_centerline() -> void:
    var records := abcde_records()
    var zero := resolver.resolve(DEPARTURE, records, [], [], Vector2.ZERO, Vector2i(8, 8), 40.0)
    var shifted := resolver.resolve(DEPARTURE, records, [], [], Vector2(10.0, 10.0), Vector2i(8, 8), 40.0)
    assert_equal(shifted.pieces[0].centerline[0], zero.pieces[0].centerline[0] + Vector2(10.0, 10.0), "Centered origin translates start")
    assert_equal(shifted.pieces[-1].centerline[-1], zero.pieces[-1].centerline[-1] + Vector2(10.0, 10.0), "Centered origin translates end")
```

Use these concrete local fixture helpers in the same suite:

```gdscript
func records_for(cells: Array[Vector2i]) -> Array[TrackCellRecord]:
    var sequence := TrackCellSequenceScript.new(Vector2i(-1, 0), 32)
    assert_equal(sequence.append_candidates(cells), cells.size(), "Fixture cells accepted")
    return sequence.get_records()

func abcde_records() -> Array[TrackCellRecord]:
    return records_for([
        Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
        Vector2i(2, 1), Vector2i(2, 2),
    ])

func close_double_turn_records() -> Array[TrackCellRecord]:
    return records_for([
        Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
        Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
    ])

func total_nominal_cells(pieces: Array[TrackGeometryPiece]) -> int:
    var total := 0
    for piece in pieces:
        total += piece.nominal_length_cells
    return total

func piece_covering_serial(
    pieces: Array[TrackGeometryPiece],
    route_serial: int
) -> TrackGeometryPiece:
    for piece in pieces:
        if piece.contains_serial(route_serial):
            return piece
    assert_true(false, "Fixture must contain requested serial")
    return null

func curve_sizes(pieces: Array[TrackGeometryPiece]) -> Array[int]:
    var sizes: Array[int] = []
    for piece in pieces:
        if piece.kind == TrackGeometryPieceScript.Kind.CURVE_1X1:
            sizes.append(1)
        elif piece.kind == TrackGeometryPieceScript.Kind.CURVE_2X2:
            sizes.append(2)
        elif piece.kind == TrackGeometryPieceScript.Kind.CURVE_3X3:
            sizes.append(3)
    return sizes

func assert_piece_kinds(
    pieces: Array[TrackGeometryPiece],
    expected: Array[int]
) -> void:
    assert_equal(pieces.size(), expected.size(), "Piece count")
    for index in range(min(pieces.size(), expected.size())):
        assert_equal(pieces[index].kind, expected[index], "Piece kind %d" % index)
```

Also assert `1x1/2x2/3x3` nominal lengths `1/3/5`, grid-bound validation and rejection, locked-piece identity preservation, deterministic repeated resolution, and rejection of an unresolved final `1x1` conflict. Grid bounds reject any out-of-bounds route record before curve sizing; `3x3 -> 2x2 -> 1x1` downgrade applies only to overlap, locked-footprint conflict, or contact-anchor failure.

- [ ] **Step 2: Run RED**

Expected: new geometry types are missing.

- [ ] **Step 3: Implement deterministic template resolution**

Represent every orientation from canonical templates transformed by rotation and translation. Translate each template through the supplied immutable `grid_origin_units` before publishing its centerline or testing anchor coverage. Resolve turns in ascending route serial order, select `3x3 -> 2x2 -> 1x1`, then iteratively downgrade both unlocked overlapping curves. Preserve supplied full locked-ledger pieces byte-for-byte and return active-slice observations for their surviving records. Compute anchor contact from centerline entry into the anchor cell, not from footprint membership.

Return `TrackGeometryResolution.accepted([])` for an empty valid route. Return `rejected(newest_serial, reason)` for grid-bound, locked-boundary, contact, or final-overlap failure. Test the distinction explicitly so the caller can roll back only the tentative newest cell.

`sample_nominal()` clamps local nominal distance into `[0, nominal_length_cells]`, maps the fraction into the template centerline, and returns detached `position` and unit `heading` values.

- [ ] **Step 4: Run GREEN and regressions**

Expected: curve and contact tests pass with stable order; all earlier suites remain green.

- [ ] **Step 5: Commit and review**

```powershell
git add -- godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd.uid godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd.uid godot-project-moe-rail-way/src/domain/track/track_geometry_resolution.gd godot-project-moe-rail-way/src/domain/track/track_geometry_resolution.gd.uid godot-project-moe-rail-way/src/domain/track/route_contact_anchor.gd godot-project-moe-rail-way/src/domain/track/route_contact_anchor.gd.uid godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd.uid godot-project-moe-rail-way/tests/run_all.gd
git commit -m "feat: resolve grid track curves"
```

Run fresh specification and quality reviews before Task 4.

## Task 4: Build the Grid Track Runtime without Cutting Over the App

**Files:**

- Create `grid_track_runtime.gd`, its UID sidecar, `test_grid_track_runtime.gd`, and its UID sidecar.
- Modify `track_cell_sequence.gd` and `tests/run_all.gd`.
- Leave the accepted `TrackSystem` and every legacy route test unchanged in this task.

**Interfaces:**

- Consumes: Tasks 1-3 configuration, sequence, piece, resolver, and anchor contracts.
- Produces: a complete `GridTrackRuntime` core with detached cell/piece/contact observations, while the accepted app continues using its legacy runtime.

- [ ] **Step 1: Write the isolated grid-runtime RED suite**

Required assertions include:

```gdscript
func test_construction_locks_piece_and_builds_one_cell_atomically() -> void:
    var track := make_three_by_three_curve_runtime()
    var before := track.get_geometry_pieces()[0].duplicate_piece()
    track.advance_construction(0.25)
    var records := track.get_cell_records()
    assert_equal(records[0].state, TrackCellRecordScript.State.BUILDING, "Active cell building")
    assert_equal(records[0].build_progress, 0.25, "Quarter progress")
    assert_true(track.get_geometry_pieces()[0].locked, "Whole piece locked")
    assert_equal(track.get_built_end_distance_cells(), 0.0, "Building remains blocked")

    track.set_contact_anchors([
        RouteContactAnchorScript.new(&"late_d", Vector2i(2, 1)),
    ])
    var after := track.get_geometry_pieces()[0]
    assert_equal(after.kind, before.kind, "Locked kind unchanged")
    assert_equal(after.centerline, before.centerline, "Locked centerline unchanged")
    assert_equal(after.footprint_cells, before.footprint_cells, "Locked footprint unchanged")
    track.advance_construction(0.75)
    assert_equal(track.get_cell_records()[0].state, TrackCellRecordScript.State.BUILT, "Cell becomes built")
    assert_equal(track.get_built_end_distance_cells(), 1.0, "Built prefix advances")

func test_recovery_refunds_composite_curve_one_cell_at_a_time() -> void:
    var track := make_fully_built_three_by_three_curve_runtime()
    assert_equal(track.recover_behind(1.0), 1, "First cell recovered")
    assert_equal(track.get_available_track_cells(), 14, "First refund")
    assert_equal(track.recover_behind(2.0), 1, "Second cell recovered")
    assert_equal(track.get_available_track_cells(), 15, "Second refund")

func test_partial_recovery_preserves_locked_curve_sampling() -> void:
    var track := make_fully_built_three_by_three_curve_runtime()
    var survivor_position := track.get_position_at_distance_cells(4.5)
    track.recover_behind(2.0)
    assert_equal(track.get_position_at_distance_cells(4.5), survivor_position, "Sampling survives partial recovery")
    var piece := track.get_geometry_pieces()[0]
    assert_equal(piece.active_local_start_cells, 2.0, "Visible slice starts after recovery")
    assert_equal(piece.active_local_end_cells, 5.0, "Visible slice keeps original end")

func test_runtime_applies_nonzero_grid_origin_to_sampling() -> void:
    var zero := GridTrackRuntimeScript.new(
        Vector2i(0, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
    )
    var shifted := GridTrackRuntimeScript.new(
        Vector2i(0, 0), 18, Vector2(10.0, 10.0), Vector2i(8, 8), 40.0
    )
    var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
    assert_equal(zero.append_cells(cells), 2, "Zero-origin fixture")
    assert_equal(shifted.append_cells(cells), 2, "Shifted fixture")
    assert_equal(shifted.get_grid_origin_units(), Vector2(10.0, 10.0), "Origin retained")
    assert_equal(
        shifted.get_position_at_distance_cells(1.5),
        zero.get_position_at_distance_cells(1.5) + Vector2(10.0, 10.0),
        "Runtime sampling shares centered origin"
    )
```

Use these exact fixture constructors:

```gdscript
func make_three_by_three_curve_runtime() -> GridTrackRuntime:
    var track := GridTrackRuntimeScript.new(
        Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
    )
    var accepted := track.append_cells([
        Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
        Vector2i(2, 1), Vector2i(2, 2),
    ])
    assert_equal(accepted, 5, "3x3 fixture accepts five cells")
    return track

func make_fully_built_three_by_three_curve_runtime() -> GridTrackRuntime:
    var track := make_three_by_three_curve_runtime()
    assert_equal(track.advance_construction(5.0), 5.0, "Fixture builds five cells")
    return track
```

Also cover ordered drag-buffer acceptance, no double charge during curve growth, transactional rollback of one tentative invalid cell, cancellation stopping at a locked piece, construction excess advancing the next cell, whole-group assignment and lock, at most one `BUILDING` cell, failed anchor reflow retaining the last valid geometry with `contact_possible = false`, and exact conservation after every mutation.

- [ ] **Step 2: Run RED**

Expected: preload or symbol failure because `GridTrackRuntime` does not exist. Existing 14 suites remain independently green.

- [ ] **Step 3: Implement the new runtime around the new domain units**

`GridTrackRuntime` owns one `TrackCellSequence`, one `TrackGeometryResolver`, current unlocked pieces, one persistent full locked-piece ledger, supplied anchors, and fixed grid configuration including the immutable `grid_origin_units` copied from `SessionStartConfig`. Do not edit or delegate the accepted `TrackSystem` yet; this parallel construction keeps every pre-cutover regression green.

On reservation, call `try_append_candidate()`, resolve, then call `apply_resolved_geometry()` only for an accepted resolution. If rejected, call `rollback_last_unlocked_ghost()` with the exact tentative serial so only that cell is refunded. On construction start, `start_building()` finds the owning group and locks every active record in that group before changing the first cell state. Copy that full piece into the immutable locked ledger. On cancellation, reject a suffix containing any record whose `geometry_locked` is true. On recovery, emit one integer refund for each eligible built cell in route order and update only the active slice; delete the full ledger piece only after its final cell is gone.

`set_contact_anchors()` always stores detached anchors. It attempts unlocked reflow without modifying locked pieces. A failed reflow retains the last valid geometry and exposes an observation with `contact_possible = false` and `contacted = false`; it never rejects, moves, or removes the anchor.

- [ ] **Step 4: Run GREEN and regressions**

Expected: the new grid-runtime suite passes and every accepted legacy suite still passes unchanged.

- [ ] **Step 5: Commit and review**

```powershell
git add -- godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd.uid godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd.uid godot-project-moe-rail-way/tests/run_all.gd
git commit -m "feat: add grid track runtime"
```

Run fresh specification and quality reviews before Task 5.

## Task 5: Implement Nominal Train Motion without Cutting Over the App

**Files:**

- Create `nominal_train_motion.gd`, its UID sidecar, `test_nominal_train_motion.gd`, and its UID sidecar.
- Modify `tests/run_all.gd`.
- Leave the accepted `TrainSystem` and its legacy tests unchanged in this task.

**Interfaces:**

- Consumes: a built-end nominal distance from `GridTrackRuntime`.
- Produces: `NominalTrainMotion` at `speed_cells_per_second` with the accepted built-end request semantics.

- [ ] **Step 1: Write the failing nominal-distance train suite**

```gdscript
func test_five_cell_curve_matches_five_straight_cell_time() -> void:
    var curve_track := make_built_three_by_three_curve_track()
    var straight_track := make_built_straight_track(5)
    var curve_train := NominalTrainMotionScript.new(1.0)
    var straight_train := NominalTrainMotionScript.new(1.0)
    curve_train.depart(0.0)
    straight_train.depart(0.0)
    for tick in range(299):
        assert_false(curve_train.advance(5.0, 1.0 / 60.0), "Curve remains before end")
        assert_false(straight_train.advance(5.0, 1.0 / 60.0), "Straight remains before end")
    assert_true(curve_train.advance(5.0, 1.0 / 60.0), "Curve reaches end on tick 300")
    assert_true(straight_train.advance(5.0, 1.0 / 60.0), "Straight reaches end on tick 300")
    assert_true(is_equal_approx(curve_train.get_route_distance_cells(), 5.0), "Curve nominal distance")
    assert_true(is_equal_approx(straight_train.get_route_distance_cells(), 5.0), "Straight nominal distance")
    assert_false(
        curve_track.get_position_at_distance_cells(2.5).is_equal_approx(
            straight_track.get_position_at_distance_cells(2.5)
        ),
        "Different geometry shares the same nominal timing"
    )

func test_train_cannot_enter_building_cell() -> void:
    var track := make_one_built_one_building_track()
    var train := NominalTrainMotionScript.new(1.0)
    train.depart(0.0)
    assert_true(train.advance(track.get_built_end_distance_cells(), 2.0), "Building cell blocks movement")
    assert_equal(train.get_route_distance_cells(), 1.0, "Train clamps to built prefix")
```

Define the fixtures locally so this task does not depend on another test script:

```gdscript
func make_built_three_by_three_curve_track() -> GridTrackRuntime:
    var track := GridTrackRuntimeScript.new(
        Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
    )
    assert_equal(track.append_cells([
        Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
        Vector2i(2, 1), Vector2i(2, 2),
    ]), 5, "Curve fixture cells")
    assert_equal(track.advance_construction(5.0), 5.0, "Curve fixture built")
    return track

func make_built_straight_track(cell_count: int) -> GridTrackRuntime:
    var track := GridTrackRuntimeScript.new(
        Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
    )
    var cells: Array[Vector2i] = []
    for index in range(cell_count):
        cells.append(Vector2i(index, 0))
    assert_equal(track.append_cells(cells), cell_count, "Straight fixture cells")
    assert_equal(track.advance_construction(float(cell_count)), float(cell_count), "Straight fixture built")
    return track

func make_one_built_one_building_track() -> GridTrackRuntime:
    var track := GridTrackRuntimeScript.new(
        Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
    )
    assert_equal(track.append_cells([Vector2i(0, 0), Vector2i(1, 0)]), 2, "Building fixture cells")
    assert_equal(track.advance_construction(1.5), 1.5, "Second cell remains building")
    return track
```

Also assert continuous position and heading across every piece boundary, inactive no-op, no reverse, and recovery-safe absolute distance.

- [ ] **Step 2: Run RED**

Expected: preload or symbol failure because `NominalTrainMotion` does not exist; accepted train tests remain green.

- [ ] **Step 3: Implement nominal cell movement**

Store speed and distance in nominal cells. Advance by `speed_cells_per_second * seconds_per_tick`, clamp to the supplied built nominal endpoint, and request track end when the proposed movement reaches that endpoint. Position and heading remain the responsibility of `GridTrackRuntime` sampling. Do not compute movement from screen-pixel arc length.

- [ ] **Step 4: Run GREEN and regressions**

Expected: the new nominal-motion suite and every accepted legacy suite pass.

- [ ] **Step 5: Commit and review**

```powershell
git add -- godot-project-moe-rail-way/src/domain/train/nominal_train_motion.gd godot-project-moe-rail-way/src/domain/train/nominal_train_motion.gd.uid godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd.uid godot-project-moe-rail-way/tests/run_all.gd
git commit -m "feat: add nominal train motion"
```

Run fresh specification and quality reviews before Task 6.

## Task 6: Rasterize Physical Pointer Motion without Cutting Over the View

**Files:**

- Create `grid_pointer_rasterizer.gd`, its UID sidecar, `test_grid_pointer_rasterizer.gd`, and its UID sidecar.
- Modify `tests/run_all.gd`.
- Leave `TrackFieldView`, `TrackInputFrame`, and every accepted input integration test unchanged in this task.

**Interfaces:**

- Consumes: the grid rectangle and dimensions from Task 1.
- Produces: deterministic ordered orthogonal cell crossings for one physical pointer-motion segment.

- [ ] **Step 1: Write the isolated rasterizer RED suite**

Cover exact horizontal, vertical, L-shaped multi-event, fast multi-cell, outside-grid, repeated-cell, dominant-axis corner, and equal-axis horizontal-first cases. A representative assertion is:

```gdscript
func test_fast_motion_returns_every_crossed_cell_in_order() -> void:
    var rasterizer := GridPointerRasterizerScript.new()
    var cells := rasterizer.rasterize_motion(
        Vector2(20.0, 20.0),
        Vector2(140.0, 20.0),
        Rect2(Vector2.ZERO, Vector2(1200.0, 560.0)),
        Vector2i(30, 14),
        Vector2i(0, 0)
    )
    assert_equal(
        cells,
        [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
        "Fast motion must preserve every crossed cell"
    )
```

For an L shape, call the rasterizer once per real mouse-motion event and append each returned array; do not infer a shortest Manhattan path between the first and final cursor samples.

- [ ] **Step 2: Run RED**

Expected: preload or symbol failure because `GridPointerRasterizer` does not exist; accepted input and app suites remain green.

- [ ] **Step 3: Implement deterministic grid traversal**

Walk boundary-crossing times in increasing order. Emit one orthogonally adjacent cell per boundary. At a simultaneous grid corner, emit the dominant motion axis first and the other axis second; for an exact equal-axis segment, emit horizontal first. Never emit a cell outside `grid_rect`, the supplied `previous_cell`, or the same cell twice consecutively.

- [ ] **Step 4: Run GREEN and regressions**

Expected: the rasterizer suite and every accepted legacy suite pass.

- [ ] **Step 5: Commit and review**

```powershell
git add -- godot-project-moe-rail-way/src/presentation/track/grid_pointer_rasterizer.gd godot-project-moe-rail-way/src/presentation/track/grid_pointer_rasterizer.gd.uid godot-project-moe-rail-way/tests/unit/test_grid_pointer_rasterizer.gd godot-project-moe-rail-way/tests/unit/test_grid_pointer_rasterizer.gd.uid godot-project-moe-rail-way/tests/run_all.gd
git commit -m "feat: rasterize grid pointer motion"
```

Run fresh specification and quality reviews before Task 7.

## Task 7: Cut Over the Complete Runtime and Presentation Atomically

**Files:**

- Modify the accepted `TrackSystem`, `TrainSystem`, `TrackInputFrame`, `SessionController`, `SessionSnapshot`, view, shell, app, editor gate, fixtures, and every legacy route-sensitive unit/integration/smoke test listed in the target map.
- Do not remove transitional configuration fields in this task; Task 8 removes them only after the new vertical slice is green.

**Interfaces:**

- Consumes: all isolated grid components completed in Tasks 1-6.
- Produces: one playable grid-only vertical slice while retaining the accepted public class names and session completion contract.

- [ ] **Step 1: Rewrite all route-sensitive suites to the grid contract**

Required scenarios:

- a drag across three horizontal cells emits all three cells in order;
- an L-shaped drag emits the physically crossed horizontal and vertical order without a diagonal shortcut;
- a fast segment crossing an exact corner follows the documented dominant-axis/equal-tie rule;
- HUD, margin, and letterbox events emit no cells;
- right-click resolves one grid cell and preserves edge semantics;
- snapshot presentation shows all five intervals of a `3x3` curve as ghost before construction;
- the active interval reports its fractional fade while remaining nontraversable;
- completed intervals are solid and the locked piece does not reflow after later input;
- `TRACK` shows integer `available / total`;
- for `COMPACT`, `STANDARD`, and `EXPANSIVE`, the same test cell's rasterized logical center, resolved centerline sample, rendered point, and train position agree exactly; this must exercise the nonzero `(10, 10)` and `(30, 30)` origins;
- resize preserves grid hit mapping and does not change domain cells.

The domain/controller migration also verifies:

- `TrackSystem` delegates cell ownership, geometry, construction, and recovery to `GridTrackRuntime`;
- `TrainSystem` delegates nominal progress to `NominalTrainMotion` and samples position and heading from `TrackSystem`;
- right-click cancellation wins before the same tick's buffered left cells;
- construction completes before same-tick departure and movement;
- recovery refunds are not spendable until the next tick;
- preparation timer freeze, regular-expiry tie priority, terminal snapshot-before-result, and post-completion inertness remain unchanged;
- every snapshot getter returns recursively detached cell, piece, footprint, centerline, and contact data.

Use render observations such as:

```gdscript
var observation := view.get_render_observation()
assert_equal(observation.cells[0].state, TrackCellRecordScript.State.BUILT, "Built cell")
assert_equal(observation.cells[1].state, TrackCellRecordScript.State.BUILDING, "Building cell")
assert_equal(observation.cells[1].build_progress, 0.5, "Build fade")
assert_equal(
    observation.pieces[0].kind,
    TrackGeometryPieceScript.Kind.CURVE_3X3,
    "Resolved curve kind"
)
assert_true(observation.pieces[0].locked, "Building locks the owning piece")
```

In both `run_logical_track_field_integration.gd` and `run_track_train_app_integration.gd`, define a file-private `compose_preset_fixture(preset, departure_cell)` helper with the same contract; do not create or modify a shared support file. Each private helper instantiates the real scene, selects a deterministic authored departure candidate which composes to the requested cell, overrides the validated test balance to one required built cell and `1.0` train cell per second, and returns the real app, field, view, controller, and latest detached snapshot. Run this exact contract for both `COMPACT` and `EXPANSIVE` in each runner:

```gdscript
func assert_centered_preset_end_to_end(
    preset: int,
    expected_origin: Vector2
) -> void:
    var fixture := await compose_preset_fixture(preset, Vector2i(0, 0))
    var field = fixture.field
    var target_cell := Vector2i(1, 0)
    var target_center := field.grid_cell_center(target_cell)
    assert_equal(fixture.app.session_start_config.grid_origin_units, expected_origin, "Config origin")
    fixture.drag_through_logical_centers([target_center])
    var input_frame = fixture.view.consume_input_frame()
    assert_equal(input_frame.crossed_cells, [target_cell], "Rasterized cell")
    fixture.advance_with_input_until_train_distance(input_frame, 1.0)
    var snapshot = fixture.latest_snapshot
    var observation := fixture.view.get_render_observation()
    assert_equal(snapshot.get_grid_origin_units(), expected_origin, "Snapshot origin")
    assert_equal(snapshot.get_geometry_pieces()[0].sample_nominal(1.0).position, target_center, "Runtime centerline")
    assert_equal(observation.pieces[0].sample_nominal(1.0).position, target_center, "Rendered centerline")
    assert_equal(snapshot.get_train_position(), target_center, "Train position")

func test_compact_centered_origin_end_to_end() -> void:
    await assert_centered_preset_end_to_end(LogicalTrackFieldScript.SizePreset.COMPACT, Vector2(10.0, 10.0))

func test_expansive_centered_origin_end_to_end() -> void:
    await assert_centered_preset_end_to_end(LogicalTrackFieldScript.SizePreset.EXPANSIVE, Vector2(30.0, 30.0))
```

The helper may split input consumption from controller advancement internally, but it must exercise the accepted `PrototypeApp`, `TrackFieldView`, `TrackSystem`, `SessionController`, `SessionSnapshot`, and train sampling path. A resolver-only or manually constructed runtime fixture does not satisfy this Task 7 integration requirement.

- [ ] **Step 2: Run RED**

Expected: the rewritten legacy suites fail against the still-active continuous runtime, while every isolated Task 1-6 suite remains green.

- [ ] **Step 3: Switch the accepted public facades and controller**

Replace active continuous-polyline code in `TrackSystem` with validation and delegation to `GridTrackRuntime`, passing the exact `SessionStartConfig.grid_origin_units` copy into the runtime and resolver. Replace `TrainSystem` internals with `NominalTrainMotion` while preserving `advance_tick(track_system, seconds_per_tick)` argument order. Replace `TrackInputFrame` with the exact constructor in Public Interfaces. Replace scalar construction, movement, recovery, and snapshot wiring in `SessionController` and `SessionSnapshot` with cell contracts.

`SessionController` uses the exact order in the spec: right cancellation, left cell buffer, construction and piece lock, departure transition, movement, later feature hooks, one-cell refund events, timer, end priority, detached snapshot, result.

- [ ] **Step 4: Implement buffered grid input and piece rendering**

Use `GridPointerRasterizer` for each real `_gui_input` mouse-motion segment and accumulate its ordered cells until `consume_input_frame()`. Give the rasterizer the same centered grid rectangle whose position was copied as `grid_origin_units`. Clear the buffer exactly once per physics tick. Draw each active piece slice by nominal intervals: solid for `BUILT`, a ghost-to-solid blend for the active `BUILDING` interval, and translucent for later ghost intervals. Draw from snapshot copies only.

Retain the existing uniform logical-to-viewport transform and selected departure marker. Do not add tile art assets in this milestone.

Update the first-party editor gate to assert preset grid counts, centered grid rectangles, custom columns/rows validation, normalized authored-candidate preservation, and composition-time snapping without source-node mutation.

- [ ] **Step 5: Run GREEN and all standalone integrations**

Run the main suite and these four scripts in separate fresh processes:

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment\godot-project-moe-rail-way'
$MoeRailScripts = @(
    'res://tests/run_all.gd',
    'res://tests/integration/run_session_shell_integration.gd',
    'res://tests/integration/run_logical_track_field_integration.gd',
    'res://tests/integration/run_track_train_input_integration.gd',
    'res://tests/integration/run_track_train_app_integration.gd'
)
foreach ($MoeRailScript in $MoeRailScripts) {
    & $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailScript
    if ($LASTEXITCODE -ne 0) { throw "GREEN failed: $MoeRailScript" }
}
```

Expected: the main suite plus session-shell, logical-field, track-input, and app integration markers pass at default and nondefault configuration.

- [ ] **Step 6: Commit only the cutover allowlist and review**

```powershell
$MoeRailTaskPaths = @(
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd',
    'godot-project-moe-rail-way/src/app/prototype_app.gd',
    'godot-project-moe-rail-way/src/domain/session/session_controller.gd',
    'godot-project-moe-rail-way/src/domain/session/session_snapshot.gd',
    'godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd',
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd',
    'godot-project-moe-rail-way/src/domain/track/track_system.gd',
    'godot-project-moe-rail-way/src/domain/train/train_system.gd',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd',
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
    'godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres',
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd',
    'godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd',
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd',
    'godot-project-moe-rail-way/tests/unit/test_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_train_system.gd'
) | Sort-Object
git add -- $MoeRailTaskPaths
$MoeRailStaged = @(git diff --cached --name-only) | Sort-Object
$MoeRailUnexpected = @($MoeRailStaged | Where-Object { $_ -notin $MoeRailTaskPaths })
if ($MoeRailUnexpected.Count -ne 0) {
    throw "Unexpected staged path: $($MoeRailUnexpected -join ', ')"
}
git commit -m "feat: cut over to grid track operation"
```

Run fresh specification and quality reviews before Task 8.

## Task 8: Delete Legacy Contracts and Pass the Milestone Gate

**Files:**

- Modify only the remaining configuration, data, fixture, route-sensitive test, runner-registration, and manual-checklist paths already listed in the target map that still name obsolete unit-distance or freeform behavior, plus these six Task 7 positional callers omitted from the cleanup staging list:
  - `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
  - `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
  - `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
  - `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
  - `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
  - `godot-project-moe-rail-way/tests/unit/test_train_system.gd`
- Delete no historical plan or tag.

**Interfaces:**

- Consumes: completed Tasks 1-7.
- Produces: one grid-only active runtime surface, updated test registration, manual evidence, and a clean reviewed feature branch.

- [ ] **Step 0: Prove legacy contract removal is RED**

Add property-absence assertions to the already registered `tests/unit/test_track_train_config_validator.gd`, then run:

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment\godot-project-moe-rail-way'
& $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd
```

Expected: nonzero exit with assertions naming still-present transitional properties. The failure must be caused by the legacy surface only; parse errors, unrelated assertions, or process diagnostics do not qualify as RED evidence.

- [ ] **Step 1: Remove transitional aliases and obsolete assertions**

Run:

```powershell
rg -n "total_units|total_track_units|recovery_distance_units|speed_units_per_second|required_built_units|endpoint_grab_radius_units|route_hit_radius_units|minimum_sample_distance_units|intersection_clearance_units|train_speed_value|total_track_value|recovery_distance_value|construction_speed_value|endpoint_grab_radius_value|route_hit_radius_value|minimum_sample_distance_value|intersection_clearance_value|departure_required_built_value|_route_points|_route_distances|partial segment|projection tie" godot-project-moe-rail-way/src godot-project-moe-rail-way/data godot-project-moe-rail-way/tests
```

Expected before cleanup: only explicitly transitional code and legacy tests are listed. Remove or rewrite every active occurrence. Historical Markdown is excluded from this scan by design.

The six positional callers listed under **Files** contain no searchable legacy identifiers, but their numeric arguments still follow the transitional 25-argument order. Migrating all six to the final 16-argument `SessionStartConfig` order is mandatory.

Run the same `rg` command after cleanup. Expected: exit `1` with no matches. Any remaining active match blocks the commit.

- [ ] **Step 2: Run the complete automated gate**

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment\godot-project-moe-rail-way'
$MoeRailScripts = @(
    'res://tests/run_all.gd',
    'res://tests/integration/run_session_shell_integration.gd',
    'res://tests/integration/run_logical_track_field_integration.gd',
    'res://tests/integration/run_track_train_input_integration.gd',
    'res://tests/integration/run_track_train_app_integration.gd'
)
foreach ($MoeRailScript in $MoeRailScripts) {
    & $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailScript
    if ($LASTEXITCODE -ne 0) { throw "Grid milestone failed: $MoeRailScript" }
}
```

Expected: every registered suite and all four standalone integrations pass, no skip marker appears, and every process exits `0`.

- [ ] **Step 3: Run hygiene and ownership checks**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment'
git -C $MoeRailFeature diff --check
git -C $MoeRailFeature status --short
$UidMissing = @(
    rg --files "$MoeRailFeature\godot-project-moe-rail-way" -g '*.gd' |
        Where-Object { -not (Test-Path -LiteralPath "$_.uid") }
)
if ($UidMissing.Count -ne 0) { throw "Missing UID: $($UidMissing -join ', ')" }
```

Expected: no whitespace errors, only plan-allowed feature paths, and zero missing UID sidecars.

- [ ] **Step 4: Perform the Windows manual gate**

Update `tests/manual/track_train_windows.md` and record:

- endpoint-only cell placement with no diagonal shortcut;
- visible `1x1`, `2x2`, and `3x3` curve fitting;
- two close curves downgrading without overlap;
- no extra inventory charge when a ghost curve grows;
- translucent ghost route, progressive active-cell fade, and atomic built state;
- geometry reflow before construction, the affected piece locking when its first cell starts, and later unlocked ghost pieces continuing to reflow;
- continuous train travel over curves using nominal timing;
- track-end failure on a building-but-incomplete next cell;
- one-cell-at-a-time refund behind the train;
- correct integer HUD and pointer alignment at `960x540`, `1280x720`, and `1920x1080`.
- centered-grid alignment in `COMPACT`, `STANDARD`, and `EXPANSIVE`: pointer cell, curve centerline, rendered track, and train occupy the same logical position.

- [ ] **Step 5: Commit the cleanup and evidence**

```powershell
$MoeRailCleanupPaths = @(
    'godot-project-moe-rail-way/data/departure_balance.tres',
    'godot-project-moe-rail-way/data/prototype_balance.tres',
    'godot-project-moe-rail-way/data/track_construction_balance.tres',
    'godot-project-moe-rail-way/data/track_inventory_balance.tres',
    'godot-project-moe-rail-way/data/train_balance.tres',
    'godot-project-moe-rail-way/src/config/departure_balance.gd',
    'godot-project-moe-rail-way/src/config/prototype_balance.gd',
    'godot-project-moe-rail-way/src/config/prototype_config_validator.gd',
    'godot-project-moe-rail-way/src/config/track_construction_balance.gd',
    'godot-project-moe-rail-way/src/config/track_inventory_balance.gd',
    'godot-project-moe-rail-way/src/config/train_balance.gd',
    'godot-project-moe-rail-way/src/domain/session/session_start_config.gd',
    'godot-project-moe-rail-way/tests/fixtures/invalid_track_train_balance.tres',
    'godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd',
    'godot-project-moe-rail-way/tests/manual/track_train_windows.md',
    'godot-project-moe-rail-way/tests/run_all.gd',
    'godot-project-moe-rail-way/tests/unit/test_config_validator.gd',
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd',
    'godot-project-moe-rail-way/tests/unit/test_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_config_validator.gd',
    'godot-project-moe-rail-way/tests/unit/test_train_system.gd'
) | Sort-Object
git add -- $MoeRailCleanupPaths
$MoeRailStaged = @(git diff --cached --name-only) | Sort-Object
$MoeRailUnexpected = @($MoeRailStaged | Where-Object { $_ -notin $MoeRailCleanupPaths })
if ($MoeRailUnexpected.Count -ne 0) {
    throw "Unexpected staged path: $($MoeRailUnexpected -join ', ')"
}
git commit -m "test: validate grid track milestone"
```

- [ ] **Step 6: Verify the committed feature and editor behavior in a disposable mirror**

Require a clean feature worktree, rerun the five automated commands from Step 2, then create an ordinary-file mirror from committed tracked files:

```powershell
$ErrorActionPreference = 'Stop'
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment'
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
if (@(git -C $MoeRailFeature status --porcelain=v1 --untracked-files=all).Count -ne 0) {
    throw 'Feature worktree must be clean before editor mirroring.'
}
$MoeRailProject = Join-Path $MoeRailFeature 'godot-project-moe-rail-way'
$MoeRailScripts = @(
    'res://tests/run_all.gd',
    'res://tests/integration/run_session_shell_integration.gd',
    'res://tests/integration/run_logical_track_field_integration.gd',
    'res://tests/integration/run_track_train_input_integration.gd',
    'res://tests/integration/run_track_train_app_integration.gd'
)
foreach ($MoeRailScript in $MoeRailScripts) {
    & $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailScript
    if ($LASTEXITCODE -ne 0) { throw "Committed gate failed: $MoeRailScript" }
}
$MoeRailMirrorRoot = Join-Path (
    [IO.Path]::GetTempPath()
) ('moerail-grid-editor-' + [Guid]::NewGuid().ToString('N'))
$MoeRailMirrorRepo = Join-Path $MoeRailMirrorRoot 'MoeRailWay'
New-Item -ItemType Directory -Path $MoeRailMirrorRepo | Out-Null
$MoeRailTracked = @(git -C $MoeRailFeature ls-files)
foreach ($MoeRailRelative in $MoeRailTracked) {
    $MoeRailSource = Join-Path $MoeRailFeature $MoeRailRelative
    $MoeRailDestination = Join-Path $MoeRailMirrorRepo $MoeRailRelative
    $MoeRailDestinationFull = [IO.Path]::GetFullPath($MoeRailDestination)
    if (-not $MoeRailDestinationFull.StartsWith(
        [IO.Path]::GetFullPath($MoeRailMirrorRepo) + [IO.Path]::DirectorySeparatorChar
    )) {
        throw "Mirror path escaped root: $MoeRailRelative"
    }
    New-Item -ItemType Directory -Force -Path (
        Split-Path -Parent $MoeRailDestinationFull
    ) | Out-Null
    Copy-Item -LiteralPath $MoeRailSource -Destination $MoeRailDestinationFull
}
$MoeRailMirrorProject = Join-Path $MoeRailMirrorRepo 'godot-project-moe-rail-way'
$MoeRailEnvRoot = Join-Path $MoeRailMirrorRoot 'env'
$MoeRailOldEnv = @{
    APPDATA = $env:APPDATA
    LOCALAPPDATA = $env:LOCALAPPDATA
    TEMP = $env:TEMP
    TMP = $env:TMP
}
try {
    foreach ($MoeRailName in @('APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP')) {
        $MoeRailValue = Join-Path $MoeRailEnvRoot $MoeRailName
        New-Item -ItemType Directory -Force -Path $MoeRailValue | Out-Null
        Set-Item -Path "Env:$MoeRailName" -Value $MoeRailValue
    }
    $MoeRailSmoke = @(
        & $MoeRailGodot --headless --editor --path $MoeRailMirrorProject --quit-after 1800 2>&1
    )
    $MoeRailSmoke | Write-Host
    if ($LASTEXITCODE -ne 0) { throw 'No-flag editor smoke failed.' }
    if ($MoeRailSmoke -match 'SCRIPT ERROR|ERROR:|Parse Error') {
        throw 'No-flag editor smoke emitted a forbidden diagnostic.'
    }
    $MoeRailGate = @(
        & $MoeRailGodot --headless --editor --path $MoeRailMirrorProject --quit-after 1800 -- --moerail-logical-field-editor-gate 2>&1
    )
    $MoeRailGate | Write-Host
    if ($LASTEXITCODE -ne 0) { throw 'Grid editor gate failed.' }
    if ($MoeRailGate -match 'SCRIPT ERROR|ERROR:|Parse Error|FAIL:') {
        throw 'Grid editor gate emitted a forbidden diagnostic.'
    }
    $MoeRailPassCount = @(
        $MoeRailGate | Where-Object { $_ -eq 'PASS: logical track field editor integration' }
    ).Count
    if ($MoeRailPassCount -ne 1) {
        throw "Editor gate PASS count is $MoeRailPassCount"
    }
} finally {
    foreach ($MoeRailName in $MoeRailOldEnv.Keys) {
        Set-Item -Path "Env:$MoeRailName" -Value $MoeRailOldEnv[$MoeRailName]
    }
}
Write-Host "EDITOR_MIRROR_RETAINED=$MoeRailMirrorRoot"
if (@(git -C $MoeRailFeature status --porcelain=v1 --untracked-files=all).Count -ne 0) {
    throw 'Feature source changed during editor mirror verification.'
}
```

Expected: no-flag editor smoke exits `0`; the flagged editor gate prints its PASS marker exactly once and exits `0`; the source feature remains clean. Retain and report the mirror path. Cleanup is a separate destructive gate.

- [ ] **Step 7: Run independent final reviews**

Dispatch one fresh specification reviewer and, after all findings are fixed and retested, one separate fresh quality reviewer. Both review the implementation diff from `MOERAIL_GRID_DOCS_SHA` to feature HEAD and use the immutable `67518fc8...` baseline only for migration comparison. Fix findings in focused allowlisted commits and rerun the five automated processes plus the disposable editor gate after each fix.

- [ ] **Step 8: Stop at the integration approval gate**

Report the feature HEAD, commit list, full test marker, manual evidence path, changed-file list, deletion-ledger completion, and primary-worktree preservation evidence. Do not merge, tag, push, open a PR, or remove the worktree without separate user approval.

## Definition of Done

- The branch is based on the reviewed documentation-only child of exact accepted `prototype-m3` and contains only plan-allowed changes.
- All baseline behavior not explicitly superseded remains covered.
- Active runtime and tests contain no freeform route sampling or floating-length inventory contract.
- Grid input preserves the actual orthogonal crossed-cell order and never pathfinds.
- Cell inventory conserves exactly and curve reclassification never double-charges.
- Curve sizes, anchor contact, overlap downgrade, reflow, and lock behavior match the specification.
- Construction, traversal, and recovery use cell states and nominal cell distance exactly.
- The copied centered-grid origin is shared by input, departure snapping, geometry, contact checks, rendering, and train sampling for every preset.
- Ghost, building, built, curve, train, inventory, warning, and result states are readable at supported resolutions.
- Runtime warp generation, cargo, economy, hazards, contracts, credit, fleet, and office upgrades are absent.
- All automated, hygiene, manual, specification, and quality gates pass with recorded evidence.
- Integration into `Prototyping`, `prototype-m4` tagging, remote push, PR creation, and worktree cleanup remain pending their own user approvals.
