#!/usr/bin/env bash
#
# run-tests.sh — dependency-free tests (no bats). Stubs `agy` on PATH and asserts
# agy-delegate.sh behavior + measure-session.py accounting.
#
#   bash tests/run-tests.sh
#
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DELEGATE="$ROOT/scripts/agy-delegate.sh"
MEASURE="$ROOT/scripts/measure-session.py"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

# --- stub `agy` on PATH; behavior controlled by $STUB_MODE -------------------
mkdir -p "$TMP/bin"
cat > "$TMP/bin/agy" <<'STUB'
#!/usr/bin/env bash
[ -n "${STUB_SLEEP:-}" ] && sleep "$STUB_SLEEP"
case "${STUB_MODE:-text}" in
  empty) exit 0 ;;                  # no stdout -> wrapper should exit 3
  fail)  echo "boom" >&2; exit 7 ;; # nonzero  -> wrapper should exit 2
  args)  printf '%s\n' "$*" ;;      # echo args for assertions
  *)     echo "STUB_OK" ;;
esac
STUB
chmod +x "$TMP/bin/agy"
export PATH="$TMP/bin:$PATH"

check() { # desc  expected_rc  actual_rc  [substr]  [actual_out]
  local desc="$1" erc="$2" arc="$3" sub="${4:-}" out="${5:-}"
  if [ "$arc" != "$erc" ]; then echo "FAIL: $desc (rc want $erc got $arc)"; FAIL=$((FAIL+1)); return; fi
  if [ -n "$sub" ] && ! printf '%s' "$out" | grep -qF -- "$sub"; then
    echo "FAIL: $desc (missing '$sub' in output)"; FAIL=$((FAIL+1)); return; fi
  echo "ok: $desc"; PASS=$((PASS+1))
}

echo "== agy-delegate.sh =="

out=$(STUB_MODE=text "$DELEGATE" "hello" 2>/dev/null); rc=$?
check "normal text passes through" 0 "$rc" "STUB_OK" "$out"

out=$(STUB_MODE=empty "$DELEGATE" "hello" 2>/dev/null); rc=$?
check "empty agy output -> exit 3" 3 "$rc"

out=$(STUB_MODE=fail "$DELEGATE" "hello" 2>/dev/null); rc=$?
check "agy failure -> exit 2" 2 "$rc"

out=$("$DELEGATE" 2>/dev/null); rc=$?
check "no prompt -> exit 1" 1 "$rc"

out=$("$DELEGATE" --bogus "hi" 2>/dev/null); rc=$?
check "unknown option -> exit 1" 1 "$rc"

out=$("$DELEGATE" --tier 2>/dev/null); rc=$?
check "option without value -> exit 1 (friendly)" 1 "$rc"

out=$(STUB_MODE=args "$DELEGATE" --tier flash "hi" 2>/dev/null); rc=$?
check "flash tier -> correct model string" 0 "$rc" "Gemini 3.5 Flash (High)" "$out"

out=$(STUB_MODE=args "$DELEGATE" --tier pro "hi" 2>/dev/null); rc=$?
check "pro tier -> correct model string" 0 "$rc" "Gemini 3.1 Pro (High)" "$out"

out=$(printf 'piped prompt' | STUB_MODE=args "$DELEGATE" - 2>/dev/null); rc=$?
check "stdin prompt (-) read" 0 "$rc" "-p" "$out"

echo "== measure-session.py =="
SESS="$TMP/sess.jsonl"
cat > "$SESS" <<'JSONL'
{"message":{"role":"user","content":"hi"}}
{"message":{"role":"assistant","usage":{"output_tokens":10,"input_tokens":2,"cache_read_input_tokens":100},"content":[{"type":"tool_use","name":"Bash"}]}}
{"message":{"role":"assistant","usage":{"output_tokens":5}}}
JSONL
out=$(python3 "$MEASURE" "$SESS" "T" 2>/dev/null); rc=$?
# output=15 input=2 cache_read=100 -> weighted = 15*5 + 2 + 100*0.1 = 87 ; total=117 ; turns=2
check "measure: total tokens" 0 "$rc" "TOTAL tokens   117" "$out"
check "measure: cost-weighted" 0 "$rc" "COST-WEIGHTED  87" "$out"
check "measure: turns" 0 "$rc" "turns          2" "$out"
check "measure: tool count" 0 "$rc" "'Bash': 1" "$out"

out=$(python3 "$MEASURE" /no/such/file 2>/dev/null); rc=$?
check "measure: missing file -> exit 1" 1 "$rc"

echo "== agy-job.sh (background jobs) =="
export ANTIGRAVITY_JOBS="$TMP/jobs"
JOB="$ROOT/scripts/agy-job.sh"

id=$(STUB_MODE=text STUB_SLEEP=1 "$JOB" start --tier flash "demo task" 2>/dev/null); rc=$?
check "job start -> exit 0" 0 "$rc"
[ -n "$id" ] && { echo "ok: job start returns id ($id)"; PASS=$((PASS+1)); } || { echo "FAIL: job start id empty"; FAIL=$((FAIL+1)); }

out=$("$JOB" status "$id" 2>/dev/null); rc=$?
check "job status shows running" 0 "$rc" "running" "$out"

for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  printf '%s' "$("$JOB" status "$id" 2>/dev/null)" | grep -q "state=done" && break
  sleep 0.5
done
out=$("$JOB" result "$id" 2>/dev/null); rc=$?
check "job result -> output when done" 0 "$rc" "STUB_OK" "$out"

cid=$(STUB_MODE=text STUB_SLEEP=10 "$JOB" start --tier flash "long task" 2>/dev/null)
sleep 0.5; "$JOB" cancel "$cid" >/dev/null 2>&1; sleep 0.5
out=$("$JOB" status "$cid" 2>/dev/null)
if printf '%s' "$out" | grep -q "state=running"; then
  echo "FAIL: job cancel (still running)"; FAIL=$((FAIL+1))
else echo "ok: job cancel stops it"; PASS=$((PASS+1)); fi

echo ""
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
