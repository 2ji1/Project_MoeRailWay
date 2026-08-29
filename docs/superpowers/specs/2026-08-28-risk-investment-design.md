# Risk & Investment Prototype Design

**Date:** 2026-08-28

**Status:** Approved for implementation

**Target branch:** `feature/risk-investment`

**Verified integration base:** `52fc157a36bad4bd8b758928ba90f7b776e106d8`

**Prerequisite evidence:** The final Warp Cargo and grid-track gate passed on the exact integration base at all four supported window sizes. Evidence is stored outside the repository.

## 1. Purpose and Authority

Risk & Investment is the next bounded prototype slice after Warp Cargo. It adds visible route risk, train durability, a session-only spending budget, paid route interventions, and temporary capacity purchases while preserving the existing Windows PC, mouse-only, top-down 2D, single continuously moving train contract.

This document is the English canonical design for the slice. It consumes the current grid ownership, local-corner geometry, ordered construction, train sampling, automatic recovery, live gesture reflow, exact Warp contact, cargo slots, and base delivery reward systems. It does not reimplement any of them.

The prototype remains concrete. This slice does not introduce production interfaces, service locators, persistence layers, generalized transaction frameworks, pathfinding products, campaign architecture, or permanent upgrade abstractions. The abstraction boundary for full development remains a post-prototype decision.

## 2. User-Confirmed Decisions

The following decisions are approved inputs to this design:

1. This slice owns provisional session cash. It does not introduce `RunState` cash.
2. Train durability and its damage/end/repair-basis loop are the second implementation axis after session cash.
3. Minimal `RunState` cash is deferred to a third, later step and is not implemented in this feature.
4. Hazards are generated deterministically from the session seed at session start.
5. Hazard placement and severity remain stable for the entire session.
6. No cycle state, cycle-based regeneration, density scaling, or damage scaling is introduced.
7. Session cash starts at `300`. Warp Cargo's `base_delivery_reward_total` remains a separate non-spendable prototype score and is not converted into cash.
8. The default layout contains `12` unique hazard cells and excludes only the departure cell. Route state, Warp state, train state, reachability, and geometry do not influence placement.
9. Maximum durability is `100`; default hazard damage is `10` durability per actual traveled cell-distance; repair-cost basis is `1` cash per durability lost.
10. One paid demolition and one grade-separated crossing use the same `50` major-track-action cost.
11. One temporary track purchase costs `40` and adds `5` inventory cells, up to six purchases.
12. One temporary cargo purchase costs `80` and adds one slot, up to four purchases.

## 3. Scope

### 3.1 Included

- one provisional session cash balance;
- deterministic, always identifiable hazard terrain;
- distance-based durability damage;
- maximum/current durability and one-shot zero-durability completion;
- repair-cost basis derived from durability loss;
- existing free `RESERVED_GHOST` suffix cancellation;
- paid right-click demolition for `BUILDING` and `BUILT` route;
- paid early demolition of a retained traveled rear prefix;
- non-branching grade-separated crossings;
- temporary track inventory purchases;
- temporary cargo-capacity purchases;
- primitive color, shape, text, outline, and button feedback;
- deterministic unit, integration, and Windows mouse verification.

### 3.2 Excluded

- `RunState`, persistent cash, settlement, contracts, operating costs, trust, debt, principal, interest, credit, and bankruptcy;
- conversion of base delivery reward into cash;
- cycle count, cycle pressure, hazard scaling, hazard regeneration, or hazard relocation;
- route-aware or reachability-aware hazard correction;
- permanent track or cargo upgrades;
- train models, multiple trains, train-length changes, or speed changes from cargo capacity;
- branches, merges, switches, or crossing-based route choice;
- custom art, textures, imported icons, custom fonts, audio, mobile, touch, or controller support;
- production architecture or generalized economy/command abstractions.

## 4. Provisional Session Cash

### 4.1 Ownership and lifetime

One concrete `SessionEconomy` owns an integer cash balance for one session. It is created from the copied `SessionStartConfig`, exists only inside the composed session, and becomes terminal with the session. A fresh session always starts from the configured starting cash. No balance is carried through `SessionResult` into a later session as authoritative state.

