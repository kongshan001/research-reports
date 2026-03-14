# 游戏表现技术调研报告

> 调研方向：2D地图场景表现技术 + 3D战斗场景表现技术
> 目标：减少美术依赖，通过程序化手段提升游戏表现效果

---

## 一、2D地图场景表现技术

### 1.1 程序化地形生成

#### 背景需求

传统2D游戏地图依赖手绘背景图，存在以下问题：
- 美术资源量大，内存占用高
- 场景单一，缺乏变化
- 每次更新需要美术重新绘制
- 难以实现动态天气和季节变化

#### 目标

通过程序化生成技术，用算法生成丰富多变的2D地图场景，减少美术工作量的同时提升场景表现力。

#### 技术方案

**噪声函数生成**

使用Perlin Noise、Simplex Noise等噪声算法生成地形高度图：

```python
import numpy as np

class TerrainGenerator:
    def __init__(self, seed=None):
        self.seed = seed or np.random.randint(0, 10000)
        np.random.seed(self.seed)
    
    def generate_heightmap(self, width, height, scale=0.1, octaves=4):
        """生成多层噪声高度图"""
        heightmap = np.zeros((height, width))
        
        for i in range(octaves):
            frequency = scale * (2 ** i)
            amplitude = 1 / (2 ** i)
            
            # 生成噪声
            noise = self._perlin_2d(width, height, frequency)
            heightmap += noise * amplitude
        
        # 归一化到0-1
        heightmap = (heightmap - heightmap.min()) / (heightmap.max() - heightmap.min())
        return heightmap
    
    def _perlin_2d(self, width, height, scale):
        """简化Perlin噪声实现"""
        # 使用随机梯度生成
        x = np.linspace(0, scale, width)
        y = np.linspace(0, scale, height)
        xv, yv = np.meshgrid(x, y)
        
        # 简化的噪声函数
        noise = np.sin(xv * 2 * np.pi) * np.cos(yv * 2 * np.pi)
        noise += 0.5 * np.sin(xv * 4 * np.pi + 1) * np.cos(yv * 4 * np.pi + 2)
        
        return noise
```

**基于高度图的纹理混合**

```glsl
// Unity Shader: 基于高度的纹理混合
Shader "Custom/TerrainBlend" {
    Properties {
        _MainTex1 ("Ground Texture", 2D) = "white" {}
        _MainTex2 ("Grass Texture", 2D) = "white" {}
        _MainTex3 ("Rock Texture", 2D) = "white" {}
        _SandThreshold ("Sand Height", Range(0,1)) = 0.3
        _GrassThreshold ("Grass Height", Range(0,1)) = 0.6
    }
    
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            sampler2D _MainTex1;
            sampler2D _MainTex2;
            sampler2D _MainTex3;
            float _SandThreshold;
            float _GrassThreshold;
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float height : TEXCOORD1;
            };
            
            v2f vert(appdata_full v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                o.height = v.vertex.y; // 使用顶点高度
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                fixed4 col1 = tex2D(_MainTex1, i.uv);
                fixed4 col2 = tex2D(_MainTex2, i.uv);
                fixed4 col3 = tex2D(_MainTex3, i.uv);
                
                // 基于高度的纹理混合
                fixed4 result;
                if (i.height < _SandThreshold) {
                    result = col1;
                } else if (i.height < _GrassThreshold) {
                    float t = (i.height - _SandThreshold) / (_GrassThreshold - _SandThreshold);
                    result = lerp(col1, col2, t);
                } else {
                    float t = (i.height - _GrassThreshold) / (1.0 - _GrassThreshold);
                    result = lerp(col2, col3, t);
                }
                
                return result;
            }
            ENDCG
        }
    }
}
```

#### 本地部署

```bash
# 安装依赖
pip install numpy opencv-python pillow

# 运行地形生成示例
python terrain_generator.py --width 512 --height 512 --output terrain.png
```

#### 效果展示

