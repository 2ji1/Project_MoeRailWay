# Contract Economy Prototype Design

**Date:** 2026-08-30

**Status:** Implementation, publication, integration, milestone tagging, verification, and feature cleanup authorized; documentation review in progress

**Target branch:** `feature/contract-economy`

**Verified integration base:** `dd9d1d04a126c23a1b3c420cde67711e6e4738dc`

## 1. Purpose and Authority

Contract Economy is the bounded prototype slice after Risk & Investment. It completes one playable contract-selection-to-settlement cycle while preserving the Windows PC, mouse-only, top-down 2D, one-train route game.

This document is the English implementation authority for the slice. It consumes the integrated Warp Cargo and Risk & Investment systems. It does not reimplement route ownership, construction, train movement, Warp generation, cargo slots, hazards, durability, demolition, crossings, or temporary purchases.

Risk & Investment deliberately deferred persistent cash and reward conversion to this slice. This design therefore supersedes only that feature's provisional statements that session cash expires and `base_delivery_reward_total` is non-spendable. Risk's priced-action accounting, no-refund rules, result evidence, and all other gameplay contracts remain authoritative. The historical Risk documents are not rewritten to pretend the later ownership existed earlier.

The implementation remains concrete. It does not introduce a generic ledger, persistence framework, transaction framework, service locator, event bus, interchangeable economy interface, or production abstraction. Full-production abstraction remains a post-prototype decision.

## 2. User-Confirmed Decisions

1. Persistent run cash starts at `300` by default.
2. The initial amount is an Inspector-editable balance value, not a hard-coded rule.
3. One persistent `RunState` cash flow is used. There is no separate renewable session allowance.
4. A session starts from current RunState cash, applies session purchases and immediate delivery fees, then returns final session cash to settlement.
5. Recommendation defaults may settle remaining prototype choices when they preserve existing approved rules and require no new external authority.
6. Gameplay implementation and local verification are authorized after the documentation gate.
7. For this Contract Economy feature only, the user authorized exact-path task commits, feature push, a `main` pull request, merge-commit integration, the next unused milestone tag, primary fast-forward/retest, and cleanup after every objective gate passes.

## 3. Scope

### 3.1 Included

- exactly six company definitions;
- one selected company contract per session;
- deterministic company assignment for every generated Warp pair;
- immediate company-specific base delivery fees for every delivery;
- contracted-company-only delivery count, quota, and attainment;
- a deterministic cash adjustment curve capped at 100% attainment;
- fixed-point trust from over-attainment only;
- persistent RunState cash, trust, and completed-cycle count;
- one-shot ordered contract, repair, and operating settlement;
- contract selection, session contract HUD, result breakdown, and return-to-operations flow;
- an explicit output boundary for Credit Survival;
- Inspector-editable balance Resources and placeholder-only presentation;
- deterministic unit, integration, and four-resolution Windows mouse verification.

### 3.2 Excluded

- borrowing, principal, interest, repayment schedules, refinancing, credit-limit calculation, deficit recovery, and bankruptcy;
- cycle-scaled hazards or other difficulty growth;
- more than one selected contract;
- permanent upgrades, train purchases, offices, campaign content, saving to disk, or cross-launch persistence;
- custom art, imported icons, custom fonts, audio, mobile, touch, controller support, or production architecture.

## 4. Run Lifecycle and Ownership

`RunState` is one concrete in-memory owner of:

- signed integer cash;
- completed cycle count;
- fixed-point trust for exactly six company IDs.

RunState exists for the current application run only. It is not an autoload and is never accessed globally. `PrototypeApp` composes it explicitly with one concrete `PrototypeRunController`.

The run phases are:

1. `OPERATIONS`: show companies and require one contract selection;
2. `SESSION`: run the existing fixed-tick Warp session using current RunState cash;
3. `RESULTS`: show the immutable settlement breakdown;
4. return to `OPERATIONS` after explicit mouse confirmation.

A session may start only when one valid company is selected and RunState cash is nonnegative. Contract Economy does not declare bankruptcy. If settlement leaves cash negative, operations remains readable and session start is disabled with `CREDIT SURVIVAL REQUIRED` feedback.

## 5. Balance Resources

### 5.1 `CompanyContractBalance`

Each of exactly six nested Resources exposes:

- `company_id: StringName`;
- `display_name: String`;
- `generation_weight: int`;
- `base_delivery_fee: int`;
- `quota: int`;
- `maximum_shortfall_penalty: int`;
- `completion_bonus_at_quota: int`;
- `trust_per_excess_delivery_milli: int`.

Company IDs must be nonempty and unique. Display names must be nonempty. Generation weights are positive integers. Quotas are at least one. Cash fields and trust increments are nonnegative and bounded against overflow.

The prototype uses neutral placeholder IDs and labels `company_01` through `company_06` / `Company 1` through `Company 6`. Their gameplay numbers remain tuning data rather than rules.

### 5.2 `ContractEconomyBalance`

One nested Resource exposes:

- `initial_run_cash = 300`;
- `base_operating_cost`;
- six `CompanyContractBalance` entries in stable array order.

The six entries are separate Inspector-editable nested Resources. Changing one company never requires editing domain code.

This `initial_run_cash` is the only Inspector authority for the run's initial cash. The former `PrototypeBalance.session_cash_balance` export, its validator requirement, and its `.tres` subresource are retired from real composition in this slice. `SessionStartConfig.starting_session_cash` remains a detached per-session value, but the run controller copies it from current `RunState.cash`; it never reloads a renewable session allowance from a second balance Resource.

Configuration validation rejects null entries, counts other than six, duplicate IDs, invalid bounds, invalid text, nonpositive total generation weight, and any worst-case arithmetic that can exceed the signed prototype cash/trust limits. Runtime never clamps invalid configuration or silently substitutes a company.

### 5.3 Legacy global reward retirement

`CargoBalance.base_delivery_reward` and the copied `SessionStartConfig.cargo_base_delivery_reward` stop being authoritative inputs in the real Contract Economy application. The composed application resolves both company ID and company-specific base fee from the six validated company entries. The old global value may remain temporarily only as an explicit fallback for direct pre-Contract synthetic test fixtures while those fixtures are migrated. Final application and integration composition never reads that fallback, and configuration tests prove that company data is the sole reward authority in the real session path.

## 6. Deterministic Company Assignment

Every Warp pair owns one company ID and a copied company-specific base fee from forecast creation through void, load, delivery, or expiry. Pair color and shape continue to identify the origin-destination pair; a separate primitive company marker identifies the company.

Company assignment uses an independent RNG stream:

```text
company_seed = session_seed ^ 0x434F4D50414E5952
```

The literal encodes the fixed positive salt `COMPANYR`. A separate existing `SessionRng` instance performs integer weighted selection in stable six-entry order. It does not advance or inspect the Warp location/lifetime RNG. The same session seed and company balances therefore reproduce company assignment without changing the already approved Warp spatial and lifecycle sequence.

No selected-contract bias, quota correction, reachability filtering, reroll, or route-aware company assignment is allowed.

## 7. Contract Selection

Operations presents all six companies. The player selects exactly one company and then explicitly starts the session.

Selection fixes for that session:

- selected company ID;
- integer quota;
- cash-curve endpoints;
- trust conversion value.

The values are copied into detached session contract configuration. Later Inspector or RunState changes cannot alter an active session. Quota never changes because of session duration, early end, generated requests, delivered cargo, or perceived achievability.

## 8. Delivery, Cargo Identity, and Immediate Cash

Cargo retains the company ID and copied base fee of its Warp pair. Loading, full-slot failure, expiry, voiding, and matching-destination delivery otherwise keep their approved behavior.

Every successful delivery emits one detached delivery fact containing:

- pair ID;
- company ID;
- base fee;
- whether the company matches the selected contract;
- contracted delivery count after the event.

The base fee is credited to the live `SessionEconomy` exactly once on the delivery tick. It is immediately available for later in-session purchases. Uncontracted deliveries receive the same company-specific base fee but change no quota, cash curve, penalty, or trust state.

`CargoSystem` accumulates the delivered cargo's copied company fee into one total. The old `base_delivery_reward_total` observation remains as a compatibility alias for that same immediate `delivery_fee_total`. The alias is not a second balance and is never credited separately. The legacy global reward fallback cannot contribute to a delivery produced by the real composed application.

## 9. Attainment and Cash Settlement Curve

Let:

- `D` be delivered cargo belonging to the selected company;
- `Q` be the fixed positive quota;
- `P` be `maximum_shortfall_penalty`;
- `B` be `completion_bonus_at_quota`.

Attainment is stored as integer basis points:

```text
attainment_basis_points = floor(D * 10000 / Q)
```

Display may exceed 100%, but cash settlement clamps delivery count to quota:

```text
capped_D = min(D, Q)
numerator = capped_D * (B + P) - Q * P
cash_contract_adjustment = signed_round_half_away_from_zero(numerator / Q)
```

The notation means exact rational rounding, never integer division followed by rounding. Let `magnitude = abs(numerator)`, `quotient = magnitude / Q` using integer floor division, and `remainder = magnitude % Q`. Increase `quotient` by one when `2 * remainder >= Q`, then apply the original sign of `numerator`; zero remains zero. Validation guarantees `numerator`, `abs(numerator)`, and `2 * remainder` fit within the signed prototype integer limit before this algorithm runs.

This produces `-P` at zero delivery, transitions linearly through the approved integer range, and produces `+B` at quota. Deliveries beyond quota do not increase the cash contract adjustment. All calculations use checked integer arithmetic. Floating-point UI percentages never feed settlement.

## 10. Trust

Only over-attainment creates trust:

```text
excess_deliveries = max(D - Q, 0)
trust_gain_milli = excess_deliveries * trust_per_excess_delivery_milli
```

Trust uses a fixed scale of `1000` units per displayed trust point. Storage never rounds; presentation rounds only for display. Trust is company-local, persistent for the in-memory run, non-spendable, and unchanged by fees, penalties, costs, contract selection, or uncontracted delivery.

