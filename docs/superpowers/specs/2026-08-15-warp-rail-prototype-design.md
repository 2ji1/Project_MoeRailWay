# Warp Rail Endless Survival Prototype Design

- Date: 2026-08-15
- Status: Approved design, amended by the accepted track-and-train baseline and approved grid-track amendment
- Audience: Agent-facing canonical specification
- Target: Prototype for validating the core game loop
- Historical track-and-train baseline: docs/superpowers/specs/2026-08-16-prototype-track-train-design.md
- Current grid-track detail: docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md

## 1. One-Sentence Definition

Warp Rail is a timed, single-stroke grid-route game in which the player continuously places limited track cells ahead of one train that never stops, serves randomly generated warp cargo requests with finite lifetimes, and keeps both delivery performance and company cash flow alive.

## 2. Prototype Goals

The prototype validates three hypotheses:

1. Continuously extending track ahead of a moving train creates repeatable tension.
2. Immediate delivery fees and a contracted quota create meaningful route and cargo-capacity choices.
3. Spending cash inside the current warp session versus preserving it for the company creates meaningful risk decisions.

Warp locations and lifetimes are never rerolled or adjusted after generation to help the player. Rejecting an unfavorable request and waiting for a later opportunity is a valid part of play.

## 3. Out of Scope

- Multiple trains, dispatching, transfers, and branching rail networks
- Stopping, speed control, and reversing
- Permanent upgrades to track inventory or cargo capacity
- Campaign progression, endings, and narrative progression
- Purchasable train models and office-upgrade content; Section 16 reserves extension boundaries only
- Guaranteed reachability or post-generation rerolls
- Manual loading or unloading, and free manual recovery of built track; paid early demolition is reserved for `proto/05-risk-investment`
- Borrowing during a warp session
- Mobile, touch, and gamepad support

The first prototype targets Windows PC, a 16:9 presentation, and mouse-only interaction. Mobile support belongs to full production after prototype validation.

## 4. Overall Game Loop

One cycle proceeds in this order:

1. Operations screen: inspect cash, company trust, and debt, then borrow if desired.
2. Contract selection: select one company from the prototype default of six.
3. Warp operation: draw track and deliver cargo until the session ends.
4. Settlement: apply contract performance, repair cost, operating cost, principal, and interest.
5. Financial recovery: if settlement leaves negative cash, return to operations and borrow to recover.
6. Next cycle or bankruptcy: start the next cycle only with nonnegative cash; otherwise end the run.

The prototype has no victory condition. Hazard density and damage grow over cycles, and the player operates until bankruptcy.

The final prototype must support the complete repeatable loop from contract selection through bankruptcy. A one-session graybox is an intermediate milestone, not the final completion criterion.

## 5. Warp Session

### 5.1 Train

- Exactly one train is active.
- When a session begins, the train moves at a fixed positive speed and never stops.
- Loading and unloading happen instantly when the train passes a point and do not affect speed.
- Reaching the current end of track or reaching zero durability ends the operation immediately.
- Increasing cargo capacity changes capacity only. It does not change physical train length, speed, or the track-recovery point.

### 5.2 Track and Single-Stroke Drawing

- The player may extend track only from the current end of one continuous ordered grid route.
- Held mouse motion reserves the orthogonally adjacent cells actually crossed. The system never creates a diagonal shortcut or finds a route to a destination.
- Every newly accepted unique route cell immediately consumes exactly one track-inventory cell. Reclassifying owned cells as a larger curve costs nothing extra.
- The system resolves the ordered cells into straight or `1x1`, `2x2`, and `3x3` curves with nominal lengths `1`, `3`, and `5` cells. Mandatory warp-cell contact and nearby-curve overlap may force a smaller curve.
- Unbuilt route appears as translucent ghost track and may reflow until construction begins. A piece locks when its first cell begins construction.
- Each cell changes through `RESERVED_GHOST`, `BUILDING`, and `BUILT`; the train may enter only the contiguous built prefix.
- Right-clicking an entirely unlocked ghost cell cancels that cell and the later ghost suffix for free and immediately returns one inventory cell per removed cell.
- Track behind the recovery lag is removed automatically in route order and returns one cell at a time. It provides no cash refund, and recovered coordinates may be reused.
- `proto/05-risk-investment` owns the future cell-based paid demolition and costly grade-separated crossing rules. Crossings never create a branch or merge.
- The train never pauses when inventory is empty. If it reaches the completed endpoint before rear cells are recovered or construction finishes, the operation ends.
- The player may buy additional track inventory with session cash. The increase disappears at every regular or early session end.

