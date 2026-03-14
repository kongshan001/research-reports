# Harness Engineering: 工业级 AI Agent 实践报告

> 基于 OpenAI Codex 的全 Agent 开发团队经验总结

## 1. 背景需求

OpenAI 团队在过去 5 个月进行了大规模实验：**从零行手写代码开始，完全由 AI Agent 构建产品**。

- 产品有内部日常用户和外部 alpha 测试者
- 代码包含：应用逻辑、测试、CI 配置、文档、可观测性、内部工具
- **开发效率：约 1/10 传统开发时间**

## 2. 目标

探索在"Agent First"时代，软件工程团队的核心职责如何从"写代码"转变为：
- 设计环境 (Design environments)
- 表达意图 (Specify intent)  
- 构建反馈循环 (Build feedback loops)

## 3. 核心成果

### 3.1 规模数据

| 指标 | 数据 |
|------|------|
| 代码总量 | ~100 万行 |
| PR 数量 | ~1500 个 |
| 团队规模 | 3-7 名工程师 |
| 人均 PR/天 | 3.5 个 |
| 单次 Codex 运行 | 最长 6 小时（人在睡觉时工作）|

### 3.2 核心原则

> **Humans steer. Agents execute.**

- 人类只负责指引方向
- 所有代码由 Codex 生成（包括 AGENTS.md 本身）
- 人类不直接写任何代码

---

## 4. 设计方案

### 4.1 知识管理：地图而非手册

**失败做法**：把所有指令塞进一个巨大的 AGENTS.md
- 上下文是稀缺资源，巨型文件会挤占任务/代码/文档空间
- 一切都"重要" = 一切都"不重要"
- 容易过时，变成"有吸引力的麻烦"

**正确做法**：AGENTS.md 是目录，不是百科全书

```
docs/                          # 知识库目录
├── architecture.md           # 架构总览
├── quality.md                # 质量评级
├── design/                   # 设计文档（含验证状态）
└── plans/                    # 执行计划
    ├── active/               # 活跃计划
    ├── completed/            # 已完成
    └── technical-debt.md     # 技术债务
```

- AGENTS.md 仅 ~100 行，作为导航入口
- 通过 linter 和 CI 强制知识库更新
- "doc-gardening" Agent 定期扫描过时文档

### 4.2 架构约束：严格边界

**核心洞察**：Agent 在有严格边界和可预测结构的环境中效率最高

```
业务域 (App Settings)
Types → Config → Repo → Service → Runtime → UI
           ↑
      Providers (横切关注点：auth, connectors, telemetry)
```

- 每个业务域只能沿固定层次依赖
- 自定义 linter 自动执行（由 Codex 生成）
- 错误信息直接注入修复指令

### 4.3 反馈循环

```
Prompt → Codex 执行 → PR → Agent Review → 迭代 → Human Review（可选）→ Merge
```

- 人类可以不审查 PR，Agent-to-Agent 审核
- 修复失败时，人类不直接写代码，而是添加工具/文档让 Agent 自我修复

### 4.4 可观测性接入

Codex 可以：
- 启动独立 git worktree 的应用实例
- 通过 Chrome DevTools Protocol 截图、DOM 快照
- 查询 LogQL 日志、PromQL 指标
- 执行"启动时间 < 800ms"、"关键路径 < 2s"等验证

---

## 5. 本地部署

### 5.1 必要基础设施

```yaml
# Codex 运行环境
- Codex CLI + GPT-5
- gh CLI (GitHub)
- 本地可观测性栈 (Loki + Prometheus)

# 应用支持
- Chrome DevTools Protocol 集成
- git worktree 多实例支持
```

### 5.2 Agent 技能配置

```bash
# 必备技能
- 代码审查 (self-review + agent review)
- 测试生成
- CI/CD 配置
- 文档更新
- Bug 复现与修复
```

---

## 6. 优缺点分析

### 6.1 优势

| 方面 | 效果 |
|------|------|
| 开发速度 | 10x 提升 |
| 人力成本 | 极低（3-7人团队）|
| 一致性 | 通过"golden principles"强制 |
| 可扩展性 | Agent 可端到端驱动新功能 |

### 6.2 挑战

| 挑战 | 解决方案 |
|------|----------|
| 上下文管理 | 结构化知识库 + 渐进式披露 |
| Agent 模式复制 | "Golden principles" + 定期清理 |
| 质量漂移 | 自动化 lint + daily refactor PR |
| 架构一致性 | 严格层次约束 + 自定义 linter |

### 6.3 风险

- 长期架构一致性：多年后如何演进？
- 人类判断力的最佳注入点仍在探索
- 模型能力演进对系统的影响未知

---

## 7. 平替对比

| 方案 | 特点 | 适用场景 |
|------|------|----------|
| OpenAI Codex 全 Agent | 100% 代码生成，高度自动化 | 大型内部项目 |
| Claude Code / Claude Agent | 注重安全性，适合企业 | 商业项目 |
| 混合模式 (Human + Agent) | 渐进式，适合团队 | 多数现有团队 |

---

## 8. 落地过程

### Phase 1: 基础设施 (1-2 周)
- [ ] Codex CLI 配置
- [ ] AGENTS.md 模板
- [ ] 基础 linter 设置
- [ ] GitHub workflow 配置

### Phase 2: 知识库搭建 (2 周)
- [ ] docs/ 目录结构
- [ ] 架构文档模板
- [ ] 设计文档规范
- [ ] 计划文档格式

### Phase 3: 约束系统 (2 周)
- [ ] 层次依赖 linter
- [ ] Golden principles 定义
- [ ] 代码风格自动修复
- [ ] Doc-gardening 任务

### Phase 4: 自动化循环 (3-4 周)
- [ ] Agent self-review
- [ ] 可观测性集成
- [ ] E2E 测试自动化
- [ ] 定期清理任务

### Phase 5: 优化与扩展 (持续)
- [ ] 性能调优
- [ ] 新工具/技能集成
- [ ] 反馈循环改进

---

## 9. 关键洞察

1. **代码是 Agent 的唯一真实**
   - Google Docs、Slack 讨论对人有效，但对 Agent 不可见
   - 所有上下文必须存入版本化的代码仓库

2. **"无聊"技术更友好**
   - 简单、可组合、API 稳定的技术更适合 Agent
   - 有时自己实现比用第三方库更容易让 Agent 理解

3. **约束即加速器**
   - 严格架构 = Agent 快速导航
   - 人机协作：中央约束 + 本地自主

4. **技术债务是贷款**
   - 持续小额偿还 > 一次性大规模清理
   - 人类审美一次编码，Agent 持续执行

---

## 10. 总结

OpenAI 的实验证明：**全 Agent 开发团队完全可行**，但需要全新的工程实践：

- 从"写代码"到"设计环境"
- 从"人工审查"到"自动化反馈"
- 从"巨型文档"到"结构化知识库"
- 从"灵活架构"到"严格约束"

**核心转变**：软件开发从"手艺活"变成"系统设计活"。

---

*本报告基于 OpenAI 官方文章《Harness engineering: leveraging Codex in an agent-first world》*
