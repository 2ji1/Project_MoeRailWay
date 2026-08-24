# 메인 우선 기능 브랜치 관리 설계 브리핑

영어 설계 정본: [docs/superpowers/specs/2026-08-25-main-first-branch-management-design.md](../../superpowers/specs/2026-08-25-main-first-branch-management-design.md)

영어 구현 계획 정본: [docs/superpowers/plans/2026-08-25-main-first-branch-management.md](../../superpowers/plans/2026-08-25-main-first-branch-management.md)

이 문서는 사용자 검토용 한국어 브리핑입니다. 실제 구현과 운영 판단은 위 영어 정본을 따르며, 내용이 다르게 읽힐 때에는 영어 정본을 먼저 바로잡습니다.

## 운영 결과

- `main`은 유일한 활성 통합 및 로컬 플레이테스트 브랜치입니다.
- 기본 작업공간 `D:\godot\MoeRailWay`는 작업 전환 중이 아닐 때 `origin/main`을 추적하는 깨끗한 로컬 `main`으로 유지합니다.
- 즉시 플레이테스트할 프로젝트는 `D:\godot\MoeRailWay\godot-project-moe-rail-way`입니다.
- 각 기능은 최신 검증된 `main`에서 `feature/*` 브랜치와 별도 외부 작업트리를 만들어 개발합니다.

## 기능 작업과 통합

각 계획 작업은 RED, 최소 GREEN, 명시된 파일 허용목록, 정확한 경로 스테이징, 집중 커밋, 필요한 전체 회귀 테스트, 독립 사양 검토와 품질 검토를 순서대로 통과합니다. 작업별 커밋은 보존하며 squash 또는 rebase 방식으로 합치지 않습니다.

기능 전체가 통과하면 기능 브랜치를 푸시하고 `main` 대상 PR을 엽니다. 필요한 검사와 검토가 끝난 PR만 merge commit 방식으로 자동 병합합니다. 병합 후 기본 작업공간의 로컬 `main`을 `origin/main`으로 fast-forward하고 전체 자동 검증을 다시 통과시킨 다음 기능 작업트리와 로컬·원격 기능 브랜치를 정리합니다.

## 사용자 작업 보호

기본 작업공간이 dirty, untracked, staged 또는 divergent 상태이면 자동 동기화를 중단합니다. 그 상태를 해소한다는 이유로 사용자 변경을 stash, reset, format, stage, copy, absorb, move 또는 delete하지 않습니다. 사용자 소유 Godot 또는 Steam 프로세스도 종료하거나 재설정하지 않습니다.

다음 안전 참조는 이 정책 아래 로컬에만 보존합니다.

- `local/user-workspace-snapshot-20260825` = `9daec4c053e6e2e7eb05e1abe04d330ea28a41a2`
- `local/legacy-main-before-sync-20260825` = `71a8ebc23a1171eaef50aaa03bddc02f594fe02c`

## 레거시 브랜치와 태그

`Prototyping`, `Development`, 기존 `proto/*` 브랜치는 새 작업에서 읽기 전용 이력 참조입니다. 새 기능을 시작하거나 통합하지 않으며 `Prototyping` 전체를 `Development`로 병합하지 않습니다.

이번 브랜치 관리 정책 전환에는 마일스톤 태그를 만들지 않습니다.
