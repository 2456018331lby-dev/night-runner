@echo off
set "GODOT=C:\Users\24560\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe"
if exist "%GODOT%" (
    echo Launching Godot 4.6 Editor...
    start "" "%GODOT%" --path "%~dp0." -e
) else (
    echo Godot executable not found at %GODOT%
    pause
)
