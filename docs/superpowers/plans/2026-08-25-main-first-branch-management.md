# Main-First Branch Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adopt the approved main-first feature workflow while keeping `D:\godot\MoeRailWay\godot-project-moe-rail-way` as the clean, immediately playable integrated project.

**Architecture:** This is a documentation-only policy migration on `feature/main-first-branch-policy`. Four independently reviewable documentation tasks replace active branch instructions, preserve historical records, publish through a merge-commit pull request, fast-forward the primary `main`, rerun the complete automated gate, and then remove the feature worktree and branches.

**Tech Stack:** Git, GitHub CLI, PowerShell, Markdown, Godot `4.7.1.stable.official.a13da4feb`

**Spec:** `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`

## Global Constraints

- Feature branch: `feature/main-first-branch-policy`
- Feature worktree: `D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy`
- Primary workspace: `D:\godot\MoeRailWay`
- Main base: `610c6e1aff52482ddf2edbe5f34529f3f5892263`
- Approved design commit: `1ef64d1cb3209d209f283cd385a1c939166fa392`
- Godot executable: `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`
- Every Markdown edit or new Markdown file must be produced by `nvidia/nvidia-nemotron-3-ultra-550b-a55b`. If native delegation fails with `unreadable_encrypted_agent_task`, use the approved plaintext proxy at `http://127.0.0.1:10100` with that exact model; do not substitute another model.
- Every specification review, quality review, code review, or other review must use `gpt-5.6-sol`.
- Web research is not expected. If it becomes necessary, assign it only to `gpt-5.6-luna`.
- Agent-facing Markdown is English. The one explicitly listed Korean briefing is the only language exception. All progress, stop reports, and final handoffs to the user are Korean.
- Do not modify Godot code, scenes, resources, tests, generated files, or editor settings.
- Do not terminate, reset, or interfere with user-owned Godot or Steam processes.
- A dirty, untracked, staged, or divergent primary workspace is a stop condition. Never stash, reset, format, stage, copy, absorb, move, or delete primary-workspace changes.
- Do not commit or push directly to `main`. Do not use `Prototyping`, `Development`, or `proto/*` for new work.
- Use merge-commit automatic merge only. Do not squash, rebase, rewrite history, or create a tag.
- Execute the plan in one PowerShell session. Before every task that uses a relative path or a Git command without `-C`, set and verify the current directory as the exact feature worktree root.
- The execution handoff must provide the trusted full SHA of the approved planning commit through `MOERAIL_POLICY_PLAN_SHA`; a SHA inferred only from the current feature history is not trusted.
- Preserve these local refs and exact SHAs throughout; do not publish them:
  - `local/user-workspace-snapshot-20260825` = `9daec4c053e6e2e7eb05e1abe04d330ea28a41a2`
  - `local/legacy-main-before-sync-20260825` = `71a8ebc23a1171eaef50aaa03bddc02f594fe02c`

## Target File Map

| Path | Responsibility | Phase |
|---|---|---|
| `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md` | Record the user's design approval | Planning commit only |
| `docs/superpowers/plans/2026-08-25-main-first-branch-management.md` | Canonical implementation instructions | Planning commit only |
| `AGENTS.md` | Active instructions for future agents | Task 1 |
| `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md` | One supersession notice while preserving its historical body | Task 2 |
| `README.md` | Current M4, main-first branch, playtest, and test guidance | Task 3 |
| `docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md` | Korean user-review briefing | Task 4 |

No other path may change. All other historical plans, evidence, and artifacts remain byte-unchanged.

---

### Task 0: Development Session Preflight

**Files:** None

**Interfaces:**

- Consumes: the approved design, this committed plan, the main base, and the two local safety refs.
- Produces: a verified implementation base stored in `$MoeRailPolicyImplementationBase` for the current execution session.

- [ ] **Step 1: Record both workspaces before refreshing remote state**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailBase = '610c6e1aff52482ddf2edbe5f34529f3f5892263'
$MoeRailDesign = '1ef64d1cb3209d209f283cd385a1c939166fa392'
Set-Location -LiteralPath $MoeRailFeature
if ([IO.Path]::GetFullPath((Get-Location).Path) -ne [IO.Path]::GetFullPath($MoeRailFeature)) {
    throw 'The current directory is not the exact feature worktree.'
}

'FEATURE BEFORE FETCH'
git -C $MoeRailFeature branch --show-current
git -C $MoeRailFeature rev-parse HEAD
git -C $MoeRailFeature rev-parse --abbrev-ref '@{upstream}' 2>$null
git -C $MoeRailFeature status --porcelain=v1 --untracked-files=all
'PRIMARY BEFORE FETCH'
git -C $MoeRailPrimary branch --show-current
git -C $MoeRailPrimary rev-parse HEAD
git -C $MoeRailPrimary rev-parse --abbrev-ref '@{upstream}'
git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all
git -C $MoeRailPrimary rev-parse origin/main
'SAFETY REFS BEFORE FETCH'
git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825
git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825
'WORKTREES'
git -C $MoeRailPrimary worktree list --porcelain
```

Expected: the observations are printed without changing either index, working tree, or local branch.

- [ ] **Step 2: Refresh `origin/main`, record again, and enforce the ref gate**

```powershell
git -C $MoeRailPrimary fetch origin main
if ($LASTEXITCODE -ne 0) { throw 'Preflight fetch failed.' }

$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailPrimaryUpstream = (git -C $MoeRailPrimary rev-parse --abbrev-ref '@{upstream}').Trim()
$MoeRailOriginMain = (git -C $MoeRailPrimary rev-parse origin/main).Trim()
$MoeRailPrimaryStatus = @(git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all)
$MoeRailFeatureBranch = (git -C $MoeRailFeature branch --show-current).Trim()
$MoeRailFeatureHead = (git -C $MoeRailFeature rev-parse HEAD).Trim()
$MoeRailFeatureStatus = @(git -C $MoeRailFeature status --porcelain=v1 --untracked-files=all)
$MoeRailPlanCommit = (git -C $MoeRailFeature log -1 --format=%H -- 'docs/superpowers/plans/2026-08-25-main-first-branch-management.md').Trim()
$MoeRailTrustedPlanSha = $env:MOERAIL_POLICY_PLAN_SHA
$MoeRailSnapshot = (git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825).Trim()
$MoeRailLegacyMain = (git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825).Trim()

if ($MoeRailPrimaryBranch -ne 'main' -or
    $MoeRailPrimaryHead -ne $MoeRailBase -or
    $MoeRailOriginMain -ne $MoeRailBase -or
    $MoeRailPrimaryUpstream -ne 'origin/main' -or
    $MoeRailPrimaryStatus.Count -ne 0 -or
    $MoeRailFeatureBranch -ne 'feature/main-first-branch-policy' -or
    $MoeRailTrustedPlanSha -notmatch '^[0-9a-f]{40}$' -or
    $MoeRailFeatureHead -ne $MoeRailTrustedPlanSha -or
    $MoeRailPlanCommit -ne $MoeRailTrustedPlanSha -or
    $MoeRailFeatureStatus.Count -ne 0 -or
    $MoeRailSnapshot -ne '9daec4c053e6e2e7eb05e1abe04d330ea28a41a2' -or
    $MoeRailLegacyMain -ne '71a8ebc23a1171eaef50aaa03bddc02f594fe02c') {
    throw 'Development Session Preflight ref or workspace mismatch.'
}
git -C $MoeRailFeature merge-base --is-ancestor $MoeRailBase $MoeRailFeatureHead
if ($LASTEXITCODE -ne 0) { throw 'Feature is not based on the approved main base.' }
git -C $MoeRailFeature merge-base --is-ancestor $MoeRailDesign $MoeRailFeatureHead
if ($LASTEXITCODE -ne 0) { throw 'Approved design commit is absent.' }

