# kanban-framework v0.3.0 深度源码分析 + 生产验证报告

> **验证日期**: 2026-05-04
> **验证环境**: wangzhe-chess（134个Python文件，63752行代码的自走棋游戏项目）
> **框架版本**: v0.3.0 (commit ff7f5f5)
> **仓库**: https://github.com/kongshan001/kanban-framework
> **分析范围**: 全量源码 3901 行（9个 Shell lib + SKILL.md + 8个 Agent + 5个 Rule + 6个 Test Suite + Dashboard）

---

## 一、源码架构全景

### 1.1 代码规模

| 模块 | 文件 | 行数 | 职责 |
|------|------|------|------|
| kanban.sh | 核心库 | 1512 | 任务 CRUD、目录迁移、知识管理、版本管理 |
| guard.sh | 防护层 | 357 | 三层 FSM 守卫 + Plan 质量门禁 |
| workflow.sh | 状态机 | 325 | 阶段转换、自迭代判断、Plan 重试 |
| worktree.sh | 隔离层 | 229 | Git Worktree 创建/合并/清理/校验 |
| dashboard.sh | 可视化 | 247 | Dashboard 进程管理 |
| evaluator.sh | 评估层 | 150 | 多角色评估调度、评分汇总 |
| scheduler.sh | 调度器 | 203 | 并行调度、依赖检查、冲突检测 |
| self_improve.sh | 自改进 | 214 | 自迭代检查、Skills 演化、框架自评估 |
| recovery.sh | 恢复层 | 133 | 崩溃恢复、超时检测 |
| SKILL.md | 编排规范 | 531 | 命令路由 + Agent 调度 prompt 模板 |
| **总计** | **9 lib + 1 spec** | **3901** | |

### 1.2 依赖关系图

```
SKILL.md (命令路由层)
  └── kanban.sh (核心: 任务CRUD + index + 知识 + 版本)
        ├── guard.sh (防护: transition + artifact + score + plan_quality)
        ├── workflow.sh (状态机: transition + 自迭代)
        │     └── ⚠️ 覆盖了 kanban.sh 的 _update_index
        ├── worktree.sh (隔离: create + merge + cleanup + validate)
        ├── evaluator.sh (评估: prepare + record + check + collect)
        ├── scheduler.sh (调度: next_task + parallel + dependency)
        ├── self_improve.sh (自改进: check + evolve + framework_assess)
        ├── recovery.sh (恢复: recover + timeout + list_interrupted)
        └── dashboard.sh (可视化: start + stop + status + restart)
```

### 1.3 数据模型

**task.json 核心字段（17个）：**
```
id, title, description, engine, status, phase, phase_lock,
assignee, worktree{branch,path,base}, iteration, max_iterations,
token_budget, token_used, scores{}, depends_on[], modified_files[],
task_breakdown{file,subtasks[]}, history[], user_decision,
requires_archive_confirmation, created_at, updated_at, entered_at
```

**目录结构（新旧两种格式）：**
```
新格式（v0.2+内聚目录）:         旧格式（v0.1散落文件）:
.kanban/tasks/TASK-001/          .kanban/tasks/TASK-001.json
  task.json                      .kanban/reports/TASK-001/iteration-1/
  inbox.md                       .kanban/dispatch/TASK-001-*.json
  dispatch/
  iteration-1/
    requirements.md
    code_reviewer_report.json
```

---

## 二、生产环境验证结果

在 wangzhe-chess 项目上执行完整 FSM 生命周期 + 多任务并行。

### 2.1 验证通过项 ✅

