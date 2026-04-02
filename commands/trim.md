---
name: trim
description: >
  Clean Claude Code output of trailing whitespace and ANSI escape sequences.
  Use /trim --clipboard to clean your clipboard in-place, or pipe output through
  the companion script. Addresses the Ink renderer whitespace padding bug
  (github.com/anthropics/claude-code/issues/23014).
---

# trim

Cleans Claude Code TUI output of trailing whitespace, ANSI escape sequences,
and excessive blank lines.

## Usage

```bash
# Clean your clipboard (read, trim, write back)
${CLAUDE_PLUGIN_ROOT}/scripts/trim-output.sh --clipboard

# Preview cleaned clipboard without overwriting
${CLAUDE_PLUGIN_ROOT}/scripts/trim-output.sh --clipboard --dry

# Pipe claude output through the cleaner
claude -p "explain grep" | ${CLAUDE_PLUGIN_ROOT}/scripts/trim-output.sh

# Clean a specific file in-place
${CLAUDE_PLUGIN_ROOT}/scripts/trim-output.sh path/to/file.txt
```

## What it removes

- Trailing spaces padded to terminal width by the Ink renderer
- ANSI/VT100 escape codes (`\x1b[...m`, reverse video `\x1b[7m`, etc.)
- Runs of 3+ consecutive blank lines (collapsed to 2)

## Why this exists

Claude Code's TUI uses the Ink renderer which pads every screen line with
actual space characters to the terminal width. This means selected+copied
text contains hundreds of invisible trailing spaces per line, making it
painful to paste into editors, SSH sessions, or scripts.

This is a tracked upstream bug. This plugin is a workaround until it's fixed
in Claude Code itself.

**Reference:** https://github.com/anthropics/claude-code/issues/23014
