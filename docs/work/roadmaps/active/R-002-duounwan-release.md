<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (45 files)`
> - 문서 갱신: `2026-10-03 07:19:01 +0900`
<!-- COMMIT_STATUS END -->

# Roadmap

ID: `R-002-duounwan-release`

상태: `Active`

연결 Goal: `G-002-duounwan-launch`

마지막 갱신일: 2026-10-03

## 목적

피벗 빌드 `1.1.0+81`을 검증·커밋·배포해 양 스토어에 동시 공개하고, 소프트 런칭 → 버스트 1 → 버스트 2를 게이트별 대표 승인으로 진행한다.

## 단계와 진행률

| 단계 | 기간(안) | 내용 | 상태 | 티켓 |
|---|---|---|---|---|
| 0. 피벗 스펙·결정 | 10/2 | 스펙 v2, D-007, 리서치 | `Done` | — |
| 1. 빌드 | 10/2~10/3 | S1 기반·버그 → S2 카피 → S3 약속 1화면 → S4 인증샷·히어로·인정 → S5 초대·애칭·온보딩 → S6 둘운완·공유·알림, backend(functions·rules·hosting·마이그레이션), brand, shots, GTM 문서, docs 동기화 | `Done`(코드, **미커밋**) | 레인 결과·잔여 위험은 `BT-009`와 `RELEASE_READINESS.md` 게이트에 반영 |
| 2. 출시 준비 | ~10/27 | 통합 검증, 실기기, 열린 이슈 정리, 대표 결정, 커밋, 서버 배포(대표 승인), 마이그레이션, 심사 제출(수동 출시) | `Active` | `BT-009-pivot-release-prep` |
| 3. 동시 공개·소프트 런칭 | 11/3~11/23 | 10:00 동시 공개, `latestBuild=81`, Gate 0 테스트 광고, 72시간 모니터링, 일일 기록표, In-App Event ① 제출(11/4) | `Ready` | 후보 BT-010 소프트 런칭 운영 (미생성) |
| 4. Gate 1 → 버스트 1 | 11/17 판정, 11/24~11/30 | In-App Event ①, 유료 집중 7일 | `Backlog` | 후보 BT-011 |
| 5. Gate 2 → 버스트 2 | 12/29 판정, 1/1~1/7 | In-App Event ②, 유료 집중 7일, 1/21 회고 | `Backlog` | 후보 BT-012 |

진행률: 단계 2/6 완료(0·1). 일정 정본은 `docs/go-to-market/LAUNCH_PLAN_DUOUNWAN.md` §2.

## 순서 원칙

1. 서버 먼저, 앱 나중(구버전 호환). 앱 공개 전까지만 서버 롤백, 공개 후 fix-forward.
2. 배포 순서: Storage 규칙 → Firestore 규칙(`config`) → Functions → Hosting → 마이그레이션 dry-run/실행 → 심사 제출(수동 출시) → 동시 공개 → `latestBuild`. 정본 `docs/operations/LAUNCH_RUNBOOK.md`.
3. 각 단계는 사전 확인 → 명령 → 검증 → 대표 승인 기록.
4. 공개가 11/10 이후로 밀리면 크리스마스 유료 버스트는 하지 않는다.

## 이번 roadmap에서 하지 않는 것

- 다음 릴리스 기능 구현(위젯 1순위, 카카오 피드 2순위 등). 우선순위 결정(대표 결정 7)이 나면 별도 roadmap을 연다.
- 보안 묶음(read 축소 + callable redeem + minBuild 상향). 크리스마스 버스트 전 minBuild=82로 할지는 대표 결정.

## 리스크

- 통합 검증에서 레인 간 충돌이 나오면 10/27 제출이 밀린다.
- iOS 심사 반려(2.3.10 푸터, 사진 UGC 신고 경로, 데모 계정) → 체크리스트 B·리뷰 노트로 선대응.
- 이벤트 실체(Now 탭 배너, 고정 기간 이벤트 약속, 공유 카드 프레임) 없이는 In-App Event가 반려될 수 있다.

## 완료 조건

- 1.1.0(81)이 양 스토어에 공개되고 `config/app.latestBuild = 81`.
- 소프트 런칭 결과로 Gate 1 판정 기록.
- 버스트 결과와 순위 스냅샷이 `RESEARCH_LOG.md`에 남음.
