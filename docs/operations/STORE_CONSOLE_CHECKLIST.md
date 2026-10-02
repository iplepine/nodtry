<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (19 files)`
> - 문서 갱신: `2026-10-03 07:18:57 +0900`
<!-- COMMIT_STATUS END -->

# 스토어·콘솔 체크리스트 — 둘운완 1.1.0 (81)

> 작성 2026-10-02 · 김삿갓 / 마케팅실장 · 검토 황희 / 리스크 감시역 · **실행: 대표**(콘솔 클릭은 전부 대표 계정)
> 메타데이터 문구: `docs/go-to-market/ASO_DUOUNWAN.md` · 배포 순서: `LAUNCH_RUNBOOK.md` · 이벤트 문구: `docs/go-to-market/LAUNCH_PLAN_DUOUNWAN.md` §4
> 원칙
> - 데모 계정 비밀번호와 결제 수단은 레포, 문서, 채팅 어디에도 적지 않는다. 대표가 콘솔에 직접 입력한다.
> - 항목마다 완료 화면을 캡처해 둔다. 캡처는 레포 밖 공유 드라이브에 보관한다.

시점 표기: **[사전]** 심사 제출 7일 전까지 · **[제출]** 심사 제출 때 · **[공개]** 동시 공개 때 · **[후]** 공개 뒤

## A. 공통 사전 준비

- [ ] **[사전]** ASC 계약·세금·금융 정보가 "활성"인지 확인한다. 만료 상태면 업로드가 "A required agreement is missing or has expired"로 실패한다(반복 이력 있음).
- [ ] **[사전]** 개인정보처리방침과 지원 페이지를 새 이름으로 갱신하고, 현재 스토어에 등록된 URL이 200으로 열리는지 확인한다. 반영할 내용:
  - 서비스명 `둘운완(DuoDone)`(구 그래,해봐)
  - 수집 항목 추가: 인증샷(사진), 운동 종류·완료 기록, 애칭, 한마디·내기 문구, 시간대·언어·앱 빌드
  - 인증샷 제공 대상은 연결된 짝꿍 1명뿐이다. 업로드 전 위치 정보(EXIF/GPS)를 지운다는 사실을 적는다.
  - 보관·파기: 본인이 삭제하거나 탈퇴하면 서버에서 삭제한다.
    - 연결을 해제하면 "앱에서 더 이상 볼 수 없음"까지만 약속한다. 상대 기기에 남은 캡처는 회수할 수 없다.
  - 처리 위탁: Google Firebase(Cloud Firestore·Cloud Storage·Cloud Functions·Authentication·FCM·Analytics·Crashlytics)
  - 국외 이전: Google LLC, 미국. 이전 항목, 시점, 방법을 적는다.
  - 민감정보 해당 여부(바디 사진·운동 기록): 변호사 검토 결과를 반영한다. 대표가 결정한다.
- [ ] **[사전]** 심사용 데모 계정 2개를 만든다. 이메일 로그인 계정이어야 하고, 게스트 계정은 심사관에게 줄 수 없다.
  - A와 B를 연결한다. A에게 오늘 요일이 포함된 운동 약속(마감 시각 있음)을 만든다.
  - A가 **오늘 날짜로** 인증샷을 1장 올린다. 사람 얼굴이나 신체가 아닌 운동화·덤벨 사진으로 한다.
  - B가 ❤️로 인정한다. 비금전 내기 1개("못 지키면 🍗 치킨 쏘기")를 걸어 둔다.
  - "오늘" 상태가 바뀌므로 **심사 제출 48시간 안에** 다시 준비한다.
- [ ] **[사전]** 임시 운영 리드(Temporary Operations Lead)를 지정한다. 신고 메일 24시간 대응과 리뷰 답변을 맡는다. 심사 메모에 약속하는 내용이므로 반드시 필요하다.
- [ ] **[사전]** 아래 "제출 전 앱 동작 확인"은 장영실 / 기술실장이 확인하고 대표에게 보고한다.

| 확인 | 이유 |
|---|---|
| 사진 뷰어에 `신고`·`연결 끊기`가 있고 실제로 동작한다 | Apple 1.2, Play UGC 정책 |
| 첫 인증샷 전에 동의 시트("부적절한 사진 금지" 포함)가 뜬다 | Apple 1.2(약관 동의) |
| 계정 삭제 시 서버에서 actions·cheers·Storage가 정리되고, Apple 로그인 사용자는 토큰을 폐기한다 | Apple 5.1.1(v), Play 계정 삭제 정책 |
| 카메라·사진(인증샷·프로필 사진)·사진 추가(공유 카드 "이미지 저장") 권한 문구가 ko/en 현지화돼 있다. 기기에서 우리 탭 → 공유 카드 만들기 → 공유하기 → 이미지 저장을 눌러 추가 권한 창이 뜨고 앱이 꺼지지 않는지 본다 | Apple 5.1.1, 2.1 |
| 기기 라벨이 ko `둘운완`, en·기타 언어 `DuoDone`이다 | Apple 2.3.8 |
| Android 병합 매니페스트에 `AD_ID`, `CAMERA`, `READ_MEDIA_IMAGES`가 없다 | Play 광고 ID·사진 권한 신고 |
| 공유 카드와 iOS 스크린샷에 "Google Play" 글자가 없다(또는 대표가 위험을 수용) | Apple 2.3.10 |

## B. App Store Connect

### B1. 앱 정보
- [ ] **[사전]** 카테고리: 주 **건강 및 피트니스**, 보조 **라이프스타일**. 현재 이미 이렇게 설정돼 있으니 유지만 확인한다.
- [ ] **[제출]** 연령 등급 설문을 다시 답한다. 결과 등급은 기록해 둔다.
  - 기능 문항
    - 사용자 생성 콘텐츠: **예**
    - 메시지·채팅: **예**(짝꿍 1:1 한마디·똑똑)
    - 광고: 아니요
    - 무제한 웹 접근: 아니요
  - 콘텐츠 문항
    - 폭력·성적 콘텐츠: 모두 없음
    - 도박·모의 도박·콘테스트: **없음**(내기는 비금전 약속 문구)
    - 의료·건강/웰니스 주제 문항이 있으면: 건강·웰니스 주제 **예**, 의료 정보 **아니요**
- [ ] **[사전]** 개인정보처리방침 URL을 ko/en 모두 갱신한다.
- [ ] **[사전]** 콘텐츠 권한: 제3자 콘텐츠 "아니요"

### B2. 앱 개인정보 보호 (App Privacy)
저장하면 바로 라이브에 반영된다. 앱 공개 전에 과다 고지 방향으로 먼저 추가한다.

| 데이터 유형 | 용도 | 사용자와 연결 | 추적 | 상태 |
|---|---|---|---|---|
| **사진 또는 비디오** | 앱 기능 | 예 | 아니요 | [ ] 추가 |
| **피트니스**(운동 종류·완료 기록) | 앱 기능 | 예 | 아니요 | [ ] 추가 |
| **기타 사용자 콘텐츠**(애칭, 한마디, 내기 문구) | 앱 기능 | 예 | 아니요 | [ ] 추가 |
| 연락처 정보(이메일·이름) | 앱 기능 | 예 | 아니요 | [ ] 기존 유지 확인 |
| 식별자(사용자 ID) | 앱 기능, 분석 | 예 | 아니요 | [ ] 기존 유지 확인 |
| 사용 데이터(제품 상호작용) | 분석 | 예 | 아니요 | [ ] 기존 유지 확인 |
| 진단(충돌·성능) | 앱 기능 | **예** | 아니요 | [ ] **변경**(아니요 → 예) |
| **위치 > 대략적인 위치** | 분석 | 예 | 아니요 | [ ] 추가 |

- 진단은 사용자와 **연결됨**으로 고지한다. 로그인할 때마다 Crashlytics에 Firebase UID를 기록한다(`ErrorReporter.setUser` → `setUserIdentifier`). 지원에 필요하므로 UID 기록은 유지한다.
- **대략적인 위치**를 분석 용도로 고지한다. Google Analytics for Firebase가 IP 주소로 국가·지역을 추정하고, 개인정보처리방침 1절도 "IP 주소로 추정한 대략적인 국가·지역"을 수집 항목으로 적는다. Analytics에 UID를 설정하므로 연결은 예다.
- **정확한 위치**는 수집하지 않음으로 둔다. 업로드 전 EXIF를 지우고, 시간대는 위치 정보가 아니다.
- HealthKit을 쓰지 않으므로 "건강"은 선택하지 않는다.

### B3. 버전 1.1.0
- [ ] **[제출]** 이름, 부제, 키워드, 프로모션 텍스트, 설명이 ASO 문서 §1.1과 일치하는지 본다. 키워드 V2 테스트 문자열이 남아 있지 않은지도 확인한다.
  - 설명은 `ios/fastlane/metadata/ko/description.txt`(= Play `ko-KR/full_description.txt`)가 최종본이다. 2026-10-03에 키워드를 나열하던 3줄을 문장으로 고쳐서 ASO 문서 초안과 다르다. 목표 검색어는 문장 안에 한 번씩만 넣었다(Play 메타데이터 정책: 반복 키워드 금지).
- [ ] **[제출]** 스크린샷이 ko·en-US 모두 6.9" **새 6장만** 있는지 본다. **구 스크린샷(로그인 컷 포함)이 남아 있으면 삭제한다.** iOS fastlane 레인(`release`, `release_manual`, `upload_assets`, `metadata_only`)은 이제 `overwrite_screenshots: true`로 올리는 로케일의 스크린샷 세트를 통째로 교체한다. 그래도 업로드 뒤 콘솔에서 확인한다.
- [ ] **[제출]** "이 버전의 새로운 기능"은 수동 문안 `ios/fastlane/metadata/{ko,en-US}/release_notes.txt`로 넣는다. 자동 생성기는 쓰지 않는다.
  - Fastfile은 `GENERATE_RELEASE_NOTES=1`일 때만 생성기를 돌리고, metadata에 커밋 안 된 변경이 있으면 멈춘다. 그래도 **레인을 돌리기 전에 수동 문안을 커밋한다.**
  - 첫 문장 ko: `그래,해봐가 둘운완이 됐어요. 약속, 기록, 짝꿍 연결은 그대로예요.`
  - 첫 문장 en: `Nodtry is now DuoDone. Your promises, history, and partner connection stay the same.`
- [ ] **[제출]** 빌드 **81** 선택
- [ ] **[제출]** 이 버전 제출에 **앱 내 구입 항목이 첨부돼 있지 않은지** 확인한다. 이번 빌드는 팁 IAP UI가 숨겨져 있다(`settings_screen.dart`의 `_kShowCoffeeDonation = false`). §E 심사 메모도 "인앱 구매 없음"으로 적는다.
- [ ] **[제출]** 버전 출시: **"이 버전을 수동으로 출시"**. fastlane은 `release_manual` 레인(`automatic_release: false`)을 쓴다. `release` 레인은 승인 즉시 자동 출시한다.
- [ ] **[제출]** 앱 심사 정보
  - 로그인 필요 체크, 데모 계정 A(대표 직접 입력)
  - 메모: §E 붙여넣기. 계정 B는 메모 안의 지정 위치에 대표가 직접 입력한다.
  - 연락처: 대표
  - 첨부(권장): A와 B 연결 → 인증샷 → 인정 → 신고·연결 끊기 흐름을 담은 60초 이내 화면 녹화

### B4. In-App Events — 1.1.0 승인 후
- [ ] **[후]** 이벤트 ① `크리스마스까지 둘운완 30일`을 생성하고 심사에 제출한다(11/4 목표, 게시일 11/10).
- [ ] **[후]** 이벤트 ② `새해 둘운완 21일 챌린지`를 생성하고 심사에 제출한다(12/15 목표, 게시일 12/18).
- 입력값은 출시 계획 §4.1·§4.2에서 그대로 복사한다. 이벤트 카드 16:9와 상세 9:16 이미지는 디자인팀이 준비한다.
- **전제**: 앱 안에 이벤트 실체(배너, 기간 고정 템플릿, 카드 프레임)가 있어야 한다(출시 계획 §4.3).

### B5. 피처링 추천
- [ ] **[사전]** ① 앱 개편(10/13 목표)
- [ ] **[사전]** ② 크리스마스 이벤트(10/27 목표)
- [ ] **[사전]** ③ 새해 이벤트(10/27 목표)
- 문안은 출시 계획 §4.4에서 복사한다.

### B6. 선택
- [ ] **[후]** 제품 페이지 최적화(PPO) 실험(ASO V5)
- [ ] **[후]** 커스텀 제품 페이지(ASO V6)
- [ ] **[사전]** ASC 앱 분석 → 캠페인 링크의 provider token(pt) 확인. 광고 링크에 쓴다.
- [ ] **[사전]** Apple Search Ads Advanced 계정 생성, 결제 수단 등록(대표 직접), 국가 대한민국 확인

## C. Google Play Console

### C1. 앱 콘텐츠 (정책)
- [ ] **[사전]** 개인정보처리방침 URL 갱신
- [ ] **[사전]** 광고 포함: **아니요**
- [ ] **[사전]** 앱 액세스: "일부 기능 제한". 데모 계정 A·B와 §E의 짧은 안내를 넣는다. 자격 증명은 대표가 직접 입력한다.
- [ ] **[사전]** 콘텐츠 등급 설문을 다시 답한다.
  - 사용자 간 상호작용·콘텐츠(사진) 교환: **예**
  - 사용자 위치 공유: 아니요
  - 디지털 상품 구매: **아니요**. 이번 빌드는 팁 IAP UI가 숨겨져 있다(`_kShowCoffeeDonation = false`). 플래그를 켠 빌드를 낼 때 "예"로 다시 답한다.
  - 도박·모의 도박: 아니요
- [ ] **[사전]** 타겟층 및 콘텐츠: **만 18세 이상만**. "아동의 관심을 끌 수 있음"은 아니요로 둔다.
- [ ] **[사전]** 데이터 보안 갱신. 모두 전송 중 암호화 **예**, 삭제 요청 가능 **예**로 둔다.

| 데이터 | 수집 | 공유 | 목적 | 필수/선택 |
|---|---|---|---|---|
| 사진 및 동영상 > 사진 | 예 | **아니요**(사용자 주도 1:1 전송은 공유가 아님) | 앱 기능 | 선택(사진 없이 기록 가능) |
| 건강 및 피트니스 > 피트니스 정보 | 예 | 아니요 | 앱 기능 | 필수 |
| 메시지 > 기타 인앱 메시지(한마디·똑똑 답장) | 예 | 아니요 | 앱 기능 | 선택 |
| 앱 활동 > 기타 사용자 생성 콘텐츠(애칭·내기 문구) | 예 | 아니요 | 앱 기능 | 선택 |
| 개인 정보 > 이름·이메일·사용자 ID | 기존 유지 | 아니요 | 앱 기능·계정 관리 | 필수 |
| 앱 활동 > 앱 상호작용 / 앱 정보 및 성능 > 비정상 종료·진단 / 기기 또는 기타 ID | 기존 유지 | 아니요 | 분석 | 필수 |
| 위치 > 대략적인 위치 | 예 | 아니요 | 분석 | 필수(자동 수집) |
| 위치 > 정확한 위치 | **아니요** | | | |

- 대략적인 위치는 Google Analytics for Firebase가 IP 주소로 추정하는 국가·지역이다. App Store B2, 개인정보처리방침 1절과 같은 입장이다.
- [x] 지원 페이지에 앱 없이 계정 삭제를 요청하는 방법을 적었다(2026-10-03, `support/index.html`).
  - FAQ "계정을 삭제하고 싶어요"(`#delete-account`)와 영어판(`#delete-account-en`)에 다음을 적었다: 앱 경로, devhohouse@gmail.com 이메일 요청, 본인 확인, 30일 이내 삭제 항목(계정·약속·기록·인증샷·프로필·건강 관련 정보), 통계·오류 로그 최대 14개월 보관, 개인정보처리방침 7절 링크.
  - 개인정보처리방침 7절에도 앵커 `#delete-ko`·`#delete-en`이 있다. 두 페이지 모두 앵커로 들어오면 해당 언어 구역을 연다.
