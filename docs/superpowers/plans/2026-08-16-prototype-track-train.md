# Prototype Track and Train Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Execution boundary:** This plan is authored in a planning session. Do not create `proto/02-track-train`, modify Godot source, integrate `Prototyping`, create `prototype-m3`, or push while reviewing it. Execute it only in a separate development session after the user explicitly starts implementation.

**Goal:** Deliver `prototype-m3` as a Windows mouse-driven prototype in which one seeded departure point starts an untimed build phase, the player reserves one continuous route, physical track constructs at a fixed rate, and one nonstopping train consumes and recovers finite track until regular expiry or built-track-end failure.

**Architecture:** Keep `PrototypeApp` as the concrete composition root. Inspector-authored feature Resources are validated and copied into `SessionStartConfig`; editor-authored `Marker2D` candidates remain scene nodes. `TrackSystem`, `TrainSystem`, and `SessionController` are concrete `RefCounted` domain objects advanced by explicit fixed ticks, while `TrackFieldView` maps mouse input into immutable tick values and renders detached snapshots with primitive Godot drawing. No interface hierarchy, graph model, physics body, navigation layer, or production abstraction is introduced.

**Tech Stack:** Godot `4.7.1.stable.official.a13da4feb`, GDScript, Godot Resource and scene files, the existing native `SceneTree` test harness, PowerShell, Git

## Global Constraints

- The immutable code baseline is `4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97`, the approved track-and-train design commit on local `Prototyping`.
- The approved planning commit must be the one direct child of that code baseline, must change only this English plan and its Korean briefing, and must be the exact starting commit for `proto/02-track-train`.
- Create `proto/02-track-train` only in a new isolated worktree at `D:\godot\MoeRailWay-worktrees\proto-02-track-train` during the later development session.
- Never branch from `main` or `Development`. Never merge `Prototyping` wholesale into `Development`.
- Preserve the primary worktree's user-owned changes in `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd`, `godot-project-moe-rail-way/tests/support/prototype_test.gd`, and `docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md`. Do not stage, format, copy, reset, or absorb them.
- Do not modify `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd` or `godot-project-moe-rail-way/tests/support/prototype_test.gd` on the feature branch. Add task-owned assertions to new test files.
- Preserve the existing public compatibility surface used by the protected boot test: `PrototypeBalance.session_duration_seconds`, `PrototypeBalance.simulation_ticks_per_second`, `create_session_start_config(seed)`, `SessionStartConfig.new(seed, duration, ticks)`, and an out-of-tree composed controller in `READY`.
- Target Windows PC, mouse-only input, the existing `1280x720` logical viewport, and supported 16:9 windows from `960x540` through `1920x1080`. Mobile, touch, and gamepad remain deferred.
- Keep the existing `canvas_items` plus `expand` stretch settings, Forward Plus renderer, and D3D12 Windows driver.
- Use `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe` and require the exact version string `4.7.1.stable.official.a13da4feb`.
- Run Godot verification with normal access to `user://logs`. A logging-denial signal 11 is an environment failure, not proof of a project regression.
- Do not terminate or reconfigure a user-owned Godot or Steam editor process.
- Add no third-party add-ons, test frameworks, custom art, custom fonts, final audio, mobile behavior, touch behavior, or gamepad behavior.
- Use primitive `draw_polyline`, `draw_circle`, and `draw_colored_polygon` presentation only.
- Keep balance-sensitive values in the owning feature Resource. `PrototypeBalance` composes Resources and has no runtime-manager behavior.
- Keep candidate coordinates in `Marker2D` scene nodes. Do not store candidate positions in a manager or Resource array.
- Copy validated Resource and node values into `SessionStartConfig` before creating active domain objects. Domain code must never read Nodes or Resources.
- Keep logical geometry independent of viewport size and `UILayoutProfile`. UI padding and resizing may change only the uniform presentation transform and letterbox area.
- Use one ordered nonbranching polyline with monotonic absolute arc distance. Do not add a route graph, branches, merges, pathfinding, navigation, physics bodies, or multiple-train support.
- Left mouse draws only. Right mouse cancels reserved unbuilt route only in `proto/02`. Paid demolition, cash mutation, and grade-separated crossings remain absent until `proto/04-risk-investment`.
- Warps, cargo, hazards, durability, contracts, settlement, credit, and repeated operations remain outside this milestone.
- Do not use wall-clock APIs, `Timer`, `_process(delta)`, variable `delta`, or physics-signal order as domain truth. Tests and the app submit one explicit input value per fixed physics tick.
- Preserve exact fixed-tick ordering: right-click, left reservation, construction, departure transition, train movement, later movement hooks, recovery, later expiry hooks, running timer, end priority, detached snapshot, one result.
- Regular time expiry wins a same-tick tie with `TRACK_END_REACHED`.
- Keep implementation concrete. Do not add abstract bases, interfaces, a service locator, a global event bus, or generalized production seams.
- Every new tracked `.gd` file must have exactly one matching `.gd.uid` sidecar. Godot-serialized `.tscn`, `.tres`, `.gd.uid`, and project settings are covered by integration, validation, boot, UID, and diff gates rather than textual unit RED.
- Agent-facing Markdown remains English. Korean user-review documents remain under `docs/briefings/ko` and name this plan as their English source of truth.
- Merge, annotated tag creation, and remote push are three separate user approval gates. Approval of one never authorizes the next.

## Approved Defaults and Technical Constants

| Owner | Field | Default | Validation |
|---|---|---:|---|
| `SessionBalance` | `session_duration_seconds` | `180.0` | `> 0.0` |
| `SessionBalance` | `simulation_ticks_per_second` | `60` | `1..240` |
| `TrainBalance` | `speed_units_per_second` | `60.0` | `> 0.0` |
| `TrackInventoryBalance` | `total_units` | `720.0` | `> 0.0` |
| `TrackInventoryBalance` | `recovery_distance_units` | `240.0` | `> 0.0` and `< total_units` |
| `TrackInventoryBalance` | `urgent_warning_seconds` | `3.0` | `> 0.0` |
| `TrackConstructionBalance` | `speed_units_per_second` | `120.0` | `> 0.0` |
| `TrackConstructionBalance` | `endpoint_grab_radius_units` | `24.0` | `> 0.0` |
| `TrackConstructionBalance` | `route_hit_radius_units` | `16.0` | `> 0.0` |
| `TrackConstructionBalance` | `minimum_sample_distance_units` | `8.0` | `> 0.0` and `<= endpoint_grab_radius_units` |
| `TrackConstructionBalance` | `intersection_clearance_units` | `4.0` | `> 0.0` and `<= minimum_sample_distance_units` |
| `DepartureBalance` | `required_built_units` | `360.0` | `> 0.0` and `<= total_units` |

Logical field presets:

| Preset | Size |
|---|---:|
| `COMPACT` | `900 x 420` |
| `STANDARD` | `1200 x 560` |
| `EXPANSIVE` | `1500 x 700` |
| `CUSTOM` | width `640..4000`, height `320..2160` |

The default preset is `STANDARD`. The input distances, candidate authoring positions, and `CUSTOM` bounds are first-implementation tuning values, not production invariants. `TrackSystem.GEOMETRY_EPSILON` is the single route-domain fixed value `0.0001`; Train, controller, route-domain tests, and hover tie-breaking reference that constant rather than defining balance data or independent route tolerances. Task 2's editor-layout comparisons may use Godot's `is_equal_approx` before TrackSystem exists.

At the default tick rate:

- construction advances `120 / 60 = 2` logical units per tick;
- the active train advances `60 / 60 = 1` logical unit per tick;
- departure begins at `360` built units;
- the free rear-retention window is `240` logical units;
- urgent warning begins at `3.0` estimated seconds to the built endpoint.

## Development Session Preflight

Run this block only after the user starts the separate development session and after the approved plan and briefing have been committed together. Each later command block is independent and redeclares its paths.

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailFeatureBranch = 'proto/02-track-train'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailMilestoneTwo = 'c93e1834da8fb38792048914120fe50f9f500cb4'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProtectedPaths = @(
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    'godot-project-moe-rail-way/tests/support/prototype_test.gd',
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
)
$MoeRailAllowedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailExpectedProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}

if (Test-Path -LiteralPath $MoeRailFeatureWorktree) {
    throw "Feature worktree already exists: $MoeRailFeatureWorktree"
}
git -C $MoeRailPrimary show-ref --verify --quiet "refs/heads/$MoeRailFeatureBranch"
$MoeRailBranchProbeExit = $LASTEXITCODE
if ($MoeRailBranchProbeExit -eq 0) {
    throw "$MoeRailFeatureBranch already exists; inspect it instead of recreating it."
} elseif ($MoeRailBranchProbeExit -ne 1) {
    throw 'Failed to inspect the feature branch ref.'
}

$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $MoeRailPrimaryBranch -ne 'Prototyping') {
    throw "Primary worktree must remain on Prototyping; found $MoeRailPrimaryBranch"
}
$MoeRailPrimaryStaged = @(git -C $MoeRailPrimary diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailPrimaryStaged.Count -ne 0) {
    $MoeRailPrimaryStaged
    throw 'Primary staging area must be empty.'
}
$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    @(Compare-Object $MoeRailAllowedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary user-owned status differs from the reviewed three-path state.'
}
$MoeRailProtectedHashes = [ordered]@{}
foreach ($MoeRailProtectedPath in $MoeRailProtectedPaths) {
    $MoeRailAbsoluteProtected = Join-Path $MoeRailPrimary $MoeRailProtectedPath
    if (-not (Test-Path -LiteralPath $MoeRailAbsoluteProtected -PathType Leaf)) {
        throw "Protected file is missing: $MoeRailProtectedPath"
    }
    $MoeRailProtectedHashes[$MoeRailProtectedPath] = (
        Get-FileHash -LiteralPath $MoeRailAbsoluteProtected -Algorithm SHA256
    ).Hash
    if ($MoeRailProtectedHashes[$MoeRailProtectedPath] -ne
        $MoeRailExpectedProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected file differs from the approved fingerprint: $MoeRailProtectedPath"
    }
}

$MoeRailTagCommitOutput = @(git -C $MoeRailPrimary rev-list -n 1 prototype-m2)
$MoeRailTagCommitExit = $LASTEXITCODE
$MoeRailTagCommit = ($MoeRailTagCommitOutput -join "`n").Trim()
$MoeRailRemotePrototypeRows = @(
    git -C $MoeRailPrimary ls-remote --heads origin refs/heads/Prototyping
)
$MoeRailRemotePrototypeExit = $LASTEXITCODE
$MoeRailRemotePrototype = if ($MoeRailRemotePrototypeRows.Count -eq 1) {
    ($MoeRailRemotePrototypeRows[0] -split "`t")[0]
} else {
    ''
}
$MoeRailCodeParentOutput = @(git -C $MoeRailPrimary rev-parse "$MoeRailCodeBase^")
$MoeRailCodeParentExit = $LASTEXITCODE
$MoeRailCodeParent = ($MoeRailCodeParentOutput -join "`n").Trim()
if ($MoeRailTagCommitExit -ne 0 -or
    $MoeRailRemotePrototypeExit -ne 0 -or
    $MoeRailRemotePrototypeRows.Count -ne 1 -or
    $MoeRailCodeParentExit -ne 0 -or
    $MoeRailTagCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailRemotePrototype -ne $MoeRailMilestoneTwo -or
    $MoeRailCodeParent -ne $MoeRailMilestoneTwo) {
    throw 'prototype-m2, origin/Prototyping, or the approved design ancestry changed.'
}

$MoeRailPlanCommit = (
    git -C $MoeRailPrimary log Prototyping -1 --format=%H -- $MoeRailPlanPath $MoeRailBriefPath
).Trim()
if ($LASTEXITCODE -ne 0 -or $MoeRailPlanCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'Could not resolve the approved planning commit.'
}
$MoeRailPlanParent = (git -C $MoeRailPrimary rev-parse "$MoeRailPlanCommit^").Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPlanParent -ne $MoeRailCodeBase -or
    $MoeRailPrimaryHead -ne $MoeRailPlanCommit) {
    throw 'The approved planning commit is not the sole child of the design baseline.'
}
$MoeRailExpectedPlanFiles = @($MoeRailPlanPath, $MoeRailBriefPath) | Sort-Object
$MoeRailActualPlanFiles = @(
    git -C $MoeRailPrimary diff-tree --no-commit-id --name-only -r $MoeRailPlanCommit |
        Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    @(Compare-Object $MoeRailExpectedPlanFiles $MoeRailActualPlanFiles).Count -ne 0) {
    $MoeRailActualPlanFiles
    throw 'The planning commit is not limited to the English plan and Korean briefing.'
}

