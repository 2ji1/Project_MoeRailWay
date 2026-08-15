# Prototype Session Shell Implementation Plan

> **Execution boundary:** This plan is authored in a strategy session. Do not create `proto/01-session-shell`, modify Godot source, or integrate `Prototyping` while reviewing it. Execute it only in a separate development session after the user explicitly starts implementation.

**Goal:** Deliver `prototype-m2` as a responsive Windows 2D session shell that starts an empty session automatically, advances a deterministic fixed-tick countdown, and transitions exactly once to a non-settling result view.

**Architecture:** `PrototypeApp` remains the concrete composition root. A pure `SessionController` consumes the existing `SessionStartConfig`, advances only through explicit integer ticks, publishes read-only snapshots, and emits one regular-time-expiry result. A concrete `SessionShell` presents the map-dominant top-down field, thin HUD bands, and result overlay. A validated `UILayoutProfile` controls Inspector-editable spacing without entering domain state. No interface hierarchy or speculative production abstraction is introduced.

**Tech Stack:** Godot 4.7.1, GDScript, Godot Resource and scene files, the existing native headless test runner, PowerShell, Git

## Approved Player Flow

1. Launch the configured main scene.
2. Validate balance and layout configuration.
3. Compose `SessionStartConfig`, `SessionRng`, and `SessionController`.
4. Start the empty session automatically. There is no ready screen or start button.
5. Show the live countdown in the top HUD while the empty field remains visible.
6. When the regular timer reaches zero, complete once and show the result overlay in the same main scene.
7. Remain on the result overlay. There is no restart button, next-cycle action, contract settlement, or debug end control in this milestone.

The default tracked balance remains 180 seconds at 60 simulation ticks per second. Automated lifecycle verification uses a separate two-second test fixture and never shortens the main prototype session.

## Global Constraints

- Base feature work on the accepted `Prototyping` commit `b28f000`, tagged `prototype-m1`.
- Create `proto/01-session-shell` from `Prototyping`, never from `main` or `Development`.
- Keep `Development` isolated and never merge `Prototyping` into it.
- Execute implementation in a new isolated worktree outside the primary repository directory.
- Preserve the primary `Prototyping` worktree's user-owned indentation-only edits in `tests/smoke/test_project_boot.gd` and `tests/support/prototype_test.gd`. Do not stage, format, revert, copy, or reset them.
- Do not modify `tests/support/prototype_test.gd` in this milestone; its existing assertions are sufficient, and task-specific helpers stay inside their owning test script.
- Preserve the unrelated untracked `docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md` and the existing worktrees.
- Target Windows PC, mouse-only input, a 1280x720 logical viewport, and supported 16:9 window sizes from 960x540 through 1920x1080.
- Keep the existing `canvas_items` plus `expand` stretch settings, Forward Plus renderer, and D3D12 Windows driver.
- Use the verified Godot executable at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe` and require the exact version `4.7.1.stable.official.a13da4feb`.
- Add no third-party add-ons, test plug-ins, custom art, custom fonts, final audio, mobile behavior, touch behavior, or gamepad behavior.
- Keep implementation concrete. The system boundaries in the specification define ownership, not mandatory interfaces or abstract base classes.
- Preserve the existing balance factory and the rule that `SessionRng` uses the factory-produced `SessionStartConfig.seed`.
- The session duration and tick rate come from `SessionStartConfig`; presentation must not reread them from the balance Resource.
- The layout profile is presentation configuration and must never enter session RNG or domain results.
- Do not implement train movement, track drawing, warps, cargo, hazards, contracts, cash changes, settlement, loans, operations flow, or bankruptcy.
- Do not add a temporary start screen, restart button, next button, debug finish button, or keyboard shortcut.
- Do not use wall-clock APIs, `_process(delta)`, or `Timer` as domain truth. Tests advance the controller through explicit ticks.
- Do not use a global event bus. Wire concrete dependencies and signals in `PrototypeApp`.
- Agent-facing Markdown remains English. User-facing briefing documents remain Korean.
- Every new tracked GDScript must have exactly one matching `.gd.uid` sidecar before final review.
- Tests may verify public contracts, output, geometry, and state. They must not freeze arbitrary internal scene-node names.
- `.tscn`, `.tres`, `.gd.uid`, and Theme serialization are configuration-file TDD exceptions. Cover them with scene integration, Resource validation, UID parity, boot, and diff gates.

## Development Session Preflight (Controller Only)

Run this only in the new development session. The current strategy session must not execute it.

The plan is committed on `main`, while the feature must start from `Prototyping`. Resolve and verify the documentation-only planning commit first, then create the feature worktree and cherry-pick that commit so execution tools can read this plan inside the feature branch. Every fenced command block is independent: redeclare absolute paths in each block, use `git -C`, and never rely on a previous shell's current directory or variables.

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailPlanPath = 'docs/superpowers/plans/2026-08-15-prototype-session-shell.md'
$MoeRailBriefPath = 'docs/briefings/ko/2026-08-15-prototype-session-shell-plan-briefing.md'
$MoeRailExpectedBase = 'b28f0001b14efe78ff2de2a0e71d95102750ec1d'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'

if (Test-Path -LiteralPath $MoeRailFeatureWorktree) {
    throw "Feature worktree path already exists: $MoeRailFeatureWorktree"
}

git -C $MoeRailPrimary show-ref --verify --quiet refs/heads/proto/01-session-shell
if ($LASTEXITCODE -eq 0) {
    throw 'proto/01-session-shell already exists; inspect it before continuing.'
} elseif ($LASTEXITCODE -ne 1) {
    throw 'Failed to inspect the feature branch state.'
}

$MoeRailPrototypeHeadOutput = @(git -C $MoeRailPrimary rev-parse --verify 'Prototyping^{commit}')
$MoeRailPrototypeHeadExit = $LASTEXITCODE
if ($MoeRailPrototypeHeadExit -ne 0) {
    throw 'Failed to resolve Prototyping.'
}
$MoeRailPrototypeHead = ($MoeRailPrototypeHeadOutput -join "`n").Trim()

$MoeRailMilestoneOneOutput = @(git -C $MoeRailPrimary rev-parse --verify 'prototype-m1^{commit}')
$MoeRailMilestoneOneExit = $LASTEXITCODE
if ($MoeRailMilestoneOneExit -ne 0) {
    throw 'Failed to resolve prototype-m1.'
}
$MoeRailMilestoneOne = ($MoeRailMilestoneOneOutput -join "`n").Trim()
if ($MoeRailPrototypeHead -ne $MoeRailMilestoneOne) {
    throw 'Prototyping no longer matches the accepted prototype-m1 baseline; inspect new commits before executing this plan.'
}
if ($MoeRailPrototypeHead -ne $MoeRailExpectedBase) {
    throw "Unexpected prototype-m1 commit: $MoeRailPrototypeHead"
}

$MoeRailPlanCommitOutput = @(git -C $MoeRailPrimary log main -1 --format=%H -- $MoeRailPlanPath $MoeRailBriefPath)
$MoeRailPlanCommitExit = $LASTEXITCODE
if ($MoeRailPlanCommitExit -ne 0) {
    throw 'Failed to inspect main for the session-shell planning commit.'
}
$MoeRailPlanCommit = ($MoeRailPlanCommitOutput -join "`n").Trim()
if (-not $MoeRailPlanCommit) {
    throw 'Could not resolve the committed session-shell planning documents on main.'
}
$MoeRailExpectedPlanFiles = @($MoeRailPlanPath, $MoeRailBriefPath)
$MoeRailCommittedPlanFiles = @(
    git -C $MoeRailPrimary diff-tree --root --no-commit-id --name-only -r $MoeRailPlanCommit |
        Where-Object { $_ }
)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the planning commit file set.'
}
$MoeRailUnexpectedPlanFiles = @($MoeRailCommittedPlanFiles | Where-Object { $_ -notin $MoeRailExpectedPlanFiles })
$MoeRailMissingPlanFiles = @($MoeRailExpectedPlanFiles | Where-Object { $_ -notin $MoeRailCommittedPlanFiles })
if ($MoeRailUnexpectedPlanFiles -or $MoeRailMissingPlanFiles) {
    $MoeRailUnexpectedPlanFiles
    $MoeRailMissingPlanFiles
    throw 'The resolved planning commit is not limited to the approved English plan and Korean briefing.'
}

git -C $MoeRailPrimary worktree add -b proto/01-session-shell $MoeRailFeatureWorktree Prototyping
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to create the isolated proto/01-session-shell worktree.'
}

git -C $MoeRailFeatureWorktree cherry-pick $MoeRailPlanCommit
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to bring the approved plan into the feature branch.'
}

$MoeRailFeatureRootOutput = @(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
$MoeRailFeatureRootExit = $LASTEXITCODE
$MoeRailFeatureRoot = ($MoeRailFeatureRootOutput -join "`n").Trim()
if ($MoeRailFeatureRootExit -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailFeatureRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree)) {
    throw "Unexpected feature root: $MoeRailFeatureRoot"
}
$MoeRailFeatureBranchOutput = @(git -C $MoeRailFeatureWorktree branch --show-current)
$MoeRailFeatureBranchExit = $LASTEXITCODE
$MoeRailFeatureBranch = ($MoeRailFeatureBranchOutput -join "`n").Trim()
if ($MoeRailFeatureBranchExit -ne 0 -or $MoeRailFeatureBranch -ne 'proto/01-session-shell') {
    throw "Unexpected feature branch: $MoeRailFeatureBranch"
}
$MoeRailFeatureCommitCountOutput = @(git -C $MoeRailFeatureWorktree rev-list --count "$MoeRailExpectedBase..HEAD")
$MoeRailFeatureCommitCountExit = $LASTEXITCODE
$MoeRailFeatureCommitCount = ($MoeRailFeatureCommitCountOutput -join "`n").Trim()
if ($MoeRailFeatureCommitCountExit -ne 0 -or $MoeRailFeatureCommitCount -ne '1') {
    throw "Expected only the planning commit after prototype-m1, found: $MoeRailFeatureCommitCount"
}
$MoeRailFeatureStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailFeatureStatus.Count -ne 0) {
    $MoeRailFeatureStatus
    throw 'The new feature worktree is not clean.'
}

