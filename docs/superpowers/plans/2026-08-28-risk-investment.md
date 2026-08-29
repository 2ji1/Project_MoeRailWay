# Risk & Investment Implementation Plan

**Date:** 2026-08-28

**Status:** Approved for implementation

**Target branch:** `feature/risk-investment`

**Verified integration base:** `52fc157a36bad4bd8b758928ba90f7b776e106d8`

**Canonical design:** `docs/superpowers/specs/2026-08-28-risk-investment-design.md`

## 1. Execution Contract

This plan implements the approved Risk & Investment prototype as six focused tasks. Gameplay implementation must not begin until the English design, this plan, and the Korean briefing have passed independent specification and quality review and the user has explicitly approved the reviewed documents.

Every implementation task uses this immutable order:

1. write and run the deterministic RED test;
2. implement the minimum GREEN behavior;
3. run focused and required regression tests;
4. compare all changes with the task's literal file allowlist;
5. stage only exact task paths;
6. create one focused commit;
7. obtain an independent specification review of that commit;
8. obtain an independent quality review of that commit.

A review fix uses the same RED, GREEN, regression, allowlist, exact staging, focused commit, and two-review sequence. Do not combine tasks, pre-build later abstractions, or move an unresolved failure into a later task.

## 2. Preconditions and Stop Rules

Before the documentation commit and again before every gameplay task:

- confirm this worktree is the only worktree attached to `feature/risk-investment`;
- confirm the feature merge base is the approved `52fc157a36bad4bd8b758928ba90f7b776e106d8` base unless a separately approved main-first refresh occurred;
- confirm the feature worktree has no changes outside the current task allowlist and has an empty index;
- confirm primary `D:\godot\MoeRailWay` is a clean `main` exactly aligned with current `origin/main`;
- fetch before making any claim about remote alignment;
- stop without stash, reset, rebase, cleanup, copying, or absorption if any gate differs.

The prerequisite Warp Cargo mouse-only checklist is already approved on the exact base at `960x540`, `1280x720`, `1600x900`, and `1920x1080`; its evidence remains outside the repository. A later Risk failure must not be hidden as a Warp or grid correction inside this feature.

## 3. Documentation Gate

**Create:**

- `docs/superpowers/specs/2026-08-28-risk-investment-design.md`
- `docs/superpowers/plans/2026-08-28-risk-investment.md`
- `docs/briefings/ko/2026-08-28-risk-investment-design-plan-briefing.md`

Review the three documents independently for specification coverage and implementation quality. After user approval, stage exactly these three paths and commit:

```text
docs: approve risk investment design and plan
```

No gameplay file belongs in this commit.

## 4. Task 1: Add Validated Session Cash

**Objective:** Introduce the provisional session-only cash authority and validated copied configuration without coupling it to Warp rewards or a future `RunState`.

**RED:** Register tests that fail because starting cash is absent, invalid values are not owner-qualified validation errors, copied start configuration is missing, and atomic insufficient-funds spending is unavailable. Prove that a rejected spend leaves a serialized economy observation byte-identical and that one accepted spend subtracts exactly once.

**Minimum GREEN:** Add one concrete `SessionCashBalance`, copy it into `SessionStartConfig`, validate `0..1,000,000`, and add one concrete `SessionEconomy` with read-only observation plus an atomic `try_spend(cost)` operation. Do not connect Warp reward, persistence, settlement, repair charging, purchases, or track actions yet.

**Regressions:** Run the focused economy and configuration suites, then the registered suite runner and all existing integration runners. Require the registered PASS marker, exit `0`, and no anchored script, error, fatal, or crash output.

**Literal file allowlist:** The following list is fixed before RED.

Create:

