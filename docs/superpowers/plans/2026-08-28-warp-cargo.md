# Warp Cargo Prototype Slice Implementation Plan

- Date: 2026-08-28
- Status: Draft for user review; not authorized for implementation
- Audience: Agent-facing execution plan
- Canonical design: `docs/superpowers/specs/2026-08-28-warp-cargo-design.md`
- Branch authority: `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`
- Planning base observed on 2026-08-28: `edebc32c977300ed21ee163b89d42624cf070bf3`
- Planned branch: `feature/warp-cargo`
- Planned external worktree: `D:\godot\MoeRailWay-worktrees\warp-cargo`

## 1. Execution Boundary

This document is a plan, not implementation authorization. Do not modify gameplay code until the user explicitly starts implementation in a separate session.

This planning task authorizes no stage, commit, push, pull request, merge, tag, primary synchronization, worktree removal, or branch deletion. A later implementation authorization may explicitly include the task-local exact staging and focused commits prescribed here; publication, integration, tags, synchronization, and cleanup always remain separate approval gates.

Prototype code must remain concrete. Do not add production abstractions or widen scope to Risk & Investment, Contract Economy, Credit Survival, custom art, or mobile support.

## 2. Implementation Session Preflight

Run all preflight checks before editing code.

1. Re-read `AGENTS.md`, the canonical design, this plan, the main-first policy, and the grid-track amendment.
2. Record the primary workspace branch, full `HEAD`, upstream, porcelain-v2 status including untracked files, `origin/main`, merge base, ahead/behind counts, and all worktrees.
3. Fetch `origin` without switching branches or touching the primary index or working tree, then record the same facts again.
4. Require `D:\godot\MoeRailWay` to be clean local `main`, tracking and exactly equal to the current verified `origin/main`.
5. Require `feature/warp-cargo` to be attached only to `D:\godot\MoeRailWay-worktrees\warp-cargo` and require its index and working tree to be clean.
6. Require exactly these three reviewed planning paths to exist in a focused, separately approved documentation commit before Task 1: `docs/superpowers/specs/2026-08-28-warp-cargo-design.md`, `docs/superpowers/plans/2026-08-28-warp-cargo.md`, and `docs/briefings/ko/2026-08-28-warp-cargo-design-plan-briefing.md`. Uncommitted planning documents stop implementation because they violate every task's changed-path allowlist. Do not commit them without that separate approval.
7. Require the feature merge base to equal the verified implementation base. If `main` advanced after planning, stop and request a branch-base decision. Do not rebase, reset, recreate, or delete the worktree automatically.
8. Confirm Godot `4.7.1` console executable and project path.
9. Run the five baseline runners below and reject nonzero exit or anchored `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, or `CRASH:` output:

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\warp-cargo\godot-project-moe-rail-way'
$MoeRailBaselineScripts = @(
    'res://tests/run_all.gd',
    'res://tests/integration/run_session_shell_integration.gd',
    'res://tests/integration/run_logical_track_field_integration.gd',
    'res://tests/integration/run_track_train_input_integration.gd',
    'res://tests/integration/run_track_train_app_integration.gd'
)
foreach ($MoeRailScript in $MoeRailBaselineScripts) {
    $MoeRailOutput = @(
        & $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailScript 2>&1
    )
    $MoeRailExit = $LASTEXITCODE
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    if ($MoeRailExit -ne 0) {
        throw "Baseline runner failed with exit $MoeRailExit: $MoeRailScript"
    }
    if ($MoeRailText -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') {
        throw "Baseline runner emitted a rejected diagnostic: $MoeRailScript"
    }
}
```

Expected baseline markers are `PASS: 19 prototype test suite(s)`, both session-shell PASS markers, logical-track-field PASS, track-train-input PASS, and track-train-app PASS. A mismatch stops implementation.

Never stash, reset, format, stage, copy, absorb, move, delete, or otherwise reinterpret user-owned changes in the primary or another worktree.

## 3. Global Task Protocol

Every task below must execute this order without omission:

1. **RED:** add or activate the smallest relevant executable test and prove it fails for the intended missing behavior. Parse errors, unrelated failures, crashes, and missing host permissions do not count.
2. **Minimum GREEN:** implement only the concrete behavior owned by that task.
3. **Regressions:** run the task-specific tests plus every listed existing runner.
4. **Allowlist:** compare the complete changed path set with the task allowlist. Any extra path stops the task.
5. **Exact-path staging:** require an empty index, stage only the literal allowlist paths changed by the task, and inspect `git diff --cached --check`, `--stat`, and full staged diff.
6. **Focused commit:** create exactly the listed task commit. Do not amend or squash prior task evidence.
7. **Independent specification review:** a reviewer other than the implementing agent compares code, tests, and evidence with the canonical design and plan.
8. **Independent quality review:** a separate reviewer checks correctness, determinism, test quality, ownership, failure handling, and accidental abstraction.

The two reviews use two distinct reviewer agents, neither of which performed the implementation. Each report names the exact reviewed `HEAD`, verdict, and findings. Keep the reports in the task conversation/evidence stream and later copy their verdicts into the pull request; do not create unplanned tracked review files.

Rejected review findings receive focused follow-up commits on the same feature branch. A review-fix commit may use the explicit union of the original task allowlists affected by the finding, and the review report must list that exact subset before editing or staging. It may not add a new path or behavior. A required new path or behavior requires a reviewed plan amendment before work continues. Rerun affected gates and both reviews.

Explicit implementation authorization must state whether it includes the task-local exact staging and focused commits prescribed here. If it does not, implementation stops after each GREEN/regression/allowlist gate and requests the next repository-write approval. Push, PR, merge, tag, primary synchronization, and cleanup are never implied by implementation authorization.

Every tracked GDScript created by this plan has exactly one adjacent `.gd.uid` sidecar. Never track `.godot`, logs, personal playtest data, generated caches, or temporary review output.

Use this executable shape for every focused, full, and integration runner named below; a shorthand runner name never means invoking a `.gd` file directly in PowerShell:

```powershell
function Invoke-MoeRailGodotGate(
    [string]$Script,
    [string[]]$UserArguments = @(),
    [string[]]$RequiredMarkers = @()
) {
    $MoeRailArguments = @('--headless', '--path', $MoeRailProject, '--script', $Script)
    if ($UserArguments.Count -gt 0) {
        $MoeRailArguments += '--'
        $MoeRailArguments += $UserArguments
    }
    $MoeRailOutput = @(& $MoeRailGodot @MoeRailArguments 2>&1)
    $MoeRailExit = $LASTEXITCODE
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    if ($MoeRailExit -ne 0) { throw "Godot gate failed with exit $MoeRailExit: $Script" }
    if ($MoeRailText -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') {
        throw "Godot gate emitted a rejected diagnostic: $Script"
    }
    foreach ($MoeRailMarker in $RequiredMarkers) {
        if ($MoeRailText -notmatch [regex]::Escape($MoeRailMarker)) {
            throw "Godot gate missed marker '$MoeRailMarker': $Script"
        }
    }
}
```

For example, the Task 1 focused call is:

```powershell
Invoke-MoeRailGodotGate `
    -Script 'res://tests/run_all.gd' `
    -UserArguments @('--suite=test_warp_pair_system.gd') `
    -RequiredMarkers @('PASS: 1 prototype test suite(s)')
