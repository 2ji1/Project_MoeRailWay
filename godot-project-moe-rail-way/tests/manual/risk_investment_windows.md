# Risk & Investment Windows Manual Verification

## Authority and evidence boundary

This checklist applies only to the exact final `feature/risk-investment` commit recorded outside the repository. Automated deterministic evidence does not turn any mouse-only row into PASS. Every mouse-only row remains PENDING until the user directly confirms it.

Use Godot `4.7.1.stable.official.a13da4feb` on Windows PC with mouse-only gameplay. Do not use keyboard gameplay shortcuts, mobile emulation, custom art, or audio as evidence.

## Exact-state record

- Feature commit: PENDING
- Integration base: PENDING
- Fixed seed: `73013`
- Tester: PENDING
- Evidence directory outside the repository: PENDING

## Resolution matrix

| Resolution | Deterministic runner | Mouse-only checklist | User confirmation | Screenshots |
|---|---|---|---|---|
| `960x540` | PENDING | PENDING | PENDING | PENDING |
| `1280x720` | PENDING | PENDING | PENDING | PENDING |
| `1600x900` | PENDING | PENDING | PENDING | PENDING |
| `1920x1080` | PENDING | PENDING | PENDING | PENDING |

## Deterministic checks per resolution

1. Launch the exact committed Risk fixture and confirm the fixed seed produces byte-identical hazard cells, route/crossing observations, cash, durability, purchase counters, terminal snapshot, and result across repeated runs.
2. Confirm the field mapping retains the same logical grid and pointer-to-cell result after resize.
3. Confirm the registered suite runner, every pre-existing integration runner, and the Risk integration runner exit `0`, print their exact anchored PASS markers, and print no anchored error, warning, fatal, script-error, or crash marker.

## Mouse-only checks per resolution

1. Hazard cells remain immediately distinguishable from ordinary terrain by fill, border, and repeated primitive mark at the full field and while track, train, or Warp primitives overlap them.
2. `CASH`, `BASE REWARD`, current/maximum `DURABILITY`, and `REPAIR` basis remain readable and update from live snapshot state.
3. Traveling partly through a hazard and then through multiple hazard cells reduces durability by actual traveled distance. Repeated traversal applies damage again.
4. Reaching zero durability presents exactly one `DURABILITY DEPLETED` result after same-sweep Warp contact and before time or track-end completion.
5. Right-clicking a `RESERVED_GHOST` suffix shows free feedback, cancels from the selected occurrence through the endpoint, refunds every removed track cell, and never changes cash.
6. Right-clicking eligible `BUILDING` or `BUILT` front suffix and retained rear prefix shows paid feedback, charges the shared major-action cost exactly once, and refunds removed track cells.
7. At a crossing cell, moving the pointer toward each centerline highlights exactly that occurrence and its affected prefix or suffix. The exact center tie is a no-op.
8. A legal perpendicular complete crossing shows a bridge/gap primitive and exact shared cost. It remains one route and never creates a branch or merge.
9. `BUY TRACK +5 / 40` and `BUY CARGO +1 / 80` apply one exact increment per click, show exact counts/capacities, and become disabled for insufficient cash, purchase limits, active gesture ownership, or completed sessions.
10. Unaffordable demolition, crossing, and purchases leave cash and gameplay state unchanged. Held or repeated frames do not duplicate a priced action.
11. HUD, buttons, hazard marks, hover outlines, crossing feedback, Warp primitives, and result overlay do not block field clicks or corrupt resize-safe mouse mapping.
12. Regular expiry, track-end completion, and durability depletion refund no spent cash. A fresh session returns to base track and cargo capacities and configured starting cash.
