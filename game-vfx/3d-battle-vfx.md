# 3D 战斗场景表现技术调研报告

> 粒子系统/屏幕特效/动态光影的低美术依赖方案

## 1. 背景需求

3D 战斗场景的表现是动作游戏、ARPG、MOBA 等游戏的核心体验。传统方案依赖大量美术资源：

- 技能特效需要逐个制作粒子/动画
- 场景光照需要烘焙 lightmap
- 屏幕特效需要后处理素材
- 打击感需要逐帧动画配合

**核心痛点**：特效资源制作周期长、难以动态调整、内存占用大

## 2. 目标

- 通过程序化粒子系统减少特效制作成本
- 实现动态光影效果替代静态光照烘焙
- 屏幕特效通过着色器实时计算
- 提供可配置、响应式的打击反馈系统
- 保持高性能表现

## 3. 设计方案

### 3.1 程序化粒子系统

#### 3.1.1 粒子系统架构

```cpp
// 核心粒子系统架构（C++ 示例）
struct Particle {
    vec3 position;
    vec3 velocity;
    vec3 acceleration;
    vec4 color;
    float life;        // 剩余生命 0.0~1.0
    float maxLife;     // 最大寿命
    float size;
    float rotation;
    vec2 uv;           // 纹理坐标
};

class ParticleSystem {
private:
    std::vector<Particle> particles;
    ParticleEmitter* emitter;
    ParticleRenderer* renderer;
    
public:
    void emit(const EmitConfig& config, int count);
    void update(float deltaTime);
    void render(RenderContext& ctx);
};
```

#### 3.1.2 技能特效生成器

```python
# Python 配置驱动的特效生成器
class SkillEffectConfig:
    def __init__(self):
        # 发射器配置
        self.emitter_type = "cone"  # cone/circle/point/box
        self.emit_rate = 100        # 每秒发射数
        self.initial_velocity = (0, 10, 0)
        self.velocity_spread = 2.0
        
        # 粒子外观
        self.start_color = (1, 0.5, 0, 1)      # 橙金色
        self.end_color = (1, 0, 0, 0)          # 渐变到透明
        self.start_size = 0.5
        self.end_size = 0.1
        self.texture = "particle_fire"
        
        # 物理参数
        self.gravity = -9.8
        self.drag = 0.1
        self.lifetime = 2.0
        
        # 渲染参数
        self.blend_mode = "add"     # add/alpha/multiply
        self.billboard = True

# 预设特效库
PRESET_EFFECTS = {
    "fire_ball": SkillEffectConfig(
        emitter_type="sphere",
        emit_rate=50,
        initial_velocity=(0, 5, 10),
        start_color=(1, 0.6, 0.1, 1),
        end_color=(0.8, 0.2, 0, 0),
    ),
    "ice_blast": SkillEffectConfig(
        emitter_type="cone",
        emit_rate=200,
        start_color=(0.5, 0.8, 1, 1),
        end_color=(0.8, 0.9, 1, 0),
    ),
    "lightning": SkillEffectConfig(
        emitter_type="line",  # 闪电用线段
        emit_rate=1,
        start_color=(0.9, 0.9, 1, 1),
    ),
    "smoke": SkillEffectConfig(
        emitter_type="sphere",
        emit_rate=30,
        start_color=(0.3, 0.3, 0.3, 0.5),
        end_color=(0.1, 0.1, 0.1, 0),
    ),
}
```

#### 3.1.3 GPU 粒子系统

```glsl
// GPU 粒子更新着色器
#version 450

struct Particle {
    vec3 position;
    vec3 velocity;
    vec4 color;
    float life;
    float size;
};

layout(std430, binding = 0) buffer Particles {
    Particle particles[];
};

uniform float deltaTime;
uniform float time;

// 简单物理更新
void main() {
    int id = gl_GlobalInvocationID.x;
    Particle p = particles[id];
    
    if (p.life <= 0.0) return; // 死亡粒子
    
    // 物理更新
    p.velocity.y -= 9.8 * deltaTime;  // 重力
    p.velocity *= (1.0 - 0.1 * deltaTime);  // 阻力
    p.position += p.velocity * deltaTime;
    
    // 生命衰减
    p.life -= deltaTime * 0.5;
    
    // 颜色随生命变化
    p.color.a = smoothstep(0.0, 0.2, p.life);
    
    particles[id] = p;
}
```