$MoeRailVersionOutput = @(& $MoeRailGodotExe --version 2>&1)
$MoeRailVersionExit = $LASTEXITCODE
$MoeRailVersion = ($MoeRailVersionOutput -join "`n").Trim()
if ($MoeRailVersionExit -ne 0 -or $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected Godot version: $MoeRailVersion"
}
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailBaselineOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProjectPath --script 'res://tests/run_all.gd' 2>&1)
$MoeRailBaselineExit = $LASTEXITCODE
$MoeRailBaselineText = $MoeRailBaselineOutput -join "`n"
$MoeRailBaselinePasses = [regex]::Matches(
    $MoeRailBaselineText,
    '(?m)^PASS: 4 prototype test suite\(s\)\r?$'
).Count
$MoeRailBaselineOutput
if ($MoeRailBaselineExit -ne 0 -or $MoeRailBaselinePasses -ne 1 -or
    $MoeRailBaselineText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The prototype-m1 baseline did not pass exactly 4 suites.'
}
$MoeRailBaselineBootOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath --quit-after 2 2>&1
)
$MoeRailBaselineBootExit = $LASTEXITCODE
$MoeRailBaselineBootText = $MoeRailBaselineBootOutput -join "`n"
$MoeRailBaselineBootPasses = [regex]::Matches(
    $MoeRailBaselineBootText,
    '(?m)^Moe Rail Way prototype foundation ready \| seed=1 ticks=60\r?$'
).Count
$MoeRailBaselineBootOutput
if ($MoeRailBaselineBootExit -ne 0 -or $MoeRailBaselineBootPasses -ne 1 -or
    $MoeRailBaselineBootText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The prototype-m1 configured main scene did not boot exactly once.'
}
$MoeRailPostBaselineStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all
)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostBaselineStatus.Count -ne 0) {
    $MoeRailPostBaselineStatus
    throw 'Baseline verification changed the feature worktree.'
}
~~~

Expected:

- The primary dirty files and unrelated worktrees remain untouched.
- The new worktree is on `proto/01-session-shell` and based on `b28f000`.
- The only commit after the feature base is the documentation-only planning commit.
- The feature worktree is clean.

Initialize the approved subagent-driven development ledger in this feature worktree. Dispatch implementation tasks serially, with a fresh implementer and independent review for each task. If that workflow is unavailable, preserve the same task order, RED/GREEN evidence, per-task commits, and review gates manually.

## Numerical and Behavioral Contracts

### Session clock

- `total_ticks = max(1, ceil(session_duration_seconds * simulation_ticks_per_second))`.
- The controller starts in `READY`, changes to `RUNNING` exactly once, and reaches `COMPLETED` exactly once.
- One call to `advance_tick()` consumes at most one simulation tick.
- Calls before `start()` or after completion do not consume time or emit completion.
- The regular completion tick first publishes a zero-remaining snapshot and then emits one result.
- `display_seconds = ceil(remaining_ticks / simulation_ticks_per_second)` for positive remaining ticks, otherwise `0`.
- The HUD formats display seconds as `M:SS`; it begins at `3:00` for the default Resource and reaches `0:00` only on completion.
- `PrototypeApp` sets `Engine.physics_ticks_per_second` from `SessionStartConfig` before enabling physics processing, then advances one domain tick per `_physics_process` callback.
- The controller never reads `delta`, system time, frame count, balance Resources, or scene nodes.

### Session result

- This milestone defines only `REGULAR_TIME_EXPIRED`.
- A result records the reason, total ticks, elapsed ticks, and remaining ticks.
- Result creation does not perform or imply settlement.
- Repeated completion requests or additional ticks cannot create another result or another result-view transition.

### Layout profile

Use these defaults and inclusive bounds:

| Field | Default | Minimum | Maximum |
|---|---:|---:|---:|
| `outer_padding_x` | 16 | 0 | 48 |
| `outer_padding_y` | 12 | 0 | 32 |
| `panel_padding` | 10 | 4 | 20 |
| `item_gap` | 12 | 4 | 24 |
| `row_gap` | 6 | 2 | 16 |
| `hud_height` | 56 | 44 | 80 |
| `icon_size` | 20 | 12 | 32 |

- The minimum supported viewport is 960x540 and the maximum automated resize case is 1920x1080; both remain 16:9.
- The field must remain at least 640x300.
- `hud_height` must be at least `icon_size + 2 * panel_padding`.
- The root layout has zero separation between the top HUD, field, and bottom HUD. Therefore `field_width = viewport_width - 2 * outer_padding_x` and `field_height = viewport_height - 2 * outer_padding_y - 2 * hud_height`.
- `item_gap` controls horizontal separation between placeholder items inside each reserved HUD band. `row_gap` controls vertical separation between result-overlay text rows. Neither reduces the field allocation.
- `panel_padding` controls content insets inside both HUD panels and the result panel. `icon_size` controls the primitive square placeholder icons. `hud_height` controls each HUD band's exact reserved height.
- Validation reports every invalid field in one pass and includes `ui_layout_profile.<field_name>` in each relevant message.
- The main tracked profile uses the default values.

### Presentation

- Top HUD placeholders: live `TIME`, inactive `TRACK`, inactive `CASH`, inactive `DURABILITY`.
- Bottom HUD placeholders: inactive `CONTRACT`, inactive `CARGO`, inactive `TRACK END` warning.
- Inactive values render as an em dash and reserve stable space; they do not invent gameplay state.
- The field is the only future track-input surface and remains the dominant vertical area.
- Result text is limited to `SESSION COMPLETE`, `REGULAR TIME EXPIRED`, and `Settlement is not available in this milestone.`
- The result overlay has no interactive control.
- View changes happen inside `prototype_app.tscn`; do not change the configured main-scene path.
- Viewport-to-field mapping uses the field Control's canvas transform. Points outside the field return no field coordinate.

## Public Contracts

`SessionSnapshot`:

~~~gdscript
class_name SessionSnapshot
extends RefCounted

func _init(
    total_ticks_value: int,
    elapsed_ticks_value: int,
    remaining_ticks_value: int,
    ticks_per_second_value: int
) -> void
func get_total_ticks() -> int
func get_elapsed_ticks() -> int
func get_remaining_ticks() -> int
func get_ticks_per_second() -> int
func get_display_seconds() -> int
~~~

The snapshot exposes values only through getters. Its backing fields are private-by-convention, it exposes no setter or mutable collection, and each publication is detached from the controller's internal counters. Presentation never writes a snapshot. Tests prove that retaining a previously published snapshot cannot change subsequent controller state.

`SessionResult`:

~~~gdscript
class_name SessionResult
extends RefCounted

enum Reason {
    REGULAR_TIME_EXPIRED,
}

func _init(
    reason_value: Reason,
    total_ticks_value: int,
    elapsed_ticks_value: int,
    remaining_ticks_value: int
) -> void
func get_reason() -> Reason
func get_total_ticks() -> int
func get_elapsed_ticks() -> int
func get_remaining_ticks() -> int
~~~

`SessionController`:

~~~gdscript
class_name SessionController
extends RefCounted

signal snapshot_published(snapshot)
signal session_completed(result)

enum State {
    READY,
    RUNNING,
    COMPLETED,
}

func _init(start_config) -> void
func start()
func advance_tick()
func get_snapshot()
func get_state() -> State
~~~

Cross-script type annotations must use explicit preload constants, following the Foundation compatibility pattern, rather than depending on a pre-existing global class cache.

`UILayoutProfile`:

~~~gdscript
class_name UILayoutProfile
extends Resource

@export var outer_padding_x: float
@export var outer_padding_y: float
@export var panel_padding: float
@export var item_gap: float
@export var row_gap: float
@export var hud_height: float
@export var icon_size: float
~~~

`UILayoutValidator`:

~~~gdscript
class_name UILayoutValidator
extends RefCounted

const MIN_SUPPORTED_VIEWPORT := Vector2i(960, 540)
const MAX_SUPPORTED_VIEWPORT := Vector2i(1920, 1080)
const MIN_FIELD_SIZE := Vector2(640.0, 300.0)

static func validate(profile, viewport_size := MIN_SUPPORTED_VIEWPORT) -> PackedStringArray
static func calculate_field_size(profile, viewport_size: Vector2i) -> Vector2
~~~

`SessionShell` public behavior:

~~~gdscript
func configure(profile, initial_snapshot) -> void
func present(snapshot) -> void
func show_result(result) -> void
func is_showing_result() -> bool
func get_field_global_rect() -> Rect2
func is_viewport_point_in_field(viewport_position: Vector2) -> bool
func try_viewport_to_field(viewport_position: Vector2) -> Variant
func get_layout_observation() -> Dictionary
~~~

`get_layout_observation()` returns a fresh diagnostic Dictionary with semantic rectangles and measurements for the two HUD bands, HUD content insets, field, primitive icons, horizontal item gaps, and result-text row gaps. It exists to test the concrete presentation boundary without freezing arbitrary child-node names and must not expose domain state or writable node references.

`PrototypeApp` retains its Foundation exports and adds a typed layout Resource plus observable composition/result boundaries:

~~~gdscript
@export var balance: PrototypeBalanceScript
@export var startup_seed := 1
@export var layout_profile: UILayoutProfileScript

var session_start_config: SessionStartConfigScript
var session_rng: SessionRngScript
var session_controller: SessionControllerScript

signal session_result_presented(result)

func compose_session_dependencies() -> PackedStringArray
func present_session_result(result) -> void
func is_showing_result() -> bool
~~~

## File Map

- Create `godot-project-moe-rail-way/src/domain/session/session_snapshot.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/domain/session/session_result.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/domain/session/session_controller.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/presentation/layout/ui_layout_profile.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/presentation/layout/ui_layout_validator.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/data/ui_layout_profile.tres`
- Create `godot-project-moe-rail-way/src/presentation/session/session_shell.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/src/presentation/session/session_shell.tscn`
- Create `godot-project-moe-rail-way/src/presentation/theme/prototype_theme.tres`
- Create `godot-project-moe-rail-way/tests/unit/test_session_controller.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/unit/test_ui_layout_validator.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd` and `.gd.uid`
- Create `godot-project-moe-rail-way/tests/fixtures/short_session_balance.tres`
- Create `godot-project-moe-rail-way/tests/fixtures/invalid_ui_layout_profile.tres`
- Create `godot-project-moe-rail-way/tests/integration/short_session_app.tscn`
- Create `godot-project-moe-rail-way/tests/integration/invalid_layout_app.tscn`
- Create `godot-project-moe-rail-way/tests/manual/session_shell_windows.md`
- Modify `godot-project-moe-rail-way/src/app/prototype_app.gd`
- Modify `godot-project-moe-rail-way/src/app/prototype_app.tscn`
- Modify `godot-project-moe-rail-way/tests/run_all.gd`
- Modify `godot-project-moe-rail-way/tests/smoke/test_project_boot.gd`

