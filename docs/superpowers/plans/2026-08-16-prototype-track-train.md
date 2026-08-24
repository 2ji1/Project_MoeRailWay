# Prototype Track and Train Implementation Plan

> **Historical status (2026-08-24):** This plan was delivered at commit `67518fc8dc4c106dfc6e20f901bcb2ef832efcb5` and accepted as tag `prototype-m3`. Its task checkboxes and amendment gates are retained as provenance and must not be resumed. The sole active route-replacement plan is `docs/superpowers/plans/2026-08-24-prototype-grid-track-amendment.md`; its supersession and deletion ledger identifies every active contract removed from this plan.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Execution boundary:** Tasks 1–3 are complete and Task 3 is clean, independently specification-and-quality-reviewed at commit `7bfeb914141aaefdb2fc05adcaa0b876ccc69267`; Task 4 must not start until the reviewed final post-commit gate and sixth-amendment adoption gate pass; Gate A, `Prototyping` integration, `prototype-m3` tag, push, PR, and cleanup remain unauthorized.

**Goal:** Deliver `prototype-m3` as a Windows mouse-driven prototype in which one seeded departure point starts an untimed build phase, the player reserves one continuous route, physical track constructs at a fixed rate, and one nonstopping train consumes and recovers finite track until regular expiry or built-track-end failure.

**Architecture:** Keep `PrototypeApp` as the concrete composition root. Inspector-authored feature Resources are validated and copied into `SessionStartConfig`; editor-authored `Marker2D` candidates remain scene nodes. `TrackSystem`, `TrainSystem`, and `SessionController` are concrete `RefCounted` domain objects advanced by explicit fixed ticks, while `TrackFieldView` maps mouse input into immutable tick values and renders detached snapshots with primitive Godot drawing. No interface hierarchy, graph model, physics body, navigation layer, or production abstraction is introduced.

**Tech Stack:** Godot `4.7.1.stable.official.a13da4feb`, GDScript, Godot Resource and scene files, the existing native `SceneTree` test harness, one first-party test-only `EditorPlugin`, PowerShell, Git

## Global Constraints

- The immutable code baseline is `4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97`, the approved track-and-train design commit on local `Prototyping`.
- The immutable feature starting plan commit is `4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1`. It is the one direct child of the code baseline, changes only this English plan and its Korean briefing, remains local `Prototyping`, and is the exact merge base for `proto/02-track-train`.
- The approved editor-gate design commit is `36730aa6bc6f05d7e01b96e79aff37ac73d0d11a`, whose parent is the immutable feature starting plan commit and whose only file is `docs/superpowers/specs/2026-08-17-prototype-track-train-editor-gate-amendment-design.md`.
- The first approved plan-amendment commit is `9047301da36c18b94e6e5be24d8dfd7423966828`. It is the direct child of the editor-gate design commit and changes only this English plan and its Korean briefing. Both first-amendment documentation commits entered the feature history through merge commit `b09aaaafe7b6be192776b49adc69c01e82e41bdc` without moving `Prototyping`.
- The approved second shutdown-amendment commit is `aaca77325acb3ecd722894f133c5319152554eb6`. It is the direct child of `9047301da36c18b94e6e5be24d8dfd7423966828`, changes only `docs/superpowers/specs/2026-08-21-prototype-track-train-editor-shutdown-amendment-design.md`, this English plan, and its Korean briefing, and entered the feature history through documentation merge `83ea845ca114f6803f24dd81a3d83f3ad97e2593` without moving `Prototyping`.
- The approved third disposable-editor-mirror amendment is supplied as `MOERAIL_APPROVED_THIRD_AMENDMENT` after independent review. It must be the direct child of `aaca77325acb3ecd722894f133c5319152554eb6` and change only `docs/superpowers/specs/2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md`, this English plan, and its Korean briefing. It enters the feature history only through the third amendment resume gate.
- The sixth-amendment documentation commit is the direct child of `1500db09f1797d3a5f461b655cfdebc61176130c`, changes exactly this canonical plan, and may enter feature history only through the adoption gate after independent review; the reviewed final Task 3 commit before adoption is `7bfeb914141aaefdb2fc05adcaa0b876ccc69267`.
- Dispatch every direct Task 2-9 implementation turn to the exact model `nvidia/nvidia-nemotron-3-ultra-550b-a55b`. Use `gpt-5.6-luna` only for required web research and a fresh `gpt-5.6-sol` agent for specification review followed by a separate fresh `gpt-5.6-sol` agent for quality review.
- The approved `proto/02-track-train` branch already exists only in the isolated worktree at `D:\godot\MoeRailWay-worktrees\proto-02-track-train`. Do not recreate, relocate, or substitute that worktree during amendment resume.
- Never branch from `main` or `Development`. Never merge `Prototyping` wholesale into `Development`.
- Preserve the primary worktree's user-owned changes in `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd`, `godot-project-moe-rail-way/tests/support/prototype_test.gd`, and `docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md`. Do not stage, format, copy, reset, or absorb them.
- Do not modify `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd` or `godot-project-moe-rail-way/tests/support/prototype_test.gd` on the feature branch. Add task-owned assertions to new test files.
- Preserve the existing public compatibility surface used by the protected boot test: `PrototypeBalance.session_duration_seconds`, `PrototypeBalance.simulation_ticks_per_second`, `create_session_start_config(seed)`, `SessionStartConfig.new(seed, duration, ticks)`, and an out-of-tree composed controller in `READY`.
- Target Windows PC, mouse-only input, the existing `1280x720` logical viewport, and supported 16:9 windows from `960x540` through `1920x1080`. Mobile, touch, and gamepad remain deferred.
- Keep the existing `canvas_items` plus `expand` stretch settings, Forward Plus renderer, and D3D12 Windows driver.
- Use `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe` and require the exact version string `4.7.1.stable.official.a13da4feb`.
- Run Godot verification with normal access to `user://logs`. A logging-denial signal 11 is an environment failure, not proof of a project regression.
- Do not terminate or reconfigure a user-owned Godot or Steam editor process.
- Every automated editor-mode command after the third amendment runs against a fresh ordinary-file project mirror selected from an approved, exact-snapshotted source's tracked plus untracked-nonignored project files. Task 2 uses its exact 20-path paused implementation source; pre-integration Task 9 uses a clean committed feature source; a separately authorized post-integration primary gate uses the clean candidate only after proving its committed tree equals primary `HEAD`, so no protected primary file is copied. Each child receives mirror-local `APPDATA`, `LOCALAPPDATA`, `TEMP`, and `TMP`; no mirror file is copied back.
- Add no third-party add-ons, test frameworks, custom art, custom fonts, final audio, mobile behavior, touch behavior, or gamepad behavior. The only permitted add-on is the repository-owned test-only editor gate at `res://addons/moerail_test_editor_gate/plugin.cfg`; it is not a production extension point.
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
- Every new tracked `.gd` file must have exactly one matching `.gd.uid` sidecar. Godot-serialized `.tscn`, `.tres`, `.gd.uid`, `plugin.cfg`, and project settings are covered by integration, validation, boot, UID, and diff gates rather than textual unit RED.
- Agent-facing Markdown remains English. Korean user-review documents remain under `docs/briefings/ko` and name this plan as their English source of truth.
- After every focused task commit, perform a fresh specification-compliance review and then a separate code/test-quality review. A finding is corrected in its own focused fix loop before the next task starts.
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

This is the immutable original preflight block that completed before implementation began. Retain it as provenance for the accepted baseline evidence, but do not rerun it after the branch and worktree exist. Use the amendment resume gate below instead. Each later command block remains independent and redeclares its paths.

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

## Approved Mid-Session Amendment Resume Gate

The original preflight above completed on 2026-08-17, Task 1 plus its focused validator-coverage correction are committed, and Task 2 is paused with an empty index. Do not rerun the original preflight now that the feature branch and worktree exist. Run this block exactly once only after the user approves the committed editor-gate amendment and set `MOERAIL_APPROVED_PLAN_AMENDMENT` to that reviewed commit's exact 40-character SHA.

This gate verifies the original base, remote, Godot version, protected primary state, reviewed documentation ancestry, and every paused Task 2 byte before it changes anything. It then performs the two user-approved cleanups: restore the indentation-only `prototype_app.gd` worktree change to feature `HEAD`, and remove the superseded untracked custom-`SceneTree` editor runner plus its sidecar. Finally, it merges the reviewed documentation branch without staging or absorbing any Task 2 work. Any mismatch stops the session; do not repair or recreate state automatically.

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailFeatureBranch = 'proto/02-track-train'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailStartingPlanCommit = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailTaskOneHead = '562499e639e6277a796fb6aeb1ac9581a0bb057e'
$MoeRailEditorGateDesignCommit = '36730aa6bc6f05d7e01b96e79aff37ac73d0d11a'
$MoeRailApprovedPlanAmendment = $env:MOERAIL_APPROVED_PLAN_AMENDMENT
$MoeRailMilestoneTwo = 'c93e1834da8fb38792048914120fe50f9f500cb4'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailDesignPath = 'docs/superpowers/specs/2026-08-17-prototype-track-train-editor-gate-amendment-design.md'
$MoeRailPrototypeAppPath = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
$MoeRailOldEditorRunnerPaths = @(
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd.uid'
)
$MoeRailExpectedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailExpectedProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}
$MoeRailExpectedPausedStatus = @(
    ' M godot-project-moe-rail-way/src/app/prototype_app.gd',
    ' M godot-project-moe-rail-way/src/domain/random/session_rng.gd',
    ' M godot-project-moe-rail-way/src/presentation/session/session_shell.gd',
    ' M godot-project-moe-rail-way/src/presentation/session/session_shell.tscn',
    ' M godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    ' M godot-project-moe-rail-way/tests/run_all.gd',
    '?? godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd',
    '?? godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd.uid',
    '?? godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd',
    '?? godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd.uid',
    '?? godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn',
    '?? godot-project-moe-rail-way/src/presentation/track/track_field_view.gd',
    '?? godot-project-moe-rail-way/src/presentation/track/track_field_view.gd.uid',
    '?? godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd',
    '?? godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd.uid',
    '?? godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd',
    '?? godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd.uid',
    '?? godot-project-moe-rail-way/tests/unit/test_departure_selection.gd',
    '?? godot-project-moe-rail-way/tests/unit/test_departure_selection.gd.uid'
) | Sort-Object
$MoeRailExpectedPausedHashes = [ordered]@{
    'godot-project-moe-rail-way/src/app/prototype_app.gd' = '0FA6071192B96D723FBE4B30AD0E41231721EFDE7E3B4DB349849FB28C2CA754'
    'godot-project-moe-rail-way/src/domain/random/session_rng.gd' = 'A6DD65CE62D79F12BF1CC4468817A2229B326D1421E78869BC0EA72B59921F9A'
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd' = '3A6C430A6843BBFB2C4CD303D42EC81F8A9D3BF841CB6EE9052B05DB40E89055'
    'godot-project-moe-rail-way/src/presentation/session/session_shell.tscn' = 'A398CC249EB00E8DEAA2CBE15544329509954EDE17C4DE4160BD41A4A0BE1DB8'
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd' = '6A5E2F3A5B9F7059BAA1DEFCF66F3EC3858EB56A0ECB66935A9052617AAE533C'
    'godot-project-moe-rail-way/tests/run_all.gd' = '18613C37E0EDFE005970D4D7E3CB9629208054C75661703A46ADA7E9BDC441E0'
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd' = 'C80DF8E8600B9C0074244A6C1CA2F2D64AAF0C4FB60C5882503B88DDAF097487'
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd.uid' = '5819ADA2633838E1A0223F4D9D92E3FC8B603ABCD6B09BAECF63583DBD844944'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd' = '441B3D01F41720E4E78C708EF3DAA13B1B5EB583B40173EA721B2676C97DEFC4'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd.uid' = 'EE710EFFC6C25810678E3DB68D9547061D7A360F0544F2CDB90891062C91F1C4'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn' = '6BADCE5FF383FE76E10C08DA31243C5F015EC5ACA8AA1459C4F9E442286B9C38'
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd' = '531FB9D6C42C8393A315DD88D6DF7D1FCAED70C0FA2143BB65E4EDFEED5449B7'
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd.uid' = 'CDE89B6A7D88CFBE5CCFDBF15C3D4626FCAB8B89C6516C46105B47FD0A87AC9F'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd' = 'D80309A74C33E972D606BA2FDCB5EFBDC7729A3A7C210D8ECE20B0A94D829571'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_editor_integration.gd.uid' = 'DCA4AC52873ECD3334685B746DCB97FE4F6BE7D5E2D5163ECECA8C38BD2EB39F'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd' = '75D13A0D627825DC2D9F98A3657A3B9627C95048929F8E5C585FC99BCEB9A5E8'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd.uid' = 'FFB4EBCA1126C7FE45B276E167DB622F64B2C3652951EA94F4EC6BEABFCAF7D0'
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd' = '8F78B62F1BB843E8D5692CD6731688D82311347D614EE955598EB9F27A88EBD7'
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd.uid' = 'AE555B0B5FAB095B0A9C98722A8455161D67E8CACFD67483DD35D77D6AE5E5D6'
}

if ($MoeRailApprovedPlanAmendment -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_APPROVED_PLAN_AMENDMENT to the reviewed amendment commit.'
}
$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPrimaryBranch -ne 'Prototyping' -or
    $MoeRailPrimaryHead -ne $MoeRailStartingPlanCommit -or
    $MoeRailPrimaryIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary identity, index, or protected status changed while Task 2 was paused.'
}
foreach ($MoeRailProtectedPath in $MoeRailExpectedProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) `
            -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected primary fingerprint changed: $MoeRailProtectedPath"
    }
}

$MoeRailTagCommit = (git -C $MoeRailPrimary rev-list -n 1 prototype-m2).Trim()
$MoeRailRemoteRows = @(
    git -C $MoeRailPrimary ls-remote --heads origin refs/heads/Prototyping
)
$MoeRailRemoteCommit = if ($MoeRailRemoteRows.Count -eq 1) {
    ($MoeRailRemoteRows[0] -split "`t")[0]
} else {
    ''
}
$MoeRailVersionOutput = @(& $MoeRailGodotExe --version 2>&1)
$MoeRailVersionExit = $LASTEXITCODE
$MoeRailVersion = ($MoeRailVersionOutput -join "`n").Trim()
$MoeRailCodeParent = (git -C $MoeRailPrimary rev-parse "$MoeRailCodeBase^").Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailVersionExit -ne 0 -or
    $MoeRailTagCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailRemoteRows.Count -ne 1 -or
    $MoeRailRemoteCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailCodeParent -ne $MoeRailMilestoneTwo -or
    $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw 'prototype-m2, origin/Prototyping, the code baseline, or the exact Godot build changed.'
}

$MoeRailPlanParent = (git -C $MoeRailPrimary rev-parse "$MoeRailStartingPlanCommit^").Trim()
$MoeRailPlanFiles = @(
    git -C $MoeRailPrimary diff-tree --no-commit-id --name-only -r `
        $MoeRailStartingPlanCommit | Sort-Object
)
$MoeRailDesignParent = (git -C $MoeRailPrimary rev-parse "$MoeRailEditorGateDesignCommit^").Trim()
$MoeRailDesignFiles = @(
    git -C $MoeRailPrimary diff-tree --no-commit-id --name-only -r `
        $MoeRailEditorGateDesignCommit | Sort-Object
)
$MoeRailAmendmentParent = (git -C $MoeRailPrimary rev-parse "$MoeRailApprovedPlanAmendment^").Trim()
$MoeRailAmendmentFiles = @(
    git -C $MoeRailPrimary diff-tree --no-commit-id --name-only -r `
        $MoeRailApprovedPlanAmendment | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPlanParent -ne $MoeRailCodeBase -or
    @(Compare-Object @($MoeRailPlanPath, $MoeRailBriefPath) $MoeRailPlanFiles).Count -ne 0 -or
    $MoeRailDesignParent -ne $MoeRailStartingPlanCommit -or
    @(Compare-Object @($MoeRailDesignPath) $MoeRailDesignFiles).Count -ne 0 -or
    $MoeRailAmendmentParent -ne $MoeRailEditorGateDesignCommit -or
    @(Compare-Object @($MoeRailPlanPath, $MoeRailBriefPath) $MoeRailAmendmentFiles).Count -ne 0) {
    $MoeRailDesignFiles
    $MoeRailAmendmentFiles
    throw 'The reviewed design or plan-amendment ancestry and file scope changed.'
}

$MoeRailFeatureCurrentBranch = (git -C $MoeRailFeatureWorktree branch --show-current).Trim()
$MoeRailFeatureHead = (git -C $MoeRailFeatureWorktree rev-parse HEAD).Trim()
$MoeRailFeatureBase = (git -C $MoeRailFeatureWorktree merge-base `
    $MoeRailStartingPlanCommit HEAD).Trim()
$MoeRailFeatureIndex = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
$MoeRailFeatureStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all |
        Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailFeatureCurrentBranch -ne $MoeRailFeatureBranch -or
    $MoeRailFeatureHead -ne $MoeRailTaskOneHead -or
    $MoeRailFeatureBase -ne $MoeRailStartingPlanCommit -or
    $MoeRailFeatureIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPausedStatus $MoeRailFeatureStatus).Count -ne 0) {
    $MoeRailFeatureStatus
    throw 'The paused Task 2 branch, HEAD, index, or exact path set changed.'
}
foreach ($MoeRailPausedPath in $MoeRailExpectedPausedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailPausedPath) `
            -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedPausedHashes[$MoeRailPausedPath]) {
        throw "Paused Task 2 file changed: $MoeRailPausedPath"
    }
}

git -C $MoeRailFeatureWorktree diff --ignore-all-space --quiet HEAD -- `
    $MoeRailPrototypeAppPath
if ($LASTEXITCODE -ne 0) {
    throw 'prototype_app.gd is no longer the authorized indentation-only change.'
}
git -C $MoeRailFeatureWorktree restore --source=HEAD --worktree -- `
    $MoeRailPrototypeAppPath
if ($LASTEXITCODE -ne 0) { throw 'Failed to restore only prototype_app.gd.' }
foreach ($MoeRailOldEditorRunnerPath in $MoeRailOldEditorRunnerPaths) {
    git -C $MoeRailFeatureWorktree ls-files --error-unmatch -- `
        $MoeRailOldEditorRunnerPath *> $null
    $MoeRailOldEditorRunnerProbe = $LASTEXITCODE
    if ($MoeRailOldEditorRunnerProbe -eq 0) {
        throw "Superseded editor runner unexpectedly became tracked: $MoeRailOldEditorRunnerPath"
    } elseif ($MoeRailOldEditorRunnerProbe -ne 1) {
        throw "Failed to verify superseded editor runner ownership: $MoeRailOldEditorRunnerPath"
    }
    $MoeRailOldEditorRunnerAbsolute = Join-Path `
        $MoeRailFeatureWorktree $MoeRailOldEditorRunnerPath
    Remove-Item -LiteralPath $MoeRailOldEditorRunnerAbsolute -Force
    if (Test-Path -LiteralPath $MoeRailOldEditorRunnerAbsolute) {
        throw "Failed to remove superseded untracked runner: $MoeRailOldEditorRunnerPath"
    }
}

$MoeRailExpectedCleanedStatus = @(
    $MoeRailExpectedPausedStatus | Where-Object {
        $_ -notmatch [regex]::Escape($MoeRailPrototypeAppPath) -and
        $_ -notmatch 'run_logical_track_field_editor_integration\.gd(?:\.uid)?$'
    }
) | Sort-Object
$MoeRailCleanedStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all |
        Sort-Object
)
if (@(Compare-Object $MoeRailExpectedCleanedStatus $MoeRailCleanedStatus).Count -ne 0 -or
    @(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) {
    $MoeRailCleanedStatus
    throw 'The approved Task 2 cleanup changed an unexpected path.'
}

git -C $MoeRailFeatureWorktree merge --no-ff $MoeRailApprovedPlanAmendment `
    -m 'docs: adopt editor gate amendment'
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to merge the reviewed documentation amendment.'
}
$MoeRailAmendmentMergeHead = (git -C $MoeRailFeatureWorktree rev-parse HEAD).Trim()
$MoeRailMergeFirstParent = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^1').Trim()
$MoeRailMergeSecondParent = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^2').Trim()
$MoeRailMergedDocPaths = @(
    git -C $MoeRailFeatureWorktree diff --name-only `
        "$MoeRailMergeFirstParent..$MoeRailAmendmentMergeHead" | Sort-Object
)
$MoeRailExpectedMergedDocPaths = @(
    $MoeRailDesignPath,
    $MoeRailPlanPath,
    $MoeRailBriefPath
) | Sort-Object
$MoeRailPostMergeStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all |
        Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailMergeFirstParent -ne $MoeRailTaskOneHead -or
    $MoeRailMergeSecondParent -ne $MoeRailApprovedPlanAmendment -or
    @(Compare-Object $MoeRailExpectedMergedDocPaths $MoeRailMergedDocPaths).Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedCleanedStatus $MoeRailPostMergeStatus).Count -ne 0 -or
    @(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) {
    $MoeRailMergedDocPaths
    $MoeRailPostMergeStatus
    throw 'The documentation merge absorbed Task 2 work or has unexpected ancestry.'
}
foreach ($MoeRailPausedPath in $MoeRailExpectedPausedHashes.Keys) {
    if ($MoeRailPausedPath -eq $MoeRailPrototypeAppPath -or
        $MoeRailPausedPath -in $MoeRailOldEditorRunnerPaths) {
        continue
    }
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailPausedPath) `
            -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedPausedHashes[$MoeRailPausedPath]) {
        throw "Documentation merge changed Task 2 work: $MoeRailPausedPath"
    }
}
$MoeRailFinalPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailFinalPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailFinalPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
$MoeRailFinalPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all |
        Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailFinalPrimaryBranch -ne 'Prototyping' -or
    $MoeRailFinalPrimaryHead -ne $MoeRailStartingPlanCommit -or
    $MoeRailFinalPrimaryIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailFinalPrimaryStatus).Count -ne 0) {
    $MoeRailFinalPrimaryStatus
    throw 'Primary identity, index, or protected path set changed during amendment resume.'
}
foreach ($MoeRailProtectedPath in $MoeRailExpectedProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) `
            -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected primary fingerprint changed during amendment resume: $MoeRailProtectedPath"
    }
}
"AMENDMENT_MERGE_SHA=$MoeRailAmendmentMergeHead"
~~~

Expected: the obsolete agent-owned custom-`SceneTree` runner and its sidecar are removed, `prototype_app.gd` exactly matches the Task 1 feature `HEAD`, the reviewed design and amendment commits are ancestors of one focused documentation merge, the sixteen retained Task 2 files remain byte-identical and unstaged, the index is empty, and the primary protected state is unchanged. Record `AMENDMENT_MERGE_SHA` in the English task ledger before continuing.

Resume the English local task ledger under the feature worktree's ignored `.superpowers/sdd/2026-08-16-prototype-track-train/` directory. This operational evidence is never staged and is outside the Target File Map. Execute tasks serially with a fresh implementer and two-stage review when `superpowers:subagent-driven-development` is available. Otherwise use `superpowers:executing-plans` and preserve the same RED/GREEN, focused-commit, and independent-review gates.

## Approved Second Amendment Resume Gate

The first amendment merge is complete, its replacement plugin has been implemented but not committed, and the exact shutdown contract failed after printing PASS. The user approved the second shutdown amendment and authorized restoring only the import-created whitespace rewrite of `src/app/prototype_app.gd`; that exact-path restore is already recorded in the ignored English Task 2 ledger. Do not rerun the first amendment gate or the import that created the existing valid plugin sidecar.

After the second amendment documentation commit passes independent review, set `MOERAIL_APPROVED_SECOND_AMENDMENT` to its exact 40-character SHA and run this block verbatim. It rechecks the original base, remote, Godot version, protected primary state, documentation ancestry, exact 20-path Task 2 state, every WIP hash, the empty feature index, and the already-restored `prototype_app.gd` before merging only the second documentation amendment. Any mismatch stops the session without repair.

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailFeatureBranch = 'proto/02-track-train'
$MoeRailStartingPlanCommit = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailFirstAmendmentCommit = '9047301da36c18b94e6e5be24d8dfd7423966828'
$MoeRailPausedFeatureHead = 'b09aaaafe7b6be192776b49adc69c01e82e41bdc'
$MoeRailApprovedSecondAmendment = $env:MOERAIL_APPROVED_SECOND_AMENDMENT
$MoeRailMilestoneTwo = 'c93e1834da8fb38792048914120fe50f9f500cb4'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailSecondDesignPath = 'docs/superpowers/specs/2026-08-21-prototype-track-train-editor-shutdown-amendment-design.md'
$MoeRailPrototypeAppPath = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
$MoeRailExpectedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailExpectedProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}
$MoeRailExpectedTaskTwoHashes = [ordered]@{
    'godot-project-moe-rail-way/project.godot' = '23B8A22A772AFCB231C9E00ADA70E791B704640607927D3B2924E0FF5DC0D324'
    'godot-project-moe-rail-way/src/domain/random/session_rng.gd' = 'A6DD65CE62D79F12BF1CC4468817A2229B326D1421E78869BC0EA72B59921F9A'
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd' = '3A6C430A6843BBFB2C4CD303D42EC81F8A9D3BF841CB6EE9052B05DB40E89055'
    'godot-project-moe-rail-way/src/presentation/session/session_shell.tscn' = 'A398CC249EB00E8DEAA2CBE15544329509954EDE17C4DE4160BD41A4A0BE1DB8'
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd' = '6A5E2F3A5B9F7059BAA1DEFCF66F3EC3858EB56A0ECB66935A9052617AAE533C'
    'godot-project-moe-rail-way/tests/run_all.gd' = '18613C37E0EDFE005970D4D7E3CB9629208054C75661703A46ADA7E9BDC441E0'
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd' = '648F9DB7B725E101876E40F586127A16B06821E22E223F1B4B26FE7FA97C741C'
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd.uid' = '6A6D4575B585A148C4456FC7C08EB3977769F97A36AA0459571B176A77D72214'
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/plugin.cfg' = 'CEB518D10044BCB5CC9A51A9FB41334D49F76264F285BA1580A4DA973CF36173'
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd' = 'C80DF8E8600B9C0074244A6C1CA2F2D64AAF0C4FB60C5882503B88DDAF097487'
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd.uid' = '5819ADA2633838E1A0223F4D9D92E3FC8B603ABCD6B09BAECF63583DBD844944'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd' = '441B3D01F41720E4E78C708EF3DAA13B1B5EB583B40173EA721B2676C97DEFC4'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd.uid' = 'EE710EFFC6C25810678E3DB68D9547061D7A360F0544F2CDB90891062C91F1C4'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn' = '6BADCE5FF383FE76E10C08DA31243C5F015EC5ACA8AA1459C4F9E442286B9C38'
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd' = '531FB9D6C42C8393A315DD88D6DF7D1FCAED70C0FA2143BB65E4EDFEED5449B7'
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd.uid' = 'CDE89B6A7D88CFBE5CCFDBF15C3D4626FCAB8B89C6516C46105B47FD0A87AC9F'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd' = '75D13A0D627825DC2D9F98A3657A3B9627C95048929F8E5C585FC99BCEB9A5E8'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd.uid' = 'FFB4EBCA1126C7FE45B276E167DB622F64B2C3652951EA94F4EC6BEABFCAF7D0'
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd' = '8F78B62F1BB843E8D5692CD6731688D82311347D614EE955598EB9F27A88EBD7'
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd.uid' = 'AE555B0B5FAB095B0A9C98722A8455161D67E8CACFD67483DD35D77D6AE5E5D6'
}
$MoeRailExpectedTaskTwoStatus = @(
    foreach ($MoeRailTaskTwoPath in $MoeRailExpectedTaskTwoHashes.Keys) {
        git -C $MoeRailFeatureWorktree ls-files --error-unmatch -- $MoeRailTaskTwoPath *> $null
        if ($LASTEXITCODE -eq 0) { " M $MoeRailTaskTwoPath" } else { "?? $MoeRailTaskTwoPath" }
    }
) | Sort-Object

if ($MoeRailApprovedSecondAmendment -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_APPROVED_SECOND_AMENDMENT to the reviewed second amendment commit.'
}
$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPrimaryBranch -ne 'Prototyping' -or
    $MoeRailPrimaryHead -ne $MoeRailStartingPlanCommit -or
    $MoeRailPrimaryIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary identity, index, or protected state changed before second amendment resume.'
}
foreach ($MoeRailProtectedPath in $MoeRailExpectedProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected primary fingerprint changed: $MoeRailProtectedPath"
    }
}
$MoeRailTagCommit = (git -C $MoeRailPrimary rev-list -n 1 prototype-m2).Trim()
$MoeRailRemoteRows = @(git -C $MoeRailPrimary ls-remote --heads origin refs/heads/Prototyping)
$MoeRailRemoteCommit = if ($MoeRailRemoteRows.Count -eq 1) {
    ($MoeRailRemoteRows[0] -split "`t")[0]
} else { '' }
$MoeRailCodeParent = (git -C $MoeRailPrimary rev-parse "$MoeRailCodeBase^").Trim()
$MoeRailVersion = ((& $MoeRailGodotExe --version 2>&1) -join "`n").Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailTagCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailRemoteRows.Count -ne 1 -or
    $MoeRailRemoteCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailCodeParent -ne $MoeRailMilestoneTwo -or
    $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw 'Base, remote, prototype-m2, or exact Godot build changed.'
}

$MoeRailSecondAmendmentParent = (
    git -C $MoeRailPrimary rev-parse "$MoeRailApprovedSecondAmendment^"
).Trim()
$MoeRailSecondAmendmentFiles = @(
    git -C $MoeRailPrimary diff-tree --no-commit-id --name-only -r `
        $MoeRailApprovedSecondAmendment | Sort-Object
)
$MoeRailExpectedSecondAmendmentFiles = @(
    $MoeRailSecondDesignPath,
    $MoeRailPlanPath,
    $MoeRailBriefPath
) | Sort-Object
if ($LASTEXITCODE -ne 0 -or
    $MoeRailSecondAmendmentParent -ne $MoeRailFirstAmendmentCommit -or
    @(Compare-Object $MoeRailExpectedSecondAmendmentFiles $MoeRailSecondAmendmentFiles).Count -ne 0) {
    $MoeRailSecondAmendmentFiles
    throw 'Second amendment ancestry or file scope changed.'
}

$MoeRailFeatureRoot = (git -C $MoeRailFeatureWorktree rev-parse --show-toplevel).Trim()
$MoeRailFeatureCurrentBranch = (git -C $MoeRailFeatureWorktree branch --show-current).Trim()
$MoeRailFeatureHead = (git -C $MoeRailFeatureWorktree rev-parse HEAD).Trim()
$MoeRailFeatureBase = (
    git -C $MoeRailFeatureWorktree merge-base $MoeRailStartingPlanCommit HEAD
).Trim()
$MoeRailFeatureIndex = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
$MoeRailFeatureStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailFeatureRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailFeatureCurrentBranch -ne $MoeRailFeatureBranch -or
    $MoeRailFeatureHead -ne $MoeRailPausedFeatureHead -or
    $MoeRailFeatureBase -ne $MoeRailStartingPlanCommit -or
    $MoeRailFeatureIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedTaskTwoStatus $MoeRailFeatureStatus).Count -ne 0) {
    $MoeRailFeatureStatus
    throw 'Paused Task 2 identity, index, or exact path set changed.'
}
git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeAppPath
if ($LASTEXITCODE -ne 0) {
    throw 'prototype_app.gd no longer matches feature HEAD.'
}
foreach ($MoeRailTaskTwoPath in $MoeRailExpectedTaskTwoHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailTaskTwoPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedTaskTwoHashes[$MoeRailTaskTwoPath]) {
        throw "Paused Task 2 file changed: $MoeRailTaskTwoPath"
    }
}

git -C $MoeRailFeatureWorktree -c merge.autostash=false merge `
    --no-ff --no-autostash $MoeRailApprovedSecondAmendment `
    -m 'docs: adopt editor shutdown amendment'
if ($LASTEXITCODE -ne 0) { throw 'Failed to merge the second documentation amendment.' }
$MoeRailSecondMergeHead = (git -C $MoeRailFeatureWorktree rev-parse HEAD).Trim()
$MoeRailMergeFirstParent = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^1').Trim()
$MoeRailMergeSecondParent = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^2').Trim()
$MoeRailMergedDocPaths = @(
    git -C $MoeRailFeatureWorktree diff --name-only `
        "$MoeRailMergeFirstParent..$MoeRailSecondMergeHead" | Sort-Object
)
$MoeRailPostMergeStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailMergeFirstParent -ne $MoeRailPausedFeatureHead -or
    $MoeRailMergeSecondParent -ne $MoeRailApprovedSecondAmendment -or
    @(Compare-Object $MoeRailExpectedSecondAmendmentFiles $MoeRailMergedDocPaths).Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedTaskTwoStatus $MoeRailPostMergeStatus).Count -ne 0 -or
    @(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) {
    $MoeRailMergedDocPaths
    $MoeRailPostMergeStatus
    throw 'Second documentation merge absorbed Task 2 work or has unexpected ancestry.'
}
git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeAppPath
if ($LASTEXITCODE -ne 0) { throw 'Second documentation merge changed prototype_app.gd.' }
foreach ($MoeRailTaskTwoPath in $MoeRailExpectedTaskTwoHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailTaskTwoPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedTaskTwoHashes[$MoeRailTaskTwoPath]) {
        throw "Second documentation merge changed Task 2 work: $MoeRailTaskTwoPath"
    }
}
$MoeRailFinalPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ((git -C $MoeRailPrimary branch --show-current).Trim() -ne 'Prototyping' -or
    (git -C $MoeRailPrimary rev-parse HEAD).Trim() -ne $MoeRailStartingPlanCommit -or
    @(git -C $MoeRailPrimary diff --cached --name-only).Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailFinalPrimaryStatus).Count -ne 0) {
    $MoeRailFinalPrimaryStatus
    throw 'Primary state changed during second amendment resume.'
}
foreach ($MoeRailProtectedPath in $MoeRailExpectedProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected primary fingerprint changed during second amendment resume: $MoeRailProtectedPath"
    }
}
"SECOND_AMENDMENT_MERGE_SHA=$MoeRailSecondMergeHead"
~~~

Expected: the reviewed three-document second amendment enters one focused merge, all 20 paused Task 2 files remain byte-identical and unstaged, `prototype_app.gd` remains identical to feature `HEAD`, the feature index stays empty, and the primary protected state is unchanged. Record `SECOND_AMENDMENT_MERGE_SHA` in the ignored English task ledger before dispatching the fresh Task 2 implementation agent.

## Approved Third Amendment Resume Gate

The second amendment documentation merge is complete, the assertion-only plugin is implemented but uncommitted, and the flagged editor assertions and engine-owned shutdown are clean. The strict post-process state check correctly rejected a new whitespace-only rewrite of `src/app/prototype_app.gd`. The user approved the disposable-editor-mirror amendment and authorized restoring exactly that one preserved rewrite to feature `HEAD`. Do not rerun either earlier amendment gate or any feature-worktree editor process.