### 3.2 屏幕特效（Post-Processing）

#### 3.2.1 打击感屏幕特效

```glsl
// 屏幕震动效果
uniform float shakeIntensity;
uniform float shakeFrequency;
uniform vec2 shakeDirection;

vec2 screenShake(vec2 uv, float time) {
    float shakeX = sin(time * shakeFrequency) * shakeIntensity;
    float shakeY = cos(time * shakeFrequency * 1.3) * shakeIntensity;
    return uv + vec2(shakeX, shakeY) * shakeDirection;
}

// 打击闪光
uniform float hitFlashIntensity;
uniform vec3 hitFlashColor;

vec3 applyHitFlash(vec3 color, vec2 uv) {
    // 屏幕中心高亮
    float centerDist = length(uv - 0.5);
    float flash = (1.0 - smoothstep(0.0, 0.5, centerDist)) * hitFlashIntensity;
    return color + hitFlashColor * flash;
}

// 慢动作效果（子弹时间）
uniform float slowMotionFactor;  // 0.0=正常, 0.1=10x慢

// 色差/RGB分离
uniform float chromaticAberration;

vec3 chromaticAberration(vec2 uv) {
    vec2 dir = uv - 0.5;
    float dist = length(dir);
    vec2 offset = dir * dist * chromaticAberration;
    
    float r = texture(texColor, uv + offset).r;
    float g = texture(texColor, uv).g;
    float b = texture(texColor, uv - offset).b;
    
    return vec3(r, g, b);
}
```

#### 3.2.2 技能特效屏幕效果

```glsl
// 冰冻效果 - 屏幕蓝化 + 雪花
uniform float freezeAmount;
uniform float time;

vec3 applyFreeze(vec3 color, vec2 uv) {
    // 蓝化
    vec3 freezeTint = vec3(0.7, 0.85, 1.0);
    color = mix(color, color * freezeTint, freezeAmount);
    
    // 雪花叠加
    float snow = fract(sin(dot(uv * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
    snow = step(0.997, snow) * freezeAmount * 0.3;
    color += vec3(snow);
    
    return color;
}

// 燃烧效果 - 屏幕红化 + 暗角
uniform float burnAmount;

vec3 applyBurn(vec3 color, vec2 uv) {
    // 红化
    vec3 burnTint = vec3(1.0, 0.6, 0.3);
    color = mix(color, color * burnTint, burnAmount);
    
    // 暗角增强
    float vignette = 1.0 - length(uv - 0.5) * 1.2;
    vignette = smoothstep(0.0, 1.0, vignette);
    color *= mix(1.0, vignette, burnAmount * 0.5);
    
    return color;
}

// 闪电期间屏幕效果
uniform float lightningFlash;

vec3 applyLightning(vec3 color, vec2 uv) {
    float flash = lightningFlash * (1.0 - length(uv - 0.5) * 1.5);
    flash = max(0.0, flash);
    return color + vec3(flash);
}
```

#### 3.2.3 统一后处理管线

```glsl
// 主后处理着色器 - 效果叠加
uniform sampler2D uSceneTexture;
uniform sampler2D uDepthTexture;

struct EffectParams {
    float shakeIntensity;
    float hitFlashIntensity;
    float freezeAmount;
    float burnAmount;
    float slowMotion;
    float chromatic;
    vec3 hitFlashColor;
};

uniform EffectParams effects;
uniform float time;
uniform vec2 resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    
    // 屏幕震动
    uv = screenShake(uv, time);
    
    // 采样场景
    vec3 color = texture(uSceneTexture, uv).rgb;
    
    // 效果叠加
    color = applyHitFlash(color, uv);
    color = applyFreeze(color, uv);
    color = applyBurn(color, uv);
    
    // 色差
    if (effects.chromatic > 0.0) {
        color = chromaticAberration(uv);
    }
    
    // 伽马校正
    color = pow(color, vec3(1.0/2.2));
    
    gl_FragColor = vec4(color, 1.0);
}
```