---

### Task 1: Add the Deterministic Empty-Session Clock

**Files:**

- Create the three session-domain scripts and UID sidecars
- Create `tests/unit/test_session_controller.gd` and its UID sidecar
- Modify `tests/run_all.gd`

**Produces:** A concrete, explicitly ticked countdown and one-shot regular completion result.

- [ ] **Step 1: Write the controller test before implementation**

Cover all of the following in `test_session_controller.gd`:

- A 2.0-second, 4-tick-per-second config produces exactly 8 total ticks.
- A 0.11-second, 10-tick-per-second config rounds up to 2 ticks and never completes early.
- `advance_tick()` before `start()` changes nothing.
- `start()` publishes the initial full-duration snapshot once and a second call does not reset time.
- Each running tick reduces remaining ticks by one.
- Display seconds use ceiling semantics and reach zero only on completion.
- A retained older snapshot remains unchanged as later ticks advance, exposes no public mutation API, and cannot alter the controller's current state.
- The final tick publishes a zero-remaining snapshot before one `REGULAR_TIME_EXPIRED` result.
- Ten additional ticks after completion do not publish another completion result.
- Result fields match the final snapshot and contain no settlement value.

Append the suite to `tests/run_all.gd`; the registered suite count becomes 5.

- [ ] **Step 2: Run RED and require the missing controller path**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailRedOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProjectPath --script 'res://tests/run_all.gd' 2>&1)
$MoeRailRedExit = $LASTEXITCODE
$MoeRailRedOutput
$MoeRailRedText = $MoeRailRedOutput -join "`n"
if ($MoeRailRedExit -eq 0 -or $MoeRailRedText -notmatch 'res://src/domain/session/session_controller.gd') {
    throw 'Expected missing-session-controller RED state was not observed.'
}
~~~

- [ ] **Step 3: Implement the minimum concrete domain model**

Implement the public contracts and numerical rules above. The controller owns integer state and emits signals synchronously. It does not extend `Node`, inspect scenes, format UI strings, or create future early-end reasons.

- [ ] **Step 4: Run GREEN and require exactly 5 suites**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailTestOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProjectPath --script 'res://tests/run_all.gd' 2>&1)
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestOutput
$MoeRailTestText = $MoeRailTestOutput -join "`n"
$MoeRailPassCount = [regex]::Matches(
    $MoeRailTestText,
    '(?m)^PASS: 5 prototype test suite\(s\)\r?$'
).Count
if ($MoeRailTestExit -ne 0 -or $MoeRailPassCount -ne 1 -or
    $MoeRailTestText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Session clock did not pass exactly 5 suites.'
}
~~~

- [ ] **Step 5: Commit the session clock**

Stage only Task 1 files, verify the exact staged set, reject leftover worktree changes, run the cached diff gate, and fail fast on every Git command.

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailExpectedTaskFiles = @(
    'godot-project-moe-rail-way/src/domain/session/session_snapshot.gd',
    'godot-project-moe-rail-way/src/domain/session/session_snapshot.gd.uid',
    'godot-project-moe-rail-way/src/domain/session/session_result.gd',
    'godot-project-moe-rail-way/src/domain/session/session_result.gd.uid',
    'godot-project-moe-rail-way/src/domain/session/session_controller.gd',
    'godot-project-moe-rail-way/src/domain/session/session_controller.gd.uid',
    'godot-project-moe-rail-way/tests/unit/test_session_controller.gd',
    'godot-project-moe-rail-way/tests/unit/test_session_controller.gd.uid',
    'godot-project-moe-rail-way/tests/run_all.gd'
) | Sort-Object

$MoeRailRootOutput = @(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
$MoeRailRootExit = $LASTEXITCODE
$MoeRailRoot = ($MoeRailRootOutput -join "`n").Trim()
$MoeRailBranchOutput = @(git -C $MoeRailFeatureWorktree branch --show-current)
$MoeRailBranchExit = $LASTEXITCODE
$MoeRailBranch = ($MoeRailBranchOutput -join "`n").Trim()
if ($MoeRailRootExit -ne 0 -or $MoeRailBranchExit -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailBranch -ne 'proto/01-session-shell') {
    throw "Refusing Task 1 commit from root '$MoeRailRoot' on branch '$MoeRailBranch'."
}
$MoeRailIndexBefore = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailIndexBefore.Count -ne 0) {
    $MoeRailIndexBefore
    throw 'Task 1 requires an initially empty index.'
}
git -C $MoeRailFeatureWorktree add -- $MoeRailExpectedTaskFiles
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stage the exact Task 1 file set.'
}
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only) | Sort-Object
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the Task 1 staged set.'
}
$MoeRailStageDifference = @(Compare-Object $MoeRailExpectedTaskFiles $MoeRailStaged)
if ($MoeRailStageDifference.Count -ne 0) {
    $MoeRailStageDifference
    throw 'Task 1 staged paths differ from the approved file set.'
}
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -eq 1) {
    throw 'Task 1 has unstaged tracked changes.'
} elseif ($MoeRailUnstagedExit -ne 0) {
    throw 'Failed to inspect Task 1 unstaged changes.'
}
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUntracked
    throw 'Task 1 has unexpected untracked files.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'Task 1 cached diff failed the whitespace gate.'
}
git -C $MoeRailFeatureWorktree commit -m "feat: add deterministic empty session clock"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit the deterministic empty session clock.'
}
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 1 did not leave a clean feature worktree.'
}
~~~

---

### Task 2: Add the Validated UI Layout Profile

**Files:**

- Create the layout profile, validator, default Resource, tests, and UID sidecars
- Modify `tests/run_all.gd`

**Produces:** Inspector-editable spacing with explicit numeric and derived-field guarantees.

- [ ] **Step 1: Write layout validation tests before implementation**

Cover:

- The default profile is valid at 960x540, 1280x720, and 1920x1080.
- A profile set to every minimum is valid at 960x540.
- A profile set to every maximum is valid at 960x540 and leaves at least 640x300 for the field.
- Horizontal and vertical outer padding remain independently observable.
- Each field below its minimum and above its maximum produces an error containing `ui_layout_profile.<field>`.
- A HUD that cannot contain `icon_size + 2 * panel_padding` is rejected.
- A derived field smaller than 640x300 is rejected and names the layout Resource and field boundary.
- A null profile is rejected.

Append the suite to `tests/run_all.gd`; the registered suite count becomes 6.

- [ ] **Step 2: Run RED and require the missing layout profile path**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailRedOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProjectPath --script 'res://tests/run_all.gd' 2>&1)
$MoeRailRedExit = $LASTEXITCODE
$MoeRailRedOutput
$MoeRailRedText = $MoeRailRedOutput -join "`n"
if ($MoeRailRedExit -eq 0 -or
    $MoeRailRedText -notmatch 'res://src/presentation/layout/ui_layout_profile.gd') {
    throw 'Expected missing-layout-profile RED state was not observed.'
}
~~~

- [ ] **Step 3: Implement the profile, validator, and default Resource**

Use the exact defaults, bounds, supported viewports, and derived constraints in this plan. Keep validation separate from `PrototypeConfigValidator`; `PrototypeApp` will aggregate both validators in Task 4.

- [ ] **Step 4: Run GREEN and require exactly 6 suites**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailTestOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProjectPath --script 'res://tests/run_all.gd' 2>&1)
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestOutput
$MoeRailTestText = $MoeRailTestOutput -join "`n"
$MoeRailPassCount = [regex]::Matches(
    $MoeRailTestText,
    '(?m)^PASS: 6 prototype test suite\(s\)\r?$'
).Count
if ($MoeRailTestExit -ne 0 -or $MoeRailPassCount -ne 1 -or
    $MoeRailTestText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Layout validation did not pass exactly 6 suites.'
}
~~~

- [ ] **Step 5: Commit the validated layout profile**

Stage only Task 2 files, verify the exact set including UID sidecars, reject leftover changes, run the cached diff gate, and commit:

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailExpectedTaskFiles = @(
    'godot-project-moe-rail-way/src/presentation/layout/ui_layout_profile.gd',
    'godot-project-moe-rail-way/src/presentation/layout/ui_layout_profile.gd.uid',
    'godot-project-moe-rail-way/src/presentation/layout/ui_layout_validator.gd',
    'godot-project-moe-rail-way/src/presentation/layout/ui_layout_validator.gd.uid',
    'godot-project-moe-rail-way/data/ui_layout_profile.tres',
    'godot-project-moe-rail-way/tests/unit/test_ui_layout_validator.gd',
    'godot-project-moe-rail-way/tests/unit/test_ui_layout_validator.gd.uid',
    'godot-project-moe-rail-way/tests/run_all.gd'
) | Sort-Object

$MoeRailRootOutput = @(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
$MoeRailRootExit = $LASTEXITCODE
$MoeRailRoot = ($MoeRailRootOutput -join "`n").Trim()
$MoeRailBranchOutput = @(git -C $MoeRailFeatureWorktree branch --show-current)
$MoeRailBranchExit = $LASTEXITCODE
$MoeRailBranch = ($MoeRailBranchOutput -join "`n").Trim()
if ($MoeRailRootExit -ne 0 -or $MoeRailBranchExit -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailBranch -ne 'proto/01-session-shell') {
    throw "Refusing Task 2 commit from root '$MoeRailRoot' on branch '$MoeRailBranch'."
}
$MoeRailIndexBefore = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailIndexBefore.Count -ne 0) {
    $MoeRailIndexBefore
    throw 'Task 2 requires an initially empty index.'
}
git -C $MoeRailFeatureWorktree add -- $MoeRailExpectedTaskFiles
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stage the exact Task 2 file set.'
}
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only) | Sort-Object
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the Task 2 staged set.'
}
$MoeRailStageDifference = @(Compare-Object $MoeRailExpectedTaskFiles $MoeRailStaged)
if ($MoeRailStageDifference.Count -ne 0) {
    $MoeRailStageDifference
    throw 'Task 2 staged paths differ from the approved file set.'
}
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -eq 1) {
    throw 'Task 2 has unstaged tracked changes.'
} elseif ($MoeRailUnstagedExit -ne 0) {
    throw 'Failed to inspect Task 2 unstaged changes.'
}
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUntracked
    throw 'Task 2 has unexpected untracked files.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'Task 2 cached diff failed the whitespace gate.'
}
git -C $MoeRailFeatureWorktree commit -m "feat: add validated prototype layout profile"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit the validated prototype layout profile.'
}
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 2 did not leave a clean feature worktree.'
}
~~~

