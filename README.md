# claude-trim

> A Claude Code plugin that strips trailing whitespace from files Claude writes, and provides tools to clean TUI output before you paste it.

[![npm version](https://img.shields.io/npm/v/claude-trim)](https://www.npmjs.com/package/claude-trim)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## The problem

Claude Code's TUI uses the [Ink](https://github.com/vadimdemedes/ink) renderer, which pads every screen line with actual space characters to the full terminal width. When you select and copy output, you get hundreds of invisible trailing spaces per line — making the paste unusable in editors, SSH sessions, or scripts without manual cleanup.

This is a [tracked upstream bug](https://github.com/anthropics/claude-code/issues/23014). This plugin is a workaround until it's fixed in Claude Code itself.

There are two related problems this plugin addresses:

| Problem | What claude-trim does |
|---|---|
| **Files Claude writes contain trailing whitespace** | `PostToolUse` hook runs `sed` to strip it after every Write/Edit |
| **Copied TUI output has trailing spaces + ANSI codes** | `scripts/trim-output.sh` cleans clipboard or piped text |

---

## Installation

### As a Claude Code plugin (recommended)

**From npm** (once published):
```bash
/plugin install claude-trim
```

**From GitHub directly:**
```bash
# Step 1: add the repo as a marketplace source (one-time)
/plugin marketplace add toombsday/claude-trim

# Step 2: install the plugin
/plugin install claude-trim@toombsday-claude-trim
```

### Local development / testing

```bash
git clone https://github.com/toombsday/claude-trim.git
cd claude-trim
chmod +x scripts/*.sh

# Start Claude Code with the plugin loaded from the current directory
claude --plugin-dir .
```

### Symlink the cleaner script to your PATH (optional but handy)

```bash
ln -s "$(pwd)/scripts/trim-output.sh" /usr/local/bin/claude-trim
```

---

## Features

### 1. Automatic file trimming (PostToolUse hook)

Every time Claude Code writes, edits, or multi-edits a file, the hook strips trailing whitespace automatically. No configuration needed.

```
[claude-trim] Trimmed trailing whitespace in 3 file(s).
```

Press **Ctrl+O** in Claude Code to see hook output.

**Safe by default:**
- Skips binary files (detected via null byte check)
- Skips files > 10 MB
- Skips `.git/` internals
- Works on both macOS (`BSD sed`) and Linux (`GNU sed`)

### 2. Clipboard cleaner (`trim-output.sh --clipboard`)

Cleans your clipboard of trailing spaces and ANSI escape sequences after you copy from the Claude Code TUI:

```bash
# After copying Claude Code output:
claude-trim --clipboard
# Now paste — no trailing spaces, no escape codes.

# Preview without overwriting clipboard:
claude-trim --clipboard --dry
```

**Supported clipboard backends** (auto-detected):
- macOS: `pbpaste`/`pbcopy`
- Linux X11: `xclip` or `xsel`
- Linux Wayland: `wl-paste`/`wl-copy`
- WSL/Windows: `clip.exe` / PowerShell

### 3. Pipe mode

```bash
# Pipe claude output directly through the cleaner
claude -p "explain grep" | claude-trim

# Clean a file in-place
claude-trim path/to/output.txt
```

### 4. `/trim` slash command

Inside Claude Code, run `/trim` for usage instructions and quick access to the scripts.

---

## Why can't this intercept the copy event directly?

Claude Code plugins work via lifecycle hooks (`PreToolUse`, `PostToolUse`, `SessionStart`, etc.) — these fire on Claude's actions, not on terminal clipboard operations. The clipboard copy event happens at the terminal emulator level, which is outside Claude Code's extension API.

The most complete fix is for Anthropic to change the Ink renderer to use `\x1b[K` (erase to end of line) instead of padding with spaces, as every other terminal UI does. Until then, this plugin gives you a one-command workaround.

**Upstream issue:** [anthropics/claude-code#23014](https://github.com/anthropics/claude-code/issues/23014) — consider upvoting it!

---

## Configuration

No configuration is required. The `PostToolUse` hook runs automatically.

To disable the hook temporarily without uninstalling the plugin, you can set a flag file:

```bash
# Disable
touch .claude-trim-disabled

# Re-enable
rm .claude-trim-disabled
```

> **Note:** Support for a `.claude-trim-disabled` flag is included in `trim-file.sh` — it checks for this file before running.

---

## Development

```bash
# Run the test suite
npm test

# Test the file trimmer manually
echo "hello world   " > /tmp/test.txt
bash scripts/trim-file.sh <<< '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt"}}'
cat -A /tmp/test.txt  # should show no trailing $ artifacts

# Test the output cleaner
echo -e "hello\x1b[7m world \x1b[27m   " | bash scripts/trim-output.sh
```

### Plugin structure

```
claude-trim/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest (name, version, hooks, commands)
├── hooks/
│   └── hooks.json        # PostToolUse hook registration
├── commands/
│   └── trim.md           # /trim slash command definition
├── scripts/
│   ├── trim-file.sh      # Hook script: strips whitespace from written files
│   └── trim-output.sh    # Standalone clipboard/pipe cleaner
├── test/
│   └── run.sh            # Test suite (bash test/run.sh)
├── package.json          # npm package manifest
├── .npmignore            # Excludes test/ and dev files from npm publish
├── LICENSE
└── README.md
```

---

## Publishing to npm

```bash
# Bump version in package.json, then:
npm publish --access public
```

After publishing, users can install via:

```bash
/plugin install claude-trim
```

---

## Contributing

PRs welcome. Please open an issue first for significant changes.

Areas that would improve this plugin:
- Windows native clipboard support improvements
- A `--watch` mode that polls the clipboard and auto-cleans
- Shell function installer (add `claude-trim --clipboard` to your shell's copy shortcut)

---

## Related

- [cleanclode.com](https://cleanclode.com/) — browser-based Claude Code output cleaner
- [anthropics/claude-code#23014](https://github.com/anthropics/claude-code/issues/23014) — upstream Ink renderer bug
- [anthropics/claude-code#22389](https://github.com/anthropics/claude-code/issues/22389) — upstream trailing spaces issue

---

## License

MIT © toombsday