### 3.3 动态光影系统

#### 3.3.1 实时动态光照

```python
# 动态光源系统
class DynamicLight:
    def __init__(self, light_type="point"):
        self.type = light_type  # point/spot/directional
        self.position = (0, 0, 0)
        self.color = (1, 1, 1)
        self.intensity = 1.0
        self.range = 10.0
        self.attenuation = 2.0  # 衰减指数
        
        # 动态效果
        self.flicker_enabled = False
        self.pulse_enabled = False
        
    def update(self, delta_time):
        if self.flicker_enabled:
            # 随机闪烁效果
            import random
            self.intensity = self.base_intensity * (0.8 + random.random() * 0.4)
            
        if self.pulse_enabled:
            # 脉冲效果
            import math
            self.intensity = self.base_intensity * (0.5 + 0.5 * math.sin(time.time() * 2))

class LightSystem:
    def __init__(self):
        self.lights = []
        self.max_lights = 16  # 性能限制
        
    def add_light(self, light):
        if len(self.lights) < self.max_lights:
            self.lights.append(light)
            
    def get_lights_in_radius(self, position, radius):
        return [l for l in self.lights 
                if distance(l.position, position) < radius]
```

#### 3.3.2 技能光源系统

```python
# 技能关联光源
class SkillLight:
    """绑定到技能的光源效果"""
    
    def __init__(self, skill_effect):
        self.light = DynamicLight("point")
        self.skill_effect = skill_effect
        
        # 光源跟随技能
        self.follow_target = True
        
    def on_skill_cast(self):
        """施放技能时触发"""
        # 初始爆发
        self.light.intensity = 3.0
        self.light.color = self.skill_effect.primary_color
        
    def on_skill_hit(self, target):
        """命中目标时触发"""
        # 命中闪光
        self.light.intensity = 5.0
        self.light.flicker_enabled = True
        self.light.base_intensity = 1.0
        
    def update(self, target_position, delta_time):
        if self.follow_target:
            self.light.position = target_position
            
        self.light.update(delta_time)
```

#### 3.3.3 动态阴影

```glsl
// 实时阴影计算（简化版）
float calculateShadow(vec3 fragPos, vec3 lightPos) {
    vec3 lightDir = normalize(lightPos - fragPos);
    
    // 简单的 PCF 软阴影
    float shadow = 0.0;
    float bias = 0.005;
    
    for (int i = 0; i < 4; i++) {
        vec2 offset = poissonDisk[i] / shadowMapSize;
        float depth = texture(shadowMap, projCoords.xy + offset).r;
        shadow += currentDepth - bias > depth ? 0.0 : 1.0;
    }
    
    return shadow / 4.0;
}

// 动态光照着色器
vec3 applyDynamicLight(vec3 baseColor, vec3 normal, vec3 fragPos) {
    vec3 result = vec3(0.0);
    
    for (int i = 0; i < numLights; i++) {
        vec3 lightDir = normalize(lights[i].position - fragPos);
        float dist = length(lights[i].position - fragPos);
        float attenuation = 1.0 / (1.0 + 0.09*dist + 0.032*dist*dist);
        
        // 漫反射
        float diff = max(dot(normal, lightDir), 0.0);
        
        // 阴影
        float shadow = calculateShadow(fragPos, lights[i].position);
        
        result += (diff * lights[i].color * attenuation * shadow);
    }
    
    return baseColor * result;
}
```

### 3.4 打击反馈系统

#### 3.4.1 打击感配置

