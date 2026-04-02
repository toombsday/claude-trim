#!/usr/bin/env bash
# trim-output.sh
# Standalone clipboard/pipe cleaner for Claude Code TUI output.
#
# The Claude Code Ink renderer pads every screen line with actual space
# characters to the terminal width (see github.com/anthropics/claude-code/issues/23014).
# This script removes those artifacts.
#
# Usage (pipe):
#   claude -p "explain grep" | trim-output.sh
#
# Usage (clipboard — interactive copy workaround):
#   trim-output.sh --clipboard        # reads clipboard, writes back cleaned
#   trim-output.sh --clipboard --dry  # reads clipboard, prints to stdout
#
# Usage (file):
#   trim-output.sh path/to/file.txt   # cleans file in-place
#
# Symlink into your PATH for convenience:
#   ln -s /path/to/scripts/trim-output.sh /usr/local/bin/claude-trim

set -euo pipefail

CLIPBOARD_MODE=false
DRY_RUN=false
FILE_ARG=""

# ── Parse args ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clipboard|-c) CLIPBOARD_MODE=true ;;
    --dry|-d)       DRY_RUN=true ;;
    --help|-h)
      echo "Usage: trim-output.sh [--clipboard] [--dry] [file]"
      echo ""
      echo "Options:"
      echo "  --clipboard, -c   Read from clipboard instead of stdin"
      echo "  --dry,       -d   Print result to stdout without writing back"
      echo "  file              Clean a file in-place instead of stdin/clipboard"
      echo ""
      echo "Without options: reads stdin, writes cleaned text to stdout."
      exit 0
      ;;
    -*) echo "[claude-trim] Unknown option: $1" >&2; exit 1 ;;
    *)  FILE_ARG="$1" ;;
  esac
  shift
done

# ── Core cleaning function ───────────────────────────────────────────────────
clean_text() {
  # Strip ANSI/VT100 escape sequences (colors, cursor movement, reverse video)
  # Then strip trailing whitespace from every line
  # Then collapse 3+ consecutive blank lines down to 2
  sed \
    -e 's/\x1b\[[0-9;]*[mGKHFABCDJhlisusr]//g' \
    -e 's/\x1b\[[0-9;]*m//g' \
    -e 's/\x1b(B//g' \
    -e 's/[[:space:]]*$//' \
  | awk '
    /^$/ { blank++; if (blank <= 2) print; next }
    { blank=0; print }
  '
}

# ── Detect clipboard tool ────────────────────────────────────────────────────
clipboard_read() {
  if command -v pbpaste &>/dev/null; then
    pbpaste
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard -o
  elif command -v xsel &>/dev/null; then
    xsel --clipboard --output
  elif command -v wl-paste &>/dev/null; then
    wl-paste
  elif command -v clip.exe &>/dev/null; then
    # WSL / Windows
    powershell.exe -command "Get-Clipboard"
  else
    echo "[claude-trim] No clipboard tool found. Install pbpaste (macOS), xclip/xsel (Linux), or wl-clipboard (Wayland)." >&2
    exit 1
  fi
}

clipboard_write() {
  if command -v pbcopy &>/dev/null; then
    pbcopy
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard -i
  elif command -v xsel &>/dev/null; then
    xsel --clipboard --input
  elif command -v wl-copy &>/dev/null; then
    wl-copy
  elif command -v clip.exe &>/dev/null; then
    clip.exe
  else
    echo "[claude-trim] No clipboard tool found for writing." >&2
    exit 1
  fi
}

# ── Run ──────────────────────────────────────────────────────────────────────
if [[ -n "$FILE_ARG" ]]; then
  # File mode: clean in-place
  if [[ ! -f "$FILE_ARG" ]]; then
    echo "[claude-trim] File not found: $FILE_ARG" >&2
    exit 1
  fi
  CLEANED=$(clean_text < "$FILE_ARG")
  if $DRY_RUN; then
    echo "$CLEANED"
  else
    echo "$CLEANED" > "$FILE_ARG"
    echo "[claude-trim] Cleaned: $FILE_ARG" >&2
  fi

elif $CLIPBOARD_MODE; then
  # Clipboard mode
  CLEANED=$(clipboard_read | clean_text)
  if $DRY_RUN; then
    echo "$CLEANED"
  else
    echo "$CLEANED" | clipboard_write
    echo "[claude-trim] Clipboard cleaned." >&2
  fi

else
  # Pipe mode: stdin → stdout
  clean_text
fi
