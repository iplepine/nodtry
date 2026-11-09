# 개인정보처리방침 / Privacy Policy — 둘운완 (DuoDone)

> 이 파일은 게시용 [`privacy-policy/index.html`](privacy-policy/index.html)(= `hosting/public/privacy/index.html`, 두 파일은 같아야 한다)의 Markdown 사본이다. 내용이 다르면 HTML이 정본이며, 고칠 때는 세 파일을 함께 고친다.
> 게시 전 확인: 시행일(현재 2026-11-10)을 실제 게시일과 맞추고, 2절·3절·7절이 설명하는 동작(사진별 삭제, 연결 해제 시 접근 차단·캐시 삭제, 공유 카드 사진 동의 `users.allowPartnerPhotoInShareCard`, 초대 리마인더, 하루 알림 수 제한, 탈퇴 시 서버 정리, 신고)이 출시 빌드(1.2.0+)·서버에 배포됐는지 확인한다(`docs/operations/RELEASE_READINESS.md` 게이트 C).

---

## 한국어

**시행일: 2026년 11월 10일 · 둘운완 (DuoDone)**

| | |
|---|---|
| 앱 이름 | 둘운완 (DuoDone) — 이전 이름: 그래, 해봐 / Nodtry (Google Play 등록정보에는 "Nodtry: Accountability Partner"로 표시될 수 있어요) |
| 패키지 이름 | com.devho.nodtry.app (Google Play · App Store 동일 앱) |
| 개발자(개인정보처리자) | devho house (Google Play 개발자 계정명 "devho house") |
| 문의 | devhohouse@gmail.com |

둘운완(이하 "앱")은 연인·부부가 서로의 운동 약속을 봐주는 1:1 앱이에요. 이 방침은 앱이 어떤 정보를 왜 수집하고, 누구와 공유하며, 언제 어떻게 지우는지 안내해요.

앱 이름이 그래, 해봐에서 둘운완으로 바뀌었어요. 운영자, 계정, 기존 약속과 기록, 짝꿍 연결은 그대로예요.

### 1. 수집하는 개인정보 항목
| 항목 | 수집 목적 | 수집 방법 |
|---|---|---|
| 이메일 주소, 로그인 ID(Firebase Auth UID), 소셜 로그인 시 제공되는 이름 | 회원 식별 및 계정 관리 | 회원가입·로그인 시 |
| 닉네임, 프로필 이미지, 짝꿍 애칭(내가 짝꿍을 부르는 호칭) | 앱 안에서 프로필·호칭 표시 | 사용자 직접 입력 |
| 운동 약속 데이터(운동 종류, 요일, 마감 시각, 목표(D-day) 이름·날짜, 완료·휴식 기록, 소감) | 핵심 기능 제공(약속 관리, 짝꿍 확인) | 서비스 이용 중 생성 |
| **인증샷**(운동 사진), 촬영 방식(카메라/앨범), 촬영 시각 | 운동 약속 인증을 연결된 짝꿍에게 보여주기, 내가 허용하면 짝꿍이 만드는 공유 카드에 넣기(아래 2절) | 사용자가 직접 촬영·선택(선택 사항) |
| 짝꿍과 주고받은 인정 리액션, 응원·똑똑 메시지, 내기(보상·벌칙) 내용 | 짝꿍 간 소통 기능 제공 | 서비스 이용 중 생성 |
| 공유 카드 사진 허용 여부(켬/끔, 기본 끔) | 짝꿍이 만드는 공유 카드에 내 인증샷을 넣어도 되는지 확인(아래 2절) | 설정에서 사용자가 직접 선택 |
| 초대 기록(초대한 사람의 로그인 ID, 초대 코드, 처음·마지막 공유 시각, 공유 횟수, 초대 리마인더 발송 횟수·시각, 연결된 시각) | 초대 링크·코드로 짝꿍 연결, 짝꿍이 아직 들어오지 않았을 때 초대 리마인더 알림 보내기(아래 3절) | 초대 메시지를 공유하거나 코드를 복사할 때 생성 |
| 건강 관련 정보(운동·식단 등 약속에 포함된 경우) | 약속 관리 및 짝꿍 확인 | 사용자 자발적 입력 |
| 기기 정보(기기 모델, OS 버전), 앱 빌드 번호, 시간대, 언어 설정, 푸시 토큰 | 알림 발송, 마감 시각 계산, 버전 호환 안내 | 자동 수집 |
| 알림 발송 횟수(받는 사람별 하루 집계) | 하루에 알림이 너무 많이 가지 않도록 발송 수 제한 | 알림을 보낼 때 서버에서 자동 생성 |
| 오류 로그(앱 충돌 정보, 로그인 ID와 함께 기록) | 오류 분석 및 해결 | 자동 수집(Firebase Crashlytics) |
| 앱 이용 기록(화면·기능 사용 이벤트, IP 주소로 추정한 대략적인 국가·지역) | 서비스 품질 개선 및 통계 | 자동 수집(Google Analytics for Firebase) |