| 场景类型 | 效果描述 |
|---------|---------|
| 地形起伏 | 自动生成山脉、平原、河流 |
| 纹理混合 | 基于高度的自动纹理过渡 |
| 动态变化 | 支持运行时重新生成 |

#### 优缺点分析

**优点：**
- 零美术依赖，程序完全可控
- 无限地形变化，避免重复
- 支持实时天气和季节系统

**缺点：**
- 需要调整参数达到美观效果
- 复杂地形可能导致视觉单调

#### 平替对比

| 方案 | 美术依赖 | 内存占用 | 变化性 |
|-----|---------|---------|-------|
| 手绘背景 | 高 | 高 | 低 |
| 瓦片地图 | 中 | 中 | 中 |
| 程序化生成 | 极低 | 低 | 高 |

---

### 1.2 着色器动态效果

#### 背景需求

2D游戏需要通过动态效果提升画面表现力，如：水面波纹、光照变化、天气效果等。

#### 目标

使用着色器（Shader）在2D画面中实现类似3D的动态光影效果。

#### 技术方案

**动态水面效果**

```glsl
// 2D水面波纹着色器
Shader "Custom/WaterRipple" {
    Properties {
        _MainTex ("Base Texture", 2D) = "white" {}
        _WaterColor ("Water Color", Color) = (0, 0.5, 0.8, 0.5)
        _RippleSpeed ("Ripple Speed", Range(0, 5)) = 1.0
        _RippleScale ("Ripple Scale", Range(0.1, 10)) = 5.0
        _RippleStrength ("Ripple Strength", Range(0, 0.1)) = 0.02
        _TimeScale ("Time Scale", Range(0.1, 3)) = 1.0
    }
    
    SubShader {
        Tags {"Queue"="Transparent" "RenderType"="Transparent"}
        
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _WaterColor;
            float _RippleSpeed;
            float _RippleScale;
            float _RippleStrength;
            float _TimeScale;
            
            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 worldUV : TEXCOORD1;
            };
            
            // 多层正弦波叠加
            float2 ripple_offset(float2 uv, float time) {
                float wave1 = sin(uv.x * _RippleScale + time * _RippleSpeed) * _RippleStrength;
                float wave2 = sin(uv.y * _RippleScale * 1.3 + time * _RippleSpeed * 1.2) * _RippleStrength;
                float wave3 = sin((uv.x + uv.y) * _RippleScale * 0.7 + time * _RippleSpeed * 0.8) * _RippleStrength;
                
                return float2(wave1 + wave3, wave2 + wave3);
            }
            
            v2f vert(appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldUV = v.uv;
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                float time = _Time.y * _TimeScale;
                
                // 计算波纹偏移
                float2 offset = ripple_offset(i.worldUV, time);
                
                // 采样基础纹理
                fixed4 baseCol = tex2D(_MainTex, i.uv + offset);
                
                // 添加高光效果
                float highlight = sin((i.worldUV.x + i.worldUV.y) * _RippleScale * 2 + time * 2) * 0.5 + 0.5;
                highlight = pow(highlight, 8) * 0.3;
                
                // 混合颜色
                fixed4 col = baseCol * (1 - _WaterColor.a) + _WaterColor * _WaterColor.a;
                col.rgb += highlight;
                
                return col;
            }
            ENDCG
        }
    }
}
```

**动态光影效果**

```python
class DynamicLighting2D:
    """2D动态光照系统"""
    
    def __init__(self):
        self.lights = []
        self.ambient_color = (0.2, 0.2, 0.3)
    
    def add_light(self, x, y, radius, color, intensity):
        self.lights.append({
            'x': x, 'y': y,
            'radius': radius,
            'color': color,
            'intensity': intensity
        })
    
    def calculate_lighting(self, pixel_x, pixel_y):
        """计算像素点的光照"""
        r, g, b = self.ambient_color
        
        for light in self.lights:
            dx = pixel_x - light['x']
            dy = pixel_y - light['y']
            distance = (dx * dx + dy * dy) ** 0.5
            
            if distance < light['radius']:
                # 光照衰减
                falloff = 1 - (distance / light['radius'])
                falloff = falloff ** 2  # 平方衰减
                
                r += light['color'][0] * light['intensity'] * falloff
                g += light['color'][1] * light['intensity'] * falloff
                b += light['color'][2] * light['intensity'] * falloff
        
        return (min(1, r), min(1, g), min(1, b))
```

