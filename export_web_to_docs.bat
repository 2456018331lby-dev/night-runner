@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "OUTPUT_DIR=%PROJECT_DIR%docs"
set "EXPORT_DIR=%PROJECT_DIR%exports\web"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $godotCommand=Get-Command Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue | Select-Object -First 1; $godot=if($godotCommand){if($godotCommand.Source){$godotCommand.Source}else{$godotCommand.Path}}else{'C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe'}; if (-not (Test-Path $godot -PathType Leaf)) { throw 'Godot 4.6.2 console build not found.' }; New-Item -ItemType Directory -Force -Path '%EXPORT_DIR%' | Out-Null; & $godot --headless --path '%PROJECT_DIR%' --export-release Web '%EXPORT_DIR%\index.html'; $exportCode=$LASTEXITCODE; if ($exportCode -ne 0) { throw ('Web export failed with exit code ' + $exportCode) }; $required=@('index.js','index.pck','index.wasm'); foreach ($name in $required) { $path=Join-Path '%EXPORT_DIR%' $name; if (-not (Test-Path $path -PathType Leaf)) { throw ('Web export missing ' + $name) }; if ((Get-Item $path).Length -le 0) { throw ('Web export produced an empty ' + $name) } }; New-Item -ItemType Directory -Force -Path '%OUTPUT_DIR%' | Out-Null; foreach ($name in $required) { Copy-Item (Join-Path '%EXPORT_DIR%' $name) (Join-Path '%OUTPUT_DIR%' $name) -Force }; Get-ChildItem '%OUTPUT_DIR%' -Filter '*.import' -ErrorAction SilentlyContinue | Remove-Item -Force; & '%PROJECT_DIR%sync_web_bundle_sizes.ps1' '%OUTPUT_DIR%'; $syncCode=$LASTEXITCODE; if ($syncCode -ne 0) { throw ('Web bundle size synchronization failed with exit code ' + $syncCode) }; foreach ($name in @('index.pck','index.wasm')) { $path=Join-Path '%OUTPUT_DIR%' $name; if (-not (Test-Path $path -PathType Leaf) -or (Get-Item $path).Length -le 0) { throw ('Docs output missing or empty: ' + $name) } }; Write-Host 'Web export to docs successful!' -ForegroundColor Green"
if errorlevel 1 (
  echo Web export FAILED.
  endlocal & exit /b 1
)
endlocal & exit /b 0
