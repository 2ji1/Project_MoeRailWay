# Warp Cargo Control-Feel Amendment Implementation Plan

- Date: 2026-08-28
- Status: Draft for user review; not authorized for implementation
- Audience: Agent-facing execution plan
- Canonical design: `docs/superpowers/specs/2026-08-28-warp-cargo-control-feel-amendment-design.md`
- Parent plan: `docs/superpowers/plans/2026-08-28-warp-cargo.md`
- Branch authority: `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`
- Planning feature base: `b5d33117d08ed3e14269b353f2a84a72c4f24a0c`
- Merge base: `edebc32c977300ed21ee163b89d42624cf070bf3`
- Branch: `feature/warp-cargo`
- External worktree: `D:\godot\MoeRailWay-worktrees\warp-cargo`

## 1. Execution Boundary

This plan documents the next implementation cycle. It does not itself authorize gameplay-code edits.

Before Task 1, require one focused, separately approved documentation commit containing exactly:

- `docs/superpowers/specs/2026-08-28-warp-cargo-control-feel-amendment-design.md`
- `docs/superpowers/plans/2026-08-28-warp-cargo-control-feel-amendment.md`
- `docs/briefings/ko/2026-08-28-warp-cargo-control-feel-amendment-briefing.md`

Implementation authorization may include task-local exact staging and focused commits. Push, pull request, merge, tag, primary synchronization, cleanup, and changes in any other worktree remain separate approval gates.

Do not widen scope to production abstractions, automatic routing, impossible-request correction, later economy or hazard slices, custom art, or mobile input.

## 2. Implementation Preflight

Before editing code:

1. Re-read `AGENTS.md`, the canonical amendment, this plan, the parent Warp Cargo design and plan, the main-first policy, the grid-track amendment, and the endpoint-track-reshaping design.
2. Record primary and feature branch, full `HEAD`, upstream, porcelain-v2 status including untracked paths, `origin/main`, merge base, ahead/behind counts, and all worktrees.
3. Fetch `origin` without switching branches or modifying any working tree or index, then record the same evidence again.
4. Require `D:\godot\MoeRailWay` to be clean local `main`, tracking and exactly equal to current `origin/main`.
5. Require the external feature worktree to be clean on `feature/warp-cargo`, based on the reviewed documentation commit whose parent is `b5d33117d08ed3e14269b353f2a84a72c4f24a0c` unless an approved review-fix documentation commit is present.
6. Require the three planning paths above to be committed together and no implementation path to be changed.
7. Require Godot `4.7.1.stable.official.a13da4feb` and the console executable at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`.
8. Run `res://tests/run_all.gd`, all four existing baseline integration runners, and `res://tests/integration/run_warp_cargo_integration.gd`. Require `PASS: 23 prototype test suite(s)`, every integration PASS marker, exit `0`, and no anchored `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, or `CRASH:`.

Any mismatch stops work. Never stash, reset, rebase, stage, copy, absorb, move, delete, or edit another worktree to clear a gate.

## 3. Global Task Protocol

Every task executes this exact order:

1. Add the smallest executable assertion and prove a relevant RED failure.
2. Implement the minimum concrete GREEN behavior.
3. Run focused tests and every named regression.
4. Compare all changed paths with the task's literal allowlist.
5. Require an empty index, stage exact literal paths only, and inspect `git diff --cached --check`, staged path list, stat, and full diff.
6. Create the named focused commit without amend or squash.
7. Obtain an independent specification review against the exact commit.
8. Obtain a distinct independent quality review against the same commit.

Review fixes use only the explicitly reported subset of the affected task allowlists. A new path or behavior requires an approved plan amendment. Keep every new tracked GDScript paired with exactly one adjacent `.gd.uid` file. Do not track generated caches, `.godot`, logs, screenshots, or temporary evidence.

Use the existing `Invoke-MoeRailGodotGate` command shape from the parent Warp Cargo plan. A focused suite must be invoked through `res://tests/run_all.gd -- --suite=<file>` and must produce `PASS: 1 prototype test suite(s)`.

