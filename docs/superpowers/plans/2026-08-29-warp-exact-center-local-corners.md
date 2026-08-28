# Warp Exact-Center Local-Corner Geometry Implementation Plan

- Date: 2026-08-29
- Status: Approved for execution
- Feature branch: `feature/warp-exact-center-local-corners`
- Verified base: `877b3dadd710abc44ea3602b530d854dd215a665`
- Canonical design: `docs/superpowers/specs/2026-08-29-warp-exact-center-local-corners-design.md`
- Stop point: tested and committed feature HEAD with user manual playtest pending; push, PR, merge, tag, primary fast-forward, and cleanup require separate approval

## 1. Fixed Allowlist

Documentation commit:

- `docs/superpowers/specs/2026-08-29-warp-exact-center-local-corners-design.md`
- `docs/superpowers/plans/2026-08-29-warp-exact-center-local-corners.md`
- `docs/briefings/ko/2026-08-29-warp-exact-center-local-corners-briefing.md`

Implementation commits:

- `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/manual/warp_cargo_windows.md`

No other path may change. No GDScript or UID sidecar is created. Risk & Investment and every unrelated worktree remain untouched.

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
- straight and unanchored baseline digests stay unchanged.

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
