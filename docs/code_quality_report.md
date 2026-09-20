# Code Quality Report — Night Runner

**Generated:** 2026-09-11  
**Scope:** Memory leaks, headless safety, performance bottlenecks  
**Methodology:** Manual inspection of GDScript files, pattern analysis, architectural boundary review

---

## Executive Summary

The codebase demonstrates **strong resource management practices** overall, with proper cleanup callbacks and headless boundary checks in place. However, several **medium-priority performance issues** exist in per-frame operations that could impact Android performance, and a few **low-risk memory leak vectors** need attention for long-session stability.

**Critical Issues:** 0  
**High Priority:** 2  
**Medium Priority:** 5  
**Low Priority:** 4

---

## 跟进状态（2026-09-20）

本报告的 P0 项已落地，回归护栏为 `run_all_verifications.ps1`：

- **H1 HUD 全量刷新** —— 已修。`scripts/ui/hud.gd` 新增 `_set_text()` / `_set_font_color()` 脏写入；生命格与冲刺条 StyleBox 只建一次、按状态切换引用；行动配色移出 `_refresh()`，只在 `set_operation_context()` 重建。
- **H2 World 每帧事件检查** —— 已修。`scripts/game/world.gd` 的批量事件检查按 0.08s（12.5Hz）节流，开局首帧立即跑一次；导航指向仍每帧更新。
- **L1 HUD 飘分上限** —— 已修。`SCORE_POPUP_CAP = 24`，超出时回收最旧的 Label。
- **L2 生命格数量** —— 维持现状，已确认 max health 在一局内稳定。
- **M1 玩家特效节点池** —— 未做。特效都用 `tween_callback(queue_free)` 正确回收，属 GC 抖动而非泄漏；对象池会带来明显复杂度，收益需真机 profile 数据支撑后再定。
- **M2 / M5 / M3 / M4 / L3** —— 未做。Godot 的父节点 `queue_free()` 会连带清理子节点，显式再 `queue_free()` 属于冗余代码；这些项已是 `is_instance_valid()` + 生命周期回收覆盖的边界情况，按"不为小概率问题加新抽象层"的原则保留。

## 正确性审计追加（2026-09-20 第二轮）

上面是性能 / 生命周期视角的清单。第二轮按"状态机与结算正确性"重新过了一遍，又发现并修掉下面这些；每项都有对应护栏，全部纳入 `run_all_verifications.ps1`。

- **终局不幂等** —— `GameState.finish_run()` 之前没有早退保护，玩家坠落事件每帧都会重复触发一次结算并反复写存档（约 60 次/秒）；`lose_health()` 只在 `is_run_failed` 时早退，成功局后仍可继续掉血。现在两者都判 `is_run_active`，`Player._handle_fall_check()` 与 `World` 的 `player_hit` / `player_fell` / `data_core_collected` 回调也各自加了进行中判定。
- **Stalker 完全免疫击退** —— `knocked_velocity` 只被赋值、从未在 `_physics_process` 里消费，受击后速度被状态机静默吞掉。现在长度超过阈值时由击退位移接管并做摩擦衰减，同时受击统一切到 `reposition`；这条直接关系到"把精英击退到平台外摔死"的核心解法。
- **Stalker 落地冲击圈半径没接数据表** —— `landing_impact_range` 在 `data/enemy_stats.tres` 里，但真实判定圈半径写死在 `enemy_stalker.tscn` 的 `landing_shape`（120），改表不影响实际命中。现在 `_ready()` 复制 shape 并写入半径。
- **敌人击杀播报与入账分数不一致** —— 5 只敌人的 `_defeat()` 播报 `POINTS_AWARD` 但环境击杀只加一半，且 0 分时仍弹出 `+0`。现在折后分值同源，0 分不弹字。
- **敌人受击不幂等** —— `receive_hit()` 缺 `defeated_once` 早退，同帧重复命中会重复播放受击飘字和掉血条。
- **`SessionScreen` 信息列永久消失** —— HUB 收起 `Summary` / `Intel` / `DirectiveName` / `DirectiveSummary` 后，暂停与结算分支没有恢复，进过一次大厅右侧就空了。
- **`SessionScreen` 主题应用顺序错误** —— `_apply_theme()` 在 `_build_route_banner()` / `_build_first_run_brief()` 之前调用，对这两个运行时面板的空判永远命中 null，样式覆盖全部丢失；同时它没有挂 `viewport.size_changed`，安全区在网页画布缩放 / 设备旋转后不刷新。
- **`TouchControls` 双重缩放与不响应 resize** —— offset 乘了一次 UI scale、pad 自身 `scale` 又乘一次；pad 轴心留在默认左上角，缩放会把 pad 拖离贴边位置；且完全没有监听 `viewport.size_changed`。
- **网页门户进度条卡住** —— `docs/index.html` 的 `fileSizes` 把 `index.pck` 声明成 273,848 字节（真实 18,393,444），Godot 用声明值累加下载总量而 `current` 是真实字节数，于是进度条在 pck 刚开始下载时就冲到 100% 然后长期不动；加载层 `#status` 的 z-index(50) 还低于焦点提示 `#click-to-focus`(100)，下载期间玩家看到的是 "Click to Start" 而不是进度。

