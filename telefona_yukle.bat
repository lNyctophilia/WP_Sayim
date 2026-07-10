@echo off
title WP Sayim - Telefona Yukle
echo.
echo   ============================================
echo     WP Sayim - Release Telefona Yukleniyor
echo   ============================================
echo   Telefonun baglanip kilidinin acik oldugundan
echo   emin olun. (Gerekirse telefon ekranindan 
echo   yukleme iznini onaylamaniz gerekebilir)
echo.

echo   [1/2] Yeni versiyon derleniyor, lutfen bekleyin...
call flutter build apk --release

if errorlevel 1 (
    echo.
    echo   [HATA] Derleme basarisiz! Kodunuzda bir hata olabilir.
    pause
    exit /b 1
)

echo.
echo   [2/2] Telefona yukleniyor...
call flutter install --release

if errorlevel 1 (
    echo.
    echo   [HATA] Yukleme basarisiz!
    echo   Telefon bagli mi? USB debugging acik mi?
    echo   Ekranda yukleme uyarisi ciktiysa onayladiniz mi?
    pause
    exit /b 1
)

echo.
echo   ============================================
echo     YUKLEME BASARILI!
echo   ============================================
echo.
pause
