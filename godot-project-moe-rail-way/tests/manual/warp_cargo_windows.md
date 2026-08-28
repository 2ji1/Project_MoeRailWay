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
| `4` | Pair 1 is in transit, origin is outline-only, and slot 0 is filled. |
| `10` | Pair 2 fills slot 1 and the HUD reads `2 / 2`. |
| `13` | Pair 3 remains at the seeded origin/destination shown in the panel; no route correction occurs. |
| `64` | The full-slot pair 3 origin contact is a no-op; pair 3 remains active and cargo remains `2 / 2`. |
| `120` | Pair 1 expires, slot 0 clears, reward remains `0`, and cargo reads `1 / 2`. |
| `121` | Pair 4 forecast appears at the seeded cells shown in the panel without correction. |
| `124` | Pair 4 uses the lowest empty slot 0 and cargo returns to `2 / 2`. |
| `138` | Pair 2 is in transit with `1s`, immediately before final-life delivery. |
| `139` | Pair 2's brief filled destination remains, cargo is `0 / 2`, reward is `37`, and all other live endpoints are absent. |
| `result` | The regular-end result is shown and adds no penalty, failure, settlement, or action text. |

The checkpoint panel also prints every pair's exact origin, destination, state, and remaining ticks. Use those facts to confirm impossible or behind-train generation is retained rather than rerolled.

## Mouse-input run

After the deterministic run at each size, launch the real scene without the driver:

```powershell
& $Godot --path $Project --resolution <width>x<height> 'res://tests/integration/warp_cargo_app.tscn'
```

Starting at departure cell `(5, 2)`, use only the left mouse button to draw an orthogonally connected route. While Warp endpoints and countdowns are visible, extend from the active endpoint, move backward and rebranch during one held gesture, release to finalize, then begin another held edit and right-click to restore its gesture origin. Clicking or dragging across Warp shapes and the cargo strip must behave exactly like the underlying track field; the Warp presentation must not capture or consume input.

## Evidence header

Record the exact feature HEAD, tester, UTC timestamp, Godot version, startup seed, observed tick trace, every tested window size, pass/fail result, and absolute screenshot paths in task-owned evidence outside this repository.

## Evidence checklist

1. Confirm forecast endpoints use matching color and shape, low alpha, and readable whole-second `F <seconds>s` text.
2. Confirm active origins are filled, destinations are outlined, and lifetime countdowns remain readable.
3. Confirm loading changes the origin to outline-only and fills the matching cargo slot without stealing mouse input from track drawing.
4. Confirm empty, full, and mixed cargo-slot states are distinguishable and the HUD reads `occupied / total`.
5. Confirm a full-slot origin contact is a no-op and a later mixed-slot load uses the lowest empty slot.
6. Confirm delivery on the final lifetime tick clears the slot and updates `BASE REWARD` immediately.
7. Confirm expiry clears matching cargo without reward, fine, or failure text.
8. Confirm an origin behind the train is not rerolled or corrected, and locked impossible contact remains visible as a missed opportunity until expiry.
9. Confirm regular expiry removes every live field endpoint, clears all cargo slots, retains earned delivery/reward totals, and adds no penalty text.
10. Repeat mouse-only drawing, held extension, rebranch, right-click cancellation, and endpoint reshaping at every required window size; Warp Cargo visuals must never intercept input.