The final snapshot and result may report final cash and spending totals as detached evidence. This observation is not persistence. Ending normally, reaching track end, or reaching zero durability all discard temporary capacity and the authority to spend.

### 4.2 Funding boundary

The only funding source in this slice is `starting_session_cash = 300`. Warp delivery continues to increase `base_delivery_reward_total` exactly as before, but that value is not cash, does not increase cash, and is not spendable. Contract Economy owns any later conversion or settlement rule.

### 4.3 Atomic spending

Every priced action follows one transaction contract:

1. derive and validate the complete gameplay candidate without mutation;
2. calculate the exact integer cost;
3. verify that current cash is at least the cost;
4. commit the gameplay candidate and subtract the cost exactly once; or
5. reject with gameplay state and cash byte-unchanged.

No action spends before validation. No retry, repeated input frame, presentation redraw, rejected release, or session completion may charge again. A successful action never receives a cash refund, including later demolition, automatic recovery, cancellation of unrelated ghost track, or session end.

Disabled button state and pointer-derived affordability feedback may be presented without mutating domain state. An unaffordable action does not publish a domain rejection event that would violate the byte-unchanged rule.

For this contract, the canonical authoritative comparison is a deterministic serialization of current cash and spending totals; ordered route records and their complete fields; geometry pieces and locked ledger; contact anchors; inventory totals; train state; hazard records; Warp pair state; cargo slots; purchase counters and capacities; session clock/completion state; and the last published domain snapshot/result. It excludes raw OS input, a request already dequeued for the current tick, pointer/hover presentation, and derived local affordability text. Rejected actions never enter a domain event log. Tests capture the canonical serialization immediately after request dequeue and compare it after the rejected attempt; no hidden authoritative counter, serial, RNG state, or queued domain command may advance.

Every priced action uses one concrete single-threaded staged commit, not a generalized transaction framework. The responsible system duplicates only its affected concrete owners, applies the candidate to those copies, and validates all invariants and the exact post-spend cash before touching live state. A valid candidate is installed through task-local `replace_from_validated_candidate` operations that cannot reject or allocate gameplay identity; cash is installed from its precomputed post-spend value in the same controller call. No snapshot, signal, redraw, or other observer runs between those assignments. A failed validation installs neither copy. An invariant failure during installation is a programming assertion, not a recoverable partially charged action.

## 5. Deterministic Hazard Terrain

### 5.1 Generation

`HazardSystem` derives a hazard-specific deterministic RNG stream without advancing the existing session/Warp stream. The exact signed 64-bit seed operation is `hazard_seed = session_seed ^ 0x5249534B48415A44`; the positive literal encodes the fixed domain salt `RISKHAZD`, and no string hashing is performed at runtime. A new existing `SessionRng` instance is constructed from that integer. Adding Risk & Investment therefore does not change the approved Warp pair sequence for the same seed.

Generation builds one mutable row-major array of every in-bounds grid cell except the departure cell. It selects without replacement by a partial Fisher-Yates shuffle. For selection index `i` from `0` through `hazard_cell_count - 1`, it evaluates `j = i + hazard_rng.next_index(candidate_count - i)`, swaps elements `i` and `j`, and appends the cell now at `i`. The ordered selected array is canonical; hazard observations preserve that order. Generation does not inspect track records, geometry, Warp pairs, train position, cargo, cash, or reachability. If the configured count exceeds the eligible cell count, completed-configuration validation fails before session start; runtime never clamps or rerolls.

The selected cells remain unchanged until the session terminates. Different seeds may produce different layouts. No cycle state exists.

### 5.2 Visibility

Every hazard cell is visible from session preparation through terminal presentation. Placeholder terrain uses one fixed high-contrast fill plus a repeated primitive mark or border. It does not rely on color alone and never intercepts mouse input.

### 5.3 Damage measure

Hazard damage uses the canonical route-distance interval that the train actually advances during the current simulation tick. For each unique hazard cell, the track query clips the movement sweep to the centerline intervals that lie inside that cell. The sum is measured in cell-distance units and multiplied by `damage_per_traveled_cell`.

