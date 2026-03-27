#!/bin/zsh

# Multi-LLM Prompt Synthesizer with cmux Integration (Dynamic Split Edition)
# Features:
# - Parallel querying of Gemini, Groq, and Codex.
# - REAL-TIME VISIBILITY: Uses cmux new-split to show LLM output as it arrives.
# - cmux sidebar progress and status reporting.
# - Optional: Use cmux screen content or stdin as context.
# - Synthesized output via Gemini 3.1 Pro (Preview model fallback).
# - Extreme Robustness (Autoresearch Phase 2): Trap cleanup, exit-code validation, fail-fast dependency assertions.
# - GUI Observability (Phase 3): Unmuted splits + IDE background stream multiplexing.
# - Exponential Resilience (Phase 4): Recursive --worker architecture for seamless API 429 / Rate Limit backoff.

SCRIPT_PATH=$(realpath "$0" 2>/dev/null || echo "$0")

# Cross-platform timeout handling for macOS (missing GNU coreutils)
if command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout"
else
  TIMEOUT_CMD=""
fi

function exec_timeout() {
  local dur=$1
  shift
  if [[ -n "$TIMEOUT_CMD" ]]; then
    $TIMEOUT_CMD "$dur" "$@"
  else
    "$@"
  fi
}

# --- RECURSIVE WORKER MODE (Handles 429 Errors & Exponential Backoff) ---
if [[ "$1" == "--worker" ]]; then
  INPUT_FILE=$2
  OUT_FILE=$3
  shift 3
  
  ATTEMPT=1
  DELAY=10
  while [[ $ATTEMPT -le 3 ]]; do
    echo "--- 🚀 LLM QUERY ATTEMPT $ATTEMPT ---" > "$OUT_FILE"
    # Pass all remaining args as the command to execute
    "$@" < "$INPUT_FILE" >> "$OUT_FILE" 2>&1
    STATUS=$?
    
    # Check for 429 error text in the output in case the API suppresses exit codes
    if [[ $STATUS -eq 0 ]] && ! grep -Eiq "(429 too many requests|rate limit|quota exceeded|429 error)" "$OUT_FILE"; then
      exit 0
    fi
    
    echo -e "\n⚠️ [Retry Mechanism] Attempt $ATTEMPT failed (Exit: $STATUS or 429 Error). Retrying in ${DELAY}s..." | tee -a "$OUT_FILE"
    sleep $DELAY
    ((DELAY+=10))
    ((ATTEMPT++))
  done
  
  echo -e "\n❌ [Fatal] API permanently failed after 3 attempts." >> "$OUT_FILE"
  exit 1
fi
# --- END WORKER MODE ---


# 1. Dependency Assertion (Chaos Monkey Guard)
for cmd in gemini groq codex; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ Fatal Error: Required binary '$cmd' is not installed or not in PATH."
    exit 1
  fi
done

# 2. Read input from stdin if piped
if [[ ! -t 0 ]]; then
  QUESTION=$(cat)
else
  QUESTION="${1}"
fi

CMUX_EXE=$(which cmux 2>/dev/null)

# Verify if cmux is actively available in this session (Chaos Monkey Context Check)
CMUX_AVAILABLE=false
if [[ -n "$CMUX_EXE" ]]; then
  # Test connection to the mux server. If access is denied (e.g., Antigravity Agent), fallback to IDE streaming.
  if $CMUX_EXE set-progress 0.0 --label "Init" &>/dev/null; then
    CMUX_AVAILABLE=true
  fi
fi

# Helper: cmux status update
function cmux_status() {
  if [[ "$CMUX_AVAILABLE" == "true" ]]; then
    $CMUX_EXE set-status "LLM Synthesis" "$1" --icon "cpu" --color "#00A8FF"
  fi
}

# Helper: cmux progress update
function cmux_progress() {
  if [[ "$CMUX_AVAILABLE" == "true" ]]; then
    $CMUX_EXE set-progress "$1" --label "$2"
  fi
}

