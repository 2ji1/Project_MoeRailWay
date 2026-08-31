# Credit Survival Implementation Plan

**Date:** 2026-08-30

**Status:** Activation candidate; technical revalidation complete, Task 0 document-integration gate pending

**Canonical design:** `docs/superpowers/specs/2026-08-30-credit-survival-design.md`

**Verified Contract integration base:** `592072c1de535bcb5ce56c4a97f6515791bfe096`

**Target branch:** `feature/credit-survival`, created from the verified document-integration `main` after Task 0 passes

## 1. Execution Contract

This plan is bound to Contract Economy merge commit `592072c1de535bcb5ce56c4a97f6515791bfe096`. Its concrete owners, paths, settlement transaction, operations screen, and test fixtures were inspected directly. No temporary Contract API or fake `RunState` is permitted.

Every later implementation task requires:

1. deterministic RED evidence before minimum GREEN;
2. minimum GREEN within the exact allowlist;
3. focused and full regression gates with exit `0`, anchored PASS markers, and no anchored warning/error/fatal/crash markers;
4. exact-path staging and a focused commit after the task gates pass;
5. independent specification and quality review;
6. preservation of the clean primary `main` checkout.

After RED/GREEN, regressions, and exact staging pass, create the focused candidate commit. An independent review is then performed read-only by a separate reviewer agent or separate zero-context review session that did not author the change. Its report names that exact candidate commit and classifies findings as Critical, Important, or Minor. A gate clears only with no unresolved Critical or Important finding; accepted Minor findings remain recorded as residual risk. A correction receives a new focused follow-up commit and the affected review repeats against the new HEAD; task commits are never rewritten.

The user has authorized autonomous exact-path staging, focused commits, push, `main` PR, merge-commit integration, conditional milestone tagging, primary ff-only synchronization and verification, and cleanup of this feature's own branch/worktree after all applicable objective gates pass. This authority does not bypass the Contract dependency, tests, manual evidence labels, reviews, tag preconditions, or protected-worktree stop rules.

## 2. Task 0: Post-Contract Revalidation and Plan Activation

**Entry gate:** Contract Economy is merged into `main`; primary `D:\godot\MoeRailWay` is clean `main`, tracks `origin/main`, and has ahead/behind `0/0`; its exact-head automated evidence passes and every Contract-required manual row has a terminal label recognized by the Contract completion contract. `AGENT-VERIFIED` is accepted only when it was produced by direct observation under explicit authority; PENDING is never accepted, and no label is upgraded to `USER PASS`.

**Read-only preflight:** Inspect `AGENTS.md`, the merged Contract design/plan, its final implementation diff and tests, the current Risk design, this design, and this plan. Record actual owners and paths for:

- persistent run cash, cycle, and company trust;
- company definitions and stable ordering;
- settlement input, staged mutation, one-shot guard, and result;
- operations/contract/results presentation;
- session start composition and return to operations;
- Contract unit, integration, and four-resolution evidence.

**Required revision:** From the verified latest `main`, create a dedicated external `docs/credit-survival-revalidation` worktree. Replace every dependency token below with an exact existing path, reconcile constructor/method names and transaction ownership, set exact six-company rates/terms/trust-limit knots and `maximum_damage_per_cell` from Contract's trust, cash, repair, and damage scale, tune cycle-growth defaults against Contract fixtures, update every task allowlist, and remove any planned path that Contract already owns differently. Change both English documents from provisional/blocked to dependency-satisfied, update their verified base to the exact Contract integration HEAD, replace Section 12's blocked-state report with an activated-state record, and update the Korean briefing status and re-entry section to match.

**Refusal rules:** Stop without branch creation when primary is dirty/divergent, Contract evidence is incomplete, a dependency path is absent, settlement has more than one cash writer, manual evidence is unconfirmed, or the revised plan would need a fake adapter.

**Document-only allowlist during revalidation:**

- `docs/superpowers/specs/2026-08-30-credit-survival-design.md`
- `docs/superpowers/plans/2026-08-30-credit-survival.md`
- `docs/briefings/ko/2026-08-30-credit-survival-design-plan-briefing.md`

