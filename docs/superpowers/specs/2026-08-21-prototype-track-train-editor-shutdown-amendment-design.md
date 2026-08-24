# Prototype Track and Train Editor Shutdown Amendment Design

**Status:** User-approved direction on 2026-08-21; independent specification and quality reviews passed on 2026-08-22

**Amends:** `docs/superpowers/specs/2026-08-17-prototype-track-train-editor-gate-amendment-design.md` only where the flagged editor gate shuts down and where the plugin UID import is state-checked

**Implementation source to amend after review:** `docs/superpowers/plans/2026-08-16-prototype-track-train.md`

## 1. New Evidence and Root Cause

The first editor-gate amendment correctly moved the assertions into an `EditorPlugin` owned by Godot's normal editor `SceneTree`. Its assertions and all non-editor Task 2 runners pass. The plugin then prints the required marker once, but the prescribed shutdown sequence fails reproducibly:

```text
PASS: logical track field editor integration
ERROR: Parent node is busy adding/removing children, `remove_child()` can't be called at this time.
ERROR: Parent node is busy adding/removing children, `remove_child()` can't be called at this time.
ERROR: Condition "data.parent" is true.
CrashHandlerException: Program crashed with signal 11
```

The backtrace anchors the first failure at the plugin's synchronous call to:

```gdscript
get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
```

Godot 4.7.1's [`Node::propagate_notification`](https://github.com/godotengine/godot/blob/4.7.1-stable/scene/main/node.cpp) recursively notifies a blocked child tree. The same source rejects `add_child` and `remove_child` while that traversal is blocked. A real window close request instead enters the specialized [`Window` event callback](https://github.com/godotengine/godot/blob/4.7.1-stable/scene/main/window.cpp), and the editor's internal close handler unloads addons while mutating the editor tree. Manually broadcasting the window-close notification from inside a plugin therefore starts teardown during a recursion that forbids the required mutations. It is not equivalent to asking the engine to end its main loop.

The import preparation step exposed a separate contract defect. The no-flag import exited cleanly and generated the unique plugin `.gd.uid`, but it also rewrote `src/app/prototype_app.gd` with whitespace-only changes. The existing Step 3A checked output and UID uniqueness but did not compare the complete file state before and after the editor process. The user authorized restoring exactly that file to feature `HEAD`; it is not part of Task 2.

The strict diagnostic gate is correct. A PASS marker followed by a shutdown error or crash is not GREEN, and the out-of-scope rewrite must not be absorbed.

## 2. Decision

Separate assertion ownership from shutdown ownership completely:

- The first-party `EditorPlugin` waits for editor readiness, performs assertions, frees its temporary scene instance, and prints exactly one PASS or FAIL marker.
- The plugin does not propagate a close notification, call `SceneTree.quit`, restart the editor, or invoke any editor shutdown API.
- The wrapper starts Godot with `--quit-after 600 --max-fps 60`. Godot's own iteration budget unloads editor addons and ends the main loop.
- The wrapper requires natural process exit before a 30-second deadline, exit code `0`, exactly one PASS marker, no failure/crash diagnostic, unchanged porcelain status, and unchanged SHA-256 fingerprints for every tracked or untracked nonignored file.