# If no question is provided, try to read screen if in cmux
if [[ -z "$QUESTION" ]]; then
  if [[ "$CMUX_AVAILABLE" == "true" ]]; then
    echo "🔍 No question provided. Reading cmux screen content..."
    SCREEN_CONTENT=$(cmux read-screen --lines 50)
    QUESTION=$(printf "Summarize the content of this screen and identify any issues or next steps:\n\n%s" "$SCREEN_CONTENT")
  else
    echo "Usage: echo 'question' | $0 OR $0 'question'"
    exit 1
  fi
fi

# 3. Memory Leak Defense / Trap Cleanup
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

# Prepare files
GEMINI_OUT="$TMP_DIR/gemini.txt"
GROQ_OUT="$TMP_DIR/groq.txt"
CODEX_OUT="$TMP_DIR/codex.txt"

GEMINI_DONE="$TMP_DIR/gemini.done"
GROQ_DONE="$TMP_DIR/groq.done"
CODEX_DONE="$TMP_DIR/codex.done"

# Ensure files exist to avoid 'cat' errors when timeouts occur
touch "$GEMINI_OUT" "$GROQ_OUT" "$CODEX_OUT"

QUESTION_FILE="$TMP_DIR/question.txt"

# Save the question to a file to avoid shell expansion issues
printf "%s" "$QUESTION" > "$QUESTION_FILE"

echo "⏳ Starting parallel LLM query: Gemini, Groq, Codex..."
cmux_status "Querying LLMs..."
cmux_progress 0.1 "LLM Querying"

# --- DYNAMIC SPLIT INTEGRATION & FAULT-TOLERANT RECURSIVE WORKER ---
if [[ "$CMUX_AVAILABLE" == "true" ]]; then
  $CMUX_EXE new-split right --command "zsh '$SCRIPT_PATH' --worker '$QUESTION_FILE' '$GEMINI_OUT' exec_timeout 60 gemini prompt; echo \$? > '$GEMINI_DONE'; echo '\n--- DONE ---'; sleep 5" &
  sleep 0.5
  $CMUX_EXE new-split down --command "zsh '$SCRIPT_PATH' --worker '$QUESTION_FILE' '$GROQ_OUT' exec_timeout 60 groq; echo \$? > '$GROQ_DONE'; echo '\n--- DONE ---'; sleep 5" &
  sleep 0.5
  $CMUX_EXE new-split down --command "zsh '$SCRIPT_PATH' --worker '$QUESTION_FILE' '$CODEX_OUT' exec_timeout 60 codex; echo \$? > '$CODEX_DONE'; echo '\n--- DONE ---'; sleep 5" &
else
  echo "🚀 IDE GUI / Non-cmux Environment Detected. Multiplexing LLM logs to main console..."
  (zsh "$SCRIPT_PATH" --worker "$QUESTION_FILE" "$GEMINI_OUT" exec_timeout 60 gemini prompt; echo $? > "$GEMINI_DONE") &
  PID_GEMINI=$!
  (zsh "$SCRIPT_PATH" --worker "$QUESTION_FILE" "$GROQ_OUT" exec_timeout 60 groq; echo $? > "$GROQ_DONE") &
  PID_GROQ=$!
  (zsh "$SCRIPT_PATH" --worker "$QUESTION_FILE" "$CODEX_OUT" exec_timeout 60 codex; echo $? > "$CODEX_DONE") &
  PID_CODEX=$!
  
  # Stream the files to the GUI terminal
  tail -qf "$GEMINI_OUT" "$GROQ_OUT" "$CODEX_OUT" 2>/dev/null &
  TAIL_PID=$!
fi

# Monitor progress (Autoresearch Latency Polling)
if [[ "$CMUX_AVAILABLE" == "true" ]]; then
  echo "⌛ Waiting for LLM panes to finish (timeout 300s due to 429 retry loops)..."
  COUNTER=0
  while [[ $COUNTER -lt 1500 ]]; do # 1500 * 0.2 = 300s
    if [[ -f "$GEMINI_DONE" && -f "$GROQ_DONE" && -f "$CODEX_DONE" ]]; then
       break
    fi
    sleep 0.2
    ((COUNTER++))
  done
  cmux_progress 0.9 "LLM Response Phase Finished"
