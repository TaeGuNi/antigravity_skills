---
name: Security & IAM Protocol
description: >
  NextAuth/JWT 기반의 인증 생태계에서 토큰 탈취(XSS, CSRF)를 원천 방어하고, 브라우저 클라이언트 사이드에서의 민감 정보 렌더링을 차단하는 무수면 보안 헌법.
---

# 🔒 Security & IAM (Identity and Access Management) Protocol

애플리케이션이 아무리 우아하고 빠르더라도, 유저의 세션 토큰이 클라이언트에 노출되는 순간 그 프로젝트는 해커들의 놀이터로 전락합니다. 이 스킬 문서는 에이전트가 인증(Auth) 로직이나 쿠키/JWT를 다룰 때 **보안 사고(XSS, CSRF, Token Leak)**를 시스템 아키텍처 레벨에서 거세(Castrate)하기 위한 절대 원칙입니다.

## 1. 토큰의 클라이언트 노출 절대 금지 (The HttpOnly Dictatorship)
클라이언트 사이드 자바스크립트(React `use client` 포함)가 접근할 수 있는 공간에 JWT나 Access Token을 저장하는 행위는 유저의 목숨을 길거리에 방치하는 것과 같습니다.

- ❌ 금지 사례: 로그인 성공 후 응답받은 토큰을 `localStorage.setItem('token', token)`에 저장하거나, 쿠키에 `HttpOnly` 옵션을 빼고 굽는 행위. (XSS 공격 한 방에 털립니다).
- ✅ 강제 원칙: 토큰은 무조건 **백엔드(또는 Next.js Route Handles)에서 `Set-Cookie` 헤더를 통해 `HttpOnly`, `Secure`, `SameSite=Strict` 옵션을 박아서 구워야 합니다**. 프론트엔드 코드는 그 토큰이 어떻게 생겼는지 만져볼 수도, 알 필요도 없어야 합니다. 오직 브라우저가 알아서 API 통신 시 쿠키를 태워 보내도록 위임하십시오.

## 2. NextAuth.js (Auth.js) 세션 전략의 완전한 무상태화 (Stateless JWT Session)
서버에 세션 상태를 저장하는 것은 클라우드 스케일아웃에 치명적인 병목(Bottleneck)을 유발합니다. (Stateless Architecture 스킬의 연장)

- ❌ 금지 사례: NextAuth의 세션 전략을 `database`로 설정하고 매 요청마다 DB/Redis를 찔러 유저 정보를 가져오는 로직.
- ✅ 해결 원칙: NextAuth(Auth.js)의 인증 전략은 오직 **JWT(JSON Web Token) 전략으로 고정**하십시오. 토큰 내에 식별자(ID)와 역할(Role)만 압축해서 담고, 서명(Signature)만 검증하여 인가(Authorization)를 판별하십시오. 

## 3. JWT Payload 최소화 및 민감 정보 격리 (No Secrets in Payload)
JWT는 암호화(Encryption)된 것이 아니라 인코딩(Encoding)된 텍스트일 뿐입니다. Base64로 풀면 누구나 내용을 읽을 수 있습니다.

- ❌ 금지 사례: JWT Payload 안에 유저의 비밀번호 해시, 주민등록번호, 실제 이메일 등을 무심코 욱여넣는 행위.
- ✅ 강제 원칙: 토큰에는 오직 **무의미한 식별자(`user_id: "uuid-xxxx"`)와 권한 레벨(`role: "admin"`)**만 담으십시오. 이름이나 프로필 사진 같은 부가 정보는 토큰에서 빼내고, 클라이언트에서 별도의 프로필 API(`/api/me`)를 통해 가져오도록 분리하십시오.

## 4. 서버사이드 검증 퍼스트 (Never Trust the Client)
프론트엔드 라우터(Middleware, 최상위 Layout)에서 권한을 튕겨냈다고 보안이 완성된 것이 아닙니다. 클라이언트의 코드는 조작 가능합니다.

- ❌ 금지 사례: 브라우저에서 `session.user.role === 'admin'`만 체크해서 관리자 버튼을 보여주고 끝내는 행위. 백엔드 API에는 아무런 방어 로직이 없는 상태.
- ✅ 아키텍트 통제: 클라이언트에서의 권한 체크는 어디까지나 "UX(사용자 경험)를 빙자한 가짜 방패"임을 인지하십시오. 진짜 방어선은 **모든 백엔드 API (또는 Next.js Server Actions) 진입점**에 있습니다. 반드시 서버 측 코드 가장 첫 줄에서 세션 검증(예: `auth()`) 및 인가(Zod + Role Check) 파이프라인을 통과시켜야만 트랜잭션이 실행되도록 강제하십시오.

## 5. CSRF 방어 (Cross-Site Request Forgery)
`SameSite=Strict` 쿠키가 강력하긴 하나, 구형 브라우저나 복잡한 CROS 환경에서는 방어선이 뚫릴 수 있습니다.

- ❌ 금지 사례: 데이터 수정(POST, PUT, DELETE) API를 뚫어놓고 아무 사이트에서나 해당 엔드포인트로 폼 전송을 허용하는 것.
- ✅ 강제 원칙: 서버사이드 렌더링(SSR) 환경에서 폼(Form) 전송이나 상태 변경 액션을 구현할 때는, 예외 없이 CSRF Token 검증 로직을 타거나, 최신 프레임워크(Next.js Server Actions)가 내장 제공하는 Anti-CSRF 헤더/토큰 메커니즘을 훼손 없이 우산 삼아 사용하십시오.

## 6. 생명주기 분리 및 Refresh Token Rotation (The Sliding Session)
Access Token의 만료 기간(Expiration)을 1년으로 설정하는 것은 서버에 백도어를 1년간 열어두는 것과 같습니다. 무상태(Stateless) JWT의 가장 큰 약점은 원격으로 강제 무효화(Revoke)하기 어렵다는 점입니다.

- ❌ 금지 사례: 수명이 긴 단일 JWT 하나만 발급하여 모든 인증을 처리하는 행위.
- ✅ 해결 원칙: 토큰은 반드시 두 가지 생명주기로 분리해야 합니다. 
  1. **Access Token**: 수명을 극단적으로 짧게(예: 15분~1시간) 제한하여 탈취당하더라도 피해를 최소화하십시오.
  2. **Refresh Token (Rotation)**: Access Token을 재발급받기 위한 용도로만 사용하며, 사용될 때마다 1회용으로 폐기하고 새 Refresh Token을 발급(Rotation)하여 탈취된 Refresh Token의 재사용을 원천 차단(Replay Attack 방어)하십시오.

## 7. Brute-Force 임계점 통제 (Auth Throttling)
로그인 API는 해커들의 가장 만만한 공격 벡터(Attack Vector)입니다. 무제한으로 비밀번호 딕셔너리 공격을 허용하는 시스템은 안일함의 극치입니다.

- ❌ 금지 사례: 실패 횟수 제한이나 클라이언트 IP 기반의 접속 차단 로직이 없는 순진한 `POST /api/login` 엔드포인트.
- ✅ 강제 원칙: 인증 스트라이크(로그인, 비밀번호 초기화, OTP 등)에는 반드시 **Rate Limiter (e.g., Redis 기반 Upstash, Nginx Limit Req)**를 태워서, 특정 IP나 계정에서 분당 N회 이상 연속 실패 시 기계적으로 `429 Too Many Requests`를 뱉고 지연(Delay) 또는 락(Lock)을 걸어 시스템을 방어하십시오.