Contract Economy does not calculate a credit limit. It only publishes the six exact trust values for later Credit Survival consumption.

## 11. Ordered Settlement

Settlement executes at most once for regular expiry, track-end completion, or durability depletion. The session result is immutable before settlement starts.

The exact Contract Economy order is:

1. install the session's final cash, including purchases and immediate delivery fees, as the settlement opening cash;
2. calculate attainment and apply the one contract cash adjustment;
3. apply over-attainment trust to the selected company;
4. subtract the existing integer `repair_cost_basis` and treat the next session as starting at maximum durability;
5. subtract `base_operating_cost`;
6. confirm all session-only track/cargo increases and pending action authority are gone;
7. increment completed cycle count once;
8. publish one immutable settlement result and enter `RESULTS`.

Cash may become negative during settlement. There is no rejection, partial settlement, skipped cost, hidden floor at zero, or automatic borrowing. Invalid arithmetic fails before mutation. The complete candidate RunState and settlement result are built and validated first, then replace the live RunState in one concrete controller operation.

Repeated result presentation, resize, mouse hold, scene redraw, or continue input never settles twice.

## 12. Presentation Contract

### 12.1 Operations

The operations screen uses ordinary Godot Controls and placeholder primitives. It shows:

- current cash and completed cycles;
- all six companies in stable order;
- company marker, name, current trust, base fee, quota, zero-delivery penalty, and quota bonus;
- selected state and one explicit `START SESSION` button;
- negative-cash blocking feedback without borrowing controls.

### 12.2 Session

The existing map remains dominant. HUD additions show selected company, contracted deliveries, quota, attainment, and accumulated delivery fees. Warp points and cargo slots add a non-color-only company marker without replacing pair color/shape identity or blocking mouse input.

### 12.3 Results

Results show the ordered numeric breakdown:

- session starting cash;
- delivery fee total as an informational reconciliation row;
- session spending as an informational reconciliation row;
- settlement opening cash, exactly `session starting cash + delivery fee total - session spending`;
- contracted deliveries and attainment;
- contract adjustment;
- trust gain;
- repair cost;
- operating cost;
- closing cash;
- completion reason and completed cycle count.

One `CONTINUE TO OPERATIONS` button changes phase once. Presentation reads detached observations and never writes cash, trust, contract counts, or settlement state directly.

## 13. Fixed-Tick and Event Order

The existing session order remains authoritative. Contract Economy adds only these steps:

1. after a cargo delivery resolves, resolve its company fact;
2. credit its fee and update contract delivery count on that same tick;
3. preserve movement-before-expiry and same-sweep completion priority;
4. after the existing one-shot session result is produced, perform ordered settlement once outside later session ticks.

Company assignment occurs when a pair is generated. Contract selection and settlement never consume session RNG.

## 14. Credit Survival Boundary

Credit Survival receives detached observations of:

- signed closing RunState cash;
- completed cycle count;
- stable six-company trust values;
- selected company ID;
- contracted deliveries, quota, and attainment;
- session starting cash, informational fee and spending reconciliation, settlement opening cash, and every later ordered settlement line item;
- whether next-session start is blocked by negative cash.

It may later add company-specific credit limits, debt, borrowing, repayment, refinancing, difficulty growth, and bankruptcy. It must not reinterpret Contract Economy's delivery fees, cash curve, trust gain, settlement order, or one-shot result.

No placeholder debt fields, fake zero loans, migration interface, or generic creditor abstraction is added in this slice.

## 15. Determinism and Test Contract

Automated evidence must prove:

- exactly six validated unique companies;
- same seed and balances reproduce company assignment while Warp spatial/lifetime traces stay unchanged;
- selected contract never biases generation;
- every delivery credits one company fee once and the compatibility total does not double-credit;
- only selected-company deliveries change attainment;
- zero, partial, exact, and over-quota settlement match exact integer formulas;
- only excess deliveries add fixed-point trust;
- regular, track-end, and durability end settle once in the same order;
- negative settlement cash is retained and blocks session start without declaring bankruptcy;
- all temporary upgrades remain cleared and no cost is refunded;
- operations, session, and results transitions are mouse-safe at all supported resolutions;
- old route, Warp, cargo, Risk, resize, and result-priority regressions remain green;
- each GDScript has exactly one tracked `.gd.uid` sidecar.

Automated evidence never converts a mouse-only row to PASS. Direct agent-driven Windows mouse observations are recorded as `AGENT-VERIFIED`, never `USER PASS`; ambiguous or incomplete observations remain pending and block publication.

## 16. Completion and Deferrals

The slice is complete only when one player can select a company, play a real session with mixed-company cargo, observe immediate fees and selected-company attainment, receive one ordered settlement, inspect persistent cash/trust, and return to operations with byte-identical fixed-seed results across reruns.

Credit Survival, Playtest Ready, custom art/audio, mobile support, campaign content, disk persistence, permanent upgrades, and production abstraction remain deferred.
