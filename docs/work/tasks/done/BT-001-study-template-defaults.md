# Task

ID: `BT-001-study-template-defaults`

유형: `Build`

상태: `Done`

연결 Roadmap: `R-001-study-sprint-prep`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-05-03

## 목표

4주 스터디 책임 스프린트 참여자가 첫 플랜을 만들 때 공부 행동을 직접 발명하지 않아도 되도록 템플릿과 기본값을 제공한다.

## 구현 범위

- 플랜 생성 첫 단계에 5개 스터디 템플릿 노출
- 템플릿 선택 시 행동, 설명, 요일, 알림 자동 입력
- 기본 빈도는 주 3회, 기본 알림은 21:00
- 영어/자격증 템플릿은 주 5회, 코딩/독서/글쓰기는 주 3회
- 새 플랜 저장 기간을 28일 프로그램으로 고정

## 완료 기준

- [x] 템플릿 선택 UI 추가
- [x] ViewModel에서 템플릿 적용 intent 처리
- [x] 저장되는 플랜이 28일 기간과 정렬된 요일을 사용
- [x] focused ViewModel 테스트 추가
- [x] 파일럿 문서 갱신

## 검증 결과

명령:

- `flutter test test/viewmodels/plan_create_viewmodel_test.dart --reporter expanded`
- `flutter test --reporter expanded`

결과:

- 통과.

## 남은 리스크

- 전체 플랜 생성 화면의 실제 모바일 시각 확인은 다음 UI slice에서 함께 수행한다.
