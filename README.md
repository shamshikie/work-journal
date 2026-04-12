# work-journal

Obsidianで日報を書き、週報・月報をスクリプトで自動生成する個人用ワークログ。

## ディレクトリ構成

```
work-journal/
├── .obsidian/             # Obsidian設定（GitHubで管理）
├── 00_templates/          # テンプレート
│   ├── daily.md           # 日報テンプレート（Templater構文）
│   ├── weekly.md          # 週報テンプレート
│   ├── monthly.md         # 月報テンプレート
│   ├── goals.md           # 目標テンプレート
│   └── 1on1.md            # 1on1ノートテンプレート
├── 01_journal/            # 年次ジャーナル
│   └── YYYY/
│       ├── H1/            # 上期ログ（4〜9月）
│       │   ├── daily/YYYY-MM/ # 日報
│       │   ├── weekly/    # 週報（スクリプト生成）
│       │   └── monthly/   # 月報（スクリプト生成）
│       └── H2/            # 下期ログ（10〜3月）
│           └── ...
├── 02_goals/              # 目標管理
│   ├── career.md          # 長期・キャリア目標
│   └── YYYY/              # 年度ごと
│       ├── YYYY-H1.md     # 上期目標（4〜9月）
│       ├── YYYY-H2.md     # 下期目標（10〜3月）
│       ├── YYYY-H1-result.md  # 上期達成結果（スクリプト生成）
│       └── YYYY-H2-result.md  # 下期達成結果（スクリプト生成）
├── 03_people/             # 同僚との関係管理ノート
├── 04_misc/               # 分類不要なメモ・雑記
└── scripts/               # 自動化スクリプト
```

## セットアップ

### 1. Obsidianで開く

Obsidian を起動 → **「Open folder as vault」** でこのリポジトリを選択。

### 2. プラグインをインストール

設定 → **Community plugins** → **Turn on community plugins** → **Browse** で以下をインストール・有効化：

| プラグイン | 優先度 | 用途 |
|---|---|---|
| **Calendar**（by Liam Cain） | 必須 | カレンダーUIから日報を作成 |
| **Templater**（by SilentVoid） | 必須 | 日報作成時にfrontmatterを自動入力 |
| **Dataview**（by Michael Brenan） | 推奨 | frontmatterやタグでノートを集計・一覧化 |
| **Git**（by Vinzent） | 推奨 | Obsidian内からgit commit/pushを操作 |

インストール後、左サイドバーにカレンダーが表示される。

### 3. GitHub Copilot CLIのセットアップ（週報・月報の生成に必要）

```bash
# gh CLIにCopilot拡張を追加（未インストールの場合）
gh extension install github/gh-copilot
```

## 毎日の使い方

### 日報を作成する

1. **Calendarの今日の日付をクリック** → `01_journal/2026/H1/daily/2026-04/2026-04-12.md` が作成される
2. Templaterが自動でfrontmatterと日付見出しを今日の値に展開する
3. **前日のファイルを全選択コピー → 今日のファイルに貼り付け**（frontmatterと見出しは今日のものに上書きされているので編集不要）
4. 今日の内容に編集していく

### タスクキューの運用

```markdown
## タスクキュー
- [ ] 未着手のタスク
- [x] 完了したタスク（日報セクションに記録してから消す）
- [-] やらなくてよくなったタスク（drop）
- [/] 進行中のタスク
```

## 週報・月報の生成（GitHub Copilot CLI Skills）

`gh copilot chat` を起動後、以下のスラッシュコマンドで呼び出す：

```
# 今週の週報を生成
/gen-weekly

# 今月の月報を生成（02_goals/YYYY/YYYY-HX.md を参照）
/gen-monthly

# 半期達成結果を生成（02_goals/YYYY/YYYY-HX.md を参照）
/gen-result

# 過去の日付を指定する場合
/gen-weekly 2026-04-07
/gen-monthly 2026-03-15
/gen-result 2026 H1
```

Skillsは `.github/skills/` に格納されており、Copilotのautopilotモードがファイルを自動で読み書きする。

## コミットサマリーの生成

### Skillsで生成（推奨）

`gh copilot chat` を起動後：

```
/commit-summary ~/repos/my-project
/commit-summary ~/repos/my-project 2026-04-07
```

### スクリプトで一覧のみ出力

```bash
# 今日のコミット一覧を出力
./scripts/commit_summary.sh ~/repos/my-project

# 特定日のコミット一覧を出力
./scripts/commit_summary.sh ~/repos/my-project 2026-04-07
```

## 目標管理

`02_goals/` フォルダに半期ごとの目標と長期目標をまとめる。

| ファイル | 内容 |
|---|---|
| `02_goals/2026/2026-H1.md` | 上期（4〜9月）の目標 |
| `02_goals/2026/2026-H2.md` | 下期（10〜3月）の目標 |
| `02_goals/career.md` | 長期・キャリア目標 |

新しい半期が始まったら `00_templates/goals.md` をコピーして `02_goals/YYYY/YYYY-HX.md` を作成する。  
達成結果は `gen_review.sh` が `02_goals/YYYY/YYYY-HX-result.md` に生成する。

## 半期切り替え時の対応（年2回）

H2（10月）になったら Obsidian の設定を変更する：

設定 → **Daily notes** → **New file location** を `01_journal/2026/H2/daily` に変更。

## GitHub管理について

`.obsidian/` の以下は**コミット対象**：
- `app.json`、`core-plugins.json`、`community-plugins.json`
- `daily-notes.json`、`templates.json`
- `plugins/calendar/data.json`、`plugins/templater-obsidian/data.json`

以下は**除外**（`.gitignore` で設定済み）：
- `workspace.json`（ウィンドウ状態）
- `cache/`、プラグインバイナリ（`main.js` など）

プラグイン本体はGit管理しないため、別環境では再インストールが必要。

## 年度・半期の判定ルール

スクリプトは4月始まりの日本の会計年度で動作する。

| 実行する月 | 保存先ディレクトリ |
|---|---|
| 4〜9月（例: 2026年5月） | `01_journal/2026/H1/` |
| 10〜12月（例: 2026年11月） | `01_journal/2026/H2/` |
| 1〜3月（例: 2027年2月） | `01_journal/2026/H2/` |
