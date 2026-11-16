@echo off
cd /d "%~dp0\.."
title WP Sayim - Beta Web & Worker Deploy
echo ===================================================
echo     WP Sayim - BETA (TEST) SURUMU YAYINLANIYOR
echo ===================================================
echo.

REM 0. Zaman damgasi olustur
set TIMESTAMP=%date%-%time%
set TIMESTAMP=%TIMESTAMP: =_%

REM 1. Flutter Web Beta Build
echo [1/4] Flutter Web (Beta) build aliniyor...
call flutter build web --release --base-href "/" --dart-define="BUILD_VERSION=%TIMESTAMP%" --dart-define="IS_BETA=true" --dart-define="CF_API_URL=https://wp-sayim-api-beta.nycgamedevs.workers.dev"
if errorlevel 1 (
    echo.
    echo HATA: Flutter Web beta build basarisiz!
    if "%~1"=="" pause
    exit /b 1
)
echo Build basarili!
echo.

REM 1.5. Beta manifest ve versiyon dosyasini ekle
echo [1.5/4] Beta Manifest ve Versiyon dosyalari yerlestiriliyor...
powershell -Command "@{'version' = '%TIMESTAMP%'} | ConvertTo-Json | Set-Content 'build\web\version.json'"
if exist web\manifest_beta.json (
    copy /y web\manifest_beta.json build\web\manifest.json >nul
)

REM 1.7. Cache Busting (flutter_bootstrap.js icindeki dosyalara timestamp ekle)
powershell -Command "(Get-Content build\web\flutter_bootstrap.js).Replace('\"main.dart.js\"', '\"main.dart.js?v=%TIMESTAMP%\"') | Set-Content build\web\flutter_bootstrap.js"

REM 2. Firebase Hosting'e Yukle (Google CDN - Turkiye'de 100% erisilebilir)
echo [2/4] Firebase Hosting'e yukleniyor (wp-sayim-beta.web.app)...
call firebase deploy --only hosting
if errorlevel 1 (
    echo.
    echo HATA: Firebase Hosting deploy basarisiz!
    if "%~1"=="" pause
    exit /b 1
)
echo Firebase Hosting yuklendi!
echo.

REM 3. Beta Cloudflare Worker Deploy
echo [3/4] Beta Cloudflare Worker deploy ediliyor (wp-sayim-api-beta)...
cd /d "%~dp0\..\cloudflare-worker"
call npx wrangler deploy --env beta
if errorlevel 1 (
    echo.
    echo UYARI: Worker deploy basarisiz oldu veya degisiklik yok.
)
cd /d "%~dp0\.."
echo.

REM 4. Git Push (beta branch)
echo [4/4] Beta kodlari GitHub'a push ediliyor...
git add -A
git commit -m "Beta build guncellendi - %date% %time:~0,5%"
git push origin beta
echo.

echo ===================================================
echo   BETA YAYINLANDI!
echo   Beta Web:    https://wp-sayim-beta.web.app/
echo   Beta Worker: https://wp-sayim-api-beta.nycgamedevs.workers.dev/
echo ===================================================
echo.
if "%~1"=="" pause
