# Credit Survival Prototype Design

**Date:** 2026-08-30

**Status:** Activation candidate; Contract Economy dependency satisfied, activates when this document set merges to `main`

**Document activation branch:** `docs/credit-survival-revalidation`

**Verified implementation base:** `592072c1de535bcb5ce56c4a97f6515791bfe096`

**Implementation branch:** `feature/credit-survival`, created from the document-integration `main` commit

## 1. Authority and Dependency Gate

Contract Economy is integrated on `main` at merge commit `592072c1de535bcb5ce56c4a97f6515791bfe096`, and annotated milestone `prototype-m6` peels to the same commit. Revalidation bound this slice to the integrated Contract implementation: `src/domain/run/run_state.gd` owns persistent cash, completed-cycle count, canonical company order, and fixed-point trust; `src/domain/run/prototype_run_controller.gd` owns contract selection, session transition, one-shot settlement staging, and the no-fail `RunState.replace_with` installation; `src/app/prototype_app.gd` composes operations, contract selection, sessions, and results; and `src/domain/run/settlement_result.gd` owns detached result facts, including its reserved Credit observation dictionary.

The primary checkout was verified clean and equal to `origin/main` at that commit before activation. The user has authorized autonomous implementation and publication after the objective document review gates pass; no additional approval pause is required inside this Credit Survival scope.

No fake Contract API, temporary `RunState`, compatibility adapter, or speculative persistence layer may be created to bypass this dependency.

## 2. Purpose

Credit Survival completes the repeatable company-survival loop after one contract-and-settlement cycle already works. It adds:

- trust-based independent company credit limits;
- voluntary between-session borrowing, including while cash is nonnegative;
- fixed per-company rates and deterministic automatic repayment schedules;
- simultaneous debt across several companies;
- shared-cash refinancing without direct early repayment;
- post-settlement deficit recovery;
- cycle progression and deterministic hazard difficulty growth;
- one-shot bankruptcy;
- operations, debt, recovery, and run-result feedback;
- detached observations required by Playtest Ready.

The prototype remains concrete. It does not add save files, accounts, a general ledger, a generic financial transaction framework, a persistence service, an event bus, or production abstractions.

## 3. Standing Product Rules

The following rules are inherited and may not be changed by this slice:

1. Borrowing is available only between sessions on the operations screen.
2. The player may borrow with positive, zero, or negative cash.
3. Each borrowing amount is an integer from one currency unit through that company's remaining credit.
4. Trust is company-specific, is never spent, and affects only that company's credit limit.
5. Every company begins with trust zero and credit limit zero.
6. Company credit assessment is independent. There is no global debt cap.
7. Borrowed and earned money share one persistent company cash balance.
8. Proceeds borrowed from one company may fund future scheduled payments owed to another company.
9. Interest rates are fixed per company for the entire run. Trust, amount, timing, and transaction count never change a rate.
10. Every borrowing action creates one repayment schedule.
11. The first scheduled payment is due at settlement of the first session ending after borrowing.
12. Interest is calculated on principal immediately before that settlement's principal repayment.
13. Repayment is automatic. Voluntary early repayment is excluded from the prototype.
14. Settlement executes at most once per session.
15. A next session cannot start while persistent cash is negative.
16. The prototype has no victory condition and continues until bankruptcy.

## 4. User-Confirmed and Adopted Decisions

### 4.1 Equal-principal repayment

The user confirmed equal-principal repayment.

For original principal `P` and configured term `N`:

```text
regular_principal = floor(P / N)
scheduled_principal(k) = regular_principal, for 1 <= k < N
scheduled_principal(N) = current principal immediately before installment N
```

Any indivisible remainder is paid in the final installment. When `P < N`, earlier installments may have zero principal and the final installment pays the remaining principal. This preserves the minimum borrowing amount of one currency unit without silently shortening the configured term.

### 4.2 Interest rounding

