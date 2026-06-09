# Maintenance Guide

这个文件给以后继续接手 `Night Runner` 的人或 AI 直接看。目标是少翻旧文档，直接知道边界、验证入口和下一步。

## 先看什么

1. [README.md](/C:/Users/24560/Desktop/study/gametwo/README.md)
2. [MAINTENANCE.md](/C:/Users/24560/Desktop/study/gametwo/MAINTENANCE.md)
3. [docs/architecture.md](/C:/Users/24560/Desktop/study/gametwo/docs/architecture.md)
4. [docs/progress.md](/C:/Users/24560/Desktop/study/gametwo/docs/progress.md)
5. [docs/backlog.md](/C:/Users/24560/Desktop/study/gametwo/docs/backlog.md)
6. [docs/exporting.md](/C:/Users/24560/Desktop/study/gametwo/docs/exporting.md)

旧设计流水账不要再新建一份；设计意图要么进 `README.md`，要么进 `docs/architecture.md` / `docs/backlog.md`。

## 当前工程判断

- 引擎：Godot 4.6
- 目标：Android APK 优先，后续扩到 PC / Steam
- 当前阶段：有中枢壳层、行动目录、局外进度、暂停设置和 Android 出包链路的竖切片
- 当前缺口：真机安全区 / 震动 / 多指触控验证、release keystore / AAB、正式视觉资产、动效、音效和实玩数值调参

## 当前游戏结构

当前有 3 条行动线路：

- `Blitz Pursuit`
- `Ghost Circuit`
- `Overdrive Protocol`

每条行动都应保留：

- 局前中枢选行动
- 局前选择 directive
- 过程中抢核心、维持连击、处理阶段增援
- 次级目标
- 撤离和可继续贪分的兑现窗口
- 成功 / 失败结果页
- 局外记录最佳分数、评级、成功次数和解锁进度

如果以后又退回“场上打怪但没有目标”，优先检查：

- `scripts/game/run_catalog.gd`
- `scripts/autoload/frontend_bridge.gd`
- `scripts/game/world.gd`
- `scripts/autoload/game_state.gd`
- `scripts/game/main.gd`
- `scenes/ui/session_screen.tscn`

## 关键边界

- `GameState`：本局状态、局外进度、成绩记录、音量 / 震动设置和存档入口
- `PlatformProfile`：平台差异入口；安全区、移动端 UI scale 和震动门禁都在这里收口
- `InputRouter`：触屏、键盘、未来手柄的统一输入层
- `FrontendBridge`：应用壳和玩法之间的流程桥接层
- `AudioEngine`：程序化音效和播放器池；headless 自动化环境不创建播放器或 WAV
- `RunCatalog`：行动目录、directive 池、次级目标和兑现规则的数据源
- `World`：按行动定义装配关卡和本局事件
- `RouteHazard`：路线机关执行器，不要把路线机关硬写回 `World`
- `Presentation`：纯视觉氛围层
- `SessionScreen`：中枢 / 结果 / 暂停产品壳
- `HUD`：局内目标、路线阶段、directive、次级目标、cashout 和短提示展示
- `TouchControls`：安卓虚拟按键和暂停入口；暂停前必须清空 `InputRouter` 的 held / pending 输入
- `Player` / 敌人脚本：只做角色行为，不管理全局状态和 UI

不要回退的手感结论：

- 攻击判定不能太窄，需要允许轻微贴脸和高度差
- 撤离门和最后几个核心不能摆得太刁钻
- 触屏攻击支持长按续攻，跳跃 / 冲刺仍保持一次性消费
- 触屏暂停前必须清空移动和动作输入，避免恢复后残留

## 修改规则

- 改系统边界：更新 `docs/architecture.md`
- 做功能：更新 `docs/progress.md`
- 新想法或未完成项：更新 `docs/backlog.md`
- 改导出 / APK / SDK：更新 `docs/exporting.md`
- 改中枢 / 结果 / UI 壳：优先经 `FrontendBridge`
- 平台判断只放 `PlatformProfile`
- 不新增依赖，除非明确需要
- 不把导出产物提交进 git
- 文档只保留当前可维护信息；旧 APK 大小、旧进程号、旧流水账交给 git 历史

## 验证入口

常用 Godot console：

```powershell
& 'C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe' --headless --path . --quit-after 3
```

按改动选择验证：

- Android preset / SDK / 包名 / 图标 / APK 路径：`scenes/tools/verify_android_export_contract.tscn`
- 设置、音量、haptics、`PlatformProfile` 安全区 / UI scale / 震动边界：`scenes/tools/verify_settings.tscn`
- 暂停页设置触控高度：`scenes/tools/verify_pause_settings.tscn`
- 运行中触控布局：`scenes/tools/verify_touch_controls_layout.tscn`
- 触控暂停输入清理和 `InputRouter` 触控语义：`scenes/tools/verify_touch_pause.tscn`
- 玩家攻击长按：`scenes/tools/verify_player_attack_hold.tscn`
- 玩家跳跃窗口：`scenes/tools/verify_player_jump_windows.tscn`
- 动态生命 HUD：`scenes/tools/verify_dynamic_health_hud.tscn`
- Overdrive 贪分路线：`scenes/tools/verify_overdrive_greed_profile.tscn`
- 遭遇压力：`scenes/tools/verify_encounter_pressure.tscn`
- headless 音频生命周期：`scenes/tools/verify_audio_engine_shutdown.tscn`

清理 / 重构前先跑相关验证；清理后至少跑受影响验证、项目加载和主场景加载。

## Android 当前证据

- `export_presets.cfg` 已有 Android preset
- Debug APK 最近验证路径：`exports/android/NightRunner-debug.apk`
- 最近验证 APK 大小：`28,416,550` bytes
- `apksigner` v2 / v3 通过
- `apkanalyzer` 确认包名 `com.nousresearch.nightrunner`、`minSdkVersion 24`、`targetSdkVersion 35`
- `NightRunner35` Android 35 模拟器安装启动通过

具体导出命令和清理规则见 [docs/exporting.md](/C:/Users/24560/Desktop/study/gametwo/docs/exporting.md)。

## 清理规则

- `exports/` 是生成目录，只保留当前 debug APK；旧截图、日志、web 导出、中间 `.pck/.idsig/.import` 可删
- 源资源旁的 Godot `.import` 不要当作垃圾删；误删会让 SVG / PNG 场景资源在 headless 加载时报错，需运行 `--headless --editor --quit` 重新导入
- 测试文件只保留未来会继续跑的护栏；单点断言优先合并进现有验证，不为每个小改动新增独立场景或孤立 `--script` 文件
- 文档不要重复记录每次出包大小和模拟器进程号
- 如果删验证文件，必须把仍有价值的断言合并进现有验证或确认已有覆盖

## GitHub

- 仓库：[night-runner](https://github.com/2456018331lby-dev/night-runner)
- 在线版本：[GitHub Pages](https://2456018331lby-dev.github.io/night-runner/)
- 当前工作分支：`hermeswork`
- GitHub MCP 当前可能返回 `Bad credentials`；可用 `git push` 和 `gh api` 作为确认路径