#### 本地部署

```bash
# Unity项目
# 1. 创建新Shader文件
# 2. 创建Material并应用Shader
# 3. 在场景中添加到Sprite Renderer

# 独立引擎
pip install pygame moderngl
```

#### 效果展示

| 效果类型 | 描述 |
|---------|------|
| 水面波纹 | 多层正弦波叠加，可调速度/强度 |
| 动态光照 | 点光源/方向光，支持颜色渐变 |
| 雾气效果 | 基于深度的雾化渲染 |

#### 优缺点分析

**优点：**
- GPU加速，性能优秀
- 效果细腻，可参数化调整
- 美术只需提供基础纹理

**缺点：**
- 需要编写Shader代码
- 部分效果需要高端GPU

---

### 1.3 动态天气系统

#### 背景需求

2D游戏需要动态天气效果增加场景沉浸感，但传统做法依赖序列帧动画，资源消耗大。

#### 目标

通过粒子系统和着色器实现程序化天气效果。

#### 技术方案

```python
class WeatherSystem:
    """2D动态天气系统"""
    
    def __init__(self):
        self.current_weather = "none"
        self.particles = []
        self.intensity = 0.0
    
    def set_weather(self, weather_type, intensity=1.0):
        """设置天气类型和强度"""
        self.current_weather = weather_type
        self.intensity = intensity
        
    def update(self, dt):
        """更新天气粒子"""
        if self.current_weather == "rain":
            self._update_rain(dt)
        elif self.current_weather == "snow":
            self._update_snow(dt)
        elif self.current_weather == "leaves":
            self._update_falling_leaves(dt)
    
    def _update_rain(self, dt):
        """雨滴效果"""
        # 快速下落，带轻微随机偏移
        for p in self.particles:
            p['y'] -= 800 * dt * self.intensity  # 下落速度
            p['x'] += random.uniform(-20, 20) * dt
            
            # 超出边界重置
            if p['y'] < 0:
                p['y'] = SCREEN_HEIGHT
                p['x'] = random.uniform(0, SCREEN_WIDTH)
    
    def _update_snow(self, dt):
        """雪花效果 - 飘落+摇摆"""
        for p in self.particles:
            p['y'] -= 100 * dt * self.intensity
            p['x'] += math.sin(p['y'] * 0.01) * 50 * dt  # 摇摆效果
            
            if p['y'] < 0:
                p['y'] = SCREEN_HEIGHT
                p['x'] = random.uniform(0, SCREEN_WIDTH)
```

```glsl
// 天气着色器 - 屏幕后处理
Shader "PostProcess/WeatherOverlay" {
    Properties {
        _MainTex ("Base Texture", 2D) = "white" {}
        _WeatherType ("Weather Type", Range(0, 3)) = 0
        _Intensity ("Intensity", Range(0, 1)) = 0.5
        _WindDirection ("Wind Direction", Vector) = (1, 0, 0, 0)
    }
    
    // 雨天屏幕湿润效果
    float rain_drops(float2 uv, float time) {
        float drops = 0;
        
        // 多层雨滴
        for(int i = 0; i < 3; i++) {
            float scale = 10.0 + i * 5.0;
            float2 drop_uv = uv * scale;
            drop_uv.y += time * (2.0 + i * 0.5);
            
            float drop = sin(drop_uv.x * 10 + sin(drop_uv.y * 5 + time));
            drop = smoothstep(0.9, 1.0, drop);
            drops += drop * (1.0 / (1.0 + i));
        }
        
        return drops;
    }
    
    // 雪天屏幕结冰效果
    float frost_effect(float2 uv, float time) {
        float frost = 0;
        float2 FrostUV = uv * 3.0;
        
        float n1 = sin(FrostUV.x * 20 + FrostUV.y * 15 + time * 0.5);
        float n2 = sin(FrostUV.x * 15 - FrostUV.y * 20 + time * 0.3);
        frost = (n1 + n2) * 0.5;
        
        return smoothstep(0.7, 1.0, frost) * 0.3;
    }
}
```

