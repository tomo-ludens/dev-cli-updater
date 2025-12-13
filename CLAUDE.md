# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a simple cross-platform script collection for batch-updating AI and developer CLI tools. The project consists of two parallel implementations:
- `dev-cli-updater.bat` - Windows version (cmd/PowerShell)
- `dev-cli-updater.sh` - macOS/Linux version (bash)

Both scripts check for updates and update the same set of CLI tools, but use platform-appropriate package managers.

## Supported Tools

The scripts update these CLI tools:
- **GitHub CLI** (`gh`) - Uses winget (Windows), brew (macOS), or apt (Debian/Ubuntu/WSL)
- **Claude Code** (`claude`) - Uses official install scripts from claude.ai
- **Codex CLI** (`codex`) - Uses npm global install from @openai/codex
- **Gemini CLI** (`gemini`) - Uses npm global install from @google/gemini-cli
- **Cursor Agent** (`cursor-agent`) - Uses built-in update command (Linux/macOS only)

## Script Architecture

### Common Pattern
Both scripts follow the same flow:
1. Check if the tool command exists
2. Get current version
3. Check for updates using platform-appropriate methods
4. Only update if newer version available (skip if up-to-date)
5. Track success/skipped status for summary

### Windows (.bat) Specifics
- Uses `chcp 65001` for UTF-8 support (emoji rendering)
- Uses subroutines (`:UpdateGitHubCLI`, `:UpdateClaude`, `:CheckAndUpdate`, `:PrintStatus`)
- `CheckAndUpdate` is a generic function for npm-based tools (Codex, Gemini)
- GitHub CLI update uses `winget list --upgrade-available` to detect updates
- Claude Code update checks npm registry version vs installed version
- Uses delayed expansion for variable handling (`setlocal enabledelayedexpansion`)

### macOS/Linux (.sh) Specifics
- Uses bash functions (`check_and_update`, `update_github_cli`, `print_status`)
- `check_and_update` is a generic function for npm-based tools (Codex, Gemini)
- GitHub CLI update auto-detects package manager (brew or apt)
- Cursor Agent is only supported on Linux/macOS (not in Windows version)
- Uses `eval` to set success/skipped flags by reference

## Update Logic Details

### GitHub CLI
- **Windows**: Uses `winget list --id GitHub.cli --upgrade-available` to detect if update exists, then `winget upgrade`
- **macOS**: Uses `brew outdated gh` check, then `brew upgrade gh`
- **Linux/WSL**: Uses `apt list --upgradable` grep for `gh/`, then `apt install -y gh`
- Requires GitHub CLI to be installed via the specified package manager

### Claude Code
- Compares `claude --version` output with `npm view @anthropic-ai/claude-code version`
- Updates via official install script (PowerShell or bash) from claude.ai domain
- Does NOT use npm update (uses official installer instead)

### npm-based Tools (Codex, Gemini)
- Uses `npm outdated -g <package>` to check for updates
- Empty output means up-to-date
- Updates via `npm install -g <package>@latest`

### Cursor Agent (Linux/macOS only)
- Runs `cursor-agent update` command
- Parses output for keywords like "already up to date", "updated", etc.
- Falls back to comparing version before/after if output is unclear

## Requirements

- `npm` must be in PATH (for Claude Code, Codex, Gemini version checks/updates)
- Platform-specific package managers:
  - Windows: `winget` for GitHub CLI
  - macOS: `brew` for GitHub CLI
  - Debian/Ubuntu/WSL: `apt` with GitHub official repository configured
- GitHub CLI must be installed from the official package manager (not community packages)

## Testing

When modifying scripts:
- Test both "already up-to-date" and "update available" scenarios
- Verify emoji rendering works correctly
- Check that "Not installed" tools are handled gracefully
- Ensure summary table shows correct status for each tool
- Test on actual platform (don't assume cross-platform compatibility)

## Important Notes

- The two scripts must be kept in sync functionally (same tools, same behavior)
- Cursor Agent is intentionally missing from Windows version
- PowerShell requires `.\` prefix when running `.bat` files from current directory
- The scripts are read-only for installed tools - they never install new tools, only update existing ones
- All package manager commands use silent/non-interactive flags where possible
