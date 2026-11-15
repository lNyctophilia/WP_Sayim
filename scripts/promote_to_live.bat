@echo off
cd /d "%~dp0\.."
title WP Sayim - Betayi Canliya Aktar
echo ===================================================
echo     WP Sayim - BETA SURUMUNU CANLIYA AKTARMA
echo ===================================================
echo.
echo DIKKAT: Bu islem 'beta' branch'indeki tum onaylanan kodlari
echo 'main' (canli) branch'ine aktaracak ve ardindan
echo canli web sitesini ve canli Worker'i guncelleyecektir.
echo.
set /p CONFIRM="Devam etmek istiyor musunuz? (E/H): "
if /i not "%CONFIRM%"=="E" (
    echo Islem iptal edildi.
    pause
    exit /b 0
)

echo.
echo [1/5] Beta branch'indeki bekleyen degisiklikler kaydediliyor...
git add -A
git commit -m "Beta son hali (canliya aktarilmadan once)" 2>nul
git push origin beta 2>nul

echo.
echo [2/5] 'main' branch'ine geciliyor...
git checkout main
if errorlevel 1 (
    echo HATA: 'main' branch'ine gecilemedi!
    pause
    exit /b 1
)
git pull origin main

echo.
echo [3/5] 'beta' branch'i 'main' ile birlestiriliyor (Merge)...
git merge beta
if errorlevel 1 (
    echo HATA: Birlestirme (merge) sirasinda cakisma olustu! Lutfen kontrol edin.
    pause
    exit /b 1
)

echo.
echo [4/5] Canli Web Deploy baslatiliyor...
call scripts\deploy_web.bat
if errorlevel 1 (
    echo HATA: Canli web deploy basarisiz!
    pause
    exit /b 1
)

echo.
echo [5/5] Canli Cloudflare Worker guncelleniyor...
cd /d "%~dp0\..\cloudflare-worker"
call npx wrangler deploy
cd /d "%~dp0\.."

echo.
echo Tekrar 'beta' branch'ine donuluyor...
git checkout beta

echo.
echo ===================================================
echo   TEBRIKLER! YENI OZELLIKLER CANLIYA AKTARILDI!
echo   Canli Web: https://lnyctophilia.github.io/WP_Sayim/
echo ===================================================
echo.
pause
