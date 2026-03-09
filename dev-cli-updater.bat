@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "HAS_NPM=0"
where npm >nul 2>&1 && set "HAS_NPM=1"

if "%HAS_NPM%"=="0" echo ⚠️ npm not found. npm-based tools (Codex CLI, Gemini CLI) will be skipped.

echo.
echo ============ GitHub CLI ================
set "SUCCESS_GH=0"
set "SKIPPED_GH=0"
set "DEPS_GH=0"
set "FAILED_GH=0"
where gh >nul 2>&1
if errorlevel 1 (
    echo ⚠️ gh command not found. Skipping.
) else (
    call :UpdateGitHubCLI
)

echo.
echo ============= Claude Code ==============
set "SUCCESS_CLAUDE=0"
set "SKIPPED_CLAUDE=0"
set "DEPS_CLAUDE=0"
set "FAILED_CLAUDE=0"
where claude >nul 2>&1
if errorlevel 1 (
    echo ⚠️ claude command not found. Skipping.
) else (
    call :UpdateClaude
)

echo.
echo ============== Codex CLI ===============
set "SUCCESS_CODEX=0"
set "SKIPPED_CODEX=0"
set "DEPS_CODEX=0"
set "FAILED_CODEX=0"
where codex >nul 2>&1
if errorlevel 1 (
    echo ⚠️ codex command not found. Skipping.
) else (
    if "%HAS_NPM%"=="0" (
        echo ⚠️ npm not found. Skipping update check for Codex CLI.
        set "DEPS_CODEX=1"
    ) else (
        call :CheckAndUpdate "codex" "@openai/codex" SUCCESS_CODEX SKIPPED_CODEX FAILED_CODEX
    )
)

echo.
echo ============= Gemini CLI ===============
set "SUCCESS_GEMINI=0"
set "SKIPPED_GEMINI=0"
set "DEPS_GEMINI=0"
set "FAILED_GEMINI=0"
where gemini >nul 2>&1
if errorlevel 1 (
    echo ⚠️ gemini command not found. Skipping.
) else (
    if "%HAS_NPM%"=="0" (
        echo ⚠️ npm not found. Skipping update check for Gemini CLI.
        set "DEPS_GEMINI=1"
    ) else (
        call :CheckAndUpdate "gemini" "@google/gemini-cli" SUCCESS_GEMINI SKIPPED_GEMINI FAILED_GEMINI
    )
)

echo.
echo =============== Summary ================
call :PrintStatus "GitHub CLI " "%SUCCESS_GH%" "%SKIPPED_GH%" "%DEPS_GH%" "%FAILED_GH%"
call :PrintStatus "Claude Code" "%SUCCESS_CLAUDE%" "%SKIPPED_CLAUDE%" "%DEPS_CLAUDE%" "%FAILED_CLAUDE%"
call :PrintStatus "Codex CLI  " "%SUCCESS_CODEX%" "%SKIPPED_CODEX%" "%DEPS_CODEX%" "%FAILED_CODEX%"
call :PrintStatus "Gemini CLI " "%SUCCESS_GEMINI%" "%SKIPPED_GEMINI%" "%DEPS_GEMINI%" "%FAILED_GEMINI%"
echo.
pause
exit /b

:PrintValueLine
setlocal DisableDelayedExpansion
set "_LABEL=%~1"
set "_VALUE=%~2"
<nul set /p "=%_LABEL%%_VALUE%"
echo.
exit /b

:UpdateGitHubCLI
where winget >nul 2>&1
if errorlevel 1 (
    echo ⚠️ winget command not found. Cannot check/update GitHub CLI.
    set "DEPS_GH=1"
    exit /b
)

set "_GH_CURRENT="
for /f "tokens=3 delims= " %%v in ('gh --version ^| findstr /R "^gh version"') do if not defined _GH_CURRENT set "_GH_CURRENT=%%v"

if defined _GH_CURRENT (
    call :PrintValueLine "Current: " "!_GH_CURRENT!"
) else (
    echo Current: ^(unknown^)
)

echo Checking for updates...
winget list --id GitHub.cli --upgrade-available --accept-source-agreements 2>nul | findstr /I /C:"GitHub.cli" >nul
if errorlevel 1 (
    echo ℹ️ Already up to date.
    set "SKIPPED_GH=1"
    exit /b
)

