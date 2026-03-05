# 프로젝트 진행 상황

## 현재 상태
- 전체 진행률: 87% (PLAN 15단계 중 13단계 완료)
- 현재 작업 중: 출시 전 최종 점검 → 출시 준비 (단계 14~15)
- 마지막 업데이트: 2026-03-05

## 완료된 단계

### 1. 핵심 기능 개발 (100%)
- 인증: 이메일 가입/로그인/OTP 인증/프로필 설정
- 홈: 내 지자체 피드 + 전국 HOT (태그 필터)
- 게시물: CRUD + 이미지 업로드 + 좋아요/북마크 + 조회수
- 댓글: CRUD + 대댓글 + 신고
- 탐색: 검색 + 지자체별 피드
- 프로필: 내 글/댓글/북마크
- 설정: 계정삭제, 로그아웃, 법적 고지, 차단 목록
- 신고/차단 (차단 유저 피드 필터링)

### 2. QA (100%)
- 22건 발견 → Critical 2 + High 6 + Medium/Low 모두 수정 완료
- 프로필 미완성 유저 라우팅, 조회수 중복 방지, 좋아요/북마크 더블탭 방지
- 이미지 업로드 실패 시 cleanup, force unwrap 제거

### 3. DB 최적화 (100%)
- RLS 최적화 (blocks 서브쿼리 제거)
- RPC 전환: toggle_like, toggle_bookmark, get_post_detail (3→1 round-trip)
- pg_cron: HOT 스코어 갱신(10분), 미인증 계정 정리(매일)
- comment_count 트리거, fcm_token 컬럼 추가

### 4. Firebase/FCM (100%)
- Firebase 프로젝트 생성 (gongter-app)
- Android google-services.json + iOS GoogleService-Info.plist 설정
- NotificationService 구현 (토큰 저장, 권한 요청)
- Xcode 프로젝트에 plist 참조 추가
- 시뮬레이터에서 초기화 정상 확인

### 5. Android 릴리즈 서명 (100%)
- gongter-release.jks 키스토어 생성
- key.properties + build.gradle.kts signingConfigs 설정

### 6. GitHub Pages (100%)
- 개인정보처리방침: https://gitnomaddi-creator.github.io/gongter/privacy.html
- 이용약관: https://gitnomaddi-creator.github.io/gongter/terms.html

### 7. 시드 콘텐츠 (100%)
- 시드 유저 20명 (seed01~20@gongter.app)
- 게시글 200개 (20개 지자체 × 10개)
- 댓글 24개 (인기글 기반)
- confession 태그 DB CHECK 추가

### 8. 관리자 기능 (100%)
- master@gongter.app → role=admin
- 관리자: 모든 지자체에 글 작성 가능 (RLS 수정)
- 설정 > 관리자 섹션 > 지자체 변경 UI + change_municipality RPC

### 9. 닉네임 보안 (100%)
- banned_words 테이블 (관리자/운영자 관련 금칙어)
- 닉네임 UNIQUE 제약조건
- 회원가입/프로필설정 시 validateNickname() 검증

### 10. PRD v1.1 갭 분석 + 구현 계획 수립 (100%)
- PRD 대비 전체 코드 검증 완료 (28개 소스 파일 리뷰)
- 10개 갭 항목 식별 (docs/PLAN.md에 12단계 구현 계획 수립)
- 주요 갭: 댓글 soft delete, 양방향 차단 RLS, 금칙어 필터링, 재직증명서 인증

### 11. PLAN 단계 1: 닉네임 검증 버그 수정 (100%)
- `profile_setup_screen.dart`: 닉네임 정규식 검증 추가 (`^[가-힣a-zA-Z0-9]+$`)
- `profile_screen.dart`: 닉네임 변경 다이얼로그 전면 개선
  - StatefulBuilder로 에러 메시지 인라인 표시
  - 3단계 검증: 2자 미만 → 정규식 → 금칙어/중복(`validateNickname`)
- `flutter analyze` 통과 확인

### 12. PLAN 단계 2: 댓글 soft delete (100%)
- Supabase `soft_delete_comment` RPC 생성 (대댓글 있으면 soft delete, 없으면 물리 삭제)
- `supabase_service.dart`의 `deleteComment()` → RPC 호출로 변경
- `post_detail_screen.dart` is_deleted 처리 기존 구현 확인 (변경 불필요)

### 13. PLAN 단계 3: 양방향 차단 RLS (100%)
- `posts_select` RLS에 양방향 차단 필터 추가 (내가 차단한 + 나를 차단한 사용자 글 제외)
- `comments_select` RLS에 동일 필터 추가
- `idx_blocks_blocked` 인덱스 이미 존재 확인 (추가 불필요)
- 클라이언트 `_blockedUserIds` 필터링 유지 (이중 안전장치)

