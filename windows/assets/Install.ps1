param([string]$LogPath, [switch]$AutoSetupWarp)
$script:LogPath = $LogPath
. (Join-Path $PSScriptRoot 'Common.ps1')

try {
    Write-TaskLog 'Windows kullanici tabanli kurulum basliyor; sistem DNS/proxy/firewall ayarlari degismeyecek.'
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Yalnizca 64 bit Windows destekleniyor.' }
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
    $hashes = @{
        'amd64' = 'cc8ac946f86994a3aed47ef1f838cfb6b7649d9245c91fcb9899654b33d61170'
        'arm64' = 'f423e10b0e5fac02ca1d2294e008bab16480938055e7620af27aba319979ccac'
    }
    $version = '3.3.0'
    $url = "https://github.com/go-gost/gost/releases/download/v$version/gost_${version}_windows_${arch}.zip"
    # Bootstrapper resolves Windows 8.3 TEMP and profile aliases before launch.
    Write-TaskLog 'Gecici dizin ve Windows profil yollari dogrulandi.'
    $stage = Join-Path $env:TEMP ('discord-warp-gost-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    try {
        $zip = Join-Path $stage 'gost.zip'
        Write-TaskLog "GOST v$version ($arch) resmi GitHub Releases paketinden indiriliyor..."
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -TimeoutSec 180
        $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $hashes[$arch]) { throw "GOST SHA256 dogrulanamadi! Indirilen dosya kullanilmadi. Beklenen $($hashes[$arch]); bulunan $actual" }
        Write-TaskLog 'GOST SHA-256 dogrulamasi basarili.'
        Write-TaskLog 'GOST arsivi aciliyor...'
        Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $stage 'unpacked') -Force
        Write-TaskLog 'Arsiv acildi; gost.exe aranip kuruluyor...'
        $gost = Get-ChildItem -LiteralPath (Join-Path $stage 'unpacked') -Filter 'gost.exe' -File -Recurse | Select-Object -First 1
        if (-not $gost) { throw 'GOST arsivinde gost.exe bulunamadi.' }
        New-Item -ItemType Directory -Path $script:AppDir -Force | Out-Null
        # Files are copied only after the upstream binary has passed integrity checks.
        $targetGost = Join-Path $script:AppDir 'gost.exe'
        if ((Test-Path -LiteralPath $targetGost -PathType Leaf) -and
            ((Get-FileHash -LiteralPath $targetGost -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $gost.FullName -Algorithm SHA256).Hash)) {
            Write-TaskLog 'Mevcut GOST ayni surumde, calisan .exe dosyasina dokunulmayacak.'
        } else {
            Copy-Item -LiteralPath $gost.FullName -Destination $targetGost -Force
        }
        if (-not (Test-Path -LiteralPath (Join-Path $script:AppDir 'gost.exe') -PathType Leaf)) {
            throw 'gost.exe kopyalama sonrasi bulunamadi; Windows Guvenligi > Koruma gecmisi bolumunu kontrol edin.'
        }
        Write-TaskLog 'GOST uygulama klasorune kopyalandi.' 
    } finally { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }

    Write-TaskLog 'Baslatici ve tani betikleri kopyalaniyor...'
    foreach ($name in @('Common.ps1','Launch-Discord.ps1','Diagnose.ps1','Remove.ps1','Setup-Warp.ps1')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $script:AppDir $name) -Force
    }
    $bundledExe = [Environment]::GetEnvironmentVariable('DWG_ORIGINAL_EXE')
    if (-not $bundledExe -or -not (Test-Path -LiteralPath $bundledExe -PathType Leaf)) {
        throw 'Kurulum programinin orijinal .exe dosyasi bulunamadi. Setup programini yeniden acip Kur / Onar deneyin.'
    }
    $targetExe = Join-Path $script:AppDir 'Discord-WARP-GOST.exe'
    # Update safely: Windows may prevent replacing a running executable.
    Copy-Item -LiteralPath $bundledExe -Destination $targetExe -Force
    Write-TaskLog 'Konsolsuz Windows baslaticisi kopyalandi.'
    Write-TaskLog 'Masaustu ve Baslat kisayollari olusturuluyor...'
    $desktop = [Environment]::GetFolderPath('Desktop')
    New-UserShortcut (Join-Path $desktop 'Discord (WARP).lnk') 'Launch-Discord.ps1' 'Discord only, local WARP proxy'
    New-UserShortcut (Join-Path $script:StartMenuDir 'Discord (WARP).lnk') 'Launch-Discord.ps1' 'Discord only, local WARP proxy'
    New-UserShortcut (Join-Path $script:StartMenuDir 'Discord WARP - Diagnose.lnk') 'Diagnose.ps1' 'Read-only connection diagnostics'
    New-UserShortcut (Join-Path $script:StartMenuDir 'Discord WARP - Uninstall.lnk') 'Remove.ps1' 'Remove user-scoped Discord WARP + GOST files'

    Write-TaskLog 'Windows Uygulamalar listesinin kaldirma girdisi olusturuluyor...'
    $uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiscordWARP-GOST'
    New-Item -Path $uninstallKey -Force | Out-Null
    New-ItemProperty -Path $uninstallKey -Name DisplayName -Value 'Discord WARP + GOST (Vista Aero)'  -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallKey -Name DisplayVersion -Value '1.0.0' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallKey -Name Publisher -Value 'Community project' -PropertyType String -Force | Out-Null
    $uninstaller = Join-Path $script:AppDir 'Remove.ps1'
    $uninstallString = '"' + (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') + '" -NoProfile -ExecutionPolicy Bypass -File "' + $uninstaller + '"'
    New-ItemProperty -Path $uninstallKey -Name UninstallString -Value $uninstallString -PropertyType String -Force | Out-Null

    Write-TaskLog 'Kurulum dosyalari ve kisayollar tamamlandi.'
    if ($AutoSetupWarp) {
        Write-TaskLog 'Kullanici onayiyla WARP otomatik hazirlama asamasina geciliyor...'
        $warpSetup = Join-Path $PSScriptRoot 'Setup-Warp.ps1'
        $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $warpArgs = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + $warpSetup + '" -LogPath "' + $LogPath + '" -UserConsented'
        $warpProcess = Start-Process -FilePath $psExe -ArgumentList $warpArgs -PassThru -Wait -WindowStyle Hidden
        if ($warpProcess.ExitCode -ne 0) {
            throw 'WARP otomatik hazirlama tamamlanamadi. GOST ve kisayollar kuruldu; WARP Hazirla dugmesinden tekrar deneyebilirsiniz.'
        }
        Save-WarpConsent
        Write-TaskLog 'WARP otomatik hazirligi onayi kaydedildi; Discord baslatilirken yeniden gerekirse kontrol edilecek.'
    }

    if (-not (Get-WarpCli)) { Write-TaskLog 'UYARI: Cloudflare WARP kurulu degil. Resmi uygulamadan yukleyin, sonra Local Proxy port 40000 secin.' }
    else {
        try { Assert-WarpProxyMode | Out-Null; Write-TaskLog 'WARP Local Proxy 40000 dogrulandi.' }
        catch { Write-TaskLog ('UYARI: ' + $_.Exception.Message.Split("`n")[0]) }
    }
    if (-not (Get-DiscordExecutable)) { Write-TaskLog 'UYARI: Discord Windows masaustu uygulamasi bulunamadi. Resmi Discord kurulumunu yapin.' }
    Write-TaskLog 'HAZIR: Discord (WARP) kisayolu eklendi. Sistem ag ayarlari degistirilmedi.'
    exit 0
} catch {
    Write-TaskLog ('HATA: ' + $_.Exception.Message)
    if ($_.InvocationInfo.ScriptLineNumber) { Write-TaskLog ('HATA KONUMU: Install.ps1 satir ' + $_.InvocationInfo.ScriptLineNumber) }
    Write-TaskLog 'Windows Defender bir dosyayi engellediyse Windows Guvenligi > Virus ve tehdit korumasi > Koruma gecmisi ekranindaki tespit adini kontrol edin. Korumayi kapatmayin.'
    exit 1
}