```

## 4. Approved Defaults and Validation

### `WarpLifecycleBalance`

```gdscript
@export_range(0.0, 60.0, 0.1) var forecast_duration_seconds := 8.0
@export_range(0.1, 120.0, 0.1) var generation_interval_seconds := 12.0
@export_range(1.0, 180.0, 0.1) var lifetime_min_seconds := 24.0
@export_range(1.0, 180.0, 0.1) var lifetime_max_seconds := 36.0
@export_range(1, 6, 1) var max_live_pairs := 3
```

### `CargoBalance`

```gdscript
@export_range(1, 8, 1) var base_slot_count := 2
@export_range(0, 1000000, 1) var base_delivery_reward := 100
```

Validation rejects null Resources, nonfinite floating values, values outside the documented range, and `lifetime_max_seconds < lifetime_min_seconds`. Values copy into `SessionStartConfig`; systems receive integer tick values and copied scalar values only.

## 5. Final Public Interfaces

Cross-script types use explicit `preload` constants, matching the current repository convention.

### 5.1 Configuration additions

`PrototypeBalance` adds:

```gdscript
@export var warp_lifecycle_balance: WarpLifecycleBalance
@export var cargo_balance: CargoBalance
```

`SessionStartConfig` appends source-compatible constructor values and public copied fields:

```gdscript
var warp_forecast_ticks: int
var warp_generation_interval_ticks: int
var warp_lifetime_min_ticks: int
var warp_lifetime_max_ticks: int
var warp_max_live_pairs: int
var cargo_base_slot_count: int
var cargo_base_delivery_reward: int
```

### 5.2 Pair model

```gdscript
class_name WarpPairRecord
extends RefCounted

enum State {
    FORECAST,
    ACTIVE_UNLOADED,
    IN_TRANSIT,
    DELIVERED,
    EXPIRED,
    VOIDED,
}

var pair_id: StringName
var ordinal: int
var origin_cell: Vector2i
var destination_cell: Vector2i
var state: State
var forecast_remaining_ticks: int
var lifetime_total_ticks: int
var lifetime_remaining_ticks: int
var style_index: int

func duplicate_record() -> WarpPairRecord
```

```gdscript
class_name WarpPairSystem
extends RefCounted

func _init(start_config: SessionStartConfig, session_rng: SessionRng) -> void
static func cell_from_row_major_index(index: int, grid_size: Vector2i) -> Vector2i
func begin_running_tick(tick_index: int) -> void
func resolve_contact_hits(
    tick_index: int,
    hits: Array[Dictionary],
    cargo_system: CargoSystem
) -> void
func expire_after_contact(tick_index: int, cargo_system: CargoSystem) -> void
func void_nonterminal(tick_index: int, cargo_system: CargoSystem) -> void
func get_route_contact_anchors() -> Array[RouteContactAnchor]
func get_pair_records() -> Array[WarpPairRecord]
func get_tick_events() -> Array[Dictionary]
```

`begin_running_tick` clears the prior tick's event buffer, advances existing forecasts, activates due pairs, handles due generation, and creates the current anchor set. It is idempotent for the same tick index.

The anchor set contains origin and destination for `ACTIVE_UNLOADED`, destination only for `IN_TRANSIT`, and none for forecast or terminal records.

Task 1 implements compiling cargo-free lifecycle signatures `expire_after_contact(tick_index)` and `void_nonterminal(tick_index)`. Task 2 replaces those signatures with the final `CargoSystem` parameters shown above and adds `resolve_contact_hits`. Task 1 must not preload, type-reference, stub, or create `CargoSystem` before its Task 2 allowlist.

### 5.3 Cargo model

```gdscript
class_name CargoSlotRecord
extends RefCounted

var slot_index: int
var pair_id: StringName
var style_index: int

func is_empty() -> bool
func duplicate_record() -> CargoSlotRecord
```

```gdscript
class_name CargoSystem
extends RefCounted

