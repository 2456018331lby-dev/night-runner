# Progress Log

## 2026-06-09

### 已完成（headless 音频生命周期修复）

- 复现并定位主场景 `--headless --quit-after 3` 退出时的 ObjectDB warning：泄漏对象是 `AudioStreamWAV` / `AudioStreamPlaybackWAV`，来源于 headless 环境里的短 WAV playback 后端，而不是玩法节点未释放
- `AudioEngine` 现在只在非 headless 运行时生成程序化 WAV 和 `AudioStreamPlayer` 池；headless 自动化检查里音频播放保持 no-op，避免验证进程退出时留下播放后端引用
- 非 headless 退出时，`AudioEngine.prepare_for_shutdown()` 会停止、断开并立即释放播放器池，同时清空程序化音效缓存
- 新增 `scenes/tools/verify_audio_engine_shutdown.tscn` / `scripts/tools/verify_audio_engine_shutdown.gd`，覆盖 headless 禁音边界和 shutdown 清理契约
- 重新安装损坏的 Android SDK `platform-tools`，补齐 `build-tools;35.0.0`、`emulator` 和 Android 35 Google APIs x86_64 system image；`adb` 恢复为 `37.0.0`
- 已通过音频生命周期、玩家跳跃窗口、动态生命 HUD、设置、暂停页设置、遭遇压力、触控暂停和触控输入回归；项目和主场景 headless 加载通过，主场景 verbose 限时退出未再出现 ObjectDB leak
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；最新 APK `28,385,599` bytes，`apksigner` v2 / v3 签名和 `apkanalyzer` 包信息校验通过
- 在 `NightRunner35` Android 35 模拟器完成新 APK 安装启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回应用进程 `2818`，`dumpsys activity` 显示 `GodotAppLauncher` 为 top resumed activity

## 2026-06-06

### 已完成（跳跃输入容错）

- 给 `Player` 增加短 jump buffer：安卓触屏或键盘提前点跳时，输入会在短窗口内等待可跳状态，不会因为刚好早于落地而直接丢失
- 把离开平台后的跳跃宽限改成明确 coyote time：刚离台仍能补跳，但窗口结束后只保留一次空中跳，避免旧逻辑里“离台后无限期保留两次跳跃”的数值漏洞
- 新增 `scenes/tools/verify_player_jump_windows.tscn` / `scripts/tools/verify_player_jump_windows.gd`，覆盖提前点跳缓存、缓存消耗、coyote 过期收束和 coyote jump 后仍保留一次空中跳
- 已通过玩家跳跃窗口、动态生命 HUD、设置、暂停页设置、遭遇压力、触控暂停和触控输入回归；项目和主场景 headless 加载也通过
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；最新 APK `28,381,044` bytes，`apksigner` v2 / v3 签名和 `apkanalyzer` 包信息校验通过
- 在 `NightRunner35` Android 35 模拟器完成新 APK 安装启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回应用进程 `3139`，`dumpsys activity` 显示 `GodotAppLauncher` 为 top resumed activity

### 已完成（动态生命 HUD 护栏）

- 修复 HUD 生命显示固定 3 格的问题：现在生命 pips 会根据 `GameState.health` 和 `run_modifiers.health_bonus` 动态生成，`Blitz Pursuit` 这类带基础生命加成的路线不会再显示少一格生命
- 生命 HUD 现在也能正确处理负生命修正和异常低生命修正，最少保留 1 格显示，避免高风险 directive 或后续调表造成 UI 空行
- 受击动画改为只针对当前缺失的生命 pips 做缩放反馈，避免实际生命上限变化后动画数组和节点数量脱节
- 新增 `scenes/tools/verify_dynamic_health_hud.tscn` / `scripts/tools/verify_dynamic_health_hud.gd`，覆盖正 `health_bonus`、负 `health_bonus` 和最小 1 格兜底
- 已通过动态生命 HUD、设置、暂停页设置、遭遇压力、触控暂停和触控输入回归
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；最新 APK `28,376,497` bytes，`apksigner` v2 / v3 签名和 `apkanalyzer` 包信息校验通过
- 在 `NightRunner35` Android 35 模拟器完成新 APK 安装启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回应用进程 `3102`，`dumpsys activity` 显示 `GodotAppLauncher` 为 top resumed activity

