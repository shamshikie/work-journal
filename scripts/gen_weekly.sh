#!/bin/bash
# 指定週の日報からOllamaで週報を生成する
# 使い方: ./scripts/gen_weekly.sh [-d YYYY-MM-DD]
#         -d YYYY-MM-DD 指定日を含む週の週報を生成
set -e

REF_DATE=$(date +%Y-%m-%d)

while getopts "d:" opt; do
  case $opt in
    d) REF_DATE="$OPTARG" ;;
    *)
      echo "使い方: $0 [-d YYYY-MM-DD]"
      exit 1
      ;;
  esac
done

YEAR=$(date -d "$REF_DATE" +%Y)
MONTH=$(date -d "$REF_DATE" +%-m)
WEEK=$(date -d "$REF_DATE" +%V)

# REF_DATE の週の月曜・日曜を計算
DOW=$(date -d "$REF_DATE" +%u)  # 1=月〜7=日
WEEK_START=$(date -d "$REF_DATE - $((DOW - 1)) days" +%m/%d)
WEEK_END=$(date -d "$REF_DATE + $((7 - DOW)) days" +%m/%d)

# 年度・半期を判定
if [ "$MONTH" -ge 4 ]; then
  FISCAL_YEAR=$YEAR
  if [ "$MONTH" -le 9 ]; then
    HALF="H1"
  else
    HALF="H2"
  fi
else
  FISCAL_YEAR=$((YEAR - 1))
  HALF="H2"
fi

# frontmatter（--- ... ---）を除去して本文だけ返す
strip_frontmatter() {
  awk 'NR==1&&/^---$/{fm=1;next} fm&&/^---$/{fm=0;next} !fm{print}' "$1"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DAILY_DIR="$ROOT_DIR/$FISCAL_YEAR/$HALF/daily"
WEEKLY_DIR="$ROOT_DIR/$FISCAL_YEAR/$HALF/weekly"
OUTPUT_FILE="$WEEKLY_DIR/W${WEEK}.md"
TEMPLATE_FILE="$ROOT_DIR/templates/weekly.md"

mkdir -p "$WEEKLY_DIR"

if [ -f "$OUTPUT_FILE" ]; then
  echo "すでに存在します: $OUTPUT_FILE"
  echo "上書きしますか？ (y/N)"
  read -r ANSWER
  if [ "$ANSWER" != "y" ]; then
    exit 0
  fi
fi

# 指定週の日報を収集
echo "W${WEEK}（${WEEK_START}〜${WEEK_END}）の日報を収集中..."
DAILY_CONTENT=""
while IFS= read -r -d '' file; do
  FILE_DATE=$(basename "$file" .md)
  FILE_WEEK=$(date -d "$FILE_DATE" +%V 2>/dev/null)
  if [ "$FILE_WEEK" = "$WEEK" ]; then
    DAILY_CONTENT="$DAILY_CONTENT

---
$(cat "$file")"
  fi
done < <(find "$DAILY_DIR" -name "*.md" -not -name ".gitkeep" -print0 2>/dev/null)

if [ -z "$DAILY_CONTENT" ]; then
  echo "指定週の日報が見つかりません"
  exit 1
fi

echo "週報を生成中..."

FORMAT=$(strip_frontmatter "$TEMPLATE_FILE" | grep "^##")

WEEKLY_CONTENT=$(printf '%s\n\n%s\n' \
"以下の日報を読み、週報として3つのセクションにまとめてください。
・## 今週やったこと: 全日報の作業内容を統合・箇条書きで要約
・## 詰まったこと・課題: 全日報の詰まったこと・メモを統合・箇条書きで要約
・## 来週やること: 全日報の明日やることから来週を箇条書きで要約
##見出し＋内容のみ出力。前置き・後書き・説明文・案内文は一切不要。

フォーマット：
$FORMAT
" \
"日報：
$DAILY_CONTENT" | ollama run qwen2.5:7b)

cat > "$OUTPUT_FILE" << EOF
---
week: ${FISCAL_YEAR}-W${WEEK}
half: ${FISCAL_YEAR}-${HALF}
---

# 週報 ${FISCAL_YEAR}-W${WEEK}（${WEEK_START}〜${WEEK_END}）

$WEEKLY_CONTENT
EOF

echo "作成しました: $OUTPUT_FILE"