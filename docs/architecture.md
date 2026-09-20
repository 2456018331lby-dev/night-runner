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
- `scripts/data`: 资源数据类（如 `RunOperationData`，供 `.tres` 资源绑定脚本结构）
- `docs/index.html`: GitHub Pages 手工维护的落地页（`export_web_to_docs.bat` 只覆盖 `index.js` / `index.pck` / `index.wasm`，不会覆盖它）。其中的 `fileSizes` 必须等于真实包体字节数——Godot 用声明值累加下载总量，而进度回调里的 `current` 是真实下载字节数，声明偏小会让进度条提前冲到 100% 后卡住。`sync_web_bundle_sizes.ps1` 负责回填，护栏是 `verify_web_portal_bundle.tscn`
- `docs/index.html` 的加载层 `#status` 必须盖在焦点提示 `#click-to-focus` 之上（前者 z-index 更大），否则 50MB 资源下载期间玩家看到的是 "Click to Start" 而不是下载进度

## 单例

### `GameState`

- 保存本局状态：分数、生命、时间、是否失败
- 对外提供 `start_run`、`add_score`、`lose_health`、`finish_run`
- 终局路径必须幂等：`finish_run()` 开头判 `is_run_active` 并立刻置 false，`lose_health()` 在 `is_run_failed` / `run_success` / 非 active 时早退。玩家坠落这类每帧都会重复触发的事件若不做守卫，会每帧重复结算并反复写存档
- `World` 的 `player_hit` / `player_fell` / `data_core_collected` 回调和 `Player` 的坠落检测、接触伤害都要先判本局是否仍在进行（`is_run_active` 且非 failed / success），避免终局后继续计分或继续触发伤害
- 负责局外进度、行动解锁、行动成绩和本地存档
- 当前还持有 run 级选择和奖励状态：选定 directive、次级目标、撤离后兑现奖励窗口
- 当前还持有轻量 UX 持久化标志：首开 brief、`Blitz Pursuit` 首局引导提示是否已看过
- 后续可接入 Steam 成就映射和平台存档同步

### `EnemyStats`

- 敌人平衡向数值的单一事实来源是 `data/enemy_stats.tres`（`EnemyStatsData` 资源，可在 Inspector 或文本里调参）；`scripts/autoload/enemy_stats.gd` 是加载与访问层
- 各 enemy 脚本在 `_ready()` 顶部经 `_hydrate_stats()` 调用 `EnemyStats.get_stat(kind, key, fallback)` 拉取；本地字面量只作 fallback，表里缺字段时行为与改造前完全一致
- `.tres` 加载失败时 autoload 回退到 inline `DEFAULT_STATS` 兜底表；verify 会强制兜底表与数据文件逐字段一致，防止静默漂移
- 调敌人数值优先改 `data/enemy_stats.tres`，不要再回到各 enemy 脚本里散改常量；纯演出常量（如 `AFTERIMAGE_*`）和部分布局常量仍留在各自脚本，不进表（例外：stalker 的 `platform_reach_x` 已进表，因为它影响索敌行为）
- 改数据文件、加载层或 enemy 调参入口后先跑 `verify_enemy_stats.tscn`（校验文件加载 / kind 集合 / 键白名单 / 类型 / 兜底一致 / 实例化一致），敌人编组相关再跑 `verify_encounter_pressure.tscn`

### `PlatformProfile`

- 统一判断当前平台
- 暴露 `is_mobile`、`is_desktop`
- 平台判断经 `detect_is_mobile()` 纯函数：Android / iOS 直接算移动端；Web 上移动端特性标签（`web_android` / `web_ios`）优先，桌面 web 标签（`web_macos` / `web_windows` / `web_linuxbsd`）是权威判据（带触屏的笔记本仍按桌面处理），标签都缺失时才退回触屏能力兜底
- 暴露 UI 安全区、移动端缩放和轻量震动入口；移动端反馈优先经这里，不要把平台分支或 haptics 调用散回玩法脚本
- 安全区 margin 计算、震动支持边界和移动端判定纯函数并入 `verify_settings.tscn` 覆盖；改安全区、移动端 UI scale、平台判断或震动入口后先跑它
- 轻震有短冷却，警告震动可打断轻震冷却但自身也有冷却；不要在触控按钮、伤害或拾取逻辑里直接调用 `Input.vibrate_handheld`
- 未来可扩展画质、UI 安全区、震动、广告开关、Steam 检测
- 当前 `SessionScreen`、`HUD`、`TouchControls` 都应经这里读安全区；新的移动端 UI 不要再写死边距