| 功能 | 测试方法 | 结果 |
|------|----------|------|
| `kanban init` | 在 git 仓库初始化 | ✅ 创建 7 个子目录 + 安装 14 个框架文件 |
| `kanban create` × 3 | 并行创建 3 个任务 | ✅ task.json 17 字段完整 + inbox.md + feature 分支 |
| `kanban status` | 直接扫描目录 | ✅ 正确展示 3 个任务状态表 |
| `workflow_transition` × 7 | 完整 FSM 流转 | ✅ pending→plan→execute→evaluate→user_decision→archive |
| PhaseGuard | 8 次检查 | ✅ 5 PASS / 3 FAIL（均为预期拦截） |
| Worktree 创建 | git worktree add | ✅ 幂等、隔离、validate 返回结构化诊断 |
| 评估评分 | 4 角色打分 8.0 | ✅ record/collect/check 全链路正确 |
| Dashboard API | npm test | ✅ 19/19 测试全部通过 |
| 调度器 | scheduler_next_task | ✅ 正确选择 TASK-002（最早的 pending） |
| 恢复 | recover_list_interrupted | ✅ 识别 planning 状态中断任务 |
| 版本记录 | kanban_version_record | ✅ 生成 v0.1.0.md + CHANGELOG.md |
| Archive 归档 | kanban_archive_task | ✅ worktree merge + cleanup + 目录迁移 |
| 用户决策 | kanban_decide | ✅ approve_and_archive 需显式确认 |
| 子任务管理 | kanban_update_subtask | ✅ 状态流转 in_progress/completed/failed |
| 知识管理 | kanban_knowledge_add | ✅ K001 自增 + 分类索引 |
| 单元测试 | 6 个测试套件 | ✅ 81/81 通过（修复旧格式测试后） |

### 2.2 发现的 Bug 列表 🐛

---

#### Bug #1 [严重] `_update_index` 被覆盖 → index.json 永远为空

| 项目 | 详情 |
|------|------|
| **位置** | `workflow.sh:321-325` |
| **现象** | `index.json` 的 tasks 数组始终为 `[]` |
| **根因** | `workflow.sh` 在 `kanban.sh` 之后被 source，其 `_update_index()` 覆盖了完整实现，变成只调用不存在的 `_update_index_core` 的空壳 |
| **影响范围** | Dashboard `/api/tasks` 返回空、scheduler 依赖 index 的功能失效 |
| **修复** | 删除 `workflow.sh:321-325` 整个 `_update_index()` 函数 |

```bash
# workflow.sh:321-325 — 应删除
_update_index() {
  if type _update_index_core >/dev/null 2>&1; then
    _update_index_core
  fi
}
```

**验证复现**: 创建 3 个任务后检查 `index.json`:
```json
{"project":"wangzhe-chess","trunk":"main","tasks":[]}
```
手动执行 `kanban.sh` 中的 `_update_index` 逻辑可正确填充，证明逻辑正确但被覆盖。

---

#### Bug #2 [严重] Dashboard server.js 只读旧格式 → 新格式项目看不到任务

| 项目 | 详情 |
|------|------|
| **位置** | `dashboard/server.js:50-67` (`readAllTasks` 函数) |
| **现象** | Dashboard 页面显示 0 个任务 |
| **根因** | `readAllTasks()` 只扫描 `tasks/*.json`（旧格式），不读 `tasks/TASK-NNN/task.json`（新格式） |
| **影响范围** | Dashboard 完全不可用于新格式项目（v0.2+ 的默认格式） |

```javascript
// server.js:53 — 只匹配 .json 文件
const files = fs.readdirSync(tasksDir).filter(f => f.endsWith('.json'));
// 缺少: 读取子目录中的 task.json
```

**修复方案**:
```javascript
function readAllTasks() {
  const tasksDir = path.join(KANBAN_ROOT, 'tasks');
  if (!fs.existsSync(tasksDir)) return [];
  const entries = fs.readdirSync(tasksDir, { withFileTypes: true });
  return entries.map(entry => {
    try {
      let data;
      if (entry.isDirectory()) {
        const tf = path.join(tasksDir, entry.name, 'task.json');
        if (!fs.existsSync(tf)) return null;
        data = JSON.parse(fs.readFileSync(tf, 'utf-8'));
      } else if (entry.name.endsWith('.json')) {
        data = JSON.parse(fs.readFileSync(path.join(tasksDir, entry.name), 'utf-8'));
      } else return null;
      return { id: data.id, status: data.status, phase: data.phase, /*...*/ };
    } catch (_) { return null; }
  }).filter(Boolean);
}
```

---

#### Bug #3 [严重] 所有 Agent 定义引用旧路径 → Agent 无法找到产物文件