Godot documents `--quit-after <int>` as quitting after the specified number of iterations. The [4.7.1 command-line parser and editor main loop](https://github.com/godotengine/godot/blob/4.7.1-stable/main/main.cpp) implement that budget and unload editor addons before ordinary cleanup. Unlike `--import`, `--quit-after` does not postpone its budget while the initial scan is active, so the gate is run only after UID/import preparation and the marker remains mandatory. Expiry of the frame budget therefore cannot masquerade as assertion success.

This is preferred over calling the public `SceneTree.quit(exit_code)` from the plugin. `SceneTree.quit` is a valid end-of-iteration request, but engine-owned `--quit-after` keeps the plugin entirely out of shutdown policy and uses the editor-build path that explicitly unloads addons. A split runtime assertion plus minimal editor smoke would reduce editor coverage and is also rejected.

## 3. Flagged Plugin Lifecycle

The activation flag remains:

```text
--moerail-logical-field-editor-gate
```

The enabled plugin follows this lifecycle:

1. `_enter_tree()` returns immediately unless the exact flag appears in `OS.get_cmdline_user_args()`.
2. With the flag, it schedules exactly one deferred `_run_gate()` call.
3. `_run_gate()` requires `Engine.is_editor_hint()`, waits until `EditorFileSystem.is_scanning()` is false, and then waits one additional process frame.
4. It loads the real logical-field scene, checks the approved presets, representative `CUSTOM` boundaries, and normalized candidate positions, then frees the temporary instance.
5. `_finish_gate()` prints exactly one PASS marker when no assertion failed. Otherwise it emits the assertion diagnostics and exactly one FAIL marker.
6. `_finish_gate()` returns. It performs no close propagation and no quit request.
7. Godot reaches its command-line iteration budget, unloads the plugin through the normal editor path, and exits.

The exact positive command shape is:

```text
Godot --headless --editor --path <project> --quit-after 600 --max-fps 60 -- --moerail-logical-field-editor-gate
```

The 600-iteration budget is a harness ceiling of approximately 10 seconds at the configured maximum rate, not a Godot timing guarantee. It gives the already prepared small project ample deferred/editor frames while preventing an unbounded headless editor. The wrapper's independent 30-second wall-clock deadline covers process startup and cleanup without turning timeout cleanup into success. If the marker is absent when the engine exits, the gate fails even when the exit code is `0`.

## 4. Diagnostic and Process Contract

The flagged editor gate requires all of the following:

- the exact child process started by the wrapper exits naturally before 30 seconds;
- process exit code `0`;
- exactly one `PASS: logical track field editor integration` line;
- no line beginning `FAIL:`, `SCRIPT ERROR:`, `ERROR:`, `FATAL:`, `WARNING:`, or `CRASH:`;
- no case-insensitive crash-handler or signal-crash text;
- no `Scan thread aborted`, RID-leak, or ObjectDB-leak diagnostic regardless of prefix;
- no tracked or untracked nonignored path, status, or content change. The wrapper compares both sorted porcelain rows and a SHA-256 snapshot of every tracked or untracked nonignored file, so an editor rewrite of an already dirty file cannot hide behind an unchanged status row.

On timeout, the wrapper declares failure first and may then terminate only the exact child process object it created. Termination is followed by a separate bounded five-second reap wait; there is no parameterless wait after the deadline. Output is captured before the failure is raised, and temp logs are preserved with reported paths if exact-child cleanup cannot be confirmed. The wrapper never enumerates, closes, or resets a user-owned Godot or Steam editor. A forced termination is never accepted as a clean exit.

The no-flag smoke uses the same wrapper-owned child-process pattern, `--quit-after 600 --max-fps 60`, independent 30-second deadline, and exact-child timeout cleanup. It requires zero gate markers and the same clean diagnostic, natural-exit, porcelain-status, and content-fingerprint properties.

## 5. Import and UID State Contract

The already generated plugin sidecar is part of the paused Task 2 work and contains one unique valid UID. Resume does not rerun import merely to reproduce that completed transition.

Step 3A becomes a state-aware operation:

1. Capture the complete sorted porcelain status and SHA-256 fingerprints for every tracked or untracked nonignored file before any command.
2. If the plugin `.gd.uid` already exists, run no editor import. Godot 4.7.1's [`ResourceFormatLoader` UID path](https://github.com/godotengine/godot/blob/4.7.1-stable/core/io/resource_loader.cpp) reads a sidecar directly, so validate its single `uid://[a-z0-9]+` value, uniqueness across tracked and untracked GDScript sidecars, and exact unchanged status and fingerprints.
3. If the sidecar is absent in a future fresh execution, start the exact no-flag import once as a wrapper-owned hidden child with a 60-second deadline and the same bounded exact-child cleanup and log-preservation policy. The only permitted status and fingerprint transition is creation of that one sidecar. Reject every byte change to a pre-existing dirty or clean file and every modified, deleted, renamed, or additional untracked path.
4. Never restore or normalize an unexpected import side effect automatically. Preserve evidence and stop.

For the current resume, `src/app/prototype_app.gd` must match feature `HEAD` before Step 3A and after every editor command. It is not added to the Task 2 allowlist.

## 6. Documentation and Git Resume

This second amendment is authored on the existing clean `codex/proto-02-editor-gate-design` worktree at first amendment commit `9047301da36c18b94e6e5be24d8dfd7423966828`. Its focused documentation commit may change only:

- this English design amendment;
- `docs/superpowers/plans/2026-08-16-prototype-track-train.md`;
- `docs/briefings/ko/2026-08-16-prototype-track-train-plan-briefing.md`.

Before the documentation commit enters `proto/02-track-train`, the second resume gate revalidates:

- the immutable primary branch, base, remote, Godot version, protected status, and protected hashes;
- the exact feature branch, merge base, paused HEAD `b09aaaafe7b6be192776b49adc69c01e82e41bdc`, and empty index;
- exactly the 20 intended Task 2 paths and their SHA-256 values;
- no `prototype_app.gd` worktree difference;
- the documentation commit's parent and exact three-file scope.

The gate then merges only that reviewed documentation commit with command-line autostash disabled, rechecks all 20 Task 2 hashes, verifies the index remains empty, and rechecks the primary protected state. It records the resulting documentation merge SHA in the ignored English SDD ledger.

No Gate A candidate, `Prototyping` integration, tag, push, PR, or cleanup is authorized.

## 7. TDD and Review Flow

The historical missing-scene RED and missing-plugin editor RED remain accepted evidence. They are not recreated by deleting current work.

After the second amendment merge:

1. A fresh exact-model implementation agent removes only the plugin's shutdown calls and keeps all assertion logic unchanged.
2. Validate the pre-existing plugin UID with the state-aware Step 3A path; do not import because the sidecar exists.
3. Run all Task 2 non-editor gates.
4. Require `prototype_app.gd` to match feature `HEAD` immediately before and after both editor subprocesses, then run the flagged editor command and no-flag smoke under the strict process, diagnostic, and status-plus-content contracts.
5. If any editor process changes `prototype_app.gd` or another out-of-scope path, stop without restoring it automatically.
6. Stage exactly the 20 Task 2 paths, commit once, and require a clean worktree.
7. Perform an independent specification-compliance review followed by a separate code/test-quality review. Any finding enters the existing focused fix loop.

## 8. Acceptance

This amendment is accepted when:

- the English design, amended canonical plan, and Korean briefing are independently reviewed and committed with the exact documentation scope;
- the documentation commit enters the feature history without absorbing Task 2 work;
- `prototype_app.gd` stays identical to feature `HEAD` through Step 3A and both editor gates;
- the flagged plugin performs real editor assertions but calls no shutdown API;
- Godot owns editor addon unloading and termination through `--quit-after`;
- the flagged and no-flag editor processes exit naturally and cleanly under the strict gate;
- Task 2's full GREEN block and both independent reviews pass;
- the primary protected state and SHA-256 fingerprints remain unchanged;
- no later integration or publication gate is crossed.
