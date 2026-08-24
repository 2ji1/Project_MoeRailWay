# Main-First Feature Branch Management Design

**Date:** 2026-08-25
**Status:** Approved for implementation

## 1. Outcome

`main` becomes MoeRailWay's only active integration branch and the branch used for local playtesting. All new feature work starts from the latest verified `main`, proceeds on a short-lived `feature/*` branch in a dedicated external worktree, and returns through a reviewed pull request. The pull request preserves its task commits and is merged with a merge commit.

When no repository transition is in progress, `D:\godot\MoeRailWay` is a clean checkout of local `main` tracking `origin/main`. The project at `D:\godot\MoeRailWay\godot-project-moe-rail-way` is therefore the immediately playable integrated build.

This user-approved document defines the target policy but has no active operational authority yet. The recorded M4 synchronization and safety refs already exist. This document becomes the canonical branch-management source only after it is merged together with the accompanying implementation work.

## 2. Scope and Authority

After merge, this document is the canonical English source for branch management, feature integration, and primary-workspace synchronization and applies to human contributors, agents, and automation operating in this repository. Until then, it is an approved candidate canonical source and must not be treated as binding policy.

It supersedes only the branch topology, integration-base, and active delivery policy in `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md`. That document remains authoritative for product direction, runtime architecture, test strategy, and the production-handoff boundary except where this document explicitly changes branch use.

Agent-facing specifications, plans, task reports, reviews, and operating instructions remain English. Korean briefings are user-review aids. Each Korean briefing must name or link its English canonical document and must not become an implementation source of truth.

Historical plans, task evidence, and milestone records describe the workflow used at the time. They must not be rewritten to imply that past work used this policy. A concise supersession notice may be added where old active-policy wording could otherwise direct new work incorrectly.

## 3. Branch and Workspace Invariants

1. `main` is the sole active integration and playtest branch.
2. The primary workspace at `D:\godot\MoeRailWay` is reserved for the clean local `main` checkout when idle. Feature implementation does not occur there.
3. Local `main` tracks `origin/main`, equals the current verified `origin/main` before a feature is created, and is updated only by a verified fast-forward. Its history is never rewritten to force a synchronization or integration to succeed.
4. Every feature branch is named under `feature/*`, starts from the latest verified `main`, and is checked out in its own dedicated external worktree.
5. Individual task commits are retained in feature history. Feature pull requests are not squash-merged or rebase-merged.
6. Direct commits or pushes to `main` are prohibited. An explicitly approved repository recovery or one-time migration may be a narrowly scoped exception only when a separate plan and separate user approval authorize its exact operations. The exception is not standing permission, cannot be inferred from ordinary workflow approval, and cannot bypass adoption of this policy.
7. `Prototyping`, `Development`, and existing `proto/*` branches are legacy read-only references for new work. New work does not start from them and is not integrated into them.
8. `Prototyping` is never merged wholesale into `Development`. Reusable prototype findings may enter later production work only through explicitly reviewed production specifications and ports.
9. Milestone tags are created only when an approved plan explicitly requires a tag and only after the merged `main` commit passes the plan's release gate.
10. User-owned changes and local safety refs are never treated as feature inputs or integration material without explicit user approval.

## 4. Operational Workflow

### 4.1 Start a feature

Before work begins, record the primary workspace's branch, `HEAD`, upstream, porcelain status, relevant refs, and current relationship to `origin/main`. Refresh the remote-tracking state without changing the primary branch, index, or working-tree content, then record those fields again so every observed remote-ref movement remains visible.

The primary workspace must be clean, checked out on local `main`, configured to track `origin/main`, and exactly equal to the current verified `origin/main`. The required integrated baseline must pass at that exact commit. Any difference or baseline failure stops feature creation; merely being capable of a later fast-forward is insufficient.

Only after that gate passes, create `feature/<name>` from the exact verified commit and attach it to a new external worktree. Record the base commit and worktree path in the feature plan or preflight evidence. Run the plan's worktree baseline checks before changing files. A worktree baseline mismatch stops the feature before implementation.

### 4.2 Execute each planned task

Each task follows the order below:

1. Produce and run the task's test or executable contract to obtain a relevant RED result.
2. Make the minimum implementation needed to reach GREEN.
3. Run the task-specific checks and every regression check required at that point by the canonical plan.
4. Compare changed paths with the task's explicit file allowlist.
5. Stage only the exact allowed paths for that task and inspect the staged diff.
6. Create one focused task commit that preserves the RED/GREEN unit of work.
7. Obtain an independent specification review and an independent quality review.
8. Address rejected findings on the same feature branch with traceable follow-up commits and repeat affected gates.

No task may absorb an unrelated primary-workspace change or widen its file allowlist implicitly. If implementation exposes a contradiction or requires a new path, the English canonical plan must be amended and approved according to its governance before that expanded work continues.

### 4.3 Complete the feature

After all tasks have passed their gates, run the feature's complete automated regression gate and every required manual verification. Confirm that the feature worktree is clean, that its commits are based on the approved `main`, and that the final changed-path set is permitted by the plan.

Push the feature branch and open a pull request targeting `main`. Do not open the pull request against `Prototyping`, `Development`, or a `proto/*` branch.

### 4.4 Merge and synchronize

The pull request becomes mergeable only after all plan-required checks and independent reviews pass. It is then merged automatically with a merge commit. Squash merge and rebase merge are prohibited because the task commits are review and audit evidence. The exact merge commit and its parents are recorded before local synchronization.

Immediately after the remote merge:

1. Record the primary branch, `HEAD`, upstream, porcelain status, relevant refs, and current local/remote relationship before refreshing remote state.
2. Refresh the remote-tracking state without changing the primary branch, index, or working-tree content, then record the same fields again. Do not hide or omit any remote-ref movement.
3. Require the primary workspace to remain clean, checked out on local `main`, and configured to track `origin/main`. Require its `HEAD` to equal the recorded first parent of the pull request's merge commit.
4. Require the refreshed `origin/main` to equal the exact recorded merge commit, then fast-forward local `main` in `D:\godot\MoeRailWay` to that commit. Do not merge, rebase, reset, or rewrite local `main`.
5. Run the complete automated gate in the primary checkout.
6. Verify that the primary checkout is clean and that `D:\godot\MoeRailWay\godot-project-moe-rail-way` is the integrated playable project.
7. Only after those checks pass, remove the feature worktree and delete the local and remote feature branches.

A check, review, merge, synchronization, or post-merge verification failure stops the workflow and preserves evidence. Cleanup does not run while evidence or a repair branch is still needed.

## 5. Task and Review Gates

RED evidence must demonstrate the missing or defective behavior described by the task. A parse error, unrelated assertion, host crash, or unauthorized diagnostic does not satisfy RED unless the canonical plan explicitly defines it as the expected result.

GREEN must be the smallest concrete implementation that satisfies the approved task. Prototype code remains specific to the prototype; the task must not introduce speculative production abstractions.

The file allowlist is a hard boundary. Before each commit, the changed and staged path sets must be compared with that task's allowlist. Unexpected paths stop the commit until their ownership and scope are resolved.

The specification review checks the implementation and evidence against the canonical English specification and plan. The quality review checks correctness, maintainability, test quality, and relevant failure handling. Both reviews must be independent of the implementation work and must report actionable findings by severity or explicitly approve with no findings.

Review is not a terminal afterthought. A failed review returns work to the same feature branch. Corrections receive focused commits, affected tests are rerun, and both the changed scope and the relevant review gate are re-evaluated. Existing task commits are preserved rather than rewritten away.

## 6. Pull Request and Merge Contract

Every feature pull request must include:

- the canonical English plan and relevant specification references;
- the feature base and final feature `HEAD`;
- a summary of task commits in execution order;
- RED, GREEN, full automated regression, and required manual-verification evidence;
- the independent specification-review outcome;
- the independent quality-review outcome;
- any residual risk or an explicit statement that none was identified;
- the intended merge method: merge commit.

The pull request targets `main`. New commits that answer review findings remain on the same feature branch and repeat the affected checks. Automatic merge may be enabled only after the required evidence and approvals are current. The resulting merge commit, its parents, and its presence on `origin/main` are verified before local synchronization begins.

## 7. Primary Workspace Protection

Before any branch switch, synchronization, or integration affecting `D:\godot\MoeRailWay`, record at minimum:

- the current branch and exact `HEAD`;
- the configured upstream;
- porcelain status, including untracked paths;
- the relevant local and remote refs before and after any remote refresh;
- exact paths and content hashes required by the active protection contract;
- the relationship between local `main` and `origin/main`.

