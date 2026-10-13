@echo off
REM ============================================================
REM BILFEN DIGIQUEST - GORSEL YENILEME (tek komut)
REM Akis: hazirla.ps1 -> chrome-dongu.ps1 -> yukle.ps1 -> rapor
REM Kullanim: yenile.cmd  (bu klasorde)
REM Tekrar calistirmak guvenlidir; sadece gorselleri gunceller.
REM Not: Turkce karaktersiz ASCII dosya (cmd uyumu icin).
REM ============================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo.
echo === 1/3 HAZIRLIK: etkinlik listesi ve HTML icerikleri ===
powershell -NoProfile -ExecutionPolicy Bypass -File hazirla.ps1
if errorlevel 1 (
  echo HATA: hazirla.ps1 basarisiz.
  goto :son
)
if not exist targets.txt (
  echo HATA: targets.txt uretilmedi.
  goto :son
)

echo.
echo === 2/3 CHROME: gercek ekran goruntuleri aliniyor (bu adim uzun surebilir) ===
powershell -NoProfile -ExecutionPolicy Bypass -File chrome-dongu.ps1
if errorlevel 1 (
  echo HATA: chrome-dongu.ps1 basarisiz.
  goto :son
)

echo.
echo === 3/3 YUKLEME: JPEG cevirme + Supabase yazma ===
powershell -NoProfile -ExecutionPolicy Bypass -File yukle.ps1
if errorlevel 1 (
  echo HATA: yukle.ps1 basarisiz.
  goto :son
)

:son
echo.
echo ================= RAPOR =================
set OK=0
set HATA=0
if exist sonuc.json (
  for /f %%A in ('powershell -NoProfile -Command "(Get-Content sonuc.json -Raw | ConvertFrom-Json | Where-Object { $_.durum -eq 'OK' }).Count"') do set OK=%%A
  for /f %%A in ('powershell -NoProfile -Command "(Get-Content sonuc.json -Raw | ConvertFrom-Json | Where-Object { $_.durum -eq 'HATA' }).Count"') do set HATA=%%A
)
echo Guncellenen etkinlik: !OK!
echo Hatali etkinlik:      !HATA!
if exist progress.txt (
  echo Detayli gunluk: progress.txt
  echo Sonuc detaylari: sonuc.json
)
echo.
echo Portalda gormek icin: https://bilfen.github.io/digiq/ (sayfayi yenile: F5)
echo =========================================
endlocal