#### 本地部署

```bash
# Unity
# 1. 创建WeatherSystem.cs脚本
# 2. 创建WeatherParticle预制体
# 3. 配置WeatherManager单例

# Godot
# 1. 创建Weather粒子系统
# 2. 添加Shader材质
```

#### 效果展示

| 天气类型 | 粒子效果 | 屏幕效果 |
|---------|---------|---------|
| 雨 | 快速下落雨滴 | 湿润效果、水滴滑落 |
| 雪 | 飘落+摇摆 | 轻微泛白、结冰效果 |
| 落叶 | 旋转飘落 | - |

---

## 二、3D战斗场景表现技术

### 2.1 粒子系统

#### 背景需求

3D战斗需要强烈的视觉反馈来增强打击感，包括：技能特效、击中反馈、环境效果等。

#### 目标

构建高性能、可配置的粒子系统，提供丰富的战斗特效。

#### 技术方案

**GPU粒子系统**

```cpp
// GPU粒子系统 - Unity Compute Shader
#pragma kernel CSMain

struct Particle {
    float3 position;
    float3 velocity;
    float4 color;
    float life;
    float size;
};

RWStructuredBuffer<Particle> particles;
float deltaTime;
float3 emitterPosition;
float3 emitterDirection;
float emitRate;
float particleLifetime;
float initialSpeed;
float gravity;

// 粒子发射
[numthreads(64,1,1)]
void CSMain (uint3 id : SV_DispatchThreadID) {
    Particle p = particles[id.x];
    
    if (p.life <= 0) {
        // 重置粒子
        p.position = emitterPosition;
        
        // 随机方向发射
        float3 randomDir = emitterDirection;
        randomDir.x += (rand(id.x) - 0.5) * 0.5;
        randomDir.y += (rand(id.x + 1000) - 0.5) * 0.5;
        randomDir.z += (rand(id.x + 2000) - 0.5) * 0.5;
        
        p.velocity = normalize(randomDir) * initialSpeed;
        p.life = particleLifetime;
        p.size = 0.1 + rand(id.x + 3000) * 0.1;
        p.color = float4(1, 1, 1, 1);
    } else {
        // 更新粒子
        p.position += p.velocity * deltaTime;
        p.velocity.y -= gravity * deltaTime;  // 重力
        p.life -= deltaTime;
        
        // 颜色随生命周期变化
        float lifeRatio = p.life / particleLifetime;
        p.color.a = lifeRatio;
    }
    
    particles[id.x] = p;
}
```

**战斗特效预设**

```python
class BattleEffectPresets:
    """战斗特效预设库"""
    
    @staticmethod
    def slash_effect():
        """剑光斩击效果"""
        return {
            'type': 'trail',
            'particle_count': 100,
            'lifetime': 0.3,
            'start_color': (1.0, 0.9, 0.5, 1.0),
            'end_color': (1.0, 0.3, 0.0, 0.0),
            'size': 0.1,
            'speed': 5.0,
            'gravity': 0,
            'blend_mode': 'additive',
            'shader': 'Particles/Additive'
        }
    
    @staticmethod
    def hit_spark():
        """击中火花效果"""
        return {
            'type': 'burst',
            'particle_count': 50,
            'lifetime': 0.2,
            'start_color': (1.0, 1.0, 0.8, 1.0),
            'end_color': (1.0, 0.5, 0.0, 0.0),
            'size': 0.05,
            'speed': 10.0,
            'gravity': 5.0,
            'cone_angle': 60,
            'blend_mode': 'additive'
        }
    
    @staticmethod
    def ice_freeze():
        """冰冻效果"""
        return {
            'type': 'aoe',
            'particle_count': 200,
            'lifetime': 1.0,
            'start_color': (0.5, 0.8, 1.0, 0.8),
            'end_color': (0.3, 0.5, 0.8, 0.0),
            'size': 0.3,
            'speed': 2.0,
            'gravity': 0,
            'expansion_speed': 3.0,
            'blend_mode': 'alpha'
        }
    
    @staticmethod
    def lightning_chain():
        """闪电链效果"""
        return {
            'type': 'chain',
            'segments': 5,
            'jitter': 0.2,
            'color': (0.6, 0.4, 1.0, 1.0),
            'thickness': 0.05,
            'lifetime': 0.1,
            'branches': 3
        }
```

