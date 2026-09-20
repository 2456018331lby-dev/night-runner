@echo off
setlocal
set "PORT=8000"
echo ========================================================
echo   NIGHT RUNNER // LOCAL WEB PORTAL PREVIEW
echo   Starting local server at http://localhost:%PORT%/docs/
echo ========================================================
start "" http://localhost:%PORT%/docs/
python -m http.server %PORT%
endlocal
