# Prototype Grid Track Amendment Design

- Date: 2026-08-24
- Status: Approved for implementation planning
- Audience: Agent-facing canonical specification
- Immutable code baseline: `Prototyping` at accepted tag `prototype-m3`
- Implementation base: one reviewed documentation-only child of `prototype-m3`
- Future implementation branch: `proto/03-grid-track-amendment`
- Accepted milestone tag after implementation: `prototype-m4`
- Historical baseline design: `docs/superpowers/specs/2026-08-16-prototype-track-train-design.md`
- Related gameplay specification: `docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md`
- Related development strategy: `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`
- Implementation plan: `docs/superpowers/plans/2026-08-24-prototype-grid-track-amendment.md`
- User briefing: `docs/briefings/ko/2026-08-24-prototype-grid-track-amendment-plan-briefing.md`

## 1. Outcome and Scope

Replace the accepted `prototype-m3` freeform polyline route model with a grid-cell route model without changing the one-train, one-line, fixed-tick session premise.

The player still extends one route from its single current endpoint while the train never stops. The change is that input reserves an ordered sequence of orthogonally adjacent cells, inventory is counted in whole track cells, and the presentation resolves those cells into straight or curved track pieces. Physical construction proceeds one logical cell at a time through a translucent ghost route.

This amendment includes:

- square-grid coordinate mapping inside the existing logical field;
- ordered endpoint-only cell reservation from buffered mouse motion;
- one-time integer inventory charge per newly reserved route cell;
- deterministic straight and `1x1`, `2x2`, or `3x3` curve resolution;
- mandatory route-contact anchor constraints for later warp cells;
- unlocked ghost-geometry reflow and construction-time geometry locking;
- per-cell `RESERVED_GHOST`, `BUILDING`, and `BUILT` state;
- continuous train movement over the completed centerline prefix at nominal cells per second;
- one-cell-at-a-time rear recovery and refund;
- cell-state snapshots, ghost-to-solid construction presentation, and grid HUD values;
- migration and regression coverage for the accepted `prototype-m3` session lifecycle.

This amendment does not include:

- warp pair generation, lifetime, forecast, cargo, loading, delivery, or expiry;
- hazards, durability, repair, paid demolition, or crossings;
- contracts, settlement, credit, bankruptcy, fleet, train purchases, or office upgrades;
- branches, merges, pathfinding, multiple trains, stopping, or reversing;
- final art, custom fonts, final audio, touch, mobile, or gamepad behavior.

`proto/04-warp-cargo` will generate random warp cells and pass them to the contact-anchor boundary defined here. It must not reimplement grid routing, curve choice, reachability correction, or route geometry.

## 2. Supersession Boundary

The `prototype-m3` tag and its original design and implementation plan remain historical evidence for the accepted continuous-polyline prototype. They are not rewritten as if the grid model had existed at that milestone.

For all implementation after this amendment is approved:

- this document is authoritative for route input, route ownership, inventory, curve geometry, construction, train traversal, recovery, and warp-cell contact;
- the historical design remains authoritative for the existing session lifecycle, seeded departure-candidate selection, logical-field-to-viewport mapping, one-shot completion, and fixed-tick ownership unless this document explicitly changes them;
- the historical implementation plan is not executable for current route work;
- later feature slices consume the grid contracts established here and may not restore the superseded polyline or floating-length contracts.

## 3. Grid Coordinate and Cell Ownership

The logical field owns a rectangular square-cell grid. The accepted default is:

- cell size: `40.0` logical units;
- `COMPACT`: `22 x 10` cells, centered inside the existing `900 x 420` logical field;
- `STANDARD`: `30 x 14` cells, exactly filling the existing `1200 x 560` logical field;
- `EXPANSIVE`: `36 x 16` cells, centered inside the existing `1500 x 700` logical field;
- `CUSTOM`: Inspector fields `custom_grid_columns` and `custom_grid_rows`, initially `30 x 14`, with positive integers that fit inside the validated custom logical field at the configured cell size.

The cell-size and preset counts are Inspector-owned prototype tuning values. Cells remain square. Any unused logical-field margin is noninteractive and is presented as part of the field border, not as a partial cell.

Every active session copies one authoritative `grid_origin_units` into `SessionStartConfig`, calculated as `(logical_field_size - Vector2(grid_size) * grid_cell_size_units) * 0.5`. Cell `(x, y)` therefore has logical center `grid_origin_units + (Vector2(x, y) + Vector2(0.5, 0.5)) * grid_cell_size_units`. Input hit testing, departure snapping, curve-template translation, route-contact coverage, piece rendering, and train sampling all consume this same origin. Domain geometry must never assume that cell `(0, 0)` begins at logical `(0, 0)`.