git -C $MoeRailPrimary worktree add -b $MoeRailFeatureBranch `
    $MoeRailFeatureWorktree $MoeRailPlanCommit
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to create the isolated feature worktree.'
}
$MoeRailFeatureRoot = (git -C $MoeRailFeatureWorktree rev-parse --show-toplevel).Trim()
$MoeRailFeatureCurrentBranch = (git -C $MoeRailFeatureWorktree branch --show-current).Trim()
$MoeRailFeatureHead = (git -C $MoeRailFeatureWorktree rev-parse HEAD).Trim()
$MoeRailFeatureStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all
)
if ($LASTEXITCODE -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailFeatureRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailFeatureCurrentBranch -ne $MoeRailFeatureBranch -or
    $MoeRailFeatureHead -ne $MoeRailPlanCommit -or
    $MoeRailFeatureStatus.Count -ne 0) {
    $MoeRailFeatureStatus
    throw 'The feature worktree identity or initial state is invalid.'
}

$MoeRailVersionOutput = @(& $MoeRailGodotExe --version 2>&1)
$MoeRailVersionExit = $LASTEXITCODE
$MoeRailVersion = ($MoeRailVersionOutput -join "`n").Trim()
$MoeRailVersionOutput
if ($MoeRailVersionExit -ne 0 -or
    $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected Godot version: $MoeRailVersion"
}
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailUnitOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/run_all.gd' 2>&1
)
$MoeRailUnitExit = $LASTEXITCODE
$MoeRailUnitText = $MoeRailUnitOutput -join "`n"
$MoeRailUnitOutput
if ($MoeRailUnitExit -ne 0 -or
    [regex]::Matches($MoeRailUnitText, '(?m)^PASS: 6 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailUnitText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The prototype-m2 unit baseline did not pass exactly six suites.'
}
$MoeRailShellOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/integration/run_session_shell_integration.gd' 2>&1
)
$MoeRailShellExit = $LASTEXITCODE
$MoeRailShellText = $MoeRailShellOutput -join "`n"
$MoeRailShellOutput
foreach ($MoeRailMarker in @(
    'PASS: session shell layout integration',
    'PASS: session shell lifecycle integration'
)) {
    if ([regex]::Matches($MoeRailShellText, "(?m)^$([regex]::Escape($MoeRailMarker))\r?$").Count -ne 1) {
        throw "Missing baseline marker: $MoeRailMarker"
    }
}
if ($MoeRailShellExit -ne 0 -or
    $MoeRailShellText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The prototype-m2 integration baseline failed.'
}
$MoeRailBootOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject --quit-after 2 2>&1
)
$MoeRailBootExit = $LASTEXITCODE
$MoeRailBootText = $MoeRailBootOutput -join "`n"
$MoeRailBootOutput
if ($MoeRailBootExit -ne 0 -or
    [regex]::Matches(
        $MoeRailBootText,
        '(?m)^Moe Rail Way session shell ready \| duration=180 ticks=60\r?$'
    ).Count -ne 1 -or
    $MoeRailBootText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The prototype-m2 main-scene boot baseline failed.'
}
$MoeRailPostBaselineStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all
)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostBaselineStatus.Count -ne 0) {
    $MoeRailPostBaselineStatus
    throw 'Baseline verification changed the feature worktree.'
}
foreach ($MoeRailProtectedPath in $MoeRailProtectedPaths) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) `
            -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected primary file changed during preflight: $MoeRailProtectedPath"
    }
}
"PLAN_COMMIT=$MoeRailPlanCommit"
~~~

Expected:

- The feature worktree is clean on `proto/02-track-train` at the printed planning commit.
- The planning commit has parent `4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97` and contains exactly two planning documents.
- The Godot code baseline passes exactly six native suites, two session-shell integration markers, and one main-scene readiness marker.
- The three primary user-owned files retain their preflight SHA-256 values.

Initialize a task ledger in the feature worktree. Execute tasks serially with a fresh implementer and two-stage review when `superpowers:subagent-driven-development` is available. Otherwise use `superpowers:executing-plans` and preserve the same RED/GREEN, focused-commit, and independent-review gates.

## Domain and Data Contracts

### Route accounting

- Absolute route distance never resets when rear geometry is removed.
- `active_start_distance <= train_distance <= built_end_distance <= reserved_end_distance` while the train is active.
- `available_units + (reserved_end_distance - active_start_distance) = total_units` within the fixed technical epsilon.
- Reservation decreases `available_units` once. Construction only moves the built boundary and never charges inventory again.
- Cancellation and recovery each return their own removed length exactly once.
- The active route is one ordered `PackedVector2Array` with parallel monotonic absolute distances.
- Every scalar route boundary corresponds to a retained canonical point or a derived interpolated boundary point at that same absolute distance; construction may advance `built_end_distance` without materializing a new canonical route vertex.
- Segment cuts first snap an epsilon-near distance to one exact eligible canonical distance; otherwise they insert one interpolated point so accounting is independent of input sample length.
- `get_built_points()` returns the active start through the exact interpolated built boundary; `get_reserved_points()` returns that same boundary through the reserved endpoint. The two arrays share an equal boundary value but are independent copies, and each returns one point when its region length is zero.

### Input

- `TrackFieldView` stores event state; it never mutates domain state from `_gui_input`.
- One `TrackInputFrame` is consumed per physics tick.
- `cursor_position` is the latest held-pointer sample, while left-press and right-press positions plus their inside-field flags are immutable edge values until that tick is consumed.
- A left press starts a stroke only when its preserved press position is inside the logical field and within the endpoint-grab radius.
- A held stroke submits at most one logical sample per fixed tick.
- A right press targets its preserved press position, is edge-triggered, ends the active stroke, suppresses the held left button until a later release, and wins the same tick even when it changes no geometry.
- Viewport-to-logical conversion retains an unclamped logical cursor for a captured drag outside the logical rectangle. Starting in HUD or letterbox space remains noninteractive.

### Clipping and cancellation

- New reservation stops at the nearest positive limit among inventory exhaustion, field boundary, and intersection with active built or reserved geometry.
- Owned-endpoint adjacency is allowed; every other active-route contact is rejected at `intersection_clearance_units` before contact.
- Recovered coordinates are absent from intersection tests and may be reused.
- Right-click hit testing considers only reserved-unbuilt route at tick start.
- The closest Euclidean projection wins. A technical-epsilon tie selects the greatest absolute route distance and therefore the smaller canceled suffix.

### Construction, train, and recovery

- Construction advances by `construction_speed / ticks_per_second` through the retained reservation after right-click and left-input processing.
- `PREPARING_DEPARTURE` changes to `RUNNING` on the exact tick whose construction reaches `required_built_units`.
- That transition tick advances the train once and consumes one session-timer tick.
- The train clamps to built end and requests `TRACK_END_REACHED` when its movement reaches that end, even if reservation remains ahead.
- Recovery runs after train movement at `train_distance - recovery_distance_units`, removes partial segments, and exposes returned inventory only after the current tick's input step.
- Estimated track-end seconds are `(built_end_distance - train_distance) / train_speed_units_per_second` and ignore unbuilt reservation.

### Completion

- `start()` changes `READY` to `PREPARING_DEPARTURE` exactly once and publishes the full frozen timer.
- No timer tick is consumed during preparation before the departure threshold tick.
- Controller state changes to `COMPLETED` before the terminal snapshot signal so reentrant ticks are harmless.
- The terminal snapshot is emitted before one `SessionResult`.
- Regular expiry outranks track end only when both requests occur on the same tick.
- All post-completion input, ticks, result presentation, cancellation, construction, movement, and recovery are no-ops.

## Public Interfaces

Cross-script types use explicit preload constants rather than relying on an existing global class cache.

`SessionStartConfig` retains its three-argument constructor and adds optional copied feature values:

~~~gdscript
class_name SessionStartConfig
extends RefCounted

func _init(
    seed_value: int,
    duration_seconds: float,
    ticks_per_second: int,
    train_speed_value := 0.0,
    total_track_value := 0.0,
    recovery_distance_value := 0.0,
    urgent_warning_value := 0.0,
    construction_speed_value := 0.0,
    endpoint_grab_radius_value := 0.0,
    route_hit_radius_value := 0.0,
    minimum_sample_distance_value := 0.0,
    intersection_clearance_value := 0.0,
    departure_required_built_value := 0.0,
    logical_field_size_value := Vector2.ZERO,
    departure_candidate_id_value := StringName(),
    departure_position_value := Vector2.ZERO
) -> void
~~~

The public fields use these exact names: `seed`, `session_duration_seconds`, `simulation_ticks_per_second`, `train_speed_units_per_second`, `total_track_units`, `recovery_distance_units`, `urgent_warning_seconds`, `construction_speed_units_per_second`, `endpoint_grab_radius_units`, `route_hit_radius_units`, `minimum_sample_distance_units`, `intersection_clearance_units`, `departure_required_built_units`, `logical_field_size`, `departure_candidate_id`, and `departure_position`.

`PrototypeBalance` remains compatible with the protected boot test while delegating storage to feature Resources:

~~~gdscript
@export var session_balance: SessionBalanceScript
@export var train_balance: TrainBalanceScript
@export var track_inventory_balance: TrackInventoryBalanceScript
@export var track_construction_balance: TrackConstructionBalanceScript
@export var departure_balance: DepartureBalanceScript

var session_duration_seconds: float:
    get: return session_balance.session_duration_seconds
    set(value): session_balance.session_duration_seconds = value

var simulation_ticks_per_second: int:
    get: return session_balance.simulation_ticks_per_second
    set(value): session_balance.simulation_ticks_per_second = value

func create_session_start_config(seed_value: int) -> SessionStartConfigScript
func complete_session_start_config(
    base_config: SessionStartConfigScript,
    logical_field_size: Vector2,
    candidate_id: StringName,
    departure_position: Vector2
) -> SessionStartConfigScript
~~~

`complete_session_start_config` preserves the seed, duration, and tick rate returned by an overridden `create_session_start_config`, then copies every remaining feature value and spatial value. This is a narrow compatibility seam for the accepted prototype shell, not a production factory hierarchy.

`PrototypeApp` retains its accepted public composition fields and adds the two concrete domain owners:

~~~gdscript
var session_start_config: SessionStartConfigScript
var session_rng: SessionRngScript
var track_system: TrackSystemScript
var train_system: TrainSystemScript
var session_controller: SessionControllerScript

func compose_session_dependencies() -> PackedStringArray
~~~

All five fields are cleared before each composition attempt. Invalid composition leaves every domain field null.

`SessionRng` adds bounded consuming and non-consuming selection methods:

~~~gdscript
func next_index(exclusive_upper_bound: int) -> int
func peek_index(exclusive_upper_bound: int) -> int
~~~

Both methods return `-1` for a nonpositive bound without advancing the wrapped generator. For a positive bound, `next_index` uses `RandomNumberGenerator.randi_range(0, exclusive_upper_bound - 1)`. `peek_index` saves the wrapped generator state, calls `next_index` exactly once, restores that exact state, and returns the sampled index. Candidate records are sorted by `candidate_id` before `peek_index`; startup validation guarantees a positive record count before indexing, and `PrototypeApp` refuses a negative selection result defensively. This selects from the one existing seeded session RNG without consuming the accepted public sequence. There is no reroll, feasibility query, second RNG, or position correction.

`DepartureCandidate` and `LogicalTrackField`:

~~~gdscript
@tool
class_name DepartureCandidate
extends Marker2D
@export var candidate_id: StringName

@tool
class_name LogicalTrackField
extends Node2D

enum SizePreset { COMPACT, STANDARD, EXPANSIVE, CUSTOM }

@export var size_preset: SizePreset = SizePreset.STANDARD
@export_range(640.0, 4000.0, 1.0) var custom_width := 1200.0
@export_range(320.0, 2160.0, 1.0) var custom_height := 560.0

func get_logical_size() -> Vector2
func get_editor_boundary_rect() -> Rect2
func get_sorted_candidate_records() -> Array[Dictionary]
func validate_configuration() -> PackedStringArray
~~~

Every candidate record is a new Dictionary with exactly `candidate_id: StringName` and `position: Vector2`. Preset changes preserve `position / old_size`, update child positions to that normalized ratio in the new size, and queue an editor redraw.

`TrackInputFrame` is a concrete tick value:

~~~gdscript
class_name TrackInputFrame
extends RefCounted

var cursor_position: Vector2
var cursor_inside_field: bool
var left_press_position: Vector2
var left_press_inside_field: bool
var right_press_position: Vector2
var right_press_inside_field: bool
var left_pressed: bool
var left_held: bool
var left_released: bool
var right_pressed: bool

func _init(
    cursor_position_value := Vector2.ZERO,
    cursor_inside_field_value := false,
    left_pressed_value := false,
    left_held_value := false,
    left_released_value := false,
    right_pressed_value := false,
    left_press_position_value := Vector2.ZERO,
    left_press_inside_field_value := false,
    right_press_position_value := Vector2.ZERO,
    right_press_inside_field_value := false
) -> void

static func empty() -> TrackInputFrame
~~~

`TrackSystem` owns the ordered route and inventory:

~~~gdscript
class_name TrackSystem
extends RefCounted

const GEOMETRY_EPSILON := 0.0001

func _init(start_config: SessionStartConfigScript) -> void
func apply_right_input(input_frame: TrackInputFrameScript) -> bool
func apply_left_input(input_frame: TrackInputFrameScript) -> void
func advance_construction(distance_units: float) -> float
func recover_behind(cutoff_distance: float) -> float
func get_active_start_distance() -> float
func get_built_end_distance() -> float
func get_reserved_end_distance() -> float
func get_built_length() -> float
func get_available_units() -> float
func get_total_units() -> float
func get_reserved_endpoint() -> Vector2
func get_built_points() -> PackedVector2Array
func get_reserved_points() -> PackedVector2Array
func get_position_at_distance(route_distance: float) -> Vector2
func get_heading_at_distance(route_distance: float) -> Vector2
func is_stroke_active() -> bool
func is_waiting_for_left_release() -> bool
func is_conservation_valid() -> bool
~~~

`apply_right_input` returns `true` for every right-button press so the controller suppresses left input for that tick even when the click is a domain no-op.

At an exact interior vertex, `get_heading_at_distance` uses the first nonzero segment after that vertex. At the final retained endpoint it uses the preceding nonzero segment. A route containing only the departure point returns `Vector2.RIGHT` as a presentation-safe technical default.

`TrainSystem` owns one train:

~~~gdscript
class_name TrainSystem
extends RefCounted

func _init(speed_units_per_second: float) -> void
func depart(route_distance := 0.0) -> void
func advance_tick(
    track_system: TrackSystemScript,
    seconds_per_tick: float
) -> bool
func is_active() -> bool
func get_route_distance() -> float
func get_position(track_system: TrackSystemScript) -> Vector2
func get_heading(track_system: TrackSystemScript) -> Vector2
~~~

`advance_tick` returns `true` only when movement reaches the current built endpoint.

`TrackFieldView` remains a concrete `Control` embedded below `%Field`:

~~~gdscript
class_name TrackFieldView
extends Control

func get_logical_track_field() -> LogicalTrackFieldScript
func get_logical_content_rect() -> Rect2
func try_viewport_to_logical(viewport_position: Vector2) -> Variant
func viewport_to_logical_unclamped(viewport_position: Vector2) -> Vector2
func consume_input_frame() -> TrackInputFrameScript
func configure_session(start_config: SessionStartConfigScript) -> void
func present(snapshot: SessionSnapshotScript) -> void
func get_render_observation() -> Dictionary
~~~

`try_viewport_to_logical` returns `null` for HUD, letterbox, and outside points. `viewport_to_logical_unclamped` exists only for a drag already captured by this Control. `get_render_observation` returns copied logical geometry and scalar presentation values, never Node references or writable domain objects.

`SessionController` extends its existing public surface:

~~~gdscript
signal snapshot_published(snapshot: SessionSnapshotScript)
signal session_completed(result: SessionResultScript)

enum State { READY, PREPARING_DEPARTURE, RUNNING, COMPLETED }

func _init(
    start_config: SessionStartConfigScript,
    track_system: TrackSystemScript,
    train_system: TrainSystemScript
) -> void
func start() -> void
func advance_tick(input_frame: TrackInputFrameScript = null) -> void
func get_snapshot() -> SessionSnapshotScript
func get_state() -> State
~~~

`SessionResult.Reason` contains exactly `REGULAR_TIME_EXPIRED` and `TRACK_END_REACHED` in this milestone.

`SessionSnapshot` preserves its first four required constructor arguments and fixes every appended optional argument in this exact order:

~~~gdscript
func _init(
    total_ticks_value: int,
    elapsed_ticks_value: int,
    remaining_ticks_value: int,
    ticks_per_second_value: int,
    has_track_train_data_value: bool = false,
    state_value: int = 0,
    built_route_value: PackedVector2Array = PackedVector2Array(),
    reserved_route_value: PackedVector2Array = PackedVector2Array(),
    construction_head_value: Vector2 = Vector2.ZERO,
    train_active_value: bool = false,
    train_position_value: Vector2 = Vector2.ZERO,
    train_heading_value: Vector2 = Vector2.RIGHT,
    available_track_units_value: float = 0.0,
    total_track_units_value: float = 0.0,
    departure_built_units_value: float = 0.0,
    departure_required_units_value: float = 0.0,
    built_distance_ahead_value: float = 0.0,
    estimated_track_end_seconds_value: float = 0.0,
    track_end_warning_urgent_value: bool = false,
    selected_departure_candidate_id_value: StringName = StringName()
) -> void
~~~

Timer-only four-argument fixtures therefore set `has_track_train_data` to `false`; every snapshot created by the new three-dependency controller passes `true` plus every remaining value. The presence flag, not a numeric sentinel, controls gameplay HUD presentation. The class retains all existing timer getters and adds detached read-only getters:

~~~gdscript
func has_track_train_data() -> bool
func get_state() -> int
func get_built_route() -> PackedVector2Array
func get_reserved_route() -> PackedVector2Array
func get_construction_head() -> Vector2
func is_train_active() -> bool
func get_train_position() -> Vector2
func get_train_heading() -> Vector2
func get_available_track_units() -> float
func get_total_track_units() -> float
func get_departure_built_units() -> float
func get_departure_required_units() -> float
func get_built_distance_ahead() -> float
func get_estimated_track_end_seconds() -> float
func is_track_end_warning_urgent() -> bool
func get_selected_departure_candidate_id() -> StringName
~~~

Packed arrays are duplicated on construction and again on getter return.

`SessionShell` preserves its prototype-m2 methods and adds:

~~~gdscript
func configure(
    profile: UILayoutProfileScript,
    initial_snapshot: SessionSnapshotScript,
    start_config: SessionStartConfigScript = null
) -> void
func get_track_field_view() -> TrackFieldViewScript
func try_viewport_to_logical_field(viewport_position: Vector2) -> Variant
func consume_track_input_frame() -> TrackInputFrameScript
~~~

The old `try_viewport_to_field` remains pixel-local for prototype-m2 compatibility. New gameplay uses `try_viewport_to_logical_field`.

`SessionShell.get_track_field_view()` resolves the direct relative path `OuterMargin/MainColumn/Field/TrackFieldView` with `get_node_or_null` on every call. `TrackFieldView.get_logical_track_field()` likewise resolves its direct `LogicalTrackField` child with `get_node_or_null`. Neither accessor may depend on an `@onready` cache, so a freshly instantiated packed app or shell can compose and validate before entering the SceneTree.

## Target File Map

### Create

- `godot-project-moe-rail-way/src/config/session_balance.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/config/train_balance.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/config/track_inventory_balance.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/config/track_construction_balance.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/config/departure_balance.gd` and `.gd.uid`
- `godot-project-moe-rail-way/data/session_balance.tres`
- `godot-project-moe-rail-way/data/train_balance.tres`
- `godot-project-moe-rail-way/data/track_inventory_balance.tres`
- `godot-project-moe-rail-way/data/track_construction_balance.tres`
- `godot-project-moe-rail-way/data/departure_balance.tres`
- `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/domain/track/track_system.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/domain/train/train_system.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd` and `.gd.uid`
- `godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn`
- `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_track_train_config_validator.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_departure_selection.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_train_system.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/fixtures/short_session_values.tres`
- `godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres`
- `godot-project-moe-rail-way/tests/fixtures/invalid_track_train_balance.tres`
- `godot-project-moe-rail-way/tests/integration/nondefault_track_train_app.tscn`
- `godot-project-moe-rail-way/tests/integration/invalid_track_train_app.tscn`
- `godot-project-moe-rail-way/tests/manual/track_train_windows.md`

### Modify

- `godot-project-moe-rail-way/project.godot`
- `godot-project-moe-rail-way/tools/configure_project.gd`
- `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- `godot-project-moe-rail-way/data/prototype_balance.tres`
- `godot-project-moe-rail-way/src/domain/random/session_rng.gd`
- `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- `godot-project-moe-rail-way/src/app/prototype_app.gd`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- `godot-project-moe-rail-way/tests/run_all.gd`
- `godot-project-moe-rail-way/tests/unit/test_project_settings.gd`
- `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- `godot-project-moe-rail-way/tests/fixtures/short_session_balance.tres`

### Explicitly unchanged

- `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd`
- `godot-project-moe-rail-way/tests/support/prototype_test.gd`
- `godot-project-moe-rail-way/src/presentation/layout/*`
- `godot-project-moe-rail-way/data/ui_layout_profile.tres`
- `godot-project-moe-rail-way/src/presentation/theme/prototype_theme.tres`
- `godot-project-moe-rail-way/src/app/prototype_app.tscn`
- `godot-project-moe-rail-way/tests/manual/session_shell_windows.md`

---

### Task 1: Compose and Validate Feature Balance Resources

**Files:**

- Create `godot-project-moe-rail-way/src/config/session_balance.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/config/train_balance.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/config/track_inventory_balance.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/config/track_construction_balance.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/config/departure_balance.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/data/session_balance.tres`
- Create `godot-project-moe-rail-way/data/train_balance.tres`
- Create `godot-project-moe-rail-way/data/track_inventory_balance.tres`
- Create `godot-project-moe-rail-way/data/track_construction_balance.tres`
- Create `godot-project-moe-rail-way/data/departure_balance.tres`
- Create `godot-project-moe-rail-way/tests/fixtures/short_session_values.tres`
- Create `godot-project-moe-rail-way/tests/unit/test_track_train_config_validator.gd` and `.gd.uid`
- Modify `godot-project-moe-rail-way/src/config/prototype_balance.gd`
- Modify `godot-project-moe-rail-way/src/config/prototype_config_validator.gd`
- Modify `godot-project-moe-rail-way/data/prototype_balance.tres`
- Modify `godot-project-moe-rail-way/src/domain/session/session_start_config.gd`
- Modify `godot-project-moe-rail-way/tests/fixtures/short_session_balance.tres`
- Modify `godot-project-moe-rail-way/tests/run_all.gd`

**Interfaces:**

- Consumes: the existing three-argument `SessionStartConfig` construction and protected `PrototypeBalance` compatibility properties.
- Produces: the five feature Resources, exact field-level validation, a complete copied `SessionStartConfig`, and `PASS: 7 prototype test suite(s)`.