After the third amendment documentation commit passes independent specification and quality review, set `MOERAIL_APPROVED_THIRD_AMENDMENT` to its exact 40-character SHA and run this block verbatim. It rechecks the original base, remote, Godot version, protected primary state, documentation ancestry, exact 21-path paused evidence, every WIP hash, the empty feature index, and the exact whitespace-only prototype rewrite before changing anything. It then restores only the approved file, merges only the three reviewed documents with autostash disabled, and repeats every invariant. Any mismatch stops the session without repair.

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailFeatureBranch = 'proto/02-track-train'
$MoeRailStartingPlanCommit = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailFirstAmendmentCommit = '9047301da36c18b94e6e5be24d8dfd7423966828'
$MoeRailSecondAmendmentCommit = 'aaca77325acb3ecd722894f133c5319152554eb6'
$MoeRailPausedFeatureHead = '83ea845ca114f6803f24dd81a3d83f3ad97e2593'
$MoeRailPausedFirstParent = 'b09aaaafe7b6be192776b49adc69c01e82e41bdc'
$MoeRailApprovedThirdAmendment = $env:MOERAIL_APPROVED_THIRD_AMENDMENT
$MoeRailMilestoneTwo = 'c93e1834da8fb38792048914120fe50f9f500cb4'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailThirdDesignPath = 'docs/superpowers/specs/2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md'
$MoeRailPrototypeAppPath = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
$MoeRailExpectedPrototypeHeadBlob = '2088b43ffdd8510eadb4682746a11c948c8f8aee'
$MoeRailExpectedPrototypeRewriteBlob = 'a3228bb9b6d8f1b2546bd026ac02aef11d755710'
$MoeRailExpectedPrototypeHeadHash = 'C60283885338A45C975EC8250FC3285D18DAD5879E7CBD38E272E3BAACDA6CEF'
$MoeRailExpectedPrototypeRewriteHash = '0FA6071192B96D723FBE4B30AD0E41231721EFDE7E3B4DB349849FB28C2CA754'
$MoeRailExpectedPrimaryStatus = @(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
) | Sort-Object
$MoeRailExpectedProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}
$MoeRailExpectedTaskTwoHashes = [ordered]@{
    'godot-project-moe-rail-way/project.godot' = '23B8A22A772AFCB231C9E00ADA70E791B704640607927D3B2924E0FF5DC0D324'
    'godot-project-moe-rail-way/src/domain/random/session_rng.gd' = 'A6DD65CE62D79F12BF1CC4468817A2229B326D1421E78869BC0EA72B59921F9A'
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd' = '3A6C430A6843BBFB2C4CD303D42EC81F8A9D3BF841CB6EE9052B05DB40E89055'
    'godot-project-moe-rail-way/src/presentation/session/session_shell.tscn' = 'A398CC249EB00E8DEAA2CBE15544329509954EDE17C4DE4160BD41A4A0BE1DB8'
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd' = '6A5E2F3A5B9F7059BAA1DEFCF66F3EC3858EB56A0ECB66935A9052617AAE533C'
    'godot-project-moe-rail-way/tests/run_all.gd' = '18613C37E0EDFE005970D4D7E3CB9629208054C75661703A46ADA7E9BDC441E0'
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd' = '38BBCD8901234B3E6F43DB5958FC026865EA151675F353A20218ADEB7FB745ED'
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd.uid' = '6A6D4575B585A148C4456FC7C08EB3977769F97A36AA0459571B176A77D72214'
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/plugin.cfg' = 'CEB518D10044BCB5CC9A51A9FB41334D49F76264F285BA1580A4DA973CF36173'
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd' = 'C80DF8E8600B9C0074244A6C1CA2F2D64AAF0C4FB60C5882503B88DDAF097487'
    'godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd.uid' = '5819ADA2633838E1A0223F4D9D92E3FC8B603ABCD6B09BAECF63583DBD844944'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd' = '441B3D01F41720E4E78C708EF3DAA13B1B5EB583B40173EA721B2676C97DEFC4'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd.uid' = 'EE710EFFC6C25810678E3DB68D9547061D7A360F0544F2CDB90891062C91F1C4'
    'godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn' = '6BADCE5FF383FE76E10C08DA31243C5F015EC5ACA8AA1459C4F9E442286B9C38'
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd' = '531FB9D6C42C8393A315DD88D6DF7D1FCAED70C0FA2143BB65E4EDFEED5449B7'
    'godot-project-moe-rail-way/src/presentation/track/track_field_view.gd.uid' = 'CDE89B6A7D88CFBE5CCFDBF15C3D4626FCAB8B89C6516C46105B47FD0A87AC9F'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd' = '75D13A0D627825DC2D9F98A3657A3B9627C95048929F8E5C585FC99BCEB9A5E8'
    'godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd.uid' = 'FFB4EBCA1126C7FE45B276E167DB622F64B2C3652951EA94F4EC6BEABFCAF7D0'
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd' = '8F78B62F1BB843E8D5692CD6731688D82311347D614EE955598EB9F27A88EBD7'
    'godot-project-moe-rail-way/tests/unit/test_departure_selection.gd.uid' = 'AE555B0B5FAB095B0A9C98722A8455161D67E8CACFD67483DD35D77D6AE5E5D6'
}
$MoeRailExpectedTaskTwoStatus = @(
    foreach ($MoeRailTaskTwoPath in $MoeRailExpectedTaskTwoHashes.Keys) {
        git -C $MoeRailFeatureWorktree ls-files --error-unmatch -- $MoeRailTaskTwoPath *> $null
        if ($LASTEXITCODE -eq 0) { " M $MoeRailTaskTwoPath" } else { "?? $MoeRailTaskTwoPath" }
    }
) | Sort-Object
$MoeRailExpectedPausedStatus = @(
    $MoeRailExpectedTaskTwoStatus
    " M $MoeRailPrototypeAppPath"
) | Sort-Object

if ($MoeRailApprovedThirdAmendment -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_APPROVED_THIRD_AMENDMENT to the reviewed third amendment commit.'
}
$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
$MoeRailPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailPrimaryBranch -ne 'Prototyping' -or
    $MoeRailPrimaryHead -ne $MoeRailStartingPlanCommit -or
    $MoeRailPrimaryIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailPrimaryStatus).Count -ne 0) {
    $MoeRailPrimaryStatus
    throw 'Primary identity, index, or protected state changed before third amendment resume.'
}
foreach ($MoeRailProtectedPath in $MoeRailExpectedProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected primary fingerprint changed: $MoeRailProtectedPath"
    }
}
$MoeRailTagCommit = (git -C $MoeRailPrimary rev-list -n 1 prototype-m2).Trim()
$MoeRailRemoteRows = @(git -C $MoeRailPrimary ls-remote --heads origin refs/heads/Prototyping)
$MoeRailRemoteCommit = if ($MoeRailRemoteRows.Count -eq 1) {
    ($MoeRailRemoteRows[0] -split "`t")[0]
} else { '' }
$MoeRailCodeParent = (git -C $MoeRailPrimary rev-parse "$MoeRailCodeBase^").Trim()
$MoeRailVersion = ((& $MoeRailGodotExe --version 2>&1) -join "`n").Trim()
if ($LASTEXITCODE -ne 0 -or
    $MoeRailTagCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailRemoteRows.Count -ne 1 -or
    $MoeRailRemoteCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailCodeParent -ne $MoeRailMilestoneTwo -or
    $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw 'Base, remote, prototype-m2, or exact Godot build changed.'
}

$MoeRailThirdAmendmentParent = (
    git -C $MoeRailPrimary rev-parse "$MoeRailApprovedThirdAmendment^"
).Trim()
$MoeRailThirdAmendmentParentTokens = @(
    (git -C $MoeRailPrimary rev-list --parents -n 1 `
        $MoeRailApprovedThirdAmendment).Trim() -split '\s+'
)
$MoeRailThirdAmendmentFiles = @(
    git -C $MoeRailPrimary diff-tree --no-commit-id --name-only -r `
        $MoeRailApprovedThirdAmendment | Sort-Object
)
$MoeRailExpectedThirdAmendmentFiles = @(
    $MoeRailThirdDesignPath,
    $MoeRailPlanPath,
    $MoeRailBriefPath
) | Sort-Object
if ($LASTEXITCODE -ne 0 -or
    $MoeRailThirdAmendmentParentTokens.Count -ne 2 -or
    $MoeRailThirdAmendmentParent -ne $MoeRailSecondAmendmentCommit -or
    @(Compare-Object $MoeRailExpectedThirdAmendmentFiles $MoeRailThirdAmendmentFiles).Count -ne 0) {
    $MoeRailThirdAmendmentFiles
    throw 'Third amendment ancestry or file scope changed.'
}

$MoeRailFeatureRoot = (git -C $MoeRailFeatureWorktree rev-parse --show-toplevel).Trim()
$MoeRailFeatureCurrentBranch = (git -C $MoeRailFeatureWorktree branch --show-current).Trim()
$MoeRailFeatureHead = (git -C $MoeRailFeatureWorktree rev-parse HEAD).Trim()
$MoeRailFeatureBase = (
    git -C $MoeRailFeatureWorktree merge-base $MoeRailStartingPlanCommit HEAD
).Trim()
$MoeRailFeatureIndex = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
$MoeRailFeatureStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all | Sort-Object
)
$MoeRailPausedSecondParent = (
    git -C $MoeRailFeatureWorktree rev-parse 'HEAD^2'
).Trim()
$MoeRailPausedActualFirstParent = (
    git -C $MoeRailFeatureWorktree rev-parse 'HEAD^1'
).Trim()
if ($LASTEXITCODE -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailFeatureRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailFeatureCurrentBranch -ne $MoeRailFeatureBranch -or
    $MoeRailFeatureHead -ne $MoeRailPausedFeatureHead -or
    $MoeRailFeatureBase -ne $MoeRailStartingPlanCommit -or
    $MoeRailPausedActualFirstParent -ne $MoeRailPausedFirstParent -or
    $MoeRailPausedSecondParent -ne $MoeRailSecondAmendmentCommit -or
    $MoeRailFeatureIndex.Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPausedStatus $MoeRailFeatureStatus).Count -ne 0) {
    $MoeRailFeatureStatus
    throw 'Paused Task 2 identity, ancestry, index, or exact evidence path set changed.'
}
foreach ($MoeRailTaskTwoPath in $MoeRailExpectedTaskTwoHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailTaskTwoPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedTaskTwoHashes[$MoeRailTaskTwoPath]) {
        throw "Paused Task 2 file changed: $MoeRailTaskTwoPath"
    }
}
$MoeRailPrototypeNumstat = @(
    git -C $MoeRailFeatureWorktree diff --numstat HEAD -- $MoeRailPrototypeAppPath
)
git -C $MoeRailFeatureWorktree diff --ignore-all-space --quiet HEAD -- $MoeRailPrototypeAppPath
$MoeRailPrototypeWhitespaceExit = $LASTEXITCODE
$MoeRailPrototypeHeadBlob = (
    git -C $MoeRailFeatureWorktree rev-parse "HEAD:$MoeRailPrototypeAppPath"
).Trim()
$MoeRailPrototypeRewriteBlob = (
    git -C $MoeRailFeatureWorktree hash-object $MoeRailPrototypeAppPath
).Trim()
$MoeRailPrototypeRewriteHash = (
    Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailPrototypeAppPath) -Algorithm SHA256
).Hash
if ($MoeRailPrototypeNumstat.Count -ne 1 -or
    $MoeRailPrototypeNumstat[0] -notmatch '^54\s+54\s+' -or
    $MoeRailPrototypeWhitespaceExit -ne 0 -or
    $MoeRailPrototypeHeadBlob -ne $MoeRailExpectedPrototypeHeadBlob -or
    $MoeRailPrototypeRewriteBlob -ne $MoeRailExpectedPrototypeRewriteBlob -or
    $MoeRailPrototypeRewriteHash -ne $MoeRailExpectedPrototypeRewriteHash) {
    $MoeRailPrototypeNumstat
    throw 'prototype_app.gd is no longer the exact authorized whitespace-only evidence.'
}

git -C $MoeRailFeatureWorktree restore --source=HEAD --worktree -- $MoeRailPrototypeAppPath
if ($LASTEXITCODE -ne 0) { throw 'Failed to restore only prototype_app.gd.' }
$MoeRailRestoredStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all | Sort-Object
)
$MoeRailRestoredPrototypeHash = (
    Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailPrototypeAppPath) -Algorithm SHA256
).Hash
if (@(Compare-Object $MoeRailExpectedTaskTwoStatus $MoeRailRestoredStatus).Count -ne 0 -or
    @(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0 -or
    $MoeRailRestoredPrototypeHash -ne $MoeRailExpectedPrototypeHeadHash) {
    $MoeRailRestoredStatus
    throw 'Exact prototype restore changed an unauthorized path or content.'
}
foreach ($MoeRailTaskTwoPath in $MoeRailExpectedTaskTwoHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailTaskTwoPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedTaskTwoHashes[$MoeRailTaskTwoPath]) {
        throw "Exact prototype restore changed Task 2 work: $MoeRailTaskTwoPath"
    }
}

git -C $MoeRailFeatureWorktree -c merge.autostash=false merge `
    --no-ff --no-autostash $MoeRailApprovedThirdAmendment `
    -m 'docs: adopt disposable editor mirror amendment'
if ($LASTEXITCODE -ne 0) { throw 'Failed to merge the third documentation amendment.' }
$MoeRailThirdMergeHead = (git -C $MoeRailFeatureWorktree rev-parse HEAD).Trim()
$MoeRailMergeFirstParent = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^1').Trim()
$MoeRailMergeSecondParent = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^2').Trim()
$MoeRailMergedDocPaths = @(
    git -C $MoeRailFeatureWorktree diff --name-only `
        "$MoeRailMergeFirstParent..$MoeRailThirdMergeHead" | Sort-Object
)
$MoeRailPostMergeStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ($LASTEXITCODE -ne 0 -or
    $MoeRailMergeFirstParent -ne $MoeRailPausedFeatureHead -or
    $MoeRailMergeSecondParent -ne $MoeRailApprovedThirdAmendment -or
    @(Compare-Object $MoeRailExpectedThirdAmendmentFiles $MoeRailMergedDocPaths).Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedTaskTwoStatus $MoeRailPostMergeStatus).Count -ne 0 -or
    @(git -C $MoeRailFeatureWorktree diff --cached --name-only).Count -ne 0) {
    $MoeRailMergedDocPaths
    $MoeRailPostMergeStatus
    throw 'Third documentation merge absorbed Task 2 work or has unexpected ancestry.'
}
git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeAppPath
if ($LASTEXITCODE -ne 0) { throw 'Third documentation merge changed prototype_app.gd.' }
foreach ($MoeRailTaskTwoPath in $MoeRailExpectedTaskTwoHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailTaskTwoPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedTaskTwoHashes[$MoeRailTaskTwoPath]) {
        throw "Third documentation merge changed Task 2 work: $MoeRailTaskTwoPath"
    }
}
$MoeRailPostFeatureRoot = (
    git -C $MoeRailFeatureWorktree rev-parse --show-toplevel
).Trim()
$MoeRailPostFeatureBranch = (
    git -C $MoeRailFeatureWorktree branch --show-current
).Trim()
$MoeRailPostFeatureBase = (
    git -C $MoeRailFeatureWorktree merge-base $MoeRailStartingPlanCommit HEAD
).Trim()
$MoeRailPostTagCommit = (
    git -C $MoeRailPrimary rev-list -n 1 prototype-m2
).Trim()
$MoeRailPostRemoteRows = @(
    git -C $MoeRailPrimary ls-remote --heads origin refs/heads/Prototyping
)
$MoeRailPostRemoteCommit = if ($MoeRailPostRemoteRows.Count -eq 1) {
    ($MoeRailPostRemoteRows[0] -split "`t")[0]
} else { '' }
$MoeRailPostCodeParent = (
    git -C $MoeRailPrimary rev-parse "$MoeRailCodeBase^"
).Trim()
$MoeRailPostVersion = ((& $MoeRailGodotExe --version 2>&1) -join "`n").Trim()
if ($LASTEXITCODE -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailPostFeatureRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailPostFeatureBranch -ne $MoeRailFeatureBranch -or
    $MoeRailPostFeatureBase -ne $MoeRailStartingPlanCommit -or
    $MoeRailPostTagCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailPostRemoteRows.Count -ne 1 -or
    $MoeRailPostRemoteCommit -ne $MoeRailMilestoneTwo -or
    $MoeRailPostCodeParent -ne $MoeRailMilestoneTwo -or
    $MoeRailPostVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw 'Feature root, branch, base, remote, prototype-m2, code parent, or Godot build changed during third amendment resume.'
}
$MoeRailFinalPrimaryStatus = @(
    git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all | Sort-Object
)
if ((git -C $MoeRailPrimary branch --show-current).Trim() -ne 'Prototyping' -or
    (git -C $MoeRailPrimary rev-parse HEAD).Trim() -ne $MoeRailStartingPlanCommit -or
    @(git -C $MoeRailPrimary diff --cached --name-only).Count -ne 0 -or
    @(Compare-Object $MoeRailExpectedPrimaryStatus $MoeRailFinalPrimaryStatus).Count -ne 0) {
    $MoeRailFinalPrimaryStatus
    throw 'Primary state changed during third amendment resume.'
}
foreach ($MoeRailProtectedPath in $MoeRailExpectedProtectedHashes.Keys) {
    $MoeRailActualHash = (
        Get-FileHash -LiteralPath (Join-Path $MoeRailPrimary $MoeRailProtectedPath) -Algorithm SHA256
    ).Hash
    if ($MoeRailActualHash -ne $MoeRailExpectedProtectedHashes[$MoeRailProtectedPath]) {
        throw "Protected primary fingerprint changed during third amendment resume: $MoeRailProtectedPath"
    }
}
"THIRD_AMENDMENT_MERGE_SHA=$MoeRailThirdMergeHead"
~~~

Expected: the exact authorized whitespace-only prototype rewrite is restored from feature `HEAD`; the reviewed three-document third amendment enters one focused merge; all 20 paused Task 2 files remain byte-identical and unstaged; the feature index stays empty; and the primary protected state remains unchanged. Record `THIRD_AMENDMENT_MERGE_SHA` in the ignored English task ledger before regenerating the Task 2 brief.

## Approved Sixth Amendment Post-Commit Adoption Gate

Run the independently reviewed Task 3 Step 4 final post-commit gate with `FEATURE_HEAD=7bfeb914141aaefdb2fc05adcaa0b876ccc69267` and `STATE_MODE=POSTCOMMIT_FINAL` before the documentation merge; do not merge documentation unless it passes.

After the one-file sixth-amendment documentation commit passes a separate Sol specification review followed by a separate Sol quality review, set `MOERAIL_APPROVED_SIXTH_AMENDMENT` to its exact 40-character SHA and run the adoption gate. It rechecks the canonical base, remote, protected state, Godot build, and feature ancestry, scope, and hashes; merges only the reviewed plan with autostash disabled; rechecks all invariants; and authorizes Task 4 only after success. It does not authorize Gate A, `Prototyping` integration, tag creation, push, PR, or cleanup.

~~~powershell
$ErrorActionPreference = 'Stop'

$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailFeatureBranch = 'proto/02-track-train'
$MoeRailStartingPlanCommit = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailFixedFeatureHead = '7bfeb914141aaefdb2fc05adcaa0b876ccc69267'
$MoeRailFixedFeatureParent = 'da65a015f4590e454876b0e93758a0c4782a254c'
$MoeRailRequiredAmendmentParent = '1500db09f1797d3a5f461b655cfdebc61176130c'
$MoeRailMilestoneTwo = 'c93e1834da8fb38792048914120fe50f9f500cb4'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailRemoteUrl = 'https://github.com/2ji1/Project_MoeRailWay.git'
$MoeRailExpectedGitCommonDir = 'D:\godot\MoeRailWay\.git'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailExpectedVersion = '4.7.1.stable.official.a13da4feb'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailApprovedSixthAmendment = $env:MOERAIL_APPROVED_SIXTH_AMENDMENT
if ($MoeRailApprovedSixthAmendment -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_APPROVED_SIXTH_AMENDMENT to the reviewed sixth-amendment commit.'
}

[string[]] $MoeRailExpectedPrimaryStatus = [string[]]@(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd'
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd'
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
)
[Array]::Sort($MoeRailExpectedPrimaryStatus, [StringComparer]::Ordinal)

$MoeRailExpectedProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}

$MoeRailExpectedTask3Hashes = [ordered]@{
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd' = 'F02C193E583105F98782F7917FA20E9F0D02CA9ECA568CF3EC0191DF0B591A43'
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd.uid' = 'E728E2E63AB09B7770163F9A30CBBA5BEBEE63109E144186776E1934387D4882'
    'godot-project-moe-rail-way/src/domain/track/track_system.gd' = '7E37B8588FF7767999949CC87C3882314E0D5400270C9B7B185CB7E1973AD919'
    'godot-project-moe-rail-way/src/domain/track/track_system.gd.uid' = '026773E4DBF2691E41D0C450EBBD554CB076F06C0E4B5B0CB9564C39210EB768'
    'godot-project-moe-rail-way/tests/run_all.gd' = '017EA13E7771288CB5049BEED310EF25AEDDD092019FDC5123EF04294AA580DC'
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd' = '5F09BFB960C2621F4443A3C52B166D7C916C7464CF06EEE9C566C6FE731D26A2'
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd.uid' = '35CC862A7B6E2211D6F06E713399F36D0B0A2B111D3E4A518AE5653C0E027BB5'
}
[string[]] $MoeRailTask3Scope = [string[]]@($MoeRailExpectedTask3Hashes.Keys)
[Array]::Sort($MoeRailTask3Scope, [StringComparer]::Ordinal)

function Invoke-MoeRailGit {
    param(
        [Parameter(Mandatory = $true)][string] $Worktree,
        [Parameter(Mandatory = $true)][string[]] $Arguments,
        [Parameter(Mandatory = $true)][string] $Label
    )
    [string[]] $Rows = [string[]]@(& git -C $Worktree @Arguments)
    [int] $ExitCode = $LASTEXITCODE
    if ($ExitCode -ne 0) {
        throw "[$Label] git exited with code $ExitCode."
    }
    return ,$Rows
}

function Get-MoeRailSingleGitRow {
    param(
        [Parameter(Mandatory = $true)][string] $Worktree,
        [Parameter(Mandatory = $true)][string[]] $Arguments,
        [Parameter(Mandatory = $true)][string] $Label
    )
    [string[]] $Rows = Invoke-MoeRailGit -Worktree $Worktree -Arguments $Arguments -Label $Label
    if ($Rows.Count -ne 1) {
        throw "[$Label] expected exactly one row, got $($Rows.Count)."
    }
    $Rows[0].Trim()
}

function Assert-MoeRailOrdinalRows {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $Actual,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $Expected,
        [Parameter(Mandatory = $true)][string] $Label
    )
    [string[]] $ActualRows = [string[]]@($Actual)
    [string[]] $ExpectedRows = [string[]]@($Expected)
    [Array]::Sort($ActualRows, [StringComparer]::Ordinal)
    [Array]::Sort($ExpectedRows, [StringComparer]::Ordinal)
    if ($ActualRows.Count -ne $ExpectedRows.Count -or
        -not [System.Linq.Enumerable]::SequenceEqual($ActualRows, $ExpectedRows, [StringComparer]::Ordinal)) {
        throw "[$Label] rows differ."
    }
}

