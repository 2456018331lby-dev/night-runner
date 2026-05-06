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
- 当前阶段：有明确目标回路的可玩原型，不是内容版

## 这个游戏现在在干嘛

当前短局闭环是：

1. 出生后一路前进
2. 抢走 3 个 `DataCore`
3. 过程中用近战击落敌人维持 `combo`
4. 数据核心拿齐后解锁 `ExtractionGate`
5. 选择继续刷分，或者立刻撤离结算评级

如果以后 AI 接手时发现又变回“场上打怪但没有目标”，优先检查：

- `scripts/game/world.gd`
- `scripts/autoload/game_state.gd`
- `scenes/game/data_core.tscn`
- `scenes/game/extraction_gate.tscn`

## 关键边界

- `GameState`：本局状态和未来元进度入口
- `PlatformProfile`：平台差异入口
- `InputRouter`：触屏、键盘、未来手柄的统一输入层
- `World`：关卡容器和本局流程
- `Presentation`：纯视觉氛围层，负责背景城市、雾、灯带和后续环境演出
- `DataCore` / `ExtractionGate`：短局目标层，负责“为什么要继续跑”
- `Player` / `EnemyRunner` / `EnemySuppressor`：只做角色行为，不管理全局状态
- `EnemyBolt`：远程敌人的轻量投射物，不接 UI 和分数

## 当前资产判断

- 角色和关键目标物已有首批原创 SVG 资产
- 背景氛围层已存在，但仍是程序化几何主导
- 还没有正式音效、命中特效、标题页美术、完整 UI 图标系统

不要在后续迭代里重新回到“纯色方块 + 默认按钮”状态。

## 继续开发的顺序

1. 先补双敌人节奏和地形段落
2. 再做打击反馈、音效和特效
3. 再做标题页、失败页和暂停/设置
4. 最后接存档、Steam 抽象层和正式关卡结构

## 修改规则

- 改系统边界：先更 `docs/architecture.md`
- 做功能：完工后更 `docs/progress.md`
- 新想法：先进 `docs/backlog.md`
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

- `Godot_v4.6.2-stable_win64_console.exe --headless --path C:\\Users\\24560\\Desktop\\study\\gametwo --quit-after 3`
- 结果：项目可加载，脚本可解析
- 2026-05-06：新增 `EnemySuppressor` / `EnemyBolt` 后再次执行同一命令，结果通过
- 2026-05-06：新增 `DataCore` / `ExtractionGate` / 结算逻辑后再次执行同一命令，结果通过
