<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 운동 약속(Plan) 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S3) · 사용자 용어 `운동 약속`, 코드·데이터 `plan`

## Plan 모델
- `userId`: 약속을 건 사람(실행자) · `managerId`: 봐주는 짝꿍(선택)
- `startDate`, `endDate`: 기간(28일) · `state`: 아래 상태 · `items`: 약속 항목(현재 1개)
- `workoutType` (선택, 신규): `gym|running|home_training|walking|pilates|yoga|stretching|swimming|climbing|cycling|hiking|strength|diet|other`. 없으면 레거시 비운동 약속으로 보고 중립 `약속` 카피를 쓴다.
- `promise`: 내기(선택) · `completedDates` / `verifiedDates` / `skippedDates` / `restedDates` / `rescuedDates`
- `lastActionId`, `lastProofPhotoPath`, `lastProofAt` (신규, 인증샷 정책 참고)
- `lastMissedNotifiedAt`, `lastPokeAt`, `lastUpdatedBy` 등 메타. 전체 필드는 `_spec/15-data-model/firestore-schema.md`

### PlanItem
- `title`: 약속 한 줄(예: `저녁에 30분 러닝`) · `days`: 요일(최소 1개) · `notificationTime`: 마감 시각 · `description`: 메모(선택)

## 상태
| 상태 | 설명 |
|---|---|
| `active` | 진행 중. **새 약속은 짝꿍 유무와 상관없이 바로 active** |
| `completed` | 기간 종료 |
| `stopped` | 실행자가 조기 중단 |
| `pending_approval` | 레거시. 구버전이 만든 승인 대기 약속만 존재 |
| `rejected` / `draft` | 레거시 |

상태 값은 추가하지 않는다(구버전 호환).

## 약속 걸기 (1화면)
1. 헤더 `{애칭}한테 어떤 운동을 약속할까요?` (혼자이거나 수정이면 `어떤 운동을 약속할까요?`)
2. 운동 타일 3열 그리드(14종 + ✏️ 직접). 타일을 고르면 비어 있는(또는 이전 타일 기본값 그대로인) 약속 한 줄·요일·마감을 채운다. 직접 입력한 줄은 유지한다.
3. 약속 한 줄(수정 가능)
4. 빈도 칩(주 2일·주 3일·평일·주말·매일) + 요일 7칩. **최소 1개 필수**(예전의 "요일 없음 = 매일" 규칙 폐지)
5. 마감 칩(아침 7시·점심 12시·저녁 7시·밤 9시·밤 10시·직접). **필수**. 이 화면에는 끄기·매시간 옵션이 없다.
6. 메모(접힘) · 혼자면 `짝꿍 연결하기` 카드
7. 하단 고정 바: 요약(`주 3일 · 오후 10시 · 28일`), 짝꿍이 있으면 `못 하면 {애칭}한테 알려져요`, 버튼 `🤙 {애칭}이랑 손가락 걸기`(조사는 `withJosa`) / 혼자 `약속 시작하기` / 수정 `저장하기`
- 빈 항목이 있으면 무엇이 빠졌는지 알려 주고 저장하지 않는다.
- 새 약속이면 짝꿍의 최신 active 약속 요일을 미리 선택하고 힌트를 보여 준다.

## 저장 규칙
| 경우 | 결과 |
|---|---|
| 새 약속 | `active`, 기간 오늘 00:00 ~ +27일 23:59:59, `managerId`=현재 짝꿍, `lastUpdatedBy`=본인, `workoutType`=선택 타일(타일 없이 입력하면 `other`) |
| active·completed·stopped 수정 | 기간·상태·기록·내기·`lastActionId` 유지, `lastUpdatedBy`=본인 |
| pending·rejected·draft 수정 | active로 바꾸고 오늘부터 새 기간 |
| 재시작(상세 화면) | `asRestartTemplate()` — id·기록 없는 복사본으로 **새 문서** 생성(기존 약속 덮어쓰기 버그 수정) |
| 알림 설정 실패 후 재시도 | 이미 저장된 약속을 갱신(기간 재시작 없음) |

## 승인·조율 (레거시)
- 새 약속에는 승인 단계가 없다.
- 남아 있는 `pending_approval` 약속은 짝꿍이 승인할 수 있다. 승인은 트랜잭션으로, 여전히 pending일 때만 기간을 오늘~+27일로 다시 잡는다.
- 짝꿍 연결 시 서버와 앱 모두 기존 active 약속에 `managerId`만 지정한다(`lastUpdatedBy: 'system_link'`). 더 이상 pending으로 되돌리지 않는다.

## 완료·중단
- 종료일이 지난 active/pending은 자동 `completed`. 완료 약속은 지금 탭 4주 정산 카드로 다음 4주 의향을 받는다.
- 실행자가 조기 중단하면 `stopped`. stopped 약속은 중단일이 없어 둘운완 계산에서 미스를 만들지 않는다(duo_stats 정책).

## 비즈니스 규칙
- 짝꿍의 약속은 읽기 전용(인정·응원·똑똑·내기 제안만).
- 서버 불변식: `managerId`는 연결된 짝꿍이어야 한다. 아니면 `onPlanCreated`/`onPlanUpdated`가 해제한다.
- 운동 문구: `workoutType`이 있으면 운동 카피(식단은 `식단`, `운동`·`오운완` 표현 안 씀), 없으면 중립 `약속` 카피.
- 분석: `plan_created {is_edit, frequency, has_partner, workout_type, template_id, template_edited}`

## 알려진 한계
- 수정 저장은 화면을 연 시점의 약속 전체를 다시 쓴다. 그 사이 짝꿍 인정이 들어오면 덮일 수 있다(피벗 이전부터 존재).
- 알림이 꺼진 레거시 약속을 수정하면 밤 9시가 미리 선택돼 리마인더와 미기록 전달이 다시 켜진다.
- 실행자가 레거시 pending 약속을 수정해 active가 되면 서버가 짝꿍에게 `승인` 푸시를 보낸다(`onPlanUpdated`가 `lastUpdatedBy`를 보지 않음). 수정 대기.
- 상세 화면·알림 설정의 `NotificationSettingEditor`는 여전히 끌 수 있어, 끄면 짝꿍 미기록 전달도 멈춘다.
