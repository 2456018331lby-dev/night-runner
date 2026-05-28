# Findings

## 2026-05-23
- `project.godot` uses 1280x720 landscape, `stretch/mode=canvas_items`, `stretch/aspect=expand`, and handheld orientation landscape.
- Autoload boundaries are already in place: `GameState`, `PlatformProfile`, `InputRouter`, `FrontendBridge`.
- `PlatformProfile.should_show_touch_controls()` currently returns true only on Android/iOS.
- `touch_controls.gd` already has first-pass drag-out cancel; it lacks safe-area/margin adaptation and pressed-state label changes.
- HUD has dynamic feedback from recent work: score pulse, damage pulse, cashout glow, event banner, toast pop.
- APK export is blocked in this environment: Android preset exists and templates are present, but expected SDK directory is missing and `adb` / `sdkmanager` are not on PATH.
- Godot CLI validation passes when using the Winget-installed console executable path directly; the short commands `godot` / `godot4` are not on PATH.
- Android APK export succeeds after pointing Godot at `C:/Users/24560/Desktop/study/Englishdemo/.android-sdk`, configuring JDK `C:/Program Files/Java/jdk-17`, and enabling `rendering/textures/vram_compression/import_etc2_astc=true`.
- `exports/android/NightRunner-debug.apk` is about 27 MB and verifies with APK Signature Scheme v2/v3.
- Route clarity was a high-impact quality gap; HUD now has a Route Vector card fed by World-side nearest-core/extraction target tracking.
- Android usability regression root cause: runtime `HUD` and `TouchControls` lived under always-instantiated `World`, while `SessionScreen` only overlaid hub/results; fixed by phase-gating run UI and using sensor landscape orientation in both project settings and Android preset.
- High-frequency game-feel gap: attacks, enemy defeats, data-core pickups, damage, and extraction had state/UI feedback but lacked enough physical visual bursts; this pass adds transient world/screen impact effects without adding a new VFX framework.
- Android still looked like the engine because the project used `res://icon.svg`, had no custom boot splash image configured, and the Android preset launcher icon fields were empty; fixed with Night Runner PNG branding assets and export preset icon paths.
- First-run pressure was too front-loaded for mobile: Blitz Pursuit had dense early enemies including phantom pressure, while player attack/mobility windows were tight. This pass shifts the first route toward learnable completion before greed mastery.
