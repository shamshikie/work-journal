---
date: <% tp.date.now("YYYY-MM-DD") %>
week: W<% tp.date.now("WW") %>
month: <% tp.date.now("YYYY-MM") %>
half: <%* const m = parseInt(tp.date.now("M")); const y = parseInt(tp.date.now("YYYY")); tR += (m >= 4 ? y : y-1) + "-" + (m >= 4 && m <= 9 ? "H1" : "H2"); %>
---

# 日報 <% tp.date.now("YYYY-MM-DD") %>

## 予定

## 今日やること

## タスクキュー

## メモ

## 日報
