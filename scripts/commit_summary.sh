#!/bin/bash
# 指定リポジトリの今日のコミットを一覧表示する
# 使い方: ./scripts/commit_summary.sh <リポジトリのパス> [日付]
# 例:     ./scripts/commit_summary.sh ~/repos/my-project
#         ./scripts/commit_summary.sh ~/repos/my-project 2026-04-01

REPO=${1:-}
DATE=${2:-$(date +%Y-%m-%d)}

if [ -z "$REPO" ]; then
  echo "使い方: $0 <リポジトリのパス> [日付]"
  echo "例:     $0 ~/repos/my-project"
  exit 1
fi

if [ ! -d "$REPO/.git" ]; then
  echo "エラー: gitリポジトリが見つかりません: $REPO"
  exit 1
fi

echo "=== $(basename "$REPO") のコミット ($DATE) ==="

AUTHOR=$(git config --global user.email)
COMMITS=$(git -C "$REPO" log \
  --after="$DATE 00:00:00" \
  --before="$DATE 23:59:59" \
  --author="$AUTHOR" \
  --format="%h %s" \
  --all)

if [ -z "$COMMITS" ]; then
  echo "（コミットなし）"
  exit 0
fi

echo "$COMMITS" | while read -r line; do
  echo "- $line"
done
