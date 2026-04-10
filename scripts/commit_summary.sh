#!/bin/bash
# 指定リポジトリの今日のコミットを一覧表示し、Ollamaで要約する
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

COMMITS=$(git -C "$REPO" log \
  --after="$DATE 00:00:00" \
  --before="$DATE 23:59:59" \
  --format="%h %s" \
  --all)

if [ -z "$COMMITS" ]; then
  echo "（コミットなし）"
  exit 0
fi

echo "$COMMITS" | while read -r line; do
  echo "- $line"
done

# Ollamaが使える場合は要約する
if command -v ollama &> /dev/null; then
  COMMIT_MSGS=$(git -C "$REPO" log \
    --after="$DATE 00:00:00" \
    --before="$DATE 23:59:59" \
    --format="----%n%h%n%B" \
    --all)
  echo ""
  echo "--- Ollama要約 ---"
  echo "$COMMIT_MSGS" | ollama run qwen2.5:7b \
    "以下のgitコミットメッセージを日本語で箇条書きでまとめてください："
fi

echo ""
read -r -p "Enterキーで終了..."