- [ ] **[사전]** Play Console에 **계정 삭제 웹 URL**을 등록한다: `<현재 등록된 지원 페이지 URL>#delete-account`. 등록한 정확한 URL을 여기에 적는다: `____`
  - 등록 전에 그 URL이 200으로 열리고, 삭제 FAQ가 화면에 보이는지 확인한다.
- [ ] **[사전]** **건강 앱 신고**: "활동 및 피트니스"와 **"영양·체중 관리"**를 둘 다 선택한다.
  - 영양·체중 관리: 운동 종류에 `식단·야식 참기` 습관 체크인이 있고, 스토어 등록정보가 다이어트(`다이어트 내기`, `커플 다이어트`, en 키워드 `diet`)를 내세운다. 신고는 등록정보와 맞아야 한다.
  - 설명란에는 이렇게 적는다: 식단·야식 참기 약속을 했는지 하루 한 번 체크인한다. 칼로리·영양소·체중을 기록하지 않는다. Health Connect에 접근하지 않는다.
  - Health Connect 권한: 없음
- [ ] **[사전]** 광고 ID 신고: 사용 안 함
- [ ] **[사전]** 사진·동영상 권한 신고: READ_MEDIA_* 권한이 없으면 해당 없음. 있으면 핵심 용도 신고가 필요하다.
- [ ] **[사전]** 정부 앱 아니요, 금융 기능 없음