'PRIMARY AFTER FETCH'
git -C $MoeRailPrimary branch --show-current
git -C $MoeRailPrimary rev-parse HEAD
git -C $MoeRailPrimary rev-parse origin/main
git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all
git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825
git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825
```

Expected: all exact comparisons pass. On any mismatch, report the observed and expected state in Korean and stop without fixing it.

- [ ] **Step 3: Run the exact feature-worktree baseline**

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy\godot-project-moe-rail-way'
$MoeRailVersion = ((& $MoeRailGodot --version 2>&1) -join "`n").Trim()
if ($LASTEXITCODE -ne 0 -or $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected Godot version: $MoeRailVersion"
}
$MoeRailCases = @(
    @{ Script = 'res://tests/run_all.gd'; Markers = @('PASS: 19 prototype test suite(s)') },
    @{ Script = 'res://tests/integration/run_session_shell_integration.gd'; Markers = @('PASS: session shell layout integration', 'PASS: session shell lifecycle integration') },
    @{ Script = 'res://tests/integration/run_logical_track_field_integration.gd'; Markers = @('PASS: logical track field integration') },
    @{ Script = 'res://tests/integration/run_track_train_input_integration.gd'; Markers = @('PASS: track train input integration') },
    @{ Script = 'res://tests/integration/run_track_train_app_integration.gd'; Markers = @('PASS: track train app integration') }
)
foreach ($MoeRailCase in $MoeRailCases) {
    $MoeRailOutput = @(& $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailCase.Script 2>&1)
    $MoeRailExit = $LASTEXITCODE
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    $MoeRailBad = @($MoeRailOutput | Where-Object { $_ -match '^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|CRASH:)' })
    $MoeRailMissing = @($MoeRailCase.Markers | Where-Object { $MoeRailText -notmatch [regex]::Escape($_) })
    if ($MoeRailExit -ne 0 -or $MoeRailBad.Count -ne 0 -or $MoeRailMissing.Count -ne 0) {
        throw "Baseline failed: $($MoeRailCase.Script)"
    }
}
$MoeRailPostGateStatus = @(git -C $MoeRailFeature status --porcelain=v1 --untracked-files=all)
if ($MoeRailPostGateStatus.Count -ne 0) { throw 'Godot baseline changed the feature worktree.' }
$MoeRailPolicyImplementationBase = (git -C $MoeRailFeature rev-parse HEAD).Trim()
"MOERAIL_POLICY_IMPLEMENTATION_BASE=$MoeRailPolicyImplementationBase"
```

Expected: Godot reports the exact version, all five processes exit `0`, every required marker appears, no anchored failure diagnostic appears, and the feature remains clean.

---

### Task 1: Replace the Active Agent Branch Instructions

**Files:**

- Modify: `AGENTS.md`

**Interfaces:**

- Consumes: the main-first design's branch, task-gate, protection, merge, synchronization, and legacy-branch contracts.
- Produces: the active repository instruction block every future agent reads first.

- [ ] **Step 1: Run the documentation RED check**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy'
Set-Location -LiteralPath $MoeRailFeature
if ([IO.Path]::GetFullPath((Get-Location).Path) -ne [IO.Path]::GetFullPath($MoeRailFeature)) { throw 'Wrong worktree.' }
$MoeRailAgents = Get-Content -LiteralPath 'AGENTS.md' -Raw
if ($MoeRailAgents -match '## Prototype Branch Boundary' -and
    $MoeRailAgents -match 'Use Prototyping as the integration base') {
    throw 'RED: AGENTS.md still selects Prototyping as the active integration base.'
} else {
    throw 'RED contract is absent for an unexpected reason.'
}
```

Expected: nonzero exit with the exact `RED:` message and no unrelated parsing or file error.

- [ ] **Step 2: Replace only the obsolete section using Nemotron**

Replace `## Prototype Branch Boundary` and its bullets with exactly this section:

```markdown
## Main-First Branch Management

- Use `main` as the only active integration and local playtest branch. Keep `D:\godot\MoeRailWay` as a clean local `main` checkout tracking `origin/main` when no approved transition is in progress.
- Create each `feature/*` branch from the latest verified `main` in a dedicated external worktree. Never implement feature changes directly in the primary `main` checkout.
- For every planned task, preserve RED, minimum GREEN, the explicit file allowlist, exact-path staging, a focused task commit, all required regression tests, and independent specification and quality reviews.
- After all feature gates pass, push the feature branch, open a pull request targeting `main`, and merge automatically with a merge commit only. Then fast-forward and test the primary `main` before cleaning up the feature worktree and local and remote feature branches.
- Treat `Prototyping`, `Development`, and existing `proto/*` branches as legacy read-only references for new work. Never merge `Prototyping` wholesale into `Development`.
- A dirty, untracked, staged, or divergent primary workspace stops automatic work. Never stash, reset, format, stage, copy, absorb, move, or delete its changes to clear the gate.
```

- [ ] **Step 3: Run the GREEN contract**

```powershell
$MoeRailAgents = Get-Content -LiteralPath 'AGENTS.md' -Raw
$MoeRailRequired = @(
    '## Main-First Branch Management',
    'only active integration and local playtest branch',
    'feature/*',
    'minimum GREEN',
    'exact-path staging',
    'independent specification and quality reviews',
    'merge automatically with a merge commit only',
    'legacy read-only references',
    'Never merge `Prototyping` wholesale into `Development`',
    'Never stash, reset, format, stage, copy, absorb, move, or delete'
)
$MoeRailMissing = @($MoeRailRequired | Where-Object { $MoeRailAgents -notmatch [regex]::Escape($_) })
if ($MoeRailMissing.Count -ne 0 -or
    $MoeRailAgents -match '## Prototype Branch Boundary' -or
    $MoeRailAgents -match 'Use Prototyping as the integration base') {
    throw "AGENTS.md GREEN failed: $($MoeRailMissing -join ', ')"
}
'GREEN: active agent branch policy is main-first'
```

Expected: exactly one `GREEN:` line and exit `0`.

- [ ] **Step 4: Enforce the allowlist, stage exactly, and commit**

```powershell
$MoeRailAllowed = @('AGENTS.md')
$MoeRailChanged = @(
    git diff --name-only
    git ls-files --others --exclude-standard
) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailChanged).Count -ne 0) {
    throw "Task 1 changed-path mismatch: $($MoeRailChanged -join ', ')"
}
git add -- AGENTS.md
$MoeRailStaged = @(git diff --cached --name-only) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailStaged).Count -ne 0) {
    throw "Task 1 staged-path mismatch: $($MoeRailStaged -join ', ')"
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 1 staged whitespace check failed.' }
git commit -m 'docs: adopt main-first agent branch policy'
if ($LASTEXITCODE -ne 0) { throw 'Task 1 commit failed.' }
```

- [ ] **Step 5: Run independent Sol specification review**

Give `gpt-5.6-sol` the canonical design, this Task 1 contract, the Task 1 commit SHA, and its parent diff. Require either `APPROVED: no actionable findings` or severity-ranked findings with exact lines. The reviewer must not edit files.

- [ ] **Step 6: Run independent Sol quality review**

Give a fresh `gpt-5.6-sol` review the complete current Task 1 result and require checks for clarity, internal consistency, Markdown quality, scope discipline, and future-agent ambiguity. Require severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 7: Remediate findings without rewriting the task commit**

Run this step only when either review reports findings. For each remediation cycle, assign the exact `AGENTS.md` corrections to Nemotron, rerun Step 3, stage only `AGENTS.md`, and create one focused follow-up commit named `docs: address agent policy review findings`. Then rerun Steps 5-6 against the complete current Task 1 result. If either review still reports findings, repeat one fix commit per cycle; Task 1 is complete only when both reviews return exactly `APPROVED: no actionable findings`. If both initial reviews approve, skip this step. Do not repeat the original Step 4 commit operation, and preserve every commit.

---

### Task 2: Mark the Legacy Prototype Branch Policy as Superseded

**Files:**

- Modify: `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`

**Interfaces:**

- Consumes: the new design's limited supersession boundary.
- Produces: one unambiguous notice while leaving every historical body line unchanged.

- [ ] **Step 1: Run the documentation RED check**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy'
Set-Location -LiteralPath $MoeRailFeature
if ([IO.Path]::GetFullPath((Get-Location).Path) -ne [IO.Path]::GetFullPath($MoeRailFeature)) { throw 'Wrong worktree.' }
$MoeRailLegacyPath = 'docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md'
$MoeRailLegacyText = Get-Content -LiteralPath $MoeRailLegacyPath -Raw
if ($MoeRailLegacyText -notmatch '2026-08-25-main-first-branch-management-design\.md') {
    throw 'RED: the legacy strategy has no main-first branch-policy supersession notice.'
} else {
    throw 'RED contract is absent for an unexpected reason.'
}
```

Expected: nonzero exit with the exact `RED:` message.

- [ ] **Step 2: Insert one notice using Nemotron**

Insert this blockquote immediately after the existing `Execution boundary` metadata line and before `## 1. Outcome`. Do not modify any existing body line.

```markdown
> **Branch-policy supersession (2026-08-25):** For new work, the branch-related directives in **Fixed Constraints**, **Branch Topology**, **Delivery Strategy**, **Feature Branches**, and **Git and Review Policy** are historical and superseded by `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`. Active work uses `main` plus short-lived `feature/*` branches; `Prototyping`, `Development`, and existing `proto/*` branches are legacy read-only references. This document remains authoritative for product direction, runtime architecture, test strategy, and production handoff.
```

- [ ] **Step 3: Prove GREEN and insertion-only preservation**

```powershell
$MoeRailLegacyPath = 'docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md'
$MoeRailNotice = '> **Branch-policy supersession (2026-08-25):** For new work, the branch-related directives in **Fixed Constraints**, **Branch Topology**, **Delivery Strategy**, **Feature Branches**, and **Git and Review Policy** are historical and superseded by `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`. Active work uses `main` plus short-lived `feature/*` branches; `Prototyping`, `Development`, and existing `proto/*` branches are legacy read-only references. This document remains authoritative for product direction, runtime architecture, test strategy, and production handoff.'
$MoeRailCurrent = Get-Content -LiteralPath $MoeRailLegacyPath -Raw
if ([regex]::Matches($MoeRailCurrent, [regex]::Escape($MoeRailNotice)).Count -ne 1 -or
    $MoeRailCurrent -notmatch '(?s)Execution boundary:.*?\r?\n\r?\n> \*\*Branch-policy supersession \(2026-08-25\):.*?\r?\n\r?\n## 1\. Outcome') {
    throw 'Legacy strategy GREEN notice placement failed.'
}
'GREEN: legacy branch policy has one correctly placed supersession notice'
```

Expected: exactly one `GREEN:` line and exit `0`.

- [ ] **Step 4: Enforce the allowlist, stage exactly, and commit**

```powershell
$MoeRailAllowed = @('docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md')
$MoeRailChanged = @(
    git diff --name-only
    git ls-files --others --exclude-standard
) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailChanged).Count -ne 0) {
    throw "Task 2 changed-path mismatch: $($MoeRailChanged -join ', ')"
}
git add -- $MoeRailAllowed
$MoeRailStaged = @(git diff --cached --name-only) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailStaged).Count -ne 0) {
    throw "Task 2 staged-path mismatch: $($MoeRailStaged -join ', ')"
}
$MoeRailNumstat = (git diff --cached --numstat -- $MoeRailAllowed).Trim()
$MoeRailPatch = @(git diff --cached --unified=0 -- $MoeRailAllowed)
$MoeRailAdded = @($MoeRailPatch | Where-Object { $_ -match '^\+(?!\+\+)' })
$MoeRailDeleted = @($MoeRailPatch | Where-Object { $_ -match '^-(?!--)' })
if ($MoeRailNumstat -ne "2`t0`t$MoeRailAllowed" -or
    $MoeRailAdded.Count -ne 2 -or
    $MoeRailAdded[0] -ne "+$MoeRailNotice" -or
    $MoeRailAdded[1] -ne "+" -or
    $MoeRailDeleted.Count -ne 0 -or
    ($MoeRailPatch -join "`n") -match '\\ No newline at end of file') {
    throw 'Task 2 must be an exact two-line Git-blob insertion with no deletion or EOF change.'
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 2 staged whitespace check failed.' }
git commit -m 'docs: mark legacy prototype branch policy superseded'
if ($LASTEXITCODE -ne 0) { throw 'Task 2 commit failed.' }
```

- [ ] **Step 5: Run independent Sol specification review**

Require `gpt-5.6-sol` to verify the notice's supersession boundary, exact link, active and legacy branches, and the staged `2` additions / `0` deletions proof comprising the notice plus one blank separator. Require severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 6: Run independent Sol quality review**

Require a fresh `gpt-5.6-sol` review of the complete current Task 2 result for clarity, placement, Markdown quality, byte-preservation of the historical body, and lack of conflicting new authority. Require severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 7: Remediate findings without rewriting history**

Run this step only when either review reports findings. For each remediation cycle, assign only the notice correction to Nemotron, rerun Step 3, stage only the legacy strategy, and run the exact proof from Task 5 Step 3 with `git diff $MoeRailBase -- $MoeRailLegacyPath` and `git diff --numstat $MoeRailBase -- $MoeRailLegacyPath` so the comparison is base-to-current-working-tree rather than follow-up-commit-only. Then create one focused follow-up commit named `docs: address legacy notice review findings` and rerun Steps 5-6 against the complete current Task 2 result. If either review still reports findings, repeat one fix commit per cycle; Task 2 is complete only when both reviews return exactly `APPROVED: no actionable findings`. If both initial reviews approve, skip this step. Do not repeat the original Step 4 staged-diff assertion or commit operation, and preserve every commit.

---

### Task 3: Refresh the Main Playtest README

**Files:**

- Modify: `README.md`

**Interfaces:**

- Consumes: the integrated M4 state, the new branch policy, and the five accepted automated entry points.
- Produces: accurate repository entry guidance without claiming cargo, contracts, hazards, debt, or economy implementation.

- [ ] **Step 1: Run the documentation RED check**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy'
Set-Location -LiteralPath $MoeRailFeature
if ([IO.Path]::GetFullPath((Get-Location).Path) -ne [IO.Path]::GetFullPath($MoeRailFeature)) { throw 'Wrong worktree.' }
$MoeRailReadme = Get-Content -LiteralPath 'README.md' -Raw
$MoeRailObsolete = @(
    '`Prototyping` is at the tagged `prototype-m1` foundation milestone',
    'Godot prototype project on Prototyping',
    'The tracked Godot project lives on the `Prototyping` branch',
    'git switch Prototyping',
    'The committed `prototype-m1` baseline passes four suites',
    'The current milestone is a deterministic, testable foundation'
)
$MoeRailPresent = @($MoeRailObsolete | Where-Object { $MoeRailReadme.Contains($_) })
if ($MoeRailPresent.Count -eq $MoeRailObsolete.Count) {
    throw 'RED: README still describes prototype-m1 on Prototyping.'
} else {
    throw "RED contract mismatch: $($MoeRailPresent -join ', ')"
}
```

Expected: nonzero exit with the exact `RED:` message.

- [ ] **Step 2: Apply the minimum truthful README update using Nemotron**

Keep the game concept, core loop, design pillars, and company-layer text unchanged. Make only these replacements:

Replace the current-status quote with:

```markdown
> **Current status:** Milestone M4 is integrated on `main`. The playable prototype includes the deterministic session shell, a centered logical-cell grid, mouse-driven endpoint track extension, curve fitting with overlap downgrade, per-cell track inventory, construction and recovery, and continuous movement for one train. Cargo, contracts, hazards, debt, and company economy remain planned work.
```

Change the repository-tree description to:

```text
`-- godot-project-moe-rail-way/       Playable Godot prototype project on main
```

Replace `## Branch Model` with:

```markdown
## Branch Model

- **`main`** is the only active integration branch and the local playtest branch.
- **`feature/*`** branches start from the latest verified `main` in dedicated external worktrees and return through reviewed pull requests using merge commits.
- **`Prototyping`**, **`Development`**, and existing **`proto/*`** branches are legacy read-only references for new work. `Prototyping` is never merged wholesale into `Development`.

The canonical workflow is defined in [Main-First Feature Branch Management Design](docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md).
```

Replace `## Getting Started` through the paragraph immediately before `## Canonical Documents` with:

````markdown
## Getting Started

The integrated Godot project targets `4.7.1.stable.official.a13da4feb`. On this development host, the immediately playable checkout is expected at `D:\godot\MoeRailWay` on a clean local `main` tracking `origin/main`. Protect and resolve any dirty or divergent state under the branch-management design before synchronizing it.

```powershell
git branch --show-current
git status --short
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = '.\godot-project-moe-rail-way'
& $MoeRailGodot --version
& $MoeRailGodot --editor --path $MoeRailProject
```

Run the registered suite and four standalone integrations with:

```powershell
$MoeRailScripts = @(
    'res://tests/run_all.gd',
    'res://tests/integration/run_session_shell_integration.gd',
    'res://tests/integration/run_logical_track_field_integration.gd',
    'res://tests/integration/run_track_train_input_integration.gd',
    'res://tests/integration/run_track_train_app_integration.gd'
)
foreach ($MoeRailScript in $MoeRailScripts) {
    & $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailScript
    if ($LASTEXITCODE -ne 0) { throw "Prototype gate failed: $MoeRailScript" }
}
```

The current automated baseline reports `PASS: 19 prototype test suite(s)` and passes the session-shell, logical-track-field, track-input, and track-and-train-app integrations.
````

Add these entries under `## Canonical Documents`:

```markdown
- [Main-First Feature Branch Management Design](docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md)
- [Main-First Branch Management Implementation Plan](docs/superpowers/plans/2026-08-25-main-first-branch-management.md)
- [Grid Track Amendment Design](docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md)
- [Grid Track Amendment Plan](docs/superpowers/plans/2026-08-24-prototype-grid-track-amendment.md)
```

Replace `## Current Scope` body with:

```markdown
The integrated M4 scope is a deterministic session shell with one continuously moving train and a playable logical-cell track loop: endpoint-only mouse input, centered grid mapping, curve fitting and overlap downgrade, per-cell reservation and inventory, progressive construction, atomic completion, and ordered recovery. The next prototype slices add warp cargo, risk and investment, contracts and economy, credit survival, and playtest-ready polish. Campaign structure, narrative progression, and production architecture remain outside the current prototype.
```

- [ ] **Step 3: Run the GREEN contract**

```powershell
$MoeRailReadme = Get-Content -LiteralPath 'README.md' -Raw
$MoeRailRequired = @(
    'Milestone M4 is integrated on `main`',
    'Playable Godot prototype project on main',
    '`main`** is the only active integration branch',
    '`feature/*`** branches start from the latest verified `main`',
    'legacy read-only references',
    'D:\godot\MoeRailWay',
    'PASS: 19 prototype test suite(s)',
    'run_session_shell_integration.gd',
    'run_logical_track_field_integration.gd',
    'run_track_train_input_integration.gd',
    'run_track_train_app_integration.gd',
    '2026-08-25-main-first-branch-management-design.md',
    '2026-08-25-main-first-branch-management.md',
    '2026-08-24-prototype-grid-track-amendment-design.md',
    '2026-08-24-prototype-grid-track-amendment.md'
)
$MoeRailForbidden = @(
    '`Prototyping` is at the tagged `prototype-m1` foundation milestone',
    'Godot prototype project on Prototyping',
    'lives on the `Prototyping` branch',
    'git switch Prototyping',
    'prototype-m1` baseline passes four suites'
)
$MoeRailMissing = @($MoeRailRequired | Where-Object { -not $MoeRailReadme.Contains($_) })
$MoeRailStale = @($MoeRailForbidden | Where-Object { $MoeRailReadme.Contains($_) })
if ($MoeRailMissing.Count -ne 0 -or $MoeRailStale.Count -ne 0) {
    throw "README GREEN failed; missing=$($MoeRailMissing -join ', '); stale=$($MoeRailStale -join ', ')"
}
'GREEN: README describes M4 on main'
```

- [ ] **Step 4: Enforce the allowlist, stage exactly, and commit**

```powershell
$MoeRailAllowed = @('README.md')
$MoeRailChanged = @(
    git diff --name-only
    git ls-files --others --exclude-standard
) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailChanged).Count -ne 0) {
    throw "Task 3 changed-path mismatch: $($MoeRailChanged -join ', ')"
}
git add -- README.md
$MoeRailStaged = @(git diff --cached --name-only) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailStaged).Count -ne 0) {
    throw "Task 3 staged-path mismatch: $($MoeRailStaged -join ', ')"
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 3 staged whitespace check failed.' }
git commit -m 'docs: refresh main playtest README'
if ($LASTEXITCODE -ne 0) { throw 'Task 3 commit failed.' }
```

- [ ] **Step 5: Run independent Sol specification review**

Require `gpt-5.6-sol` to compare the complete current Task 3 result with the canonical policy, M4 files, and fresh test markers. It must flag any unimplemented feature claim or stale branch instruction and return severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 6: Run independent Sol quality review**

Require a fresh `gpt-5.6-sol` review of the complete current Task 3 result for onboarding clarity, command safety, link correctness, Markdown structure, and preservation of unrelated game-design text. Require severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 7: Remediate findings without rewriting history**

Run this step only when either review reports findings. For each remediation cycle, assign only approved README corrections to Nemotron, rerun Step 3, stage only `README.md`, and create one focused follow-up commit named `docs: address README review findings`. Then rerun Steps 5-6 against the complete current Task 3 result. If either review still reports findings, repeat one fix commit per cycle; Task 3 is complete only when both reviews return exactly `APPROVED: no actionable findings`. If both initial reviews approve, skip this step. Do not repeat the original Step 4 commit operation, and preserve every commit.

---

### Task 4: Add the Korean User Briefing

**Files:**

- Create: `docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md`

**Interfaces:**

- Consumes: the approved English design and this English implementation plan.
- Produces: a Korean review aid that explicitly defers to both English canonical documents.

- [ ] **Step 1: Run the documentation RED check**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy'
Set-Location -LiteralPath $MoeRailFeature
if ([IO.Path]::GetFullPath((Get-Location).Path) -ne [IO.Path]::GetFullPath($MoeRailFeature)) { throw 'Wrong worktree.' }
$MoeRailBriefing = 'docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md'
if (-not (Test-Path -LiteralPath $MoeRailBriefing)) {
    throw 'RED: the Korean main-first branch-management briefing is absent.'
} else {
    throw 'RED contract is absent for an unexpected reason.'
}
```

Expected: nonzero exit with the exact `RED:` message.

- [ ] **Step 2: Create the briefing using Nemotron**

Create exactly this Korean user-review document:

```markdown
# 메인 우선 기능 브랜치 관리 설계 브리핑

영어 설계 정본: [docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md](../../superpowers/specs/2026-08-25-main-first-branch-management-design.md)

영어 구현 계획 정본: [docs/superpowers/plans/2026-08-25-main-first-branch-management.md](../../superpowers/plans/2026-08-25-main-first-branch-management.md)

이 문서는 사용자 검토용 한국어 브리핑입니다. 실제 구현과 운영 판단은 위 영어 정본을 따르며, 내용이 다르게 읽힐 때에는 영어 정본을 먼저 바로잡습니다.

## 운영 결과

- `main`은 유일한 활성 통합 및 로컬 플레이테스트 브랜치입니다.
- 기본 작업공간 `D:\godot\MoeRailWay`는 작업 전환 중이 아닐 때 `origin/main`을 추적하는 깨끗한 로컬 `main`으로 유지합니다.
- 즉시 플레이테스트할 프로젝트는 `D:\godot\MoeRailWay\godot-project-moe-rail-way`입니다.
- 각 기능은 최신 검증된 `main`에서 `feature/*` 브랜치와 별도 외부 작업트리를 만들어 개발합니다.

## 기능 작업과 통합

각 계획 작업은 RED, 최소 GREEN, 명시된 파일 허용목록, 정확한 경로 스테이징, 집중 커밋, 필요한 전체 회귀 테스트, 독립 사양 검토와 품질 검토를 순서대로 통과합니다. 작업별 커밋은 보존하며 squash 또는 rebase 방식으로 합치지 않습니다.

기능 전체가 통과하면 기능 브랜치를 푸시하고 `main` 대상 PR을 엽니다. 필요한 검사와 검토가 끝난 PR만 merge commit 방식으로 자동 병합합니다. 병합 후 기본 작업공간의 로컬 `main`을 `origin/main`으로 fast-forward하고 전체 자동 검증을 다시 통과시킨 다음 기능 작업트리와 로컬·원격 기능 브랜치를 정리합니다.

## 사용자 작업 보호

기본 작업공간이 dirty, untracked, staged 또는 divergent 상태이면 자동 동기화를 중단합니다. 그 상태를 해소한다는 이유로 사용자 변경을 stash, reset, format, stage, copy, absorb, move 또는 delete하지 않습니다. 사용자 소유 Godot 또는 Steam 프로세스도 종료하거나 재설정하지 않습니다.

다음 안전 참조는 이 정책 아래 로컬에만 보존합니다.

- `local/user-workspace-snapshot-20260825` = `9daec4c053e6e2e7eb05e1abe04d330ea28a41a2`
- `local/legacy-main-before-sync-20260825` = `71a8ebc23a1171eaef50aaa03bddc02f594fe02c`

## 레거시 브랜치와 태그

`Prototyping`, `Development`, 기존 `proto/*` 브랜치는 새 작업에서 읽기 전용 이력 참조입니다. 새 기능을 시작하거나 통합하지 않으며 `Prototyping` 전체를 `Development`로 병합하지 않습니다.

이번 브랜치 관리 정책 전환에는 마일스톤 태그를 만들지 않습니다.
```

- [ ] **Step 3: Run the GREEN contract**

```powershell
$MoeRailBriefing = 'docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md'
$MoeRailBriefingText = Get-Content -LiteralPath $MoeRailBriefing -Raw
$MoeRailRequired = @(
    'docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md',
    'docs/superpowers/plans/2026-08-25-main-first-branch-management.md',
    '사용자 검토용 한국어 브리핑',
    'D:\godot\MoeRailWay\godot-project-moe-rail-way',
    'feature/*',
    'merge commit 방식으로 자동 병합',
    'squash 또는 rebase',
    'fast-forward',
    'dirty, untracked, staged 또는 divergent',
    'stash, reset, format, stage, copy, absorb, move 또는 delete',
    'local/user-workspace-snapshot-20260825',
    '9daec4c053e6e2e7eb05e1abe04d330ea28a41a2',
    'local/legacy-main-before-sync-20260825',
    '71a8ebc23a1171eaef50aaa03bddc02f594fe02c',
    '이번 브랜치 관리 정책 전환에는 마일스톤 태그를 만들지 않습니다'
)
$MoeRailMissing = @($MoeRailRequired | Where-Object { -not $MoeRailBriefingText.Contains($_) })
if ($MoeRailMissing.Count -ne 0) { throw "Briefing GREEN failed: $($MoeRailMissing -join ', ')" }
'GREEN: Korean briefing defers to the English canonical documents'
```

- [ ] **Step 4: Enforce the allowlist, stage exactly, and commit**

```powershell
$MoeRailAllowed = @('docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md')
$MoeRailChanged = @(
    git diff --name-only
    git ls-files --others --exclude-standard
) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailChanged).Count -ne 0) {
    throw "Task 4 changed-path mismatch: $($MoeRailChanged -join ', ')"
}
git add -- $MoeRailAllowed
$MoeRailStaged = @(git diff --cached --name-only) | Sort-Object -Unique
if (@(Compare-Object $MoeRailAllowed $MoeRailStaged).Count -ne 0) {
    throw "Task 4 staged-path mismatch: $($MoeRailStaged -join ', ')"
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Task 4 staged whitespace check failed.' }
git commit -m 'docs: brief main-first branch workflow'
if ($LASTEXITCODE -ne 0) { throw 'Task 4 commit failed.' }
```

- [ ] **Step 5: Run independent Sol specification review**

Require `gpt-5.6-sol` to verify the complete current Task 4 result against the English design and plan, including the non-canonical status, exact refs, branch lifecycle, protection rules, and no-tag boundary. Require severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 6: Run independent Sol quality review**

Require a fresh `gpt-5.6-sol` review of the complete current Task 4 result for Korean clarity, terminology consistency, link correctness, Markdown quality, and absence of new implementation authority. Require severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 7: Remediate findings without rewriting history**

Run this step only when either review reports findings. For each remediation cycle, assign only approved briefing corrections to Nemotron, rerun Step 3, stage only the briefing, and create one focused follow-up commit named `docs: address briefing review findings`. Then rerun Steps 5-6 against the complete current Task 4 result. If either review still reports findings, repeat one fix commit per cycle; Task 4 is complete only when both reviews return exactly `APPROVED: no actionable findings`. If both initial reviews approve, skip this step. Do not repeat the original Step 4 commit operation, and preserve every commit.

---

### Task 5: Run the Final Feature Verification

**Files:** None unless review remediation is required

**Interfaces:**

- Consumes: completed Tasks 1-4 and their independent approvals.
- Produces: one clean reviewed feature `HEAD` and publication evidence.

- [ ] **Step 1: Prove the total path set is exact**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy'
Set-Location -LiteralPath $MoeRailFeature
if ([IO.Path]::GetFullPath((Get-Location).Path) -ne [IO.Path]::GetFullPath($MoeRailFeature)) { throw 'Wrong worktree.' }
$MoeRailBase = '610c6e1aff52482ddf2edbe5f34529f3f5892263'
$MoeRailExpected = @(
    'AGENTS.md',
    'README.md',
    'docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md',
    'docs/superpowers/plans/2026-08-25-main-first-branch-management.md',
    'docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md',
    'docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md'
) | Sort-Object
$MoeRailActual = @(git diff --name-only $MoeRailBase HEAD) | Sort-Object
if (@(Compare-Object $MoeRailExpected $MoeRailActual).Count -ne 0) {
    throw "Final path mismatch: $($MoeRailActual -join ', ')"
}
$MoeRailExpectedBySubject = @{
    'docs: define main-first branch management' = @('docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md')
    'docs: plan main-first policy migration' = @('docs/superpowers/plans/2026-08-25-main-first-branch-management.md', 'docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md')
    'docs: adopt main-first agent branch policy' = @('AGENTS.md')
    'docs: address agent policy review findings' = @('AGENTS.md')
    'docs: mark legacy prototype branch policy superseded' = @('docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md')
    'docs: address legacy notice review findings' = @('docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md')
    'docs: refresh main playtest README' = @('README.md')
    'docs: address README review findings' = @('README.md')
    'docs: brief main-first branch workflow' = @('docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md')
    'docs: address briefing review findings' = @('docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md')
}
$MoeRailCommits = @(git rev-list --reverse "$MoeRailBase..HEAD")
foreach ($MoeRailCommit in $MoeRailCommits) {
    $MoeRailSubject = (git show -s --format=%s $MoeRailCommit).Trim()
    if (-not $MoeRailExpectedBySubject.ContainsKey($MoeRailSubject)) {
        throw "Unrecognized feature-history commit: $MoeRailCommit $MoeRailSubject"
    }
    $MoeRailCommitPaths = @(git diff-tree --no-commit-id --name-only -r $MoeRailCommit) | Sort-Object
    $MoeRailCommitExpected = @($MoeRailExpectedBySubject[$MoeRailSubject]) | Sort-Object
    if (@(Compare-Object $MoeRailCommitExpected $MoeRailCommitPaths).Count -ne 0) {
        throw "Per-commit path mismatch: $MoeRailCommit $($MoeRailCommitPaths -join ', ')"
    }
}
git diff-tree --check $MoeRailBase HEAD
if ($LASTEXITCODE -ne 0) { throw 'Committed whitespace check failed.' }
```

Expected: only the six planned paths differ from the base; all other historical plans and evidence are therefore byte-unchanged.

- [ ] **Step 2: Scan the active policy files for placeholders and stale authority**

```powershell
$MoeRailActiveFiles = @(
    'AGENTS.md',
    'README.md',
    'docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md',
    'docs/superpowers/plans/2026-08-25-main-first-branch-management.md',
    'docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md'
)
$MoeRailForbidden = @(('T' + 'BD'), ('T' + 'ODO'), ('FIX' + 'ME'), ('implement' + ' later'), ('fill in' + ' details'))
foreach ($MoeRailPath in $MoeRailActiveFiles) {
    $MoeRailText = Get-Content -LiteralPath $MoeRailPath -Raw
    $MoeRailHits = @($MoeRailForbidden | Where-Object { $MoeRailText.Contains($_) })
    if ($MoeRailHits.Count -ne 0) { throw "Placeholder in ${MoeRailPath}: $($MoeRailHits -join ', ')" }
}
$MoeRailAgents = Get-Content -LiteralPath 'AGENTS.md' -Raw
$MoeRailReadme = Get-Content -LiteralPath 'README.md' -Raw
if ($MoeRailAgents -match 'Use Prototyping as the integration base' -or
    $MoeRailReadme -match 'git switch Prototyping|prototype-m1.*four suites|lives on the `Prototyping` branch') {
    throw 'Obsolete active branch authority remains.'
}
```

- [ ] **Step 3: Re-prove the final Task 2 tree is one exact two-line insertion**

```powershell
$MoeRailLegacyPath = 'docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md'
$MoeRailNotice = '> **Branch-policy supersession (2026-08-25):** For new work, the branch-related directives in **Fixed Constraints**, **Branch Topology**, **Delivery Strategy**, **Feature Branches**, and **Git and Review Policy** are historical and superseded by `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`. Active work uses `main` plus short-lived `feature/*` branches; `Prototyping`, `Development`, and existing `proto/*` branches are legacy read-only references. This document remains authoritative for product direction, runtime architecture, test strategy, and production handoff.'
$MoeRailNumstat = (git diff --numstat $MoeRailBase HEAD -- $MoeRailLegacyPath).Trim()
$MoeRailPatch = @(git diff --unified=0 $MoeRailBase HEAD -- $MoeRailLegacyPath)
$MoeRailAdded = @($MoeRailPatch | Where-Object { $_ -match '^\+(?!\+\+)' })
$MoeRailDeleted = @($MoeRailPatch | Where-Object { $_ -match '^-(?!--)' })
if ($MoeRailNumstat -ne "2`t0`t$MoeRailLegacyPath" -or
    $MoeRailAdded.Count -ne 2 -or
    $MoeRailAdded[0] -ne "+$MoeRailNotice" -or
    $MoeRailAdded[1] -ne "+" -or
    $MoeRailDeleted.Count -ne 0 -or
    ($MoeRailPatch -join "`n") -match '\\ No newline at end of file') {
    throw 'Final legacy strategy is not the exact two-line insertion.'
}
'GREEN: final legacy strategy is one exact two-line Git-blob insertion'
```

- [ ] **Step 4: Run all five Godot gates again**

Run Task 0 Step 3 unchanged. Expected: the exact Godot version, five exit codes of `0`, all positive markers, no anchored failure marker, and a clean feature worktree.

- [ ] **Step 5: Run final independent Sol specification review**

Give `gpt-5.6-sol` the base SHA, exact feature `HEAD`, canonical design, this plan, the complete diff, task commit list, RED/GREEN evidence, and fresh five-process output. Require severity-ranked findings or `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 6: Run final independent Sol quality review**

Give a fresh `gpt-5.6-sol` the same immutable evidence and require review of operational safety, command correctness, documentation consistency, link validity, task history, and residual risk. Require severity-ranked actionable findings or exactly `APPROVED: no actionable findings`. The reviewer must not edit files.

- [ ] **Step 7: Close any findings and establish the feature SHA**

If either review reports a finding, assign only the exact task-owned Markdown correction to Nemotron, use that task's exact `docs: address ... review findings` commit subject, rerun that task's GREEN and both reviews, then rerun all of Task 5. When both reviews approve:

```powershell
$MoeRailFeatureStatus = @(git status --porcelain=v1 --untracked-files=all)
if ($MoeRailFeatureStatus.Count -ne 0) { throw 'Feature is not clean after final review.' }
$MoeRailFeatureSha = (git rev-parse HEAD).Trim()
"MOERAIL_FEATURE_SHA=$MoeRailFeatureSha"
```

Expected: a clean, reviewed feature `HEAD`. Manual evidence is recorded as `Not required: documentation-only policy migration`; the five live automated processes are still required.

---

### Task 6: Publish, Merge, Synchronize, and Clean Up

**Files:** No repository file changes

**Interfaces:**

- Consumes: the clean Task 5 feature SHA and both final Sol approvals.
- Produces: a merge commit on `origin/main`, a clean tested local `main`, and no remaining policy feature worktree or feature branch.

- [ ] **Step 1: Run the pre-publication gate before and after fetch**

```powershell
$MoeRailFeature = 'D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy'
$MoeRailPrimary = 'D:\godot\MoeRailWay'
$MoeRailBase = '610c6e1aff52482ddf2edbe5f34529f3f5892263'
$MoeRailCurrentFeatureSha = (git -C $MoeRailFeature rev-parse HEAD).Trim()
$MoeRailCurrentFeatureBranch = (git -C $MoeRailFeature branch --show-current).Trim()
if ($MoeRailFeatureSha -notmatch '^[0-9a-f]{40}$' -or
    $MoeRailCurrentFeatureSha -ne $MoeRailFeatureSha -or
    $MoeRailCurrentFeatureBranch -ne 'feature/main-first-branch-policy') {
    throw 'Current feature branch or HEAD differs from the Task 5 reviewed feature SHA.'
}

'PRIMARY BEFORE PUBLICATION FETCH'
git -C $MoeRailPrimary branch --show-current
git -C $MoeRailPrimary rev-parse HEAD
git -C $MoeRailPrimary rev-parse origin/main
git -C $MoeRailPrimary rev-parse --abbrev-ref '@{upstream}'
git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all
git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825
git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825
git -C $MoeRailPrimary fetch origin main
if ($LASTEXITCODE -ne 0) { throw 'Pre-publication fetch failed.' }

$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailOriginMain = (git -C $MoeRailPrimary rev-parse origin/main).Trim()
$MoeRailPrimaryUpstream = (git -C $MoeRailPrimary rev-parse --abbrev-ref '@{upstream}').Trim()
$MoeRailPrimaryStatus = @(git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all)
$MoeRailFeatureStatus = @(git -C $MoeRailFeature status --porcelain=v1 --untracked-files=all)
$MoeRailSnapshot = (git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825).Trim()
$MoeRailLegacyMain = (git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825).Trim()
if ($MoeRailPrimaryBranch -ne 'main' -or
    $MoeRailPrimaryHead -ne $MoeRailBase -or
    $MoeRailOriginMain -ne $MoeRailBase -or
    $MoeRailPrimaryUpstream -ne 'origin/main' -or
    $MoeRailPrimaryStatus.Count -ne 0 -or
    $MoeRailFeatureStatus.Count -ne 0 -or
    $MoeRailSnapshot -ne '9daec4c053e6e2e7eb05e1abe04d330ea28a41a2' -or
    $MoeRailLegacyMain -ne '71a8ebc23a1171eaef50aaa03bddc02f594fe02c') {
    throw 'Pre-publication state mismatch.'
}
'PRIMARY AFTER PUBLICATION FETCH'
git -C $MoeRailPrimary branch --show-current
git -C $MoeRailPrimary rev-parse HEAD
git -C $MoeRailPrimary rev-parse origin/main
git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all
git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825
git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825
```

Expected: primary and remote `main` remain exactly at the base; the feature is clean. Any mismatch is reported in Korean and stops publication without automatic repair.

- [ ] **Step 2: Push and verify the exact feature branch**

```powershell
git -C $MoeRailFeature push -u origin feature/main-first-branch-policy
if ($LASTEXITCODE -ne 0) { throw 'Feature push failed.' }
$MoeRailRemoteFeature = ((git -C $MoeRailFeature ls-remote origin refs/heads/feature/main-first-branch-policy) -split "`t")[0]
if ($MoeRailRemoteFeature -ne $MoeRailFeatureSha) { throw 'Remote feature SHA mismatch.' }
```

- [ ] **Step 3: Create the pull request with complete evidence**

```powershell
$MoeRailTaskCommits = git -C $MoeRailFeature log --reverse --format='- `%H` %s' "$MoeRailBase..$MoeRailFeatureSha"
$MoeRailPrTemplate = @'
## Canonical sources
- Design: `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`
- Plan: `docs/superpowers/plans/2026-08-25-main-first-branch-management.md`

## Revisions
- Base: `__BASE_SHA__`
- Feature: `__FEATURE_SHA__`

## Ordered commits
__TASK_COMMITS__

## Task evidence and reviews
- Task 1: RED confirmed the active `Prototyping` instruction; GREEN confirmed the main-first agent contract; specification and quality reviews returned `APPROVED: no actionable findings` after any listed correction commit.
- Task 2: RED confirmed the missing supersession link; GREEN proved two exact added Git-blob lines and zero deletions; specification and quality reviews returned `APPROVED: no actionable findings` after any listed correction commit.
- Task 3: RED confirmed the obsolete M1/`Prototyping` README; GREEN confirmed M4/`main`, five test entry points, and current links; specification and quality reviews returned `APPROVED: no actionable findings` after any listed correction commit.
- Task 4: RED confirmed the briefing was absent; GREEN confirmed both English canonical sources, lifecycle, protection refs, and no-tag boundary; specification and quality reviews returned `APPROVED: no actionable findings` after any listed correction commit.
- Final feature review: both independent `gpt-5.6-sol` reviews returned `APPROVED: no actionable findings` for the exact feature SHA.

## Automated evidence
- Godot version: `4.7.1.stable.official.a13da4feb`.
- `PASS: 19 prototype test suite(s)`.
- `PASS: session shell layout integration` and `PASS: session shell lifecycle integration`.
- `PASS: logical track field integration`.
- `PASS: track train input integration`.
- `PASS: track train app integration`.
- Manual evidence: Not required: documentation-only policy migration.

## Residual risk
No runtime-code risk was identified after independent review. Operational documentation drift is mitigated by the exact path, link, history-preservation, and post-merge verification gates.

## Merge contract
Merge commit only; no squash, rebase, or tag.
'@
$MoeRailPrBody = $MoeRailPrTemplate.Replace('__BASE_SHA__', $MoeRailBase).Replace('__FEATURE_SHA__', $MoeRailFeatureSha).Replace('__TASK_COMMITS__', ($MoeRailTaskCommits -join "`n"))
if ($MoeRailPrBody.Contains('__BASE_SHA__') -or
    $MoeRailPrBody.Contains('__FEATURE_SHA__') -or
    $MoeRailPrBody.Contains('__TASK_COMMITS__') -or
    -not $MoeRailPrBody.Contains("- Base: ``$MoeRailBase``") -or
    -not $MoeRailPrBody.Contains("- Feature: ``$MoeRailFeatureSha``")) {
    throw 'Rendered PR body does not contain the exact revisions.'
}
$MoeRailPrBody
$MoeRailPrUrl = (& gh pr create --repo 2ji1/Project_MoeRailWay --base main --head feature/main-first-branch-policy --title 'docs: adopt main-first branch management' --body $MoeRailPrBody).Trim()
if ($LASTEXITCODE -ne 0 -or $MoeRailPrUrl -notmatch '^https://github\.com/2ji1/Project_MoeRailWay/pull/\d+$') {
    throw "PR creation failed: $MoeRailPrUrl"
}
"MOERAIL_PR_URL=$MoeRailPrUrl"
```

- [ ] **Step 4: Inspect current checks and merge state without inventing requirements**

```powershell
$MoeRailPr = gh pr view $MoeRailPrUrl --repo 2ji1/Project_MoeRailWay --json state,mergeable,mergeStateStatus,statusCheckRollup | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $MoeRailPr.state -ne 'OPEN' -or $MoeRailPr.mergeable -eq 'CONFLICTING') {
    throw 'PR is not an open, non-conflicting merge candidate.'
}
$MoeRailFailedChecks = @($MoeRailPr.statusCheckRollup | Where-Object { $_.conclusion -in @('FAILURE', 'CANCELLED', 'TIMED_OUT', 'ACTION_REQUIRED') })
if ($MoeRailFailedChecks.Count -ne 0) { throw 'A reported PR check failed.' }
$MoeRailPendingChecks = @($MoeRailPr.statusCheckRollup | Where-Object { $_.status -ne 'COMPLETED' })
if ($MoeRailPendingChecks.Count -ne 0) {
    gh pr checks $MoeRailPrUrl --repo 2ji1/Project_MoeRailWay --watch
    if ($LASTEXITCODE -ne 0) { throw 'A required PR check did not pass.' }
}
```

Expected: no reported failed check or merge conflict. This gate does not invent a check count or substitute GitHub state for the already completed Sol reviews.

- [ ] **Step 5: Request automatic merge-commit integration and wait for it**

```powershell
gh pr merge $MoeRailPrUrl --repo 2ji1/Project_MoeRailWay --auto --merge --match-head-commit $MoeRailFeatureSha
if ($LASTEXITCODE -ne 0) { throw 'Automatic merge is unavailable or was rejected; do not merge manually.' }
$MoeRailMerged = $null
for ($MoeRailPoll = 0; $MoeRailPoll -lt 120; $MoeRailPoll++) {
    $MoeRailMerged = gh pr view $MoeRailPrUrl --repo 2ji1/Project_MoeRailWay --json state,mergeCommit | ConvertFrom-Json
    if ($MoeRailMerged.state -eq 'MERGED') { break }
    Start-Sleep -Seconds 5
}
if ($MoeRailMerged.state -ne 'MERGED' -or -not $MoeRailMerged.mergeCommit.oid) {
    throw 'PR did not reach MERGED through automatic merge.'
}
$MoeRailMergeSha = $MoeRailMerged.mergeCommit.oid
$MoeRailRemoteMain = ((git -C $MoeRailFeature ls-remote origin refs/heads/main) -split "`t")[0]
if ($MoeRailRemoteMain -ne $MoeRailMergeSha) { throw 'Remote main does not equal the PR merge commit.' }
"MOERAIL_MERGE_SHA=$MoeRailMergeSha"
```

Expected: the PR reaches `MERGED` through `--auto --merge`. No tag is created and the attached feature branch is not deleted yet.

- [ ] **Step 6: Record, refresh, verify parents, and fast-forward the primary workspace**

```powershell
'PRIMARY BEFORE POST-MERGE FETCH'
git -C $MoeRailPrimary branch --show-current
git -C $MoeRailPrimary rev-parse HEAD
git -C $MoeRailPrimary rev-parse origin/main
git -C $MoeRailPrimary rev-parse --abbrev-ref '@{upstream}'
git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all
git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825
git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825
git -C $MoeRailPrimary fetch origin main
if ($LASTEXITCODE -ne 0) { throw 'Post-merge fetch failed.' }

$MoeRailPrimaryBranch = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHead = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailOriginMain = (git -C $MoeRailPrimary rev-parse origin/main).Trim()
$MoeRailPrimaryUpstream = (git -C $MoeRailPrimary rev-parse --abbrev-ref '@{upstream}').Trim()
$MoeRailPrimaryStatus = @(git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all)
$MoeRailSnapshot = (git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825).Trim()
$MoeRailLegacyMain = (git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825).Trim()
$MoeRailParents = ((git -C $MoeRailPrimary rev-list --parents -n 1 $MoeRailMergeSha).Trim() -split ' ')
if ($MoeRailPrimaryBranch -ne 'main' -or
    $MoeRailPrimaryHead -ne $MoeRailBase -or
    $MoeRailOriginMain -ne $MoeRailMergeSha -or
    $MoeRailPrimaryUpstream -ne 'origin/main' -or
    $MoeRailPrimaryStatus.Count -ne 0 -or
    $MoeRailParents.Count -ne 3 -or
    $MoeRailParents[1] -ne $MoeRailBase -or
    $MoeRailParents[2] -ne $MoeRailFeatureSha -or
    $MoeRailSnapshot -ne '9daec4c053e6e2e7eb05e1abe04d330ea28a41a2' -or
    $MoeRailLegacyMain -ne '71a8ebc23a1171eaef50aaa03bddc02f594fe02c') {
    throw 'Post-merge parent or primary-state contract failed.'
}
'PRIMARY AFTER POST-MERGE FETCH'
git -C $MoeRailPrimary branch --show-current
git -C $MoeRailPrimary rev-parse HEAD
git -C $MoeRailPrimary rev-parse origin/main
git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all
git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825
git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825
git -C $MoeRailPrimary merge --ff-only origin/main
if ($LASTEXITCODE -ne 0) { throw 'Primary fast-forward failed.' }
if ((git -C $MoeRailPrimary rev-parse HEAD).Trim() -ne $MoeRailMergeSha) { throw 'Primary HEAD mismatch after fast-forward.' }
```

- [ ] **Step 7: Run the exact five gates in the primary project**

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay\godot-project-moe-rail-way'
$MoeRailVersion = ((& $MoeRailGodot --version 2>&1) -join "`n").Trim()
if ($LASTEXITCODE -ne 0 -or $MoeRailVersion -ne '4.7.1.stable.official.a13da4feb') {
    throw "Unexpected post-merge Godot version: $MoeRailVersion"
}
$MoeRailCases = @(
    @{ Script = 'res://tests/run_all.gd'; Markers = @('PASS: 19 prototype test suite(s)') },
    @{ Script = 'res://tests/integration/run_session_shell_integration.gd'; Markers = @('PASS: session shell layout integration', 'PASS: session shell lifecycle integration') },
    @{ Script = 'res://tests/integration/run_logical_track_field_integration.gd'; Markers = @('PASS: logical track field integration') },
    @{ Script = 'res://tests/integration/run_track_train_input_integration.gd'; Markers = @('PASS: track train input integration') },
    @{ Script = 'res://tests/integration/run_track_train_app_integration.gd'; Markers = @('PASS: track train app integration') }
)
foreach ($MoeRailCase in $MoeRailCases) {
    $MoeRailOutput = @(& $MoeRailGodot --headless --path $MoeRailProject --script $MoeRailCase.Script 2>&1)
    $MoeRailExit = $LASTEXITCODE
    $MoeRailText = $MoeRailOutput -join "`n"
    $MoeRailOutput
    $MoeRailBad = @($MoeRailOutput | Where-Object { $_ -match '^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|CRASH:)' })
    $MoeRailMissing = @($MoeRailCase.Markers | Where-Object { $MoeRailText -notmatch [regex]::Escape($_) })
    if ($MoeRailExit -ne 0 -or $MoeRailBad.Count -ne 0 -or $MoeRailMissing.Count -ne 0) {
        throw "Post-merge primary gate failed: $($MoeRailCase.Script)"
    }
}
$MoeRailPrimaryStatus = @(git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all)
if ($MoeRailPrimaryStatus.Count -ne 0 -or
    -not (Test-Path -LiteralPath 'D:\godot\MoeRailWay\godot-project-moe-rail-way\project.godot')) {
    throw 'Primary is not clean and playable after verification.'
}
```

- [ ] **Step 8: Revalidate the exact worktree target and clean up from primary**

```powershell
Set-Location -LiteralPath $MoeRailPrimary
if ([IO.Path]::GetFullPath((Get-Location).Path) -ne [IO.Path]::GetFullPath($MoeRailPrimary)) {
    throw 'Cleanup is not running from the exact primary workspace.'
}
$MoeRailExpectedWorktree = [IO.Path]::GetFullPath('D:\godot\MoeRailWay-worktrees\feature-main-first-branch-policy')
$MoeRailResolvedWorktree = [IO.Path]::GetFullPath($MoeRailFeature)
$MoeRailWorktrees = (git -C $MoeRailPrimary worktree list --porcelain) -join "`n"
$MoeRailPorcelainPath = $MoeRailExpectedWorktree.Replace('\', '/')
$MoeRailWorktreeRecordPattern = '(?m)^worktree ' + [regex]::Escape($MoeRailPorcelainPath) + '\r?$'
$MoeRailSnapshotBeforeCleanup = (git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825).Trim()
$MoeRailLegacyMainBeforeCleanup = (git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825).Trim()
$MoeRailFeatureBranchBeforeCleanup = (git -C $MoeRailFeature branch --show-current).Trim()
$MoeRailFeatureHeadBeforeCleanup = (git -C $MoeRailFeature rev-parse HEAD).Trim()
$MoeRailLocalFeatureBeforeCleanup = (git -C $MoeRailPrimary rev-parse refs/heads/feature/main-first-branch-policy).Trim()
$MoeRailPrimaryBranchBeforeCleanup = (git -C $MoeRailPrimary branch --show-current).Trim()
$MoeRailPrimaryHeadBeforeCleanup = (git -C $MoeRailPrimary rev-parse HEAD).Trim()
$MoeRailPrimaryUpstreamBeforeCleanup = (git -C $MoeRailPrimary rev-parse --abbrev-ref '@{upstream}').Trim()
$MoeRailPrimaryStatusBeforeCleanup = @(git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all)
$MoeRailRemoteFeatureQuery = @(git -C $MoeRailPrimary ls-remote origin refs/heads/feature/main-first-branch-policy)
if ($LASTEXITCODE -ne 0) { throw 'Remote feature identity query failed before cleanup.' }
$MoeRailRemoteFeatureShaBeforeCleanup = if ($MoeRailRemoteFeatureQuery.Count -eq 0) { $null } else { ($MoeRailRemoteFeatureQuery[0] -split "`t")[0] }
$MoeRailRemoteMainQuery = @(git -C $MoeRailPrimary ls-remote origin refs/heads/main)
if ($LASTEXITCODE -ne 0 -or $MoeRailRemoteMainQuery.Count -ne 1) { throw 'Remote main identity query failed before cleanup.' }
$MoeRailRemoteMainBeforeCleanup = ($MoeRailRemoteMainQuery[0] -split "`t")[0]
if ($MoeRailResolvedWorktree -ne $MoeRailExpectedWorktree -or
    $MoeRailResolvedWorktree -notlike 'D:\godot\MoeRailWay-worktrees\*' -or
    $MoeRailWorktrees -notmatch $MoeRailWorktreeRecordPattern -or
    @(git -C $MoeRailFeature status --porcelain=v1 --untracked-files=all).Count -ne 0 -or
    $MoeRailFeatureBranchBeforeCleanup -ne 'feature/main-first-branch-policy' -or
    $MoeRailFeatureHeadBeforeCleanup -ne $MoeRailFeatureSha -or
    $MoeRailLocalFeatureBeforeCleanup -ne $MoeRailFeatureSha -or
    ($null -ne $MoeRailRemoteFeatureShaBeforeCleanup -and $MoeRailRemoteFeatureShaBeforeCleanup -ne $MoeRailFeatureSha) -or
    $MoeRailPrimaryBranchBeforeCleanup -ne 'main' -or
    $MoeRailPrimaryHeadBeforeCleanup -ne $MoeRailMergeSha -or
    $MoeRailPrimaryUpstreamBeforeCleanup -ne 'origin/main' -or
    $MoeRailPrimaryStatusBeforeCleanup.Count -ne 0 -or
    $MoeRailRemoteMainBeforeCleanup -ne $MoeRailMergeSha -or
    $MoeRailSnapshotBeforeCleanup -ne '9daec4c053e6e2e7eb05e1abe04d330ea28a41a2' -or
    $MoeRailLegacyMainBeforeCleanup -ne '71a8ebc23a1171eaef50aaa03bddc02f594fe02c') {
    throw 'Feature worktree cleanup target failed revalidation.'
}
git -C $MoeRailPrimary worktree remove -- $MoeRailFeature
if ($LASTEXITCODE -ne 0) { throw 'Feature worktree removal failed.' }
if ((git -C $MoeRailPrimary rev-parse refs/heads/feature/main-first-branch-policy).Trim() -ne $MoeRailFeatureSha) {
    throw 'Local feature ref changed before branch deletion.'
}
git -C $MoeRailPrimary branch -d feature/main-first-branch-policy
if ($LASTEXITCODE -ne 0) { throw 'Local feature branch deletion failed.' }
$MoeRailRemoteFeatureBeforeDelete = @(git -C $MoeRailPrimary ls-remote origin refs/heads/feature/main-first-branch-policy)
if ($LASTEXITCODE -ne 0) { throw 'Remote feature identity query failed before branch deletion.' }
if ($MoeRailRemoteFeatureBeforeDelete.Count -ne 0) {
    if (($MoeRailRemoteFeatureBeforeDelete[0] -split "`t")[0] -ne $MoeRailFeatureSha) {
        throw 'Remote feature branch advanced or was repurposed before deletion.'
    }
    git -C $MoeRailPrimary push --force-with-lease=refs/heads/feature/main-first-branch-policy:$MoeRailFeatureSha origin :refs/heads/feature/main-first-branch-policy
    if ($LASTEXITCODE -ne 0) { throw 'Lease-bound remote feature branch deletion failed; the ref may have changed.' }
}
$MoeRailRemoteFeatureAfterDelete = @(git -C $MoeRailPrimary ls-remote origin refs/heads/feature/main-first-branch-policy)
if ($LASTEXITCODE -ne 0) { throw 'Remote feature deletion verification query failed.' }
if ($MoeRailRemoteFeatureAfterDelete.Count -ne 0) { throw 'Remote feature branch still exists.' }
if (@(git -C $MoeRailPrimary show-ref --verify refs/remotes/origin/feature/main-first-branch-policy 2>$null).Count -ne 0) {
    git -C $MoeRailPrimary branch -dr origin/feature/main-first-branch-policy
    if ($LASTEXITCODE -ne 0) { throw 'Exact remote-tracking feature ref deletion failed.' }
}

$MoeRailSnapshot = (git -C $MoeRailPrimary rev-parse local/user-workspace-snapshot-20260825).Trim()
$MoeRailLegacyMain = (git -C $MoeRailPrimary rev-parse local/legacy-main-before-sync-20260825).Trim()
$MoeRailRemainingFeatureRef = @(git -C $MoeRailPrimary show-ref --verify refs/heads/feature/main-first-branch-policy 2>$null)
$MoeRailRemainingRemoteRef = @(git -C $MoeRailPrimary show-ref --verify refs/remotes/origin/feature/main-first-branch-policy 2>$null)
if (Test-Path -LiteralPath $MoeRailFeature) { throw 'Feature worktree path still exists.' }
if ($MoeRailRemainingFeatureRef.Count -ne 0 -or $MoeRailRemainingRemoteRef.Count -ne 0) { throw 'A feature ref remains.' }
if ($MoeRailSnapshot -ne '9daec4c053e6e2e7eb05e1abe04d330ea28a41a2' -or
    $MoeRailLegacyMain -ne '71a8ebc23a1171eaef50aaa03bddc02f594fe02c') {
    throw 'A local safety ref changed.'
}
if (@(git -C $MoeRailPrimary status --porcelain=v1 --untracked-files=all).Count -ne 0 -or
    (git -C $MoeRailPrimary rev-parse HEAD).Trim() -ne $MoeRailMergeSha) {
    throw 'Final primary state mismatch.'
}
```

Expected: only the exact validated feature worktree and feature refs are removed. The primary project remains clean at the merge commit and both safety refs retain their exact SHAs.

- [ ] **Step 9: Report the final integrated result in Korean**

Report the PR URL, feature SHA, merge SHA and both parents, all five fresh primary test results, the playable project path, local/remote branch and worktree cleanup, both unchanged safety refs, and the explicit fact that no tag was created.
