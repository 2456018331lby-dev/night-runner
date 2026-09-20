@echo off
setlocal
set "PROJECT_DIR=C:\Users\24560\Desktop\study\gametwo"
set "OUTPUT_DIR=%PROJECT_DIR%\docs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$godot=(Get-Command Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue).Source; if (-not $godot) { $godot='C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe' }; if (-not (Test-Path $godot)) { Write-Error 'Godot 4.6.2 console build not found.'; exit 1 }; New-Item -ItemType Directory -Force -Path '%PROJECT_DIR%\exports\web' | Out-Null; & $godot --headless --path '%PROJECT_DIR%' --export-release Web '%PROJECT_DIR%\exports\web\index.html'; Copy-Item '%PROJECT_DIR%\exports\web\index.js' '%OUTPUT_DIR%\index.js' -Force; Copy-Item '%PROJECT_DIR%\exports\web\index.pck' '%OUTPUT_DIR%\index.pck' -Force; Copy-Item '%PROJECT_DIR%\exports\web\index.wasm' '%OUTPUT_DIR%\index.wasm' -Force; Get-ChildItem '%OUTPUT_DIR%' -Filter '*.import' -ErrorAction SilentlyContinue | Remove-Item -Force; & '%PROJECT_DIR%\sync_web_bundle_sizes.ps1' '%OUTPUT_DIR%'"
endlocal