**Mechanical activation gate:** Every Create/Modify allowlist entry is an unconditional literal repository path. Every runner is bound to an exact command and anchored PASS marker. `rg -n '<CONTRACT_[A-Z_]+>' docs/superpowers/plans/2026-08-30-credit-survival.md` returns no match, and `rg -n -- '- `[^`]+`;' docs/superpowers/plans/2026-08-30-credit-survival.md` returns no malformed path bullet. Front matter identifies the activation-candidate state, both English verified-base fields equal the exact Contract integration HEAD, Section 12 records technical revalidation plus the pending document-integration gate, and the Korean status matches. The Contract integration runner is bound explicitly in Section 3.

**Document integration gate:** Independently specification-review and quality-review the three revised documents with no unresolved code issue, exact-stage only the document allowlist, commit it, push the document branch, merge its `main` PR with a merge commit, fast-forward primary `main`, and verify the integrated document blobs and primary cleanliness. Only after that verification, remove the document worktree and its local/remote branch. Report the exact Contract-driven changes in Korean. Then create a dedicated external `feature/credit-survival` worktree from that verified integrated `main` and proceed without another approval pause.

## 3. Revalidated Contract Bindings

- Persistent run state: `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- Company definition and order: `godot-project-moe-rail-way/src/config/company_contract_balance.gd` and `godot-project-moe-rail-way/src/config/contract_economy_balance.gd`
- Settlement owner: `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- Settlement result: `godot-project-moe-rail-way/src/domain/run/settlement_result.gd`
- Operations and contract-selection controller/composition root: `godot-project-moe-rail-way/src/app/prototype_app.gd`
- Operations and contract-selection view/scene: `godot-project-moe-rail-way/src/presentation/operations/operations_screen.gd` and `godot-project-moe-rail-way/src/presentation/operations/operations_screen.tscn`
- Result view/scene: `godot-project-moe-rail-way/src/presentation/results/contract_result_panel.gd` and `godot-project-moe-rail-way/src/presentation/results/contract_result_panel.tscn`
- Cost projection owner: `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- Contract unit tests: `godot-project-moe-rail-way/tests/unit/test_run_state.gd`, `godot-project-moe-rail-way/tests/unit/test_contract_session_controller.gd`, `godot-project-moe-rail-way/tests/unit/test_contract_economy_config.gd`, and `godot-project-moe-rail-way/tests/unit/test_contract_economy_presentation.gd`
- Contract integration runner: `godot-project-moe-rail-way/tests/integration/run_contract_economy_integration.gd`

The exact automated command root is:

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = '.\godot-project-moe-rail-way'
& $MoeRailGodot --headless --path $MoeRailProject --script 'res://tests/run_all.gd'
```

The registered runner must exit `0` and print anchored marker `PASS: <count> prototype test suite(s)`. Each integration uses the same command with one of these literal script paths: `res://tests/integration/run_session_shell_integration.gd`, `res://tests/integration/run_logical_track_field_integration.gd`, `res://tests/integration/run_track_train_input_integration.gd`, `res://tests/integration/run_track_train_app_integration.gd`, `res://tests/integration/run_warp_cargo_integration.gd`, `res://tests/integration/run_risk_investment_integration.gd`, `res://tests/integration/run_contract_economy_integration.gd`, and, after Task 6 creates it, `res://tests/integration/run_credit_survival_integration.gd`. Their exact anchored markers are respectively `PASS: session shell lifecycle integration`, `PASS: logical track field integration`, `PASS: track train input integration`, `PASS: track train app integration`, `PASS: warp cargo integration`, `PASS: risk investment integration`, `PASS: contract economy integration`, and `PASS: credit survival integration`.

A focused suite uses the registered runner plus `-- --suite=<literal test filename>`, for example `& $MoeRailGodot --headless --path $MoeRailProject --script 'res://tests/run_all.gd' -- --suite=test_credit_limit.gd`, and must exit `0` with anchored marker `PASS: 1 prototype test suite(s)`. The Credit integration itself sets and verifies `960x540`, `1280x720`, `1600x900`, and `1920x1080` viewports in one deterministic run; no external viewport argument is required. Anchored failure output is any line beginning with `ERROR:`, `WARNING:`, `SCRIPT ERROR:`, `FATAL:`, `CRASH:`, or `FAIL:`. Expected child-process invalid-input probes remain allowed only when the parent suite asserts their exact marker and exit behavior.

For every invocation, capture combined output in `$MoeRailOutput`, preserve `$MoeRailExit = $LASTEXITCODE`, require `$MoeRailExit -eq 0`, require exactly one line matching the runner's literal final PASS marker (the registered-runner pattern is `^PASS: [0-9]+ prototype test suite\(s\)$`), and reject any line matching `^(ERROR:|WARNING:|SCRIPT ERROR:|FATAL:|CRASH:|FAIL:)`. The exact task command matrix is:

- Task 1 focused suites: `test_credit_limit.gd`, `test_config_validator.gd`, `test_contract_economy_config.gd`, and `test_run_state.gd`; then the complete registered runner and all seven pre-Credit integrations listed above.
- Task 2 focused suites: `test_credit_system.gd`, `test_run_state.gd`, and `test_prototype_run_controller.gd`; then the complete registered runner and all seven pre-Credit integrations.
- Task 3 focused suites: `test_credit_settlement.gd`, `test_run_state.gd`, `test_contract_session_controller.gd`, and `test_prototype_run_controller.gd`; then the complete registered runner and all seven pre-Credit integrations.
- Task 4 focused suites: `test_cycle_progression.gd`, `test_hazard_system.gd`, `test_run_state.gd`, and `test_prototype_run_controller.gd`; then the complete registered runner and all seven pre-Credit integrations.
- Task 5 focused suites: `test_credit_survival_presentation.gd`, `test_contract_economy_presentation.gd`, `test_risk_investment_presentation.gd`, and `test_prototype_run_controller.gd`; then the complete registered runner and all seven pre-Credit integrations.
- Task 6 focused suites: `test_credit_limit.gd`, `test_credit_system.gd`, `test_credit_settlement.gd`, `test_cycle_progression.gd`, and `test_credit_survival_presentation.gd`; then the complete registered runner, all seven pre-Credit integrations, and `res://tests/integration/run_credit_survival_integration.gd`.

Each phrase “focused suites,” “registered full runner,” or “all integrations” later in this plan refers to this literal matrix and command contract, not to an open-ended search.

The copyable PowerShell gate wrapper and literal integration calls are:

```powershell
function Invoke-MoeRailGate {
    param([string]$Script, [string]$PassPattern, [string[]]$UserArgs = @())
    if ($UserArgs.Count -eq 0) {
        $MoeRailOutput = @(& $MoeRailGodot --headless --path $MoeRailProject --script $Script 2>&1)
    } else {
        $MoeRailOutput = @(& $MoeRailGodot --headless --path $MoeRailProject --script $Script -- @UserArgs 2>&1)
    }
    $MoeRailExit = $LASTEXITCODE
    $MoeRailLines = @($MoeRailOutput | ForEach-Object { $_.ToString() })
    if ($MoeRailExit -ne 0) { throw "Nonzero gate exit for $Script`: $MoeRailExit" }
    if (@($MoeRailLines | Where-Object { $_ -match $PassPattern }).Count -ne 1) { throw "Missing or duplicate final PASS for $Script" }
    if (@($MoeRailLines | Where-Object { $_ -match '^(ERROR:|WARNING:|SCRIPT ERROR:|FATAL:|CRASH:|FAIL:)' }).Count -ne 0) { throw "Forbidden marker for $Script" }
    $MoeRailLines
}

