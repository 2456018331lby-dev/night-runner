@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "OUTPUT_DIR=%PROJECT_DIR%exports\itch\web"
set "STAGE_DIR=%PROJECT_DIR%exports\itch\zip_stage"
set "ZIP_PATH=%PROJECT_DIR%exports\itch\night-runner-web.zip"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $godotCommand=Get-Command Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue | Select-Object -First 1; $godot=if($godotCommand){if($godotCommand.Source){$godotCommand.Source}else{$godotCommand.Path}}else{'C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe'}; if (-not (Test-Path $godot -PathType Leaf)) { throw 'Godot 4.6.2 console build not found.' }; $required=@('index.html','index.js','index.wasm','index.pck','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js'); try { New-Item -ItemType Directory -Force -Path '%OUTPUT_DIR%' | Out-Null; & $godot --headless --path '%PROJECT_DIR%' --export-release Web '%OUTPUT_DIR%\index.html'; $exportCode=$LASTEXITCODE; if ($exportCode -ne 0) { throw ('Web export failed with exit code ' + $exportCode) }; Get-ChildItem '%OUTPUT_DIR%' -Filter '*.import' -ErrorAction SilentlyContinue | Remove-Item -Force; foreach ($name in $required) { $path=Join-Path '%OUTPUT_DIR%' $name; if (-not (Test-Path $path -PathType Leaf)) { throw ('itch.io package missing ' + $name) }; if ((Get-Item $path).Length -le 0) { throw ('itch.io package contains an empty ' + $name) } }; if (Test-Path '%STAGE_DIR%') { Remove-Item '%STAGE_DIR%' -Recurse -Force }; New-Item -ItemType Directory -Force -Path '%STAGE_DIR%' | Out-Null; foreach ($name in $required) { Copy-Item (Join-Path '%OUTPUT_DIR%' $name) (Join-Path '%STAGE_DIR%' $name) -ErrorAction Stop }; if (Test-Path '%ZIP_PATH%') { Remove-Item '%ZIP_PATH%' -Force }; Compress-Archive -Path (Join-Path '%STAGE_DIR%' '*') -DestinationPath '%ZIP_PATH%' -CompressionLevel Optimal; if (-not (Test-Path '%ZIP_PATH%' -PathType Leaf) -or (Get-Item '%ZIP_PATH%').Length -le 0) { throw 'itch.io zip was not created or is empty.' }; Write-Host 'Web export to itch.io package successful!' -ForegroundColor Green } finally { if (Test-Path '%STAGE_DIR%') { Remove-Item '%STAGE_DIR%' -Recurse -Force -ErrorAction SilentlyContinue } }"
if errorlevel 1 (
  echo itch.io Web export FAILED.
  endlocal & exit /b 1
)
endlocal & exit /b 0
