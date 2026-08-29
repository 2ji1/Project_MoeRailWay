# Warp Exact-Center Local-Corner Geometry Implementation Plan

- Date: 2026-08-29
- Status: Approved for execution
- Feature branch: `feature/warp-exact-center-local-corners`
- Verified base: `877b3dadd710abc44ea3602b530d854dd215a665`
- Canonical design: `docs/superpowers/specs/2026-08-29-warp-exact-center-local-corners-design.md`
- Stop point: merged remote `main`, synchronized and tested local `main`, and completed feature cleanup; manual visual rows remain user-owned and `PENDING`

## 1. Fixed Allowlist

Documentation commit:

- `.claude/ballast.rules.json`
- `docs/superpowers/specs/2026-08-29-warp-exact-center-local-corners-design.md`
- `docs/superpowers/plans/2026-08-29-warp-exact-center-local-corners.md`
- `docs/briefings/ko/2026-08-29-warp-exact-center-local-corners-briefing.md`

Implementation commits:

- `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`

No other path may change. No GDScript or UID sidecar is created. Risk & Investment and every unrelated worktree remain untouched. The project rule catalog is allowed only for the user-approved `all-track-curves-local-corners` entry.

## 2. Gate Rules

1. Keep `D:\godot\MoeRailWay` clean on `main` and equal to `origin/main` throughout the feature.
2. Preserve the rejected B branch and do not cherry-pick, revert, or rewrite it.
3. Commit the three documentation paths before any implementation path changes.
4. Every behavior task follows deterministic RED, minimum GREEN, focused regression, exact-path staging, and a focused commit.
5. A RED is valid only when its intended assertions fail on the unchanged production baseline without parser, preload, warning, fatal, or crash diagnostics.
6. Use Godot `4.7.1.stable.official.a13da4feb` at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`.
7. A focused suite runs through `res://tests/run_all.gd -- --suite=<file>` and must print `PASS: 1 prototype test suite(s)` at GREEN.
8. The full suite must print exactly `PASS: 24 prototype test suite(s)`, exit `0`, and contain no anchored `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, or `CRASH:` line.
9. Preserve exactly one tracked adjacent `.gd.uid` for every tracked GDScript.
10. Manual visual acceptance remains `PENDING` until the user reports it directly.

## 3. Task 1: Commit the Approved Contract

Create only the three documentation files in the documentation allowlist. Verify language placement, internal links, base and branch facts, rejected-experiment status, implementation allowlist, manual ownership, and `git diff --check`.

Stage exact paths and commit:

```text
docs: define exact-center local corner geometry
```

## 4. Task 2: Standardize Centerline Queries

### RED

Modify only `test_track_geometry_resolver.gd` and `test_grid_track_runtime.gd`.

Require the proposed `TrackGeometryPiece` query surface and prove:

- a target on the interior of a stored segment resolves to the correct earliest uniform nominal distance;
- repeated or zero-length segments do not displace an earlier match;
- a nonmatching target returns `-1.0`;
- exact unlocked, exact compatible-locked, and exact impossible-locked observations retain their accepted distances and outcomes;
- active nominal-range cell coverage respects the supplied eight subdivisions and active slice;
- all standard `CELL_ENTRY` fixture observations agree with a full swept hit over the same active route.

Run the two focused suites. Record the intended missing-query assertions as RED.

### Minimum GREEN

Modify only `track_geometry_piece.gd`, `track_geometry_resolver.gd`, and `grid_track_runtime.gd`.

- Add `find_nominal_distance_at_position()` and `contacts_cell_in_nominal_range()` to `TrackGeometryPiece`.
- Preserve `contacts_cell()` byte behavior and its spatial cadence.
- Make resolver exact-center validation delegate to the projection query.
- Make runtime exact observation delegate to the same projection query after record occurrence, recovered-cell, and active-range policy.
- Replace the active-contact hardcoded `8.0` with `CONTACT_SAMPLES_PER_CELL` through the new nominal-range query.
- Add a separate exact-position epsilon and retain public `NOMINAL_BOUNDARY_EPSILON` for nominal comparisons.

Run both focused suites and the full registered suite.

Stage exact Task 2 paths and commit:

```text
refactor: standardize track centerline queries
```

## 5. Task 3: Generate Local-Corner Anchored Curves

### RED

Modify only `test_track_geometry_resolver.gd`.

Add all-eight-orientation fixtures for anchored `1x1`, `2x2`, and the previously excessive `3x3`. Require:

- the anchored owner retains the unanchored baseline kind, span, and footprint;
- the excessive fixture remains `CURVE_3X3`, rather than using the rejected B downgrade;
- every exact center is at `(record_offset * 16) + 8`;
- each result contains `nominal_length_cells * 16 + 1` points;
- entry and exit headings remain authoritative;
- samples outside fixed local corner windows are collinear straight runs;
- every curvature or reverse-direction excursion is confined to a local half-cell window;
- all interior samples stay inside the footprint or the existing departure lead-in exception;
- replay is byte-identical and every serial has one owner;
- straight baseline digests stay unchanged; this task predates and is superseded by the Warp-independent generalization in Section 9 for unlocked unanchored curves.

Run the resolver focused suite and record only the intended locality and retained-kind failures.

### Minimum GREEN

Modify only `track_geometry_resolver.gd`.

- Name the fixed nominal sampling constants and derive exact midpoint indices from them.
- Replace the anchored owner-wide cubic with ordered skeleton knots, bounded endpoint supports, linear fill, quadratic support fillets, and exact-knot local cubic halves from the canonical design.
- Keep exact knots literal and preserve fixed output count and heading overrides.
- Retain existing footprint validation and candidate retry rules.
- Add no visual downgrade score, Warp-ID branch, Resource, generic spline class, or arc-length table.

Run the resolver focused suite, both Task 2 focused suites, and the full suite.

Stage exact Task 3 paths and commit:

```text
fix: localize exact-center curve bends
```

## 6. Task 4: Presentation and Manual Procedure

### RED

Modify only `test_track_field_view_input.gd`.

Present the accepted excessive `3x3` exact-anchor fixture and require detached one-cell interval samples to:

- retain the literal exact center;
- contain the expected local bend at one-eighth nominal render cadence;
- keep distant samples collinear on straight runs;
- preserve interval count, route serial, state, lock flag, and detachment.

If the current production result already satisfies any individual characterization assertion, retain that assertion as regression evidence; RED must come from the new local-shape requirement.

### GREEN and Manual Checklist

Production presentation code should remain unchanged. If the RED requires presentation production changes, stop and amend the design before proceeding.

Update only `tests/manual/warp_cargo_windows.md` with the four-resolution local-corner checklist and explicit user-owned result field. Run the focused presentation suite and full registered suite.

Stage exact Task 4 paths and commit:

```text
test: cover exact-center local corner presentation
```

## 7. Final Automated Gate

Run:

- `res://tests/run_all.gd`;
- `res://tests/integration/run_session_shell_integration.gd`;
- `res://tests/integration/run_logical_track_field_integration.gd`;
- `res://tests/integration/run_track_train_input_integration.gd`;
- `res://tests/integration/run_track_train_app_integration.gd`;
- `res://tests/integration/run_warp_cargo_integration.gd`.

