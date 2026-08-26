# Reflowable Track-Head Design

**Date:** 2026-08-25
**Status:** Proposed canonical amendment for implementation planning
**Audience:** Agent-facing canonical specification
**Implementation branch:** `feature/reflowable-track-head`
**Amends:** `docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md`

## 1. Purpose

The grid-track prototype must allow a recently completed route head to acquire the largest valid curve after the player supplies enough later route cells. Construction completion and geometric finality are different concerns: a cell can be `BUILT`, visibly solid, and traversable while it remains inside a small, reflowable route-head horizon.

This amendment replaces construction-start geometry locking with deterministic, whole-piece locking. It preserves the one continuously moving train, one endpoint-only route, integer cell inventory, sequential construction and recovery, nominal-distance train motion, and all accepted game premises. In particular, random finite-lifetime warp points may remain impossible; this amendment adds no reroll, route-aware generation, reachability correction, pathfinding, branch, merge, pause, reverse, or extra train.

## 2. Explicit Supersession Boundary

This document supersedes only the following clauses of the 2026-08-24 grid-track amendment:

- Section 1's phrase “unlocked ghost-geometry reflow and construction-time geometry locking.” Geometry locking is no longer caused by construction.
- Section 4's cancellation rule that a piece becomes wholly locked when construction begins on its first cell.
- Section 5.2's use of the construction-derived locked boundary when deciding whether a candidate can span records.
- All of Section 7, “Per-Cell Construction and Geometry Locking.”
- Section 8's implication that the built prefix is necessarily a fully locked prefix. Builtness grants traversal; the train safety gate grants sampling immutability.
- Section 10's rendering wording to the extent it equates unresolved geometry with ghost presentation.
- Section 11's construction and train portions of the fixed-tick order.
- Section 13's construction-start locked-piece validation and Section 14 acceptance bullets that require it.
- The document's historical `Prototyping`, `proto/03`, `prototype-m3`, immutable-baseline, future-delivery, and accepted-tag metadata as directions for new work. Those entries remain historical evidence only; active work follows the main-first policy.
- The old task gate that uses the historical RED baseline and `PASS: 14` implementation result as a current implementation gate. Section 12 of this document and the later feature plan define the current gate.

Every other clause of that design remains authoritative, including grid coordinates, ordered unique records, serial identity, absolute nominal distance, curve templates, overlap downgrade, anchor contact, endpoint-only input, inventory conservation, and recovery ledger behavior. If an implementation detail conflicts with this document, this document wins for the reflowable head only. A later implementation plan must pin the exact then-current verified `main` commit, Godot `4.7.1`, the `PASS: 19` automated baseline, four standalone integration checks, and its exact task allowlists and independent reviews; it must not reuse the historical delivery metadata as a feature base or gate.

## 3. Terminology and State Model

### 3.1 Route and construction state

An **active route record** is an unrecovered, accepted `TrackCellRecord`, ordered by immutable route serial and absolute nominal start distance. Its construction state remains exactly one of:

1. `RESERVED_GHOST`
2. `BUILDING`
3. `BUILT`

At most one active record is `BUILDING`; route order still determines construction and recovery. `BUILDING` is blocked. The contiguous `BUILT` prefix is traversable. No construction state says whether geometry may reflow.

### 3.2 Geometry state

A resolved `TrackGeometryPiece` is either:

- **provisional:** an internal, mutable geometry classification in the route-head horizon; or
- **locked:** an immutable full-ledger piece with fixed kind, owned serial range, footprint, centerline, nominal length, absolute start distance, and optional exit-support serial.

The geometry state is independent of construction state. A provisional piece may contain `RESERVED_GHOST`, `BUILDING`, and/or `BUILT` records. A locked piece may likewise contain any construction state until ordinary construction and recovery advance.

The **locked ledger** remains the sole immutable source for a locked piece and its active slice after rear recovery. It stores immutable geometry, identity/range/distance, and any exit-support metadata only; it must preserve the existing no-renormalization guarantee. `contact_possible` and `contacted` are not ledger fields or immutable-piece results. They are current derived observations, recomputed from the authoritative current anchor set and the active geometry slice.

