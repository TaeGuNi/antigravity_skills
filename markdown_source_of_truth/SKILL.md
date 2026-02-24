---
name: Context Compression & Markdown Source of Truth
description: >
  AI의 토큰 오버플로우와 컨텍스트 망각을 막기 위해 찰나의 기억을 Markdown 기반 영구 메모리로 압축하고 시스템의 진리를 문서에 두는 스킬.
---

# 📚 Context Compression & Markdown Source of Truth

이 스킬은 에이전트와 인간의 대화가 길어질 때 발생하는 치명적인 버그인 '치매(Lost in the middle)' 현상을 방어하기 위한 궁극의 컨텍스트 보존 병기입니다. 비즈니스 로직과 진행 상태의 진리(Source of Truth)는 채팅창의 과거 대화가 아니라, 오직 명시적인 **마크다운 문서**에만 존재해야 합니다.

## 1. 마크다운 주도 개발 (MDD: Markdown-Driven Development)
코드부터 무지성으로 뜯어고치는 해커식 접근을 영구 금지합니다.

- ❌ 금지 사례: 사용자의 피처 추가 요구를 듣자마자 `src/` 폴더 안의 `.ts` 파일부터 `replace_file_content`로 고쳐버리는 행위.
- ✅ 강제 원칙: 코드를 수정하기 전, 반드시 프로젝트 내 해당 기능의 기획서(`README.md`, `docs/features/xxx.md`, 또는 `task.md`)를 먼저 업데이트하여 **코드 변경의 의도와 설계 이력을 생생한 텍스트로 영구 박제**하십시오.

## 2. 컨텍스트 압축과 망각의 방어 (The Memory Consolidation)
에이전트는 자신의 뇌(Context Window) 한계를 겸손하게 인정해야 합니다.

- ✅ 강제 원칙: 사용자와의 핑퐁(대화 턴)이 길어지고 여러 파일을 횡단하며 작업하다가 맥락이 흩어질 위험이 감지되면, 에이전트 스스로 현재 무슨 작업을 어디까지 했고 무슨 버그를 남겨놓았는지 **`memory.md` 혹은 `task.md` 에 압축 요약(Summarize)하여 상태를 세이브(Save)** 하십시오.
- 🚫 과거의 채팅 내역(History)에 의존하여 코딩하지 마십시오. 새로운 에이전트 인스턴스가 투입되거나 내일 대화창이 초기화되더라도, 오직 `memory.md`만 1초 만에 스캔하면 어제 하던 작업을 1바이트의 오차 없이 완벽하게 이어나갈 수 있어야 합니다 (불멸의 컨텍스트 구축).