For every process, inspect exit code, exact PASS marker, and anchored error diagnostics. Then run:

- `git diff --check`;
- exact changed-path union audit against Section 1;
- tracked GDScript/UID one-to-one audit;
- primary and unrelated-worktree status audit;
- staged and committed diff inspection.

Perform specification and quality reviews against the canonical design. Do not claim those reviews are independent unless a separate reviewer actually performs them. Resolve findings only inside the fixed allowlist and rerun the affected focused and final gates.

Report documentation and implementation SHAs, test evidence, changed paths, residual risks, and `MANUAL: PENDING (user-owned)`. Stop without push, PR, merge, tag, primary update, branch cleanup, Risk & Investment changes, or automatic manual acceptance.

## 8. Approved Follow-up: Adjacent-Turn Asymmetric Downgrade

The user approved correcting the `1280x720` mouse finding after deterministic diagnosis. Keep the existing branch and fixed allowlist; do not absorb `feature/warp-reservation-anchor-correction` or Risk & Investment.

### Documentation

Update and commit only the three documentation paths from Section 1 before implementation:

```text
docs: define adjacent-turn overlap fallback
```

### RED

Modify only `test_track_geometry_resolver.gd` and `test_grid_track_runtime.gd`.

- Build the exact `2x2` tail ending at `(10, 7)` from the screenshot diagnosis.
- Require both horizontal side extensions to publish, with the right target carrying an exact anchor.
- Require forward extension to remain valid.
- Require the resulting adjacent turns to use distinct `1x1` footprints, preserve exact contact, own every serial once, conserve inventory, and replay deterministically.
- Retain a genuinely irreducible overlap fixture that returns `final_overlap`.
- Run both focused suites and require only the new side-extension assertions to fail on unchanged production.

