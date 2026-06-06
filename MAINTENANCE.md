# Maintenance Guide

这个文件给以后继续接手 `Night Runner` 的人或 AI 直接看。

## 先看什么

这个项目的文档现在收敛成 5 个入口，优先按这个顺序看，不要再到处翻旧说明：

1. [README.md](/C:/Users/24560/Desktop/study/gametwo/README.md)
2. [MAINTENANCE.md](/C:/Users/24560/Desktop/study/gametwo/MAINTENANCE.md)
3. [docs/architecture.md](/C:/Users/24560/Desktop/study/gametwo/docs/architecture.md)
4. [docs/progress.md](/C:/Users/24560/Desktop/study/gametwo/docs/progress.md)
5. [docs/backlog.md](/C:/Users/24560/Desktop/study/gametwo/docs/backlog.md)

`docs/design.md` 已删除，设计意图已经并入本文件和 README，避免重复维护。

## 当前工程判断

- 引擎：Godot 4.6
- 目标：Android APK 优先，后续扩到 PC / Steam
- 当前阶段：已升级为有中枢壳层、行动目录和局外进度的竖切片骨架
- 方向确认：后续所有系统都先保证 APK 可安装、触屏可玩，同时保留桌面输入、存档和平台服务边界，方便以后上架 Steam

## 这个游戏现在在干嘛

当前已经不再是单一固定跑图，而是 3 条行动线路：

1. `Blitz Pursuit`
2. `Ghost Circuit`
3. `Overdrive Protocol`

每条行动都包含：

1. 局前中枢选行动
2. 局前明确选择 `directive`
3. 过程中抢核心、维持连击、处理阶段增援
4. 同时追次级目标
5. 达成全部核心后解锁撤离，并进入可继续贪分的兑现窗口
6. 成功或失败后进入结果页
7. 局外记录最佳分数、最佳评级、成功次数和解锁进度

如果以后 AI 接手时发现又变回“场上打怪但没有目标”，优先检查：

- `scripts/game/run_catalog.gd`
- `scripts/autoload/frontend_bridge.gd`
- `scripts/game/world.gd`
- `scripts/autoload/game_state.gd`
- `scripts/game/main.gd`
- `scenes/ui/session_screen.tscn`

## 关键边界

- `GameState`：本局状态、局外进度、成绩记录、音量 / 震动设置和存档入口
- `PlatformProfile`：平台差异入口；震动执行必须经过这里，并尊重 `GameState` 的 haptics 设置
- `InputRouter`：触屏、键盘、未来手柄的统一输入层；触屏左右移动记录左右按钮按住状态，多指同时按住时以后按下方向为准，松开后恢复仍按住的另一方向
- `FrontendBridge`：应用壳和玩法之间的前端桥接层
- `RunCatalog`：行动目录、模式差异、directive 池、次级目标和兑现规则的数据源
- `World`：按行动定义装配关卡和本局事件
- `RouteHazard`：路线机关执行器，现已支持多种行为 archetype，不要再把路线机关硬写回 `World`
- `Presentation`：纯视觉氛围层，负责背景城市、雾、灯带和后续环境演出
- `SessionScreen`：中枢 / 结果 / 暂停产品壳；暂停页承载轻量设置，不直接写存档文件
- `TouchControls`：安卓运行中虚拟按键和暂停入口；暂停只调用 `FrontendBridge.toggle_pause()`，不要直接改 `SceneTree.paused`
- `DataCore` / `ExtractionGate`：短局目标层，负责“为什么要继续跑”
- `BoostPad`：地形节奏层，负责让推进更快更立体
- `Player` / `EnemyRunner` / `EnemySuppressor`：只做角色行为，不管理全局状态
- `EnemyBastion`：精英封锁敌人，负责近中距压线与 shockwave 区域压迫
- `EnemyPhantom`：高速切入型精英，负责贴身追切、俯冲突脸和中近距节奏打断
- `EnemyStalker`：垂直伏击型精英，负责平台上方蓄势坠击和落地冲击波区域压迫
- `EnemyBolt`：远程敌人的轻量投射物，不接 UI 和分数

当前有两条已经踩过的手感结论，不要回退：