### `InputRouter`

- 把触屏输入和物理输入统一成同一接口
- 避免 `Player` 直接依赖具体按钮节点
- 当前触屏移动不是单个瞬时轴值，而是记录左右按钮各自按住状态；多指同时按住时以后按下方向为准，松开后恢复仍按住的另一方向
- 当前动作输入区分 pending 和 held：跳跃 / 冲刺通过 pending 保持一次性消费，攻击可读 held 状态来支持触屏长按续攻；触控按钮由 touch index 归属，拖出按钮应取消对应 pending，同一按钮被新触摸接管时旧触摸释放不能取消新输入
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

- 负责天际线、雾层、灯带、背景光和高精都市背景纹理等纯表现内容
- 只做视觉气氛和轻量动画，不接分数、胜负和输入
- 后续如果要继续往“商业游戏观感”靠，应优先在这一层补镜头、特效和环境演出

### `DataCore`

- 负责单个核心的悬浮表现、拾取与近距平滑磁吸
- 在玩家接近或冲刺掠过时平滑加速吸附，优化快节奏动作手感
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
- `extends RefCounted`，数据本体在 `data/run_operations.tres`（`RunOperationData` 资源），加载失败回退 inline `DEFAULT_OPERATIONS` 兜底表
- 调用方统一走 `RunCatalog.shared()` 拿共享实例（`main.gd`、`FrontendBridge`、`GameState._unlock_follow_up_operations`、各 verify 都用它），不要 `RunCatalog.new()` 各自持一份，否则 `.tres` 会被重复加载
- 调行动内容优先改 `data/run_operations.tres`，改完先跑 `verify_run_catalog.tscn`（校验字段白名单、类型、PackedScene 引用可解析、Overdrive 专属 `cashout_beacon`、兜底表一致性）
- 敌人平衡数值（hp / 分数 / 速度 / range / cooldown）统一在 `data/enemy_stats.tres` 里调（经 `EnemyStats` 访问），别回到各 enemy 脚本散改；改完先跑 `verify_enemy_stats.tscn`
- 调整敌人编组时先跑 `scripts/tools/verify_encounter_pressure.gd`，避免 Suppressor / Bastion / Stalker 这类控场精英在同一刷怪桶里过近重叠
- 每条行动的 `cashout_events` 必须保留 24 秒后的 late escalation，且 late 波次至少包含一个控制型敌人；否则长时间贪分会失去压力曲线
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
- 全局时间演出（命中 / 受击 hit-stop、连击≥3 击杀 slow-mo）也收口在本脚本：`_apply_hitstop()` 统一管理 `Engine.time_scale` 短暂下探并保证恢复到 1.0，generation 计数防止旧回调覆盖新 dip；headless 下 `_time_effects_allowed()` 直接 no-op，verify 永远看不到 time_scale 变化；`World` 侧只经 `player.trigger_kill_slowmo()` 触发，不要在别处直接改 `Engine.time_scale`
- 落地挤压 / 起跳拉伸、攻击弧光、镜头纵向前瞻和受击方向性镜头 kick 都是纯演出增量，叠加进现有 scale / offset 管线，不改变判定和计时；改这些先跑 `verify_player_attack_hold.tscn` 与 `verify_player_jump_windows.tscn`

### `EnemyRunner`

