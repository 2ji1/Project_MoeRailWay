# Prototype Track and Train Disposable Editor Mirror Amendment Design

**Status:** User-approved; independent specification and quality reviews passed on 2026-08-22; focused documentation commit and resume gate pending

**Amends:** `docs/superpowers/specs/2026-08-21-prototype-track-train-editor-shutdown-amendment-design.md` only where an editor process receives its project path, generated editor state, global editor environment, logs, and cleanup ownership

**Implementation source to amend after review:** `docs/superpowers/plans/2026-08-16-prototype-track-train.md`

## 1. New Evidence

The second shutdown amendment fixed the plugin-owned shutdown crash. The three non-editor Task 2 runners passed, the first-party `EditorPlugin` printed its exact PASS marker once, the engine-owned process exited without a prohibited diagnostic, and no RID or ObjectDB leak appeared. The strict file-state gate nevertheless failed because the editor rewrote one non-allowlisted feature file:

```text
godot-project-moe-rail-way/src/app/prototype_app.gd
54 insertions, 54 deletions
git diff --ignore-all-space: clean
HEAD blob: 2088b43ffdd8510eadb4682746a11c948c8f8aee
worktree blob: a3228bb9b6d8f1b2546bd026ac02aef11d755710
```

The feature project's ignored `.godot/editor/editor_layout.cfg` named `res://src/app/prototype_app.gd` as both the open and selected script. `project_metadata.cfg` named the same script and its scene as active. The rewrite changed four-space indentation to tabs and made no semantic change. The canonical wrapper correctly rejected it and stopped before the no-flag smoke, staging, or commit.

Four bounded disposable-mirror probes then isolated the write boundary:

1. A fresh project mirror excluded `.godot` but inherited the controller's normal Windows editor environment. Its flagged editor assertions and shutdown were clean, and the real feature worktree remained byte-identical, but the mirror-local `prototype_app.gd` still received the same whitespace rewrite.
2. A second inherited-environment mirror confirmed that the rewrite was contained to the mirror and never touched the feature worktree.
3. A fresh mirror received isolated per-run `APPDATA`, `LOCALAPPDATA`, `TEMP`, and `TMP` directories and used `--import --quit-after 240`. The flagged gate exited `0`, printed its marker once, emitted no prohibited diagnostic, left the mirror source byte-identical, and produced zero feature status or content delta.
4. A separate fresh mirror with the same isolated environment and no gate flag exited `0`, printed zero gate markers, emitted no prohibited diagnostic, and produced zero feature status or content delta.

The final two probes copied exactly 90 project files selected from Git's tracked plus untracked-nonignored set. They rejected reparse points and destination paths outside the unique temporary root. No ignored feature artifact, `.godot` directory, repository metadata, protected primary file, or user-owned editor process entered either probe.

## 2. Root Cause

Godot's [`--path`](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html#setting-the-project-path) changes the process working directory and makes the directory containing `project.godot` the writable project. The pinned 4.7.1 parser performs that directory change before project discovery: [`main.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/main/main.cpp#L1652-L1664) and [`project_settings.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/core/config/project_settings.cpp#L750-L801). It is not a read-only project selector.