Changing a logical-field preset or custom logical size preserves the existing editor rule that authored departure candidates retain normalized positions. Grid snapping happens only when values are copied into an active `SessionStartConfig`; it does not rewrite the authored `Marker2D` source position.

The selected departure candidate is snapped to one validated grid cell during composition. That departure cell is the fixed route endpoint before the first reservation and remains a zero-inventory platform anchor, preserving the `prototype-m3` zero-length starting point. Every accepted route cell after it costs one inventory cell.

The active route owns:

- one departure anchor cell;
- an ordered array of unique route-cell records;
- a monotonically increasing route serial for every accepted cell;
- an integer-valued absolute nominal start distance for every active route cell;
- one active endpoint equal to the last route cell, or the departure anchor while the route is empty;
- an integer available-inventory count;
- resolved geometry pieces that cover every active route-cell record exactly once.

Every route cell after the departure anchor is orthogonally adjacent to the preceding cell or anchor. Diagonal adjacency is invalid. A cell already owned by the active route cannot be appended again. Recovered cells are no longer active and may be reused.

The conservation invariant is exact integer arithmetic:

`available_track_cells + active_route_cell_count = total_track_cells`

No geometry classification, construction transition, train movement, or warp constraint charges inventory. Reservation charges a newly accepted cell once. Cancellation or recovery refunds a removed cell once.

Route serial is a stable identity and may contain gaps after cancellation. Absolute nominal distance follows the retained route: appending after cancellation continues from the retained endpoint, while rear recovery never renormalizes surviving distances or train progress.

## 4. Input and Cancellation

Mouse input remains presentation-owned and is consumed once per fixed tick, but the view buffers the ordered grid cells crossed by real pointer motion rather than retaining only one arbitrary polyline sample.

- A left press starts a stroke only in the current endpoint cell.
- While held, each actual orthogonal cell boundary crossing appends one candidate cell in observed order.
- A fast motion that crosses several cells buffers every crossed cell before the next fixed tick.
- The route model never creates a diagonal shortcut and never chooses a destination path.
- When a motion crosses an exact grid corner, the adapter resolves the simultaneous boundary event by the motion segment's dominant axis; an exact equal-axis tie resolves horizontal first. This is a deterministic input fallback, not pathfinding.
- Releasing left ends the stroke. A later stroke must start in the then-current endpoint cell.
- Reservation stops before the first invalid candidate: outside the grid, nonorthogonal, active-route duplicate, zero inventory, or geometry with no valid nonoverlapping resolution.
- Only accepted unique cells consume inventory.

Right-click retains the accepted prototype cancellation role with cell semantics:

- right-click selects a `RESERVED_GHOST` route cell;
- that cell and every later wholly unlocked ghost cell are removed as one suffix;
- each removed cell refunds exactly one inventory cell;
- `BUILDING`, `BUILT`, recovered, departure-anchor, and empty cells are not cancellable;
- a geometry piece becomes wholly locked when construction begins on its first logical cell, so cancellation cannot cut through that piece;
- right-click wins over left input in the same fixed tick and suppresses a held left stroke until release, preserving the accepted input precedence.

Paid demolition remains outside this amendment.

## 5. Route Sequence and Curve Contract

The ordered grid route is the source of truth. Visual geometry is a deterministic derived view over that order. The resolver may smooth a turn, but it may not add cells, remove cells, reorder cells, find a path, or change inventory.

### 5.1 Piece sizes

A straight piece covers one route cell and has one nominal cell of route length.

A 90-degree turn may resolve to:

| Visual piece | Owned route-cell span | Nominal route length |
|---|---:|---:|
| `1x1` curve | `1` cell | `1` cell |
| `2x2` curve | `3` cells | `3` cells |
| `3x3` curve | `5` cells | `5` cells |

A `2x2` curve covers the turn cell plus one incoming and one outgoing route cell. A `3x3` curve covers the turn cell plus two incoming and two outgoing route cells. A larger curve therefore replaces already-owned straight presentation over the same route cells; it never buys extra geometry.

For the route:

```text
A-B-C
    D
```

the four owned cells may resolve as straight `A` plus one three-cell `2x2` curve over `B-C-D`. Extending the route by `E` below `D` creates only one new owned cell. The five owned cells may then re-resolve as one `3x3` curve without another charge for `A-B-C-D`.

### 5.2 Candidate selection

