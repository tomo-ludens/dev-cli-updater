# Repository Guidelines

## Project Structure & Module Organization
This repository is intentionally root-only. The main entry points are `dev-cli-updater.sh` for macOS/Linux and `dev-cli-updater.bat` for Windows. `README.md` is the user-facing behavior contract; update it whenever supported tools, status labels, prerequisites, or sample output change. `CLAUDE.md` contains agent-specific notes. There is no dedicated `src/`, `tests/`, or `assets/` directory.

## Build, Test, and Development Commands
There is no build step. Edit the scripts in place and run them from the repository root.

- `.\dev-cli-updater.bat` runs the Windows updater from PowerShell.
- `dev-cli-updater.bat` runs the Windows updater from `cmd.exe`.
- `chmod +x dev-cli-updater.sh && ./dev-cli-updater.sh` runs the POSIX updater.
- `bash -n dev-cli-updater.sh` performs a shell syntax check before committing.

## Coding Style & Naming Conventions
Keep edits ASCII unless a file already uses Unicode status icons or Japanese text. Match the existing indentation: 4 spaces inside shell functions and batch blocks. In shell, use `lower_snake_case` for functions and `UPPER_SNAKE_CASE` for state variables. In batch, keep labels descriptive, such as `:UpdateGitHubCLI`, and use uppercase environment variables like `SUCCESS_GH`. Prefer small, linear control flow and keep console messages aligned with the summary labels documented in `README.md`.

## Testing Guidelines
There is no automated test suite yet. At minimum, run `bash -n dev-cli-updater.sh` after shell changes and manually execute the affected script on the target platform. When behavior is shared, verify both Windows and POSIX flows if possible. Check failure paths as well as success paths: missing command, missing `npm`, and update-check failure should each map to the expected summary state.

## Commit & Pull Request Guidelines
Follow the Conventional Commit style used in history, for example `fix(bat): ...`, `fix(sh): ...`, or `docs(readme): ...`. Keep subjects concise and scoped. Pull requests should explain why behavior changed, list the OS or shell combinations tested, and note any `README.md` updates. If console output changes, include a short before/after sample.

## Safety & Scope
Do not add automatic installation of missing tools. This project only updates tools that are already installed. Prefer explicit failure reporting over silently treating errors as "up to date."
