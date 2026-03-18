# cmux 调研报告

## 概述

**cmux** 是一个终端工作区管理器，专为 Claude Code 设计，用于在单个终端中管理多个 AI 智能体。

## 核心问题与解决方案

| 痛点 | cmux 方案 |
|------|----------|
| 10 个标签页难以区分 | 工作区命名 + 快速切换 |
| 上下文丢失 | 会话恢复机制 |
| 切换打断工作节奏 | 不抢占焦点的命令发送 |

## 三大核心功能

### 1. 工作区管理
```bash
cmux list-workspaces           # 列出所有工作区
cmux new-workspace             # 创建新工作区
cmux rename-workspace          # 重命名
cmux select-workspace         # 切换
cmux close-workspace           # 关闭
```

### 2. 编排器模式
主智能体可生成并控制其他智能体，支持：
- 发送命令到任意工作区
- 读取任意智能体的屏幕输出
- 会话自动映射（Hook 脚本）

### 3. Obsidian 仪表板
自动构建的可视化面板，展示：
- 每个智能体正在做什么
- 需要关注的事项

## 关键特性

- **无焦点抢占**：创建/恢复会话时不切换当前视图
- **自动循环**：支持 60% 上下文自动handoff（--loop 参数）
- **Socket API**：通过 Unix socket `/tmp/cmux.sock` 编程控制
- **会话映射**：Hook 自动追踪 Claude Code 会话与工作区的对应关系

## 安装使用

1. 保存为 `.claude/skills/cmux/SKILL.md`
2. 可选脚本：
   - `spawn-workspace.sh` - 快速创建命名工作区
   - `cmux-session-map.py` - 会话映射 Hook

## 适用场景

- 多任务并行处理（研究、文案、视频脚本）
- 需要同时监控多个智能体工作状态
- 避免标签页切换打断工作流

## 参考链接

- 官网：https://www.cmux.dev
- 文档：https://www.cmux.dev/docs/api
- 原文：https://cmux-artemzhutov.netlify.app/skills/cmux.md