---

### Task 3: Build the Responsive Session Shell View

**Files:**

- Create `session_shell.gd`, `session_shell.tscn`, `prototype_theme.tres`, and the script UID
- Create the integration runner and its UID

**Produces:** The actual map-dominant Control layout, placeholder HUD, public field-coordinate mapping, and hidden result overlay.

- [ ] **Step 1: Write the scene integration test before the shell exists**

Create `tests/integration/run_session_shell_integration.gd` as a standalone `SceneTree` runner. It may wait for process frames because it is separate from the synchronous unit runner.

The initial integration test must:

- Load and instantiate `session_shell.tscn` through its public contract.
- Apply minimum and maximum profiles at 960x540, defaults at 1280x720, and defaults at 1920x1080.
- Wait until Containers finish sorting before reading geometry.
- Verify top HUD, field, and bottom HUD do not overlap.
- Verify the field meets 640x300 and occupies more vertical space than either HUD.
- Verify the root separation between the top HUD, field, and bottom HUD is exactly zero.
- Change one metric at a time and use `get_layout_observation()` to prove that:
  - `outer_padding_x` and `outer_padding_y` affect only their respective outer axes;
  - `panel_padding` changes HUD and result-panel content insets;
  - `item_gap` changes horizontal HUD-item separation;
  - `row_gap` changes vertical result-text separation after `show_result()`;
  - `hud_height` changes both reserved HUD heights; and
  - `icon_size` changes each primitive placeholder icon's square size.
- Map the field center from viewport coordinates to approximately half the field size.
- Reject points immediately outside each field edge.
- Verify the initial view is the running-session view and the result overlay is hidden.
- Inspect live placeholder text through public shell state or accessibility-visible text, without asserting arbitrary child names.
- Print `PASS: session shell layout integration` and exit 0.

- [ ] **Step 2: Run RED and require the missing session-shell scene**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailRedOutput = @(& $MoeRailGodotExe --headless --path $MoeRailProjectPath --script 'res://tests/integration/run_session_shell_integration.gd' 2>&1)
$MoeRailRedExit = $LASTEXITCODE
$MoeRailRedOutput
$MoeRailRedText = $MoeRailRedOutput -join "`n"
if ($MoeRailRedExit -eq 0 -or
    $MoeRailRedText -notmatch 'res://src/presentation/session/session_shell.tscn') {
    throw 'Expected missing-session-shell RED state was not observed.'
}
~~~

- [ ] **Step 3: Create the primitive Theme and responsive Control scene**

Use `MarginContainer`, `VBoxContainer`, `PanelContainer`, and `HBoxContainer` for layout. The root `VBoxContainer` separation is zero. Apply the remaining profile values to the exact consumers defined above through theme constants, content margins, size flags, and HUD minimum size. Do not encode viewport-relative positions as fixed offsets.

Use only flat colors, default fonts, simple borders, and text. Keep the field input surface and result overlay in the same scene. The result overlay starts hidden and contains no Button.

- [ ] **Step 4: Implement public presentation behavior**

- `configure()` applies the profile and initial snapshot.
- `present()` updates only the time value in this milestone.
- `show_result()` changes visibility once and renders only the approved result text.
- Coordinate mapping uses the field's current canvas transform and returns `null` outside the field.
- Reapplying a valid profile after resize preserves the same public behavior.

- [ ] **Step 5: Run layout integration GREEN**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'

$MoeRailIntegrationOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath `
        --script 'res://tests/integration/run_session_shell_integration.gd' 2>&1
)
$MoeRailIntegrationExit = $LASTEXITCODE
$MoeRailIntegrationText = $MoeRailIntegrationOutput -join "`n"
$MoeRailIntegrationPasses = [regex]::Matches(
    $MoeRailIntegrationText,
    '(?m)^PASS: session shell layout integration\r?$'
).Count
$MoeRailIntegrationOutput
if ($MoeRailIntegrationExit -ne 0 -or $MoeRailIntegrationPasses -ne 1 -or
    $MoeRailIntegrationText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Session-shell layout integration did not pass exactly once.'
}

$MoeRailTestOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath `
        --script 'res://tests/run_all.gd' 2>&1
)
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestText = $MoeRailTestOutput -join "`n"
$MoeRailTestPasses = [regex]::Matches(
    $MoeRailTestText,
    '(?m)^PASS: 6 prototype test suite\(s\)\r?$'
).Count
$MoeRailTestOutput
if ($MoeRailTestExit -ne 0 -or $MoeRailTestPasses -ne 1 -or
    $MoeRailTestText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The shell change regressed the 6-suite runner.'
}
~~~

- [ ] **Step 6: Commit the responsive shell**

Stage only Task 3 files, verify the exact set and clean remainder, run the cached diff gate, and commit:

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailExpectedTaskFiles = @(
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.gd.uid',
    'godot-project-moe-rail-way/src/presentation/session/session_shell.tscn',
    'godot-project-moe-rail-way/src/presentation/theme/prototype_theme.tres',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd.uid'
) | Sort-Object

$MoeRailRootOutput = @(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
$MoeRailRootExit = $LASTEXITCODE
$MoeRailRoot = ($MoeRailRootOutput -join "`n").Trim()
$MoeRailBranchOutput = @(git -C $MoeRailFeatureWorktree branch --show-current)
$MoeRailBranchExit = $LASTEXITCODE
$MoeRailBranch = ($MoeRailBranchOutput -join "`n").Trim()
if ($MoeRailRootExit -ne 0 -or $MoeRailBranchExit -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailBranch -ne 'proto/01-session-shell') {
    throw "Refusing Task 3 commit from root '$MoeRailRoot' on branch '$MoeRailBranch'."
}
$MoeRailIndexBefore = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailIndexBefore.Count -ne 0) {
    $MoeRailIndexBefore
    throw 'Task 3 requires an initially empty index.'
}
git -C $MoeRailFeatureWorktree add -- $MoeRailExpectedTaskFiles
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stage the exact Task 3 file set.'
}
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only) | Sort-Object
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the Task 3 staged set.'
}
$MoeRailStageDifference = @(Compare-Object $MoeRailExpectedTaskFiles $MoeRailStaged)
if ($MoeRailStageDifference.Count -ne 0) {
    $MoeRailStageDifference
    throw 'Task 3 staged paths differ from the approved file set.'
}
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -eq 1) {
    throw 'Task 3 has unstaged tracked changes.'
} elseif ($MoeRailUnstagedExit -ne 0) {
    throw 'Failed to inspect Task 3 unstaged changes.'
}
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUntracked
    throw 'Task 3 has unexpected untracked files.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'Task 3 cached diff failed the whitespace gate.'
}
git -C $MoeRailFeatureWorktree commit -m "feat: build responsive prototype session shell"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit the responsive session shell.'
}
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 3 did not leave a clean feature worktree.'
}
~~~

---

### Task 4: Wire Automatic Start and One-Shot Result Transition

**Files:**

- Modify `prototype_app.gd`, `prototype_app.tscn`, the boot smoke test, and the integration runner
- Create the short balance fixture, invalid layout fixture, short-session wrapper scene, and invalid-layout wrapper scene

**Produces:** The approved boot-to-session-to-result flow without settlement or interaction.

- [ ] **Step 1: Write app-composition and lifecycle assertions before wiring**

Update the Foundation boot smoke test so it calls `compose_session_dependencies()` instead of manually invoking `_ready()` on an out-of-tree scene. Preserve all existing typed balance, factory-seed, and RNG-stream assertions, then add:

- `layout_profile` is an exported typed Resource.
- Valid composition creates a `SessionController` from the factory-produced `SessionStartConfig`.
- Invalid layout composition reports field-qualified errors without starting a session.

Retain every Task 3 geometry, resize, metric-observability, placeholder, result-layout, and coordinate-mapping assertion; Task 4 extends that runner and never replaces its layout coverage. Create both test wrappers before running RED. `short_session_app.tscn` instances the real main scene and overrides only the balance with `short_session_balance.tres` set to 2 seconds and 60 ticks per second. `invalid_layout_app.tscn` instances the same main scene and overrides only the layout with a fixture whose `outer_padding_x` is below its minimum.

Lifecycle assertions:

- Adding the app to the tree starts the session automatically without input.
- The initial HUD shows `0:02` for the short fixture.
- After observing auto-start, the integration runner temporarily disables the app's physics processing and explicitly advances the controller to its final tick; this keeps the assertion deterministic.
- The result reason is `REGULAR_TIME_EXPIRED` and the HUD reaches `0:00`.
- At least ten extra ticks create no second `session_result_presented` signal and no second transition.
- Call the public `present_session_result()` boundary again with the completed result. The app-level guard must still prevent a second signal and a second overlay transition, independently of the controller guard.
- The `CASH` and `CONTRACT` placeholders remain inactive em-dash displays; no settlement value, cash mutation, contract action, restart action, or next-cycle action appears.
- Retain `PASS: session shell layout integration` and additionally print `PASS: session shell lifecycle integration` before exit 0.

Run `invalid_layout_app.tscn` as a separate Godot process because its accepted debug behavior is exit code 2. Require a field-qualified layout error, no ready line, and no evidence that a session tick ran.

- [ ] **Step 2: Run RED and require the missing app contract**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'

$MoeRailUnitRedOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath `
        --script 'res://tests/run_all.gd' 2>&1
)
$MoeRailUnitRedExit = $LASTEXITCODE
$MoeRailUnitRedText = $MoeRailUnitRedOutput -join "`n"
$MoeRailUnitRedOutput
if ($MoeRailUnitRedExit -eq 0 -or
    $MoeRailUnitRedText -notmatch '(layout_profile|compose_session_dependencies)') {
    throw 'Expected missing PrototypeApp composition contract was not observed in unit RED.'
}

$MoeRailIntegrationRedOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath `
        --script 'res://tests/integration/run_session_shell_integration.gd' 2>&1
)
$MoeRailIntegrationRedExit = $LASTEXITCODE
$MoeRailIntegrationRedText = $MoeRailIntegrationRedOutput -join "`n"
$MoeRailIntegrationRedOutput
if ($MoeRailIntegrationRedExit -eq 0 -or
    $MoeRailIntegrationRedText -notmatch
        '(session_controller|session_result_presented|present_session_result|layout_profile)') {
    throw 'Expected missing PrototypeApp lifecycle contract was not observed in integration RED.'
}
~~~

- [ ] **Step 3: Refactor composition without breaking Foundation**

`compose_session_dependencies()` must:

1. Aggregate balance errors and layout errors.
2. Return all errors without touching the SceneTree when called outside it.
3. Create `SessionStartConfig` through the balance factory.
4. Create `SessionRng` from the resulting config seed.
5. Create the concrete `SessionController` from the same config.

`_ready()` must disable physics processing before validation, call this method, preserve the current debug failure behavior, set `Engine.physics_ticks_per_second`, connect controller signals, configure the shell, call `start()`, and only then enable physics processing. An invalid in-tree app exits with code 2 before physics can run. `_physics_process` also guards against a null or non-running controller.

- [ ] **Step 4: Wire fixed physics and guarded result presentation**

- `_physics_process` advances exactly one controller tick and ignores `delta`.
- Snapshot signals update the shell.
- Completion calls `present_session_result()`, which disables physics processing, shows the result once, emits `session_result_presented` once, and prints a stable result line.
- An app-level guard prevents duplicate presentation even if the completion handler is called twice.
- The existing main-scene path remains unchanged.
- The main scene references the default balance, default layout profile, Theme, and `SessionShell` scene.
- The exact ready line is `Moe Rail Way session shell ready | duration=180 ticks=60`.
- The two-second fixture's exact result line is `Moe Rail Way session complete | reason=REGULAR_TIME_EXPIRED elapsed_ticks=120 total_ticks=120`.

- [ ] **Step 5: Run complete automated GREEN**

Store and restore the previous `Engine.physics_ticks_per_second` inside integration tests so the test process does not leak global state. Then run this exact gate:

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailProjectPath = Join-Path $MoeRailFeatureWorktree 'godot-project-moe-rail-way'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'

$MoeRailTestOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath `
        --script 'res://tests/run_all.gd' 2>&1
)
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestText = $MoeRailTestOutput -join "`n"
$MoeRailTestPasses = [regex]::Matches(
    $MoeRailTestText,
    '(?m)^PASS: 6 prototype test suite\(s\)\r?$'
).Count
$MoeRailTestOutput
if ($MoeRailTestExit -ne 0 -or $MoeRailTestPasses -ne 1 -or
    $MoeRailTestText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The complete unit and smoke runner did not pass exactly 6 suites.'
}

$MoeRailIntegrationOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath `
        --script 'res://tests/integration/run_session_shell_integration.gd' 2>&1
)
$MoeRailIntegrationExit = $LASTEXITCODE
$MoeRailIntegrationText = $MoeRailIntegrationOutput -join "`n"
$MoeRailLayoutPasses = [regex]::Matches(
    $MoeRailIntegrationText,
    '(?m)^PASS: session shell layout integration\r?$'
).Count
$MoeRailLifecyclePasses = [regex]::Matches(
    $MoeRailIntegrationText,
    '(?m)^PASS: session shell lifecycle integration\r?$'
).Count
$MoeRailIntegrationOutput
if ($MoeRailIntegrationExit -ne 0 -or $MoeRailLayoutPasses -ne 1 -or
    $MoeRailLifecyclePasses -ne 1 -or
    $MoeRailIntegrationText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'Session-shell layout and lifecycle integration did not each pass exactly once.'
}

$MoeRailMainOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath --quit-after 2 2>&1
)
$MoeRailMainExit = $LASTEXITCODE
$MoeRailMainText = $MoeRailMainOutput -join "`n"
$MoeRailReadyCount = [regex]::Matches(
    $MoeRailMainText,
    '(?m)^Moe Rail Way session shell ready \| duration=180 ticks=60\r?$'
).Count
$MoeRailMainOutput
if ($MoeRailMainExit -ne 0 -or $MoeRailReadyCount -ne 1 -or
    $MoeRailMainText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The configured main scene did not auto-start within two engine iterations.'
}

$MoeRailShortOutput = @(
    & $MoeRailGodotExe --headless --fixed-fps 60 --path $MoeRailProjectPath `
        --scene 'res://tests/integration/short_session_app.tscn' --quit-after 180 2>&1
)
$MoeRailShortExit = $LASTEXITCODE
$MoeRailShortText = $MoeRailShortOutput -join "`n"
$MoeRailShortResultCount = [regex]::Matches(
    $MoeRailShortText,
    '(?m)^Moe Rail Way session complete \| reason=REGULAR_TIME_EXPIRED elapsed_ticks=120 total_ticks=120\r?$'
).Count
$MoeRailShortOutput
if ($MoeRailShortExit -ne 0 -or $MoeRailShortResultCount -ne 1 -or
    $MoeRailShortText -match '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:)') {
    throw 'The two-second session did not complete exactly once within 180 fixed-FPS iterations.'
}

$MoeRailInvalidOutput = @(
    & $MoeRailGodotExe --headless --path $MoeRailProjectPath `
        --scene 'res://tests/integration/invalid_layout_app.tscn' --quit-after 5 2>&1
)
$MoeRailInvalidExit = $LASTEXITCODE
$MoeRailInvalidText = $MoeRailInvalidOutput -join "`n"
$MoeRailInvalidLines = @($MoeRailInvalidText -split '\r?\n')
$MoeRailApprovedValidationLines = @(
    $MoeRailInvalidLines | Where-Object {
        $_ -match '^ERROR: ui_layout_profile\.outer_padding_x\b'
    }
)
$MoeRailUnexpectedFailureLines = @(
    $MoeRailInvalidLines | Where-Object {
        $_ -match '^(FAIL:|SCRIPT ERROR:|ERROR:)' -and
        $_ -notmatch '^ERROR: ui_layout_profile\.outer_padding_x\b'
    }
)
$MoeRailInvalidOutput
if ($MoeRailInvalidExit -ne 2 -or
    $MoeRailApprovedValidationLines.Count -ne 1 -or
    $MoeRailUnexpectedFailureLines.Count -ne 0 -or
    $MoeRailInvalidText -match 'Moe Rail Way session shell ready|session complete') {
    $MoeRailUnexpectedFailureLines
    throw 'Invalid layout did not fail safely before session startup.'
}
~~~

- [ ] **Step 6: Commit the automatic lifecycle**

Stage only Task 4 files, verify the exact set and clean remainder, require cached diff quality, and commit:

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailExpectedTaskFiles = @(
    'godot-project-moe-rail-way/src/app/prototype_app.gd',
    'godot-project-moe-rail-way/src/app/prototype_app.tscn',
    'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd',
    'godot-project-moe-rail-way/tests/integration/run_session_shell_integration.gd',
    'godot-project-moe-rail-way/tests/fixtures/short_session_balance.tres',
    'godot-project-moe-rail-way/tests/fixtures/invalid_ui_layout_profile.tres',
    'godot-project-moe-rail-way/tests/integration/short_session_app.tscn',
    'godot-project-moe-rail-way/tests/integration/invalid_layout_app.tscn'
) | Sort-Object

$MoeRailRootOutput = @(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
$MoeRailRootExit = $LASTEXITCODE
$MoeRailRoot = ($MoeRailRootOutput -join "`n").Trim()
$MoeRailBranchOutput = @(git -C $MoeRailFeatureWorktree branch --show-current)
$MoeRailBranchExit = $LASTEXITCODE
$MoeRailBranch = ($MoeRailBranchOutput -join "`n").Trim()
if ($MoeRailRootExit -ne 0 -or $MoeRailBranchExit -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailBranch -ne 'proto/01-session-shell') {
    throw "Refusing Task 4 commit from root '$MoeRailRoot' on branch '$MoeRailBranch'."
}
$MoeRailIndexBefore = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailIndexBefore.Count -ne 0) {
    $MoeRailIndexBefore
    throw 'Task 4 requires an initially empty index.'
}
git -C $MoeRailFeatureWorktree add -- $MoeRailExpectedTaskFiles
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stage the exact Task 4 file set.'
}
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only) | Sort-Object
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the Task 4 staged set.'
}
$MoeRailStageDifference = @(Compare-Object $MoeRailExpectedTaskFiles $MoeRailStaged)
if ($MoeRailStageDifference.Count -ne 0) {
    $MoeRailStageDifference
    throw 'Task 4 staged paths differ from the approved file set.'
}
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -eq 1) {
    throw 'Task 4 has unstaged tracked changes.'
} elseif ($MoeRailUnstagedExit -ne 0) {
    throw 'Failed to inspect Task 4 unstaged changes.'
}
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUntracked
    throw 'Task 4 has unexpected untracked files.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'Task 4 cached diff failed the whitespace gate.'
}
git -C $MoeRailFeatureWorktree commit -m "feat: wire automatic session result transition"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit automatic session result transition.'
}
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 4 did not leave a clean feature worktree.'
}
~~~

---

### Task 5: Pass the Session-Shell Milestone Gate

**Files:**

- Create `tests/manual/session_shell_windows.md`
- Modify implementation only if a preceding automated or manual check exposes a plan-scoped defect

**Produces:** Reproducible automated evidence, Windows resize evidence, repository-hygiene evidence, and the reviewed `prototype-m2` candidate.

- [ ] **Step 1: Write the English Windows manual-smoke checklist**

The checklist must record:

- Godot build and Windows environment.
- Main scene auto-starts with no click and begins at `3:00`.
- Time decrements without skipping visible whole seconds.
- Top and bottom HUDs remain thin and the field remains dominant.
- Inactive future values show em dashes without implying gameplay.
- No temporary start, restart, next, debug end, or settlement control exists.
- 960x540, 1280x720, 1600x900, and 1920x1080 window sizes show no overlap or clipping.
- Minimum and maximum profiles, applied in the Inspector to a local test copy, remain valid and are not committed over the default Resource.
- The short-session wrapper reaches the noninteractive regular result view once.
- The main 180-second Resource remains unchanged after testing.

- [ ] **Step 2: Run the complete automated gate**

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailVersionOutput = @(& $MoeRailGodotExe --version 2>&1)
$MoeRailVersionExit = $LASTEXITCODE
$MoeRailVersion = ($MoeRailVersionOutput -join "`n").Trim()
$MoeRailVersionOutput
if ($MoeRailVersionExit -ne 0 -or $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected Godot version: $MoeRailVersion"
}
~~~

Immediately rerun the complete, self-contained PowerShell gate from Task 4 Step 5 without weakening or skipping any assertion. That block uses the absolute feature project, requires one anchored pass line from each runner, treats `--quit-after` as engine iterations, completes the two-second fixture within 180 fixed-60-FPS iterations, and separately verifies invalid-layout exit code 2.

- [ ] **Step 3: Verify file ownership and repository hygiene**

