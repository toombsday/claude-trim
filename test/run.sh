#!/usr/bin/env bash
# test/run.sh — Basic test suite for claude-trim

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass() { echo "  ✓ $1"; ((PASS++)) || true; }
fail() { echo "  ✗ $1"; ((FAIL++)) || true; }

echo ""
echo "claude-trim test suite"
echo "──────────────────────"

# ── Test: trim-file.sh strips trailing spaces ────────────────────────────────
echo ""
echo "trim-file.sh"

TMP=$(mktemp)
printf 'hello world   \nno trailing\n  indented   \n' > "$TMP"
PAYLOAD=$(jq -n --arg p "$TMP" '{"tool_name":"Write","tool_input":{"file_path":$p}}')
echo "$PAYLOAD" | bash "$SCRIPT_DIR/scripts/trim-file.sh"

if grep -q ' $' "$TMP"; then
  fail "trailing spaces were NOT removed"
else
  pass "trailing spaces removed from Write output"
fi
rm -f "$TMP"

# ── Test: trim-file.sh handles MultiEdit ────────────────────────────────────
TMP1=$(mktemp); TMP2=$(mktemp)
printf 'line one   \n' > "$TMP1"
printf 'line two   \n' > "$TMP2"
PAYLOAD=$(jq -n --arg p1 "$TMP1" --arg p2 "$TMP2" \
  '{"tool_name":"MultiEdit","tool_input":{"edits":[{"file_path":$p1},{"file_path":$p2}]}}')
echo "$PAYLOAD" | bash "$SCRIPT_DIR/scripts/trim-file.sh"

if grep -q ' $' "$TMP1" || grep -q ' $' "$TMP2"; then
  fail "MultiEdit: trailing spaces NOT removed from one or more files"
else
  pass "MultiEdit: trailing spaces removed from both files"
fi
rm -f "$TMP1" "$TMP2"

# ── Test: trim-file.sh skips unknown tool ───────────────────────────────────
PAYLOAD='{"tool_name":"Read","tool_input":{"file_path":"/tmp/noop"}}'
echo "$PAYLOAD" | bash "$SCRIPT_DIR/scripts/trim-file.sh" && pass "non-Write/Edit tool exits 0 cleanly" || fail "non-Write/Edit tool failed"

# ── Test: trim-output.sh strips ANSI codes ──────────────────────────────────
echo ""
echo "trim-output.sh (pipe mode)"

RESULT=$(printf 'hello\x1b[7m world \x1b[27m   \n' | bash "$SCRIPT_DIR/scripts/trim-output.sh")
if [[ "$RESULT" == "hello world" ]]; then
  pass "ANSI escape codes stripped"
else
  fail "ANSI codes not stripped: $(echo "$RESULT" | cat -A)"
fi

# ── Test: trim-output.sh strips trailing spaces ──────────────────────────────
RESULT=$(printf 'no ansi here         \n' | bash "$SCRIPT_DIR/scripts/trim-output.sh")
if [[ "$RESULT" == "no ansi here" ]]; then
  pass "trailing spaces stripped in pipe mode"
else
  fail "trailing spaces not stripped: '$(echo "$RESULT" | cat -A)'"
fi

# ── Test: trim-output.sh collapses excessive blank lines ─────────────────────
INPUT=$(printf 'line one\n\n\n\n\nline two\n')
RESULT=$(echo "$INPUT" | bash "$SCRIPT_DIR/scripts/trim-output.sh")
BLANK_COUNT=$(echo "$RESULT" | grep -c '^$' || true)
if (( BLANK_COUNT <= 2 )); then
  pass "excessive blank lines collapsed (got $BLANK_COUNT blank lines)"
else
  fail "blank lines NOT collapsed (got $BLANK_COUNT)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "──────────────────────"
echo "Results: $PASS passed, $FAIL failed"
echo ""

(( FAIL == 0 )) && exit 0 || exit 1
