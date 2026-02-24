---
name: GitHub CLI Automation Skill
description: >
  코드 수정 후 에이전트의 완전 자율적인 GitOps(Commit, PR 생성, CI Check, Auto-Merge) 수행을 규정하는 핵심 스킬.
---

# Antigravity용 GitHub CLI (`gh`) 자동화 스킬

이 스킬 문서는 에이전트가 소스 코드를 수정한 뒤, 사용자님의 로컬에서 직접 Git 명령어를 조합하여 브랜치를 파고 PR을 자동 생성하며, CI 파이프라인(테스트) 통과 여부를 감시한 뒤 스스로 Merge(병합)까지 이끌어내는 "End-to-End" 자율 프로세스를 정의합니다.

## GitOps 자율 주행 4단계 파이프라인 (The 4-Step Autonomous Flow)

사용자가 승인한 코드 변경이 모두 완료되었다면, 에이전트는 사용자가 지시하지 않아도 능동적(Proactive)으로 다음 4개의 파이프라인을 타야 합니다.

### 1단계: 브랜치 생성 및 격리 (Isolation)

작업 중인 `main` 또는 `develop` 브랜치에 직접 푸시(Direct Push)하는 행위를 영구 금지합니다.
또한, 충돌(Merge Conflict)을 사전에 방지하기 위해 브랜치를 파기 직전 **반드시 최신 변경사항을 Pull(Rebase)**로 당겨와야 합니다.

```bash
# 치명적 충돌 방지를 위한 방어 기제
git pull origin develop --rebase 

# 신규 작업 공간 할당
git checkout -b feature/antigravity-update-xxx
git add .
git commit -m "feat: [Agent] Your concise descriptive commit message"
git push -u origin HEAD
```

### 2단계: PR 자동 생성 (PR Generation)
로컬 푸시 직후, GitHub CLI인 `gh` 명령어를 사용하여 수동 개입 없이 스스로 PR을 폭격해야 합니다.
```bash
gh pr create --title "feat: [Agent] Automated Code Refactoring" --body "## Description\nAntigravity agent applied the requested changes..."
```

### 3단계: CI/CD 상태 감시 (Status Monitoring)
PR을 열고 난 직후에는 Vercel, GitHub Actions 등 훅업된 CI(빌드/테스트)가 성공적으로 도는지 타임아웃을 걸고 주기적으로 감시하십시오.
```bash
# 30초 간격으로 최대 5분 동안 상태 체크를 수행합니다.
gh pr checks --watch
```

### 4단계: 능동적 병합 시도 (Auto-Merge)
모든 CI Check가 초록불(Success)로 떨어졌다면, 사용자에게 "머지할까요?" 묻기 전에 스스로 병합을 시도하거나 Auto-merge를 활성화하십시오. 스쿼시(Squash) 머지가 가장 깔끔한 히스토리를 보장합니다.
```bash
gh pr merge --squash --auto --delete-branch
```

## 예외 처리 (Exception Handling)

- `gh: Not logged in` 에러가 발생하면, 즉시 사용자에게 `gh auth login` 인증이 필요함을 알리십시오.
- CI/CD 파이프라인(테스트)에서 실패(Fail)나 Lint 에러가 떨어지면, 에이전트는 에러 로그를 읽고(`gh run view`) 다시 코드를 수정하여 `commit` & `push`하는 **"자가 치유(Self-Healing)"** 프로세스에 스스로 돌입해야 합니다.