This contract has the following consequences:

- merely owning, reserving, building, or drawing track in a hazard cell causes no damage;
- a stopped or not-yet-departed train causes no damage;
- partial travel through a hazard cell causes proportional damage;
- entering the same hazard cell on two separate route occurrences causes damage on both actual passes;
- unique hazard placement prevents double damage from duplicate terrain records;
- curves and crossings use the route occurrence actually sampled by the train;
- hazards never slow, reroute, or move the train.

The query is deterministic and read-only. It extends the current route-sampling surface instead of duplicating geometry in `HazardSystem`.

## 6. Durability and Repair-Cost Basis

### 6.1 Ownership

`TrainSystem` owns maximum and current durability because durability is a property of the one moving train. Both are finite nonnegative values copied from configuration. Every session starts at maximum durability.

`HazardSystem` computes a detached damage fact from the movement sweep. `SessionController` applies that fact to `TrainSystem` after Warp contact resolution. Presentation reads durability only from the detached session snapshot.

### 6.2 Damage and zero durability

Applied damage is clamped to remaining durability. Current durability never becomes negative. Crossing terrain, cash state, route construction state, and cargo capacity do not change the damage rate.

When an applied hazard fact reaches zero durability, the controller requests `DURABILITY_DEPLETED` exactly once. The movement and any Warp contacts already reached during that same sweep remain authoritative. Hazard completion then wins over track-end and regular-time requests from that tick, session completion voids remaining Warp/Cargo state through the existing terminal path, and no later input or tick mutates the session.

### 6.3 Repair basis

Repair-cost basis is an observation, not a settlement or a cash charge:

```text
durability_loss = maximum_durability - current_durability
repair_cost_basis = ceil(durability_loss * repair_cost_per_durability)
```

The value updates immediately with damage and is retained in the terminal snapshot/result. Contract Economy may later consume it. This slice never subtracts it from provisional session cash and never restores durability during the same session.

## 7. Right-Click Cancellation and Paid Demolition

### 7.1 Priority

Right-click retains its current priority over left input.

1. If a left gesture is active, right-click aborts that gesture and restores its origin for free.
2. Otherwise, right-click on an eligible `RESERVED_GHOST` record cancels that record through the endpoint for free and refunds every removed track cell, exactly as today.
3. Otherwise, right-click on an eligible `BUILDING` or `BUILT` record requests one paid demolition.
4. Any other right-click is a no-op.

Free ghost cancellation is never reclassified as a priced action.

### 7.2 Untraveled front suffix

If the clicked record begins strictly ahead of the train's current route distance, demolition removes that record and every later active route record through the endpoint. The removed records may contain `BUILDING`, `BUILT`, and trailing `RESERVED_GHOST` states; the paid classification comes from the clicked record. Every removed active record returns one track inventory cell.

The action rejects if the cut would remove the route occurrence containing the train, disconnect a retained front route, violate an exact Warp contact already passed in the current sweep, or fail existing geometry, ledger, construction, anchor, or conservation validation.

### 7.3 Retained traveled rear prefix

If the clicked record ends at or behind the train's current route distance, demolition removes the active route start through that clicked record. It is an early paid form of the existing rear recovery operation. The train-containing occurrence and every later record remain. Every removed active record returns one track inventory cell.

The implementation stages through the existing recovered-cell and locked-ledger ownership rules. Previously locked geometry remains byte-unchanged as immutable history; only active ownership, blocking cells already removed by the staged prefix operation, inventory, and observations advance.

### 7.4 Ambiguous or unsafe click

A record whose route interval contains the train is neither a front suffix nor a completed rear prefix and cannot be demolished. A click that cannot produce one complete atomic prefix or suffix candidate is a no-op. No partial span, fallback span, or automatic target relocation is allowed.

