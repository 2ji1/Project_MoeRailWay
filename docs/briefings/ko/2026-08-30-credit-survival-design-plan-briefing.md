# Credit Survival 설계·구현 계획 브리핑

- 날짜: 2026-08-30
- 상태: Contract Economy 의존성 충족, Task 0 기술 재검증 완료, 문서 통합 게이트 진행 전
- 구현 기준: `592072c1de535bcb5ce56c4a97f6515791bfe096` (`prototype-m6`)
- 영어 설계 정본: [Credit Survival Prototype Design](../../superpowers/specs/2026-08-30-credit-survival-design.md)
- 영어 구현 계획 정본: [Credit Survival Implementation Plan](../../superpowers/plans/2026-08-30-credit-survival.md)

이 문서는 사용자 검토용 한국어 브리핑입니다. 실제 구현 계약은 위 영어 정본 두 문서입니다.

## 현재 가능한 범위

현재 `main`에는 Contract Economy가 merge commit `592072c1de535bcb5ce56c4a97f6515791bfe096`로 통합되어 있고 `prototype-m6`도 같은 commit을 가리킵니다. 회사·계약·영구 현금·정산의 실제 소유 경계를 코드에서 확인했습니다.

Task 0에서 다음 항목을 확인했습니다.

- 실제 `RunState`의 현금·cycle·trust 소유 경로
- 회사 ID와 고정 순서
- 정산의 단일 현금 쓰기와 one-shot commit 방식
- operations/contract/result 화면 구조
- Contract 테스트와 4해상도 수동 증거

재검증은 최신 `main`에서 분기한 별도 문서 worktree에서 수행했습니다. 실제 경로는 `RunState`, `PrototypeRunController`, `SettlementResult`, `prototype_app.gd`, `OperationsScreen`, `ContractResultPanel`과 Contract 테스트로 확정했습니다. 세 문서만 exact-stage·commit·PR·merge하고 Primary `main`에서 문서 blob을 확인한 뒤 `feature/credit-survival`을 생성합니다.

## 확정한 상환 방식

대출은 균등 원금 상환을 사용합니다.

- 대출 원금을 계약된 상환 기간으로 나눈 몫을 앞 회차들에서 갚습니다.
- 나누어떨어지지 않는 잔액은 마지막 회차에서 모두 갚습니다.
- 원금이 기간보다 작으면 앞 회차의 원금 상환이 0일 수 있고 마지막 회차에 잔액을 갚습니다.
- 이자는 매 정산 직전의 남은 원금을 기준으로 계산합니다.
- 회사별 금리는 run 생성 시 balance에서 한 번 복사되어 run 동안 고정됩니다. 실행 중 balance를 수정해도 기존 대출과 새 대출 모두 같은 run 고정 금리를 사용합니다.
- 조기상환은 프로토타입 범위에서 제외합니다.

금리는 basis point 정수로 보관하고, 이자는 올림 계산합니다. 양수 원금과 양수 금리가 있으면 최소 1의 이자가 발생합니다.

## 회사별 독립 신용

회사 6곳은 각각 다음 상태를 독립적으로 가집니다.

- trust
- trust에서 계산한 credit limit
- 남은 원금
- 사용 가능한 신용
- 고정 금리
- 해당 회사에서 발생한 대출 일정

trust는 소비되지 않으며 오직 같은 회사의 credit limit에만 영향을 줍니다. 회사별 trust 좌표는 엄격히 증가하고 limit은 감소하지 않는 정수 knot로 정의하며, knot 사이는 영어 정본의 정수식으로 선형보간한 뒤 내림합니다.

전역 부채 한도는 없습니다. 여러 회사에서 동시에 빌릴 수 있지만 각 회사의 대출 한도는 그 회사 trust와 미상환 원금만 봅니다.

## 차입과 refinancing

차입은 세션 사이 operations 화면에서만 가능합니다. 현금이 양수여도 빌릴 수 있으며, 한 번의 마우스 press마다 하나의 대출과 상환 일정이 생깁니다.

현금은 run 전체가 공유하지만 부채는 회사별입니다. 따라서 B 회사에서 빌린 돈이 공유 현금에 들어오고, 이후 정산에서 A 회사의 예정 원리금을 지불하는 데 사용될 수 있습니다.

다만 A 회사 부채를 즉시 갚는 직접 refinancing 명령이나 자발적 조기상환은 없습니다. 여러 회사의 신뢰를 확보해 미래 정산 현금을 버티는 것이 고위험 전략입니다.

