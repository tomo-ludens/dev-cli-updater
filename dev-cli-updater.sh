#!/bin/bash

HAS_NPM=0
if command -v npm &> /dev/null; then
    HAS_NPM=1
fi

if [ "$HAS_NPM" -eq 0 ]; then
    echo "⚠️ npm not found. npm-based tools (Codex CLI, Gemini CLI) will be skipped."
fi

check_and_update() {
    local cmd=$1
    local pkg=$2
    local success_var=$3
    local skipped_var=$4
    local failed_var=$5

    local current
    current=$($cmd --version 2>/dev/null)
    echo "Current: $current"

    echo "Checking for updates..."
    local outdated
    outdated=$(npm outdated -g "$pkg" 2>/dev/null)

    if [ -z "$outdated" ]; then
        echo "ℹ️ Already up to date."
        eval "$skipped_var=1"
        return
    fi

    echo "Update available. Updating..."
    if npm install -g "${pkg}@latest"; then
        echo "✅ Updated successfully."
        $cmd --version
        eval "$success_var=1"
    else
        echo "⚠️ Update failed."
        eval "$failed_var=1"
    fi
}

update_github_cli() {
    local success_var=$1
    local skipped_var=$2
    local failed_var=$3

    local current
    current=$(gh --version 2>/dev/null | head -n 1)
    echo "Current: $current"
    echo "Checking for updates..."

    # --- macOS / Homebrew ---
    if command -v brew >/dev/null 2>&1 && brew list --versions gh >/dev/null 2>&1; then
        if brew outdated gh >/dev/null 2>&1; then
            echo "Update available. Updating (brew)..."
            if brew upgrade gh; then
                echo "✅ Updated successfully."
                gh --version
                eval "$success_var=1"
            else
                echo "⚠️ Update failed."
                eval "$failed_var=1"
            fi
        else
            echo "ℹ️ Already up to date."
            eval "$skipped_var=1"
        fi
        return
    fi

    # --- Debian / Ubuntu / WSL ---
    if command -v apt >/dev/null 2>&1; then
        if command -v sudo >/dev/null 2>&1; then
            sudo apt update -y >/dev/null 2>&1
        else
            apt update -y >/dev/null 2>&1
        fi

        if apt list --upgradable 2>/dev/null | grep -q '^gh/'; then
            echo "Update available. Updating (apt)..."
            if command -v sudo >/dev/null 2>&1; then
                if sudo apt install -y gh; then
                    echo "✅ Updated successfully."
                    gh --version
                    eval "$success_var=1"
                else
                    echo "⚠️ Update failed."
                    eval "$failed_var=1"
                fi
            else
                if apt install -y gh; then
                    echo "✅ Updated successfully."
                    gh --version
                    eval "$success_var=1"
                else
                    echo "⚠️ Update failed."
                    eval "$failed_var=1"
                fi
            fi
        else
            echo "ℹ️ Already up to date."
            eval "$skipped_var=1"
        fi
        return
    fi

    echo "⚠️ Supported package manager not found for GitHub CLI (gh)."
}

print_status() {
    local name=$1
    local success=$2
    local skipped=$3
    local deps=$4
    local failed=$5

    if [ "$success" -eq 1 ]; then
        echo "$name: ✅ Updated"
    elif [ "$skipped" -eq 1 ]; then
        echo "$name: ℹ️ Up to date"
    elif [ "$deps" -eq 1 ]; then
        echo "$name: ⏭️ Skipped (missing dependency)"
    elif [ "$failed" -eq 1 ]; then
        echo "$name: ❌ Failed"
    else
        echo "$name: ⚠️ Not installed"
    fi
}

echo ""
echo "============= GitHub CLI =============="
SUCCESS_GH=0
SKIPPED_GH=0
DEPS_GH=0
FAILED_GH=0
if ! command -v gh &> /dev/null; then
    echo "⚠️ gh command not found. Skipping."
else
    update_github_cli SUCCESS_GH SKIPPED_GH FAILED_GH
fi

echo ""
echo "============= Claude Code =============="
SUCCESS_CLAUDE=0
SKIPPED_CLAUDE=0
DEPS_CLAUDE=0
FAILED_CLAUDE=0
if ! command -v claude &> /dev/null; then
    echo "⚠️ claude command not found. Skipping."
