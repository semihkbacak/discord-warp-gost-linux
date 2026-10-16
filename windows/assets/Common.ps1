Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:AppDir = Join-Path $env:LOCALAPPDATA 'Programs\DiscordWARP-GOST'
$script:StartMenuDir = Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs'
$script:AppName = 'Discord WARP + GOST (Windows Beta)'

function Write-TaskLog([string]$message) {
    $line = ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $message)
    Write-Output $line
    if ($script:LogPath) { Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8 }
}
function Get-WarpCli {
    $found = Get-Command 'warp-cli.exe' -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    $paths = @(Join-Path $env:ProgramFiles 'Cloudflare\Cloudflare WARP\warp-cli.exe')
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($programFilesX86) { $paths += (Join-Path $programFilesX86 'Cloudflare\Cloudflare WARP\warp-cli.exe') }
    foreach ($p in $paths) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { return $p } }
    return $null
}
function Get-DiscordExecutable {
    $root = Join-Path $env:LOCALAPPDATA 'Discord'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return $null }
    $applications = @(Get-ChildItem -LiteralPath $root -Directory -Filter 'app-*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    foreach ($entry in $applications) {
        $candidate = Join-Path $entry.FullName 'Discord.exe'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}
function Test-LocalTcpPort([int]$port) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $pending = $tcp.BeginConnect('127.0.0.1', $port, $null, $null)
        if (-not $pending.AsyncWaitHandle.WaitOne(1200)) { return $false }
        $tcp.EndConnect($pending)
        return $true
    } catch { return $false } finally { $tcp.Close() }
}
function Get-WarpSettingsText {
    $cli = Get-WarpCli
    if (-not $cli) { throw 'Cloudflare WARP bulunamadi. Resmi WARP uygulamasini yukleyin.' }
    $result = & $cli settings 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw ('warp-cli settings basarisiz: ' + $result) }
    return $result
}
function Assert-WarpProxyMode {
    $settings = Get-WarpSettingsText
    # Fail closed: require explicit WarpProxy declaration and selected port.
    if ($settings -notmatch '(?is)WarpProxy\s+on\s+port\s+40000') {
        throw "WARP Local Proxy modunda degil veya port 40000 kullanilmiyor. WARP > Preferences > Advanced > Configure Proxy bolumunde port 40000'i secip Local Proxy'yi etkinlestirin. Tam WARP/VPN modunu kullanmayin.`n$settings"
    }
    return $settings
}
function Get-WarpConsentPath { return (Join-Path $script:AppDir 'warp-setup-consent.txt') }
function Confirm-WarpConsent {
    Add-Type -AssemblyName System.Windows.Forms
    if (Test-Path -LiteralPath (Get-WarpConsentPath) -PathType Leaf) { return $true }
    $text = "Discord'un baglanmasi icin Cloudflare WARP gerekebilir. Eksikse resmi WinGet Cloudflare.Warp paketi kurulur, WARP Local Proxy modu 40000 portunda ayarlanir. Gerekirse Windows yonetici onayi isteyebilir. Bagli oldugu farkli bir VPN modu DEGISTIRILMEZ. DNS, Windows genel proxy, firewall ve varsayilan rota ayarlari bu arac tarafindan degistirilmez.`n`nCloudflare sartlari: https://www.cloudflare.com/terms/`n`nKosullari kabul edip Discord (WARP) acilislarinda gerekli oldugunda WARP Local Proxy hazirlanmasini onayliyor musunuz?"
    $answer = [System.Windows.Forms.MessageBox]::Show($text, 'WARP hazirligi - kullanici onayi', 'YesNo', 'Question')
    if ($answer -ne 'Yes') { return $false }
    return $true
}
function Save-WarpConsent {
    if (-not (Test-Path -LiteralPath $script:AppDir -PathType Container)) {
        New-Item -ItemType Directory -Path $script:AppDir -Force | Out-Null
    }
    Set-Content -LiteralPath (Get-WarpConsentPath) -Value 'WARP local proxy 40000: user approved via installer or launcher' -Encoding UTF8
}
function New-UserShortcut([string]$file,[string]$scriptName,[string]$description) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($file)
    if ($scriptName -eq 'Launch-Discord.ps1') {
        $shortcut.TargetPath = Join-Path $script:AppDir 'Discord-WARP-GOST.exe'
        $shortcut.Arguments = '--launch'
    } else {
        $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $scriptFile = Join-Path $script:AppDir $scriptName
        $shortcut.Arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $scriptFile + '"'
    }
    $shortcut.WorkingDirectory = $script:AppDir
    $shortcut.Description = $description
    $discord = Get-DiscordExecutable
    if ($discord) { $shortcut.IconLocation = $discord + ',0' }
    $shortcut.Save()
}