### 14. PLAN 단계 4: 금칙어 필터링 (100%)
- `supabase_service.dart`에 `validateContent()` 메서드 추가 (전 카테고리 검사)
- `post_write_screen.dart` `_submit()`에 제목+내용 금칙어 검증 추가 (이미지 업로드 전)
- `post_edit_screen.dart` `_submit()`에 제목+내용 금칙어 검증 추가
- `post_detail_screen.dart` `_submitComment()`에 댓글 금칙어 검증 추가
- `banned_words` 테이블에 91개 단어 등록 (abuse 38 + obscene 10 + spam 11 + privacy 13 + other 19)
- "보지" 금칙어 삭제: 부분 일치 방식에서 "보지 않다" 등 일상 표현 오탐 → 제거 결정
- 10개 테스트 케이스 전체 통과 확인

### 15. PLAN 단계 5: 닉네임 중복 허용 + 계정 삭제 익명화 개선 (100%)
- `validateNickname()`에서 중복 체크 로직 제거 (금칙어만 유지, PRD 3.7 준수)
- `_getAnonLabel()`에서 `authorId == null`일 때 "탈퇴한 사용자" 표시 (기존 "익명0" 버그 수정)
- Supabase `profiles_nickname_unique` UNIQUE 제약조건 제거
- `flutter analyze` 통과 확인

### 16. PLAN 단계 6: 댓글 수정 기능 (100%)
- `supabase_service.dart`에 `updateComment()` 메서드 추가
- `post_detail_screen.dart`에 내 댓글 "수정" 버튼 + 수정 다이얼로그 추가
- 수정 시 금칙어 검증 적용 (`validateContent()` 재사용)
- `isEdited == true`인 댓글에 "수정됨" 라벨 표시
- DB: `comments_update` RLS + `tr_comments_updated` 트리거 이미 존재 (변경 불필요)
- `flutter analyze` 통과 확인

### 17. PLAN 단계 7: 온보딩 화면 (100%)
- `lib/screens/onboarding/onboarding_screen.dart` 신규 생성 (3페이지 PageView)
  - 페이지 1: 앱 소개 ("38만 지방공무원의 익명 마당")
  - 페이지 2: 핵심 기능 안내 (피드, 검색, 익명)
  - 페이지 3: 공무원법 주의사항 + "시작하기" 버튼
- `lib/main.dart`에 SharedPreferences로 `onboardingComplete` 전역 변수 로드
- `lib/router.dart`에 `/onboarding` 라우트 + redirect 온보딩 체크 추가
- "건너뛰기" 버튼 + 페이지 인디케이터(애니메이션 dot) 포함
- `flutter analyze` 통과 확인

### 18. PLAN 단계 8: 이메일 도메인 검증 강화 (100%)
- `lib/utils/email_validator.dart` 신규 생성 — korea.kr만 허용 (공직자 통합메일 단일 도메인)
- `signup_screen.dart` 88~91행: 느슨한 `.kr` 검증 → `EmailValidator.isAllowedDomain()` 교체
- 회원가입 Step 1: 허용 도메인 안내 박스 추가 ("사용 가능: korea.kr")
- 회원가입 Step 2: 소속 지자체 변경 불가 경고 문구 추가
- onnara.go.kr 제거: MX 레코드 없음 확인 → 메일 수신 불가 (온메일 = korea.kr 도메인 사용)
- `flutter analyze` 통과 확인

### 19. PLAN 단계 9: 소속 변경 문의 버튼 (100%)
- `settings_screen.dart` "계정" 섹션에 "소속 변경 문의" ListTile 추가 (로그아웃 위)
- `_showTransferInquiry()` 다이얼로그: 연 1회 무조건 처리, 초과 시 재직증명서 요청 안내
- mailto 템플릿: 제목 `[공터] 소속 변경 문의` + 본문(현재 소속/변경 소속/사유/가입 이메일)
- `flutter analyze` 통과 확인

### 20. PLAN 단계 10: 이미지 용량 제한 (100%)
- `post_write_screen.dart`의 `_pickImage()`에 파일 크기 검증 추가
- `picker.pickImage()` 리사이즈 후 `file.length()`로 크기 확인
- `AppConstants.maxImageSizeMb` (5MB) 초과 시 SnackBar 안내 + 첨부 차단
- `flutter analyze` + `flutter build ios` 통과 확인