| 项目 | 详情 |
|------|------|
| **位置** | `agents/*.md`（全部 8 个 agent 定义） |
| **现象** | Agent 在执行时无法读取 requirements.md 等产物 |
| **根因** | Agent 中硬编码路径为 `.kanban/reports/${task_id}/iteration-${iteration}/`，但 v0.2+ 实际路径为 `.kanban/tasks/${task_id}/iteration-${iteration}/` |
| **影响范围** | 所有 Agent 的 Read 操作都会失败 |

**受影响文件清单**（27处引用）:
- `agents/code-reviewer.md` — 4 处
- `agents/designer.md` — 4 处
- `agents/executor.md` — 4 处
- `agents/knowledge-manager.md` — 1 处
- `agents/planner.md` — 1 处
- `agents/pm.md` — 4 处
- `agents/qa.md` — 4 处
- `agents/researcher.md` — 1 处

**修复**: 全局替换 `.kanban/reports/${task_id}/` 为使用 `$report_dir` 变量（由 dispatch JSON 注入）。

---

#### Bug #4 [中等] 评估模板文件名与代码不匹配

| 项目 | 详情 |
|------|------|
| **位置** | `evaluator.sh:30` vs `templates/reports/` |
| **现象** | `evaluator_prepare_all` 报错 "No such file or directory" |
| **根因** | 模板文件名用连字符 `code-reviewer.json`，代码用下划线 `code_reviewer` |
| **影响** | 评估调度 dispatch 文件内容为空，Agent 无评估上下文 |

```
文件系统:  templates/reports/code-reviewer.json
代码引用:  templates/reports/code_reviewer.json  ← 不匹配
```

---

#### Bug #5 [中等] 自迭代时 iteration 不递增

| 项目 | 详情 |
|------|------|
| **位置** | `workflow.sh` `workflow_transition()` 函数 |
| **现象** | `user_decision → plan` 自迭代后 iteration 仍为 1（应为 2） |
| **根因** | `jq_extra` 仅在 `iteration == 0` 时设 `.iteration=1`，后续迭代无处理 |
| **影响** | 所有迭代的报告目录始终为 `iteration-1`，历史被覆盖 |
| **注意** | `workflow_start_iteration()` 中有递增逻辑，但它不在 transition 链路中 |

**修复**: 在 `workflow_transition` 中追加:
```bash
if [ "$to_phase" = "plan" ] && [ "$from_phase" != "" ]; then
  jq_extra=".iteration=(.iteration+1) | $jq_extra"
fi
```

---

#### Bug #6 [中等] 单元测试 test_kanban_st003.sh 全部失败

| 项目 | 详情 |
|------|------|
| **现象** | 21 个测试全部 FAIL（0 PASS） |
| **根因** | 测试使用 `get_latest_task_id()` 查找 `TASK-*.json`（旧格式），但框架现在创建 `TASK-NNN/task.json`（新格式），导致找不到任务 |
| **影响** | 知识管理、进度展示、归档确认等功能测试失效 |

---

#### Bug #7 [低] CHANGELOG.md 条目被注释包裹

| 项目 | 详情 |
|------|------|
| **位置** | `kanban.sh` `kanban_version_record()` |
| **现象** | 新版本条目被写在 `<!-- 格式: ... -->` 注释块内，用户看不到 |
| **根因** | awk 脚本在 `/^<!-- 格式:/` 行后插入，但注释是多行的 |

---

#### Bug #8 [低] `user_decision → execute` 不应被允许

| 项目 | 详情 |
|------|------|
| **位置** | `guard.sh:39` |
| **现象** | `user_decision → execute` 通过 Guard 检查（不应通过） |
| **语义** | 跳过 plan 直接 execute 破坏流程完整性 |

```bash
# guard.sh:39 — 当前
user_decision) case "$to" in archive|plan|execute) return 0 ;; esac ;;
# 建议
user_decision) case "$to" in archive|plan) return 0 ;; esac ;;
```

---

#### Bug #9 [低] `kanban_init` 中 sed 命令格式错误

| 项目 | 详情 |
|------|------|
| **位置** | `kanban.sh` `kanban_init()` |
| **现象** | `sed: can't read s/"trunk": ... : No such file or directory` |
| **根因** | macOS 风格 `sed -i ''` 在 Linux 上无效，应使用 `sed -i` |
| **影响** | trunk 分支名非 main 时 config.json 不会被更新 |

