# Warp Exact-Center Local-Corner Geometry Design

- Date: 2026-08-29
- Status: User-approved for implementation
- Audience: Agent-facing canonical specification
- Feature branch: `feature/warp-exact-center-local-corners`
- Verified base: `877b3dadd710abc44ea3602b530d854dd215a665`
- Parent route design: `docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md`
- Parent Warp amendment: `docs/superpowers/specs/2026-08-28-warp-cargo-control-feel-amendment-design.md`
- Branch authority: `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`
- Implementation plan: `docs/superpowers/plans/2026-08-29-warp-exact-center-local-corners.md`

## 1. Outcome

An unlocked curve constrained by one or more `EXACT_CELL_CENTER` anchors must use straight centerline runs joined by bounded local corner blends. It must not use one cubic across the full distance between the entry boundary, exact knots, and exit boundary.

The selected `CURVE_1X1`, `CURVE_2X2`, or `CURVE_3X3` owner remains selected unless an existing ownership, footprint, locked-overlap, exact-contact, or continuity rule rejects it. Visual quality no longer changes curve ownership merely to hide a global S-shape.

This correction also standardizes how geometry consumers interpret a centerline. `TrackGeometryPiece` owns uniform nominal sampling, continuous point projection, geometric cell coverage, and nominal-range cell coverage. The resolver and runtime retain policy decisions but do not independently reconstruct those geometric operations.

This work is a Warp Cargo geometry correction. It is not part of Risk & Investment and must not read, copy, stage, or absorb that feature's worktree.

## 2. Rejected Experiment

The unmerged experiment on `feature/warp-exact-center-visual-downgrade` at `228fc6d4e05b44d792f2f9f4f8878ebb522e83f9` added a reverse-travel threshold and downgraded an excessive anchored `3x3` to a smaller owner. Automated tests passed, but the user rejected the manual result because the same global cubic still produced visibly unnatural S-shaped segments after downgrade.

That experiment is evidence only and has no authority over this branch. This design does not carry forward its reverse-travel threshold, its ownership downgrade, or its accepted anchored-centerline digests.

For unlocked exact-anchored curves, this amendment supersedes Section 4.1 steps 2, 4, 5, and 6 of the parent Warp amendment: endpoint/exact-only hard points, owner-wide tangent assignment, owner-wide handles, and owner-wide cubic evaluation are replaced by the skeleton and local-window rules in Section 5 below. The parent's fixed exact-knot indices, footprint validation, deterministic candidate fallback for existing validity failures, straight geometry, unanchored geometry, and locked-geometry rules remain authoritative.

## 3. Preserved Contracts

The following remain unchanged:

- ordered route cells are authoritative and no cell is inserted, removed, reordered, relocated, rerolled, or pathfound;
- every active route record has exactly one geometry owner;
- straight and unanchored curve centerlines remain byte-for-byte stable;
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

The rule applies only when an unlocked candidate curve owns at least one exact anchor. Unanchored templates keep their existing code path.

Use the following fixed geometry constants, not Resources or Inspector settings:

```text
CENTERLINE_SEGMENTS_PER_NOMINAL_CELL = 16
EXACT_KNOT_OFFSET_SAMPLES = 8
ENDPOINT_SUPPORT_MAX_SAMPLES = 8
LOCAL_CORNER_HALF_WINDOW_SAMPLES = 4
```

Construction is deterministic:

1. Create hard knots for the entry boundary at sample `0`, every deduplicated exact center at `(record_offset * 16) + 8`, and the exit boundary at `nominal_length_cells * 16`.
2. Stable anchor-ID ordering continues to deduplicate multiple anchors in one route cell without changing their gameplay IDs.
3. Insert an entry support knot on the incoming ray and an exit support knot on the outgoing ray when a distinct adjacent hard point permits it. A support is at most eight samples and one half cell from its endpoint, is capped to half the adjacent sample-index and spatial forward-projection gaps, and never passes its adjacent hard point.
4. Fill every integer sample index by linear interpolation between consecutive ordered skeleton knots.
5. At an interior skeleton knot whose incoming and outgoing directions are not collinear, choose a half-window no larger than four samples and no larger than half either adjacent sample-index gap. Corner-window interiors therefore never overlap.
6. For a non-exact support corner, replace only that window with a quadratic fillet whose control is the skeleton corner. The fillet is tangent to the adjacent straight runs and need not pass through the discarded sharp support point.
7. For an exact corner, use two local cubic halves. They meet at the literal exact knot with one shared normalized bisector tangent. Each handle is no longer than one third of its local chord. The exact sample is never moved.
8. Samples outside declared corner windows remain exactly equal to the linear skeleton. A local blend spans at most eight stored segments, or one half nominal cell in total.
9. Preserve exactly `nominal_length_cells * 16 + 1` samples. Preserve explicit entry and exit heading overrides and the existing boundary stitch rules.
10. Apply the existing interior footprint validation after generation. The first-route departure lead-in remains the only existing exception. Candidate fallback remains `3x3 -> 2x2 -> 1x1` only for the pre-existing validity rules, not for a new visual-backtrack score.

Passing through an exact center that is itself a geometric corner cannot be a conventional cut-corner fillet: cutting the corner would miss the exact center. The permitted local cubic may therefore contain a small local inflection, but all such deviation is confined to the fixed half-cell window rather than distributed across the entire curve owner.

## 6. Ownership, Locking, Sampling, and Determinism

For the same accepted candidate, local-corner generation changes only the unlocked anchored `centerline` samples. Kind, serial span, footprint, group ID, nominal length, active range, and absolute nominal start do not change.

`sample_nominal()` remains uniform in stored sample index rather than screen-space arc length. This is the authoritative nominal-distance model used by train motion, exact contact distance, construction intervals, recovery slices, and presentation. Arc-length reparameterization is out of scope.

Locked pieces are copied and sliced through the existing ledger path without regeneration. Later anchor activation or removal cannot change their samples. A locked line that does not project onto an exact center remains impossible.

The same records, locked ledger, anchors, grid origin, grid size, and cell size must reproduce byte-identical generated centerline samples and contact facts.

## 7. Required Automated Evidence

Focused tests must prove:

1. resolver and runtime exact-center checks use the same earliest segment projection, including a target between stored points and a repeated-point segment;
2. active nominal-range contact observations use the same eight-subdivision policy as swept `CELL_ENTRY` hits;
3. anchored `1x1`, `2x2`, and `3x3` retain their pre-anchor kind, span, footprint, nominal length, and one-owner-per-serial invariant in all eight orthogonal turn orientations;
4. exact knots remain at their literal centers and fixed midpoint sample indices;
5. curvature exists only inside declared local windows and samples outside those windows remain straight;
6. the former excessive `3x3` remains `CURVE_3X3` and no longer contains a long global S excursion;
7. entry and exit headings, footprint containment, nonzero grid origin, deterministic replay, partial recovery, and locked immutability remain valid;
8. straight and unanchored `1x1`, `2x2`, and `3x3` centerlines retain their baseline byte digests;
9. presentation's one-eighth interval samples preserve the exact center and visibly contain the local bend without introducing curvature into distant straight runs;
10. all existing registered and standalone integration gates remain green.

## 8. Manual Acceptance and Scope Boundary

The user will perform the manual playtest. At `960x540`, `1280x720`, `1600x900`, and `1920x1080`, inspect the previously rejected exact-center turns and confirm:

- long portions of each owner are visually straight;
- curvature is confined to actual direction changes;
- no previous owner-wide S-shape remains;
- the track still crosses the exact Warp marker center;
- `1x1`, `2x2`, and `3x3` ownership does not unexpectedly shrink;
- construction locks exactly the displayed geometry and later anchors cannot rewrite it;
- loading and delivery occur once at the exact marker center.

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

The manual result remains user-owned. Recheck the reported left and right drags in the same mouse test, confirm the preview may locally reclassify the unlocked tail without moving locked geometry, and confirm the right-hand Warp marker is crossed at its exact center.