앱은 광고 ID를 수집하지 않고, 정확한 위치 정보(GPS)도 수집하지 않아요. 대략적인 국가·지역은 이용 통계에만 써요.

**내 기기에만 저장되는 정보:**
- **홈 화면·잠금 화면 위젯:** 위젯에 보여줄 나와 짝꿍의 호칭(애칭 → 짝꿍 이름 → 짝꿍), 오늘 운동 상태, 함께한 날 수를 내 기기의 위젯 저장 공간에 저장해요. 서버로 보내지 않고, 사진·소감·메시지·약속 내용은 넣지 않아요. 잠금 화면 위젯은 기기가 잠겨 있어도 보이니, 원하지 않으면 위젯을 빼 주세요. 로그아웃하거나 연결을 끊으면 지워져요.
- **초대 링크:** 초대 링크(nod-try.web.app/i/…)로 앱을 열면 링크 속 초대 코드를 연결 단계에서 쓸 때까지 내 기기에 잠시 저장해요.

### 2. 인증샷
- **수집 항목**: 사진 이미지, 촬영 방식(카메라/앨범), 촬영 시각(카메라는 찍은 시각, 앨범은 사진에 기록된 원본 촬영일이 있으면 그 날짜).
- **이용 목적**: 내가 한 운동을 연결된 짝꿍에게 보여주고, 짝꿍이 인정(리액션)할 수 있게 하기 위해서예요. 얼굴 인식 등 다른 분석이나 광고에 쓰지 않아요.
- **공개 범위**: 기본적으로 나와 **연결된 짝꿍 1명만** 볼 수 있어요. 공개 피드나 다른 사용자에게 보여주는 기능은 없어요. 다만 아래 '공유 카드'를 내가 켜면, 짝꿍이 내 인증샷이 들어간 카드를 앱 밖으로 공유할 수 있어요.
- **위치 정보 제거**: 사진은 올리기 전에 내 기기에서 크기를 줄이고 다시 저장해요. 이 과정에서 사진에 들어 있던 위치(GPS)·기기 정보 등 메타데이터(EXIF)를 모두 지우고, 원본 사진은 서버로 보내지 않아요.
- **저장 위치**: Cloud Storage for Firebase(Google LLC)에 저장해요. 짝꿍의 앱은 사진을 빠르게 보여주기 위해 기기에 임시로 저장(캐시)할 수 있어요.
- **삭제**:
  - 내 인증샷을 삭제하면 서버에서 바로 지워져요.
  - 짝꿍 연결을 끊으면 상대방은 앱에서 내 인증샷을 더 이상 볼 수 없어요. 상대방 앱에 남은 임시 저장본도 지우도록 되어 있지만, 상대방이 이미 캡처하거나 저장한 화면은 회수할 수 없어요.
  - 회원 탈퇴 시 내 인증샷은 모두 삭제돼요.