func _init(base_slot_count: int, base_delivery_reward: int) -> void
func try_load(pair_id: StringName, style_index: int) -> int
func try_deliver(pair_id: StringName) -> Dictionary
func remove_pair(pair_id: StringName) -> int
func clear_all() -> void
func get_slot_records() -> Array[CargoSlotRecord]
func get_occupied_slot_count() -> int
func get_total_slot_count() -> int
func get_delivered_pair_count() -> int
func get_base_delivery_reward_total() -> int
```

`try_deliver` returns `{ "delivered": bool, "slot_index": int, "amount": int }`. `remove_pair` returns the cleared slot index or `-1`.

### 5.4 Consumed route boundary extension

`GridTrackRuntime` and `TrackSystem` add only:

```gdscript
func get_contact_hits_between(
    previous_distance_cells: float,
    through_distance_cells: float
) -> Array[Dictionary]
```

The method returns at most one detached hit per anchor ID, ordered by nominal contact distance and then stable anchor ID. It compares the mapped cell at the previous-distance boundary with later one-eighth-nominal-cell samples and emits only the earliest outside-to-anchor-cell transition. Continuing inside the same cell across consecutive sweeps does not re-emit. Distance `0.0` is treated as outside only for the first positive movement; an anchor activated around the train at a later distance does not emit without a later re-entry. Invalid nonfinite, negative, or reversed ranges return empty without mutation in every build. The route method does not parse Warp Cargo identifiers. `WarpPairSystem` applies origin-before-destination and numeric pair-ordinal tie-breakers after consuming the raw hits. No Warp Cargo class reads geometry-piece internals.

### 5.5 Session observations

`SessionSnapshot` adds:

```gdscript
func get_warp_pair_records() -> Array[WarpPairRecord]
func get_cargo_slot_records() -> Array[CargoSlotRecord]
func get_occupied_cargo_slots() -> int
func get_total_cargo_slots() -> int
func get_delivered_pair_count() -> int
func get_base_delivery_reward_total() -> int
func get_warp_cargo_events() -> Array[Dictionary]
```

`SessionResult` adds:

```gdscript
func get_delivered_pair_count() -> int
func get_base_delivery_reward_total() -> int
```

Constructor additions remain trailing optional values so existing direct test fixtures compile while the implementation tasks migrate relevant callers.

## 6. Task 1: Add Validated Balance and Seeded Pair Lifecycle

**Objective:** Produce deterministic forecast, activation, anchor, expiry, and void behavior without cargo or app cutover.

**Create:**

- `godot-project-moe-rail-way/src/config/warp_lifecycle_balance.gd`
- `godot-project-moe-rail-way/src/config/warp_lifecycle_balance.gd.uid`
- `godot-project-moe-rail-way/src/config/cargo_balance.gd`
- `godot-project-moe-rail-way/src/config/cargo_balance.gd.uid`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_record.gd`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_record.gd.uid`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_system.gd`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_system.gd.uid`
- `godot-project-moe-rail-way/data/warp_lifecycle_balance.tres`
- `godot-project-moe-rail-way/data/cargo_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_pair_system.gd.uid`

**Modify:**

- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/tests/run_all.gd`

**RED:** Use two valid RED phases. First register a suite that calls `ResourceLoader.exists` for the planned scripts/Resources without preloading missing files; require ordinary assertion failures, not parser diagnostics. Create the minimum compiling class/Resource skeletons and UID sidecars. Then replace existence assertions with behavioral tests and require ordinary failures for default-copy, range-validation, row-major generation, independent equal-cell sampling, draw order, live-capacity gating, exact countdown activation ticks, delayed-generation cadence, active-anchor ownership, expiry, void, same-tick idempotence, fixed-seed replay, and deep-copy contracts.

Use `cell_from_row_major_index` over every index of a small grid to prove the complete mapping directly, and reject out-of-range indices. Use a `1 x 1` seeded generation to prove equal-cell origin/destination is accepted without reroll. Compare complete pair and event sequences from two systems with the same seed. Do not add a fake RNG interface or brute-force a seed until a desired assertion passes.

**Minimum GREEN:** Add the two Resources, copied tick fields, owner-qualified validation, concrete record, and concrete pair system. Reuse `SessionRng.next_index`; do not add a random framework or a route dependency. Generate anchor values only for `ACTIVE_UNLOADED` and `IN_TRANSIT` records.

**Regressions:**

- focused suite through `Invoke-MoeRailGodotGate -Script 'res://tests/run_all.gd' -UserArguments @('--suite=test_warp_pair_system.gd')`;
- full `run_all.gd`, expected suite count `20`;
- existing session-shell, logical-field, track-input, and track-app integration runners.

**Exact staging and commit:** Require an empty index; stage only changed paths in this task's Create/Modify lists; compare staged paths with that literal allowlist; inspect staged diff; commit `feat: define seeded warp pair lifecycle`.

**Independent reviews:** Specification review must prove no generation correction or cargo behavior entered. Quality review must examine RNG consumption, tick conversion, copy isolation, owner-qualified validation, ID/style uniqueness, and terminal idempotence.

## 7. Task 2: Add Concrete Cargo Slots and Base Reward