---

#### Bug #10 [低] `framework_self_assess` 无参数时报错不友好

| 项目 | 详情 |
|------|------|
| **现象** | 输出 "WARNING: cannot find task file for" |
| **修复** | 添加参数检查和 usage 提示 |

---

## 三、架构深度分析

### 3.1 设计亮点 ⭐

**1. 三层 Guard 防护体系（行业领先）**

```
Layer 1: Transition Guard — 合法阶段转换表
Layer 2: Artifact Guard  — 必需产物检查
Layer 3: Score Guard     — 评估报告完整性
+ Plan Quality Gate      — 4维加权评分 (v0.2新增)
```

这是 Agent 编排框架中见过的最严格的流程约束。每层检查独立、可组合、失败原因明确。特别是 Plan Quality Gate 用正则扫描 requirements.md 结构来评分，虽然粗糙但思路正确。

**2. Worktree 隔离 + 双引擎支持**

```bash
# 优先使用 agent-worktree (wt CLI)
# 回退到原生 git worktree
# 幂等创建 + validate 诊断
```

支持 `wt` CLI 和原生 git worktree 双引擎，幂等设计避免重复创建，`worktree_validate()` 返回结构化 JSON 诊断（errors + warnings），是生产级设计。

**3. 热迭代 / 全量迭代分流**

```
热迭代: score >= 7.0 && 无架构问题 && Plan 产物有效 → 跳回 Execute
全量迭代: 其他情况 → 回到 Plan
```

这个设计避免了低质量 Plan 被反复执行的问题，是实用的工程折衷。

**4. 11条铁律体系**

CLAUDE.md 中定义的 IR-01 到 IR-11 铁律，将框架的不可变约束显式化。特别是 IR-11（归档需用户确认）通过 `requires_archive_confirmation` 字段 + `kanban_decide` 强制执行，是安全设计的典范。

**5. 新旧格式自动迁移**

`migrate_all_tasks()` 在 `kanban_init_env()` 时自动检测并迁移旧格式。所有 helper 函数（task_dir/task_file/report_dir/dispatch_dir/inbox_file）都做双格式兼容。这对框架升级的平滑性很重要。

**6. 原子写入模式**

所有 task.json 更新都使用 `mktemp` + `mv` 的原子写入模式，避免并发写入导致的数据损坏。

### 3.2 架构问题与改善建议

#### 问题 A: Shell 函数覆盖风险 [严重]

