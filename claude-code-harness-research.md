# Claude Code Harness 项目调研报告

## 1. 背景需求

### 1.1 Agent Drift 问题
在 Claude Code 开发过程中，开发者普遍面临以下痛点：
- **计划漂移**：计划散落在聊天记录中，缺乏统一管理
- **测试被忽略**：开发过程中测试经常被跳过或推迟
- **评审延迟**：代码评审往往在开发完成后才进行
- **证据重建**：发布时的证据需要重新构建，缺乏连续性

### 1.2 核心痛点
根据项目描述，"同一个 AI 模型，改都不改，光换一套执行框架，跑分直接涨了..." 这表明问题不在于模型能力，而在于执行框架的设计。

## 2. 目标

### 2.1 主要目标
- **建立 disciplined delivery loop**：为 Claude Code 建立规范的交付循环
- **解决 Agent Drift**：通过约束路径防止智能体行为偏离
- **提供源真值循环**：围绕智能体工作建立源真值(source-of-truth)循环

### 2.2 具体目标
1. 将默认行为从"让智能体编码"转变为：
   - 编写规范和计划
   - 仅实施批准的切片
   - 验证结果
   - 独立评审
   - 为 PR 或发布打包证据

2. 为 Codex 和 OpenCode 提供有界路径

## 3. 设计方案

### 3.1 五动词工作流
Harness 采用五个核心动词构建工作流：

| 动词 | 命令 | 功能描述 |
|------|------|----------|
| Plan | `/harness-plan` | 将意图转换为 spec.md 和 Plans.md，包含范围、验收标准、依赖关系、未知因素等 |
| Work | `/harness-work` | 执行批准的任务或范围，添加测试，运行验证，保持工作在计划内 |
| Review | `/harness-review` | 独立于实现进行评审，将重大发现视为阻塞项 |
| Sync | `/harness-sync` | 同步状态和进度 |
| Release | `/harness-release` | 在实现和评审完成后检查发布就绪性、CHANGELOG/标签边界和证据打包 |

### 3.2 三层架构
底层实现上，harness 分三层：
- **Skill Layer**：技能层，提供基础技能支持
- **Execution Layer**：执行层，管理任务执行流程
- **Validation Layer**：验证层，确保质量和合规性

### 3.3 源真值机制
Harness 将 spec.md 和 Plans.md 文件视为源真值：
- 智能体未见的数据保持未知状态，而不是被默默编造
- 用户批准的合同是执行的唯一依据
- 非平凡计划记录 team_validation_mode 并通过团队/子智能体或手动通过视角验证计划

## 4. 本地部署

### 4.1 支持的工具和版本
| 工具 | 级别 | 路由 |
|------|------|------|
| Claude Code | supported | Claude 插件市场，然后 /harness-setup |
| Codex CLI | internal-compatible | scripts/setup-codex.sh --user |
| Codex app | candidate | 仅候选烟雾测试 |
| OpenCode | internal-compatible | scripts/setup-opencode.sh |
| Cursor | internal-compatible | scripts/setup-cursor.sh |
| GitHub Copilot CLI | candidate | 仅手动概要研究 |

### 4.2 部署步骤
1. **快速安装**（30秒）：
   ```bash
   claude /plugin marketplace add Chachamaru127/claude-code-harness
   claude /plugin install claude-code-harness@claude-code-harness-marketplace
   /harness-setup
   ```

2. **迁移检查**（现有用户）：
   ```bash
   bin/harness doctor --migration-report
   ```

3. **启动流程**：
   - 运行 `/harness-plan` 处理小请求
   - 批准或纠正生成的合同
   - 运行最小的批准任务，如 `/harness-work 1.1.1`
   - 运行 `/harness-review` 并保留验证输出

## 5. 效果展示

### 5.1 性能提升
根据 LangChain 的博客，使用 Harness Engineering 后：
- **Terminal Bench 2.0** 从 52.8 提升到 66.5（13.7 点的提升）
- 排名从 **Top 30 提升到 Top 5**
- 仅通过调整 harness，保持模型固定（gpt-5.2-codex）

### 5.2 关键改进点
1. **Self-Verification**：构建和自我验证循环
2. **Tracing**：通过 Traces 理解智能体故障模式
3. **Trace Analyzer Skill**：自动化的错误分析和改进建议

### 5.3 实际效果
- 计划不再散落在聊天中
- 测试成为必需环节
- 评审与实现分离
- 发布证据可追溯和打包

## 6. 优缺点分析

### 6.1 优点
1. **规范性强**：建立了清晰的五动词工作流
2. **质量保证**：通过独立的评审和验证确保代码质量
3. **可追溯性**：所有过程都有文档记录和证据保存
4. **可扩展性**：支持多种开发工具和平台
5. **效率提升**：显著提升了 Terminal Bench 性能指标

### 6.2 缺点
1. **学习曲线**：需要适应新的工作流程
2. **依赖性**：对 Claude Code 生态依赖较强
3. **复杂性**：增加了项目管理层面的复杂性
4. **兼容性**：不同工具的支持程度不一

## 7. 平替对比

### 7.1 cc-sdd
- **特点**：更轻量，专注于 spec 到代码的转换
- **优势**：简单直接，容易上手
- **劣势**：缺乏完整的交付循环和质量保证机制

### 7.2 其他方案
- **传统开发流程**：缺乏 AI 智能体协作特性
- **纯聊天式开发**：缺乏结构化和可追溯性
- **其他 AI 编程框架**：缺乏专门的 harness engineering 理念

## 8. 落地过程

### 8.1 入门阶段
1. **选择合适的工具**：根据当前使用的工具选择安装路径
2. **运行迁移检查**（如果是从其他方案迁移）
3. **安装 Harness**：通过插件市场或脚本安装

### 8.2 适应阶段
1. **小规模试用**：从小的任务开始，熟悉五动词工作流
2. **调整工作习惯**：适应新的计划-实施-评审流程
3. **建立团队共识**：确保团队成员理解并接受新的工作方式

### 8.3 成熟阶段
1. **大规模应用**：将 Harness 应用于复杂的开发项目
2. **定制优化**：根据团队需求调整工作流程
3. **持续改进**：使用 Trace Analyzer 等工具持续优化性能

### 8.4 团队推广
1. **文档建设**：建立团队内部的使用文档
2. **培训支持**：为团队成员提供培训和支持
3. **最佳实践**：总结和分享使用最佳实践

## 总结

Claude Code Harness 通过引入 harness engineering 理念，成功解决了 AI 智能体开发中的 Agent Drift 问题。其五动词工作流为开发者提供了一个结构化、可追溯、高质量的编程体验。虽然存在一定的学习曲线，但其带来的性能提升和质量保证使其成为 Claude Code 开发的重要工具。

对于每天使用 Claude Code 开发的团队和开发者来说，Harness 提供了一个系统性的解决方案，可以有效提升开发效率和代码质量，值得考虑采用。

---
*调研时间：2026年5月31日*
*项目地址：https://github.com/Chachamaru127/claude-code-harness*
*Star 数量：2,209*