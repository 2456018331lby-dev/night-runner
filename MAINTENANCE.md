# Maintenance Guide

这个文件给以后继续接手 `Night Runner` 的人或 AI 直接看。

## 先看什么

1. [README.md](/C:/Users/24560/Desktop/study/gametwo/README.md)
2. [docs/architecture.md](/C:/Users/24560/Desktop/study/gametwo/docs/architecture.md)
3. [docs/progress.md](/C:/Users/24560/Desktop/study/gametwo/docs/progress.md)
4. [docs/backlog.md](/C:/Users/24560/Desktop/study/gametwo/docs/backlog.md)

## 当前工程判断

- 引擎：Godot 4.6
- 目标：Android 优先，后续扩到 PC / Steam
- 当前阶段：双敌人可玩原型，不是内容版

## 关键边界

- `GameState`：本局状态和未来元进度入口
- `PlatformProfile`：平台差异入口
- `InputRouter`：触屏、键盘、未来手柄的统一输入层
- `World`：关卡容器和本局流程
- `Presentation`：纯视觉氛围层，负责背景城市、雾、灯带和后续环境演出
- `Player` / `EnemyRunner` / `EnemySuppressor`：只做角色行为，不管理全局状态
- `EnemyBolt`：远程敌人的轻量投射物，不接 UI 和分数

## 继续开发的顺序

1. 先做打击反馈和镜头表现
2. 再做关卡终点和结算
3. 再补双敌人节奏和地形段落
4. 最后接存档、设置、Steam 抽象层

## 修改规则

- 改系统边界：先更 `docs/architecture.md`
- 做功能：完工后更 `docs/progress.md`
- 新想法：先进 `docs/backlog.md`
- 避免把平台判断散写在玩法脚本里

## 已验证

- `Godot_v4.6.2-stable_win64_console.exe --headless --path C:\\Users\\24560\\Desktop\\study\\gametwo --quit-after 3`
- 结果：项目可加载，脚本可解析
- 2026-05-06：新增 `EnemySuppressor` / `EnemyBolt` 后再次执行同一命令，结果通过
