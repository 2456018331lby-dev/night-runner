@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "OUTPUT_DIR=%PROJECT_DIR%exports\android"
set "APK_PATH=%OUTPUT_DIR%\NightRunner-debug.apk"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $godotCommand=Get-Command Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue | Select-Object -First 1; $godot=if($godotCommand){if($godotCommand.Source){$godotCommand.Source}else{$godotCommand.Path}}else{'C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe'}; if (-not (Test-Path $godot -PathType Leaf)) { throw 'Godot 4.6.2 console build not found.' }; New-Item -ItemType Directory -Force -Path '%OUTPUT_DIR%' | Out-Null; Write-Host 'Exporting Android Debug APK to %APK_PATH% ...'; & $godot --headless --path '%PROJECT_DIR%' --export-debug Android '%APK_PATH%'; $exportCode=$LASTEXITCODE; if ($exportCode -ne 0) { throw ('Android export failed with exit code ' + $exportCode) }; if (-not (Test-Path '%APK_PATH%' -PathType Leaf)) { throw 'Android export reported success but APK was not created.' }; if ((Get-Item '%APK_PATH%').Length -le 0) { throw 'Android export created an empty APK.' }; Write-Host 'Android APK export successful!' -ForegroundColor Green"
if errorlevel 1 (
  echo Android APK export FAILED.
  endlocal & exit /b 1
)
endlocal & exit /b 0
