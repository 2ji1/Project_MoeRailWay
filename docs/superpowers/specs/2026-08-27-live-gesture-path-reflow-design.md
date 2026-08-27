# Live Gesture Path Reflow Design

**Date:** 2026-08-27

**Status:** Implemented on feature branch; pending main integration

**Implementation branch:** `feature/live-gesture-path-reflow`

**Manually accepted implementation commit:** `ecbcb191cd959d9ed24870a241d400b6cbf5d6c4`

**Verified base:** `1a0cd466287f81c3a413c773fd8974d5dbb72f08` (`main`, `origin/main`)

**Godot baseline:** `4.7.1.stable.official.a13da4feb`

**Automated baseline:** `PASS: 19 prototype test suite(s)` plus the four registered standalone integrations

## 1. Purpose and Authority

The current held-pointer fix changes the straight, left-curve, and right-curve choice of an already completed editable head. It does not make an ordinary extension gesture reversible. An ordinary gesture still accumulates every crossed cell as permanent input for the lifetime of the press. Once that accumulated candidate becomes a visible ghost, moving the still-held pointer back across the route or toward another direction normally creates a duplicate or discontinuous candidate. The runtime rejects that candidate and correctly retains the last valid state, but the visible result is a ghost that no longer follows the pointer.

This amendment makes every gesture-owned ordinary extension a live, reversible path. Each held-pointer update rebuilds the complete candidate from the exact gesture origin and the current normalized drag path. Backtracking shortens the ghost, crossing an earlier gesture cell removes the superseded suffix, and continued motion immediately creates a new branch. The candidate remains atomic and subject to all existing route, geometry, inventory, lock, construction, recovery, contact, and train-sampling invariants.

This document supersedes the ordinary-extension non-goal in `docs/superpowers/specs/2026-08-27-live-gesture-template-reselection-design.md` and the append-only ordinary-extension clauses in `docs/superpowers/specs/2026-08-26-endpoint-track-reshaping-design.md`. Those documents remain authoritative for endpoint-only gesture start, deterministic completed-head template selection, fixed-prefix preservation, right-click abort, hover behavior, and train safety except where this amendment explicitly replaces per-frame path ownership.

## 2. Reproduced Failure

The accepted playtest recording begins with no route records and `TRACK 18 / 18`. The player presses the departure endpoint once and keeps the left button held. After the first valid route appears, the pointer moves to cells on the other side of that route, but the ghost endpoint remains at the earlier location.

The failure is caused by the existing split contract:

- `TrackFieldView` emits only cells newly crossed since the previous consumed frame;
- `GridTrackRuntime` appends those facts to `_gesture_ordinary_input_facts` for the full gesture lifetime; and
- a later duplicate, overlap, or non-adjacent continuation is rejected while the last valid candidate remains visible.

The completed-head reselection tests pass because they begin with a concrete editable head and use the pointer to choose among three precomputed template targets. They do not exercise an empty-departure or fixed-endpoint ordinary gesture whose path must shrink and rebranch before release.

A separate manual observation exposed a required recovery-state fix. After a running train has recovered rear cells, the current endpoint can remain green and `gesture_has_legal_operation` can remain true while a direct adjacent drag from that endpoint publishes no new record. The failure is deterministic before terminal completion when the completed-template target is the physical press-origin cell: `live_gesture_path` omits that cell, so treating an absent target as an empty suffix drops the entire suffix path. This is a contract defect, not a terminal-input observation, and must be covered by the recovery evidence below.

## 3. Interaction Contract

### 3.1 Gesture origin

A gesture still begins only on the current active endpoint and captures the existing detached gesture-origin snapshot. The press cell is the path origin and is not charged as a new route record.

The gesture origin remains immutable until one of these terminal events:

- left release finalizes the last valid candidate;
- right press aborts and restores the exact origin;
- session completion ends capture; or
- train preparation terminates an overlapping gesture before immutable sampling.

### 3.2 Live normalized path

While the same left press remains held, presentation owns one ordered `live_gesture_path` of grid cells after the press endpoint. The physical press-origin cell is not emitted in this array; the authoritative gesture origin is explicitly represented as the implicit prefix immediately before it. The array updates from every rasterized pointer segment in event order.

For each newly observed cell:

1. Re-entering the press endpoint clears the complete live path.
2. Re-entering a cell already in the live path truncates every later cell.
3. Entering a new orthogonally adjacent cell appends it.
4. A multi-cell pointer jump is processed one rasterized cell at a time under the same rules.
5. Consecutive duplicates are ignored.

This loop-erased path rule lets the player drag backward over the current ghost and continue in a different direction without releasing. The visible candidate must respond during the held gesture; the player is not required to finalize, cancel, or start a second press.

