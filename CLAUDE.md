# CLAUDE.md — Night Runner

给在本仓库工作的 AI 助手看的操作规约。目标：少走弯路，改动可靠，文档同步。
本文件是仓库特有约束，通用工作习惯不在这里重复。

## 项目一句话

Godot 4.6 的 2D 横版动作竖切片。**Android APK 优先**，保留 PC / Steam 扩展边界。
网页版发布在 `docs/`（GitHub Pages）。引擎版本锁定 4.6.2。

## 动手前必读（按顺序）

1. `README.md` — 玩法目标与当前内容
2. `MAINTENANCE.md` — 边界、验证入口、下一步
3. `docs/architecture.md` — 模块职责与"改 X 先跑哪个 verify"
4. `docs/progress.md` / `docs/backlog.md` — 已完成 / 待办

不要新建设计流水账文档。设计意图进 `README.md` 或 `docs/architecture.md` / `docs/backlog.md`。

## 工作方式（复用 OMC / OMX 的精华）

- 宽泛需求：先探索相关代码 + 读上面的文档，再规划，最后动手。
- 改动最小化：只解决被要求的问题，别顺手重构无关代码。
- 多文件 / 跨模块 / 调试：交给子 agent；单文件小改或查函数直接做。
- 模型路由：快速查找用 haiku，常规改动用 sonnet，架构 / 易错处用 opus。
- 无依赖任务并行；构建 / 导出 / 测试放后台跑。
- Godot / GDScript API 不确定时，先查官方文档，别凭记忆写。
- 新增功能前查 `docs/backlog.md`，避免重复已规划的工作。
- 实现与审查分两趟：改完由独立的 reviewer / verifier 视角复查，不在同一上下文里自我批准。
- 声称"完成"前核对：无遗留任务、受影响的 verify 场景真实跑过且 exit 0、证据已收集；
  跑不了要说明原因，不要假设通过。
- 清理 / 重构：先跑相关 verify 锁住现有行为，再一次只做一类修改；
  优先删除与复用，不为小问题加新抽象层。

## 架构边界（硬约束）

- **Autoload 是唯一的跨场景状态通道**，场景之间不直接引用。当前 autoload：
  - `GameState` — 局外进度、存档、设置迁移（`_merge_meta_progress`）
  - `EnemyStats` — 敌人平衡数值访问层（数据本体 `data/enemy_stats.tres`，含 inline 兜底表）
  - `PlatformProfile` — 移动 / 桌面判断、安全区 margin、UI scale、震动边界
  - `InputRouter` — 输入语义（含触控 / attack held）
  - `FrontendBridge` — 网页交互桥接
  - `AudioEngine` — 程序化音效、播放器池、headless 生命周期
- 存档读写集中在 `GameState`，别在别处直接碰存档文件。
- 三条行动线路 `Blitz Pursuit` / `Ghost Circuit` / `Overdrive Protocol` 各有独立闭环，
  改数值前读 `docs/architecture.md` 对应段落，别抹平三者差异。
- 移动端 HUD 会隐藏桌面卡片但保留压缩导航；触控目标尺寸有下限（暂停控件 56px 级）。

## 验证协议（改完必须跑，别肉眼收尾）

本项目用 `scenes/tools/verify_*.tscn` headless 回归台。**不要新造冒烟测试**——先复用已有的。

Godot 可执行文件（PATH 里没有时用绝对路径）：
```
C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe
```
跑法：`<godot> --headless --path . scenes/tools/verify_XXX.tscn`（通过=exit 0，失败=exit 1 并 push_error）。

改动 → 对应 verify（完整清单见 `docs/architecture.md` 与 `MAINTENANCE.md`）：

- 设置 / 音量 / haptics / 安全区 / UI scale / 震动边界 → `verify_settings`
- Android 导出契约（包名 / SDK / 图标 / APK 路径）→ `verify_android_export_contract`
- 暂停页触控高度 / 换行 → `verify_pause_settings`
- 运行中触控布局 / 拖出取消 → `verify_touch_controls_layout`
- 触控暂停输入清理 → `verify_touch_pause`
- 失焦自动暂停（web / 切后台）→ `verify_focus_auto_pause`
- 玩家攻击长按 → `verify_player_attack_hold`
- 玩家跳跃窗口 / coyote / 二段跳 → `verify_player_jump_windows`
- 动态生命 HUD → `verify_dynamic_health_hud`
- Overdrive 贪分路线 → `verify_overdrive_greed_profile`
- 敌人编组压力 → `verify_encounter_pressure`
- 敌人数值表（`data/enemy_stats.tres` / `EnemyStats`）→ `verify_enemy_stats`
- 行动目录（`data/run_operations.tres` / `RunCatalog`）→ `verify_run_catalog`
- run telemetry 打点（死因 / 死亡坐标 / 阶段）+ 终局幂等守卫 → `verify_run_telemetry`
- 中枢 / 暂停 / 结算右侧信息列可见性 → `verify_session_screen_panels`
- 网页门户契约（`fileSizes` 与真实包体一致、加载层 z-index）→ `verify_web_portal_bundle`
- headless 音频关闭 → `verify_audio_engine_shutdown`

跑全部：`.\run_all_verifications.ps1`（自动发现 `scenes/tools/verify_*.tscn`，失败 exit 1）。

新增回归场景时沿用现有约定：`extends Node` → `_ready()` 里跑断言收集 `failures` → `get_tree().quit(0/1)`。

两条护栏纪律：

- **不得污染存档**：验证场景一旦触发 `GameState.save_progress()` 的持久化分支，必须在测试前后快照 / 还原 `user://night_runner_save.json`（参考 `verify_pause_settings.gd`）。验证套件连续跑两次，存档 hash 必须不变。
- **不得空转**：新断言要能真的抓住缺陷——把对应修复临时改回旧行为跑一次，确认断言失败，再改回来。

新建 `.gd` 后如果缺同名 `.gd.uid`（仓库里其它脚本都有），跑一次 `<godot> --headless --path . --editor --quit` 补齐；这会触发一次全量资源重导入，正常。

## 网页导出

改动影响线上版本时，跑 `export_web_to_docs.bat` 重新导出到 `docs/`，再提交推送。别手改 `docs/` 下的构建产物（`index.wasm` / `index.pck` / `index.js` 等）。

例外是 `docs/index.html`：它是手工维护的落地页，导出脚本不会覆盖它。其中的 `fileSizes`
必须等于 `docs/index.pck` / `docs/index.wasm` 的真实字节数（Godot 用声明值算下载总量，
声明偏小会让进度条提前冲到 100% 后卡住）。`export_web_to_docs.bat` 会自动调用
`sync_web_bundle_sizes.ps1` 回填，改完跑 `verify_web_portal_bundle.tscn` 确认。

## Git

- 当前在 `hermeswork` 分支，别直接推 `main`。
- 只 stage 具体文件，不用 `git add .`。
- 破坏性操作（reset --hard / force push / 删多文件）先确认。
- 只在被明确要求时提交。

## 改完同步文档

- 架构 / 边界变化 → `docs/architecture.md`
- 进展 → `docs/progress.md`
- 新待办 → `docs/backlog.md`
