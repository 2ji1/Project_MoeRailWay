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
- The direct controlled replay below confirms the `9/9` train-entry and terminal-order observation with consecutive visible states.

### Observation integrity correction — controlled 1/16x replay

- I used only the task-owned Godot game's built-in playback-rate menu to set `1/16x`; this was a runtime observation control and did not change the source, wrapper, or launcher.
- At `9/9`, the red train was visible at departure. In the following visible state it had advanced into the first locked horizontal segment with the same right-facing heading, rather than appearing at a discontinuous position.
- Successive visible states showed the same red train moving through the middle and approaching the final head. The overlay-free `TRACK END 0.6s` state showed the red train at the terminal head.
- The next visible state displayed `SESSION COMPLETE` / `TRACK END REACHED`, establishing that the terminal snapshot was present before the result overlay.

### Launcher result

- Exit: `0`
- `PASS: editor playtest completed`
- `DIAGNOSTICS_SCANNED: 6`

**PASS.** All required Task 3 route, reflow, hover/cancel, extension, rejected-input, train-entry, and terminal-order observations were completed against the durable tested implementation SHA.

## Final Task 3 evidence correction — 2026-08-26

**Durable tested implementation SHA:** `f72534e7e6aa6398b7071b8489d3b779e3d6cc66`
**Coverage-only view correction SHA:** `b70a8e0ad68a76508178f4f23e47c03a02e7c6e0`
**Coverage-only automated recovery correction SHA:** `9109dca4e9a9d1008940b44425c7d1c60871a683`

The durable tested implementation SHA is the source identified by the preserved task-owned launcher. Neither coverage-only correction SHA is claimed as a launched source. The observations below came from distinct sources and runs; they are not one continuous screenshot sequence and were not all witnessed by one observer.

### Distinct direct task-owned observations

- In a direct task-owned run, synchronized G had no cancel-hover affordance and ignored right click at `TRACK 12/18` and `TRACK END 6/9`.
- In a separate direct task-owned run, ordinary provisional H showed its normal hover affordance at `TRACK 11/18` and `TRACK END 7/9`.
- In another separate direct task-owned immediate cancellation observation, right-clicking H changed `TRACK 11/18` and `TRACK END 7/9` to `TRACK 12/18` and `TRACK END 6/9`. H alone was removed and G remained the endpoint, which is one exact-cell inventory refund.

### Independent user confirmation

The user independently confirmed the combined provisional-hover, right-click cancellation, and `+1` inventory-refund flow. The user also independently confirmed that a later RUNNING curve gesture succeeds when its drag starts from the highlighted endpoint cell. These confirmations are attributed to the user, not to the separate task-owned observation runs above.

### Automated lifecycle boundary and corrected result

The same-candidate provisional-to-lock-to-sequential-recovery serial proof is intentionally not a manual evidence claim: mutually exclusive lifecycle states cannot be established in one manual frame. Coverage-only automated correction `9109dca4e9a9d1008940b44425c7d1c60871a683` supplies that same-serial lifecycle evidence instead.

**Corrected PASS.** This supersedes the preceding broad Task 3 PASS summary only for final evidence attribution. The final manual evidence correction passes only for the exact G/H observations and the separately attributed user confirmations recorded in this section, together with the earlier direct train-entry and terminal-order replay. It does not claim that one screenshot sequence, one run, or one observer proved every hover, cancellation, refund, and running-turn fact.
