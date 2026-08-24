# Prototype Track and Train Editor Gate Amendment Design

**Status:** Approved direction on 2026-08-17; written-spec review pending

**Amends:** `docs/superpowers/specs/2026-08-16-prototype-track-train-design.md` only where automated editor verification is concerned

**Implementation source to amend after review:** `docs/superpowers/plans/2026-08-16-prototype-track-train.md`

## 1. Problem and Root-Cause Boundary

Task 2's original editor runner starts Godot 4.7.1 with `--headless --editor --script` and supplies a custom `SceneTree` as the scripted main loop. The logical-field assertions pass, the required marker prints once, and the process returns `0`, but editor shutdown emits five anchored RID-allocation `ERROR:` lines plus RID and ObjectDB leak warnings. Waiting for the editor filesystem scan, deferring quit, requesting the ordinary close notification, and detaching the script did not make that command clean. In the same project and executable, plain `--headless --editor --quit` exits without those diagnostics.

The evidence bounds the defect to the scripted editor-main-loop shutdown architecture. It does not show a logical-field, candidate, preset, or runtime mapping defect. The verification architecture must change; the strict error gate must not be weakened or post-filtered.

## 2. Decision

Replace the custom-`SceneTree` editor runner with one first-party, test-only `EditorPlugin`. Godot owns the editor `SceneTree`; the plugin performs the assertions only when an explicit command-line user flag is present. Normal project runtime never loads editor plugins, and a normal editor session loads this plugin in an inert state.

This is the only add-on introduced by the amendment. It is repository-owned verification code, not a third-party dependency or a production extension point.

## 3. Goals and Non-Goals

### Goals

- Execute the logical-field editor assertions with `Engine.is_editor_hint()` true inside the editor-owned `SceneTree`.
- Wait on editor filesystem state rather than guessing with a sleep.
- Preserve exactly one `PASS: logical track field editor integration` marker.
- Preserve exit-code, duplicate-marker, `FAIL:`, `SCRIPT ERROR:`, and anchored `ERROR:` checks.
- Reject scan-abort, RID-leak, and ObjectDB-leak diagnostics even when Godot labels them as warnings.
- Leave normal editor use and all runtime/domain behavior unchanged.

### Non-Goals

- Do not alter logical-field behavior, candidate selection, gameplay code, balance, input, or presentation.
- Do not add a reusable plugin framework, editor automation abstraction, or third-party add-on.
- Do not terminate or reconfigure a user-owned Godot or Steam editor. A gate wrapper may terminate only the exact child PID that it started, and only after declaring a timeout failure.
- Do not treat a missing marker, timeout cleanup, or filtered diagnostic as success.

## 4. Components and File Ownership

Task 2 will create:

- `godot-project-moe-rail-way/addons/moerail_test_editor_gate/plugin.cfg`
- `godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd`
- `godot-project-moe-rail-way/addons/moerail_test_editor_gate/logical_track_field_editor_gate.gd.uid`

Task 2 will additionally modify `godot-project-moe-rail-way/project.godot` to enable exactly that first-party editor plugin. The original uncommitted `tests/integration/run_logical_track_field_editor_integration.gd` runner and sidecar are removed from the Task 2 target map and are never committed.

The plugin script owns only activation, editor-readiness waiting, the existing preset/CUSTOM/candidate-position assertions, result output, and the editor close request. It loads the real `logical_track_field.tscn`; it does not duplicate production field logic.

## 5. Activation and Lifecycle

The gate command passes one user argument after Godot's `--` separator:

```text
--moerail-logical-field-editor-gate
```

The enabled plugin follows this lifecycle:

1. `_enter_tree()` checks `OS.get_cmdline_user_args()` for the exact gate flag.
2. Without the flag, it returns immediately and never prints, tests, or requests exit.
3. With the flag, it defers one `_run_gate()` call so plugin initialization can finish.
4. `_run_gate()` requires `Engine.is_editor_hint()` and resolves `EditorInterface.get_resource_filesystem()`.
5. It polls `EditorFileSystem.is_scanning()` once per process frame until scanning is false, then waits one additional process frame. It does not rely on `filesystem_changed`, because an unchanged initial scan need not emit that signal. No sleep or wall-clock delay is used as editor-readiness logic.
6. It loads and instantiates the real logical-field scene, verifies preset and representative CUSTOM boundaries plus normalized candidate positions, and frees the temporary instance.
7. Success prints the exact PASS marker once. Failure emits explicit assertion diagnostics and one `FAIL:` marker.
8. After output, the plugin asks the editor-owned root to propagate `NOTIFICATION_WM_CLOSE_REQUEST`, waits one process frame for ordinary close handlers, and then defers `get_tree().quit(0)` on success or `get_tree().quit(1)` on failure. The explicit quit is issued by an `EditorPlugin` inside Godot's normal editor-owned `SceneTree`; the plugin never installs a custom main loop.

The positive gate command is:

```text
Godot --headless --editor --path <project> --max-fps 60 -- --moerail-logical-field-editor-gate
```