### 21. PLAN 단계 11: 알림 기능 완전 구현 (100%)
- **Phase 1: 대댓글 알림 트리거**
  - `notify_on_comment()` 트리거 수정: 대댓글 시 부모 댓글 작성자에게도 알림
  - 중복 방지: 게시글 작성자 = 부모 댓글 작성자이면 알림 1개만
  - Supabase DB에 직접 적용 완료 (`003_reply_notification.sql`)
- **Phase 2: 포그라운드 알림 표시**
  - `flutter_local_notifications: ^20.1.0` 패키지 추가
  - `notification_service.dart` 전면 리팩토링: 로컬 알림 초기화 + `_handleForegroundMessage()` 구현
  - Android: 알림 채널 `gongter_notifications` (Importance.high)
  - iOS: `DarwinNotificationDetails(presentAlert, presentSound, presentBadge)`
  - 알림 탭 시 GoRouter로 `/post/{targetId}` 이동 (FCM + 로컬 알림 모두)
- **Phase 3: FCM 푸시 전송 (Edge Function)**
  - `supabase/functions/send-push/index.ts` 신규 생성 + 배포
  - Firebase Service Account JSON → Supabase Secret 등록
  - JWT → OAuth2 토큰 → FCM HTTP v1 API 호출
  - `pg_net` 확장 활성화 + `send_push_webhook()` 트리거: notifications INSERT → Edge Function
  - 무효 FCM 토큰 자동 정리 (UNREGISTERED 응답 시 fcm_token = NULL)
- **Phase 4: 공지사항 알림**
  - `supabase/functions/send-announcement/index.ts` 신규 생성 + 배포
  - FCM Topic `announcements` 구독 (앱 초기화 시) / 해제 (로그아웃 시)
  - `insert_announcement_notifications` RPC: 전체 활성 사용자에게 알림 일괄 INSERT
  - 설정 > 관리자 섹션에 "공지사항 발송" 버튼 + 다이얼로그 (제목/내용 입력)
  - `send-push` Webhook이 `type='system'` 알림은 무시 (Topic으로 이미 전송)
- **Phase 5: 알림 배지**
  - `main_shell.dart` StatelessWidget → StatefulWidget 변환
  - `getUnreadNotificationCount()` 메서드 추가
  - 하단 네비바 알림 아이콘에 `Badge` 위젯 (미읽음 개수 표시)
  - 화면 전환 시 배지 자동 갱신
- **기타**
  - `notification_screen.dart`에 `'system'` 타입 아이콘 (`Icons.campaign`) 추가
  - iOS APNs 인증 키 Firebase 프로젝트에 업로드 (개발 + 프로덕션)
  - `flutter analyze` 통과 + `flutter build ios` 성공 (38.2MB)

### 22. 미해결 이슈 수정 (100%)
- **금칙어 캐싱**: `loadBannedWords()` static 메서드 추가 — 앱 시작 시 1회 DB 조회 후 메모리 캐시
  - `validateNickname()` / `validateContent()`: 매 호출 DB 조회 → 캐시 검사로 변경 (시그니처 유지)
  - `main.dart`: `checkProfileComplete()` 직후 `loadBannedWords()` 호출
- **send-push JWT 검증 활성화**
  - Vault에 `service_role_key` 등록
  - `004_send_push_jwt.sql`: `send_push_webhook()` 함수에 Vault에서 키 읽어 `Authorization: Bearer` 헤더 추가
  - Edge Function JWT 검증 활성화 상태로 재배포 (무인증 호출 시 401 확인)
- **이슈 목록 정리**: FCM APNs 시뮬레이터(정상), 금칙어 DB 조회(해결), send-push JWT(해결) 삭제
- `flutter analyze` 통과 확인

### 23. 이메일 도메인 정정 + 금칙어 오탐 수정 (100%)
- **onnara.go.kr 제거**: MX 레코드 미존재 확인 → 메일 수신 불가 도메인 (온메일 = korea.kr)
  - `email_validator.dart`: 허용 목록에서 `onnara.go.kr` 삭제 → `korea.kr` 단일 도메인
  - `signup_screen.dart`: 에러 메시지 + 안내 박스 텍스트 수정
- **금칙어 "보지" 삭제**: 부분 일치 방식에서 "보지 않다" 등 일상 표현 오탐 → DB에서 제거 (91개 → 90개)
- `flutter analyze` 통과 확인

