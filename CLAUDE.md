# CLAUDE.md

このファイルは、このリポジトリのコードを扱う際に Claude Code（claude.ai/code）へ与えるガイダンスです。

## Project Overview

このリポジトリは、AI および開発者向け CLI ツールを一括更新するための、シンプルなクロスプラットフォームスクリプト集です。実装は 2 系統で並行して提供します。

- `dev-cli-updater.bat` - Windows 版（cmd/PowerShell）
- `dev-cli-updater.sh` - macOS/Linux 版（bash）

両スクリプトは、プラットフォームに適した方法で同一のツール群を更新し、整合したステータス表示とサマリー出力を行うことを目指します。

## Supported Tools

スクリプトは、インストール済みの以下 CLI ツールを更新します。

- **GitHub CLI**（`gh`）
  - Windows: winget
  - macOS: Homebrew
  - Linux（Debian/Ubuntu/WSL）: apt（GitHub CLI official apt repository）

- **Claude Code**（`claude`）
  - `claude update` などの Claude Code 組み込みアップデータおよび公式インストールチャネルを利用
  - `install.sh` / `install.ps1` / `install.cmd` といったネイティブ install scripts、および npm インストールも想定されるが、本リポジトリの更新ロジックは組み込みアップデータを優先する

- **Codex CLI**（`codex`）
  - npm グローバルインストール（`@openai/codex`）を利用
  - 公式サポートは macOS/Linux。Windows は experimental（WSL 推奨）

- **Gemini CLI**（`gemini`）
  - npm グローバルインストール（`@google/gemini-cli`）を利用

- **Cursor Agent**（`cursor-agent`）
  - 組み込み更新コマンド（`cursor-agent update` / `cursor-agent upgrade`）を利用
  - macOS/Linux と Windows（WSL 経由）で利用可能だが、本リポジトリは Windows の `.bat` から WSL を呼び出す実装を意図的に行わない（詳細は後述）

## Script Architecture

### Common Pattern

両スクリプトは、ツールごとに原則として以下のフローに従います。

1. ツールコマンドが存在するか確認
2. 現在のバージョンを取得
3. プラットフォームに適した方法で更新有無を確認
4. 更新がある場合のみ更新（または「already up to date」と報告する冪等な updater を実行）
5. success / skipped / failure の状態を集計しサマリーに反映

### Windows（.bat） Specifics

- UTF-8（絵文字含む）表示のため `chcp 65001` を使用
- サブルーチン（例：`:UpdateGitHubCLI`, `:UpdateClaude`, `:CheckAndUpdate`, `:PrintStatus`）を使用
- `CheckAndUpdate` は npm 系ツール（Codex, Gemini）向けの汎用関数
- GitHub CLI は `winget list --upgrade-available` / `--id` フィルタで更新検知し、`winget upgrade` で更新
- 変数取り扱いに delayed expansion（`setlocal enabledelayedexpansion`）を使用

### macOS/Linux（.sh） Specifics

- bash 関数（例：`check_and_update`, `update_github_cli`, `print_status`）を使用
- `check_and_update` は npm 系ツール（Codex, Gemini）向けの汎用関数
- GitHub CLI 更新は package manager（brew / apt）を自動判別
- Cursor Agent は Linux/macOS をデフォルトでサポート（Windows via WSL は `.bat` 実装のスコープ外）
- 参照渡し相当で success/skipped フラグを設定するため `eval` を使用（`eval` に untrusted input を渡さないこと）

## Update Logic Details

### GitHub CLI

**Windows**
- 検知: `winget list --id GitHub.cli --upgrade-available`
- 更新: `winget upgrade --id GitHub.cli`（可能な範囲で non-interactive flags を使用）
- 注意: winget は flags がない場合、同意確認などを求めることがあります。

**macOS**
- 検知: `brew outdated gh`
- 更新: `brew upgrade gh`

**Linux/WSL（Debian/Ubuntu）**
- 前提: GitHub CLI official apt repository が設定済みであること。
- 検知（典型）: `sudo apt update` を実行し、`apt list --upgradable` 等で `gh` が upgradable かを確認
- 更新: `sudo apt update && sudo apt install gh -y`
- 理由: 正確な更新検知のために `apt update` が必要です。

### Claude Code

**本リポジトリでの推奨動作**
- Claude Code の手動更新コマンド（組み込みアップデータ）を使用:
  - `claude update`
