# Risk & Investment 설계·구현 계획 브리핑

- 날짜: 2026-08-28
- 상태: 독립 사양·품질 검토 및 사용자 문서 승인 완료
- 대상 브랜치: `feature/risk-investment`
- 검증된 통합 기준: `52fc157a36bad4bd8b758928ba90f7b776e106d8`
- 영어 설계 정본: [`docs/superpowers/specs/2026-08-28-risk-investment-design.md`](../../superpowers/specs/2026-08-28-risk-investment-design.md)
- 영어 구현 계획 정본: [`docs/superpowers/plans/2026-08-28-risk-investment.md`](../../superpowers/plans/2026-08-28-risk-investment.md)

이 문서는 사용자 검토용 한국어 브리핑입니다. 실제 구현 계약은 위 두 영어 정본입니다.

## 선행 게이트

현재 통합 기준에서 기존 전체 자동화, UID sidecar, diff 검사와 네 해상도 `960x540`, `1280x720`, `1600x900`, `1920x1080`의 deterministic·마우스 전용 Warp Cargo 체크리스트가 통과했습니다. 사용자가 네 해상도 전체 행을 명시적으로 PASS 확인했으며, 증거는 저장소 밖에 보관합니다.

## 확정한 경제 경계

이번 슬라이스는 `300`으로 시작하는 Risk 전용 임시 session cash를 소유합니다. Warp Cargo의 `base_delivery_reward_total`은 별도 점수로 남고 현금으로 바뀌지 않습니다. 모든 유료 행동은 전체 후보를 먼저 검증한 뒤 돈이 충분할 때만 정확히 한 번 차감합니다. 돈이 부족하면 gameplay 상태와 현금이 모두 byte-unchanged입니다.

최소 `RunState cash`는 이번 기능 다음의 세 번째 경제 단계로 미룹니다. 이번 구현에는 이름만 있는 `RunState`, persistence, settlement, 범용 transaction framework도 미리 만들지 않습니다.

## 확정한 hazard와 내구도

- 세션 seed에서 hazard 전용 RNG 흐름을 파생해 세션 시작 시 12개 고유 셀을 고릅니다.
- 파생식은 `session_seed ^ 0x5249534B48415A44`로 고정하고, row-major 후보에 partial Fisher-Yates를 적용합니다. 기존 Warp RNG는 소비하지 않습니다.
- 출발 셀만 제외하며, 선로·Warp·열차·도달 가능성에 맞춘 재추첨이나 보정을 하지 않습니다.
- hazard 위치와 강도는 세션 내내 고정합니다.
- cycle state와 cycle scaling은 이번 슬라이스에서 명시적으로 보류합니다.
- 열차 최대 내구도는 100입니다.
- 실제 이동한 hazard 셀 거리당 내구도 10을 잃습니다. 단순히 선로가 놓였다는 이유로 피해를 받지 않습니다.
- 내구도 0은 한 번만 종료되며, 같은 이동 sweep에서 이미 발생한 Warp 접촉은 유지됩니다.
- repair-cost basis는 손실 내구도당 1 cash로 계산하되, 이번 슬라이스에서는 실제 현금 차감이나 수리를 하지 않습니다.

## 선로 투자 규칙

기존 `RESERVED_GHOST` 우클릭 suffix 취소는 계속 무료이며 제거한 셀을 전부 반환합니다. `BUILDING` 또는 `BUILT` 선로를 우클릭하면 50을 내고 다음 중 하나를 한 번에 철거합니다.

- 열차 앞쪽의 클릭 지점부터 endpoint까지 suffix
- 이미 지나가 retained 상태인 rear prefix의 시작부터 클릭 지점까지

열차가 들어 있는 구간, 모호한 span, 기존 ledger·geometry·anchor 계약을 깨는 후보는 변경 없이 거부합니다. 성공한 철거는 셀 수와 관계없이 50을 한 번만 내고 활성 셀을 전부 inventory로 돌려받습니다. 이전 구매·철거 현금은 환불하지 않습니다.

grade-separated crossing도 같은 주요 선로 행동 비용 50을 사용합니다. 기존 선로의 수직 방향으로 한 셀을 완전히 통과할 때만 허용하고, 한 줄의 ordered route 안에 별도 occurrence로 남깁니다. branch, merge, switch, 선택 가능한 방향은 만들지 않습니다. gesture 중 되돌리기와 취소는 무료이며, finalize 때 crossing occurrence마다 한 번 과금합니다.

crossing 셀에는 두 occurrence가 있으므로 셀 좌표만으로 철거 대상을 정하지 않습니다. 셀 안의 마우스 위치에서 visual gap이 아닌 각 canonical centerline까지의 거리 `a`, `b`를 계산합니다. `abs(a - b) <= 0.01`이면 모호한 입력으로 보고 아무것도 바꾸지 않으며, 그보다 크면 더 가까운 가로 또는 세로 occurrence를 선택합니다. hover에는 실제로 선택될 occurrence와 prefix/suffix를 그대로 표시합니다.