Run this tracked-file and worktree gate:

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailExpectedBase = 'b28f0001b14efe78ff2de2a0e71d95102750ec1d'
$MoeRailManualPath = 'godot-project-moe-rail-way/tests/manual/session_shell_windows.md'
$MoeRailAllowedUntrackedPaths = @($MoeRailManualPath)
$MoeRailRequiredUntrackedPaths = @($MoeRailManualPath)

$MoeRailTracked = @(git -C $MoeRailFeatureWorktree ls-files)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to enumerate tracked files.'
}
$MoeRailTrackedScripts = @(
    $MoeRailTracked | Where-Object {
        $_ -like 'godot-project-moe-rail-way/*.gd' -or
        $_ -like 'godot-project-moe-rail-way/**/*.gd'
    }
)
$MoeRailTrackedUids = @(
    $MoeRailTracked | Where-Object {
        $_ -like 'godot-project-moe-rail-way/*.gd.uid' -or
        $_ -like 'godot-project-moe-rail-way/**/*.gd.uid'
    }
)
$MoeRailMissingUids = @(
    $MoeRailTrackedScripts | Where-Object { "$_.uid" -notin $MoeRailTrackedUids }
)
$MoeRailOrphanUids = @(
    $MoeRailTrackedUids | Where-Object {
        $_.Substring(0, $_.Length - 4) -notin $MoeRailTrackedScripts
    }
)
if ($MoeRailMissingUids -or $MoeRailOrphanUids) {
    $MoeRailMissingUids
    $MoeRailOrphanUids
    throw 'Tracked GDScript and UID sidecars are not one-to-one.'
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

$MoeRailBalanceOutput = @(
    git -C $MoeRailFeatureWorktree show 'HEAD:godot-project-moe-rail-way/data/prototype_balance.tres'
)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read the tracked main balance.'
}
$MoeRailBalanceText = $MoeRailBalanceOutput -join "`n"
if ([regex]::Matches($MoeRailBalanceText, '(?m)^session_duration_seconds = 180\.0\r?$').Count -ne 1 -or
    [regex]::Matches($MoeRailBalanceText, '(?m)^simulation_ticks_per_second = 60\r?$').Count -ne 1) {
    throw 'The main tracked balance is not exactly 180 seconds at 60 ticks per second.'
}

$MoeRailShortDurationPaths = @(
    git -C $MoeRailFeatureWorktree grep -l -F 'session_duration_seconds = 2.0' HEAD -- 'godot-project-moe-rail-way'
)
$MoeRailShortDurationExit = $LASTEXITCODE
if ($MoeRailShortDurationExit -ne 0 -or $MoeRailShortDurationPaths.Count -ne 1 -or
    $MoeRailShortDurationPaths[0] -ne
        'HEAD:godot-project-moe-rail-way/tests/fixtures/short_session_balance.tres') {
    $MoeRailShortDurationPaths
    throw 'The two-second duration is not isolated to the approved test fixture.'
}

$MoeRailForbiddenControls = @(
    git -C $MoeRailFeatureWorktree grep -n -E `
        'type="Button"|debug_(end|finish)|debug (end|finish)' HEAD -- `
        'godot-project-moe-rail-way/src/app' `
        'godot-project-moe-rail-way/src/presentation/session' `
        'godot-project-moe-rail-way/project.godot'
)
$MoeRailForbiddenControlExit = $LASTEXITCODE
if ($MoeRailForbiddenControlExit -eq 0) {
    $MoeRailForbiddenControls
    throw 'A Button or debug-end action exists in the session-shell surface.'
} elseif ($MoeRailForbiddenControlExit -ne 1) {
    throw 'Failed to inspect session-shell controls and actions.'
}

git -C $MoeRailFeatureWorktree diff --check "$MoeRailExpectedBase...HEAD"
if ($LASTEXITCODE -ne 0) {
    throw 'The complete feature diff failed the whitespace gate.'
}
$MoeRailIndex = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailIndex.Count -ne 0) {
    $MoeRailIndex
    throw 'The hygiene gate requires an empty index.'
}
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -eq 1) {
    throw 'The hygiene gate found unstaged tracked changes.'
} elseif ($MoeRailUnstagedExit -ne 0) {
    throw 'Failed to inspect hygiene-gate unstaged changes.'
}
$MoeRailActualUntrackedPaths = @(
    git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard
)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect hygiene-gate untracked paths.'
}
$MoeRailUnexpectedUntrackedPaths = @(
    $MoeRailActualUntrackedPaths | Where-Object { $_ -notin $MoeRailAllowedUntrackedPaths }
)
$MoeRailMissingRequiredUntrackedPaths = @(
    $MoeRailRequiredUntrackedPaths | Where-Object { $_ -notin $MoeRailActualUntrackedPaths }
)
if ($MoeRailUnexpectedUntrackedPaths -or $MoeRailMissingRequiredUntrackedPaths) {
    $MoeRailUnexpectedUntrackedPaths
    $MoeRailMissingRequiredUntrackedPaths
    throw 'The hygiene-gate untracked paths differ from the explicit allowlist and required set.'
}
~~~

The independent feature-diff review must also confirm that no domain writer or mutation API for cash, contracts, settlement, credit, track, train, warp, cargo, or hazards was added. Do not use a raw keyword rejection for that review, because approved inactive HUD labels intentionally contain `CASH`, `CONTRACT`, `TRACK`, and `CARGO`.

- [ ] **Step 4: Perform and record Windows manual smoke**

Run the checklist on the actual Windows editor/runtime. Record date, Godot build, tested resolutions, profile extremes, pass/fail, and any host-only warnings. A screenshot is optional and must remain outside Git unless separately approved as a test artifact.

- [ ] **Step 5: Commit the milestone evidence**

The checklist must be the only remaining change. Stage exactly it, verify the staged set and clean remainder, run the cached diff gate, and commit:

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailExpectedTaskFiles = @(
    'godot-project-moe-rail-way/tests/manual/session_shell_windows.md'
)

$MoeRailRootOutput = @(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
$MoeRailRootExit = $LASTEXITCODE
$MoeRailRoot = ($MoeRailRootOutput -join "`n").Trim()
$MoeRailBranchOutput = @(git -C $MoeRailFeatureWorktree branch --show-current)
$MoeRailBranchExit = $LASTEXITCODE
$MoeRailBranch = ($MoeRailBranchOutput -join "`n").Trim()
if ($MoeRailRootExit -ne 0 -or $MoeRailBranchExit -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailBranch -ne 'proto/01-session-shell') {
    throw "Refusing Task 5 commit from root '$MoeRailRoot' on branch '$MoeRailBranch'."
}
$MoeRailIndexBefore = @(git -C $MoeRailFeatureWorktree diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $MoeRailIndexBefore.Count -ne 0) {
    $MoeRailIndexBefore
    throw 'Task 5 requires an initially empty index.'
}
git -C $MoeRailFeatureWorktree add -- $MoeRailExpectedTaskFiles
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stage the exact Task 5 file set.'
}
$MoeRailStaged = @(git -C $MoeRailFeatureWorktree diff --cached --name-only) | Sort-Object
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the Task 5 staged set.'
}
$MoeRailStageDifference = @(Compare-Object ($MoeRailExpectedTaskFiles | Sort-Object) $MoeRailStaged)
if ($MoeRailStageDifference.Count -ne 0) {
    $MoeRailStageDifference
    throw 'Task 5 staged paths differ from the approved file set.'
}
git -C $MoeRailFeatureWorktree diff --quiet
$MoeRailUnstagedExit = $LASTEXITCODE
if ($MoeRailUnstagedExit -eq 1) {
    throw 'Task 5 has unstaged tracked changes.'
} elseif ($MoeRailUnstagedExit -ne 0) {
    throw 'Failed to inspect Task 5 unstaged changes.'
}
$MoeRailUntracked = @(git -C $MoeRailFeatureWorktree ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0 -or $MoeRailUntracked.Count -ne 0) {
    $MoeRailUntracked
    throw 'Task 5 has unexpected untracked files.'
}
git -C $MoeRailFeatureWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'Task 5 cached diff failed the whitespace gate.'
}
git -C $MoeRailFeatureWorktree commit -m "test: document session shell milestone gate"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit the session-shell milestone evidence.'
}
$MoeRailPostCommitStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $MoeRailPostCommitStatus.Count -ne 0) {
    $MoeRailPostCommitStatus
    throw 'Task 5 did not leave a clean feature worktree.'
}
~~~

- [ ] **Step 6: Run fresh post-commit verification**

Repeat the exact version and Task 4 Step 5 automated gates at the new HEAD. Rerun the Step 3 hygiene block with both untracked-path arrays empty and require a completely clean feature worktree. Before review corrections, enforce the expected six commits: the planning commit and five focused implementation/evidence commits.

~~~powershell
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailExpectedBase = 'b28f0001b14efe78ff2de2a0e71d95102750ec1d'
$MoeRailHistoryCountOutput = @(
    git -C $MoeRailFeatureWorktree rev-list --count "$MoeRailExpectedBase..HEAD"
)
$MoeRailHistoryCountExit = $LASTEXITCODE
$MoeRailHistoryCount = ($MoeRailHistoryCountOutput -join "`n").Trim()
$MoeRailHistoryStatus = @(
    git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all
)
$MoeRailHistoryStatusExit = $LASTEXITCODE
if ($MoeRailHistoryCountExit -ne 0 -or $MoeRailHistoryStatusExit -ne 0 -or
    $MoeRailHistoryCount -ne '6' -or $MoeRailHistoryStatus.Count -ne 0) {
    $MoeRailHistoryStatus
    throw "Expected six post-base commits and a clean feature worktree, found: $MoeRailHistoryCount"
}
~~~

If any automated, manual, hygiene, or review check exposes a defect, commit the smallest plan-scoped correction separately, rerun every affected check plus the complete gate at the new HEAD, update the manual record when its evidence changed, and repeat independent review. Correction commits are allowed; never preserve an exact-six-commit claim after adding one, and never integrate evidence captured against an older HEAD.

- [ ] **Step 7: Review and integrate only after evidence is accepted**

Perform an independent whole-branch review against this plan and these English specifications:

- `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`
- `docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md`