- [ ] **Step 1: Write the failing configuration suite and register it seventh**

Create the suite with concrete default, null, range, cross-field, compatibility, and copy-isolation checks:

In addition to the shown core assertions, prove that `train_balance.speed_units_per_second = 0.05` and `session_balance.session_duration_seconds = 1000000.0` both validate when all cross-field relationships are valid. Only the approved `> 0` and cross-field rules may reject these float balances; do not invent a hidden tuning range.

~~~gdscript
extends "res://tests/support/prototype_test.gd"

const SessionBalanceScript = preload("res://src/config/session_balance.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")


func run() -> PackedStringArray:
    var balance = PrototypeBalanceScript.new()
    assert_not_null(balance.session_balance, "SessionBalance must exist by default")
    assert_not_null(balance.train_balance, "TrainBalance must exist by default")
    assert_not_null(balance.track_inventory_balance, "TrackInventoryBalance must exist by default")
    assert_not_null(balance.track_construction_balance, "TrackConstructionBalance must exist by default")
    assert_not_null(balance.departure_balance, "DepartureBalance must exist by default")
    assert_equal(ValidatorScript.validate(balance).size(), 0, "Approved defaults must validate")
    assert_equal(balance.session_duration_seconds, 180.0, "Legacy duration getter must delegate")
    assert_equal(balance.simulation_ticks_per_second, 60, "Legacy tick getter must delegate")

    var missing = PrototypeBalanceScript.new()
    missing.track_construction_balance = null
    _assert_contains(
        ValidatorScript.validate(missing),
        "prototype_balance.track_construction_balance.resource",
        "Missing construction Resource must name its owner"
    )

    var invalid = PrototypeBalanceScript.new()
    invalid.track_inventory_balance.total_units = 720.0
    invalid.track_inventory_balance.recovery_distance_units = 720.0
    invalid.track_construction_balance.endpoint_grab_radius_units = 7.0
    invalid.track_construction_balance.minimum_sample_distance_units = 8.0
    invalid.track_construction_balance.intersection_clearance_units = 9.0
    invalid.departure_balance.required_built_units = 721.0
    var errors := ValidatorScript.validate(invalid)
    _assert_contains(errors, "recovery_distance_units", "Recovery cross-check must name its field")
    _assert_contains(errors, "minimum_sample_distance_units", "Sample cross-check must name its field")
    _assert_contains(errors, "intersection_clearance_units", "Clearance cross-check must name its field")
    _assert_contains(errors, "required_built_units", "Departure cross-check must name its field")

    balance.session_duration_seconds = 12.0
    balance.simulation_ticks_per_second = 30
    balance.train_balance.speed_units_per_second = 45.0
    balance.track_inventory_balance.total_units = 900.0
    var base_config = balance.create_session_start_config(77)
    var config = balance.complete_session_start_config(
        base_config,
        Vector2(1200.0, 560.0),
        &"departure_03",
        Vector2(984.0, 123.2)
    )
    assert_equal(config.seed, 77, "Completed config must preserve factory seed")
    assert_equal(config.session_duration_seconds, 12.0, "Completed config must preserve factory duration")
    assert_equal(config.simulation_ticks_per_second, 30, "Completed config must preserve factory tick rate")
    assert_equal(config.train_speed_units_per_second, 45.0, "Completed config must copy train speed")
    assert_equal(config.total_track_units, 900.0, "Completed config must copy inventory")
    assert_equal(config.departure_candidate_id, &"departure_03", "Completed config must copy candidate ID")
    assert_equal(config.departure_position, Vector2(984.0, 123.2), "Completed config must copy position")
    balance.train_balance.speed_units_per_second = 99.0
    assert_equal(config.train_speed_units_per_second, 45.0, "Active config must not reread Resources")
    return finish()


func _assert_contains(errors: PackedStringArray, fragment: String, message: String) -> void:
    var found := false
    for error_message in errors:
        found = found or error_message.contains(fragment)
    assert_true(found, message)
~~~

Append its preload to `SUITES` after `test_ui_layout_validator.gd`.

- [ ] **Step 2: Run the suite to verify the configuration RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/run_all.gd' 2>&1
)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -eq 0 -or
    $MoeRailText -notmatch 'res://src/config/session_balance\.gd') {
    throw 'Expected RED from the missing SessionBalance implementation.'
}
~~~

Expected: nonzero exit with the missing `res://src/config/session_balance.gd` path. A preload parse RED may occur before the runner prints `FAIL:`.

- [ ] **Step 3: Implement the five Resources, composition, validation, and copied values**

Use these exact Resource fields:

~~~gdscript
# session_balance.gd
class_name SessionBalance
extends Resource
@export var session_duration_seconds := 180.0
@export_range(1, 240, 1) var simulation_ticks_per_second := 60

# train_balance.gd
class_name TrainBalance
extends Resource
@export var speed_units_per_second := 60.0

# track_inventory_balance.gd
class_name TrackInventoryBalance
extends Resource
@export var total_units := 720.0
@export var recovery_distance_units := 240.0
@export var urgent_warning_seconds := 3.0

# track_construction_balance.gd
class_name TrackConstructionBalance
extends Resource
@export var speed_units_per_second := 120.0
@export var endpoint_grab_radius_units := 24.0
@export var route_hit_radius_units := 16.0
@export var minimum_sample_distance_units := 8.0
@export var intersection_clearance_units := 4.0

# departure_balance.gd
class_name DepartureBalance
extends Resource
@export var required_built_units := 360.0
~~~

Give each export a non-null `new()` default in `PrototypeBalance`, retain the two compatibility properties, keep `create_session_start_config(seed)` limited to the original seed/duration/tick contract, and create the complete value with:

~~~gdscript
func complete_session_start_config(
    base_config: SessionStartConfigScript,
    logical_field_size: Vector2,
    candidate_id: StringName,
    departure_position: Vector2
) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        base_config.seed,
        base_config.session_duration_seconds,
        base_config.simulation_ticks_per_second,
        train_balance.speed_units_per_second,
        track_inventory_balance.total_units,
        track_inventory_balance.recovery_distance_units,
        track_inventory_balance.urgent_warning_seconds,
        track_construction_balance.speed_units_per_second,
        track_construction_balance.endpoint_grab_radius_units,
        track_construction_balance.route_hit_radius_units,
        track_construction_balance.minimum_sample_distance_units,
        track_construction_balance.intersection_clearance_units,
        departure_balance.required_built_units,
        logical_field_size,
        candidate_id,
        departure_position
    )
~~~

`PrototypeConfigValidator.validate` must collect all errors rather than return after the first non-null Resource. Use owner-qualified messages and enforce every constraint in the defaults table. Keep the existing two legacy error fragments so `test_config_validator.gd` remains green.

Serialize each default in its own `.tres`, reference all five from `data/prototype_balance.tres`, and make `short_session_balance.tres` reference `short_session_values.tres` for only the two-second session override while sharing the default train, inventory, construction, and departure Resources.

- [ ] **Step 4: Run the configuration GREEN gate**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/run_all.gd' 2>&1
)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -ne 0 -or
    [regex]::Matches($MoeRailText, '(?m)^PASS: 7 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 1 did not pass exactly seven suites.'
}
~~~

- [ ] **Step 5: Commit only Task 1 files**

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/src/config/session_balance.gd',
    'godot-project-moe-rail-way/src/config/session_balance.gd.uid',
    'godot-project-moe-rail-way/src/config/train_balance.gd',
    'godot-project-moe-rail-way/src/config/train_balance.gd.uid',
    'godot-project-moe-rail-way/src/config/track_inventory_balance.gd',
    'godot-project-moe-rail-way/src/config/track_inventory_balance.gd.uid',
    'godot-project-moe-rail-way/src/config/track_construction_balance.gd',
    'godot-project-moe-rail-way/src/config/track_construction_balance.gd.uid',
    'godot-project-moe-rail-way/src/config/departure_balance.gd',
    'godot-project-moe-rail-way/src/config/departure_balance.gd.uid',
    'godot-project-moe-rail-way/data/session_balance.tres',
    'godot-project-moe-rail-way/data/train_balance.tres',
    'godot-project-moe-rail-way/data/track_inventory_balance.tres',
    'godot-project-moe-rail-way/data/track_construction_balance.tres',
    'godot-project-moe-rail-way/data/departure_balance.tres',
    'godot-project-moe-rail-way/tests/fixtures/short_session_values.tres',
    'godot-project-moe-rail-way/tests/unit/test_track_train_config_validator.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_config_validator.gd.uid',
    'godot-project-moe-rail-way/src/config/prototype_balance.gd',
    'godot-project-moe-rail-way/src/config/prototype_config_validator.gd',
    'godot-project-moe-rail-way/data/prototype_balance.tres',
    'godot-project-moe-rail-way/src/domain/session/session_start_config.gd',
    'godot-project-moe-rail-way/tests/fixtures/short_session_balance.tres',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
