# Endpoint Track Reshaping Design

**Date:** 2026-08-26

**Status:** Draft for written-spec review

**Implementation branch:** `feature/endpoint-track-reshaping`

**Verified base:** `47cbad829db0e4fac8aaf15c025189cbdd1aaef4` (`main`, `origin/main`)

**Godot baseline:** `4.7.1.stable.official.a13da4feb`

**Automated baseline:** `PASS: 19 prototype test suite(s)`

## 1. Purpose and Authority

The current reflowable-head implementation incorrectly turns the five route cells owned by a `CURVE_3X3` into a generic five-record mutable horizon. The product requirement is narrower: five is the owned route-cell count of the largest L-shaped curve template, not an arbitrary straight-line editing window.

This amendment replaces the generic horizon with endpoint-only, template-driven reshaping. A player starts one left-button gesture from the active route endpoint, may reshape the actual mutable head template between straight, left-curve, and right-curve alternatives, and may continue extending from the selected replacement endpoint in the same gesture. Valid candidates publish immediately and atomically. Right-click during the gesture restores the exact gesture-origin state.

This document supersedes only the conflicting head-horizon, head-locking, endpoint-gesture, and hover clauses in:

- `docs/superpowers/specs/2026-08-25-reflowable-track-head-design.md`; and
- the corresponding implementation requirements in `docs/superpowers/plans/2026-08-25-reflowable-track-head.md`.

The grid-track design remains authoritative for ordered orthogonal route records, the existing `1x1`, `2x2`, and `3x3` curve templates, footprint and overlap rules, contact anchors, nominal route distance, construction, inventory, recovery, and deterministic train motion. The reflowable-head design remains authoritative for construction/geometry separation, whole-piece immutable ledger entries, exit-support dependencies, safe train preparation, canonical sampling, and solid rendering of built mutable geometry except where this amendment explicitly changes why a piece becomes locked or how an endpoint gesture mutates the head.

## 2. Corrected Curve Meaning

For template radius `r` in `1`, `2`, or `3`, a curve owns `2r - 1` ordered route records:

- `CURVE_1X1` owns one route record;
- `CURVE_2X2` owns three route records; and
- `CURVE_3X3` owns five route records.

A `CURVE_3X3` therefore owns an L-shaped route sequence with two incoming cells, the turn cell, and two outgoing cells. Those five records are not a generic mutable suffix size. Five straight records have no special editing identity merely because their count is five.

The existing resolver continues to derive curve footprints as the inclusive axis-aligned bounding box of the owned route cells and to sample the existing deterministic curve centerline. This amendment changes route-head mutation and locking, not template geometry.

## 3. Terminology

### 3.1 Active endpoint

The **active endpoint** is the last active route cell, or the departure cell when the route is empty. A left-button track gesture may begin only from this cell.

### 3.2 Head template

The **head template** is an actual geometry choice whose owned route span ends at the active endpoint. It is one of:

- a straight alternative over the same ordered span;
- a left-turn curve alternative; or
- a right-turn curve alternative.

A completed head curve is editable only when every record and every owning piece in its replacement span is geometry-unlocked and not required by train sampling.

### 3.3 Incoming support

An unlocked straight endpoint may retain only the minimum incoming support needed to form the largest future curve. For `CURVE_3X3`, this is the two immediately preceding straight route records. This is a template dependency, not a general two-record or five-record editing horizon.

If a locked boundary leaves fewer support records, the existing resolver may select the largest valid smaller template. It may not move a locked record to manufacture a larger curve.

### 3.4 Gesture origin and last valid candidate

The **gesture origin** is a detached, exact snapshot captured when a valid endpoint left press begins. It contains the active route sequence, inventory, geometry observations, immutable ledger, construction state, recovery state needed by the runtime transaction, and the head-template entry facts.

The **last valid candidate** is the most recent complete gesture candidate that passed every route, inventory, geometry, locked-ledger, anchor, continuity, and bounds check and was atomically published. An invalid later cursor update leaves it unchanged.

## 4. Endpoint Gesture Contract

### 4.1 Start

A fresh left press starts a head gesture only when:

- the session is not complete;
- the press maps inside the grid;
- the press cell equals the active endpoint; and
- at least one legal operation exists: a valid template replacement or a legal adjacent extension with sufficient inventory.

A press anywhere else discards its crossed-cell buffer and does not start capture. A held button after a completed, rejected, or aborted capture never starts a new gesture; the player must release and press again.

### 4.2 Template selection phase

When the gesture begins on an editable completed head curve, the fixed entry predecessor and incoming heading define three deterministic target endpoints over the current owned route count: straight, left curve, and right curve.

