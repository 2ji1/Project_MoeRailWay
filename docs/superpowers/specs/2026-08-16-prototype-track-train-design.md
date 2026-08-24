# Prototype Track and Train Design

> **Historical status (2026-08-24):** This specification was delivered at commit `67518fc8dc4c106dfc6e20f901bcb2ef832efcb5` and accepted as tag `prototype-m3`. Its continuous-polyline route rules remain milestone evidence, not current implementation authority. Current route authority is `docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md`.

- Date: 2026-08-16
- Status: Approved
- Audience: Agent-facing canonical specification
- Integration base: `Prototyping`
- Future implementation branch: `proto/02-track-train`
- Accepted milestone tag after implementation: `prototype-m3`
- Related gameplay specification: `docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md`
- Related development strategy: `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`
- User briefing: `docs/briefings/ko/2026-08-16-prototype-track-train-design-briefing.md`
- Execution boundary: this planning session may finalize and commit documentation only. Branch creation and Godot implementation begin only in a separate development session explicitly started by the user.

## 1. Outcome

`proto/02-track-train` validates whether maintaining one continuously built route ahead of one nonstopping train is playable and legible under finite inventory and delayed physical construction.

This milestone replaces the empty session shell with:

- an untimed departure-preparation phase;
- seeded selection from editor-placed departure candidates;
- immediate route reservation followed by fixed-speed physical construction;
- endpoint-only left-drag extension;
- right-click cancellation of reserved unbuilt route suffixes;
- one fixed-speed train that travels only on built track;
- continuous rear recovery and exact inventory return;
- built-track-end early termination and warning feedback.

The approved rules in this document supersede less-specific track statements in the earlier gameplay and development-strategy specifications.

## 2. Milestone Boundary

### 2.1 Included in `proto/02-track-train`

- Logical track field and resize-independent coordinate mapping
- A default set of eight editor-authored departure candidate nodes
- Seeded, equal-probability departure selection
- Departure preparation with no running session timer
- Continuous left-drag reservation from the current reserved endpoint
- Immediate reservation accounting
- Ordered construction queue with fixed construction speed
- Free right-click cancellation of reserved unbuilt suffixes
- Active-route self-intersection rejection
- Field-boundary clipping
- One fixed-speed train and built-track-end detection
- Continuous partial rear recovery
- Available-track and track-end feedback
- Track-end result reason and one-shot result presentation
- Feature-specific Inspector balance Resources

### 2.2 Explicitly deferred

- Cash mutation, paid demolition, and grade-separated crossings: `proto/04-risk-investment`
- Warp pairs, cargo, loading, delivery, and expiry: `proto/03-warp-cargo`
- Hazards, durability, temporary purchases, and repair basis: `proto/04-risk-investment`
- Contracts and settlement: `proto/05-contract-economy`
- Credit, repeated cycles, and bankruptcy: `proto/06-credit-survival`
- Replay logs, packaged Windows delivery, and formal playtest instrumentation: `proto/07-playtest-ready`
- Final art, custom fonts, audio, mobile, touch, gamepad, multiple trains, stopping, reversing, branches, merges, pathfinding, and production abstractions

## 3. Session and Departure Flow

The visible session states are:

1. `PREPARING_DEPARTURE`
2. `RUNNING`
3. `COMPLETED`

An internal transient `READY` state may remain for dependency composition, but the player never sees a separate ready screen or start button.

On scene startup:

1. Validate every Resource, logical-field setting, and departure candidate.
2. Copy Inspector values into one session-start value set.
3. Seed the existing deterministic session RNG.
4. Sort departure candidates by stable candidate ID.
5. Select exactly one candidate with equal probability using the session seed.
6. Enter `PREPARING_DEPARTURE` with the full session duration visible but frozen.
7. Display only the selected departure point at runtime.

No active train exists during departure preparation, so the nonstopping-train invariant does not apply yet. The selected point is the initial reserved endpoint.

The player reserves and constructs route until built route length reaches the configured departure requirement, whose default is `360` logical units. On the exact fixed tick that construction first reaches this length, the controller enters `RUNNING`, moves the train for its first tick, and consumes the first session-timer tick. No separate launch input or grace timer exists.

## 4. Logical Field and Departure Candidates

### 4.1 Field-size Inspector

The logical field root node owns an Inspector dropdown rather than reading screen pixels as game distance.