For each unlocked 90-degree turn, the resolver tries `3x3`, then `2x2`, then `1x1`.

A candidate is valid only when:

- the required incoming and outgoing route cells exist in the ordered route;
- its owned route-cell span does not cross a locked geometry boundary;
- its footprint remains inside the grid;
- its centerline contacts every mandatory anchor cell covered by that span;
- its footprint does not overlap an incompatible track-piece footprint.

Straight pieces fill every route cell not owned by a curve.

### 5.3 Overlap downgrade

Resolve unlocked turns in ascending route order, then detect incompatible footprint overlap. When two unlocked curves overlap, downgrade both by one size and resolve the set again. Repeat until no overlap remains.

A shared owned route cell is still an incompatible overlap. In the approved close-double-turn fixture, both candidates therefore downgrade from `3x3` through `2x2` to disjoint `1x1` curves. This preserves the invariant that every active route-cell record belongs to exactly one geometry piece.

If one side is locked, only the unlocked curve downgrades. Two `1x1` curves cannot occupy the same active route cell because route cells are unique; a remaining `1x1` conflict rejects the newly appended suffix rather than changing locked or previously accepted geometry.

The same route cells, locked prefix, anchor set, grid bounds, and seed-independent configuration always produce the same pieces.

Grid bounds reject an out-of-bounds route record before curve sizing. Because a curve footprint is the inclusive axis-aligned bounding box of its owned in-bounds route cells, grid bounds do not trigger a curve-size downgrade; the downgrade cascade is reserved for overlap, locked-footprint conflict, and contact-anchor failure.

Resolution returns an explicit accepted or rejected result. An empty accepted route is distinct from an invalid candidate. `TrackSystem` tentatively appends one cell, resolves, and rolls back that exact unlocked cell without charge if resolution rejects it.

## 6. Mandatory Route-Contact Anchors

A route-contact anchor is a stable identifier plus a grid cell. It represents a location whose gameplay meaning requires the train centerline to enter that cell. The resolver receives anchors exactly as supplied; it does not reroll, relocate, filter, or test reachability.

For each candidate piece, contact is determined from its template's centerline-to-cell coverage using the active session's `grid_origin_units`, not merely from its rectangular footprint. A curve whose footprint contains an anchor but whose centerline bypasses the anchor cell is invalid.

An anchor can therefore force a smaller curve or a straight piece. Using an ordered route shaped as:

```text
A-B-C
    D
    E
```

- an anchor at `C` can be contacted by the straight approach before the turn;
- an anchor at `D` forces the fitting `2x2` curve because a continuous `2x2` exit enters `D` immediately before the `D-E` boundary;
- an anchor at `E` can permit the fitting `3x3` curve.

This fixture still exercises the generic `3x3 -> 2x2 -> 1x1` retry. It stops at `2x2` because that is the largest template whose continuous centerline contacts `D`; requiring `1x1` at `D` would contradict both the `D-E` boundary endpoint and the outgoing tangent.

The exact resolved template is determined by the route span and contact coverage, not by a special-case label for `C`, `D`, or `E`.

`proto/04-warp-cargo` owns seeded warp pair generation and lifecycle. Its candidate pool includes every in-bounds grid cell regardless of whether that cell is empty, reserved, built, ahead of the train, or behind it. It performs no reachability guarantee, reroll, route-dependent correction, or filtering. A point generated behind the train may be impossible to serve; accepting that result is part of the game constraint.

If a later warp appears on already locked geometry, this amendment's resolver does not rewrite the locked track. The warp system observes whether the existing centerline contacts that cell and applies its own lifecycle outcome.

Updating anchors never rejects, moves, or removes an anchor. Unlocked ghost geometry re-resolves when possible. If no valid reflow can satisfy a new anchor while preserving locked pieces, the last valid geometry remains and the anchor observation reports `contact_possible = false` and `contacted = false`; the warp lifecycle owns the resulting missed opportunity.

## 7. Per-Cell Construction and Geometry Locking

Every active route-cell record has exactly one state:

1. `RESERVED_GHOST`
2. `BUILDING`
3. `BUILT`

At most one route cell is `BUILDING`. All later active cells are `RESERVED_GHOST`. All earlier unrecovered cells are `BUILT`.

Construction advances in route order at a configured rate measured in nominal cells per second. Fractional progress belongs only to the active `BUILDING` cell.

