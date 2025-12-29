@echo off
echo Getting packages for Driver App...
cd apps\driver_app
call flutter pub get
cd ..\..

echo.
echo Getting packages for Rider App...
cd apps\rider_app
call flutter pub get
cd ..\..

echo.
echo All packages fetched!
