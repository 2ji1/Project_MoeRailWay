# Contract Economy Implementation Plan

**Date:** 2026-08-30

**Status:** Authorized for autonomous execution through verified merge, `prototype-m6` publication, primary retest, and feature-only cleanup

**Target branch:** `feature/contract-economy`

**Integration base:** `dd9d1d04a126c23a1b3c420cde67711e6e4738dc`

**Canonical design:** `docs/superpowers/specs/2026-08-30-contract-economy-design.md`

## 1. Execution Contract

Implement the approved Contract Economy slice as six sequential gameplay tasks after this documentation gate. Work only in the dedicated external worktree. Preserve the primary `main` checkout and every unrelated worktree.

Each gameplay task follows this exact sequence:

1. revalidate branch, base, primary cleanliness, index emptiness, and the literal task allowlist;
2. add deterministic failing assertions and capture the anchored RED evidence;
3. implement only the minimum GREEN inside the allowlist;
4. run the focused suite, registered suite runner, and required standalone integrations;
5. run the task's pre-commit specification and quality review against the task diff;
6. stage only exact paths after every task-local pre-commit objective gate passes and inspect the cached diff;
7. create the focused task commit.

Task 6's four-resolution Windows evidence is intentionally a post-commit publication gate. Its automated RED/GREEN, regressions, pre-commit reviews, exact staging, and focused commit run first. The mouse checks then run from that clean exact commit, after which final specification and quality reviews evaluate both the committed feature and the external evidence. This is the only task-specific ordering exception; failed or ambiguous post-commit evidence blocks push and integration rather than causing evidence to name an uncommitted state.

No gameplay task begins before the documentation paths pass their review and validation gate. The user's feature-specific authority permits autonomous exact-path commits, push, PR creation, merge-commit integration, the next unused milestone tag, primary fast-forward/retest, and feature-only cleanup after their corresponding objective gates pass.

## 2. Preconditions and Stop Rules

Before every task require:

- primary `D:\godot\MoeRailWay` is clean `main` tracking the exact remote `main` expected by the task;
- feature worktree is clean except for the current task's approved paths;
- feature branch ancestry is the expected focused commit chain from `dd9d1d0`;
- no staged paths exist before exact-path staging;
- no unrelated branch or worktree is copied, reset, stashed, formatted, deleted, or absorbed;
- Godot is `4.7.1.stable.official.a13da4feb` from the approved executable;
- the task changes no path outside its literal allowlist.

Stop with evidence on any mismatch. Do not repair a protected workspace automatically.

## 3. Documentation Gate

### Objective

Approve the English design, this implementation plan, and the Korean user briefing before gameplay edits.

### Literal allowlist

Create only:

- `docs/superpowers/specs/2026-08-30-contract-economy-design.md`
- `docs/superpowers/plans/2026-08-30-contract-economy.md`
- `docs/briefings/ko/2026-08-30-contract-economy-design-plan-briefing.md`

### Validation

- English canonical files contain no Korean text.
- The Korean briefing names and links both English canonical documents.
- Design and plan agree on formulas, ownership, settlement order, deferrals, and Credit Survival outputs.
- Every gameplay task has RED, minimum GREEN, regressions, a literal allowlist, focused commit message, and review criteria.
- `git diff --check` passes and only the three documentation paths are changed.

### Proposed focused commit

`docs: approve contract economy design and plan`

After the documentation paths pass validation and review, exact-path stage them, inspect the cached diff, and create the proposed focused commit.

## 4. Task 1: Add Validated Company and Run Balances

### Objective

Introduce Inspector-editable six-company contract data and one concrete in-memory RunState with initial cash `300`, fixed-point trust, and cycle count.

### RED

Register failing assertions for exact defaults, six unique IDs, invalid counts, duplicate IDs, null nested Resources, invalid strings, invalid weights/quotas/cash/trust bounds, overflow candidates, stable observation order, signed settlement cash, nonnegative session-start authority, trust isolation, duplicate/replace behavior, removal of the former session-cash Inspector authority, and `ContractEconomyBalance.initial_run_cash` as the sole real-composition initial-cash tuning source.

### Minimum GREEN

Create concrete `CompanyContractBalance`, `ContractEconomyBalance`, and `RunState`. Add the nested balance to `PrototypeBalance` and its validator. Retire the `PrototypeBalance.session_cash_balance` export, validator branch, and `.tres` subresource so `initial_run_cash` is the only real-composition initial-cash Inspector source. Keep `SessionStartConfig.starting_session_cash` only as a detached value that Task 4 will fill from current RunState. Keep all six entries separately editable in the Inspector. Do not add contract calculation, company RNG, presentation, persistence, debt, or a generic state store.

