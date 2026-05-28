# Night Runner APK Vertical Slice Plan

## Goal
Ship a first Android APK vertical slice that feels polished and surprising for a small Godot game: strong neon tactical front-end, readable combat feedback, mobile-safe HUD/touch controls, and preserved PC/Steam expansion boundaries.

## Product Direction
- Android APK is the first release target.
- PC/Steam remains a later expansion path through existing boundaries: `InputRouter`, `PlatformProfile`, `FrontendBridge`, `GameState`.
- Do not couple gameplay scripts directly to Android or Steam SDKs.

## Quality Bar
- First impression: hub/result UI should feel like a bespoke tactical terminal, not default controls.
- In-run feel: score, damage, cashout, elite attacks, route state must have visible feedback.
- Mobile: touch controls must not block core readability and should respect safe-ish margins.
- Export: document exact blockers before claiming APK is produced.

## Phases
| Phase | Status | Scope | Acceptance |
|---|---|---|---|
| 1. Plan and audit | complete | Check current UI/mobile/export state | Plan files created and current findings logged |
| 2. Mobile HUD/safe-area pass | complete | Adjust HUD and touch controls for handheld landscape | UI margins/layout adapt when `PlatformProfile.is_mobile` |
| 3. Extra polish pass | complete | Add one high-signal polish item for first impression/game feel | Visible feedback improvement without broad refactor |
| 4. APK readiness check | complete | Check preset/templates/SDK/adb/keystore | Android SDK found at `C:/Users/24560/Desktop/study/Englishdemo/.android-sdk`; debug APK exported and signed |
| 5. Validation/documentation | complete | Godot headless, diff check, docs update | Godot headless load check passes; APK signature verifies; `git diff --check` has no whitespace errors aside from LF/CRLF warnings; route navigation build re-exported successfully; Android UI layering/orientation fix re-exported |

## Current Risks
- Current machine likely lacks Android SDK/adb/Gradle, so direct APK export may be blocked.
- Many pre-existing uncommitted changes exist; avoid destructive git operations.
- UI has to work across desktop and mobile without branching gameplay logic.

## Errors Encountered
| Error | Attempt | Resolution |
|---|---|---|
| `hud.gd` parse error at line 226 | Godot headless load check after mobile HUD edits | Split accidentally joined GDScript statements into separate lines |
| `godot: command not found` / `where.exe godot` found nothing | Retried validation through PATH lookup, project executable glob, and prior session command history | Resolved by using `C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe` |