- Claude Code の auto-update モデルに整合し、特定の install channel に過度に依存しません。

**Notes**
- Claude Code は auto-updates に加え、複数のインストール方法（ネイティブ install scripts、Homebrew、npm）をサポートします。
- `claude update` が環境要因（PATH の衝突、複数インストール等）で失敗する場合、npm ベースの強制アップグレードに寄せるのではなく、インストール状態の是正を優先してください。

**やらないこと（repo policy）**
- Claude Code 更新のために npm を必須にしない。
- npm registry のバージョンを、インストール済みバイナリの “source of truth” とみなさない。

### npm-based Tools（Codex, Gemini）

- 検知: `npm outdated -g <package>`（出力が空なら up-to-date のケースが一般的）
- 更新: `npm install -g <package>@latest`
- package 名は厳密に指定する:
  - Codex: `@openai/codex`
  - Gemini CLI: `@google/gemini-cli`

**Platform notes**
- Codex CLI は公式に macOS と Linux をサポートします。Windows は experimental で、WSL での利用が適します。

### Cursor Agent

- Cursor CLI/Agent はデフォルトで auto-updates します。
- 手動更新:
  - `cursor-agent update`
  - または `cursor-agent upgrade`
- 出力パースによる判定は許容しますが、出力が曖昧な場合は version-before/after の比較にフォールバックしてください。

## Requirements

### Common
- 必要な依存が欠けている場合、明確なメッセージを出して graceful に失敗（または該当ツールをスキップ）すること。

### npm
- 以下のために `npm` が PATH に存在する必要があります:
  - Codex CLI
  - Gemini CLI
- Claude Code は、本リポジトリの推奨ポリシー（`claude update`）では `npm` を必須としません。

### Platform-specific package managers
- Windows: `winget`（GitHub CLI）
- macOS: `brew`（GitHub CLI）
- Debian/Ubuntu/WSL: `apt`（GitHub CLI official apt repository を設定済みであること）

## Testing

スクリプトを変更する場合:

- “already up-to-date” と “update available” の両シナリオをテスト
- 絵文字表示が正しいことを確認（Windows code page の挙動）
- “Not installed” のツールが graceful に扱われることを確認
- サマリーテーブルが各ツールの正しい状態を示すことを確認
- 影響するプラットフォーム上で実機テスト（クロスプラットフォーム互換を推測で断定しない）
- apt ベースのフローでは、`sudo` の有無や `apt update` の実行が更新検知／更新前に行われることを確認

## Important Notes

- 2 つのスクリプトは、ここに明示された差分を除き、機能的に整合させて維持してください（同じツール、同じ挙動）。
- Cursor Agent:
  - Cursor は Windows via WSL をサポートしますが、Windows の `.bat` は WSL 呼び出しを意図的に実装しません。`.sh` は WSL 内で実行される場合、WSL でもサポートし得ます。
- PowerShell では、カレントディレクトリの `.bat` 実行に `.\` プレフィックスが必要です（例：`.\dev-cli-updater.bat`）。
- スクリプトは “update-only” を意図します:
  - 未インストールのツールを積極的にインストールしない（コマンド存在チェックを先に行うこと）。
- non-interactive/silent flags を可能な範囲で使う一方、原因究明に必要なエラーは隠さない。
- **Permissions**:
  - Linux/macOS は `sudo` プロンプトが発生する可能性があります。
  - Windows は、winget 更新がパッケージやスコープにより Administrator 権限を要求する場合があります。
- **Dependency checks**:
  - `npm` がない場合、npm 系ツールは明確なメッセージ付きでスキップし、全体を失敗させない。
  - `winget` / `brew` / `apt` がない場合、該当ツールは明確なメッセージ付きでスキップする。

## References（source of truth）

- Claude Code setup / install / update:
  `https://docs.anthropic.com/en/docs/claude-code/setup`
- Cursor CLI installation & update:
  `https://docs.cursor.com/ja/cli/installation`
- Codex CLI quickstart（platform support notes）:
  `https://developers.openai.com/codex/quickstart/`
- WinGet list/upgrade documentation:
  `https://learn.microsoft.com/en-us/windows/package-manager/winget/list`
  `https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade`
- GitHub CLI Linux install（official apt repo instructions）:
  `https://raw.githubusercontent.com/cli/cli/trunk/docs/install_linux.md`
