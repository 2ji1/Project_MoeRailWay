# Live Gesture Path Reflow Design

**Date:** 2026-08-27

**Status:** Scoped implementation, manual acceptance, final review, and main integration are complete on `main` via PR #15 merge commit `92d0823090851aa8608b1a7d7d2e046d4ec6a667`. The clean-gated code/test candidate is `e285c9fc9db0a591beac93c169e198c8f80afa89`; the primary `main` retest passed 19 prototype suites plus all four integrations with no `WARNING:` or `ERROR:` output. Feature-worktree cleanup remains pending.

**Implementation branch:** `feature/live-gesture-path-reflow`

**Task 5 scoped manual acceptance:** `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239` (coalesced release/fresh press, replay, ordinary/RUNNING recovery, and terminal input-lock evidence)

**Task 6 scoped manual acceptance:** `be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f` (origin-owned construction continuity and recovery pause/resume evidence)

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

The gesture origin's route identity, geometry ownership, recovery facts, and contacts
remain immutable until one of these terminal events. Existing train-preparation lock
and ledger synchronization remains the sole non-construction origin update. Construction
state and build progress are the explicit exception: progress for origin-owned route
serials is mirrored into the origin as it advances, so the origin remains an exact
abortable construction state rather than a stale pre-progress snapshot.

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

### 3.4 Active-gesture construction frontier

Progressive construction continues while an endpoint gesture is active, but only for
route serials present in both the current candidate and the detached gesture-origin
sequence. Origin membership authorizes the serial; the shared current/origin identity
is the safe construction frontier. This frontier includes serials inside an editable
completed-head template: a template replacement changes their cells or geometry while
retaining their route serials, nominal positions, construction states, and build
progress. Each progress change is mirrored by route serial into both the current
candidate and the gesture origin before the next held-pointer update can rebuild from
that origin.

Gesture-added suffix serials, which are absent from the gesture-origin sequence,
remain `RESERVED_GHOST` until the gesture finalizes. They must not enter
`BUILDING` or `BUILT` while the gesture remains active. A candidate reflow may
shorten or rebranch that suffix under the existing atomic inventory and serial rules,
but it must never roll back construction progress on an origin-owned serial.

The session tick keeps the existing construction rate, ordering, and placement in
the input-to-train causal sequence. Construction itself does not create geometry
locks, change inventory, or move the train. `recover_behind` remains paused during
an active gesture. Train preparation remains the only operation that may lock
complete geometry pieces; if sampling overlaps active gesture-owned geometry, the
gesture is finalized before immutable sampling as already specified.

### 3.5 Completed-head template selection and suffix

The existing current-pointer rule remains authoritative for choosing the straight, left-curve, or right-curve replacement of a completed editable head. The runtime still rebuilds that replacement from the gesture origin.

The post-template suffix is no longer an append-only history. It is derived from the current complete live path plus its implicit origin prefix:

- the physical press-origin cell is the authoritative implicit occurrence at index `-1`, immediately before `live_gesture_path`;
- cells before the selected target are control input and never become route records;
- when the selected target occurs in `live_gesture_path`, only cells after its most recent occurrence form the suffix;
- when the selected target is absent from `live_gesture_path` but is exactly equal to the authoritative gesture press origin, treat that origin as the implicit occurrence at index `-1` and reconcile the entire `live_gesture_path` as the suffix;
- the implicit-origin whole-live-path suffix is allowed only when the selected template remains the gesture-origin/current selected template (same-template continuation); when the template changes, reconciliation starts from an empty fact list even if the newly selected target equals the gesture origin;
- any other absent target produces an empty suffix;
- no append-only, synthetic, or pointer-invalid fallback may supply a suffix; the implicit-origin rule applies only when equality with the authoritative gesture origin is established;
- re-entering or reselecting a target discards the superseded suffix; and
- backtracking through the suffix shortens it before any new branch is appended.

The existing deterministic pointer tie order and current-selection tie retention remain unchanged.

### 3.6 Atomic last-valid behavior

Every update validates one detached candidate before publication. Bounds, adjacency, duplicate, overlap, inventory, geometry resolution, immutable ledger, anchor, continuity, construction, recovery, train-preparation, and finalization failures retain the complete last valid candidate.

Last-valid retention is an error boundary, not path ownership. A failed update must not contaminate the current normalized input snapshot or make a later valid backtrack/rebranch impossible.

### 3.7 Coalesced release and fresh press ordering

Godot may coalesce an old left-button release and a new left-button press into one consumed `TrackInputFrame`. The frame carries optional final release facts for the completed old gesture:

- `release_live_gesture_path`, a detached full path snapshot captured at the old release;
- `left_release_pointer_cell`, the old release pointer cell;
- `left_release_pointer_inside_grid`, whether that pointer was inside the grid; and
- an observable or derived explicit-release-snapshot flag that distinguishes these real final facts from legacy synthetic combined frames.

`TrackFieldView` captures the old release path and pointer immediately after rasterizing the release, before any fresh press clears the current buffers. The current `live_gesture_path` and current pointer facts remain owned by the fresh press. Ordinary release, release outside the grid, and an empty return to the press origin are all representable: an explicitly empty `release_live_gesture_path` is authoritative and must not be replaced by the fresh path.

`TrackSystem` applies the two phases only for a combined old-release/fresh-held-press frame. If the old runtime gesture is active and the release snapshot is explicit, it updates that runtime with the detached old release path and pointer facts, finalizes its last valid candidate, and clears the old latch and capture. It then begins and updates the fresh press from the fresh facts. If the old state is inactive, rejected, or train-terminated, old geometry facts are ignored while the old latch is cleared. A legacy synthetic combined frame without an explicit old release snapshot preserves last-valid finalize compatibility and must never apply fresh facts to the old runtime.

After finalization or termination cleanup, a fresh held follow-up is processed only by the fresh capture. Release cleanup clears both live and release buffers at the appropriate lifecycle boundary without allowing stale old facts to leak into a later press. The optional final constructor facts remain backward-compatible for existing synthetic producers.

### 3.8 Completed-template replay idempotence

When a template-change frame selects a target equal to the gesture origin but that target is absent from `live_gesture_path`, the runtime starts with an empty suffix and records the successful template-selection input signature: the detached live path plus pointer cell. Repeated identical held snapshots rebuild and revalidate the same candidate without adding a suffix and without bypassing current lock, recovery, geometry, or other validation rules.

A genuinely changed later path or pointer may use the implicit-origin whole-live-path suffix for same-template continuation. Returning to the recorded selection signature removes that implicit suffix again. An in-array target occurrence, with most-recent occurrence precedence, remains authoritative. A template change always reconciles from an empty fact list, even when its newly selected target equals the origin. No early-return cache, synthetic suffix, or pointer-invalid fallback may bypass candidate validation.

## 4. Identity and Inventory

The fixed pre-gesture route retains exact record serials, nominal distances, piece
ownership, ledger entries, support metadata, recovery facts, and contact observations.
For every route serial retained by the active candidate, construction state and build
progress remain synchronized between the current candidate and the gesture origin;
apart from existing train-preparation lock/ledger synchronization, this construction
synchronization is the only origin-state evolution allowed during a held edit.

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
- Capture detached old-release path and pointer facts immediately after release rasterization, before a fresh press clears current buffers; clear release facts during termination cleanup.
- Publish a detached full path snapshot on every consumed frame.
- Do not resolve geometry, mutate inventory, or decide candidate validity.

### `TrackInputFrame`

- Carry the full normalized live path in addition to the existing edge, held, release, current-pointer, and right-click facts.
- Carry optional `release_live_gesture_path`, `left_release_pointer_cell`, `left_release_pointer_inside_grid`, and an observable/derived explicit-release-snapshot flag while preserving constructor compatibility.
- Preserve the existing per-frame crossed-cell field only where required by compatibility tests during migration; it is not authoritative ordinary-gesture history after this amendment.
- Remain a concrete prototype record rather than a generalized command system.

### `TrackSystem`

- Preserve endpoint-only start and fresh-press latching.
- Pass the full live path and current pointer to the runtime while capture remains active.
- Preserve right-click abort priority and capture termination rules.
- On an explicit coalesced old-release/fresh-held-press frame, finalize the old runtime from old release facts before beginning/updating the fresh gesture; ignore old geometry facts for inactive, rejected, or train-terminated old state while clearing its latch.

### `GridTrackRuntime`

- Rebuild ordinary candidates from the gesture origin and the current full path snapshot.
- Derive a selected template's current suffix from that same snapshot.
- Remove append-only ordinary and suffix path ownership once no caller depends on it.
- Preserve the monotonic gesture serial watermark independently of the reversible candidate.
- Advance construction only through route serials already present in the gesture origin,
  including editable-template serials, mirror each state/progress change into the origin,
  and keep gesture-added suffix serials ghost-only until finalization.
- Keep recovery paused while the gesture is active; preserve existing construction rate,
  inventory accounting, geometry-lock authority, train preparation, and sampling order.
- Publish only valid candidates atomically and keep the origin independently abortable.

