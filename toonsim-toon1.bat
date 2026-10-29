@echo off
setlocal
rem =========================================================================
rem toonsim-toon1.bat - Launch FreeToon Toon 1 (800x480) Simulator
rem =========================================================================
rem Usage:
rem   toonsim-toon1.bat             Interactive Toon 1 FreeToon UI (800x480)
rem   toonsim-toon1.bat dim         Open directly at the dim screen
rem   toonsim-toon1.bat home_stock  Open directly at the classic stock home screen
rem   toonsim-toon1.bat --build     Force recompile before running
rem   toonsim-toon1.bat all [dir]   Export screenshots of all screens
rem =========================================================================

call "%~dp0toonsim-freetoon.bat" --size toon1 %*
set RC=%ERRORLEVEL%
if not "%RC%"=="0" (
    echo.
    echo [toonsim-toon1] Simulator exited with error code %RC%.
    pause
)
exit /b %RC%

