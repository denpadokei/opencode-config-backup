# RESTORE.md — AI 用リストア手順書

このリポジトリは OpenCode / OpenChamber の設定ファイル集です。
**この文書は AI エージェントが読んでそのまま実行できることを目的にしています。**
不明点はユーザーに質問してください（返答は日本語で行うこと）。

## 0. ユーザーの前提知識

- ユーザーは日本語でやり取りし、作業は **1件ずつ指示して確認** するスタイル。勝手にまとめて実行しすぎない。
- 普段使うのは Web 検索系 MCP のみ。重い MCP は `opencode.jsonc` に定義を残して `"disabled": true` にする方針。

## 1. 何が入っているか

| リポジトリ内 | 復元先 | 中身 |
| --- | --- | --- |
| `opencode/opencode.jsonc` | `~/.config/opencode/opencode.jsonc` | MCP（6有効/5無効）、plugins 6種、メモリ用エージェント3種のモデル割当 |
| `opencode/dcp.jsonc` | `~/.config/opencode/dcp.jsonc` | DCP（コンテキスト圧縮）しきい値 90%/75% |
| `opencode/cli.json` | `~/.config/opencode/cli.json` | CLI プラグイン設定 |
| `opencode/oh-my-opencode-slim.json` | `~/.config/opencode/oh-my-opencode-slim.json` | サブエージェントのモデルプリセット |
| `opencode/skills/` | `~/.config/opencode/skills/` | スキル5種（beatapi, beatsaber-pc, beatsaber-quest, chromapper-plugin, security-review） |
| `openchamber/preferences.json` | `~/.config/openchamber/preferences.json` | UI 設定（テーマ・通知・既定モデル・`locale: ja`） |
| `openchamber/routing.json` | `~/.config/openchamber/routing.json` | モデルルーティング設定 |
| `openchamber/settings.example.json` | （テンプレート） | `settings.json` の無害化サンプル。実物はアプリが生成する |

`settings.local.json`（実 `settings.json` の個別バックアップ）は **このリポジトリに存在しない**。
本物の `settings.json` は初回起動時に自動生成されるので、必要項目だけ UI または 4.4 のテンプレートを元に設定する。

## 2. バックアップに含めないもの（重要）

| ファイル | 理由 | 復旧方法 |
| --- | --- | --- |
| `~/.config/opencode/service.json` | パスワードを含む | 初回起動時に自動生成 |
| `~/.config/openchamber/relay-identity.json` | 鍵ペア | OpenChamber が自動生成 |
| `~/.config/openchamber/git-credential-endpoint.json` | 認証情報 | OpenChamber が自動生成 |
| Windows ユーザー環境変数 `GITHUB_PERSONAL_ACCESS_TOKEN` / `BEATAPI_API_KEY` | API キー | **ユーザーに聞いて設定する**。値はリポジトリに絶対に書かない |
| `~/.config/openchamber/settings.json` | パス・セッションIDなど個別環境の情報 | 初回起動時に自動生成 → UI や `settings.example.json` を参照して再設定 |
| `discovered-apps.json`, `tracked-items.json`, `sessions-directories.json`, `push-open-tags.json`, `opencode-trust.json` | アプリの状態・個人情報 | 自動生成 |
| `~/.local/share/opencode/**` | セッション DB・ログ・スナップショット | 復元不要 |
| `~/.config/openchamber/chats/`, `run/`, `bin/`, `managed-opencode/`, `*.sqlite*` | アプリの状態・キャッシュ | 自動生成 |
| GitHub 認証 | トークン | `gh auth login` で再ログイン |

## 3. 手順

### 3.1 前提ツールの確認/インストール

以下が無ければユーザーに確認してから入れる:

- Git (`winget install Git.Git`)
- GitHub CLI (`winget install GitHub.cli`) → `gh auth login`（ブラウザ認証）
- OpenChamber デスクトップ版（公式からインストール）
- Node.js + npx（`winget install OpenJS.NodeJS.LTS`）… playwright / markitdown 用
- uv / uvx（`winget install astral-sh.uv`）… duckduckgo / markitdown / beatSaberModdingTools 用

