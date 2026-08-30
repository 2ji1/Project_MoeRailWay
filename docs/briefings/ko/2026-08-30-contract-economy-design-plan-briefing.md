# Contract Economy 설계·구현 계획 브리핑

- 날짜: 2026-08-30
- 상태: 검증 통과를 조건으로 구현·출판·병합·`prototype-m6` 태그·Primary 재검증·자기 기능 정리까지 승인
- 대상 브랜치: `feature/contract-economy`
- 검증된 기준점: `dd9d1d04a126c23a1b3c420cde67711e6e4738dc`
- 영어 설계 정본: [`docs/superpowers/specs/2026-08-30-contract-economy-design.md`](../../superpowers/specs/2026-08-30-contract-economy-design.md)
- 영어 구현 계획: [`docs/superpowers/plans/2026-08-30-contract-economy.md`](../../superpowers/plans/2026-08-30-contract-economy.md)

이 문서는 사용자 검토용 브리핑입니다. 실제 구현 계약은 위 두 영어 정본입니다.

## 핵심 결정

RunState는 Inspector에서 조정 가능한 초기 현금 `300`으로 시작합니다. 현금은 세션 예산과 영구 현금으로 나누지 않습니다. 하나의 RunState 현금이 세션으로 들어가 임시 구매비를 지불하고 배송 운임을 즉시 받은 뒤, 종료 정산을 거쳐 다음 operations 화면까지 유지됩니다.

기존 `PrototypeBalance.session_cash_balance` Inspector 항목과 validator·`.tres` 하위 리소스는 실제 구성에서 퇴역시킵니다. 초기 현금의 유일한 Inspector 원천은 `ContractEconomyBalance.initial_run_cash`입니다. 세션 시작 설정의 현금 값은 별도 예산이 아니라 현재 RunState 현금을 복사한 값으로만 남습니다.

Risk & Investment가 임시로 유지했던 “세션 종료 시 현금 소멸”과 “기본 배송 보상은 지출 불가능한 점수” 경계만 이번 후속 기능에서 대체합니다. Risk의 유료 행동 정확히 한 번 차감, 거부 시 상태 불변, 현금 환불 금지와 나머지 게임 규칙은 그대로 유지합니다.

기존 `base_delivery_reward_total`은 중복 현금이 아니라 누적 배송 운임의 호환 관찰값으로 남깁니다. 새 화면과 결과에서는 의미가 분명한 `delivery_fee_total`을 사용합니다.

기존 전역 조정값 `CargoBalance.base_delivery_reward`는 실제 Contract Economy 앱의 운임 권위에서 제외합니다. 실제 앱은 여섯 회사 설정에서 회사 ID와 회사별 운임을 함께 복사합니다. 기존 전역 값은 전환 중인 옛 단위 테스트 fixture에만 명시적 fallback으로 잠시 남길 수 있으며, 실제 앱과 통합 경로에서는 읽지 않습니다.

## 회사와 계약

프로토타입에는 정확히 여섯 회사가 있습니다. 각 회사는 Inspector에서 다음 값을 독립적으로 조정할 수 있습니다.

- 생성 가중치
- 배송 기본 운임
- 계약 quota
- 배송 0건일 때 최대 미달 penalty
- quota 달성 bonus
- 초과 배송 1건당 trust

회사는 중립적인 임시 ID `company_01`부터 `company_06`까지 사용합니다. 회사 이름이나 아트 설정은 이번 기능의 게임 규칙과 분리합니다.

세션 전에 한 회사만 계약합니다. quota와 곡선 값은 시작 시 복사되어 세션 도중 바뀌지 않습니다. 선택한 회사 때문에 Warp 회사 배정이 유리해지거나 quota가 보정되지 않습니다.

## 회사 배정과 기존 Warp 보호

각 Warp 쌍에는 생성 시 회사 하나가 지정됩니다. 회사 선택은 Warp 위치·수명 RNG와 별도인 고정 salt RNG를 사용합니다. 따라서 Contract Economy를 추가해도 같은 seed의 기존 Warp 위치와 수명 순서는 바뀌지 않습니다.

도달 불가능하거나 불리한 요청도 그대로 유지합니다. 계약 회사, 현재 quota, 선로, 열차, Warp 위치를 보고 회사를 재추첨하지 않습니다.

## 배송과 현금

모든 회사의 배송은 해당 회사 기본 운임을 세션 중 즉시 지급합니다. 이 현금은 같은 세션의 이후 선로·화물칸 구매, 철거, 입체교차에 사용할 수 있습니다.

다만 계약 달성도에는 선택한 회사 배송만 들어갑니다. 비계약 회사 배송은 운임만 지급하고 quota, penalty, bonus, trust에는 영향을 주지 않습니다.

## 계약 현금 곡선

현금 곡선은 float가 아닌 정수 계산으로 고정합니다.

- 배송 0건: 설정된 최대 미달 penalty
- quota까지: penalty에서 quota bonus까지 선형 변화
- quota 달성: 설정된 completion bonus
- quota 초과: 현금 bonus는 더 늘지 않음

