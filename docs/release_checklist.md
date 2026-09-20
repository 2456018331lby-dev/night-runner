# Night Runner Release Checklist

本文档追踪从当前状态到正式发布的所有关键任务。

## 第一阶段：Web 版 itch.io 发布（Week 1-3）

### 技术准备（Week 1）

- [x] **竖屏提示实现** - `scripts/game/main.gd` 的 `_build_rotate_prompt()` 在移动端宽高比 < 1.2 时覆盖 `ROTATE YOUR DEVICE` 遮罩（待真机浏览器确认）
  - [x] 在 main.gd 或 session_screen.gd 加入 viewport 检测
  - [x] 宽高比 < 1.2 时显示 "ROTATE YOUR DEVICE" overlay
  - [x] 监听 window resize 实时切换

- [x] **run telemetry 打点补全** - `GameState.finish_run()` 聚合 `_build_run_telemetry()`，经 `JavaScriptBridge.eval` 输出到 console；护栏 `verify_run_telemetry.tscn`
  - [x] 修复 world.gd `_on_player_fell` 跳过 register_damage_source
  - [x] 在 GameState.finish_run() 加入 _build_run_telemetry()
  - [x] Web 层通过 JavaScriptBridge 输出到 console
  - [ ] 剩余：web 侧 telemetry 收集与上报（目前只 `console.log`，没有落库或分析端点）

- [x] **iframe 键盘焦点改善** - `docs/index.html` 补上画布 `tabIndex`、任意首次交互聚焦、窗口重新获得焦点 / 切回页签重新聚焦
  - [x] docs/index.html 加入首次点击提示
  - [x] 首次点击后隐藏提示并聚焦 canvas
  - [ ] 剩余：itch 草稿页 iframe 内真机确认

- [x] **音频首次手势解锁** - 任意首次交互（pointerdown / touchstart / keydown）都走同一条激活路径并聚焦画布，满足浏览器自动播放策略
  - [x] 检查 audio_engine.gd 的 web 移动端音频解锁逻辑
  - [x] 补全缺失的首次触摸解锁
  - [ ] 剩余：真机浏览器（iOS Safari / Android Chrome）确认音频可播

- [x] **批量验证自动化** - 根目录 `run_all_verifications.ps1` 自动发现并逐个 headless 跑 `scenes/tools/verify_*.tscn`（当前 17 个场景全绿）
  - [x] 创建 run_all_verifications.ps1
  - [x] 遍历所有 verify_*.tscn，汇总报告
  - [x] 验证所有现有回归测试通过

- [x] **网页包体尺寸同步** - `sync_web_bundle_sizes.ps1` 由 `export_web_to_docs.bat` 自动调用，回填 `docs/index.html` 的 `fileSizes`；护栏 `verify_web_portal_bundle.tscn`
  - [x] 修正 `index.pck` 声明值（273,848 → 18,393,444，此前进度条会在 pck 刚开始下载时冲到 100% 后卡住）
  - [x] 加载层 `#status` z-index 提到焦点提示之上
  - [x] 进度百分比夹取到 0-100

### itch.io 上架（Week 1-2）

- [ ] **导出与打包**
  - [ ] 运行 export_web_to_itch.bat
  - [ ] 确认生成 exports/itch/night-runner-web.zip
  - [ ] 验证 zip 内容（index.html/js/wasm/pck，无 .import）

- [ ] **创建 itch.io 项目页**
  - [ ] 注册/登录 itch.io 账号
  - [ ] 创建新项目：Night Runner
  - [ ] 上传 zip，配置：
    - Kind: HTML
    - Viewport: 1280x720
    - Mobile friendly: ✓
    - Fullscreen button: ✓
    - SharedArrayBuffer: ✗

- [ ] **草稿页真机验证**
  - [ ] 桌面浏览器：键盘输入、音效播放、iframe 焦点
  - [ ] 手机浏览器：触控按钮、音频解锁、竖屏提示
  - [ ] 平板浏览器：横屏布局、安全区

