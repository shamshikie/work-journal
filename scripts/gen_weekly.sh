#!/bin/bash
# 指定週の日報からOllamaで週報を生成する
# 使い方: ./scripts/gen_weekly.sh [-d N|YYYY-MM-DD]
#         -d N          N週前の週報を生成
#         -d YYYY-MM-DD 指定日を含む週の週報を生成
set -e

REF_DATE=$(date +%Y-%m-%d)

while getopts "d:" opt; do
  case $opt in
    d)
      if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
        REF_DATE=$(date -d "$OPTARG weeks ago" +%Y-%m-%d)
      else
        REF_DATE="$OPTARG"
      fi
      ;;
    *)
      echo "使い方: $0 [-d N|YYYY-MM-DD]"
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
  FILE_DATE=$(grep "^date:" "$file" | sed 's/date: //' | tr -d '[:space:]')
  if [ -n "$FILE_DATE" ]; then
    FILE_WEEK=$(date -d "$FILE_DATE" +%V 2>/dev/null)
    if [ "$FILE_WEEK" = "$WEEK" ]; then
      DAILY_CONTENT="$DAILY_CONTENT

---
$(cat "$file")"
    fi
  fi
done < <(find "$DAILY_DIR" -name "*.md" -not -name ".gitkeep" -print0 2>/dev/null)

if [ -z "$DAILY_CONTENT" ]; then
  echo "指定週の日報が見つかりません"
  exit 1
fi

echo "週報を生成中..."

FORMAT=$(grep "^##" "$TEMPLATE_FILE")

WEEKLY_CONTENT=$(echo "以下は今週の日報です。以下のフォーマットで週報を日本語で作成してください。
フォーマット：
$FORMAT

日報：
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