When one cell has multiple ordered occurrences because it is a crossing, target selection uses the pointer position inside that logical cell. For each visible occurrence, compute the shortest distance from the pointer to that occurrence's canonical unchanged centerline segment, not to the visual over/under gap. Let the two distances be `a` and `b`, in logical cell units. If `abs(a - b) <= 0.01`, the target is ambiguous and the input is a no-op; otherwise the occurrence with the smaller distance wins. This selects horizontal versus vertical crossing layers without inventing a route branch. It applies before state classification, so a selected `RESERVED_GHOST` occurrence still receives free suffix cancellation and a selected `BUILDING` or `BUILT` occurrence receives paid demolition. Presentation highlights exactly the occurrence and resulting prefix/suffix that would be affected.

### 7.5 Cost

One successful prefix or suffix demolition costs `major_track_action_cost = 50`, independent of the number of removed cells. The action charges once and refunds track inventory only. It never refunds cash previously spent on track capacity, cargo capacity, crossings, or earlier demolition.

### 7.6 Slow-planning input arbitration

An active-gesture right-click abort and a selected `RESERVED_GHOST` suffix cancellation remain immediate on the real input tick, including a skipped planning simulation tick. They are free and use the existing responsive input contract.

A selected `BUILDING` or `BUILT` right-click on a skipped planning tick does not mutate gameplay and is not discarded. The controller stores one transient paid-demolition request containing the exact selected `route_serial`; after crossings exist it also retains the occurrence's canonical centerline identity. Paid demolition and capacity purchases share one pending priced-action slot, so the earliest eligible input edge wins. While that request is pending, later field and purchase presses are ignored, pointer motion may update presentation but cannot retarget the request, and hover continues to show the retained target. On the next due simulation tick, the request is dequeued, resolved by its retained identity, fully revalidated against current train/route/cash state, and either committed once or rejected without authoritative mutation. Repeated pressed frames never duplicate it.

If the paid click arrives on a due tick, the same validation and commit path runs immediately without entering the pending slot. Completion clears a pending request without action. The pending request is transient input transport excluded from the canonical byte comparison; it is never published as a domain event or persistent state.

## 8. Grade-Separated Crossing

### 8.1 Meaning

A crossing lets the later ordered route pass through a cell already occupied by an earlier active route occurrence. The two occurrences remain separate points in one ordered route. They do not create a branch, merge, switch, alternate traversal, shared route serial, or selectable direction.

### 8.2 Validation

A crossing candidate is legal only when all conditions hold:

- the live gesture enters an occupied cell from one neighbor and exits to the opposite neighbor;
- the new entry and exit are collinear;
- the earlier centerline traverses the cell in the perpendicular orientation;
- the new occurrence and existing occurrence visibly pass through the cell center;
- the complete route remains one ordered sequence;
- the new occurrence has a fresh route serial and normal nominal distance;
- every existing bounds, inventory, construction, immutable geometry, train-sampling, and conservation rule remains valid;
- sufficient cash exists for every new crossing in the candidate.

Stopping on the occupied cell is not enough to infer a crossing. A parallel overlap, shared tangent, U-turn, diagonal entry, branch-like entry/exit, or same-orientation reuse rejects. The last valid preview remains unchanged.

### 8.3 Gesture and charging

A legal crossing appears as a pending paid item in the live preview after its opposite-side exit is known. Backtracking may remove it before release without charge. Finalizing commits the route and charges `50` once per crossing occurrence in the finalized gesture. Right-click abort restores the gesture origin and charges nothing.

Affordability is checked against the entire finalized candidate. If cash cannot cover all new crossings, the candidate is not published as payable and gameplay state and cash remain byte-unchanged. Other spending inputs are disabled while a field gesture is active, so affordability cannot drift under a visible candidate.

### 8.4 Geometry and contact

The old locked geometry remains byte-unchanged. The new crossing occurrence adds a minimal primitive over/under visual gap without changing either route's centerline ownership. Hazard terrain applies independently to each actual pass.

An exact Warp anchor in a crossing cell may be contacted on either ordered occurrence. Contact observations retain the existing earliest `contact_distance_cells` for compatibility and add a detached ordered `contact_distances_cells` array for every active occurrence that passes through the exact center. Swept hit queries test all distances and emit the Warp anchor at most once per pair lifecycle according to existing Warp ownership. This extension prevents an already traveled earlier occurrence from hiding a later valid crossing contact.

