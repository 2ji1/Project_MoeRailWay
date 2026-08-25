# Manual Test Record: Grid Track & Train (Windows)

**Date:** 2026-08-24
**OS:** Windows 11 Home build 26200
**Godot:** 4.7.1.stable.official.a13da4feb
**Tester:** Codex
**Candidate base:** 657891e73e9b177c1bba7d61d5b901ec679c453b
**Isolated project:** `D:\godot\MoeRailWay-worktrees\proto-03-grid-track-amendment\godot-project-moe-rail-way`
**Target window:** Moe Rail Way Prototype (DEBUG)
**Source process:** pinned non-Steam Godot (Steam editor untouched)
**Window closed:** normally with Alt+F4

## Direct interactive observations

- Project configuration and window capture at **1280x720**.
- Initial HUD: **TIME 3:00**, **TRACK 18/18**, **TRACK END 0/9**.
- New strokes were accepted only at endpoints.
- A diagonal pointer stroke rasterized to orthogonal cells and displayed a fitted **1x1 curve** with no diagonal segment.
- Curve-to-straight continuation behaved as expected.
- Inventory decremented in exact integer cells: **18 -> 16 -> 12 -> 8**.
- A translucent reserved tail, progressive active-cell fade, and atomic dark built geometry were visible.
- The exact **9/9** departure threshold was reached.
- Continuous train travel was visible.
- An incomplete next cell triggered **TRACK END REACHED**.
- A noninteractive result overlay appeared.
- Pointer, endpoint square, and track centerline alignment was preserved.

## Automated observation-backed coverage

All automated commands exited with code **0**:

- `res://tests/run_all.gd`: **PASS: 19 prototype test suite(s)**
- Session shell layout and lifecycle integration: **PASS**
- Logical track field integration: **PASS**
- Track-train input integration: **PASS**
- Track-train app integration: **PASS**

Registered suites and observation APIs cover the following items. These are automation-backed and were not all directly clicked during the interactive run:

- Visible **1x1**, **2x2**, and **3x3** curve fitting.
- Close-curve downgrade without overlap.
- No inventory double charge on ghost reclassification.
- Reflow followed by per-piece locking while later unlocked pieces continue to reflow.
- Nominal curved travel.
- Track-end failure when the next cell is still building.
- One-cell refund behind the train.
- Integer HUD and pointer alignment at **960x540**, **1280x720**, and **1920x1080**.
- Centered **COMPACT**, **STANDARD**, and **EXPANSIVE** alignment among pointer, curve centerline, rendered route, and train.

## Result

**PASS.** No skip markers or unsupported production abstractions were observed. The cleanup scan was pending only this record rewrite.

## Task 3 reflowable track-head evidence — 2026-08-26

**Durable tested implementation SHA:** `f72534e7e6aa6398b7071b8489d3b779e3d6cc66`
**Godot:** `4.7.1.stable.official.a13da4feb`
**Launcher source:** preserved task-owned local-`main` wrapper, with a sanitized local bare origin and a clean `main` clone at the durable tested implementation SHA.
**Window closed:** the task-owned debug game and then the task-owned editor were closed normally; no user-owned Godot or Steam process was targeted.

### Direct Task 3 observations

- I slowly built B through F/G: the route started horizontally, then reflowed into a downward turn.
- While F was being built and reclassified, the B–E interval remained one solid dark fitted piece; no provisional ghost styling appeared on that built interval.
- The synchronized G support cell showed no cancel-hover indication. A right click on G left the route and `TRACK END 6/9` unchanged.
- Dragging from G to the following cell succeeded, proving that the synchronized support remained a valid endpoint for extension (`TRACK END 7/9`).
- A deliberately rejected drag starting from a non-endpoint left the preceding seven-cell route and its `TRACK END 7/9` state unchanged.
- At the exact `9/9` departure threshold, the red train entered from the departure along the rendered track without a placement jump; its terminal snapshot was observed at the final head before the `SESSION COMPLETE` / `TRACK END REACHED` result overlay.

### Launcher result

- Exit: `0`
- `PASS: editor playtest completed`
- `DIAGNOSTICS_SCANNED: 6`

**PASS.** All required Task 3 route, reflow, hover/cancel, extension, rejected-input, train-entry, and terminal-order observations were completed against the durable tested implementation SHA.