新增护栏：`verify_session_screen_panels.tscn`（信息列可见性 + 主题顺序 + resize 连接）、`verify_web_portal_bundle.tscn`（`fileSizes` 与真实包体一致 + 加载层 z-index 顺序）。`verify_touch_controls_layout.tscn` 也扩了一块小视口缩放回归（offset 保持设计像素、轴心贴角、`size_changed` 后重新套用布局），`verify_run_telemetry.tscn` 扩了终局幂等段（已结束的局再调 `finish_run` / `lose_health` 必须完全无副作用）。以上护栏都做过变异测试（改回旧行为 → 断言确实失败），确认不是空转断言。

另一个顺手修掉的测试卫生问题：`verify_pause_settings.tscn` 的音量滑块回调会走 `GameState.set_master_volume()` 的持久化分支，把开发者的本地存档改成测试值（音量 / haptics）。现在该场景在测试前后快照并还原存档文件，整套 `run_all_verifications.ps1` 连续跑两次存档 hash 保持不变。

---

## High Priority Issues

### H1. HUD `_process()` calls `_refresh()` every frame with full UI rebuild

**Location:** `scripts/ui/hud.gd:118-129`, `151-266`

**Severity:** High (performance impact on mobile)

**Description:**  
The HUD `_process()` method calls multiple update methods every frame:
```gdscript
func _process(delta: float) -> void:
    _update_pulses(delta)
    _update_bars(delta)
    _update_popups(delta)
    _update_health_animation(delta)
```

Additionally, `_refresh()` is called from `GameState.state_changed` signal (line 114), which updates **all text labels and UI elements** (lines 151-266). However, if `GameState.state_changed` fires frequently during gameplay, this creates excessive string formatting and theme overrides:

- `score_label.text = "%04d" % GameState.score` (line 162)
- `combo_label.text = "连击 x%d (COMBO)" % GameState.combo_count` (line 165)
- `core_label.text = "%d / %d" % [GameState.data_cores_collected, GameState.data_cores_total]` (line 172)
- `time_label.text = GameState.formatted_time()` (line 174) — calls string formatting method
- Multiple `add_theme_color_override()` calls per refresh (lines 166, 169, 178)

**Impact:** String formatting and theme overrides on every state change can cause GC pressure and frame drops on low-end Android devices.

**Recommended Fix:**
1. Add dirty flags: only update labels when their underlying values actually change
2. Cache formatted strings when values haven't changed
3. Move theme color overrides to `_ready()` or apply them conditionally

**Estimated Fix Time:** 2-3 hours

---

### H2. World `_process()` checks multiple event systems every frame

**Location:** `scripts/game/world.gd:142-151`

**Severity:** High (unnecessary computation)

**Description:**  
The world `_process()` unconditionally calls multiple event check methods:
```gdscript
func _process(_delta: float) -> void:
    if not GameState.is_run_active or GameState.is_run_failed:
        return
    _check_timeline_events()
    _check_cashout_events()
    _check_setpiece_events()
    _update_hazard_states()
    _refresh_live_route_status()
    _refresh_navigation_target()
    _check_tutorial_hints()
```

Each of these methods likely iterates over event dictionaries/arrays to check conditions. This pattern creates unnecessary per-frame overhead when events are sparse or already triggered.

**Impact:** Wasted CPU cycles every frame, especially problematic during intense combat with many enemies active.

**Recommended Fix:**
1. Use timers or state flags to skip event checks when no events are pending
2. Consider event-driven approach: trigger checks only when relevant game state changes (score threshold reached, cores collected, time elapsed)
3. Batch event checks less frequently (every 0.1s instead of every frame)

