#!/bin/bash
# 今日の日報ファイルを作成する
set -e

DATE=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
MONTH=$(date +%-m)
MONTH_PADDED=$(date +%m)
YEAR_MONTH=$(date +%Y-%m)
WEEK=$(date +%V)

# 年度・半期を判定（4月始まり）
if [ "$MONTH" -ge 4 ]; then
  FISCAL_YEAR=$YEAR
  if [ "$MONTH" -le 9 ]; then
    HALF="H1"
  else
    HALF="H2"
  fi
else
  # 1〜3月は前年度のH2
  FISCAL_YEAR=$((YEAR - 1))
  HALF="H2"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DAILY_DIR="$ROOT_DIR/$FISCAL_YEAR/$HALF/daily/$YEAR_MONTH"
OUTPUT_FILE="$DAILY_DIR/$DATE.md"
TEMPLATE_FILE="$ROOT_DIR/templates/daily.md"

mkdir -p "$DAILY_DIR"

if [ -f "$OUTPUT_FILE" ]; then
  echo "すでに存在します: $OUTPUT_FILE"
  exit 0
fi

sed \
  -e "s/YYYY-MM-DD/$DATE/g" \
  -e "s/WXX/W$WEEK/g" \
  -e "s/YYYY-MM/$YEAR_MONTH/g" \
  -e "s/YYYY-HX/${FISCAL_YEAR}-${HALF}/g" \
  "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "作成しました: $OUTPUT_FILE"
