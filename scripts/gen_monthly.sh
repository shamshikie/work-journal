#!/bin/bash
# 指定月の日報からOllamaで月報を生成する
# 使い方: ./scripts/gen_monthly.sh [-d YYYY-MM-DD]
#         -d YYYY-MM-DD 指定日を含む月の月報を生成
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
YEAR_MONTH=$(date -d "$REF_DATE" +%Y-%m)
MONTH_LABEL=$(date -d "$REF_DATE" +%Y年%-m月)

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
DAILY_DIR="$ROOT_DIR/01_journal/$FISCAL_YEAR/$HALF/daily/$YEAR_MONTH"
MONTHLY_DIR="$ROOT_DIR/01_journal/$FISCAL_YEAR/$HALF/monthly"
OUTPUT_FILE="$MONTHLY_DIR/${YEAR_MONTH}.md"
GOALS_FILE="$ROOT_DIR/02_goals/${FISCAL_YEAR}/${FISCAL_YEAR}-${HALF}.md"
TEMPLATE_FILE="$ROOT_DIR/00_templates/monthly.md"

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
  echo "指定月の日報ディレクトリが見つかりません: $DAILY_DIR"
  exit 1
fi

echo "${YEAR_MONTH}の日報を収集中..."
DAILY_CONTENT=""
for f in "$DAILY_DIR"/*.md; do
  [ -f "$f" ] || continue
  DAILY_CONTENT="$DAILY_CONTENT
---
$(strip_frontmatter "$f")
"
done

if [ -z "$DAILY_CONTENT" ]; then
  echo "指定月の日報が見つかりません"
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

FORMAT=$(strip_frontmatter "$TEMPLATE_FILE" | grep "^##" | sed "s/HX/${HALF}/g")

MONTHLY_CONTENT=$(printf '%s\n\n%s\n' \
"以下の日報を読み、月報として3つのセクションにまとめてください。
・## 今月の作業サマリー: 全日報の作業内容をプロジェクト別に統合・要約
・## 目標（${HALF}）への進捗: ${GOALS_SECTION:+上記の目標内容と照らし合わせて進捗を評価}
・## 課題・来月に持ち越すこと: 全日報の詰まったこと・明日やることを統合・要約
##見出し＋内容のみ出力。前置き・後書き・説明文・案内文は一切不要。

フォーマット：
$FORMAT
" \
"${GOALS_SECTION}日報：
$DAILY_CONTENT" | ollama run qwen2.5:7b)

cat > "$OUTPUT_FILE" << EOF
---
month: ${YEAR_MONTH}
half: ${FISCAL_YEAR}-${HALF}
---

# 月報 ${MONTH_LABEL}

$MONTHLY_CONTENT
EOF

echo "作成しました: $OUTPUT_FILE"