$MoeRailBefore = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailBefore.Count -ne 0) { throw 'Task 1 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 1 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if ($LASTEXITCODE -ne 0 -or
    @(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 1 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 1 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 1 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: add track and train balance resources'
if ($LASTEXITCODE -ne 0) { throw 'Task 1 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 1 did not leave a clean feature worktree.'
}
~~~

### Task 2: Author the Logical Field and Seeded Departure Candidates

**Files:**

- Create `godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn`
- Create `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/unit/test_departure_selection.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd` and `.gd.uid`
- Modify `godot-project-moe-rail-way/src/domain/random/session_rng.gd`
- Modify `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- Modify `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- Modify `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- Modify `godot-project-moe-rail-way/tests/run_all.gd`

**Interfaces:**

- Consumes: `SessionRng`, `%Field`, and the existing pixel-local `SessionShell.try_viewport_to_field` contract.
- Produces: eight editor-movable candidates, deterministic sorted selection data, logical presets and `CUSTOM`, editor boundary observation, uniform letterbox mapping, and `PASS: 8 prototype test suite(s)`.

- [ ] **Step 1: Write the departure and field RED suite**

The suite must load the real scene and prove defaults, sorting, seed stability, rescaling, and validation:

~~~gdscript
extends "res://tests/support/prototype_test.gd"

const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")


func run() -> PackedStringArray:
    var packed = load(FIELD_SCENE_PATH) as PackedScene
    assert_not_null(packed, "Logical field scene must load")
    if packed == null:
        return finish()
    var field = packed.instantiate()
    assert_equal(field.get_logical_size(), Vector2(1200.0, 560.0), "STANDARD must be default")
    assert_equal(field.get_editor_boundary_rect(), Rect2(Vector2.ZERO, Vector2(1200.0, 560.0)), "Editor boundary must match logical size")
    var records: Array[Dictionary] = field.get_sorted_candidate_records()
    assert_equal(records.size(), 8, "Default field must contain eight candidates")
    var expected_standard_positions := [
        Vector2(216.0, 123.2), Vector2(600.0, 100.8),
        Vector2(984.0, 123.2), Vector2(264.0, 280.0),
        Vector2(936.0, 280.0), Vector2(216.0, 436.8),
        Vector2(600.0, 459.2), Vector2(984.0, 436.8),
    ]
    for index in range(records.size()):
        assert_equal(
            records[index].candidate_id,
            StringName("departure_%02d" % (index + 1)),
            "Candidate records must sort by stable ID"
        )
        _assert_vector_close(
            records[index].position,
            expected_standard_positions[index],
            "Candidate STANDARD position must match its approved normalized default"
        )
    var first_id := _select_id(records, 9123)
    assert_equal(_select_id(records, 9123), first_id, "Equal seed and set must select equal ID")
    var moved_records := records.duplicate(true)
    moved_records[0].position += Vector2(20.0, 10.0)
    assert_equal(_select_id(moved_records, 9123), first_id, "Moving positions must not change selected ID")

    var peek_rng = SessionRngScript.new(9123)
    var consuming_rng = SessionRngScript.new(9123)
    var untouched_rng = SessionRngScript.new(9123)
    assert_equal(
        peek_rng.peek_index(records.size()),
        consuming_rng.next_index(records.size()),
        "Peek must return the same bounded sample as one consuming draw"
    )
    for sample_index in range(3):
        assert_equal(
            peek_rng.next_u32(),
            untouched_rng.next_u32(),
            "Peek must preserve the public RNG sequence at sample %d" % sample_index
        )

    for invalid_bound in [0, -3]:
        var invalid_next_rng = SessionRngScript.new(9123)
        var invalid_next_baseline = SessionRngScript.new(9123)
        assert_equal(invalid_next_rng.next_index(invalid_bound), -1, "Invalid next bound must reject")
        assert_equal(invalid_next_rng.next_u32(), invalid_next_baseline.next_u32(), "Rejected next bound must not consume RNG")
        var invalid_peek_rng = SessionRngScript.new(9123)
        var invalid_peek_baseline = SessionRngScript.new(9123)
        assert_equal(invalid_peek_rng.peek_index(invalid_bound), -1, "Invalid peek bound must reject")
        assert_equal(invalid_peek_rng.next_u32(), invalid_peek_baseline.next_u32(), "Rejected peek bound must not consume RNG")

    var before_positions := PackedVector2Array()
    for record in records:
        before_positions.append(record.position / Vector2(1200.0, 560.0))
    field.size_preset = field.SizePreset.EXPANSIVE
    var expanded: Array[Dictionary] = field.get_sorted_candidate_records()
    for index in range(expanded.size()):
        _assert_vector_close(
            expanded[index].position / Vector2(1500.0, 700.0),
            before_positions[index],
            "Preset change must preserve normalized candidate position"
        )

    field.size_preset = field.SizePreset.CUSTOM
    field.custom_width = 639.0
    field.custom_height = 319.0
    var custom_errors: PackedStringArray = field.validate_configuration()
    _assert_contains(custom_errors, "custom_width", "CUSTOM width below 640 must be rejected")
    _assert_contains(custom_errors, "custom_height", "CUSTOM height below 320 must be rejected")
    field.custom_width = 1200.0
    field.custom_height = 560.0

    var candidate_parent = field.get_node("DepartureCandidates")
    candidate_parent.get_child(1).candidate_id = candidate_parent.get_child(0).candidate_id
    _assert_contains(field.validate_configuration(), "candidate_id", "Duplicate ID must be rejected")
    candidate_parent.get_child(1).candidate_id = &"departure_02"
    candidate_parent.get_child(1).position = Vector2(-1.0, 10.0)
    _assert_contains(field.validate_configuration(), "position", "Out-of-bounds position must be rejected")
    candidate_parent.get_child(1).position = Vector2(600.0, 100.8)
    candidate_parent.get_child(1).candidate_id = StringName()
    _assert_contains(field.validate_configuration(), "candidate_id", "Empty ID must be rejected")

    var empty_field = packed.instantiate()
    var empty_parent = empty_field.get_node("DepartureCandidates")
    for child in empty_parent.get_children():
        empty_parent.remove_child(child)
        child.free()
    _assert_contains(
        empty_field.validate_configuration(),
        "DepartureCandidates",
        "A field with zero candidates must be rejected"
    )
    empty_field.free()
    field.free()
    return finish()


func _select_id(records: Array[Dictionary], seed_value: int) -> StringName:
    var rng = SessionRngScript.new(seed_value)
    return records[rng.peek_index(records.size())].candidate_id


func _assert_contains(errors: PackedStringArray, fragment: String, message: String) -> void:
    var found := false
    for error_message in errors:
        found = found or error_message.contains(fragment)
    assert_true(found, message)


func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
    assert_true(actual.is_equal_approx(expected), message)
~~~

Register it eighth in `tests/run_all.gd`.

- [ ] **Step 2: Run the departure suite to verify RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -eq 0 -or
    $MoeRailText -notmatch 'res://src/presentation/track/logical_track_field\.tscn') {
    throw 'Expected RED from the missing logical field scene.'
}
~~~

- [ ] **Step 3: Implement candidates, presets, editor redraw, and logical mapping**

Use these exact preset sizes and fresh record copies:

~~~gdscript
const PRESET_SIZES := {
    SizePreset.COMPACT: Vector2(900.0, 420.0),
    SizePreset.STANDARD: Vector2(1200.0, 560.0),
    SizePreset.EXPANSIVE: Vector2(1500.0, 700.0),
}

func get_logical_size() -> Vector2:
    if size_preset == SizePreset.CUSTOM:
        return Vector2(custom_width, custom_height)
    return PRESET_SIZES[size_preset]

func get_sorted_candidate_records() -> Array[Dictionary]:
    var records: Array[Dictionary] = []
    for child in $DepartureCandidates.get_children():
        if child is DepartureCandidateScript:
            records.append({
                "candidate_id": StringName(child.candidate_id),
                "position": Vector2(child.position),
            })
    records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return String(a.candidate_id) < String(b.candidate_id)
    )
    return records
~~~

The preset setter captures `old_size`, assigns the new enum, and rescales every candidate to `(old_position / old_size) * new_size` only after children exist. The custom-width and custom-height setters use the same rule. `get_editor_boundary_rect` returns `Rect2(Vector2.ZERO, get_logical_size())`; `_draw` draws that rectangle only when `Engine.is_editor_hint()`.

Candidate validation uses inclusive logical bounds: `0.0 <= position.x <= logical_size.x` and `0.0 <= position.y <= logical_size.y`. It must not use `Rect2.has_point`, whose end edges are excluded. Extend the RED suite to prove candidates exactly on each of the four boundary edges are accepted and coordinates beyond any edge are rejected.

The tracked scene contains `DepartureCandidates` with these provisional defaults from `docs/superpowers/specs/2026-08-16-prototype-track-train-design.md`; STANDARD coordinates equal normalized position multiplied by `1200 x 560`:

| ID | Normalized position | STANDARD position |
|---|---:|---:|
| `departure_01` | `(0.18, 0.22)` | `(216.0, 123.2)` |
| `departure_02` | `(0.50, 0.18)` | `(600.0, 100.8)` |
| `departure_03` | `(0.82, 0.22)` | `(984.0, 123.2)` |
| `departure_04` | `(0.22, 0.50)` | `(264.0, 280.0)` |
| `departure_05` | `(0.78, 0.50)` | `(936.0, 280.0)` |
| `departure_06` | `(0.18, 0.78)` | `(216.0, 436.8)` |
| `departure_07` | `(0.50, 0.82)` | `(600.0, 459.2)` |
| `departure_08` | `(0.82, 0.78)` | `(984.0, 436.8)` |

Before session configuration, `TrackFieldView` may use the live authored size for editor and isolated layout checks. It computes:

~~~gdscript
var logical_size := _get_mapping_logical_size()
var uniform_scale := min(size.x / logical_size.x, size.y / logical_size.y)
var content_size := logical_size * uniform_scale
var content_offset := (size - content_size) * 0.5
~~~

It applies that scale and offset to the `LogicalTrackField` child, returns a centered `Rect2` from `get_logical_content_rect`, maps content points to logical coordinates, and rejects letterbox points. Embed one `TrackFieldView` Control and one `LogicalTrackField` scene instance directly beneath `%Field`. Preserve `SessionShell.try_viewport_to_field`; add the new logical delegate.

Implement `TrackFieldView.configure_session` in this task as configuration-only behavior: copy logical size, selected candidate ID and position, route-hit radius, and warning threshold from the completed config; verify the copied logical size equals the authored field size; mark the view session-configured; hide every candidate authoring node at runtime; and queue a redraw. `_get_mapping_logical_size` returns the copied session size after that point and the live authored size only before configuration. Every configured content rectangle, input conversion, and later Task 8 drawing operation uses the copied size. `SessionShell.configure` calls it only when its optional start config is nonnull. Drawing and snapshot presentation remain Task 8, but Task 7 can safely pass the completed config through the already-real method.

Implement both bounded methods with an early `if exclusive_upper_bound <= 0: return -1` that does not touch `_rng`. For a positive bound, implement `SessionRng.next_index` with `randi_range(0, exclusive_upper_bound - 1)`. Implement `peek_index` by saving `_rng.state`, calling `next_index` once, restoring the saved state, and returning the sampled index; it must not create or seed another generator.

Create one runtime runner that verifies all four presets, letterbox rejection, uniform scale, and resize invariance. After configuring a session, mutate the underlying `LogicalTrackField` preset and `CUSTOM` dimensions and prove that the configured content rectangle and mapped logical endpoints do not change. Create one editor runner that requires `Engine.is_editor_hint()`, changes preset and `CUSTOM`, and verifies boundary rectangles and normalized candidate positions. Their exact success markers are:

~~~text
PASS: logical track field runtime integration
PASS: logical track field editor integration
~~~

Extend the accepted `run_session_shell_integration.gd` with an out-of-tree probe that instantiates the real shell packed scene without adding it to the SceneTree and requires `get_track_field_view()` plus the nested `get_logical_track_field()` to return the real children before `_ready`. Then assert that the in-tree shell owns exactly one `TrackFieldView`, its logical delegate maps a content point correctly, and its delegate rejects the internal letterbox. Preserve every existing assertion and both accepted markers.

- [ ] **Step 4: Run Task 2 GREEN gates**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailRuns = @(
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/run_all.gd'); Markers = @('PASS: 8 prototype test suite(s)') },
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_logical_track_field_integration.gd'); Markers = @('PASS: logical track field runtime integration') },
    @{ Args = @('--headless', '--editor', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_logical_track_field_editor_integration.gd'); Markers = @('PASS: logical track field editor integration') },
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_session_shell_integration.gd'); Markers = @('PASS: session shell layout integration', 'PASS: session shell lifecycle integration') }
)
foreach ($MoeRailRun in $MoeRailRuns) {
    [string[]]$MoeRailArguments = $MoeRailRun.Args
    $MoeRailOutput = @(& $MoeRailGodotExe @MoeRailArguments 2>&1)
    $MoeRailExit = $LASTEXITCODE
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    if ($MoeRailExit -ne 0 -or $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
        throw 'Task 2 runner failed.'
    }
    foreach ($MoeRailMarker in $MoeRailRun.Markers) {
        if ([regex]::Matches(
            $MoeRailText,
            "(?m)^$([regex]::Escape($MoeRailMarker))\r?$"
        ).Count -ne 1) {
            throw "Task 2 marker failed: $MoeRailMarker"
        }
    }
}
~~~

- [ ] **Step 5: Commit only Task 2 files**

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd',
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd.uid',
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd',
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd.uid',
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn',
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd.uid',
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd',
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd.uid',
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd.uid',
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd.uid',
    'godot-project-moe-rail-way/src/domain/random/session_rng.gd',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.tscn',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 2 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 2 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 2 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 2 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 2 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: add logical track field authoring'
if ($LASTEXITCODE -ne 0) { throw 'Task 2 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 2 did not leave a clean feature worktree.'
}
~~~

### Task 3: Implement Route Reservation, Clipping, and Free Cancellation

**Files:**

- Create `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/domain/track/track_system.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd` and `.gd.uid`
- Modify `godot-project-moe-rail-way/tests/run_all.gd`

**Interfaces:**

- Consumes: copied `SessionStartConfig` geometry and inventory fields plus one `TrackInputFrame` per tick.
- Produces: ordered absolute-distance route storage, immediate reservation charge, first-limit clipping, endpoint-only stroke state, deterministic reserved-suffix cancellation, and `PASS: 9 prototype test suite(s)`.

- [ ] **Step 1: Write and register the reservation RED suite**

Use a complete test config with a `1200x560` field, `100` inventory units, departure at `(100, 100)`, and the approved input radii. The test input helper copies the general cursor into the matching preserved edge position when `left_pressed` or `right_pressed` is true unless a test supplies an explicit distinct edge position. Include this exact baseline flow:

~~~gdscript
func _verify_reservation_and_cancel() -> void:
    var track = TrackSystemScript.new(_config(100.0))
    track.apply_left_input(_input(Vector2(100.0, 100.0), true, true, true, false, false))
    track.apply_left_input(_input(Vector2(140.0, 100.0), true, false, true, false, false))
    _assert_close(track.get_reserved_end_distance(), 40.0, "Drag must reserve exact length")
    _assert_close(track.get_available_units(), 60.0, "Reservation must charge immediately")
    assert_true(track.is_conservation_valid(), "Reservation must conserve inventory")

    var right_won := track.apply_right_input(
        _input(Vector2(125.0, 100.0), true, false, true, false, true)
    )
    assert_true(right_won, "Every right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 25.0, "Click projection must cut suffix")
    _assert_close(track.get_available_units(), 75.0, "Canceled suffix must refund once")
    assert_true(track.is_waiting_for_left_release(), "Right press must suppress held left")
    track.apply_left_input(_input(Vector2(150.0, 100.0), true, false, true, false, false))
    _assert_close(track.get_reserved_end_distance(), 25.0, "Held left must not resume after right press")
    track.apply_left_input(_input(Vector2.ZERO, false, false, false, true, false))
    assert_false(track.is_waiting_for_left_release(), "Later release must clear suppression")
~~~

Add separate functions that prove:

- a press more than `24` units from the endpoint is a no-op;
- an endpoint left press followed by far motion before one consume starts from the preserved press position and samples only the latest held cursor, while an off-endpoint press followed by motion onto the endpoint remains a no-op;
- a sample below `8` units is a no-op;
- inventory clips exactly without becoming negative;
- field exit clips at the first rectangle edge while keeping the stroke active;
- a reentered held stroke continues from the boundary endpoint;
- a square-closing self-intersection stops `4` units before contact;
- the owned endpoint is not treated as self-intersection;
- every retained reserved segment blocks crossing;
- closest projection wins, and equal-distance projections choose the greatest route distance;
- projections whose actual Euclidean distances differ by at most `GEOMETRY_EPSILON` choose the greatest route distance, while a difference greater than epsilon chooses the truly nearest projection;
- canceling at a canonical route vertex or at `vertex_distance +/- GEOMETRY_EPSILON / 2.0` snaps to that exact stored vertex distance, retains that vertex exactly once, refunds the exact suffix once, and lets the next append start from the same exact boundary;
- repeating cancellation after that snapped cut adds no further refund;
- a reserved-route right press followed by motion away before one consume cancels from the preserved right-press projection exactly once;
- empty or outside-radius right-clicks change no geometry but still end the stroke;
- a right press with no held or active left stroke allows the next fresh left press, while an active or simultaneously held left button remains suppressed until release;
- a buffered left release ends or clears suppression and returns before any same-frame left press edge can start a stroke;
- the active polyline remains continuous and conservation holds after every operation.

Register the suite ninth.

- [ ] **Step 2: Run the reservation suite to verify RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -eq 0 -or
    $MoeRailText -notmatch 'res://src/domain/track/track_system\.gd') {
    throw 'Expected RED from the missing TrackSystem implementation.'
}
~~~

- [ ] **Step 3: Implement the concrete input value and ordered route**

Store route points and parallel absolute distances. Initialize both arrays with the departure point at distance `0.0`; initialize `active_start`, `built_end`, and `reserved_end` to `0.0`; initialize `available_units` and `total_units` from the copied config.

The right-input gate is exact:

~~~gdscript
func apply_right_input(input_frame: TrackInputFrameScript) -> bool:
    if input_frame == null or not input_frame.right_pressed:
        return false
    var must_wait_for_left_release := (
        (_waiting_for_left_release and not input_frame.left_released)
        or (_stroke_active and not input_frame.left_released)
        or input_frame.left_held
    )
    _stroke_active = false
    _waiting_for_left_release = must_wait_for_left_release
    if not input_frame.right_press_inside_field:
        return true
    var cut_distance := _find_reserved_projection(input_frame.right_press_position)
    if is_nan(cut_distance):
        return true
    cut_distance = _canonicalize_route_distance(
        cut_distance,
        _built_end_distance,
        _reserved_end_distance
    )
    var refund := _reserved_end_distance - cut_distance
    _truncate_route_at(cut_distance)
    _reserved_end_distance = cut_distance
    _available_units += refund
    assert(_available_units <= _total_units + GEOMETRY_EPSILON)
    if absf(_available_units - _total_units) <= GEOMETRY_EPSILON:
        _available_units = _total_units
    _assert_invariants()
    return true
~~~

`_canonicalize_route_distance(value, minimum_allowed, maximum_allowed)` considers only canonical vertex distances inside the closed allowed interval. Among vertices within `GEOMETRY_EPSILON` of the value, it chooses the smallest absolute distance delta and breaks a numerically equal-delta tie toward the greatest route distance; it returns that exact stored distance, or the original value when none qualifies. Refund, scalar-boundary mutation, retained-point selection, and return values all use the normalized distance. `_truncate_route_at` reuses an exactly matched canonical vertex; otherwise it inserts exactly one interpolated terminal point inside the containing segment, and never leaves duplicate adjacent points or distances. Refund accounting uses exact addition plus the explicit over-total assertion above; do not saturate with `min`, because saturation would hide a double refund.

Left input first consumes a release and returns for that frame, then starts only on `left_pressed && left_press_inside_field && left_press_position.distance_to(endpoint) <= endpoint_grab_radius`. After a valid start, that same tick may sample the latest `cursor_position` once when `left_held && _stroke_active && !_waiting_for_left_release`; an invalid press never becomes valid merely because later motion reaches the endpoint. Use `cursor_inside_field` only for the latest held sample and check the raw sample distance before clipping.

For every candidate segment, compute a scalar accepted length from the endpoint:

~~~gdscript
var accepted_length := min(raw_length, _available_units)
accepted_length = min(accepted_length, _distance_to_first_field_exit(start, end))
var intersection_distance := _distance_to_first_active_intersection(start, end)
if not is_inf(intersection_distance):
    accepted_length = min(
        accepted_length,
        max(0.0, intersection_distance - _intersection_clearance_units)
    )
~~~

Reject lengths at or below the technical epsilon. Otherwise append exactly one endpoint at `start + direction * accepted_length`, append its absolute distance, decrement available units once, and assert continuity, monotonic distances, nonnegative inventory, and conservation.

Field clipping uses a segment-versus-axis-aligned-rectangle parameter calculation and returns the nearest forward edge. Intersection uses segment parameters, ignores only contact at the new segment's owned start with the final active segment, and finds the smallest positive new-segment distance across all active segments. Projection iterates only portions at or beyond `built_end_distance` and clamps the projection to each segment portion. Squared distances may identify the nearest candidate, but the epsilon tie is defined in linear units: compare `absf(sqrt(candidate_distance_squared) - sqrt(best_distance_squared)) <= GEOMETRY_EPSILON`, then choose the greatest route distance only inside that linear-distance tie.

- [ ] **Step 4: Run the reservation GREEN gate**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -ne 0 -or
    [regex]::Matches($MoeRailText, '(?m)^PASS: 9 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 3 did not pass exactly nine suites.'
}
~~~

- [ ] **Step 5: Commit only Task 3 files**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd',
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd.uid',
    'godot-project-moe-rail-way/src/domain/track/track_system.gd',
    'godot-project-moe-rail-way/src/domain/track/track_system.gd.uid',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd.uid',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 3 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 3 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 3 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 3 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 3 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: add track reservation domain'
if ($LASTEXITCODE -ne 0) { throw 'Task 3 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 3 did not leave a clean feature worktree.'
}
~~~

### Task 4: Advance Construction and Recover Rear Track

**Files:**

- Modify: `godot-project-moe-rail-way/src/domain/track/track_system.gd`
- Create: `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd`
- Create: `godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd.uid`
- Modify: `godot-project-moe-rail-way/tests/run_all.gd`

- [ ] **Step 1: Write the failing construction and recovery suite**

Create one test-local config helper and separate functions that prove:

- `advance_construction(2.0)` moves the built boundary by exactly `2` units at the default rate contract;
- when construction ends inside a segment, built and reserved getters both include the same exact interpolated boundary point while returning independently mutable copies;
- construction clamps at the current reserved endpoint and returns the actual constructed distance;
- releasing the draw button does not stop construction;
- reserving another endpoint while construction is in progress extends the same queue without resetting either absolute boundary;
- right-click cancellation is applied before construction, so a suffix removed at tick start cannot be built later in that tick;
- the retained built prefix and retained reserved suffix both remain intersection blockers;
- right-clicking built track or recovered space changes no geometry and returns no inventory;
- `recover_behind` cuts through a segment at the exact interpolated point, advances `active_start_distance`, and returns the exact partial length;
- a recovery cutoff exactly on a canonical vertex or at `vertex_distance + GEOMETRY_EPSILON / 2.0` normalizes backward to that exact stored distance before return, inventory, and active-start calculations, reuses the vertex once, and leaves no duplicate adjacent point or distance;
- with the preceding vertex farther than epsilon away, a cutoff at `vertex_distance - GEOMETRY_EPSILON / 2.0` remains at its raw interpolated cutoff and never recovers forward beyond that cutoff;
- a later recovery from that snapped boundary returns only the newly eligible distance;
- repeated recovery at the same or earlier cutoff returns `0` and changes no inventory;
- recovered coordinates are absent from future intersection tests and may be reserved again;
- available inventory increases once per recovered unit, never exceeds total, and remains conserved;
- absolute distances on the retained polyline never renormalize after recovery;
- construction and recovery are no-ops after no distance is eligible.

Make the suite's first check query `track.has_method("advance_construction")`. If absent, record `Construction must advance exactly 2 units per default tick` and return `finish()` before making the call. This makes RED identify the missing Task 4 surface rather than failing as an invalid method call.

Register this suite tenth in `tests/run_all.gd`.

- [ ] **Step 2: Run the construction/recovery suite to verify RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -eq 0 -or
    $MoeRailText -notmatch 'Construction must advance exactly 2 units per default tick') {
    throw 'Expected the construction/recovery contract to fail before implementation.'
}
~~~

- [ ] **Step 3: Implement explicit construction and idempotent recovery**

`advance_construction(distance_units)` rejects negative input, computes `min(distance_units, reserved_end - built_end)`, advances only `built_end_distance`, asserts invariants, and returns the actual advance. It does not mutate inventory or route vertices.

Region getters slice by absolute distance without mutating the canonical route. `get_built_points` begins at the retained active-start point and appends an interpolated `built_end_distance` point. `get_reserved_points` begins with a separately allocated copy of that identical built-boundary point and ends at `reserved_end_distance`. Avoid duplicate adjacent vertices when the boundary already equals a canonical vertex. A zero-length region returns its single boundary point; presentation skips polylines with fewer than two points.

`recover_behind(cutoff_distance)` first clamps the raw target to `[active_start_distance, min(cutoff_distance, built_end_distance)]`, then calls `_canonicalize_route_distance` with `[active_start_distance, raw_target]`. This upper bound permits snapping only backward to an already eligible canonical vertex and never forward past the recovery cutoff. If that normalized target is not strictly forward by more than the technical epsilon, return `0.0`. Otherwise:

1. locate the normalized target and reuse its exactly matched canonical vertex; otherwise compute exactly one interpolated retained start point inside the containing segment;
2. remove all route points strictly before the target;
3. retain or insert the target point exactly once with its unchanged absolute route distance, leaving no duplicate adjacent point or distance;
4. set `active_start_distance` to the target;
5. add only `target - old_active_start` to available inventory;
6. assert continuity, monotonic absolute distances, and conservation;
7. return the recovered length.

Recovery uses the same exact-add, over-total assertion, and within-epsilon snap-to-total rule as cancellation. It must never use a saturating `min` to conceal duplicate recovery.

Do not put recovery-delay policy in this class. The controller supplies `train_distance - recovery_distance_units` after train movement. The returned inventory is therefore unavailable to the input phase that already ran in the current tick and naturally becomes usable on the next tick.

- [ ] **Step 4: Run the construction/recovery GREEN gate**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -ne 0 -or
    [regex]::Matches($MoeRailText, '(?m)^PASS: 10 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 4 did not pass exactly ten suites.'
}
~~~

- [ ] **Step 5: Commit only Task 4 files**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/src/domain/track/track_system.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_construction_recovery.gd.uid',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 4 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 4 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 4 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 4 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 4 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: add track construction and recovery'
if ($LASTEXITCODE -ne 0) { throw 'Task 4 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 4 did not leave a clean feature worktree.'
}
~~~

### Task 5: Move One Nonstopping Train Along Built Track

**Files:**

- Create: `godot-project-moe-rail-way/src/domain/train/train_system.gd`
- Create: `godot-project-moe-rail-way/src/domain/train/train_system.gd.uid`
- Create: `godot-project-moe-rail-way/tests/unit/test_train_system.gd`
- Create: `godot-project-moe-rail-way/tests/unit/test_train_system.gd.uid`
- Modify: `godot-project-moe-rail-way/tests/run_all.gd`

- [ ] **Step 1: Write the failing train suite**

Create a route helper that reserves and constructs deterministic orthogonal segments. Add separate tests for:

- an inactive train remaining at departure and reporting no endpoint request;
- `depart(0.0)` activating exactly once;
- default speed advancing exactly `1` logical unit for `1 / 60` second;
- fractional movement crossing one or more route vertices without losing distance;
- exact interpolated position and normalized heading before, at, and after a corner;
- movement clamping to `built_end_distance` even when reserved-unbuilt route exists ahead;
- `advance_tick` returning `true` exactly when requested movement reaches the built endpoint;
- zero remaining built distance causing an immediate endpoint request on the first active tick;
- invalid speed, negative departure distance, nonpositive tick duration, and backward route access being rejected;
- getters exposing scalar or copied values only.

Register this suite eleventh.

- [ ] **Step 2: Run the train suite to verify RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -eq 0 -or
    $MoeRailText -notmatch 'res://src/domain/train/train_system\.gd') {
    throw 'Expected RED from the missing TrainSystem implementation.'
}
~~~

- [ ] **Step 3: Implement scalar arc-distance movement**

Keep only `_speed_units_per_second`, `_route_distance`, and `_active` as train state. `depart` validates its starting distance and is idempotent. `advance_tick` returns `false` while inactive, otherwise computes:

~~~gdscript
var requested_distance := _route_distance + _speed_units_per_second * seconds_per_tick
var built_end := track_system.get_built_end_distance()
if requested_distance + TrackSystemScript.GEOMETRY_EPSILON >= built_end:
    _route_distance = built_end
    return true
_route_distance = requested_distance
return false
~~~

Position and heading delegate to `TrackSystem` using the absolute distance. Do not add velocity integration, acceleration, braking, a `PathFollow2D`, a physics body, or a separate route cache.

- [ ] **Step 4: Run the train GREEN gate**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -ne 0 -or
    [regex]::Matches($MoeRailText, '(?m)^PASS: 11 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 5 did not pass exactly eleven suites.'
}
~~~

- [ ] **Step 5: Commit only Task 5 files**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/src/domain/train/train_system.gd',
    'godot-project-moe-rail-way/src/domain/train/train_system.gd.uid',
    'godot-project-moe-rail-way/tests/unit/test_train_system.gd',
    'godot-project-moe-rail-way/tests/unit/test_train_system.gd.uid',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 5 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 5 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 5 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 5 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 5 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: add fixed-speed train movement'
if ($LASTEXITCODE -ne 0) { throw 'Task 5 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 5 did not leave a clean feature worktree.'
}
~~~

### Task 6: Capture Mouse Input Once per Fixed Tick

**Files:**

- Modify: `godot-project-moe-rail-way/project.godot`
- Modify: `godot-project-moe-rail-way/tools/configure_project.gd`
- Modify: `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- Modify: `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- Modify: `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- Modify: `godot-project-moe-rail-way/tests/unit/test_project_settings.gd`
- Create: `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd`
- Create: `godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd.uid`
- Create: `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd`
- Create: `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd.uid`
- Modify: `godot-project-moe-rail-way/tests/run_all.gd`

- [ ] **Step 1: Write failing settings, adapter, and real-event tests**

Extend `test_project_settings.gd` to require exactly one left-mouse event on `track_draw` and exactly one right-mouse event on a new `track_cancel` action. It must reject swapped or extra mouse bindings while preserving every viewport, stretch, renderer, and driver assertion.

Create `test_track_field_view_input.gd` with direct `_gui_input` event delivery and explicit consumes. Prove:

- one left press produces one `left_pressed` edge and a persistent `left_held` state;
- a left press position and its inside-field flag survive multiple later motion events unchanged until consume, while `cursor_position` contains only the latest motion sample;
- mouse motion updates the logical cursor but does not enqueue multiple route samples;
- a second consume without new motion still represents held state once for that physics tick;
- release produces one `left_released` edge, clears held state, and then disappears;
- right press produces one `right_pressed` edge and never aliases left draw;
- a right press position and its inside-field flag survive later motion unchanged until consume;
- a press in logical content sets the matching press-inside flag, while HUD or letterbox positions cannot start capture; `cursor_inside_field` describes only the latest pointer sample;
- after a valid field press, motion outside the logical rectangle returns an unclamped logical cursor and `cursor_inside_field == false` so domain clipping can reach the first edge;
- resize changes only the uniform mapping and not the logical input value for the same normalized content point.
- a shell placed at a nonzero viewport offset converts `_gui_input`'s Control-local `event.position` through the view's canvas/global transform before logical mapping.

Create `run_track_train_input_integration.gd`. Instantiate the real shell scene, then guard `shell.has_method("consume_track_input_frame")` before delivering events. When the method is absent, print exactly `RED: SessionShell must expose consume_track_input_frame`, quit with code `1`, and return; no unrelated parse or runtime error may substitute for that sentinel. After the guard passes, configure the shell with the nondefault logical size, place it in a `1280x720` viewport, deliver actual `InputEventMouseButton` and `InputEventMouseMotion` objects through the viewport, wait for GUI dispatch, then consume only on explicit physics steps. Exercise an inside-field press away from the current endpoint and prove the route remains unchanged. In separate same-tick cases, deliver an endpoint left press followed by far motion and prove drawing starts at the original press, then deliver a reserved-route right press followed by motion away and prove cancellation uses the original right-click projection exactly once. Also exercise ordinary endpoint press-drag, multiple motion events before one tick, field exit, release, held-left suppression, fresh-left requirement, HUD click, letterbox click, and resize. Print exactly:

~~~text
PASS: track train input integration
~~~

Register the new unit suite twelfth.

- [ ] **Step 2: Run the input contracts to verify RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailUnitOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailUnitExit = $LASTEXITCODE
$MoeRailUnitText = $MoeRailUnitOutput -join "`n"
$MoeRailUnitOutput
if ($MoeRailUnitExit -eq 0 -or
    $MoeRailUnitText -notmatch 'track_cancel must bind the right mouse button') {
    throw 'Expected the missing right-mouse input contract to fail.'
}

$MoeRailIntegrationOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/integration/run_track_train_input_integration.gd' 2>&1
)
$MoeRailIntegrationExit = $LASTEXITCODE
$MoeRailIntegrationText = $MoeRailIntegrationOutput -join "`n"
$MoeRailIntegrationOutput
if ($MoeRailIntegrationExit -eq 0 -or
    [regex]::Matches(
        $MoeRailIntegrationText,
        '(?m)^RED: SessionShell must expose consume_track_input_frame\r?$'
    ).Count -ne 1) {
    throw 'Expected the real-event input integration to fail before implementation.'
}
~~~

- [ ] **Step 3: Add the right-button action through both settings paths**

Add `track_cancel` to `[input]` in `project.godot` with one `InputEventMouseButton` whose `button_index` is `2`. Extend `tools/configure_project.gd` to build the same right-click event and save it under `input/track_cancel`. Do not change the existing `track_draw` action or unrelated settings.

After the textual edit, run the configuration tool once to force Godot serialization, then inspect and keep only the intended `project.godot` and tool changes:

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tools/configure_project.gd' 2>&1
)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -ne 0 -or
    [regex]::Matches($MoeRailText, '(?m)^Project settings configured\r?$').Count -ne 1 -or
    $MoeRailText -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
    throw 'Project settings serialization failed.'
}
~~~