Among active records, locked pieces always form one contiguous route prefix and provisional pieces form the remaining contiguous route suffix. There is no interior locked island and no provisional piece behind an active locked piece.

The **active locked frontier** is the absolute nominal end of the last active locked piece. When no active piece is locked, it is the absolute nominal start of the first active provisional piece; fully recovered ledger entries do not move it backward. Train preparation extends this frontier only forward.

An **exit-support dependency** exists when locking a whole piece used one following active route record to determine the locked piece's terminal midpoint or tangent. The ledger records that following route serial as support metadata. The support record's cell stays fixed, and the dependency itself does not lock its geometry, change its construction state, or change its rendering. Its piece remains provisional until independently locked by ordinary horizon enforcement or `prepare_for_train_sampling`; that independent lock is allowed and does not mutate or remove the predecessor ledger entry or its support metadata. Once independently locked, the support piece follows normal locked-piece invariants. While the dependent ledger entry remains active, cancellation may not remove that support serial. The dependency ends when the ledger entry is fully recovered and pruned.

### 3.3 Head horizon

The **head horizon** is the mutable suffix of active route records after all required whole pieces have been locked. At every published stable state it contains no more than five active route records. Five is the maximum because a `CURVE_3X3` owns five nominal route cells; `CURVE_2X2` and `CURVE_1X1` own three and one respectively.

The horizon is dynamic: it may contain fewer than five records after a whole piece is locked. It is not a visual state and it does not alter inventory, cell state, route serials, or absolute distances.

## 4. Resolution and Whole-Piece Horizon Algorithm

The ordered route records remain the source of truth. The resolver continues to resolve the locked ledger plus the provisional suffix with the existing deterministic candidate order (`3x3`, then `2x2`, then `1x1`), overlap downgrade, footprint, anchor, and continuity rules.

After every route mutation, perform this atomic transaction before publishing a snapshot:

1. Resolve the active records against the immutable locked ledger.
2. If the result is invalid or discontinuous, reject the triggering mutation as specified in Section 8; do not replace the last valid pieces.
3. Count all active records owned by provisional pieces. If the count is zero, commit the valid resolution without attempting to find an earliest provisional record.
4. While that count is greater than five, find the earliest active record owned by a provisional piece, stage the complete owning piece as a new immutable ledger entry (not a partial slice), then re-resolve the remaining provisional suffix against the staged ledger.
5. Recount after each staged lock. When the staged provisional suffix contains at most five records, commit the complete staged ledger and pieces together, then publish detached observations.

Step 4 is deliberately piece-aligned. It never locks only the oldest cell and never splits a `1/3/5`-cell piece. When deriving a locked piece's terminal midpoint or tangent uses its immediately following active route record, stage that route serial as the ledger entry's exit-support dependency; otherwise stage no support serial. This does not consume or lock the successor geometry. Locking also does not charge inventory, change record state, or change any route serial or nominal start distance. Re-resolution after staging an already-valid whole piece is an internal invariant: it must remain valid and continuous. If it does not, assert the invariant, discard the entire staged ledger expansion and staged pieces, retain the prior valid state, and reject the triggering mutation. No partial ledger expansion may be published or retained.

### 4.1 Authoritative anchor updates

An anchor update is not a route mutation and is always accepted as authoritative runtime state. The track system copies the supplied anchor set exactly, without filtering, relocating, rerolling, or rejecting it. It then stages a resolution of the unchanged route against the new anchors and the current locked ledger.

If the staged resolution and its head-horizon transaction are valid, atomically commit the resulting geometry and any required ledger expansion. If either geometry stage cannot commit, roll back only the staged pieces and ledger expansion, retain the new copied anchors and the last valid geometry, then independently recompute each current anchor observation against that preserved active geometry. An anchor whose cell is still entered by the preserved active centerline publishes `contact_possible = true` and `contacted = true`; only an unsatisfied anchor publishes both values as `false`. A failure after staging an already-valid whole-piece lock also asserts the relevant internal invariant. In every case, the system must not restore an old anchor set, change a locked piece, or treat the update as rejected. This is a valid gameplay state: later warp cells can be impossible.

