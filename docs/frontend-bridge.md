# FrontendBridge 桥接协议

本文档描述 `FrontendBridge`（`scripts/autoload/frontend_bridge.gd`，autoload 单例）的完整协议，
供独立前端 / UI 团队并行开发使用。它是 `docs/architecture.md` 中「前端重做接管约定」一节的展开，
与该节冲突时以本文档修订为准（改协议时两处同步更新）。

## 1. 定位

`FrontendBridge` 是前端（壳层 / UI）与玩法之间的**唯一桥接层**：

- 前端（`SessionScreen` / `HUD` / `TouchControls` 及未来重做的任何 UI）只允许接触两样东西：
  1. `FrontendBridge` 的信号与公开方法（本文档的全部内容）；
  2. `GameState` 暴露的**只读展示 getter**（分数、时间文本、结算数据等），仅用于展示，不做写入。
- 桥接层本身不执行玩法：它只维护应用相位与 operation / directive 选择状态，并把前端请求以信号形式
  广播出去；真正的路由由 `scripts/game/main.gd` 完成（连接桥接信号 → 驱动 `World` /
  `SessionScreen` / `GameState`）。

## 2. 相位机

### 相位常量

| 常量 | 值 | 含义 |
| --- | --- | --- |
| `PHASE_HUB` | `"hub"` | 中枢甲板：选 operation / directive、看记录 |
| `PHASE_RUN` | `"run"` | 局内进行中 |
| `PHASE_RESULTS` | `"results"` | 结果页（成功或失败结算） |
| `PHASE_PAUSE` | `"pause"` | 局内暂停 |

### 状态变量语义

- `app_phase: String` — 当前相位，初始为 `PHASE_HUB`。前端可读它做展示分支，不要直接赋值；
  改相位一律走方法（`toggle_pause()` / `resume_run()` / `request_return_to_hub()` 等）。
- `previous_phase: String` — 上一次相位。仅在 `set_phase()` 实际切换（新相位 ≠ 当前相位）时更新；
  重复设置同一相位既不改 `previous_phase` 也不发信号。
- `selected_operation_id: String` — 当前选中的 operation id，`bootstrap()` / `select_operation()` 维护。
- `selected_directives: Dictionary` — `operation_id -> directive_id` 的选择表，与
  `GameState.meta_progress["selected_directives"]` 同步持久化。

### 谁负责 `SceneTree.paused`

**`main.gd`，不是 bridge。** `toggle_pause()` / `resume_run()` 只翻转相位并发出
`pause_state_changed(paused)`；`main.gd` 的 `_on_pause_state_changed()` 收到后才写
`get_tree().paused`，并切换暂停页 / 局内 UI。前端（含 `TouchControls`）绝不能直接改
`SceneTree.paused`，只能调用 `FrontendBridge.toggle_pause()`。

## 3. 信号表

| 信号 | 参数 | 触发时机 | 典型消费者 |
| --- | --- | --- | --- |
| `bootstrapped` | — | `bootstrap()` 末尾必发一次（包括 operations 为空的早退分支） | 前端初始化完成钩子 |
| `phase_changed` | `phase: String` | `set_phase()` 实际切换相位时（含 `bootstrap()` 里对 hub 的一次显式 emit） | 前端根据相位切页面 |
| `operation_selected` | `operation_id: String` | `bootstrap()` 恢复记忆选择时；`select_operation()` 成功时 | `main.gd` 重建中枢（`session_screen.build_hub`） |
| `directive_selected` | `operation_id: String, directive_id: String` | `select_directive()` 成功时 | `main.gd` 在 hub 相位下刷新中枢 |
| `start_requested` | `operation_id: String` | `request_start_selected_operation()` 通过校验时 | `main.gd` 的 `_on_start_requested`：`GameState.start_run` → `world.begin` → `notify_run_started()` |
| `retry_requested` | `operation_id: String` | `request_retry_current_operation()` 且 `GameState.current_operation_id` 非空时 | `main.gd` 的 `_on_retry_requested`（内部转发给 `_on_start_requested`，与 start 同一套开局流程） |
| `return_to_hub_requested` | — | `request_return_to_hub()` 时（相位已先切回 hub） | `main.gd`：解除暂停、`world.reset_world`、重建中枢 |
| `pause_state_changed` | `paused: bool` | `toggle_pause()` / `resume_run()` / `notify_run_started()` / `set_results_phase()` | `main.gd`：写 `get_tree().paused` 并切换暂停页 / 局内 UI |

