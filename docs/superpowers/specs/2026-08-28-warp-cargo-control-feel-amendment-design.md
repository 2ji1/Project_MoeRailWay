# Warp Cargo Control-Feel Amendment Design

- Date: 2026-08-28
- Status: Implemented and integrated on `main`; final-head four-size manual re-verification remains outstanding
- Audience: Agent-facing canonical specification
- Implementation branch: `feature/warp-cargo` (removed after integration)
- Historical external worktree: `D:\godot\MoeRailWay-worktrees\warp-cargo` (removed after integration)
- Verified feature base: `b5d33117d08ed3e14269b353f2a84a72c4f24a0c`
- Verified merge base: `edebc32c977300ed21ee163b89d42624cf070bf3`
- Parent Warp Cargo design: `docs/superpowers/specs/2026-08-28-warp-cargo-design.md`
- Route authority: `docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md`
- Gesture authority: `docs/superpowers/specs/2026-08-26-endpoint-track-reshaping-design.md`
- Branch authority: `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`
- Implementation plan: `docs/superpowers/plans/2026-08-28-warp-cargo-control-feel-amendment.md`
- Reviewed feature HEAD: `402c9a28913acb24047a35cfcd4d5b8c2bb752f1`
- Integration: [PR #17](https://github.com/2ji1/Project_MoeRailWay/pull/17), merge commit `e42d9a6ccc64c55da44ee8e5fddc6f40e48c2874`, tag `prototype-m5`
- Verification: pre-amendment feature HEAD `b5d33117d08ed3e14269b353f2a84a72c4f24a0c` passed the complete deterministic and mouse-only four-size matrix; final reviewed HEAD `402c9a28913acb24047a35cfcd4d5b8c2bb752f1` received independent specification and quality approvals and passed the targeted `1280x720` locked-endpoint anchored-turn regression; post-merge `main` at `e42d9a6ccc64c55da44ee8e5fddc6f40e48c2874` passed `PASS: 24 prototype test suite(s)` plus five standalone integration runners, but the complete four-size control-feel checklist was not repeated on that final state

## 1. Outcome

Refine the completed Warp Cargo prototype so route planning reads as deliberate spatial play instead of a reflex test.

This amendment makes three user-confirmed changes:

1. An active Warp cell becomes an exact cell-center snap knot for route geometry that the player draws through that cell.
2. The session departure marker dissolves after the train departs.
3. While a valid endpoint left-drag gesture is active during `RUNNING`, domain simulation advances at 25 percent speed while pointer capture and route preview remain fully responsive.

The amendment preserves the existing one-train, one-line, continuously moving premise. It adds no pause, automatic route generation, reachability correction, reroll, pathfinding, or route-aware random filtering.

## 2. Authority and Supersession Boundary

This document supersedes only these clauses of the parent designs:

- Warp Cargo active anchors change from cell-entry coverage to exact cell-center snap knots.
- Warp Cargo contact hits for those exact anchors occur at the knot rather than on first entry into the surrounding cell.
- The fixed-tick controller gains a real-tick input layer and a deterministic planning cadence for domain simulation.
- The departure marker no longer remains visible for the whole configured session.

The following contracts remain unchanged:

- forecast points are informational, anchor-free, and geometry-neutral;
- generated cells are never moved, rejected, rerolled, or corrected;
- the player still supplies the complete ordered orthogonal route-cell sequence;
- unlocked geometry may re-resolve, while locked geometry never changes;
- impossible Warp pairs remain valid outcomes;
- route inventory, nominal distance, construction ownership, cargo capacity, delivery reward, session-end priority, and deterministic RNG order remain as previously specified.

This is a prototype amendment. It does not authorize production abstractions or later feature slices.

## 3. Fixed Product Decisions

### 3.1 Exact Warp snap

Every `ACTIVE_UNLOADED` Warp origin and destination publishes an exact cell-center anchor. Every `IN_TRANSIT` Warp publishes only its exact destination anchor. Forecast and terminal pairs publish none.

An exact anchor constrains geometry only when its cell is the departure cell or one of the player's active ordered route cells. The resolver never inserts the Warp cell into the route, chooses neighboring cells, or bends a route that the player did not reserve.

### 3.2 Departure dissolve

The selected departure marker remains fully visible through `READY` and `PREPARING_DEPARTURE`. The first presented `RUNNING` snapshot starts a `0.75` real-second alpha dissolve. The marker is not drawn after the dissolve completes.

This is presentation state only. The departure cell, route origin, absolute nominal distance, and train sampling remain unchanged.

### 3.3 Planning slowdown

The default planning scale is `25` percent. It is active only while all of the following are true:

- the session is in `RUNNING`;
- a left gesture has already been accepted from the current active endpoint; and
- the runtime gesture remains active.

Invalid presses, presses away from the endpoint, ordinary hover, right-click without an active gesture, and a merely held button after a rejected or terminated capture do not slow simulation. `PREPARING_DEPARTURE` remains untimed and uses the normal cadence.

### 3.4 Recovered departure-cell reuse

The departure cell remains a free, non-reservable route origin until rear recovery advances the active route predecessor beyond that origin. After at least one route record has been recovered and the active predecessor is no longer the departure cell, the recovered departure coordinate becomes an ordinary reservable route cell. It costs one inventory cell, receives a fresh monotonic route serial and absolute nominal distance, participates in geometry and contact resolution normally, and may be used as an exact Warp knot when an active Warp occupies it. When an active route record owns the departure coordinate, exact-anchor lookup selects that record occurrence and its centerline distance. Only the free origin occurrence, with no active record owning the coordinate, uses distance `0.0`.

If a later recovered route record is itself the departure coordinate, that coordinate becomes the active predecessor boundary again and is not immediately reservable a second time. It becomes eligible again only after recovery advances beyond it. Active-cell uniqueness, orthogonal continuity, geometry overlap rejection, train locking, and inventory conservation remain unchanged. A retained locked piece continues to block with its complete curve footprint except for exact cells explicitly present in that piece's recovered-cell map. Runtime resolution removes only those recovered cells from a detached blocking copy; non-record bounding cells and every unrecovered cell remain blocked. The source locked footprint, full centerline, immutable ledger identity, and train-sampling interval remain intact.

This rule does not move the route distance origin, recreate the dissolved departure marker, reset train distance, or permit reservation through active or unrecovered geometry. It only removes the permanent historical blacklist after the coordinate is safely behind the train.

### 3.5 Locked-endpoint exact-turn stitching

A running gesture may begin after train sampling has locked the current route endpoint. The locked endpoint remains byte-unchanged, but a newly reserved exact Warp cell immediately beyond it may own the first turn of the unlocked successor. In that case the successor's declared entry-heading override is the authoritative direction for testing whether its boundary gap continues forward from the locked predecessor. The first successor centerline point may then stitch to the locked predecessor endpoint through the existing successor-only stitch; the exact Warp knot, owned span, footprint, nominal length, and remaining centerline samples stay unchanged.

The stitch is legal only when the locked predecessor's exit heading, the boundary-gap heading, and the unlocked successor's authoritative entry heading all agree within the existing tangent epsilon. It never rewrites a pre-existing locked centerline, relaxes a backward or sideways gap, changes overlap policy, or permits a curve without the player reserving its ordered cells. A non-forward boundary remains unstitched by the resolver and is rejected by the runtime's existing piece-continuity validation; continuity ownership does not move into the resolver. Finalization may retire the newly accepted successor through the existing stable-retirement contract; that normal ledger append does not weaken the byte-unchanged requirement for every piece that was already locked when the gesture began.

## 4. Exact Cell-Center Anchor Contract

`RouteContactAnchor` gains a concrete contact mode:

```gdscript
enum ContactMode {
    CELL_ENTRY,
    EXACT_CELL_CENTER,
}
```

The existing constructor default remains `CELL_ENTRY`, preserving non-Warp and legacy fixtures. `WarpPairSystem` explicitly creates every active Warp anchor with `EXACT_CELL_CENTER`.

An exact anchor has one canonical world position:

```text
grid_origin_units
+ (Vector2(anchor.cell) + Vector2(0.5, 0.5)) * grid_cell_size_units
```

Exact contact uses a deterministic `0.0001` logical-unit distance epsilon. Footprint overlap or entry into the surrounding cell is insufficient.

### 4.1 Unlocked geometry

If an exact anchor cell is an active route record owned by an unlocked piece, that cell center becomes a hard knot in that piece's centerline. Hard knots are ordered by route serial and then stable anchor ID. Multiple Warp anchors in the same cell collapse to one geometric knot while retaining separate gameplay anchor IDs.

Straight pieces already pass through their owned cell center and retain their existing two-point centerline byte-for-byte. They are not resampled to the anchored-curve cadence. Exact contact on a straight uses the existing linear projection at the route record's nominal midpoint. For an anchored curve:

1. Preserve the accepted `CURVE_1X1`, `CURVE_2X2`, or `CURVE_3X3` owned span, footprint, nominal length, entry boundary, exit boundary, incoming tangent, and outgoing tangent.
2. Build ordered hard points from the entry boundary, exact anchor centers, and exit boundary.
3. Give the entry hard point sample index `0`, each exact knot owned by local route-record offset `i` sample index `(i * 16) + 8`, and the exit hard point sample index `nominal_length_cells * 16`.
4. Assign the entry and exit tangent unit vectors from the existing template headings. Assign each interior knot the normalized vector from its previous distinct hard point to its next distinct hard point.
5. Define a hard point's base handle length as one third of the shorter adjacent chord. An endpoint has one adjacent chord, so it uses one third of that chord. For each consecutive hard-point segment `A -> B`, clamp both endpoint handle lengths again to at most one third of `A.distance_to(B)`. The cubic controls are `A + tangent_A * handle_A` and `B - tangent_B * handle_B`.
6. For every integer sample index between the hard-point indices, evaluate that cubic at `t = (sample_index - index_A) / (index_B - index_A)`. Consecutive segments share their hard-point sample exactly. This produces exactly `nominal_length_cells * 16 + 1` points and makes `sample_nominal(i + 0.5)` return the exact Warp center.
7. Use the existing `0.0001` distance and tangent epsilon for exact-center, boundary continuity, and heading checks. Validate the entry sample at index `0` and exit sample at the final index only through the existing boundary and tangent-continuity contract because each lies on a shared cell boundary whose `floor` mapping is direction-dependent. Every interior generated sample must map to a cell inside the accepted piece footprint, except that a first-route curve may retain its necessary departure-center-to-first-boundary lead-in samples inside the departure cell. That lead-in exception does not add the departure cell to the accepted route footprint or route ownership.
8. When an anchored candidate fails these checks, follow the existing deterministic candidate loop: decrement `3x3 -> 2x2 -> 1x1`; reject the newly staged suffix only if `1x1` also fails. Locked pieces never enter this downgrade.

Unanchored templates retain their existing centerlines byte-for-byte. The amendment is not a general spline rewrite.

### 4.2 Departure-cell exact anchor

The departure cell is the one permitted exact anchor without an active route record. In that free-origin state, its center is the route's nominal distance `0.0` and already forms the first centerline boundary. The first positive train sweep may therefore contact it at `0.0`, preserving the accepted same-cell departure behavior. If an active route record owns the same coordinate after reuse, that active occurrence takes precedence and uses its fresh nominal midpoint rather than the origin distance.

### 4.3 Locked geometry and impossible outcomes

Activation never changes a locked piece. If its existing centerline does not contain the exact cell center, the anchor publishes `contact_possible = false` and remains visible until loading, expiry, or void changes its lifecycle.

An exact anchor whose cell is neither the departure cell nor an active route record is also `contact_possible = false`. The resolver does not pull the line toward it, append the cell, or modify the request.

Updating or removing anchors may re-resolve only unlocked geometry through the existing atomic candidate contract. A failed reflow preserves the last valid geometry and reports the anchor as impossible.

When the current endpoint itself is locked, the first newly reserved successor remains unlocked. If that successor becomes an exact anchored turn, its explicit entry heading participates in the existing forward-gap stitch. This joins the new curve positionally to the immutable endpoint without treating the anchored curve's first interior sample as its boundary tangent. Locked geometry and its sampling metadata remain byte-unchanged.

If activation, loading, delivery, expiry, or void changes anchors while an endpoint gesture is active, the new authoritative anchor set advances both the evolving gesture origin and the live candidate before later input on that simulation tick. Right-click abort may undo the player's route edit, but it may not discard an anchor that legitimately activated or resurrect an origin anchor that legitimately disappeared while domain time advanced. If either route form cannot re-resolve, it preserves its last valid geometry with the new anchor observation marked impossible.

Every contact observation retains the existing keys and adds detached `contact_mode` and `contact_distance_cells` values. Exact possible anchors publish their canonical absolute nominal distance. Impossible exact anchors and legacy cell-entry anchors publish `-1.0` because legacy cell coverage may have more than one entry distance and keeps its existing swept-query calculation.

## 5. Exact Contact-Hit Contract

`GridTrackRuntime.get_contact_hits_between(previous, through)` keeps its public shape and ordering. It handles each anchor according to its mode:

- `CELL_ENTRY` retains the accepted one-eighth-cell outside-to-inside sampling behavior.
- `EXACT_CELL_CENTER` uses the authoritative exact-knot observation and its nominal contact distance.

For a newly constrained exact anchor owned by route-record offset `i` inside an unlocked piece, the nominal contact distance is:

```text
piece.absolute_start_distance_cells + i + 0.5
```

The free-origin departure-cell distance is `0.0`. When an active route record reuses that coordinate, its selected occurrence uses the record-owning piece's center projection and fresh absolute nominal distance instead. A previously locked centerline that already passes through the exact center uses the earliest matching centerline-segment projection within the selected occurrence, converted through the piece's canonical uniform nominal sampling to an absolute nominal distance. An exact hit occurs once when the authoritative distance lies in the half-open sweep `(previous, through]`, with the existing first-positive-movement exception for the free-origin `0.0`. Exact anchors with `contact_possible = false` emit nothing.

Raw hits remain ordered by contact distance and stable anchor ID. `WarpPairSystem` retains origin-before-destination and pair-ordinal tie ordering, so equal-cell loading and delivery still resolve once in the same sweep.

Loading, delivery, expiry, and reward timing do not move. The only behavior change is that Warp cargo contact is aligned with the visible Warp center instead of the earlier cell boundary.

## 6. Real-Tick and Simulation-Tick Contract

The app continues to sample one immutable `TrackInputFrame` on every Godot physics tick. `Engine.time_scale` is never changed.

The controller distinguishes:

- **real tick:** every physics callback; consumes input and may publish route-preview changes;
- **simulation tick:** advances construction, departure readiness, train movement, contact, recovery, Warp lifecycle, and session time.

Outside planning slowdown, every real tick contains one simulation tick. During planning slowdown, a fixed-point accumulator adds `planning_time_scale_percent` on each real tick that begins with an active valid running gesture. A simulation tick runs when the accumulator reaches at least `100`, after which `100` is subtracted. At the default `25`, exactly one simulation tick runs per four planning real ticks.

The real tick on which a valid press first starts a gesture remains one canonical simulation tick; its published snapshot reports planning active, the configured `25`, and `did_advance_simulation_tick = true`. Slowdown begins on the next real tick after the gesture is authoritatively active. If release, abort, completion, or train-safety termination ends the gesture on a slowed real tick, unused accumulator credit is discarded. Normal one-for-one simulation resumes on the next real tick. There is no catch-up burst or time debt.

### 6.1 Per-real-tick priority

1. Read whether a valid running gesture is active at real-tick start and determine whether a simulation tick is due.
2. If a simulation tick is due and the session already begins in `RUNNING`, perform Warp forecast decrement, activation, due generation, and anchor installation.
3. Consume right-click and left-gesture input exactly once. Candidate geometry and hover observations remain responsive on every real tick.
4. If no simulation tick is due, publish a detached snapshot with no repeated Warp event payload and stop this real tick.
5. If due, advance construction.
6. Resolve departure readiness. A transition into `RUNNING` performs the existing first Warp running tick before train movement.
7. Advance and sample the train.
8. Resolve exact and legacy contact hits, cargo transitions, and anchor updates.
9. Recover eligible rear cells.
10. Expire Warp pairs.
11. Advance the running session timer.
12. Resolve regular-end priority, publish one snapshot, and emit at most one result.

Warp events remain one-snapshot observations. A skipped planning real tick publishes an empty event array rather than repeating the previous simulation tick's delivery, expiry, or void event.

## 7. Construction and Recovery During an Active Gesture

Input responsiveness does not freeze legitimate simulation work.

Construction continues on simulation ticks using the existing paired update of the live candidate and its evolving gesture-origin sequence. Right-click abort therefore removes the route edit but retains construction time that legitimately elapsed while the gesture was held.

Warp anchor lifecycle advances through the same evolving transaction boundary. On a due simulation tick, the latest authoritative anchor set replaces the anchor set in both the evolving gesture origin and current candidate. Each route form atomically re-resolves only unlocked geometry, retains locked geometry byte-unchanged, and records impossible exact contacts honestly. Later preview updates, finalize, and abort all use that evolved anchor set. They never restore press-time anchors after activation, loading, delivery, expiry, or void legitimately changed them.

Recovery changes from its current active-gesture no-op to the same transactional rule:

- calculate eligible recovered records only on simulation ticks;
- remove the same eligible pre-gesture records from both the evolving gesture origin and the published candidate;
- update both locked ledgers, recovered-piece facts, recovered nominal frontier, and inventory refunds consistently;
- preserve gesture-added suffix records, which cannot be behind the train;
- never defer eligible recovery into a release-time batch.

Paired recovery must succeed for every valid runtime state. If staging either route form fails validation, debug execution asserts at the recovery owner and release-style execution leaves the gesture origin, live candidate, ledgers, recovery frontier, and inventory byte-unchanged for that simulation tick. It does not choose between termination and preservation, does not partially recover, and does not retry a batch on release.

Right-click abort restores the route-edit origin as evolved by legitimate construction and recovery simulation, not the stale state from the press instant. This matches the existing construction behavior and prevents time travel.

## 8. Snapshot and Presentation Contract

`SessionSnapshot` adds detached scalar observations:

```gdscript
func is_planning_slowdown_active() -> bool
func get_planning_time_scale_percent() -> int
func did_advance_simulation_tick() -> bool
```

The percentage is the validated copied session value. `did_advance_simulation_tick` distinguishes a responsive input-only snapshot from a domain simulation step and supports deterministic tests without exposing accumulator internals.

`TrackFieldView` draws a primitive `PLANNING 25%` indicator while slowdown is active. It remains real-time, does not intercept input, and disappears on release, abort, train-safety termination, completion, or any non-running state.

`TrackFieldView.get_render_observation()` adds:

```gdscript
"departure_marker": {"visible": bool, "alpha": float},
"planning_indicator": {"visible": bool, "text": String},
```

Both Dictionaries are freshly detached on every call. The indicator uses the existing fallback font and a primitive contrasting backing near the field's top-left. Exact styling remains prototype presentation discretion; Windows manual verification owns readability, contrast, and non-overlap at every supported size. Automated tests do not assert backing color, opacity, size, padding, or placement, and those presentation details are not added to the public render observation.

The departure marker exposes a detached presentation observation containing current alpha and visibility. Its dissolve:

- starts once on the first `RUNNING` presentation;
- advances from real `_process(delta)`, independent of domain slowdown;
- clamps alpha from `1.0` to `0.0` over exactly `0.75` seconds;
- uses `0.0001` as the automated alpha comparison epsilon;
- never restarts on later snapshots;
- resets only when a new session is configured.

Warp countdowns, session time, construction, train position, and recovery observations change only on simulation ticks during planning. Pointer position, live candidate geometry, hover, planning indicator, and departure dissolve remain real-time.

## 9. Deterministic Acceptance Scenarios

1. An active Warp anchor explicitly uses `EXACT_CELL_CENTER`; forecast and terminal pairs remain anchor-free.
2. A straight route through a Warp cell contacts its exact center.
3. Anchored `1x1`, `2x2`, and `3x3` curves preserve their template ownership and pass the Warp center exactly at the route record's nominal midpoint.
4. Selecting a different endpoint template during one gesture rebuilds a valid exact-knot curve from the gesture origin.
5. Multiple active Warp IDs in one cell share one geometric knot and retain deterministic origin/destination hit order.
6. An anchor in a curve footprint but absent from the route sequence cannot bend or correct the route and reports impossible.
7. Activation reflows only unlocked geometry. Locked off-center geometry stays byte-unchanged and reports impossible.
8. Anchor activation or removal during a gesture evolves both the gesture origin and live candidate, so abort cannot reverse legitimate Warp time.
9. Exact contact emits at the knot distance, not on surrounding-cell entry, and does not repeat across adjacent sweeps.
10. Equal-cell origin and destination load and deliver once at the same exact knot distance when capacity exists.
11. A valid running endpoint gesture changes route preview on every real tick while train, construction, recovery, Warp lifetime, generation cadence, and session time advance once per four real ticks at the default scale.
12. Invalid clicks and held rejected capture never slow simulation.
13. Pre-departure construction remains normal speed.
14. Releasing or aborting planning creates no catch-up movement, construction, recovery, Warp time, or session time.
15. Recovery during planning advances transactionally instead of freezing and batching at release.
16. Skipped real-tick snapshots contain no repeated Warp event.
17. `PLANNING 25%` appears only while the accepted running gesture remains active.
18. The departure marker is opaque before departure, partially visible during its 0.75-second dissolve, and absent afterward without changing domain departure facts.
19. Existing route, cargo, RNG, lifecycle, resize, result-priority, and manual Warp Cargo scenarios remain green after updating only their intended exact-contact tick expectations.
20. Before rear recovery advances beyond the route origin, the departure cell cannot be reserved as track; afterward, a valid endpoint gesture may reserve the recovered coordinate with fresh identity, exact inventory accounting, normal geometry validation, and no change to route distance origin or departure presentation.
21. After train sampling locks the current endpoint, a held gesture through an adjacent exact Warp cell and then into a first turn publishes and finalizes the whole ordered suffix; the locked predecessor stays byte-unchanged and non-forward gaps remain rejected.

## 10. Scope Exclusions

- Pause, stop, reverse, branch, merge, multiple trains, or automatic pathfinding.
- Automatic Warp reachability checks, rerolls, cell relocation, route correction, or route insertion.
- Freehand splines, arbitrary control-point editing, generic curve frameworks, or a production geometry API.
- Bullet time outside a valid running endpoint gesture.
- Risk & Investment, Contract Economy, Credit Survival, purchasable upgrades, custom art, audio, mobile, touch, or gamepad support.
- Global time scaling, variable-delta domain simulation, frame-rate-dependent RNG, or catch-up simulation bursts.

## 11. Definition of Done

This amendment is complete only when:

- every deterministic acceptance scenario has focused executable evidence;
- the default planning scale is validated, copied, and Inspector-editable as an integer percentage;
- exact Warp centers constrain only player-owned unlocked route geometry;
- locked or absent-route impossible outcomes remain uncorrected;
- input and preview stay responsive at full physics frequency without `Engine.time_scale`;
- all named domain systems advance only on deterministic simulation ticks during planning;
- recovery progresses transactionally during the gesture and never batches on release;
- departure dissolve and planning feedback pass automated presentation checks and Windows manual play at all supported 16:9 sizes;
- the recovered departure coordinate is reusable only after the active predecessor advances beyond it, while pre-recovery reservation and immediate predecessor reuse remain rejected;
- an exact anchored first turn after a locked endpoint stitches through its authoritative entry heading without mutating locked geometry;
- the complete 24-suite target and every integration runner pass without rejected diagnostics;
- each implementation task preserves RED, minimum GREEN, regression, explicit allowlist, exact staging, focused commit, independent specification review, and independent quality review;
- no push, pull request, merge, tag, primary synchronization, or cleanup occurs without separate approval.