### 4.2 Curve straddling the five-cell boundary

Consider records `B C D E F G H`, in route order, where `B..F` resolve as one `CURVE_3X3` and `G` is a following straight. Before `G` is appended, `B..F` are the five-record head horizon and may all be provisional, including if they are already `BUILT`. Appending `G` first creates a six-record provisional candidate set. The existing `CURVE_3X3` owns `B..F`, so it straddles the new five-record suffix boundary that would lie between `B` and `C`.

The algorithm locks the whole `B..F` curve, then resolves `G` as the one-record provisional horizon. It does not split `B` away from the curve, downgrade the curve merely to satisfy the count, or keep six published provisional records. Thus the public horizon remains at most five records and the boundary is deterministic from route order and resolved piece ownership.

The same rule applies when the earliest provisional piece is a straight or a `CURVE_2X2`: lock its whole one- or three-record span, even when that leaves fewer than five provisional records.

## 5. Construction, Rendering, and Cancellation

Construction continues at `build_cells_per_second`, one route record at a time. Starting or completing construction must not call a geometry-lock operation. A construction tick only changes `RESERVED_GHOST -> BUILDING -> BUILT`, build progress, and the traversable built endpoint.

Rendering is construction-state-driven only:

- `RESERVED_GHOST` remains translucent ghost track.
- `BUILDING` remains the current ghost interval with its solid completed prefix.
- `BUILT` remains normal solid track, including when its owning piece is provisional inside the head horizon.

Provisionality is internal. It adds no ghost tint, flicker, dashed line, outline, HUD marker, or other styling. A reclassification changes the solid curve/straight centerline drawn for a `BUILT` interval, but never makes it look unbuilt.

Right-click cancellation remains endpoint-suffix-only. Stage the complete target-to-end suffix only when the target and every later active record are both `RESERVED_GHOST` and provisional, and the suffix does not contain an active exit-support serial. In that case, remove and refund the staged suffix one record at a time, re-resolve the retained prefix, enforce the head horizon, and atomically commit route records, inventory, pieces, and any ledger expansion. This may cut the provisional geometry span containing the target, but it never changes a locked ledger entry.

If any record from the target through the active endpoint is locked, `BUILDING`, `BUILT`, recovered, an active exit-support serial, or otherwise ineligible, cancel nothing; there is no skipping over an ineligible record. A locked `RESERVED_GHOST` record is specifically ineligible. A support record is likewise ineligible regardless of whether its piece is still provisional or has independently locked; this is ledger-derived cancellation eligibility, not a new visual or production abstraction. Later provisional ghost suffix records after that support may still be canceled normally when their own target-to-end suffix excludes the support. Departure and empty targets are also no-ops. If re-resolution or horizon enforcement of an otherwise eligible staged cancellation fails, restore route records, inventory, pieces, and ledger exactly to their pre-cancel values. Each committed canceled record refunds exactly one inventory cell.

The snapshot's detached geometry-piece observations expose the active exit-support metadata already held by the ledger. `TrackFieldView` derives cancellation eligibility from those observations and the detached cell records: when a `RESERVED_GHOST` record is an active support serial, it suppresses the existing cancel-hover affordance and right-click remains a no-op. It adds no persistent icon, color, line style, HUD label, or other visual treatment.

## 6. Train Safety Boundary and Sampling Contract

The train may traverse the contiguous `BUILT` prefix, but it may sample only locked geometry. A `BUILT` record inside the head horizon is valid for construction presentation; it is not automatically safe for a train sample.

`GridTrackRuntime.prepare_for_train_sampling(current_distance, through_distance) -> bool` is the sole domain owner of staged ledger preparation; `TrackSystem` forwards that call without recreating its policy. A `true` result atomically commits the prepared ledger and pieces. A `false` result has rolled back every staged preparation change and commits nothing.

