# Warp Cargo Windows Manual Verification

Run this checklist only after the exact final feature HEAD passes every automated gate. Keep screenshots and the completed evidence table outside the repository.

## Fixed setup

- Godot: `4.7.1.stable.official.a13da4feb`
- Scene: `res://tests/integration/warp_cargo_app.tscn`
- Startup seed: `73013` (`1.5..16.5` second test lifetime range)
- Window sizes: `960x540`, `1280x720`, `1600x900`, and `1920x1080`

## Evidence header

Record the exact feature HEAD, tester, UTC timestamp, Godot version, startup seed, observed tick trace, every tested window size, pass/fail result, and absolute screenshot paths in task-owned evidence outside this repository.

## Checklist

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
