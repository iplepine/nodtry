# 일일 운영 로그 분석 브리프 (dot용)

매일 `dailyStats`를 읽고 이상 징후와 다음 행동을 보고하기 위한 안내서.

## 1. 데이터 위치
- Firebase 프로젝트 `nod-try` → Firestore → 컬렉션 `dailyStats`, 문서 ID는 `YYYY-MM-DD`(KST).
- 매일 00:10 KST에 전날 값이 생긴다(함수 `aggregateDailyStats`). 그날 문서가 없으면 함수 실패로 보고 Functions 로그를 확인하라고 알린다.
- 읽기에는 서비스 계정 또는 콘솔 권한이 필요하다(앱 사용자 규칙으로는 읽을 수 없음). 자격 증명은 채팅에 붙여넣지 않는다.

## 2. 필드 정의
| 필드 | 뜻 |
|---|---|
| `newUsers` | 그날 가입 수 |
| `newCouples` | 그날 새로 연결된 커플 수 |
| `doneRecords` | 그날 `했어` 기록 수 |
| `activeUsers` | 그날 `했어`를 남긴 고유 사용자 수 (DAU 대용) |
| `cheers` | 인정·응원·똑똑 수 |
| `totalUsers` / `totalCouples` / `activePlans` | 집계 시점 누적·현재 값 |

## 3. 매일 계산할 파생 지표
- 연결률 = `totalCouples * 2 / totalUsers` (연결된 사용자 비율)
- 활동률 = `activeUsers / totalUsers`
- 인당 기록 = `doneRecords / activeUsers`
- 인정 반응률 = `cheers / doneRecords` (짝꿍이 기록에 얼마나 반응하는지)
- 7일 이동평균 대비 오늘 값의 증감(%)

## 4. 보고 형식 (한국어, 짧게)
1. 어제 수치 한 줄 요약과 7일 평균 대비 증감
2. 이상 징후(아래 기준)가 있으면 맨 위에 표시
3. 오늘 확인할 것 1~3개

## 5. 이상 징후 기준 (시작값, 데이터가 쌓이면 조정)
- 문서 누락: 어제 날짜 문서가 없음
- `activeUsers`가 7일 평균의 50% 미만, 또는 `doneRecords`가 0
- `newUsers`는 있는데 `newCouples`가 3일 연속 0 (초대·연결 단계 이탈 의심)
- `cheers / doneRecords`가 0.3 미만으로 3일 연속 (인정 루프 약화)
- `totalUsers`가 감소 (계정 삭제 급증)

## 6. 한계 (오판 방지)
- 배포한 날 다음 날부터 쌓인다. 과거 날짜는 비어 있다.
- 테스트 계정과 개발자 기록도 섞여 있을 수 있어, 사용자 수가 적을 때는 절대값보다 추세를 본다.
- 이 숫자는 서버 집계라서 화면 이동·초대 공유·알림 클릭 같은 앱 내 행동은 없다. 그건 GA4 이벤트(`ANALYTICS_EVENTS.md`)에서 본다.
- 판단이 필요한 결정(가격, 마케팅 집행, 스토어 변경)은 보고만 하고 CEO 승인을 받는다.