```python
# 打击感参数配置
class HitReactionConfig:
    def __init__(self):
        # 屏幕震动
        self.screen_shake_intensity = 0.5
        self.screen_shake_duration = 0.1
        self.screen_shake_frequency = 30
        
        # 屏幕闪光
        self.hit_flash_color = (1, 1, 1)
        self.hit_flash_intensity = 0.3
        self.hit_flash_duration = 0.05
        
        # 音效
        self.hit_sound = "hit_default"
        self.crit_sound = "hit_crit"
        
        # 动画
        self.hit_stop = 0.05  # 打击停顿（帧冻结）
        self.camera_bloom = 0.2
        
        # 粒子
        self.hit_particles = "spark"
        self.crit_particles = "blood_explosion"
        
# 武器类型对应的打击配置
WEAPON_HIT_CONFIGS = {
    "sword": HitReactionConfig(
        screen_shake_intensity=0.3,
        hit_flash_color=(1, 0.9, 0.8),
        hit_particles="metal_spark"
    ),
    "hammer": HitReactionConfig(
        screen_shake_intensity=0.8,
        screen_shake_duration=0.2,
        hit_flash_intensity=0.5,
        hit_particles="debris"
    ),
    "magic": HitReactionConfig(
        screen_shake_intensity=0.2,
        hit_flash_color=(0.5, 0.8, 1),
        hit_particles="magic_explosion",
        camera_bloom=0.5
    ),
}
```

#### 3.4.2 打击感系统集成

```python
class HitReactionSystem:
    def __init__(self):
        self.screen_shake = ScreenShake()
        self.post_process = PostProcessSystem()
        self.particle_system = ParticleSystem()
        self.audio = AudioSystem()
        
    def on_hit(self, hit_info):
        config = WEAPON_HIT_CONFIGS[hit_info.weapon_type]
        
        # 计算暴击倍数
        crit_multiplier = 2.0 if hit_info.is_crit else 1.0
        
        # 1. 屏幕震动
        self.screen_shake.trigger(
            intensity=config.screen_shake_intensity * crit_multiplier,
            duration=config.screen_shake_duration
        )
        
        # 2. 屏幕闪光
        flash_color = config.hit_flash_color
        if hit_info.is_crit:
            flash_color = (1, 0.8, 0.3)  # 暴击金色
            
        self.post_process.trigger_flash(
            color=flash_color,
            intensity=config.hit_flash_intensity * crit_multiplier,
            duration=config.hit_flash_duration
        )
        
        # 3. 打击停顿（hit stop）
        if hit_info.is_crit:
            self.time_scale.set_scale(0.3, 0.1)  # 慢动作
            
        # 4. 粒子效果
        particle_type = config.hit_particles
        if hit_info.is_crit:
            particle_type = config.crit_particles
            
        self.particle_system.emit_at(
            particle_type,
            hit_info.hit_position,
            count=10 * int(crit_multiplier)
        )
        
        # 5. 音效
        sound = config.crit_sound if hit_info.is_crit else config.hit_sound
        self.audio.play(sound, position=hit_info.hit_position)
        
        # 6. 相机 Bloom
        self.post_process.set_bloom(config.camera_bloom * crit_multiplier)
```

### 3.5 屏幕空间特效

#### 3.5.1 Bloom 效果

```glsl
// 简化 Bloom 效果
uniform sampler2D uScene;
uniform float threshold;  // 亮度阈值
uniform float intensity;  // 强度

vec3 extractBright(vec3 color) {
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return brightness > threshold ? color : vec3(0.0);
}

vec3 blur(sampler2D tex, vec2 uv, vec2 direction) {
    vec3 result = vec3(0.0);
    float weights[5] = float[](0.227, 0.194, 0.121, 0.054, 0.016);
    
    for (int i = -2; i <= 2; i++) {
        vec2 offset = direction * float(i) * 2.0;
        result += texture(tex, uv + offset).rgb * weights[i + 2];
    }
    return result;
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    
    // 提取高光
    vec3 bright = extractBright(texture(uScene, uv).rgb);
    
    // 模糊
    vec3 bloom = blur(uScene, uv, vec2(1, 0)) + 
                 blur(uScene, uv, vec2(0, 1));
    
    // 叠加
    vec3 color = texture(uScene, uv).rgb;
    color += bloom * intensity;
    
    gl_FragColor = vec4(color, 1.0);
}
```

#### 3.5.2 径向模糊（技能特效）