| Preset | Logical size |
|---|---:|
| `COMPACT` | `900 x 420` |
| `STANDARD` | `1200 x 560` |
| `EXPANSIVE` | `1500 x 700` |
| `CUSTOM` | Inspector-authored width and height |

`STANDARD` is the approved default. The initial custom-width range of `640..4000` and custom-height range of `320..2160` logical units are provisional implementation-planning values, not gameplay invariants; they remain Inspector-visible and reviewable before implementation. These ranges can reproduce every approved preset.

The logical field maps uniformly into the available `%Field` rectangle. Aspect-ratio remainder becomes noninteractive internal letterbox space. Window resizing and UI padding change presentation scale only; they never change route length, train speed, inventory cost, recovery distance, or simulation results.

When the field-size preset changes in the editor, candidate nodes preserve their normalized placement ratio. They remain independently movable through the Godot 2D transform gizmo and `Transform > Position`.

The logical field root provides an editor-only boundary preview for the currently selected preset or custom size. The preview must update in the Godot 2D editor without starting the game, remain aligned with candidate-node gizmos, and never become runtime gameplay geometry.

### 4.2 Candidate nodes

The logical field scene contains a `DepartureCandidates` parent with a default set of eight `DepartureCandidate` nodes based on `Marker2D`. Candidate positions do not live in a balance manager or coordinate array Resource.

Each candidate has one stable, unique ID. The following normalized positions are provisional authoring defaults for the first implementation. They may be tuned in the editor before implementation approval without changing the equal-probability selection rule:

| ID | Normalized position |
|---|---:|
| `departure_01` | `(0.18, 0.22)` |
| `departure_02` | `(0.50, 0.18)` |
| `departure_03` | `(0.82, 0.22)` |
| `departure_04` | `(0.22, 0.50)` |
| `departure_05` | `(0.78, 0.50)` |
| `departure_06` | `(0.18, 0.78)` |
| `departure_07` | `(0.50, 0.82)` |
| `departure_08` | `(0.82, 0.78)` |

Runtime selection is uniform across the sorted candidate set. It performs no reroll, feasibility test, or position correction. The same seed and unchanged candidate set select the same candidate ID. Moving a candidate changes that ID's position without changing which ID the seed selects. Adding, removing, or renaming candidates may intentionally change the mapping.

Unselected candidate markers remain editor-authoring data and are invisible at runtime.

## 5. Input Grammar

### 5.1 Left mouse button: drawing only

The left mouse button has no cancel, edit, or paid-action behavior.

The numeric input distances below--`24` for endpoint grab, `16` for route hit testing, `8` for minimum sampling, and `4` for intersection clearance--are provisional first-implementation tuning defaults. They are Inspector-owned and reviewable; endpoint-only drawing and deterministic tick sampling are the invariant rules.

- A stroke may start only within `24` logical units of the current reserved endpoint.
- Before any route exists, the selected departure point is that endpoint.
- During a held stroke, the application samples one logical cursor position per fixed tick.
- Samples closer than `8` logical units to the reserved endpoint do not append geometry.
- Each accepted sample appends one straight polyline segment from the owned endpoint toward the sampled cursor.
- Releasing the button ends input sampling but does not stop construction already queued.
- A later stroke must begin again within the endpoint radius.
- Construction may still be behind the reservation. The player always extends from the reserved endpoint, not the physical construction head.

There is no artificial speed limit on reservation input. Physical construction speed is the separate limiting rule.

### 5.2 Right mouse button: cancellation or future demolition

Right-click hit testing uses a `16`-logical-unit route radius and the route state at the start of the fixed tick.

In `proto/02`:

- Right-clicking reserved unbuilt route projects the click onto that route.
- If several reserved segments are within the hit radius, choose the smallest Euclidean-distance projection; an epsilon tie chooses the greatest route distance so the smaller suffix is canceled.
- Geometry from the projected point through the reserved endpoint is canceled.
- The canceled reservation length returns to available inventory immediately and exactly once.
- The retained prefix keeps constructing normally, and its cut position becomes the new reserved endpoint.
- Right-clicking built track, recovered space, or empty field makes no domain change.

Right-click is edge-triggered: one press submits at most one command, and holding the button never repeats cancellation. Any right-button press ends the active left-drag stroke. If left and right mouse commands occur in one fixed tick, the right-click command wins. A still-held left button does not resume automatically on the next tick; the player must release it and begin a new press within the new reserved-endpoint radius.