- **공유 카드(선택, 기본 꺼짐)**: 설정의 **'짝꿍이 만드는 공유 카드에 내 인증샷 넣기 허용'**을 켜면, 짝꿍이 자기 기기에서 만드는 공유 카드 이미지에 내 인증샷(카드 날짜의 사진, 없으면 가장 최근 사진)을 같이 넣을 수 있어요.
  - 카드는 짝꿍의 기기 안에서 만들어져요. 카드를 만들려고 사진을 서버에 새로 올리거나 카드 이미지를 둘운완 서버에 저장하지 않아요. 카드 이미지는 공유를 위해 짝꿍 기기의 임시 폴더에 잠시 저장돼요.
  - 짝꿍은 카드를 인스타그램·카카오톡 등 앱 밖으로 공유할 수 있어요. 공유는 짝꿍이 직접 하는 일이고, 한번 공유된 카드는 둘운완이 회수하거나 지울 수 없어요. 공유된 곳에서는 그 서비스의 정책이 적용돼요.
  - 설정에서 언제든 끌 수 있어요. 끄면 그다음에 만드는 카드부터 내 인증샷이 빠지고, 이미 만들었거나 공유한 카드는 바뀌지 않아요.
  - 꺼져 있어도 짝꿍은 자기 인증샷만 넣은 카드를 만들 수 있어요. 카드에는 둘의 오늘 운동 기록(운동 종류, 했는지·쉬었는지)과 함께한 날 수, 짝꿍이 나를 부르는 애칭(없으면 '짝꿍')이 들어가고, 내 실명이나 이메일은 들어가지 않아요.
- **주의**: 인증샷에는 얼굴이나 몸이 나올 수 있어요. 보여주고 싶은 사진만 올려 주세요. 다른 사람이 나온 사진이나 부적절한 사진은 올리지 말아 주세요. 사진 보기 화면에서 신고하거나 연결을 끊을 수 있어요.

### 3. 개인정보 이용 목적
- 운동 약속 만들기, 인증, 짝꿍 연결·인정·응원 등 핵심 기능 제공
- 마감 리마인더와 짝꿍 소식 알림 발송
- 초대 리마인더: 초대를 공유했는데 짝꿍이 아직 연결하지 않았으면, 마지막 공유 후 약 24시간·72시간에 최대 2번, 내 시간대 기준 오전 10시~오후 9시 사이에만 알려 드려요. 연결되거나 탈퇴하면 보내지 않아요.
- 하루 알림 수 제한: 받는 사람마다 하루에 받은 알림 수를 세어, 꼭 필요한 알림이 아니면 하루 상한을 넘었을 때 보내지 않아요.
- 회원 식별 및 계정 관리
- 오류 해결, 서비스 품질 개선 및 신규 기능 개발

개인정보를 **판매하거나 광고 목적으로 제3자에게 제공하지 않아요.** 건강 관련 정보와 인증샷은 마케팅이나 광고에 절대 쓰지 않아요.

### 4. 처리 위탁
앱 운영을 위해 아래 업무를 Google LLC에 맡기고 있어요. 각 서비스는 Google의 개인정보처리방침(policies.google.com/privacy)에 따라 데이터를 처리해요.

| 수탁자 | 서비스 | 위탁 업무 |
|---|---|---|
| Google LLC | Firebase Authentication | 로그인·회원 인증 |
| | Cloud Firestore | 계정·약속·기록 데이터 저장 |
| | Cloud Storage for Firebase | 인증샷·프로필 이미지 저장 |
| | Cloud Functions for Firebase | 알림 발송(초대 리마인더·하루 알림 수 제한 포함), 연결·탈퇴 시 데이터 정리 등 서버 처리 |
| | Firebase Cloud Messaging | 푸시 알림 전송 |
| | Firebase Crashlytics | 앱 오류(충돌) 로그 수집·분석 |
| | Google Analytics for Firebase | 앱 이용 통계 분석(광고 ID 미사용) |
| | Firebase Hosting | 초대 링크·안내 웹페이지 제공 |