The operation uses deterministic epsilon-aware nominal ownership with `NOMINAL_BOUNDARY_EPSILON = 0.0001`. One shared runtime helper canonicalizes a distance and selects its boundary owner: values within the inclusive epsilon of a nominal piece boundary become that exact boundary; values outside epsilon retain their original side. First canonicalize both requested distances through that helper. For forward movement, prepare every active provisional piece whose nominal interval then has a strictly positive-length intersection with the requested travel interval `[current_distance, through_distance]`. A zero-length boundary contact therefore does not prepare a successor. At an internal boundary used as a zero-extent point (`current_distance == through_distance` after canonicalization), the active predecessor owns and supplies the point, so only that predecessor is prepared. Departure is the special case with no predecessor: prepare the active entry piece before departure and its temporary safety sample. If forward travel starts at an internal boundary and positively enters the successor interval, the successor is prepared. At the active route end, only the existing predecessor applies. The operation never recreates or locks a nonexistent or fully recovered piece.

The same shared canonical-distance/boundary-owner helper is mandatory for `GridTrackRuntime` preparation and every authoritative pose sample. `TrackSystem` routes position and heading requests to the runtime through this helper, and `TrainSystem.capture_pose` obtains both returned values through `TrackSystem`. The raw nominal motion distance may remain monotonic, but neither raw distance nor an independent selector may choose a different piece for preparation, position, or heading. A prepared locked owner is therefore the owner sampled by both fields of the captured pose; provisional geometry is never sampled.

Starting at the active locked frontier, preparation stages every intervening provisional whole piece required by that ownership rule, records any required exit-support serial under Section 4, re-resolves the remaining provisional suffix, and atomically commits the staged ledger and pieces. It is deterministic and idempotent and never creates an interior locked island. This freezes geometry only within the current/prospective sampled travel interval; ghost or building geometry beyond it remains able to reflow.

It is required:

1. immediately before departure, for the first bounded interval beginning at the departure safety point;
2. on each running fixed tick, after the built endpoint is known and before train movement, for `[current_distance, min(current_distance + speed * dt, built_end_distance)]`;
3. only through the train's monotonic departure and bounded advance paths; presentation consumes the resulting snapshot and may not request arbitrary future authoritative sampling.

If the safe interval has no forward extent because the train is already at the built endpoint, prepare the single point `[current_distance, current_distance]` under the predecessor-ownership rule. The subsequent track-end request behavior remains unchanged.

`TrainSystem.depart()` only activates nominal motion; it performs no geometry sampling. `TrainSystem.capture_pose(track_system) -> { position, heading }` is the sole authoritative position/heading pair sampler: through `TrackSystem` and the shared runtime helper, it obtains position and heading from the same canonical locked owner. `SessionController` calls it and retains the returned pair for snapshot publication. After a successful departure preparation, the order is: call `depart`, then call `capture_pose` at distance `0` only as a temporary safe-start capture. The one published running pose remains the post-motion capture described below.

On a running tick, the order is: prepare; advance nominal motion; call `capture_pose` exactly once; cache that pair; then recover and publish. Locking an entry piece before sampling ensures that later input cannot change the train's current position or heading. Locking the prospective travel interval ensures that no geometry morphs beneath the train during a tick. The resolver must preserve continuity at every locked/provisional stitch. Sampling uses the immutable ledger for every committed locked interval, including partially recovered pieces.

If `prepare_for_train_sampling` returns `false`, `SessionController` may assert the internal invariant for debug visibility, but it must take the deterministic safe return in every build: abort the remainder of that tick. Earlier input and construction phases remain committed. There is no departure, nominal advance, pose capture, recovery, elapsed/remaining timer change, session-state transition, completion/result event, or snapshot publication; the prior published snapshot remains cached. `PREPARING` remains `PREPARING`, `RUNNING` remains `RUNNING`, and train distance is unchanged. Provisional geometry is never sampled as a fallback.

Each running tick owns one **tick-local train pose**. Immediately after successful preparation and nominal motion, `capture_pose` returns the post-motion pair and the controller retains it through snapshot publication. Rear recovery may then remove the final active records and prune a fully recovered ledger entry, but that tick's snapshot must use the cached pair and must never re-sample the train after recovery. The departure-point capture is only a temporary safety capture; the one published tick-local pose is the post-motion capture.

