# Prototype Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

> **Session boundary:** This document is finalized in a strategy session. Do not create implementation branches or worktrees, modify Godot source, or create implementation commits, merges, or tags while reviewing this plan. Execute it only in a new development session after the user explicitly starts implementation.

**Goal:** Establish the tracked, deterministic, testable Godot 4.7.1 foundation for the first playable prototype milestone on proto/00-foundation.

**Architecture:** A minimal PrototypeApp scene composes validated Resource-based balance data, an explicit SessionStartConfig, and a seeded SessionRng. A native GDScript SceneTree test runner validates pure scripts and scene loading without third-party test plugins. Repository and project settings make the Windows PC, 16:9, mouse-only target reproducible while keeping generated files out of Git.

**Tech Stack:** Godot 4.7.1, GDScript, Godot Resource files, PowerShell, Git

## Global Constraints

- Create Prototyping from the current main baseline. Do not branch it from Development.
- Implement this plan on proto/00-foundation, created from Prototyping.
- At the start of the development session, invoke superpowers:using-git-worktrees and execute all implementation in an isolated worktree. Worktree and branch setup are execution preconditions, not actions for the strategy session.
- Never merge Prototyping into Development.
- Target Windows PC, a 1280x720 logical viewport, 16:9, and mouse-only input.
- Keep Forward Plus and the current D3D12 Windows driver for this milestone; renderer evaluation is outside foundation scope.
- Add no third-party Godot add-ons or test plugins.
- Keep the existing local godot_mcp add-on in the primary workspace only. Do not copy, track, or activate it in the isolated prototype project.
- Use the verified Godot binary at D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe.
- Do not modify C:\Users\noisy\bin\godot.cmd; it points to a missing Godot 4.5.1 path.
- Write all agent-facing Markdown in English and all user-facing briefings in Korean.
- Use primitive placeholder presentation only. Custom art and final audio remain outside this milestone.
- Preserve user-owned untracked files. Never force checkout, clean, or reset the workspace.
- Treat repository ignore files and generated project-setting serialization as approved configuration-file exceptions to strict red-first TDD. Cover them with observable behavior checks: git check-ignore, project-setting assertions, two-run hash equality, and final diff verification.
- Treat Godot 4.7.1 `.gd.uid` sidecars as tracked source metadata. Every tracked GDScript must have exactly one tracked sidecar, and no orphan sidecar may remain.
- Use explicit preload constants for cross-script static annotations so the public contracts remain typed during direct execution from a fresh tree without a preparatory editor import.

---

## File Map

- Create .gitignore: repository-local Visual Companion, build, and log exclusions
- Modify godot-project-moe-rail-way/.gitignore: Godot cache and local prototype output exclusions
- Track godot-project-moe-rail-way/.editorconfig: UTF-8 editor baseline
- Track godot-project-moe-rail-way/.gitattributes: LF normalization
- Track godot-project-moe-rail-way/icon.svg: existing temporary project icon
- Track godot-project-moe-rail-way/icon.svg.import: existing Godot import settings
- Modify godot-project-moe-rail-way/project.godot: reproducible application, viewport, main scene, and mouse action settings
- Create godot-project-moe-rail-way/src/app/prototype_app.gd: composition root and startup validation
- Create godot-project-moe-rail-way/src/app/prototype_app.tscn: minimal bootable placeholder scene
- Create godot-project-moe-rail-way/src/config/prototype_balance.gd: prototype balance Resource schema
- Create godot-project-moe-rail-way/src/config/prototype_config_validator.gd: startup configuration validation
- Create godot-project-moe-rail-way/src/domain/session/session_start_config.gd: explicit immutable-by-convention session input
- Create godot-project-moe-rail-way/src/domain/random/session_rng.gd: deterministic session-owned random stream
- Create godot-project-moe-rail-way/data/prototype_balance.tres: valid default balance data
- Create godot-project-moe-rail-way/tools/configure_project.gd: idempotent project-settings writer
- Create godot-project-moe-rail-way/tests/support/prototype_test.gd: lightweight assertion support
- Create godot-project-moe-rail-way/tests/run_all.gd: native headless test entry point
- Create godot-project-moe-rail-way/tests/smoke/test_project_boot.gd: main-scene load smoke test
- Create godot-project-moe-rail-way/tests/unit/test_config_validator.gd: valid and invalid PrototypeBalance tests
- Create godot-project-moe-rail-way/tests/unit/test_session_rng.gd: deterministic sequence tests
- Create godot-project-moe-rail-way/tests/unit/test_project_settings.gd: platform, viewport, main-scene, and input tests
- Track godot-project-moe-rail-way/**/*.gd.uid: Godot 4.7.1 identity metadata, with one generated sidecar for each of the 12 GDScripts above

## Shared Interfaces

The public type names below remain declared with `class_name`. At each cross-script annotation site, the implementation uses the corresponding explicitly preloaded script constant (for example, `SessionStartConfigScript`) to preserve the same static contract without depending on a generated global class cache.

PrototypeBalance:

~~~gdscript
class_name PrototypeBalance
extends Resource

@export var session_duration_seconds: float
@export var simulation_ticks_per_second: int

func create_session_start_config(seed_value: int) -> SessionStartConfig
~~~

PrototypeConfigValidator:

~~~gdscript
class_name PrototypeConfigValidator
extends RefCounted

static func validate(balance: PrototypeBalance) -> PackedStringArray
~~~

SessionStartConfig:

~~~gdscript
class_name SessionStartConfig
extends RefCounted

var seed: int
var session_duration_seconds: float
var simulation_ticks_per_second: int
~~~

SessionRng:

~~~gdscript
class_name SessionRng
extends RefCounted

func _init(seed_value: int) -> void
func next_u32() -> int
func next_unit_float() -> float
~~~

Prototype test suites:

~~~gdscript
func run() -> PackedStringArray
~~~

---

## Development Session Preflight (Controller Only)

Do not run this preflight in the strategy session. In the separate development session, the controller performs it before dispatching Task 1. Invoke superpowers:using-git-worktrees first, then use the following verified project-specific boundary.

Verify the primary workspace without changing it:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailCurrentBranch = git -C $MoeRailPrimary branch --show-current
if ($LASTEXITCODE -ne 0 -or $MoeRailCurrentBranch.Trim() -ne 'main') {
    throw "The primary workspace must be on main."
}
$MoeRailCurrentBranch

