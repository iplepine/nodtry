# Firestore / Storage Data Model

마지막 갱신: 2026-10-03 · 기준: 둘운완 피벗 `1.1.0+81` (미배포) · 데이터 계약 정본 `docs/product/PIVOT_DUOUNWAN_SPEC.md` §9

## 계약 원칙
- 피벗 필드는 **전부 optional, 추가만**. 기존 필드명·의미는 바꾸지 않는다(`partner`, `manager`, `plan`, `promise` 그대로).
- action `type`, `PlanState`, `PromiseStatus`에 **새 값을 추가하지 않는다**(구버전 호환).
- 날짜 필드는 Timestamp. 클라이언트는 값이 있을 때만 쓴다(`if (x != null)`).
- 피벗 빌드 번호 `PIVOT_BUILD = 81`(`version: 1.1.0+81`). 서버는 `users.clientBuild >= 81`로 새 기능 푸시를 가른다.
- 표기: **[신규]** 피벗에서 추가 · **[서버]** Cloud Functions만 씀 · **[레거시]** 구버전 데이터에만

## `users/{uid}`
| 필드 | 타입 | 설명 |
|---|---|---|
| `displayName` | string? | 표시 이름(기본 `나`) |
| `email` | string? | 이메일. 기록 탭 짝꿍 이름 fallback·개발자 화면이 읽어서 아직 씀 |
| `profileImageUrl` | string? | Storage `users/{uid}/` 다운로드 URL |
| `statusMessage` | string? | 한 줄 소개 |
| `inviteCode` | string | 8자 `^[A-Z0-9]{8}$`. 새 코드 알파벳 `ABCDEFGHJKMNPQRSTUVWXYZ23456789`. **[서버] 연결 시 두 사람, 해제 시 짝꿍 없어진 사람 회전** |
| `loginType` | string | `guest` \| `google` \| `apple` \| `email` |
| `createdAt`, `updatedAt` | Timestamp | 가입·수정 |
| `fcmToken` | string? | 푸시 토큰. 권한 거부 시 삭제 |
| `clientBuild` | int? | **[신규]** 설치 빌드 번호. 로그인 시 바뀌면 기록 |
| `timezone` | string? | **[신규]** IANA(예: `Asia/Seoul`). 마감 판정 기준, 없으면 Asia/Seoul |
| `locale` | string? | **[신규]** `ko` \| `en` (설정 언어 → 기기 언어) |
| `partnerNickname` | string? | **[신규]** 내가 짝꿍을 부르는 애칭, ≤10자, 빈 값이면 필드 삭제. **[서버]** 짝꿍 없어지면 삭제 |
| `pivotNoticeSeen` | bool? | **[신규]** 기존 사용자 1회 공지 확인(기기 저장 우선, 백업용) |

## `relations/{id}`
연결 1건당 양방향 2문서(A: 초대자=manager·참여자=executor, B: 반대).
| 필드 | 타입 | 설명 |
|---|---|---|
| `executorId` | string | 약속 거는 쪽 |
| `managerId` | string | 봐주는 쪽 |
| `status` | string | `pending` \| `active` \| `rejected` (앱은 `active`로 생성) |
| `createdAt`, `connectedAt` | Timestamp | |
| `inviterId` | string? | **[신규]** 코드 소유자 uid. 두 문서 모두 같은 값 |
| `inviteCode` | string? | **[신규]** 입력한 코드. 소유자의 현재 `users.inviteCode`와 다르면 서버가 연결 취소 |

## `plans/{id}` (루트 컬렉션)
| 필드 | 타입 | 설명 |
|---|---|---|
| `userId` | string | 약속 건 사람(불변) |
| `managerId` | string? | 봐주는 짝꿍. **[서버] 연결된 짝꿍이 아니면 해제** |
| `startDate`, `endDate` | Timestamp | 28일. 새 약속은 오늘 00:00 ~ +27일 23:59:59 |
| `state` | string | `draft` \| `pending_approval`(레거시) \| `active` \| `completed` \| `rejected`(레거시) \| `stopped` |
| `items` | array<map> | 현재 1개. `title`, `days`(int[], 1=월…7=일), `count`, `notificationTime?`, `description?` |
| `items[].notificationTime` | map? | `type`(`preset`\|`custom`\|`none`), `value`, `hour`, `minute`, `alertOffset`, (`intervalHours`>0이면) `intervalHours`·`startHour`·`endHour` |
| `createdAt` | Timestamp | |
| `completedDates`, `skippedDates`, `restedDates`, `rescuedDates`, `verifiedDates` | Timestamp[] | 날짜별 기록. `verifiedDates` = 인정(응원은 넣지 않음) |
| `workoutType` | string? | **[신규]** `gym\|running\|home_training\|walking\|pilates\|yoga\|stretching\|swimming\|climbing\|cycling\|hiking\|strength\|diet\|other`. 없으면 레거시 비운동 약속 |
| `lastActionId` | string? | **[신규]** 마지막 done action 문서 ID. 인정 대상 지정 |
| `lastProofPhotoPath` | string? | **[신규]** 최신 인증샷 Storage 경로(URL 아님). 본인 삭제 시 제거 |
| `lastProofAt` | Timestamp? | **[신규]** 최신 인증 시각. `lastProofAt`이 오늘 && 경로가 `lastActionId`와 맞을 때만 "오늘 사진" |
| `lastActionNote` | string? | 마지막 기록 메모 |
| `lastCheerType`, `lastCheerMessage`, `lastCheerAt`, `lastComment` | | 마지막 응원·한마디. 인정+cheers 동시 쓰기 시 `lastCheerAt` 갱신 → 서버 푸시 1건 |
| `lastPokeMessage`, `lastPokeAt`, `lastPokeAcknowledgedAt` | | 약속 똑똑 |
| `lastMissedNotifiedAt`, `lastMissedItemTitle` | | **[서버]** 놓친 운동 자동 전달 |
| `lastUpdatedBy` | string? | 마지막 쓴 사람 uid 또는 `system_link` · `system_unlink` · `system_missed_action`. `system_*`은 푸시 안 함 |
| `promise` | map? | 내기, 아래 |
| `pilotNextPlanIntent`, `pilotExitReason`, `pilotSettledAt` | | 4주 정산 응답(이름은 레거시 유지) |