Invoke-MoeRailGate 'res://tests/run_all.gd' '^PASS: 1 prototype test suite\(s\)$' @('--suite=test_credit_limit.gd')
Invoke-MoeRailGate 'res://tests/run_all.gd' '^PASS: [0-9]+ prototype test suite\(s\)$'
Invoke-MoeRailGate 'res://tests/integration/run_session_shell_integration.gd' '^PASS: session shell lifecycle integration$'
Invoke-MoeRailGate 'res://tests/integration/run_logical_track_field_integration.gd' '^PASS: logical track field integration$'
Invoke-MoeRailGate 'res://tests/integration/run_track_train_input_integration.gd' '^PASS: track train input integration$'
Invoke-MoeRailGate 'res://tests/integration/run_track_train_app_integration.gd' '^PASS: track train app integration$'
Invoke-MoeRailGate 'res://tests/integration/run_warp_cargo_integration.gd' '^PASS: warp cargo integration$'
Invoke-MoeRailGate 'res://tests/integration/run_risk_investment_integration.gd' '^PASS: risk investment integration$'
Invoke-MoeRailGate 'res://tests/integration/run_contract_economy_integration.gd' '^PASS: contract economy integration$'
Invoke-MoeRailGate 'res://tests/integration/run_credit_survival_integration.gd' '^PASS: credit survival integration$'
```

For each additional focused filename in the task matrix, replace only the literal `--suite=test_credit_limit.gd` argument. Task 6 creates `godot-project-moe-rail-way/tools/credit_survival/verify_feature.ps1` with the literal union of every Credit Create/Modify path. The final executable structural gate is `pwsh -NoProfile -File .\godot-project-moe-rail-way\tools\credit_survival\verify_feature.ps1 -BaseCommit (git merge-base HEAD origin/main)`. That script must fail unless the feature diff is a subset of its literal allowlist, every planned Create path exists, every tracked `.gd` has exactly one tracked adjacent `.gd.uid` and vice versa, `git diff --check` passes, and `git diff --name-status --diff-filter=RD <base>...HEAD` is empty.

## 4. Anticipated Credit-Owned Paths

Task 0 may rename these only when the actual Contract structure requires it, and must revise all allowlists before implementation begins.

### Production

- `godot-project-moe-rail-way/src/config/company_credit_balance.gd`
- `godot-project-moe-rail-way/src/config/company_credit_balance.gd.uid`
- `godot-project-moe-rail-way/src/config/credit_survival_balance.gd`
- `godot-project-moe-rail-way/src/config/credit_survival_balance.gd.uid`
- `godot-project-moe-rail-way/src/domain/credit/loan_record.gd`
- `godot-project-moe-rail-way/src/domain/credit/loan_record.gd.uid`
- `godot-project-moe-rail-way/src/domain/credit/credit_quote.gd`
- `godot-project-moe-rail-way/src/domain/credit/credit_quote.gd.uid`
- `godot-project-moe-rail-way/src/domain/credit/credit_system.gd`
- `godot-project-moe-rail-way/src/domain/credit/credit_system.gd.uid`
- `godot-project-moe-rail-way/src/domain/run/cycle_progression.gd`
- `godot-project-moe-rail-way/src/domain/run/cycle_progression.gd.uid`
- `godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd`
- `godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd.uid`
- `godot-project-moe-rail-way/data/credit_survival_balance.tres`

### Tests

- `godot-project-moe-rail-way/tests/fixtures/credit_survival_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_credit_limit.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_limit.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_credit_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_system.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd`
- `godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd.uid`
- `godot-project-moe-rail-way/tests/integration/credit_survival_app.tscn`
- `godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd.uid`
- `godot-project-moe-rail-way/tests/manual/credit_survival_windows.md`
- `godot-project-moe-rail-way/tools/credit_survival/verify_feature.ps1`

## 5. Task 1: Add Validated Credit Balance and Limit Queries

**Objective:** Bind six Contract company IDs to deterministic trust-limit functions, fixed rates, and repayment terms without mutating run state.

**RED:** Register focused tests that prove exact Contract company coverage/order, `(0, 0)` first knot, minimum knot count, nonnegative knots, strict trust-coordinate order, nondecreasing limit order, floor piecewise-linear interpolation, cap behavior, trust zero, negative-trust rejection, next-integer-limit trust query/`CAP`, unknown/duplicate IDs, rate/term bounds, maximum `Vector2i` boundary safety for 64-bit interpolation, mandatory complete run-start company-rate copying, and unchanged Contract configuration on validation failure. Because both knot coordinates are nonnegative `Vector2i` values, their maximum delta product is `2147483647 * 2147483647`, which is representable by signed 64-bit Godot integers; an artificial overflow-rejection case is neither reachable nor required.

**Minimum GREEN:** Add concrete balance Resources and pure limit queries. Trust remains authoritative in `godot-project-moe-rail-way/src/domain/run/run_state.gd`. Do not add borrowing, loans, cash mutation, UI, or generalized curve/financial abstractions.

**Create allowlist:**

- `godot-project-moe-rail-way/src/config/company_credit_balance.gd`
- `godot-project-moe-rail-way/src/config/company_credit_balance.gd.uid`
- `godot-project-moe-rail-way/src/config/credit_survival_balance.gd`
- `godot-project-moe-rail-way/src/config/credit_survival_balance.gd.uid`
- `godot-project-moe-rail-way/data/credit_survival_balance.tres`
- `godot-project-moe-rail-way/tests/fixtures/credit_survival_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_credit_limit.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_limit.gd.uid`

**Modify allowlist:**

- `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/unit/test_run_state.gd`
- `godot-project-moe-rail-way/tests/unit/test_prototype_run_controller.gd`

**Regressions:** Focused limit/config suites, every existing configuration suite, registered full runner, and all existing integration runners.

**Focused commit after gates:** `feat: add trust based company credit limits`

**Independent review:** Specification review checks company independence, trust-only influence, exact arithmetic, and Contract ownership. Quality review checks overflow safety, validation clarity, and absence of speculative abstraction.

## 6. Task 2: Add Independent Loans and Atomic Borrowing

**Objective:** Create one deterministic equal-principal schedule per accepted operations-screen borrowing action and update shared cash atomically.

**RED:** Prove one-unit and exact-maximum borrowing, positive/zero/negative cash borrowing, zero/negative/overflow/maximum-plus-one rejection, multiple loans from one company, simultaneous companies, canonical company-then-loan-ID order, run-owned fixed rates for both existing and new loans after live balance edits, equal-principal remainder in the final installment, `P < N`, no-fail aggregate cash/Credit replacement, loan-ID exhaustion rejection, and value-identical canonical state observation on rejection. Held-frame edge ownership is presentation input behavior and is tested in Task 5.

**Minimum GREEN:** Add `LoanRecord` and `CreditSystem`. Stage one complete replacement containing new Credit state and the actual Contract persistent cash, validate it, then install it through the authoritative no-fail replacement boundary in one operations-controller call. Do not add settlement, automatic borrowing, early repayment, debt transfer, or a generic transaction engine.

**Create allowlist:**

- `godot-project-moe-rail-way/src/domain/credit/loan_record.gd`
- `godot-project-moe-rail-way/src/domain/credit/loan_record.gd.uid`
- `godot-project-moe-rail-way/src/domain/credit/credit_system.gd`
- `godot-project-moe-rail-way/src/domain/credit/credit_system.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_credit_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_system.gd.uid`

**Modify allowlist:**

- `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Regressions:** Focused credit/operations/cash suites, Contract settlement tests without debt, registered full runner, and all integrations.