### C2. 스토어 설정
- [ ] **[사전]** 앱 카테고리: 생산성 → **건강/운동**
- [ ] **[사전]** 태그: 운동·피트니스·습관 추적 계열에서 최대 5개
- [ ] **[사전]** 연락처 이메일: devhohouse@gmail.com

### C3. 기본 스토어 등록정보 (ko-KR, en-US)
- [ ] **[제출]** 제목, 짧은 설명, 자세한 설명(ASO §1.2·§1.4)
- [ ] **[제출]** 앱 아이콘 512×512(Heart-Check)
- [ ] **[제출]** **피처 그래픽 1024×500**(PNG/JPEG, 투명도 없음)
  - fastlane으로 올릴 때: `android/fastlane/metadata/android/{ko-KR,en-US}/images/featureGraphic.png`에 두면 production 레인이 업로드한다.
  - 콘솔에서 직접 올릴 때: 구 브랜드 그래픽을 교체한다.
- [ ] **[제출]** 휴대전화 스크린샷 6장. **구 4장(01_login 등)이 남아 있으면 삭제**
- [ ] **[후]** 선택: 스토어 등록정보 실험(ASO V7), 프로모션 콘텐츠(LiveOps, 자격 확인)

### C4. 게시
- [ ] **[사전] 관리형 게시 ON**(게시 개요 → 관리형 게시). 이게 꺼져 있으면 fastlane `production` 레인이 심사 통과 즉시 공개한다. 이름·아이콘·스토어 등록정보 변경도 함께 묶여 있다가 게시 버튼을 누를 때 공개된다.
- [ ] **[제출]** 프로덕션 출시 81 업로드를 확인한다(런북 6단계).
  - 출시 노트 `android/fastlane/metadata/android/{ko-KR,en-US}/changelogs/81.txt`는 iOS `release_notes.txt`(B3)와 같은 내용을 줄여 쓴다. 각 500자 이하여야 한다.
  - 2026-10-03 기준 두 파일 모두 작성돼 있다(ko 279자, en 443자).
