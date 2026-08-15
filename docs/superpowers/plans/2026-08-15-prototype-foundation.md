# Prototype Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Establish the tracked, deterministic, testable Godot 4.7.1 foundation for the first playable prototype milestone on proto/00-foundation.

**Architecture:** A minimal PrototypeApp scene composes validated Resource-based balance data, an explicit SessionStartConfig, and a seeded SessionRng. A native GDScript SceneTree test runner validates pure scripts and scene loading without third-party test plugins. Repository and project settings make the Windows PC, 16:9, mouse-only target reproducible while keeping generated files out of Git.

**Tech Stack:** Godot 4.7.1, GDScript, Godot Resource files, PowerShell, Git

## Global Constraints

- Create Prototyping from the current main baseline. Do not branch it from Development.
- Implement this plan on proto/00-foundation, created from Prototyping.
- Never merge Prototyping into Development.
- Target Windows PC, a 1280x720 logical viewport, 16:9, and mouse-only input.
- Keep Forward Plus and the current D3D12 Windows driver for this milestone; renderer evaluation is outside foundation scope.
- Add no third-party Godot add-ons or test plugins.
- Use the verified Godot binary at D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe.
- Do not modify C:\Users\noisy\bin\godot.cmd; it points to a missing Godot 4.5.1 path.
- Write all agent-facing Markdown in English and all user-facing briefings in Korean.
- Use primitive placeholder presentation only. Custom art and final audio remain outside this milestone.
- Preserve user-owned untracked files. Never force checkout, clean, or reset the workspace.

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
- Create godot-project-moe-rail-way/tests/unit/test_config_validator.gd: valid and invalid Resource tests
- Create godot-project-moe-rail-way/tests/unit/test_session_rng.gd: deterministic sequence tests
- Create godot-project-moe-rail-way/tests/unit/test_project_settings.gd: platform, viewport, main-scene, and input tests

## Shared Interfaces

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

### Task 1: Create the Prototype Branch Boundary and Repository Hygiene

**Files:**

- Create: .gitignore
- Modify: godot-project-moe-rail-way/.gitignore

**Interfaces:**

- Consumes: current main at the approved documentation commit; existing untracked Godot scaffold
- Produces: Prototyping and proto/00-foundation branch boundaries; deterministic ignore rules

- [ ] **Step 1: Verify the starting state without changing it**

Run:

~~~powershell
git branch --show-current
git status --short
git log -1 --oneline
git show-ref --verify --quiet refs/heads/Prototyping
if ($LASTEXITCODE -eq 0) {
    throw "Prototyping already exists; inspect it before executing this plan."
}
~~~

Expected:

- Current branch is main.
- The Godot scaffold and .superpowers may appear as untracked.
- Prototyping does not exist.
- No tracked implementation changes are present.

- [ ] **Step 2: Create the isolated prototype integration and feature branches**

Run:

~~~powershell
git switch -c Prototyping main
git switch -c proto/00-foundation
git branch --show-current
git merge-base --is-ancestor main Prototyping
if ($LASTEXITCODE -ne 0) {
    throw "Prototyping is not based on main."
}
~~~

Expected: current branch prints proto/00-foundation and the ancestry check exits 0.

- [ ] **Step 3: Add repository and project ignore rules**

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

# Local prototype output
builds/
exports/
logs/
~~~

- [ ] **Step 4: Verify generated state is ignored and source remains visible**

Run:

~~~powershell
git check-ignore -v '.superpowers/brainstorm'
git check-ignore -v 'godot-project-moe-rail-way/.godot/uid_cache.bin'
git status --short
~~~

Expected:

- Both check-ignore commands identify the new rules.
- .superpowers and the project .godot directory are absent from normal status.
- The Godot source scaffold remains untracked and visible.

- [ ] **Step 5: Commit the hygiene boundary**

Run:

~~~powershell
git add -- '.gitignore' 'godot-project-moe-rail-way/.gitignore'
git diff --cached --check
git commit -m "chore: define prototype repository hygiene"
~~~

Expected: one commit containing only the two ignore files.

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
- Track: godot-project-moe-rail-way/project.godot

**Interfaces:**

- Consumes: verified Godot 4.7.1 console binary; ignored .godot cache
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
        assert_equal(instance.name, "PrototypeApp", "Root node name must be stable")
        assert_not_null(
            instance.get_node_or_null("Backdrop"),
            "PrototypeApp must contain the placeholder Backdrop"
        )
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
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -eq 0) {
    throw "Boot test unexpectedly passed before the scene existed."
}
~~~