On a terminal tick, only the terminal snapshot—not `SessionResult`—carries the captured position and heading. The existing `SessionResult` contract remains unchanged: it carries the existing completion reason and no train pose. Result creation and publication must not request geometry sampling.

## 7. Fixed-Tick Order

The amended active tick order is:

1. Consume one immutable input frame.
2. Apply right-click cancellation against the tick-start construction state and geometry lock state.
3. If right-click did not win, append left-drag candidates in observed order. For each candidate, resolve and enforce the head horizon transaction before accepting the next candidate.
4. Advance construction progress and mark completed records `BUILT`; do not lock because construction started or completed.
5. If preparing and the built-cell requirement is met, calculate the first bounded interval beginning at departure and call `prepare_for_train_sampling`. On `false`, abort the remainder of the tick under Section 6. On `true`, call `TrainSystem.depart`, temporarily call `capture_pose` at distance `0`, enter `RUNNING`, advance nominal motion over that already-prepared interval, call `capture_pose` exactly once, cache the post-motion tick-local pair, and record a track-end request when appropriate.
6. If the tick began `RUNNING` rather than transitioning in step 5, calculate the bounded train travel interval and call `prepare_for_train_sampling`. On `false`, abort the remainder of the tick under Section 6. On `true`, advance nominal train motion, call `capture_pose` exactly once, cache the tick-local pair, and record a track-end request when appropriate.
7. Run later warp/cargo and hazard movement hooks when their owning slices exist.
8. Recover eligible rear records in route order, refunding one record at a time; prune a ledger entry only when all of its owned records are recovered.
9. Run later warp-expiry hooks, advance the session timer, resolve end requests with existing regular-expiry priority, and publish one detached snapshot using the cached tick-local pose. If completed, only after that pose-bearing terminal snapshot is published, emit `session_completed` and publish one existing-contract `SessionResult` with the resolved reason; neither action may trigger geometry re-sampling.

Inventory recovered in step 8 remains unavailable to step 3 until the following tick. The changed order neither creates a same-tick inventory source nor changes the accepted end-priority rule.

## 8. Rejection and Rollback

Each left-drag candidate is a small transaction. Tentatively append exactly that candidate record, resolve it with locked-ledger, anchor, overlap, and head-horizon rules, and commit it only when all checks succeed.

If a candidate is invalid because of bounds, adjacency, duplicate ownership, inventory exhaustion, unresolved curve, locked conflict, failed anchor contact, or failed continuity, roll back only the tentative candidate suffix beginning with that candidate. Do not change accepted earlier candidates in the same input frame, prior cell states, prior inventory charges, route serial identity, absolute nominal distances, or the last valid geometry observation. Stop consuming that left-drag buffer at the first rejection, as the existing endpoint-only input contract requires.

Anchor updates follow Section 4.1 rather than route-rejection handling: the supplied anchors are always copied and retained. An invalid reflow under that new set rolls back only staged geometry and ledger changes, keeps the last valid geometry, and independently recomputes each anchor observation against its preserved active centerline; it never restores anchors, moves a warp, rerolls, or weakens a locked piece.

## 9. Invariants

The implementation must assert and test all existing grid-track invariants plus these:

- At every snapshot boundary, at most five active records belong to provisional pieces.
- Every geometry piece is wholly provisional or wholly locked; no piece crosses that state boundary.
- Locking is caused only by horizon enforcement or prepare-for-train-sampling, never by construction state transition.
- A `BUILT` provisional interval is rendered solid and remains geometrically eligible to reclassify.
- A locked ledger entry's immutable geometry, identity/range/distance, and exit-support metadata are byte-stable until all of its owned records recover.
- Active locked pieces form one contiguous route prefix and provisional pieces form the remaining contiguous suffix, including after recovery and a sampling preparation.
- The train's current and prospective sampled interval is covered by that locked prefix before motion and sampling. The shared canonical-distance/boundary-owner helper is used by preparation and both pose fields: values within inclusive epsilon canonicalize to a boundary, values outside retain their side, and an internal zero-extent boundary point belongs to its active predecessor while departure uses the active entry piece.
- After an anchor-reflow rollback, each retained current anchor independently reports true contact values only when the preserved active geometry slice enters its cell; no failed anchor forces an unrelated contacted anchor false. Anchor observations are never immutable ledger fields.
- A tick-local train pose is captured before recovery and is the only pose used by that tick's snapshot; `SessionResult` preserves its reason-only contract and never triggers pose sampling.
- An active exit-support dependency does not itself lock support geometry. The support piece remains provisional until independently locked by ordinary horizon enforcement or preparation, after which normal locked-piece invariants apply without changing the predecessor ledger entry or its support metadata. The support serial remains cancellation-ineligible while the dependent ledger entry survives; canceling a later suffix that excludes the support remains eligible.
- A failed preparation rolls back staged ledger changes and leaves the current session state, train distance, prior published snapshot, and all later tick phases unchanged as specified in Section 6.
- Locking, reflow, cancellation, recovery, and rejected input preserve `available_track_cells + active_route_cell_count = total_track_cells`.
- Reflow and locking do not renumber records, alter serial gaps, renormalize absolute nominal distances, change nominal motion speed, or change curve ownership counts.
- Locked-ledger resolution remains deterministic for identical active records, anchors, grid configuration, and prior ledger.
- No cancellation, append, or reflow can alter a locked footprint, centerline, kind, owned serial span, nominal length, absolute distance, or exit-support metadata.

## 10. Concrete Multi-Tick Scenario

Use a 60 Hz physics tick, `build_cells_per_second = 3.0`, and a normal human drag that crosses one cell every 0.35 seconds (21 physics ticks). From a departure immediately west of `B`, draw:

```text
B - C - D
        |
        E
        |
        F - G
```

`B..F` are five route records; `B..F` form the available `CURVE_3X3` around turn `D`, and `G` is appended after the curve.

At tick 0, `B` is reserved and receives its first of 20 construction steps. It completes on tick 19. The player reaches `C`, `D`, and `E` on ticks 21, 42, and 63; each receives its first same-tick construction step and completes on ticks 40, 61, and 82. At tick 84 the player adds `F`: `B..E` are solid `BUILT` intervals, while `F` is newly `RESERVED_GHOST` before construction and becomes `BUILDING` with its first of 20 construction steps in that tick.

**Current failure:** the current construction-start rule locked `B` as a straight at tick 0. When `F` arrives, the resolver cannot replace that locked straight with the five-record curve, so the best result is a smaller curve plus straights (or a rejection under a conflict fixture). The player sees a permanently less-smooth route despite providing the required route cells.

**Intended success:** at tick 84, `B..F` are still within the five-record provisional horizon. The resolver reclassifies the already-solid `B..E` intervals and the newly ghost/building `F` interval into one `CURVE_3X3`, without charging inventory or changing construction completion. At tick 105, the player appends `G`. The temporary six-record resolution contains the curve `B..F`; horizon enforcement locks that entire five-record curve and leaves `G`'s piece provisional unless and until ordinary horizon enforcement or train preparation independently locks it. Because `G` supplied the locked curve's terminal midpoint/tangent, its serial is an exit-support dependency: it cannot be canceled while the curve survives. That later independent lock preserves the existing `B..F` ledger entry and its support metadata. If a test configuration permits departure at the five-built-cell threshold after `F` completes, `prepare_for_train_sampling(0.0, 0.0)` locks `B..F` immediately before departure, so the first train position and heading are sampled from the immutable curve. Later input can reflow only `G` and later records until their own pieces lock; it cannot move the train.

## 11. Likely Implementation Allowlist

A separate approved implementation plan must make the final allowlist exact. The likely task-scoped paths are:

- `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_resolver.gd`
- `godot-project-moe-rail-way/src/domain/track/track_geometry_piece.gd`
- `godot-project-moe-rail-way/src/domain/train/train_system.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_geometry_resolver.gd`
- `godot-project-moe-rail-way/tests/unit/test_nominal_train_motion.gd`
- `godot-project-moe-rail-way/tests/unit/test_train_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd`
- `godot-project-moe-rail-way/tests/manual/track_train_windows.md`

