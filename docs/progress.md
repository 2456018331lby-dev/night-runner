# Progress Log

## Current State - 2026-09-20

- **视觉与前端全面现代化升级**：
  - Web 门户全面重构为赛博朋克风格（`docs/index.html`）：引入响应式 16:9 视口霓虹框架、CRT 扫描线着色开关、终端自检动画加载条、交互式按键指令卡与路线档案。
  - AI 资产生成与接入：通过 nanobanana 生成了超高分辨率 16:9 赛博都市天际线夜景（`game_hero_backdrop.jpg`）与三条行动路线（`Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol`）专属视觉卡片。
  - 中枢选关卡片动态渲染路线立绘、霓虹发光动效与战术状态；氛围层融入远景天际线视差层。
- **核心游戏逻辑与手感深度优化**：
  - **空中顶点微浮（Jump Apex Float）**：在跳跃最高点提供平滑微浮手感，增强滞空微操与平台二段跳手感。
  - **情报核心平滑磁吸（Data Core Magnetism）**：在玩家接近或冲刺掠过核心时平滑加速吸附，彻底解决高速奔跑时微小距离差错失核心的问题。
  - **敌人攻击前摇预警（Enemy Telegraphs）**：远程压制者（`EnemySuppressor`）开火前 0.4 秒显示瞄准警示激光线，重装封锁者（`EnemyBastion`）强化冲击波蓄力光环，战斗交互清晰可读。
- **发布方向已定**：先把 web 版发到 itch.io 用真实玩家验证核心循环，Android 正式发布（keystore / AAB / 商店素材）排在其后。
- Web / itch.io 发布准备已落地：失焦自动暂停（RUN 阶段 focus-out 先清输入再暂停，永不自动恢复）、web 移动端判定硬化（桌面 web 标签权威，触屏笔记本不再误判成移动端）、独立 itch 打包链路 `export_web_to_itch.bat`（产出 `exports/itch/night-runner-web.zip`，与 `docs/` GitHub Pages 部署互不污染，Web preset 已排除 `docs/*`）。
- 游戏手感（juice）第一轮已落地：全局 hit-stop（命中 / 受击短暂 `Engine.time_scale` 下探，headless 自动 no-op）、落地挤压 / 起跳拉伸、镜头纵向前瞻 + 受击方向性 kick、每次挥击的攻击弧光、连击≥3 击杀 slow-mo。全部为纯演出增量，不改判定与计时。
- 敌人平衡数值已数据化：单一事实来源 `data/enemy_stats.tres`（`EnemyStatsData` 资源），`EnemyStats` autoload 作加载 / 访问层并带 inline 兜底表；verify 强制兜底表与数据文件逐字段一致。
- Android debug APK 出包链路已打通：`export_presets.cfg`、Godot Android export templates、SDK / JDK / build-tools / `adb`、`NightRunner35` 模拟器均可用；可安装包路径 `exports/android/NightRunner-debug.apk`。
- 移动端输入已有核心护栏：触屏左右移动仲裁、触摸 index 级拖出取消和同按钮接管、暂停/隐藏触控层时清空 held / pending 输入和按钮 pressed 状态、跳跃 buffer / coyote time、攻击长按续攻、触控按钮布局和暂停页触控高度。
- 移动端 HUD 会把阶段压力摘要和可选目标短状态压缩进导航卡第二行，cashout 卡会保留 overstay `00:xx` 计时和 live hazard 短状态；即使隐藏桌面版 `PhaseCard` / `SecondaryCard`，阶段事件、cashout 压力、hazard 状态和 optional 目标进度也不会在安卓布局里丢失。
- 局前行动 / 构筑面板会持续展示 route 与 directive 的真实状态；route 卡片使用 `ACTIVE` / `READY` / `LOCKED`，移动端还显示 `BEST` / `RANK` / `TIME` / `RUNS` 短记录，directive 卡片使用 `ACTIVE` / `OPTION`，选择切换时文本、选中态和边框会同步更新。
- 移动端暂停 / 结算面板的长说明会自动换行；暂停页会在 live data 中保留 route phase、压缩压力、cashout 计时/存量和 hazard 摘要，`Why:`、`Try next:` 和可选目标说明不会在窄屏上横向挤出左侧栏。
- 平台边界已收口在 `PlatformProfile`：安全区 margin、移动端 UI scale、震动支持、用户 haptics 设置、轻震/警告震动节流和 web 移动端判定纯函数都通过同一入口。
- 玩法竖切片已有 3 条行动：`Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol`。三条行动都有独立 `phase_setpiece` 阶段横幅 / 压力文案和 24 秒后的 late cashout 压力波，Overdrive 另有高分阈值和倍率结算护栏。
- 结果页现在会展示 `RANK REPORT` 和路线级记录：结算时直接说明距下一等级的分差、速度/受击/危险区命中、可选目标、cashout 得失，以及当前 route best / rank / best time / runs；评分阈值由 `GameState` 统一计算。
- 行动目录已外化为 `data/run_operations.tres`（`RunOperationData` 资源），`RunCatalog` 改 `extends RefCounted` 并暴露 `shared()` 共享实例；同时修掉了外化遗留的静态调用回归（此前 `GameState` autoload 解析失败，`main.gd` 也有类型推断错误，游戏实际无法启动）
- run telemetry 现在输出真实死因、死亡坐标（x / y）和 `live_route_phase` 阶段；未记录伤害来源时仍用 -1 哨兵，护栏为 `verify_run_telemetry.tscn`
- HUD 刷新改为脏写入：`_set_text` / `_set_font_color` 只在值变化时写 UI，生命格与冲刺条 StyleBox 只建一次并按状态切换引用，行动配色只在 `set_operation_context` 时重建；飘分数量加了 24 个上限
- `World._process` 的批量事件检查节流到 12.5Hz（开局首帧立即执行），导航指向仍每帧更新保证箭头跟手
- 重复的 `verify_run_operation_data.tscn`（内联脚本临时验证）已把字段白名单合并进 `verify_run_catalog.gd` 后删除
- 终局路径已幂等化：`finish_run()` / `lose_health()` 判 `is_run_active` 后早退，`Player` 坠落检测和 `World` 的 `player_hit` / `player_fell` / `data_core_collected` 回调都先判本局是否仍在进行。此前玩家坠落后每帧都会重复走一次结算并反复写存档，且终局后仍可能继续计分或继续受击
- 敌人计分与击退修正：5 只敌人的 `_defeat()` 改为让环境击杀折半后的分值同时进入击杀播报和 `defeated.emit()`（此前播报满分只加半分），`receive_hit()` 增加 `defeated_once` 早退防止同帧重复结算；`EnemyStalker` 的 `knocked_velocity` 现在真正被 `_physics_process` 消费（此前赋值后无人读取，这只精英完全免疫击退，破坏"击退到平台外摔死"解法），落地冲击圈半径改由 `EnemyStats.landing_impact_range` 在 `_ready()` 写入，不再受 `.tscn` 里写死的 120 影响
- `SessionScreen` 修复了 HUB 收起右侧信息列后暂停 / 结算不恢复的问题（进过一次大厅后 `Summary` / `Intel` / `DirectiveName` / `DirectiveSummary` 永久消失）；`_apply_theme()` 移到动态面板构建之后，`route_banner` 与 `first_run_brief` 的样式覆盖不再因空判失效，并挂到 `viewport.size_changed` 刷新安全区
- `TouchControls` 改为只由 `scale` 承担缩放（offset 保持设计像素，去掉双重缩放），pad 轴心对齐贴边角，并监听 `viewport.size_changed` 重新套用布局，兼容网页画布缩放与设备旋转
- 网页门户（`docs/index.html`）修复下载进度条：`fileSizes` 里 `index.pck` 声明 273,848 字节而真实包体是 18,393,444 字节，Godot 用声明值累加总量导致进度条在 pck 刚开始下载时就冲到 100% 然后长期卡住；新增 `sync_web_bundle_sizes.ps1` 由 `export_web_to_docs.bat` 自动回填，进度百分比也做了 0-100 夹取。同时把加载层 `#status` 的 z-index 提到焦点提示之上（此前被 "Click to Start" 遮住），并补上画布 `tabIndex` / 失焦重新聚焦 / 任意交互解锁的焦点管理
- 当前缺口：itch.io 实际上架与真机浏览器验证（音频解锁 / 触屏多指）、真机安全区与震动强度、telemetry 的 web 侧收集与上报、release keystore / AAB，以及更强的视觉资产与实玩数值调参。

