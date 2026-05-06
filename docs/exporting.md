# Exporting

## Android APK

可以。这个项目后面完全可以导出成真正可安装的安卓包，不只是“模拟手机布局”，而是标准 `APK` 或 `AAB`。

当前工程已经按 Android 优先设计输入和横竖屏策略，但本机导出还需要你在 Godot 编辑器里补这些配置：

1. 安装 Godot Android export templates
2. 配置 Android SDK / JDK / adb 路径
3. 创建 debug / release keystore
4. 在 `Project > Export` 新建 `Android` preset
5. 设置 package name、version code、屏幕方向和图标
6. 选择 `Export Project` 输出 `APK`，或输出 `AAB` 走后续商店分发

本地运行方式：

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

1. 先稳定 Windows 原型
2. 再调 Android 触屏和性能
3. 最后加 Steamworks 集成

## 现实判断

如果目标是“像真正的商业游戏”，导出只是最后一步。真正拉开观感差距的是：

1. 场景氛围和镜头语言
2. 角色动画、受击、特效、音效
3. 菜单、结算、设置、存档这些产品壳层
4. 统一美术风格，而不是继续用几何占位