If Minimum GREEN makes an existing `final_overlap` runtime fixture publish, inspect rather than automatically preserving or deleting its old expectation. Reclassify it as a positive regression only when the final footprints are pairwise disjoint, every serial has one owner, the locked ledger is unchanged, inventory is conserved, and construction plus train sampling remain valid. Any fixture with a genuine final footprint overlap, locked conflict, duplicate cell, or broken ownership must remain rejected.

### Minimum GREEN

Modify only `track_geometry_resolver.gd`. In the existing pairwise overlap loop, reject only when both overlapping candidates are already radius `1`. Otherwise decrement each member whose radius is greater than `1` and repeat. Do not change footprint construction, locked conflict rules, anchor rules, sequence validation, or public APIs.

Run the resolver and runtime focused suites, the full registered suite, and all five standalone integrations. Inspect exit codes, exact PASS markers, and anchored diagnostics. Repeat every audit from Section 7, update the manual checklist with the left/right finding, and commit the implementation and test paths exactly:

```text
fix: allow adjacent local turn fallback
```

Stop at a clean committed feature HEAD with `MANUAL: PENDING (user-owned)`, then launch the `1280x720` mouse-manual window from that exact feature worktree.

## 9. Approved Follow-up: Warp-Independent Generalization and Integration

The user clarified that the approved straight-spine and local-corner visual rule applies to every unlocked `CURVE_1X1`, `CURVE_2X2`, and `CURVE_3X3`, not only curves with a Warp exact-center anchor. The user also approved feature publication, merge-commit integration, primary fast-forward, post-merge verification, and cleanup. This section supersedes the prior stop boundary and every earlier unanchored centerline byte-stability requirement.

### Documentation and Project Rule

Create the approved `all-track-curves-local-corners` project rule and amend the three canonical documentation paths before behavior changes. Commit only those four paths:

```text
docs: generalize local corner geometry
```

### RED

Modify only `test_track_geometry_resolver.gd`, `test_grid_track_runtime.gd`, and `test_track_field_view_input.gd`.

- Require unanchored `1x1`, `2x2`, and `3x3` curves in all eight orthogonal orientations to use `nominal_length_cells * 16 + 1` deterministic samples.
- Require endpoint headings, the straight interior spine, bounded local nonlinear runs, footprint containment, kind, span, ownership, nominal length, nonzero origin behavior, and replay determinism.
- Add a Warp-free `3x3` runtime and presentation fixture matching the reported visual class. Require the middle run to remain straight while both endpoint transition neighborhoods are visibly rounded at the existing one-eighth presentation cadence.
- Retain straight centerline bytes, locked curve bytes, exact-center hard knots, adjacent-turn asymmetric fallback, construction, recovery, and train-sampling contracts.
- Remove only the obsolete unlocked unanchored centerline digest expectations. Run the three focused suites and require failures only from the new fixed-count and local-shape assertions on unchanged production.

### Minimum GREEN

Modify only `track_geometry_resolver.gd`.

- Rename the anchored-only builder and footprint validator to describe their curve-wide authority.
- Call the common local-corner builder for every unlocked curve with zero or more exact knots; do not retain a legacy radius-based centerline branch.
- With no exact knot, use endpoint supports and the straight segment between them as the ordinary curve skeleton.
- With exact knots, preserve the current literal fixed-index centers and local exact-corner cubic halves.
- Validate every generated curve's interior samples against its footprint, with only the existing first-route departure lead-in exception.
- Preserve ownership selection, overlap fallback, locked ledger reuse, public APIs, nominal lengths, and deterministic ordering.
- Migrate the one full-suite consumer in `test_nominal_train_motion.gd` whose cross-owner spatial bound assumes the legacy sparse curve's endpoint rate. Derive the bound from each owner's actual stored boundary segment and the unchanged uniform-index nominal mapping, just as the runtime boundary regression does. This is a test-contract generalization, not arc-length reparameterization or a production motion change.

Run all three focused suites and the complete automated gate. Stage exact paths and commit:

```text
fix: generalize local corner geometry
```

### Review and Integration

Obtain separate specification and quality reviews of the final feature diff and evidence. Address every finding with focused commits and rerun affected gates. Keep every mouse-only row `PENDING` unless the user directly reports it.

After all automated and review gates pass:

1. verify the clean primary `main` still equals refreshed `origin/main` and the feature remains based on that first parent;
2. push the feature branch and open a pull request targeting `main`, recording canonical documents, task commits, RED/GREEN evidence, complete gates, review outcomes, and the pending manual rows;
3. merge automatically with a merge commit only and record its two parents;
4. refresh the protected primary, require its `HEAD` to equal the merge first parent, and fast-forward local `main` to the exact remote merge commit;
5. rerun the registered suite and all five standalone integrations in `D:\godot\MoeRailWay` with anchored diagnostic checks;
6. require the primary to remain clean and equal `origin/main`, then stop only agent-owned feature-project Godot processes, remove this feature worktree, and delete the local and remote feature branches;
7. do not tag, modify Risk & Investment, or change any legacy branch.

## 10. Approved Follow-up: Ordered-Route Spine Alignment

The user approved correcting the `960x540` mouse finding where an earlier route record owned `(11, 3)` but the generalized diagonal spine did not visibly enter that cell. This follow-up remains on `feature/reservation-live-candidate-diagnosis` and does not modify or absorb Risk & Investment, `feature/warp-reservation-anchor-correction`, or either protected worktree.

### Fixed Follow-up Allowlist

- `docs/superpowers/specs/2026-08-29-warp-exact-center-local-corners-design.md`
- `docs/superpowers/plans/2026-08-29-warp-exact-center-local-corners.md`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`

No other path may change. No GDScript or UID sidecar is created. Commit the two documentation paths before changing implementation or test paths.

### Deterministic RED

Modify only the three unit-test paths in the follow-up allowlist.

- Add all-eight-orientation `1x1`, `2x2`, and `3x3` resolver fixtures that require each owned record's own nominal interval to visibly enter that record cell.
- Add the reported right-edge hidden-ownership shape and prove its logically owned `(11, 3)` cell lacks visible centerline contact on unchanged production.
- Require presentation sampling for each owned interval to contain at least one point inside the corresponding record cell; exact-anchor intervals still retain the literal center at their midpoint.
- Characterize that an attempted duplicate remains rejected atomically with last-valid geometry, inventory, construction, recovery, anchors, and locked ledger unchanged.
- Preserve the fixed sample count, footprint containment, exact-center contact, straight and locked bytes, one-owner invariant, deterministic replay, and no-pathfinding contract.
- Update the fixed-seed Warp integration only after observing the exact new event trace: pair 3 loads into slot `1` at tick `67`, pair 4 remains unloaded at capacity, and no generation, lifetime, or ordering fact changes.

Run the three focused suites. RED is valid only when the new ordered-center visibility assertions fail without parser, runtime, warning, crash, or unrelated assertion failures.

### Minimum GREEN

Modify only `track_geometry_resolver.gd`.

- Replace the endpoint-support diagonal skeleton for newly resolved unlocked curves with ordered route-center skeleton knots.
- Keep entry and exit boundary knots and the fixed `16` segments per nominal cell.
- Apply the existing bounded quadratic cut-corner to ordinary orthogonal route turns; keep collinear runs linear and preserve nonzero endpoint travel.
- Mark only exact-anchor centers as position-preserving hard knots and apply the existing bounded local cubic halves there.
- When a terminal exact hard knot coincides with the exit boundary, add one bounded support inside the terminal cell on the negative exit-heading ray so the final stored chord remains nonzero without changing ownership, footprint, or either endpoint.
- Do not modify route records, active-cell uniqueness, footprint construction, overlap fallback, locked ledger reuse, inventory, construction, recovery, train sampling, Warp generation, or public APIs.

Run the three focused suites, complete registered suite, and all five standalone integrations. Audit the exact changed-path union, UID sidecars, `git diff --check`, primary cleanliness, merge-base, and ahead/behind state. Stage exact paths and commit:

```text
fix: align curve spines with ordered route cells
```

Obtain independent specification and quality reviews. Keep all four resolution rows `PENDING` until the user directly verifies the exact reviewed feature HEAD. A manual failure returns to deterministic diagnosis within this allowlist. Publication follows Section 9 only after every automated, review, and user-owned manual gate passes and primary plus remote state are reverified.

## 11. Approved Follow-up: Gesture-Local Live Warp Latch

The user confirmed that a Warp contacted during one held left-button gesture must
remain the route pivot until left release, right-click abort, or removal of that
anchor ID by the Warp lifecycle. If the Warp expires while left remains held, the
current accepted route remains intact, the latch is released, and the next pointer
update may edit through the former contact.

### Fixed Follow-up Allowlist

- `docs/superpowers/specs/2026-08-29-warp-exact-center-local-corners-design.md`
- `docs/superpowers/plans/2026-08-29-warp-exact-center-local-corners.md`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`
- task-owned external manual evidence Markdown