- `godot-project-moe-rail-way/src/config/session_cash_balance.gd`
- `godot-project-moe-rail-way/src/config/session_cash_balance.gd.uid`
- `godot-project-moe-rail-way/src/domain/economy/session_economy.gd`
- `godot-project-moe-rail-way/src/domain/economy/session_economy.gd.uid`
- `godot-project-moe-rail-way/data/session_cash_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_session_economy.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_economy.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Exact staging:** Verify the diff is a subset of the literal allowlist, stage those exact changed paths only, and inspect the cached diff.

**Focused commit:** Commit `feat: add provisional session cash`.

**Independent specification review:** Check lifetime, funding boundary, exact default/range, production Resource composition, copied configuration, canonical state boundary, and byte-unchanged rejection.

**Independent quality review:** Check integer safety, detached observations, test isolation, and absence of premature transaction or `RunState` abstractions.

## 5. Task 2: Add Seeded Hazards and Train Durability

**Objective:** Generate one stable deterministic hazard layout, damage the train by actual traveled route distance, expose repair-cost basis, and terminate once at zero durability.

**RED:** Prove fixed expected cells for fixed seeds, unique sampling without replacement, departure-only exclusion, Warp draw-sequence independence, stable layout, invalid count rejection, and no route-aware correction. Prove zero damage while stopped, proportional partial-cell damage, repeated damage on repeated visits, curve-distance damage, max/current durability, clamping, repair basis, same-sweep Warp delivery retention, durability completion priority, and one-shot terminal immutability.

**Minimum GREEN:** Derive `session_seed ^ 0x5249534B48415A44`, run the specified partial Fisher-Yates selection through a separate `SessionRng`, and retain one immutable ordered hazard set. Add one read-only route-distance clipping query using existing geometry. Extend `TrainSystem` with maximum/current durability. After `complete_session_start_config()`, run the validator's completed-configuration entry point before composing systems. Apply hazard damage after Warp contact from the same movement sweep. Add `DURABILITY_DEPLETED`, snapshot/result observations, and no repair settlement. Do not add cycle state, regeneration, scaling, reachability analysis, damage events from ownership alone, or presentation.

**Regressions:** Run focused hazard, train, route-query, and controller suites; all existing controller suites; the registered suite runner; and all existing integration runners.

**Literal file allowlist:** The following list is fixed before RED.

Create:

- `godot-project-moe-rail-way/src/config/hazard_generation_balance.gd`
- `godot-project-moe-rail-way/src/config/hazard_generation_balance.gd.uid`
- `godot-project-moe-rail-way/src/config/durability_balance.gd`
- `godot-project-moe-rail-way/src/config/durability_balance.gd.uid`
- `godot-project-moe-rail-way/src/domain/hazard/hazard_system.gd`
- `godot-project-moe-rail-way/src/domain/hazard/hazard_system.gd.uid`
- `godot-project-moe-rail-way/data/hazard_generation_balance.tres`
- `godot-project-moe-rail-way/data/durability_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_hazard_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_hazard_system.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_risk_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_risk_session_controller.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/domain/train/train_system.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_train_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_session_controller.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Exact staging:** Verify and stage only the literal allowlist's changed paths and inspect the cached diff.

**Focused commit:** Commit `feat: add seeded hazards and durability`.

**Independent specification review:** Reconstruct the exact seed derivation and partial shuffle, actual-distance damage, same-tick precedence, terminal clearing, and repair basis.

**Independent quality review:** Check RNG isolation, post-grid validation timing, direct geometry-query tests, float determinism, detached data, completion idempotence, and no cycle/route-correction scope creep.

## 6. Task 3: Add Paid Track Demolition

**Objective:** Preserve free ghost suffix cancellation while adding one atomic paid demolition for eligible front suffixes and retained traveled rear prefixes.

**RED:** First reproduce the exact right-click classifications. Prove active-gesture abort and `RESERVED_GHOST` suffix cancellation remain free and immediate on due and skipped ticks. Prove a skipped-tick `BUILDING`/`BUILT` click retains one exact route-serial request, ignores later field presses and repeated frames, cannot be retargeted by pointer motion, and is consumed exactly once on the next due tick. Prove due-tick `BUILDING` and `BUILT` front suffixes cost once, completed retained rear prefixes can be removed early for the same one-time cost, every removed active cell returns inventory, immutable locked history remains unchanged, train-containing and ambiguous spans are no-ops, completion clears a pending paid request, and insufficient cash leaves the canonical authoritative track/runtime/economy state byte-identical after dequeue.

**Minimum GREEN:** Classify immediate free actions separately from a paid route-serial request and retain at most one paid request across skipped ticks. Duplicate the concrete sequence/runtime/economy owners, stage the complete demolition through existing ownership, recovery, geometry, construction, and ledger rules, validate the canonical post-state and precomputed post-spend cash, then install those validated copies through non-rejecting task-local replacement methods in one controller call. Keep right-click priority exact and do not globally loosen occupancy, collision, footprint, or reservation rejection.

**Regressions:** Run focused demolition, reservation, construction/recovery, runtime, economy, and controller suites; the registered suite runner; and all integration runners.

**Literal file allowlist:** The following list is fixed before RED.

Create:

- `godot-project-moe-rail-way/src/config/track_investment_balance.gd`
- `godot-project-moe-rail-way/src/config/track_investment_balance.gd.uid`
- `godot-project-moe-rail-way/data/track_investment_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_track_system_demolition.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_demolition.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/economy/session_economy.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_economy.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- `godot-project-moe-rail-way/tests/unit/test_risk_session_controller.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Exact staging:** Verify and stage only the literal allowlist's changed paths and inspect the cached diff.

**Focused commit:** Commit `feat: add paid track demolition`.

**Independent specification review:** Check free versus paid classification, prefix/suffix boundaries, one charge, full inventory return, and forbidden train removal.

**Independent quality review:** Check economy staged-copy installation, pending paid-request retention/clearing, canonical byte comparison, ledger invariants, existing ownership reuse, deterministic target selection, and exact no-op behavior.

## 7. Task 4: Add Non-Branching Grade-Separated Crossings

**Objective:** Permit a later perpendicular route occurrence through an occupied cell without branch/merge semantics and charge the shared major-track-action cost per finalized crossing.

**RED:** Prove that only a complete perpendicular opposite-side traversal qualifies. Cover parallel overlap, stop-on-cell, U-turn, diagonal, tangent, branch-like, and unaffordable rejection with canonical byte-identical state and cash. Prove preview backtracking and abort are free, finalize charges once per crossing, route order remains single and serial-monotonic, both ordered occurrences sample correctly, hazard damage follows each actual pass, and exact-center Warp contact can occur on a later crossing occurrence even after an earlier occurrence is behind the train. After construction, calculate pointer distance against canonical centerlines and prove `abs(a - b) <= 0.01` is a no-op while the strictly smaller distance selects horizontal or vertical occurrence. Prove selected ghost free cancellation, selected built paid prefix/suffix demolition, and retained crossing-occurrence identity across a skipped tick.

**Minimum GREEN:** Represent repeated occupied-cell occurrences in the existing ordered sequence and geometry model. Extend detached contact observation with ordered `contact_distances_cells` while retaining the earliest scalar for compatibility. Build and validate one staged route/economy candidate for the entire final gesture and install it through the concrete non-rejecting commit protocol. Select a crossing occurrence by shortest pointer-to-rendered-centerline distance with the specified tie threshold. Draw a primitive over/under gap without changing old locked geometry or adding graph traversal.

**Regressions:** Run focused crossing, sequence, geometry, route sampling, Warp, presentation, controller, and economy suites; the registered suite runner; and all integration runners. Re-run the Warp exact-center deterministic integration because contact multiplicity changes its observation surface.

**Literal file allowlist:** The following list is fixed before RED.

Create:

- `godot-project-moe-rail-way/tests/unit/test_track_system_crossing.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_crossing.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_record.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolution.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_system.gd`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_demolition.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_presentation.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Exact staging:** Verify and stage only the literal allowlist's changed paths and inspect the cached diff.

**Focused commit:** Commit `feat: add grade separated crossings`.

**Independent specification review:** Check every legality condition, no branch/merge behavior, shared cost, multi-crossing charging, crossing-cell demolition targeting, repeated hazard traversal, and exact Warp contact.

**Independent quality review:** Check representation invariants, immutable history, staged commit, compatibility fields, gesture rollback, deterministic pointer targeting, visual input pass-through, and absence of graph abstractions.

## 8. Task 5: Add Temporary Track and Cargo Purchases

**Objective:** Spend provisional cash on bounded session-only capacity increments that disappear on every end path without refund.

**RED:** Prove exact defaults, limits, costs, increments, monotonically appended cargo slots, lowest-empty-slot compatibility, unchanged train speed/length/recovery, and purchase disablement during a field gesture. Prove first-edge chronological arbitration across paid demolition, track purchase, cargo purchase, and repeated clicks; one shared transient pending priced-action slot; skipped-tick retention; and due-tick consumption. Prove insufficient funds and exceeded limits leave canonical cash/capacity state byte-identical after dequeue. Prove regular expiry, track end, and zero durability end all discard authority and never refund costs; a fresh session returns to base capacities.

**Minimum GREEN:** Add validated cargo investment configuration and the remaining track purchase fields. Extend the existing transient paid-demolition slot into one shared first-edge priced-action slot outside authoritative domain state. On a due planning tick, duplicate the affected capacity owner and economy, validate the complete candidate and post-spend cash, and install the concrete copies through the non-rejecting commit protocol. Keep all increments session-local and use snapshot/result values only as detached evidence.

**Regressions:** Run focused purchase, economy, track, cargo, configuration, and controller suites; the registered suite runner; and all integration runners.

