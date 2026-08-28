# Track Local-Corner Geometry Design

- Date: 2026-08-29
- Status: User-approved for implementation and integration
- Audience: Agent-facing canonical specification
- Feature branch: `feature/warp-exact-center-local-corners`
- Verified base: `877b3dadd710abc44ea3602b530d854dd215a665`
- Parent route design: `docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md`
- Parent Warp amendment: `docs/superpowers/specs/2026-08-28-warp-cargo-control-feel-amendment-design.md`
- Branch authority: `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`
- Implementation plan: `docs/superpowers/plans/2026-08-29-warp-exact-center-local-corners.md`

## 1. Outcome

Every unlocked `CURVE_1X1`, `CURVE_2X2`, and `CURVE_3X3` must use straight centerline runs joined by bounded local corner blends, whether or not any Warp exists. An `EXACT_CELL_CENTER` anchor adds a literal hard knot to that common construction; it is not the switch that enables local-corner geometry.

The selected `CURVE_1X1`, `CURVE_2X2`, or `CURVE_3X3` owner remains selected unless an existing ownership, footprint, locked-overlap, exact-contact, or continuity rule rejects it. Visual quality no longer changes curve ownership merely to hide a global S-shape.

This correction also standardizes how geometry consumers interpret a centerline. `TrackGeometryPiece` owns uniform nominal sampling, continuous point projection, geometric cell coverage, and nominal-range cell coverage. The resolver and runtime retain policy decisions but do not independently reconstruct those geometric operations.

This work is a Warp Cargo geometry correction. It is not part of Risk & Investment and must not read, copy, stage, or absorb that feature's worktree.

## 2. Rejected Experiment

The unmerged experiment on `feature/warp-exact-center-visual-downgrade` at `228fc6d4e05b44d792f2f9f4f8878ebb522e83f9` added a reverse-travel threshold and downgraded an excessive anchored `3x3` to a smaller owner. Automated tests passed, but the user rejected the manual result because the same global cubic still produced visibly unnatural S-shaped segments after downgrade.

That experiment is evidence only and has no authority over this branch. This design does not carry forward its reverse-travel threshold, its ownership downgrade, or its accepted anchored-centerline digests.

For every unlocked curve, this amendment supersedes Section 4.1 steps 2, 4, 5, and 6 of the parent Warp amendment and the legacy unanchored `1x1` quadratic, `2x2` four-point, and `3x3` six-point centerlines. Endpoint and optional exact hard points, owner-wide tangents, and sparse owner-wide interpolation are replaced by the common skeleton and local-window rules in Section 5 below. The parent's fixed exact-knot indices, deterministic candidate fallback for existing validity failures, straight geometry, and locked-geometry rules remain authoritative.

## 3. Preserved Contracts

The following remain unchanged:

- ordered route cells are authoritative and no cell is inserted, removed, reordered, relocated, rerolled, or pathfound;
- every active route record has exactly one geometry owner;
- straight centerlines remain byte-for-byte stable;
- unlocked unanchored curve centerlines deliberately change to the common local-corner construction;
- already locked pieces remain byte-for-byte stable and may leave an exact Warp impossible;
- exact anchors constrain only their owned active route-record occurrence, except for the existing free departure-origin case;
- each exact knot remains at local nominal distance `record_offset + 0.5` and at the literal cell center;
- nominal length, inventory, construction, recovery, train timing, RNG, cargo, reward, and lifecycle behavior do not change;
- public `TrackSystem`, `TrainSystem`, session snapshot, Warp, and cargo APIs do not change;
- `CELL_ENTRY` retains its accepted one-eighth-nominal-cell outside-to-inside hit behavior.

## 4. Centerline Consumer Authority

`TrackGeometryPiece` remains the value object that stores `centerline`, nominal length, active local range, headings, footprint, and ownership metadata. It gains two geometry-owned queries:

```gdscript
func find_nominal_distance_at_position(
    target_position: Vector2,
    position_epsilon_units: float
) -> float

func contacts_cell_in_nominal_range(
    cell: Vector2i,
    grid_origin_units: Vector2,
    cell_size_units: float,
    local_start_cells: float,
    local_end_cells: float,
    subdivisions_per_nominal_cell: int
) -> bool
```

The projection query checks centerline segments in stored order, returns the earliest matching local nominal distance under uniform point-index parameterization, and returns `-1.0` when no segment lies within the supplied logical-unit epsilon. Repeated points cannot displace an earlier valid projection.

The nominal-range query samples the inclusive bounded interval with exactly the caller-supplied subdivisions. It does not own recovery policy or anchor mode. `GridTrackRuntime` first applies active-slice and recovered-cell policy, then delegates the geometric query with `CONTACT_SAMPLES_PER_CELL`.

The existing `contacts_cell()` retains its current spatial polyline-coverage semantics for resolver candidate validation. Spatial candidate coverage and nominal gameplay hit sampling are intentionally different contracts and must not share one cadence.

The resolver uses the shared projection query to verify an exact center. The runtime uses the same query to publish exact contact possibility and distance. Runtime code no longer walks raw centerline segments to recreate projection math.