else
  echo "⌛ Waiting for LLM background streaming to finish (Retries supported)..."
  wait $PID_GEMINI
  wait $PID_GROQ
  wait $PID_CODEX
  kill -9 $TAIL_PID 2>/dev/null
  cmux_progress 0.9 "All Models Responded"
fi

echo "✅ All responses collected. Synthesizing..."
cmux_status "Synthesizing Results..."
cmux_progress 0.95 "Synthesizing"

# 4. Exit Code Validation & Filtering
function is_valid_response() {
  local done_file=$1
  if [[ -f "$done_file" ]] && [[ "$(cat "$done_file" 2>/dev/null)" == "0" ]]; then
    return 0 # Success
  else
    return 1 # Failed or Timed out 3 times
  fi
}

local valid_responses=0
is_valid_response "$GEMINI_DONE" && ((valid_responses++))
is_valid_response "$GROQ_DONE" && ((valid_responses++))
is_valid_response "$CODEX_DONE" && ((valid_responses++))

# Synthesis Guard: Autoresearch Mutation for Early Exit
if [[ $valid_responses -eq 0 ]]; then
  echo "❌ Error: All LLMs definitively failed to return a valid response (Network Error, 429 Limit, or Crash)."
  cmux_status "Failed"
  cmux_progress 1.0 "Error"
  exit 1
fi

# Synthesis Processing
SYNTH_PROMPT_FILE="$TMP_DIR/synth_prompt.txt"
{
  printf "You are an expert synthesizer operating under an analytical research framework. I asked several top-tier LLMs (Gemini, Groq, Codex) the following question:\n\n"
  cat "$QUESTION_FILE"
  printf "\n\nHere are their raw responses. Your task is to extract the optimal insights and synthesize them into a unified, high-quality conclusion.\n"
  printf "Format your final output strictly into the following sections:\n"
  printf "### 1. Consensuses (Agreeing points)\n### 2. Conflicts & Divergences\n### 3. Final Synthesized Resolution\n\n"
  
  printf "--- GEMINI RESPONSE ---\n"
  is_valid_response "$GEMINI_DONE" && cat "$GEMINI_OUT" || echo "[API Call Failed permanently after Retries]"
  
  printf "\n--- GROQ RESPONSE ---\n"
  is_valid_response "$GROQ_DONE" && cat "$GROQ_OUT" || echo "[API Call Failed permanently after Retries]"
  
  printf "\n--- CODEX RESPONSE ---\n"
  is_valid_response "$CODEX_DONE" && cat "$CODEX_OUT" || echo "[API Call Failed permanently after Retries]"
} > "$SYNTH_PROMPT_FILE"

# 5. Fault-Tolerant Synthesis (Uses the recursive worker to guard against 429 during synthesis)
SYNTH_OUT="$TMP_DIR/synth_out.txt"
zsh "$SCRIPT_PATH" --worker "$SYNTH_PROMPT_FILE" "$SYNTH_OUT" exec_timeout 120 gemini prompt --model gemini-3.1-pro-preview
SYNTHESIS_STATUS=$?

if [[ $SYNTHESIS_STATUS -ne 0 ]]; then
  echo "❌ Fatal Error: Synthesis API call crashed or timed out permanently."
  cat "$SYNTH_OUT"
  cmux_status "Failed"
  cmux_progress 1.0 "Error"
  exit 1
fi

FINAL_RESULT=$(cat "$SYNTH_OUT")

# Output the result
echo "--- FINAL SYNTHESIZED RESULT ---"
echo "$FINAL_RESULT"

# If in cmux, display the result nicely
if [[ "$CMUX_AVAILABLE" == "true" ]]; then
  $CMUX_EXE display-message "LLM Synthesis Complete."
  RESULT_FILE="$TMP_DIR/synthesis_result.md"
  {
    echo "# LLM Synthesis Result"
    echo "\n## Question"
    cat "$QUESTION_FILE"
    echo "\n## Synthesized Answer"
    echo "$FINAL_RESULT"
  } > "$RESULT_FILE"
  $CMUX_EXE markdown "$RESULT_FILE" &
fi

# Cleanup
cmux_status "Complete"
cmux_progress 1.0 "Done"
# Temp folder automatically cleaned up via EXIT trap