Apple 또는 Google 계정으로 로그인하면 해당 회사에서 이메일 등 로그인에 필요한 정보만 받아요.

### 5. 개인정보의 국외 이전
위 위탁 업무를 위해 개인정보가 아래와 같이 국외로 이전돼요.

| 항목 | 내용 |
|---|---|
| 이전받는 자 | Google LLC (1600 Amphitheatre Parkway, Mountain View, CA 94043, USA), 연락처: Google 개인정보 문의 |
| 이전되는 국가 | 미국 등 Google LLC가 데이터센터를 운영하는 국가 |
| 이전 항목 | 1절의 수집 항목(인증샷 포함) |
| 이전 일시 및 방법 | 앱을 이용할 때 수시로, 암호화된 네트워크(HTTPS/TLS)를 통해 전송 |
| 이용 목적 | 4절의 위탁 업무 수행 |
| 보유·이용 기간 | 회원 탈퇴 또는 위탁 계약 종료 시까지(6절의 보관 기간을 따름) |
| 거부 방법 및 결과 | 국외 이전을 원하지 않으면 회원 탈퇴로 거부할 수 있어요. 다만 국외 이전은 서비스 제공에 꼭 필요해서, 거부하면 앱을 이용할 수 없어요. |

### 6. 개인정보 보관 기간
| 데이터 유형 | 보관 기간 |
|---|---|
| 계정 정보(이메일, 닉네임, 프로필, 짝꿍 애칭) | 회원 탈퇴 시까지 |
| 운동 약속·기록·리액션·응원 데이터 | 회원 탈퇴 시까지 |
| 인증샷 | 사용자가 삭제하거나 회원 탈퇴할 때까지 |
| 건강 관련 정보 | 회원 탈퇴 시까지 |
| 공유 카드 사진 허용 여부, 초대 기록 | 회원 탈퇴 시까지(초대 리마인더는 연결되면 더 보내지 않아요) |
| 알림 발송 횟수 | 집계한 날로부터 약 3일 뒤 자동 삭제 |
| 위젯 정보, 기기에 저장한 초대 코드 | 내 기기에만 저장. 위젯 정보는 로그아웃·연결 해제 시, 초대 코드는 연결 단계에서 쓰면 지워지고, 앱을 지우면 모두 지워져요 |
| 기기 정보, 오류 로그, 이용 통계 | 수집일로부터 최대 14개월 |

보관 기간이 지나거나 처리 목적을 달성하면 해당 개인정보를 지체 없이 파기해요.

### 7. 개인정보 삭제 방법
- **앱에서 삭제**: 설정 > 계정 관리 > 회원 탈퇴에서 계정과 모든 데이터(인증샷 포함)를 삭제할 수 있어요. 인증샷은 사진별로 따로 삭제할 수도 있어요.
- **이메일 요청(앱 없이도 가능)**: devhohouse@gmail.com으로 삭제를 요청할 수 있어요. 앱을 이미 지웠어도 요청할 수 있어요.

삭제 요청 처리 절차:
1. 요청을 받으면 본인 여부를 확인해요.
2. 계정 정보, 약속·기록, 인증샷, 프로필, 건강 관련 정보 등 모든 개인정보를 **30일 이내**에 완전히 파기해요. 단, 6절의 기기 정보·오류 로그·이용 통계는 수집일로부터 최대 14개월 보관한 뒤 자동으로 삭제돼요.
3. 전자 파일은 복구할 수 없는 기술적 방법으로 영구 삭제해요.

### 8. 이용자의 권리
- 개인정보 열람 요청
- 설정 > 프로필 수정을 통한 개인정보 수정
- 언제든지 계정 및 모든 관련 데이터 삭제 요청
- 개인정보 수집·이용 동의 철회