The challenge is not only shortest-path planning. The player must read upcoming recovery, integer inventory timing, curve footprint, mandatory warp contact, and self-crossing risk while maintaining one continuous line.

### 5.3 Warp Origins and Destinations

- One request contains an origin-destination pair, one company, and one cargo unit.
- Both points appear at random positions together and share one lifecycle.
- Active pairs use matching colors and shapes that remain distinguishable from other active pairs.
- The origin uses a filled shape and the destination uses the matching outline.
- Random results are fixed before presentation. A forecast or current effect reveals the already determined time and location and never rerolls the result.
- Forecasted points are informational only and do not load, unload, deliver, or trigger warp interactions before activation.
- Forecast duration, point lifetime, and simultaneous active-pair count are balance data.

Each pair may load once and deliver once. Repeatedly farming the same pair for fees or trust is impossible.

### 5.4 Automatic Loading and Unloading

- Passing an active origin with an empty cargo slot loads the cargo immediately.
- After loading, the origin becomes an outline and one cargo slot shows the matching filled color and shape.
- When all slots are full, the train does not load and the origin remains active until expiry.
- Passing the matching destination delivers immediately. The destination fills and the cargo marker disappears.
- Delivery immediately pays that company’s base fee.
- If the destination expires first, its cargo disappears immediately and frees exactly one slot. There is no per-request fine.
- Missing an origin or allowing cargo to expire costs time, route length, capacity, and contract opportunity rather than a separate penalty.
- The player may buy additional cargo slots during a session. They disappear at every regular or early session end.

### 5.5 Hazards and Durability

- Hazards are always visually identifiable.
- Damage is deterministic and based on distance actually traveled through hazard terrain.
- Hazards never slow the train. Detouring spends time and track; crossing spends durability and creates future repair cost.
- Zero durability ends the operation immediately.
- After settlement, the train is restored to full durability and repair cost is charged from durability lost. Every session starts at maximum durability.

### 5.6 Session End Types

Regular warp end:

- The fixed session timer expires and clears the warp space.
- Remaining origins, destinations, and carried cargo become void: neither success nor failure.
- Voided cargo creates no per-request fine or extra reduction in attainment.
- All session-only track and cargo-capacity purchases disappear.

Early operation end:

- Reaching the track end or zero durability ends operation immediately.
- Remaining session time is discarded, and contract performance uses deliveries completed so far.
- Undelivered cargo is removed without per-request fines. Lost fees and quota opportunity are the penalty.
- Repair cost and all out-of-session fixed expenses settle normally.

If delivery and expiry share a decision instant, movement and pass-through resolve first. Entering the destination region before session time or point life reaches zero counts as delivery.

## 6. Contracts and Companies

### 6.1 Contract Selection

- Requests from several companies appear together on the field.
- Before each session the player contracts with exactly one company.
- Contract selection fixes an integer quota Q of at least one, fee, completion bonus, and shortfall penalty.
- Q never changes during the session, including after an early-end request.
- Random generation does not guarantee the quota is achievable.

### 6.2 Delivery Fees and Service Attainment

- Every company’s delivery pays its base fee immediately.
- Uncontracted-company deliveries never affect contract attainment, penalties, or trust.
- Only deliveries belonging to the contracted company count toward quota.
- Skipping an unfavorable contracted request is not recorded as an individual failure; it sacrifices a limited opportunity.
- At settlement, completed contracted deliveries D produce:

    A = D / Q * 100%
    Cash contract settlement = C(min(A, 100%))
    Trust gain = G(max(A - 100%, 0))