No `.gd.uid` file may be omitted if an added or renamed GDScript path requires one. Configuration resources, scenes, unrelated session behavior, cargo, warp generation, economy, and production abstractions are outside the expected scope unless a later plan explicitly justifies them.

`src/domain/session/session_result.gd` is deliberately outside this likely scope: the existing reason-only `SessionResult` contract is preserved without a pose field or geometry-sampling responsibility.

## 12. Verification Strategy

The later implementation plan must pin the exact then-current verified `main` commit and require Godot `4.7.1`, a `PASS: 19` automated baseline, and the four standalone integration checks: session-shell, logical-track-field, track-train-input, and track-train-app. It must then define its exact task allowlists, RED evidence, focused commits, and independent specification and quality reviews. Implementation begins only from that pinned verified `main` baseline in the dedicated feature worktree.

Automated RED and GREEN coverage must prove:

- a built early straight remains geometrically provisional and becomes the matching `CURVE_3X3` when its later four owned records arrive;
- the same built records render solid before and after that reclassification;
- the stable head contains at most five records, and the `B..F`/`G` straddling fixture locks the whole curve rather than splitting or downgrading it;
- `1x1`, `2x2`, and `3x3` whole-piece horizon exits are deterministic;
- construction alone does not lock a piece, while both horizon enforcement and train sampling do;
- epsilon-aware preparation locks only pieces with positive-length intersection with forward travel; a zero-extent wait at a built internal endpoint prepares the predecessor only, leaves the following ghost/building piece unlocked, and permits that following piece to reflow into valid `2x2`/`3x3` geometry before actual entry;
- fixtures at `boundary - epsilon`, exact boundary, `boundary + epsilon`, and just outside epsilon on both sides prove preparation and `capture_pose` use the same canonical locked owner for both position and heading and never sample provisional geometry;
- `prepare_for_train_sampling` is runtime-owned, returns `bool`, and on failure rolls back staged preparation; separate PREPARING and RUNNING fixtures prove input/construction persist but train distance, state, recovery, timer, events, snapshots, and result publication remain unchanged with no provisional fallback sample;
- a locked piece remains immutable through later append, anchor update, cancellation attempt, partial recovery, and repeated resolution;
- one same-serial B–F fixture begins as a fully `BUILT`, provisional `CURVE_3X3`, locks that complete piece through `prepare_for_train_sampling`, and then recovers it at cutoffs `1`, `2`, and `3` with exactly one refund per call; through every recovery the immutable kind, serial range, footprint, centerline, nominal length, absolute start, and exit-support metadata remain unchanged while only the active local slice start advances by one, the locked-prefix/provisional-suffix invariant holds, and inventory conservation remains true;
- a mixed-anchor fixture proves an authoritative failed reflow retains copied anchors and last valid geometry while independently publishing true/true for a still-contacted anchor and false/false only for the unsatisfied anchor;
- a slow-build fixture appends `G` so a locked `B..F` curve records `G` as exit support; canceling `G` is a no-op with no refund or geometry change, its cancel hover is absent, and a valid later continuation from fixed `G` preserves locked/provisional stitch continuity;
- the same support fixture proves the `B..F` ledger support metadata survives unchanged when `G`'s own piece later locks independently and then follows normal locked-piece invariants;
- cancellation commits only when its complete target-to-end suffix is provisional `RESERVED_GHOST` and excludes active exit-support serials; it refunds each staged record once, re-resolves the retained prefix, and restores route, inventory, pieces, and ledger exactly on failure or an ineligible suffix;
- a locked `RESERVED_GHOST` interval and an active exit-support `RESERVED_GHOST` interval are both not hover-cancelable, and a right-click on either is a no-op without any new persistent visual style;
- rejected append rolls back only its tentative suffix and preserves prior pieces, inventory, serials, distances, and contact observations;
- with zero recovery lag, exact track end, and full final-piece recovery in one tick, the terminal snapshot retains the pre-recovery captured position and heading without re-sampling after ledger pruning;
- the pose-bearing terminal snapshot event occurs before `session_completed` and result publication, while the existing `SessionResult` reason is verified separately and carries no pose;
- overlap downgrade, anchor-contact requirements, endpoint-only drag, route serial gaps, inventory conservation, nominal curve timing, build speed, rear recovery, and fixed-tick input/end priorities regress cleanly.

