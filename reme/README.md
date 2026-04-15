# ReMe 调研报告

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

当前 Agent 记忆系统的常见问题：

1. **用户无法查看** — 记忆对用户封闭，无法了解 Agent "记住"了什么
2. **用户无法编辑** — 错误的记忆无法手动纠正
3. **记忆黑箱** — 用户对记忆系统缺乏信任

ReMe（Reflection Memory）是阿里 AgentScope 出品的解决方案，提出**"文件即记忆"**理念，让记忆对用户完全透明。

## 目标

ReMe 旨在实现**用户透明的持久记忆系统**：

- **文件即记忆** — 记忆存储为可读文件，用户可直接查看
- **可编辑** — 用户可以手动修改、纠正记忆
- **多维度** — 支持 Personal、Task、Tool 三类记忆
- **无缝集成** — 与 AgentScope ReActAgent 深度集成

## 设计方案

### 核心架构

ReMe 提供三种专门的长期记忆类型：

| 记忆类型 | 类名 | 用途 |
|----------|------|------|
| Personal Memory | ReMePersonalLongTermMemory | 用户偏好、习惯、个人信息 |
| Task Memory | ReMeTaskLongTermMemory | 任务执行轨迹、经验教训 |
| Tool Memory | ReMeToolLongTermMemory | 工具调用模式、最佳实践 |

### 双接口设计

每种记忆类型提供两套接口：

**1. 工具函数接口（Tool Functions）**

供 Agent 在运行时调用：

```python
# 记录记忆
result = await memory.record_to_memory(
    thinking="User sharing travel preferences",
    content=[
        "I prefer homestays in Hangzhou",
        "Like visiting West Lake in morning"
    ]
)

# 检索记忆
result = await memory.retrieve_from_memory(
    keywords=["Hangzhou", "travel"]
)
```

**2. 直接方法接口（Direct Methods）**

供开发者编程使用：

```python
# 直接记录
await memory.record(msgs=[...])

# 直接检索
memories = await memory.retrieve(msg=query_msg)
```

### 核心技术

- **向量化存储**：Embedding + Vector Store 语义检索
- **异步优先**：完整 async/await 支持
- **分数机制**：Task Memory 支持评分（记录成功/失败经验）
- **上下文管理**：async context manager 确保资源正确释放

## 本地部署

### 安装

```bash
# 安装 AgentScope
cd agentscope
pip install -e .

# 安装 ReMe 依赖
pip install reme-ai python-dotenv
```

### 环境配置

```bash
# 设置 API Key
export DASHSCOPE_API_KEY='YOUR_API_KEY'

# 或创建 .env 文件
echo "DASHSCOPE_API_KEY=your-key" > .env
```

### 三种使用示例

#### 1. Personal Memory（用户记忆）

```python
import asyncio
from agentscope.memory import ReMePersonalLongTermMemory
from agentscope.embedding import DashScopeTextEmbedding
from agentscope.message import Msg
from agentscope.model import DashScopeChatModel
import os

async def main():
    personal_memory = ReMePersonalLongTermMemory(
        agent_name="Friday",
        user_name="user_123",
        model=DashScopeChatModel(
            model_name="qwen3-max",
            api_key=os.environ.get("DASHSCOPE_API_KEY"),
        ),
        embedding_model=DashScopeTextEmbedding(
            model_name="text-embedding-v4",
            dimensions=1024,
        ),
    )
    
    async with personal_memory:
        # 记录用户偏好
        await personal_memory.record_to_memory(
            thinking="User sharing preferences",
            content=["Prefers dark mode", "Uses vim keybindings"]
        )
        
        # 检索记忆
        result = await personal_memory.retrieve_from_memory(
            keywords=["theme", "editor"]
        )

asyncio.run(main())
```

#### 2. Task Memory（任务记忆）

```python
from agentscope.memory import ReMeTaskLongTermMemory

# 记录成功经验（带高分）
await task_memory.record_to_memory(
    thinking="Recording successful solution",
    content=["For API 404: check route definition", "Use linter for typos"],
    score=0.95
)

# 检索类似任务经验
experiences = await task_memory.retrieve(
    msg=Msg(role="user", content="How to debug 404?")
)
```

