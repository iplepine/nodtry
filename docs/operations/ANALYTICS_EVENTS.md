<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (14 files)`
> - 문서 갱신: `2026-10-03 07:18:57 +0900`
<!-- COMMIT_STATUS END -->

# 분석 이벤트 사전 (Analytics Events)

마지막 갱신: 2026-10-03 (1.1.0+81 코드 기준, 미배포) · 정본 코드: `lib/utils/analytics.dart` (`AnalyticsEvent`, `AnalyticsUserProperty`)
지표 정의는 `../go-to-market/RETENTION_METRICS.md`, 목표·대시보드는 `../go-to-market/LAUNCH_PLAN_DUOUNWAN.md` §7.

## 규칙
- Google Analytics for Firebase(GA4). 이벤트·파라미터 이름은 snake_case, 40자 이하.
- 파라미터 값은 String/num만. `AnalyticsService.log`가 bool은 `1/0`으로 바꾸고 null은 버린다(`has_*`는 1/0으로 들어온다).
- **디버그 빌드는 수집 꺼짐**(`setAnalyticsCollectionEnabled(!kDebugMode)`). 확인은 릴리스 빌드 + DebugView.
- 개인 정보는 보내지 않는다: 애칭 텍스트·메시지 본문·사진 경로 없음. 사용자 ID는 uid만(`setUserId`).
- 기존 이벤트 이름은 바꾸지 않는다(퍼널 연속성). 코드의 `partner_*` 이름도 유지.
- `screen_view`는 GoRouter 옵저버가 자동 기록. `login`·`purchase`는 Firebase 예약 이벤트.

상태 표기: **신규**(피벗에서 추가) · **변경**(파라미터 추가) · 기존 · **미발생**(UI 숨김으로 새 빌드에서 안 나옴) · **레거시**(구 약속에서만)

## 1. 피벗 퍼널 (스펙 §6의 8종 ★)
| 이벤트 | 상태 | 언제 | 파라미터 |
|---|---|---|---|
| `invite_shared` ★ | 신규 | 초대 메시지 공유 완료 또는 코드 복사 | `channel`: `kakao`·`other`·`unknown`·`copy` / `surface`: `connect`·`onboarding`·`now_card`·`us` / `has_promise`(공유 시트만, 0·1) |
| `invite_code_detected` ★ | 신규 | 코드를 찾거나 입력해 소유자 조회 | `source`: `clipboard`·`manual`·`link` / `matched`(0·1) |
| `partner_connected` ★ | 변경 | 라이브 연결 순간 1회(앱 루트 `partnerLinkBinderProvider`) | `role`: `inviter`·`invitee`. 초대자 앱이 꺼져 있으면 초대자 쪽은 기록 안 됨 |
| `proof_uploaded` ★ | 신규 | 했어 기록마다(사진 유무 무관) | `has_photo`(0·1) / `source`: `camera`·`gallery`·`none`. `has_photo=0`+`source≠none` = 업로드 실패 |
| `partner_reacted` ★ | 신규 | 짝꿍이 원탭 인정(지금·기록 탭) | `latency_bucket`: `lt_5m`·`5m_30m`·`30m_2h`·`2h_6h`·`6h_24h`·`gt_24h`·`unknown` / `surface`: `now`·`now_note`·`history`·`history_note` / `reaction`(이모지) / `has_photo` |
| `duo_done_day` ★ | 신규 | 오늘이 둘운완 데이가 되면 기기당 하루 1회 | `streak` |
| `share_card_shared` ★ | 신규 | 공유 카드가 나감(`unknown`도 공유로 셈) | `target`: `kakao`·`instagram`·`save`·`copy`·`other`·`unknown` / `trigger`: `today`·`milestone`·`manual` / `streak` |
| `review_prompt_shown` ★ | 신규 | in_app_review 요청(OS가 실제 표시 결정) | `trigger`: `first_duo_day`·`third_props` / `count`(누적 요청 수) |

## 2. 연결·계정
| 이벤트 | 상태 | 파라미터 / 메모 |
|---|---|---|
| `invite_code_shared` | 기존(유지) | `method`: `share`·`copy`. `invite_shared`와 함께 기록, 과거 퍼널 연속용 |
| `connect_code_submitted` | 변경 | `source`: `clipboard`·`manual`·`link` (신규) |
| `connect_failed` | 변경 | `reason`: `not_found`(신규)·`self_code`(신규)·`owner_taken`(신규, 상대가 이미 다른 짝꿍과 연결)·`self_taken`(신규, 내가 이미 연결됨)·`exception` |
| `partner_nickname_set` | 신규 | `kind`: `preset`·`custom`·`removed` (텍스트 미전송) |
| `partner_disconnected` | 기존 | 내가 연결 해제 |
| `login` (예약) | 기존 | `login_method`: `google`·`apple`·`anonymous`·`email` |
| `login_failed` | 기존 | `method`, `reason`(예외 타입) |
| `logout`, `account_deleted` | 기존 | — |

## 3. 약속·일일 루프
| 이벤트 | 상태 | 파라미터 / 메모 |
|---|---|---|
| `plan_created` | 변경 | `is_edit`, `frequency`(요일 수), `has_partner` + 신규 `workout_type`(id 또는 `none`), `template_id`(타일 id 또는 `none`), `template_edited`(0·1). 알림 설정 실패 후 재시도하면 `is_edit=1`로 한 번 더 기록될 수 있음 |
| `plan_completed` | 변경 | `has_message` + 신규 `has_photo` |
| `plan_skipped`, `plan_passed`, `plan_rest_used` | 기존 | — |
| `plan_rescued` | 미발생에 가까움 | rescue 버튼 숨김 |
| `partner_cheered` | 기존 | `reaction_type`, `has_message`. 지금 탭 원탭 인정 시 `partner_reacted`와 **함께** 기록됨(중복 집계 주의) |
| `cheer_sent` | 신규 | 놓친 운동 카드의 응원(인정 아님): `surface`: `missed_card`, `has_message` |
| `poke_sent` | 기존 | `target`: `user`·`plan`, `has_message`, (`plan`일 때) `has_reward`, `has_penalty` |
| `poke_acknowledged` | 기존 | 똑똑 카드 확인 |
| `poke_replied` | 신규 | `kind`: `coming`(지금 간다)·`pass`(오늘은 봐줘) |
| `promise_proposed` | 기존 | `has_reward`, `has_penalty` |
| `promise_responded` | 기존 | `accepted` |
| `promise_settlement_acknowledged` | 기존 | `has_comment` |
| `pilot_settlement_recorded` | 기존 | 4주 정산 카드: `next_plan_intent`, `exit_reason`(없으면 `none`). 이름은 레거시 유지 |
| `plan_approved`, `plan_rejected` | 레거시 | 구버전 승인 대기 약속에서만. `plan_rejected`: `has_reason` |
| `partner_checked`, `partner_verified` | 미발생 | 해당 인텐트가 UI에서 더 이상 도달 불가 |

## 4. 알림·설정·기타
| 이벤트 | 상태 | 파라미터 / 메모 |
|---|---|---|
| `notification_opened` | 변경 | `type`(푸시 `data.type`, 신규 `poke_reply`·`partner_connected`·`partner_connect_failed` 포함), `cold_start`, `action`(1.1.1+86~: 알림 버튼 `props`·`poke_coming`·`poke_pass`·`cheer`, 본문 탭은 `none`). 버튼으로 실행된 인정·답장·응원은 각각 `partner_reacted`(`surface: notification`)·`poke_replied`·`cheer_sent`로도 기록 |
| `notification_permission_result` | 기존 | `granted` |
| `notification_banner_shown`, `notification_banner_tapped` | 기존 | 권한 배너 |
| `locale_changed` | 기존 | `locale` |
| `theme_changed` | 미발생 | 테마 선택 숨김 |
| `focus_timer_started` / `_completed` / `_cancelled` | 미발생 | 집중 타이머 숨김. `duration_min`, `elapsed_min`, `manual` |
| `donation_initiated` | 기존 | `product_id` |
| `purchase` (예약) | 기존 | `value`, `currency`, `items` |
| `purchase_failed` | 기존 | `reason` |

## 5. 사용자 속성
| 속성 | 값 | 메모 |
|---|---|---|
| `login_method` | google·apple·anonymous·email | |
| `has_partner` | `true`·`false` | 연결 vs 혼자 비교의 기본 차원 |
| `app_locale` | `ko`·`en`·`system` | |
| `app_theme` | 항상 `smokyPlum` | 테마 고정으로 의미 없음 |

## 6. 폐기·미계측 이름
- 파일럿 수동 집계용 이름(`pilot_joined`, `study_plan_created`, `study_action_completed`, `partner_feedback_sent`, `plan_adjusted`, `pilot_settled`, `next_plan_intent_recorded`, `paid_intent_recorded`)은 코드에 없었고 폐기했다.
- 제안만 있고 미구현: `partner_connected.minutes_since_invite`(연결까지 시간 중앙값용. BigQuery 연결로 대체 가능, 장영실 결정).

## 7. 확인 절차 (출시 전, BT-009)
1. 릴리스 빌드에 `-FIRDebugEnabled`(iOS) / `adb shell setprop debug.firebase.analytics.app com.devho.nodtry.app`(Android)로 DebugView 연결.
2. 두 기기로 초대 공유 → 링크/클립보드 감지 → 연결 → 애칭 → 약속 → 인증샷 → 인정 → 둘운완 데이 → 공유 카드 순서로 ★ 8종이 모두 들어오는지 본다.
3. 파라미터 값이 위 표의 열거값과 같은지 확인한다.

## 8. 서버 일일 집계 (`dailyStats`)
클라이언트 이벤트로는 알 수 없는 전체 현황용. Cloud Function `aggregateDailyStats`가 매일 00:10(KST)에 **전날(KST)** 값을 Firestore `dailyStats/{YYYY-MM-DD}`에 쓴다(서버 전용, 클라이언트 규칙 없음 — Firebase 콘솔에서 확인). 같은 날을 다시 돌리면 덮어쓴다.

| 필드 | 뜻 |
|---|---|
| `newUsers` | 그날 가입 수 (`users.createdAt`) |
| `newCouples` | 그날 새로 연결된 커플 수 (`relations`는 2문서/쌍이라 반올림 절반) |
| `doneRecords` | 그날 `했어` 기록 수 (`actions.type=done`) |
| `activeUsers` | 그날 `했어`를 1건 이상 남긴 고유 사용자 수 |
| `cheers` | 그날 인정·응원·똑똑 등 `cheers` 문서 수 |
| `totalUsers`, `totalCouples`, `activePlans` | 집계 시점 누적/현재 값 |
| `computedAt` | 기록 시각 |
