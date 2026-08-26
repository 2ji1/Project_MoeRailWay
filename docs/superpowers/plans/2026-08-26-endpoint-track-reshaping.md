# Endpoint Track Reshaping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic five-record mutable horizon with endpoint-only, template-driven straight/left/right reshaping, atomic live candidates, exact gesture abort, safe train preparation, and detached green/gold hover observations.

**Architecture:** `GridTrackRuntime` owns immutable gesture-origin and last-valid transactions, template discovery, candidate validation, piece-aligned retirement, and train-safety termination. `TrackSystem` owns input-edge routing and capture, `SessionController` owns tick/completion ordering, `SessionSnapshot` publishes detached eligibility facts, and `TrackFieldView` only observes pointer/snapshot facts and renders them. Existing resolver geometry, orthogonal route records, construction, inventory, recovery, anchors, and train sampling remain authoritative.

**Tech Stack:** Godot `4.7.1.stable.official.a13da4feb`, typed GDScript, native headless `SceneTree` test suites, PowerShell, and Git worktrees.

**Spec:** `docs/superpowers/specs/2026-08-26-endpoint-track-reshaping-design.md`

## Global Constraints

- Work only in `D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping` on `feature/endpoint-track-reshaping`; the primary `D:\godot\MoeRailWay` checkout remains clean local `main`.
- Verified base and upstream are `47cbad829db0e4fac8aaf15c025189cbdd1aaef4`; the feature base-to-HEAD diff contains only the canonical design and this plan before implementation.
- Keep production ownership exactly as assigned by the seven tasks; do not edit resolver, record, geometry-piece, start-config, result, train, field, rasterizer, anchor, scene, or unrelated test files.
- Use one-at-a-time new-behavior RED microcycles. Every new RED assertion prints an exact `Endpoint reshape:` marker before exercising the behavior; if a typed missing method could prevent that marker, first use dynamic `has_method` and `call` contract checks.
- Legacy guards are never required to fail. Preserve the existing append/cancel/anchor/recovery/prepare behavior as GREEN regression guards, including the existing L-shaped five-record `CURVE_3X3` case.
- Every task is independently RED, minimum GREEN, full exact 19-suite regression, exact-path commit, fresh separate `gpt-5.6-sol` specification review, and fresh separate `gpt-5.6-sol` quality review.
- All implementation, test, Markdown, and remediation output is produced by `gpt-5.6-luna`; web work, if needed, is also `gpt-5.6-luna`. Sol reviewers are review-only and never edit.
- No rerolls, reachability correction, route-aware RNG, production abstraction layer, undo stack, route graph, pathfinding, spline editor, global mouse mode, or visual ghost-edit mode is introduced.
- A successful candidate preserves `available inventory + active owned route records = total inventory`, route serial monotonicity, nominal-distance monotonicity, recovery frontier, immutable ledger identity, anchors, and detached observation isolation.
- A PASS marker followed by an anchored `ERROR:` line, crash, nonzero exit, or missing required marker is not GREEN.

## Preflight and Shared Gate

- [ ] Verify the primary checkout is clean, on `main`, and at `47cbad829db0e4fac8aaf15c025189cbdd1aaef4`; verify `origin/main` is the same commit. Do not stash, reset, clean, format, stage, copy, move, or delete primary changes.
- [ ] Verify this worktree is clean, on `feature/endpoint-track-reshaping`, and its base-to-HEAD changed set is exactly `docs/superpowers/specs/2026-08-26-endpoint-track-reshaping-design.md` and `docs/superpowers/plans/2026-08-26-endpoint-track-reshaping.md` before implementation.
- [ ] Verify Godot reports exactly `4.7.1.stable.official.a13da4feb`.
- [ ] Run the baseline command below. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`.

```powershell
& 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way' --script res://tests/run_all.gd
```

- [ ] Run the standalone baseline integration with `& 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way' --script res://tests/integration/run_track_train_input_integration.gd`. Require exit code `0`, exact `PASS: track train input integration`, and no anchored `ERROR:`.

Use this exact shared function after each task's focused and full tests. It rejects any changed or untracked path outside the task allowlist, stages each required path separately, verifies the cached set and clean worktree, commits, captures `TASK_SHA` and `TASK_PARENT_SHA`, verifies the committed path set, and runs `git diff --check` over the task commit.

