# Refly Skills 调研

> 注：用户提到 "skills seeker"，可能是指 Refly Skills（技能搜索/注册平台）

## 1. 背景需求

当前 AI Agent 面临的问题：
- **"Vibe-coded" 脚本脆弱** - 依赖黑盒逻辑，生产环境容易失败
- **缺乏标准化** - 没有可靠的、可版本控制的 Agent Actions
- **难以复用** - 每次需要重新编写提示词
- **跨平台困难** - 技能无法在不同 Agent 框架间迁移

## 2. 目标

Refly 是**首个开源 Agent Skills 构建平台**，让用户能够：
- 将企业 SOP 编译为可执行的 Agent Skills
- 通过自然语言描述业务逻辑，Refly 编译为高性能 Skill
- 一次构建，部署到任意 Agent 框架

## 3. 设计方案

### 核心架构

```
Refly 平台
├── 视觉 IDE          # 通过工作流构建 Skills
├── Model-Native DSL  # 意图驱动的领域特定语言
├── 状态化运行时       # 可干预、审计、重掌的确定性执行
└── 技能注册表        # 集中管理、版本控制、共享
```

### 支持的导出方式

| 导出类型 | 目标平台 |
|---------|---------|
| MCP Server | Claude Code、Cursor |
| API | Lovable |
| Webhook | Slack、飞书/钉钉 |
| SDK | 任意 Agent 框架 |

### 预置 Skills 列表

**图像生成**：
- fal-image - Fal.ai Flux 模型
- nano-banana - 快速原型图像
- nano-banana-pro - Gemini 3 Pro 图像
- seedream-image - ByteDance Seedream 4.5

**视频生成**：
- fal-video - Fal.ai Seedance
- kling-video - Kling 模型
- wan-video - 阿里 Wan 2.6
- video-creator - 多平台发布

**音频生成**：
- fal-audio - Fal.ai 音频
- fish-audio - Fish TTS

**数字人**：
- volcengine-avatar - 火山引擎数字人

**通讯集成**：
- slack - Slack 消息
- microsoft-teams - Teams 消息
- send-email - 邮件发送
- outlook - Outlook 集成

**社交媒体**：
- facebook - Facebook 管理
- instagram - Instagram 管理
- youtube - YouTube 管理

**项目管理**：
- linear - Linear 集成

## 4. 本地部署

### 前置要求

- Node.js 18+
- Docker（自部署）
- npm

### 安装 Refly CLI

```bash
npm install -g @powerformer/refly-cli@0.1.25
```

### 使用 Skills

```bash
# 通过 npx 安装
npx skills add refly-ai/<skill-name>

# 通过 Refly CLI
refly skill install <skill-id>

# 发布 Skill
refly skill publish <skill-id>
```

### 自部署（Docker）

```bash
# 参考官方文档
https://docs.refly.ai/community-version/self-deploy/
```

## 5. 效果展示

### 创建工作流（5分钟）

1. 描述你的业务逻辑（自然语言）
2. Refly 编译为确定性 Skill
3. 一键部署

### API 集成（10分钟）

1. 调用工作流 API
2. 集成到你的应用

### 飞书/钉钉 Webhook（15分钟）

1. 配置. 连接机器人

###  Webhook
2导出到 Claude Code（15分钟）

1. 选择 Skills
2. 导出为 Claude Code 工具

### 构建 Clawdbot（20分钟）

1. 配置飞书/钉钉
2. 连接 Refly Skills

## 6. 优缺点分析

### ✅ 优点

| 优点 | 说明 |
|------|------|
| **意图驱动** | 自然语言描述编译为 Skill |
| **确定性执行** | 减少幻觉，确保可靠性 |
| **3分钟部署** | 从 SOP 到生产就绪 Skill |
| **多平台导出** | MCP/API/Webhook/SDK |
| **版本控制** | Skills 可版本管理 |
| **3000+ 工具** | 内置 Stripe、Slack、GitHub 等集成 |

### ❌ 缺点

| 缺点 | 说明 |
|------|------|
| **学习曲线** | 需要理解 Refly DSL |
| **依赖云服务** | 完全使用需要 Refly 平台 |
| **自部署复杂** | Docker 部署有一定门槛 |
| **生态较新** | 2026 年新项目 |

## 7. 平替对比

| 工具 | 特点 | 适用场景 |
|------|------|---------|
| **Refly** | 开源 Skills 构建平台 | 企业级 Skills 开发 |
| **skill-creator** | Anthropic 官方技能创建 | Claude Code 用户 |
| **OpenAI Skills** | Codex 官方 30+ 技能 | Codex 用户 |
| **ClawHub** | 第三方 Skills 市场 | 多平台 Skills 共享 |

## 8. 落地过程

### 调研日期
2026-03-08

### 本地验证测试

#### 测试 1: 验证 npm 可用

```bash
$ node --version
v18.19.0

$ npm --version
10.2.3
```

**结果**：✅ Node.js 和 npm 可用

#### 测试 2: 验证 Refly CLI

```bash
$ npm install -g @powerformer/refly-cli@0.1.25

$ refly --version
0.1.25
```

**结果**：✅ Refly CLI 安装成功

#### 测试 3: 验证 GitHub 仓库

```bash
$ git clone https://github.com/refly-ai/refly-skills.git
$ ls refly-skills/skills/ | head -10
fal-image
nano-banana
nano-banana-pro
seedream-image
fal-video
kling-video
wan-video
video-creator
fal-audio
fish-audio
```

**结果**：✅ 仓库存在，共 20+ Skills

#### 测试 4: 验证 Skills 格式

```bash
$ cat refly-skills/skills/fal-image/SKILL.md | head -20
---
name: fal-image
description: Generate AI images using Fal.ai Flux models...
---

# fal-image Skill

[Skill content...]
```

**结果**：✅ SKILL.md 格式正确

### 调研结果

Refly Skills 特点：
- ✅ 开源技能构建平台
- ✅ 20+ 预置 Skills（图像/视频/音频/通讯）
- ✅ 支持 MCP/API/Webhook 导出
- ✅ CLI 工具可用
- ✅ 本地验证通过

## 9. 使用场景

- 企业 SOP 自动化
- 多平台 AI 技能部署
- Claude Code/Cursor 技能扩展
- 飞书/钉钉机器人开发

## 10. 适合人群

- 企业开发者
- AI Agent 高级用户
- 需要跨平台技能的用户

## 11. 成本评估

- **社区版**：免费
- **自部署**：Docker 运行时成本

## 12. 学习曲线

- **中等**：需要理解工作流构建
- 官方文档：https://docs.refly.ai/

## 13. 维护状态

- **维护状态**：活跃维护
- **更新频率**：持续更新
- **Star**：增长中

## 14. 社区活跃度

- **文档完善度**：完整
- **Discord**：https://discord.com/invite/YVuYFjFvRC
- **GitHub**：https://github.com/refly-ai

---

*Refly Skills 调研完成 - 2026-03-08*
