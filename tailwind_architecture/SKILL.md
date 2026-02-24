---
name: Tailwind CSS & Design System Architecture Skill
description: >
  프론트엔드 UI의 디자인 일관성(Consistency) 파괴를 방지하고, 매직 넘버(Hex, px) 주입을 원천 차단하여 애플리케이션 전체를 하나의 완벽한 Design System으로 통제하는 시니어 Tailwind 룰셋.
---

# 🎨 Tailwind CSS & Design System Architecture Protocol

이 스킬 문서는 단순히 "Tailwind를 잘 쓰자"는 가이드가 아닙니다. 여러 명의 개발자나 AI 에이전트가 코드를 작성할 때, **UI 디자인의 파편화와 픽셀/컬러의 오염을 시스템 레벨에서 원천 차단(Zero-Tolerance)**하기 위해 만들어진 무자비한 디자인 시스템 헌법입니다. 일관성이 무너진 UI는 기술 부채이자 서비스의 신뢰도를 깎아먹는 가장 큰 적입니다.

## 1. 매직 넘버 및 Ad-hoc 컬러 주입 엄벌 (The "No Magic Values" Rule)
Tailwind의 가장 큰 재앙은 개발자가 임의로 대괄호(`[]`)를 열어 일회성 헥스(Hex) 코드나 픽셀(px) 값을 욱여넣는 행위입니다.

- ❌ 금지 사례: `text-[#FF5733]`, `w-[325px]`, `gap-[13px]`, `bg-[#1A1A1A]/80`
- ✅ 아키텍트의 솔루션: 디자인에 등장하는 모든 색조(Color Palette), 여백(Spacing), 타이포그래피(Typography)는 반드시 **`tailwind.config.ts` (또는 전역 CSS 변수)에 토큰(Design Token)으로 등록**해야만 사용 가능합니다.
  - 모르는 색상이나 애매한 여백(예: 13px)을 마주했다면 자의적으로 하드코딩(`[]`)하지 마십시오. 즉각 가장 가까운 의미론적(Semantic) Tailwind 기본 토큰(예: `gap-3`, `w-80`)으로 스냅(Snap)하여 보정하십시오.

## 2. 무자비한 컴포넌트 추상화 (The Consistency Enforcer)
동일한 UI 요소(버튼, 카드, 뱃지 등)가 페이지마다 다른 유틸리티 클래스 조합으로 구성되어 시각적으로 미세하게 다르게 렌더링되는 "스파게티 UI"를 절대 용납할 수 없습니다.

- ❌ 금지 사례: A 페이지에서는 `<button className="px-4 py-2 bg-blue-500 rounded-md">`, B 페이지에서는 `<button className="px-3 py-1 bg-blue-600 rounded-sm">` 처럼 파편화된 버튼을 남발.
- ✅ 해결 원칙: 재사용되는 모든 UI 프리미티브(Primitive) 요소는 반드시 `cva(class-variance-authority)`, `tailwind-merge`, `clsx`를 활용하여 **단일 진실 공급원(Single Source of Truth) 컴포넌트**로 강제 격리(Encapsulate) 하십시오. 요소의 형태를 바꾸고 싶다면 클래스를 직접 주입하지 말고 `variant="outline"`, `size="sm"` 형태의 엄격히 통제된 Props 인터페이스로만 접근하게 하십시오.

## 3. 반응형 디자인 퍼스트 (Mobile-First Immutable Law)
데스크탑 화면에서만 예쁘게 보이고 모바일에서 깨지는 UI는 미완성이 아니라 "버그(Bug)"입니다.

- ❌ 금지 사례: `className="flex flex-row max-md:flex-col ..."` (모바일을 예외 처리로 간주하는 안티 패턴)
- ✅ 강제 원칙: 모든 UI 컴포넌트의 기본 뼈대는 예외 없이 **모바일(Mobile) 사이즈를 기본값으로 작성**되어야 하며, `sm:`, `md:`, `lg:` prefix를 점진적으로 덧붙여 나가는 Mobile-First 패러다임에 절대 복종하십시오. 화면이 작아질 때 스타일을 빼는 것이 아니라, 화면이 커질 때 레이아웃을 확장(Enhance)하는 방식으로 사고하십시오.

## 4. 구조적 유틸리티 클래스 정렬 (Esthetic Code Formatting)
컴포넌트의 코드가 지저분하면 숨겨진 스타일 충돌이나 오버라이딩 버그를 캐치할 수 없습니다.

