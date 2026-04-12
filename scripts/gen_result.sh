#!/bin/bash
# 半期達成結果を生成する（目標に対する達成・結果をまとめる）
# 使い方: ./scripts/gen_review.sh [FISCAL_YEAR] [HALF]
# 例:     ./scripts/gen_review.sh          # 現在の年度・半期
#         ./scripts/gen_review.sh 2026 H1  # 指定した年度・半期
set -e

YEAR=$(date +%Y)
MONTH=$(date +%-m)

# 引数で年度・半期を指定できる
if [ -n "$1" ] && [ -n "$2" ]; then
  FISCAL_YEAR=$1
  HALF=$2
else
  # 現在の年度・半期を自動判定
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
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# frontmatter（--- ... ---）を除去して本文だけ返す
strip_frontmatter() {
  awk 'NR==1&&/^---$/{fm=1;next} fm&&/^---$/{fm=0;next} !fm{print}' "$1"
}
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$ROOT_DIR/01_journal/$FISCAL_YEAR/$HALF"
GOALS_FILE="$ROOT_DIR/02_goals/${FISCAL_YEAR}/${FISCAL_YEAR}-${HALF}.md"
MONTHLY_DIR="$BASE_DIR/monthly"
RESULT_DIR="$ROOT_DIR/02_goals/${FISCAL_YEAR}"
OUTPUT_FILE="$RESULT_DIR/${FISCAL_YEAR}-${HALF}-result.md"

mkdir -p "$RESULT_DIR"

# goals.md の存在確認
if [ ! -f "$GOALS_FILE" ]; then
  echo "目標ファイルが見つかりません: $GOALS_FILE"
  exit 1
fi

if [ -f "$OUTPUT_FILE" ]; then
  echo "すでに存在します: $OUTPUT_FILE"
  echo "上書きしますか？ (y/N)"
  read -r ANSWER
  if [ "$ANSWER" != "y" ]; then
    exit 0
  fi
fi

# 月報を収集（なければ日報にフォールバック）
echo "${FISCAL_YEAR}-${HALF} の達成結果を生成中..."
PERIOD_CONTENT=""

if [ -d "$MONTHLY_DIR" ] && [ -n "$(ls "$MONTHLY_DIR"/*.md 2>/dev/null)" ]; then
  echo "月報を使用します"
  for f in "$MONTHLY_DIR"/*.md; do
    [ -f "$f" ] || continue
    PERIOD_CONTENT="$PERIOD_CONTENT
---
$(strip_frontmatter "$f")
"
  done
else
  echo "月報が見つかりません。日報から直接生成します"
  DAILY_DIR="$BASE_DIR/daily"
  if [ -d "$DAILY_DIR" ]; then
    while IFS= read -r -d '' f; do
      PERIOD_CONTENT="$PERIOD_CONTENT
---
$(strip_frontmatter "$f")
"
    done < <(find "$DAILY_DIR" -name "*.md" -not -name ".gitkeep" -print0 2>/dev/null)
  fi
fi

if [ -z "$PERIOD_CONTENT" ]; then
  echo "日報・月報が見つかりません"
  exit 1
fi

GOALS_CONTENT=$(cat "$GOALS_FILE")

# 半期の表示名
if [ "$HALF" = "H1" ]; then
  HALF_LABEL="上期"
  if [ "$FISCAL_YEAR" -ge 2026 ]; then
    PERIOD_LABEL="${FISCAL_YEAR}年4月〜9月"
  fi
else
  HALF_LABEL="下期"
  NEXT_YEAR=$((FISCAL_YEAR + 1))
  PERIOD_LABEL="${FISCAL_YEAR}年10月〜${NEXT_YEAR}年3月"
fi

RESULT_CONTENT=$(printf '%s\n\n%s\n' \
"以下の目標と業務記録を読み、各目標について評価してください。
各目標に対して「### 目標名」「取り組んだこと（箇条書き）」「達成度・結果（一言）」の形式で出力してください。
見出しと内容のみ出力。前置き・後書き・説明文・案内文は一切不要。

目標：
$GOALS_CONTENT" \
"業務記録：
$PERIOD_CONTENT" | ollama run qwen2.5:7b)

cat > "$OUTPUT_FILE" << EOF
# ${HALF_LABEL}達成結果 ${FISCAL_YEAR}-${HALF}（${PERIOD_LABEL}）

$RESULT_CONTENT
EOF

echo "作成しました: $OUTPUT_FILE"