注意：`pause_state_changed(false)` 不只在恢复时发——开局（`notify_run_started()`）和进结果页
（`set_results_phase()`，经 `notify_run_finished()`）也会发，用于兜底解除暂停。`main.gd` 在
`paused == false` 且相位是 `PHASE_RESULTS` 时不会重新显示局内 UI。

## 4. 方法表

### 前端可调用

| 方法 | 参数 / 返回 | 行为与副作用 |
| --- | --- | --- |
| `bootstrap()` | → `void` | 从 `RunCatalog.get_operations()` 装载目录；从 `GameState.meta_progress` 恢复 `selected_operation_id` / `selected_directives`（记忆 id 为空或已锁则回退到首个解锁 operation）；若补齐了缺失的 directive 选择会写回 `meta_progress` 并 `GameState.save_progress()`；置相位为 hub 并依次 emit `phase_changed` → `operation_selected` → `bootstrapped`。由 `main.gd._ready()` 调用一次，重做的前端入口也应先等它跑完。 |
| `get_operations()` | → `Array[Dictionary]` | 返回全部 operation 定义的**深拷贝**（`duplicate(true)`），改返回值不影响内部状态。 |
| `get_selected_operation()` | → `Dictionary` | 等价 `get_operation(selected_operation_id)`。 |
| `get_operation(operation_id)` | → `Dictionary` | 按 id 查找，命中返回**深拷贝**，找不到返回空字典 `{}`。 |
| `select_operation(operation_id)` | → `void` | 空 id 为 no-op。否则更新 `selected_operation_id`、补齐该 operation 的 directive 默认选择，把两者写入 `GameState.meta_progress` 并 `save_progress()`（**写存档**），最后 emit `operation_selected`。注意：不校验解锁状态，锁定 operation 也可被"选中"用于展示，真正拦截在 start。 |
| `select_directive(operation_id, directive_id)` | → `void` | 任一参数为空则 no-op。否则写 `selected_directives`、同步 `GameState.meta_progress` 并 `save_progress()`（**写存档**），emit `directive_selected`。不校验 directive 是否属于该 operation 的池；无效 id 在读取时由 `get_selected_directive()` 回退。 |
| `get_selected_directive(operation_id)` | → `Dictionary` | operation 不存在或 directive 池为空返回 `{}`；已选 id 在池中则返回该 directive 深拷贝，否则回退池中第一个的深拷贝。 |
| `request_start_selected_operation()` | → `void` | `selected_operation_id` 为空或 `GameState.is_operation_unlocked()` 为假时是 **no-op**（对 locked 操作静默不发信号）；通过则 emit `start_requested(selected_operation_id)`。 |
| `request_retry_current_operation()` | → `void` | 若 `GameState.current_operation_id` 为空，**fallback** 到 `request_start_selected_operation()`；否则 emit `retry_requested(GameState.current_operation_id)`。 |
| `request_return_to_hub()` | → `void` | 先 `set_phase(PHASE_HUB)`（相位实际变化时才发 `phase_changed`），再 emit `return_to_hub_requested`（无条件发）。 |
| `toggle_pause()` | → `void` | **只翻转相位**：run→pause 发 `pause_state_changed(true)`，pause→run 发 `pause_state_changed(false)`；其他相位下是 no-op。不碰 `SceneTree.paused`。 |
| `resume_run()` | → `void` | 仅当 `app_phase == PHASE_PAUSE` 时切回 run 并发 `pause_state_changed(false)`，否则 no-op。 |

