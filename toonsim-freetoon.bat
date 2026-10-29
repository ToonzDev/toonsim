@echo off
setlocal enabledelayedexpansion

rem =========================================================================
rem toonsim-freetoon.bat - Launch FreeToon (LVGL) Simulator on PC
rem =========================================================================
rem Usage:
rem   toonsim-freetoon.bat [options] [screen_name / command]
rem
rem Options:
rem   --size toon2|toon1     Toon 2 (1024x600) or Toon 1 (800x480) [default: auto/toon2]
rem   --build                Force rebuild simulator binaries before launching
rem   --help, -h             Show this help message
rem   all [dir]              Headless mode: dump all screens to PPM files
rem
rem Requirements:
rem   Windows Subsystem for Linux (WSLg) with Ubuntu.
rem =========================================================================

set SCRIPT_DIR=%~dp0
set FREETOON_DIR=

if defined FREETOON_PATH (
    if exist "!FREETOON_PATH!\lvgl_ui_recovered\src\Makefile" set "FREETOON_DIR=!FREETOON_PATH!"
)
if not defined FREETOON_DIR (
    if exist "%SCRIPT_DIR%..\freetoon-lvgl\lvgl_ui_recovered\src\Makefile" (
        pushd "%SCRIPT_DIR%..\freetoon-lvgl"
        set "FREETOON_DIR=!CD!"
        popd
    )
)
if not defined FREETOON_DIR (
    if exist "%SCRIPT_DIR%freetoon-lvgl\lvgl_ui_recovered\src\Makefile" (
        pushd "%SCRIPT_DIR%freetoon-lvgl"
        set "FREETOON_DIR=!CD!"
        popd
    )
)

if not defined FREETOON_DIR (
    echo [ERROR] Could not find the freetoon-lvgl repository.
    echo Please make sure freetoon-lvgl is cloned alongside toonsim or set FREETOON_PATH.
    exit /b 1
)

rem Check for WSL
where wsl.exe >nul 2>nul
if errorlevel 1 (
    echo [ERROR] WSL is required to run the FreeToon simulator on Windows.
    echo Please install WSL with Ubuntu and WSLg enabled.
    exit /b 1
)

rem Default model
set MODEL=toon2
if exist "%SCRIPT_DIR%firmware\toon-model.txt" (
    set /p MODEL=<"%SCRIPT_DIR%firmware\toon-model.txt"
)

set DO_BUILD=0
set FORWARD_ARGS=

:parse_args
if "%~1"=="" goto done_args
if /i "%~1"=="--size" (
    set "MODEL=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="toon1" (
    set "MODEL=toon1"
    shift
    goto parse_args
)
if /i "%~1"=="toon2" (
    set "MODEL=toon2"
    shift
    goto parse_args
)
if /i "%~1"=="--build" (
    set DO_BUILD=1
    shift
    goto parse_args
)
if /i "%~1"=="--freetoon" (
    shift
    goto parse_args
)
if /i "%~1"=="--ui" (
    shift
    if /i "%~1"=="freetoon" shift
    goto parse_args
)
if /i "%~1"=="--help" (
    goto show_help
)
if /i "%~1"=="-h" (
    goto show_help
)

set "FORWARD_ARGS=!FORWARD_ARGS! %~1"
shift
goto parse_args

:done_args

rem Convert Windows path to WSL path
for /f "usebackq delims=" %%i in (`wsl -d Ubuntu wslpath -a "%FREETOON_DIR%" 2^>nul`) do set "WSL_FREETOON_DIR=%%i"
if not defined WSL_FREETOON_DIR (
    set "DRIVE=!FREETOON_DIR:~0,1!"
    for /f "delims=" %%D in ('powershell -NoProfile -Command "\"!DRIVE!\".ToLower()"') do set "DRIVE_LOWER=%%D"
    set "REST=!FREETOON_DIR:~2!"
    set "REST=!REST:\=/!"
    set "WSL_FREETOON_DIR=/mnt/!DRIVE_LOWER!!REST!"
)

rem Select binary and target based on model
if /i "%MODEL%"=="toon1" (
    set "BIN_NAME=toonui-sim1"
    set "TARGET=sim1"
    set "BUILD_SUBDIR=build-sim1"
    set "RES_INFO=800x480"
) else (
    set "BIN_NAME=toonui-sim"
    set "TARGET=sim"
    set "BUILD_SUBDIR=build-sim"
    set "RES_INFO=1024x600"
)

rem Rebuild if requested or if binary doesn't exist
if not exist "%FREETOON_DIR%\lvgl_ui_recovered\%BUILD_SUBDIR%\%BIN_NAME%" set DO_BUILD=1

if "!DO_BUILD!"=="1" (
    echo [toonsim] Building FreeToon simulator !TARGET! - !RES_INFO!...
    wsl -d Ubuntu bash -c "cd '%WSL_FREETOON_DIR%/lvgl_ui_recovered/src' && make TARGET=!TARGET! -j4"
    if errorlevel 1 (
        echo [ERROR] FreeToon simulator build failed.
        exit /b 1
    )
)

rem Ensure /mnt/data directory exists and kill any stale sim process
wsl -d Ubuntu bash -c "killall -9 toonui-sim1 toonui-sim 2>/dev/null || true" >nul 2>nul
wsl -d Ubuntu -u root bash -c "mkdir -p /mnt/data && chmod 777 /mnt/data" >nul 2>nul

:sim_loop
echo [toonsim] Starting FreeToon Simulator (%MODEL%, %RES_INFO%)...
wsl -d Ubuntu bash -c "DISPLAY=${DISPLAY:-:0} cd '%WSL_FREETOON_DIR%/lvgl_ui_recovered/%BUILD_SUBDIR%' && ./%BIN_NAME%!FORWARD_ARGS!"
set EXIT_CODE=%ERRORLEVEL%

if "%EXIT_CODE%"=="42" (
    echo.
    echo [toonsim] UI restart requested — restarting simulator...
    goto sim_loop
)

exit /b %EXIT_CODE%

:show_help
echo =========================================================================
echo FreeToon LVGL Simulator for Toon Simulator
echo =========================================================================
echo Usage:
echo   toonsim-freetoon.bat [--size toon2^|toon1] [--build] [mode / args]
echo   toonsim.bat --freetoon [--size toon2^|toon1]
echo.
echo Modes:
echo   (no arguments)       Interactive graphical simulator window (WSLg)
echo   all [dir]            Export all screen images to PPM files (default: /tmp)
echo   nav [out.ppm] [x,y]  Interactive navigation trace
echo   ^<screen^> [out.ppm]   Render a specific screen (home, settings, thermostat, etc.)
echo.
echo Options:
echo   --size toon2         Toon 2 layout (1024x600, default)
echo   --size toon1         Toon 1 layout (800x480)
echo   --build              Force recompile before running
echo   --help, -h           Show this help
echo =========================================================================
exit /b 0
