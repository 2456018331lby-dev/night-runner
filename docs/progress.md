# Progress Log

## Current State - 2026-06-09

- Android debug APK 出包链路已打通：`export_presets.cfg`、Godot Android export templates、SDK / JDK / build-tools / `adb`、`NightRunner35` 模拟器均可用。
- 当前可安装包路径：`exports/android/NightRunner-debug.apk`。最近一次验证包大小为 `28,416,550` bytes，`apksigner` v2 / v3、`apkanalyzer` 包信息、模拟器安装启动均通过。
- 移动端输入已有核心护栏：触屏左右移动仲裁、触摸 index 级拖出取消和同按钮接管、暂停/隐藏触控层时清空 held / pending 输入和按钮 pressed 状态、跳跃 buffer / coyote time、攻击长按续攻、触控按钮布局和暂停页触控高度。
- 移动端 HUD 会把阶段压力摘要和可选目标短状态压缩进导航卡第二行，cashout 卡会保留 live hazard 短状态；即使隐藏桌面版 `PhaseCard` / `SecondaryCard`，阶段事件、cashout 压力、hazard 状态和 optional 目标进度也不会在安卓布局里丢失。
- 局前行动 / 构筑面板会持续展示 route 与 directive 的真实状态；route 卡片使用 `ACTIVE` / `READY` / `LOCKED`，移动端还显示 `BEST` / `RANK` / `RUNS` 短记录，directive 卡片使用 `ACTIVE` / `OPTION`，选择切换时文本、选中态和边框会同步更新。
- 移动端暂停 / 结算面板的长说明会自动换行；`Why:`、`Try next:` 和可选目标说明不会在窄屏上横向挤出左侧栏。
- 平台边界已收口在 `PlatformProfile`：安全区 margin、移动端 UI scale、震动支持、用户 haptics 设置和轻震/警告震动节流都通过同一入口，不再把平台判断散到玩法或 UI 脚本。
- 玩法竖切片已有 3 条行动：`Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol`。三条行动都有独立 `phase_setpiece` 阶段横幅 / 压力文案和 24 秒后的 late cashout 压力波，Overdrive 另有高分阈值和倍率结算护栏。
- 可选目标状态会直接显示剩余 / 超时时间、剩余分数和 no-hit 破损 hit 数；Blitz 的 `Shock Exit` 文案与 00:58 目标时间保持一致。
- 结果页现在会展示 `RANK REPORT`：结算时直接说明距下一等级的分差、速度/受击/危险区命中、可选目标和 cashout 得失，评分阈值由 `GameState` 统一计算。
- 当前缺口仍是真机体验：刘海屏 / 18:9 安全区、震动强度、触屏多指边界、release keystore / AAB 发布流，以及更强的视觉资产、动效、音效和实玩数值调参。

## Verification Entry Points

- Android 出包契约：`scenes/tools/verify_android_export_contract.tscn`
- 设置、音量、haptics 和平台安全区：`scenes/tools/verify_settings.tscn`
- 暂停页设置触控高度：`scenes/tools/verify_pause_settings.tscn`
- 触控布局：`scenes/tools/verify_touch_controls_layout.tscn`
- 触控暂停输入清理和 InputRouter 触控语义：`scenes/tools/verify_touch_pause.tscn`
- 玩家攻击长按：`scenes/tools/verify_player_attack_hold.tscn`
- 玩家跳跃窗口：`scenes/tools/verify_player_jump_windows.tscn`
- 动态生命 HUD：`scenes/tools/verify_dynamic_health_hud.tscn`
- Overdrive 贪分路线：`scenes/tools/verify_overdrive_greed_profile.tscn`
- 遭遇压力：`scenes/tools/verify_encounter_pressure.tscn`
- headless 音频生命周期：`scenes/tools/verify_audio_engine_shutdown.tscn`

## Documentation Rule

- `docs/progress.md` 只记录当前状态和最近有用变化，不再逐条堆每次出包流水账。
- 旧验证细节、旧 APK 大小和旧提交理由通过 git 历史追溯，不在当前维护文档里重复维护。