- [ ] **[공개]** 게시 개요 → **변경사항 게시**(iOS 출시와 같은 시각)

## D. Firebase / Google Cloud 콘솔
- [ ] **[사전]** 요금제: Blaze 확인. GCP 예산 알림을 설정한다(예: 월 10만 원, 50%·90%·100%). Storage 읽기마다 Firestore get이 과금되고, 순위가 오르면 크론 비용이 선형으로 늘어난다.
- [ ] **[사전]** 마이그레이션 전 백업: Firestore 내보내기(런북 0단계) 또는 PITR 활성화(비용 발생, 대표 승인)
- [ ] **[사전]** Storage 규칙을 처음 배포할 때 나오는 "Firestore 교차 서비스 규칙용 IAM 역할 부여" 프롬프트를 승인한다(런북 1단계).
- [ ] **[사전]** Firestore에 `config/app` 문서를 생성한다: `minBuild: 0`, `latestBuild: 80`(숫자형). 규칙 배포 직후에 한다(런북 2단계).
- [ ] **[공개+1h]** `config/app.latestBuild` = **81**
- [ ] **[사전]** 권장: Analytics → BigQuery 연결(연결까지 걸린 시간 중앙값용)
- [ ] **[사전]** Crashlytics 급증 알림 ON
- [ ] **[다음 릴리스]** Kakao Developers 앱 등록(FeedTemplate 초대). 앱 키는 레포에 커밋하지 않는다.

