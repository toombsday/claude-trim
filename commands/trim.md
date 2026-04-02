---
name: trim
description: >
  Clean Claude Code output of trailing whitespace and ANSI escape sequences.
  Runs the trim-output.sh script directly. Use /trim for clipboard, /trim --dry
  to preview, or /trim <file> to clean a file in-place.
---

Run the following bash command based on what the user wants:

**Clean clipboard (default — most common use):**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/trim-output.sh --clipboard
```

**Preview clipboard without overwriting:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/trim-output.sh --clipboard --dry
```

**Clean a specific file in-place:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/trim-output.sh <file>
```

If the user typed `/trim` with no arguments, run the clipboard command.
If they typed `/trim --dry`, run the clipboard dry-run command.
If they typed `/trim <filename>`, run the file command with that filename.

After running, confirm what was done in one sentence.
