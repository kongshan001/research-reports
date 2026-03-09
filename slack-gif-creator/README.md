# Slack GIF Creator 技能调研报告

## 1. 背景需求

在 Slack 中使用 GIF 动画可以大大提升团队沟通的趣味性和表达力。但要创建适合 Slack 的 GIF 有一些特定的技术要求：
- 文件大小限制
- 尺寸规格要求
- 帧率和色彩数量优化

手动创建符合这些要求的 GIF 往往需要反复调整，效率较低。

## 2. 目标

- 提供 Slack 优化的 GIF 创建工具集
- 自动化处理尺寸、帧率、色彩等参数
- 简化从零创建或动画化现有图像的流程

## 3. 设计方案

### 核心架构

```
用户请求 → Slack GIF Creator 技能
       │
       ├── GIFBuilder - GIF 构建器
       ├── Validators - 验证工具
       ├── Easing Functions - 缓动函数
       └── Frame Composer - 帧合成器
              │
              ▼
          PIL 图像处理 → 输出优化后的 GIF
```

### 核心组件

| 组件 | 功能 |
|------|------|
| GIFBuilder | 组装帧并优化 Slack 兼容性 |
| Validators | 检查 GIF 是否符合 Slack 要求 |
| Easing Functions | 平滑动画过渡效果 |
| Frame Composer | 便捷的帧创建函数 |

### Slack 规格要求

**尺寸：**
- Emoji GIF: 128x128 (推荐)
- Message GIF: 480x480

**参数：**
- FPS: 10-30 (越低文件越小)
- 色彩数: 48-128 (越少文件越小)
- 时长: Emoji GIF 建议 3 秒以内

## 4. 本地部署

### 环境要求

```bash
pip install pillow imageio numpy
```

### 安装技能

```bash
# 添加 Anthropic skills 市场
/plugin marketplace add anthropics/skills

# 安装 example-skills
/plugin install example-skills@anthropic-agent-skills
```

### 验证安装

安装后可直接使用：
```
"用 Slack GIF 技能创建一个跳舞的猫咪 GIF"
```

## 5. 效果展示

### 基本使用示例

```python
from core.gif_builder import GIFBuilder
from PIL import Image, ImageDraw

# 1. 创建构建器
builder = GIFBuilder(width=128, height=128, fps=10)

# 2. 生成帧
for i in range(12):
    frame = Image.new('RGB', (128, 128), (240, 248, 255))
    draw = ImageDraw.Draw(frame)
    
    # 绘制动画元素
    draw.ellipse([50, 50, 80, 80], fill=(255, 100, 100))
    
    builder.add_frame(frame)

# 3. 保存并优化
builder.save('output.gif', num_colors=48, optimize_for_emoji=True)
```

### 验证 GIF

```python
from core.validators import validate_gif, is_slack_ready

# 详细验证
passes, info = validate_gif('my.gif', is_emoji=True, verbose=True)

# 快速检查
if is_slack_ready('my.gif'):
    print("Ready for Slack!")
```

### 动画概念

| 动画类型 | 实现方式 |
|----------|----------|
| Shake/Vibrate | 使用 sin/cos 震荡偏移位置 |
| Pulse/Heartbeat | 正弦波缩放 (0.8-1.2) |
| Bounce | bounce_out 缓动函数 |
| Spin/Rotate | PIL rotate 方法 |
| Fade In/Out | 调整 alpha 通道 |
| Slide | 从帧外滑入 + ease_out |
| Zoom | 缩放 + 裁剪中心 |
| Explode | 粒子系统向外扩散 |

### 优化策略

```python
# 最大程度优化 emoji
builder.save(
    'emoji.gif',
    num_colors=48,
    optimize_for_emoji=True,
    remove_duplicates=True
)
```

优化方法：
1. 减少帧数 - 降低 FPS
2. 减少色彩 - 48 色而非 128 色
3. 减小尺寸 - 128x128 而非 480x480
4. 去除重复帧
5. 启用 Emoji 模式自动优化

## 6. 优缺点分析

### 优点

- ✅ **Slack 优化**: 内置 Slack 规格要求，自动优化
- ✅ **代码驱动**: 灵活创建任意动画
- ✅ **实用工具集**: 验证器、缓动函数、帧合成器
- ✅ **动画概念丰富**: 9+ 种动画类型
- ✅ **PIL 基础**: 依赖成熟稳定的 Pillow 库

### 缺点

- ⚠️ **无预制图形**: 不包含 emoji 字体或预制图形
- ⚠️ **需要代码**: 需要编写 Python 代码创建动画
- ⚠️ **无模板**: 需要从零设计和实现动画
- ⚠️ **纯代码方式**: 不适合非程序员

## 7. 平替对比

| 方案 | 特点 | 适用场景 |
|------|------|----------|
| **Slack GIF Creator** | 代码驱动创建 | 程序员/自动化工作流 |
| **Ezgif** | 在线 GIF 工具 | 快速简单编辑 |
| **GIPHY** | GIF 搜索引擎 | 搜索现成 GIF |
| **Photoshop/FFmpeg** | 专业视频转 GIF | 高质量需求 |
| **ScreenToGif** | 屏幕录制转 GIF | 录制操作演示 |

## 8. 落地过程

### 适用场景

- 创建 Slack emoji 反应 GIF
- 自动化批量生成 GIF
- 将静态图像动画化
- 创建产品演示动画

### 使用建议

1. **确定用途**: Emoji (128x128) 还是 Message (480x480)
2. **设计动画**: 选择合适的动画概念
3. **编写代码**: 使用 GIFBuilder 创建
4. **验证优化**: 使用 Validators 检查
5. **调整参数**: 根据文件大小优化

---

## 补充信息

### 来源

- **仓库**: anthropics/skills
- **路径**: skills/slack-gif-creator
- **许可证**: Apache 2.0

### 安装命令

```bash
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
```

### 依赖

- pillow
- imageio
- numpy