- C is the configured bonus and penalty curve; G converts over-attainment to trust.
- Trust uses fixed-point storage. Rounding is display-only.
- Attainment up to 100% determines cash bonus or penalty.
- Deliveries beyond 100% still pay base fees.
- Over-attainment never increases the cash contract bonus and instead creates permanent trust for that company.

### 6.3 Trust

- Trust accumulates independently for the prototype default of six companies during one run.
- Trust is not spendable and borrowing never subtracts it.
- Trust’s only direct system input is that company’s credit-limit function H(R).
- Trust never changes interest rates, fees, quotas, bonus or penalty curves, warp frequency, or contract availability.
- Every company starts at trust zero and credit limit zero. The first over-attainment is required to unlock borrowing.
- H(R) is nondecreasing. Growth curves and per-company caps are balance data.

This structure supports concentrating on one company for a large limit or spreading over-attainment across companies to build refinancing options.

## 7. Cash and Temporary Investment

- Cash persists across sessions during a run.
- Delivery fees enter cash immediately during operation.
- Contract settlement, repair, operating cost, and loan payments occur at session settlement.
- In-session purchases require sufficient current cash.
- Purchasable items are track inventory, cargo capacity, grade-separated crossings, built-track demolition, and edits to built untraveled track.
- Temporary track and capacity increases disappear at every end condition. Spent cash never returns.

Saving preserves future company funds but can lose delivery opportunity. Overspending may make operating, repair, and loan costs unaffordable.

## 8. Loans and Debt

### 8.1 Borrowing

- Borrowing is available only on the between-session operations screen.
- The player may borrow voluntarily even with nonnegative cash.
- While operations is open, borrowing has no transaction-count limit.
- Each amount is player-selected from the minimum currency unit through that company’s remaining credit.
- Borrowing immediately increases cash and that company’s outstanding principal.
- The player may borrow from several companies and use one company’s proceeds to service another company’s debt.
- Companies do not share debt assessment. There is no global debt cap.
- Available company credit equals its trust-based limit minus its outstanding principal.

### 8.2 Interest and Repayment

- Company i has a per-cycle fixed rate r_i that never changes during one run.
- All new and existing loans from a company use the same r_i.
- Trust, company condition, borrowing time, amount, and transaction count never change the rate.
- Every borrowing action creates a repayment schedule.
- The first principal and interest payment occurs at settlement of the first session ending after borrowing.
- Each settlement adds scheduled principal and interest calculated on principal immediately before scheduled repayment.
- All principal and interest items across loans are summed.
- Term length, principal schedule, company rates, and limit curves are balance data.
- The prototype supports scheduled automatic repayment only and excludes voluntary early repayment.

Refinancing is an intentional high-risk strategy earned by building trust across companies. More debt raises unavoidable future costs and demands stronger future revenue.

### 8.3 Deficit and Bankruptcy

Settlement executes exactly once in this order:

1. Calculate contract attainment and apply cash bonus or penalty.
2. Apply over-attainment trust and update the company credit limit.
3. Restore full durability and subtract repair cost.
4. Subtract base operating cost.
5. Calculate interest on pre-repayment outstanding principal, subtract scheduled principal and interest, then reduce principal by scheduled principal.
6. Remove every session-only upgrade and open operations.

Updated credit limits and credit freed by principal payment are immediately available in the following operations screen.

Settlement may make cash negative. Negative cash does not immediately end the run. The player may borrow on the operations screen and must restore cash to at least zero before starting the next session. If all available credit is insufficient or the player declines recovery, the company becomes bankrupt.

## 9. Endless Progression

- Persistent run state contains cash, cycle count, each company’s trust, and each company’s debt.
- Every session uses the same base rules.
- Hazard density and damage grow with cycle count, raising route pressure and expected repair cost.
- Base operating cost repeats every cycle and loan schedules add fixed expense.
- Later difficulty never causes post-generation adjustment of warp positions or lifetimes.
- Bankruptcy results show survived cycles, total deliveries, best attainment per company, trust per company, peak debt, and final debt.