## Verification Entry Points

- Android 出包契约：`scenes/tools/verify_android_export_contract.tscn`
- 设置、音量、haptics、平台安全区和 web 移动端判定：`scenes/tools/verify_settings.tscn`
- 暂停页设置触控高度：`scenes/tools/verify_pause_settings.tscn`
- 触控布局：`scenes/tools/verify_touch_controls_layout.tscn`
- 触控暂停输入清理和 InputRouter 触控语义：`scenes/tools/verify_touch_pause.tscn`
- 失焦自动暂停（web / 切后台）：`scenes/tools/verify_focus_auto_pause.tscn`
- 玩家攻击长按：`scenes/tools/verify_player_attack_hold.tscn`
- 玩家跳跃窗口：`scenes/tools/verify_player_jump_windows.tscn`
- 动态生命 HUD：`scenes/tools/verify_dynamic_health_hud.tscn`
- Overdrive 贪分路线：`scenes/tools/verify_overdrive_greed_profile.tscn`
- 遭遇压力：`scenes/tools/verify_encounter_pressure.tscn`
- 敌人数值表（`data/enemy_stats.tres`）加载 / 完整性 / 实例化一致：`scenes/tools/verify_enemy_stats.tscn`
- 行动目录（`data/run_operations.tres` / `RunCatalog`）：`scenes/tools/verify_run_catalog.tscn`
- run telemetry 打点（死因、死亡坐标、阶段、cashout overstay）+ 终局幂等守卫：`scenes/tools/verify_run_telemetry.tscn`
- 中枢 / 暂停 / 结算右侧信息列可见性与主题应用顺序：`scenes/tools/verify_session_screen_panels.tscn`
- 网页门户契约（`fileSizes` 与真实包体一致、加载层 z-index）：`scenes/tools/verify_web_portal_bundle.tscn`
- headless 音频生命周期：`scenes/tools/verify_audio_engine_shutdown.tscn`

## Documentation Rule

- `docs/progress.md` 只记录当前状态和最近有用变化，不再逐条堆每次出包流水账。
- 旧验证细节、旧 APK 大小和旧提交理由通过 git 历史追溯，不在当前维护文档里重复维护。