**Objective:** Own empty, full, mixed, delivery, expiry-removal, and reward behavior independently from pair scheduling.

**Create:**

- `godot-project-moe-rail-way/src/domain/cargo/cargo_slot_record.gd`
- `godot-project-moe-rail-way/src/domain/cargo/cargo_slot_record.gd.uid`
- `godot-project-moe-rail-way/src/domain/cargo/cargo_system.gd`
- `godot-project-moe-rail-way/src/domain/cargo/cargo_system.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_cargo_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_cargo_system.gd.uid`

**Modify:**

- `godot-project-moe-rail-way/src/domain/warp/warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**RED:** Register `test_cargo_system.gd`. Require failures for lowest-empty-slot loading, full no-op, mixed-slot preservation, matching-only delivery, one reward, repeated-contact no-op, expiry removal, clear-all, exact occupancy arithmetic, and detached records. Extend pair tests to require origin-before-destination same-cell behavior, route-ordered slot reuse, lifecycle changes only after successful load/delivery, and no reward on expiry/void.

**Minimum GREEN:** Add the fixed concrete slot array and reward accumulator. Let `WarpPairSystem.resolve_contact_hits` call only the public Cargo methods and update only its own pair state/events. Do not add cash, company, contract, settlement, purchases, manual cargo commands, or a combined manager.

**Regressions:**

- focused `test_cargo_system.gd` and `test_warp_pair_system.gd` suites;
- full `run_all.gd`, expected suite count `21`;
- all four existing integration runners after `run_all.gd`.

**Exact staging and commit:** Stage only the paths in this task's Create/Modify lists and commit `feat: add automatic cargo slot transitions`.

**Independent reviews:** Specification review checks every load/delivery/expiry/void rule and one-pair-one-reward invariant. Quality review checks slot conservation, idempotence, detached copies, deterministic tie behavior, and absence of economy scope.

## 8. Task 3: Expose Ordered Hits Through the Existing Route Contract

**Objective:** Observe swept train entry into active anchor cells using accepted centerline data, without implementing Warp-specific geometry or pathfinding.

**Create:** None.

**Modify:**

- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`

**RED:** First use `has_method("get_contact_hits_between")` so the missing API produces an ordinary assertion failure rather than a parser/runtime method-call error. Add the compiling method signature returning an empty array, then require behavioral RED for straight and `1x1`/`2x2`/`3x3` centerlines, nonzero grid origin, recovered cells, multiple anchors in one sweep, one hit per anchor, earliest one-eighth-cell outside-to-inside transition distance, equal-distance stable anchor-ID ordering, `(previous, through]` repeat suppression, no re-hit while two consecutive sweeps remain inside one cell, mandatory departure-cell hit from zero, no immediate hit when an anchor activates around a train already inside at a later distance, invalid-range empty results, locked-contact-impossible observations, and returned-Dictionary mutation isolation.

The test must show the method consumes the same active piece ledger and cell mapping as current contact observations. A test that reconstructs geometry in the test or Warp domain is invalid.

**Minimum GREEN:** Add one delegated public method to `TrackSystem` and one implementation in `GridTrackRuntime`. Refactor the current internal centerline-to-cell sampling only as needed to share its calculation. Preserve current `get_contact_observations()` keys and behavior. Do not change route resolution, anchor placement, inventory, construction, recovery, gesture behavior, or train motion.

**Regressions:**

- focused `test_grid_track_runtime.gd`;
- full `run_all.gd`, still `21` suites;
- logical-track-field, track-input, and track-app integration runners.

**Exact staging and commit:** Stage exactly the three modified paths and commit `feat: expose swept route contact hits`.

**Independent reviews:** Specification review confirms the half-open sweep, distance ordering, and consumed anchor contract. Quality review specifically looks for duplicate geometry logic, sampling-boundary regressions, unstable Dictionary order, recovered-ledger mistakes, and any route correction.

## 9. Task 4: Integrate Warp Cargo Into the Fixed Tick

**Objective:** Compose pair, cargo, track, and train systems in the accepted priority; publish detached snapshots/results; keep every existing session invariant.

