@echo off
if "%1"=="" (
    echo Usage: flutter_build.bat [driver^|rider^|all] [debug^|release]
    echo Example: flutter_build.bat driver debug
    echo Example: flutter_build.bat all release
    exit /b 1
)

set APP=%1
set MODE=%2
if "%MODE%"=="" set MODE=debug

if "%APP%"=="driver" goto build_driver
if "%APP%"=="rider" goto build_rider
if "%APP%"=="all" goto build_all
echo Unknown app: %APP%
exit /b 1

:build_driver
echo Building Driver App (%MODE%)...
cd apps\driver_app
call flutter build apk --%MODE%
cd ..\..
goto end

:build_rider
echo Building Rider App (%MODE%)...
cd apps\rider_app
call flutter build apk --%MODE%
cd ..\..
goto end

:build_all
echo Building Driver App (%MODE%)...
cd apps\driver_app
call flutter build apk --%MODE%
cd ..\..
echo.
echo Building Rider App (%MODE%)...
cd apps\rider_app
call flutter build apk --%MODE%
cd ..\..
goto end

:end
echo.
echo Build complete!