- ❌ 금지 사례: `className="text-center md:flex-row flex font-bold w-full bg-white text-lg justify-between p-4"` (순서 없는 난장판)
- ✅ 아키텍트 솔루션: 코드를 수동으로 작성할 때는 반드시 다음의 우선순위(레이아웃 -> 크기 -> 타이포그래피 -> 장식)를 체화하십시오:
  1. **구조/레이아웃** (`flex`, `grid`, `absolute`, `z-index`)
  2. **여백 및 크기** (`p-`, `m-`, `w-`, `h-`)
  3. **타이포그래피** (`text-`, `font-`)
  4. **디자인 요소** (`bg-`, `border-`, `rounded-`, `shadow-`)
  5. **인터랙션 및 반응형** (`hover:`, `md:`, `transition-`)

## 5. 시맨틱 토큰(Semantic Token) 강제 (The Variables Dictatorship)
수십, 수백 개의 페이지를 가진 대규모 시스템에서 `bg-blue-500`과 같은 직접적인 색상 언급은 테마 시스템(Dark Mode, 리브랜딩) 도입 시 치명적인 리팩토링 비용을 청구합니다.

- ❌ 금지 사례: `text-red-500`, `bg-gray-100` (특정 색상을 지칭)
- ✅ 강제 원칙: 디자인 시스템의 색상은 반드시 **의미론적(Semantic) 역할**로 정의되어야 합니다. `text-destructive` (에러/삭제 버튼), `bg-muted` (비활성/보조 배경), `text-primary`와 같이 역할 기반의 커스텀 Tailwind 토큰을 `tailwind.config`에 등록하여 사용하십시오.

## 6. 레이아웃의 중앙 통제 (Layout Componentization)
페이지마다 `max-w-7xl mx-auto px-4` 같은 레이아웃 코드를 복붙하는 순간, 전체 사이트의 일관성은 시한폭탄을 안게 됩니다.

- ❌ 금지 사례: 각 페이지 컨테이너 최상단에 마진/패딩 유틸리티를 수동으로 타이핑하여 페이지마다 미세하게 여백이 어긋나는 현상.
- ✅ 해결 원칙: 페이지의 뼈대를 구성하는 컨테이너는 반드시 `<PageContainer>`, `<AuthLayout>`, `<DashboardLayout>` 등으로 추상화되어야 합니다. 개발자는 페이지 콘텐츠만 작성하고, 전체 레이아웃의 픽셀은 중앙/레이아웃 컴포넌트 한 곳에서만 통제받아야 합니다.

## 7. 기계적 린팅 자동화 (Machine-Level Enforcement)
에이전트나 인간의 '주의력'에 의존하는 방어선은 필연적으로 뚫립니다.

- ❌ 금지 사례: PR 리뷰에서 스파게티 클래스나 매직 넘버 주입을 사람이 눈으로 검사하는 행위.
- ✅ 아키텍트 통제: 프로젝트 초기 세팅 시 예외 없이 `eslint-plugin-tailwindcss` 나 `Biome`의 Tailwind 플러그인을 적용하십시오. 클래스 순서가 다르거나 승인되지 않은 임의의 픽셀(`[]`) 조작이 발생하면 CI 파이프라인에서 빌드를 터뜨려(Fail) 강제로 롤백시키십시오.

## 8. 무분별한 Z-Index 군비 경쟁 금지 (The Z-Index Escalation Ban)
드롭다운이나 모달이 가려진다고 해서 `z-50`, `z-[9999]`를 남발하는 행위는 전체 Stacking Context를 붕괴시키는 가장 흔하고 치명적인 안티 패턴입니다.

- ❌ 금지 사례: 팝업이 안 보일 때 무지성으로 `z-[999]`, `z-[9999]`를 추가하여 다른 컴포넌트와의 Z축 경쟁(Arms Race)을 유발하는 행위.
- ✅ 강제 원칙: 
  1. **Stacking Context의 이해**: `z-index`는 형제 노드 간의 경쟁일 뿐입니다. 부모의 `z-index`나 `opacity`, `transform` 속성으로 인해 생성된 닫힌 Stacking Context 내부에서는 아무리 자식에게 `z-[9999]`를 줘도 뚫고 나오지 못함을 인지하십시오.
  2. **지정된 Z-Layer 토큰 사용**: `z-index` 역시 매직 넘버를 엄격히 금지합니다. `tailwind.config`에 `z-dropdown: 40`, `z-modal: 50`, `z-toast: 60`과 같이 시스템 전체의 고도(Elevation) 계층도를 사전 정의하고 이 토큰만 사용하십시오.
  3. **Portal의 적극 활용**: 화면 최상단에 렌더링되어야 하는 모달이나 토스트 UI는 `z-index` 꼼수 대신 선언적으로 React의 `createPortal`을 사용하여 DOM 트리의 최상단(`<body>` 직하위)으로 물리적으로 빼내어 렌더링하십시오.
