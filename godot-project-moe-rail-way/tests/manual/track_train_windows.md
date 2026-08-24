# Manual Test Record: Track & Train (Windows)

**Date:** 2026-08-24
**OS:** Windows 11 Home build 26200
**Godot:** 4.7.1.stable.official.a13da4feb
**Tester:** Codex
**Task 8 commit:** 9407ae4c45f5836fa3ec7c53a066e5e7c61df980
**Tested HEAD:** 944591a3ef584b02cf1d7ad503c66b8e6288eac7
**Resolutions:** 960x540, 1280x720, 1600x900, 1920x1080
**Editor isolation:** New ordinary-file tracked-only mirror, isolated APPDATA/LOCALAPPDATA/TEMP/TMP, normal close, unchanged feature content/status
**Runtime mirror:** `C:\Users\noisy\AppData\Local\Temp\moerail-track-train-manual-correction-86845e15429d448faec52f895fc83dce\godot-project-moe-rail-way` (117 tracked files, zero SHA mismatch, no `.godot` or untracked files at creation)
**Default run:** preparation 3:00, TRACK 720/720; diagonal route exhausted TRACK END to 0.0/360.0 → TRACK END REACHED; ready duration=180 ticks=60; completion reason TRACK_END_REACHED
**Nondefault run:** `res://tests/integration/nondefault_track_train_app.tscn` — duration=4 ticks=10, TRACK 200/200, required 50; diagonal route → REGULAR TIME EXPIRED; completion reason REGULAR_TIME_EXPIRED elapsed_ticks=40 total_ticks=40
**Host:** D3D12 12_0 Forward+ on NVIDIA GeForce RTX 3060; no host-only warning lines
**Corrections applied:** 98776d9823d47a79ac764aea552d5d114e17fdf9, 2c7c328354f98af7a4d6f879eb8d8fa87acf5760, 29f5d148a9e7e1046cad498d1b76fcf2ae42857f, 536b4c0f2facb73defc767785b9ed7163dde7402, 944591a3ef584b02cf1d7ad503c66b8e6288eac7 (affected checks rerun; corrected observations supersede)
**Correction recheck:** Source `944591a3ef584b02cf1d7ad503c66b8e6288eac7`; at normal speed, immediate projected cancellation of a reserved-unbuilt suffix refunded TRACK once from 53.8/720.0 to 276.0/720.0 and moved the reserved endpoint to the click projection; a separate normal-speed built-track right-click left the route unchanged; the public endpoint/interior float32 regression passed within the 14-suite gate
**Correction logs:** Five agent-owned correction runs had zero anchored `ERROR:`, `SCRIPT ERROR:`, `WARNING:`, `FATAL:`, or `CRASH:` diagnostics; all windows closed normally

- [x] PASS: One seeded departure marker visible, all other authored candidates runtime-invisible, 3:00 frozen in preparation.
- [x] PASS: Left draw only begins at current reserved endpoint; endpoint-outside, HUD, letterbox presses inert.
- [x] PASS: Held drag samples once per fixed tick, reservation immediately decreases inventory, construction follows at configured slower rate after release.
- [x] PASS: Field-exit clipping, outside-held reentry, inventory clipping, active self-intersection clearance preserve one continuous route.
- [x] PASS: Right-click cancels only projected reserved-unbuilt suffix, refunds once/free, ends stroke, fresh left press required.
- [x] PASS: Right-click built/recovered/empty no-op; left never cancels/demolishes.
- [x] PASS: Construction continues while reserved endpoint extended; canceled reservation cannot build same tick.
- [x] PASS: At exactly 360.0 built default units, train and timer advance together first tick.
- [x] PASS: Train never stops/reverses/changes speed; catching built endpoint produces one TRACK END REACHED even with unbuilt reservation ahead.
- [x] PASS: Rear recovery continuous including partial segments; returned inventory drawable following tick.
- [x] PASS: TRACK current/total; preparation built/required; running built-end seconds one decimal; urgency at or below configured 3.0 seconds.
- [x] PASS: REGULAR TIME EXPIRED and TRACK END REACHED each one noninteractive result with no settlement/action button.
- [x] PASS: 960x540, 1280x720, 1600x900, 1920x1080 preserve field dominance, geometry, cursor alignment, no overlap/clipping.
- [x] PASS: Resizing during identical input changes no route length, inventory, construction, train speed, selected candidate ID, timer, result.
- [x] PASS: Godot 2D editor COMPACT, STANDARD, EXPANSIVE, representative CUSTOM update boundary preview and preserve normalized gizmo positions.
- [x] PASS: Candidate nodes independently draggable through 2D transform gizmos and Transform > Position.
- [x] PASS: UI padding Inspector changes layout only, not logical geometry.
- [x] PASS: No paid demolition, crossing, cash mutation, warp, cargo, hazard, durability, contract, credit, restart, debug-end.