### 9. 데이터 보안
데이터는 암호화된 통신(HTTPS/TLS)으로 전송하고 Google Firebase의 보안 클라우드 인프라에 저장해요. 인증샷은 서버 규칙으로 본인과 연결된 짝꿍만 읽을 수 있도록 제한해요. 공유 카드는 짝꿍 기기에서 만들어지고, 내가 허용한 경우에만 내 인증샷이 들어가요(2절).

### 10. 아동 개인정보 보호
앱은 만 14세 미만 아동을 대상으로 하지 않으며, 만 14세 미만 아동의 개인정보를 고의로 수집하지 않아요.

### 11. 개인정보처리방침 변경
이 방침은 바뀔 수 있으며, 변경 사항은 시행일과 함께 이 페이지에 게시해요.
- 2026년 11월 10일: 공유 카드에 내 인증샷 넣기(선택, 기본 꺼짐) 안내, 홈·잠금 화면 위젯, 초대 링크·초대 리마인더, 하루 알림 수 제한, 운동 목표(D-day) 항목 추가, 처리 위탁에 Firebase Hosting 추가
- 2026년 10월 2일: 앱 이름 변경(그래, 해봐 → 둘운완), 인증샷 항목 추가, 처리 위탁(Cloud Storage·Cloud Functions·Crashlytics·Analytics)과 국외 이전 안내 추가
- 2026년 3월 24일: 최초 시행

### 12. 문의
개인정보처리방침에 대한 문의는 아래로 연락해 주세요.
- 개인정보 보호책임자: 박정호
- 이메일: devhohouse@gmail.com

---

## English

**Effective Date: November 10, 2026 · DuoDone (둘운완)**

| | |
|---|---|
| App name | DuoDone (둘운완) — formerly Nodtry / 그래, 해봐 (the Google Play listing may still show "Nodtry: Accountability Partner") |
| Package name | com.devho.nodtry.app (the same app on Google Play and the App Store) |
| Developer (data controller) | devho house (Google Play developer account name "devho house") |
| Contact | devhohouse@gmail.com |

DuoDone ("we", "our", or "the App") is a 1:1 app where couples keep an eye on each other's workout promises. This Privacy Policy explains what we collect and why, who we share it with, and when and how it is deleted.

The App has been renamed from Nodtry (그래, 해봐) to DuoDone (둘운완). The operator, your account, existing promises and history, and your partner connection stay the same.

