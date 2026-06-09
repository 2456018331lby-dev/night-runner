# Architecture

## 目标

让当前原型同时满足三件事：

- 安卓触屏能玩
- 后续可平滑扩到 PC / Steam
- AI 接手时能快速定位系统边界

## 顶层结构

- `project.godot`: 项目配置、输入映射、全局单例
- `export_presets.cfg`: Android / Web 导出契约；改 Android 包名、SDK、图标、APK 路径或移动渲染配置后先跑 `verify_android_export_contract.tscn`
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
- 当前还持有轻量 UX 持久化标志：首开 brief、`Blitz Pursuit` 首局引导提示是否已看过
- 后续可接入 Steam 成就映射和平台存档同步

### `PlatformProfile`

- 统一判断当前平台
- 暴露 `is_mobile`、`is_desktop`
- 暴露 UI 安全区、移动端缩放和轻量震动入口；移动端反馈优先经这里，不要把平台分支散回玩法脚本
- 未来可扩展画质、UI 安全区、震动、广告开关、Steam 检测
- 当前 `SessionScreen`、`HUD`、`TouchControls` 都应经这里读安全区；新的移动端 UI 不要再写死边距

### `InputRouter`

- 把触屏输入和物理输入统一成同一接口
- 避免 `Player` 直接依赖具体按钮节点
- 当前触屏移动不是单个瞬时轴值，而是记录左右按钮各自按住状态；多指同时按住时以后按下方向为准，松开后恢复仍按住的另一方向
- 当前动作输入区分 pending 和 held：跳跃 / 冲刺通过 pending 保持一次性消费，攻击可读 held 状态来支持触屏长按续攻；拖出按钮仍应取消 pending
- 后续能接手柄、重绑定和 Steam Input

### `FrontendBridge`

- 统一对 UI / 前端暴露应用流程和局内展示状态
- 提供行动选择、开局 directive 选择、开始、暂停、重试、返回中枢等接口
- 未来如果别的 AI 重做前端，优先接这一层，不直接改玩法节点
- 约定：前端只调用桥接信号/方法，不直接操作 `World`、`Player`、敌人节点或 `GameState` 内部字段

### `AudioEngine`

- 负责程序化音效生成、缓存和 `AudioStreamPlayer` 池，不接玩法状态、分数或 UI
- 非 headless 运行时才生成 WAV 和播放器；headless 自动化检查中音频保持 no-op，避免 Godot headless WAV playback 在退出清理阶段留下 ObjectDB 泄漏
- 改程序化音效、播放器池或 headless 运行边界后先跑 `verify_audio_engine_shutdown.tscn`

## 玩法边界

### `World`

- 负责按行动定义装配玩家出生点、敌人、平台段、核心、撤离门
- 监听胜负和掉落
- 只通过前端桥接层下发目标文本和提示
- 当前也负责 `Blitz Pursuit` 的轻量首局引导触发：开局、首遇敌、首个核心、撤离解锁这四个节点只发提示，不暂停游戏
- 当前还负责按伤害来源选择屏幕冲击强度和短事件 banner；具体角色闪白、击退和受击碎片仍留在 `Player`

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
- 调整敌人编组时先跑 `scripts/tools/verify_encounter_pressure.gd`，避免 Suppressor / Bastion / Stalker 这类控场精英在同一刷怪桶里过近重叠
- `Overdrive Protocol` 是最高贪分路线，必须保留高 score-threshold、后段 cashout 波次和 `extraction_bonus_multiplier` 收益通道；改 Overdrive 目标分、cashout 梯度或 Panic Dividend 后先跑 `verify_overdrive_greed_profile.tscn`
- 不直接持有运行期节点

### `ExtractionGate`

- 负责撤离门的锁定/解锁状态和玩家进入检测
- 锁定时给出阻挡反馈，解锁后触发胜利收尾
- 奖励结算仍放在 `GameState` / `World`，不要把分数逻辑塞回门节点

### `Player`

- 只关心移动、跳跃、冲刺、攻击和受击
- 不直接管理总分和 UI
- 跳跃手感包含短 jump buffer 和 coyote time：触屏提前点跳不会被直接吞掉，刚离开平台也只有一个明确的宽限窗口；改跳跃窗口、二段跳或落地逻辑后先跑 `verify_player_jump_windows.tscn`
- 攻击手感支持长按续攻：`InputRouter` 的 attack held 状态会在冷却结束后继续触发 `_try_attack()`；改攻击输入收集、攻击冷却或触屏 action held 语义后先跑 `verify_player_attack_hold.tscn`
- 受击反馈在本脚本内完成：短冻结、方向性击退、角色白闪、受击残影和碎片；伤害来源记录仍通过 `GameState.register_damage_source`

### `EnemyRunner`