## 9. Temporary Purchases

### 9.1 Track inventory

One purchase costs `40` and increases total and available track inventory by `5`. At most six purchases are allowed. Existing active records, route serials, construction, recovery, and geometry do not change. A purchase is unavailable while a field gesture is active.

### 9.2 Cargo capacity

One purchase costs `80` and appends one empty cargo slot. At most four purchases are allowed. Existing slot identity, occupied cargo, pair identity, train length, train speed, and recovery distance do not change. Newly appended slots use monotonically increasing slot indices and participate in the existing lowest-empty-slot loading rule.

### 9.3 End behavior

Purchases belong only to the live session. Regular expiry, track-end completion, and durability completion all remove future authority to use the increments. Remaining cargo is voided through the existing Warp Cargo terminal rule. A later session starts from base track and cargo capacity.

The terminal snapshot/result may retain detached final capacity and purchase-count evidence. This does not carry capacity forward. No purchase cost is refunded on any end path.

### 9.4 Purchase input arbitration

The app and controller expose one shared transient pending priced-action slot between due planning ticks. The first eligible paid-demolition, track-purchase, or cargo-purchase mouse edge in chronological input-event order wins; later priced or field presses are ignored until that edge is consumed. Repeated pressed frames never create additional requests. A purchase press while a field gesture is active, after completion, or while another priced edge is pending is rejected before entering the slot.

On the next due planning tick, the controller dequeues that one edge and performs the canonical staged affordability/limit check. Insufficient funds or a reached limit consumes the transient edge but changes no authoritative gameplay state under the byte-unchanged comparison boundary. Skipped real ticks never consume it. This queue is input transport, not a domain command log or gameplay observation.

## 10. Tick Order

The current deterministic tick order is extended, not replaced:

1. Determine whether the planning simulation tick is due.
2. Begin the due Warp tick and install authoritative anchors.
3. Apply right-click abort, free cancellation, or one staged paid demolition.
4. Apply left route input, including pending crossing validation.
5. Apply one queued temporary purchase when no field gesture owns input.
6. Advance ordered construction.
7. Prepare immutable train sampling and move the train once.
8. Resolve Warp/Cargo contacts from the actual movement sweep.
9. Resolve hazard distance from the same movement sweep and apply durability damage.
10. If durability reaches zero, complete once with `DURABILITY_DEPLETED`.
11. Otherwise recover eligible rear track.
12. Expire Warp pairs and install the resulting anchors.
13. Advance session time and choose regular expiry before track-end completion, preserving the existing non-durability tie order.
14. Publish one detached snapshot and at most one terminal result.

Skipped planning real ticks process responsive pointer presentation, immediate free gesture abort, and immediate free ghost cancellation. They may retain one transient paid-demolition or purchase input edge, but perform no paid demolition, purchase, movement, hazard damage, Warp lifecycle, recovery, or session-time transition.

## 11. Balance Resources and Validation

Every value is Inspector-editable in the Resource responsible for that behavior. `PrototypeConfigValidator` owns authoring-time validation. `PrototypeBalance` copies validated values into `SessionStartConfig`; runtime systems never retain or reread mutable Resource objects.