```powershell
function Complete-TaskCommit {
    param(
        [Parameter(Mandatory = $true)][string]$TaskNumber,
        [Parameter(Mandatory = $true)][string[]]$RequiredPaths,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $required = @($RequiredPaths | Sort-Object -Unique)
    $trackedChanged = @(git diff --name-only)
    $stagedChanged = @(git diff --cached --name-only)
    $untracked = @(git ls-files --others --exclude-standard)
    $before = @($trackedChanged + $stagedChanged + $untracked | Where-Object { $_ } | Sort-Object -Unique)
    $unexpected = Compare-Object -ReferenceObject $required -DifferenceObject $before
    if ($null -ne $unexpected) {
        throw "Task $TaskNumber changed set is not the exact required set: $($before -join ', ')"
    }

    foreach ($path in $required) {
        git add -- $path
        if ($LASTEXITCODE -ne 0) {
            throw "git add failed for $path"
        }
    }

    $cached = @(git diff --cached --name-only | Where-Object { $_ } | Sort-Object -Unique)
    $cachedDifference = Compare-Object -ReferenceObject $required -DifferenceObject $cached
    if ($null -ne $cachedDifference) {
        throw "Task $TaskNumber cached set is not exact: $($cached -join ', ')"
    }
    if (@(git diff --name-only).Count -ne 0 -or @(git ls-files --others --exclude-standard).Count -ne 0) {
        throw "Task $TaskNumber has unstaged or untracked paths before commit"
    }

    git diff --cached --check
    if ($LASTEXITCODE -ne 0) {
        throw "Task $TaskNumber has cached whitespace errors; no commit was created"
    }
    $parent = (git rev-parse HEAD).Trim()
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        throw "Task $TaskNumber commit failed"
    }
    $script:TASK_SHA = (git rev-parse HEAD).Trim()
    $script:TASK_PARENT_SHA = $parent
    if ($script:TASK_SHA -notmatch '^[0-9a-f]{40}$' -or $script:TASK_PARENT_SHA -notmatch '^[0-9a-f]{40}$') {
        throw "Task $TaskNumber did not produce literal 40-hex commit identities"
    }

    $committed = @(git diff-tree --no-commit-id --name-only -r $script:TASK_SHA | Where-Object { $_ } | Sort-Object -Unique)
    $committedDifference = Compare-Object -ReferenceObject $required -DifferenceObject $committed
    if ($null -ne $committedDifference) {
        throw "Task $TaskNumber committed path set is not exact: $($committed -join ', ')"
    }
    if (@(git diff --name-only).Count -ne 0 -or @(git ls-files --others --exclude-standard).Count -ne 0 -or @(git diff --cached --name-only).Count -ne 0) {
        throw "Task $TaskNumber worktree is not clean after commit"
    }
    git diff --check "$script:TASK_PARENT_SHA..$script:TASK_SHA"
    if ($LASTEXITCODE -ne 0) {
        throw "Task $TaskNumber has whitespace errors"
    }
    Write-Output "TASK_SHA=$script:TASK_SHA"
    Write-Output "TASK_PARENT_SHA=$script:TASK_PARENT_SHA"
}
```

For every task, place the review package outside the worktree. It contains the immutable `TASK_SHA`, exact allowlist, focused RED log with each marker, minimum GREEN log, full 19-suite log, `git diff --check` result, and the two review reports. Each fresh Sol review reads that same immutable SHA and returns findings only. Luna applies any approved remediation in the task allowlist as a new focused commit, reruns focused and full tests, updates the package, and obtains both fresh Sol reviews against the new immutable SHA.

### Task 1: Template-Driven Retirement in GridTrackRuntime

**Files:**
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`

**Interfaces:**
- Consumes the existing `TrackCellSequence`, `TrackGeometryResolver`, `TrackGeometryPiece`, `RouteContactAnchor`, construction, recovery, and train-preparation APIs already used by `GridTrackRuntime`.
- Produces stable piece-aligned retirement, concrete endpoint-owner/support observations, and the runtime invariants consumed by later tasks. It produces no gesture lifecycle API and no `TrackSystem` capture behavior.

- [ ] **Step 1: Add the RED microcycles one at a time.** In `run()`, add each test call beside the existing runtime guards. Before each new behavior assertion print one exact marker: `Endpoint reshape: five straight records are not a generic horizon`, `Endpoint reshape: endpoint owner and incoming supports are concrete`, `Endpoint reshape: locked boundary downgrades the template`, `Endpoint reshape: construction completion does not lock`, and `Endpoint reshape: stable paths retire whole pieces`. The tests must assert that five straight records remain five straight owners without a count-based lock, that an editable endpoint reports its actual owner and the two immediately preceding straight support records, that a locked boundary selects the largest valid smaller template without moving the locked record, that completing construction leaves geometry unlocked, and that append, cancel, anchor, recovery, and prepare retire or lock only complete pieces while preserving ledger serial spans and exit-support serials.
- [ ] **Step 2: Run the focused RED.** Run `& 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way' --script res://tests/run_all.gd -- --suite=test_grid_track_runtime.gd`. Require nonzero exit and the changing `Endpoint reshape:` failure output for the new assertions; the existing L-shaped five-record guard remains a legacy GREEN guard and is not inverted.
- [ ] **Step 3: Implement the minimum GREEN in `grid_track_runtime.gd`.** Remove `_count_provisional_records`, `_earliest_provisional_piece`, the `provisional_count > 5` loop in `_stage_horizon`, and the corresponding five-count rejection in `_validate_candidate`. Add piece-aligned retirement that locks a whole endpoint-owner or incoming-support piece only when the stable append/cancel/anchor/recovery/prepare path requires retirement; preserve each piece's first and last serial and exit-support metadata. Keep construction completion independent from geometry locking. Discover the actual endpoint owner and concrete incoming support records from resolved piece ownership and the locked boundary; allow resolver downgrade when fewer supports remain. Do not add gesture begin, update, finalize, or abort methods here.
- [ ] **Step 4: Run the focused GREEN.** Repeat the focused command. Require exit code `0`, all five exact `Endpoint reshape:` markers, the legacy L-shaped `CURVE_3X3` five-record guard, and no anchored `ERROR:`.
- [ ] **Step 5: Run the full exact regression.** Run the shared full command exactly as written in Preflight. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`.
- [ ] **Step 6: Commit with exact paths.** Invoke `Complete-TaskCommit -TaskNumber 'T1' -RequiredPaths @('godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd','godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd') -Message 'feat: replace generic horizon with template-driven retirement'`. Record the emitted `TASK_SHA` and `TASK_PARENT_SHA` in the external review package.
- [ ] **Step 7: Obtain fresh reviews.** Give the immutable T1 SHA to a fresh `gpt-5.6-sol` specification reviewer for §§2, 3, 5.1, 5.2, 6, 10, and 11 items 1, 2, 17, then to a fresh `gpt-5.6-sol` quality reviewer for atomic stable paths, whole-piece ledger identity, and regression evidence. Luna alone remediates findings, if any, with the same allowlist and repeats Steps 4–7 against a new SHA.

### Task 2: Gesture Begin/Finalize Foundation and Pointer Frame

**Files:**
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd`