### 5.3 Boundary and intersection clipping

New reservation is clipped at the first of:

1. available-inventory exhaustion;
2. the logical field boundary;
3. an intersection with built or reserved active route.

An intersection result stops at the configured `4`-logical-unit clearance before contact, so it never creates a touching merge. Only the accepted length consumes inventory. Adjacency at the owned endpoint is not an intersection. A rejected zero-length result consumes nothing.

Dragging outside the logical field clips route at the boundary but keeps the held-stroke state. Re-entering the logical field may continue from that boundary endpoint without another press.

Coordinates occupied only by automatically recovered or paid-demolished route are reusable. `proto/02` never permits a free active crossing.

## 6. Route Lifecycle and Accounting

One route contains ordered geometry with these lifecycle regions:

1. `TRAVELED_RETAINED`
2. `BUILT_UNTRAVELED`
3. `RESERVED_UNBUILT`
4. `RECOVERED` or canceled geometry no longer present in the active route

The route has monotonic absolute arc distance. Construction, train movement, cuts, and recovery may split a polyline segment at an interpolated point so results do not depend on input sample length.

The conservation invariant is:

`available inventory + built active length + reserved unbuilt length = total inventory`

The equality holds within a small fixed technical geometry epsilon after every mutation. This epsilon handles floating-point comparison only; it is not balance data and is not Inspector-adjustable.

Approved default inventory values are:

- Total inventory: `720` logical units
- Departure requirement: `360` built logical units
- Rear recovery distance: `240` logical units behind the train

Reservation consumes length immediately. Construction moves length from `RESERVED_UNBUILT` to `BUILT_UNTRAVELED` without another inventory charge. Cancellation moves only canceled reserved length back to available inventory. Recovery moves only eligible built length back to inventory. No length can be returned through two transitions.

## 7. Construction, Train, Recovery, and End Rules

### 7.1 Physical construction

The default construction speed is `120` logical units per second. At `60` fixed ticks per second, the construction head advances exactly `2` logical units per tick through the reserved route.

- Construction continues after mouse release.
- New reservation may be appended while older reservation is still under construction.
- Construction stops when it reaches the reserved endpoint or the session completes.
- Canceling reservation before construction in a tick prevents that length from becoming built in the same tick.

### 7.2 Train

The default train speed is `60` logical units per second, exactly `1` logical unit per tick at the default tick rate.

- The train begins at route distance zero on departure.
- It moves forward at the configured fixed positive speed.
- It never stops, reverses, or changes speed during a session.
- It can travel only through `BUILT_UNTRAVELED` geometry.
- If its movement reaches the current built endpoint, it clamps there and records `TRACK_END_REACHED`, even when reserved unbuilt geometry remains beyond that point.

### 7.3 Rear recovery

After train movement, the recovery cutoff is:

`train route distance - recovery distance`

Any built route behind the cutoff is removed continuously, including partial segments, and returned immediately. Repeating recovery at the same cutoff returns zero. Inventory returned by recovery appears in that tick's snapshot and may be reserved beginning with the next tick.

### 7.4 Warning and completion

During `RUNNING`, track-end time is:

`built distance ahead of train / train speed`

The warning becomes urgent at or below the configured warning threshold, whose default is `3.0` seconds. Reserved unbuilt route does not count as safe track-end distance.

If regular time expiry and `TRACK_END_REACHED` occur on the same tick, `REGULAR_TIME_EXPIRED` wins. Any earlier built-track-end request wins normally. Completion publishes one terminal snapshot and then one result. Post-completion input and fixed ticks do nothing.

## 8. Inspector-Owned Data

Every balance-sensitive number is Inspector-editable through a feature-owned Resource or the spatial node that owns it.

| Owner | Field | Default | Validation |
|---|---|---:|---|
| `SessionBalance` | session duration | `180.0 s` | `> 0` |
| `SessionBalance` | fixed ticks per second | `60` | `1..240` |
| `TrainBalance` | train speed | `60.0 units/s` | `> 0` |
| `TrackInventoryBalance` | total inventory | `720.0 units` | `> 0` |
| `TrackInventoryBalance` | recovery distance | `240.0 units` | `> 0` and `< total inventory` |
| `TrackInventoryBalance` | urgent warning | `3.0 s` | `> 0` |
| `TrackConstructionBalance` | construction speed | `120.0 units/s` | `> 0` |
| `TrackConstructionBalance` | endpoint grab radius | `24.0 units` | `> 0` |
| `TrackConstructionBalance` | route hit radius | `16.0 units` | `> 0` |
| `TrackConstructionBalance` | minimum sample distance | `8.0 units` | `> 0` and `<= endpoint grab radius` |
| `TrackConstructionBalance` | intersection clearance | `4.0 units` | `> 0` and `<= minimum sample distance` |
| `DepartureBalance` | required built route | `360.0 units` | `> 0` and `<= total inventory` |