- [ ] **商店素材准备** - 负责人：Agent a4bacb44deeb52937（进行中）
  - [ ] 检查 assets/art/ 现有资产
  - [ ] 准备 store_content.md（描述文案）
  - [ ] 列出需要截取的 5 个关键场景

### 公开发布与反馈（Week 2-3）

- [ ] **发布到公开页**
  - [ ] 填写商店页面描述（基于 store_content.md）
  - [ ] 设置标签：Action, Platformer, Cyberpunk, 2D, Fast-Paced, Mobile
  - [ ] 价格：Free / Name Your Price
  - [ ] 切换到公开状态

- [ ] **社交媒体推广**
  - [ ] Reddit r/godot：发布帖 + 30秒 GIF
  - [ ] Reddit r/IndieGaming：同上
  - [ ] Twitter #screenshotsaturday
  - [ ] Discord (Godot / gamedev 服务器)

- [ ] **收集反馈（目标：100+ 玩家）**
  - [ ] 核心循环理解度
  - [ ] 三条路线差异感知
  - [ ] 移动端触控手感
  - [ ] 难度曲线
  - [ ] 手感爽快度

- [ ] **快速迭代（1-2 版本）**
  - [ ] 基于反馈调整 enemy_stats.tres
  - [ ] 调整 cashout 波次压力
  - [ ] 调整 hit-stop / slow-mo 强度
  - [ ] 重新导出上传，版本号递增

---

## 第二阶段：Android 正式发布（Week 4-6）

### Release 签名（Week 4）

- [ ] **生成 keystore**
  - [ ] 运行 keytool 生成 night-runner-release.keystore
  - [ ] 密码和 alias 记录到安全位置
  - [ ] keystore 路径加入 .gitignore

- [ ] **配置 export preset**
  - [ ] export_presets.cfg 新增 "Android Release" preset
  - [ ] 填入 keystore 路径、alias、密码
  - [ ] 导出路径：exports/android/NightRunner-release.aab

- [ ] **验证 AAB**
  - [ ] 导出 release AAB
  - [ ] bundletool 构建 universal APK
  - [ ] 真机安装验证签名

### 真机验证（Week 4-5）

- [ ] **刘海屏与安全区**
  - [ ] 小米/华为/三星真机测试
  - [ ] 检查触控按钮、暂停、HUD 是否遮挡
  - [ ] 调整 PlatformProfile safe_area_margin
  - [ ] 跑 verify_settings.tscn

- [ ] **震动强度**
  - [ ] 真机测试轻震（拾取、攻击）
  - [ ] 真机测试警告震动（受击、cashout）
  - [ ] 调整 vibrate_light_ms / vibrate_warning_ms
  - [ ] 确认 haptics 开关生效

- [ ] **多指触控**
  - [ ] 同时按住移动+跳跃+攻击+冲刺
  - [ ] 验证拖出取消、同按钮接管
  - [ ] 跑 verify_touch_pause.tscn

- [ ] **性能验证**
  - [ ] 开启 Godot 性能监控
  - [ ] 检查敌人密集波次是否掉帧
  - [ ] 优化瓶颈（afterimage / 粒子 / draw calls）

### Google Play 发布（Week 5-6）

- [ ] **商店素材**
  - [ ] 应用图标 512x512
  - [ ] Feature Graphic 1024x500
  - [ ] 截图 5 张（基于 store_content.md 计划）
  - [ ] 视频预告片 30 秒（可选）

- [ ] **商店文案**
  - [ ] 短描述（80 字中文）
  - [ ] 长描述（4000 字中文）
  - [ ] 分类：Action / Arcade
  - [ ] 年龄分级：12+

- [ ] **内部测试轨道**
  - [ ] Google Play Console 创建应用
  - [ ] 上传首个 AAB 到内部测试
  - [ ] 邀请 5-10 人测试
  - [ ] 收集崩溃报告、ANR
  - [ ] 修复阻塞问题

- [ ] **推送生产轨道**
  - [ ] 内部测试无阻塞问题后
  - [ ] 提交审核
  - [ ] 等待上架（通常 1-3 天）

---

## 第三阶段：核心体验打磨（Month 3-4）

