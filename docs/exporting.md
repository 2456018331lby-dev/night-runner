# Exporting

## Android APK

这个项目优先维护 Android APK，而不是只停留在 Web 导出。

当前状态：

- Android preset 已存在：`export_presets.cfg`
- APK 输出路径：`exports/android/NightRunner-debug.apk`
- Godot Android export templates 已安装
- 当前 SDK：`C:/Users/24560/Desktop/study/Englishdemo/.android-sdk`
- 当前 JDK：`C:/Program Files/Java/jdk-17`
- 当前验证过的 APK：`28,416,550` bytes，包名 `com.nousresearch.nightrunner`，`versionName 0.1.0`，`minSdkVersion 24`，`targetSdkVersion 35`
- 当前模拟器验证：`NightRunner35` Android 35 可安装并启动到 `com.godot.game.GodotAppLauncher`

导出前先跑：

```powershell
& 'C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe' --headless --path . scenes/tools/verify_android_export_contract.tscn
```

重新导出 debug APK：

```powershell
& 'C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe' --headless --path . --export-debug Android exports/android/NightRunner-debug.apk
```

签名和 manifest 校验：

```powershell
$Sdk = 'C:/Users/24560/Desktop/study/Englishdemo/.android-sdk'
& "$Sdk/build-tools/35.0.0/apksigner.bat" verify --verbose --print-certs exports/android/NightRunner-debug.apk
& "$Sdk/cmdline-tools/latest/bin/apkanalyzer.bat" manifest application-id exports/android/NightRunner-debug.apk
& "$Sdk/cmdline-tools/latest/bin/apkanalyzer.bat" manifest min-sdk exports/android/NightRunner-debug.apk
& "$Sdk/cmdline-tools/latest/bin/apkanalyzer.bat" manifest target-sdk exports/android/NightRunner-debug.apk
```

安装启动验证：

```powershell
$Sdk = 'C:/Users/24560/Desktop/study/Englishdemo/.android-sdk'
$Adb = "$Sdk/platform-tools/adb.exe"
& $Adb install -r exports/android/NightRunner-debug.apk
& $Adb shell monkey -p com.nousresearch.nightrunner -c android.intent.category.LAUNCHER 1
& $Adb shell pidof com.nousresearch.nightrunner
```

## Export Artifact Policy

- `exports/` 是生成目录，已在 `.gitignore` 中忽略。
- 平时只保留当前可安装的 `exports/android/NightRunner-debug.apk`。
- `exports/` 里的旧截图、日志、web 导出、中间 `.pck`、`.idsig` 和 `.import` 都可以删除；需要时重新导出。
- `assets/`、`docs/` 或项目根目录里与源资源同名的 Godot `.import` 文件不要当作垃圾删；它们虽然被 git 忽略，但 headless 场景加载依赖这些导入元数据。误删后先运行一次 `--headless --editor --quit` 重新导入资源。
- 不要把导出产物提交进仓库。

## Web / Pages

Web 版仅作为辅助展示：

1. 运行 [export_web_to_docs.bat](/C:/Users/24560/Desktop/study/gametwo/export_web_to_docs.bat)
2. 确认 `docs/index.html`、`docs/index.js`、`docs/index.wasm` 更新
3. 提交并推送到 GitHub Pages 分支策略对应位置

## Remaining Release Work

- 接 release keystore
- 增加 AAB 发布流
- 真机验证刘海屏 / 18:9 安全区、震动强度、多指触控和性能
- Windows / Steam 后续单独维护，不要把平台 SDK 调用写进角色脚本
