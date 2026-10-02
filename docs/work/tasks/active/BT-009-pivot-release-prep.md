<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (46 files)`
> - 문서 갱신: `2026-10-03 07:19:01 +0900`
<!-- COMMIT_STATUS END -->

# Task

ID: `BT-009-pivot-release-prep`

유형: `Dev/Ops`

상태: `Active`

연결 Roadmap: `R-002-duounwan-release`

연결 Goal: `G-002-duounwan-launch`

담당: 장영실 / 기술실장(실행), 정약용 / 프로덕트 총괄(범위·문서), 황희 / 리스크 감시역(검토), 승인 대표

마지막 갱신일: 2026-10-03

## 목표

피벗 빌드 `1.1.0+81`을 커밋 가능한 상태로 통합 검증하고, 대표 승인 후 `LAUNCH_RUNBOOK.md` 0~6단계(서버 배포 → 마이그레이션 → 양 스토어 심사 제출, 수동 출시)까지 끝낸다. 동시 공개(7단계) 이후는 다음 티켓.

## 배경

2026-10-02~03 빌드 레인(S1~S6, backend, brand, shots, gtm, docs)이 브랜치 `feat/couple-workout-pivot` 워킹트리에서 끝났다. 아무것도 커밋·배포하지 않았다. 레인마다 자체 검증은 통과했지만 레인이 같은 트리를 병렬로 고쳤으므로 최종 통합 검증이 필요하다. 출시 일정안은 10/27 심사 제출, 11/3 동시 공개다.

## 포함

- 스펙 §8 게이트 최종 재실행과 실기기 확인
- 출시 전 열린 이슈 수정 또는 대표 수용 결정
- 커밋(대표 요청 시), 서버 배포, 마이그레이션, 스토어 제출
- 문서 커밋 상태 스탬프(커밋 후)

## 제외

- 광고 집행, In-App Event 생성, 동시 공개(7단계 이후)
- 다음 릴리스 기능, 보안 묶음(minBuild 상향)

## 완료 기준

### A. 코드 게이트 (스펙 §8) — 최종 통합 1회 실행
- [ ] `flutter analyze` 에러 0 (레인 근거: S6·shots 0 에러, 기존 info 4건)
- [ ] `flutter test` 전부 그린 (레인 근거: S6 557/557)
- [ ] `functions`: `npm run build` · `npm test`(17) · `npm run lint`(0) (레인 근거: backend 통과)
- [ ] `rules-tests`: `npm run emulators:rules`(21) · `npm run emulators:functions`(13, firebase-tools 15 + JDK 21) (레인 근거: backend 통과)
- [ ] iOS 시뮬레이터 빌드 + 핵심 화면 스모크(`pod install`로 package_info_plus·url_launcher·share_plus·in_app_review 반영) — **미실행**
- [ ] Android release AAB 빌드(AGP 8.9.1 상향 반영 확인) — **미실행**
- [ ] 금지어 grep 0건: ARB 값·`lib`·`functions/src`·`ios/Runner`·`android/app/src/main`에서 `실천 메이트|공부|스터디|파일럿|Nod&Try|Nodtry|그래,해봐` (키 이름·주석·레거시 비교 문자열·`pivotNoticeTitle` 제외)
- [ ] 메타데이터 길이·표시명 토큰(둘운완/DuoDone) 일치 (레인 근거: brand·gtm 스크립트 통과)
- [ ] `history_state.freezed.dart` 손 편집분: build_runner 복구 후 재생성 diff 0, 또는 수용 기록

### B. 실기기 (`RELEASE_READINESS.md` 게이트 B 전부)
- [ ] 인증샷(카메라·앨범·HEIC·동의·8초 타임아웃·삭제·신고), 업로드 파일에 EXIF/GPS 없음
- [ ] 두 기기 초대·연결·애칭·해제(전 짝꿍 사진 거부, 캐시 삭제)
- [ ] 공유 카드 → 인스타·카톡, 평점 요청(TestFlight)
- [ ] 알림 카피·빈도·작은 아이콘, 버전 게이트, 기존 사용자 업데이트 경로
- [ ] DebugView 퍼널 8종

### C. 열린 이슈 — 수정 또는 대표 수용 기록
- [ ] 공유 카드 푸터 `Google Play` → 플랫폼 중립 문구(Apple 2.3.10)
- [ ] 마이그레이션 스크립트 vs 런북 계약(JSON 백업·`--restore`) 불일치 해소, 런북 5단계 `<MIGRATION_CMD>` 확정
- [ ] iOS `release_manual` 레인(automatic_release:false, overwrite_screenshots:true) 또는 런북 우회 명령 확정
- [ ] `onPlanUpdated`: 실행자가 레거시 pending을 수정해 active가 될 때 `승인` 푸시 오발송(`lastUpdatedBy === managerId`일 때만 승인 카피)
- [ ] 노란색 텍스트 대비(→ `accentWine`), 주 카드 반투명 회색 렌더
- [ ] Pretendard 폰트 파일(HTML) 교체 또는 pubspec fonts 제거
- [ ] 푸시 탭 딥링크(`partner_connected`, `poke_reply`, `partner_connect_failed`, `action_completed.actionId`) — 이번 릴리스 포함 여부 결정
- [ ] 개인정보처리방침 시행일을 실제 출시일로, 설명된 동작이 배포본에 있는지 확인 후 게시
- [ ] Android `<queries>` mailto(신고 메일, 선택)
- [ ] 랜딩이 Play 링크에 `referrer=invite_code`를 붙이지만 앱에 Install Referrer 파싱이 없음 — 이번 포함 또는 다음 릴리스로 명시(현재는 클립보드 감지에 의존)

### D. 대표 결정 기록
- [ ] `LAUNCH_PLAN_DUOUNWAN.md` §0 결정 1~7
- [ ] 공유 카드 빈도(매 둘운완 데이 vs 첫날+마일스톤)
- [ ] 영어 용어(props·knock·bet)·영어 키워드 편차(`husband,wife,run`)·ASO 제안 문안
- [ ] 튜토리얼 키(`nodtry_tutorial_completed_v1`) 변경 여부
- [ ] Temporary Operations Lead 지정(신고 24시간 응대, 리뷰 답글)

### E. 배포 (대표 승인 후, `LAUNCH_RUNBOOK.md`)
- [ ] 0단계 사전 준비(UTF-8 셸, 롤백 기준점, 콘솔 인덱스 백업)
- [ ] 1단계 Storage 규칙 + **IAM 권한 수락**
- [ ] 2단계 Firestore 규칙·인덱스(TTL) + 콘솔 `config/app {minBuild: 0, latestBuild: 80}`
- [ ] 3단계 Functions(갱신 6 + 신규 3), 로그로 예약 함수 확인
- [ ] 4단계 Hosting(`/i/{CODE}`, `/get`, og.png) — 미리보기 채널에서 카톡 미리보기 확인
- [ ] 5단계 마이그레이션 dry-run 리포트 → 대표 승인 → `--apply`
- [ ] 6단계 양 스토어 심사 제출(수동 출시, Play 관리형 게시, 스크린샷 교체·옛 4장 정리)

### F. 문서
- [ ] 커밋 후 바뀐 문서만 `doc_commit_status.py sync --file`로 스탬프
- [ ] `RELEASE_READINESS.md`에 배포 기록 추가, 이 티켓을 `tasks/done/`으로

## 검증 계획

- A는 통합 트리에서 한 번에 실행하고 결과를 이 문서에 붙인다.
- B는 iPhone(실기기) 1대 + Android 1대로 두 계정 시나리오를 돈다. 결과는 `RELEASE_READINESS.md` 게이트 B 체크.
- E는 단계마다 런북의 검증 항목과 대표 승인 기록을 남긴다.

## 참고 — 빌드 레인 요약에서 나온 위험

- functions 배포 즉시 전원 적용: 연결 안 된 사용자 간 푸시 차단, rescued 무푸시, 인정 리마인더 09~22시, 연결·해제 때 초대 코드 회전, 짝꿍 없어지면 애칭 삭제.
- 초대 코드 없는 relation(구버전) 허용 → 위조 관계 잔여 위험. 근본 해결은 보안 묶음.
- 레인 S5의 `dart format` 사고로 일부 파일(plan_create_viewmodel, settings_screen, plan_schedule_pickers)에 포맷 churn이 남았을 수 있음(동작 무관).
- `android/fastlane/json_key.json` 키가 히스토리에 있음 → 레포 공개 전 회전.
