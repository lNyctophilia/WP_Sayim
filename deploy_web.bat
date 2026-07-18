@echo off
cd /d "%~dp0"
echo ===================================
echo   WP Sayim - Web Build ve Deploy
echo ===================================
echo.

REM 0. Zaman damgasi olustur (Dart Define ve PWA Cache icin)
set TIMESTAMP=%date%-%time%
set TIMESTAMP=%TIMESTAMP: =_%

REM 1. Flutter Web Build
echo [1/4] Flutter Web build aliniyor...
call flutter build web --release --base-href "/WP_Sayim/" --dart-define="BUILD_VERSION=%TIMESTAMP%"
if errorlevel 1 (
    echo HATA: Flutter web build basarisiz!
    pause
    exit /b 1
)
echo Build basarili!
echo.

REM 1.5. Versiyon dosyasi olustur (PWA Cache guncelleme icin)
echo {"version": "%TIMESTAMP%"} > build\web\version.json

REM 2. docs klasorunu temizle ve yeni build'i kopyala
echo [2/4] Build dosyalari docs/ klasorune kopyalaniyor...
if exist docs rmdir /s /q docs
mkdir docs
xcopy build\web\* docs\ /s /e /q
echo Kopyalama tamamlandi!
echo.

REM 3. Git ile commit ve push
echo [3/4] Git commit yapiliyor...
git add docs/
git add -A
git commit -m "Web build guncellendi - %date% %time:~0,5%"
echo.

echo [4/4] GitHub'a push ediliyor...
git push origin main
echo.

echo ===================================
echo   DEPLOY TAMAMLANDI!
echo   Site: https://lnyctophilia.github.io/WP_Sayim/
echo ===================================
pause
