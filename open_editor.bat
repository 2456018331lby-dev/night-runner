@echo off
setlocal
set "PROJECT_DIR=C:\Users\24560\Desktop\study\gametwo"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$godot=(Get-Command Godot_v4.6.2-stable_win64.exe -ErrorAction SilentlyContinue).Source; if (-not $godot) { $godot=(Get-Command Godot_v4.6.2-stable_win64_console.exe -ErrorAction SilentlyContinue).Source }; if (-not $godot) { $dir='C:/Users/24560/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe'; if (Test-Path \"$dir/Godot_v4.6.2-stable_win64.exe\") { $godot=\"$dir/Godot_v4.6.2-stable_win64.exe\" } elseif (Test-Path \"$dir/Godot_v4.6.2-stable_win64_console.exe\") { $godot=\"$dir/Godot_v4.6.2-stable_win64_console.exe\" } }; if (-not $godot) { Write-Error 'Godot 4.6.2 not found in PATH or WinGet packages.'; pause; exit 1 }; Start-Process -FilePath $godot -ArgumentList '--editor','--path','%PROJECT_DIR%'"
endlocal
