<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (1 files)`
> - 문서 갱신: `2026-10-03 07:18:55 +0900`
<!-- COMMIT_STATUS END -->

# 둘운완 (DuoDone)

연인·부부가 서로의 운동 약속을 봐주는 1:1 Flutter 앱. **둘이 보면, 진짜 하게 돼요.**

- 이전 이름: Nodtry / 그래,해봐 (2026-10-02 피벗, `docs/decisions/DECISIONS.md` D-007)
- 번들 ID `com.devho.nodtry.app` · Firebase 프로젝트 `nod-try` · App Store ID `6761373605` (이름이 바뀌어도 그대로)
- 현재 버전 `1.1.0+81` (피벗 빌드, 배포 전)

## 문서
- 시작점: [`docs/README.md`](docs/README.md) — 읽는 순서와 역할별 바로가기
- 피벗 정본 스펙: [`docs/product/PIVOT_DUOUNWAN_SPEC.md`](docs/product/PIVOT_DUOUNWAN_SPEC.md)
- 출시: [`docs/operations/RELEASE_READINESS.md`](docs/operations/RELEASE_READINESS.md), [`docs/operations/LAUNCH_RUNBOOK.md`](docs/operations/LAUNCH_RUNBOOK.md)
- 데이터 모델: [`_spec/15-data-model/firestore-schema.md`](_spec/15-data-model/firestore-schema.md)
- AI 에이전트 작업 규칙: [`CLAUDE.md`](CLAUDE.md), [`AGENTS.md`](AGENTS.md)

## 구성
| 경로 | 내용 |
|---|---|
| `lib/` | Flutter 앱 (Riverpod, GoRouter, Firebase) |
| `functions/` | Cloud Functions (Node 22, TypeScript): 푸시, 놓친 운동 전달, 연결·해제·탈퇴 정리 |
| `firestore.rules`, `storage.rules`, `firestore.indexes.json` | 보안 규칙·인덱스 |
| `rules-tests/` | 규칙·트리거 에뮬레이터 테스트 |
| `hosting/public/` | 초대 랜딩 `/i/{CODE}`, `/get` |
| `privacy-policy/`, `support/` | 개인정보처리방침·지원 페이지 |
| `scripts/migrations/` | 데이터 마이그레이션(dry-run 기본) |
| `tool/` | 스토어 스크린샷 생성기 |
| `assets/brand/`, `docs/design/` | 브랜드 마스터와 가이드 |

## 개발 명령
```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test

# Cloud Functions
cd functions && npm ci && npm run build && npm test && npm run lint

# 보안 규칙 테스트 (Java 17+) / 트리거 E2E (firebase-tools 15 + JDK 21)
cd rules-tests && npm ci && npm run emulators:rules
cd rules-tests && npm run emulators:functions

# 스토어 스크린샷 (macOS 전용, 폰트 필요)
flutter test tool/generate_store_screenshots_test.dart
```

배포(Firebase·스토어)는 대표 승인 후 `docs/operations/LAUNCH_RUNBOOK.md` 순서로만 한다. 모든 Firebase 명령에 `--project nod-try`를 붙인다.