**Interfaces:**
- Consumes T1's endpoint owner/support facts and piece-aligned retirement.
- Produces runtime `gesture_begin`, `gesture_finalize`, `gesture_is_active`, `gesture_has_legal_operation`, detached origin observations, editable-span facts, deterministic straight/left/right targets, and construction/recovery deferral. It does not produce abort, live candidate publication, TrackSystem routing, train preparation, or session completion.

- [ ] **Step 1: Add each RED microcycle separately.** Print the exact markers `Endpoint reshape: gesture begin captures detached origin`, `Endpoint reshape: editable span has deterministic targets`, `Endpoint reshape: TrackInputFrame carries final pointer facts`, and `Endpoint reshape: active gesture defers construction and recovery`. Use dynamic contract checks before typed calls that would otherwise fail parsing: assert `runtime.has_method('gesture_begin')`, then invoke `runtime.call('gesture_begin', endpoint)` and inspect the returned value and detached origin observation. Assert the begin/finalize foundation captures route, inventory, pieces, ledger, recovery, construction, entry predecessor, and straight/left/right target endpoints; mutating returned observations cannot mutate runtime state. Construct `TrackInputFrame.new` with `current_pointer_cell` and `current_pointer_inside_grid` as the final two arguments and assert both fields. Execute only the T2-owned sequence `gesture_begin -> inspect detached origin/targets -> attempt construction/recovery over multiple ticks -> inspect unchanged authoritative route/build/recovery -> gesture_finalize`; assert no build rollback, build progress, refund, route change, or recovered-prefix resurrection before finalize. Do not call or test `gesture_update`, and do not add tests for abort, live candidates, TrackSystem routing, prepare, train, or session completion in this task.
- [ ] **Step 2: Run the focused RED.** Run the exact `run_all.gd -- --suite=test_grid_track_runtime.gd` and `run_all.gd -- --suite=test_track_system_reservation.gd` commands with the Godot executable and worktree path from Preflight. Require nonzero exit and changing `Endpoint reshape:` failures. A typed missing API is invalid RED evidence when its marker did not print; the dynamic `has_method` and `call` contract must print the marker first.
- [ ] **Step 3: Implement minimum GREEN.** Add the final constructor parameters and fields to `track_input_frame.gd`. In `grid_track_runtime.gd`, snapshot exact detached state at `gesture_begin`, discover the editable span and entry heading, calculate deterministic template target cells, mark runtime gesture-active, defer `advance_construction` and `recover_behind` while active, and discard only transient gesture state in `gesture_finalize`. Keep the committed route unchanged during this foundation task. Do not route any input through `TrackSystem`.
- [ ] **Step 4: Run focused GREEN.** Repeat both focused suite commands. Require exit code `0`, all four exact markers, detached mutation protection, final pointer facts, and no anchored `ERROR:`.
- [ ] **Step 5: Run the full exact regression.** Run the exact shared full command. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`.
- [ ] **Step 6: Commit with exact paths.** Invoke `Complete-TaskCommit -TaskNumber 'T2' -RequiredPaths @('godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd','godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd','godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd','godot-project-moe-rail-way/src/domain/track/track_input_frame.gd') -Message 'feat: add detached endpoint gesture foundation and pointer facts'` and record both emitted SHAs.
- [ ] **Step 7: Obtain fresh reviews.** Fresh Sol specification review checks §§3, 4.1, 4.2 foundation limits, 5.3, 6, and 11 supplemental contract coverage. Fresh Sol quality review checks typed constructor ordering, detached copies, deferral without rollback, and absence of forbidden abort/publication/routing behavior. Luna remediates only in this allowlist and repeats focused/full tests and both fresh reviews against the new SHA.

### Task 3: Atomic Live Candidates and Same-Gesture Reshaping

**Files:**
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd`

**Interfaces:**
- Consumes T2's detached gesture origin, editable span, deterministic target facts, pointer frame fields, and deferred construction/recovery.
- Produces `gesture_update` candidate staging, same-length serial-preserving span replacement, post-target extension, last-valid retention, candidate validation, and finalize-time retirement. TrackSystem remains untouched in this task.