## 4. Approved Configuration and Interfaces

`SessionBalance` adds:

```gdscript
@export_range(10, 100, 1) var planning_time_scale_percent := 25
```

`SessionStartConfig` copies:

```gdscript
var planning_time_scale_percent: int
```

`RouteContactAnchor` adds:

```gdscript
enum ContactMode { CELL_ENTRY, EXACT_CELL_CENTER }
var contact_mode: ContactMode
```

Its trailing constructor argument defaults to `CELL_ENTRY` for source compatibility. Warp anchors explicitly pass `EXACT_CELL_CENTER`.

`SessionSnapshot` adds trailing optional constructor values and getters:

```gdscript
func is_planning_slowdown_active() -> bool
func get_planning_time_scale_percent() -> int
func did_advance_simulation_tick() -> bool
```

The trailing defaults are `planning_slowdown_active = false`, `planning_time_scale_percent = 100`, and `did_advance_simulation_tick = true` for legacy direct fixtures. Real controller snapshots always pass all three authoritative values.

`TrackFieldView.get_render_observation()` appends detached `departure_marker` and `planning_indicator` Dictionaries with the exact keys from the design.

No general time service, scheduler object, spline editor, anchor-provider interface, or event bus is added.

## 5. Task 1: Snap Active Warp Routes to Exact Cell Centers

**Objective:** Change only Warp anchors from cell-entry coverage to exact center knots and align cargo contact with the visible marker.

**Modify:**

- `godot-project-moe-rail-way/src/domain/track/route_contact_anchor.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`

**RED:**

1. Assert legacy anchors still default to `CELL_ENTRY` and active Warp origin/destination anchors explicitly use `EXACT_CELL_CENTER`.
2. Add resolver fixtures for anchored straight and `CURVE_1X1`, `CURVE_2X2`, and `CURVE_3X3` pieces. Require the exact world-space cell center at the route record's nominal midpoint, preserved owned span/footprint/nominal length, entry/exit tangent continuity, and deterministic replay. The anchored straight must retain its existing two-point centerline byte-for-byte and prove exact contact by linear projection; only anchored curves use the fixed 16-samples-per-nominal-cell centerline. Rotate and mirror every curve size to prove entry/exit boundary `floor` mapping never causes direction-dependent downgrade or rejection; boundary endpoints use continuity checks while every interior sample stays inside the footprint, except for the design-authorized first-route lead-in samples that remain in the departure cell without changing footprint ownership.
3. Require multiple exact IDs in one cell to share geometry while remaining detached observations.
4. Require an exact anchor absent from the active route sequence to stay impossible even when its cell lies inside a curve footprint.
5. Require unlocked activation to re-resolve, locked off-center geometry to remain byte-unchanged and impossible, and anchor removal to affect only unlocked geometry.
6. Require contact observations to retain existing facts and add detached mode plus exact nominal distance, using `-1.0` for impossible exact or legacy cell-entry observations.
7. Require exact hits at nominal midpoint, earliest matching projection on already-locked compatible geometry, half-open repeat suppression, departure distance `0.0`, equal-distance stable-ID ordering, and legacy cell-entry fixtures unchanged.
8. Update the fixed-seed integration assertions before GREEN to require no load or delivery before the visible exact knot and hard-code the intended exact-contact ticks derived from the fixture route and nominal knot distances. Keep every non-contact-derived expectation unchanged.
9. During an active gesture, require activation and later anchor removal to update both the evolving origin and live candidate. Aborting must restore the route edit while retaining the current authoritative anchor lifecycle and its valid reflow or impossible observation.

Expected world centers and nominal knot distances must be calculated in the tests from literal fixture grid values and route-record offsets. Tests may not ask the production resolver, contact observation, or hit query for the value they then use as the expected value.

RED must be ordinary assertion failure from missing mode or missing exact behavior. Parser errors and broken legacy fixtures are invalid RED.