#### 本地部署

```bash
# Unity项目
# 1. 创建ParticleSystem预设
# 2. 配置EffectLibrary脚本
# 3. 通过代码调用播放

# UE5
# 1. 创建Niagara系统
# 2. 导出为资产供蓝图调用
```

#### 效果展示

| 特效类型 | 表现 | 适用场景 |
|---------|------|---------|
| 斩击 | 弧形轨迹+淡出 | 剑技、刀技 |
| 火花 | 爆发+散射 | 击中反馈 |
| 冰冻 | 扩散+凝结 | 冰系技能 |
| 闪电 | 链式闪烁 | 雷系技能 |

#### 优缺点分析

**优点：**
- GPU加速，万级粒子无压力
- 可配置化，策划可调整参数
- 效果丰富，覆盖各种战斗场景

**缺点：**
- 需要针对不同游戏引擎适配
- 复杂特效需要美术配合

---

### 2.2 屏幕特效

#### 背景需求

战斗需要强烈的视觉冲击来提升打击感，如：屏幕震动、慢动作、颜色滤镜等。

#### 目标

通过后处理特效增强战斗表现力。

#### 技术方案

**屏幕震动**

```csharp
// Unity屏幕震动系统
public class ScreenShake : MonoBehaviour
{
    private Vector3 originalPosition;
    private float shakeDuration = 0f;
    private float shakeMagnitude = 0.2f;
    private float dampingSpeed = 1.0f;
    
    private void Update()
    {
        if (shakeDuration > 0)
        {
            transform.localPosition = originalPosition + Random.insideUnitSphere * shakeMagnitude;
            shakeDuration -= Time.deltaTime * dampingSpeed;
        }
        else
        {
            shakeDuration = 0;
            transform.localPosition = originalPosition;
        }
    }
    
    public void TriggerShake(float duration, float magnitude)
    {
        shakeDuration = duration;
        shakeMagnitude = magnitude;
    }
    
    // 不同技能的震动预设
    public static class Presets
    {
        public static void LightHit() => Instance.TriggerShake(0.1f, 0.1f);
        public static void HeavyHit() => Instance.TriggerShake(0.3f, 0.3f);
        public static void Explosion() => TriggerShake(0.5f, 0.5f);
        public static void Ultimate() => TriggerShake(0.8f, 0.7f);
    }
}
```

**时间减缓（子弹时间）**

```csharp
public class BulletTime : MonoBehaviour
{
    private float targetTimeScale = 1.0f;
    private float transitionSpeed = 5.0f;
    
    public void EnterSlowMotion(float scale, float duration)
    {
        targetTimeScale = scale;
        StartCoroutine(ExitAfter(duration));
    }
    
    private IEnumerator ExitAfter(float duration)
    {
        yield return new WaitForSeconds(duration);
        targetTimeScale = 1.0f;
    }
    
    private void Update()
    {
        // 平滑过渡时间缩放
        Time.timeScale = Mathf.Lerp(Time.timeScale, targetTimeScale, 
            Time.deltaTime * transitionSpeed);
        
        // 补偿固定更新间隔
        Time.fixedDeltaTime = 0.02f * Time.timeScale;
    }
}
```

**色彩后处理**