- [ ] **Step 1: Add one RED microcycle per behavior.** Print exact markers before assertions: `Endpoint reshape: right left straight back preserves fixed prefix`, `Endpoint reshape: one gesture extends after selected target`, `Endpoint reshape: control cells are omitted`, `Endpoint reshape: target re-entry rebuilds from origin`, `Endpoint reshape: replacement preserves identity`, `Endpoint reshape: invalid bounds preserve last valid`, `Endpoint reshape: invalid overlap preserve last valid`, `Endpoint reshape: anchor-compatible downgrade preserves observations`, `Endpoint reshape: duplicate preserves last valid`, `Endpoint reshape: insufficient inventory preserves last valid`, `Endpoint reshape: empty departure and straight endpoints accept ordinary extension`, `Endpoint reshape: locked endpoint accepts only extension`, `Endpoint reshape: gesture rejects illegal starts`, and `Endpoint reshape: finalize applies retirement`. Each runtime API call is preceded by a dynamic `has_method` assertion and `call` for the contract marker when the method may be absent. Assert a right-to-left-to-straight-to-back sequence rebuilds from the origin with unchanged fixed-prefix cells, serials, distances, states, pieces, and inventory; a held gesture appends only cells after the selected endpoint; intermediate target-crossing cells are not records; re-entry does not compose candidates; replacement keeps serial, distance, build state, and build identity; each bounds, overlap, duplicate, and inventory rejection separately preserves the complete detached last-valid record/piece/inventory/ledger/observation state; the anchor marker uses the same staged route to prove larger-template resolution without the authoritative anchor and deterministic resolver downgrade with that authoritative anchor while preserving anchors, inventory, ledger, observations, and all transaction invariants; ordinary gesture extension works from empty/departure and straight endpoints and after a locked endpoint; nonendpoint, outside, illegal-first-step, and insufficient-inventory starts reject; finalize retires only complete pieces. Do not inject resolver rejection or require artificial anchor-only failure; existing resolver downgrade and contact behavior remains authoritative.
- [ ] **Step 2: Run focused RED.** Run exact focused commands for `test_grid_track_runtime.gd` and `test_track_cell_sequence.gd`. Require nonzero exit with the changing markers. Preserve existing append tests as legacy GREEN guards; no legacy guard is made intentionally failing.
- [ ] **Step 3: Implement minimum GREEN.** Add `TrackCellSequence.replace_span_in_place(first_serial: int, last_serial: int, new_cells: Array[Vector2i]) -> bool` with equal span length, exact serial and nominal-distance retention, unchanged state/build progress, active-cell uniqueness, and no inventory charge. Add runtime candidate rebuilding from the origin: fixed prefix, selected complete template, valid post-target extension; use resolver bounds/footprint/overlap/downgrade/anchor/continuity rules; atomically commit only a fully valid candidate; leave the last valid candidate and every authoritative observation untouched on rejection. Allocate fresh monotonic serials for new suffix records, refund exactly one inventory cell per removed gesture-owned record, never reuse consumed serials, and defer piece retirement until finalize. Keep `TrackSystem` and input routing unchanged.
- [ ] **Step 4: Run focused GREEN.** Repeat focused runtime and sequence commands. Require exit code `0`, all new markers including `Endpoint reshape: anchor-compatible downgrade preserves observations`, legacy append guards, conservation, serial/distance/build identity, causal production-resolver anchor compatibility/downgrade evidence, and no anchored `ERROR:`.
- [ ] **Step 5: Run the full exact regression.** Run the exact shared full command. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`.
- [ ] **Step 6: Commit with exact paths.** Invoke `Complete-TaskCommit -TaskNumber 'T3' -RequiredPaths @('godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd','godot-project-moe-rail-way/tests/unit/test_track_cell_sequence.gd','godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd','godot-project-moe-rail-way/src/domain/track/track_cell_sequence.gd') -Message 'feat: publish atomic endpoint reshape candidates'` and record both emitted SHAs.
- [ ] **Step 7: Obtain fresh reviews.** Fresh Sol specification review checks §§4.2–4.4, 5.3, 6, 11 items 3–7, gesture-specific ordinary extension/rejection coverage, and causal production-resolver anchor compatibility/downgrade evidence. Fresh Sol quality review checks transaction isolation, no partial inventory/serial mutation, resolver ownership, and detached last-valid preservation. Luna alone remediates the allowlist, reruns focused/full tests, and obtains both fresh reviews against the new SHA.

### Task 4: Runtime Abort and Locked Geometry Safety

**Files:**
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`

**Interfaces:**
- Consumes T2's gesture origin and T3's live candidate transaction.
- Produces `gesture_abort` and the runtime-only active-state restoration contract. TrackSystem capture, input edges, preparation, train, and session behavior are not changed here.

- [ ] **Step 1: Add the RED microcycles.** Print `Endpoint reshape: abort restores exact origin` and `Endpoint reshape: locked and prepared geometry reject mutation`. Use dynamic `has_method('gesture_abort')` and `call('gesture_abort')` before typed assertions. Build a candidate with changed cells, serial observations, construction progress, ledger, recovery and anchor observations, abort it, and compare every field to the detached origin; assert only runtime gesture-active state is cleared. Attempt template mutation against locked geometry and already-train-prepared geometry and assert route cells, pieces, serials, distances, states, ledger, inventory, and observations remain byte-for-byte equivalent.
- [ ] **Step 2: Run focused RED.** Run the exact `test_grid_track_runtime.gd` suite command. Require nonzero exit and both changing markers. Do not test TrackSystem capture or right-edge consumption.
- [ ] **Step 3: Implement minimum GREEN.** Add `gesture_abort` to restore the complete origin snapshot through the existing sequence/piece/ledger/recovery/anchor replacement paths, then clear only transient gesture-active data. Make candidate template mutation reject any locked owner, locked boundary, or train-prepared piece without moving or resizing it. Do not call or edit TrackSystem.
- [ ] **Step 4: Run focused GREEN.** Repeat the exact runtime suite command. Require exit code `0`, both markers, exact origin equality, locked/prepared immutability, and no anchored `ERROR:`.
- [ ] **Step 5: Run the full exact regression.** Run the exact shared full command. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`.
- [ ] **Step 6: Commit with exact paths.** Invoke `Complete-TaskCommit -TaskNumber 'T4' -RequiredPaths @('godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd','godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd') -Message 'feat: restore exact gesture origin on runtime abort'` and record both emitted SHAs.
- [ ] **Step 7: Obtain fresh reviews.** Fresh Sol specification review checks §7, §5.4 locked geometry, and 11 items 8 and 12. Fresh Sol quality review checks complete-state restoration, no collateral state clearing, locked-piece identity, and the absence of TrackSystem behavior. Luna remediates only the allowlist, reruns focused/full tests, and obtains both fresh reviews against the new SHA.

### Task 5: TrackSystem Capture and Right-Press Routing

**Files:**
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_system.gd`

**Interfaces:**
- Consumes T2 begin/finalize foundation, T3 live update/finalize, and T4 runtime abort.
- Produces endpoint-only fresh capture, active-gesture right-abort precedence, release finalization, and facade capture state used by T6. It does not prepare geometry or own train/session behavior.

