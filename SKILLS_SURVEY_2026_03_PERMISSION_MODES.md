# OpenClaw vs Claude Code 权限模式深度调研

> 调研日期: 2026-03-13
> 关键词: OpenClaw, Claude Code, dangerous skip permission, 文件读写权限, 安全模式

## 1. 背景与需求

随着 AI 编程助手的能力不断增强，如何在**功能灵活性**与**安全性**之间取得平衡成为核心议题。用户在使用 AI 代理（Agent）时，常常需要让 AI 能够访问文件系统、执行命令、操作浏览器等敏感资源。

当前主流 AI 编程工具提供了多种权限控制模式：

| 工具 | 完全开放权限 | 受限模式 |
|------|------------|---------|
| **Claude Code** | `--dangerously-skip-permissions` | `--permission-mode` 系列选项 |
| **OpenClaw** | `tools.fs.workspaceOnly: false` + `exec.security: full` | Tool Profiles + allow/deny |

---

## 2. 调研目标

1. 分析 OpenClaw 的权限控制系统
2. 分析 Claude Code 的 `--dangerously-skip-permissions` 模式
3. 对比两者的安全模型与实现差异
4. 整理最佳实践与配置建议

---

## 3. OpenClaw 权限系统详解

### 3.1 架构概述

OpenClaw 是一个自托管的 AI 网关，支持多渠道（WhatsApp、Telegram、Discord 等）接入 AI 代理。其权限系统设计遵循**个人助手信任模型**：

> OpenClaw 安全指南假设**单一受信任操作员边界**的部署模式，即每个网关只有一个可信用户。

### 3.2 核心概念

#### 3.2.1 Tool Profiles（工具配置文件）

OpenClaw 提供预设的工具配置文件：

| Profile | 包含工具 | 适用场景 |
|---------|---------|---------|
| `minimal` | 仅 `session_status` | 纯对话场景 |
| `coding` | `group:fs`, `group:runtime`, `group:sessions`, `group:memory`, `image` | 代码开发 |
| `messaging` | `group:messaging`, `sessions_list`, `sessions_history`, `sessions_send` | 消息处理 |
| `full` | 无限制 | 完全信任环境 |

**工具组分类：**

- `group:fs`: read, write, edit, apply_patch
- `group:runtime`: exec, bash, process
- `group:sessions`: sessions_list, sessions_history, sessions_send, sessions_spawn, session_status
- `group:memory`: memory_search, memory_get
- `group:web`: web_search, web_fetch
- `group:ui`: browser, canvas
- `group:automation`: cron, gateway
- `group:messaging`: message
- `group:nodes`: nodes
- `group:openclaw`: 所有内置 OpenClaw 工具

#### 3.2.2 文件系统权限控制

```json5
{
  tools: {
    fs: {
      // 限制文件操作在 workspace 目录内
      workspaceOnly: true  // 默认: true
    }
  }
}
```

当 `workspaceOnly: true` 时：
- `read`/`write`/`edit` 只能操作 workspace 目录
- 无法访问 `~/.openclaw`、系统配置等敏感路径
- `apply_patch` 也受此限制（可通过 `applyPatch.workspaceOnly: false` 单独配置）

#### 3.2.3 执行权限控制

```json5
{
  tools: {
    exec: {
      // 执行安全模式
      security: "allowlist",  // deny | allowlist | full
      
      // 审批模式
      ask: "on-miss",         // off | on-miss | always
      
      // 执行位置
      host: "sandbox"         // sandbox | gateway | node
    }
  }
}
```

**security 参数说明：**

| 模式 | 说明 |
|------|------|
| `deny` | 拒绝所有执行（默认 sandbox 模式） |
| `allowlist` | 仅允许白名单命令执行 |
| `full` | 完全跳过审批（需配合 elevated 或 /exec） |

**ask 参数说明：**

| 模式 | 说明 |
|------|------|
| `off` | 关闭审批提示 |
| `on-miss` | 白名单未命中时询问（默认） |
| `always` | 每次执行都询问 |

#### 3.2.4 高级权限控制

```json5
{
  tools: {
    // 完全禁用某些工具
    deny: ["group:automation", "sessions_spawn"],
    
    // 仅允许特定工具
    allow: ["read", "write", "exec"],
    
    // 按 provider 限制
    byProvider: {
      "google-antigravity": { profile: "minimal" },
      "openai/gpt-5.2": { allow: ["group:fs"] }
    }
  }
}
```

#### 3.2.5 提升模式（Elevated Mode）