**Focused commit after gates:** `feat: add independent company borrowing`

**Independent review:** Specification review checks operations-only borrowing, shared cash, company independence, no global cap, and schedule identity. Quality review checks staged commit atomicity and input-edge ownership.

## 7. Task 3: Integrate Debt Quotes and Automatic Settlement

**Objective:** Add pure debt-service quotes and one atomic Contract settlement commit using pre-repayment principal.

**RED:** Prove basis-point ceiling interest, zero rate, one-unit interest, equal-principal sequence including installment advancement when principal due is zero, quote purity, canonical company-then-loan-ID aggregation, first payment at the next settlement, run-owned copied rates, final retirement, full canonical order including durability restoration and temporary-investment cleanup, unchanged persistent/session/controller ownership, stale/wrong-cycle/revision quote rejection, reject-then-valid retry, injected pre-install failure at the final aggregate validator with every owner and identity unchanged, duplicate settlement rejection, no fallible cleanup or operations transition after `RunState.replace_with`, identity consumption only inside the complete commit, trust/limit update before following operations, immediately freed credit, and one company's borrowed cash covering another company's scheduled debt through shared cash. No failure is injected after the first install because that commit suffix is intentionally no-fail.

**Minimum GREEN:** Add immutable `CreditQuote` facts. Extend the actual Contract staged settlement so it validates Contract cash, trust, repair, operating, debt, and post-payment loan candidates before installing them once. Credit does not become a second cash writer. Do not alter delivery, quota, repair, or operating formulas.