- [ ] **Step 4: Implement the concrete GUI event buffer**

Set `TrackFieldView.mouse_filter = Control.MOUSE_FILTER_STOP` in the scene. `_gui_input` may update only adapter fields: latest local cursor, the first unconsumed left-press local position, left release edge, held state, the first unconsumed right-press local position, and whether a left capture began in logical content. Later motion must never overwrite either stored edge position. It calls `accept_event()` only for handled left/right events in this Control.

`consume_input_frame()` separately transforms the latest cursor, preserved left-press position, and preserved right-press position with `get_global_transform_with_canvas() * local_position`, then maps each to logical coordinates and computes each matching inside-field flag. It creates one new `TrackInputFrame`, clears the consumed edge flags and edge positions, and retains held/capture state until release. For an active capture whose latest cursor is outside content, it uses the unclamped conversion; without capture, an outside latest cursor remains `cursor_inside_field == false`. A HUD or letterbox press remains invalid even if later motion enters the field. It does not call `TrackSystem`, use `Input.is_action_pressed`, read wall-clock time, or emit more than one logical held sample per consume.

`SessionShell.consume_track_input_frame()` delegates to the view. Existing shell layout mapping and the pixel-local `try_viewport_to_field` remain unchanged.

- [ ] **Step 5: Run the input GREEN gates**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailUnitOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailUnitExit = $LASTEXITCODE
$MoeRailUnitText = $MoeRailUnitOutput -join "`n"
$MoeRailUnitOutput
if ($MoeRailUnitExit -ne 0 -or
    [regex]::Matches($MoeRailUnitText, '(?m)^PASS: 12 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailUnitText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 6 did not pass exactly twelve suites.'
}
$MoeRailIntegrationOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/integration/run_track_train_input_integration.gd' 2>&1
)
$MoeRailIntegrationExit = $LASTEXITCODE
$MoeRailIntegrationText = $MoeRailIntegrationOutput -join "`n"
$MoeRailIntegrationOutput
if ($MoeRailIntegrationExit -ne 0 -or
    [regex]::Matches($MoeRailIntegrationText, '(?m)^PASS: track train input integration\r?$').Count -ne 1 -or
    $MoeRailIntegrationText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 6 input integration failed.'
}
~~~

- [ ] **Step 6: Commit only Task 6 files**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/project.godot',
    'godot-project-moe-rail-way/tools/configure_project.gd',
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.tscn',
    'godot-project-moe-rail-way/tests/unit/test_project_settings.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_field_view_input.gd.uid',
    'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd.uid',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 6 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 6 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 6 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 6 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 6 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: add deterministic track input adapter'
if ($LASTEXITCODE -ne 0) { throw 'Task 6 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 6 did not leave a clean feature worktree.'
}
~~~

### Task 7: Orchestrate Preparation, Running, Recovery, and Completion

**Files:**

- Modify: `godot-project-moe-rail-way/src/domain/session/session_controller.gd`
- Modify: `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd`
- Modify: `godot-project-moe-rail-way/src/domain/session/session_result.gd`
- Modify: `godot-project-moe-rail-way/src/app/prototype_app.gd`
- Modify: `godot-project-moe-rail-way/tests/unit/test_session_controller.gd`
- Create: `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd`
- Create: `godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd.uid`
- Modify: `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- Modify: `godot-project-moe-rail-way/tests/run_all.gd`

- [ ] **Step 1: Write the failing orchestration suite**

Do not modify `test_session_controller.gd` during RED. The old accepted suite must remain runnable against the old one-argument controller until the new surface exists.

Create `test_track_train_session_controller.gd` with test-local builders for config, route points, controller, and captured signals. Add separate functions that prove:

- a new controller is internally `READY`, `start()` enters `PREPARING_DEPARTURE`, and a second `start()` is a no-op;
- the initial preparation snapshot sets `has_track_train_data`, contains full time, the selected departure ID, zero built progress, total available inventory, and no active train;
- pre-start and post-completion ticks are no-ops;
- every preparation tick below threshold may reserve and construct but does not move the train or consume timer ticks;
- on the exact tick construction first reaches `departure_required_built_units`, state changes to `RUNNING`, the train advances once, and elapsed timer ticks become `1`;
- right-click runs before left reservation, construction runs after both, and a canceled suffix cannot be constructed in the same tick;
- construction before train movement may extend built end and prevent a track-end request on that tick;
- an earlier built-end request completes with `TRACK_END_REACHED` even when reservation remains unbuilt ahead;
- recovery occurs after movement, its inventory is visible in that tick's detached snapshot, and that returned amount can fund reservation only on the next tick;
- warning seconds use built distance ahead divided by configured train speed, exclude reserved route, and become urgent at or below the configured threshold;
- regular expiry completes normally and wins when it ties a track-end request on the same tick;
- state is already `COMPLETED` inside the terminal snapshot listener, that snapshot precedes exactly one result, and a reentrant tick cannot duplicate either;
- every published route array is detached both from later domain mutation and from mutation attempted through its getter;
- all post-completion right-click, left draw, construction, movement, recovery, timer, snapshot, and result behavior is inert.

Use the exact RED assertion message `A new session must begin in PREPARING_DEPARTURE`. Register the new suite thirteenth.

Make its first check query `SessionControllerScript.State.has("PREPARING_DEPARTURE")`. If absent, record that exact message and return `finish()` before constructing the three-dependency controller. This prevents the intended RED from being masked by an enum lookup or constructor-arity error.

- [ ] **Step 2: Run the controller contracts to verify RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailExit = $LASTEXITCODE
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailExit -eq 0 -or
    $MoeRailText -notmatch 'A new session must begin in PREPARING_DEPARTURE') {
    throw 'Expected the new preparation-state contract to fail.'
}
~~~

- [ ] **Step 3: Expand the detached snapshot and terminal result**

Implement the exact compatible `SessionSnapshot` constructor and presence getter from Public Interfaces. Existing four-argument shell fixtures must report `has_track_train_data() == false`; every new controller snapshot must pass `true` and every appended value explicitly. Duplicate both packed arrays on construction and on every getter return.

Add only `TRACK_END_REACHED` to `SessionResult.Reason`; retain its constructor and timer getters exactly. Results contain no cash, settlement, score, contract, restart, or replay data.

- [ ] **Step 4: Implement the fixed-order controller**

Validate nonnull config, track, and train dependencies in `_init`, compute total ticks with the existing ceiling rule, and create one initial detached snapshot. Store `_seconds_per_tick: float` and `_construction_units_per_tick: float`, then initialize them exactly once from the copied config:

~~~gdscript
_seconds_per_tick = 1.0 / float(_start_config.simulation_ticks_per_second)
_construction_units_per_tick = (
    _start_config.construction_speed_units_per_second * _seconds_per_tick
)
assert(_seconds_per_tick > 0.0 and _construction_units_per_tick > 0.0)
~~~

`start()` changes only `READY` to `PREPARING_DEPARTURE` and publishes the full frozen snapshot. No later Resource or Node mutation may recompute either per-tick value.

Implement `advance_tick` as one guarded method with this literal phase order:

~~~gdscript
func advance_tick(input_frame: TrackInputFrameScript = null) -> void:
    if _state == State.READY or _state == State.COMPLETED:
        return
    var frame := input_frame if input_frame != null else TrackInputFrameScript.empty()
    var right_won := _track_system.apply_right_input(frame)
    if not right_won:
        _track_system.apply_left_input(frame)

    _track_system.advance_construction(_construction_units_per_tick)
    if (
        _state == State.PREPARING_DEPARTURE
        and _track_system.get_built_length() + TrackSystemScript.GEOMETRY_EPSILON
            >= _start_config.departure_required_built_units
    ):
        _state = State.RUNNING
        _train_system.depart(0.0)

    var track_end_requested := false
    if _state == State.RUNNING:
        track_end_requested = _train_system.advance_tick(
            _track_system,
            _seconds_per_tick
        )
        _track_system.recover_behind(
            _train_system.get_route_distance()
            - _start_config.recovery_distance_units
        )

    var regular_expiry_requested := false
    if _state == State.RUNNING:
        _elapsed_ticks = min(_total_ticks, _elapsed_ticks + 1)
        _remaining_ticks = _total_ticks - _elapsed_ticks
        regular_expiry_requested = _remaining_ticks == 0

    if regular_expiry_requested:
        _complete(SessionResultScript.Reason.REGULAR_TIME_EXPIRED)
    elif track_end_requested:
        _complete(SessionResultScript.Reason.TRACK_END_REACHED)
    else:
        _publish_snapshot()
~~~

`_complete` sets `_state = COMPLETED` before building and emitting the terminal snapshot, then emits exactly one result. Snapshot construction derives built distance ahead from `built_end - train_distance`, computes warning seconds only for an active train, and compares to the copied threshold. Never expose live `TrackSystem` or `TrainSystem` references.

After the new controller surface exists, adapt `test_session_controller.gd` to a fully built test route whose departure requirement is crossed under explicit input and ticks. Keep it focused on the accepted timer math, ceiling display, detached snapshots, one-shot completion, and terminal reentrancy; do not weaken any old timing or signal-order assertion.

- [ ] **Step 5: Compose the selected departure and advance both active phases in the app**

In `PrototypeApp.compose_session_dependencies()`:

1. clear all prior composition fields and result guard;
2. resolve the instantiated `SessionShell` child with `get_node_or_null` rather than relying on an `@onready` field, then reach its real `LogicalTrackField` only through the out-of-tree-safe `get_track_field_view()` and `get_logical_track_field()` accessors before validating `PrototypeBalance`, `UILayoutProfile`, and candidate nodes; this preserves the accepted out-of-tree packed-scene composition probe;
3. create the base config through `balance.create_session_start_config(startup_seed)`;
4. get copied candidate records sorted by ID;
5. construct and assign the one public `session_rng` from the factory-produced seed, then select `records[session_rng.peek_index(record_count)]`;
6. complete the config with the selected record and logical size;
7. create `TrackSystem`, `TrainSystem`, and `SessionController` from only the completed config.

The selection preview and the accepted public shell probe therefore share one seeded RNG object while the probe still observes its original unconsumed sequence. Do not create a temporary selection generator or replace `session_rng` after selection.

In `_ready`, pass the completed start config to `SessionShell.configure`, connect signals, call `start`, and retain the exact ready log:

~~~text
Moe Rail Way session shell ready | duration=180 ticks=60
~~~

In `_physics_process`, advance while state is either `PREPARING_DEPARTURE` or `RUNNING`, consume exactly one shell input frame, and submit it to the controller. Do not gate only on `RUNNING`; that would stop construction before departure.

For an invalid startup, report every owner-qualified Resource, layout, field, and candidate error, create no domain objects, emit no ready/result marker, and quit with code `2` in the existing debug/headless path.

- [ ] **Step 6: Update the accepted shell lifecycle integration**

Keep every existing layout, padding, coordinate, inactive-HUD, result-overlay, and one-shot presentation assertion. Change only the lifecycle driver:

- after the real short-session app composes, assert `PREPARING_DEPARTURE` and frozen `0:02`;
- disable the app's automatic physics processing;
- read the copied departure point and logical width from `session_start_config`;
- press at the endpoint and reserve one straight segment of at least `required_built_units + 8` toward whichever horizontal edge has more room;
- submit explicit empty input ticks until the default construction reaches the departure threshold;
- assert the threshold tick starts the train and timer together;
- continue explicit ticks until the two-second regular result;
- preserve the existing exact regular result text and duplicate-presentation guard.

This integration deliberately feeds value input; Task 6 separately proves real GUI event delivery.

- [ ] **Step 7: Run controller and accepted-shell GREEN gates**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailUnitOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailUnitExit = $LASTEXITCODE
$MoeRailUnitText = $MoeRailUnitOutput -join "`n"
$MoeRailUnitOutput
if ($MoeRailUnitExit -ne 0 -or
    [regex]::Matches($MoeRailUnitText, '(?m)^PASS: 13 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailUnitText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 7 did not pass exactly thirteen suites.'
}

$MoeRailShellOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/integration/run_session_shell_integration.gd' 2>&1
)
$MoeRailShellExit = $LASTEXITCODE
$MoeRailShellText = $MoeRailShellOutput -join "`n"
$MoeRailShellOutput
foreach ($MoeRailMarker in @(
    'PASS: session shell layout integration',
    'PASS: session shell lifecycle integration'
)) {
    if ([regex]::Matches($MoeRailShellText, "(?m)^$([regex]::Escape($MoeRailMarker))\r?$").Count -ne 1) {
        throw "Missing accepted shell marker: $MoeRailMarker"
    }
}
if ($MoeRailShellExit -ne 0 -or
    $MoeRailShellText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 7 accepted shell integration failed.'
}
~~~