**Minimum GREEN:** Add the concrete mode, exact-knot curve construction, exact-center observation, and mode-specific hit logic. Use the design's fixed sample and cubic-handle rules inside the current resolver. Do not modify route-cell ownership, template selection order, inventory, construction, train speed, Warp RNG, or lifecycle order.

**Focused and regression gates:**

- focused `test_track_geometry_resolver.gd`, `test_grid_track_runtime.gd`, and `test_warp_pair_system.gd`;
- full `run_all.gd`, still exactly `23` suites;
- all five integrations: session-shell, logical-track-field, track-train-input, track-train-app, and Warp Cargo;
- exact UID audit and `git diff --check`.

Every runner must pass. A changed Warp tick is accepted only when the Task 1 RED assertion proved its exact-knot cause and every unrelated fixture fact remains identical.

**Commit:** `feat: snap warp routes to exact cell centers`

**Reviews:** Specification review checks exact center, route ownership, locked impossibility, forecast neutrality, no correction, and exact hit order. Quality review checks deterministic sampling, tangent continuity, duplicate-knot handling, detached copies, legacy mode compatibility, and absence of generic spline architecture.

## 6. Task 2: Slow Domain Simulation During Valid Planning

**Objective:** Keep input and live route candidates at full physics frequency while running-domain systems advance deterministically at the configured percentage.

**Modify:**

- `godot-project-moe-rail-way/src/config/session_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/data/session_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_session_controller.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`

**RED:** Require ordinary failures for:

- default `25`, inclusive `10..100` validation, owner-qualified errors, and copied runtime isolation;
- four active planning real ticks producing one simulation tick at `25` while each input frame can update the live route candidate;
- train distance, construction, transactional recovery, Warp forecast/lifetime/generation, and session elapsed ticks changing only on the one due simulation tick;
- no slowdown for invalid presses, off-endpoint presses, stale held capture, or `PREPARING_DEPARTURE`;
- no accumulated catch-up after release, right-abort, train-safety termination, or completion;
- the accepted press tick publishing planning active, configured `25`, and `did_advance_simulation_tick = true`, followed by the literal three skipped and one due held-tick sequence;
- skipped real-tick snapshots reporting active planning, `25`, `did_advance_simulation_tick = false`, current candidate geometry, and an empty Warp event array;
- a due planning tick reporting `did_advance_simulation_tick = true` and preserving the existing Warp/contact/expiry/session priority;
- Task 1's guard that a due-tick Warp activation or anchor removal evolves both gesture origin and live candidate, with later preview, abort, and finalize preserving the elapsed authoritative anchor lifecycle;
- recovery removing the same eligible pre-gesture cells from the evolving origin and live candidate, refunding once, preserving new suffix cells, and preventing an abort from resurrecting recovered track;
- a pure staged-recovery failure fixture returning no commit candidate and leaving origin, candidate, ledgers, frontier, and inventory unchanged, plus a subprocess debug probe proving the public invariant owner asserts on that same failure without termination, partial mutation, or release-time batching.
- the real Warp Cargo scene reproducing the same literal four-real-ticks-to-one-simulation-tick cadence without changing fixture RNG, route, cargo, reward, or lifecycle values.

The cadence fixtures must declare the expected real-tick/simulation-tick sequence literally. They may use `did_advance_simulation_tick()` only as an asserted observation, never as the oracle that decides which domain values should have advanced.

**Minimum GREEN:** Add one integer accumulator inside `SessionController`; do not use `Engine.time_scale` or variable delta. Determine cadence from the gesture state at real-tick start, run the existing Warp-begin stage before input only when a simulation tick is due, consume input every real tick, and publish an input-only snapshot when skipped. Extend current active-gesture construction handling to recovery with the same evolving-origin transaction and the design's one exact failure policy. Discard unused credit when planning ends; never loop to catch up.

**Focused and regression gates:**

- focused five modified unit suites;
- full `run_all.gd`, still exactly `23` suites;
- all five integration runners;
- exact UID audit and `git diff --check`.

