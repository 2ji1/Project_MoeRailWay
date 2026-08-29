# Warp Cargo Windows Manual Verification

- Status: Integrated through PR #17 as `prototype-m5`; complete final-head four-size evidence remains outstanding
- Recorded evidence: pre-amendment HEAD `b5d33117d08ed3e14269b353f2a84a72c4f24a0c` passed deterministic and mouse-only verification at all four supported sizes; final reviewed HEAD `402c9a28913acb24047a35cfcd4d5b8c2bb752f1` passed the targeted `1280x720` locked-endpoint anchored-turn regression
- Outstanding evidence: rerun the complete deterministic and mouse-only checklist at `960x540`, `1280x720`, `1600x900`, and `1920x1080` on one exact current integration-candidate commit

This checklist remains the manual regression procedure for the integrated slice. Run it only after the exact candidate `HEAD` passes every automated gate. Keep screenshots and the completed evidence table outside the repository.

## Fixed setup

- Godot: `4.7.1.stable.official.a13da4feb`
- Scene: `res://tests/integration/warp_cargo_app.tscn`
- Visible deterministic driver: `res://tests/integration/run_warp_cargo_integration.gd -- --manual`
- Startup seed: `73013` (`1.5..16.5` second test lifetime range)
- Window sizes: `960x540`, `1280x720`, `1600x900`, and `1920x1080`

In PowerShell, define the fixed local paths once:

```powershell
$Godot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$Project = 'D:\godot\MoeRailWay\godot-project-moe-rail-way'
```

## Deterministic visible run

For each required size, replace `<width>x<height>` and run:

```powershell
& $Godot --path $Project --resolution <width>x<height> --script 'res://tests/integration/run_warp_cargo_integration.gd' -- --manual
```

The driver disables automatic physics, injects the approved 47-cell route on tick 1, advances the same explicit 139 ticks as the automated integration, and pauses at every row below. At each pause, compare the real scene with the checkpoint panel, capture the screenshot, record the result, and then select **Capture evidence, then continue**. The final `result` checkpoint is a presentation phase after tick 139, not a simulated tick.

| Checkpoint | Required visible evidence |
|---|---|
| `1` | Empty cargo; pair 1 forecast uses matching low-alpha color/shape and `F 1s`. |
| `3` | Pair 1 is active with a filled origin, outlined destination, and `12s`. |
| `11` | Pair 2 loads at its exact origin center into slot 0 and the HUD reads `1 / 2`. |
| `13` | Pair 3 remains at the seeded origin/destination shown in the panel; no route correction occurs. |
| `64` | Pair 3 remains active and unloaded immediately before the visible ordered route reaches it; cargo remains `1 / 2`. |
| `67` | Pair 3 loads at its visible ordered-route origin into slot 1 and cargo reaches `2 / 2`. |
| `120` | Pair 1 expires unloaded, reward remains `0`, and cargo remains `2 / 2`. |
| `121` | Pair 4 forecast appears at the seeded cells shown in the panel without correction. |
| `123` | Pair 4 activates with its original seeded lifetime facts. |
| `126` | Pair 4 remains unloaded because pair 2 and pair 3 occupy both cargo slots. |
| `138` | Pair 2 is in transit with `1s`, pair 3 remains in transit, and pair 4 remains active but unloaded. |
| `139` | Pair 2 expires before completion voids in-transit pair 3 and unloaded pair 4; cargo is `0 / 2` and reward remains `0`. |
| `result` | The regular-end result retains reward `0` and adds no penalty, failure, settlement, or action text. |

The checkpoint panel also prints every pair's exact origin, destination, state, and remaining ticks. Use those facts to confirm impossible or behind-train generation is retained rather than rerolled.

## Mouse-input run

After the deterministic run at each size, launch the real scene without the driver:

```powershell
& $Godot --path $Project --resolution <width>x<height> --script 'res://tests/integration/run_warp_cargo_integration.gd' -- --mouse-manual
```

This mouse-only mode leaves the canonical fixed-seed fixture unchanged and applies runtime-only usability values: a `90` second session, train speed `1.5` cells per second, recovery lag `2` cells, and a doubled Warp lifetime range of `3.0..33.0` seconds. Starting at departure cell `(5, 2)`, use only the left mouse button to draw an orthogonally connected route. While Warp endpoints and countdowns are visible, extend from the active endpoint, move backward and rebranch during one held gesture, release to finalize, then begin another held edit and right-click to restore its gesture origin. Clicking or dragging across Warp shapes and the cargo strip must behave exactly like the underlying track field; the Warp presentation must not capture or consume input.

At every size, also complete these control-feel checks:

1. Build a straight route through an active Warp cell and confirm the track passes through the exact center of the Warp marker.
2. Build a turning route through another active Warp cell and confirm the accepted curve passes through the exact marker center without inserting or relocating a route cell.
3. Let a route segment lock off-center before a Warp activates in that cell; confirm the locked curve does not move and the missed opportunity remains visible until lifecycle removal.
4. Start the session and confirm the departure marker is opaque before departure, fades smoothly for about `0.75` real seconds after the train departs, and stays absent afterward.
5. Hold left drag from the active endpoint and confirm `PLANNING 25%` appears near the top-left without overlapping or obscuring track work.
6. While holding, move the pointer continuously and confirm the live route preview responds every rendered update while train travel, track confirmation, recovery, Warp countdowns, and session time advance at one quarter of normal cadence.
7. During the same held edit, let recovery consume eligible pre-gesture track; confirm the candidate and its cancellation origin both retain that recovery, inventory refunds once, and new suffix cells remain editable.
8. Release and repeat with right-click abort; confirm the planning label clears immediately, no simulation catch-up occurs, and neither path resurrects recovered track.
9. Click invalid cells and merely hold after a rejected press; confirm neither case shows the planning label or slows the simulation.
10. Confirm the planning label and departure fade remain readable at this window size and that neither primitive intercepts field input.
11. After rear recovery removes the first route cell and the departure marker has dissolved, guide the active endpoint back beside departure `(5, 2)`. Hold left drag through `(5, 2)` and one following recovered cell, confirm both cells remain in the live preview, then release and confirm both install. If an active Warp occupies `(5, 2)`, confirm the reused track passes through its exact center and the origin marker does not return.
12. Let the train approach closely enough to lock the current endpoint, then start one held drag straight into an adjacent active Warp and turn on the following cell. Continue for at least one more cell before release. Confirm the Warp cell, first turn, and remaining suffix all stay in the live preview and install together without moving the locked track behind them.
13. Build a long orthogonal turn, later route the active endpoint beside one of that curve's owned cells, and attempt to drag back into it. Confirm the earlier curve is visibly present inside the rejected cell; no duplicate-cell rejection may appear to come from empty space.
14. During one completed-head gesture, keep left held while drawing a long suffix and allow a Warp activation, expiry, or other anchor refresh to occur. Backtrack through the published suffix and continue along a new branch without releasing. Confirm the live preview replaces the retired suffix immediately; candidate-local retirement must not freeze the gesture, while track already locked before the press remains unchanged.
15. With spare track inventory, begin a valid endpoint drag and keep the left button held. Move outside the track field, travel along the letterbox or window edge, and reenter at a boundary cell that is not adjacent to the last observed route cell. Confirm the preview fills only the bounded gap with one deterministic orthogonal route, never reuses visible active track, never changes locked geometry, and continues responding before release. Repeat the same physical motion and confirm the connector is identical. If inventory or legal space is insufficient, confirm the last valid preview remains unchanged rather than accepting a jump.
16. Reproduce a locked `2x2` curve whose inclusive rectangular footprint has one visibly empty corner, then route the active endpoint beside that corner and drag into it. Confirm the ordinary route enters the corner even though the locked footprint metadata still contains it. Repeat when an active Warp occupies that same corner: the accepted route must pass through the exact marker center, while the earlier locked curve remains byte-for-byte and visually unchanged. A cell where both centerlines visibly meet must still reject.
17. In one held left-button gesture, reach an active Warp exactly, continue beyond it, then backtrack the pointer before that Warp and draw a different branch without releasing. Confirm the accepted prefix remains attached through the Warp center and the replacement suffix bends from that center even when the current pointer path no longer includes the Warp cell. If a later Warp is contacted in the same gesture, confirm it becomes the deeper editing floor. Let that later Warp expire while still holding: the displayed accepted route and inventory must not change at the expiry instant, and the next pointer update may edit back only as far as any earlier still-active latch. After every contacted Warp expires, the same held gesture may edit through all former contacts. Also let a Warp activate on a pre-gesture nonendpoint route cell while the button remains held; confirm that lifecycle appearance alone does not latch or freeze ordinary endpoint preview, while its active exact geometry rule and every pre-gesture locked piece remain unchanged. Repeat with right-click and confirm the complete pre-gesture route and inventory return while locked track remains unchanged.

## Track local-corner visual addendum

This addendum applies to the `feature/warp-exact-center-local-corners` candidate. Local-corner geometry is Warp-independent: exact-center anchors add literal hard knots to the same curve construction but do not enable it. The user owns the visual and control-feel verdict; automated geometry and presentation tests cannot complete this section.

- Candidate commit: record the exact tested `HEAD`
- Manual owner: user
- Overall result: `PENDING (user-owned)`
- Evidence location: record absolute screenshot paths outside this repository

At every supported window size, first draw Warp-free turns representing the visible `1x1`, `2x2`, and `3x3` ownership scales, then inspect exact-center turns when the fixed-seed run or mouse route makes them available. Confirm all of the following:

1. Every Warp-free `1x1`, `2x2`, and `3x3` owner uses the same straight-spine and local-corner visual rule.
2. Long portions of the owner remain visually straight.
3. Curvature is limited to the actual direction-change neighborhoods.
4. Reproduce the screenshot-reported Warp-free `3x3`: its centerline follows every ordered route cell, with straight runs between cells and rounding only at the actual direction change.
5. No owner-wide S-shaped excursion remains, whether or not a Warp exists on the owner.
6. An exact-anchored turn crosses the literal center of the Warp marker without changing the ordinary local-corner rule elsewhere.
7. The accepted ownership scale does not visibly shrink merely to satisfy the exact anchor.
8. Finalization locks exactly the displayed geometry, and later Warp lifecycle changes do not rewrite it.
9. Loading and delivery each occur once at the exact marker center without changing route cells.
10. Dragging, backtracking, rebranching, release, and right-click cancellation retain the same control feel around the locally rounded track.
11. Reproduce a `2x2` tail that enters its endpoint vertically, then begin separate drags to the left and right neighbors. Confirm both previews publish, their two adjacent unlocked turns settle into visibly separate local corners, locked track does not move, and an exact Warp marker on the right target is crossed through its literal center.
12. Reproduce the `960x540` hidden-ownership report: approach the active endpoint from above while an earlier curve already owns the cell immediately below it. Confirm that earlier curve is visibly present in the owned cell and the rejected downward duplicate no longer appears to target an empty cell.
13. Reproduce the completed-head freeze report: in one held press, publish a long suffix, wait through a Warp anchor refresh, then backtrack and rebranch. Confirm the preview remains editable until release or explicit cancellation; only a lock already authoritative at the gesture origin may reject template mutation.
14. Reproduce the held field-exit report with spare inventory: draw a valid suffix, leave the field while holding left, move outside, and reenter at a nonadjacent boundary cell. Confirm one deterministic orthogonal connector appears immediately, remains subject to ordinary collision and footprint rejection, and does not affect Warp behavior. Repeat from a completed editable head and confirm only the post-template suffix is connected.
15. Reproduce the `1280x720` locked-AABB empty-corner report. First enter the empty corner without a Warp, then repeat with an active Warp in that corner. Confirm both routes publish, the Warp variant adds only its literal center knot, the old locked curve does not move, and a true shared-centerline cell remains blocked.
16. Reproduce the held Warp-latch report: contact a live Warp during the drag, continue beyond it, backtrack before it, and draw a new branch while still holding left. Confirm the prefix cannot detach from the live Warp, the new suffix bends from its exact center, and expiry releases only that gesture-local editing floor without immediately rewriting the accepted route. Repeat with two contacted Warps to confirm the deepest live contact wins and expiry falls back to the earlier live contact.

Record the user-owned result for the exact candidate in this table. Leave a row `PENDING` until that exact size and candidate commit have been checked.

| Window size | 1x1 observed | 2x2 observed | 3x3 observed | Ordered-route spine | Exact center | Local bends only | Adjacent side turns | Owned-cell visibility | Lock stable | Control feel | User result |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `960x540` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING (user-owned)` |
| `1280x720` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING (user-owned)` |
| `1600x900` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING (user-owned)` |
| `1920x1080` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING (user-owned)` |

## Evidence header

Record the exact tested commit, its branch or ref context, tester, UTC timestamp, Godot version, startup seed, observed tick trace, every tested window size, pass/fail result, and absolute screenshot paths in task-owned evidence outside this repository.

## Evidence checklist

1. Confirm forecast endpoints use matching color and shape, low alpha, and readable whole-second `F <seconds>s` text.
2. Confirm active origins are filled, destinations are outlined, and lifetime countdowns remain readable.
3. Confirm exact-center loading changes the origin to outline-only and fills the matching cargo slot without stealing mouse input from track drawing.
4. Confirm empty, full, and mixed cargo-slot states are distinguishable and the HUD reads `occupied / total`.
5. Confirm the fixed-seed exact-contact trace loads pair 2 into slot 0, loads pair 3 into slot 1 at tick `67`, and leaves pair 4 active but unloaded while capacity is full.
6. Confirm expiry clears matching cargo without reward, fine, or failure text.
7. Confirm an origin behind the train is not rerolled or corrected, and locked impossible contact remains visible as a missed opportunity until expiry.
8. Confirm regular expiry removes every live field endpoint, clears all cargo slots, retains earned delivery/reward totals, and adds no penalty text.
9. Repeat mouse-only drawing, held extension, rebranch, right-click cancellation, endpoint reshaping, exact-center snapping, planning slowdown, and departure dissolve at every required window size; Warp Cargo visuals must never intercept input.