### 玩法侧回调（前端不要调用）

| 方法 | 行为 |
| --- | --- |
| `notify_run_started()` | 由 `main.gd` 在实际开局后调用：切相位到 run，发 `pause_state_changed(false)`。 |
| `notify_run_finished()` | 由 `main.gd` 在 `GameState.run_finished` 后调用：等价 `set_results_phase()`。 |
| `set_results_phase()` | 切相位到 results 并发 `pause_state_changed(false)`。 |
| `set_phase(phase)` | 底层相位切换（去重、维护 `previous_phase`、发 `phase_changed`）。前端不要直接调它，走上面的语义化方法。 |

## 5. 典型时序

### 启动 bootstrap

1. `main.gd._ready()` 先连接全部桥接信号，再调 `FrontendBridge.bootstrap()`。
2. `bootstrap()` 内部依次 emit：`phase_changed("hub")` → `operation_selected(<记忆或首个解锁 id>)` → `bootstrapped`。
3. `main.gd` 随后用 `get_operations()` + `selected_operation_id` 构建中枢。

### hub → 开局 → results → retry / 返回

1. hub 中前端调 `select_operation(id)` / `select_directive(id, did)`，各自写存档并发对应信号，
   `main.gd` 收到后重建中枢展示。
2. 前端点开始 → `request_start_selected_operation()` → `start_requested(operation_id)`。
3. `main.gd._on_start_requested`：`GameState.start_run(operation, directive)` →
   `world.begin(operation)` → `FrontendBridge.notify_run_started()`（此时 `phase_changed("run")`、
   `pause_state_changed(false)`）→ 隐藏中枢、显示局内 UI。
4. 局终：`GameState.run_finished(success)` → `main.gd._on_run_finished`：解除
   `get_tree().paused` → `FrontendBridge.notify_run_finished()`（`phase_changed("results")`、
   `pause_state_changed(false)`）→ 构建结果页。
5. 结果页重试 → `request_retry_current_operation()` → `retry_requested(current_operation_id)` →
   `main.gd` 走与 start 相同的开局流程；若此时 `current_operation_id` 意外为空则 fallback 成一次
   普通 start。
6. 返回中枢 → `request_return_to_hub()` → `phase_changed("hub")` + `return_to_hub_requested` →
   `main.gd` 解除暂停、`world.reset_world()`、重建中枢。

### 暂停 / 恢复

1. run 中：pause 输入（键盘经 `main.gd._input`，触屏经 `TouchControls`——触屏侧必须先清空
   `InputRouter` 的 held / pending 输入）→ `toggle_pause()`。
2. `phase_changed("pause")` + `pause_state_changed(true)` → `main.gd` 置
   `get_tree().paused = true`、隐藏局内 UI、构建暂停页。
3. 恢复：暂停页按钮或再次 pause 输入 → `resume_run()`（`main.gd` 对 pause 相位的键盘输入也走
   `resume_run()`）→ `phase_changed("run")` + `pause_state_changed(false)` → `main.gd` 置
   `get_tree().paused = false`、隐藏暂停页、恢复局内 UI。

## 6. 禁区

新前端**不得**：

- 直接触碰 `World` 内部（刷怪、目标、关卡事件、`RouteHazard`），不直接引用 `Player` / 敌人节点；
- 改敌人数值（数值走 `data/enemy_stats.tres` / `EnemyStats`，与前端无关）；
- 直接读写存档文件——持久化只经 `GameState`（bridge 的 `select_*` 已代为写 `meta_progress`
  并存档，前端不要再自己碰 `meta_progress`）；
- 直接改 `SceneTree.paused`（见第 2 节）；
- 直接给 `app_phase` / `selected_operation_id` 等 bridge 内部变量赋值，改状态一律走方法。

与 `docs/architecture.md` 一致：这是文档化边界与入口收敛，不是完全封闭的硬接口层；
需要更强隔离时先扩展本协议，再动代码。