**Create allowlist:**

- `godot-project-moe-rail-way/src/domain/credit/credit_quote.gd`
- `godot-project-moe-rail-way/src/domain/credit/credit_quote.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd.uid`

**Modify allowlist:**

- `godot-project-moe-rail-way/src/domain/credit/credit_system.gd`
- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- `godot-project-moe-rail-way/src/domain/run/settlement_result.gd`
- `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/unit/test_run_state.gd`
- `godot-project-moe-rail-way/tests/unit/test_contract_session_controller.gd`

**Regressions:** Focused credit-settlement suite, all Contract settlement/idempotence/cash tests, Risk result tests, registered full runner, and all integrations.

**Focused commit after gates:** `feat: settle scheduled principal and interest`

**Independent review:** Specification review checks canonical settlement order and immediately available trust/freed credit. Quality review checks purity, one-shot identity, integer overflow, and no observer between staged installs.

## 8. Task 4: Add Recovery, Cycles, Difficulty, and Bankruptcy

**Objective:** Complete the multi-cycle survival state machine without changing hazard RNG or session gameplay rules.

**RED:** Prove negative settlement cash remains in `RESULTS`; continue then enters recovery `OPERATIONS` or `TERMINAL` without an intermediate mutation; session/contract start blocking; arbitrary valid multi-company borrowing order; deficit-capped recovery comparison and saturated aggregate observation including exactly zero; automatic `CREDIT_EXHAUSTED`; explicit `RECOVERY_DECLINED`; staged terminal-result pre-assignment failure with reason/result/phase/identity/`RunState` unchanged; one-shot bankruptcy; nonnegative cash never bankrupting; exact terminal state; controller-derived pending next cycle without mutation; `selected_cycle` commit only with contract acceptance; pending discard on cancel/reentry; settlement-only completed-cycle increment; checked cycle exhaustion rejection; overflow-free hazard-count pre-clamp including zero increment; configured `maximum_damage_per_cell` validation and cap; copied config ownership; and identical canonical JSON observations from repeated multi-cycle runs.

