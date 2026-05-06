# Night Runner

`Night Runner` 是一个先做 Android APK、后续可扩展到 PC / Steam 的 2D 横版高速动作游戏原型。当前短局目标已经明确：在霓虹都市屋顶追逐中抢走全部情报核心，决定是继续刷分还是立刻撤离。

## 当前状态

- 已完成 Godot 4.6 项目骨架
- 已完成首版可玩竖切片
- 已加入第二类敌人“远程压制者”
- 已替换首批原创 SVG 角色美术
- 已加入情报核心、撤离门、连击和评级结算
- 已预留平台抽象、进度状态和维护文档

## 玩法目标

- 短局高强度闯关
- 平台击落而不是站桩磨血
- 安卓触屏可玩，PC 键盘立即可测

## 首版内容

- 玩家基础移动、二段跳、冲刺、近战击飞
- 近战追击者与远程压制者两类敌人
- 三枚情报核心、撤离门和短局胜利条件
- 连击加分、结算评级和风险收益选择
- 原创 SVG 角色立绘与霓虹场景氛围层
- 击落敌人得分，跌落或生命归零则失败
- HUD、计时、重开、移动端虚拟按键

## 运行

1. 双击 [open_editor.bat](/C:/Users/24560/Desktop/study/gametwo/open_editor.bat) 打开 Godot 编辑器
2. 双击 [run_game.bat](/C:/Users/24560/Desktop/study/gametwo/run_game.bat) 直接运行游戏
3. 需要重新导出网页版本时，双击 [export_web_to_docs.bat](/C:/Users/24560/Desktop/study/gametwo/export_web_to_docs.bat)
4. 键位：
   - `A/D` 或方向键左右：移动
   - `Space/W/上`：跳跃
   - `J/鼠标左键`：攻击
   - `K/Shift`：冲刺
   - `R`：重开

## 在线版本

- GitHub Pages 版本会发布在仓库的 `docs/` 目录
- 每次想更新线上版本，先运行 [export_web_to_docs.bat](/C:/Users/24560/Desktop/study/gametwo/export_web_to_docs.bat)，再提交并推送

## 文档

- 维护入口：[MAINTENANCE.md](/C:/Users/24560/Desktop/study/gametwo/MAINTENANCE.md)
- 架构说明：[docs/architecture.md](/C:/Users/24560/Desktop/study/gametwo/docs/architecture.md)
- 进度日志：[docs/progress.md](/C:/Users/24560/Desktop/study/gametwo/docs/progress.md)
- 维护待办：[docs/backlog.md](/C:/Users/24560/Desktop/study/gametwo/docs/backlog.md)
- 导出与发布：[docs/exporting.md](/C:/Users/24560/Desktop/study/gametwo/docs/exporting.md)

## 维护规则

- 每次新增系统先写进 `docs/architecture.md`
- 每次推进功能或修 bug 追加到 `docs/progress.md`
- 所有未来大功能先进入 `docs/backlog.md`
- 跨平台差异优先通过 `autoload` 或配置层处理，不在玩法脚本里散落分支