The pointer movement from the old endpoint toward one of these target endpoints is control input, not constructed track. Ordered rasterized cells are observed until they enter a valid target endpoint. Entering a target selects that complete template. Intermediate cells before the selected target are ignored for route construction.

If the ordered gesture later enters a different valid template target, the newer target becomes the selected template. The runtime rebuilds from the original gesture snapshot, so switching direction never layers a second edit on top of a prior candidate.

A target is selectable only when its complete ordered route span is orthogonally adjacent, unique, in bounds, compatible with locked footprints and active anchors, and resolvable under the existing overlap and downgrade rules. Ties or cursor positions that have not entered a valid target retain the last valid candidate without guessing a new template.

### 4.3 Extension phase

After a target endpoint is selected, only ordered crossed cells after that target are interpreted as new construction. They extend from the selected replacement endpoint under the existing endpoint-only adjacency, uniqueness, bounds, inventory, and first-rejection rules.

The same left-button gesture may therefore:

1. replace the current head curve with straight, left-curve, or right-curve geometry;
2. continue beyond the selected target; and
3. append additional route cells without a release and second press.

When the active endpoint is locked or no completed head curve is editable, the gesture has no replacement phase. It begins ordinary extension from the fixed endpoint. The endpoint cell itself may be locked; the gesture may append after it but may never move it.

### 4.4 Live atomic publication

Every cursor update stages one complete candidate from the gesture origin:

```text
fixed prefix
+ selected straight/left/right template
+ valid extension cells after the selected target
```

The runtime validates the complete candidate before publication. If valid, it atomically publishes route cells, geometry pieces, inventory, construction observations, ledger updates required by already-fixed geometry, and detached presentation observations. The result appears immediately and uses normal solid/building/ghost rendering according to the preserved construction state; there is no special reflow ghost style.

If invalid, the runtime publishes nothing from that update. The last valid candidate remains authoritative and visible. Moving outside the grid, entering a conflicting cell, exhausting inventory, or failing geometry resolution does not automatically abort the gesture.

Left release finalizes the last valid candidate and discards only transient gesture state. Release does not apply another route mutation.

## 5. Template-Driven Mutability and Locking

### 5.1 Removal of the generic five-record horizon

The runtime must remove the invariant and algorithm that count provisional records and lock the earliest whole piece whenever the count exceeds five. No stable-state assertion may require `provisional_count <= 5`.

Five remains valid only as the nominal owned-record count of `CURVE_3X3` and as a test fixture count for an actual L-shaped curve.

### 5.2 Stable head mutability

Outside an active gesture, geometry-unlocked records may remain mutable only when they are:

- owned by the actual geometry piece that reaches the active endpoint; or
- one of the immediately preceding unlocked straight support records required to form a larger endpoint curve.

Whole geometry pieces that are neither part of the current endpoint template nor required incoming support retire from head mutability and become immutable ledger entries. Retirement is piece-aligned. It never splits a `1`, `3`, or `5`-record curve and continues to record any required exit-support serial.

Construction completion alone does not lock geometry. A `BUILT` endpoint template remains solid and editable until head retirement or train preparation locks it.

### 5.3 Gesture lifetime

During an active gesture, the gesture-origin replacement span and gesture-added suffix remain transaction-owned even after the candidate extends past a selected curve endpoint. This permits the player to re-enter another template target and correct the selection before release.

Head-retirement locking caused by the newly extended route occurs when the gesture finalizes, not between cursor updates. Train safety is the exception.

### 5.4 Train safety

`prepare_for_train_sampling` remains authoritative and may lock only complete geometry pieces required by canonical current/prospective train sampling. Locked geometry is never moved, resized, reclassified, removed, renumbered, or resampled from a gesture candidate.

If preparation requires any piece in an active gesture's mutable replacement span or extension suffix, the runtime first preserves the last valid published candidate, ends the gesture, and then performs the existing whole-piece train preparation. Further motion from the still-held left button is ignored until a fresh press.

Input ordering gives an already-observed gesture-abort right press priority over preparation in the same tick. The abort restores the gesture origin first; train preparation then operates on that restored route.

## 6. Record Identity, Construction, and Inventory

The fixed prefix retains exact route serials, cells, nominal distances, construction states, immutable geometry, ledger identities, and recovery facts.

Within a same-length template replacement, route records retain their route-order identity:

- each existing route serial remains at the same nominal route position;
- its cell may change to the selected alternative's cell;
- its `RESERVED_GHOST`, `BUILDING`, or `BUILT` state and build progress remain unchanged; and
- no inventory charge or refund occurs solely because its geometry or cell changes.