- [ ] **Step 8: Commit only Task 7 files**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/src/domain/session/session_controller.gd',
    'godot-project-moe-rail-way/src/domain/session/session_snapshot.gd',
    'godot-project-moe-rail-way/src/domain/session/session_result.gd',
    'godot-project-moe-rail-way/src/app/prototype_app.gd',
    'godot-project-moe-rail-way/tests/unit/test_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_train_session_controller.gd.uid',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 7 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 7 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 7 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 7 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 7 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: orchestrate track and train session'
if ($LASTEXITCODE -ne 0) { throw 'Task 7 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 7 did not leave a clean feature worktree.'
}
~~~

### Task 8: Present Primitive Track, Train, HUD, and Real-App Evidence

**Files:**

- Modify: `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd`
- Modify: `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- Create: `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd`
- Create: `godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd.uid`
- Create: `godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres`
- Create: `godot-project-moe-rail-way/tests/fixtures/invalid_track_train_balance.tres`
- Create: `godot-project-moe-rail-way/tests/integration/nondefault_track_train_app.tscn`
- Create: `godot-project-moe-rail-way/tests/integration/invalid_track_train_app.tscn`
- Create: `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd`
- Create: `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd.uid`
- Modify: `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- Modify: `godot-project-moe-rail-way/tests/run_all.gd`

- [ ] **Step 1: Write the failing composition, presentation, and app tests**

Create `test_track_train_app_composition.gd` without touching the protected boot suite. Load and instantiate the real app and shell scenes, call `compose_session_dependencies`, and prove:

- the app still exports specifically typed `PrototypeBalance` and `UILayoutProfile` properties;
- the shell owns one `TrackFieldView` and one `LogicalTrackField` with the eight authored candidate nodes;
- valid composition creates copied start config, public unconsumed RNG, `TrackSystem`, `TrainSystem`, and a `READY` controller;
- the selected candidate ID and position match one sorted scene record and only that selected marker is represented at runtime;
- mutating any Resource or candidate node after composition does not change active config, controller, or snapshot values;
- mutating the authored logical-field preset or `CUSTOM` dimensions after composition does not change configured input mapping, primitive drawing size, or domain results;
- a presented preparation snapshot exposes built/reserved/head/departure render observations and exact preparation HUD strings;
- a presented running snapshot exposes train pose, warning state, and exact running HUD strings;
- render observations contain copied arrays and scalar values, never Nodes, Resources, controller, track, or train references;
- both result reasons are accepted exactly once while a null or repeated result is ignored;
- no cash, settlement, contract, durability, cargo, restart, or action control becomes active.

Use the exact RED assertion message `TrackFieldView must expose built track render observation` and register this suite fourteenth.

Make the smoke suite guard `has_method("get_render_observation")`, then check for the `built_route` key in the returned Dictionary. If either is absent, record that exact message and return `finish()` before accessing any other new presentation key.

Create `nondefault_track_train_balance.tres` with embedded feature Resources whose distinct values are: duration `4.0`, ticks `10`, train speed `25.0`, total track `200.0`, recovery `40.0`, warning `1.5`, construction speed `50.0`, endpoint radius `18.0`, hit radius `12.0`, sample distance `6.0`, clearance `3.0`, and departure requirement `50.0`. Create `invalid_track_train_balance.tres` whose recovery distance equals its total inventory so the exact owner-qualified field fails. Reference them from the two app scene fixtures.

Create `run_track_train_app_integration.gd` to exercise real scene composition with explicit ticks. It must:

- verify every nondefault value was copied, survives mutation of the source Resource, and produces exact per-tick construction, departure, movement, recovery, and warning behavior from those nondefault numbers;
- verify the selected candidate is reproducible and unselected authoring nodes do not render;
- drive preparation, physical construction, departure, HUD transition, train movement, warning, recovery, and a track-end result;
- separately drive a regular-expiry result with enough built track;
- run the same seed and logical input frames twice at different viewport sizes and compare selected ID plus every domain snapshot signature;
- call invalid composition outside the tree, require an error containing `track_inventory_balance.recovery_distance_units`, and require no composed controller;
- create fresh real-scene instances with one required feature Resource missing and one positive numeric field set outside its valid range; require exact Resource/field ownership and no composed domain object;
- create fresh real-scene instances for invalid `CUSTOM` width/height, zero candidates, empty ID, duplicate ID, and out-of-bounds candidate position; require the exact `logical_track_field` owner plus the relevant `custom_width`, `custom_height`, `DepartureCandidates`, `candidate_id`, or `position` field fragment and no composed domain object for every case;
- prove result presentation remains one-shot for both reasons.

Print each marker exactly once:

~~~text
PASS: track train app lifecycle integration
PASS: track train startup validation integration
PASS: track train deterministic replay integration
~~~

- [ ] **Step 2: Run the presentation contracts to verify RED**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailUnitOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailUnitExit = $LASTEXITCODE
$MoeRailUnitText = $MoeRailUnitOutput -join "`n"
$MoeRailUnitOutput
if ($MoeRailUnitExit -eq 0 -or
    $MoeRailUnitText -notmatch 'TrackFieldView must expose built track render observation') {
    throw 'Expected the primitive presentation contract to fail.'
}

$MoeRailAppOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/integration/run_track_train_app_integration.gd' 2>&1
)
$MoeRailAppExit = $LASTEXITCODE
$MoeRailAppText = $MoeRailAppOutput -join "`n"
$MoeRailAppOutput
if ($MoeRailAppExit -eq 0 -or
    $MoeRailAppText -notmatch '(track train app|TrackFieldView|track_end)') {
    throw 'Expected the real-app integration to fail before presentation implementation.'
}
~~~

- [ ] **Step 3: Draw only primitive snapshot data**

Retain Task 2's already-tested `TrackFieldView.configure_session` copies and hidden authoring nodes. In this task, `present` copies the detached snapshot values into presentation fields and calls `queue_redraw`.

Implement `_draw` in logical space after applying the existing uniform scale and centered offset. Use fixed prototype constants, not new balance fields:

- built route: thick opaque `draw_polyline`;
- reserved-unbuilt route: thinner translucent `draw_polyline`;
- construction head: emphasized `draw_circle`;
- selected departure: one `draw_circle` with no unselected runtime markers;
- train: one small heading-oriented triangle through `draw_colored_polygon`;
- right-hover preview: the projected reserved suffix as a brighter translucent polyline.

The hover preview reconstructs arc distances from the copied reserved polyline, uses the copied `route_hit_radius_units`, chooses the nearest Euclidean projection, and resolves a `TrackSystemScript.GEOMETRY_EPSILON` tie in actual linear Euclidean distance toward the greatest route distance. Its smoke tests cover a distance difference of epsilon/2 and a difference greater than epsilon, matching the domain projection cases. It appears only over reserved-unbuilt geometry and never previews built-track demolition in `proto/02`.

Clear the hover preview on mouse exit, right press, completed snapshot, or loss of a reserved hit. Runtime setup explicitly hides every candidate authoring node; the selected departure is drawn only from the copied start config.

`get_render_observation` returns new copies under exact keys `logical_size`, `built_route`, `reserved_route`, `construction_head`, `selected_departure_id`, `selected_departure_position`, `train_active`, `train_position`, `train_heading`, and `hover_cancel_route`. Do not return a CanvasItem, candidate record, Resource, or domain object.

- [ ] **Step 4: Present exact preparation and running HUD values**

Keep `TIME` in the accepted `m:ss` format. When `snapshot.has_track_train_data()` is true, set `TRACK` to `"%.1f / %.1f" % [available, total]`; timer-only four-argument layout fixtures retain the accepted em dash. Do not infer presence from zero or positive numeric values.

During `PREPARING_DEPARTURE`, set `TRACK END` to `"%.1f / %.1f" % [built, required]`. During `RUNNING`, set it to `"%.1f s" % estimated_seconds`. Toggle only a local `font_color` theme override between the existing normal prototype text color and one fixed urgent prototype color. `get_layout_observation` adds `track_end_urgent` so tests do not infer style from pixels.

`show_result` maps reasons exactly:

| Reason | Result text |
|---|---|
| `REGULAR_TIME_EXPIRED` | `REGULAR TIME EXPIRED` |
| `TRACK_END_REACHED` | `TRACK END REACHED` |

Keep `SESSION COMPLETE` and `Settlement is not available in this milestone.` unchanged. Do not add buttons or future-economy text.

Extend `run_session_shell_integration.gd` again at this task to assert the real short-session lifecycle's preparation inventory/progress strings, running seconds string, urgent-style observation, and both reason texts while retaining all prior layout, mapping, timer, and one-shot assertions. This is the required Task 8 modification of that runner.

- [ ] **Step 5: Run all Task 8 GREEN gates**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailUnitOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' 2>&1)
$MoeRailUnitExit = $LASTEXITCODE
$MoeRailUnitText = $MoeRailUnitOutput -join "`n"
$MoeRailUnitOutput
if ($MoeRailUnitExit -ne 0 -or
    [regex]::Matches($MoeRailUnitText, '(?m)^PASS: 14 prototype test suite\(s\)\r?$').Count -ne 1 -or
    $MoeRailUnitText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 8 did not pass exactly fourteen suites.'
}

$MoeRailAppOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/integration/run_track_train_app_integration.gd' 2>&1
)
$MoeRailAppExit = $LASTEXITCODE
$MoeRailAppText = $MoeRailAppOutput -join "`n"
$MoeRailAppOutput
foreach ($MoeRailMarker in @(
    'PASS: track train app lifecycle integration',
    'PASS: track train startup validation integration',
    'PASS: track train deterministic replay integration'
)) {
    if ([regex]::Matches($MoeRailAppText, "(?m)^$([regex]::Escape($MoeRailMarker))\r?$").Count -ne 1) {
        throw "Missing real-app marker: $MoeRailMarker"
    }
}
if ($MoeRailAppExit -ne 0 -or
    $MoeRailAppText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 8 real-app integration failed.'
}

$MoeRailShellOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --script 'res://tests/integration/run_session_shell_integration.gd' 2>&1
)
$MoeRailShellExit = $LASTEXITCODE
$MoeRailShellText = $MoeRailShellOutput -join "`n"
$MoeRailShellOutput
foreach ($MoeRailMarker in @(
    'PASS: session shell layout integration',
    'PASS: session shell lifecycle integration'
)) {
    if ([regex]::Matches($MoeRailShellText, "(?m)^$([regex]::Escape($MoeRailMarker))\r?$").Count -ne 1) {
        throw "Missing accepted shell marker after presentation: $MoeRailMarker"
    }
}
if ($MoeRailShellExit -ne 0 -or
    $MoeRailShellText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Task 8 accepted shell integration failed.'
}
~~~

- [ ] **Step 6: Commit only Task 8 files**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd',
    'godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd',
    'godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd.uid',
    'godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres',
    'godot-project-moe-rail-way/tests/fixtures/invalid_track_train_balance.tres',
    'godot-project-moe-rail-way/tests/integration/nondefault_track_train_app.tscn',
    'godot-project-moe-rail-way/tests/integration/invalid_track_train_app.tscn',
    'godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd.uid',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    'godot-project-moe-rail-way/tests/run_all.gd'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 8 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 8 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 8 staged set differs from its file contract.'
}
$MoeRailUnstagedOutput = @(git -C $MoeRailFeatureWorktree diff --name-only)
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
$MoeRailUntrackedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntrackedExit -ne 0 -or
    $MoeRailUnstagedOutput.Count -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUnstagedOutput
    $MoeRailUntracked
    throw 'Task 8 has changes outside its staged file contract.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 8 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'feat: present track and train prototype'
if ($LASTEXITCODE -ne 0) { throw 'Task 8 commit failed.' }
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 8 did not leave a clean feature worktree.'
}
~~~

### Task 9: Pass and Record the Track-and-Train Milestone Gate

**Files:**

- Create: `godot-project-moe-rail-way/tests/manual/track_train_windows.md`
- Modify implementation or tests only if an automated, manual, hygiene, or review gate exposes a plan-scoped defect

- [ ] **Step 1: Run the complete automated gate from a fresh process set**

Close only agent-owned test processes from earlier commands. Do not close a user-owned Godot or Steam editor. Run this block at the exact Task 8 HEAD:

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailDefaultGateWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailAllowedGateWorktrees = @(
    $MoeRailDefaultGateWorktree,
    'D:\godot\MoeRailWay-worktrees\prototype-m3-candidate',
    'D:\godot\MoeRailWay'
)
$MoeRailHadGateOverride = -not [string]::IsNullOrWhiteSpace($env:MOERAIL_GATE_WORKTREE)
$MoeRailFeatureWorktree = if ($MoeRailHadGateOverride) {
    $env:MOERAIL_GATE_WORKTREE
} else {
    $MoeRailDefaultGateWorktree
}
$MoeRailFeatureWorktree = [IO.Path]::GetFullPath($MoeRailFeatureWorktree)
$MoeRailAllowedGateFullPaths = @(
    $MoeRailAllowedGateWorktrees | ForEach-Object { [IO.Path]::GetFullPath($_) }
)
if ($MoeRailFeatureWorktree -notin $MoeRailAllowedGateFullPaths -or
    -not (Test-Path -LiteralPath $MoeRailFeatureWorktree -PathType Container)) {
    throw "Unapproved or missing gate worktree: $MoeRailFeatureWorktree"
}
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'

function Invoke-MoeRailPassRunner {
    param(
        [string]$Name,
        [string[]]$Arguments,
        [string[]]$Markers
    )
    $MoeRailRunnerOutput = @(& $MoeRailGodotExe @Arguments 2>&1)
    $MoeRailRunnerExit = $LASTEXITCODE
    $MoeRailRunnerText = $MoeRailRunnerOutput -join "`n"
    $MoeRailRunnerOutput
    if ($MoeRailRunnerExit -ne 0 -or
        $MoeRailRunnerText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
        throw "$Name failed with exit code $MoeRailRunnerExit."
    }
    foreach ($MoeRailMarker in $Markers) {
        $MoeRailMarkerCount = [regex]::Matches(
            $MoeRailRunnerText,
            "(?m)^$([regex]::Escape($MoeRailMarker))\r?$"
        ).Count
        if ($MoeRailMarkerCount -ne 1) {
            throw "$Name expected one '$MoeRailMarker' marker; found $MoeRailMarkerCount."
        }
    }
}

$MoeRailVersionOutput = @(& $MoeRailGodotExe --version 2>&1)
$MoeRailVersionExit = $LASTEXITCODE
$MoeRailVersion = ($MoeRailVersionOutput -join "`n").Trim()
$MoeRailVersionOutput
if ($MoeRailVersionExit -ne 0 -or
    $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected Godot version: $MoeRailVersion"
}

Invoke-MoeRailPassRunner `
    -Name 'Project settings configuration' `
    -Arguments @('--headless', '--path', $MoeRailProject, '--script', 'res://tools/configure_project.gd') `
    -Markers @('Project settings configured')
Invoke-MoeRailPassRunner `
    -Name 'Native prototype suites' `
    -Arguments @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/run_all.gd') `
    -Markers @('PASS: 14 prototype test suite(s)')
