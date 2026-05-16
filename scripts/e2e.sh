#!/usr/bin/env bash
# End-to-end smoke walk against a running backend.
#
# Assumes:
#   - backend started: `cd backend && uv run uvicorn app.main:app --port 8000`
#   - Ollama running with a model: `ollama pull qwen2.5:7b`
#   - APP_ENV=dev so /dev/* endpoints are mounted
#
# Prints each step's status + elapsed time. Exits non-zero on any failure.

set -euo pipefail

BASE="${BASE_URL:-http://localhost:8000}"

# Lightweight colored output, falling back when not a TTY.
if [[ -t 1 ]]; then
  G=$'\033[32m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'
else
  G=''; R=''; D=''; N=''
fi

step() {
  local name="$1"; shift
  local t0 t1
  t0=$(python3 -c 'import time; print(time.time())')
  if "$@"; then
    t1=$(python3 -c 'import time; print(time.time())')
    printf "%s✓%s %s %s(%.2fs)%s\n" "$G" "$N" "$name" "$D" "$(python3 -c "print($t1 - $t0)")" "$N"
  else
    t1=$(python3 -c 'import time; print(time.time())')
    printf "%s✗%s %s %s(%.2fs)%s\n" "$R" "$N" "$name" "$D" "$(python3 -c "print($t1 - $t0)")" "$N"
    exit 1
  fi
}

pp() { python3 -m json.tool 2>/dev/null || cat; }

# Make a request and assert HTTP 2xx. Echoes the body on success, dumps it on
# stderr and returns 1 on failure — set -e is unreliable inside $(…), so we
# check explicitly.
req() {
  local method="$1" path="$2"; shift 2
  local body status
  body=$(curl -sS -o /tmp/e2e_body -w '%{http_code}' -X "$method" "$BASE$path" "$@")
  status=$body
  body=$(cat /tmp/e2e_body)
  if [[ ! "$status" =~ ^2 ]]; then
    echo "  HTTP $status: $body" >&2
    return 1
  fi
  echo "$body"
}

j() { python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"; }

check_health() {
  local r; r=$(req GET /health) || return 1
  [[ "$r" == '{"ok":true}' ]] || { echo "  unexpected: $r"; return 1; }
}

seed_user() {
  local r; r=$(req POST /dev/seed-user) || return 1
  USER_ID=$(echo "$r" | j "d['user_id']")
  echo "  user_id=$USER_ID"
}

get_assessment() {
  local r; r=$(req GET /onboarding/assessment) || return 1
  echo "  $(echo "$r" | j "f\"{len(d['questions'])} questions\"")"
}

submit_assessment() {
  local r; r=$(req POST /onboarding/assessment \
    -H "X-User-Id: $USER_ID" -H "Content-Type: application/json" \
    -d '{"answers":{"a1":0,"a2":0,"a3":1},"background_summary":"backend engineer, 5y python","preferred_style":"code"}') || return 1
  echo "  $(echo "$r" | j "d.get('summary','')")"
}

get_quest() {
  local r; r=$(req GET /quest/today -H "X-User-Id: $USER_ID") || return 1
  QUEST_ID=$(echo "$r" | j "d['id']")
  echo "  quest_id=$QUEST_ID"
  echo "  concept=$(echo "$r" | j "d['concept_id']")"
  echo "  explanation: $(echo "$r" | j "(d['explanation'][:120]+'…') if len(d['explanation'])>120 else d['explanation']")"
}

submit_answer() {
  local r; r=$(req POST "/quest/$QUEST_ID/answer" \
    -H "X-User-Id: $USER_ID" -H "Content-Type: application/json" \
    -d '{"question_index":0,"choice_index":0}') || return 1
  echo "  is_correct=$(echo "$r" | j "d['is_correct']") / correct_index=$(echo "$r" | j "d['correct_index']")"
}

tutor_chat() {
  local r; r=$(req POST /tutor/chat \
    -H "X-User-Id: $USER_ID" -H "Content-Type: application/json" \
    -d '{"history":[],"message":"我刚开始学 AI，今天的概念能再简单说一下吗？"}') || return 1
  echo "  reply: $(echo "$r" | j "(d['reply'][:200]+'…') if len(d['reply'])>200 else d['reply']")"
}

memory_snapshot() {
  local r; r=$(req GET /memory -H "X-User-Id: $USER_ID") || return 1
  echo "  mastery count=$(echo "$r" | j "len(d['items'])")"
  echo "  weak=$(echo "$r" | j "d['weak']")"
}

echo "→ base url: $BASE"

step "health"             check_health
step "seed user"          seed_user
step "GET assessment"     get_assessment
step "POST assessment"    submit_assessment
step "GET today quest"    get_quest        # first Ollama call lives here
step "POST quest answer"  submit_answer
step "POST tutor chat"    tutor_chat
step "GET memory"         memory_snapshot

echo
echo "${G}All steps passed.${N}"