```glsl
// 伤害特效着色器
Shader "PostProcess/DamageEffect" {
    Properties {
        _MainTex ("Base Texture", 2D) = "white" {}
        _DamageIntensity ("Damage Intensity", Range(0, 1)) = 0
        _HitDirection ("Hit Direction", Vector) = (0, 0, 0, 0)
    }
    
    fixed4 frag (v2f i) : SV_Target {
        fixed4 col = tex2D(_MainTex, i.uv);
        
        // 红色色调偏移
        if (_DamageIntensity > 0) {
            // 屏幕边缘变红
            float2 center = float2(0.5, 0.5);
            float dist = distance(i.uv, center);
            float redTint = smoothstep(0.3, 0.8, dist) * _DamageIntensity;
            
            col.r = lerp(col.r, 1.0, redTint);
            col.g = lerp(col.g, 0.0, redTint * 0.5);
            col.b = lerp(col.b, 0.0, redTint * 0.5);
            
            // 震动偏移
            float shake = _DamageIntensity * 0.01;
            i.uv += float2(
                sin(i.uv.y * 50) * shake,
                cos(i.uv.x * 50) * shake
            );
            
            col = tex2D(_MainTex, i.uv);
        }
        
        return col;
    }
}
```

#### 本地部署

```bash
# Unity
# 1. 创建PostProcess Volume
# 2. 添加自定义效果脚本
# 3. 配置渲染层

# UE5
# 1. 创建PostProcess材质
# 2. 在Level Blueprint调用
```

#### 效果展示

| 特效类型 | 效果描述 | 使用场景 |
|---------|---------|---------|
| 屏幕震动 | 相机抖动 | 击中、爆炸 |
| 子弹时间 | 时间减缓 | 必杀技、闪避 |
| 色彩偏移 | 红色/其他色调 | 受伤、Buff |
| 屏幕泛白 | 闪光效果 | 魔法释放 |

---

### 2.3 动态光影系统

#### 背景需求

3D战斗需要动态光影提升视觉冲击力，包括：技能发光、动态阴影、光照反馈等。

#### 目标

构建程序化控制的动态光影系统。

#### 技术方案

**动态光源管理**

```csharp
public class CombatLightingSystem : MonoBehaviour
{
    private List<Light> combatLights = new List<Light>();
    
    // 技能发光效果
    public void PlaySkillLight(Skill skill, Transform target)
    {
        // 创建跟随光源
        GameObject lightObj = new GameObject("SkillLight");
        lightObj.transform.SetParent(target);
        
        Light light = lightObj.AddComponent<Light>();
        light.type = LightType.Point;
        light.range = skill.lightRange;
        light.intensity = skill.lightIntensity;
        light.color = skill.lightColor;
        light.shadows = LightShadows.Soft;
        
        combatLights.Add(light);
        
        // 光源动画
        StartCoroutine(AnimateLight(light, skill));
    }
    
    private IEnumerator AnimateLight(Light light, Skill skill)
    {
        float elapsed = 0;
        float maxIntensity = light.intensity;
        
        while (elapsed < skill.duration)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / skill.duration;
            
            // 脉冲效果
            light.intensity = maxIntensity * Mathf.Sin(t * Mathf.PI);
            
            // 颜色渐变
            light.color = Color.Lerp(skill.startColor, skill.endColor, t);
            
            yield return null;
        }
        
        Destroy(light.gameObject);
    }
    
    // 击中闪光
    public void PlayImpactFlash(Vector3 position, Color color)
    {
        GameObject flash = new GameObject("ImpactFlash");
        flash.transform.position = position;
        
        Light light = flash.AddComponent<Light>();
        light.type = LightType.Point;
        light.range = 5f;
        light.intensity = 3f;
        light.color = color;
        light.shadows = LightShadows.None;
        
        // 快速衰减
        StartCoroutine(FlashFade(light));
    }
    
    private IEnumerator FlashFade(Light light)
    {
        float intensity = light.intensity;
        float elapsed = 0;
        
        while (elapsed < 0.15f)
        {
            elapsed += Time.deltaTime;
            light.intensity = Mathf.Lerp(intensity, 0, elapsed / 0.15f);
            yield return null;
        }
        
        Destroy(light.gameObject);
    }
}
```

