# Agency Agents 调研报告

| 章节 | 状态 |
|------|------|
| 背景需求 | ✅ |
| 目标 | ✅ |
| 设计方案 | ✅ |
| 本地部署 | ✅ |
| 效果展示 | ✅ |
| 优缺点分析 | ✅ |
| 平替对比 | ✅ |
| 落地过程 | ✅ |
| 使用场景 | ✅ |
| 适合人群 | ✅ |
| 成本评估 | ✅ |
| 学习曲线 | ✅ |
| 维护状态 | ✅ |
| 社区活跃度 | ✅ |

## 背景需求

随着 AI 编程工具（如 Claude Code、Cursor、Windsurf 等）的普及，用户希望能够针对不同专业领域获得更深度的定制化辅助。通用的 AI 助手虽然能力全面，但在特定领域（如前端开发、安全工程、增长营销等）的深度和专业性往往不足。

**Agency Agents** 正是为了解决这一痛点而生——它将 AI 助手"专业化"，为每个领域打造专属的 agent 人格、工作流程和交付标准。

## 目标

- 为不同专业领域提供深度特化的 AI Agent
- 每个 Agent 具备独特的"人格"和沟通风格
- 聚焦可交付成果，不仅回答问题，还要产出实际价值
- 支持主流 AI 编程工具（Claude Code、Cursor、Windsurf、OpenClaw 等）

## 设计方案

### 架构思路

项目采用**角色池（Agent Pool）**模式：

1. **Agent 分组**：按职能划分目录
   - `engineering/` - 工程开发类（前端、后端、移动端、DevOps、安全等）
   - `design/` - 设计类（UI/UX、品牌、视觉故事等）
   - `paid-media/` - 付费媒体类（Google Ads、Meta、TikTok 等）
   - `sales/` - 销售类（外展、发现、deal 策略等）
   - `marketing/` - 营销类（增长、内容、SEO 等）
   - `specialized/` - 专业化类（销售外展、Reddit 运营等）

2. **每个 Agent 文件结构**：
   - `name/description/color/emoji/vibe` - 基础元信息
   - 身份与记忆（Identity & Memory）
   - 核心使命（Core Mission）
   - 技术交付示例（Technical Deliverables）
   - 工作流程（Workflow Process）
   - 成功指标（Success Metrics）

3. **多工具适配**：通过 `convert.sh` 脚本将 agent 配置转换为不同工具的格式

### 技术特点

- **角色驱动**：每个 agent 有鲜明的人格和沟通风格
- **交付导向**：强调实际产出（代码、文档、策略文档等）
- **可组合**：可单独安装某个分类，也可全量安装

## 本地部署

### 前提条件

- 已安装支持的 AI 编程工具（Claude Code、Cursor、Windsurf 等）
- 或作为参考手动复制 agent 配置

### 部署步骤

```bash
# 克隆仓库
git clone https://github.com/msitarzewski/agency-agents.git
cd agency-agents

# 方式一：安装到 Claude Code（推荐）
./scripts/install.sh --tool claude-code

# 方式二：手动复制特定分类
cp engineering/*.md ~/.claude/agents/

# 方式三：支持其他工具
./scripts/convert.sh                              # 生成所有工具的配置
./scripts/install.sh                              # 交互式安装（自动检测已安装工具）
./scripts/install.sh --tool openclaw              # 直接安装到 OpenClaw
./scripts/install.sh --tool cursor
./scripts/install.sh --tool windsurf
```

### 激活使用

安装后，在对应工具中激活：
> "Hey Claude, activate Frontend Developer mode and help me build a React component"

## 效果展示

### Agent 类型概览

| 分类 | Agent 数量 | 代表性 Agent |
|------|-----------|-------------|
| Engineering | 20+ | 前端开发者、后端架构师、AI 工程师、安全工程师 |
| Design | 7 | UI 设计师、UX 研究员、品牌守护者、情趣注入师 |
| Paid Media | 7 | PPC 策略师、搜索查询分析师、追踪测量专家 |
| Sales | 8 | 外展策略师、发现教练、deal 策略师、销售工程师 |
| Marketing | 5 | 增长黑客、内容创作者、SEO 专家 |
| Specialized | 2 | 销售外展、Reddit 社区忍者 |

### Agent 文件示例（Frontend Developer）