### 24. PLAN 단계 12: AdMob 실제 ID + 네이티브 광고 + 전면광고 타이밍 변경 (100%)
- **AdMob 실제 ID 교체**
  - AdMob 콘솔에서 Android/iOS 앱 등록 (Publisher: ca-app-pub-1441586915486263)
  - 배너 + 전면 + 네이티브 광고 단위 6개 생성
  - `ad_service.dart`: 테스트 ID → 실제 ID 교체 + `nativeAdUnitId` getter 추가
  - `Info.plist` GADApplicationIdentifier: `ca-app-pub-1441586915486263~3803707426`
  - `AndroidManifest.xml` 앱 ID: `ca-app-pub-1441586915486263~3194370742`
- **전면광고 타이밍 변경** (UX 개선)
  - `post_write_screen.dart`: 글 작성 후 전면광고 **제거** (기여자 보호)
  - `post_detail_screen.dart`: `PopScope` + `onPopInvokedWithResult`로 글 상세 **뒤로가기 시** 전면광고 표시
  - 기존 제한 유지 (하루 3회, 3분 간격)
- **네이티브 광고 피드 삽입**
  - `lib/widgets/native_ad_widget.dart` 신규 생성 (NativeTemplateStyle medium, 카드형)
  - `home_screen.dart`: 내 지자체 + 전국 HOT 피드 모두 10포스트마다 1개 네이티브 광고 삽입
  - 광고 로드 실패 시 `SizedBox.shrink()` (빈 공간 없음)
- **앱 이름 확정**: 공터 - 지방공무원 익명 커뮤니티
- `flutter analyze` 통과 + `flutter build ios` 성공 (38.2MB)

### 25. PLAN 단계 13: iOS 빌드 (100%)
- Apple API로 번들 ID 등록 (`com.gongter.gongter`, ID: AUBXC5XSL9)
- Push Notifications capability 활성화
- App Store Provisioning Profile 생성 (`Gongter App Store`, UUID: 03fc9ad2)
- Xcode 프로젝트 Automatic → Manual signing 전환
  - `CODE_SIGN_IDENTITY` = Apple Distribution
  - `PROVISIONING_PROFILE_SPECIFIER` = Gongter App Store
- `ios/ExportOptions.plist` 생성 (method: app-store-connect)
- `flutter build ios --release` 성공 (38.2MB)
- `xcodebuild archive` → ARCHIVE SUCCEEDED
- `xcodebuild -exportArchive` → `gongter.ipa` (29MB)
- App Store Connect에서 앱 생성 (수동)
- IPA 업로드 성공 (altool, Delivery UUID: f3f0a7e6)

## 남은 단계

### PLAN 단계 14: 출시 전 최종 점검 (0%)
- [ ] 14-1. 인증 플로우 (온보딩/로그인/회원가입/프로필)
- [ ] 14-2. 메인 피드 (홈/내 지자체/전국 HOT/FAB/네비바)
- [ ] 14-3. 글 관리 (작성/상세/수정/삭제/신고)
- [ ] 14-4. 댓글 (작성/수정/삭제/대댓글/익명 표시)
- [ ] 14-5. 상호작용 (좋아요/북마크/신고/차단)
- [ ] 14-6. 탐색 (지자체/게시글 검색)
- [ ] 14-7. 프로필 (정보/닉네임 변경/하위 화면)
- [ ] 14-8. 알림 (목록/FCM/읽음 처리)
- [ ] 14-9. 설정 (법적 고지/문의/차단/로그아웃/삭제)
- [ ] 14-10. 광고 (배너/전면/네이티브)
- [ ] 14-11. 관리자 (공지 발송/지자체 변경)
- [ ] 14-12. 엣지 케이스 (네트워크/빈 상태/긴 텍스트/동시성/라우팅)
- [ ] 14-13. iOS/Android 공통 (권한/SafeArea/키보드/아이콘/스플래시)

### PLAN 단계 15: 출시 준비 (0%)
- [ ] 15-1. 스크린샷 촬영 (6~8장, 6.7인치 기준)
- [ ] 15-2. App Store 메타데이터 (설명/키워드/Age Rating/Review Notes)
- [ ] 15-3. Google Play 메타데이터 (설명/데이터 안전/IARC)
- [ ] 15-4. 제출 (App Store 심사 + Google Play 비공개 테스트 → 도플리 14일)