New extension records receive fresh monotonically increasing route serials and begin under the existing reservation and construction rules. Shortening a gesture-owned extension refunds exactly one inventory cell per removed gesture-added record. Re-extending charges exactly one cell per newly appended record. Serial values consumed by a previously published live candidate are never reassigned to a different record after removal.

The candidate transaction must conserve:

```text
available inventory + active owned route records = total inventory
```

It must also preserve the existing monotonic nominal-distance and recovery-frontier invariants. A failed candidate changes no cell, serial, distance, build state, inventory count, ledger entry, anchor observation, or presentation observation.

## 7. Right-Click Gesture Abort

A right press observed while a left-button head gesture is active means **abort the entire current gesture**. It does not invoke ordinary clicked-cell suffix cancellation.

Abort atomically restores the exact gesture origin, including:

- the pre-gesture route cells and endpoint;
- the pre-gesture straight/left/right geometry;
- route serials and nominal distances;
- construction state and build progress;
- inventory;
- immutable ledger and exit-support metadata;
- recovery and anchor observations; and
- detached presentation observations.

Abort clears left capture immediately. Continued physical left-button hold and motion are ignored until release followed by a new press.

When no head gesture is active, right-click retains the existing endpoint-suffix cancellation contract: the clicked record and every later active record must be cancelable provisional `RESERVED_GHOST` records, no active exit-support dependency may be removed, and a successful cancellation refunds one inventory cell per removed record.

If train preparation already ended the gesture before the right press is processed, the press follows ordinary right-click rules because no gesture remains to abort.

## 8. Hover Contract

Presentation publishes and draws two independent hover observations:

- `hover_extend_cell`: the active endpoint when a fresh left-button gesture may legally begin; and
- `hover_cancel_cell`: a cell whose clicked-to-end suffix is currently eligible for ordinary right-click cancellation.

The colors are:

- green for `hover_extend_cell`; and
- the existing gold `HOVER_COLOR` for `hover_cancel_cell`.

When both observations identify the same endpoint, green has visual priority. Right-click eligibility still exists; color priority does not change input behavior.

No green hover appears on arbitrary empty, built, locked, train-occupied, or non-endpoint route cells. A running train does not suppress endpoint hover. Both hover observations clear when the pointer is outside the grid or the session is complete.

Hover facts are derived from current authoritative route and gesture eligibility, not from construction state alone. A locked endpoint may still be green when it is fixed in place but has a legal adjacent extension. An endpoint with neither an editable template nor a legal inventory-funded adjacent extension is not green.

## 9. Input and Tick Ordering

For each physics tick, the authoritative order is:

1. If a right press and an active head gesture coexist, abort the gesture and consume the right press.
2. Otherwise apply ordinary right-click suffix cancellation and end any stale left capture as required by the existing contract.
3. Begin a fresh left gesture only from the active endpoint.
4. Apply the current left-gesture template selection and post-target extension candidate.
5. Finalize on left release or preserve active capture when held.
6. Advance ordinary construction.
7. Prepare geometry required for departure or running train sampling, ending an overlapping active gesture before locking.
8. Advance and sample the train, then perform existing recovery and snapshot publication.

A right press always consumes its input edge. It may not both abort a gesture and cancel an ordinary suffix in one tick.

## 10. Component Responsibilities

### `TrackFieldView`

- Capture the current cursor cell and inside-grid fact in addition to ordered crossed cells.
- Maintain pointer capture until release, gesture abort feedback, or session completion.
- Publish separate extend and cancel hover observations.
- Draw green over gold when both hover observations target the endpoint.
- Do not decide geometry validity or mutate inventory.

### `TrackInputFrame`

- Carry immutable per-frame pointer facts, left/right edges, held/released state, and ordered crossed cells.
- Remain a concrete prototype input record; do not introduce a general command framework.

### `TrackSystem`

- Enforce endpoint-only gesture start and fresh-press capture.
- Route active-gesture right press to runtime abort before ordinary cancellation.
- Route cursor updates to runtime candidate staging.
- End capture after abort, release, session completion, or train-safety termination.

### `GridTrackRuntime`

- Own the gesture-origin snapshot and last-valid candidate.
- Discover the concrete editable head span and fixed entry facts.
- Rebuild each candidate from the origin rather than from the prior candidate.
- Validate and atomically publish live candidates.
- Restore the origin on abort.
- Replace generic five-record horizon enforcement with template-driven retirement.
- Preserve immutable ledger, inventory, construction, recovery, and train-sampling invariants.

