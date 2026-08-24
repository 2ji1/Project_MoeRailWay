# Repository Instructions for Agents

## Documentation Language

- Write every agent-facing Markdown file in English.
- This includes specifications, implementation plans, task reports, review notes, and operational instructions.
- Treat files under docs/superpowers as agent-facing canonical documents.
- Store Korean user-review briefing documents under docs/briefings/ko.
- A Korean briefing is never the implementation source of truth. It must link to or name its English canonical document.
- Give all progress updates, review summaries, decisions, and final handoffs to the user in Korean.

## Main-First Branch Management

- Use `main` as the only active integration and local playtest branch. Keep `D:\godot\MoeRailWay` as a clean local `main` checkout tracking `origin/main` when no approved transition is in progress.
- Create each `feature/*` branch from the latest verified `main` in a dedicated external worktree. Never implement feature changes directly in the primary `main` checkout.
- For every planned task, preserve RED, minimum GREEN, the explicit file allowlist, exact-path staging, a focused task commit, all required regression tests, and independent specification and quality reviews.
- After all feature gates pass, push the feature branch, open a pull request targeting `main`, and merge automatically with a merge commit only. Then fast-forward and test the primary `main` before cleaning up the feature worktree and local and remote feature branches.
- Treat `Prototyping`, `Development`, and existing `proto/*` branches as legacy read-only references for new work. Never merge `Prototyping` wholesale into `Development`.
- A dirty, untracked, staged, or divergent primary workspace stops automatic work. Never stash, reset, format, stage, copy, absorb, move, or delete its changes to clear the gate.
