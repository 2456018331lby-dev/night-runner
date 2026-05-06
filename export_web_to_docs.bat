@echo off
setlocal
set "PROJECT_DIR=C:\Users\24560\Desktop\study\gametwo"
set "OUTPUT_DIR=%PROJECT_DIR%\docs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$godot=(Get-Command Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue).Source; if (-not $godot) { Write-Error 'Godot 4.6.2 console build not found in PATH.'; exit 1 }; New-Item -ItemType Directory -Force -Path '%OUTPUT_DIR%' | Out-Null; & $godot --headless --path '%PROJECT_DIR%' --export-release Web '%OUTPUT_DIR%\\index.html'"
endlocal