**Minimum GREEN:** Add concrete `CycleProgression`. Extend the actual Contract run controller and composition root with deficit recovery, continuation, terminal reason, and copied Risk difficulty values. Reuse existing hazard generation and validator. Do not add run-seed/log serialization, automatic borrowing, or route-aware scaling.

**Create allowlist:**

- `godot-project-moe-rail-way/src/domain/run/cycle_progression.gd`
- `godot-project-moe-rail-way/src/domain/run/cycle_progression.gd.uid`
- `godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd`
- `godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd`
- `godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd.uid`

**Modify allowlist:**

- `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/domain/credit/credit_system.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/unit/test_prototype_run_controller.gd`

**Regressions:** Focused cycle/recovery/bankruptcy suites, Risk hazard/config tests, Contract loop tests, registered full runner, and all integrations.

**Focused commit after gates:** `feat: complete credit survival cycle`

**Independent review:** Specification review checks the overall game-loop order, no automatic borrowing, one-shot bankruptcy, and Risk RNG preservation. Quality review checks state-machine terminality and deterministic arithmetic.

## 9. Task 5: Present Operations Credit and Terminal Results

**Objective:** Make borrowing, schedules, recoverability, cycle pressure, and bankruptcy readable with mouse-only placeholder UI.

**RED:** Prove six stable company rows; selected-company schedules; persistent cash/cycle/recovery display; trust/next-limit-threshold-or-`CAP`/limit/principal/remaining/rate/next-principal/next-interest values; projected operating, debt-service, and knowable repair costs in operations and before contract acceptance; bounded `-1`, `+1`, `-10`, `+10`, `MAX`; first-edge one-borrow behavior; disabled reasons; positive-cash borrowing; negative-cash continuation block; conditional decline button; bankruptcy reason; nonintercepting overlays; and resize-safe mouse mapping.

**Minimum GREEN:** Extend the actual Contract operations/results views with primitive Controls and text bound only to detached observations. Retain the Contract screen hierarchy where possible. Do not add custom art, keyboard gameplay, a new UI framework, or presentation-side domain mutation.

**Create allowlist:**

- `godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd`
- `godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd.uid`

**Modify allowlist:**

- `godot-project-moe-rail-way/src/presentation/operations/operations_screen.gd`
- `godot-project-moe-rail-way/src/presentation/operations/operations_screen.tscn`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- `godot-project-moe-rail-way/src/domain/run/settlement_result.gd`
- `godot-project-moe-rail-way/src/presentation/results/contract_result_panel.gd`
- `godot-project-moe-rail-way/src/presentation/results/contract_result_panel.tscn`
- `godot-project-moe-rail-way/tests/run_all.gd`

**Regressions:** Focused presentation/input suites, all Contract layout/input/results tests, session-shell tests, registered full runner, and all integrations.

**Focused commit after gates:** `feat: present credit survival operations`

**Independent review:** Specification review checks every visible contract and mouse-only rule. Quality review checks layout behavior, input ownership, and domain/presentation separation.

## 10. Task 6: End-to-End Evidence and Playtest Observation Surface

**Objective:** Prove the complete repeatable loop and expose detached Credit facts for Playtest Ready.

**RED:** Register one deterministic integration that covers six companies, trust unlock, positive-cash borrowing, two-company schedules, shared-cash refinancing, settlement, freed credit, negative-cash recovery, several continued cycles, difficulty growth, and terminal bankruptcy. Assert a hard-coded expected multi-cycle trace independently calculated from the canonical formulas and fixtures; do not derive the oracle by calling production Credit calculations. Repeat the same seed/input script and compare canonical JSON state/event observations exactly as a secondary determinism check.