The path snapshot ends at the current inside-grid pointer cell whenever the current rasterized movement is representable by a valid normalized path. Pointer motion outside the grid retains the last observed inside-grid path and does not implicitly finalize or abort.

### 3.3 Ordinary extension

When the gesture origin has no editable completed-head template, every update stages:

```text
exact gesture-origin route
+ current complete live_gesture_path
```

The runtime does not append this frame to a historical ordinary-input list. It rebuilds from the gesture origin and the complete current path snapshot. Shortening refunds exactly one inventory cell per removed gesture-owned record. Rebranching charges only the records present in the new candidate. A rejected candidate changes nothing and leaves the last valid candidate visible.

This applies both to an empty departure and to ordinary extension from a fixed or locked endpoint. The origin endpoint remains fixed; only records created by the active gesture are reversible.

### 3.4 Completed-head template selection and suffix

The existing current-pointer rule remains authoritative for choosing the straight, left-curve, or right-curve replacement of a completed editable head. The runtime still rebuilds that replacement from the gesture origin.

The post-template suffix is no longer an append-only history. It is derived from the current complete live path plus its implicit origin prefix:

- the physical press-origin cell is the authoritative implicit occurrence at index `-1`, immediately before `live_gesture_path`;
- cells before the selected target are control input and never become route records;
- when the selected target occurs in `live_gesture_path`, only cells after its most recent occurrence form the suffix;
- when the selected target is absent from `live_gesture_path` but is exactly equal to the authoritative gesture press origin, treat that origin as the implicit occurrence at index `-1` and reconcile the entire `live_gesture_path` as the suffix;
- any other absent target produces an empty suffix;
- no append-only, synthetic, or pointer-invalid fallback may supply a suffix; the implicit-origin rule applies only when equality with the authoritative gesture origin is established;
- re-entering or reselecting a target discards the superseded suffix; and
- backtracking through the suffix shortens it before any new branch is appended.

The existing deterministic pointer tie order and current-selection tie retention remain unchanged.

### 3.5 Atomic last-valid behavior

Every update validates one detached candidate before publication. Bounds, adjacency, duplicate, overlap, inventory, geometry resolution, immutable ledger, anchor, continuity, construction, recovery, train-preparation, and finalization failures retain the complete last valid candidate.

Last-valid retention is an error boundary, not path ownership. A failed update must not contaminate the current normalized input snapshot or make a later valid backtrack/rebranch impossible.

## 4. Identity and Inventory

The fixed pre-gesture route retains exact record serials, nominal distances, construction state, build progress, piece ownership, ledger entries, support metadata, recovery facts, and contact observations.

Gesture-created records use monotonically increasing route serials. A serial published by an earlier live candidate is never reassigned to a different cell after that candidate is shortened or rebranched. The gesture origin therefore retains a serial watermark separate from its exact route snapshot.

Every published candidate must satisfy:

```text
available inventory + active owned route records = total inventory
```

Shortening and rebranching are staged transactions. A failed replacement preserves route records, serial watermark, inventory, pieces, ledger, recovery, anchors, contacts, and presentation observations exactly.

## 5. Component Responsibilities

### `TrackFieldView`

- Continue mapping and rasterizing real Godot mouse events.
- Maintain the complete normalized live path for the current capture.
- Keep the physical press-origin cell out of `live_gesture_path`; the detached gesture-origin fact remains authoritative as its implicit prefix.
- Clear the live path on release cleanup, abort feedback, train-safety termination, and session completion.
- Publish a detached full path snapshot on every consumed frame.
- Do not resolve geometry, mutate inventory, or decide candidate validity.

### `TrackInputFrame`

- Carry the full normalized live path in addition to the existing edge, held, release, current-pointer, and right-click facts.
- Preserve the existing per-frame crossed-cell field only where required by compatibility tests during migration; it is not authoritative ordinary-gesture history after this amendment.
- Remain a concrete prototype record rather than a generalized command system.

### `TrackSystem`

- Preserve endpoint-only start and fresh-press latching.
- Pass the full live path and current pointer to the runtime while capture remains active.
- Preserve right-click abort priority and capture termination rules.

### `GridTrackRuntime`

- Rebuild ordinary candidates from the gesture origin and the current full path snapshot.
- Derive a selected template's current suffix from that same snapshot.
- Remove append-only ordinary and suffix path ownership once no caller depends on it.
- Preserve the monotonic gesture serial watermark independently of the reversible candidate.
- Publish only valid candidates atomically and keep the origin independently abortable.

No resolver, train, construction, recovery, hover-color, route-graph, pathfinding, spline, or production abstraction is added.

