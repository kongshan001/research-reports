# Graphify 调研报告

## 概述

**Graphify** 是一个将代码库、文档、图片、视频转换为**可查询知识图谱**的 CLI 工具。

- **GitHub**: https://github.com/safishamsi/graphify
- **PyPI**: `graphifyy`（双 y）
- **版本**: 0.5.3
- **ClawHub**: https://clawhub.ai/fantox/graphify (评分 4.034)
- **支持语言**: 25+ 种编程语言（含 Python/JS/TS/Go/Rust/Java 等）

## 核心能力

| 能力 | 说明 |
|------|------|
| AST 提取 | tree-sitter 解析代码，无需 LLM，完全本地 |
| 语义提取 | LLM 分析文档/PDF/图片（需 API Key） |
| 视频转录 | Whisper 本地转录音视频 |
| 社区发现 | 自动检测代码社区聚类 |
| 路径查询 | BFS/DFS 遍历 + 最短路径 |
| 增量更新 | SHA-256 缓存，只处理变更文件 |
| 多平台集成 | Claude Code / Cursor / OpenClaw / Codex 等 |

## 三阶段流水线

1. **AST 提取** — tree-sitter 确定性解析（无 LLM 调用）
2. **转录** — Whisper 本地处理音视频
3. **语义提取** — LLM 并行分析文档/图片

## 与 Understand-Anything 对比

| 维度 | Graphify | Understand-Anything |
|------|----------|-------------------|
| 安装方式 | pip install (graphifyy) | ClawHub 技能 |
| 提取方式 | tree-sitter AST（本地） | subagent（需 LLM） |
| 输出格式 | graph.json + GRAPH_REPORT.md + graph.html | knowledge-graph.json |
| 查询能力 | ✅ 内置 query/path/explain 命令 | ❌ 无查询，需配合 Dashboard |
| 增量更新 | ✅ SHA-256 缓存 | ✅ git commit hash |
| 多模态 | ✅ PDF/图片/视频 | ❌ 仅代码 |
| 图谱规模 | 6207 nodes / 19918 edges (wangzhe-chess) | 70 nodes / 75 edges |
| Token 节省 | ~71.5x | 未知 |
| 社区发现 | ✅ 43 communities | ✅ 6 layers |

**关键差异**：Graphify 的 AST 提取不消耗 LLM token，图谱粒度更细（函数级 vs 文件级），且有内置查询引擎。

## 实际应用：wangzhe-chess 项目

### 生成的图谱

```
6207 nodes · 19918 edges · 43 communities
提取: 39% EXTRACTED · 61% INFERRED · 0% AMBIGUOUS
Token 成本: 0 input · 0 output（纯 AST 提取）
```

### Top God Nodes（核心抽象）

1. `BaseMessage` — 308 edges（消息系统核心）
2. `Hero` — 224 edges（英雄实体）
3. `Session` — 220 edges（WebSocket 会话）
4. `Base` — 192 edges（ORM 基类）
5. `IdMixin` — 177 edges（ID 混入）

### 查询示例

```bash
# 语义搜索
graphify query "battle simulator"
# → 返回 BattleSimulator, BattleUnit, DeterministicRNG 等相关节点

# 最短路径
graphify path "BattleSimulator" "Hero"
# → 5 hops: TestBattleSimulator → DamageType → Enum → models.py → ...

# 节点解释
graphify explain "BattleSimulator"
```

### 自动集成

已执行 `graphify claw install`，在 AGENTS.md 中写入规则，OpenClaw 会自动在回答代码问题时查询图谱。

## 与 LLM 知识库的结合思路

Graphify 的 graph.json 天然适合作为 RAG 的结构化数据源：

### 方案一：Graph-Enhanced RAG
```
graphify update . → graph.json → 节点摘要向量化 → RAG 索引
                                        ↓
用户提问 → graphify query → 定位节点 → 向量检索扩展 → LLM 回答
```

### 方案二：Agent 直接查询（当前已实现）
```
用户问代码问题 → AGENTS.md 规则 → graphify query/path → 精准上下文 → 回答
```
这是目前最低成本的方案，0 token 消耗，已经生效。

### 方案三：持续同步
```
git hook (post-commit) → graphify update . → 增量更新图谱
```
保持图谱与代码同步，`graphify hook install` 即可启用。

## 安装与使用

```bash
# 安装
pip install graphifyy

# 生成图谱
cd /path/to/project
graphify update .

# 查询
graphify query "认证逻辑在哪"
graphify path "AuthMiddleware" "Database"
graphify explain "UserSession"

# 注册到 OpenClaw
graphify claw install

# Git hook 自动同步
graphify hook install
```

## 参考链接

- GitHub: https://github.com/safishamsi/graphify
- ClawHub: https://clawhub.ai/fantox/graphify
- PyPI: https://pypi.org/project/graphifyy/