### 已完成（移动端触控与暂停入口）

- 修复触屏左右移动的多指仲裁：`InputRouter` 现在记录左右键各自按住状态，最后按下的方向优先；松开后会恢复仍按住的另一方向，避免安卓上双指误触后角色突然停住
- 给 `TouchControls` 增加运行中暂停按钮，安卓玩家不再依赖键盘 `P` / `Esc` 才能进入暂停页
- 让 `Main` 和 `SessionScreen` 在 `SceneTree.paused` 后仍能处理输入和按钮事件，避免暂停页 Resume / Hub 被暂停状态本身冻结
- 新增 `scripts/tools/verify_touch_input.gd`，覆盖左右方向按住 / 释放仲裁和动作一次性消费逻辑
- 新增 `scenes/tools/verify_touch_pause.tscn` / `scripts/tools/verify_touch_pause.gd`，覆盖触控暂停按钮必须经 `FrontendBridge.toggle_pause()` 进入暂停态
- 已通过触控输入回归脚本、触控暂停回归场景、Godot headless 项目加载、`touch_controls.tscn` 单场景加载和 `main.tscn` 主场景加载校验
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；当时 APK `28,350,189` bytes，`apksigner` v2 / v3 签名和 `apkanalyzer` 包信息校验通过
- 在 `NightRunner35` Android 35 模拟器完成新 APK 安装启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回进程 `6716`，`dumpsys activity` 显示 `GodotAppLauncher` 为 resumed activity

### 已完成（遭遇压力预算）

- 新增 `scripts/tools/verify_encounter_pressure.gd`，扫描三条行动的初始遭遇、timeline、core、completion、cashout 和 setpiece 刷怪桶
- 给 Suppressor / Bastion / Stalker 增加同桶距离预算，避免远程锁线、冲击波封锁和垂直坠击在同一小区域同时生成
- 调整 `Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol` 中几处过密控场精英刷怪：把部分 Bastion 降级为 Runner 压力，或挪到另一段路线
- 这个脚本只约束“同一波刷怪的基础站位”，不替代真机实玩；它的目标是防止明显无解的初始叠压重新进入调表
- 已通过遭遇压力回归场景、Godot headless 项目加载、`main.tscn` 主场景加载、触控输入回归和触控暂停回归
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；最新 APK `28,358,828` bytes，`apksigner` v2 / v3 签名和 `apkanalyzer` 包信息校验通过
- 在 `NightRunner35` Android 35 模拟器完成新 APK 安装启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回进程 `2938`，`dumpsys activity` 显示 `GodotAppLauncher` 为 resumed activity

### 已完成（暂停页设置持久化）

- 给 `GameState.meta_progress` 增加 `settings`，旧存档会自动补默认 `master_volume` 和 `haptics_enabled`
- 设置迁移会修复异常旧存档里的非字典 `settings` / `ux_flags`，避免坏存档阻断启动期默认设置回填
- 新增 `GameState.set_master_volume()` / `set_haptics_enabled()`，音量立即应用到 `Master` bus，震动开关会随存档持久化
- `PlatformProfile` 现在执行震动前会同时检查平台能力和 `GameState.are_haptics_enabled()`，暂停页关闭震动后不会继续触发轻/重震动
- `SessionScreen` 暂停页的设置区从临时音量滑杆升级为可持久化的 `VOLUME` 滑杆和 `HAPTICS` 开关
- 新增 `scenes/tools/verify_settings.tscn` / `scripts/tools/verify_settings.gd`，覆盖旧存档迁移、音量夹取、AudioServer 应用和震动开关写入
- 新增 `scenes/tools/verify_pause_settings.tscn` / `scripts/tools/verify_pause_settings.gd`，覆盖暂停页会生成音量滑杆 / 震动开关，且控件变化会写回 `GameState`
- 已通过设置回归、暂停页设置回归、遭遇压力回归、触控输入回归、触控暂停回归和 `main.tscn` 主场景加载
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；最新 APK `28,371,954` bytes，`apksigner` v2 / v3 签名和 `apkanalyzer` 包信息校验通过
- 在 `NightRunner35` Android 35 模拟器完成新 APK 安装启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回进程 `3396`，`dumpsys activity` 显示 `GodotAppLauncher` 为 resumed activity