- 攻击判定不能太窄，允许轻微贴脸和高度差，否则玩家会觉得“按了没用”
- 撤离门和最后几个核心不能摆得太刁钻，否则玩家会把问题理解成“功能坏了”

## 当前资产判断

- 角色和关键目标物已有首批原创 SVG 资产
- 背景氛围层已存在，但仍是程序化几何主导
- 现在已有完整中枢 / 行动卡 / 结果页 / 暂停层壳体，但仍是逻辑优先版本
- HUD 已升级为“行动卡 + 任务卡 + 路线阶段卡 + 指令卡 + 次级目标卡 + cashout 卡 + 短提示”
- 还没有正式音效、命中特效、角色动画状态机、完整 UI 图标系统

不要在后续迭代里重新回到“纯色方块 + 默认按钮”状态。

## 继续开发的顺序

1. 先继续加强三条行动的地形辨识度和事件差异
2. 再做打击反馈、音效、屏幕特效和敌人预警
3. 再继续补结果页、战斗回顾、设置和移动端适配
4. 最后接更完整存档、Steam 抽象层和正式章节结构

## 修改规则

- 改系统边界：先更 `docs/architecture.md`
- 做功能：完工后更 `docs/progress.md`
- 新想法：先进 `docs/backlog.md`
- 改中枢 / 结果 / UI 壳时，优先经 `FrontendBridge`
- 前端 / UI 层只改 `SessionScreen`、`HUD` 或它们的替身层，不直接改 `World`、角色脚本或存档写入
- 前端只需要先保证“能看、能接、能替换”，高级美术、动效、品牌化视觉留给后续 AI 迭代
- 避免把平台判断散写在玩法脚本里
- 如果删文档，先确认内容已经并入现存入口，避免再长回重复说明

## 在线与发布

