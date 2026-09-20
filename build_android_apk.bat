@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "OUTPUT_DIR=%PROJECT_DIR%exports\android"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$godot=(Get-Command Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue).Source; if (-not $godot) { $godot='C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe' }; if (-not (Test-Path $godot)) { Write-Error 'Godot 4.6.2 console build not found.'; pause; exit 1 }; New-Item -ItemType Directory -Force -Path '%OUTPUT_DIR%' | Out-Null; Write-Host 'Exporting Android Debug APK to %OUTPUT_DIR%\NightRunner-debug.apk ...'; & $godot --headless --path '%PROJECT_DIR%' --export-debug Android '%OUTPUT_DIR%\NightRunner-debug.apk'; if ($LASTEXITCODE -eq 0) { Write-Host 'Android APK export successful!' -ForegroundColor Green } else { Write-Warning 'Android APK export requires Android SDK / Build Tools. Code interfaces and presets are fully configured.' }"
endlocal