**Estimated Fix Time:** 3-4 hours

---

## Medium Priority Issues

### M1. Player creates many visual effect nodes without pooling

**Location:** `scripts/actors/player.gd` — multiple visual effect spawning methods

**Severity:** Medium (memory churn)

**Description:**  
Player script creates numerous temporary visual nodes throughout gameplay:
- Dash afterimages (Polygon2D): `_spawn_dash_afterimage()` line 495-504, every 0.045s during dash
- Damage afterimages (Sprite2D): `_spawn_damage_afterimage()` line 522-532
- Damage burst shards (Polygon2D x8-9 + ring): `_spawn_damage_burst()` line 535-577, creates 9-10 nodes per hit
- Landing dust (Polygon2D x5): `_spawn_landing_dust()` line 594-613
- Speed lines (Polygon2D): `_maybe_spawn_speed_lines()` line 616-640, every 0.08s when running fast
- Attack arc (Polygon2D): `_spawn_attack_arc()` line 397-420
- Hit sparks (Polygon2D): `_spawn_hit_spark()` line 423-440
- Hit flash (Polygon2D): `_spawn_hit_flash()` line 443-459

Each node uses `create_tween()` with `tween_callback(node.queue_free)` for cleanup (correct pattern), but the high creation frequency causes GC pressure.

**Impact:** Allocating/freeing 20-50 visual nodes per second creates memory churn. Not a leak, but impacts frame stability on mobile.

**Recommended Fix:**
1. Implement object pools for commonly created effect types (Polygon2D, Sprite2D)
2. Reuse and reset pooled nodes instead of creating new ones
3. Prioritize pooling for high-frequency effects: dash afterimages, speed lines, damage bursts

**Estimated Fix Time:** 4-6 hours

---

### M2. Enemy HP bar Polygon2D nodes created but never explicitly freed

**Location:**  
- `scripts/actors/enemy_runner.gd:52-70`
- `scripts/actors/enemy_bastion.gd:62-80`
- `scripts/actors/enemy_suppressor.gd:74-92`
- `scripts/actors/enemy_stalker.gd:138-150`

**Severity:** Medium (potential leak on parent queue_free failure)

**Description:**  
Each enemy creates two Polygon2D nodes in `_setup_hp_bar()`:
```gdscript
hp_bar_bg = Polygon2D.new()
# ... configure ...
add_child(hp_bar_bg)

hp_bar_fill = Polygon2D.new()
# ... configure ...
add_child(hp_bar_fill)
```

These nodes are added as children but never explicitly freed. The `_defeat()` method only calls `queue_free()` on the parent enemy node (e.g., enemy_runner.gd:182), relying on Godot's automatic child cleanup.

**Impact:** If `queue_free()` is interrupted or fails, child nodes could orphan. Low probability, but affects long-running sessions.

**Recommended Fix:**
1. Add explicit cleanup in `_defeat()` before `queue_free()`:
```gdscript
if is_instance_valid(hp_bar_bg):
    hp_bar_bg.queue_free()
if is_instance_valid(hp_bar_fill):
    hp_bar_fill.queue_free()
```
2. Or store in array and clean in loop like stalker's afterimages pattern

**Estimated Fix Time:** 30 minutes

---

### M3. Stalker afterimages array can grow unbounded if cleanup fails

**Location:** `scripts/actors/enemy_stalker.gd:68`, `430-449`, `607-619`

**Severity:** Medium (unlikely but possible leak)

**Description:**  
Stalker maintains `var afterimages: Array[Sprite2D] = []` and spawns afterimages during plunge state. Cleanup happens in `_update_afterimages()` (lines 430-449):
```gdscript
for index in range(afterimages.size() - 1, -1, -1):
    var image := afterimages[index]
    if not is_instance_valid(image):
        afterimages.remove_at(index)
        continue
    var next_life := float(image.get_meta("life", AFTERIMAGE_LIFETIME)) - delta
    if next_life <= 0.0:
        image.queue_free()
        afterimages.remove_at(index)
```

Defeat cleanup also clears afterimages (lines 607-619). However, if `_physics_process()` stops being called (defeated_once=true) while afterimages still have remaining life, and `_defeat()` somehow isn't triggered, afterimages could persist.

**Impact:** Edge case memory leak if enemy state machine breaks. Unlikely but possible.

