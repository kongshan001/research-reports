# Letta 调研报告

| 章节 | 状态 |
|------|------|
| 背景需求 | ✅ |
| 目标 | ✅ |
| 设计方案 | ✅ |
| 本地部署 | ✅ |
| 效果展示 | ✅ |
| 优缺点分析 | ✅ |
| 平替对比 | ✅ |
| 落地过程 | ⚠️ |
| 使用场景 | ✅ |
| 适合人群 | ✅ |
| 成本评估 | ✅ |
| 学习曲线 | ✅ |
| 维护状态 | ✅ |
| 社区活跃度 | ✅ |

## 背景需求

传统 Agent 的核心局限是**无状态**：

1. **每次会话从零开始** — 无法跨会话积累经验
2. **人格一致性差** — 长对话中容易"变脸"
3. **学习能力弱** — 无法从历史经验中改进

Letta（原 MemGPT）借鉴**操作系统虚拟内存**的思想，将 Agent 设计为有状态的"持久化 Agent"。

## 目标

Letta 旨在构建**深度个性化的有状态 Agent**，实现：

- **持久化身份** — Agent 拥有长期记忆和稳定人格
- **持续学习** — 后台异步改进 prompt 和技能
- **可移植性** — 记忆可在不同模型间迁移
- **多端支持** — 桌面/移动/远程控制

## 设计方案

### 核心架构：虚拟内存模型

Letta 借鉴 OS 虚拟内存的核心理念：

| OS 概念 | Letta 对应 |
|---------|-----------|
| RAM | 有限长度的 context window |
| 磁盘存储 | 持久化记忆存储 |
| 页表/Paging | 记忆分级与调度 |
| Swap | 自动在 context 和存储间迁移 |
| 进程 | 有状态的 Agent |

### 记忆管理机制

**1. 记忆分块（Memory Blocks）**

Letta 定义两种核心记忆块：

```python
# 人类记忆块（关于用户）
{
    "label": "human",
    "value": "Name: Timber. Occupation: building Letta"
}

# Agent 人格记忆块（关于自己）
{
    "label": "persona", 
    "value": "I am a self-improving superintelligence"
}
```

**2. 记忆调度策略**

- **自动溢出**：当 context 满时，自动将不常用记忆移到持久存储
- **优先级调度**：根据使用频率和重要性动态调整
- **Git 版本化**：每次记忆变更自动版本化，支持回溯

**3. Sleeptime 异步学习**

Letta Code 特有的后台学习机制：

- **后台子 Agent**：独立运行，不阻塞主对话
- **持续改进**：定期优化 prompt、生成新技能
- **Memory Palace**：可视化查看 Agent 记忆

### 核心技术特性

- **模型无关**：支持任意 LLM（推荐 Opus 4.5/GPT-5.2）
- **工具调用**：内置 + 自定义工具
- **多端部署**：本地 CLI / 桌面 App / 服务器
- **跨模型迁移**：记忆可导出导入

## 本地部署

### 安装

```bash
# Node.js 18+ required
# Letta Code CLI
npm install -g @letta-ai/letta-code

# Python SDK
pip install letta-client

# TypeScript SDK
npm install @letta-ai/letta-client
```

### 快速开始

```python
from letta_client import Letta
import os

client = Letta(api_key=os.getenv("LETTA_API_KEY"))

# 创建 Agent
agent_state = client.agents.create(
    model="openai/gpt-5.2",
    memory_blocks=[
        {"label": "human", "value": "Name: Alice, prefers dark mode"},
        {"label": "persona", "value": "I am a helpful coding assistant"}
    ],
    tools=["web_search", "fetch_webpage"]
)

# 发送消息
response = client.agents.messages.create(
    agent_id=agent_state.id,
    input="What do you know about me?"
)

# 获取记忆
memories = client.agents.memory.list(agent_id=agent_state.id)
```

### Docker 部署

```bash
# 启动 Letta Server
docker run -d -p 8283:8283 \
    -e LETTA_SERVER_URL=http://localhost:8283 \
    -e OPENAI_API_KEY=$OPENAI_API_KEY \
    lettaai/letta-server
```

## 效果展示

### 功能演示

- **桌面应用**：可视化 Agent 管理和记忆编辑
- **Memory Palace**：实时查看 Agent 脑中的记忆
- **多端对话**：桌面/移动/Telegram

### 性能特性

- **无状态 → 有状态**：对话可以跨会话延续
- **人格一致性**：长期记忆确保人格稳定
- **持续学习**：后台子 Agent 异步改进

## 优缺点分析

### 优点

1. **OS 思想创新**：虚拟内存模型设计优雅
2. **Git 版本化**：记忆变更可追溯
3. **后台学习**：Sleeptime 异步提升 Agent
4. **可视化**：Memory Palace 直观管理
5. **跨模型迁移**：记忆可移植
6. **多端支持**：桌面/移动/远程

### 缺点

1. **复杂度高**：虚拟内存模型学习曲线陡
2. **资源消耗**：后台子 Agent 占用额外资源
3. **API 依赖**：需要 Letta 服务或自托管
4. **延迟问题**：后台学习引入异步延迟
5. **调试困难**：记忆版本化增加复杂度
6. **商业化**：部分高级功能需要付费

## 平替对比

| 框架 | 核心思想 | 记忆管理 | 特点 | 适合场景 |
|------|----------|----------|------|----------|
| Letta | 虚拟内存 | 自动调度 + 版本化 | OS 风格 | 深度个性化 |
| Mem0 | 工厂模式 | 向量检索 | 简单易用 | 快速开发 |
| ReMe | 文件风格 | 三类专记忆 | 用户透明 | 需要用户编辑 |
| Text2Mem | 指令集 | 原子操作 | 标准化 | 企业级 |

## 落地过程

⚠️ **待补充**：本地测试记录。

### 与自托管 LLM 集成

```python
from letta_client import Letta

# 使用本地 LLM
client = Letta(
    base_url="http://localhost:8283/v1",
    api_key="your-key"
)

# 创建使用本地模型的 Agent
agent = client.agents.create(
    model="ollama/llama3",
    # ... 其他配置
)
```

## 使用场景

- **编程助手**：学习用户代码风格，持续改进
- **数字员工**：长期运行，处理邮件/日历/文档
- **AI 伴侣**：深度个性化，拥有独特记忆和人格
- **远程控制**：在任意设备上运行 Agent 并迁移记忆

## 适合人群

- 需要深度个性化 Agent 的开发者
- 对 Agent 架构有研究兴趣的工程师
- 希望 Agent 能持续学习的用户

## 成本评估

- **免费层**：有限调用次数
- **自托管**：需要服务器 + LLM API
- **托管服务**：按调用量收费
- **估算**：自托管约 $50/月（服务器 + API）

## 学习曲线

- **入门难度**：中 — 需要理解虚拟内存模型
- **进阶功能**：高 — 掌握后台学习、子 Agent
- **推荐资源**：官方文档 + Discord 社区

## 维护状态

- **活跃维护**：持续更新中
- **版本迭代**：Letta Code 和 Letta API 定期更新
- **社区活跃**：Discord + 论坛

## 社区活跃度

- **GitHub Star**：8k+
- **贡献者**：100+
- **Discord**：活跃社区
- **社交**：Twitter、LinkedIn、YouTube

---

*调研时间：2026-04-15*