Company rates are stored as integer basis points per cycle. Interest uses deterministic ceiling division:

```text
interest_due = ceil(pre_repayment_principal * rate_basis_points / 10_000)
```

Zero rate produces zero interest. Positive principal at a positive rate produces at least one currency unit of interest. All multiplication and addition are overflow-checked before mutation.

### 4.3 One loan per borrowing action

Every accepted borrowing press creates one immutable loan identity and one schedule. Loans are not silently combined, even when the company and cycle match. Presentation may aggregate totals, but deterministic observations retain stable company order and ascending loan ID.

## 5. Contract Economy Prerequisite Contract

The integrated Contract Economy provides the following concrete facts and operations.

### 5.1 Persistent run ownership

One run-owned state must expose:

- persistent integer cash;
- current cycle number;
- six stable company IDs in canonical order;
- fixed-point trust per company;
- a company-rate basis-point table copied once from validated balance data at run creation;
- completed settlement and Credit facts needed across cycles; the selected contract and active cycle remain controller-owned transient state;
- one-shot run completion state.

`RunState` is the one persistent Credit source of truth. It stores the canonical active-loan list, the next loan ID, Credit revision, and run-copied company rates. Outstanding company principal, remaining credit, next principal, and next interest are derived from the active-loan list and are never stored as independent mutable caches. Every loan ID is unique and positive; original principal is positive; current principal is in `1..original principal`; installments settled are in `0..term`; first due cycle is positive; and each loan company belongs to the canonical six-company order.

Contract Economy must already prove that session-only cash and capacity are not persistent authority. Credit Survival must not copy Risk's `SessionEconomy` into a second persistent cash owner.

### 5.2 Settlement boundary

Contract Economy must expose one staged, one-shot settlement operation that:

1. applies contract cash bonus or penalty;
2. applies over-attainment trust;
3. updates the trust-based credit-limit input;
4. charges repair cost and restores durability to full as one existing repair stage;
5. charges base operating cost;
6. accepts Credit Survival's detached debt-service quote;
7. stages one aggregate settlement candidate containing the persistent `RunState` replacement for cash and Credit state plus the controller-owned result and phase replacements;
8. installs the already validated `RunState` candidate with `RunState.replace_with`, then assigns the already constructed settlement result and `RESULTS` phase without another fallible call. The terminal `SessionResult` already carries repair basis and cleared temporary-investment facts and is not mutated by settlement.

The controller owns a monotonically increasing settlement identity. Entering a session reserves the identity; quote creation reads it; a rejected settlement retains it; and the successful `try_settle_session` consumes it only as the controller assigns the settlement result and `RESULTS` phase. The identity is not duplicated into `RunState`. Credit revision remains in `RunState` because borrowing and debt payment change persistent Credit facts independently of controller presentation.

`PrototypeRunController` remains the sole authoritative cash candidate builder and installer for both settlement and borrowing. `CreditSystem` is a pure calculator/validator that proposes loan and debt-service facts but never installs cash. `RunState` owns installed cash and Credit facts. Presentation writes neither.

### 5.3 Session transition boundary

Contract Economy must already compose one session from persistent cash and must return one authoritative session result into settlement. Credit Survival extends that transition with debt service, deficit recovery, cycle advancement, difficulty composition, and bankruptcy; it does not reimplement cargo, contract attainment, repair basis, or session spending.

## 6. Credit Limits

### 6.1 Fixed-point input

Credit consumes each company's authoritative fixed-point trust without display rounding. Contract Economy defines the trust scale. Revalidation must bind the exact scale before any credit balance value is approved.

### 6.2 Deterministic nondecreasing function

Each company credit balance contains an ordered set of integer knots `(trust, limit)`. The first knot is `(0, 0)`. Trust and limit values are nondecreasing. For trust `T` between adjacent knots `(Ta, La)` and `(Tb, Lb)`, the limit is `La + floor((T - Ta) * (Lb - La) / (Tb - Ta))`. Validation guarantees positive denominators and multiplication headroom before the query runs. Values above the last trust knot use the last limit as the company cap.

