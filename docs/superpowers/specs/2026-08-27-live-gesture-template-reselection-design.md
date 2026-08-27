# Live Gesture Template Reselection Design

**Status:** Approved in chat on 2026-08-27

## Problem

An active endpoint reshape gesture can replace the completed head with the straight, left-curve, or right-curve template. The runtime currently changes that selection only when a frame contains one of the three exact template target cells. `TrackSystem` appends the current pointer cell to the rasterized cells, but `GridTrackRuntime` still interprets any non-target pointer cell as extension input for the already-selected template.

When the pointer moves toward a different template without landing on its exact target cell, the extension candidate is invalid. Last-valid retention correctly preserves the previous candidate, but the visible result is that the first ghost geometry appears latched and no longer responds to the held pointer.

## Interaction Contract

- A reshape gesture still begins only at the active endpoint and retains the exact gesture-origin snapshot.
- While the same left press remains held, the current inside-grid pointer cell is authoritative for selecting among the straight, left-curve, and right-curve target endpoints.
- Selection uses Manhattan distance from the current pointer cell to each deterministic target endpoint.
- If more than one target is equally near, retain the currently selected template when it is one of the tied targets. If no current selection breaks the tie, use the existing deterministic order: straight, left, right.
- When the authoritative pointer selects a different template, discard the prior gesture-owned suffix and rebuild the complete candidate from the gesture origin with the newly selected template. Do not interpret cells crossed while moving between templates as extension cells for the new template.
- An exact selected target still resets extension input. Cells crossed after that target may extend the route under the existing suffix rules.
- Publish only a fully valid candidate atomically. Bounds, overlap, inventory, continuity, lock, train-preparation, and finalization failures retain the last valid candidate without corrupting the origin or observations.
- Releasing left finalizes the currently published candidate. Right-click during the held gesture restores the exact gesture origin.
- Locked geometry and train-entered geometry remain immutable.

## Layering

`TrackFieldView` continues to own pointer rasterization and supplies both rasterized cells and the current pointer fact through `TrackInputFrame`. `TrackSystem` passes those two facts to `GridTrackRuntime` without merging away their meaning. `GridTrackRuntime` owns deterministic template selection and atomic candidate rebuilding.

## Non-goals

- No free-form or pixel-continuous curve shape is introduced.
- No new visual ghost style, color, opacity, or animation is introduced.
- No production abstraction layer or generalized route editor is introduced.
- Existing ordinary extension, inventory accounting, recovery, construction, hover, and cancellation contracts remain unchanged.

## Verification

The automated evidence must hold one left press continuously while moving the pointer through non-target cells nearest to the left, straight, and right targets. Each move must atomically replace the published head, preserve the fixed prefix and inventory, and require no release between selections. A real `TrackFieldView` input integration must cover the same held-pointer sequence so a facade-only synthetic test cannot mask the playtest interaction.