**Commit:** `feat: slow running simulation during route planning`

**Reviews:** Specification review reconstructs a press, three skipped held real ticks, one due planning tick, release, and next normal tick, covering every named domain system and no catch-up. Quality review checks accumulator boundaries, input single-consumption, abort rollback, event non-repetition, transactional recovery, snapshot detachment, and no global time scaling.

## 7. Task 3: Present Planning and Dissolve the Departure Marker

**Objective:** Make the new planning state legible and remove the departure marker smoothly after departure without changing domain state.

**Create:**

- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_control_feel_presentation.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_control_feel_presentation.gd.uid`

**Modify:**

- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`

`test_track_train_app_composition.gd` is authorized only to add the two intended public render-observation keys to its exact schema assertion. It authorizes no production behavior or broader assertion changes.

**RED:** Register the new suite and require:

- opaque visible departure marker in `READY` and `PREPARING_DEPARTURE`;
- one-shot dissolve start on first `RUNNING` snapshot;
- alpha `1.0`, `0.5`, and `0.0` at `0.0`, `0.375`, and `0.75` real seconds within `0.0001`;
- no restart from later running snapshots and reset only on `configure_session`;
- route origin, selected departure facts, and train observations unchanged by dissolve;
- visible primitive `PLANNING 25%` only for an active running slowdown snapshot;
- indicator clear on release, abort, train-safety termination, non-running state, and completion;
- departure dissolve and planning indicator update on real presentation time during skipped simulation snapshots;
- `get_render_observation()` publishing detached `departure_marker` and `planning_indicator` Dictionaries with exact `visible`/`alpha` and `visible`/`text` keys;
- indicator input pass-through in automation, with top-left readability, contrast, and non-overlap owned by the four-size Windows manual checklist; automation must not assert backing color, opacity, size, padding, or placement, and must not add those details to the render observation;
- the real Warp Cargo scene exposing the departure alpha and `PLANNING 25%` observations while the Task 2 domain cadence remains green.

**Minimum GREEN:** Add concrete view-local alpha, one-shot transition state, real `_process(delta)` advancement, and primitive indicator drawing. Reuse the fallback font and current logical transform. Add only the corresponding real-scene integration assertions and extend the manual checklist with explicit mouse steps for an anchored straight, an anchored curve, locked impossible contact, departure dissolve, responsive full-frequency preview, four-to-one domain cadence, transactional recovery, release without catch-up, and planning indicator behavior at all four supported sizes. Do not add textures, animation assets, tweens that depend on global time scale, presentation-to-domain calls, or scene-tree-wide state.

**Regressions:**

- focused new suite;
- full `run_all.gd`, expected `PASS: 24 prototype test suite(s)`;
- all five integration runners;
- supported resize unit/integration checks and `git diff --check`.

**Commit:** `feat: present warp planning control feedback`

**Reviews:** Specification review checks real-time dissolve and exact planning visibility. Quality review checks redraw/process lifecycle, repeated-snapshot idempotence, input pass-through, resize mapping, observation detachment, and no presentation-owned gameplay decisions.

## 8. Task 4: Reuse the Recovered Departure Coordinate

**Objective:** Fix the manual-play failure in which a valid endpoint drag was silently rejected after Warp snapping because its next cell was the already recovered departure coordinate.

**Modify:**

- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`

**RED:** Reproduce the observed route contract with departure `(5, 2)`: build and recover a prefix, retain an active endpoint at `(6, 2)`, then perform an endpoint gesture through `(5, 2)` to the recovered `(4, 2)` cell. Require legal-operation discovery, the live candidate, and finalize to retain both cells without `locked_overlap`. Capture the source locked piece identity, complete footprint, full centerline, active sampling interval, and unrecovered ownership before the gesture and require them unchanged afterward. Add the opposite candidate fixture against an unrecovered cell of that same partially recovered locked piece and require deterministic `locked_overlap`; retain the existing resolver regression that blocks a suffix entering a non-record curve-footprint cell. Together these prove that only exact cells in the recovered map are released rather than disabling or shrinking the whole piece as a blocker. At the sequence layer, require the departure coordinate to remain rejected before recovery, become reservable only after the active predecessor advances beyond it, consume one inventory cell with a fresh route serial and absolute nominal distance, remain subject to active-cell uniqueness, and become temporarily reserved again when a reused departure record itself becomes the active predecessor boundary after recovery. Cover both append and in-place replacement before and after that recovery boundary. With an exact Warp on the reused coordinate, require contact observation to select the active record occurrence and its fresh midpoint distance; without an active record there, retain the free-origin `0.0` behavior.

The expected eligibility transition must be asserted from literal cells, route records, inventory counts, and recovery operations. Tests may inspect the sequence's concrete records but may not add a policy flag, train-state dependency, or mock recovery service.

**Minimum GREEN:** Replace the permanent departure-coordinate blacklist with the concrete active-predecessor rule already owned by `TrackCellSequence`. Apply the same rule to append, in-place span replacement, and runtime legal-operation discovery. In exact-anchor lookup, prefer an active record that owns the departure coordinate and otherwise retain the free-origin occurrence. Before runtime resolution, clone the locked ledger and erase only exact cells named by each piece's recovered-cell map from the clone's blocking footprint. Do not mutate or shrink the source ledger footprint, centerline, active sampling interval, or identity, and do not release non-record curve-footprint cells. Do not change route distance origin, departure presentation, Warp geometry, recovery cadence, unrecovered overlap validation, inventory values, or train behavior.

**Regressions:**

- focused `test_track_cell_sequence.gd`, `test_track_geometry_resolver.gd`, and `test_grid_track_runtime.gd`;
- full `run_all.gd`, still exactly `PASS: 24 prototype test suite(s)`;
- all five integration runners;
- exact UID audit and `git diff --check`.

**Commit:** `fix: allow recovered departure cell reuse`

**Reviews:** Specification review checks the pre-recovery prohibition, post-recovery eligibility, immediate predecessor boundary, unchanged distance origin, and exact captured gesture. Quality review checks a single source of truth for eligibility, append/replacement consistency, monotonic identity, inventory conservation, transactional rejection, and absence of train or Warp coupling.

## 9. Task 5: Stitch an Exact First Turn After a Locked Endpoint

**Objective:** Fix the reproduced manual-play failure in which an exact Warp cell publishes after a fully locked endpoint but the next held cell is dropped because the anchored first-turn successor is not stitched to that endpoint.

**Modify:**

- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`

**RED:** Reproduce the observed departure `(5, 2)` route through `(5, 7)`, `(6, 7)`, and the locked vertical endpoint `(7, 3)`, with an exact Warp at `(7, 2)`. Lock every existing piece through the endpoint, begin a legal held gesture, and require the literal live paths `[(7, 2)]`, `[(7, 2), (6, 2)]`, and `[(7, 2), (6, 2), (5, 2)]` to publish in order and finalize with endpoint `(5, 2)`. Capture every piece already present in the locked ledger and require that locked prefix byte-unchanged after every update and finalize; finalization may append the newly accepted successor through the existing stable-retirement contract. At the resolver layer, require the unlocked anchored `CURVE_1X1` successor to stitch its first point to the locked predecessor endpoint by using its declared entry-heading override while retaining the exact `(7, 2)` center knot, owned serial, footprint, nominal length, and remaining centerline samples. Add the opposite sideways/backward-gap fixture and require it to remain unstitched and invalid. The ordinary locked straight-extension and locked-geometry impossibility fixtures remain unchanged.

**Minimum GREEN:** In the existing locked-predecessor stitch predicate, compare the boundary gap with the predecessor's canonical exit heading and the successor's canonical entry heading so existing heading overrides are honored. Continue changing only the unlocked successor's first centerline point. Do not loosen the tangent epsilon, mutate locked pieces, alter curve construction, move an exact knot, change template selection, bypass overlap validation, or add Warp-specific branching to the geometry resolver.

