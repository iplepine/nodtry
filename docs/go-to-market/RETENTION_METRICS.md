<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (9 files)`
> - 문서 갱신: `2026-10-03 07:18:56 +0900`
<!-- COMMIT_STATUS END -->

# 유지·퍼널 지표 — 둘운완

마지막 갱신: 2026-10-03 · 이벤트 정의 `../operations/ANALYTICS_EVENTS.md` · 대시보드·목표 `LAUNCH_PLAN_DUOUNWAN.md` §7

## 핵심 루프
초대 공유 → 연결(+애칭) → 운동 약속 → 오운완 인증(인증샷) → 짝꿍 인정 → 다음 예정일 → 둘운완 데이 → 공유 카드 → (신규 설치)

## 핵심 가설
- 제품: 연인·부부 한 명이 운동 약속을 봐주면 혼자일 때보다 약속 이행일이 늘어난다. `Assumption`
  - 외부 근거는 이 앱의 효과가 아니다: Wallace 1995(배우자 동반 중도 포기 6.3% vs 혼자 43%) `Evidence`(논문, 소규모·1995), stickK(확인자 있음 약 59% vs 없음 약 29%) `Signal`(자기선택).
- 성장: 초대→연결 50% 이상, 둘운완 데이→공유 카드 15% 이상이면 유료 신규 1명이 iOS 설치 1.3건 이상과 오가닉 노출을 만든다. `Assumption`
- 비교는 자기선택 편향이 섞이므로 인과로 단정하지 않는다. 방향성과 운영 가능성을 본다.

## 퍼널 (GA4, 출시 후 측정)
| 단계 | 정의(이벤트) | 목표 | 근거 수준 |
|---|---|---|---|
| 초대 공유 | `invite_shared` 사용자 / 신규 가입자 | 기준선 측정 | — |
| 코드 감지 경로 | `invite_code_detected` `source`별 비율, `matched=1` 비율 | 참고 | — |
| **초대→연결** | `invite_shared` 사용자 중 72시간 안에 `partner_connected` | **≥50%** | `Assumption` |
| 연결까지 시간 | `invite_shared` → `partner_connected` 중앙값 | ≤24h | `Assumption` |
| 애칭 설정 | `partner_nickname_set` / `partner_connected{role}` | 참고 | — |
| 첫 약속 | `plan_created{is_edit=0}` / 연결 사용자 | 기준선 측정 | — |
| 인증샷 비율 | `proof_uploaded{has_photo=1}` / `proof_uploaded` | 참고 | — |
| 업로드 실패 | `proof_uploaded{has_photo=0, source≠none}` / `source≠none` | <5% | `Assumption` |
| 인정까지 시간 | `partner_reacted.latency_bucket` 분포 | 중앙 ≤3h(`lt_5m`~`30m_2h` 비중) | `Assumption` |
| 둘운완 데이 | `duo_done_day` 사용자 / 연결 사용자(주간) | 기준선 측정 | — |
| **둘운완→공유 카드** | `share_card_shared` 사용자 / `duo_done_day` 사용자 | **≥15%** | `Assumption` |
| 평점 요청 | `review_prompt_shown` 횟수 vs 스토어 평점 수 | 버스트 전 iOS ≥50(대체 ≥20) | `Assumption` |

## 리텐션
| 지표 | 목표 | 근거 수준 |
|---|---|---|
| D1 전체 / 연결 사용자 | ≥35% / ≥45% | `Assumption` |
| D7 전체 / 연결 사용자 | ≥15% / ≥25% | `Assumption` |
| 연속 둘운완 3·7·30일 도달률 | 기준선 측정(`share_card_shared{trigger=milestone}`, `duo_done_day.streak`) | — |
| 연결 해제율 | `partner_disconnected` / 연결 쌍(주간) | 기준선 측정 | — |

- 연결 사용자와 혼자 쓰는 사용자를 나눠 본다(사용자 속성 `has_partner`).

## 핵심 가설 측정 (출시 후)
| 측정 | 산식 | 해석 |
|---|---|---|
| 예정일 완료율(연결 vs 혼자) | 예정일 중 done 비율. 서버 데이터(plans `completedDates`·요일) 집계 필요 — GA4만으로는 불가 | 핵심 가설 방향 |
| 인정 후 다음 예정일 완료율 | 인정받은 다음 예정일의 done 비율 vs 인정 없이 맞은 다음 예정일 | 인정의 효과 방향 |
| 놓친 운동 후 복귀 | `action_missed` 후 24시간 안 done 비율, `poke_replied{kind}` 분포 | "짝꿍이 안다"의 효과 방향 |
| 감시/부담 인식 | 리뷰·문의·신고 텍스트 분류, 연결 해제율 | 신뢰·지속 가능성 |

## 위험 신호
- 초대 공유는 많은데 연결이 안 됨(링크·설치·코드 입력 마찰)
- 인증샷 업로드 실패율 상승(HEIC·회선)
- 인정까지 시간이 길어짐(`gt_24h` 비중 증가) → 확인 루프 약화
- `poke_replied{kind=pass}` 비중 증가, 똑똑 후 앱 미방문
- 연결 해제·신고 증가(감시로 해석)
- 공유 카드 시트 무시율 상승(매일 노출 피로 — 빈도 결정 대기)

## 측정 메모
- 디버그 빌드는 Analytics 수집이 꺼져 있다. 릴리스 빌드 + DebugView로 퍼널 8종을 확인한다(BT-009).
- 연결까지 시간 중앙값은 Firebase → BigQuery 연결 또는 `partner_connected.minutes_since_invite` 추가가 필요하다(장영실 결정).
- `partner_connected{role=inviter}`는 초대자 앱이 살아 있을 때만 기록된다. 초대→연결 비율은 `invitee` 기준으로도 함께 본다.

## 폐기된 파일럿 지표 (이력)
`pilot_joined`, `study_plan_created`, `study_action_completed`, `partner_feedback_sent`, `plan_adjusted`, `pilot_settled`, `next_plan_intent_recorded`, `paid_intent_recorded`는 4주 스터디 파일럿 수동 집계용 이름이었다. 코드에 계측된 적이 없고 파일럿은 모집 준비 단계에서 중단됐다(D-007). 앱에 남은 `pilotNextPlanIntent`·`pilotExitReason`·`pilotSettledAt` 필드는 4주 정산 카드가 계속 쓴다.
