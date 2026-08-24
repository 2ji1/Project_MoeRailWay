# Project MoeRailWay

This repository contains the design documents and Godot prototype foundation for the game described in the canonical specification as **Warp Rail**. It is a Windows PC, mouse-driven, top-down 2D endless-survival concept built around a real-time, single-stroke railway puzzle. The player keeps one train moving through an unstable warp space while balancing route geometry, cargo capacity, contract performance, and company finances.

The project is in early prototype development. The immediate goal is to validate whether the core route-drawing loop remains readable, tense, and strategically interesting before committing to campaign content or production-scale architecture.

> **Current status:** Milestone M4 is integrated on `main`. The playable prototype includes the deterministic session shell, a centered logical-cell grid, mouse-driven endpoint track extension, curve fitting with overlap downgrade, per-cell track inventory, construction and recovery, and continuous movement for one train. Cargo, contracts, hazards, debt, and company economy remain planned work.

## Game Concept

Warp space periodically creates random source-and-destination pairs with finite lifetimes. The train never stops, so the player must continuously extend track from its current endpoint before the train reaches the end of the line.

Track is limited but automatically recovered behind the train. This turns route planning into a moving one-stroke puzzle: a short route may save time but create an expensive self-crossing, while a wide detour may consume too much track or allow a destination to expire.

Cargo handling is automatic. Passing a source loads its matching symbol into an empty cargo slot; passing the paired destination delivers it and frees the slot. The player decides which opportunities to pursue through route choice rather than manual loading menus.

## Core Loop

1. Review cash, debt, company trust, and contract options in the operations screen.
2. Choose a contractor and enter a timed warp session.
3. Draw a continuous route ahead of one constantly moving train.
4. Pick up and deliver random, finite-lifetime cargo pairs.
5. Trade route distance against track stock, cargo slots, hazards, durability, and emergency crossing costs.
6. Settle freight revenue, contract performance, repairs, operating costs, principal, and interest.
7. Reinvest, borrow against earned company trust, or continue saving for later cycles.
8. Repeat until the company can no longer recover from a negative balance.

## Design Pillars

- **One train, always moving.** There is no dispatching layer, stopping command, or multi-train scheduling problem in the prototype.
- **One-stroke route pressure.** Track can only be extended from the active endpoint. Crossing active track is possible only as an expensive, non-branching overpass.
- **Immutable uncertainty.** Warp positions and lifetimes are random. Forecast information may reveal a result early, but the game does not reroll or secretly correct unfavorable outcomes.
- **Automatic handling.** Track recovery, cargo loading, and cargo delivery are automated so the player's attention stays on route decisions.
- **Temporary warp investment.** Track-capacity and cargo-slot purchases made inside a session disappear when warp space resets.
- **Persistent company consequences.** Cash, trust, debt, and recurring expenses survive between sessions.
- **Strategic refusal.** Ignoring an unfavorable contract opportunity is allowed; the cost is the lost chance to meet the session quota.

## Company Layer

Each session can contain cargo from several companies, while the player initially contracts with one. Every successful delivery pays freight revenue, but only the selected contractor contributes to that session's service quota.

Contract performance may exceed 100%. The excess does not increase the cash contract bonus; it builds persistent trust with that company. Trust affects only that company's credit limit. Interest rates remain fixed, and loans may be taken freely from the operations screen once trust has unlocked credit.

Future expansion boundaries reserve surplus-currency sinks without removing the core puzzle. Planned extension points include purchasable train models, persistent office upgrades, and a contract-management department that can raise the simultaneous contract limit while keeping every contract's quota and settlement independent.

## Repository Structure

```text
.
|-- AGENTS.md                         Repository rules for agents
|-- docs/
|   |-- superpowers/specs/            English canonical design specifications
|   |-- superpowers/plans/            English implementation plans
|   `-- briefings/ko/                 Korean user-review briefings
`-- godot-project-moe-rail-way/       Playable Godot prototype project on main
```

The English files under `docs/superpowers` are the implementation source of truth. Korean briefings summarize those documents for user review and are not canonical specifications.

## Branch Model

- **`main`** is the only active integration branch and the local playtest branch.
- **`feature/*`** branches start from the latest verified `main` in dedicated external worktrees and return through reviewed pull requests using merge commits.
- **`Prototyping`**, **`Development`**, and existing **`proto/*`** branches are legacy read-only references for new work. `Prototyping` is never merged wholesale into `Development`.

The canonical workflow is defined in [Main-First Feature Branch Management Design](docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md).

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

## Canonical Documents

- [Warp Rail Endless Survival Prototype Design](docs/superpowers/specs/2026-08-15-warp-rail-prototype-design.md)
- [Prototype Development Strategy](docs/superpowers/specs/2026-08-15-prototype-development-strategy-design.md)
- [Prototype Foundation Plan](docs/superpowers/plans/2026-08-15-prototype-foundation.md)
- [Korean Review Briefings](docs/briefings/ko/)
- [Main-First Feature Branch Management Design](docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md)
- [Main-First Branch Management Implementation Plan](docs/superpowers/plans/2026-08-25-main-first-branch-management.md)
- [Grid Track Amendment Design](docs/superpowers/specs/2026-08-24-prototype-grid-track-amendment-design.md)
- [Grid Track Amendment Plan](docs/superpowers/plans/2026-08-24-prototype-grid-track-amendment.md)

## Current Scope

The integrated M4 scope is a deterministic session shell with one continuously moving train and a playable logical-cell track loop: endpoint-only mouse input, centered grid mapping, curve fitting and overlap downgrade, per-cell reservation and inventory, progressive construction, atomic completion, and ordered recovery. The next prototype slices add warp cargo, risk and investment, contracts and economy, credit survival, and playtest-ready polish. Campaign structure, narrative progression, and production architecture remain outside the current prototype.