Unit names remain explicit:

- nominal boundary comparisons continue to use `NOMINAL_BOUNDARY_EPSILON` in nominal cells;
- exact center projection uses a separate `0.0001` logical-unit position epsilon;
- tangent comparisons use their existing dimensionless dot epsilon;
- anchored geometry uses `16` stored segments per nominal cell;
- gameplay cell entry uses `8` nominal subdivisions per cell;
- presentation keeps `9` points per interval, meaning eight render subdivisions plus both endpoints.

These cadences must not be collapsed into one global setting.

## 5. Local-Corner Centerline Construction

The rule applies to every unlocked candidate curve. The same builder accepts zero or more exact knots. A Warp-free curve therefore uses the entry boundary, endpoint support knots, a straight interior spine, and the exit boundary; an exact-anchored curve adds its literal centers as ordered hard knots without changing the selected ownership kind.

Use the following fixed geometry constants, not Resources or Inspector settings:

```text
CENTERLINE_SEGMENTS_PER_NOMINAL_CELL = 16
EXACT_KNOT_OFFSET_SAMPLES = 8
ENDPOINT_SUPPORT_MAX_SAMPLES = 8
LOCAL_CORNER_HALF_WINDOW_SAMPLES = 4
```

Construction is deterministic:

1. Create hard knots for the entry boundary at sample `0`, every deduplicated exact center when present at `(record_offset * 16) + 8`, and the exit boundary at `nominal_length_cells * 16`.
2. Stable anchor-ID ordering continues to deduplicate multiple anchors in one route cell without changing their gameplay IDs.
3. Insert an entry support knot on the incoming ray and an exit support knot on the outgoing ray when a distinct adjacent hard point permits it. A support is at most eight samples and one half cell from its endpoint, is capped to half the adjacent sample-index and spatial forward-projection gaps, and never passes its adjacent hard point. With no exact knot, the straight segment between these two supports is the visible diagonal spine shown in the approved `2x2` and `3x3` proposal.
4. Fill every integer sample index by linear interpolation between consecutive ordered skeleton knots.
5. At an interior skeleton knot whose incoming and outgoing directions are not collinear, choose a half-window no larger than four samples and no larger than half either adjacent sample-index gap. Corner-window interiors therefore never overlap.
6. For a non-exact support corner, replace only that window with a quadratic fillet whose control is the skeleton corner. The fillet is tangent to the adjacent straight runs and need not pass through the discarded sharp support point.
7. For an exact corner, use two local cubic halves. They meet at the literal exact knot with one shared normalized bisector tangent. Each handle is no longer than one third of its local chord. The exact sample is never moved.
8. Samples outside declared corner windows remain exactly equal to the linear skeleton. A local blend spans at most eight stored segments, or one half nominal cell in total.
9. Preserve exactly `nominal_length_cells * 16 + 1` samples. Preserve explicit entry and exit heading overrides and the existing boundary stitch rules.
10. Apply interior footprint validation to every generated curve, not only exact-anchored curves. The first-route departure lead-in remains the only existing exception. Candidate fallback remains `3x3 -> 2x2 -> 1x1` only for existing ownership, grid, locked, anchor, and footprint validity rules, not for a visual-backtrack score.

For a Warp-free curve, the endpoint support fillets are the only curved neighborhoods and all samples between them remain on the straight spine. Passing through an exact center that is itself a geometric corner cannot be a conventional cut-corner fillet: cutting the corner would miss the exact center. The permitted local cubic may therefore contain a small local inflection, but all such deviation is confined to the fixed half-cell window rather than distributed across the entire curve owner.

## 6. Ownership, Locking, Sampling, and Determinism

For the same accepted candidate, local-corner generation changes only unlocked curve `centerline` samples. Kind, serial span, footprint, group ID, nominal length, active range, and absolute nominal start do not change. The common fixed sampling count is `nominal_length_cells * 16 + 1` for anchored and unanchored curves alike.

`sample_nominal()` remains uniform in stored sample index rather than screen-space arc length. This is the authoritative nominal-distance model used by train motion, exact contact distance, construction intervals, recovery slices, and presentation. Arc-length reparameterization is out of scope.

Locked pieces are copied and sliced through the existing ledger path without regeneration. Later anchor activation or removal cannot change their samples. A locked line that does not project onto an exact center remains impossible.

The same records, locked ledger, anchors, grid origin, grid size, and cell size must reproduce byte-identical generated centerline samples and contact facts.

## 7. Required Automated Evidence

Focused tests must prove:

1. resolver and runtime exact-center checks use the same earliest segment projection, including a target between stored points and a repeated-point segment;
2. active nominal-range contact observations use the same eight-subdivision policy as swept `CELL_ENTRY` hits;
3. anchored and unanchored `1x1`, `2x2`, and `3x3` retain their kind, span, footprint, nominal length, and one-owner-per-serial invariant in all eight orthogonal turn orientations;
4. exact knots remain at their literal centers and fixed midpoint sample indices;
5. curvature exists only inside declared local windows and samples outside those windows remain straight;
6. the former excessive `3x3` remains `CURVE_3X3` and no longer contains a long global S excursion;
7. entry and exit headings, footprint containment, nonzero grid origin, deterministic replay, partial recovery, and locked immutability remain valid;
8. straight centerlines and locked curve centerlines retain their baseline bytes, while newly resolved unanchored curves use deterministic fixed-count local-corner samples;
9. presentation's one-eighth interval samples show the local bends and straight spine for Warp-free curves, and additionally preserve the exact center for anchored curves;
10. all existing registered and standalone integration gates remain green.