No resolver, train, construction subsystem, recovery, hover-color, route-graph,
pathfinding, spline, or production abstraction is added. The correction changes only
which existing construction records may advance during a held gesture.

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
14. A coalesced old-release/fresh-press event preserves the old release path and pointer independently from fresh facts, including an explicit empty release path and a release outside the grid.
15. Coalesced ordering covers active, inactive/rejected, and train-terminated old states; legacy synthetic combined frames preserve last-valid finalize compatibility; ordinary release, empty return-to-origin, fresh held follow-up, and termination cleanup clear the correct live/release buffers.
16. A completed-template origin-equal absent-target selection records its detached path/pointer signature; identical held replay revalidates without a suffix or validation bypass, changed later motion can extend through same-template implicit origin, and returning to the signature removes that suffix. Template changes reconcile from empty, while most-recent in-array target precedence remains authoritative.
17. While a gesture is held over a partially constructed route, construction advances origin-owned serials, including editable-template serials, at the configured per-tick rate. With progress larger than the remaining origin work, the returned consumed amount stops exactly at the shared origin frontier; leftover budget never transitions a gesture-added suffix, whose state remains `RESERVED_GHOST` with build progress `0.0`. Crossing multiple origin serial boundaries preserves route order and per-tick rate.
18. The construction correction records an exact `{route_serial: {state, build_progress}}` map and proves that held reflow, abort, finalize, and rejected updates retain the latest mirrored origin-owned state/progress in both origin and current candidate. It asserts unchanged inventory and lock/ledger observations, `recover_behind == 0` while active, and unchanged serial identity.
19. Session lifecycle evidence asserts causal input-application, construction-advance, then train-preparation/sampling order. Active-gesture sampling that overlaps mutable geometry terminates the gesture before immutable sampling; non-overlapping sampling preserves active capture and locks only complete geometry pieces. Both paths preserve the shared serial map and leave gesture-added suffixes unbuilt.

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
9. Begin a fresh endpoint gesture over a partially constructed route and verify that
   already-reserved origin serials continue solidifying, while any newly added suffix
   remains ghost-only until release. Verify the visible result before release and
   confirm recovery remains paused while the gesture is held.

The discovered recovery failure was a required fix before acceptance: while the session is RUNNING (not `SESSION COMPLETE — TRACK END REACHED`), repeat the 18-cell, 13-straight, construct/lock/sample, rear-recovery-to-7-records/11-available setup, press the three-record straight editable-head endpoint, drag one adjacent cell, and verify the eighth record appears with 10 available cells before release. Do not treat a terminal completed-session click as evidence of this defect. The coalesced-release, template-replay, ordinary-RUNNING, and terminal manual evidence is attributed to tested HEAD `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239`; active-gesture construction and recovery pause/resume evidence is attributed to tested HEAD `be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f`; these reviewed results are integrated on `main` via PR #15 merge commit `92d0823090851aa8608b1a7d7d2e046d4ec6a667`.

Record the evidence in English in the existing Windows track-train manual record. The primary `main` checkout remains the user playtest workspace and is updated only after reviewed pull-request integration.

## 8. Non-goals

- No arbitrary pathfinding from the press endpoint to a remote pointer cell.
- No mouse-position spline or pixel-continuous curve deformation.
- No branchable route or general route editor.
- No undo stack beyond the active gesture origin and current normalized path.
- No new ghost styling, animation, color, or opacity.
- No change to curve template geometry, grid dimensions, train motion, construction
  rate, recovery policy, or right-click suffix eligibility. Active-gesture construction
  follows the route-identity frontier in section 3.4; recovery remains paused.

## 9. Delivery Gates

Implementation remains isolated in `feature/live-gesture-path-reflow`. Each implementation task requires a focused failing test, observed RED, minimum GREEN, the complete 19-suite and four-integration regression gate, an explicit exact-file allowlist, exact-path staging, a focused commit, independent specification review, and independent quality review.

After automated evidence, manual verification, and final reviews pass, follow the active main-first branch policy: push the feature branch, open a pull request targeting `main`, merge with a merge commit, fast-forward and retest the primary `main`, then clean the feature worktree and branches. Do not terminate, reset, or repurpose a user-owned Godot editor process.

## 10. Integration Record

The live gesture path reflow slice is integrated on `main` via PR #15 merge commit
`92d0823090851aa8608b1a7d7d2e046d4ec6a667`. The primary `main` retest passed with
Godot `4.7.1.stable.official.a13da4feb`, `PASS: 19 prototype test suite(s)`, and
all four standalone integrations, with no `WARNING:` or `ERROR:` output. The
integrated behavior covers live held endpoint reflow, completed-head reselection,
hover/cancel, origin-owned construction continuity during a held gesture, and
recovery pause/resume. The historical manual evidence remains attributed to Task 5
tested HEAD `6eee5f2f15d586806c3d68d99fd2e0cc87d4c239` and Task 6 tested HEAD
`be18f1fc84b96ce1f1361cb6b9878c1ed8aeda7f`; cleanup of the feature worktree and
branches remains pending.