The independent arithmetic oracle fixes three separate scenarios before production code exists. Scenario A is an isolated debt-arithmetic fixture pre-seeded with cash 300, completed cycle 0, `company_06` trust 100/limit 150, and `company_01` trust 100/limit 100; the full-loop portion separately proves gameplay-earned trust unlock. Scenario A accepts reverse creation order `company_06` principal 60 at 900 bp/term 6 then `company_01` principal 40 at 400 bp/term 4, and reaches post-borrow cash 400. Cycle 1 starts with cash 400, delivery fees 0, and session spending 100, so settlement opening cash is 300; contract adjustment 50, repair 50, and operating 50 produce pre-debt cash 250. Canonical quote order is `company_01` loan ID 2 then `company_06` loan ID 1; payments are `(principal 10, interest 2)` and `(principal 10, interest 6)`, yielding closing cash 222 and principals 30/50. Cycle 2 starts with cash 222, delivery fees 0, and session spending 62, so opening cash is 160; contract adjustment 40, repair 50, and operating 50 produce pre-debt cash 100; payments are 12 and 15, yielding closing cash 73 and principals 20/40. Scenario B starts from a fixture with completed cycle 2, cash `-30`, `company_02` trust 100 and no debt, giving limit/remaining credit 100; borrowing 30 produces cash 0, principal 30, and first due cycle 3. Scenario C starts from completed cycle 2, cash `-11`, trust 100 for every company, and active principals equal to the six trust-100 limits: `100,100,125,125,150,150`. Every remaining credit is therefore zero; continue from `RESULTS` produces comparison capacity 0, saturated aggregate 0, and one `CREDIT_EXHAUSTED` terminal transition. Expected values may not be copied from production output.

**Minimum GREEN:** Compose the real Contract scene with the revalidated Credit systems and balance fixture. Extend detached run/settlement results with cycle, per-company credit/debt, due/paid debt service, borrow/recovery facts, difficulty values, bankruptcy reason, and raw debt-service-share terms. Do not write logs; Playtest Ready owns serialization.

**Create allowlist:**

- `godot-project-moe-rail-way/tests/integration/credit_survival_app.tscn`
- `godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd.uid`
- `godot-project-moe-rail-way/tests/manual/credit_survival_windows.md`
- `godot-project-moe-rail-way/tools/credit_survival/verify_feature.ps1`

**Modify allowlist:**