**Regressions:**

- focused `test_track_geometry_resolver.gd` and `test_grid_track_runtime.gd`;
- full `run_all.gd`, still exactly `PASS: 24 prototype test suite(s)`;
- all five integration runners;
- exact UID audit and `git diff --check`.

**Commit:** `fix: stitch anchored turns after locked endpoints`

**Reviews:** Specification review checks the literal reproduced gesture, immutable locked predecessor, exact Warp knot, full suffix, and non-forward rejection. Quality review checks canonical heading use, epsilon preservation, successor-only mutation, deterministic continuity, and absence of Warp coupling or geometry abstraction.

## 10. Final Automated and Manual Evidence Gate

After Task 5 and its reviews, run the complete gate without changing files:

- full `run_all.gd`, exact `PASS: 24 prototype test suite(s)`;
- `run_session_shell_integration.gd`;
- `run_logical_track_field_integration.gd`;
- `run_track_train_input_integration.gd`;
- `run_track_train_app_integration.gd`;
- `run_warp_cargo_integration.gd`, exact `PASS: warp cargo integration`;
- exit `0`, every required PASS marker, no rejected anchored diagnostics;
- feature changed-path union audit, `.gd.uid` one-to-one audit, and `git diff --check`.

Then run the Task 3, Task 4, and Task 5 manual checklist at `960x540`, `1280x720`, `1600x900`, and `1920x1080` on the exact reviewed implementation head. The user verifies each state and reports pass/fail. Keep screenshots and completed evidence outside the repository; the tracked manual file contains instructions only. A failed automated or manual row returns to the owning Task 1, 2, 3, 4, or 5 allowlist through an explicit review finding. The evidence gate itself creates no commit and cannot manufacture a test-only RED.

Integration expected positions, knot distances, tick indices, and four-to-one cadence remain hard-coded fixture facts. Do not derive an expected value by calling the same production method under test. The Windows user observation is the independent visual and control-feel check rather than a substitute for deterministic assertions.

## 11. Task Allowlist Summary

No task may change a path outside its section. The complete implementation union is the exact union of Task 1 through Task 5 paths. The three planning documents belong only to the focused documentation commit and never enter an implementation task commit.

Before each task commit:

1. Require `git diff --cached --name-only` to be empty.
2. Reject renames and deletions.
3. Compare unstaged, staged, and untracked paths with the literal task allowlist.
4. Stage only `git add -- <literal paths>`.
5. Compare the sorted staged list with the sorted changed allowlist subset.
6. Run `git diff --cached --check`, inspect the stat, and inspect the full staged diff.

An unexpected path stops the task. Do not absorb it into the nearest allowlist.

## 12. Final Feature Gate and Stop Point

After Task 5, the evidence gate, and any reviewed allowlisted fixes:

1. Require clean `feature/warp-cargo` at the reviewed final head and unchanged approved merge base.
2. Require protected primary `main` to remain clean and exactly equal to current `origin/main`.
3. Audit the complete feature diff against the parent Warp Cargo allowlist, this plan's implementation union, and these six exact separately approved planning paths:
   - `docs/superpowers/specs/2026-08-28-warp-cargo-design.md`
   - `docs/superpowers/plans/2026-08-28-warp-cargo.md`
   - `docs/briefings/ko/2026-08-28-warp-cargo-design-plan-briefing.md`
   - `docs/superpowers/specs/2026-08-28-warp-cargo-control-feel-amendment-design.md`
   - `docs/superpowers/plans/2026-08-28-warp-cargo-control-feel-amendment.md`
   - `docs/briefings/ko/2026-08-28-warp-cargo-control-feel-amendment-briefing.md`
4. Require the complete automated and manual evidence from Section 10 to be current for the exact head.
5. Obtain final independent specification and quality approvals against that exact head and evidence.
6. Report commits, tests, manual result, changed-path audit, and residual risks.

Stop there. Push, pull request, merge, tag, primary fast-forward/retest, and feature cleanup each require separate user authorization.
