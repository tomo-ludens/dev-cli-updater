# dev-cli-updater

AI / 開発者向け CLI ツールを **インストール済みのものだけ** 一括アップデートする、シンプルなクロスプラットフォームスクリプトです。

- Windows: `dev-cli-updater.bat`
- macOS / Linux: `dev-cli-updater.sh`

## 対応ツール

- [GitHub CLI](https://github.com/cli/cli)（`gh`）
- [Claude Code](https://github.com/anthropics/claude-code)（`claude`）
- [Codex CLI](https://github.com/openai/codex)（`codex`）
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)（`gemini`）
- [Cursor Agent](https://github.com/getcursor/cursor)（`cursor-agent`）※ `dev-cli-updater.sh` のみ（Windows `.bat` では更新しません）

## 仕様（概要）

各ツールについて次の流れで処理します。

1. コマンド存在チェック（未インストールならスキップ）
2. 現在のバージョン表示
3. 更新有無チェック
4. 更新がある場合のみアップデート（または updater 実行）
5. 結果をサマリー表示

## 必要な環境

### 共通
- 既に対象ツールがインストール済みであること（本スクリプトは新規インストールを行いません）

### npm（任意だが推奨）
- `npm` は **Codex CLI / Gemini CLI の更新**に必要です（`npm` が無い場合は依存不足としてスキップします）
- `Claude Code` は `claude update` を使用するため、`npm` を必須にしません

### OS / パッケージマネージャ要件（GitHub CLI）
GitHub CLI（`gh`）のアップデートはシステムのパッケージマネージャで行います。以下の経路でインストール済みである必要があります。

- Windows: [`winget`](https://learn.microsoft.com/windows/package-manager/winget/) でインストールされた GitHub CLI
- macOS: [`brew`](https://brew.sh/) でインストールされた GitHub CLI
- Debian / Ubuntu / WSL: [GitHub CLI 公式 APT リポジトリ](https://cli.github.com/) からインストールされた GitHub CLI

### 実行環境
- Windows: `cmd.exe` または PowerShell
- macOS / Linux: `bash`

## 使い方

### Windows

**PowerShell** から実行（推奨）：
```powershell
cd <project-root>
.\dev-cli-updater.bat
````

> PowerShell はセキュリティ上の理由から、カレントディレクトリのコマンドを自動で検索しません。そのため、`.\` を先頭に付ける必要があります。

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

## ステータス（Summary の表示）

サマリーは概ね次のいずれかで表示されます。

* `✅ Updated`：更新を実行して成功
* `ℹ️ Up to date`：最新のためスキップ
* `⏭️ Skipped (missing dependency)`：依存不足（例：`npm` が無い）でスキップ
* `❌ Failed`：更新に失敗
* `⚠️ Not installed`：コマンドが見つからず未インストール扱い

## 注意事項

* このスクリプトは **既にインストールされているツールのみ** をアップデートします。未インストールのツールはスキップされます。
* GitHub CLI の更新は `winget` / `brew` / `apt` に依存します。環境によっては権限昇格（管理者 / `sudo`）が必要です。
* Debian / Ubuntu / WSL では、GitHub CLI が **GitHub CLI 公式 APT リポジトリ**由来である必要があります（ディストリビューション側のコミュニティパッケージは対象外）。
* Windows `.bat` は `cursor-agent` を更新しません（必要なら WSL 上で `.sh` を実行する運用にしてください）。

## ライセンス

MIT

```
補足（README に反映した前提）：
- `Claude Code` は手動更新として `claude update` が公式に案内されています。:contentReference[oaicite:0]{index=0}
- `Codex CLI` は macOS/Linux が公式サポートで、Windows は experimental（WSL 推奨）です。:contentReference[oaicite:1]{index=1}
- `cursor-agent update` / `cursor-agent upgrade` が手動更新手段として案内されています。:contentReference[oaicite:2]{index=2}
::contentReference[oaicite:3]{index=3}
```
