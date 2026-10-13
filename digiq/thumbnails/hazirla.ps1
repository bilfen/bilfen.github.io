# HAZIRLA: etkinlikleri listele, kod/dosya iceriklerini shots altina HTML olarak yaz,
# hedef listesini targets.txt (id|tip|hedefURL) olarak uret.
# ASCII-saf dosya (PS 5.1 uyumu icin).
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$thumb = "C:\Users\Ogrenci\Desktop\Freebuff Uygulamalar\bilfenbilisimai\digiq\thumbnails"
$shot  = "$thumb\shots"
New-Item -ItemType Directory -Force $shot | Out-Null

$etks = Get-Content "$thumb\etkinlikler.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$hedef = @($etks | Where-Object { $_.durum -ne 'reddedildi' -and $_.icerik })

$satirlar = New-Object System.Collections.ArrayList
foreach ($e in $hedef) {
  $id = [string]$e.id
  $tip = [string]$e.tip
  if ($tip -eq 'drive') {
    $adr = ([string]$e.icerik).Trim()
    if ($adr -notmatch '^https?://') { continue }
  } else {
    $kod = [string]$e.icerik
    if ($kod -notmatch '(?i)<html[\s>]') {
      $kod = "<!DOCTYPE html><html><head><meta charset=`"utf-8`"><meta name=`"viewport`" content=`"width=device-width,initial-scale=1`"></head><body>$kod</body></html>"
    }
    $htmlDosya = "$shot\$id.html"
    [System.IO.File]::WriteAllText($htmlDosya, $kod, (New-Object System.Text.UTF8Encoding($false)))
    $adr = "file:///" + ($htmlDosya -replace '\\', '/')
  }
  $null = $satirlar.Add("$id|$tip|$adr")
}

Set-Content "$thumb\targets.txt" ($satirlar -join "`r`n") -Encoding UTF8
Set-Content "$thumb\progress.txt" ("BASLANGIC: " + $satirlar.Count) -Encoding UTF8
Write-Output ("HAZIR: " + $satirlar.Count + " hedef")