**Recommended Fix:**
1. Add timeout check: if `defeated_once` is true, immediately clear all afterimages
2. Use `is_queued_for_deletion()` check before accessing nodes
3. Consider setting a hard cap: `if afterimages.size() > 20: afterimages[0].queue_free(); afterimages.remove_at(0)`

**Estimated Fix Time:** 1 hour

---

### M4. Player dash/damage afterimage arrays similar risk to stalker

**Location:** `scripts/actors/player.gd:66`, `70`, `473-504`, `507-532`

**Severity:** Medium (same pattern as M3)

**Description:**  
Player maintains two afterimage arrays:
- `var dash_afterimages: Array[Polygon2D] = []` (line 66)
- `var damage_afterimages: Array[Sprite2D] = []` (line 70)

Both use similar cleanup patterns to stalker with `is_instance_valid()` checks and lifetime tracking. Same edge case risk if `_process()` stops updating but nodes aren't freed.

**Impact:** Same as M3 — unlikely edge case leak.

**Recommended Fix:**
Same as M3: add hard caps and immediate cleanup on player defeat/scene exit.

**Estimated Fix Time:** 1 hour

---

### M5. Suppressor aim_laser Line2D created but no explicit cleanup

**Location:** `scripts/actors/enemy_suppressor.gd:37`, `63-69`, `257-266`, `277`

**Severity:** Medium (relies on parent cleanup)

**Description:**  
Suppressor creates `aim_laser` Line2D in `_setup_aim_laser()`:
```gdscript
aim_laser = Line2D.new()
# ... configure ...
add_child(aim_laser)
```

The laser visibility is managed in `_refresh_visuals()` (lines 257-266), but there's no explicit `queue_free()` call before the parent's `queue_free()` on line 277. Relies on automatic child cleanup.

**Impact:** Same as M2 — low-probability orphan risk.

**Recommended Fix:**
Add explicit cleanup in `_defeat()`:
```gdscript
if is_instance_valid(aim_laser):
    aim_laser.queue_free()
```

**Estimated Fix Time:** 15 minutes

---

## Low Priority Issues

### L1. HUD score_popups array managed correctly but could use hard cap

**Location:** `scripts/ui/hud.gd:90`, `132-142`, `_update_popups()`

**Severity:** Low (already has cleanup, just lacks cap)

**Description:**  
HUD tracks `var score_popups: Array[Dictionary] = []` with Label nodes. The `spawn_score_popup()` method adds entries, and `_update_popups()` (called every frame in `_process()`) handles cleanup.

Array grows during intense scoring sequences (enemy waves). While cleanup is present, no hard cap prevents unbounded growth during extreme scenarios.

**Impact:** Could grow to 50-100 entries during rapid scoring. Minimal memory impact but unnecessary iteration.

**Recommended Fix:**
Add cap check in `spawn_score_popup()`:
```gdscript
if score_popups.size() > 30:
    score_popups[0]["node"].queue_free()
    score_popups.remove_at(0)
```

**Estimated Fix Time:** 15 minutes

---

### L2. HUD health_pips and health_target_scale arrays resized dynamically

**Location:** `scripts/ui/hud.gd:92-94`, `_sync_health_pip_count()`

**Severity:** Low (normal resize behavior)

**Description:**  
HUD maintains `var health_pips: Array[PanelContainer] = []` and `var health_target_scale: Array[float] = []`. These are resized when max health changes.

Not a leak, but dynamic resizing during gameplay could cause minor GC pressure if max health changes frequently (unlikely in current design).

**Impact:** Negligible — max health changes are rare.

**Recommended Fix:**
No fix needed unless max health becomes dynamic. Document that max health should be stable during runs.

**Estimated Fix Time:** N/A (document only, 10 minutes)

---

### L3. World generated_platforms, spawned_hazards, active_data_cores arrays

**Location:** `scripts/game/world.gd:29-31`, `113-127`

**Severity:** Low (cleanup exists but could be more defensive)

**Description:**  
World tracks three arrays:
- `var generated_platforms: Array[Node2D] = []`
- `var spawned_hazards: Array[Area2D] = []`
- `var active_data_cores: Array[Area2D] = []`

`reset_world()` clears these properly (lines 113-127) with `is_instance_valid()` checks. However, no per-frame validation ensures stale references are removed if nodes are freed externally.

**Impact:** Stale references could accumulate if data cores are collected/removed outside of expected flow. Minor iteration overhead.