- [ ] **Step 1: Add the RED microcycles.** Print `Endpoint reshape: fresh capture is endpoint-only`, `Endpoint reshape: active right abort consumes edge`, `Endpoint reshape: facade clears capture after runtime abort`, `Endpoint reshape: held input waits for release and fresh press`, and `Endpoint reshape: left release finalizes`. Assert a left press captures only at the active endpoint and only when runtime reports a legal operation; a nonendpoint press discards crossed cells; active right press calls runtime abort before ordinary cancellation and returns consumed; runtime abort leaves the facade inactive; held input after completion, rejection, or abort cannot restart capture until release then fresh press; release finalizes once and clears capture. Keep ordinary right-click ghost suffix cancellation as a legacy GREEN guard.
- [ ] **Step 2: Run focused RED.** Run the exact `run_all.gd -- --suite=test_track_system_reservation.gd` command. Require nonzero exit and all changing markers. Do not add prepare, train, session, or snapshot assertions.
- [ ] **Step 3: Implement minimum GREEN.** In `track_system.gd`, route a right edge first to `gesture_abort` when both facade capture and runtime active are true, consume the edge, and skip ordinary cancellation. Otherwise preserve ordinary clicked-cell suffix cancellation. Start only on a fresh endpoint press with `gesture_has_legal_operation`, route current pointer/crossed cells to `gesture_update` while active, call `gesture_finalize` on left release, and refuse a held restart until a release edge occurs. Expose only the capture/runtime-active facts needed by T6; do not add preparation or session calls.
- [ ] **Step 4: Run focused GREEN.** Repeat the exact reservation suite command. Require exit code `0`, all five markers, legacy ordinary cancellation GREEN, consumed right edge, fresh-press gating, and no anchored `ERROR:`.
- [ ] **Step 5: Run the full exact regression.** Run the exact shared full command. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`.
- [ ] **Step 6: Commit with exact paths.** Invoke `Complete-TaskCommit -TaskNumber 'T5' -RequiredPaths @('godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd','godot-project-moe-rail-way/src/domain/track/track_system.gd') -Message 'feat: route endpoint capture and gesture abort precedence'` and record both emitted SHAs.
- [ ] **Step 7: Obtain fresh reviews.** Fresh Sol specification review checks §§4.1, 7, 9 steps 1–5, and 11 items 9–10. Fresh Sol quality review checks edge consumption, right-abort precedence, held-button state, and facade/runtime separation. Luna remediates only the allowlist, reruns focused/full tests, and obtains both fresh reviews against the new SHA.

### Task 6: Train-Safety Termination, Session Ordering, and Detached Snapshot Facts

**Files:**
- Modify: `godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd`
- Modify: `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- Modify: `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- Modify: `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`

**Interfaces:**
- Consumes T3 live candidates, T4 abort/restoration, and T5 capture routing.
- Produces train-preparation termination, facade prepare-result/capture clearing, exact input and session ordering, and detached snapshot endpoint-gesture eligibility/active facts. Define the snapshot constructor additions as final `endpoint_gesture_eligible_value: bool` and `endpoint_gesture_active_value: bool`, with getters `is_endpoint_gesture_eligible()` and `is_endpoint_gesture_active()`; both session suites test constructor detachment and getters.

- [ ] **Step 1: Add exact RED microcycles in the assigned suites.** Print `Endpoint reshape: replacement overlap terminates last valid`, `Endpoint reshape: extension overlap terminates last valid`, `Endpoint reshape: nonoverlap remains active`, `Endpoint reshape: prepare true returns true and clears capture`, `Endpoint reshape: prepare false returns false and clears capture`, `Endpoint reshape: held motion waits for release after termination`, `Endpoint reshape: deferred construction and recovery resume`, `Endpoint reshape: session tick and completion order`, `Endpoint reshape: snapshot detaches endpoint gesture facts`, and `Endpoint reshape: train session snapshot detaches endpoint gesture facts`. Use dynamic `has_method` and `call` for runtime and facade contracts before typed calls. For each prepare case record `was_active`, the runtime's original result, and `active_after`; assert capture clears iff `was_active && !active_after` regardless of the original result and that the facade returns the original result. Assert replacement-span overlap and extension-suffix overlap preserve the last valid candidate then terminate before locking; a nonoverlap candidate remains active. Assert construction and recovery are deferred during the active gesture and resume after termination. Assert right-abort, ordinary cancellation, fresh left, candidate update, release, construction, train preparation, train advance/sample, recovery, snapshot publication, and completion tie ordering. Assert both session suites construct snapshots with detached eligibility/active facts, mutate source values after construction, and receive unchanged getter values.
- [ ] **Step 2: Run focused RED.** Run the exact focused commands for all four assigned suites. Require nonzero exit and every changing marker. The contract test is invalid if a missing typed API prevents the marker; dynamic method discovery must be visible first.
- [ ] **Step 3: Implement minimum GREEN.** In runtime preparation, detect whether canonical current/prospective sampling intersects an active replacement span or extension suffix; preserve the last valid published candidate, terminate the gesture, and continue whole-piece preparation. In `TrackSystem.prepare_for_train_sampling`, capture `was_active`, call runtime preparation, read `active_after`, clear facade capture exactly when `was_active && !active_after`, and return the unmodified runtime result for both true and false. Ignore held motion until a release and fresh press. In `SessionController.advance_tick`, enforce right-abort priority, ordinary right fallback, fresh-left/update/release, construction, preparation, train movement, recovery, elapsed/completion ordering, and terminal snapshot before result. Add detached snapshot fields/getters and pass current TrackSystem facts from `_create_snapshot`.
- [ ] **Step 4: Run focused GREEN.** Repeat all four exact focused suite commands. Require exit code `0`, all markers, original prepare result preservation, correct capture clearing, deferred-work resumption, exact event ordering, detached getters in both session suites, and no anchored `ERROR:`.
- [ ] **Step 5: Run the full exact regression.** Run the exact shared full command. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`.
- [ ] **Step 6: Commit with exact paths.** Invoke `Complete-TaskCommit -TaskNumber 'T6' -RequiredPaths @('godot-project-moe-rail-way/tests/unit/test_grid_track_runtime.gd','godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd','godot-project-moe-rail-way/tests/unit/test_session_controller.gd','godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd','godot-project-moe-rail-way/src/domain/track/grid_track_runtime.gd','godot-project-moe-rail-way/src/domain/track/track_system.gd','godot-project-moe-rail-way/src/domain/session/session_controller.gd','godot-project-moe-rail-way/src/domain/session/session_snapshot.gd') -Message 'feat: terminate overlapping gestures before train sampling'` and record both emitted SHAs.
- [ ] **Step 7: Obtain fresh reviews.** Fresh Sol specification review checks §§5.4, 7, 9, 11 items 8, 11, 12, 17, and the snapshot contract table. Fresh Sol quality review checks the `was_active`/original-result/`active_after` contract, no double input consumption, completion ordering, train safety, and detached snapshots. Luna remediates only the allowlist, reruns focused/full tests, and obtains both fresh reviews against the new SHA.