## E. 심사 메모 (붙여넣기용, EN)

ASC "앱 심사 정보 > 메모"에 붙인다. Play "앱 액세스"에는 1~2번과 "REPORT / BLOCK" 단락만 붙인다. `[ ]` 안은 최종 빌드 화면을 보고 바꾼다.

메모에는 이번 빌드에서 실제로 참인 내용만 적는다(2026-10-03 기준).
- **초대 코드**: 서버는 1:1 제한을 강제하고, 연결될 때마다 두 사람의 코드를 새로 발급한다. 하지만 코드가 찍히지 않은 연결 요청은 아직 검사하지 않는다. 그래서 "single-use"는 쓰지 않는다. 서버가 "초대자의 현재 코드와 일치하는 코드"를 필수로 검사하도록 고쳐 배포한 뒤에만, 첫 항목 끝 문장을 `Our server requires the inviter's current code and enforces the 1:1 limit; codes rotate after each connection.`로 바꾼다.
- **연결 끊기**: 사진 접근은 서버 트리거가 `managerId`를 지운 뒤에 끝난다. 그래서 "immediately"가 아니라 "within seconds"로 쓰고, 사진과 앱 화면에 대해서만 말한다. plans/actions 읽기가 아직 로그인 사용자 전체에 열려 있어서 "약속 접근 차단"은 주장하지 않는다. 읽기를 참여자로 좁힌 뒤에만 `…can no longer open your proof photos or shared promises.`로 바꿀 수 있다.
- **인앱 구매**: 팁 IAP UI가 숨겨져 있으므로(`_kShowCoffeeDonation = false`) "인앱 구매 없음"으로 적는다. 플래그를 켜는 빌드에서는 이 문장을 다시 쓴다.

