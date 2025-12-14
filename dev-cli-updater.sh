#!/bin/bash

if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Cannot check for updates."
    exit 1
fi

check_and_update() {
    local cmd=$1
    local pkg=$2
    local success_var=$3
    local skipped_var=$4

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
    fi
}

update_github_cli() {
    local success_var=$1
    local skipped_var=$2

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
                fi
            else
                if apt install -y gh; then
                    echo "✅ Updated successfully."
                    gh --version
                    eval "$success_var=1"
                else
                    echo "⚠️ Update failed."
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

    if [ "$success" -eq 1 ]; then
        echo "$name: ✅ Updated"
    elif [ "$skipped" -eq 1 ]; then
        echo "$name: ℹ️ Up to date"
    else
        echo "$name: ⚠️ Not installed / Failed"
    fi
}

echo ""
echo "============= GitHub CLI =============="
SUCCESS_GH=0
SKIPPED_GH=0
if ! command -v gh &> /dev/null; then
    echo "⚠️ gh command not found. Skipping."
else
    update_github_cli SUCCESS_GH SKIPPED_GH
fi

echo ""
echo "============= Claude Code =============="
SUCCESS_CLAUDE=0
SKIPPED_CLAUDE=0
if ! command -v claude &> /dev/null; then
    echo "⚠️ claude command not found. Skipping."
else
    current_ver=$(claude --version 2>/dev/null | awk '{print $1}')
    echo "Current: $current_ver"

    echo "Checking for updates..."
    latest_ver=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
    echo "Latest:  $latest_ver"

    if [ "$current_ver" = "$latest_ver" ]; then
        echo "ℹ️ Already up to date."
        SKIPPED_CLAUDE=1
    else
        echo "Update available. Updating..."
        if curl -fsSL https://claude.ai/install.sh | bash; then
            echo "✅ Updated successfully."
            claude --version
            SUCCESS_CLAUDE=1
        else
            echo "⚠️ Update failed."
        fi
    fi
fi

echo ""
echo "============== Codex CLI ==============="
SUCCESS_CODEX=0
SKIPPED_CODEX=0
if ! command -v codex &> /dev/null; then
    echo "⚠️ codex command not found. Skipping."
else
    check_and_update "codex" "@openai/codex" SUCCESS_CODEX SKIPPED_CODEX
fi

echo ""
echo "============= Gemini CLI ==============="
SUCCESS_GEMINI=0
SKIPPED_GEMINI=0
if ! command -v gemini &> /dev/null; then
    echo "⚠️ gemini command not found. Skipping."
else
    check_and_update "gemini" "@google/gemini-cli" SUCCESS_GEMINI SKIPPED_GEMINI
fi

echo ""
echo "============ Cursor Agent =============="
SUCCESS_CURSOR=0
SKIPPED_CURSOR=0
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
print_status "GitHub CLI  " $SUCCESS_GH $SKIPPED_GH
print_status "Claude Code " $SUCCESS_CLAUDE $SKIPPED_CLAUDE
print_status "Codex CLI   " $SUCCESS_CODEX $SKIPPED_CODEX
print_status "Gemini CLI  " $SUCCESS_GEMINI $SKIPPED_GEMINI
print_status "Cursor Agent" $SUCCESS_CURSOR $SKIPPED_CURSOR
echo ""