The existing `PrototypeBalance` remains a composition Resource that references feature-specific `.tres` files. It does not own runtime state or execute game rules. Candidate coordinates stay in scene nodes rather than any balance Resource.

Session startup copies validated values into `SessionStartConfig`. Active domain objects never read Nodes or Resources directly, and changing Inspector data cannot mutate an active session.

`TrackInvestmentBalance` is introduced only in `proto/04`. One authoritative `major_track_action_cost` value is shared by one paid built-track demolition and one grade-separated crossing so the two prices cannot drift.

## 9. Concrete Ownership

Keep implementation concrete for the prototype.

- `TrackSystem`: ordered route, reservation, construction head, inventory, cancellation, intersection clipping, and recovery
- `TrainSystem`: one train's route distance, position, heading, fixed-speed movement, and built-end request
- `SessionController`: state, fixed-tick order, end-request priority, snapshots, and one-shot completion
- `LogicalTrackField`: field-size preset, logical bounds, and editor candidate-node placement
- `TrackFieldView`: input sampling, coordinate mapping, primitive drawing, hover previews, and snapshot presentation
- `PrototypeApp`: explicit composition root using the existing shell and session lifecycle
- `EconomySystem`: future sole cash writer and paid-action authorizer beginning in the relevant investment slice

Presentation converts viewport positions into logical-field positions and submits value commands. It never mutates `TrackSystem`, `TrainSystem`, inventory, or cash directly.

`SessionSnapshot` exposes detached copies of built route, reserved route, construction-head position, train pose, available and total inventory, departure progress, built distance ahead, estimated track-end time, warning state, timer state, and session phase.

Do not add interfaces, abstract bases, a global event bus, a route graph, physics bodies, navigation, pathfinding, or generalized multi-train support.

## 10. Fixed-Tick Order

Every active application fixed tick, whether preparing or running, uses this exact order:

1. Read one mouse input frame in logical coordinates.
2. Apply one right-click cancellation or future authorized demolition against tick-start route state.
3. If no right-click command won, append valid left-drag reservation.
4. Advance physical construction through the remaining reservation.
5. If preparing and built length reaches the departure requirement, enter `RUNNING`.
6. If running, advance the train and record a built-track-end request.
7. Resolve later movement-derived cargo and hazard steps when their branches exist.
8. Recover eligible rear track and credit inventory once.
9. Resolve later warp-expiry steps when that branch exists.
10. Advance the session timer only while running and record regular expiry.
11. Resolve end requests, with regular expiry winning a same-tick tie against track end.
12. Publish one detached snapshot.
13. If completed, emit one result after the terminal snapshot.

Construction that completes before train movement in a tick may prevent track-end failure in that tick. Recovery happens after input, so returned inventory cannot fund reservation until the following tick.

## 11. Presentation Contract

Use primitive presentation only:

- Built track: thick solid line
- Reserved unbuilt track: thinner translucent line
- Construction head: small emphasized marker
- Train: simple shape with visible heading
- Selected departure point: simple marker
- Unselected candidate nodes: runtime-invisible
- Right-click hover target in `proto/02`: highlighted reserved-route cancellation range
- Paid demolition-range preview: added with the demolition action in `proto/04`

The existing top `TRACK` HUD value shows `available / total`. During preparation, the bottom `TRACK END` value shows `built / configured departure requirement` using the current numeric values. During running it shows estimated seconds to the built endpoint and switches to urgent styling at or below the configured warning threshold.

The result overlay supports both `REGULAR_TIME_EXPIRED` and `TRACK_END_REACHED`. The app's existing completion guard remains authoritative.

Custom art, fonts, particles, and audio remain excluded. Art replacement must not change domain geometry, hit distances, balance data, or layout metrics.

## 12. Validation and Failure Handling

Debug startup fails before creating session state when:

- a required feature Resource is missing;
- a numeric field violates its validated constraint;
- departure requirement exceeds total inventory;
- a custom logical field size is invalid;
- no departure candidate exists;
- candidate IDs are empty or duplicated;
- candidate positions fall outside logical bounds.

Errors identify the owning Resource or node and exact field. Runtime assertions remain next to the system that owns each invariant.

Input that cannot produce valid route geometry is a no-op. It never consumes inventory. Right-clicking built track during `proto/02` is a no-op because cash-backed demolition has not arrived. Completed sessions ignore later input and tick calls.

## 13. Historical Paid-Demolition Pointer

The former continuous-polyline paid-demolition and crossing rules were removed from active future authority on 2026-08-24 because they duplicate and conflict with the grid-cell route model. `proto/05-risk-investment` owns a future cell-based specification for paid demolition, early rear recovery, and grade-separated crossings. The deletion is recorded in `docs/superpowers/plans/2026-08-24-prototype-grid-track-amendment.md`.

## 14. Verification Strategy

### 14.1 Pure domain tests

- Exact reservation charge and free suffix-cancellation refund
- Overlong reservation clipped without negative inventory
- Field-boundary and active-route-intersection clipping
- One continuous ordered polyline after every accepted operation
- Construction advances exactly `2` units per default tick
- Construction continues after release and accepts later endpoint extension
- `PREPARING_DEPARTURE` freezes the timer before the configured built-length threshold
- The threshold tick starts `RUNNING`, advances the train once, and consumes exactly one timer tick
- Departure occurs only at `360` built units under the approved default configuration
- Fixed train movement and heading through multi-segment corners
- Built-end clamp and one-shot `TRACK_END_REACHED`
- Partial-segment recovery and repeated-recovery idempotence
- Conservation invariant after every mutation
- Same-tick regular-expiry priority
- Terminal snapshot before one result

### 14.2 SceneTree integration tests

- Real left-drag reservation and right-click cancellation
- Left clicks away from the current endpoint do nothing
- HUD and letterbox input do not create route
- Equal-seed departure candidate selection is stable
- Zero candidates, empty or duplicate candidate IDs, and out-of-bounds candidate positions reject startup with node-specific diagnostics
- `COMPACT`, `STANDARD`, `EXPANSIVE`, and one valid `CUSTOM` size preserve logical geometry and pointer alignment
- One nondefault balance configuration changes construction, departure, movement, recovery, and warning behavior without code changes
- Missing Resources, invalid balance values, and invalid `CUSTOM` dimensions reject startup with owner-and-field diagnostics
- A right-click press cancels at most once, terminates a held left stroke, and requires a new left press before drawing resumes
- The editor boundary preview follows preset and `CUSTOM` changes while candidate gizmos remain aligned
- Runtime window resize preserves pointer alignment and simulation values
- HUD shows preparation progress, inventory, warning, and result reason
- Identical explicit input sequences reproduce ordered snapshots and results

### 14.3 Windows manual gate

- The selected candidate appears and the session timer remains frozen during preparation.
- Reserving route immediately reduces available inventory.
- Physical track visibly follows the reservation at the configured slower speed.
- Right-click cancels only the selected unbuilt suffix and returns its exact length.
- Built route reaches `360`, then the train and timer begin together.
- The player can extend from the reserved endpoint while construction is still behind.
- The train continues with zero available inventory and fails if it catches construction.
- Rear route disappears continuously and returned inventory can be reused.
- Warning becomes urgent at three seconds and track end produces one result overlay.
- Supported 16:9 window sizes preserve geometry and input alignment.
- The Godot 2D editor shows the selected logical-field boundary and keeps every departure-candidate gizmo aligned while presets and `CUSTOM` values change.

## 15. Acceptance

The milestone is accepted only when:

- all existing `prototype-m2` automated behavior remains covered;
- all new domain and integration tests pass without skips;
- inventory never becomes negative and every return occurs once;
- candidate selection, route construction, movement, recovery, and end-event order reproduce under identical inputs;
- Windows manual play demonstrates that a player can sustain the train through reservation, construction, and recovery timing;
- the implementation contains no paid-economy placeholder, custom art dependency, speculative production abstraction, or unrelated refactor;
- the feature branch is reviewed before squash integration into `Prototyping` and tagging as `prototype-m3`.

No implementation branch or worktree is created by this design document.
