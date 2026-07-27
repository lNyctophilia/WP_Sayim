@echo off
cd /d "%~dp0\.."
title WP Sayim - APK Olustur
echo.
echo   ============================================
echo     WP Sayim - Release APK Olusturuluyor
echo   ============================================
echo.

set LAST_VERSION=
if exist docs\version.json (
    for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Get-Content docs\version.json | ConvertFrom-Json).version"`) do set LAST_VERSION=%%a
)

if "%LAST_VERSION%"=="" (
    set LAST_VERSION=APK_Surumu
)

echo Son Web Surumu algilandi: %LAST_VERSION%
echo.

:: Otomatik versiyon numarasi artirma (pubspec.yaml)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_auto_bump.ps1"
echo.

:: Shorebird kullanarak Base Release APK olusturuyoruz
call C:\Users\Halil\.shorebird\bin\shorebird.bat release android -- --dart-define="BUILD_VERSION=%LAST_VERSION%"

if errorlevel 1 (
    echo.
    echo   [HATA] Shorebird Build basarisiz!
    pause
    exit /b 1
)

echo.
echo   ============================================
echo     BUILD BASARILI!
echo     APK: build\app\outputs\flutter-apk\app-release.apk
echo   ============================================
echo.
explorer "build\app\outputs\flutter-apk"
pause