## 8. Manual Acceptance and Scope Boundary

The user will perform the manual playtest. At `960x540`, `1280x720`, `1600x900`, and `1920x1080`, inspect both ordinary Warp-free turns and exact-center turns and confirm:

- long portions of each owner are visually straight;
- curvature is confined to actual direction changes;
- no previous owner-wide S-shape remains;
- the track still crosses the exact Warp marker center;
- `1x1`, `2x2`, and `3x3` ownership does not unexpectedly shrink;
- construction locks exactly the displayed geometry and later anchors cannot rewrite it;
- loading and delivery occur once at the exact marker center.

The screenshot-reported ordinary `3x3` case is a required row: its long middle run must be straight, with curvature confined to the two endpoint transition neighborhoods even though no Warp lies on the owner.

Manual status remains `PENDING` until the user reports the result. Automated evidence cannot mark it passed.

This feature does not add a general spline framework, curve Resources, arbitrary curvature tuning, arc-length motion, route correction, reachability filtering, rerolls, custom art, hazards, investments, contracts, credit, settlement, or snapshot-cache optimization.

## 9. Approved Adjacent-Turn Overlap Amendment

The user's `1280x720` mouse playtest exposed a separate resolver defect at an unlocked `2x2` tail. The route enters endpoint cell `(10, 7)` from `(10, 6)`. Extending from that endpoint to either horizontal neighbor creates an adjacent second turn. The unchanged resolver reports `final_overlap` with or without an exact Warp anchor, while the forward extension to `(10, 8)` succeeds.

The cause is the pairwise overlap loop, not Warp contact or local-corner generation. It shrinks both overlapping candidates in lockstep. For adjacent turns whose initial radii are `3` and `2`, the first pass produces `2` and `1`. Their footprints still overlap, and the existing loop rejects immediately because one candidate is already `1`, without testing the non-overlapping `1` and `1` combination.

For two overlapping unlocked curve candidates, the resolver must instead:

1. reject with `final_overlap` only when both candidates are already `1x1` and their footprints still overlap;
2. otherwise decrement every overlapping candidate whose radius is greater than `1`, leaving an already-`1x1` candidate unchanged;
3. repeat the existing deterministic pair scan until no candidate footprints overlap;
4. apply every existing span, grid, non-owned-record, locked-footprint, anchor-contact, centerline-footprint, continuity, and one-owner validation afterward.

This is an exhaustive use of the existing `3x3 -> 2x2 -> 1x1` fallback, not a collision relaxation. It may re-resolve the previous unlocked `2x2` and the new adjacent turn as two `1x1` owners. It never changes a locked piece, never accepts overlapping final footprints, and never inserts, removes, reorders, or rerolls route cells.

Focused evidence must cover both horizontal directions from the reported `2x2` tail, with the right target using `EXACT_CELL_CENTER`; the same right target without an anchor; the still-valid forward extension; exact-center contact; distinct final footprints; one owner per serial; inventory conservation; deterministic replay; and a negative case where two irreducible `1x1` footprints genuinely overlap and still return `final_overlap`.

GREEN review must also reclassify any historical runtime fixture that changes from `final_overlap` to accepted geometry only after proving that its final footprints are pairwise disjoint, every active serial has exactly one owner, the locked ledger is unchanged, inventory is conserved, and the accepted route remains constructible and train-sampleable. The two existing dense-turn fixtures meet those conditions and therefore become positive regressions for exhaustive local fallback. The irreducible duplicate-turn resolver fixture remains the authoritative negative case; no genuine final overlap is accepted.

The manual result remains user-owned. Recheck the reported left and right drags in the same mouse test, confirm the preview may locally reclassify the unlocked tail without moving locked geometry, and confirm the right-hand Warp marker is crossed at its exact center.

## 10. Approved Warp-Independent Generalization

The user clarified twice that local-corner geometry was always intended for ordinary curves as well as Warp exact-center curves. Treating the exact-center correction as a substitute for generalization was a scope error. This section supersedes every earlier statement in this document or plan that preserves unlocked unanchored curve centerlines byte-for-byte.

The correction must reuse one deterministic local-corner builder for every unlocked curve. An empty exact-knot list produces the ordinary straight-spine shape; one or more exact knots constrain that same construction. No Warp-ID or anchor-presence branch may select between a legacy curve and the common local-corner curve.

The user also approved publication and integration after the required tests and independent reviews: push this feature branch, open a pull request to `main`, merge with a merge commit, fast-forward the clean primary `main`, rerun the complete automated gate there, and clean up the feature worktree and local and remote feature branches. Manual visual rows remain `PENDING` unless the user directly confirms them; publication does not convert them to PASS.
