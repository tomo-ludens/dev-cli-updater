@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

where npm >nul 2>&1
if errorlevel 1 (
    echo ❌ npm not found. Cannot check for updates.
    pause
    exit /b 1
)

echo.
echo ============= Claude Code ==============
set "SUCCESS_CLAUDE=0"
set "SKIPPED_CLAUDE=0"
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
where codex >nul 2>&1
if errorlevel 1 (
    echo ⚠️ codex command not found. Skipping.
) else (
    call :CheckAndUpdate "codex" "@openai/codex" SUCCESS_CODEX SKIPPED_CODEX
)

echo.
echo ============= Gemini CLI ===============
set "SUCCESS_GEMINI=0"
set "SKIPPED_GEMINI=0"
where gemini >nul 2>&1
if errorlevel 1 (
    echo ⚠️ gemini command not found. Skipping.
) else (
    call :CheckAndUpdate "gemini" "@google/gemini-cli" SUCCESS_GEMINI SKIPPED_GEMINI
)

echo.
echo =============== Summary ================
call :PrintStatus "Claude Code" "%SUCCESS_CLAUDE%" "%SKIPPED_CLAUDE%"
call :PrintStatus "Codex CLI  " "%SUCCESS_CODEX%" "%SKIPPED_CODEX%"
call :PrintStatus "Gemini CLI " "%SUCCESS_GEMINI%" "%SKIPPED_GEMINI%"
echo.
pause
exit /b

:UpdateClaude
for /f "tokens=1 delims= " %%v in ('claude --version 2^>nul') do set "_CURRENT_VER=%%v"
echo Current: %_CURRENT_VER%

echo Checking for updates...
for /f "tokens=*" %%v in ('npm view @anthropic-ai/claude-code version 2^>nul') do set "_LATEST=%%v"
echo Latest:  %_LATEST%

if "%_CURRENT_VER%"=="%_LATEST%" (
    echo ℹ️ Already up to date.
    set "SKIPPED_CLAUDE=1"
    exit /b
)

echo Update available. Updating...
powershell -Command "irm https://claude.ai/install.ps1 | iex"
if errorlevel 1 (
    echo ⚠️ Update failed.
    exit /b
)
echo ✅ Updated successfully.
cmd /c claude --version
set "SUCCESS_CLAUDE=1"
exit /b

:CheckAndUpdate
set "_CMD=%~1"
set "_PKG=%~2"
set "_SUCCESS_VAR=%~3"
set "_SKIPPED_VAR=%~4"

for /f "tokens=*" %%v in ('%_CMD% --version 2^>nul') do set "_CURRENT=%%v"
echo Current: %_CURRENT%

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
) else (
    echo %~1: ⚠️ Not installed / Failed
)
exit /b