Expected: exit code is nonzero and the failure says PrototypeApp scene must load.

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
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Prototype test runner failed."
}
~~~

Expected: PASS: 1 prototype test suite(s), exit code 0.

- [ ] **Step 6: Commit the tracked scaffold and boot slice**

Run:

~~~powershell
git add -- 'godot-project-moe-rail-way/.editorconfig' 'godot-project-moe-rail-way/.gitattributes' 'godot-project-moe-rail-way/icon.svg' 'godot-project-moe-rail-way/icon.svg.import' 'godot-project-moe-rail-way/project.godot' 'godot-project-moe-rail-way/src/app/prototype_app.gd' 'godot-project-moe-rail-way/src/app/prototype_app.tscn' 'godot-project-moe-rail-way/tests/support/prototype_test.gd' 'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' 'godot-project-moe-rail-way/tests/run_all.gd'
git diff --cached --check
git commit -m "feat: bootstrap prototype application"
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
    assert_true(
        errors.has("session_duration_seconds must be greater than 0"),
        "Duration error must name the field"
    )
    assert_true(
        errors.has("simulation_ticks_per_second must be greater than 0"),
        "Tick-rate error must name the field"
    )

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
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -eq 0) {
    throw "Configuration tests unexpectedly passed before implementation."
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

@export_range(1.0, 3600.0, 1.0) var session_duration_seconds := 180.0
@export_range(1, 240, 1) var simulation_ticks_per_second := 60


func create_session_start_config(seed_value: int) -> SessionStartConfig:
    return SessionStartConfig.new(
        seed_value,
        session_duration_seconds,
        simulation_ticks_per_second
    )
~~~

Create godot-project-moe-rail-way/src/config/prototype_config_validator.gd:

~~~gdscript
class_name PrototypeConfigValidator
extends RefCounted


static func validate(balance: PrototypeBalance) -> PackedStringArray:
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

@export var balance: PrototypeBalance
@export var startup_seed := 1

var session_start_config: SessionStartConfig


func _ready() -> void:
    var errors := PrototypeConfigValidator.validate(balance)
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

Add this assertion inside the non-null branch of godot-project-moe-rail-way/tests/smoke/test_project_boot.gd:

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
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Configuration implementation failed its test suite."
}

$MoeRailBootArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--scene', 'res://src/app/prototype_app.tscn', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailBootArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0) {
    throw "PrototypeApp scene failed to boot."
}
if (-not ($BootOutput -match 'Moe Rail Way prototype foundation ready')) {
    throw "PrototypeApp did not report successful startup."
}
~~~

Expected: 2 suites pass, and the explicit scene boot reports seed 1 and tick rate 60. A host-only Windows certificate-store warning may appear, but parse errors, script errors, and nonzero exit are failures.

- [ ] **Step 7: Commit validated configuration**

Run:

~~~powershell
git add -- 'godot-project-moe-rail-way/src/domain/session/session_start_config.gd' 'godot-project-moe-rail-way/src/config/prototype_balance.gd' 'godot-project-moe-rail-way/src/config/prototype_config_validator.gd' 'godot-project-moe-rail-way/data/prototype_balance.tres' 'godot-project-moe-rail-way/src/app/prototype_app.gd' 'godot-project-moe-rail-way/src/app/prototype_app.tscn' 'godot-project-moe-rail-way/tests/smoke/test_project_boot.gd' 'godot-project-moe-rail-way/tests/unit/test_config_validator.gd' 'godot-project-moe-rail-way/tests/run_all.gd'
git diff --cached --check
git commit -m "feat: add validated prototype session config"
~~~

Expected: one focused commit with Resource configuration, validation, integration, and tests.

---

### Task 4: Add the Deterministic Session Random Stream

**Files:**

