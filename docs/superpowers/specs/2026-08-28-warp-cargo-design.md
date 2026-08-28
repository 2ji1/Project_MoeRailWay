# Warp Cargo Prototype Slice Design

- Date: 2026-08-28
- Status: Implemented and integrated on `main`; final-head four-size manual re-verification remains outstanding
- Audience: Agent-facing canonical specification
- Active branch policy: `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`
- Product authority: `docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md`
- Runtime strategy: `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`
- Consumed route authority: `docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md`
- Implementation plan: `docs/superpowers/plans/2026-08-28-warp-cargo.md`
- Normative amendment: `docs/superpowers/specs/2026-08-28-warp-cargo-control-feel-amendment-design.md`
- Reviewed feature HEAD: `402c9a28913acb24047a35cfcd4d5b8c2bb752f1`
- Integration: [PR #17](https://github.com/2ji1/Project_MoeRailWay/pull/17), merge commit `e42d9a6ccc64c55da44ee8e5fddc6f40e48c2874`, tag `prototype-m5`
- Verification: pre-amendment feature HEAD `b5d33117d08ed3e14269b353f2a84a72c4f24a0c` passed the complete deterministic and mouse-only matrix at `960x540`, `1280x720`, `1600x900`, and `1920x1080`; final reviewed HEAD `402c9a28913acb24047a35cfcd4d5b8c2bb752f1` received independent specification and quality approvals and passed the targeted `1280x720` locked-endpoint anchored-turn regression; post-merge `main` at `e42d9a6ccc64c55da44ee8e5fddc6f40e48c2874` passed `PASS: 24 prototype test suite(s)` plus five standalone integration runners, but the complete four-size control-feel checklist was not repeated on that final state

## 1. Outcome

Add the next concrete prototype slice: seeded, finite-lifetime warp origin-destination pairs; automatic cargo loading and delivery; finite cargo slots; an immediate base delivery reward; and readable placeholder feedback.

The slice must create route and capacity choices without weakening the accepted game premise. A generated request may be impossible. The implementation must expose that outcome honestly rather than correcting the request or the route.

This document specifies prototype behavior only. It neither implements production architecture nor decides which prototype classes will later be abstracted or ported into `Development`.

## 2. Fixed Context

- Target platform: Windows PC.
- Input: mouse only.
- View: top-down orthographic 2D with a map-dominant session layout inspired by Mini Metro.
- Train: exactly one train, moving continuously after departure at the accepted fixed positive speed.
- Route: one ordered, nonbranching grid route.
- Randomness: one explicit session seed and deterministic event order.
- Presentation: primitive colors, geometric shapes, default fonts, and existing layout Resources.
- Mobile, touch, gamepad, and responsive mobile layout remain full-production scope.

## 3. Scope

### 3.1 Included

- Seeded generation of origin-destination pairs over the complete in-bounds grid.
- Forecast, activation, active-unloaded, in-transit, delivered, expired, and regular-end-void states.
- Finite point lifetime sampled deterministically inside validated bounds.
- Stable origin and destination `RouteContactAnchor` values while a pair is active.
- Deterministic swept train-contact observation over the existing nominal route centerline.
- Automatic loading into the lowest-index empty slot.
- Automatic matching delivery and one base reward per delivered pair.
- Cargo removal on destination expiry and on regular session end.
- Empty, full, and mixed cargo-slot behavior.
- Detached pair, cargo, delivery, reward, and countdown observations in session snapshots and results.
- Color-and-shape placeholder feedback for forecast points, active points, in-transit cargo, delivery, expiry, and void outcomes.
- Inspector-editable lifecycle and cargo balance Resources with explicit validation.
- Deterministic unit tests, fixed-seed integration tests, and Windows manual verification.

### 3.2 Excluded

- Risk & Investment, including hazards, durability, repair, paid demolition, and crossings.
- Contract Economy, including companies, quotas, trust, settlement, or persistent cash ownership.
- Credit Survival, including borrowing, repayment, bankruptcy, and cycle progression.
- Purchasable cargo capacity or track inventory.
- Multiple cargo types with different rules, manual loading, manual unloading, cargo rejection, or cargo prioritization controls.
- Reachability tests, rerolls, pathfinding, route-aware random filtering, automatic route modification, or replacement requests for impossible pairs.
- Custom textures, icons, fonts, animation, audio, or final art production.
- Production service interfaces, dependency-injection frameworks, global event buses, generic state-machine libraries, or speculative polymorphism.

## 4. Non-Negotiable Random Generation Contract

The candidate pool is every `Vector2i(x, y)` for `0 <= x < grid_size.x` and `0 <= y < grid_size.y`, in row-major order. Origin and destination are sampled independently from that complete pool. They may therefore resolve to the same cell. The implementation does not reroll an equal-cell result.

There is no reachability correction before or after either draw.

Generation must not inspect:

- current, reserved, building, built, recovered, or locked track;
- train position or route distance;
- whether a cell is ahead of or behind the train;
- whether the centerline can contact a cell;
- cargo-slot occupancy;
- prior success or failure;
- any cost, hazard, contract, or economy state.

For each generated pair, random draws occur in this fixed order:

1. origin row-major cell index;
2. destination row-major cell index;
3. active-lifetime tick inside the inclusive configured range.

Pair ordinal, stable identifier, and presentation style do not consume RNG. A pair ID is `warp_pair_<ordinal>`, with ordinals beginning at `1`. The lowest unused placeholder style among live pairs is assigned deterministically.

The first forecast is due on the first `RUNNING` tick. Later forecasts are due at the configured generation interval measured from the tick on which the previous pair was actually generated. A due forecast that finds the live-pair limit full leaves exactly one pending opportunity. It retries once on each later running tick, accumulates no backlog, and consumes no RNG until a live slot exists. After the delayed pair is generated, its actual generation tick becomes the base for the next interval. `FORECAST`, `ACTIVE_UNLOADED`, and `IN_TRANSIT` count as live. Terminal pairs do not.

Identical seed, configuration, input frames, and tick count must reproduce pair records and ordered events exactly. Different player actions may change when a live slot becomes available; they may therefore change the tick of a later generation, but they never change a result that has already been generated or forecast.

## 5. Pair Lifecycle

`WarpPairRecord` has exactly these states:

```text
FORECAST
  -> ACTIVE_UNLOADED
      -> IN_TRANSIT
          -> DELIVERED
          -> EXPIRED
      -> EXPIRED
  -> VOIDED

ACTIVE_UNLOADED -> VOIDED
IN_TRANSIT      -> VOIDED
```

### 5.1 Forecast

- Both already-determined cells, the matching color/shape, and activation countdown are visible.
- Forecast points do not create `RouteContactAnchor` values.
- Forecast points cannot load, deliver, or respond to train contact.
- Forecast does not alter route geometry. This preserves the approved rule that forecast is informational only.
- A forecast generated on running tick `G` with `N > 0` remaining ticks is displayed for ticks `G` through `G + N - 1`. At the beginning of tick `G + N`, its counter decrements to zero and it activates.
- A zero-tick forecast activates on its generation tick.

### 5.2 Activation

- On a tick that begins in `RUNNING`, activation and zero-tick generation occur before track input, construction, and train movement.
- The departure-transition tick begins in `PREPARING_DEPARTURE`, so its input and construction already occurred. If construction starts the train on that tick, it becomes running tick `1`; the first forecast/activation step runs once after departure readiness and before the first train movement.
- Activation installs two stable anchors: `warp_pair_<ordinal>/origin` and `warp_pair_<ordinal>/destination`.
- The route system receives the exact generated cells. It does not move, reject, or correct them.
- Unlocked ghost geometry may re-resolve through the existing anchor contract. Locked geometry remains unchanged.
- `contact_possible = false` is a valid observation and never triggers a replacement request.

### 5.3 Loading and Transit

- Sweeping through an active origin attempts loading automatically.
- If at least one slot is empty, the lowest-index empty slot receives that pair's cargo and the pair becomes `IN_TRANSIT`.
- If all slots are full, no state changes. The origin remains active and may load on a later pass before expiry.
- Repeated origin contact after loading is a no-op.
- One pair can own at most one cargo slot.
- After loading succeeds, the origin anchor is removed and the destination anchor remains. Removing the completed origin constraint may re-resolve only unlocked ghost geometry through the existing route contract.

### 5.4 Delivery

- Sweeping through the matching destination while the pair is `IN_TRANSIT` delivers automatically.
- Delivery clears exactly that pair's slot, makes the pair terminal, increments delivered-pair count once, and adds exactly one configured base reward.
- Destination contact before loading is a no-op.
- A delivered pair ignores every later contact and can never pay again.

### 5.5 Expiry

- Active lifetime begins on the activation tick.
- Contact resolves before the current active tick is consumed.
- After contact, the lifetime decrements by one. Reaching zero makes an undelivered pair `EXPIRED`.
- Expiring `ACTIVE_UNLOADED` cargo changes no slot.
- Expiring `IN_TRANSIT` cargo clears exactly its matching slot.
- Expiry creates no reward, fine, failed-request counter, route correction, or replacement request.

### 5.6 Regular-End Void

- Point expiry resolves before session-timer expiry on the same tick.
- If the session timer then reaches zero, every remaining `FORECAST`, `ACTIVE_UNLOADED`, and `IN_TRANSIT` pair becomes `VOIDED`.
- Every in-transit void clears exactly its matching slot.
- Void creates no reward, fine, failure, or attainment effect.
- The terminal snapshot and result retain delivered count and base reward already earned.

The current early `TRACK_END_REACHED` result also clears all nonterminal pair and cargo state before publishing its terminal snapshot. It uses the same no-fine void operation, but `VOIDED` remains named for the regular-end gameplay contract rather than becoming a separate penalty state.

## 6. Contact and Ordering Contract

Warp Cargo consumes the current route and movement systems. It must not reproduce grid mapping, curve templates, construction state, nominal train motion, or centerline sampling inside a warp class.

The only required route-boundary extension is a detached hit query on the existing track runtime:

```gdscript
func get_contact_hits_between(
    previous_distance_cells: float,
    through_distance_cells: float
) -> Array[Dictionary]
```

Each hit contains:

```gdscript
{
    "anchor_id": StringName,
    "cell": Vector2i,
    "contact_distance_cells": float,
}
```

The query uses the same resolved-piece ledger, nominal sampling, grid origin, and cell coverage already used by `RouteContactAnchor` observations. It returns only anchors entered by the half-open movement sweep `(previous_distance_cells, through_distance_cells]`. It never searches for or constructs a route.

The implementation subdivides nominal distance into the same deterministic one-eighth-cell samples used by the accepted contact observation. For each anchor, it maps the sample at `previous_distance_cells` and then walks later samples through `through_distance_cells`. A hit occurs only on the first sampled transition from a different cell into the anchor cell; continuing through the same anchor cell on the next tick emits nothing. The one exception is the first positive train movement from route distance `0.0`: its prior state is treated as outside, so an active anchor in the departure cell emits at `0.0`. If an anchor activates while the train is already inside its cell at any later distance, it emits nothing until a future outside-to-inside re-entry; with the one-line route this may make the request impossible. `contact_distance_cells` is the transition sample's nominal distance. A query emits at most one hit per stable anchor ID. Nonfinite distances, a negative previous distance, or `through_distance_cells < previous_distance_cells` return an empty array without mutation in every build. The controller supplies distances no greater than the built endpoint.

The route query orders raw hits by ascending `contact_distance_cells`, then stable anchor ID. It does not parse Warp Cargo IDs or know endpoint meaning. `WarpPairSystem` then resolves hits by:

1. ascending `contact_distance_cells`;
2. origin before destination for the same pair and distance;
3. ascending pair ordinal;
4. stable anchor ID as a final tie-breaker.

This order permits a same-cell origin and destination to load and then deliver once on the same train sweep when a slot is available. Across different pairs at the same distance, lower pair ordinal gets the first loading opportunity. Physical route order otherwise controls slot turnover, so a delivery earlier in the sweep may free a slot for an origin later in that same sweep.

## 7. Fixed-Tick Priority

The active session controller owns this exact order:

1. If the tick begins in `RUNNING`, assign the next one-based running tick index, decrement existing positive forecast counters, activate counters that reach zero, generate one due forecast when capacity permits, immediately activate a newly generated zero-tick forecast, and install the resulting active anchors.
2. Consume one immutable mouse input frame.
3. Apply right-click cancellation against tick-start track state.
4. If right-click did not win, apply left-drag grid reservations and existing unlocked-geometry resolution.
5. Advance cell construction and resolve departure readiness.
6. If departure begins on this tick, assign running tick index `1` and perform the one Warp Cargo begin-tick step before the first train movement. Do not also perform step 1 on that transition tick.
7. Record the train's previous nominal distance, advance the train over the built centerline, capture its new pose, and record a track-end request without completing the session yet.
8. Query ordered route-contact hits over the actual train sweep.
9. Resolve automatic origin loading and matching destination delivery in hit order.
10. Recover eligible rear track cells using the accepted route rules.
11. Decrement active pair lifetimes and expire pairs whose lifetime reaches zero.
12. Advance the running session timer and record regular expiry.
13. Prioritize regular expiry over a same-tick track-end request, void remaining pairs and cargo exactly once, and complete at most once.
14. Publish one detached terminal or nonterminal snapshot, then emit at most one result.

Consequences:

- Train movement and point contact always resolve before point expiry at the same decision instant.
- Point expiry resolves before regular-end void on the same tick.
- A same-tick delivery survives both point expiry and session expiry and pays once.
- Rear recovery remains unavailable to reservation until the next tick.
- No presentation signal or Godot callback order decides gameplay state.

## 8. Cargo Ownership and Reward Boundary

`CargoSystem` owns the fixed slot array and the provisional session base-reward total. `WarpPairSystem` owns pair lifecycle. `SessionController` invokes them in the fixed order above.

The reward total is deliberately not named cash. Contract Economy remains responsible for later persistent cash ownership, company fee curves, contract attribution, and settlement. This slice publishes `base_delivery_reward_total` as immediate prototype feedback and result evidence only.

Slot invariants:

- The slot array length equals configured base capacity for the whole session.
- One slot is either empty or contains one stable pair ID and its style index.
- One pair appears in at most one slot.
- `occupied + empty = total` exactly.
- Delivery, expiry, or void clears a matching slot at most once.
- `clear_all()` clears slots only; it preserves delivered count and reward already earned.
- Empty, full, and mixed states are derived from the slot array, never stored as separate authoritative flags.

Reward invariants:

- `CargoSystem.delivered_pair_count` is the authoritative delivered count and equals the number of archived pair records in `DELIVERED` state.
- `base_delivery_reward_total = delivered_pair_count * base_delivery_reward` for this slice.
- Reward never decreases and never changes on load, expiry, void, or repeated contact.

## 9. Inspector-Editable Resources

Balance values are separated by responsibility. They are copied into `SessionStartConfig` at composition so later Inspector edits cannot mutate a running session.

### 9.1 `WarpLifecycleBalance`

| Field | Default | Valid range | Meaning |
|---|---:|---:|---|
| `forecast_duration_seconds` | `8.0` | `0.0..60.0` | Time between forecast creation and activation |
| `generation_interval_seconds` | `12.0` | `0.1..120.0` | Running-time interval between generated forecasts |
| `lifetime_min_seconds` | `24.0` | `1.0..180.0` | Inclusive minimum active lifetime |
| `lifetime_max_seconds` | `36.0` | `1.0..180.0` | Inclusive maximum active lifetime; must be at least the minimum |
| `max_live_pairs` | `3` | `1..6` | Maximum simultaneous forecast, active-unloaded, and in-transit pairs |

Seconds convert to integer ticks with `ceil(seconds * simulation_ticks_per_second)`. Generation interval and active lifetime are always at least one tick. The sampled lifetime is uniform over the inclusive integer tick range.

The maximum is six because the placeholder presentation defines six simultaneous distinguishable color-shape styles. Increasing that limit requires an approved presentation-scope change, not silent style reuse.

### 9.2 `CargoBalance`

| Field | Default | Valid range | Meaning |
|---|---:|---:|---|
| `base_slot_count` | `2` | `1..8` | Fixed cargo capacity for this slice |
| `base_delivery_reward` | `100` | `0..1,000,000` | Immediate provisional reward per delivered pair |

The reward is an integer. This slice has no fractional currency, scaling curve, company multiplier, purchase price, or capacity upgrade.

Validation rejects a null nested Resource and names the full owner-qualified field. Invalid configuration prevents debug session start. No value is clamped, repaired, or substituted at runtime.

## 10. Concrete Prototype Components

Use concrete GDScript classes:

- `WarpPairRecord`: detached pair state and duplication.
- `WarpPairSystem`: schedule, seeded generation, forecast, activation, anchors, hit resolution, expiry, void, and ordered event log.
- `CargoSlotRecord`: detached slot state and duplication.
- `CargoSystem`: slot ownership, automatic load/delivery/removal, delivered count, and provisional base reward.
- `SessionController`: fixed-tick composition of accepted track/train behavior and the two new systems.
- `SessionSnapshot` and `SessionResult`: detached observations only.
- `TrackFieldView`: primitive endpoint and countdown rendering from snapshots.
- `CargoSlotStrip`: primitive cargo-slot rendering from snapshots.
- `SessionShell`: text totals and view wiring.

Do not add a `WarpCargoManager`, service locator, global singleton, global event bus, abstract repository, generic lifecycle framework, or interchangeable cargo-provider interface. Production abstraction scope is decided after prototype evidence exists.

## 11. Snapshot, Result, and Event Contract

`SessionSnapshot` adds detached getters for:

- all pair records in ordinal order;
- all cargo slots in slot-index order;
- occupied and total cargo slots;
- delivered pair count;
- base delivery reward total;
- ordered Warp Cargo events emitted on the current tick.

`SessionResult` adds delivered pair count and base delivery reward total. It does not add cash, quota, attainment, failure count, or settlement.

Each event is a detached Dictionary with:

```gdscript
{
    "tick": int,
    "type": StringName,
    "pair_id": StringName,
    "slot_index": int,
    "amount": int,
}
```

Allowed event types are `FORECASTED`, `ACTIVATED`, `LOADED`, `DELIVERED`, `EXPIRED`, and `VOIDED`. Fields not applicable to an event use `-1` or `0`; keys are never omitted. Event order follows the fixed-tick and hit-order contracts.

Snapshots and results deep-copy pair, slot, contact, and event observations. Presentation cannot mutate domain state through a returned object.

Every generated pair record remains archived in ordinal order until session completion. Terminal records no longer count as live and publish no anchors, but their final state remains available for invariants and replay. The current tick's event buffer determines one-snapshot delivery, expiry, or void feedback; on the following tick the terminal record remains archived but is no longer drawn on the field.

Event payloads are exact:

| Event | `slot_index` | `amount` |
|---|---:|---:|
| `FORECASTED` | `-1` | `0` |
| `ACTIVATED` | `-1` | `0` |
| `LOADED` | loaded slot index | `0` |
| `DELIVERED` | cleared slot index | base delivery reward |
| `EXPIRED` | cleared slot index when in transit, otherwise `-1` | `0` |
| `VOIDED` | cleared slot index when in transit, otherwise `-1` | `0` |

A zero-tick generation emits `FORECASTED` and then `ACTIVATED` on the same tick. Same-stage events use ascending pair ordinal. Unknown, duplicate, or malformed contact hits are debug assertion failures; release-style execution ignores them without changing pair, cargo, or reward state. `begin_running_tick`, contact resolution, post-contact expiry, and void each guard their tick or terminal transition so a repeated call cannot consume time or reward twice.

After activation, loading/delivery, expiry, or void changes pair state, `SessionController` immediately supplies the newly derived anchor array to `TrackSystem` before the next stage that can observe anchors and again before snapshot publication. Anchor getters derive from current records; they do not expose a stale tick-start cache.

## 12. Placeholder Presentation Contract

The six built-in placeholder styles use paired color and shape, not color alone. Their fixed prototype order is: teal circle `#2EC4B6`, orange diamond `#FF9F1C`, violet square `#9B5DE5`, yellow circle `#F4D35E`, blue diamond `#3A86FF`, and pink square `#FF5D8F`. This is a functional placeholder palette, not an accessibility-validated final palette. Style selection is deterministic and independent of RNG.

Visible states:

| State | Origin | Destination | Cargo slot | Text feedback |
|---|---|---|---|---|
| Forecast | low-alpha filled shape | low-alpha outline | none | activation countdown |
| Active, unloaded | opaque filled shape | opaque outline | empty | lifetime countdown |
| In transit | outline only | opaque outline | matching filled shape | lifetime countdown |
| Delivered | removed after terminal observation | brief filled destination observation in the event snapshot | cleared | delivered count and reward increase |
| Expired | removed after terminal observation | removed after terminal observation | matching slot clears | expiry event observation |
| Voided | absent from regular terminal field | absent | all slots clear | result retains earned deliveries/reward only |

Terminal records remain archived, but terminal points do not remain interactive or occupy a live style. A `DELIVERED`, `EXPIRED`, or `VOIDED` event may draw its terminal endpoint for exactly the snapshot carrying that event; it is absent from the next snapshot.

All field positions use `grid_origin_units`, `grid_cell_size_units`, and the generated cell. Input hit regions remain owned by the existing track view. Warp visuals never intercept mouse input.

Countdown text uses whole seconds rounded up from remaining ticks: forecast shows `F <seconds>s`, while active and in-transit pairs show `<seconds>s`. Zero is not displayed because activation or expiry occurs before snapshot publication. The existing HUD placeholder for cash becomes `BASE REWARD` for this slice, and the cargo area shows `occupied / total` plus the primitive slot strip. Contract and durability placeholders remain unchanged.

Custom art production is explicitly deferred. This slice records the proven visible-state list for a later art-resource scope; it does not create final assets.

## 13. Deterministic Acceptance Scenarios

1. A fixed seed and configuration reproduce origin cell, destination cell, sampled lifetime, style assignment, forecast tick, activation tick, and event order.
2. Every in-bounds grid cell can be produced by controlled RNG fixtures; no route or reachability state is queried during generation.
3. An equal-cell origin/destination loads and delivers once in one ordered sweep when a slot is empty.
4. An origin behind the train remains impossible without reroll or correction.
5. An active anchor can reflow unlocked ghost geometry, while locked geometry remains unchanged and may report contact impossible.
6. Empty capacity loads into slot zero.
7. Full capacity leaves the active origin and all slots unchanged.
8. Mixed capacity loads into the lowest empty slot and preserves occupied slots.
9. Multiple same-tick contacts resolve by route distance, endpoint kind, and pair ordinal.
10. A destination contact on the final lifetime tick delivers and pays before expiry.
11. A destination reached after expiry does nothing.
12. In-transit expiry clears exactly one matching slot without reward or fine.
13. One pair cannot load twice, occupy two slots, deliver twice, or pay twice.
14. Regular timer expiry voids forecast, unloaded, and in-transit pairs without a penalty and clears all slots.
15. A same-tick delivery and regular end retain the delivery and reward in the terminal snapshot and result.
16. Existing grid reservation, construction, recovery, gesture, route sampling, session priority, resize, and one-shot result tests remain green.
17. Windows manual play shows readable forecast, active, transit, delivery, expiry, full-slot, mixed-slot, and regular-end-clear states at supported 16:9 sizes.

## 14. Error Handling and Invariants

- Invalid grid size, balance range, or nested Resource prevents composition.
- Pair IDs and anchor IDs are stable and unique inside a session.
- Pair ordinal is monotonic and never reused.
- RNG is consumed only by an actual pair generation in the specified draw order.
- A generated origin or destination always remains in bounds.
- An `ACTIVE_UNLOADED` pair publishes origin and destination anchors. An `IN_TRANSIT` pair publishes only its destination anchor. Forecast and terminal pairs publish none.
- Forecast and terminal pairs publish no route anchor.
- Contact hits are detached, ordered, and limited to the movement sweep.
- Delivery and expiry cannot both transition the same pair.
- Terminal transitions are idempotent.
- Session completion voids nonterminal pair and cargo state once before the terminal snapshot.
- Existing track inventory, geometry locking, train motion, and result one-shot invariants remain unchanged.

Assertions live next to the concrete owner. Invalid input is a no-op where safe; it never changes reward or silently repairs a generated request.

## 15. Open Questions

No blocking design questions remain for this slice. The following decisions are intentionally deferred rather than unresolved:

- whether base reward later becomes company cash, contract fee, or another economy input;
- purchasable cargo slots and their cost curve;
- final art, animation, audio, and accessibility palette validation;
- production interfaces, persistence, replay format, and abstraction scope.

Those topics belong to their named later slices or to the prototype-to-production review. They must not be inferred into Warp Cargo implementation.

## 16. Definition of Done

Warp Cargo is complete only when:

- all acceptance scenarios have deterministic automated coverage at the appropriate layer;
- the Windows manual checklist passes;
- existing five baseline runners remain green;
- all balance fields are Inspector-editable, copied at session start, and owner-qualified validation errors are tested;
- no generation correction, reroll, route-aware filter, pathfinding, or automatic route modification exists;
- no Risk & Investment, Contract Economy, Credit Survival, custom-art, production-architecture, or speculative-abstraction work is present;
- each implementation task preserves RED, minimum GREEN, regression, allowlist, exact staging, focused commit, independent specification review, and independent quality review evidence;
- the feature gate passes on the reviewed `feature/warp-cargo` head before any separately approved publication step.
