@echo off
REM Bitontree rulebook installer — Windows double-click launcher.
REM Calls install-global.ps1 with PowerShell, bypassing execution policy locally.
REM Pass -Force or -DryRun by editing the line below or by running .ps1 directly.

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%install-global.ps1"

if not exist "%PS1%" (
  echo Cannot find: %PS1%
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "ERR=%ERRORLEVEL%"

echo.
echo Press any key to close...
pause >nul
exit /b %ERR%