### 已完成（敌人生命闭环修复）

- 修复 `EnemySuppressor`、`EnemyBastion`、`EnemyPhantom` 的命中生命闭环：`receive_hit()` 现在会实际扣减 `current_hp`，避免玩家打到敌人但敌人无法被击败
- 给这三类敌人在 `_ready()` 中重新接上 `current_hp = max_hp` 和 `_setup_hp_bar()`，避免首次命中时血条节点为空导致运行时报错
- 给 `EnemySuppressor`、`EnemyBastion`、`EnemyPhantom` 的击败流程补回本地 `+points` 漂字反馈，使它们与 `EnemyRunner` / `EnemyStalker` 的击败读感一致
- 重新执行 Godot headless 项目加载校验，并单独加载 `enemy_suppressor.tscn`、`enemy_bastion.tscn`、`enemy_phantom.tscn`，全部通过
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；最新 APK `28,345,491` bytes，`apksigner verify --verbose --print-certs` 确认 v2 / v3 签名通过
- 用 `apkanalyzer` 确认最新 APK 包名 `com.nousresearch.nightrunner`、版本 `0.1.0`、`minSdk 24`、`targetSdk 35`
- 重新启动 `NightRunner35` Android 35 模拟器并完成安装启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回进程 `6044`，`dumpsys activity activities` 显示 `com.godot.game.GodotAppLauncher` 为 resumed activity

### 已完成（Stalker 伏击读感）

- 给 `EnemyStalker` 补专门落点预警：进入 warning 时用 physics ray 预测下方平台 / 地面，并在世界坐标固定显示坠落线和椭圆危险圈，玩家能提前判断冲击区
- 给 `EnemyStalker` 补坠击残影：plunge 阶段按短间隔生成半透明立绘残影，强调垂直下砸速度和危险方向
- 给 `AudioEngine` 增加 `stalker_impact` 程序合成重击音效，并在 Stalker 落地触发，避免精英压迫只靠 toast 和视觉脉冲成立
- 保持 Stalker 的逻辑边界不变：敌人只管理自身预警、残影、冲击表现；分数、UI 和全局流程仍留在 `World` / `GameState`
- 给玩家受击补第一版强反馈：普通命中和重击命中现在有不同短冻结、击退力度、角色白闪、受击残影和方向性碎片
- 给 `World` 的受击屏幕反馈做来源分级：Stalker 落地、Bastion shockwave、Phantom dive 和路线机关会触发更强屏幕冲击，并短暂推送 `HEAVY IMPACT` 事件 banner
- 通过 Godot headless 项目加载校验和 `enemy_stalker.tscn` 单场景加载校验
- 重新导出 `exports/android/NightRunner-debug.apk` 成功；最新 APK `28,345,491` bytes，`apksigner verify --verbose --print-certs` 确认 v2 / v3 签名通过
- 用 `apkanalyzer` 确认最新 APK 包名 `com.nousresearch.nightrunner`、版本 `0.1.0`、`minSdk 24`、`targetSdk 35` 和横屏方向配置
- 在 `NightRunner35` Android 35 模拟器完成最新 APK 安装和启动验证：`adb install -r` 成功，`monkey` 可拉起应用，`pidof` 返回进程 `6063`，`dumpsys window` 显示 Godot launcher activity 获得焦点

### 当前问题