```glsl
// 技能释放时的径向模糊
uniform float radialBlurStrength;
uniform vec2 radialBlurCenter;

vec3 radialBlur(sampler2D tex, vec2 uv) {
    vec3 color = vec3(0.0);
    float total = 0.0;
    vec2 dir = uv - radialBlurCenter;
    float dist = length(dir);
    
    for (int i = 0; i < 8; i++) {
        float scale = 1.0 - radialBlurStrength * float(i) / 8.0;
        vec2 sampleUV = radialBlurCenter + dir * scale;
        float weight = 1.0 - float(i) / 8.0;
        
        color += texture(tex, sampleUV).rgb * weight;
        total += weight;
    }
    
    return color / total;
}
```

## 4. 本地部署

### 4.1 Unity 实现方案

**核心组件**：
- Unity Particle System（VFX Graph）
- Universal Render Pipeline (URP)
- Shader Graph
- Post Processing Stack v2

**项目结构**：
```
Assets/
├── VFX/
│   ├── Particles/
│   │   ├── Fire/
│   │   ├── Ice/
│   │   ├── Lightning/
│   │   └── Impact/
│   ├── Shaders/
│   │   ├── ScreenShake.shader
│   │   ├── HitFlash.shader
│   │   └── RadialBlur.shader
│   └── Scripts/
│       ├── ParticleSystemManager.cs
│       ├── HitReactionSystem.cs
│       ├── DynamicLightSystem.cs
│       └── PostProcessController.cs
├── Presets/
│   ├── WeaponHitConfigs/
│   └── SkillEffectConfigs/
└── Resources/
    └── Textures/
```

### 4.2 Unreal Engine 实现方案

**核心组件**：
- Niagara 粒子系统
- Niagara Fluids
- Post Process Volume
- Volumetric Fog

**Niagara 系统示例**：
- 模块化粒子效果蓝图
- GPU 加速粒子计算
- Sprite/ribbon/mesh 粒子类型

### 4.3 Godot 4.x 实现方案

**着色器语法转换**：
```glsl
# Godot 后处理效果
shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float shake_intensity = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // 屏幕震动
    if (shake_intensity > 0.0) {
        uv.x += sin(TIME * 50.0) * shake_intensity * 0.01;
        uv.y += cos(TIME * 40.0) * shake_intensity * 0.01;
    }
    
    vec3 color = texture(screen_texture, uv).rgb;
    ALBEDO = color;
}
```

### 4.4 轻量级方案（无引擎）

**技术栈**：Python + ModernGL / PyOpenGL

```python
# 简单粒子系统示例
import moderngl
import numpy as np

class SimpleParticleSystem:
    def __init__(self, ctx):
        self.ctx = ctx
        # 粒子数据：位置(xyz) + 速度(xyz) + 生命周期
        self.particle_data = np.zeros(1000, dtype='f4')
        
    def update(self, dt):
        # 更新粒子位置
        # 应用重力、阻力
        # 减少生命周期
        pass
        
    def render(self):
        # 渲染点精灵
        pass
```

## 5. 效果展示

### 5.1 技术效果对比

| 效果类型 | 传统美术方案 | 程序化方案 | 效果提升 |
|---------|------------|-----------|---------|
| 技能特效 | 逐个制作动画 | 参数配置生成 | 可调整/复用 |
| 打击感 | 预设震动动画 | 实时计算 | 响应式反馈 |
| 动态光照 | 烘焙 lightmap | 实时计算 | 动态变化 |
| 屏幕特效 | 视频素材 | 着色器计算 | 资源节省 |
| 粒子数量 | 100-500 | 10000+ | 20x+ |

### 5.2 实际游戏案例

**案例 1**： Devil May Cry 5（打击感标杆）
- 程序化屏幕震动
- 即时打击停顿（hit stop）
- 动态特写镜头

**案例 2**： Hades（roguelike 动作游戏）
- Niagara 粒子系统
- 动态光源跟随技能
- 屏幕特效与叙事结合

**案例 3**： Genshin Impact（开放世界动作）
- GPU 粒子系统
- 元素反应屏幕效果
- 动态光影系统

## 6. 优缺点分析

### 6.1 优点

✅ **资源成本大幅降低**：无需逐个制作特效动画
✅ **动态响应**：可根据战斗情况实时调整
✅ **高度可配置**：参数化设计易于调整
✅ **运行时变化**：同一技能可产生不同变体
✅ **内存效率高**：程序化生成替代静态资源
✅ **更好打击感**：实时计算实现精确反馈

