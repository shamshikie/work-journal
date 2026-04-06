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

mkdir -p "$DAILY_DIR"

if [ -f "$OUTPUT_FILE" ]; then
  echo "すでに存在します: $OUTPUT_FILE"
  exit 0
fi

cat > "$OUTPUT_FILE" << EOF
---
date: $DATE
week: W$WEEK
month: $YEAR_MONTH
half: ${FISCAL_YEAR}-${HALF}
---

# 日報 $DATE

## 作業内容

## 詰まったこと・メモ

## 明日やること
EOF

echo "作成しました: $OUTPUT_FILE"