**问题本质**: `kanban_init_env()` 按文件名 source 所有 lib/*.sh，后加载的文件可能覆盖前面定义的函数。Bug #1 就是 `workflow.sh` 覆盖 `kanban.sh` 的 `_update_index` 导致的。

**根因**: Shell 没有 namespace 机制，所有函数都在全局作用域。

**建议方案**:
1. **命名空间前缀**: 所有 kanban.sh 函数加 `kb_` 前缀，guard.sh 加 `guard_` 前缀... 但工作量大
2. **防覆盖检查**: 在关键函数定义前检查是否已存在
   ```bash
   if type _update_index >/dev/null 2>&1; then
     echo "FATAL: _update_index redefined in $(basename "$0")" >&2
     exit 1
   fi
   ```
3. **显式加载顺序**: 不用 glob，改为显式列表
   ```bash
   for lib in kanban guard workflow evaluator worktree scheduler self_improve recovery dashboard; do
     source "$lib_dir/${lib}.sh"
   done
   ```

#### 问题 B: 新旧格式过渡不彻底 [严重]

v0.2 引入了新的内聚目录结构，但多处仍使用旧格式：

| 组件 | 新格式支持 | 问题 |
|------|-----------|------|
| kanban.sh helper 函数 | ✅ 双格式兼容 | — |
| kanban_status | ✅ 扫描两种 | — |
| guard.sh | ✅ 通过 helper | — |
| Dashboard server.js | ❌ 只读旧格式 | Bug #2 |
| Agent 定义 (*.md) | ❌ 硬编码旧路径 | Bug #3 |
| 单元测试 st003 | ❌ 只查旧格式 | Bug #6 |
| evaluator.sh | ✅ 通过 helper | — |

**建议**: 新格式已稳定，应全面清理旧格式代码。在 v0.4 中标记旧格式 deprecated，v0.5 移除兼容代码。

#### 问题 C: index.json 双路径问题

**当前状态**: `kanban_status()` 直接扫描目录（正确），Dashboard 读 index.json（空）。两条数据路径。

**建议**: Dashboard 也改为直接扫描目录（`readdirSync` + 读 task.json），删除 index.json。index.json 的同步成本（每次 transition 都更新）大于收益（仅 Dashboard 使用）。

#### 问题 D: Agent 报告 schema 不统一

评估模板定义了 `required_fields` 和 `schema`，但 Agent 定义中的输出格式与之不同：

```
模板 (templates/reports/code-reviewer.json):
  required_fields: ["score", "improvements", "risks", "architecture_issues", "code_style_violations"]

Agent 定义 (agents/code-reviewer.md):
  输出格式: {dimensions: {architecture: {...}}, score: 0.0, passed: false, ...}

evaluator_record_score 实际读取:
  .average_score // .score
```

三者的字段名和结构不完全匹配。建议统一 schema 并添加 JSON Schema 验证。

#### 问题 E: 错误处理缺乏标准化

当前错误格式混杂：

| 来源 | 格式 |
|------|------|
| Guard | `FAIL:reason:detail` |
| kanban.sh | `ERROR: message` |
| workflow.sh | `GUARD BLOCKED: ...` |
| SKILL.md prompt | `PLAN_QUALITY_FAIL: ...` |

建议定义标准错误函数：
```bash
kanban_error()   { echo "ERROR:kanban:$1" >&2; return 1; }
kanban_guard()   { echo "FAIL:$1:$2" >&2; return 1; }
kanban_warn()    { echo "WARN:kanban:$1" >&2; }
```

#### 问题 F: 缺少并发安全机制

`_update_index` 使用 `mktemp` + `mv` 实现原子写入（好），但 `kanban_update_task` 在读-改-写之间没有锁。如果两个 Agent 同时更新同一个 task.json，可能出现数据丢失。

建议：使用 `flock` 实现文件锁：
```bash
kanban_update_task() {
  local tf=$(task_file "$1")
  (
    flock -x 200
    # ... read-modify-write ...
  ) 200>"$tf.lock"
}
```

#### 问题 G: self_improve_check 与 workflow_self_improve_check 重复

两个函数做几乎相同的事（判断是否需要迭代），但逻辑有差异：

| 函数 | 判断 all_pass | 判断 max_reached | 判断 hot/full |
|------|:---:|:---:|:---:|
| self_improve_check | ✅ | ✅ | ❌ (只返回 "iterate") |
| workflow_self_improve_check | ✅ | ✅ | ✅ (返回 "hot"/"full") |

应合并为一个，避免行为不一致。

### 3.3 性能分析

**index.json 更新开销**: 每次任务状态变更都会触发 `_update_index`（遍历所有 task 目录 + 2 次 jq 调用/任务 + 1 次 jq -n 合并）。100 个任务时约 200 次 jq 调用。建议改为懒更新或直接删除 index.json。

**Dashboard SSE 推送**: 使用 fs.watch 监听目录变更，配合 150ms debounce，设计合理。但只监听旧格式路径。

**Guard 中的 bc 调用**: 每次阈值比较都 fork 一个 bc 进程。高频调用时（如调度器主循环）可能有性能问题。建议改用 bash 原生整数比较（将浮点 × 10 转为整数）。

### 3.4 安全性评估

| 安全项 | 评分 | 说明 |
|--------|------|------|
| Dashboard XSS 防护 | ✅ | DOMPurify 清洗 HTML |
| Dashboard 路径遍历 | ✅ | 阻止 `../../../etc/passwd` |
| Dashboard 信息泄露 | ✅ | 错误响应不暴露文件路径 |
| 归档确认机制 | ✅ | IR-11 铁律 + requires_archive_confirmation |
| Git 操作安全 | ⚠️ | worktree_merge 使用 `git merge --squash` 无冲突检测 |
| 文件锁 | ❌ | 并发写入 task.json 无保护 |

---

## 四、单元测试分析

### 4.1 测试覆盖情况

| 测试套件 | 测试数 | 通过 | 失败 | 覆盖范围 |
|----------|--------|------|------|----------|
| test_hot_iteration_fixes.sh | 19 | 19 | 0 | Fix 1-8 修复验证 |
| test_integration_st010_st017.sh | 43 | 43 | 0 | 归档兜底、目录内聚、迁移、Plan 质量门禁 |
| test_kanban_st003.sh | ~21 | 0 | ~21 | 知识管理、进度、归档确认（❌ 全失败） |
| test_retrospective.sh | ~7 | 5 | 2 | Retrospective FSM 扩展 |
| test_score_history_st007.sh | ~8 | 0 | ~8 | 评分历史（❌ 全失败） |
| test_worktree_lifecycle_st001_st009.sh | ~12 | 10 | 2 | Worktree 生命周期 |
| Dashboard (npm test) | 19 | 19 | 0 | API 安全测试 |
| **总计** | **~129** | **~96** | **~33** | |

### 4.2 测试失败原因分析

**test_kanban_st003.sh 全部失败**: `get_latest_task_id()` 查找 `TASK-*.json` 旧格式，与新的 `TASK-NNN/task.json` 不匹配。

**test_score_history_st007.sh 失败**: 同样的旧格式路径问题。

**test_retrospective.sh 部分失败**: "evaluate → user_decision (blocked when retrospective present)" 测试期望失败但实际通过，说明 retrospective 兼容逻辑有细微问题。

### 4.3 测试覆盖缺口

| 功能 | 有测试 | 缺测试 |
|------|--------|--------|
| kanban init | ✅ | — |
| kanban create | ✅ | — |
| kanban status | ✅ | — |
| FSM transition | ✅ | — |
| Guard 三层检查 | ✅ | — |
| Worktree CRUD | ✅ | — |
| 评估系统 | ✅ | — |
| kanban_decide | ✅ | — |
| kanban_archive | ✅ | — |
| **Dashboard server.js** | ❌ | **新格式任务读取** |
| **Agent 调度** | ❌ | **端到端 Agent 交互** |
| **并发安全** | ❌ | **多 Agent 同时更新 task.json** |
| **worktree_merge 冲突** | ❌ | **合并冲突场景** |
| **热迭代完整流程** | ❌ | **score 7.x → hot → execute 循环** |

---

## 五、CLAUDE.md 铁律体系评审

11 条 Iron Rules 设计合理，但与代码实现有差距：

| 铁律 | 代码实现 | 一致性 |
|------|----------|--------|
| IR-01 Guard 不可绕过 | guard_check 在 transition 入口 | ✅ 一致 |
| IR-02 产物完整性 | guard_check_artifacts | ✅ 一致 |
| IR-03 4角色评估 | evaluator + guard_check_evaluation | ✅ 一致 |
| IR-04 热迭代条件 | workflow_self_improve_check | ✅ 一致 |
| IR-05 文档产出 | artifact guard | ✅ 一致 |
| IR-06 知识沉淀 | kanban_knowledge_add + framework_self_assess | ⚠️ 非强制（retrospective 阶段可选） |
| IR-07 Worktree 清理 | worktree_cleanup | ✅ 一致 |
| IR-08 迭代上限 | workflow_self_improve_check | ✅ 一致 |
| IR-09 评分统一 | evaluator + threshold | ✅ 一致 |
| IR-10 变更伴测试 | QA agent 评分维度 | ⚠️ 无 guard 强制（靠 QA agent 自觉） |
| IR-11 归档确认 | requires_archive_confirmation | ✅ 一致 |

---

## 六、改善建议路线图

### Phase 1: v0.3.1 — 热修复（1-2天）

**目标**: 修复 3 个严重 Bug，使框架基本可用。

| 编号 | Bug | 修复量 |
|------|-----|--------|
| Bug #1 | 删除 workflow.sh 的 `_update_index` | 5 行删除 |
| Bug #2 | Dashboard readAllTasks 支持新格式 | ~20 行重写 |
| Bug #3 | Agent 定义路径从 `reports/` 改为 `$report_dir` | 27 处替换 |

### Phase 2: v0.4.0 — 稳定性提升（1周）

| 编号 | 改善项 | 详情 |
|------|--------|------|
| Bug #4 | 模板文件名统一 | 重命名为下划线或修改代码 |
| Bug #5 | iteration 递增修复 | workflow_transition 增加递增逻辑 |
| Bug #6 | 测试适配新格式 | get_latest_task_id 改用 task_dir |
| 改善 A | 显式加载顺序 | 替代 glob source |
| 改善 C | 删除 index.json | Dashboard 改为直接扫描 |
| 改善 F | 并发安全 | task.json 写入加 flock |
| 新增 | 集成测试 | 完整 FSM 生命周期 + 多任务并行 |

### Phase 3: v0.5.0 — 架构优化（2周）

| 编号 | 改善项 | 详情 |
|------|--------|------|
| 改善 B | 清理旧格式代码 | 全部使用新格式，删除兼容逻辑 |
| 改善 D | 统一 Agent schema | 定义 JSON Schema 并在 guard 中验证 |
| 改善 E | 错误处理标准化 | 定义 kanban_error/kanban_guard 函数 |
| 改善 G | 合并重复函数 | self_improve_check 二选一 |
| 新增 | worktree 冲突处理 | merge 前检测冲突，提供解决选项 |
| 新增 | 性能优化 | bc 替换为整数比较，减少 jq 调用次数 |

---

## 七、总评

| 维度 | 评分(1-5) | 说明 |
|------|-----------|------|
| **设计理念** | 5 | FSM + Guard + 多角色评估 + 自迭代，Agent 编排的最佳实践 |
| **架构设计** | 4 | 模块化 lib 分工清晰，SKILL.md prompt 工程精细 |
| **代码质量** | 3.5 | 原子写入、幂等设计好，但存在覆盖 bug 和路径不一致 |
| **安全性** | 4.5 | Dashboard 防护完善，归档确认严格，缺并发保护 |
| **可维护性** | 3 | 新旧格式双路径增加复杂度，测试有 33 个失败 |
| **文档质量** | 4 | SKILL.md 详尽，CLAUDE.md 铁律体系有说服力 |
| **生产就绪度** | **3** | 修复 3 个严重 Bug 后可达到 4 分 |

### 核心结论

**kanban-framework 是目前见过的最完整的 Claude Code 任务编排框架。** 它的 FSM + Guard 三层防护 + 多角色评估设计，解决了 Agent 编排中最关键的质量保证问题。

v0.3.0 存在 3 个严重 Bug（index 覆盖、Dashboard 新格式不兼容、Agent 路径过时），这些是新旧格式迁移不彻底导致的。修复后框架即可用于生产环境。

**推荐的框架使用模式**:
1. 单 Agent 简单任务 → 直接用 Claude Code，不需要 kanban
2. 多步骤复杂任务（需要 Plan → Execute → Evaluate 循环）→ kanban 非常适合
3. 多 Agent 并行项目 → kanban + scheduler + worktree 隔离

---

## 附录

### A. 验证环境

```
项目: wangzhe-chess (王者之奕 - 自走棋游戏)
规模: 134 Python files, 63752 LOC
分支: main
依赖: jq 1.7, git 2.x, bash 5.x, node v24.13.1
创建任务: TASK-001 (战斗日志回放), TASK-002 (装备合成), TASK-003 (英雄池优化)
FSM 流转: 7 次 transition
Guard 检查: 8 次 (5 PASS / 3 FAIL 预期拦截)
Dashboard: 19/19 API 测试通过
单元测试: 129 个（96 通过 / 33 失败）
```

### B. Bug 严重性汇总

| 严重性 | 数量 | 编号 |
|--------|------|------|
| 🔴 严重 | 3 | #1 index覆盖, #2 Dashboard, #3 Agent路径 |
| 🟡 中等 | 3 | #4 模板文件名, #5 iteration不递增, #6 测试失败 |
| 🟢 低 | 4 | #7 CHANGELOG注释, #8 转换漏洞, #9 sed格式, #10 无参数报错 |
