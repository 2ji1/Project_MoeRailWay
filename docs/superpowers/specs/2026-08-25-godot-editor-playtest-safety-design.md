# Godot Editor Playtest Safety Design

## Status and Authority

This specification is the binding design for the repository's editor playtest safety mechanism. It governs the PowerShell launcher, behavior tests, and README usage. No runtime code or generalized framework is introduced. This spec is a user-approved candidate on `feature/godot-editor-playtest-safety`; it becomes canonical only after merge to `main`.

## Incident Evidence Table

| # | Observation | Classification |
|---|-------------|----------------|
| 1 | User ran Godot 4.7.2.stable.steam.ed1daf0bf; after session-ready, editor output repeated 762 times: `scene/gui/text_edit.cpp:6981 - Index p_gutter = -1 is out of bounds (gutters.size() = 4)` | Fact |
| 2 | Exact source is `TextEdit::set_line_gutter_item_color` rejecting `p_gutter=-1` at lines 6979–6984 in Godot 4.7.2 | Fact |
| 3 | Godot issue 81135 and PR 84907 historically document the same editor gutter/safe-line path | Fact |
| 4 | 4.7.x contains the old reload guard; 81135/84907 do not prove the old bug remains unfixed in 4.7.2 | Fact |
| 5 | Whether version, project-local state, global state, or a 4.7.2 regression is individually causal remains unresolved | Inference |
| 6 | Repository search found no `TextEdit`, `CodeEdit`, or gutter calls, ruling out direct tracked-project API misuse | Fact |
| 7 | No gameplay workaround is justified by the evidence | Decision |
| 8 | Canonical build is exactly 4.7.1.stable.official.a13da4feb at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe`; console uses same stem ending `_console.exe` | Fact |
| 9 | Steam 4.7.2 is outside contract | Fact |
| 10 | Approved spec `2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md` proves a real editor plus inherited user state can rewrite source | Fact |
| 11 | Controlled probe copied 145 tracked Godot-project files to a unique ordinary-file mirror, excluded `.git` and `.godot`, used child-only `APPDATA`, `LOCALAPPDATA`, `TEMP`, `TMP`, launched visible exact 4.7.1 editor, ran F6, saw zero editor errors/warnings and zero prohibited diagnostics, kept 145 of 145 files byte-identical, left source worktrees clean | Fact |
| 12 | The combined exact-version, fresh-project-state, isolated-child-environment path is proven | Fact |
| 13 | Windows 11 `tar.exe` listed but failed to extract the Git archive entry `assets/선로-🚆.bin` with `Invalid empty pathname`; `.NET System.Formats.Tar.TarFile` extracted the same archive and preserved every file | Fact |
| 14 | The first committed Task 2 manual attempt exited 2 before opening Godot because omitted typed string parameters bind as empty strings; null-only default guards left both `GitExecutable` and `TempParent` unresolved | Fact |
| 15 | Independent Task 2 quality review found that a failed recursive removal could already have deleted part of the mirror while the outer handler still printed `PRESERVED_MIRROR`; the same review found no external sentinel/source-integrity assertions in the cleanup-junction test and no regression for a nonzero child exit after otherwise valid logs | Fact |

## Root-Cause Boundary

The gutter diagnostic originates from Godot's editor internals (`TextEdit::set_line_gutter_item_color`). The repository's tracked code does not invoke gutter APIs. Direct tracked-project API misuse is ruled out. The exact 4.7.1 editor with a fresh project state and isolated child-only environment is the verified safe path. Whether version, project-local state, global state, or a 4.7.2 regression is individually causal remains unresolved.

## Decision

One concrete repository PowerShell visible-playtest launcher with behavior tests and README usage. The launcher:

- Rejects ambient Git repository-routing and command-config injection variables before any Git command; then invokes from clean local `main` tracking `origin/main`, where dirty, staged, untracked, or divergent state fails before temp creation
- Resolves omitted or whitespace-only `GitExecutable` and `TempParent` values with `[string]::IsNullOrWhiteSpace` before their first use, so the documented no-override launcher command reaches the same gates as explicit test invocations
- Verifies exact canonical version (4.7.1.stable.official.a13da4feb) before temp creation
- Mirrors only committed tracked `godot-project-moe-rail-way` ordinary files from `HEAD`; reads Git path records as strict UTF-8, NUL-delimited bytes; excludes `.git`, `.godot`, reparse points, invalid UTF-8, CR/LF/TAB path characters, and path escape; rejects every Git entry except blob mode `100644` or `100755` before archive creation; materializes the pinned Git tar archive with `.NET System.Formats.Tar.TarFile`; rejects post-extraction reparse points before any other recursive traversal; produces SHA-256 manifest before and after copy
- Requires the complete `RepositoryRoot` and temp-parent chains to be ordinary/non-reparse before any Git command; captures the repository directory identity; rejects a temp parent equal to/below the lexical repository or whose ancestor identities include the repository identity; creates a unique validated temp root containing project, child `APPDATA`, `LOCALAPPDATA`, `TEMP`, `TMP`, and logs
- Uses `ProcessStartInfo` with `UseShellExecute=false`, separate `ArgumentList`, child-only `Environment` overrides, visible GUI executable; never mutates controller or user environment and never hides the window
- Waits for natural editor exit; never enumerates, stops, or resets any Godot or Steam process; no timeout termination
- Scans captured editor and game logs for anchored `FAIL:`, `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, `CRASH:`, exact gutter diagnostic (`Index p_gutter = -1 is out of bounds`), and established crash or leak terms; confirms source Git status and tracked SHA-256 snapshot unchanged; never copies back
- Tracks whether recursive cleanup removal has started. Before removal starts, an ordinary failure with the captured root identity still reachable at its original path preserves the intact mirror and reports `PRESERVED_MIRROR`. After removal starts, a removal failure with that identity still reachable reports `CLEANUP_REMNANTS` because contents may be partial and must never be described as intact. If an ancestor/root identity is lost, it refuses further deletion and reports `MIRROR_IDENTITY_LOST` with the last-known path and captured identity without claiming the current lexical path is the mirror
- Treats a nonzero editor child exit as a gate failure even when all captured logs are syntactically valid and contain no prohibited diagnostic; behavior-test launcher helpers scrub the test-only exit-code variable from inherited environments before applying an intentional case override