$MoeRailTrackedChanges = git -C $MoeRailPrimary status --short --untracked-files=no
if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect tracked primary-workspace changes."
}
if ($MoeRailTrackedChanges) {
    $MoeRailTrackedChanges
    throw "Tracked changes must be resolved before creating Prototyping."
}

git -C $MoeRailPrimary status --short --untracked-files=all
git -C $MoeRailPrimary log -1 --oneline
git -C $MoeRailPrimary show-ref --verify --quiet refs/heads/Prototyping
if ($LASTEXITCODE -eq 0) {
    throw "Prototyping already exists; inspect it before executing this plan."
} elseif ($LASTEXITCODE -ne 1) {
    throw "Failed to inspect the Prototyping branch state."
}
~~~

Expected:

- Current branch is main.
- The Godot scaffold and .superpowers may appear as untracked.
- Prototyping does not exist.
- No tracked changes are present, so the committed English plan is included in the branch baseline.

Create the prototype integration branch and isolated feature worktree:

~~~powershell
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailWorktreeRoot = 'D:\godot\MoeRailWay-worktrees'
$MoeRailWorktree = Join-Path $MoeRailWorktreeRoot 'proto-00-foundation'
if (Test-Path -LiteralPath $MoeRailWorktree) {
    throw "The planned worktree path already exists; inspect it before continuing."
}

git -C $MoeRailPrimary branch Prototyping main
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create Prototyping from main."
}

New-Item -ItemType Directory -Path $MoeRailWorktreeRoot -Force | Out-Null
git -C $MoeRailPrimary worktree add -b proto/00-foundation $MoeRailWorktree Prototyping
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create the isolated proto/00-foundation worktree."
}

git -C $MoeRailWorktree branch --show-current
git -C $MoeRailWorktree merge-base --is-ancestor main Prototyping
if ($LASTEXITCODE -ne 0) {
    throw "Prototyping is not based on main."
}
~~~

Expected: the isolated worktree is created outside the primary repository directory, its current branch prints proto/00-foundation, and the ancestry check exits 0.

Copy only the existing source scaffold into the isolated worktree. Do not copy the generated .godot directory:

~~~powershell
$MoeRailWorktree = 'D:\godot\MoeRailWay-worktrees\proto-00-foundation'
$MoeRailSourceProject = 'D:\godot\MoeRailWay\godot-project-moe-rail-way'
$MoeRailTargetProject = Join-Path $MoeRailWorktree 'godot-project-moe-rail-way'
New-Item -ItemType Directory -Path $MoeRailTargetProject -Force | Out-Null

$MoeRailScaffoldFiles = @(
    '.editorconfig',
    '.gitattributes',
    '.gitignore',
    'icon.svg',
    'icon.svg.import',
    'project.godot'
)
foreach ($MoeRailScaffoldFile in $MoeRailScaffoldFiles) {
    $MoeRailScaffoldSource = Join-Path $MoeRailSourceProject $MoeRailScaffoldFile
    if (-not (Test-Path -LiteralPath $MoeRailScaffoldSource)) {
        throw "Missing scaffold source file: $MoeRailScaffoldSource"
    }
    Copy-Item -LiteralPath $MoeRailScaffoldSource -Destination $MoeRailTargetProject -ErrorAction Stop
}
foreach ($MoeRailScaffoldFile in $MoeRailScaffoldFiles) {
    $MoeRailCopiedFile = Join-Path $MoeRailTargetProject $MoeRailScaffoldFile
    if (-not (Test-Path -LiteralPath $MoeRailCopiedFile -PathType Leaf)) {
        throw "Scaffold copy verification failed: $MoeRailCopiedFile"
    }
}
if (Test-Path -LiteralPath (Join-Path $MoeRailTargetProject '.godot')) {
    throw "Generated .godot state must not be copied into the worktree."
}

git -C $MoeRailWorktree status --short --untracked-files=all
~~~

Expected: the six explicit scaffold source files are visible as untracked, while no .godot cache content is present. Initialize the subagent-driven-development workspace and ledger with D:\godot\MoeRailWay-worktrees\proto-00-foundation as the explicit working directory, then dispatch Task 1 with that same working directory. The local .superpowers SDD workspace may appear as untracked until Task 1 installs the root ignore rule. Do not rely on PowerShell location or variables persisting across tool calls.

---

### Task 1: Establish Repository Hygiene in the Isolated Prototype Worktree

**Files:**

- Create: .gitignore
- Modify: godot-project-moe-rail-way/.gitignore
- Modify: godot-project-moe-rail-way/project.godot

**Interfaces:**

- Consumes: the preflight-created proto/00-foundation worktree and copied source scaffold
- Produces: deterministic repository and Godot-project ignore rules; a plugin-free tracked project baseline

- [ ] **Step 1: Verify the isolated feature boundary without changing it**

Run:

~~~powershell
git branch --show-current
git status --short --untracked-files=all
git merge-base --is-ancestor main Prototyping
if ($LASTEXITCODE -ne 0) {
    throw "Prototyping is not based on main."
}
~~~

Expected:

- Current branch is proto/00-foundation.
- The ancestry check exits 0.
- The six copied Godot source scaffold files are untracked and visible.
- The local .superpowers SDD workspace may also appear as untracked at this point.
- No .godot cache content is present.

- [ ] **Step 2: Add ignore rules and remove local plug-in activation**

Create .gitignore with:

~~~gitignore
# Local Visual Companion state
.superpowers/

# Local prototype output
builds/
logs/
*.log
~~~

Replace godot-project-moe-rail-way/.gitignore with:

~~~gitignore
# Godot 4+ generated state
.godot/
/android/

# Local development tooling
/addons/godot_mcp/

# Local prototype output
builds/
exports/
logs/
~~~

The copied project.godot contains a local editor plug-in reference whose add-on source is intentionally not copied. Use apply_patch on the isolated worktree copy of godot-project-moe-rail-way/project.godot to remove this complete block:

~~~ini
[editor_plugins]

enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg")
~~~

Do not modify the primary workspace copy of project.godot or delete the primary workspace add-on.

- [ ] **Step 3: Verify generated state is ignored and source remains visible**

Run:

~~~powershell
$MoeRailIgnoreChecks = @(
    '.superpowers/brainstorm',
    'godot-project-moe-rail-way/.godot/uid_cache.bin',
    'godot-project-moe-rail-way/addons/godot_mcp/plugin.cfg'
)
foreach ($MoeRailIgnoredPath in $MoeRailIgnoreChecks) {
    git check-ignore -v -- $MoeRailIgnoredPath
    if ($LASTEXITCODE -ne 0) {
        throw "Expected ignored path is not covered: $MoeRailIgnoredPath"
    }
}
$MoeRailPluginReference = Select-String -LiteralPath 'godot-project-moe-rail-way/project.godot' -Pattern 'editor_plugins|godot_mcp'
if ($MoeRailPluginReference) {
    $MoeRailPluginReference
    throw "The isolated prototype project still activates local Godot MCP tooling."
}
git status --short --untracked-files=all
~~~

Expected:

- All three check-ignore commands identify the new rules.
- .superpowers, the project .godot directory, and local godot_mcp add-on are absent from normal status.
- No editor plug-in activation remains in the isolated project.godot.
- The intended Godot source scaffold remains untracked and visible.

- [ ] **Step 4: Commit the hygiene boundary**

Run:

~~~powershell
git add -- '.gitignore' 'godot-project-moe-rail-way/.gitignore' 'godot-project-moe-rail-way/project.godot'
if ($LASTEXITCODE -ne 0) {
    throw "Failed to stage the repository-hygiene files."
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "Repository-hygiene staged diff check failed."
}
git commit -m "chore: define prototype repository hygiene"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to commit the repository-hygiene boundary."
}
~~~

Expected: one configuration-only commit containing the two ignore files and the plugin-free project baseline.

---

### Task 2: Add the Native Test Harness and Bootable Placeholder Scene

**Files:**

- Create: godot-project-moe-rail-way/tests/support/prototype_test.gd
- Create: godot-project-moe-rail-way/tests/run_all.gd
- Create: godot-project-moe-rail-way/tests/smoke/test_project_boot.gd
- Create: godot-project-moe-rail-way/src/app/prototype_app.gd
- Create: godot-project-moe-rail-way/src/app/prototype_app.tscn
- Track: godot-project-moe-rail-way/.editorconfig
- Track: godot-project-moe-rail-way/.gitattributes
- Track: godot-project-moe-rail-way/icon.svg
- Track: godot-project-moe-rail-way/icon.svg.import

**Interfaces:**

- Consumes: verified Godot 4.7.1 console binary; ignored .godot cache; plugin-free tracked project.godot
- Produces: res://tests/run_all.gd headless test entry point; res://src/app/prototype_app.tscn boot scene

- [ ] **Step 1: Create the assertion support**

Create godot-project-moe-rail-way/tests/support/prototype_test.gd:

~~~gdscript
extends RefCounted

var _failures := PackedStringArray()


func assert_true(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func assert_false(condition: bool, message: String) -> void:
    assert_true(not condition, message)


func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        _failures.append(
            "%s | expected=%s actual=%s" % [message, str(expected), str(actual)]
        )


func assert_not_null(value: Variant, message: String) -> void:
    assert_true(value != null, message)


func finish() -> PackedStringArray:
    return _failures.duplicate()
~~~

- [ ] **Step 2: Write the boot-scene test before the scene exists**

Create godot-project-moe-rail-way/tests/smoke/test_project_boot.gd:

~~~gdscript
extends "res://tests/support/prototype_test.gd"


func run() -> PackedStringArray:
    var packed_scene := load("res://src/app/prototype_app.tscn") as PackedScene
    assert_not_null(packed_scene, "PrototypeApp scene must load")

    if packed_scene != null:
        var instance := packed_scene.instantiate()
        assert_not_null(instance, "PrototypeApp scene must instantiate")
        if instance != null:
            instance.free()

    return finish()
~~~

Create godot-project-moe-rail-way/tests/run_all.gd:

~~~gdscript
extends SceneTree

const SUITES = [
    preload("res://tests/smoke/test_project_boot.gd"),
]


func _initialize() -> void:
    var failures := PackedStringArray()

    for suite_script in SUITES:
        var suite = suite_script.new()
        var suite_failures: PackedStringArray = suite.run()
        for failure in suite_failures:
            failures.append("%s: %s" % [suite_script.resource_path, failure])

    if failures.is_empty():
        print("PASS: %d prototype test suite(s)" % SUITES.size())
        quit(0)
        return

    for failure in failures:
        push_error(failure)
    print("FAIL: %d assertion(s)" % failures.size())
    quit(1)
~~~

- [ ] **Step 3: Run the test and verify the red state**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $MoeRailGodotExe)) {
    throw "Verified Godot 4.7.1 binary is missing."
}
$MoeRailVersionOutput = & $MoeRailGodotExe --version 2>&1
$MoeRailVersionExit = $LASTEXITCODE
$MoeRailVersionOutput
$MoeRailVersion = ($MoeRailVersionOutput -join "`n").Trim()
if ($MoeRailVersionExit -ne 0 -or $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected Godot version: $MoeRailVersion"
}
$MoeRailRedOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailRedExit = $LASTEXITCODE
$MoeRailRedOutput
if ($MoeRailRedExit -eq 0 -or -not ($MoeRailRedOutput -match 'PrototypeApp scene must load')) {
    throw "Expected missing-scene red state was not observed."
}
~~~

Expected: the exact Godot version is 4.7.1.stable.official.a13da4feb, then the test exits nonzero and says PrototypeApp scene must load.

- [ ] **Step 4: Create the minimal application composition root**

Create godot-project-moe-rail-way/src/app/prototype_app.gd:

~~~gdscript
extends Node


func _ready() -> void:
    print("Moe Rail Way prototype foundation ready")
~~~

Create godot-project-moe-rail-way/src/app/prototype_app.tscn:

~~~ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/app/prototype_app.gd" id="1_app"]

[node name="PrototypeApp" type="Node"]
script = ExtResource("1_app")

[node name="Backdrop" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.949, 0.929, 0.867, 1)

[node name="FoundationLabel" type="Label" parent="Backdrop"]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -180.0
offset_top = -28.0
offset_right = 180.0
offset_bottom = 28.0
grow_horizontal = 2
grow_vertical = 2
text = "Moe Rail Way Prototype\nFoundation"
horizontal_alignment = 1
vertical_alignment = 1
~~~

- [ ] **Step 5: Run the boot test and verify the green state**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailTestOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestOutput
if ($MoeRailTestExit -ne 0 -or -not ($MoeRailTestOutput -match 'PASS: 1 prototype test suite\(s\)')) {
    throw "Prototype test runner did not pass exactly 1 suite."
}

$MoeRailBootArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--scene', 'res://src/app/prototype_app.tscn', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailBootArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0 -or -not ($BootOutput -match 'Moe Rail Way prototype foundation ready')) {
    throw "PrototypeApp did not complete a real headless boot."
}
~~~

Expected: PASS: 1 prototype test suite(s), the explicit scene boots headlessly and reports readiness, and both commands exit 0.

- [ ] **Step 6: Commit the tracked scaffold and boot slice**

Run:

~~~powershell
git add -- 'godot-project-moe-rail-way/.editorconfig' 'godot-project-moe-rail-way/.gitattributes' 'godot-project-moe-rail-way/icon.svg' 'godot-project-moe-rail-way/icon.svg.import' 'godot-project-moe-rail-way/src/app/prototype_app.gd' 'godot-project-moe-rail-way/src/app/prototype_app.tscn' 'godot-project-moe-rail-way/tests/support/prototype_test.gd' 'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' 'godot-project-moe-rail-way/tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Failed to stage the application-bootstrap files."
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "Application-bootstrap staged diff check failed."
}
git commit -m "feat: bootstrap prototype application"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to commit the application bootstrap."
}
~~~

Expected: generated .godot content is not staged.

---

### Task 3: Add Validated Balance Data and SessionStartConfig

**Files:**

- Create: godot-project-moe-rail-way/src/domain/session/session_start_config.gd
- Create: godot-project-moe-rail-way/src/config/prototype_balance.gd
- Create: godot-project-moe-rail-way/src/config/prototype_config_validator.gd
- Create: godot-project-moe-rail-way/data/prototype_balance.tres
- Create: godot-project-moe-rail-way/tests/unit/test_config_validator.gd
- Modify: godot-project-moe-rail-way/tests/run_all.gd
- Modify: godot-project-moe-rail-way/src/app/prototype_app.gd
- Modify: godot-project-moe-rail-way/src/app/prototype_app.tscn
- Modify: godot-project-moe-rail-way/tests/smoke/test_project_boot.gd

**Interfaces:**

- Consumes: PrototypeApp composition root and native test runner
- Produces: PrototypeBalance.create_session_start_config(seed_value); PrototypeConfigValidator.validate(balance)

- [ ] **Step 1: Write the configuration tests before implementation**

Create godot-project-moe-rail-way/tests/unit/test_config_validator.gd:

~~~gdscript
extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const Validator = preload("res://src/config/prototype_config_validator.gd")


func run() -> PackedStringArray:
    var valid_balance := PrototypeBalanceScript.new()
    assert_equal(
        Validator.validate(valid_balance).size(),
        0,
        "Default balance must be valid"
    )

    var invalid_balance := PrototypeBalanceScript.new()
    invalid_balance.session_duration_seconds = 0.0
    invalid_balance.simulation_ticks_per_second = 0
    var errors: PackedStringArray = Validator.validate(invalid_balance)
    assert_equal(errors.size(), 2, "Both invalid fields must be reported")
    var duration_error_found := false
    var tick_rate_error_found := false
    for error_message in errors:
        duration_error_found = (
            error_message.contains("session_duration_seconds")
            or duration_error_found
        )
        tick_rate_error_found = (
            error_message.contains("simulation_ticks_per_second")
            or tick_rate_error_found
        )
    assert_true(duration_error_found, "Duration error must name the field")
    assert_true(tick_rate_error_found, "Tick-rate error must name the field")

    var start_config = valid_balance.create_session_start_config(4242)
    assert_equal(start_config.seed, 4242, "SessionStartConfig must preserve seed")
    assert_equal(
        start_config.session_duration_seconds,
        valid_balance.session_duration_seconds,
        "SessionStartConfig must copy session duration"
    )
    assert_equal(
        start_config.simulation_ticks_per_second,
        valid_balance.simulation_ticks_per_second,
        "SessionStartConfig must copy tick rate"
    )

    return finish()
~~~

Add the new suite to godot-project-moe-rail-way/tests/run_all.gd:

~~~gdscript
const SUITES = [
    preload("res://tests/smoke/test_project_boot.gd"),
    preload("res://tests/unit/test_config_validator.gd"),
]
~~~

- [ ] **Step 2: Run the tests and verify the red state**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailRedOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailRedExit = $LASTEXITCODE
$MoeRailRedOutput
if ($MoeRailRedExit -eq 0 -or -not ($MoeRailRedOutput -match 'res://src/config/prototype_balance.gd')) {
    throw "Expected missing-configuration-script red state was not observed."
}
~~~

Expected: parse or preload failure identifies the missing configuration scripts.

- [ ] **Step 3: Implement SessionStartConfig**

Create godot-project-moe-rail-way/src/domain/session/session_start_config.gd:

~~~gdscript
class_name SessionStartConfig
extends RefCounted

var seed: int
var session_duration_seconds: float
var simulation_ticks_per_second: int


func _init(
    seed_value: int,
    duration_seconds: float,
    ticks_per_second: int
) -> void:
    seed = seed_value
    session_duration_seconds = duration_seconds
    simulation_ticks_per_second = ticks_per_second
~~~

- [ ] **Step 4: Implement PrototypeBalance and its validator**

Create godot-project-moe-rail-way/src/config/prototype_balance.gd:

~~~gdscript
class_name PrototypeBalance
extends Resource

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

@export_range(1.0, 3600.0, 1.0) var session_duration_seconds := 180.0
@export_range(1, 240, 1) var simulation_ticks_per_second := 60


func create_session_start_config(seed_value: int) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        seed_value,
        session_duration_seconds,
        simulation_ticks_per_second
    )
~~~

Create godot-project-moe-rail-way/src/config/prototype_config_validator.gd:

~~~gdscript
class_name PrototypeConfigValidator
extends RefCounted

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")


static func validate(balance: PrototypeBalanceScript) -> PackedStringArray:
    var errors := PackedStringArray()

    if balance == null:
        errors.append("prototype balance resource is required")
        return errors

    if balance.session_duration_seconds <= 0.0:
        errors.append("session_duration_seconds must be greater than 0")

    if balance.simulation_ticks_per_second <= 0:
        errors.append("simulation_ticks_per_second must be greater than 0")

    return errors
~~~

Create godot-project-moe-rail-way/data/prototype_balance.tres:

~~~ini
[gd_resource type="Resource" script_class="PrototypeBalance" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/config/prototype_balance.gd" id="1_balance"]

[resource]
script = ExtResource("1_balance")
session_duration_seconds = 180.0
simulation_ticks_per_second = 60
~~~

- [ ] **Step 5: Wire validated configuration into PrototypeApp**

Replace godot-project-moe-rail-way/src/app/prototype_app.gd with:

~~~gdscript
extends Node

const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

@export var balance: PrototypeBalanceScript
@export var startup_seed := 1

var session_start_config: SessionStartConfigScript


func _ready() -> void:
    var errors := ValidatorScript.validate(balance)
    if not errors.is_empty():
        for error_message in errors:
            push_error(error_message)
        if OS.is_debug_build():
            get_tree().quit(2)
        return

    session_start_config = balance.create_session_start_config(startup_seed)
    print(
        "Moe Rail Way prototype foundation ready | seed=%d ticks=%d" %
        [
            session_start_config.seed,
            session_start_config.simulation_ticks_per_second,
        ]
    )
~~~

Replace godot-project-moe-rail-way/src/app/prototype_app.tscn with:

~~~ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://src/app/prototype_app.gd" id="1_app"]
[ext_resource type="Resource" path="res://data/prototype_balance.tres" id="2_balance"]

[node name="PrototypeApp" type="Node"]
script = ExtResource("1_app")
balance = ExtResource("2_balance")

[node name="Backdrop" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.949, 0.929, 0.867, 1)

[node name="FoundationLabel" type="Label" parent="Backdrop"]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -180.0
offset_top = -28.0
offset_right = 180.0
offset_bottom = 28.0
grow_horizontal = 2
grow_vertical = 2
text = "Moe Rail Way Prototype\nFoundation"
horizontal_alignment = 1
vertical_alignment = 1
~~~

Add this assertion inside the `if instance != null` branch, immediately before `instance.free()`, in godot-project-moe-rail-way/tests/smoke/test_project_boot.gd:

~~~gdscript
            assert_not_null(
                instance.get("balance"),
                "PrototypeApp must receive the default balance Resource"
            )
~~~

- [ ] **Step 6: Run configuration and boot tests**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailTestOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestOutput
if ($MoeRailTestExit -ne 0 -or -not ($MoeRailTestOutput -match 'PASS: 2 prototype test suite\(s\)')) {
    throw "Configuration implementation did not pass exactly 2 suites."
}

$MoeRailBootArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--scene', 'res://src/app/prototype_app.tscn', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailBootArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0 -or -not ($BootOutput -match 'seed=1 ticks=60')) {
    throw "PrototypeApp did not boot with the default seed and tick rate."
}
~~~

Expected: 2 suites pass, and the explicit scene boot reports seed 1 and tick rate 60. A host-only Windows certificate-store warning may appear, but parse errors, script errors, and nonzero exit are failures.

- [ ] **Step 7: Commit validated configuration**

Run:

~~~powershell
git add -- 'godot-project-moe-rail-way/src/domain/session/session_start_config.gd' 'godot-project-moe-rail-way/src/config/prototype_balance.gd' 'godot-project-moe-rail-way/src/config/prototype_config_validator.gd' 'godot-project-moe-rail-way/data/prototype_balance.tres' 'godot-project-moe-rail-way/src/app/prototype_app.gd' 'godot-project-moe-rail-way/src/app/prototype_app.tscn' 'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' 'godot-project-moe-rail-way/tests/unit/test_config_validator.gd' 'godot-project-moe-rail-way/tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Failed to stage the validated-configuration files."
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "Validated-configuration staged diff check failed."
}
git commit -m "feat: add validated prototype session config"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to commit validated prototype session config."
}
~~~

Expected: one focused commit with Resource configuration, validation, integration, and tests.

---

### Task 4: Add the Deterministic Session Random Stream

**Files:**

- Create: godot-project-moe-rail-way/src/domain/random/session_rng.gd
- Create: godot-project-moe-rail-way/tests/unit/test_session_rng.gd
- Modify: godot-project-moe-rail-way/tests/run_all.gd
- Modify: godot-project-moe-rail-way/tests/smoke/test_project_boot.gd
- Modify: godot-project-moe-rail-way/src/app/prototype_app.gd

**Interfaces:**

- Consumes: SessionStartConfig.seed
- Produces: SessionRng.next_u32() and SessionRng.next_unit_float() for later warp generation

- [ ] **Step 1: Write deterministic sequence tests**

Create godot-project-moe-rail-way/tests/unit/test_session_rng.gd:

~~~gdscript
extends "res://tests/support/prototype_test.gd"

const SessionRngScript = preload("res://src/domain/random/session_rng.gd")


func run() -> PackedStringArray:
    var first = SessionRngScript.new(4242)
    var second = SessionRngScript.new(4242)

    for index in range(16):
        assert_equal(
            first.next_u32(),
            second.next_u32(),
            "Matching seeds must match at integer sample %d" % index
        )

    var first_float = SessionRngScript.new(9001)
    var second_float = SessionRngScript.new(9001)
    for index in range(16):
        assert_equal(
            first_float.next_unit_float(),
            second_float.next_unit_float(),
            "Matching seeds must match at float sample %d" % index
        )

    var baseline_sequence := []
    var alternate_sequence := []
    var baseline_rng = SessionRngScript.new(4242)
    var alternate_rng = SessionRngScript.new(4243)
    for index in range(16):
        baseline_sequence.append(baseline_rng.next_u32())
        alternate_sequence.append(alternate_rng.next_u32())
    assert_false(
        baseline_sequence == alternate_sequence,
        "Different seeds must produce different integer sequences"
    )

    return finish()
~~~

Append the RNG suite to godot-project-moe-rail-way/tests/run_all.gd:

~~~gdscript
const SUITES = [
    preload("res://tests/smoke/test_project_boot.gd"),
    preload("res://tests/unit/test_config_validator.gd"),
    preload("res://tests/unit/test_session_rng.gd"),
]
~~~

- [ ] **Step 2: Run the tests and verify the red state**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailRedOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailRedExit = $LASTEXITCODE
$MoeRailRedOutput
if ($MoeRailRedExit -eq 0 -or -not ($MoeRailRedOutput -match 'res://src/domain/random/session_rng.gd')) {
    throw "Expected missing-RNG-script red state was not observed."
}
~~~

