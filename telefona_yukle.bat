@echo off
title Day Track - Telefona Yukle
echo.
echo   ============================================
echo     Day Track - Release Telefona Yukleniyor
echo   ============================================
echo   Telefonun baglanip kilidinin acik oldugundan
echo   emin olun.
echo.

echo   [1/2] Yeni versiyon derleniyor, lutfen bekleyin...
flutter build apk --release

if errorlevel 1 (
    echo.
    echo   [HATA] Derleme basarisiz! Kodunuzda bir hata olabilir.
    pause
    exit /b 1
)

echo.
echo   [2/2] Telefona yukleniyor...
flutter install --release

if errorlevel 1 (
    echo.
    echo   [HATA] Yukleme basarisiz!
    echo   Telefon bagli mi? USB debugging acik mi?
    pause
    exit /b 1
)

echo.
echo   ============================================
echo     YUKLEME BASARILI!
echo   ============================================
echo.
pause