- Create: godot-project-moe-rail-way/src/domain/random/session_rng.gd
- Create: godot-project-moe-rail-way/tests/unit/test_session_rng.gd
- Modify: godot-project-moe-rail-way/tests/run_all.gd
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
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -eq 0) {
    throw "RNG tests unexpectedly passed before implementation."
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

@export var balance: PrototypeBalance
@export var startup_seed := 1

var session_start_config: SessionStartConfig
var session_rng: SessionRng


func _ready() -> void:
    var errors := PrototypeConfigValidator.validate(balance)
    if not errors.is_empty():
        for error_message in errors:
            push_error(error_message)
        if OS.is_debug_build():
            get_tree().quit(2)
        return

    session_start_config = balance.create_session_start_config(startup_seed)
    session_rng = SessionRng.new(session_start_config.seed)
    print(
        "Moe Rail Way prototype foundation ready | seed=%d ticks=%d" %
        [
            session_start_config.seed,
            session_start_config.simulation_ticks_per_second,
        ]
    )
~~~

- [ ] **Step 5: Run all tests and the boot scene**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Deterministic RNG implementation failed its tests."
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
git add -- 'godot-project-moe-rail-way/src/domain/random/session_rng.gd' 'godot-project-moe-rail-way/src/app/prototype_app.gd' 'godot-project-moe-rail-way/tests/unit/test_session_rng.gd' 'godot-project-moe-rail-way/tests/run_all.gd'
git diff --cached --check
git commit -m "feat: add deterministic session random stream"
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
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -eq 0) {
    throw "Project-setting tests unexpectedly passed before configuration."
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
& $MoeRailGodotExe @MoeRailConfigureArgs
if ($LASTEXITCODE -ne 0) {
    throw "First project configuration run failed."
}

$FirstHash = (Get-FileHash 'godot-project-moe-rail-way\project.godot').Hash
& $MoeRailGodotExe @MoeRailConfigureArgs
if ($LASTEXITCODE -ne 0) {
    throw "Second project configuration run failed."
}
$SecondHash = (Get-FileHash 'godot-project-moe-rail-way\project.godot').Hash
if ($FirstHash -ne $SecondHash) {
    throw "Project configuration is not idempotent."
}
~~~

Expected: both runs print Project settings configured and both file hashes match.

- [ ] **Step 5: Run the complete automated and boot verification**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
& $MoeRailGodotExe --version
if ($LASTEXITCODE -ne 0) {
    throw "Godot version check failed."
}

& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Foundation test suite failed."
}

$MoeRailMainArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailMainArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0) {
    throw "Configured main scene failed to boot."
}
if (-not ($BootOutput -match 'Moe Rail Way prototype foundation ready')) {
    throw "Configured main scene did not report readiness."
}
~~~

Expected:

- Version is 4.7.1.stable.
- All 4 suites pass.
- The project boots its configured main scene and reports readiness.

- [ ] **Step 6: Verify repository hygiene and diff quality**

Run:

~~~powershell
git diff --check
if ($LASTEXITCODE -ne 0) {
    throw "Working-tree diff check failed."
}

$TrackedGenerated = git ls-files | Select-String -Pattern '(^|/)\.godot/|(^|/)logs/|(^|/)builds/'
if ($TrackedGenerated) {
    $TrackedGenerated
    throw "Generated files are tracked."
}

git status --short
~~~

Expected: no whitespace errors, no generated paths tracked, and only Task 5 source changes appear.

- [ ] **Step 7: Commit reproducible settings**

Run:

~~~powershell
git add -- 'godot-project-moe-rail-way/tools/configure_project.gd' 'godot-project-moe-rail-way/tests/unit/test_project_settings.gd' 'godot-project-moe-rail-way/tests/run_all.gd' 'godot-project-moe-rail-way/project.godot'
git diff --cached --check
git commit -m "chore: configure prototype platform baseline"
~~~

Expected: one focused settings, test, and tool commit.

- [ ] **Step 8: Run fresh post-commit verification**

Run:

~~~powershell
$MoeRailGodotExe = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
& $MoeRailGodotExe --headless --path 'godot-project-moe-rail-way' --script 'res://tests/run_all.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Post-commit test suite failed."
}

$MoeRailMainArgs = @('--headless', '--path', 'godot-project-moe-rail-way', '--quit-after', '2')
$BootOutput = & $MoeRailGodotExe @MoeRailMainArgs 2>&1
$BootExit = $LASTEXITCODE
$BootOutput
if ($BootExit -ne 0 -or -not ($BootOutput -match 'seed=1 ticks=60')) {
    throw "Post-commit boot verification failed."
}

git status --short
~~~

Expected: 4 suites pass, main scene boots with seed 1 and ticks 60, and tracked working state is clean.

- [ ] **Step 9: Hand off the completed feature branch for review**

Invoke superpowers:verification-before-completion, then superpowers:requesting-code-review. After review passes, invoke superpowers:finishing-a-development-branch.

The approved integration action is:

1. Squash proto/00-foundation into Prototyping.
2. Run the complete test and boot verification on Prototyping.
3. Create tag prototype-m1 on the verified integration commit.
4. Do not merge or target Development.

Do not perform the squash merge or tag before review evidence is accepted.
