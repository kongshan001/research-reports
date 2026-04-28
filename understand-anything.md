# Understand-Anything 调研报告

## 概述

**Understand-Anything** 是一个 ClawHub 上的热门 Agent 技能（作者 lum1104），用于分析代码库并生成交互式知识图谱（Knowledge Graph），帮助理解项目架构、组件关系和依赖。

- **ClawHub**: https://clawhub.ai/lum1104/understand
- **评分**: 1.523
- **最新版本**: 1.1.0（2026-04-28 更新）
- **配套**: Understand-Anything-Dashboard（可视化仪表盘）

## 核心机制

### 五阶段流水线

| 阶段 | 功能 | 方式 |
|------|------|------|
| **Phase 0: Pre-flight** | 检测变更，决定全量/增量分析 | git diff + commit hash |
| **Phase 1: SCAN** | 发现源文件、检测语言/框架 | subagent 并行扫描 |
| **Phase 2: ANALYZE** | 分析每个文件，生成 GraphNode + GraphEdge | subagent 批量分析（每批5-10文件，3个并发） |
| **Phase 3: ASSEMBLE** | 合并所有节点和边，去重清理 | 本地合并 |
| **Phase 4: ARCHITECTURE** | 识别架构分层（UI/API/Service/Data） | subagent + 框架感知提示 |
| **Phase 5: TOUR** | 生成代码导览路径 | subagent + README 对齐 |

### 关键设计

- **增量更新**：基于 git commit hash，只重新分析变更文件
- **框架感知**：自动识别 React/Next.js/Express/Django/Go 等，给出分层提示
- **并发分析**：最多 3 个 subagent 并行处理文件批次
- **输出**：`knowledge-graph.json`（节点 + 边 + 层级 + 导览）

## 与 LLM 知识库的结合思路

这是本次调研的重点。Understand-Anything 本质上是**代码结构 → 图谱**的转换器，但生成的知识图谱可以被 LLM 知识库系统直接消费。

### 思路一：图谱即知识库（Graph-as-Knowledge-Base）

```
代码库 → Understand-Anything → knowledge-graph.json → 向量化存储 → RAG
```

- 将生成的每个 GraphNode（文件级/模块级节点）的 `summary` 字段作为文档
- 将 GraphEdge（imports/calls/depends 关系）作为结构化元数据
- 构建向量索引时保留图谱关系，检索时可以沿边扩展上下文
- **效果**：问"用户认证是怎么实现的？"时，RAG 不仅找到 auth 模块，还能沿 imports 边找到依赖的 middleware、database 层

### 思路二：Agent 原生查询图谱

```
用户提问 → Agent 读取 knowledge-graph.json → 精确定位相关节点 → 读取源码
```

- 不走 RAG，而是让 Agent 直接读取 JSON 图谱
- 根据问题定位起始节点，沿边遍历相关节点
- 只读取相关文件的实际代码，而非全部索引
- **优势**：精确、实时、不需要额外的向量数据库

### 思路三：混合方案（推荐）

```
Understand-Anything 生成图谱
    ├── 结构层（图谱 JSON）→ Agent 直接查询
    ├── 语义层（node summary）→ 向量化 → RAG 检索
    └── 代码层（源文件）→ 按需读取
```

三层协作：
1. **图谱层**回答结构问题（"这个项目有哪些模块？"）
2. **RAG 层**回答语义问题（"错误处理是怎么做的？"）
3. **代码层**回答细节问题（"这个函数的具体实现？"）

### 思路四：持续同步

- 利用 Understand-Anything 的增量更新能力
- 每次 git push 触发增量分析
- 变更的节点自动更新向量索引
- 实现**代码知识库的实时同步**

## 对我们 OpenClaw 的启发

| 能力 | 当前状态 | 可借鉴 |
|------|---------|--------|
| 代码理解 | 靠 read/exec 手动探索 | 自动生成结构化图谱 |
| 知识检索 | 无 | RAG + 图谱混合检索 |
| 项目上下文 | 靠 AGENTS.md / SOUL.md | 自动化的 knowledge-graph |
| 增量同步 | 无 | git hook 触发增量更新 |

### 落地建议

1. **短期**：安装 understand-anything 技能，对我们的项目（wangzhe-chess、roguelike-survivor-h5 等）生成图谱
2. **中期**：把 knowledge-graph.json 集成到 Agent 上下文中，作为项目理解的"第二大脑"
3. **长期**：构建图谱 → 向量化 → RAG 的完整流水线，实现代码知识库

## 安装方式

```bash
clawhub install understand
clawhub install understand-dashboard
```

## 参考链接

- ClawHub 技能页: https://clawhub.ai/lum1104/understand
- 配套 Dashboard: https://clawhub.ai/lum1104/understand-dashboard
- 版本: 1.1.0（支持增量分析）
