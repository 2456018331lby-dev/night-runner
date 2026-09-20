# Backlog

## P0 发布验证（itch.io web 优先）

- 上架 itch.io：跑 `export_web_to_itch.bat` 出 `exports/itch/night-runner-web.zip`，按 `docs/exporting.md` 的 itch.io 打包节上传（HTML kind、1280x720、Mobile friendly + 全屏、SharedArrayBuffer 关）
- 上架前在 itch 草稿页真机验证：音频首次手势解锁（任意首次交互都会聚焦画布并满足自动播放策略，仍需真机确认）、iframe 内键盘焦点（已补 `tabIndex` + 失焦/切回页签重新聚焦，仍需 iframe 内确认）、手机浏览器触控按键出现、竖屏时的表现
- 竖屏手机浏览器提示 —— 已落地：`main.gd` 的 `_build_rotate_prompt()` 在移动端宽高比 < 1.2 时覆盖 `ROTATE YOUR DEVICE` 遮罩，仍缺真机浏览器确认
- run telemetry 打点 —— 已落地：`GameState.finish_run()` 聚合 `_build_run_telemetry()`，含死因、真实死亡坐标（x/y）、`live_route_phase` 阶段、cashout overstay、route/directive，web 层经 `JavaScriptBridge` 输出；护栏为 `verify_run_telemetry.tscn`。剩余缺口：web 侧的 telemetry 收集与上报（目前只 `console.log`，没有落库或分析端点）
- Poki / CrazyGames 需各自 JS SDK（加载事件 / 广告断点 / gameplay start-stop）且 CrazyGames 对 36MB wasm 有压力——单独立项，itch 验证后再说

## P0 可玩性

- 继续真机调攻击命中、受击、音效和屏幕反馈强度；已有全局 hit-stop、落地挤压/起跳拉伸、镜头 kick + 纵向前瞻、攻击弧光、连击≥3 击杀 slow-mo 和来源级屏幕冲击第一版，后续重点是实玩强度调参
- 继续调多敌人混编节奏；当前已新增遭遇压力回归脚本，防止远程压制者 / Bastion / Stalker 在同一刷怪桶中过近重叠
- 继续实玩 3 个行动的独立地形记忆点和阶段事件强度；当前三条行动都有 `phase_setpiece` 阶段横幅 / 压力文案护栏
- 继续实玩三条路线的后段 cashout 压迫；当前 Blitz / Ghost / Overdrive 都已有 24 秒后 late cashout 波次，Overdrive 另有更高 dividend score threshold、cashout 倍率通道和脚本护栏，后续重点是真机/实玩调参

## P1 安卓体验（web 验证后）

- 真机验证触屏拖出取消和多指输入边界；当前已有脚本级 touch-index 拖出取消、jump buffer / coyote time、攻击长按续攻和触控暂停输入清理护栏，但仍缺真机手感确认
- 真机验证振动反馈、18:9 / 刘海屏安全区和当前触控区域布局；暂停页 `VOLUME` / `HAPTICS`、运行中触控按钮与 `PlatformProfile` 安全区 / 震动边界、轻震/警告震动节流已有脚本护栏，后续重点是真机手感确认，不要再为每个小平台断言新建独立测试文件
- 接 release keystore、AAB 发布流和真机发布前检查；当前 debug APK preset 已有 Android 导出契约护栏
- 触控模式用户开关（auto / on / off，存 `GameState` 设置）——兜底 web 误判和外接键盘场景

## P1 PC / Steam 扩展

- 键位重绑定
- 手柄支持
- 设置菜单
- 本地存档
- Steam 成就、排行榜、云存档抽象层
- 前端桥接层上接独立桌面产品壳和高级 UI
- 前端视觉继续迭代：正式 typography / 图标系统 / 品牌化终端皮肤 / 更强结果页动效，当前已有第一版镀铬边框、卡片化和 HUD 脉冲反馈

## P2 内容

- 三段式城市追逐关卡
- 盾兵、俯冲兵、Boss
- `EnemyStalker` 继续打磨命中停顿时长、混音层、落地冲击真机强度和多敌人混编节奏；当前已有第一版平台附着精度、落点预警、坠击残影、重击音效、玩家受击闪白和来源级屏幕冲击
- `EnemyPhantom` 继续打磨预警、落点提示、音效和命中演出，当前已有第一版蓄势预警与俯冲残影
- 评分系统继续扩展为章节目标、更细的撤离评价和时间奖励；当前结果页已有 rank 分差、速度/受击/cashout 得失说明，可选目标 HUD 状态也会显示剩余时间 / 分数或 no-hit 破损原因
- 视觉主题资产替换掉占位图形
- 环境机关、动态事件和行动专属收集物

## P3 工程

- 导出预设与 CI
- 数据驱动敌人数值表 —— 已完成：数据本体在 `data/enemy_stats.tres`（`EnemyStatsData` 资源，Inspector 可调参），`EnemyStats` autoload 作加载/访问层并保留 inline 兜底表，各 enemy 脚本 `_ready()` 从表 hydrate；`verify_enemy_stats.tscn` 校验文件加载、kind 集合、键白名单、类型、兜底一致和实例化一致
- 自动化测试脚本（批量 verify runner）—— 已完成：根目录 `run_all_verifications.ps1` 自动发现 `scenes/tools/verify_*.tscn`、逐个 headless 跑并汇总通过/失败/耗时，失败时 exit 1
- `RunCatalog` 操作表外化 —— 已完成：数据本体在 `data/run_operations.tres`（`RunOperationData` 资源），`RunCatalog`（`extends RefCounted`）作加载/访问层并保留 inline `DEFAULT_OPERATIONS` 兜底表；调用方统一走 `RunCatalog.shared()` 拿共享实例，避免每处各加载一份 `.tres`；`verify_run_catalog.tscn` 校验字段白名单、类型、PackedScene 引用可解析、Overdrive 专属 `cashout_beacon` 和兜底表一致性
- 前端桥接协议文档化 —— 已完成：`docs/frontend-bridge.md`（相位机 / 信号表 / 方法副作用 / 典型时序 / 禁区），后续改 `frontend_bridge.gd` 协议时需同步更新该文档
- 网页版包体尺寸自动同步 —— 已完成：`sync_web_bundle_sizes.ps1` 把 `docs/index.html` 的 `fileSizes` 回填成 `docs/index.pck` / `index.wasm` 的真实字节数（Godot 用声明值累加下载总量，声明偏小会让进度条提前冲到 100% 后卡住），由 `export_web_to_docs.bat` 自动调用；`verify_web_portal_bundle.tscn` 作为护栏
- 导出预设与 CI 的剩余缺口：尚无 CI 在 push 时自动跑 `run_all_verifications.ps1` 和网页门户契约检查