- 只关心朝玩家逼近、接触伤害、被击退和掉落死亡
- 击杀记分和环境击杀折半必须同源：`_defeat()` 里算出的折后分值既进击杀播报也进 `defeated.emit()`，分值为 0 时不生成 `+0` 飘字
- `receive_hit()` 必须先判 `defeated_once` 早退，同一帧内的重复命中不能重复播报、重复掉血条

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
- `knocked_velocity` 必须在 `_physics_process` 里真正消费（长度超过阈值时接管位移并做摩擦衰减），否则这只精英会完全免疫击退，破坏"击退到平台外摔死"这条核心解法
- 受击统一把状态切到 `reposition` 再交给击退位移接管；cling / plunge / recovery 各分支不能让击退速度被状态机静默吞掉
- 落地冲击判定圈半径在 `_ready()` 时由 `EnemyStats` 的 `landing_impact_range` 写入（复制 `landing_shape.shape` 并改 radius），不要在 `.tscn` 里写死

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
- `SessionScreen` 当前还负责移动端安全区避让、route 卡短记录、结果页 debrief 卡片、首开一键快开入口和暂停页轻量设置
- 移动端 route 卡短记录必须保留 best score、rank、best clear time 和 runs；无成功记录时 best clear time 显示 `--`，不要显示伪时间
- 暂停页的 live data 必须保留 route phase / compact pressure、cashout timer + banked value 和 live hazard 摘要，便于 Android 玩家暂停后判断继续路线
- 结果页 `RUN METRICS` 必须同时展示 career best 和当前 route best / rank / best time / runs，避免复盘时丢失路线级进步反馈
- `HUD` 负责局内主目标、路线阶段、环境压力、directive、次级目标、cashout 状态和移动端低打断提示
- `HUD` 的生命 pips 必须根据 `GameState.health` 与 `run_modifiers.health_bonus` 动态生成，不要再假设固定 3 格生命；改行动基础生命或 directive 生命修正后先跑 `verify_dynamic_health_hud.tscn`
- 移动端 `HUD` 会隐藏桌面版 `PhaseCard` / `SecondaryCard`，但导航卡必须保留压缩后的阶段压力和可选目标短状态；改移动端 HUD 密度或导航文案后先跑 `verify_dynamic_health_hud.tscn`
- 移动端 `CashoutCard` 压缩文案时仍必须保留 cashout overstay 计时和 live hazard 短状态；不要为了省高度把 `00:xx`、`Hot zone` / `Priming` 状态从安卓 HUD 中完全移除
- `TouchControls` 负责移动端虚拟移动 / 跳跃 / 攻击 / 冲刺 / 暂停入口；运行中暂停必须先清空 `InputRouter` 的 held / pending 输入，再经 `FrontendBridge.toggle_pause()`，不要让触控层直接改 `SceneTree.paused`
- `TouchControls` 的移动 / 动作 / 暂停按钮必须保持移动端触控目标尺寸，且左右操作区、右侧动作区和暂停按钮不能互相重叠；改触控布局、touch-index 归属或拖出取消后先跑 `verify_touch_controls_layout.tscn`
- `TouchControls` 的左右操作区 offset 必须保持设计像素，缩放只由 `scale` 承担（offset 再乘一次 UI scale 就是双重缩放）；pad 的 `pivot_offset` 要落在各自贴边的那一角（左区左下、右区右下），缩放才只向内收
- `TouchControls` 必须监听 `viewport.size_changed` 重新套用布局：安全区和 UI scale 都由视口尺寸推导，网页端画布缩放和设备旋转都会改变它
- 这两层都只读 `FrontendBridge` 和 `GameState` 暴露出来的展示数据，不直接驱动玩法判定，便于后续完全重做前端
- `SessionScreen` 的 HUB 会整体收起右侧信息列（`Summary` / `Brief` / `Intel` / `RecordGrid` / `DirectiveName` / `DirectiveSummary` / `DirectiveScroll`）；暂停与结算分支必须显式恢复这些控件，否则进过一次大厅后右侧内容永久消失。改 `_refresh_focus()` 的 phase 分支后先跑 `verify_session_screen_panels.tscn`
- `SessionScreen._apply_theme()` 必须在 `_build_route_banner()` / `_build_first_run_brief()` 之后调用：这两个面板是运行时创建的，提前调用会让其中的空判永远命中 null、样式覆盖全部丢失；同时要挂在 `viewport.size_changed` 上刷新安全区
- `SessionScreen` 的暂停 / 结果说明文本必须用自动换行和横向填充，避免移动端 `Why:`、`Try next:` 或可选目标说明在窄屏溢出；改这些 helper 后先跑 `verify_pause_settings.tscn`
- 暂停页设置只通过 `GameState.set_master_volume()` / `GameState.set_haptics_enabled()` 改持久化设置；`PlatformProfile` 是震动是否执行的唯一平台门禁
- 移动端暂停页的 `VOLUME`、`HAPTICS`、`RESUME`、`HUB` 控件必须保持 56px 级最小触控高度；改暂停页布局后先跑 `verify_pause_settings.tscn`

## 前端重做接管约定

- 桥接协议的逐信号 / 逐方法细节见 [docs/frontend-bridge.md](frontend-bridge.md)
- 重做中枢 / HUD / 结果页时，优先保留 `FrontendBridge` 作为唯一流程入口
- 当前职责拆分：
  - `FrontendBridge`：前端可调用入口、phase 与 operation/directive 选择协议
  - `main.gd`：把桥接请求路由到 `World` / `SessionScreen` / `GameState`；同时负责失焦自动暂停（web/切后台）——RUN 阶段收到 focus-out 通知时先清 `InputRouter` held / pending 再 `FrontendBridge.toggle_pause()`，永不因 focus-in 自动恢复；改这段先跑 `verify_focus_auto_pause.tscn`
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