Fix, rerun the complete evidence loop, and re-review every finding before integration. Record the accepted feature HEAD as `FEATURE_SHA` and set `MOERAIL_ACCEPTED_FEATURE` to that exact 40-character hash. Then construct a squash candidate without moving `Prototyping`:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailFeatureWorktree = 'D:\godot\MoeRailWay-worktrees\proto-01-session-shell'
$MoeRailCandidateWorktree = 'D:\godot\MoeRailWay-worktrees\prototype-m2-candidate'
$MoeRailCandidateBranch = 'codex/prototype-m2-candidate'
$MoeRailFeatureBranch = 'proto/01-session-shell'
$MoeRailExpectedBase = 'b28f0001b14efe78ff2de2a0e71d95102750ec1d'
$MoeRailAcceptedFeature = $env:MOERAIL_ACCEPTED_FEATURE
if ($MoeRailAcceptedFeature -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_ACCEPTED_FEATURE to the exact reviewed FEATURE_SHA.'
}

if (Test-Path -LiteralPath $MoeRailCandidateWorktree) {
    throw "Candidate worktree path already exists: $MoeRailCandidateWorktree"
}
git -C $MoeRailPrimary show-ref --verify --quiet "refs/heads/$MoeRailCandidateBranch"
$MoeRailCandidateBranchExit = $LASTEXITCODE
if ($MoeRailCandidateBranchExit -eq 0) {
    throw "$MoeRailCandidateBranch already exists."
} elseif ($MoeRailCandidateBranchExit -ne 1) {
    throw 'Failed to inspect the candidate branch.'
}
git -C $MoeRailPrimary show-ref --verify --quiet refs/tags/prototype-m2
$MoeRailTagExit = $LASTEXITCODE
if ($MoeRailTagExit -eq 0) {
    throw 'prototype-m2 already exists; inspect it before continuing.'
} elseif ($MoeRailTagExit -ne 1) {
    throw 'Failed to inspect prototype-m2.'
}

$MoeRailPrototypeHeadOutput = @(git -C $MoeRailPrimary rev-parse --verify 'Prototyping^{commit}')
$MoeRailPrototypeHeadExit = $LASTEXITCODE
$MoeRailPrototypeHead = ($MoeRailPrototypeHeadOutput -join "`n").Trim()
if ($MoeRailPrototypeHeadExit -ne 0 -or $MoeRailPrototypeHead -ne $MoeRailExpectedBase) {
    throw "Prototyping advanced or changed after feature start: $MoeRailPrototypeHead"
}
$MoeRailFeatureBranchHeadOutput = @(
    git -C $MoeRailPrimary rev-parse --verify "$MoeRailFeatureBranch^{commit}"
)
$MoeRailFeatureBranchHeadExit = $LASTEXITCODE
$MoeRailFeatureBranchHead = ($MoeRailFeatureBranchHeadOutput -join "`n").Trim()
if ($MoeRailFeatureBranchHeadExit -ne 0 -or
    $MoeRailFeatureBranchHead -ne $MoeRailAcceptedFeature) {
    throw 'The feature branch no longer points to the exact reviewed FEATURE_SHA.'
}
$MoeRailFeatureMergeBaseOutput = @(
    git -C $MoeRailPrimary merge-base Prototyping $MoeRailAcceptedFeature
)
$MoeRailFeatureMergeBaseExit = $LASTEXITCODE
$MoeRailFeatureMergeBase = ($MoeRailFeatureMergeBaseOutput -join "`n").Trim()
if ($MoeRailFeatureMergeBaseExit -ne 0 -or $MoeRailFeatureMergeBase -ne $MoeRailExpectedBase) {
    throw "Unexpected feature merge base: $MoeRailFeatureMergeBase"
}
$MoeRailFeatureRootOutput = @(git -C $MoeRailFeatureWorktree rev-parse --show-toplevel)
$MoeRailFeatureRootExit = $LASTEXITCODE
$MoeRailFeatureRoot = ($MoeRailFeatureRootOutput -join "`n").Trim()
$MoeRailFeatureCurrentBranchOutput = @(git -C $MoeRailFeatureWorktree branch --show-current)
$MoeRailFeatureCurrentBranchExit = $LASTEXITCODE
$MoeRailFeatureCurrentBranch = ($MoeRailFeatureCurrentBranchOutput -join "`n").Trim()
$MoeRailFeatureHeadOutput = @(git -C $MoeRailFeatureWorktree rev-parse HEAD)
$MoeRailFeatureHeadExit = $LASTEXITCODE
$MoeRailFeatureHead = ($MoeRailFeatureHeadOutput -join "`n").Trim()
$MoeRailFeatureStatus = @(git -C $MoeRailFeatureWorktree status --porcelain --untracked-files=all)
$MoeRailFeatureStatusExit = $LASTEXITCODE
if ($MoeRailFeatureRootExit -ne 0 -or $MoeRailFeatureCurrentBranchExit -ne 0 -or
    $MoeRailFeatureHeadExit -ne 0 -or $MoeRailFeatureStatusExit -ne 0 -or
    [IO.Path]::GetFullPath($MoeRailFeatureRoot) -ne [IO.Path]::GetFullPath($MoeRailFeatureWorktree) -or
    $MoeRailFeatureCurrentBranch -ne $MoeRailFeatureBranch -or
    $MoeRailFeatureHead -ne $MoeRailAcceptedFeature -or
    $MoeRailFeatureStatus.Count -ne 0) {
    $MoeRailFeatureStatus
    throw 'The reviewed feature worktree, branch, or status is not the accepted clean state.'
}
$MoeRailFeatureCommitCountOutput = @(
    git -C $MoeRailFeatureWorktree rev-list --count "$MoeRailExpectedBase..$MoeRailAcceptedFeature"
)
$MoeRailFeatureCommitCountExit = $LASTEXITCODE
$MoeRailFeatureCommitCount = [int](($MoeRailFeatureCommitCountOutput -join "`n").Trim())
if ($MoeRailFeatureCommitCountExit -ne 0 -or $MoeRailFeatureCommitCount -lt 6) {
    throw "Feature history is missing planned commits: $MoeRailFeatureCommitCount"
}

git -C $MoeRailPrimary worktree add -b $MoeRailCandidateBranch $MoeRailCandidateWorktree Prototyping
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to create the isolated prototype-m2 candidate worktree.'
}
git -C $MoeRailCandidateWorktree merge --squash $MoeRailAcceptedFeature
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to construct the prototype-m2 squash candidate.'
}
$MoeRailExpectedCandidateFiles = @(
    git -C $MoeRailPrimary diff --name-only "$MoeRailExpectedBase...$MoeRailAcceptedFeature"
) | Sort-Object
if ($LASTEXITCODE -ne 0 -or $MoeRailExpectedCandidateFiles.Count -eq 0) {
    throw 'Failed to derive the reviewed feature file set.'
}
$MoeRailCandidateStaged = @(
    git -C $MoeRailCandidateWorktree diff --cached --name-only
) | Sort-Object
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the candidate staged set.'
}
$MoeRailCandidateDifference = @(
    Compare-Object $MoeRailExpectedCandidateFiles $MoeRailCandidateStaged
)
if ($MoeRailCandidateDifference.Count -ne 0) {
    $MoeRailCandidateDifference
    throw 'The squash candidate does not contain the exact reviewed feature paths.'
}
git -C $MoeRailCandidateWorktree diff --quiet $MoeRailAcceptedFeature --
if ($LASTEXITCODE -ne 0) {
    throw 'The squash candidate working tree does not exactly match the reviewed feature tree.'
}
git -C $MoeRailCandidateWorktree diff --quiet
$MoeRailCandidateUnstagedExit = $LASTEXITCODE
if ($MoeRailCandidateUnstagedExit -eq 1) {
    throw 'The squash candidate has unstaged tracked changes.'
} elseif ($MoeRailCandidateUnstagedExit -ne 0) {
    throw 'Failed to inspect candidate unstaged changes.'
}
$MoeRailCandidateUntracked = @(
    git -C $MoeRailCandidateWorktree ls-files --others --exclude-standard
)
if ($LASTEXITCODE -ne 0 -or $MoeRailCandidateUntracked.Count -ne 0) {
    $MoeRailCandidateUntracked
    throw 'The squash candidate has unexpected untracked files.'
}
git -C $MoeRailCandidateWorktree diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'The squash candidate failed the cached diff gate.'
}
git -C $MoeRailCandidateWorktree commit -m "feat: deliver prototype session shell"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit the prototype-m2 candidate.'
}
$MoeRailCandidateParentOutput = @(git -C $MoeRailCandidateWorktree rev-parse 'HEAD^')
$MoeRailCandidateParentExit = $LASTEXITCODE
$MoeRailCandidateParent = ($MoeRailCandidateParentOutput -join "`n").Trim()
$MoeRailCandidateStatus = @(
    git -C $MoeRailCandidateWorktree status --porcelain --untracked-files=all
)
$MoeRailCandidateStatusExit = $LASTEXITCODE
$MoeRailCandidateTreeOutput = @(git -C $MoeRailCandidateWorktree rev-parse 'HEAD^{tree}')
$MoeRailCandidateTreeExit = $LASTEXITCODE
$MoeRailCandidateTree = ($MoeRailCandidateTreeOutput -join "`n").Trim()
$MoeRailFeatureTreeOutput = @(
    git -C $MoeRailFeatureWorktree rev-parse "$MoeRailAcceptedFeature^{tree}"
)
$MoeRailFeatureTreeExit = $LASTEXITCODE
$MoeRailFeatureTree = ($MoeRailFeatureTreeOutput -join "`n").Trim()
if ($MoeRailCandidateParentExit -ne 0 -or $MoeRailCandidateStatusExit -ne 0 -or
    $MoeRailCandidateTreeExit -ne 0 -or $MoeRailFeatureTreeExit -ne 0 -or
    $MoeRailCandidateParent -ne $MoeRailExpectedBase -or
    $MoeRailCandidateStatus.Count -ne 0 -or $MoeRailCandidateTree -ne $MoeRailFeatureTree) {
    $MoeRailCandidateStatus
    throw 'The committed squash candidate has an unexpected parent, tree, or dirty status.'
}
$MoeRailCandidateCommitOutput = @(git -C $MoeRailCandidateWorktree rev-parse HEAD)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to print the candidate commit for evidence recording.'
}
"CANDIDATE_SHA=$((($MoeRailCandidateCommitOutput -join "`n").Trim()))"
~~~

Run the complete version, automated, hygiene, and Windows manual gates against `$MoeRailCandidateWorktree`. For the automated block, change only its first worktree assignment from the feature path to the candidate path. For the hygiene block, set both untracked-path arrays empty. Record the printed `CANDIDATE_SHA` with the evidence. Do not promote the candidate if any output or manual evidence differs from the reviewed feature.

After candidate evidence is accepted, promote it with a fast-forward only. The unrelated untracked planning file may remain in the primary worktree, but no tracked/index change or untracked collision with candidate paths is allowed:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailCandidateWorktree = 'D:\godot\MoeRailWay-worktrees\prototype-m2-candidate'
$MoeRailCandidateBranch = 'codex/prototype-m2-candidate'
$MoeRailExpectedBase = 'b28f0001b14efe78ff2de2a0e71d95102750ec1d'
$MoeRailAcceptedCandidate = $env:MOERAIL_ACCEPTED_CANDIDATE
if ($MoeRailAcceptedCandidate -notmatch '^[0-9a-f]{40}$') {
    throw 'Set MOERAIL_ACCEPTED_CANDIDATE to the exact reviewed CANDIDATE_SHA.'
}

$MoeRailPrimaryBranchOutput = @(git -C $MoeRailPrimary branch --show-current)
$MoeRailPrimaryBranchExit = $LASTEXITCODE
$MoeRailPrimaryBranch = ($MoeRailPrimaryBranchOutput -join "`n").Trim()
$MoeRailPrimaryHeadOutput = @(git -C $MoeRailPrimary rev-parse HEAD)
$MoeRailPrimaryHeadExit = $LASTEXITCODE
$MoeRailPrimaryHead = ($MoeRailPrimaryHeadOutput -join "`n").Trim()
if ($MoeRailPrimaryBranchExit -ne 0 -or $MoeRailPrimaryHeadExit -ne 0 -or
    $MoeRailPrimaryBranch -ne 'Prototyping' -or $MoeRailPrimaryHead -ne $MoeRailExpectedBase) {
    throw "Primary worktree is not cleanly positioned at prototype-m1: $MoeRailPrimaryBranch $MoeRailPrimaryHead"
}
git -C $MoeRailPrimary diff --quiet
$MoeRailPrimaryUnstagedExit = $LASTEXITCODE
git -C $MoeRailPrimary diff --cached --quiet
$MoeRailPrimaryStagedExit = $LASTEXITCODE
if ($MoeRailPrimaryUnstagedExit -ne 0 -or $MoeRailPrimaryStagedExit -ne 0) {
    throw 'Primary tracked or staged changes remain; stop and ask their owner without resetting them.'
}