표시 달성도는 100%를 넘을 수 있지만 현금 정산은 100%에서 고정됩니다. 정수 나눗셈은 signed half-away-from-zero 규칙으로 반올림하여 seed와 실행 환경이 같으면 결과가 완전히 동일합니다.

## Trust

Trust는 quota를 넘긴 배송만 생성합니다. 초과 배송 수에 회사별 고정소수점 trust 값을 곱합니다. 회사별 trust는 서로 독립이고 현금처럼 사용할 수 없습니다.

이번 기능은 trust를 저장하고 결과에 표시할 뿐 신용한도를 계산하지 않습니다. Credit Survival이 이 값을 입력으로 사용합니다.

## 정산 순서

세션은 정규 시간 종료, 선로 끝 도달, 내구도 0 중 어느 이유로 끝나도 정확히 한 번 다음 순서로 정산합니다.

1. 세션 구매와 즉시 배송 운임이 반영된 최종 세션 현금을 가져옵니다.
2. 계약 달성 cash adjustment를 반영합니다.
3. quota 초과 trust를 계약 회사에 반영합니다.
4. 기존 repair-cost basis를 차감합니다.
5. Inspector의 base operating cost를 차감합니다.
6. 모든 세션 한정 증가량이 제거됐는지 확인합니다.
7. 완료 cycle을 한 번 증가시킵니다.
8. 변경 불가능한 정산 결과를 표시합니다.

정산으로 현금이 음수가 되어도 0으로 보정하거나 비용을 생략하지 않습니다. Contract Economy는 파산을 선언하지 않습니다. Operations 화면에서 다음 세션 시작만 막고 `CREDIT SURVIVAL REQUIRED`를 표시합니다.

## 화면 범위

Operations 화면은 여섯 회사, 현재 현금·cycle, 회사별 trust·운임·quota·penalty·bonus와 선택 상태를 표시합니다.

세션 HUD는 계약 회사, 계약 배송 수, quota, 달성도, 누적 배송 운임을 표시합니다. Warp와 화물칸에는 색·형태와 별개의 간단한 회사 표식을 추가합니다.

결과 화면은 세션 시작 현금, 정보 표시용 배송 운임과 세션 지출, `세션 시작 현금 + 배송 운임 - 세션 지출`로 계산된 정산 시작 현금, 달성도, 계약 조정, trust, 수리비, 운영비, 최종 현금을 보여줍니다. 운임과 지출 행은 정산 시작 현금에 이미 반영된 조정 내역이므로 다시 더하거나 빼지 않습니다.

커스텀 아트·아이콘·폰트·오디오는 만들지 않습니다. 기존 레이아웃 Resource와 기본 Control·색·형태·텍스트만 사용합니다.

## 구현 작업 순서

1. 회사 Balance와 RunState
2. Warp 회사 배정과 화물 회사 정체성
3. 계약 배송 집계와 즉시 운임
4. 영구 RunState 정산
5. Operations·세션 HUD·결과 화면
6. 전체 통합 및 네 해상도 Windows 검증

모든 작업은 deterministic RED를 먼저 만들고 최소 GREEN, 전체 회귀, UID·diff·allowlist 검사, 독립 사양·품질 검토를 거칩니다. 마우스 전용 검증은 `960x540`, `1280x720`, `1600x900`, `1920x1080`에서 직접 조작하며, 에이전트가 확인한 행은 `USER PASS`가 아닌 `AGENT-VERIFIED`로 기록합니다. 모호하거나 불완전한 행은 `PENDING`으로 남고 출판을 차단합니다.

## Credit Survival 전달 경계

후속 기능에는 다음 값만 명확히 전달합니다.

- 음수를 허용하는 최종 RunState 현금
- 완료 cycle 수
- 여섯 회사의 고정소수점 trust
- 선택 회사와 계약 달성 결과
- 세션 시작 현금, 운임·지출 조정 내역, 정산 시작 현금
- 계약·수리·운영 정산 항목
- 음수 현금으로 다음 세션이 차단됐는지 여부

대출, 이자, 원금, 상환 일정, refinancing, 신용한도, 적자 회복, 파산은 이번 구현에 빈 필드나 임시 인터페이스로도 추가하지 않습니다.

## 승인 게이트

현재는 세 문서만 작성된 상태입니다. 문서 검증과 독립 검토를 통과하면 다음 세 경로만 exact-path stage하여 첫 문서 커밋을 생성합니다.

- `docs/superpowers/specs/2026-08-30-contract-economy-design.md`
- `docs/superpowers/plans/2026-08-30-contract-economy.md`
- `docs/briefings/ko/2026-08-30-contract-economy-design-plan-briefing.md`

그 뒤 모든 객관적 검증이 통과하면 작업별 구현 커밋, feature push, `main` PR, merge commit, Primary `--ff-only` 동기화와 통합 HEAD 전체 재검증을 먼저 수행합니다. 그 검증이 통과한 뒤에만 비어 있는 `prototype-m6` annotated tag를 생성·push하고 원격 태그가 같은 통합 commit을 가리키는지 확인한 다음, 자기 기능 worktree·branch cleanup까지 자율 진행합니다. 기존 태그나 다른 작업트리는 건드리지 않습니다.