**Create:**

- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_session_controller.gd.uid`

**Modify:**

- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/domain/random/session_rng.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

`test_project_boot.gd` must keep its seed-offset balance fixture valid by delegating to the complete configured balance after Task 1 adds required nested Resources. `session_rng.gd` may expose only exact state capture and restore, and `warp_pair_system.gd` may expose only exact pair-state capture and restore, so a rejected Task 4 preparation attempt can roll back the attempted running tick atomically without changing later Warp draws or pair state. These paths authorize no new random policy, request correction, pair transition, or test replacement.

**RED:** Register the controller suite. Use deterministic small-grid systems and explicit ticks to require:

- no scheduling during `PREPARING_DEPARTURE`;
- first running-tick forecast and zero-forecast activation timing;
- active anchors installed before relevant route input/movement;
- previous and through train distances passed to the route hit query;
- physical-distance, origin-before-destination, and ordinal hit order;
- movement/contact delivery before same-tick pair expiry;
- pair expiry before session timer expiry;
- delivery retained when regular expiry also wins a track-end tie;
- regular and early completion clear nonterminal cargo once;
- terminal snapshot precedes one result;
- result contains delivered count and base reward;
- pair, slot, event, snapshot, and result observations are detached;
- all mutation calls after completion are no-ops while observation getters continue returning the terminal snapshot.

**Minimum GREEN:** Compose one `WarpPairSystem` and one `CargoSystem` in `PrototypeApp`, pass them explicitly to `SessionController`, and implement the exact tick order. Trailing null constructor defaults disable Warp Cargo only for unchanged legacy direct fixtures and publish empty pair/slot/event observations with zero totals; they never construct implicit default systems. The real app must always provide both validated systems, and one null without the other is a debug assertion failure. Extend snapshot/result as data holders only. Do not add an event bus or let presentation call domain transitions.

**Regressions:**

- focused new controller suite;
- existing `test_session_controller.gd` and `test_track_train_session_controller.gd`;
- full `run_all.gd`, expected suite count `22`;
- all four existing integration runners.

**Exact staging and commit:** Stage only this task's Create/Modify paths and commit `feat: orchestrate warp cargo session ticks`.

**Independent reviews:** Specification review reconstructs the full tick trace for final-life delivery and regular-end void. Quality review checks completion idempotence, dependency nullability, snapshot copying, legacy-test compatibility, and that app composition owns wiring without becoming a global manager.

## 10. Task 5: Add Placeholder Feedback and End-to-End Evidence

**Objective:** Make every required state readable in the real Windows scene with primitive visuals and prove the complete slice end to end.

**Create:**

- `godot-project-moe-rail-way/src/presentation/cargo/cargo_slot_strip.gd`
- `godot-project-moe-rail-way/src/presentation/cargo/cargo_slot_strip.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_presentation.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_presentation.gd.uid`
- `godot-project-moe-rail-way/tests/fixtures/warp_cargo_balance.tres`
- `godot-project-moe-rail-way/tests/integration/warp_cargo_app.tscn`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd.uid`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`

**Modify:**

- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`
- `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`

The two existing regression tests above require assertion-only updates for Task 5's intended public presentation changes: `TrackFieldView` adds the `warp_endpoints` observation key, and the inactive `CASH`/`CARGO` placeholders become the live `BASE REWARD` and `occupied / total` displays. No production behavior or additional scope is authorized by these paths.

**RED:** First register presentation assertions and create the integration runner with expected missing-view failures. Require observations for all six placeholder styles, forecast alpha/countdown, filled origin, outlined destination, in-transit origin change, slot fill, delivered reward change, expiry removal, void clearing, nonintercepting field input, correct logical-grid mapping, and `occupied / total` text. The integration must run a fixed seed through forecast, load, full-slot no-op, mixed-slot load, delivery on the final lifetime tick, expiry, and regular-end void in the real scene.

