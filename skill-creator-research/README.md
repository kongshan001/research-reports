# skill-creator 技能调研

## 1. 背景需求

AI 编程助手（如 Claude Code、Codex）虽然功能强大，但存在以下局限：
- **能力边界固定** - 无法按需扩展特定领域能力
- **工作流重复** - 相同任务每次都需要重新描述
- **知识零散** - 领域知识需要每次手动提供
- **缺乏标准化** - 团队无法共享最佳实践

## 2. 目标

skill-creator 是 Anthropic 提供的 **AgentSkills 创建工具**，旨在帮助 AI 获得特定领域的程序性知识、工作流程和工具集成，让通用 AI 代理"专业化"。

## 3. 设计方案

### 核心架构

```
skill-name/
├── SKILL.md (必需)
│   ├── YAML frontmatter 元数据 (必需)
│   │   ├── name: 技能名称
│   │   └── description: 触发描述
│   └── Markdown 主体说明
└── 资源包 (可选)
    ├── scripts/      - 可执行代码 (Python/Bash等)
    ├── references/   - 参考文档 (按需加载)
    └── assets/       - 输出资源 (模板、图片等)
```

### 渐进式加载设计

三层加载系统：
1. **元数据** (name + description) - 常驻上下文 (~100词)
2. **SKILL.md 主体** - 技能触发时加载 (<5k词)
3. **资源包** - 按需加载 (无限)

### 核心原则

| 原则 | 说明 |
|------|------|
| **简洁为王** | 上下文窗口是公共资源，默认 AI 已经很聪明 |
| **适当自由度** | 根据任务脆弱性和变异性选择指令粒度 |
| **渐进式披露** | 按需加载，避免上下文膨胀 |

## 4. 本地部署

### 前置要求

- OpenClaw 已安装
- Git 用于版本管理

### 安装步骤

skill-creator 已内置于 OpenClaw：

```
/usr/lib/node_modules/openclaw/skills/skill-creator/
├── SKILL.md
└── scripts/
    ├── init_skill.py
    ├── package_skill.py
    ├── quick_validate.py
    ├── test_package_skill.py
    └── test_quick_validate.py
```

### 使用方式

```bash
# 初始化新技能
python scripts/init_skill.py <skill-name> --path <output-directory> [--resources scripts,references,assets]

# 打包技能
python scripts/package_skill.py <path/to/skill-folder>

# 快速验证
python scripts/quick_validate.py <path/to/skill-folder>
```

## 5. 效果展示

### 创建流程

1. **理解技能用例** - 通过具体示例理解技能用途
2. **规划可复用内容** - 确定需要打包的脚本、参考、资产
3. **初始化技能** - 运行 init_skill.py 生成模板
4. **编辑技能** - 编写 SKILL.md 和资源文件
5. **打包技能** - 运行 package_skill.py 验证并打包
6. **迭代优化** - 基于实际使用反馈持续改进

### 示例：创建 PDF 编辑技能

```bash
# 初始化
python scripts/init_skill.py pdf-editor --path ./skills --resources scripts,references

# 编辑 SKILL.md 添加 PDF 处理指南
# 添加 scripts/rotate_pdf.py 等工具脚本
# 添加 references/api-docs.md 参考文档

# 打包
python scripts/package_skill.py ./skills/pdf-editor
```

## 6. 优缺点分析

### ✅ 优点

| 优点 | 说明 |
|------|------|
| **标准化格式** | 统一的 SKILL.md 格式，易于理解和创建 |
| **渐进式加载** | 优化上下文使用，不会一次性加载所有内容 |
| **模块化设计** | 技能自包含、可独立分发 |
| **实用性** | 基于真实用例迭代优化 |
| **可复用** | 一次创建，多次使用 |
| **官方支持** | Anthropic 官方维护 |

### ❌ 缺点

| 缺点 | 说明 |
|------|------|
| **学习曲线** | 需要理解技能设计原则 |
| **生态较小** | 相比社区技能生态较小 |
| **Codex 限定** | 主要面向 Codex，部分能力依赖于 OpenAI 生态 |

## 7. 平替对比

| 工具 | 特点 | 适用场景 |
|------|------|---------|
| **skill-creator** | Anthropic 官方技能创建工具 | OpenClaw/Codex 用户 |
| **OpenAI Skills** | Codex 官方技能系统，30+ 精选技能 | Codex 用户 |
| **MCP** | 模型上下文协议 | 跨平台工具集成 |
| **ClawHub** | 第三方 Skills 市场 | 多平台 Skills 共享 |

## 8. 落地过程

### 调研日期
2026-03-08

### 调研结果

已验证 OpenClaw 内置 skill-creator 功能完整：
- ✅ SKILL.md 格式规范
- ✅ 包含 5 个工具脚本
- ✅ 支持 scripts/references/assets 分离
- ✅ 已同步到 cc_skills 仓库

### 实践记录

1. 从 OpenClaw 内置技能复制到 cc_skills
2. 验证目录结构完整性
3. 测试工具脚本可用性

## 9. 使用场景

- 创建领域特定的 AI 技能
- 封装团队最佳实践
- 固化重复性工作流程
- 分发可复用的 AI 能力

## 10. 适合人群

- AI 助手深度用户
- 开发者工具团队
- 需要固化工作流的个人或团队

## 11. 成本评估

- **免费**：OpenClaw 内置功能
- **无 API 费用**：本地执行

## 12. 学习曲线

- **中等**：需要理解技能设计原则和渐进式加载机制
- 官方文档详细，建议先阅读 SKILL.md 主体内容

## 13. 维护状态

- **维护状态**：Anthropic 官方维护
- **更新频率**：随 OpenClaw 版本更新

## 14. 社区活跃度

- **Star**：N/A（内置于 OpenClaw）
- **文档完善度**：完整
- **工具脚本**：5 个（init/package/validate/test）

---

*调研完成时间：2026-03-08*
