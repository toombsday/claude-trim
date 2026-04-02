#!/usr/bin/env bash
# trim-file.sh
# PostToolUse hook: strips trailing whitespace from every file Claude Code writes or edits.
# Receives a JSON payload on stdin describing the tool use event.
#
# Supports: Write, Edit, MultiEdit
# Skips:    Binary files, files > 10 MB, files in .git/
#
# Exit codes:
#   0  — success (hook ran cleanly; Claude continues normally)
#   1  — non-fatal warning (logged, Claude continues)

set -euo pipefail

# ── Read stdin ──────────────────────────────────────────────────────────────
INPUT=$(cat)

# ── Honour the disable flag ──────────────────────────────────────────────────
[[ -f ".claude-trim-disabled" ]] && exit 0

# ── Extract file paths from the tool input ───────────────────────────────────
# Write/Edit provide tool_input.file_path; MultiEdit provides tool_input.edits[].file_path
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')

case "$TOOL" in
  Write|Edit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    FILES=("$FILE_PATH")
    ;;
  MultiEdit)
    FILES=()
    while IFS= read -r line; do
      FILES+=("$line")
    done < <(echo "$INPUT" | jq -r '.tool_input.edits[].file_path // empty' | sort -u)
    ;;
  *)
    exit 0
    ;;
esac

# ── Process each file ────────────────────────────────────────────────────────
TRIMMED=0
SKIPPED=0

trim_file() {
  local file="$1"

  # Guard: must be a non-empty path
  [[ -z "$file" ]] && return

  # Guard: file must exist
  [[ -f "$file" ]] || return

  # Guard: skip .git internals
  if [[ "$file" == *"/.git/"* ]]; then
    ((SKIPPED++)) || true
    return
  fi

  # Guard: skip files larger than 10 MB
  local size
  size=$(wc -c < "$file" 2>/dev/null || echo 0)
  if (( size > 10485760 )); then
    ((SKIPPED++)) || true
    return
  fi

  # Guard: skip binary files (check via file command)
  if ! file "$file" 2>/dev/null | grep -q "text"; then
    ((SKIPPED++)) || true
    return
  fi

  # Trim trailing whitespace on every line.
  # Use a platform-safe in-place sed:
  #   macOS sed requires a backup extension; we use '' for no backup.
  #   GNU sed accepts -i without an argument.
  if sed --version &>/dev/null; then
    # GNU sed
    sed -i 's/[[:space:]]*$//' "$file"
  else
    # BSD/macOS sed
    sed -i '' 's/[[:space:]]*$//' "$file"
  fi

  ((TRIMMED++)) || true
}

for f in "${FILES[@]}"; do
  trim_file "$f"
done

# ── Optional: log summary to stderr (visible with Ctrl+O in Claude Code) ─────
if (( TRIMMED > 0 )); then
  echo "[claude-trim] Trimmed trailing whitespace in $TRIMMED file(s)." >&2
fi
if (( SKIPPED > 0 )); then
  echo "[claude-trim] Skipped $SKIPPED file(s) (binary, oversized, or .git)." >&2
fi

exit 0
