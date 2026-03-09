# Unity RenderGraph 调研报告

## 1. 背景需求

在现代游戏开发中，渲染管线日益复杂。传统方式下，渲染开发者需要手动管理渲染资源的生命周期（创建、绑定、释放），这导致：

- **资源泄漏风险**: 手动管理容易遗漏资源释放
- **性能瓶颈难发现**: 渲染状态变化不透明，难以优化
- **代码耦合严重**: 渲染Pass之间相互依赖，难以复用
- **多线程困难**: 传统渲染 API 非线程安全

RenderGraph 应运而生，旨在解决这些问题。

## 2. 目标

- **自动化资源管理**: 自动追踪资源依赖关系和生命周期
- **渲染性能优化**: 消除不必要的渲染状态切换和资源绑定
- **并行渲染支持**: 为多线程渲染提供基础
- **调试友好**: 提供渲染过程的可视化和调试工具

## 3. 设计方案

### 核心概念

```
RenderGraph
    │
    ├── RenderPass（渲染通道）
    │       │
    │       ├── Pass Name
    │       ├── Enable/Disable 条件
    │       └── Execute() 回调
    │
    └── RenderResource（渲染资源）
            │
            ├── Texture（纹理）
            ├── Buffer（缓冲区）
            └── RenderTarget（渲染目标）
```

### 工作流程

```csharp
// 1. 创建 RenderGraph
var renderGraph = new RenderGraph();

// 2. 注册渲染资源
var colorBuffer = renderGraph.CreateTexture(new TextureDesc2D
{
    width = 1920,
    height = 1080,
    format = GraphicsFormat.R8G8B8A8_SRGB,
    name = "ColorBuffer"
});

// 3. 添加渲染 Pass
renderGraph.AddRenderPass("MainPass", (passData, context) =>
{
    // 设置渲染状态
    var cmd = context.cmd;
    cmd.SetRenderTarget(colorBuffer);
    
    // 执行渲染
    CoreUtils.DrawFullscreen(cmd, shader, material);
});

// 4. 执行渲染
renderGraph.Execute(commandBuffer);
```

### 自动资源管理

RenderGraph 会自动分析资源的使用关系：

1. **依赖分析**: 追踪每个 Pass 读取/写入的资源
2. **生命周期计算**: 资源在首次使用时创建，最后使用后释放
3. **别名 Alias**: 识别可重用的资源，避免不必要的分配

### 渲染优化

- **状态合并**: 相同渲染状态的 Pass 可合并
- **LOD 切换**: 根据距离自动切换细节级别
- **异步执行**: 支持并行执行独立的渲染 Pass

## 4. 本地部署

### 环境要求

- **Unity 版本**: 2021.3+ (URP 12+) 或 Unity 6
- **渲染管线**: URP (Universal Render Pipeline) 或 HDRP
- **平台**: 所有支持 URP 的平台

### 安装步骤

1. **安装 URP 包**
   ```
   Window > Package Manager > Unity Registry
   搜索 "Universal RP" > Install
   ```

2. **创建 Render Pipeline Asset**
   ```
   Project Settings > Graphics
   Assign URP Asset
   ```

3. **启用 RenderGraph (URP 14+)**
   ```csharp
   // 在 URP Settings 中
   Render Pipeline: Universal
   Renderer Type: Forward Plus (或 Custom)
   
   // 启用 RenderGraph API
   using UnityEngine.Rendering;
   GraphicsSettings.useScriptableRenderPipelineBatching = true;
   ```

## 5. 效果展示

### 代码示例

#### 基本 Pass

```csharp
public class MyRenderFeature : ScriptableRendererFeature
{
    public override void AddRenderPasses(ScriptableRenderer renderer)
    {
        var pass = new MyRenderPass();
        pass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        renderer.EnqueuePass(pass);
    }
    
    public class MyRenderPass : ScriptableRenderPass
    {
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // 配置渲染目标
            ConfigureTarget(colorAttachmentHandle);
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("MyPass");
            
            // 执行渲染
            CoreUtils.DrawFullscreen(cmd, myMaterial);
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
```