## 6. Required Automated Evidence

The implementation must add focused RED/GREEN evidence for all of the following:

1. A real `TrackFieldView` held press from an empty departure emits a complete live path snapshot rather than only the latest delta.
2. Moving backward onto an earlier gesture cell truncates the later path cells.
3. Continuing from that earlier cell in another direction appends a new branch in the same held press.
4. Returning to the press endpoint clears the live path without releasing.
5. An empty-departure ordinary gesture publishes one valid ghost, then replaces it with the rebranched ghost while still held.
6. The superseded ordinary suffix disappears, inventory matches the current candidate, and fixed-origin facts remain exact.
7. Removed live-candidate serials are never reused for different cells.
8. A rejected rebranch retains the last valid candidate, and a later valid backtrack/rebranch still succeeds.
9. A completed-head template gesture retains current-pointer straight/left/right reselection and derives extension only from the current normalized suffix.
10. Right-click during either ordinary or template gesture restores the exact pre-gesture route and inventory.
11. Release finalizes the current candidate, and further held motion remains ignored until a fresh press where required by the existing termination contract.
12. Train preparation, locked geometry, construction, recovery, hover, cancellation, session completion, and all existing input behavior remain green.
13. A real RUNNING-state recovery sequence starts with `18` inventory cells, builds and constructs `13` straight records, locks/samples the train, recovers the rear prefix to leave `7` records and `11` available cells, then presses the current endpoint of the resulting three-record straight editable head, drags to an adjacent valid cell, and requires an eighth record/current endpoint with `10` available cells before release. The test must assert the press-origin target is recovered through the implicit-origin suffix rule and must use actual `InputEventMouseButton` and `InputEventMouseMotion` delivery through `TrackFieldView` and `TrackSystem`.

At least one integration must use actual `InputEventMouseButton` and `InputEventMouseMotion` instances in this order:

```text
press endpoint
drag to create a multi-cell ghost
keep left held
move backward across that ghost
continue to the opposite side
observe the replacement before release
```

A domain-only call sequence cannot substitute for this integration.

The recovery sequence in item 13 is an additional actual-event integration requirement; synthetic direct runtime calls alone do not prove that the press-origin representation, endpoint latch, rasterized path, and RUNNING lifecycle compose correctly.

## 7. Manual Acceptance

On Windows with Godot `4.7.1.stable.official.a13da4feb`:

1. Start a fresh session with the full track inventory visible.
2. Press the green departure endpoint and keep the left button held.
3. Drag several cells to create a visible straight or curve ghost.
4. Without releasing, move backward across the ghost and continue toward the opposite side.
5. Verify that the superseded cells disappear immediately and the ghost endpoint follows the current drag path.
6. Repeat from an existing completed editable head and verify straight, left-curve, and right-curve reselection plus suffix shortening.
7. Verify that inventory follows the currently visible candidate exactly.
8. During another held edit, right-click and verify exact restoration to the pre-gesture route and inventory.

The discovered recovery failure is a required fix before acceptance: while the session is RUNNING (not `SESSION COMPLETE — TRACK END REACHED`), repeat the 18-cell, 13-straight, construct/lock/sample, rear-recovery-to-7-records/11-available setup, press the three-record straight editable-head endpoint, drag one adjacent cell, and verify the eighth record appears with 10 available cells before release. Do not treat a terminal completed-session click as evidence of this defect, and do not upgrade this amendment to Implemented or accepted until the required fix is implemented and reviewed.

Record the evidence in English in the existing Windows track-train manual record. The primary `main` checkout remains the user playtest workspace and is updated only after reviewed pull-request integration.

## 8. Non-goals

- No arbitrary pathfinding from the press endpoint to a remote pointer cell.
- No mouse-position spline or pixel-continuous curve deformation.
- No branchable route or general route editor.
- No undo stack beyond the active gesture origin and current normalized path.
- No new ghost styling, animation, color, or opacity.
- No change to curve template geometry, grid dimensions, train motion, construction timing, recovery, or right-click suffix eligibility.

## 9. Delivery Gates

Implementation remains isolated in `feature/live-gesture-path-reflow`. Each implementation task requires a focused failing test, observed RED, minimum GREEN, the complete 19-suite and four-integration regression gate, an explicit exact-file allowlist, exact-path staging, a focused commit, independent specification review, and independent quality review.

After automated evidence, manual verification, and final reviews pass, follow the active main-first branch policy: push the feature branch, open a pull request targeting `main`, merge with a merge commit, fast-forward and retest the primary `main`, then clean the feature worktree and branches. Do not terminate, reset, or repurpose a user-owned Godot editor process.