Use startup seed `73013`. `warp_cargo_balance.tres` is one `PrototypeBalance` fixture with embedded copies of every nested balance Resource. Give Warp Cargo the distinct values: forecast `0.2` seconds, interval `0.5` seconds, lifetime minimum `1.5` seconds, lifetime maximum `16.5` seconds, live limit `3`, cargo slots `2`, and base reward `37`, at `10` ticks per second. These lifetime values preserve the canonical `1.0..180.0` validation contract while providing enough seeded separation for one real-route full-slot no-op, later mixed-slot load, expiry, and final-life delivery. Give the existing nested Resources valid deterministic test values and record all exact values in the fixture assertions. The scene references that fixture and a deterministic custom field. Unit tests independently verify the seed's draw sequence against direct `SessionRng` calls; the integration may read generated cells to construct controlled input but must compare the final hard-coded event/state trace approved in the Task 5 RED review. It must not alter production defaults or rely on frame-rate timing; it advances explicit physics ticks and controlled input frames.

**Minimum GREEN:** Draw endpoints inside `TrackFieldView` from detached snapshot records using existing logical transforms. Add one concrete noninteractive `CargoSlotStrip` Control and wire it through `SessionShell`. Rename the existing cash placeholder label to `BASE REWARD` and show the provisional integer total. Use primitives, the fallback font, and six fixed color-shape styles only. Do not create textures, import assets, intercept input, or alter domain rules to simplify rendering.

**Regressions:**

- focused presentation suite;
- full `run_all.gd`, expected suite count `23`;
- new `run_warp_cargo_integration.gd`, expected `PASS: warp cargo integration`;
- all four existing integration runners;
- `git diff --check` and exact UID sidecar audit.

**Windows manual verification:** Execute `tests/manual/warp_cargo_windows.md` at `960x540`, `1280x720`, `1600x900`, and `1920x1080`. Record final feature `HEAD`, seed, observed ticks, tester, Godot version, window sizes, pass/fail rows, and screenshot paths in task-owned evidence outside the repository; summarize that evidence in the later pull request rather than dirtying the feature worktree. Verify mouse-only track drawing remains correct, warp visuals never steal input, color and shape both identify pairs, whole-second countdowns are readable, empty/full/mixed slots are distinguishable, reward updates immediately, impossible behind-train pairs are not corrected, locked impossible contact remains visible as a missed opportunity, expiry clears cargo, and regular end clears all live state without penalty text.

**Exact staging and commit:** Stage only this task's Create/Modify paths and commit `feat: present warp cargo prototype feedback`.

**Independent reviews:** Specification review checks every visible state and the custom-art exclusion. Quality review checks resize/layout behavior, draw performance, mapping reuse, input pass-through, fixture determinism, manual evidence, and absence of domain decisions in presentation.

## 11. Per-Task Staging Guard

For each task, construct `$MoeRailTaskPaths` from that task's literal Create/Modify lists. Then run the equivalent of:

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\warp-cargo'
function Invoke-MoeRailGitLines([string[]]$Arguments) {
    $Output = @(& git -C $MoeRailFeature @Arguments)
    if ($LASTEXITCODE -ne 0) {
        throw "git failed: $($Arguments -join ' ')"
    }
    return $Output
}

$MoeRailInitiallyStaged = @(Invoke-MoeRailGitLines @('diff', '--cached', '--name-only'))
if ($MoeRailInitiallyStaged.Count -ne 0) {
    throw 'Index must be empty before exact-path staging.'
}

$MoeRailForbiddenStatus = @(
    Invoke-MoeRailGitLines @('diff', '--name-status', '--diff-filter=DR')
    Invoke-MoeRailGitLines @('diff', '--cached', '--name-status', '--diff-filter=DR')
)
if ($MoeRailForbiddenStatus.Count -ne 0) {
    throw "Renames and deletions are not authorized: $($MoeRailForbiddenStatus -join ', ')"
}

$MoeRailChanged = @(
    Invoke-MoeRailGitLines @('diff', '--name-only')
    Invoke-MoeRailGitLines @('diff', '--cached', '--name-only')
    Invoke-MoeRailGitLines @('ls-files', '--others', '--exclude-standard')
) | Sort-Object -Unique
$MoeRailUnexpected = @($MoeRailChanged | Where-Object { $_ -notin $MoeRailTaskPaths })
if ($MoeRailUnexpected.Count -ne 0) {
    throw "Unexpected worktree path: $($MoeRailUnexpected -join ', ')"
}