This preserves the canonical nondecreasing `H(R)` contract while allowing six companies to have different growth and caps. It does not permit trust to change rates, terms, fees, quotas, contract availability, or any session rule.

### 6.3 Remaining credit

```text
outstanding_company_principal = sum(active loan principal for company)
credit_limit = H(authoritative company trust)
remaining_credit = max(credit_limit - outstanding_company_principal, 0)
```

Limit reduction below outstanding principal never erases or accelerates debt. It only makes remaining credit zero. Under the current game rules trust does not decrease, but the fail-closed behavior remains deterministic.

## 7. Borrowing and Shared Cash

Borrowing is an operations-only atomic action:

1. validate that the run and operations screen are active and not terminal;
2. validate stable company ID and integer amount;
3. recompute remaining company credit from current trust and principal;
4. reject amounts below one or above remaining credit with the canonical state observation value-unchanged;
5. stage one complete run-state replacement containing the new loan, incremented next-loan ID and Credit revision, run-copied rates, and post-borrow persistent cash; company principal remains derived from the staged active-loan list;
6. validate it fully and install it through the authoritative no-fail replacement boundary in one controller call;
7. publish one detached borrow result.

There is no gameplay or balance transaction-count limit while operations is open; the numeric safety policy in Section 10.2 remains a fail-closed machine-bound guard. A held mouse button does not synthesize repeated borrowing. Distinct press edges may create distinct loans.

Cash is global to the run, while principal and credit remain company-specific. There is no direct command to transfer debt or repay another company early. Refinancing occurs because borrowed cash enters the shared balance and can cover another company's scheduled payment at a later settlement.

## 8. Loans, Quotes, and Settlement Commit

### 8.1 Loan record

Each active loan contains only concrete prototype facts:

- stable loan ID;
- stable company ID;
- original principal;
- current principal;
- fixed rate basis points copied at borrowing;
- configured term in cycles;
- installments already settled;
- first due cycle.

`first_due_cycle` is always `RunState.completed_cycle_count + 1` at the accepted borrow. Before the first session this is cycle 1; after cycle `C` settles, including during deficit recovery, it is cycle `C + 1`. Contract acceptance commits that same pending next cycle, so the first session ending after the borrow is exactly the first due settlement.

An active loan is defined by `current principal > 0`; terminal state is derived rather than stored. Run creation copies every company's rate from validated balance data. Every later loan copies the company's run-owned rate, so editing balance data during a running debug session affects neither existing nor new loans in that run.

### 8.2 Detached debt-service quote

Before settlement mutation, `CreditSystem` derives an immutable quote in canonical company order and ascending loan ID within each company. The quote carries settlement identity, current cycle, and Credit state revision. Each item contains pre-repayment principal, scheduled principal, interest, post-payment principal, and post-payment installments settled. Every due installment increments `installments_settled` exactly once even when scheduled principal is zero; this is required for `P < N` schedules to advance. Repeated quote creation for the same authoritative state produces the same canonical detached observation and does not advance a schedule. Tests compare a canonical JSON string built only from ordered arrays and dictionaries whose keys are inserted in the specified order; they do not compare Resource identity or unspecified Dictionary history. This test representation is not Playtest Ready's event-log format.

### 8.3 Atomic commit

The settlement controller validates the complete Contract, repair, operating, detached terminal-session facts, result, and Credit aggregate before mutating state. Cash and Credit are not installed through two fallible writes. Persistent facts remain in the staged `RunState`; the completed `SessionResult` remains immutable; and phase/result/settlement-identity facts remain in `PrototypeRunController`. After constructing the detached `SettlementResult`, the commit sequence is exactly `RunState.replace_with(candidate)`, controller result assignment, controller phase assignment to `RESULTS`, and settlement-identity consumption. These operations are assertion-protected assignments over already validated candidates and contain no fallible cleanup, signal, snapshot, redraw, or presentation call. Presentation observes the completed aggregate afterward and may redraw or retry without domain mutation.