- 只关心朝玩家逼近、接触伤害、被击退和掉落死亡

### `EnemySuppressor`

- 只关心和玩家维持射击距离、发射投射物、被击退和掉落死亡
- 继续复用 `enemy` 组、`receive_hit` 和 `defeated` 接口

### `EnemyBastion`

- 精英封锁敌人
- 负责制造 windup -> shockwave 的近中距压迫区
- 仍只输出自身受击、碰撞伤害和区域压制，不接 UI、进度或结算

### `EnemyPhantom`

- 高速切入型精英
- 负责 windup -> dive 的近身追切、突脸打断和中近距节奏扰动
- 只输出自身受击、碰撞伤害和俯冲压迫，不直接接 UI、进度或结算
- 掉落离场不计分，避免把高机动失足变成白送分数

### `EnemyStalker`

- 垂直伏击型精英
- 负责平台上方 cling -> warning -> plunge -> recovery -> reposition 循环
- warning 阶段自己预测落点并显示世界坐标坠落线 / 危险圈，plunge 阶段自己生成残影，landing 阶段自己触发冲击视觉和专属重击音效
- 只输出自身受击、碰撞伤害和落地冲击，不直接接 UI、进度或结算

### `EnemyBolt`

- 由 `EnemySuppressor` 生成
- 只负责命中玩家或地形后消失
- 不直接操作分数、HUD 或全局流程

## PC 扩展接口

- `GameState` 预留 `meta_progress` 字典，并持久化局外进度、首开 UX 标记、音量和震动设置
- `PlatformProfile` 预留桌面特性检测层
- `InputRouter` 可直接加手柄轴和重绑定
- `FrontendBridge` 允许未来替换成更复杂的前端、设置页和商店壳层
- `World` 可拆成关卡模式、Boss 模式、挑战模式
- `docs/backlog.md` 中所有 PC 扩展项均应优先挂到已有边界，而不是在 `player.gd` 里硬加

## 当前产品壳分工

- `SessionScreen` 负责中枢甲板、首开 brief、结果页、暂停页和局前构筑展示
- `SessionScreen` 当前还负责移动端安全区避让、结果页 debrief 卡片、首开一键快开入口和暂停页轻量设置
- `HUD` 负责局内主目标、路线阶段、环境压力、directive、次级目标、cashout 状态和移动端低打断提示
- `HUD` 的生命 pips 必须根据 `GameState.health` 与 `run_modifiers.health_bonus` 动态生成，不要再假设固定 3 格生命；改行动基础生命或 directive 生命修正后先跑 `verify_dynamic_health_hud.tscn`
- `TouchControls` 负责移动端虚拟移动 / 跳跃 / 攻击 / 冲刺 / 暂停入口；运行中暂停必须先清空 `InputRouter` 的 held / pending 输入，再经 `FrontendBridge.toggle_pause()`，不要让触控层直接改 `SceneTree.paused`
- 这两层都只读 `FrontendBridge` 和 `GameState` 暴露出来的展示数据，不直接驱动玩法判定，便于后续完全重做前端
- 暂停页设置只通过 `GameState.set_master_volume()` / `GameState.set_haptics_enabled()` 改持久化设置；`PlatformProfile` 是震动是否执行的唯一平台门禁
- 移动端暂停页的 `VOLUME`、`HAPTICS`、`RESUME`、`HUB` 控件必须保持 56px 级最小触控高度；改暂停页布局后先跑 `verify_pause_settings.tscn`

## 前端重做接管约定

- 重做中枢 / HUD / 结果页时，优先保留 `FrontendBridge` 作为唯一流程入口
- 当前职责拆分：
  - `FrontendBridge`：前端可调用入口、phase 与 operation/directive 选择协议
  - `main.gd`：把桥接请求路由到 `World` / `SessionScreen` / `GameState`
  - `SessionScreen` / `HUD`：只负责展示，不直接改玩法
- 新前端应消费：
  - `FrontendBridge` 的 phase / operation / directive 选择接口
  - `GameState` 的只读运行态文本与结算数据
- 新前端不应：
  - 直接改 `World` 内部刷怪、目标、关卡事件
  - 直接改敌人脚本数值或角色碰撞逻辑
  - 直接写存档文件
- 如果要增加更复杂前端特效、动画编排或独立 UI 框架，尽量挂在 `SessionScreen` / `HUD` 替身层，而不是把玩法代码挪进 UI
- 当前这是文档化边界与入口收敛，不是完全封闭的硬接口层；后续如需更强隔离，再继续封装

## AI 维护约定

- 变更系统边界时，先更新本文档
- 新增场景或单例时，先判断能否复用现有结构
- 需要持久化时，优先挂到 `GameState`，不要让 UI 自己写文件
