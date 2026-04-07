# work-journal

日報をベースに週報・月報・半期レビューを自動生成する個人用ワークログ。

## ディレクトリ構成

```
work-journal/
├── TODO.md                    # 持ち越しタスクのみ管理
├── templates/                 # 各種テンプレート
├── scripts/                   # 自動化スクリプト
└── YYYY/
    ├── H1/                    # 上期（4〜9月）
    │   ├── goals.md           # 上期目標
    │   ├── daily/YYYY-MM/     # 日報
    │   ├── weekly/            # 週報（自動生成）
    │   ├── monthly/           # 月報（自動生成）
    │   └── review/            # 半期レビュー（自動生成）
    └── H2/                    # 下期（10〜3月）
        └── ...
```

## セットアップ

```bash
git init
git add .
git commit -m "initial commit"

# Ollamaのインストール（週報・月報・レビュー生成に使用）
# https://ollama.com
ollama pull qwen2.5:7b
```

## 使い方

### 毎日

```bash
# 日報ファイルを作成
./scripts/new_daily.sh

# gitコミットを確認して日報記入の補助に使う
./scripts/commit_summary.sh ~/repos/your-project
```

### 毎週

```bash
./scripts/gen_weekly.sh
```

### 毎月

```bash
./scripts/gen_monthly.sh
```

### 半期末

```bash
# 現在の半期のレビューを生成
./scripts/gen_review.sh

# 過去の半期を指定
./scripts/gen_review.sh 2026 H1
```

## TODO管理

- `TODO.md` には**複数日にまたがるタスク**のみ書く
- 完了したら削除して `git commit -m "done: タスク名"`
- 当日完結したタスクは日報に直接書く
- 過去の完了タスクは `git log TODO.md` で確認

## 日報の書き方

- frontmatterは `new_daily.sh` が自動生成するので触らない
- セクションは書きたい項目だけ埋めれば良い
- プロジェクト名やタグは書きたいときだけ本文に自由に書く

## 年度・半期の自動判定

スクリプトは4月始まりの日本の会計年度で動作する。

| 実行する月 | 保存先ディレクトリ |
|---|---|
| 4〜9月（例: 2026年5月） | `2026/H1/` |
| 10〜12月（例: 2026年11月） | `2026/H2/` |
| 1〜3月（例: 2027年2月） | `2026/H2/` |
