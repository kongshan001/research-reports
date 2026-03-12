# Companion - Claude Code Web UI

> 开源 Web UI for Claude Code & Codex，无需 API Key，直接使用现有订阅

## 1. 背景需求

Claude Code 作为命令行工具功能强大，但 CLI 界面存在以下局限：
- 单一会话，无法并行处理多任务
- 工具调用过程不透明
- 会话崩溃后无法恢复
- 缺乏可视化界面

Companion 通过逆向 CLI 隐藏的 WebSocket 协议，为 Claude Code 提供 Web 界面。

## 2. 目标

- 提供 Web 端 UI，无需 API Key
- 支持多会话并行
- 工具调用可视化
- 会话崩溃恢复
- 双向支持 Claude Code 和 Codex

## 3. 设计方案

### 技术架构

```
┌─────────────────────────────────────────────────────────┐
│                    Browser (React)                      │
│                   http://localhost:3456                 │
└─────────────────────┬───────────────────────────────────┘
                      │ WebSocket
                      │ ws://localhost:3456/ws/browser/:session
┌─────────────────────▼───────────────────────────────────┐
│              Companion Server (Bun + Hono)              │
│                   ws://localhost:3456/ws/cli/:session   │
└─────────────────────┬───────────────────────────────────┘
                      │ NDJSON Events
                      │ CLI --sdk-url WebSocket 协议
┌─────────────────────▼───────────────────────────────────┐
│              Claude Code / Codex CLI                    │
└─────────────────────────────────────────────────────────┘
```

### 核心功能

| 功能 | 说明 |
|------|------|
| Parallel sessions | 多会话并行，无需切换终端 |
| Full visibility | 实时流式输出、工具调用、工具结果可视化 |
| Permission control | 敏感操作需 UI 审批 |
| Session recovery | 进程/服务器重启后恢复工作 |
| Dual-engine | 支持 Claude Code 和 Codex |

### 认证机制

- 首次启动自动生成 auth token，存储在 `~/.companion/auth.json`
- 支持手动管理 token
- 支持环境变量 `COMPANION_AUTH_TOKEN`

## 4. 本地部署

### 方式一：直接运行（推荐）

```bash
# 安装 Bun (如果未安装)
curl -fsSL https://bun.sh/install | bash

# 运行
bunx the-companion

# 访问
open http://localhost:3456
```

### 方式二：全局安装

```bash
bun install -g the-companion
the-companion
```

### 方式三：后台服务

```bash
# 注册为后台服务 (macOS launchd / Linux systemd)
the-companion install

# 启动服务
the-companion start

# 访问
open http://localhost:3456
```

### Docker 部署

```bash
# Preview 构建
docker run -p 3456:3456 docker.io/stangirard/the-companion:preview-main

# Stable 构建
docker run -p 3456:3456 the-companion
```

## 5. 效果展示

### 界面功能

```
┌──────────────────────────────────────────────┐
│  Companion - Claude Code UI                 │
├──────────────────────────────────────────────┤
│  [Session 1] [Session 2] [+]               │
├──────────────────────────────────────────────┤
│  💬 Message history...                       │
│                                              │
│  🔧 Tool calls:                              │
│  ├── read file: src/main.py                 │
│  ├── exec: python main.py                   │
│  └── write: Output saved                    │
│                                              │
│  ⚠️ Permission: Approve/Deny?               │
│  [Approve] [Deny]                           │
└──────────────────────────────────────────────┘
```

### 部署效果

- 多会话并行处理任务
- 实时查看工具调用链
- 敏感操作审批确认
- 崩溃后无缝恢复

## 6. 优缺点分析

### 优点

- ✅ 无需 API Key，使用现有 Claude 订阅
- ✅ Web 界面，跨设备访问
- ✅ 多会话并行
- ✅ 工具调用完全透明
- ✅ 会话恢复
- ✅ 开源 MIT 协议

### 缺点

- ⚠️ 需要本地运行 Claude Code CLI
- ⚠️ 本地部署，无法远程访问
- ⚠️ 需要 Bun 运行时
- ⚠️ WebSocket 协议逆向工程，未来可能失效

## 7. 平替对比

| 方案 | 类型 | API Key | 多会话 | 可视化 | 部署方式 |
|------|------|---------|--------|--------|---------|
| Companion | Web UI | ❌ 无需 | ✅ | ✅ 完整 | 本地 Bun |
| Claude Desktop | 官方桌面 | ✅ 需要 | ❌ | ⚠️ 有限 | 桌面应用 |
| claude.ai | Web | ✅ 需要 | ❌ | ⚠️ 有限 | 云端 |
| Cursor | IDE | ✅ 需要 | ⚠️ | ⚠️ 有限 | 桌面应用 |

## 8. 落地过程

### 实践记录

1. **安装 Bun**：使用官方脚本安装
2. **启动 Companion**：`bunx the-companion`
3. **访问 UI**：浏览器打开 localhost:3456
4. **认证配置**：获取 token 或使用环境变量
5. **创建会话**：测试多会话并行
6. **工具审批**：测试敏感操作审批流程
7. **崩溃恢复**：模拟进程崩溃，验证恢复功能

### 适用场景

- 需要多任务并行的开发者
- 想要可视化工具调用过程
- 不愿每月额外付费 API Key
- 偏好 Web 界面的用户

---

**状态**: ✅ 已调研  
**仓库**: https://github.com/The-Vibe-Company/companion  
**技术栈**: Bun + Hono + React  
**协议**: 逆向 WebSocket (NDJSON)