## 알려진 이슈
- google-services.json / GoogleService-Info.plist: .gitignore 처리됨 (로컬에만 존재)
- (정정) `DropdownButtonFormField`의 `initialValue`는 Flutter 3.33+에서 정식 API — `value`가 deprecated. 버그 아님
- (해결) 금칙어 "보지": 오탐 문제로 DB에서 삭제 완료
- (v2 이관) 글 수정 시 이미지 추가/삭제 불가 (post_edit_screen.dart)
- (v2 이관) 홈 태그 필터 칩 6개 Expanded — 좁은 기기에서 글자 잘림 가능
- korea.kr 가입 시 지자체 자동 감지 불가 → 프로필 설정에서 수동 선택 필요 (정상 동작)
- (출시 후 검토) 알림 배지: 실시간 업데이트 아닌 화면 전환 시 폴링 방식 — 사용자 증가 시 Supabase Realtime 구독 검토
- Pods 배포 타겟 경고: flutter_native_splash(9.0), flutter_local_notifications(11.0), app_tracking_transparency(9.0), PromisesObjC(9.0) — Xcode 최소 12.0 요구. 빌드에 영향 없음, Pods 업데이트 시 자동 해소 예상
- Gongter_AppStore.mobileprovision: ios/ 폴더에 존재, .gitignore 처리 필요

## 메모
- Supabase Free Tier 사용 중 (MAU 50,000까지 무료)
- 테스트 계정: master@gongter.app / master123!
- Git 최신 커밋: abf4865 (2026-03-01)
- PRD v1.1 기준 구현 계획: docs/PLAN.md (15단계, 단계 1~13 완료)
- Firebase Service Account: firebase-service-account.json (.gitignore 처리)
- APNs 인증 키: AuthKey_B7Z37AQHYM.p8 (AllDayMafia와 공유, Team Scoped)
- Edge Functions: send-push (개별 푸시, JWT 검증 활성화), send-announcement (공지 Topic)

## 변경 이력
| 날짜 | 내용 |
|---|---|
| 2026-03-05 | PLAN 단계 13(iOS 빌드) 완료 — 번들 ID 등록(Apple API), Manual signing 전환, ExportOptions.plist, IPA 생성(29MB) + App Store Connect 업로드 성공 |
| 2026-03-05 | PLAN 단계 12(AdMob 실제 ID + 네이티브 광고) 완료 — 실제 ID 6개 교체, 전면광고 타이밍 변경(글 작성 후→글 상세 뒤로가기), 네이티브 광고 피드 삽입(10포스트/1광고), 앱 이름 확정 |
| 2026-03-05 | 이메일 도메인 정정(onnara.go.kr 제거 → korea.kr만) + 금칙어 "보지" 오탐 삭제 |
| 2026-03-05 | 미해결 이슈 수정 — 금칙어 캐싱(loadBannedWords) + send-push JWT 검증 활성화(Vault + 004 마이그레이션) + 이슈 목록 정리 |
| 2026-03-05 | PLAN 단계 11(알림 기능) 완료 — 대댓글 트리거 + 포그라운드 알림 + Edge Function FCM 전송 + 공지사항 + 알림 배지 |
| 2026-03-05 | PLAN 단계 10(이미지 용량 제한) 완료 — _pickImage()에 5MB 초과 검증 + SnackBar 안내 |
| 2026-03-05 | PLAN 단계 9(소속 변경 문의) 완료 — 설정 > 계정에 mailto 템플릿 + 연 1회 안내 다이얼로그 |
| 2026-03-05 | PLAN 단계 8(이메일 도메인 검증 강화) 완료 — korea.kr/onnara.go.kr만 허용, 안내 박스 + 지자체 변경 불가 경고 추가 |
| 2026-03-05 | PLAN 단계 7(온보딩 화면) 완료 — 3페이지 PageView + SharedPreferences + 라우터 연동 |
| 2026-03-05 | PLAN.md 재구성 (12→14단계): 재직증명서 삭제, 이메일 화이트리스트/소속변경 문의/이미지용량제한/FCM포그라운드/네이티브광고 추가 |
| 2026-03-02 | PLAN 단계 6(댓글 수정 기능) 완료 — updateComment + 수정 다이얼로그 + 금칙어 검증 + "수정됨" 라벨 |
| 2026-03-02 | PLAN 단계 5(닉네임 중복 허용 + 익명화 개선) 완료 — 중복 체크 제거, 탈퇴 사용자 라벨, UNIQUE 제약 제거 |
| 2026-03-02 | PLAN 단계 4(금칙어 필터링) 완료 — 92개 단어, 글/댓글/수정 전체 적용 |
| 2026-03-02 | PLAN 단계 2(댓글 soft delete) + 단계 3(양방향 차단 RLS) 완료 |
| 2026-03-02 | PRD v1.1 갭 분석 완료, PLAN.md 12단계 수립, 단계 1(닉네임 검증) 완료 |
| 2026-03-01 | 출시 준비: DB 최적화, FCM, 릴리즈 서명, 시드 콘텐츠, 관리자 기능 |