**实时阴影增强**

```csharp
public class DynamicShadowEnhancer : MonoBehaviour
{
    // 技能释放时增强阴影
    public void EnhanceShadowsOnSkill(Skill skill)
    {
        RenderSettings.shadowStrength = 1.0f;
        
        // 技能持续期间加深阴影
        StartCoroutine(ShadowPulse(skill.duration));
    }
    
    private IEnumerator ShadowPulse(float duration)
    {
        float elapsed = 0;
        
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            // 轻微脉动
            RenderSettings.shadowStrength = 0.8f + Mathf.Sin(elapsed * 10) * 0.2f;
            yield return null;
        }
        
        RenderSettings.shadowStrength = 0.5f;
    }
}
```

**全局光照动态调整**

```glsl
// 战斗模式GI调整
Shader "Hidden/CombatGI" {
    Properties {
        _MainTex ("Base", 2D) = "white" {}
        _CombatIntensity ("Combat Intensity", Range(0, 1)) = 0
        _SkillColor ("Skill Color", Color) = (1, 0.5, 0, 1)
    }
    
    fixed4 frag (v2f i) : SV_Target {
        fixed4 col = tex2D(_MainTex, i.uv);
        
        // 战斗时增加对比度
        if (_CombatIntensity > 0) {
            // 提高饱和度
            float luminance = dot(col.rgb, float3(0.299, 0.587, 0.114));
            col.rgb = lerp(float3(luminance), col.rgb, 1.0 + _CombatIntensity * 0.3);
            
            // 技能颜色叠加
            col.rgb += _SkillColor.rgb * _CombatIntensity * 0.2;
        }
        
        return col;
    }
}
```

#### 本地部署

```bash
# Unity
# 1. 创建LightingSettings配置文件
# 2. 添加CombatLighting脚本
# 3. 配置光照探针和反射探针
```

#### 效果展示

| 光影效果 | 描述 | 战斗场景 |
|---------|------|---------|
| 技能发光 | 跟随技能的光源 | 魔法、激光 |
| 击中闪光 | 瞬间高亮 | 攻击命中 |
| 阴影脉动 | 动态阴影变化 | 技能释放 |
| GI增强 | 全局光照变化 | 战斗高潮 |

---

## 三、总结与技术选型

### 3.1 技术对比

| 类别 | 技术方案 | 美术依赖 | 性能影响 | 效果上限 |
|-----|---------|---------|---------|---------|
| 2D地形 | 程序化生成 | 极低 | 低 | 高 |
| 2D着色器 | GPU渲染 | 极低 | 低 | 高 |
| 2D天气 | 粒子+Shader | 低 | 中 | 中 |
| 3D粒子 | GPU粒子 | 低 | 中 | 极高 |
| 3D屏幕特效 | 后处理 | 极低 | 中 | 高 |
| 3D动态光影 | 光源管理 | 低 | 高 | 极高 |

### 3.2 推荐实施路径

**阶段一：基础效果**
- 2D：程序化地形 + 基础着色器效果
- 3D：粒子特效库 + 屏幕震动

**阶段二：增强效果**
- 2D：动态天气系统 + 高级着色器
- 3D：动态光影 + 后处理特效

**阶段三：高级效果**
- 2D：AI辅助地形生成
- 3D：程序化剧情动画 + 全局光照动态调整

### 3.3 落地建议

1. **技术优先级**：先实现粒子系统和屏幕震动，成本低、收益高
2. **美术配合**：即使追求程序化，建议保留基础纹理配合
3. **性能监控**：GPU粒子和动态光影需要持续性能测试
4. **配置化**：所有效果参数配置化，便于策划调整

---

*报告生成时间：2026-03-14*
*调研方向：游戏表现技术方案*
