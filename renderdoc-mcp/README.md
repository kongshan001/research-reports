# RenderDocMCP - 图形调试 MCP 服务器

## 1. 背景需求

在游戏开发和图形编程中，RenderDoc 是最常用的图形调试工具之一。它可以捕获 GPU 调用、帧缓冲、纹理、缓冲区等图形资源数据。然而，传统调试方式需要手动在 RenderDoc UI 中浏览大量数据，效率较低。

随着 AI 助手（如 Claude、Cursor）的普及，开发者希望能够通过自然语言来查询和分析 RenderDoc 的捕获数据，从而更快地定位渲染问题。

## 2. 目标

- 让 AI 助手能够直接访问 RenderDoc 的捕获数据
- 提供自然语言接口来查询图形调试信息
- 支持ドローコール分析、シェーダー检查、テクスチャ/バッファ数据获取

## 3. 设计方案

### 架构

```
Claude/AI Client (stdio)
        │
        ▼
MCP Server Process (Python + FastMCP 2.0)
        │ File-based IPC (%TEMP%/renderdoc_mcp/)
        ▼
RenderDoc Process (Extension)
```

### 核心设计

- **RenderDoc 扩展**: 作为 RenderDoc 的 UI 扩展运行Bridge
- **文件式 IPC**: 因 RenderDoc 内置 Python 没有 socket 模块，使用临时文件进行进程间通信
- **MCP 协议**: 使用 FastMCP 2.0 实现标准 MCP 服务器

### MCP 工具

| 工具 | 功能 |
|------|------|
| get_capture_status | 获取捕获文件加载状态 |
| get_draw_calls | 获取ドローコール列表（层级结构） |
| get_draw_call_details | 获取特定ドローコール详情 |
| get_shader_info | 获取シェーダー源码和常量缓冲 |
| get_buffer_contents | 获取缓冲内容（Base64） |
| get_texture_info | 获取纹理元数据 |
| get_texture_data | 获取纹理像素数据（Base64） |
| get_pipeline_state | 获取渲染管线状态 |

## 4. 本地部署

### 环境要求

- Python 3.10+
- uv 包管理器
- RenderDoc 1.20+

### 安装步骤

```bash
# 1. 安装 RenderDoc 扩展
python scripts/install_extension.py

# 2. 在 RenderDoc 中启用扩展
# Tools > Manage Extensions > 启用 "RenderDoc MCP Bridge"

# 3. 安装 MCP 服务器
uv tool install .

# 4. 配置 Claude Desktop
# claude_desktop_config.json:
{
  "mcpServers": {
    "renderdoc": {
      "command": "renderdoc-mcp"
    }
  }
}

# 5. 配置 Claude Code
# .mcp.json:
{
  "mcpServers": {
    "renderdoc": {
      "command": "renderdoc-mcp"
    }
  }
}
```

## 5. 效果展示

### 使用示例

```python
# 获取所有ドローコール
get_draw_calls(include_children=True)

# 获取特定事件的シェーダー信息
get_shader_info(event_id=123, stage="pixel")

# 获取パイプライン状态
get_pipeline_state(event_id=123)

# 获取纹理数据（指定mip级别）
get_texture_data(resource_id="ResourceId::123", mip=2)

# 获取缓冲内容（支持偏移和长度）
get_buffer_contents(resource_id="ResourceId::123", offset=256, length=512)
```

### 典型场景

1. **渲染问题排查**: "为什么这个物体没有渲染？" → AI 分析ドローコール和パイプライン状态
2. **シェーダー调试**: "这个纹理为什么是黑的？" → AI 检查シェーダー代码和常量缓冲
3. **性能优化**: "哪个ドローコール最耗时？" → AI 列出所有调用及其状态

## 6. 优缺点分析

### 优点

- ✅ AI 直接交互，无需手动在 RenderDoc UI 中搜索
- ✅ 支持全面的图形数据查询（ドローコール、シェーダー、テクスチャ、バッファ）
- ✅ 使用 FastMCP 2.0，现代化架构
- ✅ 支持多平台潜力（虽目前仅 Windows + DirectX 11 验证）

### 缺点

- ⚠️ 仅支持 Windows + DirectX 11 验证，其他平台/API 未测试
- ⚠️ 需要 RenderDoc 1.20+
- ⚠️ 文件式 IPC 可能存在延迟，不适合实时分析
- ⚠️ 项目较新（2024年），生态和社区支持有限

## 7. 平替对比

| 方案 | 特点 | 适用场景 |
|------|------|----------|
| **RenderDocMCP** | AI 驱动的图形调试 | 需要自然语言查询渲染数据 |
| **RenderDoc 内置 Python API** | 官方 API，功能完整 | 自动化脚本和批量分析 |
| **RenderDoc Online Capturing** | 远程捕获 | 移动端/嵌入式设备调试 |
| **Graphics API Debugger (NVIDIA Nsight)** | 硬件级调试 | GPU 特定优化 |

## 8. 落地过程

### 适用项目

- Unity/Unreal/自定义游戏引擎的渲染调试
- 图形 API (DirectX/Vulkan/OpenGL) 开发
- GPU Shader 开发和调试

### 集成建议

1. **开发流程**: 在本地开发时启动 RenderDoc 捕获，MCP 服务器常驻后台
2. **问题复现**: 捕获问题帧 → Claude 分析 → 定位根因
3. **团队协作**: 捕获文件 (.rdc) 可分享，团队成员均可使用 MCP 分析

### 注意事项

- 首次使用需安装 RenderDoc 扩展
- 配置文件需正确设置 MCP 客户端
- 大型捕获文件可能需要较长时间加载

---

**项目地址**: https://github.com/halby24/RenderDocMCP
**许可证**: MIT
