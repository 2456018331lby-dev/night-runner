# Architecture

## 目标

让当前原型同时满足三件事：

- 安卓触屏能玩
- 后续可平滑扩到 PC / Steam
- AI 接手时能快速定位系统边界

## 顶层结构

- `project.godot`: 项目配置、输入映射、全局单例
- `scenes/app`: 应用入口
- `scenes/game`: 战斗和关卡容器
- `scenes/actors`: 玩家、敌人、后续 Boss / NPC
- `scenes/ui`: HUD 和触屏 UI
- `scripts/autoload`: 全局状态、平台适配、输入桥接
- `scripts/game`: 关卡循环、摄像机、生成、模式状态
- `scripts/actors`: 角色行为
- `scripts/ui`: UI 逻辑

## 单例

### `GameState`

- 保存本局状态：分数、生命、时间、是否失败
- 对外提供 `start_run`、`add_score`、`lose_health`、`finish_run`
- 负责局外进度、行动解锁、行动成绩和本地存档
- 当前还持有 run 级选择和奖励状态：选定 directive、次级目标、撤离后兑现奖励窗口
- 后续可接入 Steam 成就映射和平台存档同步

### `PlatformProfile`

- 统一判断当前平台
- 暴露 `is_mobile`、`is_desktop`
- 未来可扩展画质、UI 安全区、震动、广告开关、Steam 检测

### `InputRouter`

- 把触屏输入和物理输入统一成同一接口
- 避免 `Player` 直接依赖具体按钮节点
- 后续能接手柄、重绑定和 Steam Input

### `FrontendBridge`

- 统一对 UI / 前端暴露应用流程和局内展示状态
- 提供行动选择、开局 directive 选择、开始、暂停、重试、返回中枢等接口
- 未来如果别的 AI 重做前端，优先接这一层，不直接改玩法节点

## 玩法边界

### `World`

- 负责按行动定义装配玩家出生点、敌人、平台段、核心、撤离门
- 监听胜负和掉落
- 只通过前端桥接层下发目标文本和提示

### `Presentation`

- 负责天际线、雾层、灯带、背景光等纯表现内容
- 只做视觉气氛和轻量动画，不接分数、胜负和输入
- 后续如果要继续往“商业游戏观感”靠，应优先在这一层补镜头、特效和环境演出

### `DataCore`

- 负责单个核心的悬浮表现和拾取
- 只发出 `collected`，不直接改 UI

### `BoostPad`

- 负责给玩家提供固定方向的推进/弹射节奏
- 只触发位移，不自己管理分数或目标

### `RouteHazard`

- 数据驱动的路线机关节点
- 负责周期性激活、碰撞惩罚和自身视觉状态
- 当前已支持 `pulse_beam`、`sweep_wall`、`collapse_zone` 三类 archetype
- 由 `World` 按行动配置生成和切阶段，不自己决定关卡节奏

### `RunCatalog`

- 提供行动目录与内容定义
- 负责“当前有哪些可玩行动”和“每个行动如何装配”的数据来源
- 当前每条行动还定义基础 modifiers、directive 池、次级目标、路线机关和撤离兑现规则
- 不直接持有运行期节点

### `ExtractionGate`

- 负责撤离门的锁定/解锁状态和玩家进入检测
- 锁定时给出阻挡反馈，解锁后触发胜利收尾
- 奖励结算仍放在 `GameState` / `World`，不要把分数逻辑塞回门节点

### `Player`

- 只关心移动、跳跃、冲刺、攻击和受击
- 不直接管理总分和 UI

### `EnemyRunner`

- 只关心朝玩家逼近、接触伤害、被击退和掉落死亡

### `EnemySuppressor`

- 只关心和玩家维持射击距离、发射投射物、被击退和掉落死亡
- 继续复用 `enemy` 组、`receive_hit` 和 `defeated` 接口

### `EnemyBolt`

- 由 `EnemySuppressor` 生成
- 只负责命中玩家或地形后消失
- 不直接操作分数、HUD 或全局流程

## PC 扩展接口

- `GameState` 预留 `meta_progress` 字典
- `PlatformProfile` 预留桌面特性检测层
- `InputRouter` 可直接加手柄轴和重绑定
- `FrontendBridge` 允许未来替换成更复杂的前端、设置页和商店壳层
- `World` 可拆成关卡模式、Boss 模式、挑战模式
- `docs/backlog.md` 中所有 PC 扩展项均应优先挂到已有边界，而不是在 `player.gd` 里硬加

## 当前产品壳分工

- `SessionScreen` 负责中枢甲板、结果页、暂停页和局前构筑展示
- `HUD` 负责局内主目标、路线阶段、环境压力、directive、次级目标和 cashout 状态
- 这两层都只读桥接状态，不直接驱动玩法判定，便于后续完全重做前端

## AI 维护约定

- 变更系统边界时，先更新本文档
- 新增场景或单例时，先判断能否复用现有结构
- 需要持久化时，优先挂到 `GameState`，不要让 UI 自己写文件