Every quote is bound to the settlement identity, current cycle, and Credit state revision used to calculate it. Commit rejects a stale identity, wrong cycle, or changed revision with the complete canonical run-state observation and settlement identity value-unchanged, so a corrected quote may be retried. The settlement identity is consumed exactly once only by the successful complete replacement. A duplicate result callback, repeated frame, reopened result screen, or retry cannot charge interest or principal twice.

Principal paid at settlement immediately frees the same amount of company credit. Trust gained earlier in the same settlement also affects the credit limit visible in the following operations screen.

## 9. Deficit Recovery and Bankruptcy

### 9.1 Recovery mode

Settlement may leave cash negative. This opens operations in deficit-recovery mode. Contract selection and session start remain disabled until cash is nonnegative.

The player may perform any valid borrowing sequence. A company with remaining credit may be used regardless of which company was contracted or which company is owed scheduled debt.

### 9.2 Recoverability

```text
recovery_comparison_capacity = sum remaining credit, stopping once it reaches `-current_cash`
recovery_possible = recovery_comparison_capacity >= -current_cash
```

If cash is negative and recovery is impossible, bankruptcy is mathematically unavoidable and completes once with reason `CREDIT_EXHAUSTED`. `RunState` already constrains cash to `-1_000_000_000_000..1_000_000_000_000`, so negating a negative cash value is safe. The comparison capacity stops at the deficit and cannot overflow. Detached observations separately expose `aggregate_remaining_credit_saturated`, computed across all six companies with checked addition and saturation at `RunState.MAX_ABSOLUTE_CASH`; per-company remaining-credit observations preserve the uncapped exact inputs.

If recovery is possible, the player may borrow or explicitly decline recovery. Declining while cash is negative completes once with reason `RECOVERY_DECLINED`. Declining is unavailable while cash is nonnegative.

No automatic borrowing occurs. Bankruptcy never rewrites debt, trust, or cash to cosmetic values; the terminal run result retains the exact state.

Settlement always commits and shows its ordinary `SettlementResult` first. When the player continues, `PrototypeRunController.try_continue_to_operations` computes recoverability from the committed `RunState`. Recoverable negative cash enters recovery operations. Unrecoverable negative cash stages and fully validates a terminal-transition candidate containing reason `CREDIT_EXHAUSTED`, the complete detached terminal result, and `TERMINAL` phase before the first controller assignment. The commit suffix assigns those already validated fields without a fallible call and does not mutate `RunState`. `try_decline_recovery` stages and commits the same candidate shape with `RECOVERY_DECLINED`. Injected failure before the first assignment leaves reason, result, phase, settlement identity, and `RunState` unchanged. Repeated continue, decline, result callback, or presentation calls reject in `TERMINAL` and cannot replace the terminal result.

## 10. Cycle Progression and Difficulty

### 10.1 Cycle ownership

`RunState.completed_cycle_count` is the only persistent cycle counter. In operations with no selected contract, the pending/next cycle is `completed_cycle_count + 1` and is controller-derived only. Accepting a contract copies that value into controller-owned `selected_cycle` in the same transition as the selected contract; `RunState` remains unchanged. During the session and results phase, `selected_cycle` is the active/current cycle. Successful settlement requires `selected_cycle == completed_cycle_count + 1` and then increments `completed_cycle_count` exactly once. Returning to operations clears `selected_cycle`; cancellation before session start also clears it without persistent mutation. Therefore the first session is cycle 1, a post-cycle-`C` operations/recovery screen has completed count `C` and next cycle `C + 1`, and every accepted borrow uses `first_due_cycle = completed_cycle_count + 1`.

### 10.2 Difficulty composition