### Task 7: Detached Hover Observations and End-to-End Input Evidence

**Files:**
- Modify: `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- Modify: `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- Modify: `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`

**Interfaces:**
- Consumes T6 detached `SessionSnapshot` endpoint-gateway facts and current pointer facts, plus authoritative rendered records/pieces and existing gold cancellation eligibility.
- Produces the current-pointer fields in `TrackFieldView.consume_input_frame` as the final `TrackInputFrame` constructor arguments, separate green/gold hover observations, view-local capture termination feedback, and drawing. The view does not recompute domain legality, mutate inventory, choose templates, or change global mouse mode.

- [ ] **Step 1: Add unit and integration RED assertions before view GREEN.** Add unit markers `Endpoint reshape: consume frame carries current pointer facts`, `Endpoint reshape: actionable endpoint is green`, `Endpoint reshape: green over gold retains cancellation`, `Endpoint reshape: outside, completion, and inactive clear hover`, `Endpoint reshape: snapshot termination clears view capture and buffer`, `Endpoint reshape: no-green negatives`, `Endpoint reshape: locked extendable endpoint is green`, `Endpoint reshape: no-operation endpoint is not green`, and `Endpoint reshape: whole suffix dependency is negative`; keep existing nonendpoint gold behavior as a legacy GREEN guard. The producer test must construct a frame through `TrackFieldView.consume_input_frame` and assert `current_pointer_cell` and `current_pointer_inside_grid` are supplied as the final two `TrackInputFrame.new` arguments. Add view-layer RED assertions that a presented snapshot transition from gesture-active to gesture-inactive after runtime abort, and the same transition after train-safety termination, clears local left capture, stale crossed-cell input, and pending press/release state; held motion remains ignored until release and a fresh press. Add integration assertions before any view GREEN claim for endpoint green, overlap green, abort capture clear, and train-preparation freeze; these four integration assertions are view-layer assertions and do not substitute for the already-green T5/T6 domain capture and preparation contracts. The integration runner must print exact changing failure markers after those assertions exist: `Endpoint reshape integration assertion failed endpoint green`, `Endpoint reshape integration assertion failed overlap endpoint green`, `Endpoint reshape integration assertion failed abort clears capture`, and `Endpoint reshape integration assertion failed train preparation freezes overlap`.
- [ ] **Step 2: Run focused RED.** Run the exact `test_track_field_view_input.gd` suite command and the standalone integration command below. Require each relevant process to be nonzero with its exact changing failure marker after assertions are present; missing markers make RED invalid. No view GREEN is claimed from a missing assertion.

```powershell
& 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'D:\godot\MoeRailWay-worktrees\feature-endpoint-track-reshaping\godot-project-moe-rail-way' --script res://tests/integration/run_track_train_input_integration.gd
```

- [ ] **Step 3: Implement minimum GREEN.** Change `TrackFieldView.consume_input_frame` so its `TrackInputFrame.new` call supplies `current_pointer_cell` and `current_pointer_inside_grid` as the final two constructor arguments, and add the producer assertion's exact marker. Add `_hover_extend_cell` and publish it beside `_hover_cancel_cell`. Derive green solely from detached snapshot eligibility, active endpoint, current pointer cell/inside-grid fact, session state, and the presented endpoint; derive gold from existing cancelable suffix facts. In `TrackFieldView.present` and `TrackFieldView.consume_input_frame`, detect snapshot gesture-active true-to-false transitions caused by abort or train-safety termination and clear local left capture, stale crossed-cell input, and pending press/release state; completion clears the same state. Held motion remains ignored until release followed by a fresh press. Clear both hover observations on outside-grid, inactive, and completion. Draw gold first and green second so green wins only visual priority while right-click eligibility remains. Keep running-state endpoint green, permit a locked endpoint with a legal adjacent extension, reject arbitrary empty/built/locked/train-occupied/nonendpoint cells, reject no-operation endpoints and whole-suffix dependency cases, and preserve the existing nonendpoint gold guard. Add the four exact success prints after successful view-layer integration assertions: `PASS: Endpoint reshape integration running endpoint green`, `PASS: Endpoint reshape integration overlap endpoint green`, `PASS: Endpoint reshape integration abort clears capture`, and `PASS: Endpoint reshape integration train preparation freezes overlap`. Retain the exact legacy `PASS: track train input integration` print and do not add global mouse-mode or domain legality code.
- [ ] **Step 4: Run focused GREEN.** Run the exact view suite and standalone integration command. Require exit code `0`, every new unit marker, all four exact endpoint integration PASS markers, exact `PASS: track train input integration`, and no anchored `ERROR:`.
- [ ] **Step 5: Run the full exact regression.** Run the exact shared full command. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, and no anchored `ERROR:`. Then rerun standalone integration and require all four new PASS lines plus the legacy PASS line and no anchored `ERROR:`.
- [ ] **Step 6: Commit with exact paths.** Invoke `Complete-TaskCommit -TaskNumber 'T7' -RequiredPaths @('godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd','godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd','godot-project-moe-rail-way/src/presentation/track/track_field_view.gd') -Message 'feat: render endpoint extend and cancel hover observations'` and record both emitted SHAs.
- [ ] **Step 7: Obtain fresh reviews.** Fresh Sol specification review checks §8, §10 TrackFieldView responsibilities, 11 items 13–17, and the four integration PASS outputs. Fresh Sol quality review checks detached-only presentation logic, green-over-gold ordering, all negative cases, no global mouse mode, and clean diagnostics. Luna remediates only the allowlist, reruns focused/full/integration gates, and obtains both fresh reviews against the new SHA.