- When construction starts a cell, the complete geometry piece that owns that cell becomes locked.
- Starting construction does not make the cell traversable.
- During construction, the active cell's centerline interval fades continuously from ghost color to normal color according to progress in `[0.0, 1.0]`.
- At exactly `1.0`, the cell atomically becomes `BUILT` and traversable.
- Any excess fixed-tick progress advances the next cell deterministically.
- A locked piece never changes size, footprint, centerline, route-cell span, or contact result.
- Unlocked ghost pieces after the locked prefix may reflow whenever accepted input or an anchor update changes the valid solution.

For a five-cell `3x3` curve, the whole curve is visible as ghost geometry before construction. Its five nominal centerline intervals construct in route order. Completed intervals are solid and traversable; the active interval is fading but blocked; remaining intervals are ghost and blocked. Locking begins when construction starts the first interval and covers the entire five-cell piece.

## 8. Train Traversal and Nominal Distance

The train still moves continuously and never jumps between cell centers. Each geometry piece supplies a continuous centerline plus a nominal length equal to its owned route-cell count.

Train speed is measured in nominal cells per second. A `3x3` curve therefore takes the same time to traverse as five straight cells, even when the drawn curve's pixel length differs from five times the visual cell size. The fixed-speed invariant is nominal route progress, not constant screen-pixel velocity.

Only the contiguous `BUILT` prefix is traversable. `BUILDING` progress does not extend the safe endpoint. If train movement reaches the built endpoint, the existing `TRACK_END_REACHED` request and same-tick regular-expiry priority remain unchanged.

Position and heading are sampled continuously from the locked centerline at the train's absolute nominal route distance. Geometry behind the train may be removed without renormalizing that distance.

## 9. Rear Recovery

The recovery lag is an integer number of nominal cells behind the train. A built route cell becomes eligible when the train's absolute nominal distance has passed that cell's end distance plus the configured lag.

Eligible cells are removed from oldest to newest. Each removed cell:

- produces one distinct recovery transition;
- returns exactly one inventory cell;
- removes its presentation interval;
- leaves absolute route serials and train distance unchanged.

A fixed tick may process every newly eligible cell, but refunds are emitted and accounted for one cell at a time. A multi-cell curve is never refunded as one composite object. Locked geometry metadata may be discarded only after all of that piece's route cells have been recovered.

A persistent locked-piece ledger keeps each piece's full original serial span, absolute nominal start distance, and full centerline during partial recovery. Presentation receives an active slice of that immutable piece, while train sampling continues to use the full ledger. Removing the first cells of a curve therefore clips only its visible active interval and never changes positions or headings on its surviving interval.

Recovery remains after train movement and after the current tick's reservation step. Inventory recovered during a tick may fund reservation beginning with the following tick.

## 10. Snapshot and Presentation Contract

Presentation receives detached observations and never infers authoritative state from color or geometry.

The snapshot exposes:

- ordered active cell records with route serial, grid coordinate, state, and build progress;
- resolved piece records with kind, owned serial range, footprint, centerline, nominal length, and lock state;
- the built nominal endpoint;
- train nominal distance, position, and heading;
- integer available and total track cells;
- integer departure built and required cells;
- estimated seconds to the built endpoint and urgent-warning state;
- selected departure candidate ID and snapped departure cell;
- the authoritative grid origin used by input, geometry, rendering, and train sampling;
- route-contact anchor observations and whether the present centerline contacts each anchor.

Rendering uses replaceable primitive drawing:

- all reserved geometry is translucent ghost track;
- the active construction interval blends from ghost to solid over its progress;
- built intervals use the normal track color;
- curve pieces render from deterministic templates rather than the raw mouse trace;
- cells and footprints can be shown with debug overlays but are not required final art;
- the HUD displays integer `available / total` inventory.

The player must be able to distinguish a blocked ghost interval from a traversable built interval without reading debug text.

## 11. Fixed-Tick Order

The amended active tick order is:

1. Consume one immutable input frame containing a right-click cell and an ordered left-drag cell buffer.
2. Apply right-click cancellation against tick-start cell and lock state.
3. If right-click did not win, append valid left-drag cells in order and resolve unlocked geometry.
4. Advance construction progress; lock a piece when its first cell begins and mark completed cells `BUILT`.
5. If preparing and the built-cell requirement is met, enter `RUNNING`.
6. If running, advance the train over the built centerline and record a track-end request.
7. Run the later warp/cargo and hazard movement hooks when their owning slices exist.
8. Recover eligible rear cells in route order and refund each once.
9. Run later warp-expiry hooks when their owning slice exists.
10. Advance the session timer only while running and record regular expiry.
11. Resolve end requests, with regular expiry winning a same-tick tie against track end.
12. Publish one detached snapshot.
13. If completed, emit one result after the terminal snapshot.