## 정산 순서

Contract Economy의 실제 구조가 다음 순서를 단일 staged commit으로 제공해야 합니다.

1. 계약 성과의 cash bonus 또는 penalty
2. 초과 달성 trust 반영
3. 갱신된 credit limit 계산
4. 수리비 차감과 내구도 완전 복구
5. 운영비 차감
6. 상환 전 원금 기준 이자와 예정 원금 차감

정산은 소유권을 섞지 않습니다. 영구 현금·active loan·Credit revision·run 고정 금리는 persistent `RunState`가 소유하고, settlement ID·operations 상태·detached 결과는 `PrototypeRunController`가 소유합니다. 회사별 원금 합계는 active loan에서 계산하며 별도 mutable cache로 저장하지 않습니다. 완료된 `SessionResult`는 정산 중 다시 변경하지 않습니다. 모든 후보와 결과를 먼저 검증·생성한 뒤 `RunState.replace_with`, 결과 배치, `RESULTS` phase 배치, settlement ID 소비 순서로 실패 가능한 호출 없이 commit합니다.

Credit 시스템은 차입 대출 후보와 정산 원금·이자 quote를 부작용 없이 제공합니다. 실제 현금 후보 생성과 설치는 `PrototypeRunController`만 수행합니다. 정산이 성공하면 `RunState`의 대출 잔액도 같은 commit 안에서 갱신됩니다.

Quote는 settlement ID, cycle, Credit revision에 묶입니다. 오래된 quote는 전체 상태와 ID를 바꾸지 않고 거부되어 올바른 quote로 다시 시도할 수 있습니다. 같은 정산이 다시 호출되거나 결과 화면이 다시 열려도 원리금을 두 번 차감하지 않습니다.

## 적자 회복과 파산

정산 뒤 현금이 음수여도 먼저 일반 결과 화면을 표시합니다. 사용자가 계속하기를 누르면 회복 가능성을 계산하고, 그때 적자 회복 operations 또는 terminal 파산으로 이동합니다.

`settlement → RESULTS → continue/recoverability check → recovery OPERATIONS or TERMINAL`

- 현금이 0 이상이 될 때까지 다음 계약과 세션 시작은 비활성화됩니다.
- 여러 회사에서 원하는 순서로 빌릴 수 있습니다.
- 현재 현금과 모든 회사의 남은 신용을 더해도 0에 도달할 수 없으면 `CREDIT_EXHAUSTED` 파산이 한 번만 발생합니다.
- 회복 가능하지만 사용자가 회복을 포기하면 `RECOVERY_DECLINED` 파산이 발생합니다.
- 자동 대출은 없습니다.
- 파산 결과에는 실제 현금·trust·부채 상태를 그대로 남깁니다.

## cycle과 난이도

첫 세션은 cycle 1입니다. `RunState`에는 완료된 cycle 수만 저장합니다. 결과 화면에서 계속하기를 누르면 먼저 회복 가능성을 판정하고, 음수지만 회복 가능하면 recovery operations로 이동합니다. 현금이 0 이상인 operations에서 다음 cycle은 `completed + 1`로만 계산되며, 계약을 확정할 때 controller의 active cycle로 기록됩니다. 계약 선택을 취소하면 이 값은 폐기되고, `RunState`의 완료 cycle은 세션 정산 성공 때만 한 번 증가합니다.

활성화한 난이도 기본값은 다음과 같습니다.

- 2 cycle마다 hazard 셀 1개 증가
- 매 cycle마다 hazard 셀 통과 피해 1 증가
- hazard 셀 수는 실제 논리 필드의 유효 셀 수까지만 증가
- 피해는 inspector의 `maximum_damage_per_cell = 10.0`까지만 증가

회사별 금리는 canonical 순서로 400, 500, 600, 700, 800, 900 bp이며 기간은 4, 4, 5, 5, 6, 6 cycle입니다. trust-limit knot는 영어 설계 정본에 고정했고 모두 inspector에서 조정할 수 있습니다. 난이도 증가는 경로, Warp 위치, 도달 가능성, 현금, 부채를 보고 보정하지 않으며 기존 hazard RNG를 그대로 사용합니다.

## operations 화면

화면에는 다음 정보를 마우스 전용으로 표시합니다.