## 11. Held-Candidate Retirement Does Not Revoke Origin Editability

The `960x540` Warp Cargo mouse gate at feature candidate `1550012a43e4e7ee7c45fc87e2be78df95b376a9` exposed a separate completed-head reflow defect. A valid held update could append enough suffix cells for stable retirement to lock the editable template in the currently published candidate. The next backtrack or rebranch still carried a valid live path, but `_gesture_template_mutation_is_safe()` inspected that published candidate and rejected every replacement as `unsafe_template_mutation`. Diagnostic evidence showed no pre-gesture locked ledger even though the candidate records had acquired retirement locks.

Within one active press, template-mutation authority comes from the latest authoritative gesture-origin snapshot, not from retirement decisions made only by a published live candidate. The runtime must evaluate the editable span against `_gesture_origin_sequence`, `_gesture_origin_pieces`, and `_gesture_origin_locked_ledger`:

1. Every origin record in the editable span must exist and remain geometry-unlocked.
2. Every such serial must have exactly one unlocked owner in the origin pieces.
3. No origin locked-ledger entry may overlap the editable span.
4. Stable retirement performed while validating or publishing a held candidate may lock that candidate's earlier pieces, but it must not retroactively revoke the origin span's editability during the same press.
5. Construction-state mirroring may advance origin-owned records but does not create geometry locks.
6. Train preparation or another existing train-safety transition may update or terminate the gesture origin before immutable sampling; locks present in that authoritative origin remain strict and byte-preserving.

The correction changes only the source snapshot used by the existing template-mutation safety predicate. It does not unlock or rewrite any piece, weaken ledger validation, permit mutation across a pre-gesture locked boundary, alter retirement rules for finalized candidates, or bypass candidate resolution, footprint, continuity, inventory, construction, recovery, contact, or finalization checks.

Required deterministic evidence must begin an unlocked completed-head template gesture, publish a long suffix that retires the live candidate's original template, prove the current candidate now contains a lock absent from the gesture origin, and then backtrack or rebranch while the same press remains held. The second update must publish successfully from the origin snapshot. A paired prepared/locked-origin fixture must continue to reject the same template mutation with records, geometry bytes, ledger, inventory, recovery, anchors, and contacts unchanged.

## 12. Bounded Held-Reentry Connection

The `960x540` Warp Cargo mouse gate at feature candidate
`d2c055a4b93fd4773b97e6f8b8e08480ef70eb0f` exposed a separate input gap.
The left-button capture and pointer continued updating and the route retained spare
inventory, but an outside-grid interval followed by reentry produced live-path edges
such as `(9, 3) -> (10, 4)`, `(7, 9) -> (7, 11)`, and
`(9, 10) -> (11, 10)`. `TrackCellSequence` correctly rejected those non-orthogonal
or skipped-cell appends, and last-valid preview preservation made the held gesture
appear frozen. This finding is independent of Warp anchors and curve geometry.

The input adapter may now mark its own detached live/release snapshot as eligible
for bounded reentry connection. That authority has all of these limits:

1. Only a frame created by the real `TrackFieldView` capture may grant the
   authority. Constructor-compatible synthetic frames and direct runtime calls
   default to no authority, so an arbitrary remote pointer jump remains rejected.
2. The runtime considers a connector only when two consecutive cells in the
   authorized normalized path are not Manhattan-adjacent. Adjacent observed cells
   remain byte-for-byte authoritative and are never rerouted.
3. The connector starts at the current candidate endpoint and ends at the next
   observed reentry cell. It searches only the finite configured grid, uses only
   orthogonal cells, and is bounded by current integer inventory.
4. The chosen connector is a shortest available cell path. Search expansion and
   tie-breaking use a fixed cardinal order, making identical origin, inventory,
   grid, and input facts produce the same ordered route cells.
5. Active route cells remain blocked. Departure reuse remains governed by the
   existing recovered-departure rule. Every inserted cell is appended through the
   existing sequence transaction, so duplicate cells, discontinuity, and inventory
   exhaustion still fail closed.
6. Connection does not bypass resolver or publication authority. The complete
   candidate must still pass geometry resolution, rectangular footprint collision,
   locked-ledger preservation, continuity, one-owner validation, construction and
   recovery conservation, anchor/contact handling, and finalization checks.
