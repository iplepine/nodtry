<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 집중 타이머(Focus Timer) 정책 — 숨김

마지막 갱신: 2026-10-03 · 상태: **숨김 (1.1.0+81부터)**

## 현재 상태
- 둘운완 피벗(D-007, 스펙 §6)에서 지금 탭의 `지금 할게!` 버튼을 숨겼다: `now_tab_screen.dart`의 `const _kFocusTimerEnabled = false`.
- 코드(`lib/features/now/presentation/focus_timer/`), 테스트, 분석 이벤트(`focus_timer_started|completed|cancelled`)는 그대로 남아 있다. 새 빌드에서는 이 이벤트가 발생하지 않는다.
- 숨긴 이유: 핵심 루프를 `오늘 운동했어? → 인증샷 → 인정` 하나로 좁히기 위해. 운동은 앱 밖에서 하고 앱은 인증만 받는다.

## 다시 켤 때 조건
- 지금 탭 히어로(📸 / 사진 없이 / 쉴게)와 버튼 위계가 충돌하지 않게 다시 설계한다.
- 운동 문구로 바꾼다(예: 홈트 N분). 공부·집중 문구는 금지어다.
- 플래그를 `true`로 바꾸기 전에 이 문서와 `now_tab_policy.md`를 먼저 갱신한다.

## 예전 동작 요약 (참고용)
- `nowAction` 카드의 `지금 할게!` → 5/10/25분 또는 직접(1~120분) → 카운트다운(멈춤·포기·`했어! 지금 끝낼게`) → 종료 시 메모 다이얼로그에 경과 시간 prefill → `reportCompletion`으로 `done` 기록.
- 진행 중 상태는 동기화하지 않았고(인앱 전용), 포기하면 아무 기록도 남기지 않았다. 데이터 모델 변경은 없었다.
