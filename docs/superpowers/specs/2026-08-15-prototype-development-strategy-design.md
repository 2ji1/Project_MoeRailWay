# Prototype Development Strategy Design

- Date: 2026-08-15
- Status: Approved
- Audience: Agent-facing canonical specification
- Related gameplay specification: docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md
- User briefing: docs/briefings/ko/2026-08-15-prototype-development-strategy-briefing.md

## 1. Outcome

Build a Windows PC prototype that repeatedly runs the complete company loop:

1. Inspect operations and debt.
2. Select one company contract.
3. Operate one top-down 2D warp session.
4. Settle contract, repair, operating, principal, and interest costs.
5. Recover a deficit through borrowing when possible.
6. Continue to another cycle or end in bankruptcy.

The prototype validates continuous track pressure, contract-driven cargo choice, and temporary investment versus cash preservation. It does not establish the production codebase.

## 2. Fixed Constraints

- Platform: Windows PC
- Presentation baseline: 16:9
- Input: mouse only
- View: top-down orthographic 2D inspired by Mini Metro
- Session layout: map-dominant field with thin top- and bottom-anchored HUD bands
- Mobile, touch, gamepad, and responsive mobile layout: full-production scope
- Active train count: exactly one
- Production branch Development remains isolated
- Prototype integration branch: Prototyping
- Prototype delivery model: sequential vertical slices
- Prototype art: primitives, colors, default fonts, and replaceable placeholder audio only

## 3. Branch Topology

Create Prototyping from the current main baseline. Do not create it from Development even when both names currently resolve to the same commit.

Use this ownership model:

- main: shared documentation and stable repository baseline
- Development: later full-production integration
- Prototyping: prototype integration and playable milestone history
- proto/*: short-lived prototype feature branches created from the latest Prototyping

Never merge Prototyping into Development. Prototype completion produces validated evidence and production requirements rather than a production merge.

## 4. Delivery Strategy

Use sequential vertical slices. Each feature branch starts only after its predecessor is merged into Prototyping. Every merge must leave Prototyping executable and playable through all previously accepted behavior.

This strategy is preferred over subsystem-parallel branches because Godot scenes, the central session controller, event ordering, and shared state would otherwise create high integration risk. It is preferred over a single demo branch because settlement and credit rules require testable ownership boundaries from the beginning.

UI grows inside the feature that needs it. Do not maintain a long-lived UI branch. This prevents scene conflicts and ensures every rule arrives with readable feedback.

## 5. Runtime Architecture

### 5.1 Domain and Presentation Separation

Game rules live in testable GDScript models and calculators. Godot Node2D, Line2D, Control, Container, and CanvasLayer nodes handle input and presentation only.

Use these conceptual units:

- RunState: cash, cycle count, company trust, and company debt during a run
- SessionStartConfig: immutable composed inputs for one session
- SessionController: fixed-tick orchestration and event ordering
- TrackSystem and TrainSystem: route inventory, recovery, movement, and track-end failure
- WarpPairSystem and CargoSystem: request lifecycle and automatic cargo transitions
- RiskSystem: deterministic distance-based hazard damage
- ContractSystem: contracted deliveries, attainment, cash result, and trust
- EconomySystem: sole writer of cash, purchases, and ordered settlement
- CreditSystem: limits, borrowing, schedules, interest, and principal
- Presentation: field, HUD, operations, results, warnings, and previews

Do not use a global event bus. A composition controller wires explicit dependencies and receives explicit commands and domain events.

### 5.2 Fixed-Tick Data Flow

Each physics tick uses this order:

1. Accept sampled mouse input as track commands.
2. Advance the train and record track-end requests.
3. Resolve swept origin and destination pass-through.
4. Resolve deterministic hazard damage.
5. Resolve warp expiry.
6. Resolve session-time expiry.
7. Prioritize all end requests.
8. Execute settlement at most once.
9. Publish a read-only presentation snapshot.

Presentation observes state and never writes cash, trust, debt, or contract delivery counts directly.

### 5.3 Determinism

- One explicit session seed owns all random generation.
- Generated warp results are fixed before forecast presentation.
- Ordered domain events are recorded for replay and diagnosis.
- Tests compare important state and event sequences under fixed seeds.
- Godot physics-signal callback order is not a source of game-rule truth.

### 5.4 Extension Boundary

The prototype implements only SessionStartConfig as the input boundary for selected train and permanent office effects. It does not implement fleet, train purchases, or office upgrades.

Future production may compose:

1. Selected train-model base
2. Permanent office effects
3. Session-only purchases

Only the third layer disappears at session end.

## 6. UI and Art Boundary

### 6.1 Session Layout

- The central field uses top-down orthographic 2D.
- A thin top HUD presents session time, track inventory, cash, and durability.
- A thin bottom HUD presents contract progress, cargo slots, and urgent track-end warning.
- The map remains the dominant interactive area.
- UI containers use anchors and size flags rather than fixed pixel positions.

### 6.2 Adjustable Layout Metrics

Create an agent-editable UILayoutProfile Godot Resource with:

- outer_padding_x
- outer_padding_y
- panel_padding
- item_gap
- row_gap
- hud_height
- icon_size

Horizontal and vertical padding are independent. Validated bounds prevent layout settings from consuming the required playfield or causing HUD overlap. The prototype exposes these values in the Inspector and does not implement a player-facing settings screen.

### 6.3 Art Replacement Rule

Functional state, input hit regions, and layout semantics are independent from final textures, icons, fonts, animation, and audio. Views and themes consume replaceable assets.

Changing prototype art must not require edits to domain systems. Changing padding and layout metrics is allowed and is not treated as domain-logic modification.

Custom art production remains deferred. After the prototype feature set stabilizes, create a separate art-resource scope using the proven list of visible states and feedback needs.

## 7. Feature Branches

### 7.1 proto/00-foundation

Purpose: establish a reproducible prototype project.

Scope:

- Track the currently untracked Godot project scaffold.
- Add repository ignores for Godot cache, local logs, exports, and Visual Companion state.
- Establish directories for domain, presentation, data, tests, and debug tools.
- Configure Windows PC, 16:9, mouse input, and project startup.
- Add the native headless test runner and a boot smoke test.
- Define balance Resource loading and deterministic seed input.

Acceptance:

- Editor startup succeeds.
- Headless startup succeeds.
- The complete test command succeeds.
- No generated cache or local log is tracked.

### 7.2 proto/01-session-shell

Purpose: provide a timed empty session in the approved visual layout.

Scope:

- Top-down field and fixed 16:9 baseline
- Thin top and bottom HUD containers
- UILayoutProfile and Inspector-adjustable metrics
- Session start, countdown, regular end, and result transition
- Primitive placeholder theme

Acceptance:

- A timed empty session completes once.
- Regular end cannot trigger settlement or transition twice.
- Minimum and maximum layout metrics do not overlap controls or remove the required field.
- Mouse coordinates map consistently to the field after supported window resizing.

### 7.3 proto/02-track-train

Purpose: validate continuous track maintenance.

Scope:

- Endpoint-only track extension
- Track-inventory consumption
- Automatic rear recovery
- Fixed-speed train movement
- Track-end early termination
- Remaining-distance or remaining-time warning

Acceptance:

- Inventory never becomes negative.
- Every recovered segment returns length once.
- The train never stops to wait for inventory.
- Reaching the end ends operation once.
- A player can sustain the train by drawing and timing recovery.

### 7.4 proto/03-warp-cargo

Purpose: create selective delivery decisions.

Scope:

- Seeded pair generation and forecast
- Activation, loading, transit, delivery, expiry, and void states
- Automatic load and unload
- Cargo-slot capacity
- Immediate base delivery fee
- Pair and cargo feedback using color and shape

Acceptance:

- Empty, full, and mixed cargo-slot scenarios behave correctly.
- One pair creates one cargo and one reward.
- Movement resolves before expiry at the same decision instant.
- Regular end voids remaining cargo without penalty.
- Fixed seeds reproduce pair and event order.

### 7.5 proto/04-risk-investment

Purpose: introduce route, durability, and temporary-spending trade-offs.

Scope:

- Visible hazard terrain
- Distance-based deterministic damage
- Durability and repair-cost basis
- Planned-track edits
- Costly grade-separated crossings without branching
- Temporary track and cargo-capacity purchases

Acceptance:

- Damage is deterministic for the traveled path.
- Purchases and edits charge cash once.
- Crossings never create branches or merges.
- Zero durability ends operation once.
- Every end condition removes temporary increases.

### 7.6 proto/05-contract-economy

Purpose: complete one contract and settlement cycle.

Scope:

- Six company definitions
- One selected company contract
- Quota, fee, completion curve, penalty curve, and over-attainment trust
- Contract selection screen
- Ordered contract, repair, and operating settlement
- Operations and results feedback required for the cycle

Acceptance:

- Uncontracted deliveries pay fees without affecting contract state.
- Attainment through 100% controls cash settlement.
- Only over-attainment creates trust.
- Settlement order matches the gameplay specification.
- One full contract-selection-to-settlement cycle is playable.

### 7.7 proto/06-credit-survival

Purpose: complete the endless company-survival loop.

Scope:

- Trust-based company credit limits
- Voluntary between-session borrowing
- Fixed company rates and automatic repayment schedules
- Multiple-company debt and refinancing
- Deficit recovery
- Cycle progression, difficulty growth, and bankruptcy

Acceptance:

- Borrowing never exceeds remaining company credit.
- Positive-cash voluntary borrowing works.
- Principal and interest use the specified pre-repayment basis.
- One company’s proceeds may service another company’s debt.
- Updated trust and freed credit are available immediately after settlement.
- The loop repeats until bankruptcy.

### 7.8 proto/07-playtest-ready

Purpose: deliver a reproducible external playtest build.

Scope:

- Seed and ordered event logging
- Replay or deterministic diagnostic reproduction
- Required playtest metrics
- Bankruptcy results and run summary
- Balance Resource cleanup
- Input and warning usability pass
- Windows debug export

Acceptance:

- Fixed-seed state and important event sequences match across reruns.
- Logs are created outside Git-tracked paths.
- A Windows build starts and completes the full loop.
- A new tester can begin a run without developer intervention.
- Observers can record the three target decisions.

## 8. Test Strategy and Merge Gates

Use three layers on every branch:

1. Pure domain unit tests
2. Fixed-seed integration scenarios
3. Windows 16:9 manual smoke play

Use a lightweight native GDScript headless runner and avoid third-party test-plugin dependency for the prototype.

Required merge conditions:

- Branch is based on the latest accepted Prototyping state.
- All existing and new headless tests pass.
- The branch-specific fixed-seed scenario passes.
- The Windows manual smoke checklist passes.
- No test is skipped or disabled to permit merging.
- No generated cache, local run log, or playtest personal data is tracked.
- Prototyping remains executable and playable after merge.

Squash each accepted feature branch into Prototyping and create sequential tags prototype-m1 through prototype-m8. The tag identifies the accepted playable state after each branch.

## 9. Error Handling and Invariants

- Invalid balance or layout Resources prevent a debug session from starting and identify the resource and field.
- Debug assertions live near the system that owns each invariant.
- SessionController accumulates end requests and selects one final reason.
- Settlement uses a completion guard and cannot execute twice.
- Presentation falls back to operations or results on recoverable release-style errors rather than silently changing economy state.
- Event logs include seed, cycle, tick, event type, and stable entity identifiers.

The gameplay specification’s invariant list is mandatory and is covered incrementally by the branch acceptance tests.

## 10. Git and Review Policy

- Do not push feature work directly to Prototyping.
- Do not target Development with prototype work.
- Keep one validation objective per branch.
- Do not mix unrelated refactors with feature delivery.
- Avoid parallel edits to the shared main session scene.
- Review domain ownership, test evidence, and manual smoke evidence before merge.
- Fix regressions before starting the next sequential branch.

Implementation branch creation is not part of this design-document commit. It begins only after the implementation plan is approved.

## 11. Prototype Exit and Production Handoff

Feature completion alone does not validate the prototype. Repeated play must visibly produce:

- Track extension and recovery-pressure decisions
- Contract-relevant cargo choice under finite capacity
- Temporary spending versus cash-preservation decisions

Record mechanics that worked, mechanics that failed, observed balance ranges, UX problems, and art requirements.

Do not merge Prototyping into Development. Write an English production specification, review prototype units individually, and selectively port only stable data, pure logic, or tests with explicit ownership and no prototype-only dependency.

The production codebase begins from validated requirements, not from an automatic prototype promotion.
