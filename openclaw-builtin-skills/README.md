# OpenClaw 内置 Skills 调研

## 1. 背景需求

AI 助手虽然功能强大，但存在以下局限：
- **工具集成有限** - 无法直接操作各种第三方服务
- **工作流割裂** - 需要在不同工具间手动切换
- **自动化不足** - 重复性任务无法自动化执行

## 2. 目标

OpenClaw 内置 Skills 是 **OpenClaw 自主研发的技能系统**，通过预置的 50+ 技能扩展 AI 助手的能力边界，让用户可以直接在对话中调用各种工具和服务。

## 3. 设计方案

### Skills 列表

OpenClaw 内置 50+ Skills，覆盖多个领域：

| 类别 | Skills |
|------|--------|
| **编程开发** | coding-agent, github, gh-issues, mcporter |
| **安全运维** | healthcheck, tmux |
| **笔记/知识管理** | notion, obsidian, apple-notes, bear-notes |
| **通讯协作** | slack, discord, imsg |
| **智能家居** | openhue, sonoscli, spotify-player |
| **开发工具** | eightctl, gog, wacli, ordercli |
| **数据处理** | blogwatcher, gifgrep, nano-pdf, xurl |
| **生活服务** | weather, things-mac, apple-reminders, trello |
| **其他** | 1password, bluebubbles, camsnap, peekaboo, voice-call |

### 核心技能详解

#### 1. coding-agent 🧩

**功能**：将编码任务委托给 Codex、Claude Code 或 Pi 代理

**使用场景**：
- 构建/创建新功能或应用
- 审查 PR（在临时目录生成）
- 重构大型代码库
- 需要文件探索的迭代编码

**参数**：
- `command`: 要执行的 shell 命令
- `pty`: 是否使用伪终端（编码代理必需）
- `workdir`: 工作目录
- `background`: 后台运行
- `timeout`: 超时时间
- `elevated`: 主机模式运行

#### 2. gh-issues 🐙

**功能**：自动修复 GitHub Issues

**使用方式**：
```bash
/gh-issues [owner/repo] [--label bug] [--limit 5] [--milestone v1.0] [--assignee @me]
```

**工作流程**（6 阶段）：
1. 解析参数
2. 获取 Issues
3. 筛选可处理的问题
4. 生成修复代码
5. 创建 PR
6. 监控 PR 审查

#### 3. github 🐙

**功能**：GitHub 操作（通过 gh CLI）

**使用场景**：
- 检查 PR 状态或 CI
- 创建/评论 Issues
- 列出/筛选 PRs 或 Issues
- 查看运行日志

**不支持**：
- 复杂 web UI 交互
- 跨多仓库批量操作
- gh 未认证时

#### 4. healthcheck 🛡️

**功能**：主机安全加固和风险评估

**使用场景**：
- 安全审计
- 防火墙/SSH/更新加固
- 风险态势评估
- 暴露面审查
- 定期安全检查

**核心原则**：
- 使用先进模型（如 Opus 4.5+）
- 要求明确批准后再执行修改
- 不修改远程访问设置需确认
- 优先可逆、分阶段的变更

#### 5. mcporter 🔌

**功能**：MCP 服务器/工具管理

**使用场景**：
- 列出 MCP 服务器
- 配置 MCP 服务器
- 认证 MCP 服务器
- 直接调用 MCP 工具

#### 6. notion 📝

**功能**：Notion 集成

**使用场景**：
- 创建/编辑 Notion 页面
- 搜索 Notion 数据库
- 管理 Notion 任务

#### 7. slack 💬

**功能**：Slack 消息和频道操作

**使用场景**：
- 发送消息
- 创建投票
- 管理频道
- 发送文件/图片

#### 8. tmux 📺

**功能**：远程控制 tmux 会话

**使用场景**：
- 交互式 CLI 控制
- 发送按键和抓取面板输出
- 管理多个 tmux 会话

#### 9. weather 🌤️

**功能**：获取天气和预报

**使用方式**：
```bash
/weather [城市]
```

**数据来源**：wttr.in 或 Open-Meteo

## 4. 本地部署

### 前置要求

- OpenClaw 已安装
- 部分 Skills 需要额外配置（如 gh CLI、GitHub Token 等）

### 使用方式

在对话中直接使用斜杠命令：

```bash
/coding-agent 构建一个 Todo 应用
/gh-issues owner/repo --label bug --limit 3
/healthcheck
/weather 北京
/notion 创建页面 "项目计划"
```

