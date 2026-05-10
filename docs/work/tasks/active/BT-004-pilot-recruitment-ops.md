# Task

ID: `BT-004-pilot-recruitment-ops`

유형: `Ops`

상태: `Active`

연결 Roadmap: `R-001-study-sprint-prep`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-05-10

## 목표

4주 스터디 책임 스프린트를 실제 10쌍 파일럿으로 시작할 수 있도록 모집 메시지, 시작 전 질문, 1주차 수동 집계 위치를 확정한다.

## 배경

제품 thin slice는 카테고리 기반 플랜 생성, 파트너 똑똑 압박, 놓친 약속 자동 전달, 4주 정산 카드까지 준비됐다. `1.0.30+49`는 Android production과 iOS TestFlight까지 배포됐다. 다음 병목은 제품 기능이 아니라 모집과 운영 증거 수집이다.

## 포함

- 10쌍 모집 메시지 최종본
- 시작 전 질문 5개 확정
- 1주차 D1/W1 수동 집계 시트 또는 로그 위치 확정
- 똑똑이 압박으로 느껴지는지 확인할 인터뷰 질문 확정

## 제외

- 결제 구현
- 공개 모집 랜딩 페이지
- 자동 분석 대시보드

## 완료 기준

- [ ] 모집 링크 또는 모집 폼이 준비됨
- [ ] 시작 전/종료 후 질문이 한 곳에 정리됨
- [ ] `pilot_joined`, `partner_connected`, `study_plan_created`, `partner_feedback_sent` 수동 집계 위치가 정해짐
- [ ] 파일럿 시작 안내 문구가 확정됨

## 현재 To-do

- [ ] 모집 링크 또는 모집 폼 생성
- [ ] 시작 전 질문 5개와 종료 후 질문 6개를 폼/문서 한 곳에 정리
- [ ] 수동 집계 시트 컬럼 확정: `pilot_joined`, `partner_connected`, `study_plan_created`, `study_action_completed`, `partner_feedback_sent`, `poke_sent`, `action_missed_seen`
- [ ] 내부 테스트/프로덕션 설치 안내 문구 확정
- [ ] 1쌍 리허설: 설치 → 가입 → 연결 → 플랜 생성 → 똑똑/확인 → 히스토리 확인

## 검증 계획

- 운영자가 참여자 1쌍을 수동 등록한다고 가정하고 모집부터 앱 설치 안내까지 리허설한다.

## 준비 완료 항목

- Android production: `1.0.30+49`
- iOS TestFlight: `1.0.30+49`
- Cloud Functions: Node.js 22, `notifyMissedActions`, `onPlanUpdated`, `onCheerCreated` 배포 완료