## 10. Information and Feedback

### 10.1 Operation Screen

The following must remain readable:

- Session time remaining
- Distance or estimated time from train to current track end
- Track inventory remaining
- Cash and action costs
- Maximum and occupied cargo slots
- Durability and expected hazard damage
- Contract company, quota, deliveries, and attainment
- Each pair’s color, shape, company, and remaining lifetime
- Forecast location and countdown

Company identity uses a small marker separate from pair color and shape. Color and shape identify origin-destination pairing only.

Cargo slots appear as cars following the train for immediate readability, but capacity never changes physical train length.

The session layout uses a top-down orthographic 2D field inspired by Mini Metro and thin top- and bottom-anchored HUD bands. The map remains the dominant area.

### 10.2 Operations Screen

The player must compare, for each company:

- Current trust
- Trust required for the next credit-limit increase
- Total and remaining credit
- Fixed rate
- Outstanding principal
- Next-cycle principal and interest

Before borrowing or choosing a contract, show the projected total fixed expense at the next settlement.

### 10.3 Adjustable UI Layout

- UI art and game logic remain separate, while layout metrics remain intentionally configurable.
- An agent-editable UILayoutProfile resource owns horizontal and vertical outer padding, panel padding, item gaps, row gaps, HUD height, and icon size.
- Godot Control and Container nodes respond automatically when metrics change.
- Each axis may be tuned independently in the Inspector during prototyping.
- Validated minimum and maximum values prevent padding or HUD height from consuming the required playfield.
- The prototype does not include a player-facing UI settings screen.
- Full production may reuse the same structure for a user-facing UI scale option.

## 11. Conceptual System Boundaries

- RunState: cash, cycle count, company state, and debt that persist during a run
- WarpSession: timer, difficulty stage, and regular or early end requests
- TrackSystem: route reservation, ordered construction, inventory, automatic recovery, cancellation, demolition geometry, and crossing validation
- TrainSystem: fixed-speed movement, end-of-track detection, pass-through detection, and durability
- WarpPairSystem: generation, forecast, activation, lifetime, and state transitions
- CargoSystem: slots, automatic loading and unloading, and expiry removal
- ContractSystem: selected contract list, quota, deliveries, attainment, cash curve, and trust gain; prototype list length is at most one
- EconomySystem: delivery fees, purchases, and ordered settlement
- CreditSystem: company limits, borrowing, principal, interest, and schedules
- Presentation: field shapes, timers, warnings, cost previews, results, and adjustable layout

Communication is limited to explicit events such as track placed, origin passed, destination passed, warp expired, delivery completed, session end requested, loan executed, and settlement completed.

EconomySystem is the sole cash writer. ContractSystem is the sole contract-performance writer. Presentation never changes domain state directly.

The implementation uses one composition controller rather than a global event bus. Pure GDScript domain models remain separate from Node2D, Line2D, Control, and CanvasLayer presentation nodes.

## 12. State Transitions and Decision Order

Warp-pair states are:

    Forecast -> Active/Unloaded -> In Transit -> Delivered
                                -> Expired
                   In Transit -> Destination Expired/Cargo Removed
    Any active state -> Regular Warp End/Voided

Each physics tick resolves in this exact order:

1. Apply right-click cancellation or authorized demolition commands against the tick-start route state.
2. Accept sampled left-drag input as route reservations.
3. Advance physical construction and resolve departure readiness.
4. Calculate train movement and end-of-built-track status. Record an end request without settling yet.
5. Resolve swept origin and destination pass-through and apply loading or delivery.
6. Resolve hazard damage and zero durability.
7. Recover eligible rear track and return its length once.
8. Resolve warp-pair expiry.
9. Resolve session timer expiry.
10. Prioritize accumulated end requests and execute one settlement.
11. Publish one read-only presentation snapshot, then emit one result if the session completed.

The session controller owns this order. Pass-through is computed from previous to current train position rather than depending on Godot physics-signal ordering.

## 13. Required Invariants