### `TrackGeometryResolver`

- Continue to resolve the existing deterministic straight and `1x1/2x2/3x3` curve templates.
- Continue bounds, footprint, overlap downgrade, locked conflict, anchor contact, continuity, and nominal sampling rules.
- Accept staged route-cell alternatives without gaining gesture or inventory responsibilities.

No production-oriented abstraction layer, general undo stack, branchable route graph, pathfinding system, freehand spline editor, or visual ghost-edit mode is added.

## 11. Required Automated Evidence

The implementation must add focused RED/GREEN coverage proving:

1. Five straight route records are not treated as a generic mutable five-record horizon.
2. A five-record L-shaped route still resolves as one `CURVE_3X3` with nominal length five.
3. A completed unlocked endpoint `CURVE_3X3` changes right-to-left, right-to-straight, and back again without changing fixed-prefix facts or inventory.
4. A single held gesture reshapes the head and appends post-target extension cells.
5. Intermediate cells between the old endpoint and selected target are control input and never become route records.
6. Re-entering a different target rebuilds from the gesture origin instead of composing edits.
7. Invalid bounds, overlap, duplicate, and inventory candidates preserve the last valid state exactly. A causal production-resolver anchor compatibility/downgrade case uses the same staged route: it resolves at the larger template without the authoritative anchor, then deterministically downgrades to a compatible template when that authoritative anchor is present, preserving anchor observations, inventory, ledger, and every other transaction invariant. The evidence must not require artificial anchor rejection.
8. Left-drag plus right press restores the exact gesture-origin cells, pieces, serials, construction states, inventory, ledger, recovery, and observations.
9. Gesture abort consumes the right press, clears capture, and requires a fresh left press.
10. Ordinary right-click ghost suffix cancellation remains unchanged when no gesture is active.
11. Train preparation freezes an overlapping gesture candidate before sampling and prevents later held-motion mutation.
12. Locked and train-prepared geometry never changes under template selection.
13. Running-state endpoint hover remains green when a gesture can start.
14. A cancelable non-endpoint ghost remains gold.
15. An endpoint that is both extendable and cancelable renders green while retaining right-click eligibility.
16. Session completion and pointer exit clear both hover observations.
17. Full inventory, construction, recovery, train-motion, input, presentation, smoke, and integration regressions remain green.

For anchor evidence, the existing resolver downgrade and contact-anchor behavior remains authoritative and resolver changes are forbidden. An otherwise-valid curve candidate may therefore be downgraded when an authoritative anchor is incompatible; a radius-1 curve contacts its sole footprint turn cell. The causal test proves compatibility and deterministic downgrade rather than manufacturing an anchor-only rejection.

## 12. Manual Acceptance

On Windows with Godot `4.7.1.stable.official.a13da4feb`:

1. Build a straight approach and form a completed unlocked right-turn `3x3` curve at the route endpoint.
2. Press the endpoint and drag to the left-turn target; observe immediate solid left-curve replacement.
3. Without releasing, enter the straight target and continue beyond it; observe immediate straight replacement followed by continuous extension.
4. Repeat the gesture, change the head, append cells, and right-click while still holding left; observe exact restoration to the pre-gesture route and inventory.
5. Start the train and verify that an actionable endpoint retains green hover while the train is running.
6. Verify that ordinary cancelable non-endpoint ghost cells retain the existing gold hover.
7. Verify that an endpoint satisfying both extend and cancel eligibility renders green and that right-click still performs the eligible action.
8. Allow the train to approach the edited span; verify that geometry freezes before sampling and cannot be moved by continued held motion.

Record manual evidence in English under the existing Windows track-train manual record. Do not claim one screenshot proves mutually exclusive lifecycle states; identify separate runs when necessary.

## 13. Delivery and Review Gates

Implementation occurs only in the dedicated external worktree for `feature/endpoint-track-reshaping`, based on the verified `main` commit above. The primary `D:\godot\MoeRailWay` checkout remains a clean local `main` playtest workspace and is not modified during feature implementation.

The implementation plan must define small sequential tasks. Every task requires:

- a focused failing RED test;
- the minimum GREEN implementation;
- the complete automated regression gate;
- an explicit exact-file allowlist;
- exact-path staging and a focused commit;
- independent specification review; and
- independent quality review.

After the complete feature passes automated and manual validation plus final independent reviews, push the feature branch, open a pull request targeting `main`, and merge only with a merge commit under the active main-first branch policy. Fast-forward and retest the primary `main` before worktree and branch cleanup. No integration, push, pull request, merge, or cleanup is part of this design-document commit.