```json5
{
  tools: {
    elevated: {
      enabled: true,
      // full 模式会跳过 exec 审批
      mode: "full"  // on | off | ask | full
    }
  }
}
```

使用 `/elevated full` 可以一键开启：
- 主机执行模式（host=gateway）
- 跳过所有 exec 审批

---

## 4. Claude Code 权限系统详解

### 4.1 权限模式概览

Claude Code 提供了一套简洁但功能强大的权限控制机制：

```bash
# 完全跳过所有权限检查（危险！）
claude --dangerously-skip-permissions

# 允许用户选择是否跳过权限（非默认）
claude --allow-dangerously-skip-permissions

# 权限模式选项
claude --permission-mode <mode>
```

### 4.2 Permission Mode 详解

| 模式 | 说明 |
|------|------|
| `default` | 默认行为，每次敏感操作需用户确认 |
| `acceptEdits` | 自动接受代码编辑操作 |
| `bypassPermissions` | 跳过所有权限检查 |
| `delegate` | 委托给外部权限服务 |
| `dontAsk` | 不询问，静默拒绝或放行 |
| `plan` | 仅规划模式，不执行 |

### 4.3 工具级别控制

```bash
# 仅允许特定工具
claude --allowed-tools "Bash(git:*) Edit"

# 禁用特定工具
claude --disallowed-tools "Bash rm"

# 完全禁用所有工具
claude --tools ""
```

### 4.4 目录级别控制

```bash
# 添加额外允许访问的目录
claude --add-dir /path/to/directory

# 默认只能访问当前工作目录
```

### 4.5 MCP 服务器权限

```bash
# 加载 MCP 服务器配置
claude --mcp-config config.json

# 仅使用指定 MCP，忽略其他配置
claude --strict-mcp-config
```

---

## 5. 深度对比分析

### 5.1 安全模型对比

| 维度 | OpenClaw | Claude Code |
|------|----------|-------------|
| **信任模型** | 个人助手模型（单一受信任操作员） | 用户本地信任模型 |
| **权限粒度** | 细粒度（profile + allow/deny + workspaceOnly） | 中粒度（permission-mode + tools） |
| **执行控制** | sandbox/gateway/node 三级执行环境 | 本地执行 |
| **审批机制** | 可配置 ask 模式 | permission-mode |
| **工作目录限制** | workspaceOnly 配置 | --add-dir 添加目录 |

### 5.2 功能对比

| 功能 | OpenClaw | Claude Code |
|------|----------|-------------|
| 完全跳过权限 | ❌ 无直接对应 | ✅ `--dangerously-skip-permissions` |
| 限制工作目录 | ✅ `workspaceOnly: true` | ✅ `--add-dir` |
| 工具白名单 | ✅ `allow: [...]` | ✅ `--allowed-tools` |
| 工具黑名单 | ✅ `deny: [...]` | ✅ `--disallowed-tools` |
| 执行安全模式 | ✅ `security: deny/allowlist/full` | ❌ 无直接对应 |
| 审批提示 | ✅ `ask: off/on-miss/always` | ✅ `--permission-mode` |
| 多执行环境 | ✅ sandbox/gateway/node | ❌ 仅本地 |
| 按模型限制 | ✅ `byProvider` | ❌ 无直接对应 |
| 运行时审批 | ✅ Exec Approvals | ❌ 静态配置 |

### 5.3 安全强度对比

```
OpenClaw 安全强度谱系：
┌─────────────────────────────────────────────────────────────┐
│ minimal (session_status) ──► coding ──► messaging ──► full │
└─────────────────────────────────────────────────────────────┘
           ▲                                           ▲
           │                                           │
        最安全 ◄─────────────────────────────────► 最开放
```

```
Claude Code 安全强度谱系：
┌─────────────────────────────────────────────────────────────┐
│ default ──► acceptEdits ──► dontAsk ──► bypassPermissions │
└─────────────────────────────────────────────────────────────┘
           ▲                                           ▲
           │                                           │
        最安全 ◄─────────────────────────────────► 最开放
```

### 5.4 风险对比

#### OpenClaw 潜在风险：

1. **workspaceOnly 逃逸**：如果同时设置 `workspaceOnly: false` + `exec.security: full`，AI 可以访问系统任意文件
2. **Elevated 滥用**：`/elevated full` 会完全跳过审批，需严格控制触发者
3. **多用户场景**：共享网关时，所有用户共享同一权限集

#### Claude Code 潜在风险：

