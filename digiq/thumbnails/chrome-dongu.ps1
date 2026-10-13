# CHROME-DONGU: targets.txt satirlarini tek tek headless Chrome ile acar,
# shots/<id>.png olarak ekran goruntusu alir. ASCII-saf dosya (PS 5.1 uyumu).
$ErrorActionPreference = 'Continue'

$thumb = "C:\Users\Ogrenci\Desktop\Freebuff Uygulamalar\bilfenbilisimai\digiq\thumbnails"
$shot  = "$thumb\shots"
$targets = "$thumb\targets.txt"
$progress = "$thumb\progress.txt"

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (!(Test-Path $chrome)) { $chrome = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" }
if (!(Test-Path $chrome)) { Write-Output "HATA: Chrome/Edge bulunamadi"; exit 1 }

if (!(Test-Path $targets)) { Write-Output "HATA: targets.txt yok - once hazirla.ps1 calistirin"; exit 1 }

$satirlar = Get-Content $targets -Encoding UTF8 | Where-Object { $_.Trim() }
$toplam = 0; $basari = 0

foreach ($satir in $satirlar) {
  $parca = $satir.Split('|')
  if ($parca.Count -lt 3) { continue }
  $id = $parca[0]
  $tip = $parca[1]
  $adres = $parca[2].Trim()
  $toplam++
  $png = "$shot\$id.png"
  $prof = "$shot\prof-$id"
  if (Test-Path $png) { Remove-Item $png -Force -ErrorAction SilentlyContinue }
  if (Test-Path $prof) { Remove-Item $prof -Recurse -Force -ErrorAction SilentlyContinue }

  # Chrome'u ProcessStartInfo ile tam kontrol ederek calistir:
  # yollarda bosluk oldugu icin argumanlar tek string ve tek tek tirnaklanir.
  $arglar = '--headless=new --disable-gpu --hide-scrollbars --no-first-run --no-default-browser-check ' +
    '"--user-data-dir=' + $prof + '" ' +
    '"--screenshot=' + $png + '" ' +
    '--window-size=1280,800 --virtual-time-budget=15000 ' +
    '"' + $adres + '"'
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $chrome
  $psi.Arguments = $arglar
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = [System.Diagnostics.Process]::Start($psi)
  $null = $p.WaitForExit(60000)
  if (!$p.HasExited) { try { $p.Kill() } catch {} }
  Start-Sleep -Milliseconds 400

  if (Test-Path $png -PathType Leaf) {
    $boyut = (Get-Item $png).Length
    if ($boyut -gt 3000) {
      $basari++
      Add-Content $progress ("OK    " + $id.Substring(0,8) + " | screenshot " + $boyut + " B") -Encoding UTF8
      Write-Output ("OK    " + $id.Substring(0,8) + " ($tip)")
    } else {
      Add-Content $progress ("HATA  " + $id.Substring(0,8) + " | png cok kucuk ($boyut B)") -Encoding UTF8
      Write-Output ("HATA  " + $id.Substring(0,8) + " ($tip): png cok kucuk")
    }
  } else {
    Add-Content $progress ("HATA  " + $id.Substring(0,8) + " | screenshot olusmadi (chrome cikis: " + $p.ExitCode + ")") -Encoding UTF8
    Write-Output ("HATA  " + $id.Substring(0,8) + " ($tip): screenshot olusmadi")
  }
  Remove-Item $prof -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output ("CHROME-BITTI: $basari / $toplam ekran goruntusu alindi")