- Track inventory never becomes negative.
- Available inventory plus built active length plus reserved unbuilt length equals total inventory within the fixed technical geometry epsilon.
- Each recovered segment returns inventory exactly once.
- Each canceled, demolished, or automatically recovered length returns inventory through exactly one transition.
- Built and reserved route geometry remains one ordered, nonbranching path around the train.
- One warp pair creates one cargo unit and one delivery reward.
- One cargo unit occupies one slot and frees exactly one slot.
- Delivery and expiry never apply to the same pair.
- Regular-end voiding never creates a penalty or failed-request count.
- Settlement executes once per session.
- Borrowing never exceeds remaining company credit.
- Borrowing never consumes trust or changes interest.
- Trust affects no direct rule except that company’s credit limit.
- Session-only upgrades never survive any end condition.
- UI-layout values remain inside validated bounds and cannot reduce the field below the required playable area.

Invalid balance or UI configuration prevents session start in debug builds and reports the exact resource and field. Debug assertions enforce invariants close to their owning systems. Release-style prototype builds fail safely to operations or results rather than applying settlement twice.

## 14. Required Prototype Scenarios

1. Inventory remains zero while waiting for recovery and the train reaches the end first.
2. Crossing active track charges the larger cost without creating a branch.
3. Automatic load and unload with empty, full, and mixed cargo slots.
4. Delivery immediately before destination expiry and removal immediately after expiry.
5. Regular end voids in-transit cargo without result.
6. Early end discards remaining time and settles current deliveries.
7. Attainment exceeds 100% and only the excess becomes trust.
8. Voluntary borrowing with positive cash and borrowing from several companies.
9. One company’s loan services another company’s principal and interest.
10. New borrowing recovers a post-settlement deficit, and exhausted limits cause bankruptcy.
11. Every end condition clears temporary track and cargo capacity.
12. Repair cost scales with durability loss and the next session starts at full durability.
13. UI layout accepts minimum and maximum configured padding without overlap or field loss.

Random sessions store their seed and ordered event log for replay. Playtests record survived cycles, end-of-track early-end rate, crossing frequency, deliveries gained per temporary purchase, contracted versus uncontracted deliveries, idle cargo-slot rate, and debt-service share.

Prototype validation requires observing all three target decisions in repeated play: maintaining track under recovery pressure, selecting contract-relevant cargo under capacity pressure, and spending versus preserving cash. Feature completion alone does not count as prototype validation.

## 15. Balance Data

The following are tunable data rather than rules:

- Session duration and forecast duration
- Train speed and base durability
- Base track inventory, recovery distance, departure construction length, construction speed, and input hit distances
- Base cargo capacity
- The shared major-track-action cost for built-track demolition and grade-separated crossing, plus temporary-expansion cost curves
- Pair generation interval, simultaneous active count, and lifetime distribution
- Company frequency, fee, quota, bonus, and penalty curves
- Over-attainment-to-trust conversion
- Trust-to-credit-limit curves
- Company fixed rates and repayment terms
- Base operating cost, hazard damage, and cycle scaling
- Repair cost per durability
- UI-layout padding, gaps, HUD height, and icon size within validated bounds

Tuning must not change these rules: no post-generation correction, continuous single-stroke track, a nonstopping active train, automatic loading and baseline recovery, exact reservation accounting, expiring session investment, and independent company credit.

## 16. Post-Prototype Permanent Spending and Extension Boundary

These items are not prototype content. They reserve boundaries so validated production work can add permanent uses for surplus cash without rebuilding the core loop.

### 16.1 Common Rules

- Permanent purchases occur only on the operations screen.
- Purchases use persistent company cash. Borrowed and earned cash share the same balance, so leveraged asset buying remains possible.
- Purchased trains and office levels survive warp resets.
- Each item supports a purchase price and per-cycle upkeep, including zero upkeep.
- Permanent upgrades add choices and trade-offs without removing nonstopping, single-train, limited-track, random-warp, or finite-lifetime constraints.

### 16.2 Train Models and Fleet

