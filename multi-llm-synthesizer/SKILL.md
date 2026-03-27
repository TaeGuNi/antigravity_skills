---
name: multi-llm-synthesizer
description: "Parallel querying of multiple LLMs (Gemini, Groq, Codex) and synthesis of their responses. Integrated with cmux for progress tracking and full split-screen visibility. Use when the user needs a second (or third) opinion on a complex problem, or want to summarize screen content with multi-LLM consensus."
---

# Multi-LLM Synthesizer

The Multi-LLM Synthesizer allows Gemini CLI to perform high-fidelity analysis by gathering opinions from multiple leading models (Gemini, Groq, Codex) and synthesizing them into a single, high-quality conclusion.

## Key Features

- **Parallel Execution**: Queries all models simultaneously to minimize latency with timeout guards (60s).
- **cmux Integration & Real-Time Visibility**: Updates the sidebar with progress and actively spawns terminal splits for Gemini, Groq, and Codex to show responses as they arrive.
- **Context Injection**: Automatically captures the current terminal screen if no question is provided, or seamlessly reads piped data from standard input (stdin).
- **Markdown Display**: Opens the final result in a new `cmux` markdown viewer pane.

## Workflow

### 🧠 Cognitive Decision Tree: Choosing Your Approach
```text
User task → Does it require complex architectural analysis, coding consensus, or a second opinion?
    ├─ No → Use standard single-model `gemini-3.1-pro` for speed and context efficiency.
    └─ Yes → Run `multi_llm_prompt.zsh` to trigger the Multi-LLM Synthesizer.
```

### 📦 The "Black-Box" Tooling Rule
**CRITICAL**: DO NOT attempt to read the source code of `multi_llm_prompt.zsh` (e.g., via `cat` or `view_file`) before using it. This script is fully sealed and complex. Simply invoke it as a black box via the CLI parameters above to protect your context window from token explosion.

1. **Invoke the script**: Run `multi_llm_prompt.zsh` with the user's question, or pipe output to it.
2. **Monitor Splits**: Watch Gemini, Groq, and Codex output stream into their respective `cmux` panes.
3. **Review Synthesis**: The final synthesized result will be displayed natively via `cmux markdown`.

## Usage Instructions

To use this skill, execute the provided script:

```bash
zsh .gemini/skills/multi-llm-synthesizer/scripts/multi_llm_prompt.zsh "<QUESTION>"
```

If no question is provided, it will first check for **Piped Input (stdin)**. If empty, it will read the last 50 lines of the current `cmux` screen as context.

### Example Queries

- **Direct Question**: 
  `zsh .gemini/skills/multi-llm-synthesizer/scripts/multi_llm_prompt.zsh "What is the best way to refactor this React component?"`
- **Piped Log Analysis**: 
  `cat /var/log/nginx/error.log | zsh .gemini/skills/multi-llm-synthesizer/scripts/multi_llm_prompt.zsh`
- **Screen Reading**: 
  `zsh .gemini/skills/multi-llm-synthesizer/scripts/multi_llm_prompt.zsh` (Reads current `cmux` screen)

## Technical Details

- **Gemini**: Used for primary querying and final robust synthesis (using `gemini-3.1-pro-preview`).
- **Groq & Codex**: Provide alternative zero-shot perspectives.
- **Chaos Monkey Guard**: Strict dependency injection checks. Script `exit 1` immediately if `gemini`, `groq`, or `codex` are missing, preventing polluted downstream execution.
- **Exponential API Resilience (New)**: Incorporates a recursive `--worker` architecture to seamlessly catch `429 Too Many Requests` and network drops, applying up to 3 exponential backoff retries to all queries.
- **Memory Leak Defense**: Uses POSIX `trap EXIT INT TERM` to guarantee absolute destruction of the `$TMP_DIR` even upon `Ctrl+C` aboard.
- **Pipefail Exit Codes**: Executes VM panes with `set -o pipefail` to capture actual LLM crash codes, automatically discarding "[API Call Failed]" responses from the final synthesis.
- **Deadlock Immunity**: The final `/prompt` resolution is hard-wrapped in a `timeout 120` mechanism to protect the main thread from synchronous Gateway hangs.
- **Autoresearch Latency**: Uses accelerated 0.2s check polling (vs 1s) to eliminate dead-time upon LLM completion.
- **CoT Synthesis**: Implements structured inference, enforcing output segmentation into Consensuses, Conflicts, and Unified Resolution.
- **cmux API**: Actively uses `set-status`, `set-progress`, `read-screen`, `new-split`, and `markdown` viewer functionalities.
