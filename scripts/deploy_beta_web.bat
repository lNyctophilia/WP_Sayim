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
call flutter build web --release --wasm --base-href "/" --dart-define="BUILD_VERSION=%TIMESTAMP%" --dart-define="IS_BETA=true" --dart-define="CF_API_URL=https://wp-sayim-api-beta.nycgamedevs.workers.dev"
if errorlevel 1 (
    echo.
    echo HATA: Flutter Web beta build basarisiz!
    pause
    exit /b 1
)
echo Build basarili!
echo.

REM 1.5. Beta manifest ve versiyon dosyasini ekle
echo [1.5/4] Beta Manifest ve Versiyon dosyalari yerlestiriliyor...
echo {"version": "%TIMESTAMP%"} > build\web\version.json
if exist web\manifest_beta.json (
    copy /y web\manifest_beta.json build\web\manifest.json >nul
)

REM 2. Cloudflare Pages'e Yukle
echo [2/4] Cloudflare Pages'e yukleniyor (wp-sayim-beta)...
call npx --prefix cloudflare-worker wrangler pages deploy build\web --project-name=wp-sayim-beta
if errorlevel 1 (
    echo.
    echo HATA: Cloudflare Pages deploy basarisiz!
    pause
    exit /b 1
)
echo Cloudflare Pages yuklendi!
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
echo   Beta Web:    https://wp-sayim-beta.pages.dev/
echo   Beta Worker: https://wp-sayim-api-beta.nycgamedevs.workers.dev/
echo ===================================================
echo.
pause
