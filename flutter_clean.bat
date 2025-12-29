@echo off
echo Cleaning Driver App...
cd apps\driver_app
call flutter clean
cd ..\..

echo.
echo Cleaning Rider App...
cd apps\rider_app
call flutter clean
cd ..\..

echo.
echo All apps cleaned!