echo Update available. Updating...
winget upgrade --id GitHub.cli -e --silent --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo ⚠️ Update failed.
    set "FAILED_GH=1"
    exit /b
)

echo ✅ Updated successfully.
cmd /c gh --version
set "SUCCESS_GH=1"
exit /b

:UpdateClaude
set "_CLAUDE_BEFORE="
for /f "usebackq delims=" %%v in (`claude --version 2^>nul`) do if not defined _CLAUDE_BEFORE set "_CLAUDE_BEFORE=%%v"

if defined _CLAUDE_BEFORE (
    call :PrintValueLine "Current: " "!_CLAUDE_BEFORE!"
) else (
    echo Current: ^(unknown^)
)

set "_CLAUDE_LOG=%TEMP%\dev-cli-updater-claude-%RANDOM%-%RANDOM%.log"
echo Running: claude update
cmd /c claude update > "!_CLAUDE_LOG!" 2>&1
set "_CLAUDE_EXIT=!ERRORLEVEL!"

if not "!_CLAUDE_EXIT!"=="0" (
    if exist "!_CLAUDE_LOG!" type "!_CLAUDE_LOG!"
    if exist "!_CLAUDE_LOG!" del /q "!_CLAUDE_LOG!" >nul 2>&1
    echo ⚠️ Update failed.
    set "FAILED_CLAUDE=1"
    exit /b
)

findstr /I /C:"up to date" /C:"already up to date" /C:"latest version" "!_CLAUDE_LOG!" >nul
if not errorlevel 1 (
    if exist "!_CLAUDE_LOG!" del /q "!_CLAUDE_LOG!" >nul 2>&1
    echo ℹ️ Already up to date.
    set "SKIPPED_CLAUDE=1"
    exit /b
)

set "_CLAUDE_AFTER="
for /f "usebackq delims=" %%v in (`claude --version 2^>nul`) do if not defined _CLAUDE_AFTER set "_CLAUDE_AFTER=%%v"

if defined _CLAUDE_AFTER (
    call :PrintValueLine "After:   " "!_CLAUDE_AFTER!"
)

if defined _CLAUDE_BEFORE (
    if defined _CLAUDE_AFTER (
        if /I "!_CLAUDE_BEFORE!"=="!_CLAUDE_AFTER!" (
            if exist "!_CLAUDE_LOG!" del /q "!_CLAUDE_LOG!" >nul 2>&1
            echo ℹ️ Already up to date ^(or updates apply on next start^).
            set "SKIPPED_CLAUDE=1"
            exit /b
        )
    )
)

if exist "!_CLAUDE_LOG!" del /q "!_CLAUDE_LOG!" >nul 2>&1
echo ✅ Update command completed.
set "SUCCESS_CLAUDE=1"
exit /b

:CheckAndUpdate
set "_CMD=%~1"
set "_PKG=%~2"
set "_SUCCESS_VAR=%~3"
set "_SKIPPED_VAR=%~4"
set "_FAILED_VAR=%~5"

set "_CURRENT="
for /f "tokens=*" %%v in ('%_CMD% --version 2^>nul') do if not defined _CURRENT set "_CURRENT=%%v"

if defined _CURRENT (
    call :PrintValueLine "Current: " "!_CURRENT!"
) else (
    echo Current: ^(unknown^)
)

echo Checking for updates...
set "_OUTDATED="
for /f "tokens=*" %%o in ('npm outdated -g %_PKG% 2^>nul') do set "_OUTDATED=%%o"

if not defined _OUTDATED (
    echo ℹ️ Already up to date.
    set "%_SKIPPED_VAR%=1"
    exit /b
)

echo Update available. Updating...
call npm install -g %_PKG%@latest
if errorlevel 1 (
    echo ⚠️ Update failed.
    set "%_FAILED_VAR%=1"
    exit /b
)

echo ✅ Updated successfully.
cmd /c %_CMD% --version
set "%_SUCCESS_VAR%=1"
exit /b

:PrintStatus
if "%~2"=="1" (
    echo %~1: ✅ Updated
) else if "%~3"=="1" (
    echo %~1: ℹ️ Up to date
) else if "%~4"=="1" (
    echo %~1: ⏭️ Skipped ^(missing dependency^)
) else if "%~5"=="1" (
    echo %~1: ❌ Failed
) else (
    echo %~1: ⚠️ Not installed
)
exit /b
