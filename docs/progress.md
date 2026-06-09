# Progress Log

## Current State - 2026-06-09

- Android debug APK 出包链路已打通：`export_presets.cfg`、Godot Android export templates、SDK / JDK / build-tools / `adb`、`NightRunner35` 模拟器均可用。
- 当前可安装包路径：`exports/android/NightRunner-debug.apk`。最近一次验证包大小为 `28,416,550` bytes，`apksigner` v2 / v3、`apkanalyzer` 包信息、模拟器安装启动均通过。
- 移动端输入已有核心护栏：触屏左右移动仲裁、暂停前清空 held / pending 输入、跳跃 buffer / coyote time、攻击长按续攻、触控按钮布局和暂停页触控高度。
- 局前行动 / 构筑面板会持续展示 route 与 directive 的真实状态；route 卡片使用 `ACTIVE` / `READY` / `LOCKED`，directive 卡片使用 `ACTIVE` / `OPTION`，选择切换时文本、选中态和边框会同步更新。
- 平台边界已收口在 `PlatformProfile`：安全区 margin、移动端 UI scale、震动支持和用户 haptics 设置都通过同一入口，不再把平台判断散到玩法或 UI 脚本。
- 玩法竖切片已有 3 条行动：`Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol`。Overdrive 已有高分阈值、后段 cashout 压力波和倍率结算护栏。
- 结果页现在会展示 `RANK REPORT`：结算时直接说明距下一等级的分差、速度/受击/危险区命中、可选目标和 cashout 得失，评分阈值由 `GameState` 统一计算。
- 当前缺口仍是真机体验：刘海屏 / 18:9 安全区、震动强度、触屏多指边界、release keystore / AAB 发布流，以及更强的视觉资产、动效、音效和实玩数值调参。

## Recent Cleanup - 2026-06-09

- 删除独立 PlatformProfile 验证场景 / 脚本 / UID，把安全区、移动端 UI scale 和震动门禁断言合并进已有 `verify_settings.tscn`，减少测试文件数量但保留覆盖。
- 清理文档里的旧 APK 大小、旧模拟器进程号和重复出包历史；这些历史证据保留在 git commit 中，当前文档只保留可继续维护的信息。
- 清理 `exports/` 下的旧截图、日志、web 导出、中间 `.pck/.idsig/.import` 文件，只保留当前 debug APK 作为本机可安装包；源码资产 `.import` 误删后已通过 Godot headless editor 重新导入恢复。
- 收敛 `SessionScreen` 的 route / directive 卡片状态格式，复用已有 `verify_pause_settings.tscn` 覆盖局前 modifier 文本、route `ACTIVE` / `READY` / `LOCKED` 和 directive `ACTIVE` / `OPTION` 切换，避免再新增单点测试文件。

## Verification Entry Points

- Android 出包契约：`scenes/tools/verify_android_export_contract.tscn`
- 设置、音量、haptics 和平台安全区：`scenes/tools/verify_settings.tscn`
- 暂停页设置触控高度：`scenes/tools/verify_pause_settings.tscn`
- 触控布局：`scenes/tools/verify_touch_controls_layout.tscn`
- 触控暂停输入清理：`scenes/tools/verify_touch_pause.tscn`
- 触控输入语义：`--script res://scripts/tools/verify_touch_input.gd`
- 玩家攻击长按：`scenes/tools/verify_player_attack_hold.tscn`
- 玩家跳跃窗口：`scenes/tools/verify_player_jump_windows.tscn`
- 动态生命 HUD：`scenes/tools/verify_dynamic_health_hud.tscn`
- Overdrive 贪分路线：`scenes/tools/verify_overdrive_greed_profile.tscn`
- 遭遇压力：`scenes/tools/verify_encounter_pressure.tscn`
- headless 音频生命周期：`scenes/tools/verify_audio_engine_shutdown.tscn`

## Documentation Rule

- `docs/progress.md` 只记录当前状态和最近有用变化，不再逐条堆每次出包流水账。
- 旧验证细节、旧 APK 大小和旧提交理由通过 git 历史追溯，不在当前维护文档里重复维护。
