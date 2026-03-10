# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform scripts that batch-update installed AI/dev CLI tools. Two parallel implementations:

- `dev-cli-updater.bat` — Windows (cmd/PowerShell)
- `dev-cli-updater.sh` — macOS/Linux (bash)

Scripts are **update-only**: they never install tools that aren't already present.

## Running the Scripts

```powershell
# Windows (PowerShell)
.\dev-cli-updater.bat

# macOS / Linux
chmod +x dev-cli-updater.sh && ./dev-cli-updater.sh
```

No build step, no test suite. Verification is manual — run on the target platform and check each status scenario.

## Architecture

Both scripts follow the same per-tool flow: check command exists -> get current version -> detect update -> update if available -> track result status. Each tool's outcome is one of 4 flags (`SUCCESS_*`, `SKIPPED_*`, `DEPS_*`, `FAILED_*`), summarized at the end via `PrintStatus` / `print_status`.

### .bat structure
- Subroutines via `call :Label` pattern: `:UpdateGitHubCLI`, `:UpdateClaude`, `:CheckAndUpdate` (npm generic), `:PrintStatus`
- `chcp 65001` for UTF-8/emoji; `setlocal enabledelayedexpansion` for variable handling
- `CheckAndUpdate` takes variable names as args and sets them via `set "%_VAR%=1"`
- Parenthesized blocks in cmd require escaping `(` `)` in echo statements: `^(` `^)`

### .sh structure
- Functions: `update_github_cli`, `check_and_update` (npm generic), `print_status`
- `update_github_cli` uses `eval` to set caller variables by name (safe — args are internal only, never user input)
- Cursor Agent section is inline (not a function) and uses output-parsing with version-comparison fallback
- `apt_prefix` variable avoids sudo/non-sudo code duplication in apt branch

## Supported Tools and Update Methods

| Tool | .bat method | .sh method |
|------|-------------|------------|
| GitHub CLI (`gh`) | `winget list --upgrade-available` / `winget upgrade` | `brew outdated gh` (output, not exit code) / `apt list --upgradable` |
| Claude Code (`claude`) | `claude update` + version comparison | same |
| Codex CLI (`codex`) | `npm outdated -g @openai/codex` / `npm install -g` | same |
| Gemini CLI (`gemini`) | `npm outdated -g @google/gemini-cli` / `npm install -g` | same |
| Cursor Agent (`cursor-agent`) | **not implemented** (intentional) | `cursor-agent update` + output parsing / version fallback |

## Key Constraints

- **Keep .bat and .sh functionally aligned.** Same tools, same behavior, same summary format — except: .bat intentionally omits Cursor Agent (no WSL invocation from .bat).
- **Claude Code must not require npm.** Use `claude update` (built-in updater). Don't fall back to `npm install -g`.
- **Claude Code .bat: use `cmd /c`, not `call`.** `claude` resolves to a `.cmd` wrapper; `call claude` inlines its execution, which corrupts the parent batch parser state. Always use `cmd /c claude update` to run in a subprocess.
- **brew outdated detection:** Check output content (`[ -n "$brew_outdated" ]`), not exit code — `brew outdated` returns 0 regardless.
- **npm outdated detection:** Empty output means up-to-date.
- **Package names are exact:** `@openai/codex`, `@google/gemini-cli`.
- **apt flow requires `apt update` first** for accurate detection. GitHub CLI must come from the official apt repository.
- **Non-interactive flags** (`--silent`, `--accept-source-agreements`, `-y`) wherever possible — but don't suppress error output needed for debugging.

## .bat Gotchas

- `echo` inside `if (...) (...)` blocks: literal parentheses must be escaped as `^(` `^)` or the block terminates early.
- `where` replaces `command -v`; `errorlevel 1` replaces `$?`.
- `for /f` loops with backticks or pipes need `^|` and `2^>nul` escaping.
- `cmd /c <tool> --version` is used after update to get fresh output (avoids cached PATH).
- `call npm install ...` — `call` is needed for npm.cmd to return control. But for `claude`, use `cmd /c` instead (see Key Constraints).

## Testing Checklist

Since there are no automated tests, verify manually on the target platform:

- "already up-to-date" and "update available" scenarios
- Emoji rendering (Windows: depends on `chcp 65001` and terminal support)
- Missing tool handled gracefully (shows "Not installed")
- Missing dependency (npm/winget/brew/apt) shows "Skipped (missing dependency)"
- Failed update shows "Failed"
- Summary table matches actual results
- Run `bash -n dev-cli-updater.sh` after shell changes as a syntax check

## Coding Style

- Shell: `lower_snake_case` for functions, `UPPER_SNAKE_CASE` for state variables
- Batch: PascalCase labels (`:UpdateGitHubCLI`), `UPPER_SNAKE_CASE` for state variables
- 4 spaces indentation in both scripts
- Keep status messages consistent with README summary labels

## Commit Conventions

Follow Conventional Commits as seen in history: `fix(bat):`, `fix(sh):`, `docs(readme):`, `chore(gitattributes):`. Keep subject concise and scoped. If output text changes, include a sample of the new console messages in the PR description.

## References

- Claude Code setup/update: `https://docs.anthropic.com/en/docs/claude-code/setup`
- Cursor CLI: `https://docs.cursor.com/ja/cli/installation`
- Codex CLI: `https://developers.openai.com/codex/quickstart/`
- WinGet: `https://learn.microsoft.com/en-us/windows/package-manager/winget/list`
- GitHub CLI Linux install: `https://raw.githubusercontent.com/cli/cli/trunk/docs/install_linux.md`