Run the complete project automated suite after the focused tests. The Windows manual play must visibly demonstrate: a normal-speed draw whose already-solid head becomes a larger solid curve; no provisional ghost styling; a train that does not jump when the player continues drawing; rejected input retaining the last valid track; and endpoint-only cancellation. The same-serial provisional-to-lock-to-recovery lifecycle, including one-cell refund cadence and immutable-ledger preservation, is an automated requirement; Windows manual evidence must not be used as its proof.

## 13. Non-Goals

This amendment does not add predictive curve previews beyond existing geometry, player-selectable curve sizes, a route editor, manual demolition, dynamic track length, new art, a new HUD state, adaptive train speed, pixel-distance motion, or any change to cargo, warp spawning, reachability, hazards, economy, credit, fleets, or campaign progression.

It does not revisit the accepted grid origin, cell rasterization, logical viewport mapping, departure selection, anchor semantics, fixed session lifecycle, or branch-management policy. It also does not authorize implementation, merge, push, pull-request creation, tagging, or cleanup by itself.

## 14. Acceptance Criteria

This amendment is implemented only when all of the following are evidenced:

- Recently completed route-head intervals can reclassify from straight to a valid matching curve while remaining visually solid.
- Geometry provisionality is absent from presentation styling; only `RESERVED_GHOST`, `BUILDING`, and `BUILT` control the existing visual states.
- Every stable snapshot has a deterministic, piece-aligned, maximum-five-record provisional head horizon, including the specified curve-straddling case.
- Construction completion does not lock geometry.
- Horizon exit and prepare-for-train-sampling lock full pieces into the immutable ledger, and no geometry can morph within or under the train's current and prospective sampled interval; geometry farther ahead may still reflow inside the head horizon.
- The shared epsilon-aware canonical-distance/boundary-owner helper leaves a successor unlocked at a zero-extent internal boundary and prepares it only when forward travel positively enters it; preparation and both captured pose fields select the same locked owner at boundary-minus, exact, boundary-plus, and outside-epsilon fixtures.
- Anchor updates are always retained as authoritative state; an unsatisfied provisional reflow retains last valid geometry and independently reports each anchor's preserved-geometry contact, rather than rejecting, relocating, or rerolling the anchors.
- Locked geometry ledger entries may carry only immutable exit-support serial metadata. The dependency itself does not lock or style support geometry: it remains provisional until independently locked, then follows normal locked-piece invariants without changing the predecessor metadata. While active, it is cancellation-ineligible and has no cancel-hover affordance, but can otherwise reflow and support a continuous later extension.
- Train position and heading remain continuous through reflow, locking, piece boundaries, partial rear recovery, and a terminal snapshot on a tick that fully recovers the final piece.
- Automation, not Windows manual play, proves the same B–F serials survive the complete provisional `CURVE_3X3` to prepared whole-piece lock to sequential cutoff-`1`/`2`/`3` recovery lifecycle with one-cell refunds, immutable metadata, advancing active slice, contiguous locked/provisional ownership, and conserved inventory.
- The terminal snapshot uses the tick-local pose captured before recovery, never a post-pruning re-sample; only after it is published may `session_completed` and the unchanged reason-only `SessionResult` publish without sampling geometry.
- All conserved inventory, sequential construction/recovery, serial identity, nominal-distance, overlap/downgrade, anchor, input, and game-premise contracts remain true.
- Rejected input preserves the last valid geometry and rolls back only the triggering tentative suffix.
- Focused RED/GREEN tests, the pinned `PASS: 19` regression gate and four standalone integrations, independent specification review, independent quality review, and the Windows manual scenario all pass on the feature branch.