- Train models are data-driven TrainModelDefinition records.
- The player permanently owns purchased models and selects exactly one before a session.
- Exactly one train remains active regardless of fleet size.
- Extensible model fields are price, upkeep, fixed speed, durability, repair multiplier, base track inventory, and base cargo capacity.
- Model speeds may differ but remain fixed during sessions and inside common positive bounds.
- Office effects never alter speed or speed multiplier during a session.
- Higher performance must trade against price, upkeep, repair, or another capability; avoid strict upgrades.
- Session-only inventory and capacity add on top of model base values and are the only values removed at session end.

### 16.3 Office Upgrades

- Office upgrades are data-driven, staged OfficeUpgradeDefinition records.
- Each definition has an identifier, price, upkeep, prerequisites, maximum level, and an allowed effect list.
- Prerequisites may reference office levels and owned models only, not trust or borrowing.
- The prototype contract limit is one company.
- A future contract-management department may increase simultaneous company contracts.
- Multiple contracts calculate Q, D, A, cash settlement, and trust independently.
- One cargo belongs to one company contract and never advances multiple contracts.
- Multiple contracts add both bonus opportunity and independent shortfall risk; quotas are never pooled.

Allowed office families include:

- Operations Analysis: improves forecast timing or presentation without changing generated results or lifetimes
- Maintenance: adjusts model durability and repair multipliers within allowed bounds
- Logistics: adjusts base track or cargo capacity without preserving session-only purchases
- Contract Management: increases simultaneous contract limit and presents each contract independently

Financial office upgrades may improve information or repayment convenience only. Fixed company rates and the rule that trust affects only credit limits remain unchanged.

### 16.4 Extension Interfaces

Future implementation may add:

- TrainModelCatalog for model definitions and balance data
- FleetState for owned and selected models
- OfficeUpgradeCatalog for definitions, levels, and prerequisites
- OfficeState for purchased levels and upkeep
- UpgradeEffectResolver for composing only explicitly allowed effects
- ContractSystem accepting a contract list from the first implementation, with prototype maximum length one

UpgradeEffectResolver uses a closed effect list: base track, base cargo capacity, durability, repair multiplier, forecast information, and simultaneous contract limit.

It cannot affect warp position, lifetime, rerolls, stopping, in-session speed, temporary-purchase persistence, trust, fixed interest, or the credit-limit function.

Session start composes values in this explicit order:

1. Selected train-model base
2. Permanent office effects
3. Current session’s temporary purchases

Only the third layer is removed at session end.

The prototype implements a SessionStartConfig input boundary only. It does not implement train catalogs, fleet state, office catalogs, office state, or upgrade content.

### 16.5 Invariants After Extension

- Fleet size never creates more than one active train.
- No model or upgrade can stop the train or ignore track-end failure.
- Warp location and lifetime remain uncorrected after generation.
- No effect provides free crossings, unlimited track, or unlimited cargo.
- At maximum progression, base track still cannot complete every field-spanning route without recovery decisions.
- Maximum permanent cargo capacity remains below maximum simultaneous cargo count.
- Office upgrades never preserve temporary track or cargo capacity.
- Multiple contracts retain independent performance and settlement.
- Trust continues to affect only that company’s credit limit.

### 16.6 Future Extension Verification

- Owned models and office levels survive every session end while temporary purchases disappear.
- Owning several models still creates only the selected one.
- Multiple contracts credit one cargo to one company and settle independently.
- Model and office upkeep appears once in forecast and once in actual settlement.
- Operations Analysis reveals only already-determined RNG information.

## 17. Prototype-to-Production Handoff

Prototyping is isolated from Development. The Prototyping branch is never merged wholesale into Development.

After validation:

1. Record validated mechanics, rejected assumptions, balance ranges, usability findings, and art requirements in English production specifications.
2. Review each prototype module for independent reuse.
3. Reimplement prototype shortcuts in production architecture unless a module has explicit tests, a stable interface, and no prototype-only dependency.
4. Selectively port approved data, tests, and pure logic. Never import the prototype scene tree as the production foundation by default.

The purpose of this boundary is to carry evidence into production without carrying accidental prototype architecture.