### 6.2 缺点

⚠️ **图形学门槛**：需要着色器编写能力
⚠️ **调试复杂**：特效问题难以快速定位
⚠️ **美术风格难统一**：程序化结果可能不一致
⚠️ **性能敏感**：过多粒子/光源影响性能
⚠️ **难以精确控制**：无法达到手绘的精细度

### 6.3 风险与挑战

| 风险 | 缓解方案 |
|-----|---------|
| 效果单调 | 建立丰富的预设库 |
| 性能问题 | 使用 GPU 粒子 + 对象池 |
| 风格不统一 | 制定美术规范 + 参数模板 |
| 调试困难 | 开发特效预览工具 |

## 7. 平替对比

### 7.1 方案对比矩阵

| 方案 | 美术依赖 | 灵活性 | 性能 | 适用场景 |
|-----|---------|-------|------|---------|
| 手绘特效 | 高 | 低 | 高 | 精确表现 |
| 骨骼动画 | 高 | 中 | 中 | 角色特效 |
| 粒子系统 | 中 | 高 | 中 | 技能特效 |
| 程序化特效 | 低 | 极高 | 可控 | 大量重复特效 |
| 视频素材 | 极高 | 极低 | 低 | 过场动画 |

### 7.2 推荐技术栈

**动作游戏/ARPG**：
```
首选：Unity URP + VFX Graph + Shader Graph
备选：Unreal Niagara + Blueprint
轻量：Godot 4 + GPU Particles
```

**MOBA/竞技游戏**：
```
重点：性能优化 + 打击感系统
方案：GPU 实例化 + 对象池
```

## 8. 落地过程

### 8.1 实施路线图

**阶段 1：基础粒子系统（2 周）**
- [ ] 核心粒子系统架构
- [ ] 基础发射器实现
- [ ] 粒子渲染管线

**阶段 2：特效预设库（3 周）**
- [ ] 元素特效（火/水/冰/雷）
- [ ] 物理特效（打击/碎片/烟尘）
- [ ] 武器特效（剑/弓/法杖）

**阶段 3：屏幕特效系统（2 周）**
- [ ] 后处理管线
- [ ] 屏幕震动/闪光
- [ ] Bloom/色差效果

**阶段 4：打击感系统（2 周）**
- [ ] 打击反馈配置
- [ ] 打击感系统集成
- [ ] 武器类型差异化

**阶段 5：动态光影（2 周）**
- [ ] 动态光源系统
- [ ] 技能关联光源
- [ ] 实时阴影

**阶段 6：优化整合（2 周）**
- [ ] 性能优化
- [ ] 工具链完善
- [ ] 完整 Demo

### 8.2 关键里程碑

| 周次 | 里程碑 | 验收标准 |
|-----|-------|---------|
| W2 | 粒子系统可运行 | 能发射和渲染基础粒子 |
| W5 | 特效库基本完成 | 常见技能特效可用 |
| W7 | 屏幕特效完成 | 打击感反馈正常 |
| W9 | 动态光影完成 | 战斗场景光影丰富 |
| W11 | 完整 Demo | 可玩的战斗原型 |

### 8.3 资源预估

| 资源 | 数量 | 说明 |
|-----|-----|-----|
| 粒子纹理 | 10-20 张 | 程序化/基础纹理 |
| 着色器 | 15-20 个 | 粒子/后处理/光照 |
| 脚本 | 10-15 个 | 系统核心代码 |
| 特效预设 | 30-50 个 | 技能/打击/环境 |
| 总开发时间 | 11-13 周 | 熟练开发者 |

### 8.4 技术扩展方向

1. **VFX Graph 进阶**：复杂粒子行为
2. **计算着色器**：GPU 粒子计算
3. **实例化渲染**：大量小物体
4. **LOD 系统**：多层次细节
5. **AI 生成**：辅助特效设计

---

**调研完成**：2026-03-14
**技术方向**：游戏表现 / 粒子系统 / 屏幕特效 / 动态光影
