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

## Root-Cause Boundary

The gutter diagnostic originates from Godot's editor internals (`TextEdit::set_line_gutter_item_color`). The repository's tracked code does not invoke gutter APIs. Direct tracked-project API misuse is ruled out. The exact 4.7.1 editor with a fresh project state and isolated child-only environment is the verified safe path. Whether version, project-local state, global state, or a 4.7.2 regression is individually causal remains unresolved.

## Decision

One concrete repository PowerShell visible-playtest launcher with behavior tests and README usage. The launcher:

- Invokes from clean local `main` tracking `origin/main`; dirty, staged, untracked, or divergent state fails before temp creation
- Verifies exact canonical version (4.7.1.stable.official.a13da4feb) before temp creation
- Mirrors only committed tracked `godot-project-moe-rail-way` ordinary files from `HEAD`; excludes `.git`, `.godot`, reparse points, and path escape; produces SHA-256 manifest before and after copy
- Creates a unique validated temp root containing project, child `APPDATA`, `LOCALAPPDATA`, `TEMP`, `TMP`, and logs
- Uses `ProcessStartInfo` with `UseShellExecute=false`, separate `ArgumentList`, child-only `Environment` overrides, visible GUI executable; never mutates controller or user environment and never hides the window
- Waits for natural editor exit; never enumerates, stops, or resets any Godot or Steam process; no timeout termination
- Scans captured editor and game logs for anchored `FAIL:`, `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, `CRASH:`, exact gutter diagnostic (`Index p_gutter = -1 is out of bounds`), and established crash or leak terms; confirms source Git status and tracked SHA-256 snapshot unchanged; never copies back
- On failure: preserves exact mirror and reports path; on success: revalidates exact owned temp root and descendants before cleanup; cleanup failure is a gate failure reporting remnants

## Exact Safety Contract

| Requirement | Binding Rule |
|-------------|--------------|
| Invocation state | Clean local `main` tracking `origin/main` only; any divergence fails pre-temp |
| Version gate | Exact canonical 4.7.1.stable.official.a13da4feb verified before temp creation |
| Mirror scope | Committed tracked ordinary files from `HEAD` only; `.git`, `.godot`, reparse points, path escape excluded |
| Integrity proof | SHA-256 manifest before and after copy; byte-identical verification |
| Temp root | Unique, validated, contains project + child `APPDATA`/`LOCALAPPDATA`/`TEMP`/`TMP` + logs |
| Process launch | `UseShellExecute=false`, `ArgumentList`, child-only `Environment`, visible GUI, no controller/user env mutation |
| Exit handling | Natural editor exit only; no process enumeration, stop, reset, or timeout kill |
| Log scanning | Anchored `FAIL:`, `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, `CRASH:`, exact gutter diagnostic, established crash/leak terms |
| Source preservation | Git status clean + tracked SHA-256 snapshot unchanged; never copy back |
| Failure mode | Preserve exact mirror, report path |
| Success cleanup | Revalidate exact owned temp root and descendants before cleanup; cleanup failure = gate failure reporting remnants |

## TDD and Review Gates

**RED before launcher exists.** Behavior tests (PowerShell/Pester or equivalent) must cover:

1. Wrong-version rejection before temp creation
2. Dirty, feature-branch, and divergent-state rejection before temp creation
3. Mirror and child-environment contract without opening user GUI
4. Source preservation (Git status + SHA-256 unchanged)
5. Failure preservation (exact mirror retained, path reported)
6. Safe cleanup (revalidation before cleanup; cleanup failure gates)

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