- `godot-project-moe-rail-way/src/domain/run/settlement_result.gd`
- `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- `godot-project-moe-rail-way/tests/integration/run_contract_economy_integration.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/integration/contract_economy_app.tscn`

**Automated final gate:**

1. focused Credit unit suites;
2. registered complete suite runner;
3. every pre-existing standalone integration runner;
4. exact `PASS: credit survival integration` at all four window sizes;
5. a hard-coded independently calculated expected multi-cycle trace, including cross-company reverse creation order, plus two identical runs with equal canonical JSON observations;
6. UID parity for every GDScript;
7. exact feature allowlist with zero outside paths;
8. rename/delete audit;
9. `git diff --check`;
10. exit `0` and no anchored warning/error/fatal/script-error/crash output.

**Windows mouse-only gate:** First create the Task 6 implementation commit without terminal evidence rows. On that exact implementation commit, verify at `960x540`, `1280x720`, `1600x900`, and `1920x1080`:

- all six companies and selected-company detail are reachable;
- credit figures and next payment remain readable;
- amount controls, `MAX`, and `BORROW` work without keyboard input;
- a held click does not duplicate borrowing;
- positive-cash voluntary borrowing works;
- deficit mode blocks continuation and permits recovery;
- insufficient credit and explicit decline show distinct bankruptcy results;
- cycle and difficulty observations update once;
- prior contract, Warp, track, hazard, purchase, and result interactions remain usable.

Directly observed rows are recorded as `AGENT-VERIFIED`, never `USER PASS`. If objective exact-commit automation, code review, and deterministic presentation checks pass but the available tooling cannot directly perform a manual row, record that row as `WAIVED_BY_USER_GATE_RELAXATION` with the exact tooling limitation. Under the user's approved gate relaxation, that terminal label satisfies the manual completion condition for merge, tag, handoff, and cleanup; it is not evidence that the interaction was observed. PENDING remains a blocker and automated evidence alone never becomes `USER PASS`.

Record the terminal manual labels in `godot-project-moe-rail-way/tests/manual/credit_survival_windows.md` and create a separate evidence-only commit `test: record credit survival windows evidence`. Rerun the complete automated, UID, diff, and allowlist gates on that evidence commit. Because the second commit changes only the evidence Markdown, each manual row still names the exact implementation commit it observed or waived, while the final feature HEAD is non-circular and fully reviewable.

The evidence-only commit has one literal Modify allowlist entry: `godot-project-moe-rail-way/tests/manual/credit_survival_windows.md`. Its staging rule is `staged paths == evidence allowlist`; the Task 6 Create-path requirement applies only to the preceding implementation commit. Every waived row records both the tooling limitation and authority text `Credit Survival execution delegation, user message dated 2026-08-31`.

**Task 6 implementation commit:** `test: prove credit survival loop`

**Final independent reviews:** After the evidence commit and repeated automated gates, specification review checks the exact final feature HEAD, complete canonical contract, terminal manual labels, and deferrals. Quality review checks the exact final feature diff, deterministic evidence, exact allowlist, test quality, and residual risks. If either review requires a code or scene correction, create a focused allowlisted follow-up implementation commit, rerun all automated/structural gates, repeat every manual row affected by that correction against the new implementation HEAD, update the evidence Markdown, create a new evidence-only commit, and repeat both final reviews. No prior manual label is carried forward to changed behavior without an explicit unaffected determination recorded in the evidence file.

## 11. Exact-Path Staging Guard

Before every future task commit:

1. confirm branch, HEAD, base, upstream, worktree ownership, primary cleanliness, and ahead/behind;
2. capture the task's Create/Modify allowlist from the revalidated plan;
3. prove no staged path exists before exact staging;
4. stage only explicit literal paths with `git add -- <path...>`;
5. for a task's first implementation commit, require every staged path to be a member of the task allowlist, require every Create path for that task to be staged, and permit an allowed Modify path to remain unchanged; formally `staged paths subset_of allowlist` and `Create paths subset_of staged paths`. For a review-fix follow-up commit, require only `staged paths subset_of the same task allowlist`; already committed Create paths are not staged again;
6. run `git diff --cached --check` and UID audit;
7. record staged paths and verification results in the Korean progress report;
8. create the focused candidate commit after RED/GREEN, regression, staging, diff, and UID gates pass, then run independent reviews against that exact commit;
9. verify the post-commit tree;
10. continue to the next planned task, while deferring push until the final feature gate.

No glob staging, `git add .`, stash, reset, rebase, primary copy, or cleanup is allowed.

## 12. Plan Activation Record

`REVALIDATION: COMPLETE; IMPLEMENTATION: ACTIVATES ON DOCUMENT MERGE`. Contract Economy is integrated at `592072c1de535bcb5ce56c4a97f6515791bfe096`, `prototype-m6` peels to that commit, the protected primary checkout was clean and synchronized, concrete Contract paths replaced every dependency token, and no compatibility adapter is required. Task 0 itself completes only after the three documents merge through their document-only PR, primary `main` verifies those blobs, and `feature/credit-survival` is created from that verified document-integration commit.

## 13. Authorized Integration, Milestone, and Handoff

After the final implementation commit and final independent reviews pass:

1. fetch and prove the feature base, primary `main`, and `origin/main` relationships again;
2. push only `feature/credit-survival`;
3. open a pull request targeting `main` with exact commits, tests, manual evidence labels, allowlist/UID/diff results, and residual risks;
4. merge with a merge commit only after all objective checks are green;
5. verify the remote merge commit and that its tree contains the reviewed feature tree;
6. fast-forward primary `main` only, then run the complete integrated test and four-resolution deterministic gate on the integration HEAD;
7. if any primary integration or direct-observation gate fails, prohibit tag publication, Playtest Ready handoff, and cleanup;
8. after primary gates pass, inspect local and remote tags plus Contract Economy integration evidence;
9. create and push annotated `prototype-m7` only when `prototype-m6` is the normally integrated Contract milestone and `prototype-m7` is unused everywhere; never move an existing tag. If those conditions are false, skip and report the tag without treating it as feature failure;
10. do not convert agent mouse observations into `USER PASS`; record them as `AGENT-VERIFIED` unless the user directly confirms the row;
11. only after the primary integration gate passes and any eligible tag publication either succeeds or is explicitly skipped as ineligible, remove this feature's own worktree and local/remote branch;
12. send one follow-up to Playtest Ready task `01a052db-4df7-7041-bf08-226ef441a450` containing final main SHA, PR, tag, test evidence, manual evidence labels, and an instruction to live-revalidate before implementation.

Any dirty/divergent protected checkout, tag collision, failed check, warning/error marker, unresolved review finding, or Contract mismatch stops the affected transition without stash, reset, deletion, evidence relaxation, or false completion reporting.