No other path may change. In particular, do not modify the pointer rasterizer,
geometry resolver, Warp generation or lifecycle classes, Cargo, train motion,
inventory, project configuration, UID sidecars, Risk & Investment, or either
protected worktree.

### Deterministic RED

The first runtime RED uses an empty-departure gesture with active exact anchor
`warp_latch/origin` at `(2, 1)`. The accepted held path is `(1, 1) -> (2, 1) ->
(2, 2)`. Backtracking to `(1, 1)` must retire only `(2, 2)` and preserve the
latched prefix `(1, 1) -> (2, 1)` with exactly `18` inventory remaining. Unchanged
production instead removes `(2, 1)` and reports `19`, producing exactly two
assertion failures and exit `1` without parser or unrelated diagnostics.

Add the recorded completed-head shape with an active exact anchor at the press
endpoint and a second diagonal Warp target. Require actual mouse events to retain
the press anchor, route the suffix through the deterministic free orthogonal tie,
contact the second Warp center, and finalize without reusing an owned cell.
Also begin from an ordinary departure, contact a Warp in the middle of the held
path, backtrack until the current pointer path omits that Warp cell, and rebranch.
Require the accepted route to retain the Warp prefix and connect the new suffix
from the latched exact center through the deterministic free tie.

Also require:

- anchor-ID removal during the held gesture preserves the complete accepted
  candidate and inventory, clears the exact observation, and allows the next
  update to backtrack through the former latch;
- activation on a pre-gesture nonendpoint occurrence does not itself create a
  gesture contact or freeze preview; ordinary held extension continues from the
  authoritative endpoint while pre-gesture locked pieces remain byte-stable;
- completed-head reflow that preserves a serial but relocates its cell is not
  historical; activation at that relocated exact occurrence latches and retains
  current route, inventory, the complete origin ledger, and any candidate ledger
  piece fully contained by the latched prefix;
- a Warp ID that had a press-time nonendpoint contact may latch again when the
  gesture removes that historical occurrence and later accepts the same ID at a
  different serial or cell; suppression is occurrence-scoped, never ID-scoped;
- right-click-equivalent abort restores the authoritative gesture origin;
- multiple IDs and later contacts advance only the active editing floor;
- locked geometry bytes, footprint rejection, one owner per serial, nominal
  sampling, construction, recovery, and deterministic replay remain unchanged.
- after an accepted long suffix passes through a live Warp, refresh the same
  anchor set so stable retirement records candidate-local locked pieces after the
  latch; then backtrack first to a reused suffix serial and finally to the Warp
  occurrence itself. Unchanged production must reproduce
  `candidate_validation / candidate_invariant`, preserve the stale endpoint, and
  expose the retired piece's missing exit support without parser or unrelated
  failures.

### Minimum GREEN

Modify only `grid_track_runtime.gd`.

- Track detached gesture-local latch facts by stable anchor ID, cell, and accepted
  route serial, plus the deterministic prefix required to rebuild later suffixes.
- Capture a possible active exact anchor at the press endpoint and capture later
  exact contacts only after the complete candidate passes ordinary resolution,
  continuity, validation, and finalization checks.
- While a latch remains active, derive mutation only after its occurrence and use
  the existing bounded connector when rasterized suffix input first collides with
  owned prefix cells but a legal shortest continuation exists.
- On anchor refresh, remove stale latch IDs without changing the already staged
  candidate. Clear all latch state on finalize, abort, train termination, and the
  existing gesture-state reset path.
- If records after an already valid latch later become immutable, preserve the
  latch and report a template-mutation rejection; do not silently delete it and
  retry the same frame under ordinary editing.
- Build the retained candidate ledger from the latch prefix before appending the
  reconciled suffix. Preserve a candidate-local locked piece only when its full
  serial span and nonnegative exit-support serial are already present in that
  prefix. Reused suffix serials must not resurrect pieces retired by the cut.
- Do not add Warp-ID parsing, change anchor production, weaken rejection, or
  mutate locked geometry.

Run the runtime focused suite, actual-input integration, related Warp and geometry
suites, the complete registered suite, all five standalone integrations, UID
audit, and `git diff --check`. Stage exact allowlist paths and create one focused
commit after both independent reviews approve the same candidate. Manual rows stay
user-owned and `PENDING` until replayed at all four supported sizes.
