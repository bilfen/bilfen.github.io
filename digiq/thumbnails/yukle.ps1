# YUKLE: shots altindaki id.png dosyalarini JPEG'e cevirip Supabase'e PATCH et.
# ASCII-saf dosya (PS 5.1 uyumu icin).
$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

Add-Type -AssemblyName System.Drawing
$thumb = "C:\Users\Ogrenci\Desktop\Freebuff Uygulamalar\bilfenbilisimai\digiq\thumbnails"
$shot  = "$thumb\shots"
$anon  = 'sb_publishable_hU6il_Kq9_E_57WqaOT8BA_iLtDPpuM'
$sbUrl = 'https://zvqwhesibqntcnpqoytm.supabase.co'
$headers = @{ apikey = $anon; Authorization = "Bearer $anon" }

$etks = Get-Content "$thumb\etkinlikler.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$adHarita = @{}
foreach ($e in $etks) { $adHarita[$e.id] = [string]$e.ad }
$tipHarita = @{}
foreach ($e in $etks) { $tipHarita[$e.id] = [string]$e.tip }

$targets = Get-Content "$thumb\targets.txt" -Encoding UTF8 | Where-Object { $_.Trim() }
$progress = "$thumb\progress.txt"
$sonuclar = New-Object System.Collections.ArrayList
$ok = 0; $hata = 0

foreach ($satir in $targets) {
  $parca = $satir.Split('|')
  if ($parca.Count -lt 2) { continue }
  $id = $parca[0]
  $png = "$shot\$id.png"
  $ad = $adHarita[$id]
  if ($ad -and $ad.Length -gt 34) { $ad = $ad.Substring(0, 34) }
  try {
    if (!(Test-Path $png)) { throw "png yok" }
    $finfo = Get-Item $png
    if ($finfo.Length -lt 4000) { throw "png cok kucuk ($($finfo.Length) B)" }

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

    if ($dataUrl.Length -lt 5000) { throw "gorsel cok kucuk ($($dataUrl.Length) B)" }

    $escaped = $dataUrl.Replace('\', '\\').Replace('"', '\"')
    $body = '{"gorsel":' + '"' + $escaped + '"}'
    Invoke-RestMethod -Uri "$sbUrl/rest/v1/ozel_etkinlik?id=eq.$id" -Method Patch -Headers $headers -ContentType 'application/json' -Body $body | Out-Null

    $ok++
    $tip = $tipHarita[$id]
    $null = $sonuclar.Add([pscustomobject]@{ id = $id; ad = $ad; tip = $tip; durum = 'OK'; boyut = [int]($dataUrl.Length / 1024); mesaj = '' })
    Add-Content $progress ("OK    " + $id.Substring(0,8) + " | " + $ad + " | " + $dataUrl.Length + " B") -Encoding UTF8
  } catch {
    $hata++
    $msg = $_.Exception.Message
    if ($msg.Length -gt 140) { $msg = $msg.Substring(0, 140) }
    $tip = $tipHarita[$id]
    $null = $sonuclar.Add([pscustomobject]@{ id = $id; ad = $ad; tip = $tip; durum = 'HATA'; boyut = 0; mesaj = $msg })
    Add-Content $progress ("HATA  " + $id.Substring(0,8) + " | " + $ad + " | $msg") -Encoding UTF8
  }
}

$sonuclar | ConvertTo-Json -Depth 3 | Set-Content "$thumb\sonuc.json" -Encoding UTF8
Add-Content $progress ("BITTI: $ok basarili / $hata hata") -Encoding UTF8
Write-Output ("BITTI: $ok / " + ($ok + $hata))
