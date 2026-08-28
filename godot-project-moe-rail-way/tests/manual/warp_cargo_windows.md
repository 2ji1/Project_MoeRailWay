# Warp Cargo Windows Manual Verification

Run this checklist only after the exact final feature HEAD passes every automated gate. Keep screenshots and the completed evidence table outside the repository.

## Fixed setup

- Godot: `4.7.1.stable.official.a13da4feb`
- Scene: `res://tests/integration/warp_cargo_app.tscn`
- Visible deterministic driver: `res://tests/integration/run_warp_cargo_integration.gd -- --manual`
- Startup seed: `73013` (`1.5..16.5` second test lifetime range)
- Window sizes: `960x540`, `1280x720`, `1600x900`, and `1920x1080`

In PowerShell, define the fixed local paths once:

```powershell
$Godot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$Project = 'D:\godot\MoeRailWay-worktrees\warp-cargo\godot-project-moe-rail-way'
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
| `64` | Impossible exact contacts remain unloaded; pair 3 remains active and cargo remains `1 / 2`. |
| `120` | Pair 1 expires unloaded, reward remains `0`, and cargo remains `1 / 2`. |
| `121` | Pair 4 forecast appears at the seeded cells shown in the panel without correction. |
| `123` | Pair 4 activates with its original seeded lifetime facts. |
| `126` | Pair 4 loads at its exact origin center into slot 1 and cargo reaches `2 / 2`. |
| `138` | Pair 2 is in transit with `1s`, immediately before final-life delivery. |
| `139` | Pair 2 expires before completion voids the remaining live pairs; cargo is `0 / 2` and reward remains `0`. |
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

## Evidence header

Record the exact feature HEAD, tester, UTC timestamp, Godot version, startup seed, observed tick trace, every tested window size, pass/fail result, and absolute screenshot paths in task-owned evidence outside this repository.

## Evidence checklist

1. Confirm forecast endpoints use matching color and shape, low alpha, and readable whole-second `F <seconds>s` text.
2. Confirm active origins are filled, destinations are outlined, and lifetime countdowns remain readable.
3. Confirm exact-center loading changes the origin to outline-only and fills the matching cargo slot without stealing mouse input from track drawing.
4. Confirm empty, full, and mixed cargo-slot states are distinguishable and the HUD reads `occupied / total`.
5. Confirm the fixed-seed exact-contact trace loads pair 2 into slot 0 and pair 4 into slot 1.
6. Confirm expiry clears matching cargo without reward, fine, or failure text.
7. Confirm an origin behind the train is not rerolled or corrected, and locked impossible contact remains visible as a missed opportunity until expiry.
8. Confirm regular expiry removes every live field endpoint, clears all cargo slots, retains earned delivery/reward totals, and adds no penalty text.
9. Repeat mouse-only drawing, held extension, rebranch, right-click cancellation, endpoint reshaping, exact-center snapping, planning slowdown, and departure dissolve at every required window size; Warp Cargo visuals must never intercept input.
