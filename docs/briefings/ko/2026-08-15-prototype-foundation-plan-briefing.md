# 프로토타입 기반 구축 구현 계획 브리핑

- 작성일: 2026-08-15
- 대상 브랜치: proto/00-foundation
- 기준 브랜치: Prototyping
- 용도: 사용자 검토용 한국어 브리핑
- 에이전트용 영어 정본: docs/superpowers/plans/2026-08-15-prototype-foundation.md

## 1. 이번 계획의 범위

전체 8개 피처를 한 계획에서 동시에 구현하지 않는다. 먼저 첫 번째 버티컬 슬라이스인 proto/00-foundation만 상세 계획으로 고정한다.

이번 마일스톤의 결과는 다음과 같다.

- 현재 미추적 상태인 Godot 프로젝트를 안전하게 Git에 등록
- Prototyping과 proto/00-foundation 브랜치 경계 생성
- Windows PC·1280x720 논리 해상도·16:9·마우스 입력 기준 설정
- 실행 가능한 최소 PrototypeApp 씬
- 외부 플러그인 없는 GDScript 헤드리스 테스트 러너
- 검증 가능한 밸런스 Resource
- 명시적인 SessionStartConfig
- 동일 시드를 재현하는 SessionRng
- 프로젝트 설정을 반복 실행해도 결과가 같은 구성 도구

선로·기차·워프·화물·계약·대출은 아직 구현하지 않는다. 각 기능은 승인된 후속 피처 브랜치에서 추가한다.

## 2. 실행 환경 확인 결과

프로젝트가 선언한 Godot 버전은 4.7이다. 실제로 사용할 수 있는 콘솔 실행 파일은 다음 경로에서 4.7.1로 확인했다.

D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe

현재 C:\Users\noisy\bin\godot.cmd는 존재하지 않는 Godot 4.5.1 경로를 가리켜 실행되지 않는다. 계획에서는 이 파일을 수정하지 않고 확인된 4.7.1 실행 파일을 명시적으로 사용한다.

## 3. 작업 순서

### 작업 1: 브랜치와 저장소 위생

현재 main에서 Prototyping을 만들고, 그 브랜치에서 proto/00-foundation을 분기한다.

저장소 루트의 .superpowers, 빌드 결과, 로컬 로그를 무시한다. Godot 프로젝트 안에서는 .godot 캐시, Android 생성물, 로컬 빌드·내보내기·로그 폴더를 무시한다.

강제 체크아웃, clean, reset은 사용하지 않는다. 현재 미추적 Godot 소스는 보존한다.

### 작업 2: 테스트 러너와 최소 실행 씬

SceneTree 기반 tests/run_all.gd를 만들고 테스트 파일이 run 함수를 통해 실패 목록을 반환하게 한다.

먼저 존재하지 않는 PrototypeApp 씬을 읽는 실패 테스트를 실행한다. 실패를 확인한 뒤, 단색 배경과 Foundation 문구만 있는 최소 씬을 만들어 테스트를 통과시킨다.

이 시점에는 커스텀 아트가 없다.

### 작업 3: 밸런스 설정과 세션 입력

PrototypeBalance Resource에 세션 길이와 초당 시뮬레이션 틱 수를 둔다. 기본값은 180초와 60틱이다.

PrototypeConfigValidator는 잘못된 값을 한 번에 모두 보고한다. SessionStartConfig는 시드, 세션 길이, 틱 수를 명시적으로 전달한다.

PrototypeApp은 시작할 때 설정을 검증하고 유효하지 않으면 디버그 실행을 종료한다.

### 작업 4: 결정적 RNG

SessionRng를 만들어 동일한 시드는 정수·실수 난수 시퀀스를 동일하게 재현하도록 한다.

PrototypeApp은 SessionStartConfig의 시드로 SessionRng를 생성한다. 이후 워프 생성 기능이 이 인터페이스를 사용한다.

### 작업 5: 재현 가능한 프로젝트 설정

configure_project.gd가 다음 값을 설정하고 project.godot에 저장한다.

- 앱 이름: Moe Rail Way Prototype
- 메인 씬: PrototypeApp
- 논리 해상도: 1280x720
- 스트레치: canvas_items
- 화면비 처리: expand
- track_draw 입력: 마우스 왼쪽 버튼

구성 도구를 두 번 실행한 뒤 project.godot 해시가 같은지 검사해 멱등성을 확인한다.

## 4. 테스트 방식

모든 기능은 실패 테스트를 먼저 실행하고 최소 구현으로 통과시킨다.

최종 자동 검증은 다음을 확인한다.

- Godot 4.7.1 실행
- 테스트 스위트 4개 통과
- PrototypeApp 메인 씬 헤드리스 부팅
- 기본 시드 1과 틱 수 60 적용
- .godot, logs, builds가 Git 추적 대상이 아님
- Git 공백 오류 없음

Windows 환경에서 시스템 인증서 저장소 경고가 나타날 수 있지만, 스크립트 파싱 오류, 런타임 스크립트 오류, 0이 아닌 종료 코드는 실패로 처리한다.

## 5. 커밋과 병합

작업 단위별로 다음 커밋을 남긴다.

1. chore: define prototype repository hygiene
2. feat: bootstrap prototype application
3. feat: add validated prototype session config
4. feat: add deterministic session random stream
5. chore: configure prototype platform baseline

코드 검토와 전체 검증이 끝나기 전에는 Prototyping에 병합하지 않는다.

검토가 통과하면 proto/00-foundation을 Prototyping에 스쿼시 병합하고, 다시 전체 검증한 뒤 prototype-m1 태그를 생성한다. Development에는 병합하거나 PR을 만들지 않는다.

## 6. 이후 단계

foundation 마일스톤이 Prototyping에서 검증된 뒤 다음 브랜치인 proto/01-session-shell의 별도 상세 구현 계획을 작성한다.
