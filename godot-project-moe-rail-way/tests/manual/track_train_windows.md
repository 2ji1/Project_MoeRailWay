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