- run 현금과 현재 cycle
- 다음 정산의 운영비·예정 원금·예정 이자, 세션 전에는 `UNKNOWN`인 수리비, 적자 회복 상태
- 회사 6곳의 trust, 다음 신용한도 증가에 필요한 trust 또는 `CAP`, 한도, 원금, 남은 신용, 금리, 다음 원금, 다음 이자
- 선택한 회사의 개별 대출 일정
- `-1`, `+1`, `-10`, `+10`, `MAX`, `BORROW`
- 적자일 때만 보이는 `DECLINE RECOVERY`

비용 전망은 operations의 차입 전과 최종 계약 확정 전 양쪽에서 표시합니다. 회사 목록만 내부 스크롤을 허용하고, 현금·회복 상태·주요 버튼은 4개 지원 해상도에서 계속 보이도록 설계합니다. 키보드 gameplay 입력은 요구하지 않습니다.

## Playtest Ready에 넘길 정보

Credit Survival은 파일 로그를 직접 만들지 않고 다음 원시 사실을 detached observation으로 제공합니다.

- cycle별 cash 변화
- 회사별 trust, limit, principal, remaining credit
- 대출·상환 일정과 정산별 원금·이자
- 차입과 적자 회복 이벤트
- cycle별 hazard count와 damage
- 파산 이유와 최종 상태
- debt-service share 계산에 필요한 분자·분모

Playtest Ready는 Contract 또는 이후 단계가 run seed reference를 제공하는 경우 이를 함께 사용하고, ordered event log 형식으로 직렬화합니다.

## 구현 작업 순서

1. 기술 재검증 완료, 문서 통합 게이트 진행 전: Contract Economy 실제 경계와 경로 재검증
2. 회사별 credit balance와 limit 계산
3. 대출 일정과 atomic borrowing
4. 자동 원리금 정산
5. 적자 회복, cycle 진행, 난이도 증가, 파산
6. operations·결과 UI
7. 전체 loop 통합과 Playtest observation

각 작업은 deterministic RED, 최소 GREEN, 정확한 파일 allowlist, exact-path staging, focused commit, 전체 회귀, 독립 specification/quality review를 거칩니다.

## 검증과 승인 경계

최종 구현은 다음을 통과해야 합니다.

- 등록된 전체 unit/smoke suite
- 기존 모든 integration runner
- 반복 multi-cycle·파산 결정론
- GDScript와 `.gd.uid` 1:1 검사
- allowlist와 rename/delete/diff 검사
- `960x540`, `1280x720`, `1600x900`, `1920x1080` Windows 마우스 검증
- 최종 독립 specification/quality review

직접 확인한 행은 `AGENT-VERIFIED`로만 기록합니다. exact-commit 자동화·코드·결정론 검증이 모두 통과했지만 사용 가능한 도구가 특정 수동 행을 직접 수행할 수 없는 경우에만, 정확한 제약 사유와 함께 `WAIVED_BY_USER_GATE_RELAXATION`으로 기록합니다. 이 표기는 승인된 완화 규칙에 따라 merge·tag·인계·cleanup의 수동 완료 조건을 충족하지만 실제 관찰 증거를 뜻하지 않습니다. 사용자가 직접 확인하지 않은 결과를 `USER PASS`로 바꾸지 않습니다.

현재 단계는 `REVALIDATION: COMPLETE; IMPLEMENTATION: ACTIVATES ON DOCUMENT MERGE`입니다. 문서 PR이 `main`에 통합되면 별도 `feature/credit-survival` worktree에서 구현을 시작합니다.

Contract 통합 후 재검증과 모든 구현·검증 게이트를 객관적으로 통과하면 exact-path stage, focused commit, push, main PR, merge commit 병합, primary ff-only 동기화·통합 재검증, 조건부 milestone tag, 자기 feature branch/worktree 정리까지 자율 진행합니다. `prototype-m7`은 primary의 전체 통합·4해상도 게이트가 먼저 통과하고, Contract가 정상적인 `prototype-m6`로 통합됐으며 local/remote 모두에서 `prototype-m7`이 비어 있을 때만 Credit 병합 커밋에 annotated tag로 생성합니다. 기존 tag는 이동하지 않습니다. 조건이 맞지 않으면 tag만 건너뛰고 보고하며, primary 게이트를 통과한 기능과 자기 branch/worktree 정리는 계속할 수 있습니다. Primary 통합 테스트 실패 시에는 tag·인계·cleanup을 모두 금지합니다.

마지막으로 최종 main SHA, PR, tag, 자동·수동 증거 구분을 Playtest Ready 작업 `01a052db-4df7-7041-bf08-226ef441a450`에 한 번 전달하고, 그 작업이 다시 live 검증한 뒤 구현을 시작하도록 합니다.