- Stalker 的落点预警、残影和玩家受击闪白已补齐第一版，但仍缺真机画面检查、命中停顿手感调参和更完整的混音层
- 多敌人混编已有第一道脚本护栏，但仍需要继续实玩验证，尤其是移动中敌人 AI 追位后是否会再次形成无解站位；远程压制者本轮已修复可击杀性，不再应出现“打中但不掉血”的基础缺陷
- Android 模拟器可安装启动的证据已更新到 2026-06-09 APK；触控输入、暂停页设置、动态生命 HUD、玩家跳跃窗口和音频生命周期已有脚本级回归验证，但仍缺真机触屏 / 刘海屏 / 震动强度验证

### 下一步建议

- 上真机调玩家受击冻结时长、闪白强度、屏幕冲击透明度和震动强度，避免小屏上过亮或过吵
- 上真机确认暂停页 `VOLUME` / `HAPTICS` 控件尺寸和触控命中范围，尤其是刘海屏安全区与系统手势区
- 继续实玩 Stalker 与 Suppressor 的同屏节奏，重点看移动中 AI 追位和现金兑现阶段是否仍会锁死路线
- 上真机安装最新 APK，补实际画面、触控多指、刘海屏和震动强度验证证据

## 2026-06-01

### 已完成（首开即玩 / 移动端体验包）

- 把中枢首屏改成更明显的首开入口：默认仍落在 `Blitz Pursuit`，主按钮改成直接可开的 `START ...`，并增加仅首开显示的 `FIRST RUN BRIEF`
- 给 `GameState.meta_progress` 增加 `ux_flags`，现在会记录首开 brief、`Blitz Pursuit` 轻量引导四个提示点和教程完成状态；旧存档缺字段会自动补默认值
- 给 `World` 接入 `Blitz Pursuit` 轻量教程链路：开局移动提示、首次接近敌人的战斗提示、首次拿核心后的目标提示、撤离解锁后的“立即撤 / 继续 cashout”提示
- 给结果页补 `WHY / TRY NEXT / QUICK REMINDER` 信息，让首次失败后能立刻知道自己为什么崩和下一把最该改什么
- 给 `PlatformProfile` 增加移动端轻量 haptics 边界，并把按钮按下、核心收集、受击、低血、撤离解锁接到统一震动入口
- 调整触屏布局和按钮文案：左右键缩成 `L / R`，攻击改成 `ATK`，整体触控区放大并继续避让安全区/系统手势区
- 给 HUD 冲刺状态补文案，不再只靠颜色表达；移动端现在会直接显示 `DASH READY` / `DASH COOLING`
- 把 `SessionScreen` 继续收口成更像正式产品壳：Hub 首屏改成 `QUICK DEPLOY`，结果页改成 `WHY YOU LOST / TRY NEXT / RUN VERDICT / SCORE BREAKDOWN` 卡片式复盘，首次失败的 `Quick Reminder` 改成更短的一眼提示
- 给 `SessionScreen` 本身补上安全区边距读取，顶部信号条和内容壳现在会一起避让 Android 刘海/状态栏，不再只有 HUD 和触控层避让
- 首开手机 Hub 继续减负：`Blitz Pursuit` 的第一次部署会隐藏完整 directive 列表和战绩栅格，只保留默认 directive 与更明确的“直接开始”文案，避免首屏像后台配置页
- 把移动端局内 toast 上抬到触控区上方，减少提示文本压住右侧动作键和底部系统手势区的情况
- 重新通过一轮 Godot headless 加载校验
- 命令行重新导出 `exports/android/NightRunner-debug.apk` 成功；`apksigner` 验证通过 v2/v3，`aapt` 确认包名、应用名、`targetSdkVersion 35` 和传感器横屏配置正确
- 已在 Android 35 模拟器上完成安装和启动验证：`adb install -r` 成功，应用进程可拉起并保持前台焦点
- 模拟器上确认旧的 `gl_compatibility` 会打出 `Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS`；现已把 `renderer/rendering_method.mobile` 改成 `mobile`，重新导出后 Vulkan / Forward Mobile 正常启动，至少解决了已复现的 Android 渲染报错
- 2026-06-01 12:21 再次重导出 APK，并完成一轮新包安装验证；模拟器上最新进程 `pid 6199`，`logcat` 继续显示 `usesVulkan(): true`、`renderingDevice: vulkan`、`renderer: mobile`，本轮未复现旧的 shader uniform 报错

