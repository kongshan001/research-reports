# EvoMap 深度调研报告

> 调研时间：2026-04-06 | 来源：evomap.ai 官方文档

---

## 一、项目概述

EvoMap（ evolvemap.ai ）定位为 **AI Agent 自我进化基础设施**，是一个 AI 代理协作市场。其核心理念是从生物学中汲取灵感：

> **Carbon and silicon, intertwined like a double helix** — agents share evolved capabilities through open protocol, humans provide the intuition that no algorithm can replicate.

简单来说：AI Agent 在这个平台上可以像生物进化一样，分享、继承、优化各自解决问题的能力，并通过 token 经济激励协作。

**运营主体**：AutoGame Limited

---

## 二、技术架构核心

### 2.1 GEP-A2A 协议

EvoMap 的核心通信协议为 **GEP-A2A (Gene Evolution Protocol - Agent to Agent)** v1.0.0。

所有 A2A 请求需要统一的协议信封结构：

```json
{
  "protocol": "gep-a2a",
  "protocol_version": "1.0.0",
  "message_type": "<hello|publish|validate|fetch|report>",
  "message_id": "msg_<unique>",
  "sender_id": "node_<your_node_id>",
  "timestamp": "<ISO 8601 UTC>",
  "payload": { "..." }
}
```

**协议特点**：
- 每个请求需要唯一 message_id
- 需要 Authorization Bearer token
- 支持 REST 风格端点 + A2A 协议两种模式

### 2.2 核心资产类型

EvoMap 定义了三种核心资产，完整发布需要打包为 **Bundle**：

| 资产类型 | 描述 | 关键字段 |
|---------|------|---------|
| **Gene** | 可复用的策略模板 | `category`, `signals_match`, `summary` |
| **Capsule** | 验证过的解决方案 | `trigger`, `content`, `diff`, `confidence`, `outcome` |
| **EvolutionEvent** | 进化过程记录 | `intent`, `genes_used`, `outcome`, `mutations_tried` |

**重要约束**：
- Gene 和 Capsule 必须一起发布（Bundle）
- 每个资产有内容寻址 ID：`sha256(canonical_json(asset_without_asset_id))`
- 需使用 canonical JSON（键排序）确保哈希一致性
- 可通过 `POST /a2a/validate` 预验证

### 2.3 节点注册与心跳

**注册流程**：
```
1. POST /a2a/hello（无 sender_id）
2. 获得 node_id + node_secret
3. 每 5 分钟心跳一次，否则 15 分钟后离线
```

```json
// Hello 响应
{
  "your_node_id": "node_a3f8b2c1d9e04567",
  "node_secret": "6a7b8c9d...64_hex_chars...",
  "claim_url": "https://evomap.ai/claim/REEF-4X7K"
}
```

---

## 三、生态功能模块

### 3.1 任务与赏金系统（Bounty Tasks）

- 用户发布问题，可附加 token 赏金
- Agent 认领 → 解决 → 发布解决方案 → 完成 → 获得赏金
- 支持 **Swarm** 多代理任务分解

**Swarm 机制**：
- 任务太大？分解为 subtasks 并行执行
- 奖励分配：发起者 5%，求解者 85%（按权重），聚合者 10%

### 3.2 工作池（Worker Pool）

- 注册为 worker，平台自动分配任务
- 基于领域 expertise 匹配
- 适合持续运行模式

### 3.3 配方与有机体（Recipe + Organism）

- **Recipe**：可复用的 Gene 流水线（链式执行）
- **Organism**：Recipe 的运行实例，追踪每个 Gene 的执行

```
创建 Recipe → 发布 → 表达为 Organism → 执行每个 Gene → 标记完成
```

### 3.4 会话协作（Session）

- 多代理实时协作解决复杂问题
- 支持消息传递、上下文共享、任务板

### 3.5 服务市场（Service Marketplace）

- Agent 可发布并出售自己的能力
- 其他代理或用户可以下单购买服务

### 3.6 Token 经济

- 信用 credits 作为流通货币
- 支持充值、转移、任务支付、服务购买
- 有完整的经济学 API 可查询

---

## 四、应用场景与最佳实践

### 4.1 典型场景

| 场景 | 适用功能 |
|------|---------|
| 代码问题修复 | Bounty Tasks + Swarm |
| 持续性开发任务 | Worker Pool |
| 复杂工作流 | Recipe + Organism |
| 实时 debug 协作 | Session |
| 专业化能力输出 | Service Marketplace |

### 4.2 接入最佳实践

1. **先看文档**：`GET /a2a/help?q=<keyword>` 即时查询
2. **注册节点**：完整走一遍 hello → heartbeat 流程
3. **预验证**：发布前用 `/a2a/validate` 验证哈希
4. **保持心跳**：每 5 分钟一次，断开即离线
5. **从小处着手**：先发布简单 Capsule 积累 reputation

---

## 五、对软件开发的启示

从 EvoMap 的设计中，可以提取以下对软件开发有价值的思路：

### 5.1 内容寻址与版本管理

```
asset_id = sha256(canonical_json(asset))
```

**启发**：
- 任何可复用单元都应有唯一内容哈希
- 关键配置、模板、解决方案均可用此思路做去重和版本追踪
- 配合 canonical JSON 保证确定性

### 5.2 协议信封设计

统一协议结构（protocol + version + message_type + payload）是通用做法，但 EvoMap 的亮点在于：
- 每个 message 带唯一 ID，方便追踪
- 错误响应带 `correction` 块，直接给出修复建议
- 4xx 不重试，5xx 指数退避

### 5.3 任务分解与并行（Swarm）

- 大任务拆小任务 → 多代理并行 → 聚合结果
- 类似 MapReduce 思想，适合 AI Agent 场景

### 5.4 声誉与经济系统

- reputation 影响任务可见性和分成
- credits 作为激励，形成正向循环

### 5.5 自描述 API

`GET /a2a/help?q=<anything>` 是很好的设计：
- 无需文档站点，直接运行时查询
- 支持概念查询和端点查询
- 返回结构化 + markdown 双格式

### 5.6 生物隐喻的架构设计

用 DNA→Gene→Capsule→EvolutionEvent 来类比系统设计：
- **DNA**（底层编码）→ 基础设施抽象
- **Gene**（可遗传能力）→ 可复用策略
- **Capsule**（具体解决方案）→ 验证过的产出
- **Evolution**（进化过程）→ 持续优化迭代

这种隐喻有助于构建**可积累、可演进**的系统。

---

## 六、总结

EvoMap 是一个非常有意思的实验：它尝试在 AI Agent 之间建立类似生物进化的协作机制。通过 GEP-A2A 协议、Bundle 发布机制、赏金任务、Swarm 分解、Recipe 复用等设计，构建了一个 AI 解决问题的协作网络。

对于软件开发而言，其核心价值不在于直接使用这个平台，而在于它展示的：
- **内容寻址**的思想
- **协议设计**的细节
- **任务分解**的思路
- **自描述 API** 的实践
- **生物隐喻**的架构思维方式

这些都是可以迁移到其他系统设计中的有效信息。

---

*文档最后更新：2026-04-06*