#!/bin/bash
# 今月の日報からOllamaで月報を生成する
set -e

YEAR=$(date +%Y)
MONTH=$(date +%-m)
MONTH_PADDED=$(date +%m)
YEAR_MONTH=$(date +%Y-%m)
MONTH_LABEL=$(date +%Y年%-m月)

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
DAILY_DIR="$ROOT_DIR/$FISCAL_YEAR/$HALF/daily/$YEAR_MONTH"
MONTHLY_DIR="$ROOT_DIR/$FISCAL_YEAR/$HALF/monthly"
OUTPUT_FILE="$MONTHLY_DIR/${YEAR_MONTH}.md"
GOALS_FILE="$ROOT_DIR/$FISCAL_YEAR/$HALF/goals.md"
TEMPLATE_FILE="$ROOT_DIR/templates/monthly.md"

mkdir -p "$MONTHLY_DIR"

if [ -f "$OUTPUT_FILE" ]; then
  echo "すでに存在します: $OUTPUT_FILE"
  echo "上書きしますか？ (y/N)"
  read -r ANSWER
  if [ "$ANSWER" != "y" ]; then
    exit 0
  fi
fi

if [ ! -d "$DAILY_DIR" ]; then
  echo "今月の日報ディレクトリが見つかりません: $DAILY_DIR"
  exit 1
fi

echo "${YEAR_MONTH}の日報を収集中..."
DAILY_CONTENT=$(cat "$DAILY_DIR"/*.md 2>/dev/null || true)

if [ -z "$DAILY_CONTENT" ]; then
  echo "今月の日報が見つかりません"
  exit 1
fi

# 目標ファイルを読み込む
GOALS_SECTION=""
if [ -f "$GOALS_FILE" ]; then
  GOALS_SECTION="目標（${HALF}）：
$(cat "$GOALS_FILE")
"
fi

echo "月報を生成中..."

FORMAT=$(grep "^##" "$TEMPLATE_FILE" | sed "s/HX/${HALF}/g")

MONTHLY_CONTENT=$(echo "以下は今月の日報です。以下のフォーマットで月報を日本語で作成してください。
フォーマット：
$FORMAT

${GOALS_SECTION}日報：
$DAILY_CONTENT" | ollama run qwen2.5:7b)

cat > "$OUTPUT_FILE" << EOF
# 月報 ${MONTH_LABEL}

$MONTHLY_CONTENT
EOF

echo "作成しました: $OUTPUT_FILE"