### 已完成

- 给 `EnemyStalker` 新增原创 SVG 资产，并接回场景作为主立绘；原几何节点现在只保留为底层氛围与状态发光
- 收紧 `EnemyStalker` 的再附着逻辑：不再简单找一个上方节点，而是读取 `platform` 碰撞矩形，优先选择真正能覆盖玩家路线的上方平台落点
- 确认 `World._build_platforms()` 生成的动态平台已经加入 `platform` group，前一版维护文档里的“需要确认”现在已实际验证
- 让 `EnemyStalker` 的 warning / plunge / hit / landing 状态同步驱动立绘 tint 和轻微缩放，伏击读感更接近正式敌人而不是占位图形

### 当前问题

- `EnemyStalker` 现在已有独立轮廓和更稳定的附着位；坠击残影、专门落点预警、音效层和玩家受击闪白已在 2026-06-06 补第一版，后续重点转向真机调参和混编节奏
- 战斗反馈整体仍偏视觉脉冲，命中停顿、受击闪白和音效还有继续加密空间
- 移动端安全区、振动反馈和触控区现在已经接入，但还没做真机验证和更细的多设备调优
- Android 模拟器能证明“可安装、可启动、不立即崩”，但系统截图对 Godot `SurfaceView` 取证仍不可靠，目前还缺一张可直接展示游戏内容的 Android 运行截图

### 下一步建议

- 继续给 `EnemyStalker` 和其他精英补 hit-stop 调参、混音层和危险提示联动，避免高压只靠数值成立
- 上真机验证 18:9 / 刘海屏安全区、触控布局和震动强度
- 用真机或更稳定的图像抓取路径确认 Android 实际首屏画面，顺手核对 `SessionScreen` 新的安全区与结果页层级
- 继续加强 hit-stop、受击闪白、命中特效和危险提示

## 2026-05-28

### 已完成

- 新增第五类精英敌人 `EnemyStalker`，垂直伏击型 archetype：附着平台上方蓄势，预警后坠击，落地产生冲击波区域压迫
- `EnemyStalker` 包含完整行为状态机：cling → warning → plunge → recovery → reposition 循环
- 创建 `enemy_stalker.tscn` 场景文件，包含 Body/Mask/Eye/Shadow 视觉节点和 LandingZone 冲击区域
- 把 `EnemyStalker` 接入三条行动的常驻编组：`Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol` 各有一个 Stalker 初始站位
- 把 `EnemyStalker` 接入三条行动的 timeline_events 增援波次
- 把 `EnemyStalker` 接入 `Overdrive Protocol` 的 phase_setpiece（Overdrive Collapse）增援
- 扩展 `GameState` 伤害来源摘要，结果页现在能区分 stalker slam / stalker shockwave
- 改进 HUD 冲刺冷却条：冲刺就绪时显示亮蓝色，冷却中显示暗蓝色，状态切换更明显
- 更新 `MAINTENANCE.md`，加入 `EnemyStalker` 到关键边界说明
- 创建 `hermeswork` 分支并完成 GitHub 提交

### 当前问题

- `EnemyStalker` 目前是程序化几何视觉，还没有专门的 SVG 资产
- Stalker 的"附着平台"逻辑依赖平台分组（`platform` group），当前平台是动态生成的 StaticBody2D，需要确认是否已加入 `platform` group
- 受击反馈仍主要是 toast / 抖屏层级，还缺音效
- 触屏还没做振动反馈、安全区适配和更完整的真机调优

### 下一步建议

- 给 `EnemyStalker` 做原创 SVG 资产，替换程序化几何
- 给 Stalker 的平台附着逻辑做更精确的平台搜索（当前是简单位置判断）
- 继续加强打击反馈：hit-stop 增强、受击闪白、音效
- 做移动端安全区 / 刘海屏适配，并在真机上调按钮区域

## 2026-05-23

### 已完成

