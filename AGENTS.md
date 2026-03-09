# Repository Guidelines

## Project Structure & Module Organization
This repository is intentionally small and root-only. The main entry points are `dev-cli-updater.sh` for macOS/Linux and `dev-cli-updater.bat` for Windows. `README.md` is the user-facing behavior contract; update it whenever supported tools, status labels, or prerequisites change. `CLAUDE.md` contains agent-specific notes. There is no dedicated `src/`, `tests/`, or assets directory.

## Build, Test, and Development Commands
Run the scripts directly from the repository root:

- `.\dev-cli-updater.bat` - run the Windows updater from PowerShell.
- `dev-cli-updater.bat` - run the Windows updater from `cmd.exe`.
- `chmod +x dev-cli-updater.sh && ./dev-cli-updater.sh` - run the POSIX updater.
- `bash -n dev-cli-updater.sh` - syntax-check the shell script before committing.

There is no build step. Development is script editing plus local verification.

## Coding Style & Naming Conventions
Keep edits ASCII unless the file already uses Unicode status icons or Japanese text. Match existing indentation: 4 spaces inside shell functions and batch blocks. In shell, use `lower_snake_case` for functions and `UPPER_SNAKE_CASE` for state variables. In batch, keep labels like `:UpdateGitHubCLI` and environment variables such as `SUCCESS_GH`. Prefer small, linear control flow and keep status messages consistent with the README summary labels.

## Testing Guidelines
There is no automated test suite yet. At minimum, run `bash -n dev-cli-updater.sh` after shell changes and manually execute the affected script on the target platform. When changing shared behavior, verify both Windows and POSIX flows if possible. Include failure-path checks: missing command, missing `npm`, and update-check failure should produce the expected summary state.

## Commit & Pull Request Guidelines
Follow the existing Conventional Commit pattern used in history, for example `fix(scripts): ...`, `docs(readme): ...`, or `chore(gitattributes): ...`. Keep the subject line concise and scoped. Pull requests should explain why the behavior changed, list the OS/shells tested, and note any README updates. If output text changes, include a short sample of the new summary or console messages.

## Safety & Scope
Do not add automatic installation of missing tools. This project only updates tools that are already installed. Prefer explicit failure reporting over silently treating errors as "up to date."