**Recommended Fix:**
Add periodic cleanup (every 1-2 seconds) to remove invalid references:
```gdscript
for i in range(active_data_cores.size() - 1, -1, -1):
    if not is_instance_valid(active_data_cores[i]):
        active_data_cores.remove_at(i)
```

**Estimated Fix Time:** 30 minutes

---

### L4. AudioEngine uses global fixed-size player pool (correct pattern)

**Location:** `scripts/autoload/audio_engine.gd:14`, `17-26`, `38-51`

**Severity:** Low (no issue, best practice)

**Description:**  
AudioEngine creates a fixed pool of 16 AudioStreamPlayer nodes in `_ready()` and has proper shutdown cleanup in `prepare_for_shutdown()`. This is the **correct pooling pattern** and prevents memory leaks.

Headless check on line 18 ensures no audio nodes are created in headless mode.

**Impact:** No issue. This is exemplary resource management.

**Recommended Fix:**
None. Use this pattern as reference for other systems.

**Estimated Fix Time:** N/A

---

## Headless Mode Safety Analysis

### ✅ All Critical Boundaries Covered

**AudioEngine:** Line 18 checks `DisplayServer.get_name() != "headless"` and early-returns from all play methods when `_audio_enabled` is false. **SAFE.**

**Player time dilation:** Line 90 checks `DisplayServer.get_name() != "headless"` before applying `Engine.time_scale` changes. **SAFE.**

**Recommendation:** No headless safety issues found. All audio/visual code properly gated.

---

## Performance Hotspot Summary

### Per-Frame Operations Audit

**High-frequency `_process()` / `_physics_process()` methods:**

1. **hud.gd `_process()`**: 4 update methods + signal-driven `_refresh()` — **H1**
2. **world.gd `_process()`**: 7 check methods every frame — **H2**
3. **player.gd `_physics_process()`**: Reasonable, but spawns 20-50 visual nodes/second — **M1**
4. **enemy_*.gd `_physics_process()`**: Standard AI loops, no hotspots detected

**`get_node()` usage:** Only 21 occurrences found, mostly in verify scripts and tool scenes. All gameplay scripts use `@onready` caching. **No issue.**

**Unnecessary text updates:** HUD refreshes all labels on every state change without dirty flags — **H1**

---

## Verification Protocol

After fixes, run these verification scenes to ensure no regressions:

```bash
# Godot path (if not in PATH)
GODOT="C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe"

# Memory management related
$GODOT --headless --path . scenes/tools/verify_audio_engine_shutdown.tscn

# Performance baseline (if available)
# Add verify_hud_refresh_rate.tscn after implementing dirty flags
# Add verify_world_event_overhead.tscn after optimizing event checks
```

---

## Priority Ranking Summary

### Fix Order Recommendation

1. **H1** → HUD dirty flags (highest impact on mobile performance)
2. **H2** → World event check optimization (second highest impact)
3. **M1** → Player visual effect pooling (reduces GC pressure)
4. **M2, M5** → Explicit HP bar / aim laser cleanup (quick wins, 45 min total)
5. **M3, M4** → Afterimage array safety (defensive programming)
6. **L1** → HUD popup cap (quick win)
7. **L3** → World array validation (defensive programming)
8. **L2** → Document max health stability (no code change)

**Total Estimated Fix Time:** 13-18 hours across all issues

---

## Code Quality Strengths

The codebase demonstrates several **best practices**:

1. ✅ **Consistent tween cleanup pattern**: All visual effects use `tween_callback(node.queue_free)`
2. ✅ **Proper autoload shutdown**: AudioEngine has explicit `prepare_for_shutdown()`
3. ✅ **@onready caching**: No excessive `get_node()` calls in hot paths
4. ✅ **Headless boundary checks**: Audio/visual code properly gated
5. ✅ **is_instance_valid() usage**: Defensive node validation in cleanup loops
6. ✅ **Defeated_once flags**: Prevents double-cleanup and state machine errors

These patterns should be maintained and applied to the issues identified above.

---

## Conclusion

No critical memory leaks detected. The primary concerns are **per-frame performance overhead** (HUD/World `_process()` methods) and **memory churn from high-frequency node creation** (player visual effects). These are **medium-priority optimizations** for Android performance, not blockers for release.

Recommended focus: **H1 and H2 fixes before Android APK release** to ensure smooth 60 FPS on mid-range devices.

---

**Report End**
