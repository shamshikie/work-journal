#!/bin/bash
# 今日（または指定日）の日報ファイルを作成する
# 使い方: ./scripts/new_daily.sh [-d N|YYYY-MM-DD]
#         -d N          N日前の日報を作成
#         -d YYYY-MM-DD 指定日の日報を作成
set -e

REF_DATE=$(date +%Y-%m-%d)

while getopts "d:" opt; do
  case $opt in
    d)
      if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
        REF_DATE=$(date -d "$OPTARG days ago" +%Y-%m-%d)
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

DATE=$REF_DATE
YEAR=$(date -d "$REF_DATE" +%Y)
MONTH=$(date -d "$REF_DATE" +%-m)
YEAR_MONTH=$(date -d "$REF_DATE" +%Y-%m)
WEEK=$(date -d "$REF_DATE" +%V)

# 年度・半期を判定（4月始まり）
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