- 梳理维护文档和当前工程状态，确认下一轮优先继续围绕路线辨识、反馈密度、移动端体验和导出流推进
- 给触屏按钮补拖出取消：移动键拖出会释放方向，跳跃 / 攻击 / 冲刺拖出会取消待消费动作，减少移动端误触
- 让受击提示直接使用已记录的伤害来源摘要，玩家现在能区分 phantom dive、bastion shockwave、suppressor fire、route hazard 等压力来源
- 确认后续产品方向：以 Android APK 为第一发布目标，同时持续保留 PC / Steam 扩展边界
- 给 `EnemyPhantom` 补俯冲前指向预警、蓄势环和短残影，让高速突脸从"突然撞上"变成玩家能读到的精英攻击
- 做了一轮前端观感升级：中枢 / 结果页增加战术终端镀铬边框、进入动效、动态背景脉冲，并把行动卡和 directive 卡改得更像可选战术卡片
- 给 HUD 增加分数跳动、受击闪脉冲、cashout 呼吸高亮和 toast 弹入反馈，提升局内反馈密度

### 当前问题

- 受击反馈仍主要是 toast / 抖屏层级，还缺更明确的命中特效、音效和受击演出
- `EnemyPhantom` 仍需要专门预警特效、残影和落点提示
- 触屏还没做振动反馈、安全区适配和更完整的真机调优

### 下一步建议

- 给 `EnemyPhantom` 补 windup 预警和 dive 残影，让高速突脸更可读
- 继续加强 hit-stop、受击闪白、音效和 UI 危险反馈
- 做移动端安全区 / 刘海屏适配，并在真机上调按钮区域

## 2026-05-15

### 已完成

- 新增精英敌人 `EnemyPhantom`，补上一种高速贴身压迫 archetype，能在中近距蓄势后执行横向俯冲
- 把 `EnemyPhantom` 接入三条行动的常驻与阶段增援编组，让 `Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol` 都出现更立体的精英混编压力
- 扩展 `GameState` 伤害来源摘要，结果页现在能区分 phantom slash / phantom dive 与 bastion 压迫
- 更新中枢焦点卡的 elite pressure 摘要，局前可直接看到 bastion / phantom 的路线分布
- 修正 `EnemyPhantom` 的玩法边界：受击后 dive 冷却、命中后收招、撞墙/落地提前结束 dive、接触推力兜底
- 顺手统一敌人接触推力兜底与"掉坑离场不计分"规则，避免白送分或 0 水平击退
- 把前端做成可直接看到的战术终端风格壳层，并预留后续更漂亮前端的接管边界
- 在架构文档里补前端接管约定，明确 `FrontendBridge` 是未来 UI 重做的唯一流程入口
- 开始做一轮路线逻辑和数值收束：降低 `Ghost Circuit` 的正面精英压迫，让它更像角度阅读 / 清线撤离路线；强化 `Blitz Pursuit` 的"先快清、后贪分"节奏提示
- 补了一层运行中路线气质提示，让 HUD 能直接告诉玩家这局更偏"快清贪分 / 角度阅读 / directive 适配"哪种决策逻辑
- 给 `World` 和 `Presentation` 再补一层阶段读板与事件脉冲，让 cashout / overdrive / stealth 曝光这类状态变化更容易被玩家看见
- 给撤离门补了一层 greed / overdrive 可视化，让 cashout 真正看起来像一个越来越危险的高收益出口，而不是静态终点
- 给跳板和 HUD 再补一层"高压阶段正在发生"的可见反馈，尽量减少玩家做对了但画面没告诉他的断层感
- 继续压缩战斗 HUD 的说明堆叠，把路线气质、压力和 cashout 风险更集中地塞进主阶段卡，减少"像后台控制台"那种原型感
- 给 `Overdrive Protocol` 补了第一个 boss 级 setpiece 原型：`Overdrive Collapse`，尝试把后半段从普通高压刷怪推成真正的第二阶段
- 给 HUD 补了中心事件横幅原型，准备把 `Overdrive Collapse` 这类阶段事件从"提示文本"推进到真正会压住玩家视线的转阶段信号
- 给 `Overdrive Collapse` 再补一层空间封锁原型，开始让 setpiece 真正改变玩家后半段走位，而不是只改文本和刷怪压力
- 重新通过一轮 Godot headless 加载校验

