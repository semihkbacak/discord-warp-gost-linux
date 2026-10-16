param([string]$LogPath, [switch]$UserConsented)
$script:LogPath = $LogPath
. (Join-Path $PSScriptRoot 'Common.ps1')

# WARP is a third-party Windows service. This script never edits system DNS,
# Windows global proxy, Windows Firewall, or network routes directly.
# Only proceed after a visible user decision in the setup GUI.
if (-not $UserConsented) {
    Write-TaskLog 'HATA: WARP kurulumu/yapilandirmasi icin acik kullanici onayi gerekiyor.'
    exit 2
}

function Run-WarpCli([string[]]$Arguments, [bool]$AllowFailure = $false) {
    $cli = Get-WarpCli
    if (-not $cli) { throw 'warp-cli.exe bulunamadi; WARP kurulumu bitmemis olabilir.' }
    # Windows PowerShell 5.1 may elevate redirected native stderr to a terminating error.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $text = (& $cli @Arguments 2>&1 | Out-String).Trim()
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    if (($code -ne 0) -and (-not $AllowFailure)) {
        throw ('warp-cli ' + ($Arguments -join ' ') + ' basarisiz. Kod: ' + $code + ' | ' + $text)
    }
    return @{ ExitCode = $code; Text = $text }
}
function Get-WarpConnectionState([string]$StatusText) {
    if ($StatusText -match '(?i)\bDisconnected\b|\bNot Connected\b') { return 'disconnected' }
    if ($StatusText -match '(?i)\bConnected\b') { return 'connected' }
    return 'unknown'
}
try {
    Write-TaskLog 'WARP otomatik hazirlama basladi; yalnizca kullanici onayiyla ilerleniyor.'
    $cli = Get-WarpCli
    if (-not $cli) {
        $winget = Get-Command 'winget.exe' -ErrorAction SilentlyContinue
        if (-not $winget) {
            throw 'WARP kurulu degil ve Windows Paket Yoneticisi (winget) bulunamadi. Microsoft App Installer veya resmi Cloudflare kurucusunu yukleyin.'
        }
        Write-TaskLog 'WARP bulunamadi. Cloudflare.Warp resmi WinGet paketinden yuklenecek; Windows yonetici onayi isteyebilir.'
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $wingetResult = (& $winget.Source install --id Cloudflare.Warp --exact --source winget --accept-source-agreements --accept-package-agreements 2>&1 | Out-String).Trim()
            $code = $LASTEXITCODE
        } finally { $ErrorActionPreference = $previous }
        if ($code -ne 0) { throw ('Cloudflare.Warp yukleme basarisiz. winget kodu: ' + $code + ' | ' + $wingetResult) }
        Write-TaskLog 'Cloudflare WARP yuklemesi tamamlandi; servisin hazir olmasi bekleniyor.'
        for ($i = 0; $i -lt 30; $i++) {
            if (Get-WarpCli) { break }
            Start-Sleep -Seconds 2
        }
        $cli = Get-WarpCli
        if (-not $cli) { throw 'WARP yuklenmis gorunuyor fakat warp-cli bulunamadi. Bilgisayari yeniden baslatin ya da Cloudflare WARP uygulamasini acin.' }
    } else {
        Write-TaskLog 'Cloudflare WARP zaten kurulu; yeniden yuklenmeyecek.'
    }

    # Fail-closed if an existing VPN/DNS WARP mode is actively connected.
    $settings = Run-WarpCli @('settings') $true
    $status = Run-WarpCli @('status') $true
    if (($settings.Text -notmatch '(?is)WarpProxy\s+on\s+port\s+40000') -and ((Get-WarpConnectionState $status.Text) -eq 'connected')) {
        throw 'WARP baska bir modda zaten BAGLI. Mevcut VPN/DNS baglantisini degistirmemek icin otomatik ayar durduruldu. WARP uygulamasindan baglantiyi kendiniz kesin, sonra WARP Hazirla secenegini yeniden kullanin.'
    }
    if ($settings.Text -match '(?is)WarpProxy\s+on\s+port\s+40000') {
        Write-TaskLog 'WARP zaten Local Proxy 40000 modunda.'
    } else {
        # CLI syntax is tested before issuing mutating commands; unsupported
        # and managed-enrollment cases require the official WARP UI.
        $modeHelp = Run-WarpCli @('mode','--help') $true
        $proxyHelp = Run-WarpCli @('proxy','--help') $true
        if ($modeHelp.ExitCode -ne 0 -or $proxyHelp.ExitCode -ne 0) {
            throw 'Mevcut WARP surumunun CLI proxy komutlari dogrulanamadi. Resmi WARP arayuzunden Local Proxy 40000 secin; farkli bir mod denemesi yapilmadi.'
        }
        $reg = Run-WarpCli @('registration','show') $true
        if (($reg.ExitCode -ne 0) -or ($reg.Text -match '(?i)not registered|registration missing|no registration')) {
            Write-TaskLog 'WARP cihazi henuz kayitli degil; kullanici onayiyla kayit baslatiliyor.'
            # User affirmed the official terms in the GUI. Never silently enroll.
            $register = Run-WarpCli @('--accept-tos','registration','new') $true
            if ($register.ExitCode -ne 0) {
                throw ('WARP ilk kaydi otomatik tamamlanamadi. Resmi WARP uygulamasinda kaydi tamamlayin. ' + $register.Text)
            }
        }
        $modeStatus = Run-WarpCli @('status') $true
        if (($modeStatus.ExitCode -ne 0) -or ((Get-WarpConnectionState $modeStatus.Text) -ne 'disconnected')) {
            throw ('WARP bagli olmadigini kesin dogrulayamadik; ag ayarlarina dokunulmayacak. WARP uygulamasindan baglantiyi durdurun. Durum: ' + $modeStatus.Text)
        }
        Write-TaskLog 'WARP Local Proxy modu seciliyor (butun sistem VPN modu DEGIL).'
        [void](Run-WarpCli @('mode','proxy'))
        Write-TaskLog 'WARP proxy portu 40000 olarak ayarlaniyor.'
        [void](Run-WarpCli @('proxy','port','40000'))
        $verified = Run-WarpCli @('settings')
        if ($verified.Text -notmatch '(?is)WarpProxy\s+on\s+port\s+40000') {
            throw 'CLI cevap verdi ancak WarpProxy on port 40000 dogrulanamadi. WARP GUI > Preferences > Advanced > Configure Proxy bolumunu kontrol edin.'
        }
        Write-TaskLog 'WARP Local Proxy 40000 dogrulandi.'
    }
    $status = Run-WarpCli @('status') $true
    $state = Get-WarpConnectionState $status.Text
    if ($state -eq 'unknown') { throw ('WARP durumunu anlayamadik; otomatik baglanti guvenlik icin durduruldu. ' + $status.Text) }
    if ($state -eq 'disconnected') {
        $checked = Run-WarpCli @('settings')
        if ($checked.Text -notmatch '(?is)WarpProxy\s+on\s+port\s+40000') {
            throw 'WARP baglanmadan hemen once proxy modu dogrulanamadi, guvenlik nedeniyle baglanilmadi.'
        }
        Write-TaskLog 'WARP yalnizca Local Proxy olarak baglaniyor...'
        [void](Run-WarpCli @('connect'))
    }
    $ready = $false
    for ($i = 0; $i -lt 20; $i++) {
        if (Test-LocalTcpPort 40000) { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'WARP proxy port 40000 acilmadi. WARP servis durumunu / yetkileri kontrol edin.' }
    $finalSettings = Run-WarpCli @('settings')
    if ($finalSettings.Text -notmatch '(?is)WarpProxy\s+on\s+port\s+40000') {
        throw 'Baglanti sonrasi WARP proxy modu kayboldu; guvenlik kontrolu gecmedi.'
    }
    Save-WarpConsent
    Write-TaskLog 'BASARILI: WARP yalnizca 127.0.0.1:40000 Local Proxy olarak hazir.'
    Write-TaskLog 'Windows sistem DNS/varsayilan rota/proxy/firewall ayarlari bu betik tarafindan degistirilmedi.'
    exit 0
} catch {
    Write-TaskLog ('WARP HATA: ' + $_.Exception.Message)
    Write-TaskLog 'Local Proxy dogrulanamadigi icin Discord baglantisini otomatik baslatmayin.'
    exit 1
}
