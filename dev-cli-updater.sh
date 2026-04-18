#!/bin/sh

HAS_NPM=0
if command -v npm >/dev/null 2>&1; then
    HAS_NPM=1
fi

if [ "$HAS_NPM" -eq 0 ]; then
    echo "⚠️ npm not found. npm-based tools (Codex CLI, Gemini CLI) will be skipped."
fi

check_and_update() {
    cau_cmd=$1
    cau_pkg=$2
    cau_success_var=$3
    cau_skipped_var=$4
    cau_failed_var=$5

    cau_current=$("$cau_cmd" --version 2>/dev/null | head -n 1)
    echo "Current: $cau_current"

    echo "Checking for updates..."
    cau_outdated=$(npm outdated -g "$cau_pkg" 2>/dev/null)

    if [ -z "$cau_outdated" ]; then
        echo "ℹ️ Already up to date."
        eval "$cau_skipped_var=1"
        return
    fi

    echo "Update available. Updating..."
    if npm install -g "${cau_pkg}@latest"; then
        echo "✅ Updated successfully."
        "$cau_cmd" --version
        eval "$cau_success_var=1"
    else
        echo "⚠️ Update failed."
        eval "$cau_failed_var=1"
    fi
}

update_github_cli() {
    ugc_success_var=$1
    ugc_skipped_var=$2
    ugc_deps_var=$3
    ugc_failed_var=$4

    ugc_current=$(gh --version 2>/dev/null | head -n 1)
    echo "Current: $ugc_current"
    echo "Checking for updates..."

    # macOS / Homebrew
    if command -v brew >/dev/null 2>&1 && brew list --versions gh >/dev/null 2>&1; then
        ugc_brew_outdated=$(brew outdated gh 2>/dev/null)
        if [ -n "$ugc_brew_outdated" ]; then
            echo "Update available. Updating (brew)..."
            if brew upgrade gh; then
                echo "✅ Updated successfully."
                gh --version
                eval "$ugc_success_var=1"
            else
                echo "⚠️ Update failed."
                eval "$ugc_failed_var=1"
            fi
        else
            echo "ℹ️ Already up to date."
            eval "$ugc_skipped_var=1"
        fi
        return
    fi

    # Debian / Ubuntu / WSL
    if command -v apt >/dev/null 2>&1; then
        ugc_apt_prefix=
        if command -v sudo >/dev/null 2>&1; then
            ugc_apt_prefix=sudo
        fi

        $ugc_apt_prefix apt update -y >/dev/null 2>&1

        if apt list --upgradable 2>/dev/null | grep -q '^gh/'; then
            echo "Update available. Updating (apt)..."
            if $ugc_apt_prefix apt install -y gh; then
                echo "✅ Updated successfully."
                gh --version
                eval "$ugc_success_var=1"
            else
                echo "⚠️ Update failed."
                eval "$ugc_failed_var=1"
            fi
        else
            echo "ℹ️ Already up to date."
            eval "$ugc_skipped_var=1"
        fi
        return
    fi

    echo "⚠️ Supported package manager not found for GitHub CLI (gh)."
    eval "$ugc_deps_var=1"
}

print_status() {
    ps_name=$1
    ps_success=$2
    ps_skipped=$3
    ps_deps=$4
    ps_failed=$5

    if [ "$ps_success" -eq 1 ]; then
        echo "$ps_name: ✅ Updated"
    elif [ "$ps_skipped" -eq 1 ]; then
        echo "$ps_name: ℹ️ Up to date"
    elif [ "$ps_deps" -eq 1 ]; then
        echo "$ps_name: ⏭️ Skipped (missing dependency)"
    elif [ "$ps_failed" -eq 1 ]; then
        echo "$ps_name: ❌ Failed"
    else
        echo "$ps_name: ⚠️ Not installed"
    fi
}

echo ""
echo "============= GitHub CLI =============="
SUCCESS_GH=0
SKIPPED_GH=0
DEPS_GH=0
FAILED_GH=0
if ! command -v gh >/dev/null 2>&1; then
    echo "⚠️ gh command not found. Skipping."
else
    update_github_cli SUCCESS_GH SKIPPED_GH DEPS_GH FAILED_GH
fi

echo ""
echo "============= Claude Code =============="
SUCCESS_CLAUDE=0
SKIPPED_CLAUDE=0
DEPS_CLAUDE=0
FAILED_CLAUDE=0
if ! command -v claude >/dev/null 2>&1; then
    echo "⚠️ claude command not found. Skipping."
else
    claude_before=$(claude --version 2>/dev/null | head -n 1)
    if [ -n "$claude_before" ]; then
        echo "Current: $claude_before"
    else
        echo "Current: (unknown)"
    fi

    echo "Running: claude update"
    claude_update_output=$(claude update 2>&1)
    claude_update_exit=$?

    if [ "$claude_update_exit" -eq 0 ]; then
        claude_after=$(claude --version 2>/dev/null | head -n 1)
        if [ -n "$claude_after" ]; then
            echo "After:   $claude_after"
        fi

        if printf '%s\n' "$claude_update_output" | grep -qi "up to date\|already.*up.*to.*date\|latest version"; then
            echo "ℹ️ Already up to date."
            SKIPPED_CLAUDE=1
        elif [ -n "$claude_before" ] && [ -n "$claude_after" ]; then
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
        if [ -n "$claude_update_output" ]; then
            printf '%s\n' "$claude_update_output"
        fi
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
if ! command -v codex >/dev/null 2>&1; then
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
if ! command -v gemini >/dev/null 2>&1; then
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
echo "=============== Summary ================"
print_status "GitHub CLI  " "$SUCCESS_GH" "$SKIPPED_GH" "$DEPS_GH" "$FAILED_GH"
print_status "Claude Code " "$SUCCESS_CLAUDE" "$SKIPPED_CLAUDE" "$DEPS_CLAUDE" "$FAILED_CLAUDE"
print_status "Codex CLI   " "$SUCCESS_CODEX" "$SKIPPED_CODEX" "$DEPS_CODEX" "$FAILED_CODEX"
print_status "Gemini CLI  " "$SUCCESS_GEMINI" "$SKIPPED_GEMINI" "$DEPS_GEMINI" "$FAILED_GEMINI"
echo ""
