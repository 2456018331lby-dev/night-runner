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
- 目标：Android 优先，后续扩到 PC / Steam
- 当前阶段：已升级为有中枢壳层、行动目录和局外进度的竖切片骨架

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

- `GameState`：本局状态、局外进度、成绩记录和存档入口
- `PlatformProfile`：平台差异入口
- `InputRouter`：触屏、键盘、未来手柄的统一输入层
- `FrontendBridge`：应用壳和玩法之间的前端桥接层
- `RunCatalog`：行动目录、模式差异、directive 池、次级目标和兑现规则的数据源
- `World`：按行动定义装配关卡和本局事件
- `RouteHazard`：路线机关执行器，现已支持多种行为 archetype，不要再把路线机关硬写回 `World`
- `Presentation`：纯视觉氛围层，负责背景城市、雾、灯带和后续环境演出
- `SessionScreen`：中枢 / 结果 / 暂停产品壳
- `DataCore` / `ExtractionGate`：短局目标层，负责“为什么要继续跑”
- `BoostPad`：地形节奏层，负责让推进更快更立体
- `Player` / `EnemyRunner` / `EnemySuppressor`：只做角色行为，不管理全局状态
- `EnemyBastion`：精英封锁敌人，负责近中距压线与 shockwave 区域压迫
- `EnemyPhantom`：高速切入型精英，负责贴身追切、俯冲突脸和中近距节奏打断
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
- 避免把平台判断散写在玩法脚本里
- 如果删文档，先确认内容已经并入现存入口，避免再长回重复说明

## 在线与发布

- GitHub 仓库：[night-runner](https://github.com/2456018331lby-dev/night-runner)
- 在线版本：[GitHub Pages](https://2456018331lby-dev.github.io/night-runner/)
- 网页导出入口：[export_web_to_docs.bat](/C:/Users/24560/Desktop/study/gametwo/export_web_to_docs.bat)

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
