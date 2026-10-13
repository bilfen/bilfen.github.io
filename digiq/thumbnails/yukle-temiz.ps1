# YUKLE-TEMIZ: shots/<kisa>-temiz.png dosyalarini JPEG'e cevirip Supabase'e PATCH et.
# ASCII-saf dosya (PS 5.1 uyumu). Kullanim: powershell -File yukle-temiz.ps1
$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

Add-Type -AssemblyName System.Drawing
$thumb = "C:\Users\Ogrenci\Desktop\Freebuff Uygulamalar\bilfenbilisimai\digiq\thumbnails"
$anon  = 'sb_publishable_hU6il_Kq9_E_57WqaOT8BA_iLtDPpuM'
$sbUrl = 'https://zvqwhesibqntcnpqoytm.supabase.co'
$headers = @{ apikey = $anon; Authorization = "Bearer $anon" }

$kisaIdler = @('57d19dbd', '10bd5e64', '3fee370e')

$etks = Get-Content "$thumb\etkinlikler.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$tamMap = @{}
$adMap = @{}
foreach ($e in $etks) {
  $tamMap[$e.id.Substring(0, 8)] = [string]$e.id
  $adMap[$e.id] = [string]$e.ad
}

foreach ($k in $kisaIdler) {
  $id = $tamMap[$k]
  $ad = $adMap[$id]
  try {
    $png = "$thumb\shots\$k-temiz.png"
    if (!(Test-Path $png)) { throw "png yok: $png" }
    $finfo = Get-Item $png
    if ($finfo.Length -lt 3000) { throw "png cok kucuk ($($finfo.Length) B)" }

    $bmp = [System.Drawing.Image]::FromFile($png)
    $w = 800
    $h = [int]([Math]::Round(800.0 * $bmp.Height / $bmp.Width))
    if ($h -lt 1) { $h = 1 }
    $out = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::White)
    $g.DrawImage($bmp, 0, 0, $w, $h)

    $ms = New-Object System.IO.MemoryStream
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]72)
    $out.Save($ms, $codec, $ep)
    $dataUrl = 'data:image/jpeg;base64,' + [Convert]::ToBase64String($ms.ToArray())

    $g.Dispose(); $out.Dispose(); $bmp.Dispose(); $ms.Dispose()

    if ($dataUrl.Length -lt 8000) { throw "gorsel cok kucuk ($($dataUrl.Length) B)" }

    $escaped = $dataUrl.Replace('\', '\\').Replace('"', '\"')
    $body = '{"gorsel":' + '"' + $escaped + '"}'
    Invoke-RestMethod -Uri "$sbUrl/rest/v1/ozel_etkinlik?id=eq.$id" -Method Patch -Headers $headers -ContentType 'application/json' -Body $body | Out-Null

    Write-Output ("OK    " + $k + " | " + $ad + " | yuklendi " + [int]($dataUrl.Length / 1024) + " KB")
  } catch {
    Write-Output ("HATA  " + $k + " | " + $ad + " | " + $_.Exception.Message)
  }
}