### 当前问题

- `EnemyPhantom` 目前已有轮廓、颜色反馈和俯冲节奏，但还没有专门预警特效、音效和命中演出
- 关卡里已经有 bastion + phantom 两类精英，但仍缺少真正的 boss 级节点与地形分支演出
- Android APK 仍需在 Godot 编辑器里补 export preset、SDK、keystore

### 下一步建议

- 继续给 `EnemyPhantom` 补预警视觉、残影/落点提示和更明确的受击反馈
- 再做第二类阶段记忆点：更强地形分支、Boss 级封锁事件或行动专属遭遇
- 开始补音效、设置菜单和移动端安全区适配

## 2026-05-10

### 已完成

- 新增精英敌人 `EnemyBastion`，提供蓄力 shockwave 的封锁压迫模型
- 把三条行动的敌人编组继续拉开，让部分关键阶段会出现 bastion 压线节点
- 让中枢直接提示路线中的 elite pressure 数量，让局前阅读更接近正式战术界面
- 继续扩展结果页战术回顾，补足 cashout 击杀与 clean / contested verdict
- 把 `RouteHazard` 从单一激光梁扩展成三类数据驱动机关：`pulse_beam`、`sweep_wall`、`collapse_zone`
- 给三条行动补了更有记忆点的机关组合，让 `Blitz Pursuit`、`Ghost Circuit`、`Overdrive Protocol` 在空间风险上进一步分化
- 让 `World` 持续汇总路线阶段、环境压力和 hazard 状态，并把这些信息推送给 HUD
- 让 HUD 新增路线阶段读板，结果页新增得分拆解、机关命中和成败原因回顾
- 让本局统计区分战斗分、核心分、撤离奖励、可选目标奖励和 cashout 奖励，结果页不再只剩一句总结
- 给中枢 / 结果壳补扫描线和压暗层，让整体更接近战术终端而不是原型工具页
- 新增数据驱动 `RouteHazard` 环境机关系统，并接入三条行动的不同激活阶段
- 让三条行动在"空间风险"层面出现真正差异，不再只靠敌人波次和文案区分
- 给三条行动补了更明确的 lane signal、后期阶段事件和 cashout 期间的追杀波次
- 让中枢和 HUD 直接展示 directive modifier 摘要、cashout 计时和路线打法提示
- 给玩家攻击补轻量 hit-stop 与动作闪，给敌人与投射物补更强可读性反馈
- 让场景氛围层根据 cashout 热度提升灯带、雾层和光束强度
- 把行动指令从开局随机切换成局前明确选择，给每条行动补上真正的 build 决策
- 给三条行动加入次级目标，并把目标结果接入结算
- 加入"撤离已解锁但继续留场可叠加 payout"的 cashout 风险收益循环
- 把中枢升级为更完整的战术甲板，展示行动、directive、次级目标和 cashout 情报
- 把 HUD 升级为同时展示 directive、次级目标和兑现状态
- 修正并重新通过一轮 Godot headless 加载校验
- 把启动流程从"直接进局"重构成"中枢选行动 -> 开始行动 -> 结果页 / 暂停"
- 新增 `RunCatalog`，把单一固定跑图升级成 3 条行动线路
- 把三种玩法气质收敛成一套竖切片：
  - `Blitz Pursuit` 偏高速追逃
  - `Ghost Circuit` 偏潜入夺取撤离
  - `Overdrive Protocol` 偏轻 Rogue 指令变体