function Assert-MoeRailOrdinaryPathChain {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Boundary
    )
    $MoeRailFullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $MoeRailFullBoundary = [IO.Path]::GetFullPath($Boundary).TrimEnd('\')
    $MoeRailBoundaryPrefix = $MoeRailFullBoundary + '\'
    $MoeRailConfined = (
        [string]::Equals(
            $MoeRailFullPath,
            $MoeRailFullBoundary,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $MoeRailFullPath.StartsWith(
            $MoeRailBoundaryPrefix,
            [StringComparison]::OrdinalIgnoreCase
        )
    )
    if (-not $MoeRailConfined) {
        throw "Path '$MoeRailFullPath' is not confined within boundary '$MoeRailFullBoundary'."
    }
    $MoeRailCurrent = $MoeRailFullPath
    while ($true) {
        if (-not (Test-Path -LiteralPath $MoeRailCurrent)) {
            throw "Path '$MoeRailCurrent' does not exist."
        }
        $MoeRailItem = Get-Item -LiteralPath $MoeRailCurrent -Force
        if (($MoeRailItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Path '$MoeRailCurrent' is a reparse point."
        }
        if ([string]::Equals(
            $MoeRailCurrent,
            $MoeRailFullBoundary,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            break
        }
        $MoeRailParent = [IO.Path]::GetFullPath(
            ([IO.Path]::GetDirectoryName($MoeRailCurrent))
        ).TrimEnd('\')
        if ([string]::Equals(
            $MoeRailParent,
            $MoeRailCurrent,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Path-chain ascent made no progress at '$MoeRailCurrent'."
        }
        if (-not (Test-Path -LiteralPath $MoeRailParent -PathType Container)) {
            throw "Parent '$MoeRailParent' is not a directory."
        }
        $MoeRailCurrent = $MoeRailParent
    }
    $MoeRailFullPath
}

function Assert-MoeRailHashMap {
    param(
        [Parameter(Mandatory = $true)][string] $Root,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary] $Expected,
        [Parameter(Mandatory = $true)][string] $Label
    )
    $MoeRailFullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $MoeRailFullRoot -PathType Container)) {
        throw "[$Label] root '$MoeRailFullRoot' is not a directory."
    }
    $null = Assert-MoeRailOrdinaryPathChain `
        -Path $MoeRailFullRoot `
        -Boundary $MoeRailFullRoot
    foreach ($Path in $Expected.Keys) {
        $MoeRailCandidate = [IO.Path]::GetFullPath(
            (Join-Path $MoeRailFullRoot $Path)
        )
        $MoeRailCandidate = Assert-MoeRailOrdinaryPathChain `
            -Path $MoeRailCandidate `
            -Boundary $MoeRailFullRoot
        if (-not (Test-Path -LiteralPath $MoeRailCandidate -PathType Leaf)) {
            throw "[$Label] '$MoeRailCandidate' is not a file."
        }
        $MoeRailItem = Get-Item -LiteralPath $MoeRailCandidate -Force
        if (-not [string]::Equals(
            $MoeRailItem.PSProvider.Name,
            'FileSystem',
            [StringComparison]::Ordinal
        )) {
            throw "[$Label] '$MoeRailCandidate' is not on the FileSystem provider."
        }
        if ($MoeRailItem.PSIsContainer) {
            throw "[$Label] '$MoeRailCandidate' is a container."
        }
        $MoeRailDisallowedAttributes = (
            [IO.FileAttributes]::ReparsePoint -bor [IO.FileAttributes]::Device
        )
        if (($MoeRailItem.Attributes -band $MoeRailDisallowedAttributes) -ne 0) {
            throw "[$Label] '$MoeRailCandidate' has disallowed attributes."
        }
        $MoeRailActualHash = (
            Get-FileHash -LiteralPath $MoeRailCandidate -Algorithm SHA256
        ).Hash
        $MoeRailExpectedHash = $Expected[$Path]
        if (-not [string]::Equals(
            $MoeRailActualHash,
            $MoeRailExpectedHash,
            [StringComparison]::Ordinal
        )) {
            throw "[$Label] hash mismatch for '$Path': expected '$MoeRailExpectedHash', actual '$MoeRailActualHash'."
        }
    }
}

$MoeRailApprovedCommit = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', "$MoeRailApprovedSixthAmendment^{commit}") -Label 'approved sixth amendment commit'
if (-not [string]::Equals($MoeRailApprovedCommit, $MoeRailApprovedSixthAmendment, [StringComparison]::Ordinal)) {
    throw 'Approved sixth-amendment commit resolution changed.'
}
$MoeRailApprovedParentRow = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-list', '--parents', '-n', '1', $MoeRailApprovedSixthAmendment) -Label 'approved sixth amendment parent'
[string[]] $MoeRailApprovedParentTokens = [string[]]@($MoeRailApprovedParentRow -split '\s+')
if ($MoeRailApprovedParentTokens.Length -ne 2 -or
    -not [string]::Equals($MoeRailApprovedParentTokens[0], $MoeRailApprovedSixthAmendment, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailApprovedParentTokens[1], $MoeRailRequiredAmendmentParent, [StringComparison]::Ordinal)) {
    throw 'Approved sixth-amendment ancestry changed.'
}
[string[]] $MoeRailApprovedFiles = Invoke-MoeRailGit -Worktree $MoeRailPrimary -Arguments @('diff-tree', '--no-commit-id', '--name-only', '-r', $MoeRailApprovedSixthAmendment) -Label 'approved sixth amendment scope'
Assert-MoeRailOrdinalRows -Actual $MoeRailApprovedFiles -Expected ([string[]]@($MoeRailPlanPath)) -Label 'approved sixth amendment scope'

$MoeRailPrimaryRoot = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', '--show-toplevel') -Label 'primary root'
if (-not [IO.Path]::GetFullPath($MoeRailPrimaryRoot).Equals([IO.Path]::GetFullPath($MoeRailPrimary), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Primary worktree root changed.'
}
$MoeRailPrimaryBranch = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('branch', '--show-current') -Label 'primary branch'
$MoeRailPrimaryHead = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', 'HEAD') -Label 'primary head'
$MoeRailPrimaryCommonDir = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir') -Label 'primary common dir'
$MoeRailPrimaryRemote = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('remote', 'get-url', 'origin') -Label 'primary remote'
if (-not [string]::Equals($MoeRailPrimaryBranch, 'Prototyping', [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailPrimaryHead, $MoeRailStartingPlanCommit, [StringComparison]::Ordinal) -or
    -not [IO.Path]::GetFullPath($MoeRailPrimaryCommonDir).Equals([IO.Path]::GetFullPath($MoeRailExpectedGitCommonDir), [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($MoeRailPrimaryRemote, $MoeRailRemoteUrl, [StringComparison]::Ordinal)) {
    throw 'Primary identity changed before sixth-amendment adoption.'
}
[string[]] $MoeRailPrimaryIndex = Invoke-MoeRailGit -Worktree $MoeRailPrimary -Arguments @('diff', '--cached', '--name-only') -Label 'primary index'
Assert-MoeRailOrdinalRows -Actual $MoeRailPrimaryIndex -Expected ([string[]]@()) -Label 'primary index'
[string[]] $MoeRailPrimaryStatus = Invoke-MoeRailGit -Worktree $MoeRailPrimary -Arguments @('status', '--porcelain=v1', '--untracked-files=all') -Label 'primary status'
Assert-MoeRailOrdinalRows -Actual $MoeRailPrimaryStatus -Expected $MoeRailExpectedPrimaryStatus -Label 'primary status'
Assert-MoeRailHashMap -Root $MoeRailPrimary -Expected $MoeRailExpectedProtectedHashes -Label 'primary protected files'

$MoeRailPrototypeM2 = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-list', '-n', '1', 'prototype-m2') -Label 'prototype-m2'
[string[]] $MoeRailRemoteRows = Invoke-MoeRailGit -Worktree $MoeRailPrimary -Arguments @('ls-remote', '--heads', 'origin', 'refs/heads/Prototyping') -Label 'remote Prototyping'
$MoeRailCodeParent = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', "$MoeRailCodeBase^") -Label 'code parent'
if ($MoeRailRemoteRows.Count -ne 1) {
    throw 'Remote Prototyping must have exactly one row.'
}
[string[]] $MoeRailRemoteTokens = [string[]]@($MoeRailRemoteRows[0] -split '\t')
if ($MoeRailRemoteTokens.Length -ne 2 -or
    -not [string]::Equals($MoeRailPrototypeM2, $MoeRailMilestoneTwo, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailRemoteTokens[0], $MoeRailMilestoneTwo, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailRemoteTokens[1], 'refs/heads/Prototyping', [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailCodeParent, $MoeRailMilestoneTwo, [StringComparison]::Ordinal)) {
    throw 'Canonical milestone, remote, or code parent changed.'
}
[string[]] $MoeRailVersionRows = [string[]]@(& $MoeRailGodotExe --version 2>&1)
[int] $MoeRailVersionExit = $LASTEXITCODE
if ($MoeRailVersionExit -ne 0 -or $MoeRailVersionRows.Count -ne 1 -or
    -not [string]::Equals($MoeRailVersionRows[0].Trim(), $MoeRailExpectedVersion, [StringComparison]::Ordinal)) {
    throw 'Exact Godot version changed.'
}

$MoeRailFeatureRoot = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-parse', '--show-toplevel') -Label 'feature root'
if (-not [IO.Path]::GetFullPath($MoeRailFeatureRoot).Equals([IO.Path]::GetFullPath($MoeRailFeatureWorktree), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Feature worktree root changed.'
}
$MoeRailFeatureCurrentBranch = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('branch', '--show-current') -Label 'feature branch'
$MoeRailFeatureCurrentHead = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-parse', 'HEAD') -Label 'feature head'
$MoeRailFeatureCommonDir = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir') -Label 'feature common dir'
$MoeRailFeatureRemote = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('remote', 'get-url', 'origin') -Label 'feature remote'
$MoeRailFeatureBase = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('merge-base', $MoeRailFeatureBranch, 'Prototyping') -Label 'feature merge base'
if (-not [string]::Equals($MoeRailFeatureCurrentBranch, $MoeRailFeatureBranch, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailFeatureCurrentHead, $MoeRailFixedFeatureHead, [StringComparison]::Ordinal) -or
    -not [IO.Path]::GetFullPath($MoeRailFeatureCommonDir).Equals([IO.Path]::GetFullPath($MoeRailExpectedGitCommonDir), [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($MoeRailFeatureRemote, $MoeRailRemoteUrl, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailFeatureBase, $MoeRailStartingPlanCommit, [StringComparison]::Ordinal)) {
    throw 'Feature identity changed before sixth-amendment adoption.'
}
[string[]] $MoeRailFeatureIndex = Invoke-MoeRailGit -Worktree $MoeRailFeatureWorktree -Arguments @('diff', '--cached', '--name-only') -Label 'feature index'
[string[]] $MoeRailFeatureStatus = Invoke-MoeRailGit -Worktree $MoeRailFeatureWorktree -Arguments @('status', '--porcelain=v1', '--untracked-files=all') -Label 'feature status'
Assert-MoeRailOrdinalRows -Actual $MoeRailFeatureIndex -Expected ([string[]]@()) -Label 'feature index'
Assert-MoeRailOrdinalRows -Actual $MoeRailFeatureStatus -Expected ([string[]]@()) -Label 'feature status'
$MoeRailFeatureParentRow = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-list', '--parents', '-n', '1', 'HEAD') -Label 'feature parent'
[string[]] $MoeRailFeatureParentTokens = [string[]]@($MoeRailFeatureParentRow -split '\s+')
if ($MoeRailFeatureParentTokens.Length -ne 2 -or
    -not [string]::Equals($MoeRailFeatureParentTokens[0], $MoeRailFixedFeatureHead, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailFeatureParentTokens[1], $MoeRailFixedFeatureParent, [StringComparison]::Ordinal)) {
    throw 'Feature parent changed before sixth-amendment adoption.'
}
[string[]] $MoeRailFeatureCommitFiles = Invoke-MoeRailGit -Worktree $MoeRailFeatureWorktree -Arguments @('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD') -Label 'feature Task 3 scope'
Assert-MoeRailOrdinalRows -Actual $MoeRailFeatureCommitFiles -Expected $MoeRailTask3Scope -Label 'feature Task 3 scope'
Assert-MoeRailHashMap -Root $MoeRailFeatureWorktree -Expected $MoeRailExpectedTask3Hashes -Label 'feature Task 3 files'

[string[]] $MoeRailMergeOutput = Invoke-MoeRailGit -Worktree $MoeRailFeatureWorktree -Arguments @('-c', 'merge.autostash=false', 'merge', '--no-ff', '--no-edit', $MoeRailApprovedSixthAmendment) -Label 'sixth amendment merge'
$MoeRailMergeOutput

$MoeRailNewHead = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-parse', 'HEAD') -Label 'post-merge head'
$MoeRailMergeParentRow = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-list', '--parents', '-n', '1', $MoeRailNewHead) -Label 'post-merge parents'
[string[]] $MoeRailMergeParentTokens = [string[]]@($MoeRailMergeParentRow -split '\s+')
if ($MoeRailMergeParentTokens.Length -ne 3 -or
    -not [string]::Equals($MoeRailMergeParentTokens[0], $MoeRailNewHead, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailMergeParentTokens[1], $MoeRailFixedFeatureHead, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailMergeParentTokens[2], $MoeRailApprovedSixthAmendment, [StringComparison]::Ordinal)) {
    throw 'Sixth-amendment merge ancestry is invalid.'
}
[string[]] $MoeRailMergeFiles = Invoke-MoeRailGit -Worktree $MoeRailFeatureWorktree -Arguments @('diff', '--name-only', "$MoeRailFixedFeatureHead..$MoeRailNewHead") -Label 'sixth amendment merge scope'
Assert-MoeRailOrdinalRows -Actual $MoeRailMergeFiles -Expected ([string[]]@($MoeRailPlanPath)) -Label 'sixth amendment merge scope'

$MoeRailPostFeatureRoot = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-parse', '--show-toplevel') -Label 'post-merge feature root'
$MoeRailPostFeatureBranch = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('branch', '--show-current') -Label 'post-merge feature branch'
$MoeRailPostFeatureCommonDir = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir') -Label 'post-merge feature common dir'
$MoeRailPostFeatureRemote = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('remote', 'get-url', 'origin') -Label 'post-merge feature remote'
$MoeRailPostFeatureBase = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('merge-base', $MoeRailFeatureBranch, 'Prototyping') -Label 'post-merge feature base'
if (-not [IO.Path]::GetFullPath($MoeRailPostFeatureRoot).Equals([IO.Path]::GetFullPath($MoeRailFeatureWorktree), [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($MoeRailPostFeatureBranch, $MoeRailFeatureBranch, [StringComparison]::Ordinal) -or
    -not [IO.Path]::GetFullPath($MoeRailPostFeatureCommonDir).Equals([IO.Path]::GetFullPath($MoeRailExpectedGitCommonDir), [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($MoeRailPostFeatureRemote, $MoeRailRemoteUrl, [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailPostFeatureBase, $MoeRailStartingPlanCommit, [StringComparison]::Ordinal)) {
    throw 'Feature identity changed during sixth-amendment adoption.'
}
[string[]] $MoeRailPostFeatureIndex = Invoke-MoeRailGit -Worktree $MoeRailFeatureWorktree -Arguments @('diff', '--cached', '--name-only') -Label 'post-merge feature index'
[string[]] $MoeRailPostFeatureStatus = Invoke-MoeRailGit -Worktree $MoeRailFeatureWorktree -Arguments @('status', '--porcelain=v1', '--untracked-files=all') -Label 'post-merge feature status'
Assert-MoeRailOrdinalRows -Actual $MoeRailPostFeatureIndex -Expected ([string[]]@()) -Label 'post-merge feature index'
Assert-MoeRailOrdinalRows -Actual $MoeRailPostFeatureStatus -Expected ([string[]]@()) -Label 'post-merge feature status'
Assert-MoeRailHashMap -Root $MoeRailFeatureWorktree -Expected $MoeRailExpectedTask3Hashes -Label 'post-merge feature Task 3 files'

$MoeRailPostPrimaryRoot = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', '--show-toplevel') -Label 'post-merge primary root'
$MoeRailPostPrimaryBranch = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('branch', '--show-current') -Label 'post-merge primary branch'
$MoeRailPostPrimaryHead = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', 'HEAD') -Label 'post-merge primary head'
$MoeRailPostPrimaryCommonDir = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir') -Label 'post-merge primary common dir'
$MoeRailPostPrimaryRemote = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('remote', 'get-url', 'origin') -Label 'post-merge primary remote'
if (-not [IO.Path]::GetFullPath($MoeRailPostPrimaryRoot).Equals([IO.Path]::GetFullPath($MoeRailPrimary), [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($MoeRailPostPrimaryBranch, 'Prototyping', [StringComparison]::Ordinal) -or
    -not [string]::Equals($MoeRailPostPrimaryHead, $MoeRailStartingPlanCommit, [StringComparison]::Ordinal) -or
    -not [IO.Path]::GetFullPath($MoeRailPostPrimaryCommonDir).Equals([IO.Path]::GetFullPath($MoeRailExpectedGitCommonDir), [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals($MoeRailPostPrimaryRemote, $MoeRailRemoteUrl, [StringComparison]::Ordinal)) {
    throw 'Primary identity changed during sixth-amendment adoption.'
}
[string[]] $MoeRailPostPrimaryIndex = Invoke-MoeRailGit -Worktree $MoeRailPrimary -Arguments @('diff', '--cached', '--name-only') -Label 'post-merge primary index'
[string[]] $MoeRailPostPrimaryStatus = Invoke-MoeRailGit -Worktree $MoeRailPrimary -Arguments @('status', '--porcelain=v1', '--untracked-files=all') -Label 'post-merge primary status'
Assert-MoeRailOrdinalRows -Actual $MoeRailPostPrimaryIndex -Expected ([string[]]@()) -Label 'post-merge primary index'
Assert-MoeRailOrdinalRows -Actual $MoeRailPostPrimaryStatus -Expected $MoeRailExpectedPrimaryStatus -Label 'post-merge primary status'
Assert-MoeRailHashMap -Root $MoeRailPrimary -Expected $MoeRailExpectedProtectedHashes -Label 'post-merge primary protected files'

$MoeRailFinalFeatureHead = Get-MoeRailSingleGitRow -Worktree $MoeRailFeatureWorktree -Arguments @('rev-parse', 'HEAD') -Label 'final feature head'
$MoeRailFinalPrimaryHead = Get-MoeRailSingleGitRow -Worktree $MoeRailPrimary -Arguments @('rev-parse', 'HEAD') -Label 'final primary head'
if (-not [string]::Equals($MoeRailFinalFeatureHead, $MoeRailNewHead, [StringComparison]::Ordinal)) {
    throw "Final feature head mismatch: expected $MoeRailNewHead, got $MoeRailFinalFeatureHead."
}
if (-not [string]::Equals($MoeRailFinalPrimaryHead, $MoeRailStartingPlanCommit, [StringComparison]::Ordinal)) {
    throw "Final primary head mismatch: expected $MoeRailStartingPlanCommit, got $MoeRailFinalPrimaryHead."
}

Write-Host "SIXTH_AMENDMENT_MERGE_SHA=$MoeRailNewHead"
~~~

Expected: The reviewed one-file sixth-amendment documentation commit enters feature history through one focused merge whose first parent is final reviewed Task 3 commit `7bfeb914141aaefdb2fc05adcaa0b876ccc69267` and whose second parent is the reviewed documentation commit; only the canonical plan differs across the merge, the seven Task 3 files remain byte-identical, the feature branch is clean, the primary branch remains protected and unchanged, and the final head equalities are rechecked. Record `SIXTH_AMENDMENT_MERGE_SHA` in the ignored English ledger; Task 4 is then authorized to begin, but Gate A, integration, tag creation, push, PR, and cleanup remain unauthorized.

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
- `godot-project-moe-rail-way/addons/moerail_test_editor_gate/plugin.cfg`
- `godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/integration/run_track_train_input_integration.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/integration/run_track_train_app_integration.gd` and `.gd.uid`
- `godot-project-moe-rail-way/tests/fixtures/short_session_values.tres`
- `godot-project-moe-rail-way/tests/fixtures/nondefault_track_train_balance.tres`
- `godot-project-moe-rail-way/tests/fixtures/invalid_track_train_balance.tres`
- `godot-project-moe-rail-way/tests/integration/nondefault_track_train_app.tscn`
- `godot-project-moe-rail-way/tests/integration/invalid_track_train_app.tscn`
- `godot-project-moe-rail-way/tests/manual/track_train_windows.md`

### Reviewed Resume-Only Documentation History

- Create `docs/superpowers/specs/2026-08-17-prototype-track-train-editor-gate-amendment-design.md` through reviewed commit `36730aa6bc6f05d7e01b96e79aff37ac73d0d11a`.
- Modify `docs/superpowers/plans/2026-08-16-prototype-track-train.md` and `docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md` through first amendment commit `9047301da36c18b94e6e5be24d8dfd7423966828`.
- Create `docs/superpowers/specs/2026-08-21-prototype-track-train-editor-shutdown-amendment-design.md` and modify the English plan plus Korean briefing through reviewed commit `aaca77325acb3ecd722894f133c5319152554eb6`.
- Create `docs/superpowers/specs/2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md` and modify the English plan plus Korean briefing through `MOERAIL_APPROVED_THIRD_AMENDMENT`.

These documentation paths enter the feature history only through their approved documentation merge gates. They are never staged or committed with a Task 1-9 implementation allowlist.

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

**Execution status:** Completed and independently reviewed. The focused implementation commit is `6a5fe45a12b3021b90fe9879e65c4b56a26ebe40`; the specification-review correction is `562499e639e6277a796fb6aeb1ac9581a0bb057e`. The required RED, seven-suite GREEN, correction GREEN, specification review, and quality review are recorded. Do not rerun or amend Task 1 while resuming Task 2.

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

- [x] **Step 1: Write the failing configuration suite and register it seventh**

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

- [x] **Step 2: Run the suite to verify the configuration RED**

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

- [x] **Step 3: Implement the five Resources, composition, validation, and copied values**

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

- [x] **Step 4: Run the configuration GREEN gate**

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

- [x] **Step 5: Commit only Task 1 files**

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

**Execution status:** Task 2 Steps 1 through 5, including replacement Step 2A and disposable-editor-mirror Step 4B, are complete; implementation commit `9cd0dc51bf4ffde260f42a85c3fa01b3d595225f` and focused specification correction `d472814e4b13544b52280d91a80a6cc68ff5bcea` are committed. All required non-editor and isolated editor gates passed. Task 2 has no active WIP or rerun instruction; the historical gate bodies below are retained only as completed evidence and must not be rerun during Task 3 or Task 4 continuation.

**Files:**

- Create `godot-project-moe-rail-way/src/presentation/track/departure_candidate.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/presentation/track/logical_track_field.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/presentation/track/logical_track_field.tscn`
- Create `godot-project-moe-rail-way/src/presentation/track/track_field_view.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/unit/test_departure_selection.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/addons/moerail_test_editor_gate/plugin.cfg`
- Create `godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/integration/run_logical_track_field_integration.gd` and `.gd.uid`
- Modify `godot-project-moe-rail-way/project.godot`
- Modify `godot-project-moe-rail-way/src/domain/random/session_rng.gd`
- Modify `godot-project-moe-rail-way/src/presentation/session/session_shell.gd`
- Modify `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- Modify `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd`
- Modify `godot-project-moe-rail-way/tests/run_all.gd`

**Interfaces:**

- Consumes: `SessionRng`, `%Field`, and the existing pixel-local `SessionShell.try_viewport_to_field` contract.
- Produces: eight editor-movable candidates, deterministic sorted selection data, logical presets and `CUSTOM`, an explicitly activated first-party editor-owned verification gate, uniform letterbox mapping, and `PASS: 8 prototype test suite(s)`.

- [x] **Step 1: Write the departure and field RED suite**

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

- [x] **Step 2: Run the departure suite to verify RED**

Historical evidence only: this exact missing-scene RED already passed and is recorded in the English Task 2 report. Do not run this block during amendment resume.

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

- [x] **Step 2A: Verify the replacement editor gate is RED before the plugin exists**

Historical evidence only: this exact missing-plugin RED already passed and is recorded in the English Task 2 report. Do not run this block during the second amendment resume. The process remained alive without the exact marker or an unrelated Godot error; the wrapper declared RED and terminated only the child process object it started.

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailMarker = 'PASS: logical track field editor integration'
$MoeRailBeforeStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all |
        Sort-Object
)
$MoeRailStdoutPath = [IO.Path]::GetTempFileName()
$MoeRailStderrPath = [IO.Path]::GetTempFileName()
$MoeRailProcess = $null
try {
    $MoeRailArguments = @(
        '--headless', '--editor', '--path', $MoeRailProject,
        '--max-fps', '60', '--', '--moerail-logical-field-editor-gate'
    )
    $MoeRailProcess = Start-Process -FilePath $MoeRailGodotExe `
        -ArgumentList $MoeRailArguments -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $MoeRailStdoutPath `
        -RedirectStandardError $MoeRailStderrPath
    $MoeRailExited = $MoeRailProcess.WaitForExit(10000)
    if ($MoeRailExited) {
        throw 'Editor exited before the missing-plugin RED deadline.'
    }
    if (-not $MoeRailProcess.HasExited) {
        $MoeRailProcess.Kill()
        $MoeRailProcess.WaitForExit()
    }
    $MoeRailOutput = @(
        Get-Content -LiteralPath $MoeRailStdoutPath
        Get-Content -LiteralPath $MoeRailStderrPath
    )
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    if ([regex]::Matches(
        $MoeRailText,
        "(?m)^$([regex]::Escape($MoeRailMarker))\r?$"
    ).Count -ne 0 -or
        $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)' -or
        $MoeRailText -match '(?i)(Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))') {
        throw 'Editor-gate RED was masked by a marker or unrelated diagnostic.'
    }
} finally {
    if ($MoeRailProcess -ne $null) { $MoeRailProcess.Dispose() }
    Remove-Item -LiteralPath $MoeRailStdoutPath, $MoeRailStderrPath -Force
}
$MoeRailAfterStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all |
        Sort-Object
)
if (@(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0) {
    $MoeRailAfterStatus
    throw 'The editor-gate RED changed the feature worktree.'
}
'RED: logical track field editor marker is absent without the plugin'
~~~

Expected: after the wrapper-owned process is declared timed out and cleaned up, exactly `RED: logical track field editor marker is absent without the plugin` is printed by PowerShell, the feature path set is unchanged, and no Godot failure or leak diagnostic substitutes for the missing marker.

- [x] **Step 3: Implement candidates, presets, editor redraw, and logical mapping**

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

Create one runtime runner that verifies all four presets, letterbox rejection, uniform scale, and resize invariance. After configuring a session, mutate the underlying `LogicalTrackField` preset and `CUSTOM` dimensions and prove that the configured content rectangle and mapped logical endpoints do not change. Its exact success marker is:

~~~text
PASS: logical track field runtime integration
~~~

Replace the superseded custom-`SceneTree` editor runner with the one permitted first-party `EditorPlugin`. Create `plugin.cfg` exactly as:

~~~ini
[plugin]

name="MoeRail Logical Field Test Gate"
description="Runs the repository-owned logical-field editor integration gate only when explicitly requested."
author="Moe Rail Way"
version="1.0.0"
script="logical_track_field_editor_gate.gd"
~~~

Add this exact project setting without changing unrelated settings:

~~~ini
[editor_plugins]

enabled=PackedStringArray("res://addons/moerail_test_editor_gate/plugin.cfg")
~~~

Create the plugin script with this concrete editor-owned lifecycle and assertion set:

~~~gdscript
@tool
extends EditorPlugin

const GATE_FLAG := "--moerail-logical-field-editor-gate"
const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const PASS_MARKER := "PASS: logical track field editor integration"

var _failures := PackedStringArray()
var _gate_started := false


func _enter_tree() -> void:
    if GATE_FLAG not in OS.get_cmdline_user_args():
        return
    if _gate_started:
        return
    _gate_started = true
    call_deferred("_run_gate")


func _run_gate() -> void:
    _assert_true(Engine.is_editor_hint(), "Editor integration must run with editor hint")
    var editor_filesystem := EditorInterface.get_resource_filesystem()
    _assert_true(editor_filesystem != null, "Editor filesystem must exist")
    if editor_filesystem != null:
        while editor_filesystem.is_scanning():
            await get_tree().process_frame
        await get_tree().process_frame

    var packed = load(FIELD_SCENE_PATH) as PackedScene
    _assert_true(packed != null, "Logical field scene must load in the editor")
    if packed != null:
        var field = packed.instantiate()
        var baseline: Array[Dictionary] = field.get_sorted_candidate_records()
        _assert_equal(baseline.size(), 8, "Editor gate requires eight authored candidates")
        var normalized: Array[Vector2] = []
        for record in baseline:
            normalized.append(record.position / Vector2(1200.0, 560.0))
        var cases := [
            [field.SizePreset.COMPACT, Vector2(900.0, 420.0)],
            [field.SizePreset.STANDARD, Vector2(1200.0, 560.0)],
            [field.SizePreset.EXPANSIVE, Vector2(1500.0, 700.0)],
        ]
        for case in cases:
            field.size_preset = case[0]
            _assert_equal(
                field.get_editor_boundary_rect(),
                Rect2(Vector2.ZERO, case[1]),
                "Preset boundary must update in editor"
            )
            _assert_normalized_positions(
                field.get_sorted_candidate_records(), normalized, case[1]
            )
        field.size_preset = field.SizePreset.CUSTOM
        field.custom_width = 960.0
        field.custom_height = 480.0
        _assert_equal(
            field.get_editor_boundary_rect(),
            Rect2(Vector2.ZERO, Vector2(960.0, 480.0)),
            "CUSTOM boundary must update in editor"
        )
        _assert_normalized_positions(
            field.get_sorted_candidate_records(), normalized, Vector2(960.0, 480.0)
        )
        field.free()

    _finish_gate()


func _finish_gate() -> void:
    if _failures.is_empty():
        print(PASS_MARKER)
    else:
        for failure in _failures:
            push_error(failure)
        print("FAIL: %d logical track field editor assertion(s)" % _failures.size())


func _assert_normalized_positions(
    records: Array[Dictionary],
    expected: Array[Vector2],
    logical_size: Vector2
) -> void:
    _assert_equal(records.size(), expected.size(), "Candidate count must remain stable")
    for index in range(min(records.size(), expected.size())):
        _assert_true(
            records[index].position.is_equal_approx(expected[index] * logical_size),
            "Editor resize must preserve normalized candidate positions"
        )


func _assert_true(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
~~~

The unique matching `.gd.uid` already exists in the paused Task 2 state and must be validated without rerunning import. If the sidecar is absent, malformed, or duplicated in any resumed or fresh execution, stop immediately. Do not run any feature-worktree editor import, generate the sidecar in a mirror, copy a generated file back, hand-author a replacement, or restore another path automatically.

Without `GATE_FLAG`, `_enter_tree()` returns before scheduling work or printing a gate marker. With the flag, the plugin performs assertions and prints its result but never propagates a close notification, calls `SceneTree.quit`, restarts the editor, or invokes another shutdown API. Godot owns addon unloading and termination through the wrapper's `--quit-after` iteration budget. The plugin does not install a custom main loop, duplicate field logic, suppress diagnostics, or run in the game. The exact success marker remains:

~~~text
PASS: logical track field editor integration
~~~

Extend the accepted `run_session_shell_integration.gd` with an out-of-tree probe that instantiates the real shell packed scene without adding it to the SceneTree and requires `get_track_field_view()` plus the nested `get_logical_track_field()` to return the real children before `_ready`. Then assert that the in-tree shell owns exactly one `TrackFieldView`, its logical delegate maps a content point correctly, and its delegate rejects the internal letterbox. Preserve every existing assertion and both accepted markers.

- [x] **Historical Step 3A: Feature-worktree UID preparation superseded by the third amendment**

Historical evidence only. This block belonged to the second amendment and must not be run after the third amendment. Its feature-worktree editor-import fallback is superseded. The current validation-only Step 3B follows this preserved record.

~~~text
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailPluginUid = 'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd.uid'
$MoeRailPrototypeApp = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
function Get-MoeRailContentSnapshot {
    $MoeRailTrackedPaths = @(git -C $MoeRailFeatureWorktree ls-files)
    $MoeRailTrackedExit = $LASTEXITCODE
    $MoeRailUntrackedPaths = @(
        git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
    )
    $MoeRailUntrackedExit = $LASTEXITCODE
    if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
        throw 'Failed to enumerate the repository content snapshot.'
    }
    @(
        @($MoeRailTrackedPaths + $MoeRailUntrackedPaths) |
            Sort-Object -Unique |
            ForEach-Object {
                $MoeRailSnapshotAbsolute = Join-Path $MoeRailFeatureWorktree $_
                if (-not (Test-Path -LiteralPath $MoeRailSnapshotAbsolute -PathType Leaf)) {
                    throw "Snapshot path is not a file: $_"
                }
                $MoeRailSnapshotHash = (
                    Get-FileHash -LiteralPath $MoeRailSnapshotAbsolute -Algorithm SHA256
                ).Hash
                "$_`t$MoeRailSnapshotHash"
            }
    )
}
function Get-MoeRailStatusSnapshot {
    $MoeRailStatusRows = @(
        git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all
    )
    $MoeRailStatusExit = $LASTEXITCODE
    if ($MoeRailStatusExit -ne 0) {
        throw "Failed to capture repository status: exit $MoeRailStatusExit"
    }
    @($MoeRailStatusRows | Sort-Object)
}
$MoeRailBeforeStatus = @(Get-MoeRailStatusSnapshot)
$MoeRailBeforeContent = @(Get-MoeRailContentSnapshot)
git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
if ($LASTEXITCODE -ne 0) { throw 'prototype_app.gd must match feature HEAD before UID validation.' }
$MoeRailPluginUidAbsolute = Join-Path $MoeRailFeatureWorktree $MoeRailPluginUid
$MoeRailUidWasMissing = -not (
    Test-Path -LiteralPath $MoeRailPluginUidAbsolute -PathType Leaf
)
$MoeRailExpectedAfterStatus = $MoeRailBeforeStatus
if ($MoeRailUidWasMissing) {
    $MoeRailStdoutPath = [IO.Path]::GetTempFileName()
    $MoeRailStderrPath = [IO.Path]::GetTempFileName()
    $MoeRailProcess = $null
    $MoeRailPreserveLogs = $false
    try {
        $MoeRailArguments = @(
            '--headless', '--editor', '--path', $MoeRailProject, '--import'
        )
        $MoeRailProcess = Start-Process -FilePath $MoeRailGodotExe `
            -ArgumentList $MoeRailArguments -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $MoeRailStdoutPath `
            -RedirectStandardError $MoeRailStderrPath
        $MoeRailTimedOut = -not $MoeRailProcess.WaitForExit(60000)
        $MoeRailTerminationFailure = ''
        if ($MoeRailTimedOut) {
            try {
                if (-not $MoeRailProcess.HasExited) { $MoeRailProcess.Kill() }
            } catch {
                $MoeRailTerminationFailure = $_.Exception.Message
            }
            try {
                if (-not $MoeRailProcess.WaitForExit(5000)) {
                    $MoeRailTerminationFailure = (
                        $MoeRailTerminationFailure + ' Child did not exit within the 5-second reap deadline.'
                    ).Trim()
                }
            } catch {
                $MoeRailTerminationFailure = (
                    $MoeRailTerminationFailure + ' ' + $_.Exception.Message
                ).Trim()
            }
        }
        $MoeRailImportOutput = @(
            Get-Content -LiteralPath $MoeRailStdoutPath -ErrorAction SilentlyContinue
            Get-Content -LiteralPath $MoeRailStderrPath -ErrorAction SilentlyContinue
        )
        $MoeRailImportText = $MoeRailImportOutput -join "`n"
        $MoeRailImportOutput
        if ($MoeRailTimedOut) {
            if (-not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
                $MoeRailPreserveLogs = $true
                throw "UID import timed out and exact-child cleanup failed: $MoeRailTerminationFailure; logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
            }
            throw 'UID import exceeded its 60-second deadline.'
        }
        if ($MoeRailProcess.ExitCode -ne 0 -or
            $MoeRailImportText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
            $MoeRailImportText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))' -or
            $MoeRailImportText -match '(?m)^PASS: logical track field editor integration\r?$') {
            throw 'The no-flag import was not inert and clean.'
        }
    } finally {
        $MoeRailChildStillRunning = $false
        if ($MoeRailProcess -ne $null) {
            try { $MoeRailChildStillRunning = -not $MoeRailProcess.HasExited } catch {
                $MoeRailChildStillRunning = $true
            }
            $MoeRailProcess.Dispose()
        }
        if ($MoeRailPreserveLogs -or $MoeRailChildStillRunning) {
            "Preserved exact-child import logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
        } else {
            Remove-Item -LiteralPath $MoeRailStdoutPath, $MoeRailStderrPath `
                -Force -ErrorAction SilentlyContinue
        }
    }
    $MoeRailExpectedAfterStatus = @(
        $MoeRailBeforeStatus
        "?? $MoeRailPluginUid"
    ) | Sort-Object
}
$MoeRailAfterStatus = @(Get-MoeRailStatusSnapshot)
$MoeRailAfterContent = @(Get-MoeRailContentSnapshot)
if (@(Compare-Object $MoeRailExpectedAfterStatus $MoeRailAfterStatus).Count -ne 0) {
    $MoeRailAfterStatus
    throw 'UID preparation changed a path other than the one missing plugin sidecar.'
}
$MoeRailExpectedAfterContent = $MoeRailBeforeContent
if ($MoeRailUidWasMissing) {
    $MoeRailNewUidContent = @(
        $MoeRailAfterContent | Where-Object {
            $_.StartsWith("$MoeRailPluginUid`t", [StringComparison]::Ordinal)
        }
    )
    if ($MoeRailNewUidContent.Count -ne 1) {
        throw 'The missing plugin sidecar did not produce exactly one content record.'
    }
    $MoeRailExpectedAfterContent = @(
        $MoeRailBeforeContent
        $MoeRailNewUidContent[0]
    ) | Sort-Object
}
if (@(Compare-Object $MoeRailExpectedAfterContent $MoeRailAfterContent).Count -ne 0) {
    throw 'UID preparation changed repository file content outside its permitted transition.'
}
git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
if ($LASTEXITCODE -ne 0) {
    throw 'UID preparation changed prototype_app.gd; preserve evidence and stop without restoring it.'
}
if (-not (Test-Path -LiteralPath $MoeRailPluginUidAbsolute -PathType Leaf)) {
    throw 'The plugin GDScript UID sidecar is still missing.'
}
$MoeRailUidPaths = @(
    git -C $MoeRailFeatureWorktree ls-files '*.gd.uid'
    git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard '*.gd.uid'
)
$MoeRailUidRecords = @(
    foreach ($MoeRailUidPath in $MoeRailUidPaths) {
        $MoeRailUidValue = (
            Get-Content -LiteralPath (Join-Path $MoeRailFeatureWorktree $MoeRailUidPath) -Raw
        ).Trim()
        [pscustomobject]@{ Path = $MoeRailUidPath; Value = $MoeRailUidValue }
    }
)
$MoeRailPluginUidRecord = @(
    $MoeRailUidRecords | Where-Object { $_.Path -eq $MoeRailPluginUid }
)
if ($MoeRailPluginUidRecord.Count -ne 1 -or
    $MoeRailPluginUidRecord[0].Value -notmatch '^uid://[a-z0-9]+$') {
    $MoeRailPluginUidRecord
    throw 'The plugin UID sidecar is missing or malformed.'
}
$MoeRailDuplicatePluginUid = @(
    $MoeRailUidRecords | Where-Object {
        $_.Value -eq $MoeRailPluginUidRecord[0].Value
    }
)
if ($MoeRailDuplicatePluginUid.Count -ne 1) {
    $MoeRailDuplicatePluginUid
    throw 'The plugin UID sidecar is duplicated.'
}
~~~

- [x] **Historical Step 4: Real-feature editor GREEN rejected by the strict state gate**

Historical evidence only. This block produced clean assertions and shutdown but rewrote `prototype_app.gd`; its strict postcondition rejected the run. Do not run it after the third amendment. The current disposable-mirror Step 4B follows this preserved record.

~~~text
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailPrototypeApp = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
function Get-MoeRailContentSnapshot {
    $MoeRailTrackedPaths = @(git -C $MoeRailFeatureWorktree ls-files)
    $MoeRailTrackedExit = $LASTEXITCODE
    $MoeRailUntrackedPaths = @(
        git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
    )
    $MoeRailUntrackedExit = $LASTEXITCODE
    if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
        throw 'Failed to enumerate the repository content snapshot.'
    }
    @(
        @($MoeRailTrackedPaths + $MoeRailUntrackedPaths) |
            Sort-Object -Unique |
            ForEach-Object {
                $MoeRailSnapshotAbsolute = Join-Path $MoeRailFeatureWorktree $_
                if (-not (Test-Path -LiteralPath $MoeRailSnapshotAbsolute -PathType Leaf)) {
                    throw "Snapshot path is not a file: $_"
                }
                $MoeRailSnapshotHash = (
                    Get-FileHash -LiteralPath $MoeRailSnapshotAbsolute -Algorithm SHA256
                ).Hash
                "$_`t$MoeRailSnapshotHash"
            }
    )
}
function Get-MoeRailStatusSnapshot {
    $MoeRailStatusRows = @(
        git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all
    )
    $MoeRailStatusExit = $LASTEXITCODE
    if ($MoeRailStatusExit -ne 0) {
        throw "Failed to capture repository status: exit $MoeRailStatusExit"
    }
    @($MoeRailStatusRows | Sort-Object)
}
function Stop-MoeRailOwnedChild {
    param([System.Diagnostics.Process]$Process)
    $MoeRailTerminationFailure = ''
    try {
        if (-not $Process.HasExited) { $Process.Kill() }
    } catch {
        $MoeRailTerminationFailure = $_.Exception.Message
    }
    try {
        if (-not $Process.WaitForExit(5000)) {
            $MoeRailTerminationFailure = (
                $MoeRailTerminationFailure + ' Child did not exit within the 5-second reap deadline.'
            ).Trim()
        }
    } catch {
        $MoeRailTerminationFailure = (
            $MoeRailTerminationFailure + ' ' + $_.Exception.Message
        ).Trim()
    }
    $MoeRailTerminationFailure
}
$MoeRailRuns = @(
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/run_all.gd'); Markers = @('PASS: 8 prototype test suite(s)') },
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_logical_track_field_integration.gd'); Markers = @('PASS: logical track field runtime integration') },
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_session_shell_integration.gd'); Markers = @('PASS: session shell layout integration', 'PASS: session shell lifecycle integration') }
)
foreach ($MoeRailRun in $MoeRailRuns) {
    [string[]]$MoeRailArguments = $MoeRailRun.Args
    $MoeRailOutput = @(& $MoeRailGodotExe @MoeRailArguments 2>&1)
    $MoeRailExit = $LASTEXITCODE
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    if ($MoeRailExit -ne 0 -or
        $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
        $MoeRailText -match '(?i)(CrashHandlerException|Program crashed|signal \d+)') {
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

function Invoke-MoeRailHistoricalRealFeatureEditorGate {
    $MoeRailMarker = 'PASS: logical track field editor integration'
    $MoeRailBeforeStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailBeforeContent = @(Get-MoeRailContentSnapshot)
    git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
    if ($LASTEXITCODE -ne 0) {
        throw 'prototype_app.gd must match feature HEAD before the flagged editor gate.'
    }
    $MoeRailStdoutPath = [IO.Path]::GetTempFileName()
    $MoeRailStderrPath = [IO.Path]::GetTempFileName()
    $MoeRailProcess = $null
    $MoeRailPreserveLogs = $false
    try {
        $MoeRailArguments = @(
            '--headless', '--editor', '--path', $MoeRailProject,
            '--quit-after', '600', '--max-fps', '60', '--',
            '--moerail-logical-field-editor-gate'
        )
        $MoeRailProcess = Start-Process -FilePath $MoeRailGodotExe `
            -ArgumentList $MoeRailArguments -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $MoeRailStdoutPath `
            -RedirectStandardError $MoeRailStderrPath
        $MoeRailTimedOut = -not $MoeRailProcess.WaitForExit(30000)
        $MoeRailTerminationFailure = ''
        if ($MoeRailTimedOut) {
            $MoeRailTerminationFailure = Stop-MoeRailOwnedChild -Process $MoeRailProcess
        }
        $MoeRailOutput = @(
            Get-Content -LiteralPath $MoeRailStdoutPath -ErrorAction SilentlyContinue
            Get-Content -LiteralPath $MoeRailStderrPath -ErrorAction SilentlyContinue
        )
        $MoeRailText = $MoeRailOutput -join "`n"
        $MoeRailOutput
        $MoeRailAfterStatus = @(Get-MoeRailStatusSnapshot)
        $MoeRailAfterContent = @(Get-MoeRailContentSnapshot)
        git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
        $MoeRailPrototypeAppExit = $LASTEXITCODE
        if ($MoeRailTimedOut) {
            if (-not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
                $MoeRailPreserveLogs = $true
                throw "Logical field editor integration timed out and exact-child cleanup failed: $MoeRailTerminationFailure; logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
            }
            throw 'Logical field editor integration exceeded its 30-second deadline.'
        }
        if ($MoeRailPrototypeAppExit -ne 0 -or
            $MoeRailProcess.ExitCode -ne 0 -or
            [regex]::Matches(
                $MoeRailText,
                "(?m)^$([regex]::Escape($MoeRailMarker))\r?$"
            ).Count -ne 1 -or
            $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
            $MoeRailText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))' -or
            @(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeContent $MoeRailAfterContent).Count -ne 0) {
            $MoeRailAfterStatus
            throw 'Logical field editor integration failed its marker, diagnostic, exit, or file-state contract.'
        }
    } finally {
        $MoeRailChildStillRunning = $false
        if ($MoeRailProcess -ne $null) {
            try { $MoeRailChildStillRunning = -not $MoeRailProcess.HasExited } catch {
                $MoeRailChildStillRunning = $true
            }
            $MoeRailProcess.Dispose()
        }
        if ($MoeRailPreserveLogs -or $MoeRailChildStillRunning) {
            "Preserved flagged editor logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
        } else {
            Remove-Item -LiteralPath $MoeRailStdoutPath, $MoeRailStderrPath `
                -Force -ErrorAction SilentlyContinue
        }
    }
}


function Invoke-MoeRailHistoricalRealFeatureNoFlagEditorSmoke {
    $MoeRailBeforeStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailBeforeContent = @(Get-MoeRailContentSnapshot)
    git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
    if ($LASTEXITCODE -ne 0) {
        throw 'prototype_app.gd must match feature HEAD before the no-flag editor smoke.'
    }
    $MoeRailStdoutPath = [IO.Path]::GetTempFileName()
    $MoeRailStderrPath = [IO.Path]::GetTempFileName()
    $MoeRailProcess = $null
    $MoeRailPreserveLogs = $false
    try {
        $MoeRailArguments = @(
            '--headless', '--editor', '--path', $MoeRailProject,
            '--quit-after', '600', '--max-fps', '60'
        )
        $MoeRailProcess = Start-Process -FilePath $MoeRailGodotExe `
            -ArgumentList $MoeRailArguments -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $MoeRailStdoutPath `
            -RedirectStandardError $MoeRailStderrPath
        $MoeRailTimedOut = -not $MoeRailProcess.WaitForExit(30000)
        $MoeRailTerminationFailure = ''
        if ($MoeRailTimedOut) {
            $MoeRailTerminationFailure = Stop-MoeRailOwnedChild -Process $MoeRailProcess
        }
        $MoeRailOutput = @(
            Get-Content -LiteralPath $MoeRailStdoutPath -ErrorAction SilentlyContinue
            Get-Content -LiteralPath $MoeRailStderrPath -ErrorAction SilentlyContinue
        )
        $MoeRailText = $MoeRailOutput -join "`n"
        $MoeRailOutput
        $MoeRailAfterStatus = @(Get-MoeRailStatusSnapshot)
        $MoeRailAfterContent = @(Get-MoeRailContentSnapshot)
        git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
        $MoeRailPrototypeAppExit = $LASTEXITCODE
        if ($MoeRailTimedOut) {
            if (-not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
                $MoeRailPreserveLogs = $true
                throw "No-flag editor smoke timed out and exact-child cleanup failed: $MoeRailTerminationFailure; logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
            }
            throw 'No-flag editor smoke exceeded its 30-second deadline.'
        }
        if ($MoeRailPrototypeAppExit -ne 0 -or
            $MoeRailProcess.ExitCode -ne 0 -or
            $MoeRailText -match '(?m)^(PASS: logical track field editor integration|FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
            $MoeRailText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))' -or
            @(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeContent $MoeRailAfterContent).Count -ne 0) {
            $MoeRailAfterStatus
            throw 'The enabled editor plugin was not inert and clean without its gate flag.'
        }
    } finally {
        $MoeRailChildStillRunning = $false
        if ($MoeRailProcess -ne $null) {
            try { $MoeRailChildStillRunning = -not $MoeRailProcess.HasExited } catch {
                $MoeRailChildStillRunning = $true
            }
            $MoeRailProcess.Dispose()
        }
        if ($MoeRailPreserveLogs -or $MoeRailChildStillRunning) {
            "Preserved no-flag editor logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
        } else {
            Remove-Item -LiteralPath $MoeRailStdoutPath, $MoeRailStderrPath `
                -Force -ErrorAction SilentlyContinue
        }
    }
}

~~~

- [x] **Step 3B: Validate the existing plugin sidecar without editor import**

Run this validation-only block after the third amendment resume. The sidecar must already exist. If it is absent, malformed, or duplicated, stop without starting an editor, generating a replacement in a mirror, or copying anything back.

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailPluginUid = 'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd.uid'
$MoeRailPrototypeApp = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
function Get-MoeRailContentSnapshot {
    $MoeRailTracked = @(git -C $MoeRailFeatureWorktree ls-files)
    $MoeRailTrackedExit = $LASTEXITCODE
    $MoeRailUntracked = @(
        git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
    )
    $MoeRailUntrackedExit = $LASTEXITCODE
    if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
        throw 'Failed to enumerate repository content.'
    }
    @(
        @($MoeRailTracked + $MoeRailUntracked) | Sort-Object -Unique |
            ForEach-Object {
                $MoeRailAbsolute = Join-Path $MoeRailFeatureWorktree $_
                if (-not (Test-Path -LiteralPath $MoeRailAbsolute -PathType Leaf)) {
                    throw "Snapshot path is not a file: $_"
                }
                $MoeRailHash = (
                    Get-FileHash -LiteralPath $MoeRailAbsolute -Algorithm SHA256
                ).Hash
                "$_`t$MoeRailHash"
            }
    )
}
function Get-MoeRailStatusSnapshot {
    $MoeRailRows = @(
        git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all
    )
    if ($LASTEXITCODE -ne 0) { throw 'Failed to capture feature status.' }
    @($MoeRailRows | Sort-Object)
}
$MoeRailBeforeStatus = @(Get-MoeRailStatusSnapshot)
$MoeRailBeforeContent = @(Get-MoeRailContentSnapshot)
git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
if ($LASTEXITCODE -ne 0) {
    throw 'prototype_app.gd must match feature HEAD before UID validation.'
}
$MoeRailPluginUidAbsolute = Join-Path $MoeRailFeatureWorktree $MoeRailPluginUid
if (-not (Test-Path -LiteralPath $MoeRailPluginUidAbsolute -PathType Leaf)) {
    throw 'The approved plugin UID sidecar is absent; stop without editor import.'
}
$MoeRailUidPaths = @(
    git -C $MoeRailFeatureWorktree ls-files '*.gd.uid'
    git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard '*.gd.uid'
)
$MoeRailUidRecords = @(
    foreach ($MoeRailUidPath in $MoeRailUidPaths) {
        $MoeRailValue = (
            Get-Content -LiteralPath (
                Join-Path $MoeRailFeatureWorktree $MoeRailUidPath
            ) -Raw
        ).Trim()
        [pscustomobject]@{ Path = $MoeRailUidPath; Value = $MoeRailValue }
    }
)
$MoeRailPluginRecord = @(
    $MoeRailUidRecords | Where-Object { $_.Path -eq $MoeRailPluginUid }
)
if ($MoeRailPluginRecord.Count -ne 1 -or
    $MoeRailPluginRecord[0].Value -notmatch '^uid://[a-z0-9]+$') {
    $MoeRailPluginRecord
    throw 'The approved plugin UID sidecar is missing or malformed.'
}
$MoeRailDuplicates = @(
    $MoeRailUidRecords | Where-Object {
        $_.Value -eq $MoeRailPluginRecord[0].Value
    }
)
if ($MoeRailDuplicates.Count -ne 1) {
    $MoeRailDuplicates
    throw 'The approved plugin UID value is duplicated.'
}
$MoeRailAfterStatus = @(Get-MoeRailStatusSnapshot)
$MoeRailAfterContent = @(Get-MoeRailContentSnapshot)
if (@(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0 -or
    @(Compare-Object $MoeRailBeforeContent $MoeRailAfterContent).Count -ne 0) {
    throw 'UID validation changed feature state.'
}
~~~

- [x] **Step 4B: Run Task 2 GREEN gates with isolated disposable editor mirrors**

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailProjectPrefix = 'godot-project-moe-rail-way/'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailPrototypeApp = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
$MoeRailMirrorLeafPrefix = 'moerail-track-train-editor-'

function Get-MoeRailContentSnapshot {
    $MoeRailTracked = @(git -C $MoeRailFeatureWorktree ls-files)
    $MoeRailTrackedExit = $LASTEXITCODE
    $MoeRailUntracked = @(
        git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
    )
    $MoeRailUntrackedExit = $LASTEXITCODE
    if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
        throw 'Failed to enumerate repository content.'
    }
    @(
        @($MoeRailTracked + $MoeRailUntracked) | Sort-Object -Unique |
            ForEach-Object {
                $MoeRailAbsolute = Join-Path $MoeRailFeatureWorktree $_
                if (-not (Test-Path -LiteralPath $MoeRailAbsolute -PathType Leaf)) {
                    throw "Snapshot path is not a file: $_"
                }
                $MoeRailHash = (
                    Get-FileHash -LiteralPath $MoeRailAbsolute -Algorithm SHA256
                ).Hash
                "$_`t$MoeRailHash"
            }
    )
}
function Get-MoeRailStatusSnapshot {
    $MoeRailRows = @(
        git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all
    )
    if ($LASTEXITCODE -ne 0) { throw 'Failed to capture feature status.' }
    @($MoeRailRows | Sort-Object)
}
function Stop-MoeRailOwnedChild {
    param([System.Diagnostics.Process]$Process)
    $MoeRailFailure = ''
    try {
        if (-not $Process.HasExited) { $Process.Kill() }
    } catch {
        $MoeRailFailure = $_.Exception.Message
    }
    try {
        if (-not $Process.WaitForExit(5000)) {
            $MoeRailFailure = (
                $MoeRailFailure + ' Child did not exit within the 5-second reap deadline.'
            ).Trim()
        }
    } catch {
        $MoeRailFailure = ($MoeRailFailure + ' ' + $_.Exception.Message).Trim()
    }
    $MoeRailFailure
}
function Assert-MoeRailOrdinaryPathChain {
    param([string]$Path, [string]$Boundary)
    $MoeRailFullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $MoeRailFullBoundary = [IO.Path]::GetFullPath($Boundary).TrimEnd('\')
    $MoeRailBoundaryPrefix = $MoeRailFullBoundary + '\'
    if ($MoeRailFullPath -ne $MoeRailFullBoundary -and
        -not $MoeRailFullPath.StartsWith(
            $MoeRailBoundaryPrefix,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Path escaped its ordinary-file boundary: $MoeRailFullPath"
    }
    $MoeRailCurrent = $MoeRailFullPath
    while ($true) {
        if (-not (Test-Path -LiteralPath $MoeRailCurrent)) {
            throw "Required path-chain item is missing: $MoeRailCurrent"
        }
        $MoeRailCurrentItem = Get-Item -LiteralPath $MoeRailCurrent -Force
        if (($MoeRailCurrentItem.Attributes -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse point is forbidden in path chain: $MoeRailCurrent"
        }
        if ($MoeRailCurrent -eq $MoeRailFullBoundary) { break }
        $MoeRailParent = [IO.Path]::GetFullPath(
            (Split-Path -Parent $MoeRailCurrent)
        ).TrimEnd('\')
        if ($MoeRailParent -eq $MoeRailCurrent) {
            throw "Path chain did not reach its boundary: $MoeRailFullPath"
        }
        $MoeRailCurrent = $MoeRailParent
    }
    $MoeRailFullPath
}
function Assert-MoeRailOrdinaryTree {
    param([string]$Root)
    $MoeRailQueue = [Collections.Generic.Queue[string]]::new()
    $MoeRailQueue.Enqueue($Root)
    while ($MoeRailQueue.Count -gt 0) {
        $MoeRailDirectory = $MoeRailQueue.Dequeue()
        foreach ($MoeRailChild in Get-ChildItem -LiteralPath $MoeRailDirectory -Force) {
            if (($MoeRailChild.Attributes -band
                [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse point is forbidden in mirror tree: $($MoeRailChild.FullName)"
            }
            if ($MoeRailChild.PSIsContainer) {
                $MoeRailQueue.Enqueue($MoeRailChild.FullName)
            }
        }
    }
}
function Assert-MoeRailMirrorRoot {
    param([string]$Root)
    $MoeRailTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $MoeRailFullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $MoeRailRootParent = [IO.Path]::GetFullPath(
        (Split-Path -Parent $MoeRailFullRoot)
    ).TrimEnd('\')
    if ($MoeRailRootParent -ne $MoeRailTemp -or
        (Split-Path -Leaf $MoeRailFullRoot) -notmatch
        '^moerail-track-train-editor-[0-9a-f]{32}$') {
        throw "Unsafe disposable mirror root: $MoeRailFullRoot"
    }
    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailTemp -Boundary $MoeRailTemp)
    if (Test-Path -LiteralPath $MoeRailFullRoot) {
        [void](Assert-MoeRailOrdinaryPathChain `
            -Path $MoeRailFullRoot -Boundary $MoeRailTemp)
    }
    $MoeRailFullRoot
}
function New-MoeRailDisposableEditorMirror {
    $MoeRailTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $MoeRailRoot = Assert-MoeRailMirrorRoot -Root (
        Join-Path $MoeRailTemp (
            $MoeRailMirrorLeafPrefix + [guid]::NewGuid().ToString('N')
        )
    )
    try {
        $MoeRailMirrorProject = Join-Path $MoeRailRoot 'project'
        $MoeRailEnvironment = Join-Path $MoeRailRoot 'environment'
        $MoeRailAppData = Join-Path $MoeRailEnvironment 'appdata'
        $MoeRailLocalAppData = Join-Path $MoeRailEnvironment 'localappdata'
        $MoeRailChildTemp = Join-Path $MoeRailEnvironment 'temp'
        $MoeRailLogs = Join-Path $MoeRailRoot 'logs'
        foreach ($MoeRailDirectory in @(
            $MoeRailMirrorProject, $MoeRailAppData, $MoeRailLocalAppData,
            $MoeRailChildTemp, $MoeRailLogs
        )) {
            New-Item -ItemType Directory -Path $MoeRailDirectory | Out-Null
        }
        $MoeRailTracked = @(git -C $MoeRailFeatureWorktree ls-files)
        $MoeRailTrackedExit = $LASTEXITCODE
        $MoeRailUntracked = @(
            git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
        )
        $MoeRailUntrackedExit = $LASTEXITCODE
        if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
            throw 'Failed to select disposable mirror files.'
        }
        $MoeRailRepositoryPaths = @(
            @($MoeRailTracked + $MoeRailUntracked) | Sort-Object -Unique
        )
        $MoeRailProjectPaths = @(
            $MoeRailRepositoryPaths | Where-Object {
                $_.StartsWith($MoeRailProjectPrefix, [StringComparison]::Ordinal)
            }
        )
        if ($MoeRailProjectPaths.Count -eq 0) {
            throw 'No project files were selected for the disposable mirror.'
        }
        $MoeRailMirrorPrefix = $MoeRailMirrorProject.TrimEnd('\') + '\'
        $MoeRailManifest = @()
        foreach ($MoeRailRepositoryPath in $MoeRailProjectPaths) {
            $MoeRailRelative = $MoeRailRepositoryPath.Substring(
                $MoeRailProjectPrefix.Length
            )
            if ($MoeRailRelative -match '(^|/)(\.git|\.godot)(/|$)') {
                throw "Repository metadata or generated project data is forbidden in a mirror: $MoeRailRepositoryPath"
            }
            $MoeRailSource = Join-Path $MoeRailFeatureWorktree $MoeRailRepositoryPath
            if (-not (Test-Path -LiteralPath $MoeRailSource -PathType Leaf)) {
                throw "Mirror source is not an ordinary file: $MoeRailRepositoryPath"
            }
            [void](Assert-MoeRailOrdinaryPathChain `
                -Path $MoeRailSource -Boundary $MoeRailFeatureWorktree)
            $MoeRailDestination = [IO.Path]::GetFullPath(
                (Join-Path $MoeRailMirrorProject $MoeRailRelative)
            )
            if (-not $MoeRailDestination.StartsWith(
                $MoeRailMirrorPrefix,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                throw "Mirror destination escaped its root: $MoeRailRepositoryPath"
            }
            $MoeRailSourceHash = (
                Get-FileHash -LiteralPath $MoeRailSource -Algorithm SHA256
            ).Hash
            $MoeRailManifest += [pscustomobject]@{
                Relative = $MoeRailRelative
                Source = $MoeRailSource
                Destination = $MoeRailDestination
                Hash = $MoeRailSourceHash
            }
        }
        foreach ($MoeRailManifestEntry in $MoeRailManifest) {
            New-Item -ItemType Directory -Path (
                Split-Path -Parent $MoeRailManifestEntry.Destination
            ) -Force | Out-Null
            [void](Assert-MoeRailOrdinaryPathChain `
                -Path (Split-Path -Parent $MoeRailManifestEntry.Destination) `
                -Boundary $MoeRailMirrorProject)
            Copy-Item -LiteralPath $MoeRailManifestEntry.Source `
                -Destination $MoeRailManifestEntry.Destination
            [void](Assert-MoeRailOrdinaryPathChain `
                -Path $MoeRailManifestEntry.Destination `
                -Boundary $MoeRailMirrorProject)
        }
        $MoeRailSourceRecords = @(
            $MoeRailManifest | ForEach-Object { "$($_.Relative)`t$($_.Hash)" } |
                Sort-Object
        )
        $MoeRailSecondSourceRecords = @(
            foreach ($MoeRailManifestEntry in $MoeRailManifest) {
                [void](Assert-MoeRailOrdinaryPathChain `
                    -Path $MoeRailManifestEntry.Source `
                    -Boundary $MoeRailFeatureWorktree)
                $MoeRailSecondHash = (
                    Get-FileHash -LiteralPath $MoeRailManifestEntry.Source `
                        -Algorithm SHA256
                ).Hash
                "$($MoeRailManifestEntry.Relative)`t$MoeRailSecondHash"
            }
        ) | Sort-Object
        $MoeRailMirrorRecords = @(
            Get-ChildItem -LiteralPath $MoeRailMirrorProject -File -Recurse |
                ForEach-Object {
                    if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                        throw "Mirror contains a reparse point: $($_.FullName)"
                    }
                    $MoeRailRelative = $_.FullName.Substring(
                        $MoeRailMirrorPrefix.Length
                    ).Replace('\', '/')
                    $MoeRailHash = (
                        Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
                    ).Hash
                    "$MoeRailRelative`t$MoeRailHash"
                } | Sort-Object
        )
        if (@(Compare-Object $MoeRailSourceRecords $MoeRailSecondSourceRecords).Count -ne 0 -or
            @(Compare-Object $MoeRailSourceRecords $MoeRailMirrorRecords).Count -ne 0) {
            throw 'Disposable mirror file list or content differs from its selected source.'
        }
        [pscustomobject]@{
            Root = $MoeRailRoot
            Project = $MoeRailMirrorProject
            AppData = $MoeRailAppData
            LocalAppData = $MoeRailLocalAppData
            Temp = $MoeRailChildTemp
            Stdout = (Join-Path $MoeRailLogs 'stdout.log')
            Stderr = (Join-Path $MoeRailLogs 'stderr.log')
            EngineLog = (Join-Path $MoeRailLogs 'godot.log')
        }
    } catch {
        "PRESERVED_DISPOSABLE_MIRROR=$MoeRailRoot"
        throw
    }
}
function Remove-MoeRailDisposableEditorMirror {
    param([pscustomobject]$Mirror)
    $MoeRailSafeRoot = Assert-MoeRailMirrorRoot -Root $Mirror.Root
    if (-not (Test-Path -LiteralPath $MoeRailSafeRoot -PathType Container)) {
        throw 'Disposable mirror root disappeared before approved cleanup.'
    }
    [void](Assert-MoeRailOrdinaryPathChain `
        -Path $MoeRailSafeRoot `
        -Boundary ([IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')))
    Assert-MoeRailOrdinaryTree -Root $MoeRailSafeRoot
    Remove-Item -LiteralPath $MoeRailSafeRoot -Recurse -Force
}
function Get-MoeRailLogText {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required editor capture is missing: $Path"
    }
    $MoeRailCaptureItem = Get-Item -LiteralPath $Path -Force
    if (($MoeRailCaptureItem.Attributes -band
        [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Editor capture is a reparse point: $Path"
    }
    Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
}
function Invoke-MoeRailDisposableEditorGate {
    param([switch]$WithGateFlag)
    $MoeRailBeforeStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailBeforeContent = @(Get-MoeRailContentSnapshot)
    git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
    if ($LASTEXITCODE -ne 0) {
        throw 'prototype_app.gd must match feature HEAD before mirror creation.'
    }
    $MoeRailMirror = New-MoeRailDisposableEditorMirror
    $MoeRailAfterCopyStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailAfterCopyContent = @(Get-MoeRailContentSnapshot)
    git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
    $MoeRailAfterCopyPrototypeExit = $LASTEXITCODE
    if ($MoeRailAfterCopyPrototypeExit -ne 0 -or
        @(Compare-Object $MoeRailBeforeStatus $MoeRailAfterCopyStatus).Count -ne 0 -or
        @(Compare-Object $MoeRailBeforeContent $MoeRailAfterCopyContent).Count -ne 0) {
        "PRESERVED_DISPOSABLE_MIRROR=$($MoeRailMirror.Root)"
        throw 'Mirror creation changed feature state; child launch is forbidden.'
    }
    $MoeRailProcess = $null
    $MoeRailSuccess = $false
    try {
        $MoeRailArguments = @(
            '--headless', '--path', $MoeRailMirror.Project, '--editor', '--import',
            '--quit-after', '240', '--max-fps', '60',
            '--log-file', $MoeRailMirror.EngineLog
        )
        if ($WithGateFlag) {
            $MoeRailArguments += @('--', '--moerail-logical-field-editor-gate')
        }
        $MoeRailEnvironment = @{
            APPDATA = $MoeRailMirror.AppData
            LOCALAPPDATA = $MoeRailMirror.LocalAppData
            TEMP = $MoeRailMirror.Temp
            TMP = $MoeRailMirror.Temp
        }
        $MoeRailStartInfo = [Diagnostics.ProcessStartInfo]::new()
        $MoeRailStartInfo.FileName = $MoeRailGodotExe
        $MoeRailStartInfo.UseShellExecute = $false
        $MoeRailStartInfo.CreateNoWindow = $true
        $MoeRailStartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
        $MoeRailStartInfo.RedirectStandardOutput = $true
        $MoeRailStartInfo.RedirectStandardError = $true
        foreach ($MoeRailArgument in $MoeRailArguments) {
            [void]$MoeRailStartInfo.ArgumentList.Add([string]$MoeRailArgument)
        }
        foreach ($MoeRailEnvironmentName in $MoeRailEnvironment.Keys) {
            $MoeRailStartInfo.Environment[$MoeRailEnvironmentName] =
                $MoeRailEnvironment[$MoeRailEnvironmentName]
        }
        $MoeRailProcess = [Diagnostics.Process]::new()
        $MoeRailProcess.StartInfo = $MoeRailStartInfo
        if (-not $MoeRailProcess.Start()) {
            throw 'Failed to start the exact disposable editor child.'
        }
        $MoeRailStdoutTask = $MoeRailProcess.StandardOutput.ReadToEndAsync()
        $MoeRailStderrTask = $MoeRailProcess.StandardError.ReadToEndAsync()
        $MoeRailTimedOut = -not $MoeRailProcess.WaitForExit(30000)
        $MoeRailTerminationFailure = ''
        if ($MoeRailTimedOut) {
            $MoeRailTerminationFailure = Stop-MoeRailOwnedChild -Process $MoeRailProcess
        }
        if ($MoeRailTimedOut -and
            -not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
            throw "Timed-out editor child was not reaped; asynchronous capture remains bounded by preserving the mirror: $MoeRailTerminationFailure"
        }
        $MoeRailCaptureTasks = [Threading.Tasks.Task[]]@(
            $MoeRailStdoutTask, $MoeRailStderrTask
        )
        try {
            $MoeRailCaptureCompleted = [Threading.Tasks.Task]::WaitAll(
                $MoeRailCaptureTasks,
                5000
            )
        } catch {
            throw "Editor output capture failed: $($_.Exception.Message)"
        }
        if (-not $MoeRailCaptureCompleted) {
            try { $MoeRailProcess.StandardOutput.Dispose() } catch {}
            try { $MoeRailProcess.StandardError.Dispose() } catch {}
            throw 'Editor output capture exceeded its 5-second completion deadline.'
        }
        $MoeRailCapturedStdout = $MoeRailStdoutTask.GetAwaiter().GetResult()
        $MoeRailCapturedStderr = $MoeRailStderrTask.GetAwaiter().GetResult()
        [IO.File]::WriteAllText(
            $MoeRailMirror.Stdout,
            $MoeRailCapturedStdout,
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            $MoeRailMirror.Stderr,
            $MoeRailCapturedStderr,
            [Text.UTF8Encoding]::new($false)
        )
        $MoeRailStdout = Get-MoeRailLogText -Path $MoeRailMirror.Stdout
        $MoeRailStderr = Get-MoeRailLogText -Path $MoeRailMirror.Stderr
        $MoeRailEngineLog = Get-MoeRailLogText -Path $MoeRailMirror.EngineLog
        $MoeRailProcessText = @($MoeRailStdout, $MoeRailStderr) -join "`n"
        $MoeRailDiagnosticText = @(
            $MoeRailStdout, $MoeRailStderr, $MoeRailEngineLog
        ) -join "`n"
        $MoeRailProcessText
        $MoeRailPassCount = [regex]::Matches(
            $MoeRailProcessText,
            '(?m)^PASS: logical track field editor integration\r?$'
        ).Count
        $MoeRailFailCount = [regex]::Matches(
            $MoeRailProcessText,
            '(?m)^FAIL: logical track field editor integration\r?$'
        ).Count
        $MoeRailExpectedPassCount = if ($WithGateFlag) { 1 } else { 0 }
        $MoeRailAfterStatus = @(Get-MoeRailStatusSnapshot)
        $MoeRailAfterContent = @(Get-MoeRailContentSnapshot)
        git -C $MoeRailFeatureWorktree diff --quiet HEAD -- $MoeRailPrototypeApp
        $MoeRailPrototypeExit = $LASTEXITCODE
        if ($MoeRailTimedOut -or
            -not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure) -or
            $MoeRailProcess.ExitCode -ne 0 -or
            $MoeRailPassCount -ne $MoeRailExpectedPassCount -or
            $MoeRailFailCount -ne 0 -or
            $MoeRailDiagnosticText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
            $MoeRailDiagnosticText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))' -or
            $MoeRailPrototypeExit -ne 0 -or
            @(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeContent $MoeRailAfterContent).Count -ne 0) {
            throw 'Disposable editor gate failed its process, diagnostic, marker, or feature-state contract.'
        }
        $MoeRailSuccess = $true
    } finally {
        if ($MoeRailProcess -ne $null) { $MoeRailProcess.Dispose() }
        if ($MoeRailSuccess) {
            try {
                Remove-MoeRailDisposableEditorMirror -Mirror $MoeRailMirror
            } catch {
                "PRESERVED_DISPOSABLE_MIRROR=$($MoeRailMirror.Root)"
                throw "Disposable mirror cleanup failed; preserve any remaining evidence: $($_.Exception.Message)"
            }
        } else {
            "PRESERVED_DISPOSABLE_MIRROR=$($MoeRailMirror.Root)"
        }
    }
}

$MoeRailRuns = @(
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/run_all.gd'); Markers = @('PASS: 8 prototype test suite(s)') },
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_logical_track_field_integration.gd'); Markers = @('PASS: logical track field runtime integration') },
    @{ Args = @('--headless', '--path', $MoeRailProject, '--script', 'res://tests/integration/run_session_shell_integration.gd'); Markers = @('PASS: session shell layout integration', 'PASS: session shell lifecycle integration') }
)
foreach ($MoeRailRun in $MoeRailRuns) {
    [string[]]$MoeRailArguments = $MoeRailRun.Args
    $MoeRailOutput = @(& $MoeRailGodotExe @MoeRailArguments 2>&1)
    $MoeRailExit = $LASTEXITCODE
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    if ($MoeRailExit -ne 0 -or
        $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
        $MoeRailText -match '(?i)(CrashHandlerException|Program crashed|signal \d+)') {
        throw 'Task 2 non-editor runner failed.'
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
Invoke-MoeRailDisposableEditorGate -WithGateFlag
Invoke-MoeRailDisposableEditorGate
~~~

Expected: the three non-editor markers pass; the flagged mirror prints its editor marker exactly once and exits naturally; the separate no-flag mirror prints zero gate markers and exits naturally; neither run emits a prohibited diagnostic or changes any feature file; and each successful disposable root is removed only after its exact child exits. On any failure, preserve the exact mirror root and stop.

- [x] **Step 5: Task 2 commit and focused correction are complete**

Implementation commit `9cd0dc51bf4ffde260f42a85c3fa01b3d595225f` and correction `d472814e4b13544b52280d91a80a6cc68ff5bcea` are committed and reviewed. Task 2 file scope is complete, the feature was clean before Task 3, and the former staging and commit command is historical and removed from active instructions.

### Task 3: Implement Route Reservation, Clipping, and Free Cancellation

**Files:**

- Create `godot-project-moe-rail-way/src/domain/track/track_input_frame.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/domain/track/track_system.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd` and `.gd.uid`
- Modify `godot-project-moe-rail-way/tests/run_all.gd`

**Interfaces:**

- Consumes: copied `SessionStartConfig` geometry and inventory fields plus one `TrackInputFrame` per tick.
- Produces: ordered absolute-distance route storage, immediate reservation charge, first-limit clipping, endpoint-only stroke state, deterministic reserved-suffix cancellation, and `PASS: 9 prototype test suite(s)`.

- [x] **Step 1: Write and register the reservation RED suite**

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

- [x] **Step 2: Run the reservation suite to verify RED**

The missing preload prevents `run_all.gd` from reaching its own `quit(1)` path under the required Godot build, so the exact direct invocation does not return naturally. Run the same five Godot arguments through this bounded controller instead. It captures both streams in memory, accepts only a nonzero process plus the exact missing-`TrackSystem` diagnostic, terminates only the verified process tree that it started when the child remains alive after ten seconds, and proves that feature content and the protected primary files did not change. Do not add `--quit-after`, switch the test to dynamic loading, weaken the missing-path check, or terminate any pre-existing Godot or Steam process.

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailPrimaryWorktree = 'D:\godot\MoeRailWay'
$MoeRailExpectedProtected = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' = @{
        Status = ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd'
        Sha256 = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    }
    'godot-project-moe-rail-way/tests/support/prototype_test.gd' = @{
        Status = ' M godot-project-moe-rail-way/tests/support/prototype_test.gd'
        Sha256 = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    }
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md' = @{
        Status = '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
        Sha256 = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
    }
}

function Get-MoeRailTask3ContentSnapshot {
    $MoeRailTracked = @(git -C $MoeRailFeatureWorktree ls-files)
    $MoeRailTrackedExit = $LASTEXITCODE
    $MoeRailUntracked = @(
        git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
    )
    $MoeRailUntrackedExit = $LASTEXITCODE
    if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
        throw 'Failed to enumerate Task 3 RED source content.'
    }
    @(
        @($MoeRailTracked + $MoeRailUntracked) | Sort-Object -Unique |
            ForEach-Object {
                $MoeRailAbsolute = Join-Path $MoeRailFeatureWorktree $_
                if (-not (Test-Path -LiteralPath $MoeRailAbsolute -PathType Leaf)) {
                    throw "Task 3 RED snapshot path is not a file: $_"
                }
                $MoeRailHash = (
                    Get-FileHash -LiteralPath $MoeRailAbsolute -Algorithm SHA256
                ).Hash
                "$_`t$MoeRailHash"
            }
    )
}

function Get-MoeRailTask3StatusSnapshot {
    $MoeRailRows = @(
        git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all
    )
    if ($LASTEXITCODE -ne 0) { throw 'Failed to capture Task 3 RED status.' }
    @($MoeRailRows | Sort-Object)
}

function Get-MoeRailTask3MatchingProcesses {
    @(
        Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" |
            Where-Object {
                $_.CommandLine -like "*$MoeRailFeatureWorktree*" -and
                $_.CommandLine -like '*res://tests/run_all.gd*'
            }
    )
}

function Stop-MoeRailTask3OwnedProcessTree {
    param([System.Diagnostics.Process]$Process)
    $MoeRailFailures = [Collections.Generic.List[string]]::new()
    $MoeRailHasExited = $false
    try {
        $MoeRailHasExited = $Process.HasExited
    } catch {
        $MoeRailFailures.Add("Failed to inspect child exit state: $($_.Exception.Message)")
    }
    if (-not $MoeRailHasExited) {
        try {
            $Process.Kill($true)
        } catch {
            $MoeRailFailures.Add("Failed to terminate owned process tree: $($_.Exception.Message)")
        }
    }
    try {
        if (-not $Process.WaitForExit(5000)) {
            $MoeRailFailures.Add('Owned process tree exceeded its 5-second reap deadline.')
        }
    } catch {
        $MoeRailFailures.Add("Failed while reaping owned process tree: $($_.Exception.Message)")
    }
    $MoeRailFailures -join ' '
}

function Assert-MoeRailTask3ProtectedPrimary {
    foreach ($MoeRailProtectedPath in $MoeRailExpectedProtected.Keys) {
        $MoeRailExpected = $MoeRailExpectedProtected[$MoeRailProtectedPath]
        $MoeRailStatus = @(
            git -C $MoeRailPrimaryWorktree status --short -- $MoeRailProtectedPath
        )
        if ($LASTEXITCODE -ne 0 -or $MoeRailStatus.Count -ne 1 -or
            $MoeRailStatus[0] -cne $MoeRailExpected.Status) {
            $MoeRailStatus
            throw "Protected primary status changed: $MoeRailProtectedPath"
        }
        $MoeRailAbsolute = Join-Path $MoeRailPrimaryWorktree $MoeRailProtectedPath
        $MoeRailHash = (
            Get-FileHash -LiteralPath $MoeRailAbsolute -Algorithm SHA256
        ).Hash
        if ($MoeRailHash -cne $MoeRailExpected.Sha256) {
            throw "Protected primary hash changed: $MoeRailProtectedPath"
        }
    }
}

$MoeRailPreexistingProcessIds = @(
    Get-MoeRailTask3MatchingProcesses | ForEach-Object { [int]$_.ProcessId }
)
$MoeRailBeforeStatus = @(Get-MoeRailTask3StatusSnapshot)
$MoeRailBeforeContent = @(Get-MoeRailTask3ContentSnapshot)
$MoeRailCachedPaths = @(
    git -C $MoeRailFeatureWorktree diff --cached --name-only
)
$MoeRailCachedExit = $LASTEXITCODE
if ($MoeRailCachedExit -ne 0 -or $MoeRailCachedPaths.Count -ne 0) {
    throw 'Task 3 RED requires an empty feature index.'
}
Assert-MoeRailTask3ProtectedPrimary

$MoeRailArguments = @(
    '--headless',
    '--path', $MoeRailProject,
    '--script', 'res://tests/run_all.gd'
)
$MoeRailStartInfo = [Diagnostics.ProcessStartInfo]::new()
$MoeRailStartInfo.FileName = $MoeRailGodotExe
$MoeRailStartInfo.UseShellExecute = $false
$MoeRailStartInfo.CreateNoWindow = $true
$MoeRailStartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$MoeRailStartInfo.RedirectStandardOutput = $true
$MoeRailStartInfo.RedirectStandardError = $true
foreach ($MoeRailArgument in $MoeRailArguments) {
    [void]$MoeRailStartInfo.ArgumentList.Add([string]$MoeRailArgument)
}

$MoeRailProcess = [Diagnostics.Process]::new()
$MoeRailProcess.StartInfo = $MoeRailStartInfo
$MoeRailStarted = $false
$MoeRailRunFailure = $null
$MoeRailCleanupFailure = ''
try {
    if (-not $MoeRailProcess.Start()) {
        throw 'Failed to start the exact Task 3 RED child.'
    }
    $MoeRailStarted = $true
    $MoeRailStdoutTask = $MoeRailProcess.StandardOutput.ReadToEndAsync()
    $MoeRailStderrTask = $MoeRailProcess.StandardError.ReadToEndAsync()
    $MoeRailNaturalExit = $MoeRailProcess.WaitForExit(10000)
    if (-not $MoeRailNaturalExit) {
        $MoeRailTerminationFailure = Stop-MoeRailTask3OwnedProcessTree `
            -Process $MoeRailProcess
        if (-not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
            throw "Failed to reap the bounded Task 3 RED tree: $MoeRailTerminationFailure"
        }
    }
    $MoeRailCaptureTasks = [Threading.Tasks.Task[]]@(
        $MoeRailStdoutTask, $MoeRailStderrTask
    )
    try {
        $MoeRailCaptureCompleted = [Threading.Tasks.Task]::WaitAll(
            $MoeRailCaptureTasks,
            5000
        )
    } catch {
        throw "Task 3 RED output capture failed: $($_.Exception.Message)"
    }
    if (-not $MoeRailCaptureCompleted) {
        $MoeRailStreamDisposeFailures = [Collections.Generic.List[string]]::new()
        try {
            $MoeRailProcess.StandardOutput.Dispose()
        } catch {
            $MoeRailStreamDisposeFailures.Add(
                "stdout disposal failed: $($_.Exception.Message)"
            )
        }
        try {
            $MoeRailProcess.StandardError.Dispose()
        } catch {
            $MoeRailStreamDisposeFailures.Add(
                "stderr disposal failed: $($_.Exception.Message)"
            )
        }
        $MoeRailStreamDisposeDetail = ''
        if ($MoeRailStreamDisposeFailures.Count -ne 0) {
            $MoeRailStreamDisposeDetail = (
                ' Stream cleanup failures: ' +
                ($MoeRailStreamDisposeFailures -join ' ')
            )
        }
        throw (
            'Task 3 RED output capture exceeded its completion deadline.' +
            $MoeRailStreamDisposeDetail
        )
    }
    $MoeRailStdout = $MoeRailStdoutTask.GetAwaiter().GetResult()
    $MoeRailStderr = $MoeRailStderrTask.GetAwaiter().GetResult()
    $MoeRailExit = $MoeRailProcess.ExitCode
} catch {
    $MoeRailRunFailure = $_
} finally {
    if ($MoeRailStarted) {
        $MoeRailCleanupFailure = Stop-MoeRailTask3OwnedProcessTree `
            -Process $MoeRailProcess
    }
    try {
        $MoeRailProcess.Dispose()
    } catch {
        $MoeRailDisposeFailure = "Failed to dispose Task 3 RED process: $($_.Exception.Message)"
        $MoeRailCleanupFailure = @(
            $MoeRailCleanupFailure, $MoeRailDisposeFailure
        ) -join ' '
    }
}
if (-not [string]::IsNullOrWhiteSpace($MoeRailCleanupFailure)) {
    $MoeRailRunContext = ''
    if ($null -ne $MoeRailRunFailure) {
        $MoeRailRunContext = " Original run failure: $($MoeRailRunFailure.Exception.Message)"
    }
    throw "Task 3 RED cleanup failed: $MoeRailCleanupFailure$MoeRailRunContext"
}
if ($null -ne $MoeRailRunFailure) { throw $MoeRailRunFailure }

$MoeRailText = @($MoeRailStdout, $MoeRailStderr) -join "`n"
$MoeRailStdout
$MoeRailStderr
"TASK3_RED_NATURAL_EXIT=$MoeRailNaturalExit"
"TASK3_RED_EXIT=$MoeRailExit"
$MoeRailDiagnosticLines = @(
    $MoeRailText -split '\r?\n' |
        ForEach-Object { $_.TrimEnd() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)
$MoeRailExpectedScriptErrors = @(
    '^SCRIPT ERROR: Parse Error: Preload file "res://src/domain/track/track_system\.gd" does not exist\.$',
    '^SCRIPT ERROR: Parse Error: Preload file "res://src/domain/track/track_input_frame\.gd" does not exist\.$',
    '^SCRIPT ERROR: Parse Error: "TrackInputFrameScript" is a constant but does not contain a type\.$',
    '^SCRIPT ERROR: Parse Error: Cannot infer the type of "right_won" variable because the value doesn''t have a set type\.$',
    '^SCRIPT ERROR: Compile Error: Failed to compile depended scripts\.$',
    '^SCRIPT ERROR: Invalid call\. Nonexistent function ''new'' in base ''GDScript''\.$'
)
foreach ($MoeRailExpectedError in $MoeRailExpectedScriptErrors) {
    if (@(
        $MoeRailDiagnosticLines | Where-Object { $_ -match $MoeRailExpectedError }
    ).Count -ne 1) {
        throw "Task 3 RED expected one diagnostic matching: $MoeRailExpectedError"
    }
}
$MoeRailUnexpectedScriptErrors = @(
    $MoeRailDiagnosticLines | Where-Object { $_ -match '^SCRIPT ERROR:' } |
        Where-Object {
            $MoeRailLine = $_
            -not @(
                $MoeRailExpectedScriptErrors | Where-Object {
                    $MoeRailLine -match $_
                }
            )
        }
)
$MoeRailExpectedLoadError = (
    '^ERROR: Failed to load script "res://tests/run_all\.gd" with error ' +
    '"Compilation failed"\.$'
)
$MoeRailErrorLines = @(
    $MoeRailDiagnosticLines | Where-Object { $_ -match '^ERROR:' }
)
if (@($MoeRailErrorLines | Where-Object { $_ -match $MoeRailExpectedLoadError }).Count -ne 1 -or
    @($MoeRailErrorLines | Where-Object { $_ -notmatch $MoeRailExpectedLoadError }).Count -ne 0 -or
    $MoeRailUnexpectedScriptErrors.Count -ne 0 -or
    $MoeRailText -match '(?m)^(FAIL:|FATAL:|WARNING:|CRASH:)' -or
    $MoeRailText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|ObjectDB instances leaked|Resources still in use|RID allocations)') {
    $MoeRailUnexpectedScriptErrors
    $MoeRailErrorLines
    throw 'Task 3 RED emitted an unexpected diagnostic.'
}
if ($MoeRailExit -eq 0) {
    throw 'Expected RED from the missing TrackSystem implementation.'
}
$MoeRailOwnedLeftovers = @(
    Get-MoeRailTask3MatchingProcesses | Where-Object {
        $MoeRailPreexistingProcessIds -notcontains [int]$_.ProcessId
    }
)
if ($MoeRailOwnedLeftovers.Count -ne 0) {
    $MoeRailOwnedLeftovers | Select-Object ProcessId, ParentProcessId, CommandLine
    throw 'Task 3 RED left an owned Godot process behind.'
}
$MoeRailAfterStatus = @(Get-MoeRailTask3StatusSnapshot)
$MoeRailAfterContent = @(Get-MoeRailTask3ContentSnapshot)
if (@(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0 -or
    @(Compare-Object $MoeRailBeforeContent $MoeRailAfterContent).Count -ne 0) {
    throw 'Task 3 RED changed feature status or content.'
}
Assert-MoeRailTask3ProtectedPrimary
~~~

- [x] **Step 3: Implement the concrete input value and ordered route**

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

Godot's float32 `Vector2` may have no exact-ray cap-safe representation within `GEOMETRY_EPSILON`. Any clipped endpoint uses 48 radial iterations, then may refine each stored component in the movement direction only when the actual stored delta from the radial endpoint is at most `GEOMETRY_EPSILON`, the scalar cap recomputed from stored runtime components remains inclusively satisfied, exact field containment holds, and closeness to the accepted limit is nondecreasing. Field raw length is `sqrt(dx * dx + dy * dy)`, never `Vector2.distance_to`. Projection selection retains an immutable true global-minimum distance reference to prevent epsilon chaining. Canonical vertex normalization chooses the true nearest vertex and breaks only an exact equal-distance-delta tie toward the greatest route distance. Fixed-epsilon tests use explicit `absf` comparisons, never `is_equal_approx`.

Before running the gate, set `MOERAIL_TASK3_STEP4_FEATURE_HEAD=7bfeb914141aaefdb2fc05adcaa0b876ccc69267` and `MOERAIL_TASK3_STEP4_STATE_MODE=POSTCOMMIT_FINAL`, then revalidate the exact clean committed state.

- [ ] **Step 4: Run the reservation GREEN gate**

~~~powershell
# Final Task 3 Step 4 post-commit GREEN gate using a disposable editor mirror
# Validates clean committed Task 3 bytes plus protected primary state before sixth-amendment adoption
# This bounded gate reuses the independently reviewed disposable-editor-mirror helper from Task 2 Step 4B:
# - exact seven SHA-256 literals (no truncation)
# - caller-provided feature HEAD via MOERAIL_TASK3_STEP4_FEATURE_HEAD
# exact zero feature status rows (clean post-commit state)
# - mirror root validated before Get-Item
# - project.godot directly under mirror project
# - full ordinary/reparse/manifest checks from reviewed helper
# - bounded controller-owned Process with exact ownership semantics
# - import diagnostics on stdout/stderr/log
# - class-cache path-based lookup (not name-only)
# - test command exactly five args, no log-file, exact PASS cardinality
# - CIM observation with executable+command-line match
# - full feature/mirror/primary postchecks at all phases
# - top-level try/catch/finally with exact child cleanup attempts

$ErrorActionPreference = 'Stop'

# --- Caller-provided feature HEAD ---
$MoeRailEnvFeatureHead = $env:MOERAIL_TASK3_STEP4_FEATURE_HEAD
if ($MoeRailEnvFeatureHead -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_TASK3_STEP4_FEATURE_HEAD to the exact expected feature HEAD (40 hex chars).'
}

[string] $MoeRailTask3Step4StateMode = $env:MOERAIL_TASK3_STEP4_STATE_MODE

if (-not [string]::Equals(
    $MoeRailEnvFeatureHead,
    '7bfeb914141aaefdb2fc05adcaa0b876ccc69267',
    [StringComparison]::Ordinal
)) {
    throw "Invalid MOERAIL_TASK3_STEP4_FEATURE_HEAD: '$MoeRailEnvFeatureHead'"
}
if (-not [string]::Equals(
    $MoeRailTask3Step4StateMode,
    'POSTCOMMIT_FINAL',
    [StringComparison]::Ordinal
)) {
    throw "Invalid MOERAIL_TASK3_STEP4_STATE_MODE: '$MoeRailTask3Step4StateMode'"
}

# --- Constants ---
$MoeRailFeatureWorktree   = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailFeatureBranch     = 'proto/02-track-train'
$MoeRailFeatureHead       = $MoeRailEnvFeatureHead
$MoeRailMergeBase         = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailRemoteUrl         = 'https://github.com/2ji1/Project_MoeRailWay.git'
$MoeRailPrimary           = 'D:\godot\MoeRailWay'
$MoeRailPrimaryBranch     = 'Prototyping'
$MoeRailPrimaryHead       = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailExpectedGitCommonDir = 'D:\godot\MoeRailWay\.git'
$MoeRailGodotExe          = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailExpectedVersion   = '4.7.1.stable.official.a13da4feb'

# --- Feature seven-path scope and exact SHA-256 ---
$MoeRailFeatureScope = @(
    'godot-project-moe-rail-way/tests/run_all.gd',
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd',
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd.uid',
    'godot-project-moe-rail-way/src/domain/track/track_system.gd',
    'godot-project-moe-rail-way/src/domain/track/track_system.gd.uid',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd',
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd.uid'
) | Sort-Object

$MoeRailExpectedFeatureHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/run_all.gd'                                    = '017EA13E7771288CB5049BEED310EF25AEDDD092019FDC5123EF04294AA580DC'
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd'              = 'F02C193E583105F98782F7917FA20E9F0D02CA9ECA568CF3EC0191DF0B591A43'
    'godot-project-moe-rail-way/src/domain/track/track_input_frame.gd.uid'          = 'E728E2E63AB09B7770163F9A30CBBA5BEBEE63109E144186776E1934387D4882'
    'godot-project-moe-rail-way/src/domain/track/track_system.gd'                   = '7E37B8588FF7767999949CC87C3882314E0D5400270C9B7B185CB7E1973AD919'
    'godot-project-moe-rail-way/src/domain/track/track_system.gd.uid'               = '026773E4DBF2691E41D0C450EBBD554CB076F06C0E4B5B0CB9564C39210EB768'
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd'        = '5F09BFB960C2621F4443A3C52B166D7C916C7464CF06EEE9C566C6FE731D26A2'
    'godot-project-moe-rail-way/tests/unit/test_track_system_reservation.gd.uid'    = '35CC862A7B6E2211D6F06E713399F36D0B0A2B111D3E4A518AE5653C0E027BB5'
}

# --- Primary protected paths and exact SHA-256 ---
$MoeRailProtectedPaths = @(
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    'godot-project-moe-rail-way/tests/support/prototype_test.gd',
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
)
$MoeRailExpectedProtectedHashes = [ordered]@{
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd'                 = '7871537D0BE68518D59CA0F6EDA8E8295662F03DF3F723591163946D54E51324'
    'godot-project-moe-rail-way/tests/support/prototype_test.gd'                  = 'F1046A3C22D979C60473CE64B639937EB1C35E61D76568AB53D2BB08F521985B'
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'               = '826EBE2D77A76C077D3D7F4ABE8BC89329CAE39BC302284559D2433A8F700681'
}
$MoeRailAllowedPrimaryStatus = [string[]]@(
    ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
    '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
)
[Array]::Sort($MoeRailAllowedPrimaryStatus, [StringComparer]::Ordinal)

# --- Helper functions (adapted from independently reviewed Task 2 Step 4B) ---
function Get-MoeRailGitNulPaths {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Worktree,

        [Parameter(Mandatory = $true)]
        [string[]] $GitArguments,

        [Parameter(Mandatory = $true)]
        [string] $Label
    )

    [string[]]$argsArray = @('-C', $Worktree) + $GitArguments

    $procResult = Invoke-MoeRailBoundedProcess `
        -Executable 'git' `
        -Arguments $argsArray `
        -EnvironmentOverrides @{} `
        -Label $Label `
        -OwnedChildren $MoeRailOwnedChildren

    if ($procResult.ExitCode -ne 0) {
        throw "[$Label] git exited with code $($procResult.ExitCode). stderr: $($procResult.Stderr)"
    }

    if (-not [string]::IsNullOrEmpty($procResult.Stderr)) {
        throw "[$Label] git produced stderr on success: $($procResult.Stderr)"
    }

    $raw = $procResult.Stdout

    if ($raw.Length -eq 0) {
        return @()
    }

    if ($raw[$raw.Length - 1] -ne [char]0) {
        throw "[$Label] stdout does not terminate with NUL character"
    }

    $records = $raw.Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries)
    return $records
}

function Get-MoeRailContentSnapshot {
    param([string]$Worktree)
    $MoeRailTracked = @(Get-MoeRailGitNulPaths -Worktree $Worktree -GitArguments @('ls-files','-z') -Label 'snapshot tracked ls-files')
    $MoeRailUntracked = @(Get-MoeRailGitNulPaths -Worktree $Worktree -GitArguments @('ls-files','-z','--others','--exclude-standard') -Label 'snapshot untracked ls-files')
    $MoeRailSnapshotPaths = [System.Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal)
    @($MoeRailTracked + $MoeRailUntracked) | ForEach-Object { $null = $MoeRailSnapshotPaths.Add($_) }
    @(
        $MoeRailSnapshotPaths | ForEach-Object {
            $MoeRailSnapshotPath = $_
            $MoeRailAbsolute = Join-Path $Worktree $MoeRailSnapshotPath
            if (-not (Test-Path -LiteralPath $MoeRailAbsolute -PathType Leaf)) {
                throw "Snapshot path is not a file: $MoeRailSnapshotPath"
            }
            $MoeRailHash = (Get-FileHash -LiteralPath $MoeRailAbsolute -Algorithm SHA256).Hash
            "$MoeRailSnapshotPath`t$MoeRailHash"
        }
    )
}

function Get-MoeRailStatusSnapshot {
    param([string]$Worktree)
    $MoeRailRows = @(git -C $Worktree status --porcelain=v1 --untracked-files=all)
    if ($LASTEXITCODE -ne 0) { throw 'Failed to capture status.' }
    @($MoeRailRows | Sort-Object)
}

function Assert-MoeRailOrdinaryPathChain {
    param([string]$Path, [string]$Boundary)
    $MoeRailFullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $MoeRailFullBoundary = [IO.Path]::GetFullPath($Boundary).TrimEnd('\')
    $MoeRailBoundaryPrefix = $MoeRailFullBoundary + '\'
    if ($MoeRailFullPath -ne $MoeRailFullBoundary -and
        -not $MoeRailFullPath.StartsWith($MoeRailBoundaryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escaped its ordinary-file boundary: $MoeRailFullPath"
    }
    $MoeRailCurrent = $MoeRailFullPath
    while ($true) {
        if (-not (Test-Path -LiteralPath $MoeRailCurrent)) {
            throw "Required path-chain item is missing: $MoeRailCurrent"
        }
        $MoeRailCurrentItem = Get-Item -LiteralPath $MoeRailCurrent -Force
        if (($MoeRailCurrentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse point is forbidden in path chain: $MoeRailCurrent"
        }
        if ($MoeRailCurrent -eq $MoeRailFullBoundary) { break }
        $MoeRailParent = [IO.Path]::GetFullPath((Split-Path -Parent $MoeRailCurrent)).TrimEnd('\')
        if ($MoeRailParent -eq $MoeRailCurrent) {
            throw "Path chain did not reach its boundary: $MoeRailFullPath"
        }
        $MoeRailCurrent = $MoeRailParent
    }
    $MoeRailFullPath
}

function Assert-MoeRailOrdinaryTree {
    param([string]$Root)
    $MoeRailQueue = [Collections.Generic.Queue[string]]::new()
    $MoeRailQueue.Enqueue($Root)
    while ($MoeRailQueue.Count -gt 0) {
        $MoeRailDirectory = $MoeRailQueue.Dequeue()
        foreach ($MoeRailChild in Get-ChildItem -LiteralPath $MoeRailDirectory -Force) {
            if (($MoeRailChild.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse point is forbidden in tree: $($MoeRailChild.FullName)"
            }
            if ($MoeRailChild.PSIsContainer) {
                $MoeRailQueue.Enqueue($MoeRailChild.FullName)
            }
        }
    }
}

function Assert-MoeRailMirrorRoot {
    param([string]$Root)
    $MoeRailTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $MoeRailFullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $MoeRailRootParent = [IO.Path]::GetFullPath((Split-Path -Parent $MoeRailFullRoot)).TrimEnd('\')
    if ($MoeRailRootParent -ne $MoeRailTemp -or
        (Split-Path -Leaf $MoeRailFullRoot) -notmatch '^moerail-track-train-editor-[0-9a-f]{32}$') {
        throw "Unsafe disposable mirror root: $MoeRailFullRoot"
    }
    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailTemp -Boundary $MoeRailTemp)
    if (Test-Path -LiteralPath $MoeRailFullRoot) {
        [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailFullRoot -Boundary $MoeRailTemp)
    }
    $MoeRailFullRoot
}

function Assert-MoeRailMirrorState {
    param(
        [Parameter(Mandatory=$true)][string]$Phase,
        [Parameter(Mandatory=$true)][string]$TempRoot,
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$Project,
        [Parameter(Mandatory=$true)][string]$Environment,
        [Parameter(Mandatory=$true)][string]$Logs,
        [switch]$RequireProjectGodot
    )

    $MoeRailFullTempRoot = [IO.Path]::GetFullPath($TempRoot).TrimEnd('\')
    $MoeRailFullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $MoeRailFullProject = [IO.Path]::GetFullPath($Project).TrimEnd('\')
    $MoeRailFullEnvironment = [IO.Path]::GetFullPath($Environment).TrimEnd('\')
    $MoeRailFullLogs = [IO.Path]::GetFullPath($Logs).TrimEnd('\')

    foreach ($MoeRailPath in @($MoeRailFullTempRoot, $MoeRailFullRoot)) {
        if (-not (Test-Path -LiteralPath $MoeRailPath -PathType Container)) {
            throw "Phase $Phase`: path not found or not a container: $MoeRailPath"
        }
        $MoeRailItem = Get-Item -LiteralPath $MoeRailPath -Force
        if (($MoeRailItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Phase $Phase`: reparse point detected at $MoeRailPath"
        }
    }

    $MoeRailRootParent = [IO.Path]::GetFullPath((Split-Path -Parent $MoeRailFullRoot)).TrimEnd('\')
    if (-not $MoeRailRootParent.Equals($MoeRailFullTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Phase '$Phase': MoeRailRootParent '$MoeRailRootParent' does not match MoeRailFullTempRoot '$MoeRailFullTempRoot'"
    }
    $MoeRailRootLeaf = Split-Path -Leaf $MoeRailFullRoot
    if ($MoeRailRootLeaf -notmatch '^moerail-track-train-editor-[0-9a-f]{32}$') {
        throw "Phase $Phase`: unexpected root leaf '$MoeRailRootLeaf'"
    }

    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailFullTempRoot -Boundary $MoeRailFullTempRoot)
    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailFullRoot -Boundary $MoeRailFullTempRoot)

    $MoeRailPairs = @(
        @($MoeRailFullProject, 'project'),
        @($MoeRailFullEnvironment, 'environment'),
        @($MoeRailFullLogs, 'logs')
    )

    foreach ($MoeRailPair in $MoeRailPairs) {
        $MoeRailSupplied = $MoeRailPair[0]
        $MoeRailLeaf = $MoeRailPair[1]
        $MoeRailExpected = [IO.Path]::GetFullPath((Join-Path $MoeRailFullRoot $MoeRailLeaf)).TrimEnd('\')
        if (-not $MoeRailSupplied.Equals($MoeRailExpected, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Phase $Phase`: $MoeRailLeaf path mismatch: supplied '$MoeRailSupplied' expected '$MoeRailExpected'"
        }
        if (-not (Test-Path -LiteralPath $MoeRailSupplied -PathType Container)) {
            throw "Phase $Phase`: $MoeRailLeaf path not found or not a container: $MoeRailSupplied"
        }
        $MoeRailItem = Get-Item -LiteralPath $MoeRailSupplied -Force
        if (($MoeRailItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Phase $Phase`: reparse point detected at $MoeRailSupplied"
        }
        [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailSupplied -Boundary $MoeRailFullRoot)
    }

    if ($RequireProjectGodot) {
        $MoeRailProjectGodot = [IO.Path]::GetFullPath((Join-Path $MoeRailFullProject 'project.godot')).TrimEnd('\')
        if (-not (Test-Path -LiteralPath $MoeRailProjectGodot -PathType Leaf)) {
            throw "Phase $Phase`: project.godot not found at $MoeRailProjectGodot"
        }
        $MoeRailProjectGodotItem = Get-Item -LiteralPath $MoeRailProjectGodot -Force
        if (($MoeRailProjectGodotItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Phase $Phase`: project.godot is a reparse point at $MoeRailProjectGodot"
        }
        [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailProjectGodot -Boundary $MoeRailFullProject)
    }

    [void](Assert-MoeRailOrdinaryTree -Root $MoeRailFullRoot)
    $MoeRailFullRoot
}

function Assert-MoeRailMirrorManifest {
    param(
        [Parameter(Mandatory)][string]$Phase,
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][System.Collections.IDictionary]$ExpectedManifest
    )

    $normProject = [IO.Path]::GetFullPath($Project).TrimEnd('\')
    $normRoot    = [IO.Path]::GetFullPath($Root).TrimEnd('\')

    [void](Assert-MoeRailOrdinaryPathChain -Path $normProject -Boundary $normRoot)
    [void](Assert-MoeRailOrdinaryTree -Root $normProject)

    $MoeRailActualHashes = [System.Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    $files  = [IO.Directory]::EnumerateFiles($normProject, '*', [IO.SearchOption]::AllDirectories)
    foreach ($f in $files) {
        $attr = [IO.File]::GetAttributes($f)
        if ($attr -band [IO.FileAttributes]::ReparsePoint) {
            throw "Phase '$Phase': reparse point detected at '$f'"
        }
        $rel = $f.Substring($normProject.Length + 1).Replace('\', '/')
        if ($rel -cmatch '^\.godot(/|$)') { continue }
        $hash = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash
        if ($MoeRailActualHashes.ContainsKey($rel)) {
            throw "Phase '$Phase': duplicate actual manifest path '$rel'"
        }
        $MoeRailActualHashes.Add($rel, $hash)
    }

    $MoeRailActualPaths = [string[]]@($MoeRailActualHashes.Keys)
    $MoeRailExpectedPaths = [string[]]@($ExpectedManifest.Keys | ForEach-Object { [string]$_ })
    [Array]::Sort($MoeRailActualPaths, [StringComparer]::Ordinal)
    [Array]::Sort($MoeRailExpectedPaths, [StringComparer]::Ordinal)

    if ($MoeRailActualPaths.Length -ne $MoeRailExpectedPaths.Length) {
        throw "Phase '$Phase': file count mismatch (actual=$($MoeRailActualPaths.Length), expected=$($MoeRailExpectedPaths.Length))"
    }

    for ($i = 0; $i -lt $MoeRailActualPaths.Length; $i++) {
        $a = $MoeRailActualPaths[$i]
        $e = $MoeRailExpectedPaths[$i]
        if (-not [string]::Equals($a, $e, [StringComparison]::Ordinal)) {
            throw "Phase '$Phase': file-set mismatch at index $i (actual='$a', expected='$e')"
        }
        $expHash = $ExpectedManifest[$e]
        $actHash = $MoeRailActualHashes[$a]
        if (-not [string]::Equals($actHash, $expHash, [StringComparison]::Ordinal)) {
            throw "Phase '$Phase': hash mismatch for '$a' (actual='$actHash', expected='$expHash')"
        }
    }
}

function Get-MoeRailLogText {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required capture is missing: $Path"
    }
    $MoeRailCaptureItem = Get-Item -LiteralPath $Path -Force
    if (($MoeRailCaptureItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Capture is a reparse point: $Path"
    }
    Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
}

function Assert-MoeRailFeatureState {
    param(
        [string]$Phase,
        [scriptblock]$FailureHandler
    )
    [string[]] $MoeRailFeatureRootRows = [string[]]@(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
    [int] $MoeRailFeatureRootExit = $LASTEXITCODE
    [string] $MoeRailFeatureRoot = if ($MoeRailFeatureRootRows.Count -eq 1) { $MoeRailFeatureRootRows[0].Trim() } else { $null }

    [string[]] $MoeRailFeatureCommonDirRows = [string[]]@(git -C $MoeRailFeatureWorktree rev-parse --path-format=absolute --git-common-dir)
    [int] $MoeRailFeatureCommonDirExit = $LASTEXITCODE
    [string] $MoeRailFeatureCommonDir = if ($MoeRailFeatureCommonDirRows.Count -eq 1) { $MoeRailFeatureCommonDirRows[0].Trim() } else { $null }

    [string[]] $MoeRailFeatureCurrentBranchRows = [string[]]@(git -C $MoeRailFeatureWorktree branch --show-current)
    [int] $MoeRailFeatureCurrentBranchExit = $LASTEXITCODE
    [string] $MoeRailFeatureCurrentBranch = if ($MoeRailFeatureCurrentBranchRows.Count -eq 1) { $MoeRailFeatureCurrentBranchRows[0].Trim() } else { $null }

    [string[]] $MoeRailFeatureCurrentHeadRows = [string[]]@(git -C $MoeRailFeatureWorktree rev-parse HEAD)
    [int] $MoeRailFeatureCurrentHeadExit = $LASTEXITCODE
    [string] $MoeRailFeatureCurrentHead = if ($MoeRailFeatureCurrentHeadRows.Count -eq 1) { $MoeRailFeatureCurrentHeadRows[0].Trim() } else { $null }

    [string[]] $MoeRailFeatureIndex = [string[]]@(git -C $MoeRailFeatureWorktree diff --cached --name-only)
    [int] $MoeRailFeatureIndexExit = $LASTEXITCODE

    [string[]] $MoeRailFeatureStatus = [string[]]@(git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all)
    [int] $MoeRailFeatureStatusExit = $LASTEXITCODE
    [Array]::Sort($MoeRailFeatureStatus, [StringComparer]::Ordinal)

    [string[]] $MoeRailRemoteRows = [string[]]@(git -C $MoeRailFeatureWorktree remote get-url origin)
    [int] $MoeRailRemoteExit = $LASTEXITCODE

    [string[]] $MoeRailMergeBaseCheck = [string[]]@(git -C $MoeRailFeatureWorktree merge-base $MoeRailFeatureBranch Prototyping)
    [int] $MoeRailMergeBaseExit = $LASTEXITCODE

    if (
        $MoeRailFeatureRootExit -ne 0 -or $MoeRailFeatureRootRows.Count -ne 1 -or
        ![System.IO.Path]::GetFullPath($MoeRailFeatureRoot).Equals([System.IO.Path]::GetFullPath($MoeRailFeatureWorktree), [System.StringComparison]::OrdinalIgnoreCase) -or
        $MoeRailFeatureCommonDirExit -ne 0 -or $MoeRailFeatureCommonDirRows.Count -ne 1 -or -not [string]::Equals([IO.Path]::GetFullPath($MoeRailFeatureCommonDir), [IO.Path]::GetFullPath($MoeRailExpectedGitCommonDir), [StringComparison]::OrdinalIgnoreCase) -or
        $MoeRailFeatureCurrentBranchExit -ne 0 -or $MoeRailFeatureCurrentBranchRows.Count -ne 1 -or
        !$MoeRailFeatureCurrentBranch.Equals($MoeRailFeatureBranch, [System.StringComparison]::Ordinal) -or
        $MoeRailFeatureCurrentHeadExit -ne 0 -or $MoeRailFeatureCurrentHeadRows.Count -ne 1 -or
        !$MoeRailFeatureCurrentHead.Equals($MoeRailFeatureHead, [System.StringComparison]::Ordinal) -or
        $MoeRailFeatureIndexExit -ne 0 -or $MoeRailFeatureIndex.Count -ne 0 -or
        $MoeRailFeatureStatusExit -ne 0 -or
        $MoeRailRemoteExit -ne 0 -or $MoeRailRemoteRows.Count -ne 1 -or
        !$MoeRailRemoteRows[0].Equals($MoeRailRemoteUrl, [System.StringComparison]::Ordinal) -or
        $MoeRailMergeBaseExit -ne 0 -or $MoeRailMergeBaseCheck.Count -ne 1 -or
        !$MoeRailMergeBaseCheck[0].Equals($MoeRailMergeBase, [System.StringComparison]::Ordinal)
    ) {
        & $FailureHandler
        throw "Feature state invalid at ${Phase}: root=$MoeRailFeatureRoot branch=$MoeRailFeatureCurrentBranch head=$MoeRailFeatureCurrentHead index=$($MoeRailFeatureIndex.Count) status=$($MoeRailFeatureStatus.Count) remote=$MoeRailRemoteRows mergeBase=$($MoeRailMergeBaseCheck -join ';')"
    }

    [string[]] $MoeRailExpectedFeatureStatus = [string[]]@()

    if ($MoeRailFeatureStatus.Count -ne $MoeRailExpectedFeatureStatus.Length -or
        -not [System.Linq.Enumerable]::SequenceEqual($MoeRailFeatureStatus, $MoeRailExpectedFeatureStatus, [StringComparer]::Ordinal)) {
        & $FailureHandler
        throw "Feature status rows mismatch at ${Phase}"
    }

    $MoeRailSnapshot = Get-MoeRailContentSnapshot -Worktree $MoeRailFeatureWorktree
    $MoeRailInitialSnapshot = $script:MoeRailInitialFeatureSnapshot
    if (-not [System.Linq.Enumerable]::SequenceEqual[string]([string[]]@($MoeRailSnapshot), [string[]]@($MoeRailInitialSnapshot), [StringComparer]::Ordinal)) {
        & $FailureHandler
        throw "Feature content snapshot mismatch at ${Phase}"
    }

    foreach ($MoeRailPath in $MoeRailFeatureScope) {
        $MoeRailAbs = Join-Path $MoeRailFeatureWorktree $MoeRailPath
        $MoeRailHash = (Get-FileHash -LiteralPath $MoeRailAbs -Algorithm SHA256).Hash
        if (-not [string]::Equals($MoeRailHash, $MoeRailExpectedFeatureHashes[$MoeRailPath], [StringComparison]::Ordinal)) {
            & $FailureHandler
            throw "Feature scope hash mismatch at ${Phase}: $MoeRailPath (expected $($MoeRailExpectedFeatureHashes[$MoeRailPath]), got $MoeRailHash)"
        }
    }
}

function Assert-MoeRailPrimaryState {
    param(
        [string]$Phase,
        [scriptblock]$FailureHandler
    )
    [string[]] $MoeRailPrimaryRootRows = git -C $MoeRailPrimary rev-parse --show-toplevel
    [int] $MoeRailPrimaryRootExit = $LASTEXITCODE
    [string] $MoeRailPrimaryRoot = if ($MoeRailPrimaryRootRows.Count -eq 1) { $MoeRailPrimaryRootRows[0].Trim() } else { $null }

    [string[]] $MoeRailPrimaryCommonDirRows = git -C $MoeRailPrimary rev-parse --path-format=absolute --git-common-dir
    [int] $MoeRailPrimaryCommonDirExit = $LASTEXITCODE
    [string] $MoeRailPrimaryCommonDir = if ($MoeRailPrimaryCommonDirRows.Count -eq 1) { $MoeRailPrimaryCommonDirRows[0].Trim() } else { $null }

    [string[]]$MoeRailPrimaryCurrentBranchRows = @(git -C $MoeRailPrimary branch --show-current)
    $MoeRailPrimaryCurrentBranchExit = $LASTEXITCODE
    $MoeRailPrimaryCurrentBranch = if ($MoeRailPrimaryCurrentBranchRows.Count -eq 1) { $MoeRailPrimaryCurrentBranchRows[0].Trim() } else { $null }

    [string[]]$MoeRailPrimaryCurrentHeadRows = @(git -C $MoeRailPrimary rev-parse HEAD)
    $MoeRailPrimaryCurrentHeadExit = $LASTEXITCODE
    $MoeRailPrimaryCurrentHead = if ($MoeRailPrimaryCurrentHeadRows.Count -eq 1) { $MoeRailPrimaryCurrentHeadRows[0].Trim() } else { $null }

    $MoeRailPrimaryIndex = @(git -C $MoeRailPrimary diff --cached --name-only)
    $MoeRailPrimaryIndexExit = $LASTEXITCODE

    $MoeRailPrimaryStatus = [string[]]@(git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all)
    $MoeRailPrimaryStatusExit = $LASTEXITCODE
    [Array]::Sort($MoeRailPrimaryStatus, [StringComparer]::Ordinal)

    [string[]]$MoeRailPrimaryRemoteRows = @(git -C $MoeRailPrimary remote get-url origin)
    $MoeRailPrimaryRemoteExit = $LASTEXITCODE
    $MoeRailPrimaryRemoteUrlActual = if ($MoeRailPrimaryRemoteRows.Count -eq 1) { $MoeRailPrimaryRemoteRows[0].Trim() } else { $null }

    if ($MoeRailPrimaryRootExit -ne 0 -or $MoeRailPrimaryRootRows.Count -ne 1 -or -not [string]::Equals([IO.Path]::GetFullPath($MoeRailPrimaryRoot), [IO.Path]::GetFullPath($MoeRailPrimary), [StringComparison]::OrdinalIgnoreCase) -or
        $MoeRailPrimaryCommonDirExit -ne 0 -or $MoeRailPrimaryCommonDirRows.Count -ne 1 -or -not [string]::Equals([IO.Path]::GetFullPath($MoeRailPrimaryCommonDir), [IO.Path]::GetFullPath($MoeRailExpectedGitCommonDir), [StringComparison]::OrdinalIgnoreCase) -or
        $MoeRailPrimaryCurrentBranchExit -ne 0 -or $MoeRailPrimaryCurrentBranchRows.Count -ne 1 -or -not [string]::Equals($MoeRailPrimaryCurrentBranch, $MoeRailPrimaryBranch, [StringComparison]::Ordinal) -or
        $MoeRailPrimaryCurrentHeadExit -ne 0 -or $MoeRailPrimaryCurrentHeadRows.Count -ne 1 -or -not [string]::Equals($MoeRailPrimaryCurrentHead, $MoeRailPrimaryHead, [StringComparison]::Ordinal) -or
        $MoeRailPrimaryIndexExit -ne 0 -or $MoeRailPrimaryIndex.Count -ne 0 -or
        $MoeRailPrimaryStatusExit -ne 0 -or -not [System.Linq.Enumerable]::SequenceEqual[string]($MoeRailAllowedPrimaryStatus, $MoeRailPrimaryStatus, [StringComparer]::Ordinal) -or
        $MoeRailPrimaryRemoteExit -ne 0 -or $MoeRailPrimaryRemoteRows.Count -ne 1 -or -not [string]::Equals($MoeRailPrimaryRemoteUrlActual, $MoeRailRemoteUrl, [StringComparison]::Ordinal)) {
        & $FailureHandler
        throw "Primary state invalid at ${Phase}: branch=$MoeRailPrimaryCurrentBranch head=$MoeRailPrimaryCurrentHead index=$($MoeRailPrimaryIndex.Count)"
    }

    foreach ($MoeRailPath in $MoeRailProtectedPaths) {
        $MoeRailAbs = Join-Path $MoeRailPrimary $MoeRailPath
        [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailAbs -Boundary $MoeRailPrimary)
        $MoeRailActual = (Get-FileHash -LiteralPath $MoeRailAbs -Algorithm SHA256).Hash
        if (-not [string]::Equals($MoeRailActual, $MoeRailExpectedProtectedHashes[$MoeRailPath], [StringComparison]::Ordinal)) {
            & $FailureHandler
            throw "Protected hash mismatch at ${Phase}: $MoeRailPath (expected $($MoeRailExpectedProtectedHashes[$MoeRailPath]), got $MoeRailActual)"
        }
    }
}

function Get-MoeRailCimMatches {
    param([string]$MirrorProjectPath)
    try {
        $MoeRailCimRows = Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction Stop
    } catch {
        throw "Get-CimInstance failed: $($_.Exception.Message)"
    }
    @($MoeRailCimRows | Where-Object {
        $_.ExecutablePath -and [string]::Equals($_.ExecutablePath, $MoeRailGodotExe, [StringComparison]::OrdinalIgnoreCase) -and
        $_.CommandLine -and $_.CommandLine.IndexOf($MirrorProjectPath, [StringComparison]::OrdinalIgnoreCase) -ge 0
    } | ForEach-Object { $_.ProcessId } | Sort-Object)
}

# --- Common bounded process helper (replaces Stop-MoeRailOwnedChild and per-call sequences) ---
function Invoke-MoeRailBoundedProcess {
    param(
        [Parameter(Mandatory=$true)][string]$Executable,
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [Parameter(Mandatory=$true)][hashtable]$EnvironmentOverrides,
        [Parameter(Mandatory=$true)][string]$Label,
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[psobject]]$OwnedChildren
    )

    $MoeRailPsi = [Diagnostics.ProcessStartInfo]::new()
    $MoeRailPsi.FileName = $Executable
    $MoeRailPsi.UseShellExecute = $false
    $MoeRailPsi.RedirectStandardOutput = $true
    $MoeRailPsi.RedirectStandardError = $true
    $MoeRailPsi.CreateNoWindow = $true
    foreach ($MoeRailArg in $Arguments) {
        [void]$MoeRailPsi.ArgumentList.Add($MoeRailArg)
    }
    foreach ($MoeRailKey in $EnvironmentOverrides.Keys) {
        $MoeRailPsi.Environment[$MoeRailKey] = $EnvironmentOverrides[$MoeRailKey]
    }

    $MoeRailProc = [Diagnostics.Process]::new()
    $MoeRailProc.StartInfo = $MoeRailPsi
    # External record before Start
    $MoeRailRecord = [pscustomobject]@{
        Label     = $Label
        Process   = $MoeRailProc
        StdoutReader = $null
        StderrReader = $null
        StdoutTask   = $null
        StderrTask   = $null
        Started   = $false
        Disposed  = $false
    }

    $OwnedChildren.Add($MoeRailRecord)

    $MoeRailStarted = $false
    $MoeRailExited = $false
    $MoeRailMainError = $null
    $MoeRailErrors = @()
    $MoeRailExitCode = $null
    $MoeRailStdout = $null
    $MoeRailStderr = $null

    try {
        $MoeRailStarted = $MoeRailProc.Start()
        if (-not $MoeRailStarted) {
            $MoeRailMainError = "Process start failed"
            throw $MoeRailMainError
        }
        $MoeRailRecord.Started = $true

        $MoeRailRecord.StdoutReader = $MoeRailProc.StandardOutput
        $MoeRailRecord.StderrReader = $MoeRailProc.StandardError
        $MoeRailRecord.StdoutTask = $MoeRailRecord.StdoutReader.ReadToEndAsync()
        $MoeRailRecord.StderrTask = $MoeRailRecord.StderrReader.ReadToEndAsync()

        $MoeRailExited = $MoeRailProc.WaitForExit(30000)
        if (-not $MoeRailExited) {
            $MoeRailMainError = "Process timed out after 30 seconds"
        }
        else {
            $MoeRailExitCode = $MoeRailProc.ExitCode
        }
    }
    catch {
        if ($null -eq $MoeRailMainError) {
            $MoeRailMainError = $_.Exception.Message
        }
    }
    finally {
        if ($MoeRailStarted -and -not $MoeRailExited) {
            try {
                $MoeRailHasExited = $MoeRailProc.HasExited
            }
            catch {
                $MoeRailErrors += "HasExited check failed: $($_.Exception.Message)"
                $MoeRailHasExited = $false
            }

            if (-not $MoeRailHasExited) {
                try {
                    $MoeRailProc.Kill($true)
                }
                catch {
                    $MoeRailErrors += "Kill failed: $($_.Exception.Message)"
                }
            }

            try {
                $MoeRailReapResult = $MoeRailProc.WaitForExit(5000)
                if (-not $MoeRailReapResult) {
                    $MoeRailErrors += "Reap timed out after 5 seconds"
                }
                else {
                    $MoeRailExited = $true
                }
            }
            catch {
                $MoeRailErrors += "Reap failed: $($_.Exception.Message)"
            }
        }

        if ($null -ne $MoeRailRecord.StdoutTask -and $null -ne $MoeRailRecord.StderrTask) {
            $MoeRailTaskArray = [System.Threading.Tasks.Task[]]@($MoeRailRecord.StdoutTask, $MoeRailRecord.StderrTask)
            $MoeRailWaitAllResult = $false
            try {
                $MoeRailWaitAllResult = [System.Threading.Tasks.Task]::WaitAll($MoeRailTaskArray, 5000)
            }
            catch {
                $MoeRailErrors += "WaitAll failed: $($_.Exception.Message)"
            }

            if ($MoeRailWaitAllResult) {
                try {
                    $MoeRailStdout = $MoeRailRecord.StdoutTask.GetAwaiter().GetResult()
                }
                catch {
                    $MoeRailErrors += "Stdout GetResult failed: $($_.Exception.Message)"
                }
                try {
                    $MoeRailStderr = $MoeRailRecord.StderrTask.GetAwaiter().GetResult()
                }
                catch {
                    $MoeRailErrors += "Stderr GetResult failed: $($_.Exception.Message)"
                }
            }
            else {
                $MoeRailErrors += "Task WaitAll timed out or failed"
            }
        }
        elseif ($MoeRailStarted) {
            $MoeRailErrors += "Missing stdout or stderr task after process start"
        }

        if ($MoeRailStarted -and $null -eq $MoeRailExitCode) {
            try {
                if ($MoeRailProc.HasExited) {
                    $MoeRailExited = $true
                    $MoeRailExitCode = $MoeRailProc.ExitCode
                }
            }
            catch {
                $MoeRailErrors += "ExitCode read failed: $($_.Exception.Message)"
            }
        }

        $MoeRailSafeToDispose = (-not $MoeRailStarted) -or ($MoeRailExited -eq $true)

        if ($MoeRailSafeToDispose) {
            if ($null -ne $MoeRailRecord.StdoutReader) {
                try {
                    $MoeRailRecord.StdoutReader.Dispose()
                }
                catch {
                    $MoeRailErrors += "StdoutReader dispose failed: $($_.Exception.Message)"
                }
            }
            if ($null -ne $MoeRailRecord.StderrReader) {
                try {
                    $MoeRailRecord.StderrReader.Dispose()
                }
                catch {
                    $MoeRailErrors += "StderrReader dispose failed: $($_.Exception.Message)"
                }
            }

            try {
                $MoeRailProc.Dispose()
                $MoeRailRecord.Disposed = $true
            }
            catch {
                $MoeRailErrors += "Process dispose failed: $($_.Exception.Message)"
            }
        }
        else {
            $MoeRailErrors += "Disposal deferred to outer finally: process may still be alive"
        }
    }

    if ($null -ne $MoeRailMainError) {
        $MoeRailErrors = @($MoeRailMainError) + $MoeRailErrors
    }
    if ($MoeRailErrors.Count -gt 0) {
        throw "${Label}: " + ($MoeRailErrors -join '; ')
    }

    # Return Stdout/Stderr/ExitCode only after clean cleanup
    [pscustomobject]@{
        Stdout   = $MoeRailStdout
        Stderr   = $MoeRailStderr
        ExitCode = $MoeRailExitCode
    }
}

# --- Initialize gate state variables ---
$MoeRailTempRoot = $null
$MoeRailMirrorRoot = $null
$MoeRailMirrorProject = $null
$MoeRailOwnedChildren = [System.Collections.Generic.List[psobject]]::new()
$MoeRailFeatureReady = $false
$MoeRailPrimaryReady = $false
$MoeRailCimReady = $false
$MoeRailOriginalError = $null
$MoeRailCleanupErrors = [System.Collections.Generic.List[string]]::new()
$MoeRailOverallSuccess = $false
try {

# --- Preflight: verify feature state ---
Write-Host "=== Verifying feature worktree ==="
$script:MoeRailInitialFeatureSnapshot = Get-MoeRailContentSnapshot -Worktree $MoeRailFeatureWorktree
Assert-MoeRailFeatureState -Phase 'preflight' -FailureHandler { }
Write-Host "=== Verifying primary worktree ==="
Assert-MoeRailPrimaryState -Phase 'preflight' -FailureHandler { }

$MoeRailFeatureReady = $true
$MoeRailPrimaryReady = $true

# --- Verify Godot executable via bounded controller helper ---
Write-Host "=== Verifying Godot executable ==="
$MoeRailVersionResult = Invoke-MoeRailBoundedProcess `
    -Executable $MoeRailGodotExe `
    -Arguments @('--version') `
    -EnvironmentOverrides @{} `
    -Label 'version' `
    -OwnedChildren $MoeRailOwnedChildren
$MoeRailVersion = $MoeRailVersionResult.Stdout.Trim()
if ($MoeRailVersionResult.ExitCode -ne 0 -or
    -not [string]::Equals($MoeRailVersion, $MoeRailExpectedVersion, [StringComparison]::Ordinal) -or
    -not [string]::IsNullOrEmpty($MoeRailVersionResult.Stderr)) {
    throw "Unexpected Godot version probe: version=$MoeRailVersion exit=$($MoeRailVersionResult.ExitCode) stderr=$($MoeRailVersionResult.Stderr)"
}

# --- Create unique disposable mirror (adapted from reviewed helper) ---
Write-Host "=== Creating disposable mirror ==="
$MoeRailTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$MoeRailMirrorGuid = [Guid]::NewGuid().ToString('N')
$MoeRailMirrorRoot = Join-Path $MoeRailTempRoot "moerail-track-train-editor-$MoeRailMirrorGuid"
$MoeRailMirrorRoot = Assert-MoeRailMirrorRoot -Root $MoeRailMirrorRoot
$MoeRailMirrorProject = Join-Path $MoeRailMirrorRoot 'project'
$MoeRailMirrorEnv = Join-Path $MoeRailMirrorRoot 'environment'
$MoeRailMirrorLogs = Join-Path $MoeRailMirrorRoot 'logs'

New-Item -ItemType Directory -Path $MoeRailMirrorProject | Out-Null
New-Item -ItemType Directory -Path (Join-Path $MoeRailMirrorEnv 'appdata') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $MoeRailMirrorEnv 'localappdata') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $MoeRailMirrorEnv 'temp') | Out-Null
New-Item -ItemType Directory -Path $MoeRailMirrorLogs | Out-Null

Assert-MoeRailMirrorState `
    -Phase 'post-create' `
    -TempRoot $MoeRailTempRoot `
    -Root $MoeRailMirrorRoot `
    -Project $MoeRailMirrorProject `
    -Environment $MoeRailMirrorEnv `
    -Logs $MoeRailMirrorLogs |
    Out-Null

# Validate project.godot will be directly under mirror project
$MoeRailProjectGodotDest = Join-Path $MoeRailMirrorProject 'project.godot'
$MoeRailProjectGodotDestReal = [IO.Path]::GetFullPath($MoeRailProjectGodotDest)
$MoeRailMirrorProjectReal = [IO.Path]::GetFullPath($MoeRailMirrorProject)
if ($MoeRailProjectGodotDestReal -ne (Join-Path $MoeRailMirrorProjectReal 'project.godot')) {
    throw "project.godot destination not directly under mirror project"
}

# --- Enumerate feature tracked + untracked-nonignored project files ---
Write-Host "=== Enumerating feature source files ==="
$MoeRailTracked = @(Get-MoeRailGitNulPaths -Worktree $MoeRailFeatureWorktree -GitArguments @('ls-files','-z') -Label 'feature tracked ls-files')
$MoeRailUntrackedNonIgnored = @(Get-MoeRailGitNulPaths -Worktree $MoeRailFeatureWorktree -GitArguments @('ls-files','-z','--others','--exclude-standard') -Label 'feature untracked ls-files')
$MoeRailProjectPrefixedSet = [System.Collections.Generic.SortedSet[string]]::new([StringComparer]::Ordinal)
foreach ($MoeRailCandidatePath in @($MoeRailTracked + $MoeRailUntrackedNonIgnored)) {
    if ($MoeRailCandidatePath.StartsWith('godot-project-moe-rail-way/', [StringComparison]::Ordinal)) {
        [void]$MoeRailProjectPrefixedSet.Add($MoeRailCandidatePath)
    }
}
$MoeRailProjectPrefixed = @($MoeRailProjectPrefixedSet)
if ($MoeRailProjectPrefixed.Count -eq 0) {
    throw "No project-prefixed files found in feature worktree"
}

# Strip exact godot-project-moe-rail-way/ prefix for mirror-relative keys
$MoeRailSourceManifest = @($MoeRailProjectPrefixed | ForEach-Object {
    if ($_ -notmatch '^godot-project-moe-rail-way/') {
        throw "Manifest entry missing required prefix: $_"
    }
    $_.Substring('godot-project-moe-rail-way/'.Length)
})

# Build pre-copy manifest with hashes and full validation
$MoeRailPreCopyManifest = [System.Collections.Generic.SortedDictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($MoeRailRelPath in $MoeRailSourceManifest) {
    $MoeRailSrcAbs = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way' $MoeRailRelPath
    if (-not (Test-Path -LiteralPath $MoeRailSrcAbs -PathType Leaf)) {
        throw "Source is not an ordinary file: $MoeRailRelPath"
    }
    # Validate source chain
    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailSrcAbs -Boundary $MoeRailFeatureWorktree)
    $MoeRailDstAbs = Join-Path $MoeRailMirrorProject $MoeRailRelPath
    $MoeRailDstAbsReal = [IO.Path]::GetFullPath($MoeRailDstAbs)
    $MoeRailMirrorProjectReal = [IO.Path]::GetFullPath($MoeRailMirrorProject)
    if (-not $MoeRailDstAbsReal.StartsWith($MoeRailMirrorProjectReal + [IO.Path]::DirectorySeparatorChar)) {
        throw "Destination escapes mirror project: $MoeRailRelPath"
    }
    if ($MoeRailRelPath -match '(^|/)\.git(/.*)?$' -or $MoeRailRelPath -match '(^|/)\.godot(/.*)?$') {
        throw "Forbidden path component in manifest: $MoeRailRelPath"
    }
    if (Test-Path -LiteralPath $MoeRailDstAbs) {
        throw "Destination already exists: $MoeRailRelPath"
    }
    [void] (Assert-MoeRailOrdinaryPathChain -Path $MoeRailMirrorProject -Boundary $MoeRailMirrorRoot)
    [void] (Assert-MoeRailOrdinaryTree -Root $MoeRailMirrorProject)
    $MoeRailPreCopyManifest[$MoeRailRelPath] = (Get-FileHash -LiteralPath $MoeRailSrcAbs -Algorithm SHA256).Hash
}

# --- Copy files to mirror ---
Write-Host "=== Copying files to mirror ==="
foreach ($MoeRailRelPath in $MoeRailPreCopyManifest.Keys) {
    $MoeRailSrcAbs = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way' $MoeRailRelPath
    $MoeRailDstAbs = Join-Path $MoeRailMirrorProject $MoeRailRelPath
    [void] (Assert-MoeRailOrdinaryTree -Root $MoeRailMirrorProject)
    $MoeRailDstDir = Split-Path $MoeRailDstAbs -Parent
    if (Test-Path -LiteralPath $MoeRailDstAbs) {
        throw "Destination already exists: $MoeRailRelPath"
    }
    if (-not (Test-Path -LiteralPath $MoeRailDstDir -PathType Container)) {
        New-Item -ItemType Directory -Path $MoeRailDstDir -ErrorAction Stop | Out-Null
    }
    if (-not (Test-Path -LiteralPath $MoeRailDstDir -PathType Container)) {
        throw "Destination directory is not a container: $MoeRailRelPath"
    }
    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailDstDir -Boundary $MoeRailMirrorProject)
    if (-not (Test-Path -LiteralPath $MoeRailSrcAbs -PathType Leaf)) { throw "Source path '$MoeRailRelPath' is not a leaf file." }
    [void] (Assert-MoeRailOrdinaryPathChain -Path $MoeRailSrcAbs -Boundary $MoeRailFeatureWorktree)
    Copy-Item -LiteralPath $MoeRailSrcAbs -Destination $MoeRailDstAbs -Force -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $MoeRailDstAbs -PathType Leaf)) {
        throw "Destination leaf not created: $MoeRailRelPath"
    }
    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailDstAbs -Boundary $MoeRailMirrorProject)
}

# --- Verify post-copy: source unchanged, mirror matches ---
Write-Host "=== Verifying post-copy manifest ==="
foreach ($MoeRailRelPath in $MoeRailPreCopyManifest.Keys) {
    $MoeRailSrcAbs = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way' $MoeRailRelPath
    $MoeRailDstAbs = Join-Path $MoeRailMirrorProject $MoeRailRelPath
    $MoeRailSrcHash = (Get-FileHash -LiteralPath $MoeRailSrcAbs -Algorithm SHA256).Hash
    $MoeRailDstHash = (Get-FileHash -LiteralPath $MoeRailDstAbs -Algorithm SHA256).Hash
    if ($MoeRailSrcHash -ne $MoeRailPreCopyManifest[$MoeRailRelPath]) {
        throw "Source file changed during copy: $MoeRailRelPath"
    }
    if ($MoeRailDstHash -ne $MoeRailPreCopyManifest[$MoeRailRelPath]) {
        throw "Mirror file hash mismatch: $MoeRailRelPath"
    }
}
# Independent mirror snapshot
$MoeRailMirrorProjectReal = [IO.Path]::GetFullPath($MoeRailMirrorProject)
$MoeRailMirrorSnapshot = @(Get-ChildItem -LiteralPath $MoeRailMirrorProject -Recurse -File | ForEach-Object {
    if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Mirror contains reparse point: $($_.FullName)"
    }
    $MoeRailRel = $_.FullName.Substring($MoeRailMirrorProjectReal.Length + 1).Replace('\', '/')
    @{ Path = $MoeRailRel; Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
})
$MoeRailMirrorPaths = [string[]]@($MoeRailMirrorSnapshot | ForEach-Object { $_.Path })
$MoeRailSourcePaths = [string[]]@($MoeRailSourceManifest)
[Array]::Sort($MoeRailMirrorPaths, [StringComparer]::Ordinal)
[Array]::Sort($MoeRailSourcePaths, [StringComparer]::Ordinal)
if (-not [System.Linq.Enumerable]::SequenceEqual($MoeRailSourcePaths, $MoeRailMirrorPaths, [StringComparer]::Ordinal)) {
    throw "Mirror file set differs from source manifest: source=$($MoeRailSourcePaths.Count) mirror=$($MoeRailMirrorPaths.Count)"
}
foreach ($MoeRailEntry in $MoeRailMirrorSnapshot) {
    if ($MoeRailEntry.Hash -ne $MoeRailPreCopyManifest[$MoeRailEntry.Path]) {
        throw "Mirror snapshot hash mismatch: $($MoeRailEntry.Path)"
    }
}

Assert-MoeRailMirrorState `
    -Phase 'post-copy' `
    -TempRoot $MoeRailTempRoot `
    -Root $MoeRailMirrorRoot `
    -Project $MoeRailMirrorProject `
    -Environment $MoeRailMirrorEnv `
    -Logs $MoeRailMirrorLogs `
    -RequireProjectGodot |
    Out-Null

# --- Verify feature/primary state unchanged after copy ---
Write-Host "=== Verifying feature/primary state unchanged after copy ==="
Assert-MoeRailFeatureState -Phase 'post-copy' -FailureHandler { }
Assert-MoeRailPrimaryState -Phase 'post-copy' -FailureHandler { }

# --- Prepare isolated environment ---
Write-Host "=== Preparing isolated environment ==="
$MoeRailMirrorEnvAppData = Join-Path $MoeRailMirrorEnv 'appdata'
$MoeRailMirrorEnvLocalAppData = Join-Path $MoeRailMirrorEnv 'localappdata'
$MoeRailMirrorEnvTemp = Join-Path $MoeRailMirrorEnv 'temp'

# --- Capture pre-launch PID baseline for Godot processes matching mirror ---
Write-Host "=== Capturing pre-launch PID baseline ==="
$MoeRailPreLaunchMatches = Get-MoeRailCimMatches -MirrorProjectPath $MoeRailMirrorProject

$MoeRailCimReady = $true

# --- Launch Godot import in mirror ---
Write-Host "=== Launching Godot editor import ==="
$MoeRailImportEngineLog = [IO.Path]::GetFullPath(
    (Join-Path $MoeRailMirrorLogs 'godot_import_engine.log')
).TrimEnd('\')
$MoeRailExpectedImportEngineLog = [IO.Path]::GetFullPath(
    (Join-Path $MoeRailMirrorLogs 'godot_import_engine.log')
).TrimEnd('\')
if (-not $MoeRailImportEngineLog.Equals(
        $MoeRailExpectedImportEngineLog,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "import engine log path mismatch"
}
if (Test-Path -LiteralPath $MoeRailImportEngineLog) {
    throw "import engine log already exists"
}

Assert-MoeRailMirrorState `
    -Phase 'pre-import-child' `
    -TempRoot $MoeRailTempRoot `
    -Root $MoeRailMirrorRoot `
    -Project $MoeRailMirrorProject `
    -Environment $MoeRailMirrorEnv `
    -Logs $MoeRailMirrorLogs `
    -RequireProjectGodot |
    Out-Null

$MoeRailImportEnv = @{
    'APPDATA'      = $MoeRailMirrorEnvAppData
    'LOCALAPPDATA' = $MoeRailMirrorEnvLocalAppData
    'TEMP'         = $MoeRailMirrorEnvTemp
    'TMP'          = $MoeRailMirrorEnvTemp
}
$MoeRailImportResult = Invoke-MoeRailBoundedProcess `
    -Executable $MoeRailGodotExe `
    -Arguments @('--headless','--editor','--path',$MoeRailMirrorProject,'--import','--quit-after','240','--log-file',$MoeRailImportEngineLog) `
    -EnvironmentOverrides $MoeRailImportEnv `
    -Label 'import' `
    -OwnedChildren $MoeRailOwnedChildren

Assert-MoeRailMirrorState `
    -Phase 'post-import-child' `
    -TempRoot $MoeRailTempRoot `
    -Root $MoeRailMirrorRoot `
    -Project $MoeRailMirrorProject `
    -Environment $MoeRailMirrorEnv `
    -Logs $MoeRailMirrorLogs `
    -RequireProjectGodot |
    Out-Null
[void](Assert-MoeRailMirrorManifest -Phase 'post-import-child' -Project $MoeRailMirrorProject -Root $MoeRailMirrorRoot -ExpectedManifest $MoeRailPreCopyManifest)

$MoeRailImportStdout = $MoeRailImportResult.Stdout
$MoeRailImportStderr = $MoeRailImportResult.Stderr
$MoeRailImportExitCode = $MoeRailImportResult.ExitCode

$MoeRailActualImportEngineLog = [IO.Path]::GetFullPath($MoeRailImportEngineLog).TrimEnd('\')
if (-not $MoeRailActualImportEngineLog.Equals(
        $MoeRailExpectedImportEngineLog,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "import engine log path mismatch"
}
if (-not (Test-Path -LiteralPath $MoeRailActualImportEngineLog -PathType Leaf)) {
    throw "import engine log file not found"
}
$MoeRailImportEngineLogItem = Get-Item -LiteralPath $MoeRailActualImportEngineLog -Force
if (($MoeRailImportEngineLogItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "import engine log is a reparse point at '$MoeRailActualImportEngineLog'"
}
$MoeRailActualImportEngineLog = [IO.Path]::GetFullPath(
    $MoeRailImportEngineLogItem.FullName
).TrimEnd('\')
if (-not $MoeRailActualImportEngineLog.Equals(
        $MoeRailExpectedImportEngineLog,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "import engine log path mismatch"
}
[void](Assert-MoeRailOrdinaryPathChain `
    -Path $MoeRailActualImportEngineLog `
    -Boundary $MoeRailMirrorLogs)
$MoeRailImportEngineText = Get-MoeRailLogText -Path $MoeRailActualImportEngineLog

Write-Host "Import exit code: $MoeRailImportExitCode"
Write-Host "Import stdout:`n$MoeRailImportStdout"
Write-Host "Import stderr:`n$MoeRailImportStderr"
Write-Host "Import engine log:`n$MoeRailImportEngineText"

if ($MoeRailImportExitCode -ne 0) {
    throw "Godot import exited with code $MoeRailImportExitCode"
}
$MoeRailStrictDiagnosticPattern = '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)'
$MoeRailCrashLeakPattern = '(?i)(CrashHandlerException|Program crashed|signal\s+\d+|Scan thread aborted|RID[^\r\n]*(?:leak|allocation)|ObjectDB[^\r\n]*(?:leaked at exit|still alive)|Resources?[^\r\n]*still in use)'
$MoeRailImportChannels = [ordered]@{
    stdout     = $MoeRailImportStdout
    stderr     = $MoeRailImportStderr
    engine_log = $MoeRailImportEngineText
}
foreach ($MoeRailChannelName in $MoeRailImportChannels.Keys) {
    $MoeRailChannelText = $MoeRailImportChannels[$MoeRailChannelName]
    if ($MoeRailChannelText -match $MoeRailStrictDiagnosticPattern) {
        throw "Prohibited diagnostic found in import $MoeRailChannelName"
    }
    if ($MoeRailChannelText -match $MoeRailCrashLeakPattern) {
        throw "Crash/leak diagnostic found in import $MoeRailChannelName"
    }
}

# --- Verify global_script_class_cache.cfg registers TrackInputFrame and TrackSystem by path ---
Write-Host "=== Verifying global script class cache ==="
$MoeRailCacheCfg = Join-Path $MoeRailMirrorProject '.godot/global_script_class_cache.cfg'
if (-not (Test-Path -LiteralPath $MoeRailCacheCfg -PathType Leaf)) {
    throw "global_script_class_cache.cfg not found at $MoeRailCacheCfg"
}
[void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailCacheCfg -Boundary $MoeRailMirrorProject)
$MoeRailRawLines = Get-Content -Path $MoeRailCacheCfg -Raw -Encoding UTF8 -ErrorAction Stop
$MoeRailLines = $MoeRailRawLines -split "`r?`n"
$MoeRailNonBlankIndices = @()
for ($MoeRailIdx = 0; $MoeRailIdx -lt $MoeRailLines.Count; $MoeRailIdx++) {
    if ($MoeRailLines[$MoeRailIdx].Trim() -ne '') { $MoeRailNonBlankIndices += $MoeRailIdx }
}
if ($MoeRailNonBlankIndices.Count -lt 2) { throw "Cache file has fewer than two nonblank lines" }
$MoeRailFirstTrimmed = $MoeRailLines[$MoeRailNonBlankIndices[0]].Trim()
$MoeRailLastTrimmed = $MoeRailLines[$MoeRailNonBlankIndices[-1]].Trim()
if (-not [string]::Equals($MoeRailFirstTrimmed, 'list=[{', [StringComparison]::Ordinal)) { throw "First nonblank line is not 'list=[{' but: $MoeRailFirstTrimmed" }
if (-not [string]::Equals($MoeRailLastTrimmed, '}]', [StringComparison]::Ordinal)) { throw "Last nonblank line is not '}]' but: $MoeRailLastTrimmed" }
$MoeRailFirstCount = ($MoeRailLines | Where-Object { [string]::Equals($_.Trim(), 'list=[{', [StringComparison]::Ordinal) }).Count
$MoeRailLastCount = ($MoeRailLines | Where-Object { [string]::Equals($_.Trim(), '}]', [StringComparison]::Ordinal) }).Count
if ($MoeRailFirstCount -ne 1) { throw "Boundary 'list=[{' occurs $MoeRailFirstCount times, expected exactly one" }
if ($MoeRailLastCount -ne 1) { throw "Boundary '}]' occurs $MoeRailLastCount times, expected exactly one" }
$MoeRailEntries = @()
$MoeRailCurrentEntry = @()
$MoeRailCurrentEntryHasContent = $false
$MoeRailUnexpectedBodyTokens = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$null = $MoeRailUnexpectedBodyTokens.Add('{')
$null = $MoeRailUnexpectedBodyTokens.Add('}')
$null = $MoeRailUnexpectedBodyTokens.Add('[{')
$null = $MoeRailUnexpectedBodyTokens.Add('}]')
$null = $MoeRailUnexpectedBodyTokens.Add('list=[{')
for ($MoeRailIdx = $MoeRailNonBlankIndices[0] + 1; $MoeRailIdx -lt $MoeRailNonBlankIndices[-1]; $MoeRailIdx++) {
    $MoeRailLine = $MoeRailLines[$MoeRailIdx]
    $MoeRailTrimmed = $MoeRailLine.Trim()
    if ([string]::Equals($MoeRailTrimmed, '}, {', [System.StringComparison]::Ordinal)) {
        if (-not $MoeRailCurrentEntryHasContent) { throw "Empty entry before '}, {' at line $($MoeRailIdx + 1)" }
        $MoeRailEntries += ,$MoeRailCurrentEntry
        $MoeRailCurrentEntry = @()
        $MoeRailCurrentEntryHasContent = $false
        continue
    }
    if ($MoeRailUnexpectedBodyTokens.Contains($MoeRailTrimmed)) {
        throw "Unexpected structural token '$MoeRailTrimmed' inside body at line $($MoeRailIdx + 1)"
    }
    if ($MoeRailTrimmed -ne '') { $MoeRailCurrentEntryHasContent = $true }
    $MoeRailCurrentEntry += $MoeRailLine
}
if (-not $MoeRailCurrentEntryHasContent) { throw "Final entry has no nonblank lines" }
$MoeRailEntries += ,$MoeRailCurrentEntry
$MoeRailClassRegex = '^"class"\s*:\s*&?"([^"]+)"\s*,?\s*$'
$MoeRailPathRegex = '^\s*"path"\s*:\s*"([^"]+)"\s*,?\s*$'
$MoeRailSeenClasses = [System.Collections.Generic.Dictionary[string,bool]]::new([StringComparer]::Ordinal)
$MoeRailEntriesByPath = [System.Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($MoeRailEntry in $MoeRailEntries) {
    $MoeRailEntryClass = $null
    $MoeRailEntryPath = $null
    $MoeRailClassCount = 0
    $MoeRailPathCount = 0
    foreach ($MoeRailEntryLine in $MoeRailEntry) {
        $MoeRailEntryTrimmed = $MoeRailEntryLine.Trim()
        if ($MoeRailEntryTrimmed -cmatch $MoeRailClassRegex) {
            $MoeRailClassCount++
            if ($MoeRailClassCount -gt 1) { throw "Duplicate class field in entry" }
            $MoeRailEntryClass = $matches[1]
        }
        elseif ($MoeRailEntryTrimmed -cmatch $MoeRailPathRegex) {
            $MoeRailPathCount++
            if ($MoeRailPathCount -gt 1) { throw "Duplicate path field in entry" }
            $MoeRailEntryPath = $matches[1]
        }
    }
    if ($MoeRailClassCount -ne 1) { throw "Entry missing exactly one class field" }
    if ($MoeRailPathCount -ne 1) { throw "Entry missing exactly one path field" }
    if ($MoeRailSeenClasses.ContainsKey($MoeRailEntryClass)) { throw "Duplicate class name across entries: $MoeRailEntryClass" }
    $MoeRailSeenClasses.Add($MoeRailEntryClass, $true)
    if ($MoeRailEntriesByPath.ContainsKey($MoeRailEntryPath)) { throw "Duplicate path across entries: $MoeRailEntryPath" }
    $MoeRailEntriesByPath.Add($MoeRailEntryPath, $MoeRailEntryClass)
}
$MoeRailRequiredClassesByPath = [System.Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
$MoeRailRequiredClassesByPath.Add('res://src/domain/track/track_input_frame.gd', 'TrackInputFrame')
$MoeRailRequiredClassesByPath.Add('res://src/domain/track/track_system.gd', 'TrackSystem')
foreach ($MoeRailRequiredPath in $MoeRailRequiredClassesByPath.Keys) {
    if (-not $MoeRailEntriesByPath.ContainsKey($MoeRailRequiredPath)) { throw "Required cache path missing: $MoeRailRequiredPath" }
    $MoeRailExpectedClass = $MoeRailRequiredClassesByPath[$MoeRailRequiredPath]
    $MoeRailActualClass = $MoeRailEntriesByPath[$MoeRailRequiredPath]
    if (-not [string]::Equals($MoeRailActualClass, $MoeRailExpectedClass, [StringComparison]::Ordinal)) {
        throw "Class mismatch for cache path $MoeRailRequiredPath`: expected $MoeRailExpectedClass, got $MoeRailActualClass"
    }
}
Write-Host "global_script_class_cache.cfg contains TrackInputFrame and TrackSystem each with expected path in same entry"

# --- Verify feature/primary state unchanged after import ---
Write-Host "=== Verifying feature/primary state unchanged after import ==="
Assert-MoeRailFeatureState -Phase 'post-import' -FailureHandler { }
Assert-MoeRailPrimaryState -Phase 'post-import' -FailureHandler { }
$MoeRailPostImportMatches = Get-MoeRailCimMatches -MirrorProjectPath $MoeRailMirrorProject
$MoeRailNewPostImport = @($MoeRailPostImportMatches | Where-Object { $_ -notin $MoeRailPreLaunchMatches })
if ($MoeRailNewPostImport.Count -ne 0) {
    throw "New matching Godot processes after import: $($MoeRailNewPostImport -join ',')"
}

# --- Launch unit tests in mirror ---
Write-Host "=== Launching unit tests ==="
$MoeRailTestLogFile = Join-Path $MoeRailMirrorLogs 'godot_test.log'

$MoeRailTestEnv = @{
    'APPDATA'      = $MoeRailMirrorEnvAppData
    'LOCALAPPDATA' = $MoeRailMirrorEnvLocalAppData
    'TEMP'         = $MoeRailMirrorEnvTemp
    'TMP'          = $MoeRailMirrorEnvTemp
}
$MoeRailTestResult = Invoke-MoeRailBoundedProcess `
    -Executable $MoeRailGodotExe `
    -Arguments @('--headless','--path',$MoeRailMirrorProject,'--script','res://tests/run_all.gd') `
    -EnvironmentOverrides $MoeRailTestEnv `
    -Label 'test' `
    -OwnedChildren $MoeRailOwnedChildren

Assert-MoeRailMirrorState `
    -Phase 'post-test-child' `
    -TempRoot $MoeRailTempRoot `
    -Root $MoeRailMirrorRoot `
    -Project $MoeRailMirrorProject `
    -Environment $MoeRailMirrorEnv `
    -Logs $MoeRailMirrorLogs `
    -RequireProjectGodot |
    Out-Null
[void](Assert-MoeRailMirrorManifest -Phase 'post-test-child' -Project $MoeRailMirrorProject -Root $MoeRailMirrorRoot -ExpectedManifest $MoeRailPreCopyManifest)

$MoeRailTestStdout = $MoeRailTestResult.Stdout
$MoeRailTestStderr = $MoeRailTestResult.Stderr
$MoeRailTestExitCode = $MoeRailTestResult.ExitCode

# Write captures to ordinary non-reparse files
[IO.File]::WriteAllText($MoeRailTestLogFile, $MoeRailTestStdout + "`n" + $MoeRailTestStderr, [Text.UTF8Encoding]::new($false))
$MoeRailTestLogItem = Get-Item -LiteralPath $MoeRailTestLogFile -Force
if (($MoeRailTestLogItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Test log is a reparse point"
}

$MoeRailTestCombined = $MoeRailTestStdout + "`n" + $MoeRailTestStderr
Write-Host "Test exit code: $MoeRailTestExitCode"
Write-Host "Test combined output:`n$MoeRailTestCombined"

if ($MoeRailTestExitCode -ne 0) {
    throw "Godot test exited with code $MoeRailTestExitCode"
}
$MoeRailPassCount = [regex]::Matches($MoeRailTestCombined, '(?m)^PASS: 9 prototype test suite\(s\)\r?$').Count
if ($MoeRailPassCount -ne 1) {
    throw "Expected exactly one 'PASS: 9 prototype test suite(s)' line, found $MoeRailPassCount"
}
$MoeRailTestStrictDiagnosticPattern = '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)'
$MoeRailTestCrashLeakPattern = '(?i)(CrashHandlerException|Program crashed|signal\s+\d+|Scan thread aborted|RID[^\r\n]*(?:leak|allocation)|ObjectDB[^\r\n]*(?:leaked at exit|still alive)|Resources?[^\r\n]*still in use)'
if ($MoeRailTestCombined -match $MoeRailTestStrictDiagnosticPattern) {
    throw "Prohibited diagnostic found in test output"
}
if ($MoeRailTestCombined -match $MoeRailTestCrashLeakPattern) {
    throw "Crash/leak diagnostic found in test output"
}

# --- Verify feature/primary state unchanged after test ---
Write-Host "=== Verifying feature/primary state unchanged after test ==="
Assert-MoeRailFeatureState -Phase 'post-test' -FailureHandler { }
Assert-MoeRailPrimaryState -Phase 'post-test' -FailureHandler { }
$MoeRailPostTestMatches = Get-MoeRailCimMatches -MirrorProjectPath $MoeRailMirrorProject
$MoeRailNewPostTest = @($MoeRailPostTestMatches | Where-Object { $_ -notin $MoeRailPreLaunchMatches })
if ($MoeRailNewPostTest.Count -ne 0) {
    throw "New matching Godot processes after test: $($MoeRailNewPostTest -join ',')"
}

$MoeRailOverallSuccess = $true

}
catch {
    $MoeRailOriginalError = $_
}
finally {
    # --- Cleanup all owned records on every path ---
    foreach ($MoeRailOwnedRecord in $MoeRailOwnedChildren) {
        if ($MoeRailOwnedRecord -and $MoeRailOwnedRecord.Process) {
            $MoeRailProc = $MoeRailOwnedRecord.Process
            if (-not $MoeRailOwnedRecord.Disposed) {
                $MoeRailRecordExited = $false
                if ($MoeRailOwnedRecord.Started) {
                    try {
                        if ($MoeRailProc.HasExited) {
                            $MoeRailRecordExited = $true
                        }
                    }
                    catch {
                        $MoeRailCleanupErrors.Add("HasExited check error for {$($MoeRailOwnedRecord.Label)}: $($_.Exception.Message)")
                    }

                    if (-not $MoeRailRecordExited) {
                        try {
                            $MoeRailProc.Kill($true)
                        }
                        catch {
                            $MoeRailCleanupErrors.Add("Kill error for {$($MoeRailOwnedRecord.Label)}: $($_.Exception.Message)")
                        }

                        try {
                            if ($MoeRailProc.WaitForExit(5000)) {
                                $MoeRailRecordExited = $true
                            }
                            else {
                                $MoeRailCleanupErrors.Add("Reap timeout after kill for {$($MoeRailOwnedRecord.Label)}")
                            }
                        }
                        catch {
                            $MoeRailCleanupErrors.Add("Reap error for {$($MoeRailOwnedRecord.Label)}: $($_.Exception.Message)")
                        }
                    }
                }
                else {
                    $MoeRailRecordExited = $true
                }

                if ($MoeRailRecordExited) {
                    if ($null -ne $MoeRailOwnedRecord.StdoutReader) {
                        try { $MoeRailOwnedRecord.StdoutReader.Dispose() }
                        catch { $MoeRailCleanupErrors.Add("StdoutReader dispose error for {$($MoeRailOwnedRecord.Label)}: $($_.Exception.Message)") }
                    }
                    if ($null -ne $MoeRailOwnedRecord.StderrReader) {
                        try { $MoeRailOwnedRecord.StderrReader.Dispose() }
                        catch { $MoeRailCleanupErrors.Add("StderrReader dispose error for {$($MoeRailOwnedRecord.Label)}: $($_.Exception.Message)") }
                    }

                    try {
                        $MoeRailProc.Dispose()
                        $MoeRailOwnedRecord.Disposed = $true
                    }
                    catch {
                        $MoeRailCleanupErrors.Add("Process dispose error for {$($MoeRailOwnedRecord.Label)}: $($_.Exception.Message)")
                    }
                }
                else {
                    $MoeRailCleanupErrors.Add("Owned process still alive after cleanup attempts for {$($MoeRailOwnedRecord.Label)}")
                }
            }
        }
    }

    # --- Final state assertions ---
    if ($MoeRailFeatureReady) {
        try { Assert-MoeRailFeatureState -Phase 'final' -FailureHandler { } }
        catch { $MoeRailCleanupErrors.Add("Final feature state assertion failed: $($_.Exception.Message)") }
    }
    if ($MoeRailPrimaryReady) {
        try { Assert-MoeRailPrimaryState -Phase 'final' -FailureHandler { } }
        catch { $MoeRailCleanupErrors.Add("Final primary state assertion failed: $($_.Exception.Message)") }
    }
    if ($MoeRailCimReady -and $MoeRailMirrorProject) {
        try {
            $MoeRailFinalMatches = Get-MoeRailCimMatches -MirrorProjectPath $MoeRailMirrorProject
            $MoeRailLeftovers = @($MoeRailFinalMatches | Where-Object { $_ -notin $MoeRailPreLaunchMatches })
            if ($MoeRailLeftovers.Count -ne 0) {
                $MoeRailCleanupErrors.Add("Leftover matching Godot processes: $($MoeRailLeftovers -join ',')")
            }
        }
        catch { $MoeRailCleanupErrors.Add("CIM final query error: $($_.Exception.Message)") }
    }

    if ($null -ne $MoeRailMirrorRoot) {
        try {
            if (-not (Test-Path -LiteralPath $MoeRailMirrorRoot -PathType Container)) {
                $MoeRailCleanupErrors.Add("Final mirror state assertion failed: expected mirror root is missing: $MoeRailMirrorRoot")
            }
            else {
                try {
                    Assert-MoeRailMirrorState `
                        -Phase 'final' `
                        -TempRoot $MoeRailTempRoot `
                        -Root $MoeRailMirrorRoot `
                        -Project $MoeRailMirrorProject `
                        -Environment $MoeRailMirrorEnv `
                        -Logs $MoeRailMirrorLogs `
                        -RequireProjectGodot |
                    Out-Null
                    [void](Assert-MoeRailMirrorManifest -Phase 'final' -Project $MoeRailMirrorProject -Root $MoeRailMirrorRoot -ExpectedManifest $MoeRailPreCopyManifest)
                }
                catch {
                    $MoeRailCleanupErrors.Add("Final mirror state assertion failed: $($_.Exception.Message)")
                }
            }
        }
        catch {
            $MoeRailCleanupErrors.Add("Final mirror state assertion probe failed: $($_.Exception.Message)")
        }
    }

    # --- Determine mirror disposition ---
    if ($MoeRailOverallSuccess -and [string]::IsNullOrWhiteSpace($MoeRailMirrorRoot)) {
        $MoeRailCleanupErrors.Add("Successful gate did not retain an expected mirror root.")
    }

    $MoeRailHasErrors = (-not $MoeRailOverallSuccess) -or
        ($null -ne $MoeRailOriginalError) -or
        ($MoeRailCleanupErrors.Count -gt 0)
    if ($MoeRailHasErrors) {
        try {
            if ($MoeRailMirrorRoot -and ($MoeRailMirrorRoot.Trim() -ne '')) {
                try {
                    if (Test-Path -LiteralPath $MoeRailMirrorRoot) {
                        Write-Host "PRESERVED_DISPOSABLE_MIRROR=$MoeRailMirrorRoot"
                    }
                }
                catch {
                    $MoeRailCleanupErrors.Add("Preserved mirror probe failed: $($_.Exception.Message)")
                }
            }
        }
        catch {
            $MoeRailCleanupErrors.Add("Preserved mirror guard failed: $($_.Exception.Message)")
        }
        $MoeRailAllErrors = [System.Collections.Generic.List[string]]::new()
        if (-not $MoeRailOverallSuccess) {
            $MoeRailAllErrors.Add("Overall success flag is false.")
        }
        if ($MoeRailOriginalError) {
            $MoeRailAllErrors.Add($MoeRailOriginalError.Exception.Message)
        }
        foreach ($MoeRailCleanupError in $MoeRailCleanupErrors) {
            $MoeRailAllErrors.Add($MoeRailCleanupError)
        }
        throw "Task 3 Step 4 GREEN gate FAILED: " + ($MoeRailAllErrors -join '; ')
    }

    # --- Clean success path: revalidate and delete exact mirror ---
    try {
        if (-not $MoeRailOverallSuccess) {
            throw "OverallSuccess is false; refusing success cleanup"
        }
        if ([string]::IsNullOrWhiteSpace($MoeRailMirrorRoot)) {
            throw "MirrorRoot is null or whitespace"
        }
        if (-not (Test-Path -LiteralPath $MoeRailMirrorRoot -PathType Container)) {
            throw "MirrorRoot does not exist as a container: $MoeRailMirrorRoot"
        }

        $MoeRailMirrorRootRealFinal = [IO.Path]::GetFullPath($MoeRailMirrorRoot).TrimEnd('\')
        $MoeRailTempRootReal = [IO.Path]::GetFullPath($MoeRailTempRoot).TrimEnd('\')
        $MoeRailMirrorParentFinal = [IO.Path]::GetFullPath(
            (Split-Path -Parent $MoeRailMirrorRootRealFinal)
        ).TrimEnd('\')
        $MoeRailMirrorLeafFinal = Split-Path -Leaf $MoeRailMirrorRootRealFinal

        if (-not [string]::Equals(
                $MoeRailMirrorParentFinal,
                $MoeRailTempRootReal,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw "Parent path does not match temp root (case-insensitive)"
        }
        if ($MoeRailMirrorLeafFinal -notmatch '^moerail-track-train-editor-[0-9a-f]{32}$') {
            throw "Leaf name does not match required pattern"
        }

        Assert-MoeRailFeatureState -Phase 'pre-delete' -FailureHandler { }
        Assert-MoeRailPrimaryState -Phase 'pre-delete' -FailureHandler { }
        $MoeRailValidatedDeleteRoot = Assert-MoeRailMirrorState `
            -Phase 'pre-delete' `
            -TempRoot $MoeRailTempRoot `
            -Root $MoeRailMirrorRoot `
            -Project $MoeRailMirrorProject `
            -Environment $MoeRailMirrorEnv `
            -Logs $MoeRailMirrorLogs `
            -RequireProjectGodot
        [void](Assert-MoeRailMirrorManifest -Phase 'pre-delete' -Project $MoeRailMirrorProject -Root $MoeRailMirrorRoot -ExpectedManifest $MoeRailPreCopyManifest)
        $MoeRailValidatedDeleteRoot = [IO.Path]::GetFullPath(
            $MoeRailValidatedDeleteRoot
        ).TrimEnd('\')
        if (-not $MoeRailValidatedDeleteRoot.Equals(
                $MoeRailMirrorRootRealFinal,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            throw "Path mismatch: '$MoeRailValidatedDeleteRoot' does not equal '$MoeRailMirrorRootRealFinal' (case-insensitive)"
        }

        [void](Assert-MoeRailOrdinaryPathChain `
            -Path $MoeRailValidatedDeleteRoot `
            -Boundary $MoeRailTempRootReal)
        [void](Assert-MoeRailOrdinaryTree -Root $MoeRailValidatedDeleteRoot)
        Remove-Item -LiteralPath $MoeRailValidatedDeleteRoot `
            -Recurse -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $MoeRailValidatedDeleteRoot) {
            throw "Mirror still exists after deletion: $MoeRailValidatedDeleteRoot"
        }
    }
    catch {
        $MoeRailDeleteError = $_
        if ([string]::IsNullOrWhiteSpace($MoeRailMirrorRoot) -eq $false) {
            try {
                if (Test-Path -LiteralPath $MoeRailMirrorRoot) {
                    Write-Host "PRESERVED_DISPOSABLE_MIRROR=$MoeRailMirrorRoot"
                }
            }
            catch {
                $MoeRailCleanupErrors.Add("Preserved mirror probe failed after cleanup error: $($_.Exception.Message)")
            }
        }
        $MoeRailCleanupErrors.Add("Mirror success cleanup failed: $($MoeRailDeleteError.Exception.Message)")

        $MoeRailAllErrors = [System.Collections.Generic.List[string]]::new()
        if ($MoeRailOverallSuccess -eq $false) {
            $MoeRailAllErrors.Add("Overall success flag is false.")
        }
        if ($null -ne $MoeRailOriginalError) {
            $MoeRailAllErrors.Add($MoeRailOriginalError.Exception.Message)
        }
        foreach ($e in $MoeRailCleanupErrors) {
            $MoeRailAllErrors.Add($e)
        }
        throw "Task 3 Step 4 GREEN gate FAILED: " + ($MoeRailAllErrors -join '; ')
    }
}

Write-Host "=== Task 3 Step 4 GREEN gate PASSED ==="
~~~

- [x] **Step 5: Task 3 final commit, amend, and reviews are complete**

Clean commit `7bfeb914141aaefdb2fc05adcaa0b876ccc69267` with sole parent `da65a015f4590e454876b0e93758a0c4782a254c` contains exactly seven Task 3 files; separate specification and quality reviews both PASS. Task 4 remains gated by the Step 4 final post-commit gate and sixth-amendment adoption.

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
- at the current maximum `CUSTOM` size of `4000 x 2160`, diagonal corner and final-endpoint recovery at cutoff offset `GEOMETRY_EPSILON / 2.0` and at `GEOMETRY_EPSILON` multiplied by each factor `1.1`, `1.2`, `1.3`, `1.4`, `1.5`, `1.8`, `2.1`, and `50.0` preserves the exact raw return and active scalar plus exact-add inventory, except that final-endpoint `GEOMETRY_EPSILON / 2.0` inventory uses the documented within-epsilon snap-to-total; every retained boundary remains distinct, headings and conservation remain correct, and any exceptional first-segment scalar-versus-geometry delta is no greater than the coordinate-aware float32 bound defined below; factor `10.0` at the same maximum-coordinate diagonal remains within `GEOMETRY_EPSILON` and therefore does not enable the exception;
- on a fresh `4000 x 2160` track with `3000.0` units, reserving from `Vector2(2804.983642578125, 1368.7210693359375)` toward `Vector2(391.3240966796875, 905.2901000976562)` retains the concrete stored endpoint `Vector2(391.323883056640625, 905.2901611328125)` and scalar length `2457.7470703125`; recovery at raw cutoff `0.2` retains exactly `Vector2(2804.787353515625, 1368.683349609375)`, leaves remaining scalar `2457.5470703125002` versus geometric length `2457.54736328125`, enables the first-segment exception, and remains within the coordinate-and-scalar-aware bound;
- on a separate copy of that same stored non-axis segment, recovery at raw cutoff `100.5` retains exactly `Vector2(2706.286376953125, 1349.7708740234375)`, produces both remaining scalar and geometric length `2357.2470703125`, and does not enable the exception;
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

**Godot float32 recovered-boundary representation exception:** In the pinned default-precision Godot 4.7.1 build, GDScript route-distance scalars are float64 while `Vector2` and `PackedVector2Array` coordinates are float32. A noncanonical recovery keeps the normalized scalar unchanged for `active_start_distance`, the stored route distance, recovery accounting, inventory, and the return value. First materialize its retained start coordinate using `collision_point - previous_point.direction_to(collision_point) * remaining_scalar`, where `remaining_scalar` is the unchanged scalar distance from the recovered boundary to `collision_point`. If that direct float32 result equals `collision_point`, the existing 48-iteration bounded retreat searches earlier interpolations until it finds the first distinct retained coordinate; this fallback changes only the retained coordinate and never the normalized scalar, accounting, inventory, or return value. Let `max_abs_coordinate` be the greatest absolute x or y component of the resulting retained start point and `collision_point`, let `scalar_length` be that positive `remaining_scalar`, and define `float32_scale` as `max(max(max_abs_coordinate, scalar_length), 1.0)`. If the resulting first retained segment has `absf(scalar_length - geometric_length) > GEOMETRY_EPSILON`, it may use the exception only when that delta is no greater than `GEOMETRY_EPSILON + float32_scale * pow(2.0, -20.0)`. The `2^-20` term provides sixteen binary32 unit roundoffs for direction normalization, scalar conversion and component multiplication, coordinate subtraction, and the final `distance_to` calculation; the fixed epsilon remains the budget for surrounding float64 route-distance arithmetic.

The exception flag is derived only after direct reconstruction and any required distinct-coordinate fallback, using the scalar-versus-geometry delta of the final retained coordinate. It must not be set preemptively or used to bypass any other failed invariant. The exceptional segment must still have positive scalar length and distinct adjacent coordinates. Every later segment and every nonexceptional first segment must satisfy `absf(scalar_length - geometric_length) <= GEOMETRY_EPSILON`. A repeated or earlier-cutoff no-op preserves the current flag without recomputation. Every successful advancing recovery recomputes the flag for its new first segment, including clearing it for a canonical or ordinary result, and removal of the represented first segment clears it. The widened bound applies only to this first recovered segment's scalar-versus-geometry assertion; it does not relax canonicalization, accounting, conservation, headings, intersection behavior, or any other route comparison. Changing the coordinate bounds, engine precision, reconstruction expression, or float32 operation sequence requires updating this proof and both the positive and negative maximum-range regression cases.

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

Run invalid `TrainSystem` assertion probes in isolated child Godot processes: `test_train_system.gd` calls `OS.execute` with `OS.get_executable_path()` and arguments `--headless`, the same `--path`, `--script res://tests/run_all.gd`, `--quit-after 1`, and a unique `--train-invalid-probe=<case>` user argument after `--`. `run_all.gd` detects that user argument and runs only the selected probe. Capture combined standard output and standard error without re-emitting expected diagnostics, and require both a unique `TRAIN_INVALID_PROBE_BEGIN:<case>` marker and the expected assertion text. Never search for, kill, or reset pre-existing Godot or Steam processes. Do not add files beyond the Task 5 five-file scope. The normal GREEN output remains free of `ERROR:` and `SCRIPT ERROR:` markers.

- [ ] **Step 2: Run the train suite to verify RED**

**Amendment:** A missing `preload` for `res://src/domain/train/train_system.gd` prevents the direct RED process from reaching its `SceneTree` quit path under the exact Godot 4.7.1 build, so add `--quit-after 1` only to the launched RED process. RED acceptance ignores the exit code, which may be `0` despite compile diagnostics, requires the exact missing-path diagnostic, forbids `PASS: 11 prototype test suite(s)`, and never terminates an existing process.

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailProject = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProject --script 'res://tests/run_all.gd' --quit-after 1 2>&1)
$MoeRailText = $MoeRailOutput -join "`n"
$MoeRailOutput
if ($MoeRailText -notmatch 'res://src/domain/train/train_system\.gd' -or
    $MoeRailText -match '(?m)^PASS: 11 prototype test suite\(s\)\r?$') {
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

Close only agent-owned test processes from earlier commands. Do not close a user-owned Godot or Steam editor. Run this block at the exact Task 8 HEAD. The two superseded functions whose text begins `Invoke-MoeRailHistoricalRealFeature` are retained only inside a non-executed here-string; they are never defined or invoked. Only `Invoke-MoeRailDisposableEditorGate` may start editor mode. When the gate target is the protected primary worktree after separately authorized integration, the clean candidate with an identical `HEAD` tree is the editor mirror source, so no protected primary file is copied.

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
$MoeRailCandidateWorktree = [IO.Path]::GetFullPath(
    'D:\godot\MoeRailWay-worktrees\prototype-m3-candidate'
)
$MoeRailPrimaryWorktree = [IO.Path]::GetFullPath('D:\godot\MoeRailWay')
$MoeRailEditorMirrorSourceWorktree = if (
    $MoeRailFeatureWorktree -eq $MoeRailPrimaryWorktree
) {
    $MoeRailCandidateWorktree
} else {
    $MoeRailFeatureWorktree
}
if (-not (Test-Path -LiteralPath $MoeRailEditorMirrorSourceWorktree -PathType Container)) {
    throw "Missing approved editor mirror source: $MoeRailEditorMirrorSourceWorktree"
}
if ($MoeRailFeatureWorktree -eq $MoeRailPrimaryWorktree) {
    $MoeRailPrimaryTree = (git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{tree}').Trim()
    $MoeRailCandidateTree = (
        git -C $MoeRailEditorMirrorSourceWorktree rev-parse 'HEAD^{tree}'
    ).Trim()
    if ($LASTEXITCODE -ne 0 -or $MoeRailPrimaryTree -ne $MoeRailCandidateTree) {
        throw 'Primary and clean candidate trees differ before editor mirroring.'
    }
}

function Get-MoeRailContentSnapshot {
    $MoeRailTrackedPaths = @(git -C $MoeRailFeatureWorktree ls-files)
    $MoeRailTrackedExit = $LASTEXITCODE
    $MoeRailUntrackedPaths = @(
        git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
    )
    $MoeRailUntrackedExit = $LASTEXITCODE
    if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
        throw 'Failed to enumerate the repository content snapshot.'
    }
    @(
        @($MoeRailTrackedPaths + $MoeRailUntrackedPaths) |
            Sort-Object -Unique |
            ForEach-Object {
                $MoeRailSnapshotAbsolute = Join-Path $MoeRailFeatureWorktree $_
                if (-not (Test-Path -LiteralPath $MoeRailSnapshotAbsolute -PathType Leaf)) {
                    throw "Snapshot path is not a file: $_"
                }
                $MoeRailSnapshotHash = (
                    Get-FileHash -LiteralPath $MoeRailSnapshotAbsolute -Algorithm SHA256
                ).Hash
                "$_`t$MoeRailSnapshotHash"
            }
    )
}
function Get-MoeRailStatusSnapshot {
    $MoeRailStatusRows = @(
        git -C $MoeRailFeatureWorktree status --porcelain=v1 --untracked-files=all
    )
    $MoeRailStatusExit = $LASTEXITCODE
    if ($MoeRailStatusExit -ne 0) {
        throw "Failed to capture repository status: exit $MoeRailStatusExit"
    }
    @($MoeRailStatusRows | Sort-Object)
}
function Stop-MoeRailOwnedChild {
    param([System.Diagnostics.Process]$Process)
    $MoeRailTerminationFailure = ''
    try {
        if (-not $Process.HasExited) { $Process.Kill() }
    } catch {
        $MoeRailTerminationFailure = $_.Exception.Message
    }
    try {
        if (-not $Process.WaitForExit(5000)) {
            $MoeRailTerminationFailure = (
                $MoeRailTerminationFailure + ' Child did not exit within the 5-second reap deadline.'
            ).Trim()
        }
    } catch {
        $MoeRailTerminationFailure = (
            $MoeRailTerminationFailure + ' ' + $_.Exception.Message
        ).Trim()
    }
    $MoeRailTerminationFailure
}

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
        $MoeRailRunnerText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
        $MoeRailRunnerText -match '(?i)(CrashHandlerException|Program crashed|signal \d+)') {
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

$MoeRailHistoricalRealFeatureEvidence = @'
function Invoke-MoeRailHistoricalRealFeatureEditorGate {
    $MoeRailMarker = 'PASS: logical track field editor integration'
    $MoeRailBeforeStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailBeforeContent = @(Get-MoeRailContentSnapshot)
    $MoeRailStdoutPath = [IO.Path]::GetTempFileName()
    $MoeRailStderrPath = [IO.Path]::GetTempFileName()
    $MoeRailProcess = $null
    $MoeRailPreserveLogs = $false
    try {
        $MoeRailArguments = @(
            '--headless', '--editor', '--path', $MoeRailProject,
            '--quit-after', '600', '--max-fps', '60', '--',
            '--moerail-logical-field-editor-gate'
        )
        $MoeRailProcess = Start-Process -FilePath $MoeRailGodotExe `
            -ArgumentList $MoeRailArguments -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $MoeRailStdoutPath `
            -RedirectStandardError $MoeRailStderrPath
        $MoeRailTimedOut = -not $MoeRailProcess.WaitForExit(30000)
        $MoeRailTerminationFailure = ''
        if ($MoeRailTimedOut) {
            $MoeRailTerminationFailure = Stop-MoeRailOwnedChild -Process $MoeRailProcess
        }
        $MoeRailOutput = @(
            Get-Content -LiteralPath $MoeRailStdoutPath -ErrorAction SilentlyContinue
            Get-Content -LiteralPath $MoeRailStderrPath -ErrorAction SilentlyContinue
        )
        $MoeRailText = $MoeRailOutput -join "`n"
        $MoeRailOutput
        $MoeRailAfterStatus = @(Get-MoeRailStatusSnapshot)
        $MoeRailAfterContent = @(Get-MoeRailContentSnapshot)
        if ($MoeRailTimedOut) {
            if (-not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
                $MoeRailPreserveLogs = $true
                throw "Logical field editor integration timed out and exact-child cleanup failed: $MoeRailTerminationFailure; logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
            }
            throw 'Logical field editor integration exceeded its 30-second deadline.'
        }
        if ($MoeRailProcess.ExitCode -ne 0 -or
            [regex]::Matches(
                $MoeRailText,
                "(?m)^$([regex]::Escape($MoeRailMarker))\r?$"
            ).Count -ne 1 -or
            $MoeRailText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
            $MoeRailText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))' -or
            @(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeContent $MoeRailAfterContent).Count -ne 0) {
            $MoeRailAfterStatus
            throw 'Logical field editor integration failed its marker, diagnostic, exit, or file-state contract.'
        }
    } finally {
        $MoeRailChildStillRunning = $false
        if ($MoeRailProcess -ne $null) {
            try { $MoeRailChildStillRunning = -not $MoeRailProcess.HasExited } catch {
                $MoeRailChildStillRunning = $true
            }
            $MoeRailProcess.Dispose()
        }
        if ($MoeRailPreserveLogs -or $MoeRailChildStillRunning) {
            "Preserved flagged editor logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
        } else {
            Remove-Item -LiteralPath $MoeRailStdoutPath, $MoeRailStderrPath `
                -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-MoeRailHistoricalRealFeatureNoFlagEditorSmoke {
    $MoeRailBeforeStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailBeforeContent = @(Get-MoeRailContentSnapshot)
    $MoeRailStdoutPath = [IO.Path]::GetTempFileName()
    $MoeRailStderrPath = [IO.Path]::GetTempFileName()
    $MoeRailProcess = $null
    $MoeRailPreserveLogs = $false
    try {
        $MoeRailArguments = @(
            '--headless', '--editor', '--path', $MoeRailProject,
            '--quit-after', '600', '--max-fps', '60'
        )
        $MoeRailProcess = Start-Process -FilePath $MoeRailGodotExe `
            -ArgumentList $MoeRailArguments -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $MoeRailStdoutPath `
            -RedirectStandardError $MoeRailStderrPath
        $MoeRailTimedOut = -not $MoeRailProcess.WaitForExit(30000)
        $MoeRailTerminationFailure = ''
        if ($MoeRailTimedOut) {
            $MoeRailTerminationFailure = Stop-MoeRailOwnedChild -Process $MoeRailProcess
        }
        $MoeRailOutput = @(
            Get-Content -LiteralPath $MoeRailStdoutPath -ErrorAction SilentlyContinue
            Get-Content -LiteralPath $MoeRailStderrPath -ErrorAction SilentlyContinue
        )
        $MoeRailText = $MoeRailOutput -join "`n"
        $MoeRailOutput
        $MoeRailAfterStatus = @(Get-MoeRailStatusSnapshot)
        $MoeRailAfterContent = @(Get-MoeRailContentSnapshot)
        if ($MoeRailTimedOut) {
            if (-not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
                $MoeRailPreserveLogs = $true
                throw "No-flag editor smoke timed out and exact-child cleanup failed: $MoeRailTerminationFailure; logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
            }
            throw 'No-flag editor smoke exceeded its 30-second deadline.'
        }
        if ($MoeRailProcess.ExitCode -ne 0 -or
            $MoeRailText -match '(?m)^(PASS: logical track field editor integration|FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
            $MoeRailText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))' -or
            @(Compare-Object $MoeRailBeforeStatus $MoeRailAfterStatus).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeContent $MoeRailAfterContent).Count -ne 0) {
            $MoeRailAfterStatus
            throw 'The enabled editor plugin was not inert and clean without its gate flag.'
        }
    } finally {
        $MoeRailChildStillRunning = $false
        if ($MoeRailProcess -ne $null) {
            try { $MoeRailChildStillRunning = -not $MoeRailProcess.HasExited } catch {
                $MoeRailChildStillRunning = $true
            }
            $MoeRailProcess.Dispose()
        }
        if ($MoeRailPreserveLogs -or $MoeRailChildStillRunning) {
            "Preserved no-flag editor logs: $MoeRailStdoutPath ; $MoeRailStderrPath"
        } else {
            Remove-Item -LiteralPath $MoeRailStdoutPath, $MoeRailStderrPath `
                -Force -ErrorAction SilentlyContinue
        }
    }
}

'@
function Get-MoeRailWorktreeContentSnapshot {
    param([string]$Worktree)
    $MoeRailTracked = @(git -C $Worktree ls-files)
    $MoeRailTrackedExit = $LASTEXITCODE
    $MoeRailUntracked = @(git -C $Worktree ls-files --others --exclude-standard)
    $MoeRailUntrackedExit = $LASTEXITCODE
    if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
        throw "Failed to enumerate mirror-source content: $Worktree"
    }
    @(
        @($MoeRailTracked + $MoeRailUntracked) | Sort-Object -Unique |
            ForEach-Object {
                $MoeRailAbsolute = Join-Path $Worktree $_
                if (-not (Test-Path -LiteralPath $MoeRailAbsolute -PathType Leaf)) {
                    throw "Snapshot path is not a file: $_"
                }
                $MoeRailHash = (
                    Get-FileHash -LiteralPath $MoeRailAbsolute -Algorithm SHA256
                ).Hash
                "$_`t$MoeRailHash"
            }
    )
}
function Get-MoeRailWorktreeStatusSnapshot {
    param([string]$Worktree)
    $MoeRailRows = @(
        git -C $Worktree status --porcelain=v1 --untracked-files=all
    )
    if ($LASTEXITCODE -ne 0) { throw "Failed to capture status: $Worktree" }
    @($MoeRailRows | Sort-Object)
}

$MoeRailProjectPrefix = 'godot-project-moe-rail-way/'
$MoeRailPrototypeApp = 'godot-project-moe-rail-way/src/app/prototype_app.gd'
$MoeRailMirrorLeafPrefix = 'moerail-track-train-editor-'
function Assert-MoeRailOrdinaryPathChain {
    param([string]$Path, [string]$Boundary)
    $MoeRailFullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $MoeRailFullBoundary = [IO.Path]::GetFullPath($Boundary).TrimEnd('\')
    $MoeRailBoundaryPrefix = $MoeRailFullBoundary + '\'
    if ($MoeRailFullPath -ne $MoeRailFullBoundary -and
        -not $MoeRailFullPath.StartsWith(
            $MoeRailBoundaryPrefix,
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Path escaped its ordinary-file boundary: $MoeRailFullPath"
    }
    $MoeRailCurrent = $MoeRailFullPath
    while ($true) {
        if (-not (Test-Path -LiteralPath $MoeRailCurrent)) {
            throw "Required path-chain item is missing: $MoeRailCurrent"
        }
        $MoeRailCurrentItem = Get-Item -LiteralPath $MoeRailCurrent -Force
        if (($MoeRailCurrentItem.Attributes -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse point is forbidden in path chain: $MoeRailCurrent"
        }
        if ($MoeRailCurrent -eq $MoeRailFullBoundary) { break }
        $MoeRailParent = [IO.Path]::GetFullPath(
            (Split-Path -Parent $MoeRailCurrent)
        ).TrimEnd('\')
        if ($MoeRailParent -eq $MoeRailCurrent) {
            throw "Path chain did not reach its boundary: $MoeRailFullPath"
        }
        $MoeRailCurrent = $MoeRailParent
    }
    $MoeRailFullPath
}
function Assert-MoeRailOrdinaryTree {
    param([string]$Root)
    $MoeRailQueue = [Collections.Generic.Queue[string]]::new()
    $MoeRailQueue.Enqueue($Root)
    while ($MoeRailQueue.Count -gt 0) {
        $MoeRailDirectory = $MoeRailQueue.Dequeue()
        foreach ($MoeRailChild in Get-ChildItem -LiteralPath $MoeRailDirectory -Force) {
            if (($MoeRailChild.Attributes -band
                [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse point is forbidden in mirror tree: $($MoeRailChild.FullName)"
            }
            if ($MoeRailChild.PSIsContainer) {
                $MoeRailQueue.Enqueue($MoeRailChild.FullName)
            }
        }
    }
}
function Assert-MoeRailMirrorRoot {
    param([string]$Root)
    $MoeRailTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $MoeRailFullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $MoeRailRootParent = [IO.Path]::GetFullPath(
        (Split-Path -Parent $MoeRailFullRoot)
    ).TrimEnd('\')
    if ($MoeRailRootParent -ne $MoeRailTemp -or
        (Split-Path -Leaf $MoeRailFullRoot) -notmatch
        '^moerail-track-train-editor-[0-9a-f]{32}$') {
        throw "Unsafe disposable mirror root: $MoeRailFullRoot"
    }
    [void](Assert-MoeRailOrdinaryPathChain -Path $MoeRailTemp -Boundary $MoeRailTemp)
    if (Test-Path -LiteralPath $MoeRailFullRoot) {
        [void](Assert-MoeRailOrdinaryPathChain `
            -Path $MoeRailFullRoot -Boundary $MoeRailTemp)
    }
    $MoeRailFullRoot
}
function New-MoeRailDisposableEditorMirror {
    $MoeRailTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $MoeRailRoot = Assert-MoeRailMirrorRoot -Root (
        Join-Path $MoeRailTemp (
            $MoeRailMirrorLeafPrefix + [guid]::NewGuid().ToString('N')
        )
    )
    try {
        $MoeRailMirrorProject = Join-Path $MoeRailRoot 'project'
        $MoeRailEnvironment = Join-Path $MoeRailRoot 'environment'
        $MoeRailAppData = Join-Path $MoeRailEnvironment 'appdata'
        $MoeRailLocalAppData = Join-Path $MoeRailEnvironment 'localappdata'
        $MoeRailChildTemp = Join-Path $MoeRailEnvironment 'temp'
        $MoeRailLogs = Join-Path $MoeRailRoot 'logs'
        foreach ($MoeRailDirectory in @(
            $MoeRailMirrorProject, $MoeRailAppData, $MoeRailLocalAppData,
            $MoeRailChildTemp, $MoeRailLogs
        )) {
            New-Item -ItemType Directory -Path $MoeRailDirectory | Out-Null
        }
        $MoeRailTracked = @(
            git -C $MoeRailEditorMirrorSourceWorktree ls-files
        )
        $MoeRailTrackedExit = $LASTEXITCODE
        $MoeRailUntracked = @(
            git -C $MoeRailEditorMirrorSourceWorktree `
                ls-files --others --exclude-standard
        )
        $MoeRailUntrackedExit = $LASTEXITCODE
        if ($MoeRailTrackedExit -ne 0 -or $MoeRailUntrackedExit -ne 0) {
            throw 'Failed to select disposable mirror files.'
        }
        $MoeRailProjectPaths = @(
            @($MoeRailTracked + $MoeRailUntracked) | Sort-Object -Unique |
                Where-Object {
                    $_.StartsWith(
                        $MoeRailProjectPrefix,
                        [StringComparison]::Ordinal
                    )
                }
        )
        if ($MoeRailProjectPaths.Count -eq 0) {
            throw 'No project files were selected for the disposable mirror.'
        }
        $MoeRailMirrorPrefix = $MoeRailMirrorProject.TrimEnd('\') + '\'
        $MoeRailManifest = @()
        foreach ($MoeRailRepositoryPath in $MoeRailProjectPaths) {
            $MoeRailRelative = $MoeRailRepositoryPath.Substring(
                $MoeRailProjectPrefix.Length
            )
            if ($MoeRailRelative -match '(^|/)(\.git|\.godot)(/|$)') {
                throw "Repository metadata or generated project data is forbidden in a mirror: $MoeRailRepositoryPath"
            }
            $MoeRailSource = Join-Path `
                $MoeRailEditorMirrorSourceWorktree $MoeRailRepositoryPath
            if (-not (Test-Path -LiteralPath $MoeRailSource -PathType Leaf)) {
                throw "Mirror source is not an ordinary file: $MoeRailRepositoryPath"
            }
            [void](Assert-MoeRailOrdinaryPathChain `
                -Path $MoeRailSource `
                -Boundary $MoeRailEditorMirrorSourceWorktree)
            $MoeRailDestination = [IO.Path]::GetFullPath(
                (Join-Path $MoeRailMirrorProject $MoeRailRelative)
            )
            if (-not $MoeRailDestination.StartsWith(
                $MoeRailMirrorPrefix,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                throw "Mirror destination escaped its root: $MoeRailRepositoryPath"
            }
            $MoeRailSourceHash = (
                Get-FileHash -LiteralPath $MoeRailSource -Algorithm SHA256
            ).Hash
            $MoeRailManifest += [pscustomobject]@{
                Relative = $MoeRailRelative
                Source = $MoeRailSource
                Destination = $MoeRailDestination
                Hash = $MoeRailSourceHash
            }
        }
        foreach ($MoeRailManifestEntry in $MoeRailManifest) {
            New-Item -ItemType Directory -Path (
                Split-Path -Parent $MoeRailManifestEntry.Destination
            ) -Force | Out-Null
            [void](Assert-MoeRailOrdinaryPathChain `
                -Path (Split-Path -Parent $MoeRailManifestEntry.Destination) `
                -Boundary $MoeRailMirrorProject)
            Copy-Item -LiteralPath $MoeRailManifestEntry.Source `
                -Destination $MoeRailManifestEntry.Destination
            [void](Assert-MoeRailOrdinaryPathChain `
                -Path $MoeRailManifestEntry.Destination `
                -Boundary $MoeRailMirrorProject)
        }
        $MoeRailSourceRecords = @(
            $MoeRailManifest | ForEach-Object { "$($_.Relative)`t$($_.Hash)" } |
                Sort-Object
        )
        $MoeRailSecondSourceRecords = @(
            foreach ($MoeRailManifestEntry in $MoeRailManifest) {
                [void](Assert-MoeRailOrdinaryPathChain `
                    -Path $MoeRailManifestEntry.Source `
                    -Boundary $MoeRailEditorMirrorSourceWorktree)
                $MoeRailSecondHash = (
                    Get-FileHash -LiteralPath $MoeRailManifestEntry.Source `
                        -Algorithm SHA256
                ).Hash
                "$($MoeRailManifestEntry.Relative)`t$MoeRailSecondHash"
            }
        ) | Sort-Object
        $MoeRailMirrorRecords = @(
            Get-ChildItem -LiteralPath $MoeRailMirrorProject -File -Recurse |
                ForEach-Object {
                    if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                        throw "Mirror contains a reparse point: $($_.FullName)"
                    }
                    $MoeRailRelative = $_.FullName.Substring(
                        $MoeRailMirrorPrefix.Length
                    ).Replace('\', '/')
                    $MoeRailHash = (
                        Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
                    ).Hash
                    "$MoeRailRelative`t$MoeRailHash"
                } | Sort-Object
        )
        if (@(Compare-Object $MoeRailSourceRecords $MoeRailSecondSourceRecords).Count -ne 0 -or
            @(Compare-Object $MoeRailSourceRecords $MoeRailMirrorRecords).Count -ne 0) {
            throw 'Disposable mirror differs from its selected clean source.'
        }
        [pscustomobject]@{
            Root = $MoeRailRoot
            Project = $MoeRailMirrorProject
            AppData = $MoeRailAppData
            LocalAppData = $MoeRailLocalAppData
            Temp = $MoeRailChildTemp
            Stdout = (Join-Path $MoeRailLogs 'stdout.log')
            Stderr = (Join-Path $MoeRailLogs 'stderr.log')
            EngineLog = (Join-Path $MoeRailLogs 'godot.log')
        }
    } catch {
        "PRESERVED_DISPOSABLE_MIRROR=$MoeRailRoot"
        throw
    }
}
function Remove-MoeRailDisposableEditorMirror {
    param([pscustomobject]$Mirror)
    $MoeRailSafeRoot = Assert-MoeRailMirrorRoot -Root $Mirror.Root
    if (-not (Test-Path -LiteralPath $MoeRailSafeRoot -PathType Container)) {
        throw 'Disposable mirror root disappeared before approved cleanup.'
    }
    [void](Assert-MoeRailOrdinaryPathChain `
        -Path $MoeRailSafeRoot `
        -Boundary ([IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')))
    Assert-MoeRailOrdinaryTree -Root $MoeRailSafeRoot
    Remove-Item -LiteralPath $MoeRailSafeRoot -Recurse -Force
}
function Get-MoeRailLogText {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required editor capture is missing: $Path"
    }
    $MoeRailCaptureItem = Get-Item -LiteralPath $Path -Force
    if (($MoeRailCaptureItem.Attributes -band
        [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Editor capture is a reparse point: $Path"
    }
    Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
}
function Invoke-MoeRailDisposableEditorGate {
    param([switch]$WithGateFlag)
    $MoeRailBeforeTargetHead = (
        git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{commit}'
    ).Trim()
    $MoeRailBeforeTargetTree = (
        git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{tree}'
    ).Trim()
    $MoeRailBeforeSourceHead = (
        git -C $MoeRailEditorMirrorSourceWorktree rev-parse 'HEAD^{commit}'
    ).Trim()
    $MoeRailBeforeSourceTree = (
        git -C $MoeRailEditorMirrorSourceWorktree rev-parse 'HEAD^{tree}'
    ).Trim()
    if ($LASTEXITCODE -ne 0 -or
        ($MoeRailFeatureWorktree -eq $MoeRailPrimaryWorktree -and
            $MoeRailBeforeTargetTree -ne $MoeRailBeforeSourceTree)) {
        throw 'Gate target and mirror-source identities are invalid before mirror creation.'
    }
    $MoeRailBeforeTargetStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailBeforeTargetContent = @(Get-MoeRailContentSnapshot)
    $MoeRailBeforeSourceStatus = @(
        Get-MoeRailWorktreeStatusSnapshot `
            -Worktree $MoeRailEditorMirrorSourceWorktree
    )
    $MoeRailBeforeSourceContent = @(
        Get-MoeRailWorktreeContentSnapshot `
            -Worktree $MoeRailEditorMirrorSourceWorktree
    )
    if ($MoeRailBeforeSourceStatus.Count -ne 0) {
        $MoeRailBeforeSourceStatus
        throw 'The approved editor mirror source is not clean.'
    }
    git -C $MoeRailEditorMirrorSourceWorktree `
        diff --quiet HEAD -- $MoeRailPrototypeApp
    if ($LASTEXITCODE -ne 0) {
        throw 'Mirror-source prototype_app.gd differs from its HEAD.'
    }
    $MoeRailMirror = New-MoeRailDisposableEditorMirror
    $MoeRailAfterCopySourceStatus = @(
        Get-MoeRailWorktreeStatusSnapshot `
            -Worktree $MoeRailEditorMirrorSourceWorktree
    )
    $MoeRailAfterCopySourceContent = @(
        Get-MoeRailWorktreeContentSnapshot `
            -Worktree $MoeRailEditorMirrorSourceWorktree
    )
    $MoeRailAfterCopyTargetStatus = @(Get-MoeRailStatusSnapshot)
    $MoeRailAfterCopyTargetContent = @(Get-MoeRailContentSnapshot)
    $MoeRailAfterCopyTargetHead = (
        git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{commit}'
    ).Trim()
    $MoeRailAfterCopyTargetTree = (
        git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{tree}'
    ).Trim()
    $MoeRailAfterCopySourceHead = (
        git -C $MoeRailEditorMirrorSourceWorktree rev-parse 'HEAD^{commit}'
    ).Trim()
    $MoeRailAfterCopySourceTree = (
        git -C $MoeRailEditorMirrorSourceWorktree rev-parse 'HEAD^{tree}'
    ).Trim()
    if ($LASTEXITCODE -ne 0 -or
        $MoeRailBeforeTargetHead -ne $MoeRailAfterCopyTargetHead -or
        $MoeRailBeforeTargetTree -ne $MoeRailAfterCopyTargetTree -or
        $MoeRailBeforeSourceHead -ne $MoeRailAfterCopySourceHead -or
        $MoeRailBeforeSourceTree -ne $MoeRailAfterCopySourceTree -or
        ($MoeRailFeatureWorktree -eq $MoeRailPrimaryWorktree -and
            $MoeRailAfterCopyTargetTree -ne $MoeRailAfterCopySourceTree) -or
        @(Compare-Object $MoeRailBeforeTargetStatus $MoeRailAfterCopyTargetStatus).Count -ne 0 -or
        @(Compare-Object $MoeRailBeforeTargetContent $MoeRailAfterCopyTargetContent).Count -ne 0 -or
        @(Compare-Object $MoeRailBeforeSourceStatus $MoeRailAfterCopySourceStatus).Count -ne 0 -or
        @(Compare-Object $MoeRailBeforeSourceContent $MoeRailAfterCopySourceContent).Count -ne 0) {
        "PRESERVED_DISPOSABLE_MIRROR=$($MoeRailMirror.Root)"
        throw 'Mirror creation changed its gate target or clean source.'
    }
    $MoeRailProcess = $null
    $MoeRailSuccess = $false
    try {
        $MoeRailArguments = @(
            '--headless', '--path', $MoeRailMirror.Project, '--editor', '--import',
            '--quit-after', '240', '--max-fps', '60',
            '--log-file', $MoeRailMirror.EngineLog
        )
        if ($WithGateFlag) {
            $MoeRailArguments += @('--', '--moerail-logical-field-editor-gate')
        }
        $MoeRailEnvironment = @{
            APPDATA = $MoeRailMirror.AppData
            LOCALAPPDATA = $MoeRailMirror.LocalAppData
            TEMP = $MoeRailMirror.Temp
            TMP = $MoeRailMirror.Temp
        }
        $MoeRailStartInfo = [Diagnostics.ProcessStartInfo]::new()
        $MoeRailStartInfo.FileName = $MoeRailGodotExe
        $MoeRailStartInfo.UseShellExecute = $false
        $MoeRailStartInfo.CreateNoWindow = $true
        $MoeRailStartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
        $MoeRailStartInfo.RedirectStandardOutput = $true
        $MoeRailStartInfo.RedirectStandardError = $true
        foreach ($MoeRailArgument in $MoeRailArguments) {
            [void]$MoeRailStartInfo.ArgumentList.Add([string]$MoeRailArgument)
        }
        foreach ($MoeRailEnvironmentName in $MoeRailEnvironment.Keys) {
            $MoeRailStartInfo.Environment[$MoeRailEnvironmentName] =
                $MoeRailEnvironment[$MoeRailEnvironmentName]
        }
        $MoeRailProcess = [Diagnostics.Process]::new()
        $MoeRailProcess.StartInfo = $MoeRailStartInfo
        if (-not $MoeRailProcess.Start()) {
            throw 'Failed to start the exact disposable editor child.'
        }
        $MoeRailStdoutTask = $MoeRailProcess.StandardOutput.ReadToEndAsync()
        $MoeRailStderrTask = $MoeRailProcess.StandardError.ReadToEndAsync()
        $MoeRailTimedOut = -not $MoeRailProcess.WaitForExit(30000)
        $MoeRailTerminationFailure = ''
        if ($MoeRailTimedOut) {
            $MoeRailTerminationFailure = Stop-MoeRailOwnedChild -Process $MoeRailProcess
        }
        if ($MoeRailTimedOut -and
            -not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure)) {
            throw "Timed-out editor child was not reaped; asynchronous capture remains bounded by preserving the mirror: $MoeRailTerminationFailure"
        }
        $MoeRailCaptureTasks = [Threading.Tasks.Task[]]@(
            $MoeRailStdoutTask, $MoeRailStderrTask
        )
        try {
            $MoeRailCaptureCompleted = [Threading.Tasks.Task]::WaitAll(
                $MoeRailCaptureTasks,
                5000
            )
        } catch {
            throw "Editor output capture failed: $($_.Exception.Message)"
        }
        if (-not $MoeRailCaptureCompleted) {
            try { $MoeRailProcess.StandardOutput.Dispose() } catch {}
            try { $MoeRailProcess.StandardError.Dispose() } catch {}
            throw 'Editor output capture exceeded its 5-second completion deadline.'
        }
        $MoeRailCapturedStdout = $MoeRailStdoutTask.GetAwaiter().GetResult()
        $MoeRailCapturedStderr = $MoeRailStderrTask.GetAwaiter().GetResult()
        [IO.File]::WriteAllText(
            $MoeRailMirror.Stdout,
            $MoeRailCapturedStdout,
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            $MoeRailMirror.Stderr,
            $MoeRailCapturedStderr,
            [Text.UTF8Encoding]::new($false)
        )
        $MoeRailStdout = Get-MoeRailLogText -Path $MoeRailMirror.Stdout
        $MoeRailStderr = Get-MoeRailLogText -Path $MoeRailMirror.Stderr
        $MoeRailEngineLog = Get-MoeRailLogText -Path $MoeRailMirror.EngineLog
        $MoeRailProcessText = @($MoeRailStdout, $MoeRailStderr) -join "`n"
        $MoeRailDiagnosticText = @(
            $MoeRailStdout, $MoeRailStderr, $MoeRailEngineLog
        ) -join "`n"
        $MoeRailProcessText
        $MoeRailPassCount = [regex]::Matches(
            $MoeRailProcessText,
            '(?m)^PASS: logical track field editor integration\r?$'
        ).Count
        $MoeRailFailCount = [regex]::Matches(
            $MoeRailProcessText,
            '(?m)^FAIL: logical track field editor integration\r?$'
        ).Count
        $MoeRailExpectedPassCount = if ($WithGateFlag) { 1 } else { 0 }
        $MoeRailAfterTargetStatus = @(Get-MoeRailStatusSnapshot)
        $MoeRailAfterTargetContent = @(Get-MoeRailContentSnapshot)
        $MoeRailAfterSourceStatus = @(
            Get-MoeRailWorktreeStatusSnapshot `
                -Worktree $MoeRailEditorMirrorSourceWorktree
        )
        $MoeRailAfterSourceContent = @(
            Get-MoeRailWorktreeContentSnapshot `
                -Worktree $MoeRailEditorMirrorSourceWorktree
        )
        $MoeRailAfterTargetHead = (
            git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{commit}'
        ).Trim()
        $MoeRailAfterTargetTree = (
            git -C $MoeRailFeatureWorktree rev-parse 'HEAD^{tree}'
        ).Trim()
        $MoeRailAfterSourceHead = (
            git -C $MoeRailEditorMirrorSourceWorktree rev-parse 'HEAD^{commit}'
        ).Trim()
        $MoeRailAfterSourceTree = (
            git -C $MoeRailEditorMirrorSourceWorktree rev-parse 'HEAD^{tree}'
        ).Trim()
        $MoeRailIdentityExit = $LASTEXITCODE
        git -C $MoeRailEditorMirrorSourceWorktree `
            diff --quiet HEAD -- $MoeRailPrototypeApp
        $MoeRailPrototypeExit = $LASTEXITCODE
        if ($MoeRailTimedOut -or
            -not [string]::IsNullOrWhiteSpace($MoeRailTerminationFailure) -or
            $MoeRailIdentityExit -ne 0 -or
            $MoeRailBeforeTargetHead -ne $MoeRailAfterTargetHead -or
            $MoeRailBeforeTargetTree -ne $MoeRailAfterTargetTree -or
            $MoeRailBeforeSourceHead -ne $MoeRailAfterSourceHead -or
            $MoeRailBeforeSourceTree -ne $MoeRailAfterSourceTree -or
            ($MoeRailFeatureWorktree -eq $MoeRailPrimaryWorktree -and
                $MoeRailAfterTargetTree -ne $MoeRailAfterSourceTree) -or
            $MoeRailProcess.ExitCode -ne 0 -or
            $MoeRailPassCount -ne $MoeRailExpectedPassCount -or
            $MoeRailFailCount -ne 0 -or
            $MoeRailDiagnosticText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)' -or
            $MoeRailDiagnosticText -match '(?i)(CrashHandlerException|Program crashed|signal \d+|Scan thread aborted|(?:\bRID allocations\b[^\r\n]*leaked at exit|\bRIDs?\b[^\r\n]*(?:was|were) leaked)|ObjectDB instances[^\r\n]*(?:leaked at exit|still alive))' -or
            $MoeRailPrototypeExit -ne 0 -or
            @(Compare-Object $MoeRailBeforeTargetStatus $MoeRailAfterTargetStatus).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeTargetContent $MoeRailAfterTargetContent).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeSourceStatus $MoeRailAfterSourceStatus).Count -ne 0 -or
            @(Compare-Object $MoeRailBeforeSourceContent $MoeRailAfterSourceContent).Count -ne 0) {
            throw 'Disposable editor gate failed its strict process or state contract.'
        }
        $MoeRailSuccess = $true
    } finally {
        if ($MoeRailProcess -ne $null) { $MoeRailProcess.Dispose() }
        if ($MoeRailSuccess) {
            try {
                Remove-MoeRailDisposableEditorMirror -Mirror $MoeRailMirror
            } catch {
                "PRESERVED_DISPOSABLE_MIRROR=$($MoeRailMirror.Root)"
                throw "Disposable mirror cleanup failed; preserve any remaining evidence: $($_.Exception.Message)"
            }
        } else {
            "PRESERVED_DISPOSABLE_MIRROR=$($MoeRailMirror.Root)"
        }
    }
}

$MoeRailGateBeforeStatus = @(Get-MoeRailStatusSnapshot)
$MoeRailGateBeforeContent = @(Get-MoeRailContentSnapshot)
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
Invoke-MoeRailDisposableEditorGate -WithGateFlag
Invoke-MoeRailDisposableEditorGate
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

$MoeRailPostGateStatus = @(Get-MoeRailStatusSnapshot)
$MoeRailPostGateContent = @(Get-MoeRailContentSnapshot)
$MoeRailExpectedGateStatus = @(if (
    $MoeRailFeatureWorktree -eq [IO.Path]::GetFullPath('D:\godot\MoeRailWay')
) {
    @(
        ' M godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
        ' M godot-project-moe-rail-way/tests/support/prototype_test.gd',
        '?? docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
    ) | Sort-Object
} else {
    @()
})
if (@(Compare-Object $MoeRailExpectedGateStatus $MoeRailPostGateStatus).Count -ne 0 -or
    @(Compare-Object $MoeRailGateBeforeStatus $MoeRailPostGateStatus).Count -ne 0 -or
    @(Compare-Object $MoeRailGateBeforeContent $MoeRailPostGateContent).Count -ne 0) {
    $MoeRailPostGateStatus
    throw 'The automated gate changed tracked or untracked feature files.'
}
if ($MoeRailHadGateOverride) {
    Remove-Item Env:MOERAIL_GATE_WORKTREE
}
~~~

The expected evidence is one unit marker, two accepted-shell markers, one runtime logical-field marker, one editor-owned logical-field marker followed by engine-owned natural exit before 30 seconds, one clean no-flag editor smoke with zero gate markers, one input marker, three app markers, one main-ready marker, and one intentional invalid-start exit `2`. The flagged and no-flag processes each use a separate exact ordinary-file mirror, isolated `APPDATA`, `LOCALAPPDATA`, `TEMP`, and `TMP`, `--import --quit-after 240`, and mirror-local logs. Any missing or duplicate marker, nonzero positive-run exit, or unexpected `FAIL:`, `SCRIPT ERROR:`, `ERROR:`, `FATAL:`, `WARNING:`, or `CRASH:` line fails the positive runners. Crash-handler, signal-crash, `Scan thread aborted`, RID-allocation leak, or ObjectDB-leak diagnostics also fail both editor commands regardless of prefix.

- [ ] **Step 2: Perform the Windows editor/runtime smoke and write the completed English record**

Use the exact Godot executable above. Runtime-only checks may use the clean committed feature project. Every visible editor-only check must use one new ordinary-file disposable copy of that clean committed feature project, selected by the same tracked plus untracked-nonignored, no-reparse-point, no-copy-back contract as Step 1. Give the visible editor mirror-local `APPDATA`, `LOCALAPPDATA`, `TEMP`, and `TMP`, record the exact source commit and mirror provenance, close that visible editor normally, verify the feature status and content are unchanged, then remove only the revalidated exact temporary root after evidence is complete. Never terminate a user-owned Godot or Steam process. If an editor lock or user-owned process prevents isolated testing, stop and ask the user. Create `tests/manual/track_train_windows.md` only after running the checks, and record the date, Windows version, exact Godot build, Task 8 commit SHA, tester, each tested window size, an exact PASS status per item, and every host-only warning. If any item fails, keep Task 9 incomplete, preserve the exact failed mirror, correct the defect, and rerun affected checks before creating the final evidence record.

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

Before staging the manual record, set `MOERAIL_APPROVED_THIRD_AMENDMENT` to the exact reviewed third-amendment SHA reported when this design, plan, and briefing were committed, then run:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailPlanCommit = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailFirstEditorGateDesignCommit = '36730aa6bc6f05d7e01b96e79aff37ac73d0d11a'
$MoeRailFirstPlanAmendment = '9047301da36c18b94e6e5be24d8dfd7423966828'
$MoeRailSecondAmendment = 'aaca77325acb3ecd722894f133c5319152554eb6'
$MoeRailApprovedThirdAmendment = $env:MOERAIL_APPROVED_THIRD_AMENDMENT
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailFirstDesignPath = 'docs/superpowers/specs/2026-08-17-prototype-track-train-editor-gate-amendment-design.md'
$MoeRailSecondDesignPath = 'docs/superpowers/specs/2026-08-21-prototype-track-train-editor-shutdown-amendment-design.md'
$MoeRailThirdDesignPath = 'docs/superpowers/specs/2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md'
if ($MoeRailApprovedThirdAmendment -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_APPROVED_THIRD_AMENDMENT to the reviewed third amendment commit.'
}
$MoeRailPlanParent = (git -C $MoeRailFeatureWorktree rev-parse "$MoeRailPlanCommit^").Trim()
$MoeRailPlanFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailPlanCommit | Sort-Object
)
$MoeRailDesignParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailFirstEditorGateDesignCommit^"
).Trim()
$MoeRailDesignFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailFirstEditorGateDesignCommit | Sort-Object
)
$MoeRailFirstAmendmentParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailFirstPlanAmendment^"
).Trim()
$MoeRailFirstAmendmentFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailFirstPlanAmendment | Sort-Object
)
$MoeRailSecondAmendmentParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailSecondAmendment^"
).Trim()
$MoeRailSecondAmendmentFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailSecondAmendment | Sort-Object
)
$MoeRailThirdAmendmentParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailApprovedThirdAmendment^"
).Trim()
$MoeRailThirdAmendmentParentTokens = @(
    (git -C $MoeRailFeatureWorktree rev-list --parents -n 1 `
        $MoeRailApprovedThirdAmendment).Trim() -split '\s+'
)
$MoeRailThirdAmendmentFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailApprovedThirdAmendment | Sort-Object
)
$MoeRailPrototypeHead = (git -C $MoeRailFeatureWorktree rev-parse 'Prototyping^{commit}').Trim()
$MoeRailFeatureBase = (
    git -C $MoeRailFeatureWorktree merge-base $MoeRailPlanCommit HEAD
).Trim()
git -C $MoeRailFeatureWorktree merge-base --is-ancestor `
    $MoeRailApprovedThirdAmendment HEAD
$MoeRailThirdAmendmentAncestorExit = $LASTEXITCODE
if ($MoeRailPlanParent -ne $MoeRailCodeBase -or
    @(Compare-Object @($MoeRailPlanPath, $MoeRailBriefPath) $MoeRailPlanFiles).Count -ne 0 -or
    $MoeRailDesignParent -ne $MoeRailPlanCommit -or
    @(Compare-Object @($MoeRailFirstDesignPath) $MoeRailDesignFiles).Count -ne 0 -or
    $MoeRailFirstAmendmentParent -ne $MoeRailFirstEditorGateDesignCommit -or
    @(Compare-Object @($MoeRailPlanPath, $MoeRailBriefPath) $MoeRailFirstAmendmentFiles).Count -ne 0 -or
    $MoeRailSecondAmendmentParent -ne $MoeRailFirstPlanAmendment -or
    @(Compare-Object @($MoeRailSecondDesignPath, $MoeRailPlanPath, $MoeRailBriefPath) $MoeRailSecondAmendmentFiles).Count -ne 0 -or
    $MoeRailThirdAmendmentParentTokens.Count -ne 2 -or
    $MoeRailThirdAmendmentParent -ne $MoeRailSecondAmendment -or
    @(Compare-Object @($MoeRailThirdDesignPath, $MoeRailPlanPath, $MoeRailBriefPath) $MoeRailThirdAmendmentFiles).Count -ne 0 -or
    $MoeRailPrototypeHead -ne $MoeRailPlanCommit -or
    $MoeRailFeatureBase -ne $MoeRailPlanCommit -or
    $MoeRailThirdAmendmentAncestorExit -ne 0) {
    throw 'Starting plan, reviewed amendment ancestry, or Prototyping base changed before the feature gate.'
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
$MoeRailExpectedAddonPaths = @(
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/plugin.cfg',
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd',
    'godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd.uid'
) | Sort-Object
$MoeRailTrackedAddonPaths = @(
    $MoeRailTracked | Where-Object {
        $_ -match '^godot-project-moe-rail-way/addons/'
    } | Sort-Object
)
if (@(Compare-Object $MoeRailExpectedAddonPaths $MoeRailTrackedAddonPaths).Count -ne 0) {
    $MoeRailTrackedAddonPaths
    throw 'Tracked add-ons differ from the one approved first-party editor gate.'
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

1. specification compliance against this plan, `docs/superpowers/specs/2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md`, `docs/superpowers/specs/2026-08-21-prototype-track-train-editor-shutdown-amendment-design.md`, `docs/superpowers/specs/2026-08-17-prototype-track-train-editor-gate-amendment-design.md`, `docs/superpowers/specs/2026-08-16-prototype-track-train-design.md`, `docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md`, and `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`;
2. code and test quality, with special attention to arc-distance conservation, field/intersection clipping, fixed-tick ordering, signal reentrancy, scene/Resource validation, GUI event buffering, copied snapshot data, protected paths, and scope creep.

If any gate or review finds a defect, make the smallest focused correction commit, rerun every affected RED/GREEN contract plus the entire Step 1 gate, repeat Windows checks affected by the change, add a new English evidence update that names the new HEAD, and repeat both reviews. Do not claim an exact nine-task-commit history after correction commits; the later squash candidate intentionally collapses all reviewed feature commits.

Stop after reporting the clean reviewed `FEATURE_SHA`. Do not construct a squash candidate, fast-forward `Prototyping`, create `prototype-m3`, or push until the relevant approval described below is received.

---

## Post-Implementation Approval Gates

These commands belong to the later development session. They are not authorized by approval of this planning document.

### Gate A: Build a Reviewed Squash Candidate

After the user accepts the complete feature evidence, set `MOERAIL_ACCEPTED_FEATURE` to the exact reviewed `FEATURE_SHA` and keep `MOERAIL_APPROVED_THIRD_AMENDMENT` set to the exact reviewed third-amendment SHA. Candidate construction does not move `Prototyping`:

~~~powershell
$ErrorActionPreference = 'Stop'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-02-track-train'
$MoeRailCandidateWorktree = 'D:\godot\MoeRailWay-worktrees\prototype-m3-candidate'
$MoeRailFeatureBranch = 'proto/02-track-train'
$MoeRailCandidateBranch = 'codex/prototype-m3-candidate'
$MoeRailCodeBase = '4e9fc7e39d3c07c51cf5b823fc0963fee01f0f97'
$MoeRailPlanCommit = '4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1'
$MoeRailFirstEditorGateDesignCommit = '36730aa6bc6f05d7e01b96e79aff37ac73d0d11a'
$MoeRailFirstPlanAmendment = '9047301da36c18b94e6e5be24d8dfd7423966828'
$MoeRailSecondAmendment = 'aaca77325acb3ecd722894f133c5319152554eb6'
$MoeRailApprovedThirdAmendment = $env:MOERAIL_APPROVED_THIRD_AMENDMENT
$MoeRailAcceptedFeature = $env:MOERAIL_ACCEPTED_FEATURE
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-16-prototype-track-train.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md'
$MoeRailFirstDesignPath = 'docs/superpowers/specs/2026-08-17-prototype-track-train-editor-gate-amendment-design.md'
$MoeRailSecondDesignPath = 'docs/superpowers/specs/2026-08-21-prototype-track-train-editor-shutdown-amendment-design.md'
$MoeRailThirdDesignPath = 'docs/superpowers/specs/2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md'
if ($MoeRailAcceptedFeature -notmatch '^[0-9a-f]{40}$' -or
    $MoeRailApprovedThirdAmendment -notmatch '^[0-9a-f]{40}$') {
    throw 'Set the accepted feature and reviewed third-amendment SHAs before Gate A.'
}
$MoeRailPlanParent = (git -C $MoeRailFeatureWorktree rev-parse "$MoeRailPlanCommit^").Trim()
$MoeRailPlanFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r $MoeRailPlanCommit |
        Sort-Object
)
$MoeRailExpectedPlanFiles = @($MoeRailPlanPath, $MoeRailBriefPath) | Sort-Object
$MoeRailDesignParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailFirstEditorGateDesignCommit^"
).Trim()
$MoeRailDesignFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailFirstEditorGateDesignCommit | Sort-Object
)
$MoeRailFirstAmendmentParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailFirstPlanAmendment^"
).Trim()
$MoeRailFirstAmendmentFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailFirstPlanAmendment | Sort-Object
)
$MoeRailSecondAmendmentParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailSecondAmendment^"
).Trim()
$MoeRailSecondAmendmentFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailSecondAmendment | Sort-Object
)
$MoeRailThirdAmendmentParent = (
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailApprovedThirdAmendment^"
).Trim()
$MoeRailThirdAmendmentParentTokens = @(
    (git -C $MoeRailFeatureWorktree rev-list --parents -n 1 `
        $MoeRailApprovedThirdAmendment).Trim() -split '\s+'
)
$MoeRailThirdAmendmentFiles = @(
    git -C $MoeRailFeatureWorktree diff-tree --no-commit-id --name-only -r `
        $MoeRailApprovedThirdAmendment | Sort-Object
)
git -C $MoeRailFeatureWorktree merge-base --is-ancestor `
    $MoeRailApprovedThirdAmendment $MoeRailAcceptedFeature
$MoeRailThirdAmendmentAncestorExit = $LASTEXITCODE
if ($MoeRailPlanParent -ne $MoeRailCodeBase -or
    @(Compare-Object $MoeRailExpectedPlanFiles $MoeRailPlanFiles).Count -ne 0 -or
    $MoeRailDesignParent -ne $MoeRailPlanCommit -or
    @(Compare-Object @($MoeRailFirstDesignPath) $MoeRailDesignFiles).Count -ne 0 -or
    $MoeRailFirstAmendmentParent -ne $MoeRailFirstEditorGateDesignCommit -or
    @(Compare-Object $MoeRailExpectedPlanFiles $MoeRailFirstAmendmentFiles).Count -ne 0 -or
    $MoeRailSecondAmendmentParent -ne $MoeRailFirstPlanAmendment -or
    @(Compare-Object @($MoeRailSecondDesignPath, $MoeRailPlanPath, $MoeRailBriefPath) $MoeRailSecondAmendmentFiles).Count -ne 0 -or
    $MoeRailThirdAmendmentParentTokens.Count -ne 2 -or
    $MoeRailThirdAmendmentParent -ne $MoeRailSecondAmendment -or
    @(Compare-Object @($MoeRailThirdDesignPath, $MoeRailPlanPath, $MoeRailBriefPath) $MoeRailThirdAmendmentFiles).Count -ne 0 -or
    $MoeRailThirdAmendmentAncestorExit -ne 0) {
    throw 'Accepted feature, starting plan, or reviewed amendment identity is invalid.'
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

- `proto/02-track-train` has immutable merge base `4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1` on `Prototyping`, contains all three reviewed editor-gate amendments in its feature history, and never uses `main` or `Development`.
- The fixed default gate reports exactly `PASS: 14 prototype test suite(s)` plus every anchored integration and boot marker, including the editor-owned logical-field marker and the zero-marker no-flag editor smoke.
- The approved preparation, route reservation, construction, train, recovery, warning, cancellation, termination, logical-field, candidate, Inspector, and Windows-resize contracts are automated or manually evidenced as assigned above.
- Only right-click reserved-unbuilt cancellation is implemented; built-track paid demolition and crossings remain deferred to `proto/04-risk-investment`.
- No production abstraction pass occurs. The prototype remains concrete and leaves abstraction-scope decisions to later `Development` specifications.
- Every balance-sensitive value is Inspector-owned by its feature Resource or spatial node, while the active session reads only copied values.
- The only tracked add-on is the inert-by-default first-party editor gate under `addons/moerail_test_editor_gate`; no third-party or production plugin framework is introduced.
- User-owned primary changes retain their exact status and SHA-256 fingerprints.
- Agent-facing Markdown is English; the paired user briefing is Korean and names this plan as canonical.
- Merge, annotated tag, and push remain separately approved and separately verified.
