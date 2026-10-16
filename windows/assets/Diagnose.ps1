param([string]$LogPath)
$script:LogPath = $LogPath
. (Join-Path $PSScriptRoot 'Common.ps1')
try {
    Write-TaskLog 'Tani islemi sadece okuma yapar; ag ayarlari degistirilmez.'
    Write-TaskLog ('Windows: ' + [Environment]::OSVersion.VersionString)
    Write-TaskLog ('Discord: ' + $(if (Get-DiscordExecutable) { 'kurulu' } else { 'bulunamadi' }))
    Write-TaskLog ('GOST: ' + $(if (Test-Path (Join-Path $script:AppDir 'gost.exe')) { 'kurulu' } else { 'bulunamadi' }))
    Write-TaskLog ('WARP 40000: ' + (Test-LocalTcpPort 40000))
    Write-TaskLog ('GOST 40001: ' + (Test-LocalTcpPort 40001) + ' (Discord WARP baslatilmadiysa False normaldir)')
    if (Get-WarpCli) {
        try {
            $settings = Assert-WarpProxyMode
            Write-TaskLog ('WARP Local Proxy 40000: DOGRULANDI')
            $status = (& (Get-WarpCli) status 2>&1 | Out-String)
            Write-TaskLog ('WARP durum: ' + (($status.Trim() -replace '\s+',' ') -replace '[^\x20-\x7E]',' '))
        } catch { Write-TaskLog ('WARP uyari: ' + $_.Exception.Message.Split("`n")[0]) }
    } else { Write-TaskLog 'WARP bulunamadi; https://1.1.1.1/ adresinden indirilebilir.' }
    $internetProxy = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue)
    if ($internetProxy) { Write-TaskLog ('Windows kullanici proxy etkin: ' + $internetProxy.ProxyEnable + ' (bu kurulum tarafindan degistirilmedi)') }
    Write-TaskLog 'Tani tamamlandi.'
    if (-not $LogPath) { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Baglanti tanisi tamamlandi. Ayrintilar kurulum sihirbazinda veya terminalde gorunebilir.', 'Discord WARP - Tani') | Out-Null }
    exit 0
} catch {
    Write-TaskLog ('HATA: ' + $_.Exception.Message)
    exit 1
}