- 新增 `FrontendBridge` 作为前端 / 产品壳和玩法层的桥接接口
- 扩展 `GameState` 为本局状态 + 局外进度 + 存档中心
- 新增本地存档，记录已解锁行动、最佳成绩、行动记录和成功率
- 重构 `World` 为按行动定义装配平台、敌人、核心、跳板和阶段事件
- 重构 HUD，加入行动上下文、指令信息和更完整的任务展示
- 新增中枢/结果/暂停壳层 `SessionScreen`
- 让 `Presentation` 支持按行动主题换色
- 完成一次大改后的 Godot headless 加载校验

### 当前问题

- 观感已经比原型完整很多，但仍未达到"高端商业成品"的特效密度
- 行动路线虽然已经有多类机关和首个精英封锁敌人，但仍缺少真正的分支地形、更多精英 archetype 和 boss 级记忆点
- 还没有标题动效、音效、命中停顿、敌人预警特效和设置菜单
- Android APK 仍需在 Godot 编辑器里补 export preset、SDK、keystore

### 下一步建议

- 给每条行动继续补更强的地形分支、第二类精英敌人与更明确的阶段演出
- 做打击反馈、镜头语言、音效和命中停顿
- 继续提升中枢和结果页美术层级，补设置、图标系统和移动端安全区
- 接 Android 导出 preset，并开始真机触控调优

## 2026-05-06

### 已完成

- 加入第二类敌人 `EnemySuppressor`
- 加入远程投射物 `EnemyBolt`
- 把 `World` 刷怪从单一追击者改成混合编组
- 更新维护文档和架构说明，明确远程敌人与投射物边界
- 完成一次新增敌人后的 Godot headless 加载校验
- 重做 HUD 视觉层级和移动端触屏布局，替换掉默认按钮/裸文本风格
- 增加城市天际线、雾层、霓虹灯带和基础镜头冲击感，缩小"占位原型"和"正式游戏感"的差距
- 新增原创 SVG 角色资产并接入玩家、追击者、压制者场景
- 新增情报核心、撤离门、连击与评级结算，把玩法从"打几只怪"升级成有明确目的的短局闭环
- 去掉碍眼的中部常驻提示，改成任务卡 + 底部短提示，并加入跳板和核心后增援来提升节奏变化
- 放宽攻击判定、拉长终点段并补更多核心/平台/敌人，修正"打不到、撤不走、内容太少"的问题

### 当前问题

- 远程敌人还没有动画、音效和预警特效
- 关卡没有终点、结算和进度保存
- Android 导出仍需要本机补充 SDK/keystore 配置
- 标题页、暂停、失败页和音效还没补齐

### 下一步建议

- 给双敌人编组补更明确的节奏和地形段落
- 做打击反馈、命中停顿、音效和镜头表现
- 增加标题页、失败页和完整结果页

## 2026-05-03

### 已完成

- 创建 `Night Runner` Godot 4.6 项目
- 定义安卓优先、PC 可扩展的系统边界
- 搭建 `GameState`、`PlatformProfile`、`InputRouter`
- 实现首版玩家移动、跳跃、冲刺、攻击
- 实现敌人追击、受击、落坑死亡和接触伤害
- 实现 HUD、计时、重开和触屏按键
- 编写导出、架构、设计和待办文档
- 完成一次 Godot headless 加载校验

### 当前问题

- 还有较多占位几何和占位视觉
- 还没有完整音效、特效、动画状态机
- Android debug APK 已可导出，后续 release 版仍需要正式签名、图标、真机兼容性测试

## 2026-05-23 APK 竖切片进展

- 已成功导出 `exports/android/NightRunner-debug.apk`，约 27 MB，签名验证通过 v2/v3。
- Android SDK 使用 `C:/Users/24560/Desktop/study/Englishdemo/.android-sdk`，JDK 使用 `C:/Program Files/Java/jdk-17`。
- 开启 `rendering/textures/vram_compression/import_etc2_astc=true` 后解决 Godot Android 导出空白 configuration error。
- 新增 HUD `ROUTE VECTOR` 导航卡，运行中指向最近数据核心，收齐后指向撤离门，提升移动端路线清晰度。

### 下一步建议

- 加入第二类敌人和一个追逐关卡段落
- 做打击反馈和摄像机抖动
- 补存档与关卡解锁