$MoeRailCandidateCommitOutput = @(git -C $MoeRailCandidateWorktree rev-parse HEAD)
$MoeRailCandidateCommitExit = $LASTEXITCODE
$MoeRailCandidateCommit = ($MoeRailCandidateCommitOutput -join "`n").Trim()
$MoeRailCandidateParentOutput = @(git -C $MoeRailCandidateWorktree rev-parse 'HEAD^')
$MoeRailCandidateParentExit = $LASTEXITCODE
$MoeRailCandidateParent = ($MoeRailCandidateParentOutput -join "`n").Trim()
if ($MoeRailCandidateCommitExit -ne 0 -or $MoeRailCandidateParentExit -ne 0 -or
    $MoeRailCandidateCommit -ne $MoeRailAcceptedCandidate -or
    $MoeRailCandidateParent -ne $MoeRailExpectedBase) {
    throw 'The current candidate is not the exact accepted one-commit fast-forward from prototype-m1.'
}
$MoeRailCandidateChangedPaths = @(
    git -C $MoeRailCandidateWorktree diff --name-only "$MoeRailExpectedBase..$MoeRailCandidateCommit"
)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect candidate paths before promotion.'
}
$MoeRailPrimaryUntracked = @(git -C $MoeRailPrimary ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect primary untracked paths.'
}
$MoeRailUntrackedCollisions = @(
    $MoeRailPrimaryUntracked | Where-Object { $_ -in $MoeRailCandidateChangedPaths }
)
if ($MoeRailUntrackedCollisions.Count -ne 0) {
    $MoeRailUntrackedCollisions
    throw 'Primary untracked files collide with candidate paths.'
}
git -C $MoeRailPrimary show-ref --verify --quiet refs/tags/prototype-m2
$MoeRailTagExit = $LASTEXITCODE
if ($MoeRailTagExit -eq 0) {
    throw 'prototype-m2 appeared before promotion; inspect it.'
} elseif ($MoeRailTagExit -ne 1) {
    throw 'Failed to recheck prototype-m2.'
}

git -C $MoeRailPrimary merge --ff-only $MoeRailCandidateCommit
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to fast-forward Prototyping to the accepted candidate.'
}
$MoeRailIntegratedHeadOutput = @(git -C $MoeRailPrimary rev-parse HEAD)
$MoeRailIntegratedHeadExit = $LASTEXITCODE
$MoeRailIntegratedHead = ($MoeRailIntegratedHeadOutput -join "`n").Trim()
if ($MoeRailIntegratedHeadExit -ne 0 -or $MoeRailIntegratedHead -ne $MoeRailCandidateCommit) {
    throw 'Prototyping does not point to the accepted candidate.'
}
~~~

Run the full automated, hygiene, and Windows smoke gates again on the integrated primary checkout. Change the worktree assignment in each reusable block to `D:\godot\MoeRailWay`. For hygiene, allow only `docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md` as optional untracked state by putting it in `$MoeRailAllowedUntrackedPaths` and leaving `$MoeRailRequiredUntrackedPaths` empty. Only after the gates pass and the user accepts the integrated evidence, set `MOERAIL_ACCEPTED_CANDIDATE` to the same reviewed SHA and create the tag:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailCandidateWorktree = 'D:\godot\MoeRailWay-worktrees\prototype-m2-candidate'
$MoeRailExpectedBase = 'b28f0001b14efe78ff2de2a0e71d95102750ec1d'
$MoeRailAllowedPrimaryUntracked = @(
    'docs/superpowers/plans/2026-08-15-godot-mcp-project-setup.md'
)
$MoeRailAcceptedCandidate = $env:MOERAIL_ACCEPTED_CANDIDATE
$MoeRailCandidateHeadOutput = @(git -C $MoeRailCandidateWorktree rev-parse HEAD)
$MoeRailCandidateHeadExit = $LASTEXITCODE
$MoeRailCandidateHead = ($MoeRailCandidateHeadOutput -join "`n").Trim()
$MoeRailCandidateParentOutput = @(git -C $MoeRailCandidateWorktree rev-parse 'HEAD^')
$MoeRailCandidateParentExit = $LASTEXITCODE
$MoeRailCandidateParent = ($MoeRailCandidateParentOutput -join "`n").Trim()
$MoeRailCandidateStatus = @(
    git -C $MoeRailCandidateWorktree status --porcelain --untracked-files=all
)
$MoeRailCandidateStatusExit = $LASTEXITCODE
$MoeRailIntegratedBranchOutput = @(git -C $MoeRailPrimary branch --show-current)
$MoeRailIntegratedBranchExit = $LASTEXITCODE
$MoeRailIntegratedBranch = ($MoeRailIntegratedBranchOutput -join "`n").Trim()
$MoeRailIntegratedHeadOutput = @(git -C $MoeRailPrimary rev-parse HEAD)
$MoeRailIntegratedHeadExit = $LASTEXITCODE
$MoeRailIntegratedHead = ($MoeRailIntegratedHeadOutput -join "`n").Trim()
if ($MoeRailAcceptedCandidate -notmatch '^[0-9a-f]{40}$' -or
    $MoeRailCandidateHeadExit -ne 0 -or $MoeRailCandidateParentExit -ne 0 -or
    $MoeRailCandidateStatusExit -ne 0 -or
    $MoeRailIntegratedBranchExit -ne 0 -or $MoeRailIntegratedHeadExit -ne 0 -or
    $MoeRailCandidateHead -ne $MoeRailAcceptedCandidate -or
    $MoeRailCandidateParent -ne $MoeRailExpectedBase -or
    $MoeRailCandidateStatus.Count -ne 0 -or
    $MoeRailIntegratedBranch -ne 'Prototyping' -or
    $MoeRailIntegratedHead -ne $MoeRailAcceptedCandidate) {
    $MoeRailCandidateStatus
    throw 'The candidate and primary worktrees are not on the exact accepted integration state.'
}
git -C $MoeRailPrimary diff --quiet
$MoeRailPrimaryUnstagedExit = $LASTEXITCODE
git -C $MoeRailPrimary diff --cached --quiet
$MoeRailPrimaryStagedExit = $LASTEXITCODE
if ($MoeRailPrimaryUnstagedExit -ne 0 -or $MoeRailPrimaryStagedExit -ne 0) {
    throw 'Primary tracked or staged changes appeared after integrated verification.'
}
$MoeRailPrimaryUntracked = @(git -C $MoeRailPrimary ls-files --others --exclude-standard)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect primary untracked paths before tagging.'
}
$MoeRailUnexpectedPrimaryUntracked = @(
    $MoeRailPrimaryUntracked | Where-Object { $_ -notin $MoeRailAllowedPrimaryUntracked }
)
if ($MoeRailUnexpectedPrimaryUntracked.Count -ne 0) {
    $MoeRailUnexpectedPrimaryUntracked
    throw 'Unexpected primary untracked paths appeared after integrated verification.'
}
git -C $MoeRailPrimary show-ref --verify --quiet refs/tags/prototype-m2
$MoeRailTagExit = $LASTEXITCODE
if ($MoeRailTagExit -eq 0) {
    throw 'prototype-m2 already exists; inspect it before tagging.'
} elseif ($MoeRailTagExit -ne 1) {
    throw 'Failed to inspect prototype-m2 immediately before tagging.'
}
git -C $MoeRailPrimary tag -a prototype-m2 $MoeRailAcceptedCandidate -m "Prototype milestone 2: session shell"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to create the prototype-m2 annotated tag.'
}
$MoeRailTaggedCommitOutput = @(git -C $MoeRailPrimary rev-list -n 1 prototype-m2)
$MoeRailTaggedCommitExit = $LASTEXITCODE
$MoeRailTaggedCommit = ($MoeRailTaggedCommitOutput -join "`n").Trim()
$MoeRailTagTypeOutput = @(git -C $MoeRailPrimary cat-file -t prototype-m2)
$MoeRailTagTypeExit = $LASTEXITCODE
$MoeRailTagType = ($MoeRailTagTypeOutput -join "`n").Trim()
if ($MoeRailTaggedCommitExit -ne 0 -or $MoeRailTagTypeExit -ne 0 -or
    $MoeRailTaggedCommit -ne $MoeRailAcceptedCandidate -or $MoeRailTagType -ne 'tag') {
    throw 'prototype-m2 does not identify the verified integrated commit.'
}
~~~

Do not merge or target `Development`. Do not delete the feature or candidate worktree/branch until the user accepts the integrated verification evidence. Never reset, normalize, or absorb the primary worktree's user-owned changes.
