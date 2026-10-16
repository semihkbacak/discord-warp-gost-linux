param([string]$LogPath)
$script:LogPath = $LogPath
. (Join-Path $PSScriptRoot 'Common.ps1')

try {
    if (-not $LogPath) {
        Add-Type -AssemblyName System.Windows.Forms
        $answer = [System.Windows.Forms.MessageBox]::Show('Discord WARP + GOST baslaticisini kaldirmak istiyor musunuz? Discord, WARP ve sistem DNS ayarlari korunacak.', 'Discord WARP - Kaldirma', 'YesNo', 'Question')
        if ($answer -ne 'Yes') { exit 0 }
    }
    $pidFile = Join-Path $script:AppDir 'gost.pid'
    if (Test-Path -LiteralPath $pidFile) {
        $pidNumber = 0
        if ([int]::TryParse((Get-Content -LiteralPath $pidFile -Raw).Trim(), [ref]$pidNumber)) {
            $p = Get-Process -Id $pidNumber -ErrorAction SilentlyContinue
            $expected = Join-Path $script:AppDir 'gost.exe'
            if ($p -and ($p.Path -eq $expected)) {
                Stop-Process -Id $pidNumber -Force
                Write-TaskLog 'Bu uygulamanin baslattigi GOST islemi durduruldu.'
            }
        }
    }
    $desktop = [Environment]::GetFolderPath('Desktop')
    foreach ($item in @(
        (Join-Path $desktop 'Discord (WARP).lnk'),
        (Join-Path $script:StartMenuDir 'Discord (WARP).lnk'),
        (Join-Path $script:StartMenuDir 'Discord WARP - Diagnose.lnk'),
        (Join-Path $script:StartMenuDir 'Discord WARP - Uninstall.lnk')
    )) { Remove-Item -LiteralPath $item -Force -ErrorAction SilentlyContinue }
    Remove-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DiscordWARP-GOST' -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $script:AppDir) {
        Remove-Item -LiteralPath $script:AppDir -Recurse -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $script:AppDir) { throw 'Uygulama klasoru tamamen silinemedi.' }
    }
    Write-TaskLog 'Kaldirma tamamlandi. WARP, Discord, GoodbyeDPI ve Windows DNS/proxy ayarlari korunuyor.'
    if (-not $LogPath) { [System.Windows.Forms.MessageBox]::Show('Kaldirma tamamlandi. Discord ve WARP kaldirilmadi.', 'Discord WARP', 'OK', 'Information') | Out-Null }
    exit 0
} catch {
    Write-TaskLog ('HATA: ' + $_.Exception.Message)
    if (-not $LogPath) { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Kaldirma hatasi', 'OK', 'Error') | Out-Null }
    exit 1
}
