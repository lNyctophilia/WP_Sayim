@echo off
cd /d "%~dp0\.."
title WP Sayim - Shorebird Yama (Patch) Gonder
echo.
echo   ============================================
echo     WP Sayim - Shorebird Yamasi (Guncelleme)
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

:: Shorebird kullanarak sadece kod guncellemesini buluta atiyoruz
call C:\Users\Halil\.shorebird\bin\shorebird.bat patch android --release-version=latest -- --dart-define="BUILD_VERSION=%LAST_VERSION%"

if errorlevel 1 (
    echo.
    echo   [HATA] Shorebird Yama Gonderimi Basarisiz!
    pause
    exit /b 1
)

echo.
echo   ============================================
echo     YAMA (PATCH) BASARIYLA GONDERILDI!
echo     Uygulamayi kullananlar kapatip actiklarinda
echo     guncel kodlari gorecekler. (APK kurulumu yok!)
echo   ============================================
echo.
pause