#### 使用 RenderGraph (Unity 6)

```csharp
// 在 ScriptableRenderContext 中使用
public struct RenderGraphData
{
    // 声明资源
    public TextureHandle colorBuffer;
    public TextureHandle depthBuffer;
}

void Render(RenderGraph renderGraph, in CameraData cameraData)
{
    // 创建资源
    var colorBuffer = renderGraph.CreateTexture(new TextureDesc2D
    {
        width = cameraData.camera.scaledPixelWidth,
        height = cameraData.camera.scaledPixelHeight,
        format = GraphicsFormat.B10G11R11_UFloatPack32,
        name = "SceneColor"
    });
    
    // 添加 Pass
    renderGraph.AddRenderPass("OpaquePass", (passData, context) =>
    {
        var cmd = context.cmd;
        cmd.SetRenderTarget(colorBuffer);
        // 渲染...
    });
    
    // 执行
    renderGraph.Execute(commandBuffer);
}
```

### 性能提升

| 指标 | 传统方式 | RenderGraph |
|------|----------|--------------|
| Draw Call 开销 | 高 | 低 |
| 资源管理复杂度 | 手动 | 自动 |
| 多线程支持 | 困难 | 原生支持 |
| 内存碎片 | 严重 | 通过别名优化 |

## 6. 优缺点分析

### 优点

- ✅ **自动化资源管理**: 消除资源泄漏，简化开发
- ✅ **性能优化**: 自动分析依赖，消除不必要的渲染操作
- ✅ **线程安全**: 为多核 CPU 提供更好的支持
- ✅ **调试工具**: Frame Debugger 集成，可视化渲染流程
- ✅ **代码解耦**: Pass 之间通过资源句柄通信，低耦合

### 缺点

- ⚠️ **学习曲线**: 需要理解 RenderGraph 的编程模型
- ⚠️ **兼容性**: 仅支持 URP/HDRP，旧版 Built-in Pipeline 不支持
- ⚠️ **灵活性受限**: 某些高级渲染技术可能受框架限制
- ⚠️ **调试复杂**: 自动化可能隐藏性能问题的根源

## 7. 平替对比

| 方案 | 特点 | 适用场景 |
|------|------|----------|
| **Unity RenderGraph** | URP/HDRP 内置，自动化管理 | URP/HDRP 项目 |
| **Built-in Render Pipeline** | 传统手动管理 | 简单项目/遗留代码 |
| **自定义渲染框架** | 完全控制 | 高级渲染/引擎定制 |
| **Compute Shader + GPU** | GPU 端处理 | 大规模并行计算 |

## 8. 落地过程

### 适用项目

- **URP 项目**: 使用 Universal Render Pipeline 的项目
- **Unity 6 项目**: 新建或迁移到 Unity 6 的项目
- **高性能需求**: 对渲染性能有较高要求的项目

### 迁移指南

1. **评估当前渲染管线**
   - 检查是否使用 URP 12+
   - 确认项目是否在支持列表中

2. **逐步迁移**
   - 先在新功能中使用 RenderGraph
   - 保持旧代码逐步改造

3. **性能测试**
   - 使用 Profiler 对比性能
   - 检查 Frame Debugger 中的渲染调用

### 常见问题

- **资源句柄失效**: 确保在 Pass 执行期间资源有效
- **循环依赖**: RenderGraph 不支持 Pass 间循环依赖
- **平台限制**: 某些平台可能不完全支持所有特性

---

## 补充信息

### 使用场景

- 游戏渲染管线开发
- 后处理效果实现
- 延迟渲染优化
- VR/AR 渲染优化

### 适合人群

- Unity 中高级开发者
- 渲染工程师
- 技术美术

### 成本评估

- **免费**: URP/HDRP 免费使用
- **许可**: Unity Pro/License (部分高级功能)

### 维护状态

- ✅ Unity 官方积极维护
- ✅ 每个 Unity 版本更新
- ✅ 社区活跃

### 社区资源

- Unity Forums
- Render Graph 官方文档
- GitHub Unity Graphics 仓库
