param([string]$LogPath)
$ErrorActionPreference = 'Stop'
$script:LogPath = if ($LogPath) { $LogPath } else { Join-Path $env:TEMP 'discord-warp-gost-last-launch.log' }
. (Join-Path $PSScriptRoot 'Common.ps1')
Add-Type -AssemblyName System.Windows.Forms

function Stop-Launch([string]$message) {
    Write-TaskLog ('HATA: ' + $message)
    [System.Windows.Forms.MessageBox]::Show($message, 'Discord (WARP) - baglanti sorunu', 'OK', 'Warning') | Out-Null
    exit 1
}
function Prepare-WarpIfNeeded {
    $configured = $false
    try {
        Assert-WarpProxyMode | Out-Null
        $configured = $true
        Write-TaskLog 'WARP WarpProxy 40000 modu dogrulandi.'
    } catch {
        Write-TaskLog ('WARP proxy henuz hazir degil: ' + $_.Exception.Message.Split("`n")[0])
    }
    if (-not $configured) {
        if (-not (Confirm-WarpConsent)) { Stop-Launch 'WARP Local Proxy 40000 hazirlanmasina izin verilmedi. Discord baslatilmadi.' }
        Write-TaskLog 'Kullanici onayiyla WARP kurulumu/Local Proxy hazirligi basliyor...'
        $setup = Join-Path $script:AppDir 'Setup-Warp.ps1'
        if (-not (Test-Path -LiteralPath $setup)) { Stop-Launch 'WARP kurulum betigi bulunamadi. Kur / Onar ile uygulamayi tekrar yukleyin.' }
        $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        # Wrap the output in the same log file so the error is visible to the user.
        $args = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + $setup + '" -LogPath "' + $script:LogPath + '" -UserConsented'
        $task = Start-Process -FilePath $ps -ArgumentList $args -PassThru -Wait -WindowStyle Hidden
        if ($task.ExitCode -ne 0) { Stop-Launch ('WARP otomatik hazirligi tamamlanamadi. Ayrinti: ' + $script:LogPath + '. Mevcut WARP VPN baglantisi varsa otomatik degistirilmez.') }
        Assert-WarpProxyMode | Out-Null
    }
    $cli = Get-WarpCli
    if (-not $cli) { Stop-Launch 'warp-cli bulunamadi. Kur / Onar adimini tekrarlayin.' }
    $status = (& $cli status 2>&1 | Out-String)
    # Do not treat 'Disconnected' or 'Not Connected' as connected.
    if ($status -match '(?i)\bDisconnected\b|\bNot Connected\b') {
        Write-TaskLog 'WARP yalnizca Local Proxy olarak baglaniyor...'
        Assert-WarpProxyMode | Out-Null
        & $cli connect 2>&1 | Out-Null
    } elseif ($status -notmatch '(?im)^\s*(?:Status(?: update)?\s*:\s*)?Connected\b') {
        Stop-Launch ('WARP baglanti durumu kesin anlasilamadi. Degisiklik yapilmadi: ' + $status.Trim())
    }
    for ($i=0; $i -lt 20; $i++) {
        if (Test-LocalTcpPort 40000) { break }
        Start-Sleep -Seconds 1
    }
    if (-not (Test-LocalTcpPort 40000)) { Stop-Launch 'WARP Local Proxy 40000 portu acilmadi. WARP servis ve baglanti durumunu kontrol edin.' }
    Assert-WarpProxyMode | Out-Null
    Write-TaskLog 'WARP 127.0.0.1:40000 hazir.'
}
function Check-DiscordProcesses {
    $running = @(Get-Process -Name Discord -ErrorAction SilentlyContinue)
    if ($running.Count -eq 0) { return }
    $msg = "Discord zaten calisiyor veya Starting ekraninda takilmis. Proxy parametresi calisan bir Discord oturumuna uygulanamayabilir.`n`nTum Discord sureclerini simdi kapatip Discord (WARP) ile yeniden acalim mi? Kaydedilmemis oturum verileri kaybolabilir."
    $choice = [System.Windows.Forms.MessageBox]::Show($msg,'Discord (WARP) - mevcut Discord', 'YesNo', 'Question')
    if ($choice -ne 'Yes') { Stop-Launch 'Discord calisirken proxy ayari degistirilemiyor. Tepsiden Discord uygulamasini tamamen kapatip yeniden deneyin.' }
    foreach ($p in $running) { Stop-Process -Id $p.Id -Force -ErrorAction Stop }
    Start-Sleep -Seconds 2
    if (@(Get-Process -Name Discord -ErrorAction SilentlyContinue).Count -gt 0) { Stop-Launch 'Discord hala calisiyor. Gorev Yoneticisinden kapatin veya Windows oturumunu yeniden baslatin.' }
    Write-TaskLog 'Kullanici onayiyla onceki Discord surecleri kapatildi.'
}
function Start-OwnedGost {
    $exe = Join-Path $script:AppDir 'gost.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { Stop-Launch 'GOST bulunamadi. Kur / Onar adimini calistirin.' }
    $pidFile = Join-Path $script:AppDir 'gost.pid'
    $tracked = $null
    if (Test-Path -LiteralPath $pidFile) {
        $pidNum = 0
        if ([int]::TryParse((Get-Content -LiteralPath $pidFile -Raw).Trim(), [ref]$pidNum)) {
            $candidate = Get-Process -Id $pidNum -ErrorAction SilentlyContinue
            if ($candidate -and ($candidate.Path -eq $exe)) { $tracked = $candidate }
        }
    }
    if (Test-LocalTcpPort 40001) {
        if (-not $tracked) { Stop-Launch '127.0.0.1:40001 baska bir uygulama tarafindan kullanimda; o isleme dokunmuyoruz.' }
        Write-TaskLog 'Daha once baslatilan kendi GOST proxy surecimiz kullaniliyor.'
    } else {
        if ($tracked) { Stop-Process -Id $tracked.Id -Force -ErrorAction SilentlyContinue }
        $args = @('-L','http://127.0.0.1:40001?resolver=https://1.0.0.1/dns-query','-F','socks5://127.0.0.1:40000')
        $proc = Start-Process -FilePath $exe -ArgumentList $args -WindowStyle Hidden -PassThru
        [IO.File]::WriteAllText($pidFile, $proc.Id.ToString())
        for ($i=0; $i -lt 20; $i++) { if (Test-LocalTcpPort 40001) { break }; Start-Sleep -Milliseconds 300 }
        if (-not (Test-LocalTcpPort 40001)) { Stop-Launch 'GOST localhost:40001 baslatilamadi. Defender koruma gecmisini kontrol edin.' }
    }
    Write-TaskLog 'GOST localhost:40001 hazir.'
}
function Test-DiscordHttps {
    $curl = Get-Command 'curl.exe' -ErrorAction SilentlyContinue
    if (-not $curl) { Stop-Launch 'Windows curl.exe bulunamadi; dogrulanmamis baglanti ile Discord baslatilmayacak.' }
    Write-TaskLog 'Discord HTTPS proxy testi yapiliyor...'
    $testText = (& $curl.Source --silent --show-error --head --max-time 20 -x 'http://127.0.0.1:40001' 'https://discordapp.com/app' 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Stop-Launch ('Discord HTTPS proxy testi basarisiz: ' + $testText) }
    if ($testText -notmatch '(?im)^HTTP/\S+\s+(?:200|301|302|403)\b') { Stop-Launch ('HTTPS proxy sunucusundan beklenmeyen cevap: ' + $testText) }
    Write-TaskLog 'HTTPS proxy testi gecti.'
}
try {
    Write-TaskLog 'Discord WARP baslatiliyor; sistem DNS / genel proxy ayarlari degistirilmeyecek.'
    $discord = Get-DiscordExecutable
    if (-not $discord) { Stop-Launch 'Discord masaustu programi bulunamadi. Resmi Discord kurulumunu tamamlayin.' }
    # Detect and request consent before closing an already running Discord.
    Check-DiscordProcesses
    Prepare-WarpIfNeeded
    Start-OwnedGost
    Test-DiscordHttps
    Write-TaskLog 'Proxy baglantisi dogrulandi; Discord baslatiliyor...'
    $p = Start-Process -FilePath $discord -ArgumentList @('--proxy-server=http://127.0.0.1:40001') -PassThru
    if (-not $p) { Stop-Launch 'Discord sureci baslatilamadi.' }
    Write-TaskLog ('Discord baslatma istegi tamamlandi (PID ' + $p.Id + '). Starting ekraninin gecilmesi ayrica dogrulanmalidir.')
    exit 0
} catch {
    $message = $_.Exception.Message
    Write-TaskLog ('BASLATMA HATASI: ' + $message)
    [System.Windows.Forms.MessageBox]::Show($message, 'Discord (WARP) - hata', 'OK', 'Error') | Out-Null
    exit 1
}
