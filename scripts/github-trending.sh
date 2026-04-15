#!/bin/bash
# GitHub Trending 调研脚本
# 每30分钟执行一次

WORKSPACE="/root/.openclaw/workspace-research"
cd "$WORKSPACE"

echo "=== 开始 GitHub Trending 调研 ==="
DATE=$(date "+%Y-%m-%d %H:%M")
SINCE_DATE=$(date -d '7 days ago' +%Y-%m-%d)

# 获取本周飙升项目 (按 stars 排序)
TRENDING=$(gh api "search/repositories?q=created:>$SINCE_DATE&sort=stars&order=desc" --jq '.items[:15] | .[] | "\(.full_name)|\(.stargazers_count)|\(.language // "N/A")|\(.description // "N/A")"' 2>/dev/null)

# 获取今日新项目
TODAY=$(date +%Y-%m-%d)
NEW_PROJECTS=$(gh api "search/repositories?q=created:>$TODAY&sort=stars&order=desc" --jq '.items[:10] | .[] | "\(.full_name)|\(.stargazers_count)|\(.language // "N/A")|\(.description // "N/A")"' 2>/dev/null)

# 生成报告
REPORT="# GitHub Trending 调研报告

> 采集时间: $DATE

## 本周热门飙升 (Top 15)

| 项目 | ⭐ | 语言 | 描述 |
|------|-----|------|------|
$(echo "$TRENDING" | while IFS='|' read -r name stars lang desc; do
  if [[ -n "$name" ]]; then
    echo "| [$name](https://github.com/$name) | $stars | $lang | ${desc:0:80} |"
  fi
done)

## 今日新增 (Top 10)

| 项目 | ⭐ | 语言 | 描述 |
|------|-----|------|------|
$(echo "$NEW_PROJECTS" | while IFS='|' read -r name stars lang desc; do
  if [[ -n "$name" ]]; then
    echo "| [$name](https://github.com/$name) | $stars | $lang | ${desc:0:80} |"
  fi
done)

---
*自动采集于 GitHub Trending | $DATE*
"

# 写入报告
echo "$REPORT" > "$WORKSPACE/docs/github-trending.md"

# 添加并提交
git add docs/github-trending.md
git commit -m "Update GitHub Trending - $DATE" 2>/dev/null

# 推送到远程
git push origin master 2>/dev/null

echo "=== 调研完成，已推送 ==="
