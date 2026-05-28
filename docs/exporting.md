# Exporting

## Android APK

目标改成 APK 是对的，这个项目应该优先走“本机可安装包”而不是只停留在网页导出。

当前状态：

- 已有 `Android` export preset（见 `export_presets.cfg`）
- 本机已安装 Godot Android export templates（`android_debug.apk` / `android_release.apk` 模板存在）
- Godot headless 加载校验已通过，命令行要使用 Winget 安装的 console exe 完整路径
- 已成功导出 `exports/android/NightRunner-debug.apk`；APK 约 27 MB，签名验证通过 v2/v3
- Godot 当前使用 Android SDK：`C:/Users/24560/Desktop/study/Englishdemo/.android-sdk`

重新导出 APK 的步骤：

1. 确认 Godot Editor Settings：Android SDK 指向 `C:/Users/24560/Desktop/study/Englishdemo/.android-sdk`
2. 确认 Godot Editor Settings：JDK 指向 `C:/Program Files/Java/jdk-17`
3. 确认 `project.godot` 开启 `rendering/textures/vram_compression/import_etc2_astc=true`
4. 用 `Project > Export > Android` 导出 `APK`，或在命令行重试：
   `"C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe" --headless --path "C:/Users/24560/Desktop/study/gametwo" --export-debug "Android" "C:/Users/24560/Desktop/study/gametwo/exports/android/NightRunner-debug.apk"`

建议本机目标路径：

- SDK：`C:\\Users\\24560\\AppData\\Local\\Android\\Sdk`
- APK 输出：`exports/android/NightRunner-debug.apk`

如果以后 AI 接手，要先检查：

1. `export_presets.cfg` 里是否已有 Android preset
2. `C:\\Users\\24560\\AppData\\Roaming\\Godot\\export_templates\\4.6.2.stable\\android_debug.apk` 是否存在
3. `adb` / SDK / JDK 是否能在 Windows 侧找到
4. Godot Editor 的 Android export 设置是否已保存

当前工程已经按 Android 优先设计输入和横竖屏策略，不需要再从 0 重做移动端交互边界。

1. 双击 [open_editor.bat](/C:/Users/24560/Desktop/study/gametwo/open_editor.bat) 打开工程
2. 双击 [run_game.bat](/C:/Users/24560/Desktop/study/gametwo/run_game.bat) 直接试玩
3. 需要命令行自检时可运行：
   `Godot_v4.6.2-stable_win64_console.exe --headless --path C:\\Users\\24560\\Desktop\\study\\gametwo --quit-after 3`

安卓导出不是“调用一个脚本按钮”就结束，而是做完 `Export Preset` 后，在 Godot 导出面板里出包。

## GitHub Pages 在线部署

当前项目已经可以导出 Web 版本。

1. 运行 [export_web_to_docs.bat](/C:/Users/24560/Desktop/study/gametwo/export_web_to_docs.bat)
2. 确认 `docs/` 下生成 `index.html`、`index.js`、`index.wasm` 等文件
3. 提交并推送到 GitHub
4. 在仓库设置里启用 Pages，来源选 `main` 分支的 `/docs`

建议包名：

- `com.yourstudio.nightrunner`

## Windows / Steam

PC 版导出路径建议：

- `exports/windows/NightRunner.exe`

Steam 接入时建议保持以下边界：

- Steam 成就和云存档只通过独立服务层接入
- 不在 `player.gd`、`enemy_runner.gd` 中直接写平台 SDK 调用

## 构建顺序建议

1. 先稳定可玩的 Godot 竖切片，不让玩法脚本绑定单一平台
2. 优先打通 Android APK：SDK、adb、keystore、触屏、安全区和性能
3. 保持 Windows 桌面包可运行，给 PC 试玩和后续 Steam 页面素材留出口
4. 最后加 Steamworks 集成，成就、排行榜、云存档都走独立服务层

## 现实判断

如果目标是“像真正的商业游戏”，导出只是最后一步。真正拉开观感差距的是：

1. 场景氛围和镜头语言
2. 角色动画、受击、特效、音效
3. 菜单、结算、设置、存档这些产品壳层
4. 统一美术风格，而不是继续用几何占位

## 当前 APK 预留目标

- 目标不是只保留 Web 版，而是以 `APK` 为主、Web 为辅
- 后续优先把 Android SDK / adb / keystore 配好，形成稳定出包流
- 维护者接手时，先修环境，再导出，不要先改玩法后才发现无法出包
- 当前已确认：Godot Android export templates 存在，工程内已有 Android export preset；当前缺口主要是 Windows 侧 Android SDK / adb / Gradle