### `plans.promise`
`status`(`proposed|active|settled|rejected`), `proposerId`, `reward?{description, targetDays}`(지키면), `penalty?{description, targetDays}`(못 지키면), `proposedAt`, `acceptedAt?`, `settledAt?`, `settledSuccessDays?`, `settledFailDays?`, `settlementResult?`, `settlementAcknowledgedBy?`(uid[]). 연결 해제 시 **[서버]** proposed/active → `rejected`.

## `actions/{id}`
날짜별 기록(기록 탭 원천).
| 필드 | 타입 | 설명 |
|---|---|---|
| `userId`, `planId` | string | 실행자, 약속 |
| `date` | Timestamp | 기록 시각 |
| `type` | string | `done` \| `skipped` \| `rested` \| `rescued` (추가 금지) |
| `title` | string | 약속 제목 스냅샷 |
| `note` | string? | 실행자 메모 |
| `createdAt` | Timestamp | 서버 시각(인정 리마인더 기준) |
| `isReconciled` | bool? | **[레거시]** 사후 정리 기록 |
| `verifiedBy`, `verifiedAt` | | 인정한 짝꿍 |
| `comment` / `partnerMessage` | string? | 짝꿍 한마디(기록 탭 / 지금 탭 경로) |
| `proofPhotoPath` | string? | **[신규]** 항상 `proofs/{userId}/{planId}/{actionId}.jpg`. 본인 삭제 시 제거 |
| `proofSource` | string? | **[신규]** `camera` \| `gallery` |
| `proofTakenAt` | Timestamp? | **[신규]** 카메라=촬영 시각, 앨범=EXIF 원본 촬영일(없으면 비움) |
| `reaction` | string? | **[신규]** 짝꿍이 인정한 이모지 ❤️🔥💪👏(구버전 👍) |
| `verifyReminderSentAt` | Timestamp? | **[서버]** 인정 리마인더 1회 표시 |

## `cheers/{id}` (append-only, 클라이언트 수정·조회 없음)
| 필드 | 타입 | 설명 |
|---|---|---|
| `fromUserId`, `toUserId` | string | |
| `planId` | string? | |
| `reactionType` | string | `poke`(똑똑) \| 이모지(인정·응원) \| **[신규] `reply`**(똑똑 원탭 답장) |
| `message` | string? | 똑똑 문구 / 한마디 / 답장 문구(`지금 간다 🏃`, `오늘은 봐줘 🙏`) / 응원 고정 문구 |
| `createdAt` | Timestamp | |
- 이모지 cheers는 실행자가 오늘 `completedDates`가 있으면 인정, 없으면 응원으로 푸시된다. 놓친 운동 응원은 `💪` + `할 수 있어! 기다릴게 💪`, `verifiedDates` 안 건드림.

## `config/{doc}` **[신규]**
- `config/app`: `{minBuild: int, latestBuild: int}`. 공개 read(로그인 전 포함), 쓰기는 콘솔·admin만. 문서가 없거나 읽기 실패면 게이트 없음.

## 서버 전용 **[신규]**
- `serverLocks/{key}`: `{at, expireAt}`. 똑똑 하루 1회(`poke_plan_{planId}_{day}`, `poke_pair_{from}_{to}_{day}`), 쌍별 연결·해제 이벤트 잠금(2분). `expireAt` TTL 정책(`firestore.indexes.json`).
- `emulatorPushes`: 에뮬레이터에서만 FCM 대신 기록.

## Storage
| 경로 | 내용 | 규칙 요약 |
|---|---|---|
| `users/{uid}/{file}` | 프로필 이미지 | read 로그인 전체, write 본인·이미지 <5MB |
| `proofs/{ownerUid}/{planId}/{actionId}.jpg` **[신규]** | 인증샷(EXIF 제거 JPEG, 긴 변 1440px) | read 본인·현재 `plans.managerId`, create 본인·jpeg·<3MB·plan 소유, update 금지, delete 본인 |
- Firestore에는 경로만 저장한다. 다운로드 URL 저장 금지. 앱은 `getData()` + 경로 키 로컬 캐시(연결 해제 시 삭제).

## 푸시 `data` 계약
- `data.type` 기존 값 유지. 신규: `partner_connected {partnerId, senderName}`, `poke_reply {planId, senderName, message}`, `partner_connect_failed {reason: owner_taken|self_taken|invalid_code}`.
- `action_completed`에 optional `actionId`, `hasProof`(`'true'|'false'`).
- 전체 타입 표는 `docs/product/policy/notification_policy.md`.

## 마이그레이션
- `scripts/migrations/clear_stale_manager_ids.js --project <id> [--apply] [--verbose]`: relation 없는 `plans.managerId`를 찾아(기본 dry-run) `onRelationDeleted`와 같은 업데이트로 정리. 짝꿍 2명 이상 사용자는 보고만. 실행은 대표 승인 후(`LAUNCH_RUNBOOK.md` 5단계).
- 그 외 필드는 백필하지 않는다. 새 필드가 없는 문서는 레거시로 읽는다.