Credit Survival owns progression timing, not hazard generation. For cycle `C >= 1`, it composes copied session-start values from the Risk base balances:

```text
clamped_base_hazards = min(eligible cells, base_hazard_count)
hazard_steps = floor((C - 1) / hazard_growth_interval_cycles)
if hazard_cells_per_step == 0:
    applied_hazard_steps = 0
else:
    applied_hazard_steps = min(hazard_steps, floor((eligible cells - clamped_base_hazards) / hazard_cells_per_step))
hazard_count = clamped_base_hazards + applied_hazard_steps * hazard_cells_per_step
```

The executable damage calculation caps before multiplication:

```text
if damage_per_cell_per_cycle == 0:
    damage_steps = 0
else:
    damage_steps = min(C - 1, floor((maximum_damage_per_cell - base_damage_per_cell) / damage_per_cell_per_cycle))
damage_per_cell = min(maximum_damage_per_cell, base_damage_per_cell + damage_steps * damage_per_cell_per_cycle)
```

Activated defaults are:

- `hazard_growth_interval_cycles = 2`;
- `hazard_cells_per_step = 1`;
- `damage_per_cell_per_cycle = 1.0`.

Revalidation tuned these values against Contract's 300 initial cash, 50 base operating cost, 100 delivery-fee default, 100 maximum shortfall penalty, 150 quota bonus, and repair-cost scale. They remain inspector-editable validated prototype balance values.

Scaling never inspects route, Warp positions, reachability, cash, debt, or contract choice. Hazard locations remain generated by the existing separate deterministic hazard RNG from the composed session seed. Count clamps only to the number of eligible cells; damage grows only to the configured finite maximum. Damage inputs are finite nonnegative doubles, progression uses only integer cycle steps, and the implementation computes `base + step * increment` only after capping the integer step against the finite maximum; it then applies `min(maximum, value)`. Tests compare the resulting finite numeric values exactly for the inspector defaults and at the cap.

Persistent cash uses a validated signed 64-bit range and may be negative. Principal, trust, rate, term, loan-ID sequence, cycle, and count values use validated nonnegative signed 64-bit ranges. Config validation reserves arithmetic headroom for every configured multiplication and interpolation. Runtime addition, subtraction, multiplication, and increment use checked operations and reject the initiating action with the canonical state observation value-unchanged. Recoverability compares the cash deficit against a remaining-credit sum capped at that deficit, so the sum itself cannot overflow. The formulas above cap hazard and damage steps before multiplication. A cycle increment or loan allocation that has exhausted its validated range is rejected with a detached technical-limit result; it is neither bankruptcy nor victory and never mutates the run. Operations remains open, the initiating control is disabled with the technical-limit reason, and other valid operations remain available. Boundary tests must exercise each policy.

Contract Economy must prove that authoritative trust is nonnegative. Credit still rejects negative trust as invalid input and never silently clamps it.

Credit Survival does not define the run-seed or event-log format. Playtest Ready owns reproducible run packaging and serialization.

## 11. Presentation and Mouse-Only Interaction

The operations screen retains the Contract Economy layout and adds one credit area:

- persistent cash, current cycle, projected fixed expense, and recovery status;
- six compact company rows in stable order;
- trust, trust required for the next integer credit-limit increase (or `CAP`), credit limit, outstanding principal, remaining credit, fixed rate, next scheduled principal, and next scheduled interest per row;
- one selected-company detail panel with active schedules;
- a mouse-only integer amount control with `-1`, `+1`, `-10`, `+10`, and `MAX` actions bounded to remaining credit;
- one `BORROW` button;
- one `DECLINE RECOVERY` button visible only in negative-cash recovery mode;
- disabled-state reasons that do not mutate domain state.

At all four supported window sizes, the company list may scroll inside its own panel, while persistent cash, recovery status, and primary actions remain visible. No keyboard gameplay input is required.