### Literal allowlist

Create:

- `godot-project-moe-rail-way/src/config/company_contract_balance.gd`
- `godot-project-moe-rail-way/src/config/company_contract_balance.gd.uid`
- `godot-project-moe-rail-way/src/config/contract_economy_balance.gd`
- `godot-project-moe-rail-way/src/config/contract_economy_balance.gd.uid`
- `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- `godot-project-moe-rail-way/src/domain/run/run_state.gd.uid`
- `godot-project-moe-rail-way/data/contract_economy_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_contract_economy_config.gd`
- `godot-project-moe-rail-way/tests/unit/test_contract_economy_config.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_run_state.gd`
- `godot-project-moe-rail-way/tests/unit/test_run_state.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/tests/fixtures/risk_investment_balance.tres`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_economy.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

### Regressions and reviews

Run the two focused suites, configuration suites, the full registered runner, and every existing standalone integration. Specification review checks exact six-entry validation, sole initial-cash Inspector ownership, and removal of the renewable session allowance from real composition. Quality review checks integer bounds, copied observations, concrete ownership, and absence of persistence/generalized frameworks.

### Focused commit

`feat: add contract economy run balances`

## 5. Task 2: Assign Companies and Preserve Cargo Identity

### Objective

Assign one deterministic company to every Warp pair without changing approved Warp location/lifetime RNG, and carry that identity through cargo lifecycle.

### RED

Prove the independent XOR-salted company stream, stable weighted selection, same-seed identity, different approved seed variation, unchanged old Warp spatial/lifetime trace, no contract bias, forecast-to-terminal company-and-fee identity, full-slot retry identity, load/delivery/expiry/void identity, company-fee accumulation through the compatibility alias, and real-application nonuse of the legacy global reward.

### Minimum GREEN

Extend pair and cargo records with one validated company ID and copied company-specific fee. Pass the six stable company definitions into `WarpPairSystem` through completed session configuration and use a separate `SessionRng`. Make `CargoSystem` accumulate the delivered cargo fee as both `delivery_fee_total` and the legacy observation alias. Keep the old global reward only as an explicit fallback for direct pre-Contract fixtures; the real application path must not read it. Extend cargo delivery facts with company identity and fee. Do not credit `SessionEconomy`, count contracts, select a contract, reroll, or add presentation.

### Literal allowlist

Modify:

- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/src/config/cargo_balance.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_record.gd`
- `godot-project-moe-rail-way/src/domain/warp/warp_pair_system.gd`
- `godot-project-moe-rail-way/src/domain/cargo/cargo_slot_record.gd`
- `godot-project-moe-rail-way/src/domain/cargo/cargo_system.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_pair_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_cargo_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_config_validator.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_investment_purchases.gd`
- `godot-project-moe-rail-way/tests/unit/test_risk_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_session_controller.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`

### Regressions and reviews

Run focused Warp/Cargo/config suites, all Warp controller and presentation suites, the registered runner, and all integrations. Compare the old fixed-seed Warp spatial/lifetime trace byte-for-byte. Specification review checks immutable uncertainty and company identity. Quality review checks RNG isolation, weighted integer selection, and no duplicated company data ownership.

### Focused commit

`feat: assign companies to warp cargo`

## 6. Task 3: Add Contract Counting and Immediate Delivery Fees

### Objective

Select one contract, count only matching-company deliveries, and credit every company's fee to the live session cash exactly once.

### RED

Cover selection validation, immutable quota, contracted versus uncontracted deliveries, immediate spendable fees, repeated-contact no-op, compatibility reward-total aliasing without double credit, zero/partial/exact/over-quota attainment, exact signed cash-curve rounding, fixed-point excess trust facts, early-end counts, and canonical byte-unchanged rejection.

### Minimum GREEN

Create one concrete `ContractSystem`. Extend `SessionEconomy` with checked credit. Pass detached company delivery facts through the existing session controller order. Add selected contract and delivery observations to session snapshot/result. Calculate but do not yet apply persistent settlement. Do not add operations/results UI, RunState mutation, loans, or generic transactions.

### Literal allowlist

Create:

- `godot-project-moe-rail-way/src/domain/contract/contract_system.gd`
- `godot-project-moe-rail-way/src/domain/contract/contract_system.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_contract_system.gd`
- `godot-project-moe-rail-way/tests/unit/test_contract_system.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_contract_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_contract_session_controller.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/domain/economy/session_economy.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_economy.gd`
- `godot-project-moe-rail-way/tests/unit/test_warp_cargo_session_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_risk_session_controller.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

### Regressions and reviews

Run the two new focused suites, economy/Cargo/Warp/Risk controller suites, the registered runner, and every integration. Specification review checks selected-only attainment and all-company fees. Quality review checks exact-once credit, fixed-point arithmetic, compatibility aliases, and presentation independence.

### Focused commit

`feat: resolve contract deliveries and fees`

## 7. Task 4: Settle One Persistent Run Cycle

### Objective

Move final session cash into RunState and apply contract adjustment, trust, repair, and operating cost once in canonical order.

### RED

Cover all three end reasons, exact order and line items, negative closing cash, no floor or skipped cost, full-durability next-session basis, cycle increment once, temporary-upgrade removal, repeated settlement rejection with byte-identical state, checked candidate install, result immutability, nonnegative start gate, and detached Credit Survival observations.

### Minimum GREEN

Create one concrete `PrototypeRunController` that owns phases and builds a complete validated RunState/settlement candidate before replacing live state. Initialize `SessionEconomy` from current RunState cash. Keep debt, credit, borrowing, bankruptcy, saving, and generalized settlement pipelines absent.

### Literal allowlist

Create:

- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd`
- `godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd.uid`
- `godot-project-moe-rail-way/src/domain/run/settlement_result.gd`
- `godot-project-moe-rail-way/src/domain/run/settlement_result.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_prototype_run_controller.gd`
- `godot-project-moe-rail-way/tests/unit/test_prototype_run_controller.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/domain/run/run_state.gd`
- `godot-project-moe-rail-way/src/domain/contract/contract_system.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/tests/unit/test_contract_system.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

### Regressions and reviews

Run run/contract/session/Risk focused suites, the registered runner, and every integration. Specification review checks order, one-shot settlement, negative-cash boundary, and Credit deferral. Quality review checks candidate atomicity, overflow handling, state ownership, and absence of hidden phase mutations.

### Focused commit

`feat: settle persistent contract cycles`

## 8. Task 5: Present Operations, Session Contract, and Results

### Objective

Make selection, contract progress, fees, trust, ordered settlement, and phase transitions readable with mouse-only placeholder UI.

### RED

Require six stable company rows, selected state, start gating, current cash/trust/cycle, session company markers, selected-company quota/attainment, all-company fee total, distinct session-starting and settlement-opening cash, non-additive fee/spending reconciliation rows, exact result line order, negative-cash blocking text, one continue edge, nonintercepting map overlays, input arbitration, and resize-safe layout.

### Minimum GREEN

Create ordinary Control scenes for operations and results. Extend existing shell/cargo/Warp presentation with primitive company markers and detached snapshot bindings. Preserve map dominance and Inspector layout metrics. Presentation sends explicit selection/start/continue commands and never mutates domain state.

### Literal allowlist

Create:

- `godot-project-moe-rail-way/src/presentation/operations/operations_screen.gd`
- `godot-project-moe-rail-way/src/presentation/operations/operations_screen.gd.uid`
- `godot-project-moe-rail-way/src/presentation/operations/operations_screen.tscn`
- `godot-project-moe-rail-way/src/presentation/results/contract_result_panel.gd`
- `godot-project-moe-rail-way/src/presentation/results/contract_result_panel.gd.uid`
- `godot-project-moe-rail-way/src/presentation/results/contract_result_panel.tscn`
- `godot-project-moe-rail-way/tests/unit/test_contract_economy_presentation.gd`
- `godot-project-moe-rail-way/tests/unit/test_contract_economy_presentation.gd.uid`

Modify:

- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.tscn`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- `godot-project-moe-rail-way/src/presentation/cargo/cargo_slot_strip.gd`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- `godot-project-moe-rail-way/src/presentation/theme/prototype_theme.tres`
- `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`
- `godot-project-moe-rail-way/tests/run_all.gd`

### Regressions and reviews

Run the focused presentation suite, app composition, all existing presentation/input suites, the registered runner, and every integration. Specification review checks every visible contract and phase. Quality review checks mouse mapping, signal lifetime, layout scaling, domain separation, and absence of custom assets.

### Focused commit

`feat: present contract economy cycle`

## 9. Task 6: Add End-to-End and Windows Evidence

### Objective

Prove a deterministic real-scene cycle from operations selection through mixed-company delivery and ordered settlement back to operations.

### RED

Register the new integration runner before production wiring is complete. Require a hard-coded fixed-seed trace containing contracted and uncontracted deliveries, an in-session purchase funded by immediate fees, over-attainment trust, one early or regular end, exact settlement lines, persistent closing state, and return to operations. Require repeated-run byte identity.

