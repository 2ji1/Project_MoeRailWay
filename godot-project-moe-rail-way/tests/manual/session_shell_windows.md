# Prototype Session Shell Windows Manual Smoke

## Environment

- Date: 2026-08-15 KST
- Initial feature evidence commit: `38bee2ba2cb8e8a71c3a50268a10910e3c3bfc07`
- Post-review terminal-reentrancy correction verified: `d3947d02f346a2966abc780a809222ba88f0471b`
- Godot executable: `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe`
- Required Godot build: `4.7.1.stable.official.a13da4feb`
- Host: Windows NT 10.0.26200.0
- Renderer target: Forward Plus with the D3D12 Windows driver
- Input target: mouse only

## Manual Runtime Checks

| Check | Evidence | Result |
|---|---|---|
| Main scene starts automatically with no click and begins at `3:00`. | A fresh main-scene launch displayed `3:00` without input in `main-960-initial.png`. | Pass |
| Visible whole seconds decrement without skipping. | One PID displayed the consecutive sequence `2:59`, `2:58`, `2:57` in `timer-sequence-1.png` through `timer-sequence-3.png`. | Pass |
| Top and bottom HUD bands remain thin while the field remains dominant. | Full-window captures at all four required resolutions preserve two thin HUD bands around the dominant field. | Pass |
| Inactive future values use em dashes and imply no gameplay state. | Both HUD bands display only em dashes for inactive future values in every default-profile capture. | Pass |
| No start, restart, next, debug-end, or settlement control exists. | No interactive control is visible in the main or result captures; the result view is informational only. | Pass |
| `960x540` has no overlap or clipping. | `main-960-initial.png` shows the complete requested client area and both HUD bands. | Pass |
| `1280x720` has no overlap or clipping. | `main-1280x720.png` shows the complete requested client area and both HUD bands. | Pass |
| `1600x900` has no overlap or clipping. | `main-1600x900.png` shows the complete requested client area and both HUD bands. | Pass |
| `1920x1080` has no overlap or clipping. | `main-1920x1080.png` shows the complete requested client area and both HUD bands. | Pass |
| Every-minimum profile remains valid in a disposable local test copy. | Inspector-persisted minimum values (`0`, `0`, `4`, `4`, `2`, `44`, `12`) were applied to a disposable local Resource copy and captured at `960x540` in `profile-min-960x540.png`; the copy was then deleted. | Pass |
| Every-maximum profile remains valid in a disposable local test copy. | Inspector-persisted maximum values (`48`, `32`, `20`, `24`, `16`, `80`, `32`) were applied to a disposable local Resource copy and captured at `960x540` in `profile-max-960x540.png`; the field remained larger than `640x300`, and the copy was then deleted. | Pass |
| The short-session wrapper reaches the noninteractive regular result view once. | `short-session-result-post-review.png` rechecks the sole regular result overlay after the approved two-second fixture on correction commit `d3947d0`; the fresh automated lifecycle gate independently observed one exact result log. | Pass |
| The tracked main balance remains exactly 180 seconds at 60 ticks per second. | Post-smoke repository inspection found the tracked Resource unchanged at `180.0` seconds and `60` ticks per second. | Pass |

## Host-Only Warnings

- Godot must be run outside the Codex filesystem sandbox on this host. The sandbox denied `user://logs` writes and triggered a Godot native access violation (`CrashHandlerException`, signal 11); the identical test and boot commands passed outside the sandbox. This is a host execution constraint, not a project failure.
- The user-owned Steam Godot editor remained running and untouched throughout the successful smoke runs. Every smoke process was identified from its direct launch PID, exited with code `0`, and left no Godot 4.7.1 or Windows Error Reporting residue.
- Early desktop-region captures were offset by mixed-DPI multi-monitor coordinates. Final evidence uses Win32 full-window capture (`PrintWindow` with `PW_RENDERFULLCONTENT`) of the exact launched PID, so all requested client areas are present. Screenshots remain outside Git under the Codex visualization directory.

## Final Assessment

- Pass. The Windows runtime, four supported viewport sizes, both profile extremes, timer progression, and the post-review regular-result transition satisfy the session-shell milestone checklist. The tracked default layout and main balance Resources remain unchanged.