The next-limit query returns the smallest integer trust greater than the current value for which `H(trust)` exceeds the current integer limit, or `CAP` if none exists. The projected fixed expense for the next session's settlement separates base operating cost, scheduled principal, and scheduled interest. Repair cost is `UNKNOWN` before a session because route damage is contingent; the completed result shows the authoritative repair basis. The same fixed-cost projection must be visible before borrowing in operations and before final contract acceptance, using Contract-owned cost facts rather than presentation-side calculations.

## 12. Playtest Ready Observation Contract

Snapshots and terminal results expose detached data only:

- run seed reference if Contract/Playtest later provides it;
- current and completed cycle;
- cash before settlement, after settlement, after borrowing, and at terminal state;
- company trust, credit limit, principal, and remaining credit in stable order;
- active loans in canonical company order, then ascending loan ID within each company;
- each settlement's scheduled principal, interest, and total debt service;
- borrow events with company, amount, and resulting cash/principal;
- recovery state, deficit-capped comparison capacity, saturated aggregate remaining credit, and exact per-company remaining credit;
- difficulty values composed for each cycle;
- bankruptcy reason and exact terminal state;
- debt-service share numerator and settlement-income denominator as raw integers. The numerator is scheduled principal plus interest actually committed at that settlement. The denominator is delivery-fee total plus `max(contract cash adjustment, 0)`; it excludes starting cash, borrowed proceeds, and negative contract penalties. A zero denominator remains the raw value zero and no ratio is calculated by Credit Survival.

Credit Survival emits or exposes these facts through concrete observations. It does not write files or invent the final ordered event-log schema; Playtest Ready consumes them.

Canonical company order followed by ascending loan ID is the one total ordering for quotes, snapshots, events, settlement results, and UI schedules. Creation order across different companies never changes this ordering.

## 13. Balance and Validation

Credit-specific balance data is inspector-editable and validated before a run:

- exactly one credit balance for each Contract company ID;
- unique stable company IDs in Contract canonical order;
- at least two trust-limit knots, beginning at `(0, 0)`;
- strictly increasing trust coordinates and nondecreasing limits;
- rate basis points in `0..10_000`;
- term cycles in `1..1_000`;
- positive hazard-growth interval;
- nonnegative hazard-count increment;
- finite, nonnegative damage increment;
- finite `maximum_damage_per_cell` at least equal to the Risk base damage;
- overflow-safe maximum products and sums.

The activated prototype defaults use Contract's milli-trust scale and its 300 initial cash, 50 base operating cost, 100 base delivery fee, 100 maximum shortfall penalty, 150 completion bonus, and 100 milli-trust per excess delivery. Company defaults in canonical order are: `company_01` rate 400 bp, term 4, knots `(0,0),(100,100),(300,250),(600,500),(1000,800)`; `company_02` 500 bp, term 4, knots `(0,0),(100,100),(300,275),(600,550),(1000,850)`; `company_03` 600 bp, term 5, knots `(0,0),(100,125),(300,300),(600,575),(1000,900)`; `company_04` 700 bp, term 5, knots `(0,0),(100,125),(300,325),(600,625),(1000,950)`; `company_05` 800 bp, term 6, knots `(0,0),(100,150),(300,350),(600,675),(1000,1000)`; and `company_06` 900 bp, term 6, knots `(0,0),(100,150),(300,375),(600,725),(1000,1100)`. Difficulty defaults are one additional hazard cell every two cycles, one additional damage unit per cycle, and `maximum_damage_per_cell = 10.0`. All remain inspector-editable validated balance values.

## 14. Determinism and Required Scenarios

Automated coverage must prove at least:

1. trust zero yields zero credit and monotone knots never reduce a limit;
2. borrowing one unit and the exact maximum succeeds; zero, negative, overflow, and maximum-plus-one reject with canonical state value-unchanged;
3. positive-cash voluntary borrowing works;
4. repeated mouse frames create no duplicate loan;
5. six companies retain independent limits, principal, rates, and schedules;
6. equal-principal schedules place the indivisible remainder in the final installment;
7. interest uses the exact pre-repayment principal and ceiling basis-point rule;
8. quote creation is pure, stale quotes reject without consuming identity, and the complete settlement commits once;
9. trust gained and principal freed by settlement are immediately available afterward;
10. one company's proceeds can cover another company's later scheduled payment through shared cash;
11. negative cash blocks contract/session start and accepts arbitrary valid borrowing order;
12. insufficient aggregate credit causes one `CREDIT_EXHAUSTED` bankruptcy;
13. recoverable negative cash remains nonterminal until recovery or explicit decline;
14. rate edits after run creation affect neither existing nor newly created loans in that run;
15. pending cycles cancel without mutation and commit exactly once with contract acceptance;
16. numeric boundaries reject with canonical state value-unchanged, recoverability cannot overflow, hazard count clamps before growth, and damage remains finite;
17. reverse cross-company loan creation still produces the canonical company-then-loan-ID order everywhere;
18. cycle scaling changes only copied hazard count/damage and preserves Warp/hazard RNG rules;
19. fixed seeds and identical inputs produce identical canonical JSON observations for multi-cycle state and terminal bankruptcy;
20. presentation remains mouse-usable at `960x540`, `1280x720`, `1600x900`, and `1920x1080`;
21. all prior grid, train, Warp Cargo, Risk & Investment, and Contract Economy tests remain green.

## 15. Explicit Exclusions

- Save/load, cloud persistence, profiles, accounts, or campaign meta-progression.
- Voluntary early repayment, debt forgiveness, delinquency fees, variable rates, credit scores, collateral, guarantors, or shared global debt caps.
- Automatic borrowing or automatic refinancing.
- Trust spending or any trust effect other than the same company's credit limit.
- Permanent trains, office upgrades, multiple simultaneous contracts, or post-prototype purchases.
- Custom art, imported icons, custom fonts, audio, mobile, touch, controller, or keyboard gameplay controls.
- A generic ledger, transaction engine, repository, service locator, event bus, or production abstraction layer.

## 16. Completion Boundary

The dependency revalidation completes when the English design, English implementation plan, and Korean briefing are internally consistent, integrated into `main`, and receive independent specification and quality review. That document integration activates implementation.

The Credit Survival feature completes only after Contract Economy is integrated, the documents are revalidated and independently cleared, the implementation passes task-level RED/GREEN gates, full regression, the four-resolution Windows mouse gate, deterministic multi-cycle/bankruptcy checks, and final independent specification and quality review. A directly observed manual row is labeled `AGENT-VERIFIED`. When objective exact-commit automation, code review, and deterministic presentation checks pass but available tooling cannot perform a row, the user's approved `WAIVED_BY_USER_GATE_RELAXATION` terminal label satisfies that row's completion condition while explicitly recording that no observation occurred. `PENDING` never satisfies the gate, and neither label is reported as `USER PASS`.

After those gates pass, the agent is authorized to create focused commits, push the feature branch, open a `main` pull request, merge with a merge commit, synchronize and retest primary `main`, conditionally create the next milestone tag, and clean up only its own Credit branch/worktree without another approval pause. The milestone tag may be the annotated `prototype-m7` only after the primary integrated full and four-resolution gates pass, live verification proves Contract Economy is already the normally integrated `prototype-m6`, `prototype-m7` is unused locally and remotely, and the tag targets the Credit integration merge commit. Existing tags never move. If the milestone conditions are false, the tag is skipped and reported without failing the already verified feature; cleanup may still proceed after primary gates pass. A failed primary gate prohibits tag publication, Playtest Ready handoff, and cleanup. The final verified integration evidence is then sent once to the Playtest Ready task `01a052db-4df7-7041-bf08-226ef441a450` with an instruction to live-revalidate before implementation.