## Exact Safety Contract

| Requirement | Binding Rule |
|-------------|--------------|
| Invocation state | Ambient Git routing/config-injection variables rejected before any Git command; clean local `main` tracking `origin/main` only; any divergence fails pre-temp |
| Optional defaults | Omitted or whitespace-only `GitExecutable` and `TempParent` values resolve to the discovered `git.exe` and canonical system temp path before path or process use |
| Version gate | Exact canonical 4.7.1.stable.official.a13da4feb verified before temp creation |
| Mirror scope | Committed tracked ordinary files from `HEAD` only; strict UTF-8/NUL Git path records; only blob mode `100644`/`100755` accepted before archive creation; `.NET System.Formats.Tar.TarFile` extraction; `.git`, `.godot`, reparse points, invalid UTF-8, CR/LF/TAB path characters, and path escape excluded |
| Integrity proof | SHA-256 manifest before and after copy; byte-identical verification |
| Temp root | Complete repository/temp-parent chains are ordinary; repository identity is absent from every temp-parent ancestor identity; outside the source repository; unique and validated; contains project + child `APPDATA`/`LOCALAPPDATA`/`TEMP`/`TMP` + logs |
| Process launch | `UseShellExecute=false`, `ArgumentList`, child-only `Environment`, visible GUI, no controller/user env mutation |
| Exit handling | Natural editor exit only; any nonzero editor exit is a gate failure even after valid logs; no process enumeration, stop, reset, or timeout kill |
| Log scanning | Anchored `FAIL:`, `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, `CRASH:`, exact gutter diagnostic, established crash/leak terms |
| Source preservation | Git status clean + tracked SHA-256 snapshot unchanged; never copy back |
| Failure mode | Before recursive removal starts, report `PRESERVED_MIRROR` only while the captured root identity remains reachable at its original path; after removal starts, report `CLEANUP_REMNANTS` while that identity remains reachable because contents may be partial; otherwise report `MIRROR_IDENTITY_LOST` with last-known path/identity and never label a decoy path as preserved |
| Success cleanup | Revalidate the temp-parent chain to its volume root, captured temp-parent/root directory identities, and exact owned descendants before cleanup; set the cleanup-started flag only after final revalidation and immediately before recursive removal; any removal failure is a gate failure reporting `CLEANUP_REMNANTS` when identity remains reachable |

## TDD and Review Gates

**RED before launcher exists.** Behavior tests (PowerShell/Pester or equivalent) must cover:

1. Wrong-version rejection before temp creation
2. Separate tracked-unstaged, staged-only, untracked-only, feature-branch, and divergent-state rejection before temp creation
3. Repository-root and repository-descendant temp-parent rejection plus repository-junction alias rejection before temp creation
4. Ambient Git routing/config-injection rejection with test-owned source and decoy repositories both unchanged
5. Synthetic Git mode `120000` rejection before temp creation, proving that archive link entries cannot reach managed extraction
6. Unicode path mirror through `.NET System.Formats.Tar`, deterministic early child-exit diagnostics, a nonzero child exit after otherwise valid logs, ambient fake-version and test-exit-code sanitization, and child-environment contract without opening user GUI
7. Source preservation (Git status + SHA-256 unchanged), including around the nonzero-exit, cleanup-junction, and cleanup-removal cases
8. Failure preservation (`PRESERVED_MIRROR` only before removal begins; `CLEANUP_REMNANTS` after removal begins and may have partially succeeded; honest identity-loss marker and last-known path/identity otherwise)
9. Safe cleanup, including an external junction target containing a sentinel whose bytes remain unchanged, and deterministic ordinary ancestor replacement with the original root object restored at the same lexical leaf, detected by captured parent identity before any recursive deletion
10. Parameterized default-resolution probes that supply only `RepositoryRoot`, `GodotExecutable`, and `Mode=VerifyMirror` in the omitted case and explicitly whitespace-only `GitExecutable` and `TempParent` in the second case; both prove success, source preservation, and no leaked system-temp mirror roots

Tests use test-owned temp Git fixtures or doubles. Never open or interfere with user GUI.

**Full regression** = tooling tests + README five Godot commands separately with canonical console executable.

**Review assignments:**
- Markdown, code, and output authoring: `nvidia/nvidia-nemotron-3-ultra-550b-a55b`
- Web research only: `gpt-5.6-luna`
- Every spec, quality, and code review: `gpt-5.6-sol`

## Acceptance

Completion stops at clean independently reviewed feature `HEAD`. Push, PR, merge, tag, and worktree cleanup require separate approval.

## Authorization Boundary

This design authorizes only the PowerShell launcher, its behavior tests, and README usage within this repository. It does not authorize:
- Runtime code or generalized framework
- Mutation of source `.godot`, user Godot settings, or Steam settings
- Mutation of user processes
- Use of Steam 4.7.2 or any non-canonical version
- Copy-back of any temp artifacts to source
- Process enumeration, termination, or timeout kill of Godot/Steam processes
- Running five tests through the launcher (README commands run separately with console executable)
- Review assignment to Nemotron or Luna