### 数值平衡（持续）

- [ ] **基于 telemetry 分析**
  - [ ] 统计死因分布
  - [ ] 识别死亡率突增阶段
  - [ ] 分析 cashout overstay 时长

- [ ] **调整敌人数值**
  - [ ] 修改 data/enemy_stats.tres
  - [ ] 调整 RunCatalog 敌人编组
  - [ ] 跑 verify_enemy_stats.tscn

- [ ] **三条路线差异化强化**
  - [ ] Blitz：增加 boost pad 密度
  - [ ] Ghost：增加隐蔽路径提示
  - [ ] Overdrive：提高 score threshold

- [ ] **directive 平衡**
  - [ ] 统计 directive 选择率和胜率
  - [ ] 调整过强/过弱修正值

### 手感与演出（Month 3）

- [ ] **hit-stop / slow-mo 调优**
  - [ ] 基于反馈调整时长和 time_scale
  - [ ] 考虑改为连击≥5 触发
  - [ ] 增加可选强度设置

- [ ] **镜头 kick 与前瞻**
  - [ ] 调整偏移量和恢复速度
  - [ ] 调整纵向前瞻 lerp 权重

- [ ] **敌人预警与演出**
  - [ ] EnemySuppressor：枪口充能光效
  - [ ] EnemyBastion：地面裂纹
  - [ ] EnemyStalker：坠击碎片和屏幕震动
  - [ ] EnemyPhantom：俯冲残影密度

### 视觉资产替换（Month 3-4）

- [ ] **角色与敌人美术**
  - [ ] 玩家：分层精灵（头/身/四肢）
  - [ ] 敌人：统一赛博朋克风格
  - [ ] 使用 AI 生成或外包

- [ ] **UI 与 HUD 品牌化**
  - [ ] 统一 typography（等宽终端字体）
  - [ ] 图标系统（生命、分数、时间、连击）
  - [ ] HUD 卡片动效

- [ ] **环境与氛围层**
  - [ ] 远景天际线细节（飞行器、广告牌）
  - [ ] 前景雾层随 phase 切换
  - [ ] 地面反光与雨滴粒子

---

## 第四阶段：工程健壮性（Month 5-6）

### 代码质量（Week 1-2）

- [ ] **RunCatalog 数据外化** - 负责人：Agent aaa97f9fa456365f3（进行中）
  - [ ] 创建 RunOperationData Resource
  - [ ] 迁移到 data/run_operations.tres
  - [ ] 重构为加载层 + 兜底表
  - [ ] 创建 verify_run_catalog.tscn

- [ ] **内存泄漏修复** - 负责人：Agent a3a511d4d95d6a7a2（进行中）
  - [ ] 修复 world.gd 敌人/核心/平台清理
  - [ ] 修复 audio_engine.gd 播放器池泄漏
  - [ ] 修复敌人投射物/特效清理

- [ ] **性能优化** - 负责人：Agent a3a511d4d95d6a7a2（进行中）
  - [ ] 优化 world.gd _process() 热点
  - [ ] 减少敌人脚本 get_node() 调用
  - [ ] HUD 只在数据变化时更新文本

- [ ] **前端桥接协议测试**
  - [ ] 为 FrontendBridge 信号/方法新增单元测试
  - [ ] 覆盖 phase 切换、operation 选择、pause/resume

### PC 扩展基础（Week 3-8）

- [ ] **键位重绑定**
  - [ ] GameState 加入 key_bindings 字典
  - [ ] 创建 KeybindingsScreen
  - [ ] 动态修改 InputMap

- [ ] **手柄支持**
  - [ ] InputRouter 加入 joy_axis / joy_button 检测
  - [ ] 支持 Xbox / PlayStation / Switch Pro
  - [ ] 手柄连接时自动隐藏触控按钮

- [ ] **设置菜单扩展**
  - [ ] 从暂停页升级为独立 SettingsScreen
  - [ ] 新增：主音量、音效、音乐、震动强度、触控模式、画质
  - [ ] 设置实时预览