```
DuoDone (Korean name: 둘운완; formerly "Nodtry") helps couples keep each other accountable for workout promises. Two people connect one-to-one with an invite code, and each sees only the other's progress.

HOW TO REVIEW
Two demo accounts are already connected to each other. Account A is in the Sign-In Information field. Account B: [B email] / [B password].
1. Sign in as A (email login). The Now tab shows today's workout promise. Tap "📸 인증샷 찍기" (take a proof photo) or "사진 없이 했어" (done, no photo).
2. Sign in as B (another device, or sign out first). B sees A's proof photo and acknowledges it with a one-tap reaction (❤️🔥💪👏). We call this "인정" (acknowledge).

PRIVATE 1:1 SHARING, NOT A PUBLIC FEED
- In the app, two people connect only when the invitee enters the inviter's invite code or opens the inviter's invite link. Each person can be connected to only one partner at a time. Our server enforces this 1:1 limit and issues both people new invite codes after each connection.
- Proof photos are visible only to that one connected partner. There is no public feed, search, follower system, or messaging with strangers.
- Location metadata (EXIF/GPS) is removed on the device before upload.
- Before the first photo upload, users accept a one-time notice that inappropriate photos are not allowed.

REPORT / BLOCK
- Report: open the partner's proof photo → "신고" (Report). [Reports are sent to our team at devhohouse@gmail.com]; we review every report within 24 hours.
- Block: "연결 끊기" (Disconnect) in the same photo viewer [and in 우리 tab → …]. Disconnecting ends the connection: within seconds the former partner can no longer open your proof photos, and your promises no longer appear in their app.
- Account deletion: [설정 → 계정 삭제] deletes the account, photos, and records on our server.

BETS ARE NON-MONETARY
- "내기" (bet) is a short free-text promise between the two partners, for example "loser buys chicken" or "does the dishes for a week". The app never processes, holds, or transfers money and offers no prizes or payouts. If the text includes money terms, the app shows a notice that money bets are not supported.
- This version has no in-app purchases.

PERMISSIONS
- Camera: only to take a workout proof photo for the connected partner.
- Photos: to choose a workout proof photo or a profile photo from the album. If the user taps "Save Image" when sharing a streak card, iOS asks for add-only access to save it to Photos.
- Notifications: reminders before a promise deadline and partner reactions.

The app does not use HealthKit and makes no weight-loss or medical claims.
```

## F. 완료 서명

| 구역 | 완료일 | 확인자 | 대표 승인 |
|---|---|---|---|
| A 공통 | | | |
| B ASC | | | |
| C Play | | | |
| D Firebase/GCP | | | |