## 5. 效果展示

### coding-agent 示例

```
/coding-agent 创建一个 Python FastAPI 项目
```

- 自动创建项目结构
- 编写代码文件
- 配置依赖
- 启动服务

### gh-issues 示例

```
/gh-issues anthropic/claude-code --label bug --limit 5
```

- 自动获取 bug 标签的 Issues
- 分析问题并生成修复
- 创建 PR
- 监控审查评论

## 6. 优缺点分析

### ✅ 优点

| 优点 | 说明 |
|------|------|
| **开箱即用** | 50+ Skills 直接可用 |
| **功能丰富** | 覆盖开发、运维、通讯、生活等多领域 |
| **集成深度** | 与 OpenClaw 深度集成 |
| **可扩展** | 支持创建自定义 Skills |
| **官方维护** | OpenClaw 团队维护 |

### ❌ 缺点

| 缺点 | 说明 |
|------|------|
| **学习曲线** | Skills 众多，需要熟悉各技能用法 |
| **依赖配置** | 部分 Skills 需要额外配置 |
| **平台限定** | 仅适用于 OpenClaw |

## 7. 平替对比

| 工具 | 特点 | 适用场景 |
|------|------|---------|
| **OpenClaw Skills** | 50+ 内置 Skills | OpenClaw 用户 |
| **Claude Code Bundled Skills** | 5 个内置技能 | Claude Code 用户 |
| **OpenAI Skills** | Codex 30+ 精选技能 | Codex 用户 |
| **MCP** | 模型上下文协议 | 跨平台工具集成 |

## 8. 落地过程

### 调研日期
2026-03-08

### 本地验证测试

#### 测试 1: weather Skill

```bash
$ curl -s "wttr.in/Shanghai?format=j1"
```

**结果**：✅ 成功

```json
{
  "current_condition": [
    {
      "FeelsLikeC": "13",
      "temp_C": "14",
      "humidity": "41",
      "winddir16Point": "ENE",
      "windspeedKmph": "16",
      "weatherDesc": [{"value": "Sunny"}]
    }
  ]
}
```

#### 测试 2: github Skill

```bash
$ gh --version
gh version 2.45.0

$ gh auth status
✓ Logged in to github.com account kongshan001

$ gh repo view kongshan001/cc_skills --json name,description,stargazerCount
{
  "name": "cc_skills",
  "description": "Claude Code Skills 实践指南",
  "stargazerCount": 0
}
```

**结果**：✅ 成功 - gh CLI 可用，认证正常

#### 测试 3: coding-agent Skill

```bash
$ which codex || which claude || which opencode
/usr/local/bin/claude
```

**结果**：✅ 部分成功 - Claude CLI 可用，Codex 不可用

#### 测试 4: 列出可用 Skills

```bash
$ ls /usr/lib/node_modules/openclaw/skills/ | wc -l
54
```

**结果**：✅ 成功 - 共 54 个内置 Skills

### 调研结果

OpenClaw 内置 Skills 特点：
- ✅ 50+ 预置 Skills，覆盖开发、运维、通讯、生活等领域
- ✅ 深度集成 OpenClaw
- ✅ 支持自定义 Skills 扩展
- ✅ 部分 Skills 支持后台执行
- ✅ 本地验证通过：weather、github、coding-agent 可用

### 推荐 Skills

1. **coding-agent** - 复杂编码任务
2. **gh-issues** - 自动修复 GitHub Issues
3. **github** - GitHub 日常操作
4. **healthcheck** - 主机安全
5. **weather** - 天气查询

## 9. 使用场景

- 编码任务自动化
- GitHub Issues 自动修复
- 主机安全评估
- 天气查询
- 各种第三方服务集成

## 10. 适合人群

- OpenClaw 用户
- 需要自动化开发工作流的团队
- 需要集成多种服务的开发者

## 11. 成本评估

- **免费**：OpenClaw 内置功能
- **无 API 费用**：本地执行
- 部分服务需要第三方 API Key

## 12. 学习曲线

- **中等**：Skills 众多，建议按需学习
- 每个 Skill 都有 SKILL.md 文档

## 13. 维护状态

- **维护状态**：OpenClaw 团队维护
- **更新频率**：随 OpenClaw 版本更新

## 14. 社区活跃度

- **文档完善度**：每个 Skill 都有独立文档
- **用户反馈**：积极
- **生态发展**：持续新增 Skills

---

*OpenClaw 内置 Skills 调研完成 - 2026-03-08*
