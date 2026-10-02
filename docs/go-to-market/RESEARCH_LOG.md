<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (8 files)`
> - 문서 갱신: `2026-10-03 07:18:56 +0900`
<!-- COMMIT_STATUS END -->

# 리서치 로그

## 목적
사용자 문제, 시장 반응, 온보딩 병목, 유지 요인을 짧게 누적한다. 현재 핵심 연구 질문은 `작은 약속을 알아봐 주고 확인해 주는 한 사람이 있을 때 다음 실천율이 높아지는가`다.

이 질문의 상승 효과는 아직 `Assumption`이다. 파일럿 결과가 쌓이기 전에는 효과가 입증됐다고 기록하거나 외부에 주장하지 않는다.

## 기록 형식
- 날짜:
- 대상:
- 질문:
- 관찰:
- 인사이트:
- 후속 액션:

## 우선 질문
- 사용자가 혼자 루틴을 포기하는 순간은 언제인가
- 어떤 한 사람이라면 작은 약속을 부담 없이 알아봐 줄 수 있는가
- 초대부터 `partner_connected`까지 어디에서 이탈하는가
- `partner_feedback_sent`는 얼마나 자주, 얼마나 빨리 도착하는가
- 피드백을 받은 뒤 다음 예정 행동 완료율은 피드백이 없었던 경우와 어떻게 다른가
- 확인과 똑똑은 응원, 감시, 부담 중 무엇으로 느껴지는가
- 같은 실천 메이트와 다음 4주를 이어갈 의향이 있는가
- 보상/벌칙 약속은 실제 행동을 바꾸는가
- 4주 후 사용자가 다시 플랜을 만들 이유는 무엇인가

## 초기 가설
- 한 명의 실천 메이트가 작은 약속을 알아봐 주면 피드백 없음 상태보다 다음 실천율이 높아진다. `Assumption`
- 초대와 연결이 완료되고 피드백이 다음 예정 행동 전에 도착해야 가설을 검증할 수 있다. `Assumption`
- 목표가 작을수록 첫 주 이탈이 줄어든다.
- 벌칙보다 응원과 보상이 장기 유지에 더 적합하다.

고객에게는 `실천 메이트`를 사용한다. 코드와 데이터의 기존 `partner_connected`, `partner_feedback_sent` 등 `partner_*` 명칭은 변경하지 않는다. 연인, 친구, 가족, 동료는 실천 메이트가 될 수 있는 예시일 뿐 별도 세그먼트나 제품 정체성이 아니다.

## 열린 메모
- 민감한 루틴은 공유 범위를 세밀하게 조정해야 할 수 있다.
- 실천 메이트가 바쁘거나 피드백이 늦으면 실천 루프가 약해질 수 있다.
- 10쌍 파일럿의 피드백 유무 비교에는 자기선택과 행동 난이도 차이가 섞일 수 있으므로 인과 효과로 단정하지 않는다.

## 2026-10-02 피벗 리서치

- 날짜: 2026-10-02 (조사일. 스토어 순위는 이날 스냅샷)
- 대상: 한국 App Store·Google Play 카테고리 차트, 커플·운동 앱 경쟁 구도, ASO 키워드, 브랜드 충돌, 근거 연구, 스토어 정책
- 질문: 커플 운동 약속 앱 `둘운완`으로 피벗하면 어느 카테고리에서 Top 10에 들 수 있는가. 무엇을 근거로 무엇을 주장할 수 있는가.
- 결정 연결: `docs/decisions/DECISIONS.md` D-007, 정본 스펙 `docs/product/PIVOT_DUOUNWAN_SPEC.md`. 이 절 위에 있는 `실천 메이트` 가설과 용어는 D-007로 대체된 이력이다. 기록 보존을 위해 지우지 않는다.

### 라벨 정의
- `Evidence`: 공식 문서·정책, 또는 이날 직접 관측한 1차 데이터(스토어 페이지, 차트, KIPRIS)
- `Signal`: 2차 출처(언론·블로그·분석 사이트), 자동완성 결과, 개별 사례. 방향만 알려 준다
- `Assumption`: 추론, 또는 아직 검증하지 않은 가정. 외부에 주장하지 않는다

### 관찰

| # | 관찰 | 라벨 | 출처 |
|---|---|---|---|
| 1 | iOS KR 건강 및 피트니스 무료 Top 20은 정부·의료미용·리워드·운동 앱이 섞여 있다. 1인·소규모 앱도 들어 있다(Charlie #11~13, 짐워크 #14~15, StressWatch #20). Top 50 안에 커플 운동 앱은 없다 | Evidence | https://apps.apple.com/kr/charts/iphone/health-fitness-apps/6013 ; https://www.appbrain.com/stats/appstore-rankings/top_free/health_and_fitness/kr ; https://www.similarweb.com/top-apps/apple/korea-republic-of/health-fitness/ |
| 2 | 차트 변동이 크다. Finns SwimLog가 #20(9/29, Similarweb)에서 #193(10/2, App Store 페이지)으로 내려갔다. 측정 출처가 서로 다르다 | Signal | https://apps.apple.com/kr/app/finns-swimlog/id6764380467 |
| 3 | iOS KR 라이프스타일 상위권은 편의점·마트·정부 앱이다. 썸원은 라이프스타일 #140, 비트윈은 소셜 #101로 대형 커플 앱도 Top 10 밖이다 | Evidence | https://apps.apple.com/kr/charts/iphone/lifestyle-apps/6012 ; https://apps.apple.com/kr/charts/iphone/social-networking-apps/6005 |
| 4 | Play KR 건강/운동 Top 10은 정부 앱과 수백만 설치 리워드 만보기가 지킨다. 20~50위에는 누적 설치가 적은 앱도 있다 | Evidence(차트) / Signal(속도만으로 진입 가능하다는 해석) | https://www.appbrain.com/stats/google-play-rankings/top_free/health_fitness/kr |
| 5 | KR 카테고리 Top 10에 필요한 일 다운로드는 공개 데이터가 없다. 간접 기준점: 필라이즈(하루 약 2.6K, 양대 마켓)가 iOS 건강 1위, 헤이문(첫 주 하루 약 3K)이 출시 4일 만에 iOS 건강 1위 | Signal | https://www.betanews.net/article/view/beta202606260011 ; https://www.ksvalley.com/news/article.html?no=6914 ; https://www.apptweak.com/en/aso-blog/number-of-downloads-to-reach-top-rankings |
| 6 | 추정: iOS Top 10 유지에 하루 1,000~3,000건, Top 20~30에 하루 수백 건 | Assumption | 위 5번에서 추론. 소프트 런칭에서 실측 예정 |
| 7 | 현재 기준선: iOS App ID 6761373605, 주 건강 및 피트니스·보조 라이프스타일, KR 평점 0. Play는 생산성 카테고리, 설치 10+ | Evidence | https://itunes.apple.com/lookup?bundleId=com.devho.nodtry.app&country=kr ; https://play.google.com/store/apps/details?id=com.devho.nodtry.app |
| 8 | 같은 방식이 해외에서 검증됐다. Sweatmates(미국, 2025-12 출시)는 사진 인증·파트너 확인·가벼운 벌칙 구조이고 평점 약 4.9, 평가 약 1.3만이다. KR 스토어에도 있지만 영어 전용이고 KR 평가는 0이다 | Evidence | https://apps.apple.com/us/app/sweatmates-partner-fitness/id6756000479 ; https://apps.apple.com/kr/app/id6756000479 |
| 9 | 국내 유사 앱은 모두 작다. 투투 26, 키피럽 5, 다메다메 9(평가 수) | Evidence | https://apps.apple.com/kr/app/id6455260918 ; https://apps.apple.com/kr/app/id6757021644 ; https://apps.apple.com/kr/app/id6479599229 |
| 10 | 새 경쟁 신호: 커플 운동 내기 콘셉트의 SweatBets가 2026-09-17 미국에 출시됐다. 딜라이트룸은 비트윈(커플)과 플릭(근력 기록)을 함께 보유하고 있다 | Evidence(출시) / Signal(위협 해석) | https://apps.apple.com/us/app/id6807899279 ; https://www.unicornfactory.co.kr/article/2025091610104358526 |
| 11 | 썸원은 혼자 쓸 수 없는 구조, 고무신 커뮤니티, 틱톡 입소문으로 성장했고 초기 광고비는 2.5만 원이었다 | Signal | https://maily.so/unsexybusinesskr/posts/5xrxkqdyo2v |
| 12 | 위젯이 커플·친구 앱 확산을 이끌었다(Locket, Widgetable, TheDayBefore) | Signal | https://whatastartup.substack.com/p/he-built-an-app-for-his-girlfriend-and-ended-up-having-80-million-total-downloads ; https://mwm.ai/apps/widgetable-besties-couples/1641107226 |
| 13 | #오운완 게시물 약 732만 개. 2022년 인스타그램 급성장 해시태그로 꼽혔다 | Signal | https://www.seouland.com/arti/culture/culture_general/14938.html ; https://www.newsis.com/view/NISX20221213_0002121171 |
| 14 | 키워드 의도(자동완성 기준, 검색량 아님) | Signal | Naver·Google·Play 자동완성(2026-10-02) ; https://apps.apple.com/kr/iphone/search?term=운동%20인증 |
|    | · '운동 인증 어플', '오운완 어플', '커플 다이어트 어플', '다이어트 내기', '커플 내기 벌칙', '남친 운동시키는 법'이 나온다 | | |
|    | · iOS에서 '운동 인증'·'다이어트 내기' 상위 결과는 평가 30개 미만 앱이다 | | |
| 15 | '커플'·'커플앱'은 닫혀 있다(비트윈 평가 약 26.9만, 썸원 약 13.1만) | Evidence | https://apps.apple.com/KR/app/id458035189 ; https://apps.apple.com/kr/app/id1469506430 |
| 16 | iOS 키워드 필드가 100바이트인지 100자인지 출처마다 다르다 | Assumption(미검증) | https://www.applyra.io/blog/app-store-character-limits ; https://github.com/AsoBeast/asobeast/pull/110 |
| 17 | `둘운완`은 KIPRIS 상표명칭, 네이버 정확 일치, KR App Store, Play 검색에서 모두 0건이다. 유사 칭호는 확인하지 않았다(변리사 필요) | Evidence(텍스트 검색) / Assumption(등록 가능성) | https://www.kipris.or.kr ; https://itunes.apple.com/search?term=둘운완&country=kr&entity=software |
| 18 | KIPO는 '오운완' 계열 출원을 거절·포기 처리해 왔다(샵오운완 09류 등). 일반어로 보는 경향이다 | Evidence | KIPRIS TN="오운완" (예: 4020220113494, 4020220239187) |
| 19 | 같은 이름 '운동했어'인 앱이 양 스토어에 있어 후보에서 탈락했다 | Evidence | https://apps.apple.com/kr/app/id6780768847 ; https://play.google.com/store/apps/details?id=com.dmlabs.workedout |
| 20 | 배우자와 함께 등록한 기혼자의 12개월 중도 포기율 6.3%, 혼자 등록 43%. 1995년 소규모 연구이고 이 앱의 효과가 아니다 | Evidence(논문) / 외부 주장은 긴 설명에서 출처와 함께만 | https://www.researchgate.net/publication/14426469 |
| 21 | stickK: 확인자(referee)가 있으면 성공률 약 59%, 없으면 약 29%. 사용자가 스스로 고른 집단이라 인과관계가 아니다 | Signal | https://www.stickk.com/aboutus ; https://yaledailynews.com/blog/2012/02/21/stickk-helps-the-irresolute/ |
| 22 | 실제 돈을 거는 방식은 위험하다. Pact가 FTC와 합의해 $948,788을 환불했다 | Evidence | https://www.marketingdive.com/news/exercise-app-settles-ftc-allegations-that-it-defrauded-users/505701/ |
| 23 | 유료·인센티브로 순위를 부풀리면 Apple은 퇴출할 수 있고, Google은 인센티브 설치를 걸러낸다 | Evidence | https://developer.apple.com/app-store/review/guidelines/ ; https://android-developers.googleblog.com/2017/06/google-plays-policy-on-incentivized.html |
| 24 | 피처링 추천은 출시 3주~3개월 전에 낸다. In-App Event는 검색에 노출되고, 이름 30자·짧은 설명 50자 제한이 있다 | Evidence | https://developer.apple.com/help/app-store-connect/manage-featuring-nominations/nominate-your-app-for-featuring/ ; https://developer.apple.com/app-store/in-app-events/ |
| 25 | 카테고리 정의상 Apple 건강 및 피트니스와 Google 건강/운동은 운동 추적을 포함한다. Play 건강/운동은 건강 앱 신고 대상이 될 수 있다 | Evidence | https://developer.apple.com/app-store/categories/ ; https://support.google.com/googleplay/android-developer/answer/9859673 |
| 26 | 20대 아이폰 비율 약 60~64%(전체 24%) | Signal | https://www.datanews.co.kr/news/article.html?no=139581 |
| 27 | 페어 설치 기댓값: 유료 신규 1명당 iOS 설치 약 1.36건(짝꿍 전환 60% × 아이폰 60%) | Assumption | 26번에서 계산 |
| 28 | `nod-try.web.app` Hosting은 아직 비어 있다("Site Not Found"). 초대 랜딩이 첫 배포가 된다 | Evidence | https://nod-try.web.app/ (curl 2026-10-02) |

### 인사이트
- iOS KR 건강 및 피트니스는 인디 앱도 들어가는 유일한 현실적 Top 10 카테고리다. 다만 순위는 3~7일 다운로드 속도 싸움이라 Top 10은 "버스트 중 진입"으로 정의한다.
- 초대 루프는 1:1 구조라 K≤1이다. 순위에 필요한 속도는 출시 버스트(In-App Event·유료)와 공유 카드(#둘운완)가 만든다.
- '커플' 단독 키워드는 닫혀 있다. 대신 커플·오운완·운동·인증·다이어트·내기 조합의 빈 검색어를 선점한다.
- 외부 근거 수치는 이 앱의 효과가 아니다. 대외 주장은 출처를 밝힌 연구 소개로만 쓴다. 우리 가설("커플이 봐주면 운동 약속을 더 지킨다")은 계속 `Assumption`이다.

### 가설 갱신
- 핵심 가설: 연인·부부 한 명이 운동 약속을 봐주면 혼자일 때보다 약속 이행일이 늘어난다. `Assumption`
  - 측정: 연결 사용자와 혼자 쓰는 사용자의 예정일 완료율, `duo_done_day`, D7을 비교한다.
  - 자기선택 편향이 섞이므로 인과로 단정하지 않는다.
- 성장 가설: 초대→연결 50% 이상, 둘운완 데이→공유 카드 15% 이상이면 유료 1명이 iOS 설치 1.3건 이상과 오가닉 노출을 만든다. `Assumption`

### 후속 액션
- 소프트 런칭(11/3~11/23 계획)에서 순위-설치 곡선을 실측하고 6번 추정을 갱신한다 → `LAUNCH_PLAN_DUOUNWAN.md` §3
- ASA 인기도, 키워드 100바이트/100자, KR 스토어의 en-US 색인 여부를 검증한다 → `ASO_DUOUNWAN.md` §3
- 변리사에게 둘운완·DuoDone 09·41·42·45류 유사군 정밀 조사와 출원을 맡긴다(D-007 대표 승인 대기)
- Sweatmates·SweatBets의 한국어 지원 여부를 월 1회 확인한다
