# dev-cli-updater

AI / 開発者向け CLI ツールを一括アップデートするシンプルなスクリプトです。

## 対応ツール

- [GitHub CLI](https://github.com/cli/cli)
- [Claude Code](https://github.com/anthropics/claude-code)
- [Codex CLI](https://github.com/openai/codex)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [Cursor Agent](https://github.com/getcursor/cursor)

## 必要な環境

- `npm`（Claude Code、Codex CLI、Gemini CLI のアップデートに必要）
- `bash`（macOS / Linux）
- `cmd.exe` または PowerShell（Windows）
- GitHub CLI のアップデートには以下が必要：
  - Windows: [`winget`](https://learn.microsoft.com/windows/package-manager/winget/) でインストールされた GitHub CLI
  - macOS: [`brew`](https://brew.sh/) でインストールされた GitHub CLI
  - Debian / Ubuntu / WSL: [GitHub 公式 APT リポジトリ](https://cli.github.com/)からインストールされた GitHub CLI

## 使い方

### Windows

**PowerShell** から実行（推奨）：
```powershell
cd <project-root>
.\dev-cli-updater.bat
```

> PowerShell はセキュリティ上の理由から、カレントディレクトリのコマンドを自動で検索しません。そのため、スクリプト実行時には `.\` を先頭に付ける必要があります。

**コマンドプロンプト**（cmd.exe）から実行：
```bat
cd <project-root>
dev-cli-updater.bat
```

### macOS / Linux
```bash
chmod +x dev-cli-updater.sh
./dev-cli-updater.sh
```

## 注意事項

- このスクリプトは、既にインストールされているツールのみをアップデートします。未インストールのツールは、サマリーに「Not installed / Failed」と表示されます。
- GitHub CLI のアップデートには、システムのパッケージマネージャー（`winget`、`brew`、`apt`）を使用します。アップデートが利用可能な場合のみ更新を実行します。
- Debian / Ubuntu / WSL では、GitHub CLI が[GitHub 公式 APT リポジトリ](https://cli.github.com/)からインストールされている必要があります。ディストリビューションのコミュニティパッケージには対応していません。

## ライセンス

MIT
