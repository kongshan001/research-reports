# kanban-framework v0.3.0 生产环境验证报告

> **验证日期**: 2026-05-04
> **验证环境**: wangzhe-chess（134个Python文件，63000+行代码的自走棋游戏项目）
> **框架版本**: v0.3.0 (commit ff7f5f5)
> **仓库**: https://github.com/kongshan001/kanban-framework

---

## 一、验证方法论

在真实项目 `wangzhe-chess` 上执行完整的 FSM 生命周期：

```
init → create task × 3 → plan → execute → evaluate → user_decision → archive
```

覆盖的测试维度：

| 维度 | 测试内容 |
|------|----------|
| **初始化** | kanban init, 目录结构, agents/rules/dashboard 安装 |
| **任务管理** | 创建3个并行任务, task.json 结构, 分支创建 |
| **FSM 流转** | 全阶段 transition, 状态/phase_lock 同步 |
| **PhaseGuard** | transition/artifact/score 三层检查 |
| **Worktree** | 创建/验证, git worktree 隔离 |
| **评估系统** | 多角色报告, 评分记录, 阈值判断 |
| **Dashboard** | 19个 API/安全测试 |
| **版本管理** | version record, CHANGELOG 生成 |
| **调度器** | next_task, count_active, 依赖检查 |
| **恢复** | 中断任务检测 |

---

## 二、验证通过项 ✅

### 2.1 核心生命周期
- **`kanban init`**: 正确创建 .kanban/ 目录结构，安装 14 个框架文件（agents + rules + dashboard）
- **`kanban create`**: 任务创建正常，生成 task.json（15个字段完整）、inbox.md、feature 分支
- **`kanban status`**: 直接扫描 tasks 目录，正确展示多任务状态表
- **完整 FSM 流转**: `pending → plan → execute → evaluate → user_decision → archive` 全链路通过

### 2.2 PhaseGuard 三层防护
- **Transition Guard**: 正确拦截非法阶段跳转（如 archive → plan）
- **Artifact Guard**: 缺少产物文件时正确阻塞（缺少 4 个评估报告被拦截）
- **Score Guard**: 评分低于阈值（8.0 < 9.0）时正确拒绝通过

### 2.3 Worktree 隔离
- `worktree_create` 在 `.kanban/worktrees/TASK-NNN/` 创建独立 git worktree
- 幂等设计：重复创建不报错
- `worktree_validate` 返回结构化 JSON 诊断结果

### 2.4 Dashboard
- **19/19 测试全部通过**
- 安全性验证：路径遍历攻击防护、XSS 防护（DOMPurify）、错误信息不泄露
- API 端点正常：config, workflow, tasks

### 2.5 评估系统
- `evaluator_record_score`: 正确读取报告分数并写入 task.json
- `evaluator_collect_scores`: 汇总多角色评分，计算平均分
- `evaluator_check_pass`: 阈值判断正确

### 2.6 调度与恢复
- `scheduler_next_task`: 正确选择优先级最高的 pending 任务
- `recover_list_interrupted`: 准确识别未完成的 planning 状态任务
- `kanban_version_record`: 生成版本文件和 CHANGELOG

---

## 三、发现的 Bug 🐛

### Bug #1 [严重] `_update_index` 被覆盖导致 index.json 永远为空

| 项目 | 详情 |
|------|------|
| **文件** | `workflow.sh:321` |
| **现象** | `index.json` 的 tasks 数组始终为 `[]`，即使有 3 个任务 |
| **根因** | `workflow.sh` 重新定义了 `_update_index()`，只调用不存在的 `_update_index_core`，覆盖了 `kanban.sh` 中的完整实现 |
| **影响** | Dashboard 的 `/api/tasks` 返回空数组（尽管直接扫描测试通过，因为测试不依赖 index.json） |
| **修复建议** | 删除 `workflow.sh` 第 321-325 行的 `_update_index()` 函数定义 |

```bash
# workflow.sh:321-325 — 删除这整个函数
_update_index() {
  if type _update_index_core >/dev/null 2>&1; then
    _update_index_core
  fi
}
```

### Bug #2 [中等] 评估模板文件名与代码不匹配

| 项目 | 详情 |
|------|------|
| **文件** | `evaluator.sh:30` |
| **现象** | `evaluator_prepare_all` 报错 "No such file or directory" |
| **根因** | 模板文件名用连字符 (`code-reviewer.json`)，代码用下划线 (`code_reviewer`) |
| **影响** | 评估调度生成的 dispatch 文件内容为空，LLM Agent 无法获取评估上下文 |
| **修复建议** | 统一文件名，二选一：重命名模板文件为下划线，或修改代码使用连字符 |

```
# 文件系统:  templates/reports/code-reviewer.json
# 代码引用:  templates/reports/code_reviewer.json
```

### Bug #3 [中等] 自迭代时 iteration 不递增

| 项目 | 详情 |
|------|------|
| **文件** | `workflow.sh:62-75` |
| **现象** | `user_decision → plan` 自迭代后 iteration 仍为 1（应为 2） |
| **根因** | `jq_extra` 仅在 `iteration == 0` 时设置 `.iteration=1`，后续迭代不处理 |
| **影响** | 迭代报告目录始终写入 `iteration-1`，历史版本被覆盖 |
| **修复建议** | 在 workflow_transition 中，当 from != "" 且 to == "plan" 时递增 iteration |

```bash
# 在 jq_extra 赋值后追加:
if [ "$to_phase" = "plan" ] && [ "$from_phase" != "" ]; then
  jq_extra=".iteration=(.iteration+1) | $jq_extra"
fi
```