| Resource | Field | Default | Valid range | Runtime owner |
|---|---|---:|---:|---|
| `SessionCashBalance` | `starting_session_cash` | `300` | `0..1,000,000` | `SessionEconomy` |
| `HazardGenerationBalance` | `hazard_cell_count` | `12` | `0..4,096`, and no more than eligible cells | `HazardSystem` |
| `DurabilityBalance` | `maximum_durability` | `100.0` | finite `1.0..1,000,000.0` | `TrainSystem` |
| `DurabilityBalance` | `damage_per_traveled_cell` | `10.0` | finite `0.0..1,000,000.0` | `HazardSystem` |
| `DurabilityBalance` | `repair_cost_per_durability` | `1.0` | finite `0.0..1,000,000.0` | snapshot/result calculation |
| `TrackInvestmentBalance` | `major_track_action_cost` | `50` | `0..1,000,000` | `SessionEconomy` + `TrackSystem` transaction |
| `TrackInvestmentBalance` | `temporary_track_purchase_cost` | `40` | `0..1,000,000` | `SessionEconomy` |
| `TrackInvestmentBalance` | `temporary_track_cells_per_purchase` | `5` | `1..4,096` | `TrackSystem` |
| `TrackInvestmentBalance` | `maximum_temporary_track_purchases` | `6` | `0..100` | session purchase counter |
| `CargoInvestmentBalance` | `temporary_cargo_purchase_cost` | `80` | `0..1,000,000` | `SessionEconomy` |
| `CargoInvestmentBalance` | `temporary_cargo_slots_per_purchase` | `1` | `1..8` | `CargoSystem` |
| `CargoInvestmentBalance` | `maximum_temporary_cargo_purchases` | `4` | `0..8` | session purchase counter |

Validation rejects null nested Resources, non-finite floats, out-of-range values, integer overflow in maximum capacity/cost calculations, and a configured cargo maximum above the concrete supported slot limit. `PrototypeConfigValidator.validate()` owns Resource-only checks. After `PrototypeBalance.complete_session_start_config()` has copied the logical grid and departure cell, `PrototypeConfigValidator.validate_completed_session_start_config()` owns `hazard_cell_count <= grid_cell_count - 1` and any other grid-dependent cross-field check. `PrototypeApp` calls both validation entry points before composing runtime systems. Errors name the full Resource-qualified field. There is no runtime clamp or silent default substitution.

## 12. Snapshots, Results, and Presentation

Detached snapshots add:

- current and starting session cash;
- spending totals by action class;
- maximum/current durability and repair-cost basis;
- immutable hazard cell records;
- temporary track and cargo purchase counts and current capacity;
- pending crossing preview facts;
- pointer-derived demolition/crossing eligibility and affordability facts.

`SessionResult` adds `DURABILITY_DEPLETED`, final cash, durability loss, repair-cost basis, and purchase/action totals. It does not settle, repair, persist, or convert reward.

The top HUD shows `CASH` and `DURABILITY` as live values while retaining time, track, and base reward. The bottom HUD retains contract/cargo/track-end information and adds concrete `BUY TRACK +5 / 40` and `BUY CARGO +1 / 80` buttons. Disabled styling communicates purchase limits, active gesture ownership, and insufficient funds without mutating domain state.

Hazards use primitive terrain marks. Demolition hover uses one suffix/prefix outline. A pending crossing uses a simple bridge/gap primitive and cost text. No custom art or audio is introduced.

## 13. Determinism and Test Contract

Required evidence includes:

- same seed produces byte-identical hazard cells; different approved seeds vary; Warp RNG history remains unchanged;
- hazard layout and severity never change during a session;
- partial and multi-cell movement damage equals actual canonical distance;
- zero durability completes once after same-sweep Warp contact and before other end reasons;
- repair basis equals durability loss times its configured rate with the documented ceiling;
- free ghost cancellation remains free and refunds the full suffix;
- front-suffix and rear-prefix paid demolition each charge once and refund every removed cell;
- unaffordable or invalid demolition changes neither gameplay state nor cash;
- crossings require perpendicular complete traversal, never branch or merge, charge once per finalized occurrence, and preserve locked geometry;
- multiple exact-contact distances at a crossing remain deterministic and do not double-deliver;
- temporary purchases apply exact increments, honor limits, never affect train length/speed/recovery, and never refund;
- all three end reasons terminate spending and carry no temporary increase into a new session;
- current grid, construction, recovery, geometry, train, Warp Cargo, input, layout, and four-resolution Windows regressions remain green;
- one tracked `.gd.uid` sidecar exists per GDScript and no orphan sidecar exists.

## 14. Deferred Third Step

Minimal `RunState` cash is explicitly third and deferred. Its later design must decide cross-session lifetime, reward conversion, settlement order, repair charging, contracts, operating costs, persistence, and result-to-run transfer. Nothing in this slice makes provisional session cash authoritative beyond one session or promises a migration API.