Expected: preload failure identifies res://src/domain/random/session_rng.gd.

- [ ] **Step 3: Implement SessionRng**

Create godot-project-moe-rail-way/src/domain/random/session_rng.gd:

~~~gdscript
class_name SessionRng
extends RefCounted

var _rng: RandomNumberGenerator


func _init(seed_value: int) -> void:
    _rng = RandomNumberGenerator.new()
    _rng.seed = seed_value


func next_u32() -> int:
    return _rng.randi()


func next_unit_float() -> float:
    return _rng.randf()
~~~

- [ ] **Step 4: Compose SessionRng from SessionStartConfig**

Replace godot-project-moe-rail-way/src/app/prototype_app.gd with:

~~~gdscript
extends Node

const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")

@export var balance: PrototypeBalanceScript
@export var startup_seed := 1

var session_start_config: SessionStartConfigScript
var session_rng: SessionRngScript


func _ready() -> void:
    var errors := ValidatorScript.validate(balance)
    if not errors.is_empty():
        for error_message in errors:
            push_error(error_message)
        if OS.is_debug_build():
            get_tree().quit(2)
        return

    session_start_config = balance.create_session_start_config(startup_seed)
    session_rng = SessionRngScript.new(session_start_config.seed)
    if is_inside_tree():
        print(
            "Moe Rail Way prototype foundation ready | seed=%d ticks=%d" %
            [
                session_start_config.seed,
                session_start_config.simulation_ticks_per_second,
            ]
        )
~~~

Extend `tests/smoke/test_project_boot.gd` with an application-level composition assertion. Use a typed `PrototypeBalance` test subclass whose factory returns a seed offset from `startup_seed`, invoke `_ready()` while the instance remains outside the tree so the test emits no readiness log, and compare several `session_rng` samples with a `SessionRng` created from `session_start_config.seed`. This must fail if `PrototypeApp` seeds the RNG directly from `startup_seed` instead of the factory-produced session configuration.

- [ ] **Step 5: Run all tests and the boot scene**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailTestOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestOutput
if ($MoeRailTestExit -ne 0 -or -not ($MoeRailTestOutput -match 'PASS: 3 prototype test suite\(s\)')) {
    throw "Deterministic RNG implementation did not pass exactly 3 suites."
}

$MoeRailBootArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--scene', 'res://src/app/prototype_app.tscn', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailBootArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0 -or -not ($BootOutput -match 'seed=1 ticks=60')) {
    throw "PrototypeApp did not compose the configured seed and tick rate."
}
~~~

Expected: 3 suites pass and the app reports seed 1, ticks 60.

- [ ] **Step 6: Commit deterministic random infrastructure**

Run:

~~~powershell
git add -- 'godot-project-moe-rail-way/src/domain/random/session_rng.gd' 'godot-project-moe-rail-way/src/app/prototype_app.gd' 'godot-project-moe-rail-way/tests/unit/test_session_rng.gd' 'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' 'godot-project-moe-rail-way/tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Failed to stage deterministic-RNG files."
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "Deterministic-RNG staged diff check failed."
}
git commit -m "feat: add deterministic session random stream"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to commit deterministic session random stream."
}
~~~

Expected: one focused RNG and composition commit.

---

### Task 5: Make Project Settings Reproducible and Pass the Foundation Gate

**Files:**

- Create: godot-project-moe-rail-way/tools/configure_project.gd
- Create: godot-project-moe-rail-way/tests/unit/test_project_settings.gd
- Modify: godot-project-moe-rail-way/project.godot through the configuration tool
- Modify: godot-project-moe-rail-way/tests/run_all.gd

**Interfaces:**

- Consumes: PrototypeApp scene and verified Godot 4.7.1 CLI
- Produces: main-scene selection, 1280x720 logical viewport, canvas_items expand stretch, and track_draw left-mouse action

- [ ] **Step 1: Write project-setting tests before configuration**

Create godot-project-moe-rail-way/tests/unit/test_project_settings.gd:

~~~gdscript
extends "res://tests/support/prototype_test.gd"


func run() -> PackedStringArray:
    assert_equal(
        ProjectSettings.get_setting("application/config/name"),
        "Moe Rail Way Prototype",
        "Application name must identify the prototype"
    )
    assert_equal(
        ProjectSettings.get_setting("application/run/main_scene"),
        "res://src/app/prototype_app.tscn",
        "PrototypeApp must be the main scene"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/size/viewport_width"),
        1280,
        "Logical viewport width must be 1280"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/size/viewport_height"),
        720,
        "Logical viewport height must be 720"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/stretch/mode"),
        "canvas_items",
        "2D stretch mode must remain canvas_items"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/stretch/aspect"),
        "expand",
        "Aspect mode must remain expand"
    )

    assert_true(InputMap.has_action("track_draw"), "track_draw action must exist")
    var has_left_mouse := false
    for event in InputMap.action_get_events("track_draw"):
        if event is InputEventMouseButton:
            has_left_mouse = (
                event.button_index == MOUSE_BUTTON_LEFT
                or has_left_mouse
            )
    assert_true(has_left_mouse, "track_draw must bind the left mouse button")

    return finish()
~~~

Append the settings suite to godot-project-moe-rail-way/tests/run_all.gd:

~~~gdscript
const SUITES = [
    preload("res://tests/smoke/test_project_boot.gd"),
    preload("res://tests/unit/test_config_validator.gd"),
    preload("res://tests/unit/test_session_rng.gd"),
    preload("res://tests/unit/test_project_settings.gd"),
]
~~~

- [ ] **Step 2: Run the tests and verify the red state**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailRedOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailRedExit = $LASTEXITCODE
$MoeRailRedOutput
if ($MoeRailRedExit -eq 0) {
    throw "Project-setting tests unexpectedly passed before configuration."
}
$MoeRailRequiredSettingFailures = @(
    'Application name must identify the prototype',
    'PrototypeApp must be the main scene',
    'Logical viewport width must be 1280',
    'Logical viewport height must be 720',
    'track_draw action must exist'
)
foreach ($MoeRailExpectedFailure in $MoeRailRequiredSettingFailures) {
    if (-not ($MoeRailRedOutput -match [regex]::Escape($MoeRailExpectedFailure))) {
        throw "Expected project-setting red signal is missing: $MoeRailExpectedFailure"
    }
}
~~~