Godot derives project-local generated data as `res://.godot`, creates that directory and its editor/import children when needed, loads editor layout from it after the first scan, and saves layout there on exit. The relevant pinned sources are [`project_settings.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/core/config/project_settings.cpp#L56-L69), [`editor_paths.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/editor/file_system/editor_paths.cpp#L235-L270), and [`editor_node.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/editor/editor_node.cpp#L1386-L1423). Omitting `.godot` therefore creates fresh project-local editor state but does not by itself isolate global editor configuration.

On Windows, Godot also uses `%APPDATA%\Godot` for global editor data and `%LOCALAPPDATA%\Godot` for cache. This is documented by [`EditorPaths`](https://docs.godotengine.org/en/4.7/classes/class_editorpaths.html) and implemented in [`os_windows.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/platform/windows/os_windows.cpp#L2251-L2271). The inherited-environment probe and isolated-environment probes show that both project-local and process-global editor state must be isolated. This causal conclusion is an inference from the official paths plus the controlled probe difference.

`--import` sets editor command-line-tool mode, enables `wait_for_import`, and initially assigns a one-iteration quit budget. A later `--quit-after 240` replaces that iteration count while preserving import waiting. The pinned parsing and main-loop behavior appear in [`main.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/main/main.cpp#L1572-L1576), [`main.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/main/main.cpp#L1671-L1683), and [`main.cpp`](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/main/main.cpp#L4772-L4781). The exact combined command is a harness inference from those sources and is confirmed by both isolated probes.

The root defect is therefore not the assertion plugin or the strict filter. It is running a stateful editor against the feature directory and inherited user editor environment while simultaneously requiring the feature bytes to remain unchanged.

## 3. Decision

Every automated editor process runs against its own controller-created disposable project mirror:

- The feature worktree is the read-only source of tracked plus untracked-nonignored project files for Task 2 and pre-integration Task 9. A separately authorized post-integration primary gate uses the clean candidate only after exact committed-tree equality with primary `HEAD`; it never copies a protected primary file.
- The mirror contains ordinary copied files only. It contains no junction, symlink, `.git`, pre-existing `.godot`, ignored import output, or other generated feature artifact.
- The controller verifies the mirror's prelaunch file list and SHA-256 fingerprints against the selected feature source files.
- The child receives mirror-local `APPDATA`, `LOCALAPPDATA`, `TEMP`, and `TMP` directories. It does not inherit the user's Godot editor data or cache paths.
- Godot writes imports, layout, cache, formatting, and logs only inside the disposable root.
- Nothing is ever copied from the mirror back into the feature or primary worktree.
- The flagged and no-flag runs use separate mirrors so neither process consumes state created by the other.
- The feature's complete sorted porcelain status and tracked plus untracked-nonignored SHA-256 snapshot must remain unchanged before mirror creation, after copy, and after the child exits.
- Task 9 additionally pins the gate target and mirror-source `HEAD` and tree identities around each mirror run; a primary target must equal the clean candidate source tree before copy, after copy, and after child exit.

This is concrete test orchestration in the canonical PowerShell gates. It does not add a repository harness file, production abstraction, interface layer, generalized project copier, or new runtime dependency.

## 4. Exact Mirror and Environment Contract

For each editor process, the wrapper:

1. Resolves the system temporary directory to an absolute path.
2. Creates one unique child named `moerail-track-train-editor-<guid>` and records that exact path.
3. Requires the root's immediate parent to equal the resolved system temporary directory, requires the exact leaf prefix, and rejects a reparse point anywhere in the temporary-root chain.
4. Creates a `project` directory, an `environment` directory with `appdata`, `localappdata`, and `temp` children, and a `logs` directory.
5. Enumerates `git ls-files` plus `git ls-files --others --exclude-standard` from the feature worktree and selects only paths beginning `godot-project-moe-rail-way/`.
6. Explicitly rejects `.git` and `.godot` path components, requires every source and every ancestor through the approved source root to be ordinary and non-reparse, derives the project-relative destination, resolves it to an absolute path, and rejects any destination outside the mirror project root.
7. Builds and hashes the complete selected manifest before copying. It then creates only ordinary destination ancestors, copies each manifest entry with `Copy-Item -LiteralPath`, and rejects a reparse point in every destination chain.
8. Rehashes the complete source manifest after copying and compares both that second source pass and an independently enumerated mirror snapshot against the original pre-copy path and SHA-256 records before launch.
9. Launches the exact Godot executable with a child-only environment map:

```text
APPDATA=<mirror>/environment/appdata
LOCALAPPDATA=<mirror>/environment/localappdata
TEMP=<mirror>/environment/temp
TMP=<mirror>/environment/temp
```

10. Adds every Godot argument separately through `ProcessStartInfo.ArgumentList`, overrides the four child environment entries through `ProcessStartInfo.Environment`, asynchronously drains stdout and stderr, and writes both captures inside `<mirror>/logs` without shell quoting or pipe deadlock. After exact-child exit, both capture tasks have a separate five-second completion deadline; timeout closes the redirected readers, fails the gate, and preserves the mirror. The absolute Godot `--log-file` is in the same directory.

No `HOME`, `USERPROFILE`, repository configuration, user Godot setting, or running editor process is reset or changed.

## 5. Editor Process Contract

The exact flagged command shape is:

```text
Godot --headless --path <mirror-project> --editor --import --quit-after 240 --max-fps 60 --log-file <mirror-log> -- --moerail-logical-field-editor-gate
```

The no-flag smoke uses the same command without `--` and the gate flag. Each run has its own fresh mirror and independent 30-second wall-clock deadline. The 240-iteration budget is a harness ceiling of approximately four seconds at the configured maximum rate after import readiness, not a Godot timing guarantee.

The flagged run requires natural exit code `0` and exactly one PASS marker in the redirected process output. The no-flag run requires natural exit code `0` with zero PASS or FAIL gate markers. Stdout, stderr, and the Godot log must each exist as an ordinary non-reparse file; a missing or unreadable capture fails the gate. The Godot log may duplicate a console line, so marker cardinality is measured on redirected stdout plus stderr while prohibited diagnostics are scanned across stdout, stderr, and the Godot log. Both reject:

- any line beginning `FAIL:`, `SCRIPT ERROR:`, `ERROR:`, `FATAL:`, `WARNING:`, or `CRASH:`;
- crash-handler, program-crash, signal-crash, scan-abort, RID-leak, or ObjectDB-leak text regardless of prefix;
- timeout, abnormal exit, mirror setup mismatch, feature status delta, feature content delta, or a `prototype_app.gd` difference from feature `HEAD`.

On timeout, failure is declared before cleanup. The wrapper may terminate only the exact child process object it started and waits at most five additional seconds for that child to exit. It never enumerates or terminates another Godot or Steam process.

On any setup, process, diagnostic, marker, snapshot, or exact-child-cleanup failure, the wrapper preserves the exact disposable root and prints its path. On success, after confirming the child has exited and all postconditions pass, it revalidates the exact immediate parent, prefix, complete root path chain, and every descendant without following a reparse point, then recursively removes only that root. A revalidation or removal error fails the gate, prints the exact root, and preserves every artifact that remains; recursive filesystem deletion cannot promise an intact root after a partial operating-system failure. Temporary mirror cleanup is part of this approved gate; it is not feature-worktree cleanup.

## 6. Resume and Git Contract

The paused feature state is feature HEAD `83ea845ca114f6803f24dd81a3d83f3ad97e2593`, an empty index, the 20 intended Task 2 paths, and the newly preserved whitespace-only `prototype_app.gd` rewrite. The user explicitly authorized a third canonical amendment and restoring exactly that one file to feature `HEAD`.

The third resume gate runs only after this design, the canonical plan, and the Korean briefing pass independent specification and quality review and enter one focused documentation commit. Before any mutation it revalidates:

- primary branch `Prototyping`, immutable HEAD, remote, milestone tag, exact Godot build, exact protected status, empty primary index, and all protected SHA-256 values;
- documentation commit parentage and exact three-file scope;
- feature root, branch, paused HEAD, merge base, and empty index;
- exactly the 20 Task 2 paths plus `godot-project-moe-rail-way/src/app/prototype_app.gd`;
- every preserved file SHA-256 value;
- an exact `54/54` prototype diff, no non-whitespace difference, the approved feature-HEAD content hash, and the approved whitespace-rewrite hash.

The gate then restores only `prototype_app.gd` from feature `HEAD`, requires exactly the 20 Task 2 paths and their preserved hashes, merges only the reviewed documentation commit with autostash disabled, and repeats every feature and primary invariant. It records `THIRD_AMENDMENT_MERGE_SHA` in the ignored English ledger.

No Task 2 staging or commit occurs in the resume gate. No Gate A candidate, `Prototyping` integration, `prototype-m3` tag, push, PR, or worktree cleanup is authorized.

## 7. TDD and Downstream Verification

The failed real-worktree editor run is the accepted RED for this amendment. The isolated flagged and no-flag probes are design evidence, not a substitute for the committed canonical Task 2 GREEN block.

After the third amendment merge:

1. Regenerate the Task 2 brief from the amended English plan.
2. Dispatch the exact requested implementation model, `nvidia/nvidia-nemotron-3-ultra-550b-a55b`. The plugin source is already in its canonical assertion-only form; the implementer first verifies that no additional production change is required.
3. Validate the existing plugin UID without running a feature-worktree editor import. If the sidecar is absent or malformed at resume, stop; do not create it through a feature editor, generate it in a mirror, or copy it back.
4. Run the three non-editor Task 2 commands against the feature project.
5. Run flagged and no-flag editor gates in two independent disposable mirrors under the exact strict contract above.
6. Stage exactly the 20 Task 2 paths, commit once, and require a clean feature worktree.
7. Perform independent specification-compliance review followed by independent code/test-quality review with `gpt-5.6-sol`.

Task 9 reuses the same disposable-mirror helper contract for its automated editor gates. Its visible editor-only manual checks use an exact clean committed feature copy rather than the feature worktree; the tester closes that visible editor normally, nothing is copied back, and the feature status and content are verified unchanged before the English evidence commit. Runtime-only manual checks may run the committed feature project because they do not open editor mode. If a later separately authorized post-integration gate targets the protected primary worktree, its editor mirror source is the clean candidate worktree with an identical committed tree; no protected primary file is copied into a mirror.

## 8. Acceptance

This amendment is accepted when:

- the new English design, amended canonical plan, and Korean briefing are independently reviewed and committed with exact scope;
- the third resume gate restores only the explicitly approved whitespace rewrite and merges only the reviewed documentation commit;
- each automated editor process receives a fresh exact project mirror and isolated per-run editor environment;
- flagged and no-flag processes exit naturally with their exact marker counts and pristine strict diagnostics;
- imports, editor layout, cache, formatting, logs, and temporary cleanup remain confined to the approved disposable root;
- the feature and primary worktrees retain exact status and content before and after every editor process;
- Task 2 reaches a clean focused commit and passes both independent reviews;
- Task 9 repeats the same isolation contract for automated and editor-only manual verification;
- no integration or publication authorization boundary is crossed.