- [ ] **Steam 集成准备**
  - [ ] 接入 GodotSteam 插件
  - [ ] 实现成就映射
  - [ ] 实现排行榜
  - [ ] 实现云存档同步

---

## 第五阶段：内容扩展（Month 7+，长期）

### 新关卡（每月 1 个）

- [ ] **三段式城市追逐 - 关卡 1**
  - [ ] 设计：街道层（boost pad 密集）
  - [ ] 在 RunCatalog 新增 operation
  - [ ] 测试与平衡

- [ ] **三段式城市追逐 - 关卡 2**
  - [ ] 设计：高架层（垂直空间）
  - [ ] 新增 Stalker / Phantom 主导编组

- [ ] **三段式城市追逐 - 关卡 3**
  - [ ] 设计：天台层（狭窄平台）
  - [ ] 新增 Bastion 封锁 + 多重 hazard

### 新敌人（每季度 1-2 种）

- [ ] **盾兵（Shielder）**
  - [ ] 机制：正面无效，背后/冲刺破盾
  - [ ] 美术：持盾机器人
  - [ ] 数值：高 hp，低速，盾破眩晕

- [ ] **俯冲兵升级（Diver+）**
  - [ ] 增加俯冲后地面冲击波
  - [ ] 增加俯冲可被击退打断

- [ ] **Boss**
  - [ ] 多阶段血条
  - [ ] 第一阶段：召唤小怪
  - [ ] 第二阶段：扇形弹幕 + 冲击波
  - [ ] 第三阶段：全屏 hazard + 伏击

### 新模式（每季度 1 个）

- [ ] **挑战模式（Daily Challenge）**
  - [ ] 每日固定种子
  - [ ] 固定 directive 组合
  - [ ] 全球排行榜

- [ ] **无尽模式（Endless）**
  - [ ] 持续生成敌人波次
  - [ ] 难度递增
  - [ ] 生存时间/击杀数排行榜

- [ ] **自定义模式（Custom Run）**
  - [ ] 玩家自选 operation / directive / hazard / 敌人密度
  - [ ] 用于练习和实验

---

## 关键里程碑

### MVP（Week 3）
- ✓ itch.io 公开发布
- ✓ 收集 100+ 玩家反馈
- ✓ 快速迭代 1-2 版本

### Android Launch（Week 6）
- ✓ Google Play 上架
- ✓ 真机性能优化
- ✓ 商店素材完整

### Quality Pass（Month 4）
- ✓ 视觉资产第一轮替换
- ✓ 核心数值平衡
- ✓ 手感打磨完成

### PC Launch（Month 6）
- ✓ Steam 上架
- ✓ PC 扩展完成
- ✓ 键位/手柄/设置菜单

### Content Update 1（Month 9）
- ✓ 3 个新关卡
- ✓ 2 种新敌人
- ✓ 1 个新模式

---

## 当前进度

**已完成（脚本级）**：
- Web 版技术任务：竖屏提示、run telemetry 打点、iframe 焦点管理、音频手势解锁路径
- `RunCatalog` 数据外化（`data/run_operations.tres` + `RunCatalog.shared()`）与回归修复
- 批量验证自动化：`run_all_verifications.ps1`，当前 17 个 `verify_*.tscn` 全绿
- 代码质量 + 正确性审计两轮（终局幂等、敌人击退 / 计分、UI 可见性、网页门户进度条），详见 `docs/code_quality_report.md`
- 网页包体尺寸自动同步：`sync_web_bundle_sizes.ps1` + `verify_web_portal_bundle.tscn`

**下一步（需要真机 / 真实账号）**：
- 导出 itch.io 版本（`export_web_to_itch.bat`）并上传草稿页
- 真机验证：音频解锁、iframe 内键盘焦点、竖屏提示、触屏多指、安全区与震动强度
- 补 web 侧 telemetry 收集端点
- 接 release keystore 与 AAB 发布流

**风险追踪**：
- 脚本级护栏已覆盖主要回退面；剩余风险集中在真机环境（浏览器音频策略、刘海屏安全区、多指触控）与发布链路（keystore / 商店素材）