A dirty, untracked, staged, or divergent primary state categorically blocks automatic synchronization before ownership is classified. Agents must not stash, reset, format, stage, copy, absorb, move, or delete any affected path for any purpose in the blocked workflow. No tool may modify the primary index or working-tree content to clear or reinterpret the gate. The inherited prohibition on terminating, resetting, or interfering with user-owned Godot or Steam processes remains in force.

An exact-path snapshot branch and commit may be created only after explicit user approval for that specific snapshot. It must include only the approved paths, record their path and content-hash evidence together with its parent and commit hash, and remain local under this policy. Publishing or removing such a preservation ref requires a separately approved policy change rather than ordinary workflow approval. Creating a snapshot does not authorize modifying or deleting the original user work beyond the separately approved transition.

## 8. Failure and Stop Conditions

Stop and report evidence when any of the following occurs:

- the primary branch, `HEAD`, upstream, status, protected hash, or remote relationship differs from the approved preflight;
- the feature baseline or required Godot version differs from the canonical plan;
- RED is caused by an unrelated failure;
- a task changes a path outside its allowlist;
- a required automated or manual gate fails;
- either independent review rejects the current result;
- the pull request cannot merge with the approved merge-commit method;
- a merge conflict requires a policy decision or a history rewrite;
- local `main` cannot fast-forward exactly to `origin/main`;
- post-merge tests fail or the primary workspace is not clean and playable;
- feature cleanup would remove evidence or affect user-owned work.

The report must identify the observed state, expected state, relevant commits and paths, command output or test markers, and a recommended recovery. Do not rewrite `main`, weaken a gate, change merge methods, or discard evidence to continue automatically.

## 9. Transition Plan

The starting integrated state is M4 on `origin/main` through merge commit `610c6e1aff52482ddf2edbe5f34529f3f5892263`. The primary workspace has already been synchronized to that commit and its M4 automated baseline has passed.

Two local preservation refs record pre-policy state:

- `local/user-workspace-snapshot-20260825` at `9daec4c053e6e2e7eb05e1abe04d330ea28a41a2`;
- `local/legacy-main-before-sync-20260825` at `71a8ebc23a1171eaef50aaa03bddc02f594fe02c`.

Both refs remain local under this policy. Publishing or removing either ref requires a separately approved policy change. They are safety evidence, not feature bases or inputs to feature builds.

Policy adoption proceeds on `feature/main-first-branch-policy` from the synchronized M4 `main`. After this design is approved, a separate implementation plan will define exact file allowlists, checks, commits, reviews, pull-request publication, merge, synchronization, and cleanup. No historical implementation plan is mass-edited during the transition.

## 10. Documentation Impact

This design file, `docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md`, is already created as the candidate canonical source. The implementation phase changes only the following four additional paths:

1. Update `AGENTS.md` so future agents use `main` and `feature/*` under this policy.
2. Add a clear, concise supersession notice to `docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md` while preserving its non-branching design authority and historical content.
3. Update `README.md` from its obsolete prototype milestone and branch instructions to the current M4-on-`main` reality and the immediately playable primary project path.
4. Add `docs/briefings/ko/2026-08-25-main-first-branch-management-design-briefing.md`, naming and linking this English canonical design.

All other historical plans, evidence files, and artifacts remain byte-unchanged in this migration. They are not modified, moved, or removed.

## 11. Definition of Done

The migration is complete only when all of the following are true:

- this English design has been reviewed, approved, and committed;
- the approved implementation plan has been executed on `feature/main-first-branch-policy` with its file allowlists and review gates intact;
- `AGENTS.md`, the prior strategy specification, `README.md`, and the Korean briefing agree on the new active policy;
- the feature history preserves its focused commits and passes independent specification and quality reviews;
- a pull request targeting `main` records all required evidence and is merged with a merge commit;
- `origin/main` contains the policy merge, local `main` has been fast-forwarded to it, and the full automated gate passes in `D:\godot\MoeRailWay`;
- the primary workspace is clean and the Godot project there is immediately playable;
- the policy feature worktree and local/remote feature branches are removed only after post-merge verification;
- the two local preservation refs remain intact unless separately approved;
- legacy branches remain read-only and no historical plan has been rewritten as if it followed the new workflow.