## 12. Configuration Migration

The first grid defaults preserve the accepted `prototype-m3` time ratios using a `40.0`-unit cell:

| Historical field | Grid replacement | Default |
|---|---|---:|
| `total_units = 720.0` | `total_track_cells` | `18` |
| `recovery_distance_units = 240.0` | `recovery_lag_cells` | `6` |
| `speed_units_per_second = 120.0` construction | `build_cells_per_second` | `3.0` |
| `speed_units_per_second = 60.0` train | `speed_cells_per_second` | `1.5` |
| `required_built_units = 360.0` | `required_built_cells` | `9` |

`endpoint_grab_radius_units`, `route_hit_radius_units`, `minimum_sample_distance_units`, and `intersection_clearance_units` are removed from active configuration. Cell hit testing, adjacency, footprint overlap, and endpoint ownership replace them.

The urgent-warning threshold remains `3.0` seconds. All values remain Inspector-owned and may be tuned after the first playable grid build; the integer ownership and nominal-distance meanings are invariants.

## 13. Validation and Failure Handling

Debug composition rejects:

- nonpositive cell size;
- nonpositive grid dimensions or a grid that does not fit the logical field;
- departure candidates that do not snap to an in-bounds cell;
- nonpositive total inventory;
- negative recovery lag;
- nonpositive construction or train speed;
- departure requirement outside `1..total_track_cells`;
- duplicate active route cells, nonorthogonal adjacency, nonmonotonic route serials, or multiple `BUILDING` cells;
- an unlocked piece whose owned serial range overlaps another piece, leaves an active cell uncovered, crosses a lock boundary, or disagrees with its nominal length;
- a locked-piece active slice that disagrees with its immutable full ledger entry or surviving active cells;
- a locked piece that changes after construction starts;
- any mismatch between the copied grid origin and the centered grid rectangle derived from logical-field size, grid size, and cell size;
- an anchor reported as contacted when its cell is not entered by the resolved centerline.

Invalid input is a no-op after the accepted prefix. It never spends inventory. Runtime assertions remain next to the domain owner of each invariant.

## 14. Verification and Acceptance

Acceptance requires:

- the existing 14-suite `prototype-m3` baseline passes before implementation begins;
- RED tests demonstrate that the current continuous input, floating inventory, continuous construction, and partial recovery do not satisfy the new contract;
- identical cell input and anchor sequences produce identical route cells, pieces, locks, snapshots, and results;
- each unique accepted cell is charged once and each canceled or recovered cell is refunded once;
- `1x1`, `2x2`, and `3x3` curves own exactly `1`, `3`, and `5` route cells and consume no classification surcharge;
- overlapping unlocked curves downgrade deterministically;
- a mandatory anchor can force a smaller valid curve, while no reachability correction is introduced;
- construction visibly and logically follows `RESERVED_GHOST -> BUILDING -> BUILT` one cell at a time;
- construction start locks the whole owning piece and later route extension cannot change it;
- the train moves continuously only on the built prefix and traverses a five-cell curve in the same time as five straight cells;
- rear recovery refunds multi-cell curves one logical cell at a time;
- `COMPACT`, `STANDARD`, and `EXPANSIVE` integration tests prove that a rasterized cell center, its resolved piece centerline, and the train position share the same logical coordinates, including nonzero centered-grid origins;
- supported 16:9 resize behavior, one-shot completion, deterministic seed behavior, and the accepted fixed-tick end priority remain covered;
- the implementation adds no cargo, economy, hazard, credit, pathfinding, graph, multi-train, or production abstraction;
- a Windows manual play demonstrates readable cell placement, curve reflow before lock, ghost-to-solid construction, continuous curve travel, and sequential rear recovery.

## 15. Deferred Ownership

- `proto/04-warp-cargo`: seeded random warp pairs, forecast, lifecycle, loading, delivery, expiry, and uncorrected cell placement; consumes `RouteContactAnchor`.
- `proto/05-risk-investment`: hazards, durability, repair basis, paid cell-suffix demolition, early rear-cell recovery, and grade-separated crossing rules.
- `proto/06-contract-economy`: companies, contracts, settlement, and trust.
- `proto/07-credit-survival`: borrowing, repayment, refinancing, cycle progression, and bankruptcy.
- `proto/08-playtest-ready`: replay evidence, metrics, usability, and Windows export.

Fleet expansion, train-model purchases, and office upgrades remain production/campaign extension points described by the gameplay specification and are not implemented in this amendment.