### 1. Information We Collect
| Data | Purpose | Method |
|---|---|---|
| Email address, login ID (Firebase Auth UID), name provided by social sign-in | Account identification and management | At sign-up / sign-in |
| Nickname, profile image, partner nickname (what you call your partner) | In-app profile and name display | User input |
| Workout promise data (workout type, days, deadline, goal (D-day) name and date, done/rest records, notes) | Core features (promise tracking, partner check-ins) | Generated during use |
| **Proof photos** (workout photos), capture source (camera/album), capture time | Showing your workout to your connected partner; if you allow it, including it in share cards your partner makes (Section 2) | Taken or selected by you (optional) |
| Reactions, cheers and knock messages exchanged with your partner, bet (reward/penalty) details | Partner communication features | Generated during use |
| Share-card photo setting (on/off, off by default) | Whether your partner may put your proof photo on the share cards they make (Section 2) | Chosen by you in Settings |
| Invite records (inviter's login ID, invite code, first and last share time, share count, number and time of invite reminders sent, time of connection) | Connecting through an invite link or code; sending invite reminders while your partner hasn't joined yet (Section 3) | Created when you share your invite or copy your code |
| Health-related data (exercise, diet, etc. if included in promises) | Promise management and partner check-ins | Voluntary user input |
| Device information (model, OS version), app build number, time zone, language setting, push token | Notifications, deadline calculation, version compatibility notices | Automatic |
| Notification counts (per recipient, per day) | Limiting how many notifications are sent per day | Created by the server when a notification is sent |
| Crash logs (recorded with your login ID) | Troubleshooting | Automatic (Firebase Crashlytics) |
| App usage events (screens and features used, approximate country/region estimated from IP address) | Service improvement and statistics | Automatic (Google Analytics for Firebase) |

The App does not collect the advertising ID or precise (GPS) location. Approximate country/region is used only for usage statistics.

**Stored only on your device:**
- **Home-screen and lock-screen widgets:** the names shown (you, and your partner's nickname, display name or "your partner"), today's workout status and your streak are saved in your device's widget storage. They are not sent to our servers, and no photos, notes, messages or promise text are included. Lock-screen widgets are visible while your device is locked, so remove the widget if you prefer. The data is cleared when you sign out or disconnect.
- **Invite links:** when you open the App from an invite link (nod-try.web.app/i/…), the invite code in it is kept on your device until it is used to connect.

### 2. Proof Photos
- **What**: the photo, how it was captured (camera/album), and when (camera: the time you took it; album: the original capture date recorded in the photo, if any).
- **Why**: to show the workout you did to your connected partner so they can acknowledge it with a reaction. We do not use photos for facial recognition, other analysis, or advertising.
- **Who can see it**: by default, only you and **your one connected partner**. There is no public feed and no sharing with other users. If you turn on the share-card setting below, your partner may share a card containing your proof photo outside the App.
- **Location removed**: before upload, the App resizes and re-encodes the photo on your device, which removes all metadata (EXIF) such as GPS location and device details. The original photo is never sent to our servers.
- **Where it is stored**: Cloud Storage for Firebase (Google LLC). Your partner's app may keep a temporary on-device copy (cache) to display it quickly.
- **Deletion**:
  - When you delete a proof photo, it is removed from our servers right away.
  - When you disconnect from your partner, they can no longer see your photos in the App. Their app is designed to clear its temporary copy, but screenshots or saves they already made cannot be recalled.
  - When you delete your account, all of your proof photos are deleted.
- **Share cards (optional, off by default)**: if you turn on **"Let my partner put my proof photo on their share cards"** in Settings, your partner can include your proof photo (the photo from the card's day, or else your most recent one) in a share-card image they create on their own device.
  - The card is created on your partner's device. No photo is uploaded to our servers to make it, and the card image is not stored on DuoDone servers. The card image is briefly saved in a temporary folder on your partner's device so it can be shared.
  - Your partner may share the card outside the App, for example on Instagram or KakaoTalk. Sharing is your partner's own action; once a card has been shared, DuoDone cannot recall or delete it, and the policies of the service it was shared to apply.
  - You can turn the setting off at any time. Cards made after that will not include your photo; cards already made or shared are not affected.
  - Even with the setting off, your partner can make a card with only their own photo. Cards show both of your workouts for the day (workout type, done or rested), your streak and the nickname your partner uses for you (or "Your partner"), never your real name or email.
- **Please note**: proof photos may show your face or body, so only upload photos you are comfortable sharing. Do not upload photos of other people or inappropriate content. You can report a photo or disconnect from the photo viewer.

### 3. How We Use Your Information
- Provide core features (workout promises, proof, partner connection, reactions, cheers)
- Send deadline reminders and partner notifications
- Invite reminders: if you shared an invite and your partner hasn't connected yet, we remind you up to 2 times, about 24 and 72 hours after your last share, only between 10:00 and 21:00 in your time zone. They stop once you connect or delete your account.
- Daily notification limit: we count the notifications each person receives per day and, except for essential ones, stop sending once the daily limit is reached.
- Identify members and manage accounts
- Fix errors, improve service quality, and develop new features

We do **not** sell your personal data or share it with third parties for advertising. Health-related data and proof photos are never used for marketing or advertising.

### 4. Service Providers (Processors)
We entrust the following tasks to Google LLC. Each service processes data under Google's Privacy Policy (policies.google.com/privacy).

| Processor | Service | Task |
|---|---|---|
| Google LLC | Firebase Authentication | Sign-in and authentication |
| | Cloud Firestore | Account, promise and history data storage |
| | Cloud Storage for Firebase | Proof photo and profile image storage |
| | Cloud Functions for Firebase | Server processing such as notifications (including invite reminders and the daily notification limit) and clean-up on disconnect or account deletion |
| | Firebase Cloud Messaging | Push notification delivery |
| | Firebase Crashlytics | Crash log collection and analysis |
| | Google Analytics for Firebase | App usage statistics (no advertising ID) |
| | Firebase Hosting | Invite links and informational web pages |

If you sign in with Apple or Google, we receive only the information needed to sign you in, such as your email address.

### 5. International Data Transfer
To perform the tasks above, personal data is transferred outside Korea as follows.

| Item | Details |
|---|---|
| Recipient | Google LLC (1600 Amphitheatre Parkway, Mountain View, CA 94043, USA), contact: Google privacy inquiries |
| Country | United States and other countries where Google LLC operates data centers |
| Data transferred | The items in Section 1 (including proof photos) |
| When and how | Whenever you use the App, over encrypted connections (HTTPS/TLS) |
| Purpose | The processing tasks in Section 4 |
| Retention | Until account deletion or the end of the processing agreement (see Section 6) |
| How to refuse | You can refuse the transfer by deleting your account. Because the transfer is necessary to provide the service, the App cannot be used without it. |

### 6. Data Retention Period
| Data Type | Retention Period |
|---|---|
| Account information (email, nickname, profile, partner nickname) | Until account deletion |
| Workout promises, history, reactions and cheers | Until account deletion |
| Proof photos | Until you delete them or delete your account |
| Health-related data | Until account deletion |
| Share-card photo setting, invite records | Until account deletion (invite reminders stop once you connect) |
| Notification counts | Deleted automatically about 3 days after the day counted |
| Widget data, invite code saved on your device | On your device only. Widget data is cleared on sign-out or disconnect, the invite code once it is used to connect, and both when you uninstall the App |
| Device information, crash logs and usage statistics | Up to 14 months from collection |

Data is destroyed without delay once the retention period expires or the purpose of processing is fulfilled.

### 7. How to Delete Your Data
- **In the App**: go to Settings > Account > Delete Account to delete your account and all data, including proof photos. You can also delete individual proof photos.
- **By email (no app needed)**: send a deletion request to devhohouse@gmail.com. You can do this even if you have already uninstalled the App.

Deletion process:
1. We verify your identity when we receive the request.
2. All personal data, including account data, promises and history, proof photos, profile information and health-related data, is permanently destroyed within **30 days**. Device information, crash logs and usage statistics (Section 6) are kept for up to 14 months from collection and then deleted automatically.
3. Electronic files are permanently deleted using methods that prevent recovery.

### 8. Your Rights
- Request access to your personal information
- Edit your profile through Settings > Edit Profile
- Delete your account and all associated data at any time
- Withdraw consent to data collection and use

### 9. Data Security
Data is transmitted over encrypted connections (HTTPS/TLS) and stored on Google Firebase's secure cloud infrastructure. Server rules restrict proof photos so that only you and your connected partner can read them. Share cards are created on your partner's device and include your proof photo only if you allowed it (Section 2).

### 10. Children's Privacy
The App is not intended for children under 14. We do not knowingly collect personal information from children under 14.

### 11. Changes to This Policy
We may update this Privacy Policy. Changes will be posted on this page with the effective date.
- November 10, 2026: Added share cards with your proof photo (optional, off by default), home-screen and lock-screen widgets, invite links and invite reminders, the daily notification limit, and workout goals (D-day); added Firebase Hosting as a processor
- October 2, 2026: App renamed (Nodtry → DuoDone); proof photos added; processors (Cloud Storage, Cloud Functions, Crashlytics, Analytics) and international transfer disclosed
- March 24, 2026: First version

### 12. Contact Us
- Privacy Officer: Jungho Park
- Email: devhohouse@gmail.com