Invoke-MoeRailPassRunner `
    -Name 'Accepted session shell integration' `
    -Arguments @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_session_shell_integration.gd') `
    -Markers @(
        'PASS: session shell layout integration',
        'PASS: session shell lifecycle integration'
    )
Invoke-MoeRailPassRunner `
    -Name 'Logical field runtime integration' `
    -Arguments @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_logical_track_field_integration.gd') `
    -Markers @('PASS: logical track field runtime integration')
Invoke-MoeRailPassRunner `
    -Name 'Logical field editor integration' `
    -Arguments @('--headless', '--editor', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_logical_track_field_editor_integration.gd') `
    -Markers @('PASS: logical track field editor integration')
Invoke-MoeRailPassRunner `
    -Name 'Track input integration' `
    -Arguments @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_track_train_input_integration.gd') `
    -Markers @('PASS: track train input integration')
Invoke-MoeRailPassRunner `
    -Name 'Track and train app integration' `
    -Arguments @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_track_train_app_integration.gd') `
    -Markers @(
        'PASS: track train app lifecycle integration',
        'PASS: track train startup validation integration',
        'PASS: track train deterministic replay integration'
    )
Invoke-MoeRailPassRunner `
    -Name 'Main scene boot' `
    -Arguments @('--headless', '--path', $MoeRailProject, '--quit-after', '2') `
    -Markers @('Moe Rail Way session shell ready | duration=180 ticks=60')

$MoeRailInvalidOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProject `
        --scene 'res://tests/integration/invalid_track_train_app.tscn' `
        --quit-after 30 2>&1
)
$MoeRailInvalidExit = $LASTEXITCODE
$MoeRailInvalidText = $MoeRailInvalidOutput -join "`n"
$MoeRailInvalidOutput
$MoeRailUnexpectedInvalidLines = @(
    $MoeRailInvalidText -split "`r?`n" | Where-Object {
        $_ -match '^(FAIL:|SCRIPT ERROR:)' -or
        ($_ -match '^ERROR:' -and
            $_ -notmatch 'track_inventory_balance\.recovery_distance_units')
    }
)
if ($MoeRailInvalidExit -ne 2 -or
    [regex]::Matches(
        $MoeRailInvalidText,
        'track_inventory_balance\.recovery_distance_units'
    ).Count -lt 1 -or $MoeRailUnexpectedInvalidLines.Count -ne 0 -or
    $MoeRailInvalidText -match 'Moe Rail Way session shell ready|Moe Rail Way session complete') {
    throw 'Invalid track/train startup did not fail closed with its exact owner and field.'
}

$MoeRailPostGateStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all |
        Sort-Object
)
$MoeRailExpectedGateStatus = if (
    $MoeRailFeatureWorktree -eq [IO.Path]::GetFullPath('D:\godot\MoeRailWay')
) {
    @(
        ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
        ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
        '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
    ) | Sort-Object
} else {
    @()
}
if ($LASTEXITCODE -ne 0 -or
    @(Compare-Object $MoeRailExpectedGateStatus $MoeRailPostGateStatus).Count -ne 0) {
    $MoeRailPostGateStatus
    throw 'The automated gate changed tracked or untracked feature files.'
}
if ($MoeRailHadGateOverride) {
    Remove-Item Env:MOERAIL_GATE_WORKTREE
}
~~~

The expected evidence is one unit marker, two accepted-shell markers, one runtime logical-field marker, one editor logical-field marker, one input marker, three app markers, one main-ready marker, and one intentional invalid-start exit `2`. Any missing, duplicate, unexpected `FAIL:`, `SCRIPT ERROR:`, or `ERROR:` line fails the positive runners.

- [ ] **Step 2: Perform the Windows editor/runtime smoke and write the completed English record**

Use the exact Godot executable above and the real feature project. If a user-owned editor has the project open or an import/editor lock prevents isolated testing, stop and ask the user; never terminate that process. Create `tests/manual/track_train_windows.md` only after running the checks, and record the date, Windows version, exact Godot build, Task 8 commit SHA, tester, each tested window size, an exact PASS status per item, and every host-only warning. If any item fails, keep Task 9 incomplete, correct the defect, and rerun affected checks before creating the final evidence record.

The completed record must cover:

- one seeded departure marker is visible, all other authored candidates are runtime-invisible, and `3:00` remains frozen in preparation;
- left draw begins only at the current reserved endpoint, while endpoint-outside, HUD, and letterbox presses do nothing;
- held drag samples once per fixed tick, reservation immediately decreases available inventory, and construction follows at its configured slower rate after release;
- field-exit clipping, outside-held reentry, inventory clipping, and active self-intersection clearance preserve one continuous route;
- right-click cancels only the projected reserved-unbuilt suffix, refunds it once for free, ends the stroke, and requires a fresh left press;
- right-clicking built track, recovered space, or empty field is a no-op, and left click never cancels or demolishes;
- construction continues while the reserved endpoint is extended and canceled reservation cannot build in the same tick;
- at exactly `360.0` built units with defaults, the train and timer advance together for their first tick;
- the train never stops, reverses, or changes speed; catching the built endpoint produces one `TRACK END REACHED` result even with unbuilt reservation ahead;
- rear track recovers continuously, including partial segments, and returned inventory becomes drawable on the following tick;
- `TRACK` shows current available/total, preparation shows built/required, running shows built-end seconds with one decimal, and urgency appears at or below `3.0` configured seconds;
- `REGULAR TIME EXPIRED` and `TRACK END REACHED` each show one noninteractive result with no settlement or action button;
- `960x540`, `1280x720`, `1600x900`, and `1920x1080` preserve field dominance, geometry, cursor alignment, and no overlap or clipping;
- resizing during an identical input sequence changes no route length, inventory, construction, train speed, selected candidate ID, timer, or result;
- in the Godot 2D editor, `COMPACT`, `STANDARD`, `EXPANSIVE`, and representative `CUSTOM` sizes update the boundary preview and preserve every candidate's normalized gizmo position;
- candidate nodes remain independently draggable through their 2D transform gizmos and `Transform > Position`;
- UI padding Inspector changes affect layout only and do not change logical geometry;
- no paid demolition, crossing, cash mutation, warp, cargo, hazard, durability, contract, credit, restart, or debug-end behavior appears.

Represent the 18 required items above, in the same order, as exactly 18 Markdown rows beginning `- [x] PASS:`. Screenshots are optional and remain outside Git unless the user separately approves them as artifacts. The Markdown record is agent-facing and must be entirely English, with no unchecked box, failed result, or incomplete status entry.

- [ ] **Step 3: Verify feature ownership, sidecars, scope, and protected primary files**

Before staging the manual record, run:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailPlanCommit = (
    git -C $MoeRailFeatureWorktree log HEAD -1 --format=%H -- $MoeRailPlanPath $MoeRailBriefPath
).Trim()
$MoeRailPlanParent = (git -C $MoeRailFeatureWorktree rev-parse "$MoeRailPlanCommit^").Trim()
$MoeRailPrototypeHead = (git -C $MoeRailFeatureWorktree rev-parse 'Prototyping^{commit}').Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPlanCommit -notmatch '^[0-9a-f]{40}$' -or
    $MoeRailPlanParent -ne $MoeRailCodeBase -or
    $MoeRailPrototypeHead -ne $MoeRailPlanCommit) {
    throw 'Approved planning commit or Prototyping base changed before the feature gate.'
}
$MoeRailManualPath = 'godot-project-moe-rail-way/tests/manual/track_train_windows.md'
$MoeRailProtectedPaths = @(
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    'godot-project-moe-rail-way/tests/support/prototype_test.gd'
)
$MoeRailExpectedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailExpectedPrimaryHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}

$MoeRailFeatureBranch = (git -C $MoeRailFeatureWorktree branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $MoeRailFeatureBranch -ne 'proto/02-track-train') {
    throw "Unexpected feature branch: $MoeRailFeatureBranch"
}
$MoeRailTracked = @(git -C $MoeRailFeatureWorktree ls-files)
if ($LASTEXITCODE -ne 0) { throw 'Failed to enumerate tracked feature files.' }
$MoeRailTrackedScripts = @($MoeRailTracked | Where-Object { $_.EndsWith('.gd') })
$MoeRailTrackedUids = @($MoeRailTracked | Where-Object { $_.EndsWith('.gd.uid') })
$MoeRailMissingUids = @(
    $MoeRailTrackedScripts | Where-Object { "$_.uid" -notin $MoeRailTrackedUids }
)
$MoeRailOrphanUids = @(
    $MoeRailTrackedUids | Where-Object {
        $_.Substring(0, $_.Length - 4) -notin $MoeRailTrackedScripts
    }
)
if ($MoeRailMissingUids.Count -ne 0 -or $MoeRailOrphanUids.Count -ne 0) {
    $MoeRailMissingUids
    $MoeRailOrphanUids
    throw 'Tracked GDScript and UID sidecars are not one-to-one.'
}
$MoeRailUidRecords = @(
    foreach ($MoeRailUidPath in $MoeRailTrackedUids) {
        $MoeRailUidValue = (
            Get-Content -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailUidPath) -Raw
        ).Trim()
        [pscustomobject]@{ Path = $MoeRailUidPath; Value = $MoeRailUidValue }
    }
)
$MoeRailMalformedUids = @(
    $MoeRailUidRecords | Where-Object { $_.Value -notmatch '^uid://[a-z0-9]+$' }
)
$MoeRailDuplicateUids = @(
    $MoeRailUidRecords | Group-Object Value | Where-Object { $_.Count -ne 1 }
)
if ($MoeRailMalformedUids.Count -ne 0 -or $MoeRailDuplicateUids.Count -ne 0) {
    $MoeRailMalformedUids
    $MoeRailDuplicateUids
    throw 'Tracked UID content is malformed or duplicated.'
}

$MoeRailProhibitedTracked = @(
    $MoeRailTracked | Where-Object {
        $_ -match '(^|/)(\.superpowers|\.godot|logs|builds|exports|android)(/|$)' -or
        $_ -match '(^|/)addons/godot_mcp(/|$)' -or
        $_ -match '\.log$'
    }
)
if ($MoeRailProhibitedTracked.Count -ne 0) {
    $MoeRailProhibitedTracked
    throw 'Generated, local, export, Android, or godot_mcp paths are tracked.'
}

$MoeRailChangedPaths = @(
    git -C $MoeRailFeatureWorktree diff --name-only "$MoeRailPlanCommit..HEAD"
)
if ($LASTEXITCODE -ne 0 -or $MoeRailChangedPaths.Count -eq 0) {
    throw 'Failed to enumerate the feature change set.'
}
$MoeRailProtectedFeatureChanges = @(
    $MoeRailChangedPaths | Where-Object { $_ -in $MoeRailProtectedPaths }
)
if ($MoeRailProtectedFeatureChanges.Count -ne 0) {
    $MoeRailProtectedFeatureChanges
    throw 'The feature changed a protected primary-owned test path.'
}
$MoeRailOutOfSlicePaths = @(
    $MoeRailChangedPaths | Where-Object {
        $_ -match 'godot-project-moe-rail-way/src/(economy|warp|cargo|hazard|contract|credit|settlement)/' -or
        $_ -match 'godot-project-moe-rail-way/src/.*(pathfind|navigation|multi_train)'
    }
)
if ($MoeRailOutOfSlicePaths.Count -ne 0) {
    $MoeRailOutOfSlicePaths
    throw 'The feature introduced a deferred gameplay or generalized route slice.'
}

foreach ($MoeRailRequiredData in @(
    'godot-project-moe-rail-way/data/session_balance.tres',
    'godot-project-moe-rail-way/data/train_balance.tres',
    'godot-project-moe-rail-way/data/track_inventory_balance.tres',
    'godot-project-moe-rail-way/data/track_construction_balance.tres',
    'godot-project-moe-rail-way/data/departure_balance.tres'
)) {
    git -C $MoeRailFeatureWorktree cat-file -e "HEAD:$MoeRailRequiredData"
    if ($LASTEXITCODE -ne 0) { throw "Missing tracked default data: $MoeRailRequiredData" }
}

$MoeRailManualAbsolute = Join-Path $MoeRailFeatureWorktree $MoeRailManualPath
if (-not (Test-Path -LiteralPath $MoeRailManualAbsolute -PathType Leaf)) {
    throw 'The completed Windows manual record is missing.'
}
$MoeRailManualText = Get-Content -LiteralPath $MoeRailManualAbsolute -Raw
$MoeRailManualPassRows = [regex]::Matches(
    $MoeRailManualText,
    '(?m)^- \[x\] PASS: .+\r?$'
).Count
if ($MoeRailManualText -match '(?i)\b(?:T.{0}BD|T.{0}ODO|PEND.{0}ING|NOT\s+RUN|FAIL(?:ED)?)\b|\[ \]' -or
    $MoeRailManualText -match '[\uAC00-\uD7A3]' -or
    $MoeRailManualPassRows -ne 18) {
    throw 'The English manual record is incomplete, failed, malformed, or contains Korean text.'
}

git -C $MoeRailFeatureWorktree diff --check "$MoeRailPlanCommit...HEAD"
if ($LASTEXITCODE -ne 0) { throw 'The committed feature diff failed whitespace validation.' }
$MoeRailIndex = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
if ($MoeRailIndex.Count -ne 0 -or $MoeRailUnstagedExit -ne 0 -or
    $MoeRailUntracked.Count -ne 1 -or $MoeRailUntracked[0] -ne $MoeRailManualPath) {
    $MoeRailIndex
    $MoeRailUntracked
    throw 'Only the completed untracked manual record may remain before its evidence commit.'
}

$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary user-owned status changed during feature implementation.'
}
foreach ($MoeRailProtectedPath in $MoeRailExpectedPrimaryHashes.Keys) {
    $MoeRailProtectedAbsolute = Join-Path $MoeRailPrimary $MoeRailProtectedPath
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath $MoeRailProtectedAbsolute -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedPrimaryHashes[$MoeRailProtectedPath]) {
        throw "Primary protected fingerprint changed: $MoeRailProtectedPath"
    }
}
~~~

In addition to the path gate, independently inspect the source diff for hidden cash writers, paid demolition, crossings, warps, cargo, hazards, durability, contracts, credit, settlement, graph/pathfinding, multiple trains, or generalized abstractions. Do not use a raw keyword failure for that semantic review because accepted inactive HUD labels contain several future feature names.

- [ ] **Step 4: Commit only the completed manual evidence**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailTaskFiles = @(
    'godot-project-moe-rail-way/tests/manual/track_train_windows.md'
)
if (@(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) { throw 'Task 9 index is not empty.' }
git -C $MoeRailFeatureWorktree add -- $MoeRailTaskFiles
if ($LASTEXITCODE -ne 0) { throw 'Task 9 staging failed.' }
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only | Sort-Object)
if (@(Compare-Object ($MoeRailTaskFiles | Sort-Object) $MoeRailStaged).Count -ne 0) {
    $MoeRailStaged
    throw 'Task 9 staged set differs from its file contract.'
}
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
if ($MoeRailUnstagedExit -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUntracked
    throw 'Task 9 has changes outside the staged evidence file.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 9 cached diff failed.' }
git -C $MoeRailFeatureWorktree commit -m 'test: document track train milestone gate'
if ($LASTEXITCODE -ne 0) { throw 'Task 9 commit failed.' }
$MoeRailPostCommitStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all
)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 9 did not leave a clean feature worktree.'
}
~~~

- [ ] **Step 5: Rerun fresh verification and obtain independent review**

At the Task 9 commit, rerun the complete Step 1 block unchanged. Rerun Step 3 with these two deliberate changes only: require a completely clean feature worktree instead of allowing the manual file, and compute `$MoeRailChangedPaths` at the new HEAD. Record the exact 40-character feature HEAD as `FEATURE_SHA`.

Then use `superpowers:requesting-code-review` for two independent read-only passes:

1. specification compliance against this plan, `docs/superpowers/specs/2026-08-16-prototype-track-train-design.md`, `docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md`, and `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`;
2. code and test quality, with special attention to arc-distance conservation, field/intersection clipping, fixed-tick ordering, signal reentrancy, scene/Resource validation, GUI event buffering, copied snapshot data, protected paths, and scope creep.

If any gate or review finds a defect, make the smallest focused correction commit, rerun every affected RED/GREEN contract plus the entire Step 1 gate, repeat Windows checks affected by the change, add a new English evidence update that names the new HEAD, and repeat both reviews. Do not claim an exact nine-task-commit history after correction commits; the later squash candidate intentionally collapses all reviewed feature commits.

Stop after reporting the clean reviewed `FEATURE_SHA`. Do not construct a squash candidate, fast-forward `Prototyping`, create `prototype-m3`, or push until the relevant approval described below is received.

---

## Post-Implementation Approval Gates

These commands belong to the later development session. They are not authorized by approval of this planning document.

### Gate A: Build a Reviewed Squash Candidate