planning slow tick 중 우클릭도 잃지 않습니다. gesture abort와 ghost suffix 취소는 기존처럼 즉시 무료 처리합니다. `BUILDING`·`BUILT` 철거는 정확한 route serial과 crossing occurrence 정체성을 하나만 보관하고 다음 due tick에 다시 검증해 한 번 실행합니다. 그 사이 pointer가 움직여도 대상을 바꾸지 않고, 추가 field press는 무시합니다.

## 임시 구매

- 임시 track inventory: 40을 내고 5셀 증가, 최대 6회
- 임시 cargo capacity: 80을 내고 1슬롯 증가, 최대 4회

두 증분은 정규 종료, track-end 종료, 내구도 0 종료에서 모두 소멸합니다. 사용한 현금은 환불하지 않으며 새 세션은 기본 용량에서 다시 시작합니다.

유료 철거와 두 구매 입력이 같은 simulation tick 전에 들어오면 이 세 행동이 공유하는 pending slot에 실제 입력 이벤트 순서의 첫 mouse press 하나만 유지합니다. 나머지 field·purchase press와 반복 pressed frame은 무시하고, field gesture 중인 구매 press는 pending에 넣지 않습니다.

## 구현 작업 순서

1. 검증 가능한 임시 session cash
2. 고정 seeded hazard, 실제 이동거리 피해, 열차 내구도와 repair-cost basis
3. 무료 ghost 취소를 보존한 유료 전·후방 철거
4. branch·merge 없는 유료 grade-separated crossing
5. 임시 track·cargo 구매
6. placeholder 화면 피드백, 종단 통합, 네 해상도 Windows 검증

각 작업은 `RED → 최소 GREEN → 회귀 테스트 → 명시적 파일 allowlist → 정확 경로 staging → 집중 commit → 독립 사양 검토 → 독립 품질 검토` 순서를 바꾸지 않습니다. 리뷰 수정도 같은 순서를 다시 적용합니다.

## 화면과 검증 범위

hazard는 색상 외에도 반복되는 primitive mark 또는 border로 항상 식별 가능하게 표시합니다. 현금, 내구도, repair basis, 비용, 구매 수량, crossing 상태는 단순 색상·형태·텍스트·기본 버튼으로만 보여줍니다. custom art, texture, icon, custom font, animation system, audio, mobile 입력은 제외합니다.

최종 검증에는 결정론적 단위·통합 테스트, 기존 전체 회귀, 정확한 UID sidecar audit, `git diff --check`, 고정 seed 반복 비교, 그리고 네 해상도 deterministic·mouse-only 체크리스트가 포함됩니다. 사용자 확인이 없는 마우스 행은 PASS로 기록하지 않습니다.

## 문서 승인 시 함께 확인할 설계 결과

승인된 숫자와 경계에서 파생된 다음 구현 세부도 영어 설계에 명시했습니다.

1. hazard RNG를 위 literal seed 식과 partial Fisher-Yates 순서로 고정해 같은 session seed의 기존 Warp 추첨 순서를 바꾸지 않습니다.
2. 같은 틱에서 이동·Warp 접촉을 먼저 확정하고 내구도 0 종료가 일반 시간·track-end 종료보다 우선합니다.
3. repair-cost basis는 관측값만 만들고 이번 cash에서 실제로 차감하지 않습니다.
4. crossing 셀의 여러 route occurrence를 위해 기존 최초 접촉 거리와 함께 ordered contact-distance 목록을 추가합니다.
5. crossing 셀 우클릭은 canonical pointer-to-centerline 거리 차의 절댓값이 `0.01` 이하이면 no-op, 아니면 더 가까운 가로·세로 occurrence를 선택합니다.
6. 유료 행동은 영향받는 concrete owner의 복사본에서 후보와 post-cash를 모두 검증한 뒤, 관찰 불가능한 한 controller call 안에서 실패하지 않는 교체로 설치합니다. 범용 transaction framework는 만들지 않습니다.
7. 부족 자금의 byte-unchanged 비교에는 route, geometry, ledger, anchor, inventory, cash, train, hazard, Warp, cargo, 구매 counter, session 종료 상태를 포함하며, 이미 dequeue된 raw input과 hover 표시는 제외합니다.
8. skipped planning tick에서는 무료 우클릭만 즉시 처리하고 유료 철거는 정확한 occurrence를 다음 due tick까지 한 번 보관합니다.

## 명시적 보류

- 최소 `RunState cash` 선도입
- cycle state 및 cycle scaling
- base reward의 현금 전환
- 실제 수리와 정산
- 계약, 신뢰, 대출, 파산
- 영구 업그레이드와 persistence
- 본 개발용 추상화와 최종 아트·오디오

문서 승인 전에는 gameplay code를 수정하지 않습니다.