### 3.2 設定の復元

```powershell
git clone https://github.com/denpadokei/opencode-config-backup.git
cd opencode-config-backup
pwsh -NoProfile -ExecutionPolicy Bypass -File .\restore.ps1
```

`settings.local.json` がローカルに残っている場合は実 `settings.json` としても戻される（無ければ手動設定）。

### 3.3 シークレットの再設定

1. ユーザーに `GITHUB_PERSONAL_ACCESS_TOKEN` と `BEATAPI_API_KEY` の値を聞き、ユーザー環境変数として設定する。
   - **値をチャットやファイルに貼らせないこと**。ユーザー自身に設定してもらうか、AI は入力後に即座に破棄する。
2. `gh auth login`（またはユーザーが gh CLI で再ログイン）。
3. OpenChamber を起動してホストにログイン（`service.json` 等は自動生成される）。

### 3.4 settings.json の再設定

アプリが生成した `settings.json` に対して、最低限 UI で行うか直接編集する:

- `locale: "ja"`（UI の言語）
- `lightThemeId` / `darkThemeId`（既定テーマでOK）
- `projects` に各開発ディレクトリを登録（レシピは 4.4）
- 既定モデルは `preferences.json` が復元済み

### 3.5 痛PC MOD の再適用

```powershell
git clone https://github.com/denpadokei/openchamber-itachou-mod.git <任意の作業フォルダ>
cd <クローン先>
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Image "<ユーザーの壁紙画像>"
```

- 背景画像はリポジトリに無い。ユーザーの画像を `-Image` で指定するか `bg.jpg` に置く。
- OpenChamber を更新したら `apply-on-launch.ps1` 向けショートカットで復活する。

### 3.6 プロジェクトの再登録（settings.json 直接編集）

OpenChamber のプロジェクトは `~/.config/openchamber/settings.json` の `projects` 配列で管理される。
UI から「プロジェクトを追加」でも良いが、AI が直接追加する場合は:

1. `id` = `"path_"` + UTF-8 パス（**スラッシュ区切り**、例 `C:/Users/<you>/source/repos/<project>`）の base64（**末尾の `=` は削る**）
2. `path` / `label` / `color` / `addedAt`（epoch ms）/ `lastOpenedAt` / `labelSource: "auto"` / `sidebarCollapsed` を入れる
3. `activeProjectId` も更新する。実行中のアプリは即座に認識する
4. `session.create` は新規 projectId を渡すと "agent configuration is unavailable" で失敗することがある → **`directory` を渡して作成し、戻り値の `projectId` で紐づく**

### 3.7 メモリの復旧

エージェントの記憶（`~/.claude/projects/<project-hash>/memory/`）はバックアップ外。
新環境ではこの文書の要点を伝えて運用を引き継ぐ。

## 4. 検証チェックリスト

1. `opencode` が起動し、`/mcp` で context7・exa・github-copilot・beatapi・microsoft-learn・duckduckgo が接続、playwright・markitdown・nuget・unity が disabled
2. plugins 6種（oh-my-opencode-slim, opencode-dcp, opencode-navigator, oc-flight-deck, opencode-goal-plugin, opencode-claude-memory）が読み込まれる
3. OpenChamber UI が日本語（設定 → 外観 → Language → 日本語）
4. 痛PC MOD が効いている（`http://127.0.0.1:57123/assets/itachou.css` が 200）
5. メモリ抽出が動く（何か作業して memory が保存される）
6. （Beat Saber mod 開発をする場合）beatSaberModdingTools MCP で `build_environment` が通る

## 5. バックアップの取り方

```powershell
cd <このリポジトリのクローン先>
pwsh -NoProfile -ExecutionPolicy Bypass -File .\backup.ps1 -Push
```

設定を変えたら（MCP 追加、エージェント設定変更など）これを実行して push すること。
`backup.ps1` は `settings.json` を **git 管理外の `settings.local.json` としてのみ** ローカル保存する。
公開リポジトリに個別環境の情報が載ることはない。
