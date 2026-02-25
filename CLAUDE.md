# 공터 (Gongter) - 지방공무원 익명 커뮤니티

## 프로젝트 개요
- **스택**: Flutter + Supabase + AdMob + GoRouter
- **번들 ID**: com.gongter.gongter
- **컨셉**: 지방공무원 전용 익명 커뮤니티 (국내 전용, 다국어 불필요)
- **현재 버전**: 1.0.0+1

## Supabase
- Project ref: `lvqgmcrwdkmcgqkwkdlq`
- URL: https://lvqgmcrwdkmcgqkwkdlq.supabase.co
- 조직: pickbriefing (별도 계정)
- Access Token: sbp_501e19c69823efe532c6fbe6aa27a49c56f58c70
- DB 스키마 배포 완료, 243개 지자체 시드 완료
- RPC: `delete_my_account()`, `view_post()`, `search_posts()`

## 테스트 계정
- master@gongter.app / master123!
- User ID: eee90e1e-d099-485b-a2fc-981b3bbb1b5d
- 지자체: 서울특별시 (verified)

## 구현 완료
- 인증: 이메일 가입/로그인/OTP/프로필설정
- 홈: 내 지자체 피드 + 전국 HOT (태그 필터)
- 게시물: CRUD + 이미지 업로드 + 좋아요/북마크 + 조회수
- 댓글: CRUD + 신고
- 탐색: 검색 + 지자체별 피드
- 프로필: 내 글/댓글/북마크
- 설정: 계정삭제, 로그아웃, 이용약관, 개인정보처리방침
- 신고/차단 (차단 유저 피드 필터링)
- AdMob 배너 + 전면광고 (테스트 ID)
- ATT (App Tracking Transparency)
- CachedNetworkImage, timeago 한국어

## QA 완료 (build 7)
- 22건 발견 → Critical 2 + High 6 + Medium/Low 모두 수정
- 프로필 미완성 유저 라우팅, 조회수 중복 방지, 좋아요/북마크 더블탭 방지
- 댓글 신고, 차단 유저 피드 필터링, force unwrap 제거
- 이미지 업로드 실패 시 cleanup, 닉네임 유효성 검사

## 남은 작업
- [ ] Firebase/FCM 초기화 (패키지만 설치, 코드 0)
- [ ] AdMob 실제 ID 교체 (현재 테스트 ID)
- [ ] Android Release Signing (키스토어)
- [ ] 앱스토어/구글플레이 준비 (스크린샷, 설명, Age Rating)
- [ ] GitHub Pages 배포 (privacy/terms URL 호스팅)

## Git 히스토리
1. c9e83e7 - Initial project setup
2. ab5956b - Municipality seed data (243개)
3. 7dd2c11 - Supabase connection + schema deploy
4. 4c23971 - Auth flow, profile, post edit, image upload
5. 5a83cbd - App icon (green - old)
6. 09a4260 - Redesign to coral/peach theme

## 테마
- Primary: #E8836B (코랄)
- Secondary: #F2A896 (피치)
- Surface: #FFF8F5
- Accent: #D4604A

## Android SDK
- compileSdk: 36 / targetSdk: 35 / minSdk: 24

## AdMob
- 현재 테스트 ID 사용 중
- 전면광고: 글 작성 후 표시 (하루 3회, 3분 간격 제한)