### Bug #4 [低] CHANGELOG.md 条目被注释包裹

| 项目 | 详情 |
|------|------|
| **文件** | `kanban.sh` 中 `kanban_version_record` 函数 |
| **现象** | 版本记录写入 CHANGELOG.md 时被 `<!-- -->` 包裹，实际内容不可见 |
| **影响** | 用户查看 CHANGELOG 看不到版本历史 |
| **修复建议** | 将版本条目写在注释区域之外 |

### Bug #5 [低] `user_decision → execute` 不应被允许

| 项目 | 详情 |
|------|------|
| **文件** | `guard.sh:39` |
| **现象** | 从 user_decision 阶段可以直接跳转到 execute |
| **语义问题** | 用户决策后应回到 plan（重新规划）或归档，跳过 plan 直接 execute 破坏流程完整性 |
| **修复建议** | 将 `case "$to" in archive|plan|execute)` 改为 `case "$to" in archive|plan)` |

### Bug #6 [低] `framework_self_assess` 缺少参数时报错不友好

| 项目 | 详情 |
|------|------|
| **现象** | 无参数调用输出 "WARNING: cannot find task file for" |
| **修复建议** | 添加参数检查，输出 usage 信息 |

### Bug #7 [低] `kanban_init` 中的 sed 警告

| 项目 | 详情 |
|------|------|
| **现象** | `sed: can't read s/"trunk": "main"/"trunk": "master"/: No such file or directory` |
| **根因** | sed 命令缺少 `-i` 或 `-e` 参数，sed 将表达式当作文件名 |
| **影响** | 当 trunk 分支名不是 main 时，config.json 不会正确更新 |

---

## 四、架构观察与改善建议

### 4.1 函数覆盖风险 [架构]

**问题**: `kanban_init_env` 按文件名 source 所有 lib/*.sh，后加载的文件可能覆盖前面定义的函数（如 _update_index）。当前没有防覆盖机制。

**建议**:
1. 在 `kanban.sh` 的关键函数顶部添加覆盖检测：
   ```bash
   if type _update_index >/dev/null 2>&1; then
     echo "WARNING: _update_index already defined, skip kanban.sh definition"
     return 0
   fi
   ```
2. 或者改为：所有 `_update_index` 实现重命名为 `_update_index_impl`，由统一入口调用

### 4.2 index.json 与直接扫描的双路径问题

**问题**: `kanban_status` 直接扫描目录，不依赖 index.json；但 Dashboard API 使用 index.json。两条数据路径导致行为不一致。

**建议**: 统一数据源。要么：
- 全部用 index.json（每次变更时更新）—— 需要先修复 Bug #1
- 全部用直接扫描（删除 index.json）—— 简单但性能稍差

### 4.3 错误处理标准化

**问题**: 不同函数的错误输出格式不统一（有的用 `ERROR:`，有的用 `FAIL:`，有的用 exit code）。

**建议**: 定义标准错误格式：
```bash
# 标准错误输出格式
kanban_error() { echo "ERROR: $1" >&2; return 1; }
kanban_fail() { echo "FAIL:$1:$2" >&2; return 1; }
```

### 4.4 缺少集成测试

**问题**: 当前只有 Dashboard 的 API 测试（19个），缺少核心工作流的端到端测试。

**建议**: 添加 `tests/integration/` 目录，覆盖：
- 完整 FSM 生命周期
- 多任务并行创建
- 自迭代流程
- Worktree 创建/合并
- Guard 拦截场景

### 4.5 配置验证

**问题**: `kanban init` 不验证 workflow.json 的结构正确性。

**建议**: init 时用 jq schema 验证 workflow.json 的 phases/transition 合法性。

---

## 五、生产环境适用性评估

| 评估维度 | 评分 (1-5) | 说明 |
|----------|-----------|------|
| **功能完整性** | 4 | 核心生命周期完整，4阶段FSM + 评估 + 版本管理 |
| **稳定性** | 3 | 存在 index 覆盖和模板文件名问题，影响实际使用 |
| **安全性** | 5 | Dashboard 安全测试全部通过，Guard 层设计完善 |
| **可扩展性** | 4 | 模块化 lib 设计，新增阶段/角色方便 |
| **文档质量** | 3 | SKILL.md 详细但缺少错误排查指南 |
| **生产就绪度** | 3 | 需修复 Bug #1 和 #2 后可用于生产 |

### 总评

框架设计理念优秀——FSM 强约束 + 多角色评估 + 自迭代是很好的 Agent 编排模式。但在 v0.3.0 中存在函数覆盖和文件名不匹配两个影响实际使用的 bug，建议修复后发布 v0.3.1。

**推荐路线**:
1. **v0.3.1（热修复）**: 修复 Bug #1（_update_index 覆盖）和 Bug #2（模板文件名）
2. **v0.4.0**: 修复其余 Bug + 添加集成测试 + 错误处理标准化
3. **v0.5.0**: 架构优化（双路径统一、配置验证）

---

## 附录：验证环境详情

```
项目: wangzhe-chess (王者之奕 - 自走棋游戏)
规模: 134 Python files, 63752 LOC
分支: main
依赖: jq 1.7, git 2.x, bash 5.x
创建任务: TASK-001 (战斗日志回放), TASK-002 (装备合成), TASK-003 (英雄池优化)
FSM 流转: 7 次 transition，全部成功
Guard 检查: 8 次检查，5 PASS / 3 FAIL（均为预期行为）
Dashboard: 19/19 测试通过
```