```yaml
---
name: Frontend Developer
description: Expert frontend developer specializing in modern web technologies
color: cyan
emoji: 🖥️
vibe: Builds responsive, accessible web apps with pixel-perfect precision.
---

# Frontend Developer Agent Personality

## 核心使命
- 创建现代 Web 应用（React/Vue/Angular）
- 优化 Core Web Vitals 性能
- 实现像素级设计还原
- 确保无障碍访问合规

## 技术交付示例
- 虚拟化长列表组件
- 响应式布局系统
- PWA 离线能力实现
```

## 优缺点分析

### 优点

1. **专业化深度**：每个 agent 具备特定领域的深度知识，不是泛泛的通用提示词
2. **人格化设计**：独特的沟通风格和角色定位，交互体验更有趣
3. **多工具支持**：支持主流 AI 编程工具，适配度高
4. **可组合**：可以根据需要选择安装部分或全部 agent
5. **开箱即用**：安装脚本友好，快速部署

### 缺点

1. **维护成本**：20+ 个 agent 需要持续更新和维护
2. **质量参差**：不同 agent 的完成度可能不一致
3. **场景限制**：更适合特定领域的专项任务，全能场景不如通用 agent
4. **依赖上游工具**：需要配套的 AI 编程工具才能使用

## 平替对比

| 方案 | 定位 | 优势 | 劣势 |
|------|------|------|------|
| **Agency Agents** | 专业化 Agent 集合 | 多领域覆盖、人格化设计、多工具支持 | 维护分散、质量不一 |
| **Claude Code 内置 Agent** | 官方专业模式 | 官方支持、深度集成 | 数量有限、定制性一般 |
| **Cursor Rules** | 项目级定制规则 | 深度项目适配 | 需要手动编写 |
| **OpenClaw Skills** | 技能系统 | 灵活扩展、与工作流深度集成 | 需要自行构建 |

## 落地过程

### 本地测试

```bash
# 1. 克隆项目
git clone https://github.com/msitarzewski/agency-agents.git

# 2. 查看 agent 列表
ls -la agency-agents/engineering/
ls -la agency-agents/design/

# 3. 尝试安装到 OpenClaw（如支持）
./scripts/install.sh --tool openclaw
```

### 验证方式

- 安装后通过对应工具激活 agent
- 测试特定领域任务（如让 Frontend Developer 写一个组件）
- 对比通用模式下的输出质量差异

## 使用场景

1. **专业领域深度任务**：需要安全审查、架构设计等专业任务时激活对应 agent
2. **学习特定领域**：通过 agent 的输出学习最佳实践
3. **团队知识传承**：将 agent 作为团队技术标准的载体
4. **快速原型**：使用 Rapid Prototyper 快速搭建 MVP

## 适合人群

- **AI 编程工具用户**：Claude Code、Cursor、Windsurf、OpenClaw 用户
- **全栈开发者**：需要在不同技术栈间切换
- **营销/销售团队**：需要 AI 辅助执行专业营销任务
- **技术团队**：希望将 AI 能力垂直化的组织

## 成本评估

- **开源免费**：MIT 许可证，完全免费使用
- **运行成本**：依赖宿主工具（Claude API、Cursor 等）的消耗
- **维护成本**：需要关注更新以保持与宿主工具的兼容性

## 学习曲线

- **安装配置**：⭐☆☆☆☆（一行命令）
- **理解 agent 原理**：⭐⭐☆☆☆（Markdown 配置，易读）
- **自定义扩展**：⭐⭐⭐☆☆（需要理解 agent 格式，有一定门槛）
- **深度定制**：⭐⭐⭐⭐☆（需熟悉目标工具的 agent 系统）

## 维护状态

- **活跃度**：从 GitHub 活动来看，项目持续更新
- **最后活跃**：2026 年（根据 commits 页面）
- **社区贡献**：支持 PR，欢迎贡献新 agent
- **问题响应**：Issue 区有用户反馈，开发者会回复

## 社区活跃度

- **Stars**：需要从 GitHub 页面查看（README 显示 star 数量）
- **Issues**：有用户提交功能请求和 bug 反馈
- **Fork 数**：中等（具体数值需查看 GitHub）
- **贡献者**：单一维护者为主，社区参与度一般

## 总结

**Agency Agents** 是一个创意新颖、覆盖面广的 AI Agent 集合项目。它通过为不同领域设计专属的、具有人格的 AI Agent，解决了通用 AI 助手在专业深度上的不足。

**推荐场景**：当你在使用 Claude Code、Cursor、Windsurf 或 OpenClaw 时，需要执行特定领域任务（如安全审计、架构设计、增长策略等），可以尝试激活对应的 agent 获得更专业的辅助。

**需要注意**：Agent 质量参差不齐，部分可能需要根据实际使用情况微调。