& git -C $MoeRailFeature add -- $MoeRailTaskPaths
if ($LASTEXITCODE -ne 0) { throw 'Exact-path staging failed.' }
$MoeRailStaged = @(Invoke-MoeRailGitLines @('diff', '--cached', '--name-only')) | Sort-Object -Unique
$MoeRailExpectedStaged = @($MoeRailTaskPaths | Where-Object { $_ -in $MoeRailChanged }) | Sort-Object -Unique
if (Compare-Object $MoeRailExpectedStaged $MoeRailStaged) {
    throw 'Staged paths do not exactly match the changed task allowlist.'
}
& git -C $MoeRailFeature diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
& git -C $MoeRailFeature diff --cached --stat
if ($LASTEXITCODE -ne 0) { throw 'Staged stat inspection failed.' }
& git -C $MoeRailFeature diff --cached
if ($LASTEXITCODE -ne 0) { throw 'Staged diff inspection failed.' }
```

All planned paths use repository-relative ASCII names, so the guard avoids porcelain substring parsing entirely. This plan authorizes no renames or deletions. Do not stage the canonical planning documents into an implementation task commit unless a separately approved documentation amendment changed them for that task.

## 12. Final Automated Feature Gate

After all task commits and review-fix commits:

1. Confirm the feature worktree is on `feature/warp-cargo`, has the approved merge base, and has no staged or unstaged changes.
2. Compare the complete feature diff against the union of all task allowlists and separately approved plan-document paths.
3. Require one `.gd.uid` sidecar per tracked GDScript and no orphan sidecar.
4. Run:
   - `res://tests/run_all.gd` with `PASS: 23 prototype test suite(s)`;
   - `run_session_shell_integration.gd`;
   - `run_logical_track_field_integration.gd`;
   - `run_track_train_input_integration.gd`;
   - `run_track_train_app_integration.gd`;
   - `run_warp_cargo_integration.gd`.
5. Require exit `0`, every expected PASS marker, and no anchored error, warning, fatal, script-error, or crash output.
6. Re-run the Windows manual checklist on the exact final feature `HEAD`.
7. Obtain final independent specification and quality approvals against the exact final `HEAD` and evidence set.
8. Inspect commit order and require focused task history with review fixes preserved.

Stop after reporting the final gate. Push, PR creation, automatic merge, primary synchronization, tag creation, and cleanup require separate user authorization.

## 13. Final Review Checklist

### Specification reviewer

- Candidate pool contains every in-bounds cell and no route state.
- Origin/destination independent sampling, equal-cell result, draw order, and finite lifetime match the design.
- Forecast is informational and anchor-free; activation installs exact anchors.
- Existing route, construction, recovery, train sampling, and `RouteContactAnchor` contracts are consumed, not reimplemented.
- Movement/contact precedes expiry; expiry precedes session expiry; regular expiry retains same-tick delivery.
- Empty/full/mixed slot behavior and one-pair-one-reward are exact.
- Void and expiry create no fine or failure.
- Placeholder visuals use both color and shape and add no custom art.
- Deferred slices and production abstraction are absent.

### Quality reviewer

- RNG consumption and event order are deterministic and tested.
- Resource values are validated, copied, and owner-qualified in errors.
- Pair, slot, hit, event, snapshot, and result data are detached.
- Terminal transitions and session completion are idempotent.
- No route geometry or physical movement logic is duplicated.
- Presentation does not intercept input or mutate domain state.
- Tests exercise real boundaries rather than test-only replacement implementations.
- All task allowlists, exact staging evidence, commits, regressions, and manual evidence are complete.

## 14. Known Deferred Work

- Contract attribution and conversion of base reward into persistent cash.
- Temporary cargo-capacity purchase and cost curves.
- Hazards, durability, demolition, and crossings.
- Credit, settlement, bankruptcy, and multi-cycle progression.
- Final art and accessibility validation.
- Production architecture, persistence, replay format, and abstraction-scope decisions.

These are explicit exclusions, not hidden implementation tasks.