### Minimum GREEN

Add one deterministic fixture, scene, runner, and manual checklist. Update existing integrations only for required constructor/observation changes. Do not weaken prior expectations or turn manual rows into automation.

### Literal allowlist

Create:

- `godot-project-moe-rail-way/tests/fixtures/contract_economy_balance.tres`
- `godot-project-moe-rail-way/tests/integration/contract_economy_app.tscn`
- `godot-project-moe-rail-way/tests/integration/run_contract_economy_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_contract_economy_integration.gd.uid`
- `godot-project-moe-rail-way/tests/manual/contract_economy_windows.md`

Modify:

- `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_warp_cargo_integration.gd`
- `godot-project-moe-rail-way/tests/integration/run_risk_investment_integration.gd`

### Post-commit four-resolution Windows gate

After creating the Task 6 focused commit, require a clean feature worktree and run deterministic and mouse-only checks on that exact commit at `960x540`, `1280x720`, `1600x900`, and `1920x1080`. Verify:

- all six company rows and contract details remain readable;
- selection and start work with mouse only;
- company markers remain distinct from pair color/shape;
- contracted and uncontracted deliveries visibly produce the correct fee/attainment behavior;
- purchases can use newly earned fees without a frame-order error;
- result line items and closing cash match the deterministic companion trace;
- trust changes only for over-attainment;
- continue returns to operations once;
- negative cash blocks start without showing false bankruptcy;
- HUD, result, and operations Controls never corrupt field mapping or retain hidden clicks.

Store exact commit, Godot version, seed, resolution, tester, observations, and screenshots outside the repository. Direct agent-driven rows use `AGENT-VERIFIED`, never `USER PASS`; any ambiguous row remains `PENDING` and blocks publication.

### Pre-commit regressions and reviews

Run the new integration twice and compare canonical traces; run the registered suite runner and all standalone integrations. Pre-commit specification review checks the complete design and Credit boundary. Pre-commit quality review checks real-scene composition, cleanup, deterministic fixtures, and UI lifetime. After the focused commit and four-resolution gate, final independent reviews additionally check the exact committed state and evidence truthfulness before publication.

### Focused commit

`test: verify contract economy cycle`

## 10. Exact-Path Staging Guard

For every task, construct an array containing exactly that task's literal changed paths. Require an empty index, reject renames/deletions, compare all changed/untracked paths against the task allowlist, stage with `git add -- <exact paths>`, compare cached paths against expected changed allowlist paths, then run and inspect:

```powershell
git diff --cached --check
git diff --cached --stat
git diff --cached
```

No glob staging, `git add .`, formatting sweep, unrelated documentation amendment, rename, or deletion is authorized.

## 11. Automated Final Gate

The exact final feature state must provide:

1. clean expected branch and primary/remote alignment;
2. feature diff contained in the union of approved task allowlists;
3. `git diff --check` PASS over the feature range;
4. exactly one tracked `.gd.uid` per tracked GDScript and no orphan sidecar;
5. the registered unit/smoke runner with its exact current PASS count;
6. every pre-existing standalone integration with one exact PASS marker;
7. the new Contract Economy integration with one exact PASS marker;
8. repeated fixed-seed canonical traces that are byte-identical;
9. four-resolution deterministic checks;
10. no anchored warning, error, fatal, script-error, or crash output;
11. final independent specification and quality approval;
12. direct mouse-only evidence labeled `AGENT-VERIFIED` and kept distinct from automation.

## 12. Main-First Transition

After every local feature gate passes, push the feature branch, open a PR targeting `main`, and merge with a merge commit only. Fast-forward primary `main` with `--ff-only` and rerun the complete merged-main gate on the exact merge commit. Only after that gate passes, confirm `prototype-m6` is unused locally and remotely, create one annotated tag on the verified integration commit, push that exact tag, and verify that the remote annotated tag peels to the same commit; never move or replace an existing tag. Then remove only this feature's worktree and local/remote branch.

If primary becomes dirty, remote `main` advances, ancestry changes, or an evidence row is incomplete, stop without stash, reset, rebase, force push, or cleanup.

## 13. Explicit Deferrals

- Credit limits, debt, borrowing, interest, repayment, refinancing, deficit recovery, and bankruptcy.
- Cycle difficulty scaling and hazard regeneration.
- Disk persistence and save migration.
- Multiple selected contracts.
- Permanent assets and upgrades.
- Playtest-ready logging/export work.
- Custom art/audio, mobile input, and production abstraction.