A PowerShell wrapper starts that exact child process, captures both output streams, and waits at most 60 seconds. Natural process exit before the deadline is required. On timeout, the wrapper first records failure and may then terminate only that exact child PID so the gate does not orphan a test editor. Timeout cleanup is never a success path. The positive command does not use `--quit-after`, so a Godot iteration ceiling cannot masquerade as the plugin's explicit success exit.

This lifecycle follows Godot's documented distinction between [propagating a close request and explicitly quitting the `SceneTree`](https://docs.godotengine.org/en/stable/tutorials/inputs/handling_quit_requests.html). Editor filesystem readiness follows the documented [`EditorFileSystem.is_scanning()`](https://docs.godotengine.org/en/stable/classes/class_editorfilesystem.html) state rather than assuming that a filesystem-change signal must occur.

## 6. Gate Contract

The amended Task 2 and Task 9 positive editor command runs the normal editor with the enabled test plugin and the explicit user flag. It requires all of the following:

- process exit code `0`;
- exactly one `PASS: logical track field editor integration` line;
- no line beginning `FAIL:`, `SCRIPT ERROR:`, or `ERROR:`;
- no `Scan thread aborted`, RID leak, or ObjectDB leak diagnostic;
- no tracked or untracked file change after the runner.

Task 2 also runs a no-flag editor smoke with the enabled plugin:

```text
Godot --headless --editor --path <project> --quit-after 30
```

That smoke requires exit code `0`, zero positive or failure gate markers, no prohibited diagnostics, and no tracked or untracked file change. The flagged positive gate proves that the configured plugin loads; this separate run exercises the same enabled plugin without activation. Source review additionally verifies that the no-flag `_enter_tree()` branch returns before scheduling work, printing output, or requesting exit.

The other Task 2 runners remain unchanged: exactly eight native suites, one runtime logical-field marker, and both accepted session-shell markers.

## 7. Plan Amendment and Git Safety

The design and plan amendments are authored in the isolated `codex/proto-02-editor-gate-design` worktree. They are reviewed before entering the dirty feature worktree.

The amended implementation plan will:

- add one explicit documentation-amendment step before Task 2 resumes;
- update the global add-on constraint to permit only this first-party test plugin;
- replace the old editor runner in the Target File Map, Task 2 file contract, Task 2 GREEN command, Task 2 commit allowlist, and Task 9 complete gate, and add the no-flag editor smoke to Task 2 and Task 9;
- add `project.godot` and the three plugin files to Task 2 ownership;
- preserve the strict positive-runner error filter and add explicit leak-warning rejection;
- pin the immutable feature starting plan commit to `4c0b9ac9a1335c8ffa8cb24f4b7eaf9434dc30c1` in Task 9 and Gate A instead of resolving the latest commit that touched the amended plan;
- include the reviewed design/plan/briefing amendment commits in the feature history and later squash tree without moving `Prototyping` now.

Before applying the reviewed documentation commits to `proto/02-track-train`, the resume gate will verify the primary protected status and hashes, the feature branch and empty index, and the exact Task 2 work-in-progress paths. The user-authorized indentation-only `prototype_app.gd` change is restored to the feature HEAD content and is not staged or absorbed. Documentation commits are then applied only if their paths do not overlap the Task 2 implementation paths.

No Gate A candidate, `Prototyping` integration, tag, push, PR, or cleanup is authorized by this amendment.

## 8. TDD and Review Flow

The already recorded missing-scene RED remains valid for Task 2 behavior. The editor-gate amendment adds its own RED/GREEN evidence:

1. RED: run the amended editor command before the plugin exists or is enabled; require a non-passing gate because the exact marker is absent.
2. GREEN: add the smallest plugin and project setting, then require the exact marker, explicit natural exit before the wrapper deadline, no anchored errors, no leak warnings, and no file changes.
3. Run the no-flag editor smoke and require the plugin to remain inert by the gate contract.
4. Run the complete Task 2 GREEN block.
5. Stage only the amended Task 2 allowlist and create the existing focused Task 2 commit.
6. Perform independent specification compliance review followed by code/test quality review. Findings enter the existing Superpowers fix loop.

If the editor-owned plugin still produces any prohibited shutdown diagnostic, the task stops. The implementation must not relax the filter, suppress output, use force-kill as a successful exit path, or substitute runtime/static assertions for actual editor execution. Terminating the wrapper-owned child after an already-failed timeout is cleanup only.

## 9. Acceptance

This amendment is accepted when:

- the written design and amended English plan are reviewed and approved;
- the Korean briefing names the amended English plan as its source of truth;
- `prototype_app.gd` matches feature HEAD before Task 2 resumes;
- the flagged positive gate and no-flag editor smoke jointly verify that the configured editor-owned plugin activates only for its explicit gate flag;
- the exact editor gate is clean under Godot `4.7.1.stable.official.a13da4feb`;
- Task 2's complete GREEN block and both independent reviews pass;
- protected primary files retain their approved status and SHA-256 fingerprints;
- no later integration or publication gate is crossed.