After the user accepts the complete feature evidence, set `MOERAIL_ACCEPTED_FEATURE` to the exact reviewed `FEATURE_SHA`. Candidate construction does not move `Prototyping`:

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailCandidateWorktree = 'D:\godot\MoeRailWay-worktrees\prototype-m3-candidate'
$MoeRailFeatureBranch = 'proto/02-track-train'
$MoeRailCandidateBranch = 'codex/prototype-m3-candidate'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailPlanCommit = (
    git -C $MoeRailFeatureWorktree log HEAD -1 --format=%H -- $MoeRailPlanPath $MoeRailBriefPath
).Trim()
$MoeRailPlanParent = (git -C $MoeRailFeatureWorktree rev-parse "$MoeRailPlanCommit^").Trim()
$MoeRailPlanFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r $MoeRailPlanCommit |
        Sort-Object
)
$MoeRailExpectedPlanFiles = @($MoeRailPlanPath, $MoeRailBriefPath) | Sort-Object
$MoeRailAcceptedFeature = $env:MOERAIL_ACCEPTED_FEATURE
if ($MoeRailAcceptedFeature -notmatch '^[0-9a-f]{40}$' -or
    $MoeRailPlanCommit -notmatch '^[0-9a-f]{40}$' -or
    $MoeRailPlanParent -ne $MoeRailCodeBase -or
    @(Compare-Object $MoeRailExpectedPlanFiles $MoeRailPlanFiles).Count -ne 0) {
    throw 'Accepted feature or approved planning-commit identity is invalid.'
}
if (Test-Path -LiteralPath $MoeRailCandidateWorktree) {
    throw "Candidate worktree already exists: $MoeRailCandidateWorktree"
}
git -C $MoeRailPrimary show-ref --verify --quiet "refs/heads/$MoeRailCandidateBranch"
$MoeRailCandidateProbe = $LASTEXITCODE
if ($MoeRailCandidateProbe -eq 0) {
    throw "$MoeRailCandidateBranch already exists."
} elseif ($MoeRailCandidateProbe -ne 1) {
    throw 'Failed to inspect the candidate branch.'
}
$MoeRailPrototypeHead = (git -C $MoeRailPrimary rev-parse 'Prototyping^{commit}').Trim()
$MoeRailFeatureCurrentBranch = (git -C $MoeRailFeatureWorktree branch --show-current).Trim()
$MoeRailFeatureHead = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{commit}').Trim()
$MoeRailFeatureBase = (git -C $MoeRailFeatureWorktree merge-base $MoeRailPlanCommit HEAD).Trim()
$MoeRailFeatureStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPrototypeHead -ne $MoeRailPlanCommit -or
    $MoeRailFeatureCurrentBranch -ne $MoeRailFeatureBranch -or
    $MoeRailFeatureHead -ne $MoeRailAcceptedFeature -or
    $MoeRailFeatureBase -ne $MoeRailPlanCommit -or
    $MoeRailFeatureStatus.Count -ne 0) {
    $MoeRailFeatureStatus
    throw 'Feature or Prototyping no longer matches the reviewed candidate base.'
}

git -C $MoeRailPrimary worktree add -b $MoeRailCandidateBranch `
    $MoeRailCandidateWorktree $MoeRailPlanCommit
if ($LASTEXITCODE -ne 0) { throw 'Failed to create the candidate worktree.' }
git -C $MoeRailCandidateWorktree merge --squash $MoeRailAcceptedFeature
if ($LASTEXITCODE -ne 0) { throw 'Failed to construct the squash candidate.' }
$MoeRailExpectedFiles = @(
    git -C $MoeRailFeatureWorktree diff --name-only "$MoeRailPlanCommit..$MoeRailAcceptedFeature" |
        Sort-Object
)
$MoeRailStagedFiles = @(
    git -C $MoeRailCandidateWorktree diff --cached --name-only | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailExpectedFiles.Count -eq 0 -or
    @(Compare-Object $MoeRailExpectedFiles $MoeRailStagedFiles).Count -ne 0) {
    $MoeRailStagedFiles
    throw 'Candidate staged paths differ from the reviewed feature.'
}
git -C $MoeRailCandidateWorktree diff --quiet $MoeRailAcceptedFeature --
if ($LASTEXITCODE -ne 0) { throw 'Candidate tree differs from the reviewed feature tree.' }
git -C $MoeRailCandidateWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Candidate cached diff failed.' }
git -C $MoeRailCandidateWorktree commit -m 'feat: deliver prototype track and train milestone'
if ($LASTEXITCODE -ne 0) { throw 'Failed to commit the squash candidate.' }
$MoeRailCandidateHead = (git -C $MoeRailCandidateWorktree rev-parse HEAD).Trim()
$MoeRailCandidateParent = (git -C $MoeRailCandidateWorktree rev-parse 'HEAD^').Trim()
$MoeRailCandidateTree = (git -C $MoeRailCandidateWorktree rev-parse 'HEAD^{tree}').Trim()
$MoeRailFeatureTree = (git -C $MoeRailFeatureWorktree rev-parse "$MoeRailAcceptedFeature^{tree}").Trim()
$MoeRailCandidateStatus = @(
    git -C $MoeRailCandidateWorktree status --porcelain --untracked-files=all
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailCandidateParent -ne $MoeRailPlanCommit -or
    $MoeRailCandidateTree -ne $MoeRailFeatureTree -or
    $MoeRailCandidateStatus.Count -ne 0) {
    $MoeRailCandidateStatus
    throw 'Committed candidate has an unexpected parent, tree, or status.'
}
"CANDIDATE_SHA=$MoeRailCandidateHead"
~~~

Immediately before rerunning the complete Task 9 Step 1 block, set `$env:MOERAIL_GATE_WORKTREE = 'D:\godot\MoeRailWay-worktrees\prototype-m3-candidate'`. Run the block verbatim; it validates the allowlisted path and removes the override after success. Recheck the candidate's clean status and exact tree equality with `FEATURE_SHA`; that identity carries forward the already-reviewed sidecar, scope, hygiene, and Windows record. Repeat any manual check if candidate verification produces a different observation. Obtain one final candidate review and report `CANDIDATE_SHA`.

### Gate B: Fast-Forward `Prototyping` Only After Integration Approval

Set `MOERAIL_ACCEPTED_CANDIDATE` to the accepted `CANDIDATE_SHA`. This gate preserves the exact three primary user-owned files while applying the one candidate commit:

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailCandidateWorktree = 'D:\godot\MoeRailWay-worktrees\prototype-m3-candidate'
$MoeRailPlanCommit = (git -C $MoeRailCandidateWorktree rev-parse 'HEAD^').Trim()
$MoeRailAcceptedCandidate = $env:MOERAIL_ACCEPTED_CANDIDATE
$MoeRailExpectedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}
if ($MoeRailAcceptedCandidate -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_ACCEPTED_CANDIDATE to the accepted CANDIDATE_SHA.'
}
$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailCandidateHead = (git -C $MoeRailCandidateWorktree rev-parse HEAD).Trim()
$MoeRailCandidateParent = (git -C $MoeRailCandidateWorktree rev-parse 'HEAD^').Trim()
$MoeRailPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPrimaryBranch -ne 'Prototyping' -or
    $MoeRailPrimaryHead -ne $MoeRailPlanCommit -or
    $MoeRailCandidateHead -ne $MoeRailAcceptedCandidate -or
    $MoeRailCandidateParent -ne $MoeRailPlanCommit -or
    $MoeRailPrimaryIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary or candidate state changed before integration.'
}
foreach ($MoeRailProtectedPath in $MoeRailProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected fingerprint changed before integration: $MoeRailProtectedPath"
    }
}
$MoeRailCandidatePaths = @(
    git -C $MoeRailCandidateWorktree diff --name-only "$MoeRailPlanCommit..$MoeRailAcceptedCandidate"
)
$MoeRailPrimaryUntracked = @(git -C $MoeRailPrimary ls-files --others --exclude-standard)
$MoeRailProtectedCollisions = @(
    $MoeRailCandidatePaths | Where-Object { $_ -in $MoeRailProtectedHashes.Keys }
)
$MoeRailUntrackedCollisions = @(
    $MoeRailPrimaryUntracked | Where-Object { $_ -in $MoeRailCandidatePaths }
)
if ($MoeRailProtectedCollisions.Count -ne 0 -or $MoeRailUntrackedCollisions.Count -ne 0) {
    $MoeRailProtectedCollisions
    $MoeRailUntrackedCollisions
    throw 'Candidate paths collide with protected or untracked primary files.'
}

git -C $MoeRailPrimary merge --ff-only $MoeRailAcceptedCandidate
if ($LASTEXITCODE -ne 0) { throw 'Failed to fast-forward Prototyping.' }
$MoeRailIntegratedHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $MoeRailIntegratedHead -ne $MoeRailAcceptedCandidate) {
    throw 'Prototyping does not point to the accepted candidate.'
}
foreach ($MoeRailProtectedPath in $MoeRailProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected fingerprint changed during integration: $MoeRailProtectedPath"
    }
}
$MoeRailPostIntegrationStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
$MoeRailPostIntegrationIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPostIntegrationIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPostIntegrationStatus).Count -ne 0) {
    $MoeRailPostIntegrationStatus
    throw 'Primary status changed during integration.'
}
~~~

Immediately before rerunning the complete Task 9 Step 1 block, set `$env:MOERAIL_GATE_WORKTREE = 'D:\godot\MoeRailWay'`. Run the block verbatim; its primary-worktree branch allows only the exact protected three-path status and removes the override after success. Require the same exact protected fingerprints and report the integrated commit. Integration approval does not authorize a tag.

### Gate C: Create `prototype-m3` Only After Tag Approval

After the user explicitly approves the annotated tag, revalidate the integrated commit and protected state. Refuse if the tag exists locally or remotely. Then create and verify it without pushing:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailAcceptedCandidate = $env:MOERAIL_ACCEPTED_CANDIDATE
$MoeRailExpectedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}
if ($MoeRailAcceptedCandidate -notmatch '^[0-9a-f]{40}$' -or
    (git -C $MoeRailPrimary rev-parse HEAD).Trim() -ne $MoeRailAcceptedCandidate) {
    throw 'Integrated HEAD is not the accepted candidate.'
}
$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
$MoeRailPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPrimaryIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary protected status changed before tagging.'
}
foreach ($MoeRailProtectedPath in $MoeRailProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected fingerprint changed before tagging: $MoeRailProtectedPath"
    }
}
git -C $MoeRailPrimary show-ref --verify --quiet refs/tags/prototype-m3
$MoeRailLocalTagProbe = $LASTEXITCODE
$MoeRailRemoteTag = @(
    git -C $MoeRailPrimary ls-remote --tags origin refs/tags/prototype-m3
)
$MoeRailRemoteTagProbe = $LASTEXITCODE
if ($MoeRailLocalTagProbe -eq 0 -or
    ($MoeRailRemoteTagProbe -eq 0 -and $MoeRailRemoteTag.Count -ne 0)) {
    throw 'prototype-m3 already exists locally or remotely.'
} elseif ($MoeRailLocalTagProbe -ne 1 -or $MoeRailRemoteTagProbe -ne 0) {
    throw 'Failed to inspect the local or remote prototype-m3 tag.'
}
git -C $MoeRailPrimary tag -a prototype-m3 $MoeRailAcceptedCandidate `
    -m 'Prototype milestone 3: track and train'
if ($LASTEXITCODE -ne 0) { throw 'Failed to create prototype-m3.' }
$MoeRailTaggedCommit = (git -C $MoeRailPrimary rev-list -n 1 prototype-m3).Trim()
$MoeRailTagType = (git -C $MoeRailPrimary cat-file -t prototype-m3).Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailTaggedCommit -ne $MoeRailAcceptedCandidate -or $MoeRailTagType -ne 'tag') {
    throw 'prototype-m3 is not an annotated tag on the accepted commit.'
}
~~~

Tag approval does not authorize a push.

### Gate D: Atomically Publish Branch and Tag Only After Push Approval

After explicit push approval, require remote `Prototyping` to remain at published `prototype-m2` commit `c93e1834da8fb38792048914120fe50f9f500cb4` and require no remote `prototype-m3`. Push exactly the branch and annotated tag together:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailAcceptedCandidate = $env:MOERAIL_ACCEPTED_CANDIDATE
$MoeRailExpectedRemoteBase = 'c93e1834da8fb38792048914120fe50f9f500cb4'
$MoeRailExpectedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}
$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
$MoeRailPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPrimaryIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary protected status changed before publication.'
}
foreach ($MoeRailProtectedPath in $MoeRailProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected fingerprint changed before publication: $MoeRailProtectedPath"
    }
}
$MoeRailRemoteBranchRows = @(
    git -C $MoeRailPrimary ls-remote --heads origin refs/heads/Prototyping
)
$MoeRailRemoteBranchProbe = $LASTEXITCODE
$MoeRailRemoteTagRows = @(
    git -C $MoeRailPrimary ls-remote --tags origin refs/tags/prototype-m3 'refs/tags/prototype-m3^{}'
)
$MoeRailRemoteTagProbe = $LASTEXITCODE
if ($MoeRailRemoteBranchProbe -ne 0 -or $MoeRailRemoteTagProbe -ne 0 -or
    $MoeRailRemoteBranchRows.Count -ne 1 -or
    ($MoeRailRemoteBranchRows[0] -split "`t")[0] -ne $MoeRailExpectedRemoteBase -or
    $MoeRailRemoteTagRows.Count -ne 0) {
    $MoeRailRemoteBranchRows
    $MoeRailRemoteTagRows
    throw 'Remote branch or tag state changed before publication.'
}
$MoeRailLocalHead = (git -C $MoeRailPrimary rev-parse 'Prototyping^{commit}').Trim()
$MoeRailLocalTagCommit = (git -C $MoeRailPrimary rev-list -n 1 prototype-m3).Trim()
$MoeRailLocalTagObject = (git -C $MoeRailPrimary rev-parse 'prototype-m3^{tag}').Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailLocalHead -ne $MoeRailAcceptedCandidate -or
    $MoeRailLocalTagCommit -ne $MoeRailAcceptedCandidate) {
    throw 'Local branch or annotated tag differs from the accepted commit.'
}

git -C $MoeRailPrimary push --atomic origin `
    refs/heads/Prototyping:refs/heads/Prototyping `
    refs/tags/prototype-m3:refs/tags/prototype-m3
if ($LASTEXITCODE -ne 0) { throw 'Atomic prototype-m3 publication failed.' }

$MoeRailPublishedBranchRows = @(
    git -C $MoeRailPrimary ls-remote --heads origin refs/heads/Prototyping
)
$MoeRailPublishedBranchProbe = $LASTEXITCODE
$MoeRailPublishedTagRows = @(
    git -C $MoeRailPrimary ls-remote --tags origin refs/tags/prototype-m3 'refs/tags/prototype-m3^{}'
)
$MoeRailPublishedTagProbe = $LASTEXITCODE
$MoeRailPublishedDirectRows = @(
    $MoeRailPublishedTagRows | Where-Object { $_ -match 'refs/tags/prototype-m3$' }
)
$MoeRailPublishedPeeledRows = @(
    $MoeRailPublishedTagRows | Where-Object { $_ -match 'refs/tags/prototype-m3\^\{\}$' }
)
if ($MoeRailPublishedBranchProbe -ne 0 -or $MoeRailPublishedTagProbe -ne 0 -or
    $MoeRailPublishedBranchRows.Count -ne 1 -or
    $MoeRailPublishedDirectRows.Count -ne 1 -or
    $MoeRailPublishedPeeledRows.Count -ne 1) {
    throw 'Remote publication did not expose exactly one branch, tag object, and peeled tag row.'
}
$MoeRailPublishedBranch = ($MoeRailPublishedBranchRows[0] -split "`t")[0]
$MoeRailPublishedTagObject = (
    $MoeRailPublishedDirectRows |
        ForEach-Object { ($_ -split "`t")[0] }
)
$MoeRailPublishedPeeled = (
    $MoeRailPublishedPeeledRows |
        ForEach-Object { ($_ -split "`t")[0] }
)
if ($MoeRailPublishedBranch -ne $MoeRailAcceptedCandidate -or
    $MoeRailPublishedTagObject -ne $MoeRailLocalTagObject -or
    $MoeRailPublishedPeeled -ne $MoeRailAcceptedCandidate) {
    throw 'Remote branch, tag object, or peeled commit failed verification.'
}

$MoeRailApiBranch = (
    gh api repos/2ji1/Project_MoeRailWay/git/ref/heads/Prototyping --jq '.object.sha'
).Trim()
$MoeRailApiTagObject = (
    gh api repos/2ji1/Project_MoeRailWay/git/ref/tags/prototype-m3 --jq '.object.sha'
).Trim()
$MoeRailApiTagCommit = (
    gh api "repos/2ji1/Project_MoeRailWay/git/tags/$MoeRailApiTagObject" --jq '.object.sha'
).Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailApiBranch -ne $MoeRailAcceptedCandidate -or
    $MoeRailApiTagObject -ne $MoeRailLocalTagObject -or
    $MoeRailApiTagCommit -ne $MoeRailAcceptedCandidate) {
    throw 'GitHub API publication verification failed.'
}
$MoeRailPostPushStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
$MoeRailPostPushIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPostPushIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPostPushStatus).Count -ne 0) {
    $MoeRailPostPushStatus
    throw 'Primary protected status changed during publication.'
}
foreach ($MoeRailProtectedPath in $MoeRailProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected fingerprint changed during publication: $MoeRailProtectedPath"
    }
}
~~~

Report the remote branch commit, annotated tag object, peeled commit, atomic-push result, and GitHub API result. Create no additional commit or pull request. Keep the feature and candidate worktrees until the user accepts publication evidence; cleanup is a separate reversible-operations decision.

---

## Definition of Done

- `proto/02-track-train` starts from the approved planning commit on `Prototyping`, not from `main` or `Development`.
- The fixed default gate reports exactly `PASS: 14 prototype test suite(s)` plus every anchored integration and boot marker.
- The approved preparation, route reservation, construction, train, recovery, warning, cancellation, termination, logical-field, candidate, Inspector, and Windows-resize contracts are automated or manually evidenced as assigned above.
- Only right-click reserved-unbuilt cancellation is implemented; built-track paid demolition and crossings remain deferred to `proto/04-risk-investment`.
- No production abstraction pass occurs. The prototype remains concrete and leaves abstraction-scope decisions to later `Development` specifications.
- Every balance-sensitive value is Inspector-owned by its feature Resource or spatial node, while the active session reads only copied values.
- User-owned primary changes retain their exact status and SHA-256 fingerprints.
- Agent-facing Markdown is English; the paired user briefing is Korean and names this plan as canonical.
- Merge, annotated tag, and push remain separately approved and separately verified.