**Literal file allowlist:** The following list is fixed before RED.

Create:

- `godot-project-moe-rail-way/src/config/cargo_investment_balance.gd`
- `godot-project-moe-rail-way/src/config/cargo_investment_balance.gd.uid`
- `godot-project-moe-rail-way/src/domain/session/session_investment_input.gd`
- `godot-project-moe-rail-way/src/domain/session/session_investment_input.gd.uid`
- `godot-project-moe-rail-way/data/cargo_investment_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_session_investment_purchases.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_investment_purchases.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/config/track_investment_balance.gd`
- `godot-project-moe-rail-way/src/domain/cargo/cargo_system.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/data/track_investment_balance.tres`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_cargo_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- `godot-project-moe-rail-way/tests/unit/test_risk_session_controller.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Exact staging:** Verify and stage only the literal allowlist's changed paths and inspect the cached diff.

**Focused commit:** Commit `feat: add temporary capacity purchases`.

**Independent specification review:** Check all prices, increments, limits, input arbitration, lifetime, no-refund behavior, and gesture exclusion.

**Independent quality review:** Check production Resource composition, overflow validation, slot identity, staged atomicity, end-path idempotence, and no persistent-upgrade abstraction.

## 9. Task 6: Add Placeholder Presentation and End-to-End Evidence

**Objective:** Make hazard, durability, cash, affordability, demolition, crossing, and purchase state readable in the real Windows scene and prove the complete feature.

**RED:** Register presentation assertions before implementation. Require hazard identification by fill plus repeated primitive mark/border, current/max durability, repair basis, session cash, disabled unaffordable actions, exact purchase counts/capacities, free-versus-paid right-click feedback, crossing preview/cost, one zero-durability result, nonintercepting overlays, and resize-safe mouse mapping. The deterministic real-scene runner must cover one fixed layout, partial and repeated hazard travel, free ghost cancellation, one paid demolition, one crossing, both purchase types, an insufficient-funds byte-unchanged rejection, Warp interaction, and every end-path cleanup contract.

**Minimum GREEN:** Extend existing field and shell presentation with placeholder colors, shapes, outlines, text, and ordinary buttons. Bind only detached snapshot state and existing input surfaces. Do not add custom art, textures, imported icons, custom fonts, animation systems, audio, mobile controls, or domain mutations in presentation.

**Regressions:** Run the focused presentation suite, the complete registered suite runner, the new Risk integration, and every existing integration runner. Require exact PASS markers and clean exits.

**Windows regression verification:** On the exact Task 6 implementation state, run deterministic and mouse-only checks at `960x540`, `1280x720`, `1600x900`, and `1920x1080`. Verify layout identity for the fixed seed, hazard readability, actual-distance durability loss, one-shot zero-durability end, cash and affordability feedback, free ghost suffix cancellation, paid front/rear demolition, non-branching crossing construction and traversal, Warp contact on crossing occurrences, both temporary purchases, input pass-through, and no refund on all end paths. Store commit, Godot version, seed, rows, tester confirmation, and screenshots outside the repository. Never mark an unconfirmed mouse-only row PASS.

**Literal file allowlist:** The following list is fixed before RED.

Create:

- `godot-project-moe-rail-way/tests/fixtures/risk_investment_balance.tres`
- `godot-project-moe-rail-way/tests/integration/risk_investment_app.tscn`
- `godot-project-moe-rail-way/tests/integration/run_risk_investment_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_risk_investment_integration.gd.uid`
- `godot-project-moe-rail-way/tests/manual/risk_investment_windows.md`
- `godot-project-moe-rail-way/tests/unit/test_risk_investment_presentation.gd`
- `godot-project-moe-rail-way/tests/unit/test_risk_investment_presentation.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.tscn`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- `godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd`
- `godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`
- `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Exact staging:** Verify and stage only the literal allowlist's changed paths and inspect the cached diff.

**Focused commit:** Commit `feat: present risk investment prototype`.

**Independent specification review:** Check every visible contract, exact crossing occurrence highlight, the four-resolution evidence, and exclusions.

**Independent quality review:** Check layout scaling, mouse mapping, deterministic fixture isolation, presentation/domain separation, input pass-through, and absence of custom assets.

## 10. Exact-Path Staging Guard

For every task, define `$MoeRailTaskPaths` as the literal Create/Modify list in that task and run the following equivalent guard from this dedicated worktree:

```powershell
$MoeRailFeature = 'C:\Users\noisy\.codex\worktrees\46df\MoeRailWay'

function Invoke-MoeRailGitLines([string[]]$Arguments) {
    $Output = @(& git -C $MoeRailFeature @Arguments)
    if ($LASTEXITCODE -ne 0) {
        throw "git failed: $($Arguments -join ' ')"
    }
    return $Output
}

$MoeRailInitiallyStaged = @(Invoke-MoeRailGitLines @('diff', '--cached', '--name-only'))
if ($MoeRailInitiallyStaged.Count -ne 0) {
    throw 'The index must be empty before task-local staging.'
}

$MoeRailChanged = @(
    Invoke-MoeRailGitLines @('diff', '--name-only')
    Invoke-MoeRailGitLines @('ls-files', '--others', '--exclude-standard')
) | Sort-Object -Unique

$MoeRailForbidden = @(
    Invoke-MoeRailGitLines @('diff', '--name-status', '--diff-filter=DR')
    Invoke-MoeRailGitLines @('diff', '--cached', '--name-status', '--diff-filter=DR')
)
if ($MoeRailForbidden.Count -ne 0) {
    throw "Renames and deletions are not authorized: $($MoeRailForbidden -join ', ')"
}

$MoeRailUnexpected = @($MoeRailChanged | Where-Object { $_ -notin $MoeRailTaskPaths })
if ($MoeRailUnexpected.Count -ne 0) {
    throw "Unexpected worktree paths: $($MoeRailUnexpected -join ', ')"
}

git -C $MoeRailFeature add -- $MoeRailTaskPaths
if ($LASTEXITCODE -ne 0) { throw 'Exact-path staging failed.' }

$MoeRailStaged = @(Invoke-MoeRailGitLines @('diff', '--cached', '--name-only')) | Sort-Object -Unique
$MoeRailExpected = @($MoeRailTaskPaths | Where-Object { $_ -in $MoeRailChanged }) | Sort-Object -Unique
if (Compare-Object $MoeRailExpected $MoeRailStaged) {
    throw 'The staged paths do not exactly match the task allowlist.'
}

git -C $MoeRailFeature diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'The staged diff failed whitespace validation.' }
git -C $MoeRailFeature diff --cached --stat
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the staged stat.' }
git -C $MoeRailFeature diff --cached
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the staged diff.' }
```

No task authorizes renames or deletions. Stop if either appears. Documentation paths are excluded from gameplay commits unless a separately approved documentation amendment names them.

## 11. Determinism and Automated Gate

After every task, record the exact commit and commands outside the repository. The final automated gate requires:

1. clean `feature/risk-investment` and exact expected primary/remote alignment;
2. complete feature diff contained in the union of approved allowlists;
3. `git diff --check` on the feature range;
4. exactly one tracked `.gd.uid` sidecar per tracked GDScript and no orphan sidecar;
5. the registered unit/smoke runner with its current expected PASS marker;
6. every pre-existing standalone integration runner;
7. the new Risk & Investment integration runner;
8. explicit fixed-seed repeat runs that compare hazard cells, route/crossing observations, cash, durability, purchases, terminal snapshot, and result byte-for-byte;
9. exit `0`, all anchored PASS markers, and no anchored error, warning, fatal, script-error, or crash output.

Do not substitute automation for the final Windows mouse-only rows.

## 12. Final Feature Gate and Main-First Transition

On the exact final feature commit:

1. repeat all automated and four-resolution manual gates;
2. obtain final independent specification approval against the canonical design and evidence;
3. obtain final independent quality approval against the complete diff, commits, tests, UID audit, and evidence;
4. inspect focused commit order and verify no unapproved path or scope;
5. fetch and revalidate the clean primary, `origin/main`, merge base, ahead/behind, upstreams, and all worktrees.

If every gate passes and remote/primary remain exact, follow `AGENTS.md`: push the feature branch, open a pull request to `main`, and merge with a merge commit only. Then fast-forward primary `main`, rerun the full automated gate on the merge commit, and perform only the authorized feature worktree/branch cleanup. If primary becomes dirty or the remote advances, stop and report evidence without trying to repair state automatically.

## 13. Explicit Deferrals

- `RunState` cash is the third later economy step, not part of this feature.
- Cycle state, cycle-based hazard regeneration, density scaling, and damage scaling are deferred.
- Warp base reward remains a non-spendable observation.
- Repair settlement and durability restoration are deferred.
- Contract Economy, Credit Survival, persistence, permanent upgrades, final art/audio, and production abstraction are deferred.

These items must not appear as convenience scaffolding in any implementation task.