## Canonical Design Evidence Map

The following map ties every required §11 evidence item to its owning implementation task. The numbered automated evidence items are not moved between owners.

| Design evidence | Owner | Required proof |
| --- | --- | --- |
| 1 | T1 new | Five straight records do not trigger a generic horizon. |
| 2 | T1 legacy | An actual five-record L-shaped route remains one nominal-length-five `CURVE_3X3`. |
| 3–7 | T3 | Reshape alternatives, same-gesture extension, control-cell omission, origin rebuild, independent bounds/overlap/duplicate/inventory last-valid preservation, and causal production-resolver anchor compatibility/downgrade preservation. |
| 8 | T4 | Right-abort restores exact origin state and clears only runtime gesture state. |
| 9 | T5 | Abort consumes the right edge, clears capture, and requires a fresh press. |
| 10 | T5 legacy | Ordinary right-click ghost suffix cancellation remains unchanged with no gesture active. |
| 11 | T6 | Train preparation terminates overlapping candidates before sampling and held motion cannot mutate them. |
| 12 | T4 locked plus T6 train overlap | Locked/prepared geometry cannot mutate; train overlap freezes the last valid candidate. |
| 13–16 | T7 | Running endpoint green, gold cancellation, green-over-gold overlap, and outside/completion clearing plus all negatives. |
| 17 | Every task plus T7/final integration | Each task runs the full exact 19-suite regression; T7 and final evidence also run standalone integration. |

Supplemental contract and output evidence is separate from the numbered map:

| Contract/output | Owner | Exact evidence |
| --- | --- | --- |
| TrackInputFrame pointer contract | T2 | Final constructor arguments preserve `current_pointer_cell` and `current_pointer_inside_grid`. |
| TrackFieldView frame producer contract | T7 | `consume_input_frame` forwards current pointer cell and inside-grid state as the final two `TrackInputFrame.new` arguments. |
| Runtime begin/finalize contract | T2 | Dynamic `has_method`/`call` marker appears before typed assertions; origin and editable target facts are detached. |
| Runtime update/last-valid contract | T3 | Candidate publication is atomic and rejected updates leave every last-valid fact unchanged. |
| Runtime abort contract | T4 | Dynamic abort call restores origin and clears only active gesture state. |
| TrackSystem capture contract | T5 | Endpoint-only fresh capture, active-right precedence, release finalization, and held-until-release behavior. |
| Prepare return contract | T6 | `was_active`, runtime original result, `active_after`; clear capture iff `was_active && !active_after`, return original result for true and false. |
| SessionSnapshot contract in both session suites | T6 | Constructor copies endpoint eligibility/active facts and getters remain detached. |
| Integration output 1 | T7/final | `PASS: Endpoint reshape integration running endpoint green`. |
| Integration output 2 | T7/final | `PASS: Endpoint reshape integration overlap endpoint green`. |
| Integration output 3 | T7/final | `PASS: Endpoint reshape integration abort clears capture`. |
| Integration output 4 | T7/final | `PASS: Endpoint reshape integration train preparation freezes overlap`. |

## Manual Evidence Closure

After T7 implementation and reviews, Luna performs the eight separate Windows manual runs from design §12 using Godot `4.7.1.stable.official.a13da4feb`. A single screenshot never represents mutually exclusive lifecycle states; record separate runs for each of the eight scenarios. Before editing, capture the existing manual file's byte-for-byte SHA-256 as `$existingPrefixSha256` with `Get-FileHash`. Append exactly one new section whose first and last lines are the unique plain-text sentinels `ENDPOINT_RESHAPE_EVIDENCE_BEGIN` and `ENDPOINT_RESHAPE_EVIDENCE_END`, preserving every byte of the existing prefix. Between them, write exactly eight headings `### Run 1:` through `### Run 8:`. Each run has one `Implementation SHA:` line containing the literal 40-hex T7 implementation SHA, one `Godot:` line containing `4.7.1.stable.official.a13da4feb`, one `Timestamp:` line containing an ISO-8601 timestamp, one nonempty English `Observation:` line, and one `Result:` line containing `PASS` or `FAIL`. Use `apply_patch` only on `godot-project-moe-rail-way/tests/manual/track_train_windows.md`; do not edit the plan, code, or tests for evidence.

Use this executable validator after the append. It extracts only the bytes between the unique sentinels, checks that the existing prefix hash is unchanged, requires the begin and end sentinels exactly once with the end sentinel at EOF, checks eight numbered headings, the same literal implementation SHA exactly eight times, the exact Godot version exactly eight times, eight ISO timestamps, eight nonempty observations, eight results, and checks forbidden placeholder forms only in the extracted section. Existing arrows or other text in the pre-existing manual prefix are not inspected. Supply the actual T7 SHA captured in `$TASK_SHA` and the pre-append `$existingPrefixSha256`.