#### 3. Tool Memory（工具记忆）

```python
import json
from datetime import datetime

# 记录工具执行结果
tool_result = {
    "create_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "tool_name": "web_search",
    "input": {"query": "Python tutorial", "max_results": 10},
    "output": "Found 10 results",
    "success": True,
    "time_cost": 2.3
}

await tool_memory.record(
    msgs=[Msg(role="assistant", content=json.dumps(tool_result))]
)

# 检索工具使用指南
guidelines = await tool_memory.retrieve()
```

### 与 ReActAgent 集成

```python
from agentscope.agent import ReActAgent
from agentscope.formatter import DashScopeChatFormatter
from agentscope.memory import InMemoryMemory

agent = ReActAgent(
    name="Friday",
    sys_prompt="You are a helpful assistant with long-term memory.",
    model=DashScopeChatModel(...),
    formatter=DashScopeChatFormatter(),
    toolkit=Toolkit(),
    memory=InMemoryMemory(),
    long_term_memory=personal_memory,
    long_term_memory_mode="both"  # 启用记录和检索工具
)
```

## 效果展示

### 架构图

ReMe 集成在 AgentScope 生态中：

```
┌─────────────────────────────────────┐
│         ReActAgent                  │
│  ┌─────────────────────────────┐   │
│  │   InMemoryMemory (短期)     │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │  ReMe (长期记忆)             │   │
│  │  - Personal Memory          │   │
│  │  - Task Memory              │   │
│  │  - Tool Memory              │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 特性总结

- ✅ 三种专门记忆类型
- ✅ 双接口设计（工具函数 + 直接方法）
- ✅ 向量语义检索
- ✅ 异步优先架构
- ✅ ReActAgent 无缝集成

## 优缺点分析

### 优点

1. **用户透明** — 文件即记忆，用户可直接查看
2. **可编辑** — 用户可以手动纠正错误记忆
3. **多维度** — 三种专门记忆类型分工明确
4. **无缝集成** — 与 AgentScope 深度集成
5. **分数机制** — Task Memory 支持评分
6. **轻量级** — 依赖简单，易于部署

### 缺点

1. **框架依赖** — 需要 AgentScope 环境
2. **API 依赖** — 需要 DashScope 或其他 LLM API
3. **功能有限** — 不如 Letta 的虚拟内存强大
4. **生态较小** — 主要在 AgentScope 生态中使用
5. **文档有限** — 相比 Mem0 文档较少

## 平替对比

| 框架 | 透明性 | 记忆类型 | 复杂度 | 适合场景 |
|------|--------|----------|--------|----------|
| ReMe | 高（文件） | 3 种专门 | 低 | 需要用户编辑 |
| Letta | 中 | 2 种块 | 高 | 深度个性化 |
| Mem0 | 低 | 3 种层级 | 中 | 快速开发 |
| Text2Mem | 低 | 原子操作 | 中高 | 标准化 |

## 落地过程

⚠️ **待补充**：本地测试记录。

## 使用场景

- **需要用户信任** — 用户想了解 Agent 记住了什么
- **错误记忆纠正** — 用户可以手动修改错误信息
- **透明化需求** — 需要展示记忆给用户看的场景
- **任务学习** — 从任务执行中学习经验
- **工具优化** — 记录工具调用模式

## 适合人群

- 使用 AgentScope 的开发者
- 对记忆透明性有需求的团队
- 希望用户参与记忆管理的场景

## 成本评估

- **开源免费**：Apache 2.0
- **运行成本**：主要是 LLM API + Embedding API
- **估算**：1000 用户 × $0.01/用户/月 ≈ $10/月

## 学习曲线

- **入门难度**：低 — API 简洁，示例丰富
- **进阶功能**：中 — 三种记忆类型选择
- **推荐资源**：AgentScope 官方文档

## 维护状态

- **维护中**：作为 AgentScope 的一部分维护
- **更新**：随 AgentScope 2.0 更新
- **文档**：有官方示例和教程

## 社区活跃度

- **AgentScope Star**：3k+
- **ReMe 生态**：阿里 Modelscope 团队支持
- **社区**：Discord + DingTalk

---

*调研时间：2026-04-15*
