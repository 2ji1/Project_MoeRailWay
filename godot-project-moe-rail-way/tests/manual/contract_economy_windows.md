# Contract Economy Windows Manual Gate

## Purpose

Validate the exact committed Contract Economy cycle on Windows with mouse-only input. This checklist does not replace the deterministic integration trace. Store exact commit, Godot version, seed, tester, resolution, observations, and screenshots outside the repository.

## Status rules

- Direct agent observation is labeled `AGENT-VERIFIED`, never `USER PASS`.
- User-owned acceptance remains `PENDING` until the user confirms it.
- Any ambiguous or failed row remains `PENDING` and blocks publication.
- Automation may support a row but never converts a mouse-only row into user acceptance.

## Required environment

- Windows PC
- Godot 4.7.1 stable
- Fixed seed `73013`
- Resolutions `960x540`, `1280x720`, `1600x900`, and `1920x1080`
- Scene `res://tests/integration/contract_economy_app.tscn`
- Companion runner `res://tests/integration/run_contract_economy_integration.gd`

## Per-resolution checklist

Repeat every row at all four required resolutions.

| Row | Observation | Status |
| --- | --- | --- |
| CE-WIN-01 | All six company rows, trust, fee, quota, penalty, bonus, cash, and cycle are readable. | PENDING |
| CE-WIN-02 | Company selection and session start work with mouse-only input. | PENDING |
| CE-WIN-03 | Company markers remain readable and distinct from Warp pair color and shape. | PENDING |
| CE-WIN-04 | Contracted and uncontracted deliveries show the correct immediate fee and attainment behavior. | PENDING |
| CE-WIN-05 | A purchase can use a fee earned earlier in the session without a frame-order failure. | PENDING |
| CE-WIN-06 | Result line items and closing cash match the deterministic companion trace. | PENDING |
| CE-WIN-07 | Trust changes only after over-attainment by the selected company. | PENDING |
| CE-WIN-08 | Continue returns to Operations exactly once and clears the previous selection. | PENDING |
| CE-WIN-09 | Negative cash blocks Start and shows `CREDIT SURVIVAL REQUIRED` without declaring bankruptcy. | PENDING |
| CE-WIN-10 | Operations, HUD, result Controls, resizing, and hidden views do not corrupt field mapping or retain hidden clicks. | PENDING |

## Deterministic companion values

- Session starting cash: `0`
- Selected company: `company_02`
- Contract quota: `1`
- Fixed-seed deliveries: `warp_pair_1` contracted at `40`, `warp_pair_2` uncontracted at `80`, then `warp_pair_3` contracted at `40`
- Delivery fee total: `160`
- Session purchase spending: `40`
- Settlement opening cash: `120`
- Contract adjustment: `60`
- Trust gain: `125` milli
- Repair cost: `0`
- Operating cost: `50`
- Closing cash: `130`
- Completed cycle count: `1`
- No-delivery closing cash: `-170`

## Fixed-seed route

Starting at departure cell `(0, 2)`, drag the endpoint through the following ordered cells. The route reaches each generated origin before its matching destination and ends naturally at track end. Do not inject Warp, Cargo, delivery, settlement, or completion state.

1. Select `company_02` and press Start with the mouse.
2. Draw the full route below from the departure endpoint.
3. After `warp_pair_1` is visibly delivered and session cash reaches `40`, press the Cargo purchase button before the next delivery.
4. Observe `warp_pair_2` as an uncontracted delivery and `warp_pair_3` as the second contracted delivery.
5. Let the train reach the natural track end, compare every result line with the companion values, and press Continue once.

```text
(1,2) (2,2) (3,2) (4,2) (5,2) (6,2) (7,2) (8,2) (9,2) (10,2) (11,2)
(11,3) (11,4) (11,5) (11,6) (10,6) (9,6) (8,6) (7,6) (6,6) (5,6) (4,6)
(3,6) (2,6) (1,6) (1,5) (1,4) (2,4) (3,4) (4,4) (5,4) (6,4) (7,4)
(8,4) (9,4) (10,4) (10,3) (9,3) (8,3) (7,3) (6,3) (5,3) (4,3) (3,3) (2,3)
(1,3) (0,3) (0,4) (0,5) (0,6) (0,7) (1,7) (2,7) (3,7) (4,7) (5,7) (6,7)
(7,7) (8,7) (9,7) (10,7) (11,7) (11,8) (11,9) (10,9)
(9,9) (8,9) (7,9) (6,9) (5,9) (4,9) (3,9) (2,9) (1,9) (0,9) (0,8) (1,8) (2,8)
```

## Evidence record template

```text
Commit:
Godot:
Seed: 73013
Resolution:
Tester:
Status: AGENT-VERIFIED | PENDING
Observed rows:
Screenshot paths:
Notes:
```