7. If no bounded cell connector exists, or if the connected candidate fails any
   later gate, the runtime preserves the last valid preview and records a specific
   rejection. It never permits the invalid raw jump.
8. Template reselection remains authoritative. Connection applies only to the
   suffix after the selected template endpoint; it does not synthesize a template
   selection or mutate an authoritative locked template.

This is not a route graph, reachability correction, Warp routing, or a general
point-to-point construction command. It is a capture-local normalization of a
single observed outside/reentry discontinuity during one held endpoint gesture.
It preserves one train, one ordered nonbranching route, endpoint-only construction,
monotonic route serials, nominal sampling, and locked geometry bytes.

Required deterministic evidence must reproduce a real held press that leaves the
field, traverses outside, and reenters at a nonadjacent boundary cell while inventory
remains available. The view snapshot must retain the raw nonadjacent observation and
the detached connection-authority fact; the runtime must publish the same fixed
orthogonal shortest connector on repeated runs. Paired evidence must prove that the
same gap without real-view authority is rejected, blocked/no-inventory connectors
remain rejected, existing active cells are not reused, selected-template suffix
connection preserves template authority, release uses its detached authority, and
abort restores the exact origin.

## 13. Locked AABB Footprint and Geometric Collision Occupancy

The `1280x720` mouse gate at feature candidate
`6ba9a9fde5eb241533ca8aff0db90ba22341aaeb` exposed a separate locked-collision
ambiguity. The accepted endpoint was `(4, 2)` and the user dragged into active mint
Warp origin cell `(3, 2)`. The input path was adjacent and complete, but resolution
rejected it as `locked_overlap`. An earlier locked `CURVE_2X2` owned ordered cells
`(2, 2) -> (2, 1) -> (3, 1)` and retained the required inclusive AABB footprint
`[(2, 1), (3, 1), (2, 2), (3, 2)]`. Its centerline did not enter the unowned corner
`(3, 2)`, so the rejection appeared to target an empty cell. The Warp did not consume
input, and its exact-center anchor never became an accepted ordered-route constraint.

This amendment separates two existing meanings without changing either stored route
or geometry bytes:

1. `footprint_cells` remains the inclusive AABB of a curve's owned route cells. It
   remains authoritative for geometry containment, ownership metadata, locked-ledger
   identity, recovery bookkeeping, bounds, unlocked candidate overlap/downgrade, and
   irreducible `final_overlap` rejection.
2. Collision occupancy against an already locked piece is derived on demand from the
   cells in its currently blocking footprint that its stored centerline actually
   contacts. Use the existing deterministic `TrackGeometryPiece.contacts_cell()`
   spatial query and the current grid origin and cell size. Do not add a mutable or
   separately stored occupancy field.
3. A prospective unlocked straight or curve conflicts with a locked piece only when
   both centerlines contact at least one common currently blocking footprint cell.
   A shared AABB-only corner with no locked centerline contact is not a collision.
4. Existing recovered-cell filtering runs before occupancy derivation. A recovered
   footprint cell remains nonblocking exactly as before; the complete source ledger
   footprint and centerline remain byte-for-byte unchanged.
5. Unlocked-versus-unlocked candidate selection remains unchanged and continues to use
   AABB overlap, symmetric `3x3 -> 2x2 -> 1x1` downgrade, and `final_overlap`. This
   correction must not reinterpret or globally relax that gate.
6. Active ordered route cells remain unique. Geometric occupancy does not permit a
   duplicate route cell, branch, merge, self-crossing, discontinuity, or remote route
   insertion. Sequence validation still runs before resolution.
7. An `EXACT_CELL_CENTER` anchor does not override collision. It constrains the common
   local-corner geometry only after its cell is accepted as an owned active route
   occurrence. Warp-free and Warp-occupied cells use the identical collision rule.
8. Locked kind, serial span, footprint, centerline, group, nominal length, active
   slice, construction, recovery, sampling, contact observations, and inventory remain
   unchanged. Identical inputs must derive identical occupancy and resolution.

Required deterministic evidence must reproduce the literal locked `CURVE_2X2` fixture,
show that `(3, 2)` is in its AABB but not its geometric collision occupancy, and prove
that an adjacent suffix through `(3, 2)` resolves with or without an exact-center
anchor. The anchored result must contain the literal center knot. Paired negative
fixtures must still reject when the locked centerline truly contacts the shared cell,
when the route cell is already active, and when two unlocked final AABBs irreducibly
overlap. Every accepted fixture must prove pairwise geometric collision separation,
one owner per serial, locked-ledger byte identity, deterministic replay, inventory and
construction/recovery conservation, continuity, nominal sampling, and exact abort.