Expected: failures identify the application name, main scene, viewport size, and missing track_draw action.

- [ ] **Step 3: Create the idempotent project configuration tool**

Create godot-project-moe-rail-way/tools/configure_project.gd:

~~~gdscript
extends SceneTree


func _initialize() -> void:
    ProjectSettings.set_setting(
        "application/config/name",
        "Moe Rail Way Prototype"
    )
    ProjectSettings.set_setting(
        "application/run/main_scene",
        "res://src/app/prototype_app.tscn"
    )
    ProjectSettings.set_setting(
        "display/window/size/viewport_width",
        1280
    )
    ProjectSettings.set_setting(
        "display/window/size/viewport_height",
        720
    )
    ProjectSettings.set_setting(
        "display/window/stretch/mode",
        "canvas_items"
    )
    ProjectSettings.set_setting(
        "display/window/stretch/aspect",
        "expand"
    )

    var left_click := InputEventMouseButton.new()
    left_click.button_index = MOUSE_BUTTON_LEFT
    ProjectSettings.set_setting(
        "input/track_draw",
        {
            "deadzone": 0.5,
            "events": [left_click],
        }
    )

    var save_result := ProjectSettings.save()
    if save_result != OK:
        push_error(
            "Failed to save project settings: %s" %
            error_string(save_result)
        )
        quit(1)
        return

    print("Project settings configured")
    quit(0)
~~~

- [ ] **Step 4: Apply project settings twice to prove idempotence**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailConfigureArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--script', 'res://tools/configure_project.gd')
$MoeRailFirstConfigureOutput = & $MoeRailGodotExe @MoeRailConfigureArgs 2>&1
$MoeRailFirstConfigureExit = $LASTEXITCODE
$MoeRailFirstConfigureOutput
if ($MoeRailFirstConfigureExit -ne 0 -or -not ($MoeRailFirstConfigureOutput -match 'Project settings configured')) {
    throw "First project configuration run did not report success."
}

$FirstHash = (Get-FileHash -LiteralPath 'godot-project-moe-rail-way\project.godot' -ErrorAction Stop).Hash
$MoeRailSecondConfigureOutput = & $MoeRailGodotExe @MoeRailConfigureArgs 2>&1
$MoeRailSecondConfigureExit = $LASTEXITCODE
$MoeRailSecondConfigureOutput
if ($MoeRailSecondConfigureExit -ne 0 -or -not ($MoeRailSecondConfigureOutput -match 'Project settings configured')) {
    throw "Second project configuration run did not report success."
}
$SecondHash = (Get-FileHash -LiteralPath 'godot-project-moe-rail-way\project.godot' -ErrorAction Stop).Hash
if ($FirstHash -ne $SecondHash) {
    throw "Project configuration is not idempotent."
}
~~~

Expected: both runs print Project settings configured and both file hashes match.

- [ ] **Step 5: Run the complete automated and boot verification**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailVersionOutput = & $MoeRailGodotExe --version 2>&1
$MoeRailVersionExit = $LASTEXITCODE
$MoeRailVersionOutput
$MoeRailVersion = ($MoeRailVersionOutput -join "`n").Trim()
if ($MoeRailVersionExit -ne 0 -or $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected Godot version: $MoeRailVersion"
}

$MoeRailTestOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestOutput
if ($MoeRailTestExit -ne 0 -or -not ($MoeRailTestOutput -match 'PASS: 4 prototype test suite\(s\)')) {
    throw "Foundation test runner did not pass exactly 4 suites."
}

$MoeRailMainArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailMainArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0 -or -not ($BootOutput -match 'seed=1 ticks=60')) {
    throw "Configured main scene did not boot with the default seed and tick rate."
}
~~~

Expected:

- Version is exactly 4.7.1.stable.official.a13da4feb.
- All 4 suites pass.
- The project boots its configured main scene with seed 1 and tick rate 60.

- [ ] **Step 6: Verify repository hygiene and diff quality**

Run:

~~~powershell
$MoeRailTask5Files = @(
    'godot-project-moe-rail-way/tools/configure_project.gd',
    'godot-project-moe-rail-way/tests/unit/test_project_settings.gd',
    'godot-project-moe-rail-way/tests/run_all.gd',
    'godot-project-moe-rail-way/project.godot'
)
git add -- $MoeRailTask5Files
if ($LASTEXITCODE -ne 0) {
    throw "Failed to stage Task 5 files for complete diff verification."
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "Task 5 staged diff check failed."
}
git diff --check
if ($LASTEXITCODE -ne 0) {
    throw "Unexpected unstaged working-tree diff check failed."
}

$TrackedGenerated = git ls-files | Select-String -Pattern '(^|/)(\.superpowers|\.godot|logs|builds|exports|android)/|(^|/)addons/godot_mcp/|\.log$'
if ($TrackedGenerated) {
    $TrackedGenerated
    throw "Generated files are tracked."
}

$MoeRailPluginReference = Select-String -LiteralPath 'godot-project-moe-rail-way/project.godot' -Pattern 'editor_plugins|godot_mcp'
if ($MoeRailPluginReference) {
    $MoeRailPluginReference
    throw "The final prototype project activates local Godot MCP tooling."
}

$MoeRailStagedFiles = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect staged Task 5 files."
}
$MoeRailUnexpectedStaged = @($MoeRailStagedFiles | Where-Object { $_ -notin $MoeRailTask5Files })
$MoeRailMissingStaged = @($MoeRailTask5Files | Where-Object { $_ -notin $MoeRailStagedFiles })
if ($MoeRailUnexpectedStaged -or $MoeRailMissingStaged) {
    $MoeRailUnexpectedStaged
    $MoeRailMissingStaged
    throw "The staged Task 5 file set does not match the plan."
}

git status --short --untracked-files=all
~~~

Expected: no whitespace errors in staged or unstaged changes, no generated or local-tool paths tracked, no local editor plug-in activation, and exactly the four Task 5 files are staged.

- [ ] **Step 7: Commit reproducible settings**

Run:

~~~powershell
git diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw "Final Task 5 staged diff check failed."
}
git commit -m "chore: configure prototype platform baseline"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to commit the prototype platform baseline."
}
~~~

Expected: one focused settings, test, and tool commit.

- [ ] **Step 8: Run fresh post-commit verification**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailTestOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
$MoeRailTestExit = $LASTEXITCODE
$MoeRailTestOutput
if ($MoeRailTestExit -ne 0 -or -not ($MoeRailTestOutput -match 'PASS: 4 prototype test suite\(s\)')) {
    throw "Post-commit verification did not pass exactly 4 suites."
}

$MoeRailMainArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailMainArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0 -or -not ($BootOutput -match 'seed=1 ticks=60')) {
    throw "Post-commit boot verification failed."
}

$MoeRailTrackedStatus = git status --short --untracked-files=no
if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect the post-commit tracked status."
}
if ($MoeRailTrackedStatus) {
    $MoeRailTrackedStatus
    throw "Tracked working state is not clean after the Task 5 commit."
}
git status --short --untracked-files=all
~~~

Expected: 4 suites pass, main scene boots with seed 1 and ticks 60, and tracked working state is clean.

- [ ] **Step 9: Verify tracked script identities and a fresh tracked checkout**

After all Foundation fixes and `.gd.uid` sidecars are committed, run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailTrackedScripts = @(
    git ls-files |
        Where-Object {
            $_.StartsWith('godot-project-moe-rail-way/') -and
            $_.EndsWith('.gd')
        }
)
$MoeRailTrackedSidecars = @(
    git ls-files |
        Where-Object {
            $_.StartsWith('godot-project-moe-rail-way/') -and
            $_.EndsWith('.gd.uid')
        }
)
$MoeRailMissingSidecars = @(
    $MoeRailTrackedScripts |
        Where-Object { "$_.uid" -notin $MoeRailTrackedSidecars }
)
$MoeRailOrphanSidecars = @(
    $MoeRailTrackedSidecars |
        Where-Object { $_.Substring(0, $_.Length - 4) -notin $MoeRailTrackedScripts }
)
if (
    $MoeRailTrackedScripts.Count -ne 12 -or
    $MoeRailTrackedSidecars.Count -ne 12 -or
    $MoeRailMissingSidecars -or
    $MoeRailOrphanSidecars
) {
    $MoeRailMissingSidecars
    $MoeRailOrphanSidecars
    throw "Tracked GDScripts and UID sidecars are not one-to-one."
}

$MoeRailUidValues = @(
    $MoeRailTrackedSidecars |
        ForEach-Object { (Get-Content -Raw -LiteralPath $_).Trim() }
)
if (
    @($MoeRailUidValues | Where-Object { $_ -notmatch '^uid://[a-z0-9]+$' }) -or
    @($MoeRailUidValues | Sort-Object -Unique).Count -ne $MoeRailUidValues.Count
) {
    throw "Tracked GDScript UID values must be valid and unique."
}

$MoeRailEditorOutput = & $MoeRailGodotExe --headless --editor --path 'godot-project-moe-rail-way' --quit 2>&1
$MoeRailEditorExit = $LASTEXITCODE
$MoeRailEditorOutput
if ($MoeRailEditorExit -ne 0) {
    throw "Second editor/import pass failed."
}
$MoeRailUidChanges = @(git status --short --untracked-files=all -- '*.gd.uid')
if ($MoeRailUidChanges) {
    $MoeRailUidChanges
    throw "The committed GDScript UID set changed after a second editor/import pass."
}

$MoeRailFreshRoot = Join-Path (
    Split-Path -Parent (Get-Location)
) ("proto-00-foundation-verify-" + [guid]::NewGuid().ToString('N'))
git worktree add --detach $MoeRailFreshRoot HEAD
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create the fresh detached verification checkout."
}
try {
    if (Test-Path -LiteralPath (Join-Path $MoeRailFreshRoot 'godot-project-moe-rail-way\.godot')) {
        throw "Fresh tracked checkout unexpectedly contains a .godot cache."
    }

    Push-Location $MoeRailFreshRoot
    try {
        $MoeRailFreshTestOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd' 2>&1
        $MoeRailFreshTestExit = $LASTEXITCODE
        $MoeRailFreshTestOutput
        if ($MoeRailFreshTestExit -ne 0 -or -not ($MoeRailFreshTestOutput -match 'PASS: 4 prototype test suite\(s\)')) {
            throw "Fresh tracked checkout did not pass exactly 4 suites."
        }

        $MoeRailFreshBootOutput = & $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --quit-after 2 2>&1
        $MoeRailFreshBootExit = $LASTEXITCODE
        $MoeRailFreshBootOutput
        if ($MoeRailFreshBootExit -ne 0 -or -not ($MoeRailFreshBootOutput -match 'seed=1 ticks=60')) {
            throw "Fresh tracked checkout main boot failed."
        }

        $MoeRailConfigureArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--script', 'res://tools/configure_project.gd')
        & $MoeRailGodotExe @MoeRailConfigureArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Fresh tracked checkout first configuration run failed."
        }
        $MoeRailFirstHash = (Get-FileHash -LiteralPath 'godot-project-moe-rail-way\project.godot' -Algorithm SHA256).Hash
        & $MoeRailGodotExe @MoeRailConfigureArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Fresh tracked checkout second configuration run failed."
        }
        $MoeRailSecondHash = (Get-FileHash -LiteralPath 'godot-project-moe-rail-way\project.godot' -Algorithm SHA256).Hash
        if ($MoeRailFirstHash -ne $MoeRailSecondHash) {
            throw "Fresh tracked checkout project configuration is not idempotent."
        }

        $MoeRailFreshStatus = @(git status --short --untracked-files=all)
        if ($MoeRailFreshStatus) {
            $MoeRailFreshStatus
            throw "Fresh tracked checkout is not clean after normal Foundation verification."
        }
    } finally {
        Pop-Location
    }
} finally {
    git worktree remove --force $MoeRailFreshRoot
}
~~~

Expected: exactly 12 tracked GDScripts have 12 valid, unique, tracked sidecars; a second pinned editor/import pass leaves the UID set unchanged; the fresh detached checkout starts without `.godot`, directly passes 4 suites and main boot, produces identical settings hashes, and remains fully clean.

- [ ] **Step 10: Hand off the completed feature branch for review**

Invoke superpowers:verification-before-completion, then superpowers:requesting-code-review. After review passes, invoke superpowers:finishing-a-development-branch.

The approved integration action is:

1. Squash proto/00-foundation into Prototyping.
2. Run the complete test and boot verification on Prototyping.
3. Create tag prototype-m1 on the verified integration commit.
4. Do not merge or target Development.

Do not perform the squash merge or tag before review evidence is accepted.