else
    claude_before=$(claude --version 2>/dev/null)
    if [ -n "$claude_before" ]; then
        echo "Current: $claude_before"
    else
        echo "Current: (unknown)"
    fi

    echo "Running: claude update"
    if claude update; then
        claude_after=$(claude --version 2>/dev/null)
        if [ -n "$claude_after" ]; then
            echo "After:   $claude_after"
        fi

        if [ -n "$claude_before" ] && [ -n "$claude_after" ]; then
            if [ "$claude_before" = "$claude_after" ]; then
                echo "ℹ️ Already up to date (or updates apply on next start)."
                SKIPPED_CLAUDE=1
            else
                echo "✅ Update command completed."
                SUCCESS_CLAUDE=1
            fi
        else
            echo "✅ Update command completed."
            SUCCESS_CLAUDE=1
        fi
    else
        echo "⚠️ Update failed."
        FAILED_CLAUDE=1
    fi
fi

echo ""
echo "============== Codex CLI ==============="
SUCCESS_CODEX=0
SKIPPED_CODEX=0
DEPS_CODEX=0
FAILED_CODEX=0
if ! command -v codex &> /dev/null; then
    echo "⚠️ codex command not found. Skipping."
else
    if [ "$HAS_NPM" -eq 0 ]; then
        echo "⚠️ npm not found. Skipping update check for Codex CLI."
        DEPS_CODEX=1
    else
        check_and_update "codex" "@openai/codex" SUCCESS_CODEX SKIPPED_CODEX FAILED_CODEX
    fi
fi

echo ""
echo "============= Gemini CLI ==============="
SUCCESS_GEMINI=0
SKIPPED_GEMINI=0
DEPS_GEMINI=0
FAILED_GEMINI=0
if ! command -v gemini &> /dev/null; then
    echo "⚠️ gemini command not found. Skipping."
else
    if [ "$HAS_NPM" -eq 0 ]; then
        echo "⚠️ npm not found. Skipping update check for Gemini CLI."
        DEPS_GEMINI=1
    else
        check_and_update "gemini" "@google/gemini-cli" SUCCESS_GEMINI SKIPPED_GEMINI FAILED_GEMINI
    fi
fi

echo ""
echo "============ Cursor Agent =============="
SUCCESS_CURSOR=0
SKIPPED_CURSOR=0
DEPS_CURSOR=0
FAILED_CURSOR=0
if ! command -v cursor-agent &> /dev/null; then
    echo "⚠️ cursor-agent command not found. Skipping."
else
    current_cursor=$(cursor-agent --version 2>/dev/null)
    echo "Current: $current_cursor"

    echo "Checking for updates..."
    update_output=$(cursor-agent update 2>&1)

    if echo "$update_output" | grep -qi "already.*up.*to.*date\|no.*update\|latest"; then
        echo "ℹ️ Already up to date."
        SKIPPED_CURSOR=1
    elif echo "$update_output" | grep -qi "updated\|success\|upgrade"; then
        echo "✅ Updated successfully."
        cursor-agent --version
        SUCCESS_CURSOR=1
    else
        new_cursor=$(cursor-agent --version 2>/dev/null)
        if [ "$current_cursor" = "$new_cursor" ]; then
            echo "ℹ️ Already up to date."
            SKIPPED_CURSOR=1
        else
            echo "✅ Updated successfully."
            cursor-agent --version
            SUCCESS_CURSOR=1
        fi
    fi
fi

echo ""
echo "=============== Summary ================"
print_status "GitHub CLI  " $SUCCESS_GH $SKIPPED_GH $DEPS_GH $FAILED_GH
print_status "Claude Code " $SUCCESS_CLAUDE $SKIPPED_CLAUDE $DEPS_CLAUDE $FAILED_CLAUDE
print_status "Codex CLI   " $SUCCESS_CODEX $SKIPPED_CODEX $DEPS_CODEX $FAILED_CODEX
print_status "Gemini CLI  " $SUCCESS_GEMINI $SKIPPED_GEMINI $DEPS_GEMINI $FAILED_GEMINI
print_status "Cursor Agent" $SUCCESS_CURSOR $SKIPPED_CURSOR $DEPS_CURSOR $FAILED_CURSOR
echo ""