```powershell
function Assert-EndpointReshapeManualEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ImplementationSha,
        [Parameter(Mandatory = $true)][string]$ExpectedPrefixSha256
    )
    if ($ImplementationSha -notmatch '^[0-9a-f]{40}$') {
        throw 'The manual record requires a literal 40-hex implementation SHA'
    }
    if ($ExpectedPrefixSha256 -notmatch '^[0-9a-fA-F]{64}$') {
        throw 'The validator requires the pre-append prefix SHA-256'
    }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    $begin = 'ENDPOINT_RESHAPE_EVIDENCE_BEGIN'
    $end = 'ENDPOINT_RESHAPE_EVIDENCE_END'
    $beginMatches = [regex]::Matches($text, '(?m)^ENDPOINT_RESHAPE_EVIDENCE_BEGIN\r?$')
    $endMatches = [regex]::Matches($text, '(?m)^ENDPOINT_RESHAPE_EVIDENCE_END\r?$')
    if ($beginMatches.Count -ne 1 -or $endMatches.Count -ne 1) {
        throw 'The endpoint evidence section requires one begin and one end sentinel'
    }
    $beginMatch = $beginMatches[0]
    $endMatch = $endMatches[0]
    if ($endMatch.Index -le $beginMatch.Index) {
        throw 'The endpoint evidence sentinels are out of order'
    }
    $markerBytes = [Text.Encoding]::UTF8.GetBytes($begin)
    $markerIndex = -1
    for ($i = 0; $i -le $bytes.Length - $markerBytes.Length; $i++) {
        $matches = $true
        for ($j = 0; $j -lt $markerBytes.Length; $j++) {
            if ($bytes[$i + $j] -ne $markerBytes[$j]) {
                $matches = $false
                break
            }
        }
        if ($matches) {
            $markerIndex = $i
            break
        }
    }
    if ($markerIndex -lt 0) {
        throw 'The endpoint evidence begin sentinel has no byte position'
    }
    $prefixBytes = if ($markerIndex -eq 0) { [byte[]]@() } else { $bytes[0..($markerIndex - 1)] }
    $hash = [Security.Cryptography.SHA256]::Create()
    $actualPrefixSha256 = ([BitConverter]::ToString($hash.ComputeHash($prefixBytes))).Replace('-', '')
    $hash.Dispose()
    if ($actualPrefixSha256 -ine $ExpectedPrefixSha256) {
        throw 'The pre-existing manual prefix changed'
    }
    $afterEnd = $text.Substring($endMatch.Index + $endMatch.Length).Trim()
    if (-not [string]::IsNullOrEmpty($afterEnd)) {
        throw 'The endpoint evidence section must be the one final appended section'
    }
    $scopeStart = $beginMatch.Index + $beginMatch.Length
    $scope = $text.Substring($scopeStart, $endMatch.Index - $scopeStart)
    $headings = [regex]::Matches($scope, '(?m)^### Run ([1-8]):[^\r\n]*\r?$')
    if ($headings.Count -ne 8) {
        throw 'The manual record requires eight numbered run headings'
    }
    $headingNumbers = @($headings | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    if ($headingNumbers.Count -ne 8) {
        throw 'The manual record requires each run number from one through eight exactly once'
    }
    if (@([regex]::Matches($scope, [regex]::Escape($ImplementationSha))).Count -ne 8) {
        throw 'The implementation SHA must occur exactly eight times'
    }
    if (@([regex]::Matches($scope, [regex]::Escape('4.7.1.stable.official.a13da4feb'))).Count -ne 8) {
        throw 'The exact Godot version must occur exactly eight times'
    }
    if (@([regex]::Matches($scope, '(?m)^Timestamp: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\r?$')).Count -ne 8) {
        throw 'The manual record requires eight ISO timestamps'
    }
    if (@([regex]::Matches($scope, '(?m)^Observation: \S.*\r?$')).Count -ne 8) {
        throw 'The manual record requires eight nonempty observations'
    }
    if (@([regex]::Matches($scope, '(?m)^Result: (PASS|FAIL)\r?$')).Count -ne 8) {
        throw 'The manual record requires eight results'
    }
    if ($scope.IndexOf([char]60) -ge 0 -or $scope.IndexOf([char]62) -ge 0 -or $scope -match 'TODO|TBD|PLACEHOLDER') {
        throw 'The appended endpoint evidence contains a forbidden placeholder form'
    }
    Write-Output 'Manual endpoint reshape evidence validator: PASS'
}
```

Run both automated gates again after the evidence append: the exact 19-suite command and the standalone integration command. Require exit code `0`, exactly `PASS: 19 prototype test suite(s)`, all four endpoint integration PASS lines, exact `PASS: track train input integration`, and no anchored `ERROR:`. Commit the evidence file with exact-path staging and a focused evidence commit, then obtain fresh Sol specification and quality reviews against the evidence commit plus its parent. This evidence commit is separate from T7's implementation commit; the final handoff names both the durable implementation SHA and the evidence/feature HEAD.

## Final Self-Review and Handoff

- [ ] Confirm there are exactly seven `### Task` headings, each sequential and independently RED, minimum GREEN, full 19-suite regression, exact-path commit, fresh Sol specification review, and fresh Sol quality review.
- [ ] Confirm every listed path exists in the current repository and every task allowlist matches its required paths exactly; the manual record is changed only in the separate evidence closure.
- [ ] Confirm no task requires behavior owned by a later task: T1 has no gesture lifecycle, T2 has no abort/publication/routing, T3 has no facade routing, T4 has no capture, T5 has no train/session, T6 has no presentation, and T7 has no domain legality.
- [ ] Confirm all §11 map items, supplemental contracts, and four integration PASS outputs are represented.
- [ ] Confirm actionable implementation and manual-evidence content contains no placeholder-shaped text, forced branch deletion, or trailing whitespace. The validator's own pattern literals and this policy sentence are detection code, not evidence payload; inspect the extracted evidence section separately. Run `git diff --check` and report the changed plan path; do not commit this plan in this documentation task.
- [ ] Confirm final feature state is a clean feature/evidence HEAD with literal implementation and evidence SHAs and complete review logs. Do not claim integration.

Later work has five separate approval gates, with no commands in this plan: push the feature branch; open the pull request targeting `main`; merge with a merge commit; fast-forward and retest the primary `main`; remove the worktree nonforcefully, delete the local branch with `branch -d`, and delete the remote feature branch. These gates are not batched, and none is complete during this execution.