1. **完全放权风险**：`--dangerously-skip-permissions` 相当于完全信任 AI
2. **目录遍历**：添加过多目录可能导致敏感文件暴露
3. **MCP 权限**：MCP 服务器可能具有扩展的系统访问能力

---

## 6. 配置示例

### 6.1 OpenClaw 安全加固配置

```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",
    auth: { mode: "token", token: "replace-with-long-random-token" },
  },
  session: {
    dmScope: "per-channel-peer",
  },
  tools: {
    profile: "coding",
    deny: ["group:automation", "sessions_spawn"],
    fs: { workspaceOnly: true },
    exec: { 
      security: "deny", 
      ask: "always" 
    },
    elevated: { enabled: false },
  },
  channels: {
    whatsapp: { dmPolicy: "pairing", groups: { "*": { requireMention: true } } },
  },
}
```

### 6.2 OpenClaw 开发者完全信任配置

```json5
{
  tools: {
    profile: "full",
    fs: { workspaceOnly: false },
    exec: { 
      security: "full", 
      ask: "off",
      host: "gateway"
    },
  }
}
```

### 6.3 Claude Code 安全模式

```bash
# 默认模式（每次询问）
claude

# 自动接受编辑
claude --permission-mode acceptEdits

# 完全信任（跳过所有权限）
claude --dangerously-skip-permissions

# 仅允许特定工具
claude --allowed-tools "Bash(git:*) Edit Read"

# 限制访问目录
claude --add-dir /workspace --add-dir /projects
```

---

## 7. 最佳实践

### 7.1 OpenClaw 最佳实践

1. **从最小权限开始**：使用 `minimal` 或 `coding` profile
2. **强制 workspaceOnly**：保持 `fs.workspaceOnly: true`
3. **分层审批**：根据执行位置配置不同安全级别
4. **定期审计**：使用 `openclaw security audit` 检查配置
5. **网络隔离**：gateway 绑定到 loopback，避免公网暴露

### 7.2 Claude Code 最佳实践

1. **避免生产环境使用 `--dangerously-skip-permissions`**
2. **优先使用 `--permission-mode acceptEdits`**
3. **谨慎添加目录**：仅添加必要的项目目录
4. **定期检查 MCP 服务器权限**
5. **分离敏感环境**：开发/测试/生产使用不同配置

---

## 8. 落地建议

### 8.1 个人开发环境

| 场景 | OpenClaw 配置 | Claude Code 配置 |
|------|--------------|-----------------|
| 日常开发 | `profile: coding` + `workspaceOnly: true` | `--permission-mode acceptEdits` |
| 完全信任 | `profile: full` + `security: full` | `--dangerously-skip-permissions` |

### 8.2 团队协作环境

| 场景 | OpenClaw 配置 | Claude Code 配置 |
|------|--------------|-----------------|
| 共享 Bot | `profile: minimal` + 严格 allowlist | 不推荐 Claude Code 团队共用 |
| 代码审查 | `profile: coding` + `ask: always` | `--permission-mode default` |

### 8.3 生产环境

| 场景 | OpenClaw 配置 | Claude Code 配置 |
|------|--------------|-----------------|
| 自动化任务 | `profile: minimal` + cron | 不推荐 |
| CI/CD 集成 | 通过 gateway API 隔离执行 | 不推荐 |

---

## 9. 总结

### 9.1 核心差异

| 维度 | OpenClaw | Claude Code |
|------|----------|-------------|
| **设计理念** | 企业级网关，精细权限控制 | 开发者工具，轻量易用 |
| **灵活性** | 高（多层配置） | 中（CLI 参数） |
| **安全性** | 高（workspace 隔离 + sandbox） | 中（依赖用户判断） |
| **适用场景** | 多渠道接入、远程协作 | 本地开发、快速原型 |

### 9.2 选型建议

- **需要多渠道接入** → OpenClaw
- **需要细粒度权限控制** → OpenClaw
- **需要远程协作** → OpenClaw
- **本地快速开发** → Claude Code
- **简单 CLI 工具** → Claude Code
- **需要 MCP 扩展** → Claude Code

---

## 10. 参考资料

- [OpenClaw Security Documentation](https://docs.openclaw.ai/gateway/security)
- [OpenClaw Tools Documentation](https://docs.openclaw.ai/tools/index)
- [Claude Code Help](https://docs.anthropic.com/en/docs/claude-code)
- [OpenClaw Security Audit](https://docs.openclaw.ai/cli/security)

---

*调研完成 - 2026-03-13*
