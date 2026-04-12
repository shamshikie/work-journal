---
date: <% tp.date.now("YYYY-MM-DD") %>
week: W<% tp.date.now("WW") %>
month: <% tp.date.now("YYYY-MM") %>
half: <%* const m = parseInt(tp.date.now("M")); const y = parseInt(tp.date.now("YYYY")); tR += (m >= 4 ? y : y-1) + "-" + (m >= 4 && m <= 9 ? "H1" : "H2"); %>
---
<%*
const today = tp.date.now("YYYY-MM-DD");
const vault = app.vault;
let bodyContent = null;

function getDailyPath(m) {
  const year = m.year();
  const monthNum = m.month() + 1;
  const fiscalYear = monthNum >= 4 ? year : year - 1;
  const half = (monthNum >= 4 && monthNum <= 9) ? "H1" : "H2";
  const mmStr = m.format("YYYY-MM");
  const dateStr = m.format("YYYY-MM-DD");
  return `10_journal/${fiscalYear}/${half}/daily/${mmStr}/${dateStr}.md`;
}

for (let i = 1; i <= 60; i++) {
  const prev = moment(today).subtract(i, "days");
  const file = vault.getAbstractFileByPath(getDailyPath(prev));
  if (file) {
    const raw = await vault.read(file);
    const m = raw.match(/^---\n[\s\S]*?\n---\n([\s\S]*)$/);
    bodyContent = m ? m[1] : raw;
    break;
  }
}

if (bodyContent !== null) {
  tR += bodyContent.trimEnd();
} else {
  tR += `# 日報\n\n## 今日やること\n\n## タスクキュー\n\n- [ ] タスク名 #p/プロジェクト #area/領域\n\n## メモ\n\n## 日報`;
}
_%>