- GitHub 仓库：[night-runner](https://github.com/2456018331lby-dev/night-runner)
- 在线版本：[GitHub Pages](https://2456018331lby-dev.github.io/night-runner/)
- 网页导出入口：[export_web_to_docs.bat](/C:/Users/24560/Desktop/study/gametwo/export_web_to_docs.bat)
- Android 导出预设：`export_presets.cfg` 中已预留 `Android` preset，目标包路径 `exports/android/NightRunner-debug.apk`
- 当前环境判断：Godot Android export templates、SDK、JDK、build-tools、`adb` 和 Android 35 模拟器已可用；命令行出包、签名验证、模拟器安装启动已打通，当前缺口主要是真机画面、触控和震动强度验证
- `scripts/tools/verify_player_jump_windows.gd` 是玩家跳跃手感护栏；改 jump buffer、coyote time、二段跳或落地重置逻辑时先跑它，避免触屏提前点跳被吞或离台后保留无限宽限
- `scripts/tools/verify_encounter_pressure.gd` 是行动调表护栏；新增 Suppressor / Bastion / Stalker 刷怪时先跑它，避免同一波把远程锁线、shockwave 和坠击压到同一小区域
- `scripts/tools/verify_dynamic_health_hud.gd` 是生命 HUD 护栏；改行动基础生命、directive `health_bonus` 或 HUD 生命区时先跑它，避免实际生命和屏幕 pips 再次不一致
- `scripts/tools/verify_settings.gd` / `scripts/tools/verify_pause_settings.gd` 是设置护栏；改 `GameState` 设置结构、暂停页设置控件或 `PlatformProfile` 震动边界时先跑它们

后续如果要更新线上版本：

1. 运行 `export_web_to_docs.bat`
2. 确认 `docs/index.html`、`docs/index.js`、`docs/index.wasm` 已更新
3. 提交并同步到 GitHub

## 已验证

- `C:\\Users\\24560\\AppData\\Local\\Microsoft\\WinGet\\Packages\\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\\Godot_v4.6.2-stable_win64_console.exe --headless --path C:\\Users\\24560\\Desktop\\study\\gametwo --quit-after 3`
- 结果：项目可加载，脚本可解析
- 2026-05-06：新增 `EnemySuppressor` / `EnemyBolt` 后再次执行同一命令，结果通过
- 2026-05-06：新增 `DataCore` / `ExtractionGate` / 结算逻辑后再次执行同一命令，结果通过
- 2026-05-10：新增 `RunCatalog` / `FrontendBridge` / `SessionScreen` / 存档与行动目录后再次执行同一命令，结果通过
- 2026-05-10：新增 directive 预选、次级目标展示、cashout 风险收益和中枢/HUD 扩展后再次执行同一命令，结果通过
- 2026-06-06：新增 `EnemyStalker` 落点预警、坠击残影和重击音效后，项目 headless 加载与 `enemy_stalker.tscn` 单场景加载均通过
- 2026-06-06：重新导出 `exports/android/NightRunner-debug.apk`，`apksigner` v2 / v3 验证通过，`apkanalyzer` 确认包名 / minSdk / targetSdk，`NightRunner35` Android 35 模拟器安装启动通过
- 2026-06-06：新增玩家受击白闪、受击残影、方向性碎片和来源级重击屏幕反馈后，项目 headless 加载通过
- 2026-06-06：修复 `EnemySuppressor` / `EnemyBastion` / `EnemyPhantom` 命中不扣血和血条未初始化问题后，项目 headless 加载与三个敌人单场景加载均通过；重新导出 Android debug APK，v2 / v3 签名和 `apkanalyzer` 包信息校验通过；`NightRunner35` Android 35 模拟器安装启动通过，`pidof` 返回进程 `6044`，`dumpsys activity` 显示 `GodotAppLauncher` 为 resumed activity
- 2026-06-06：新增移动端左右触控仲裁、运行中暂停按钮和暂停页继续响应输入后，`verify_touch_input.gd` 与 `verify_touch_pause.tscn` 均通过；项目 / 触控场景 / 主场景 headless 加载通过；重新导出 Android debug APK，v2 / v3 签名和 `apkanalyzer` 包信息校验通过；`NightRunner35` 模拟器安装启动通过，`pidof` 返回进程 `6716`，`dumpsys activity` 显示 `GodotAppLauncher` 为 resumed activity
- 2026-06-06：新增遭遇压力预算脚本后，三条行动的初始 / timeline / core / completion / cashout / setpiece 刷怪桶通过 Suppressor / Bastion / Stalker 同桶距离回归检查；重新导出 Android debug APK，v2 / v3 签名和 `apkanalyzer` 包信息校验通过；`NightRunner35` 模拟器安装启动通过，`pidof` 返回进程 `2938`，`dumpsys activity` 显示 `GodotAppLauncher` 为 resumed activity
- 2026-06-06：新增可持久化音量 / 震动设置后，`verify_settings.tscn` 和 `verify_pause_settings.tscn` 均通过；设置会写入 `GameState.meta_progress.settings`，暂停页控件通过 `GameState` 更新运行时音量和震动开关，异常旧存档的非字典设置会回退到默认结构；重新导出 Android debug APK，v2 / v3 签名和 `apkanalyzer` 包信息校验通过；`NightRunner35` 模拟器安装启动通过，`pidof` 返回进程 `3396`，`dumpsys activity` 显示 `GodotAppLauncher` 为 resumed activity
- 2026-06-06：修复 HUD 固定 3 格生命导致 `health_bonus` 路线 / directive 显示不准的问题后，新增 `verify_dynamic_health_hud.tscn`，覆盖正生命修正、负生命修正和最小 1 格兜底；动态生命 HUD、设置、暂停设置、遭遇压力、触控暂停和触控输入回归均通过；重新导出 Android debug APK，v2 / v3 签名和 `apkanalyzer` 包信息校验通过；`NightRunner35` 模拟器安装启动通过，`pidof` 返回进程 `3102`，`dumpsys activity` 显示 `GodotAppLauncher` 为 top resumed activity
- 2026-06-06：给 `Player` 增加短 jump buffer 和明确 coyote time 后，新增 `verify_player_jump_windows.tscn`，覆盖提前点跳缓存、缓存消耗、coyote 过期收束和 coyote jump 后仍保留一次空中跳；玩家跳跃窗口、动态生命 HUD、设置、暂停设置、遭遇压力、触控暂停和触控输入回归均通过；重新导出 Android debug APK，v2 / v3 签名和 `apkanalyzer` 包信息校验通过；`NightRunner35` 模拟器安装启动通过，`pidof` 返回进程 `3139`，`dumpsys activity` 显示 `GodotAppLauncher` 为 top resumed activity
