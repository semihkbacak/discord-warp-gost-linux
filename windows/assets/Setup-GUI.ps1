# Discord WARP + GOST — Turkish Vista Aero native hotspots (RC5).
# The appearance is a locally bundled picture skin, not global Windows DWM changes.
# Connection scripts are unchanged from the last working Windows beta.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$ErrorActionPreference = 'Stop'

$nativeCode = @'
using System;
using System.Windows.Forms;
using System.Drawing;
using System.Runtime.InteropServices;
public class AeroSkinForm : Form {
    public AeroSkinForm() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);
        UpdateStyles();
        KeyPreview = true;
    }
}
// Unlike RC3, all actionable areas are real WinForms controls rather than
// coordinate-driven PictureBox clicks. Native focus, keyboard and mouse semantics.
public class AeroHotspot : Control {
    public Image Skin { get; set; }
    public Rectangle SourceArea { get; set; }
    private bool hot;
    public AeroHotspot() {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint |
                 ControlStyles.OptimizedDoubleBuffer | ControlStyles.Selectable, true);
        TabStop = true;
        Cursor = Cursors.Hand;
    }
    protected override void OnPaintBackground(PaintEventArgs e) { }
    protected override void OnPaint(PaintEventArgs e) {
        if (Skin != null)
            e.Graphics.DrawImage(Skin, ClientRectangle, SourceArea, GraphicsUnit.Pixel);
        if (hot || Focused) {
            using (Pen p = new Pen(Color.FromArgb(225, 250, 255), 2))
                e.Graphics.DrawRectangle(p, 1, 1, Math.Max(1, Width-3), Math.Max(1, Height-3));
        }
    }
    protected override void OnMouseEnter(EventArgs e) { base.OnMouseEnter(e); hot=true; Invalidate(); }
    protected override void OnMouseLeave(EventArgs e) { base.OnMouseLeave(e); hot=false; Invalidate(); }
    protected override void OnGotFocus(EventArgs e) { base.OnGotFocus(e); Invalidate(); }
    protected override void OnLostFocus(EventArgs e) { base.OnLostFocus(e); Invalidate(); }
    protected override void OnKeyDown(KeyEventArgs e) {
        if (e.KeyCode == Keys.Space || e.KeyCode == Keys.Enter) {
            OnClick(EventArgs.Empty); e.Handled = true; e.SuppressKeyPress = true;
        } else base.OnKeyDown(e);
    }
}
public static class AeroNative {
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr window, int message, IntPtr wp, IntPtr lp);
}
'@
Add-Type -TypeDefinition $nativeCode -ReferencedAssemblies @('System.Windows.Forms','System.Drawing')

$script:skinFile = Join-Path $PSScriptRoot 'aero-skin.png'
if (-not (Test-Path -LiteralPath $script:skinFile)) { throw 'Vista Aero theme artwork is missing.' }
$script:skin = [System.Drawing.Image]::FromFile($script:skinFile)
$script:W = 864
$script:H = 642
$script:busy = $false
$script:job = $null
$script:jobKind = ''
$script:jobLog = $null
$script:jobDisplayedText = ''
$script:footerText = 'Yalnızca Discord kullanır. Sistem DNS ayarları değişmez.'
$script:logLines = @(
    '[BİLGİ] Discord WARP + GOST | Vista Aero Türkçe Sürüm',
    '[BİLGİ] Kur / Onar veya Bağlantı Testi seçeneklerinden birini kullanın.',
    '[BİLGİ] Genel sistem DNS, ağ rotası ve proxy ayarları değiştirilmez.'
)
$script:scrollPosition = 0
$script:visibleLogLines = 12
$script:statusLabels = @('Kontrol ediliyor...', 'Kontrol ediliyor...', 'Kontrol ediliyor...', 'Kontrol ediliyor...')
$script:statusOk = @($false, $false, $false, $false)
$script:hover = ''
$script:logFont = New-Object System.Drawing.Font('Consolas', 8.5, [System.Drawing.FontStyle]::Regular)
$script:statusFont = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Regular)
$script:footerFont = New-Object System.Drawing.Font('Segoe UI', 8.2, [System.Drawing.FontStyle]::Regular)
$script:penHover = New-Object System.Drawing.Pen(([System.Drawing.Color]::FromArgb(235,245,255)), 2.0)
$script:penHover2 = New-Object System.Drawing.Pen(([System.Drawing.Color]::FromArgb(90,210,255)), 1.0)
$script:logBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(236,242,252))
$script:okBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(16,150,75))
$script:offBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(65,86,109))
$script:footerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(36,82,128))

$form = New-Object AeroSkinForm
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.ClientSize = New-Object System.Drawing.Size($script:W,$script:H)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
$form.BackColor = [System.Drawing.Color]::FromArgb(157,195,224)
$form.BackgroundImage = $script:skin
$form.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
$form.Text = 'Discord WARP + GOST — Vista Aero Türkçe v1.0.0'
$form.ShowIcon = $true
$form.ShowInTaskbar = $true
$form.MinimizeBox = $true
$form.MaximizeBox = $false
$form.KeyPreview = $true
$icoPath = Join-Path $PSScriptRoot 'app.ico'
if (Test-Path -LiteralPath $icoPath) { $form.Icon = [System.Drawing.Icon]::new($icoPath) }

# The bitmap is solely decoration. These states are generated from the real machine.
function Refresh-SystemStatus {
    $base = Join-Path $env:LOCALAPPDATA 'Programs\DiscordWARP-GOST'
    $app = Test-Path -LiteralPath (Join-Path $base 'Launch-Discord.ps1')
    $gost = Test-Path -LiteralPath (Join-Path $base 'gost.exe')
    $discord = Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'Discord')
    $warpDir = Join-Path $env:ProgramFiles 'Cloudflare\Cloudflare WARP\warp-cli.exe'
    $warp = Test-Path -LiteralPath $warpDir
    $script:statusOk = @($app,$gost,$warp,$discord)
    $script:statusLabels = @(
        $(if ($app) { 'Hazır' } else { 'Kurulu değil' }),
        $(if ($gost) { 'Kurulu' } else { 'Kurulu değil' }),
        $(if ($warp) { 'Algılandı' } else { 'Kurulu değil' }),
        $(if ($discord) { 'Algılandı' } else { 'Bulunamadı' })
    )
    $form.Invalidate()
}

function Set-LogText([string]$content) {
    $lines = New-Object System.Collections.Generic.List[string]
    foreach($line in ($content -split "`r?`n")) {
        if ($null -eq $line) { continue }
        $part = [string]$line
        if ($part.Length -eq 0) { continue }
        while ($part.Length -gt 118) {
            $lines.Add($part.Substring(0,118))
            $part = '  ' + $part.Substring(118)
        }
        $lines.Add($part)
    }
    $script:logLines = $lines.ToArray()
    $script:scrollPosition = [Math]::Max(0,$script:logLines.Length - $script:visibleLogLines)
    $form.Invalidate()
}

# All click targets correspond exactly to the reference artwork, including custom titlebar.
$script:targets = @(
    @{name='install';rect=[System.Drawing.Rectangle]::new(12,275,165,74)},
    @{name='diagnose';rect=[System.Drawing.Rectangle]::new(180,275,166,74)},
    @{name='remove';rect=[System.Drawing.Rectangle]::new(350,275,165,74)},
    @{name='warp';rect=[System.Drawing.Rectangle]::new(519,275,167,74)},
    @{name='download';rect=[System.Drawing.Rectangle]::new(690,275,165,74)},
    @{name='launch';rect=[System.Drawing.Rectangle]::new(513,578,189,49)},
    @{name='close';rect=[System.Drawing.Rectangle]::new(719,578,134,49)},
    @{name='minimize';rect=[System.Drawing.Rectangle]::new(738,0,40,35)},
    @{name='maximize';rect=[System.Drawing.Rectangle]::new(777,0,31,35)},
    @{name='winclose';rect=[System.Drawing.Rectangle]::new(808,0,55,35)}
)
function Resolve-Point([int]$x,[int]$y) {
    if ($form.ClientSize.Width -le 0 -or $form.ClientSize.Height -le 0) { return [System.Drawing.Point]::new(0,0) }
    return [System.Drawing.Point]::new([int][Math]::Round($x * $script:W / $form.ClientSize.Width),[int][Math]::Round($y * $script:H / $form.ClientSize.Height))
}
function Hit-Target([int]$x,[int]$y) {
    foreach ($entry in $script:targets) {
        if ($entry.rect.Contains($x,$y)) { return $entry.name }
    }
    return ''
}

$form.Add_Paint({
    $gfx=$_.Graphics
    $gfx.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $gfx.ScaleTransform(($form.ClientSize.Width / [float]$script:W),($form.ClientSize.Height / [float]$script:H))
    # Live status replaces all demonstration values from the artistic image.
    $columns=@(103,306,513,731)
    for($i=0;$i -lt 4;$i++) {
        $brush=if($script:statusOk[$i]) { $script:okBrush } else { $script:offBrush }
        $orb=if($script:statusOk[$i]) { [System.Drawing.Color]::FromArgb(32,199,92) } else { [System.Drawing.Color]::FromArgb(97,115,132) }
        $circle=New-Object System.Drawing.SolidBrush($orb)
        $gfx.FillEllipse($circle,[float]$columns[$i],[float]226,10,10)
        $circle.Dispose()
        $gfx.DrawString($script:statusLabels[$i],$script:statusFont,$brush,([float]($columns[$i]+21)),[float]223)
    }
    # Real logs: no synthetic success claims copied from the design mockup.
    $gfx.SetClip([System.Drawing.Rectangle]::new(28,387,789,165))
    $visible=[Math]::Min($script:visibleLogLines,[Math]::Max(0,$script:logLines.Length-$script:scrollPosition))
    for($i=0;$i -lt $visible;$i++) {
        $line=$script:logLines[$script:scrollPosition+$i]
        $gfx.DrawString($line,$script:logFont,$script:logBrush,29.0,[float](387+$i*13))
    }
    $gfx.ResetClip()
    # Left footer safely displays current action completion/error state.
    $message=$script:footerText
    if ($message.Length -gt 77) { $message=$message.Substring(0,74)+'...' }
    $gfx.DrawString($message,$script:footerFont,$script:footerBrush,51.0,593.0)
    # Native AeroHotspot controls render their own hover/focus indication.
})

function Set-Busy([bool]$value) {
    $script:busy=$value
    if($value){$script:footerText='İşlem sürüyor. Ayrıntılar işlem günlüğünde.'}
    $form.Invalidate()
}
function Ask-WarpConsent {
    $message="Cloudflare WARP kurulumu / Local Proxy 40000 ayarı hazırlanacak. WinGet, resmî WARP paketini kurabilir ve Windows yönetici onayı isteyebilir.`n`nWARP başka modda bağlıysa hiçbir değişiklik yapılmaz. Sistem genelinde DNS, proxy ve güvenlik duvarı ayarları değiştirilmez.`n`nCloudflare WARP koşulları: https://www.cloudflare.com/terms/`n`nKoşulları okudunuz ve kabul ediyor musunuz?"
    return ([System.Windows.Forms.MessageBox]::Show($message, 'WARP Local Proxy onayı', 'YesNo', 'Question') -eq 'Yes')
}
function Begin-Task([string]$kind,[string]$filename,[string]$extra='') {
    if ($script:busy) { return }
    $script:jobKind=$kind
    $script:jobLog=Join-Path $env:TEMP ('discord-warp-task-'+[guid]::NewGuid().ToString('N')+'.log')
    $script:jobDisplayedText=''
    Set-LogText "[BİLGİ] $kind başladı. İşlem günlüğü bekleniyor..."
    Set-Busy $true
    $scriptPath=Join-Path $PSScriptRoot $filename
    $arguments='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "'+$scriptPath+'" -LogPath "'+$script:jobLog+'"'+$extra
    try {
        $script:job=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $arguments -WindowStyle Hidden -PassThru
    } catch {
        Set-Busy $false
        $script:footerText='İşlem başlatılamadı; günlükteki hatayı kontrol edin.'
        Set-LogText $_.Exception.Message
    }
}

function Try-CloseWindow {
    if($script:busy){
        [System.Windows.Forms.MessageBox]::Show('İşlem devam ederken pencere kapatılamaz.','İşlem devam ediyor') | Out-Null
        return
    }
    $form.Close()
}
function Perform-Action([string]$name) {
    if($script:busy -and $name -notin @('minimize','winclose','close')) { return }
    switch($name) {
        'install' {
            if(Ask-WarpConsent){Begin-Task 'kurulum' 'Install.ps1' ' -AutoSetupWarp'}
            else {
                $answer=[System.Windows.Forms.MessageBox]::Show('WARP kurulumu onaylanmadı. Yalnızca GOST ve kısayollar kurulsun mu?','Yalnızca GOST','YesNo','Question')
                if($answer -eq 'Yes'){Begin-Task 'kurulum' 'Install.ps1'}
            }
        }
        'diagnose' {Begin-Task 'tanılama' 'Diagnose.ps1'}
        'remove' {
            $answer=[System.Windows.Forms.MessageBox]::Show('Yalnızca bu uygulamanın dosyaları ve kısayolları kaldırılacak. Discord ve Cloudflare WARP korunacak. Devam edilsin mi?','Kaldırmayı onayla','YesNo','Question')
            if ($answer -eq 'Yes'){Begin-Task 'kaldırma' 'Remove.ps1'}
        }
        'warp' {if(Ask-WarpConsent){Begin-Task 'warp-hazırlık' 'Setup-Warp.ps1' ' -UserConsented'}}
        'download' {Start-Process 'https://discord.com/download'}
        'launch' {
            $installed=Join-Path $env:LOCALAPPDATA 'Programs\DiscordWARP-GOST\Launch-Discord.ps1'
            if (Test-Path -LiteralPath $installed){Begin-Task 'başlatma' 'Launch-Discord.ps1'}
            else {[System.Windows.Forms.MessageBox]::Show('Önce Kur / Onar işlemini tamamlayın.','Discord WARP + GOST')|Out-Null}
        }
        'minimize' {$form.WindowState=[System.Windows.Forms.FormWindowState]::Minimized}
        'maximize' {
            # Reference shows a maximise control; fixed themed canvas expands at 125%.
            if ($form.ClientSize.Width -gt $script:W){$form.ClientSize=[System.Drawing.Size]::new($script:W,$script:H)}
            else {
                $b=[System.Windows.Forms.Screen]::FromControl($form).WorkingArea
                if ($b.Width -gt 1080 -and $b.Height -gt 808) {$form.ClientSize=[System.Drawing.Size]::new(1080,802)}
            }
            $bounds=[System.Windows.Forms.Screen]::FromControl($form).WorkingArea
            $form.Location=[System.Drawing.Point]::new(($bounds.Left+[int](($bounds.Width-$form.Width)/2)),($bounds.Top+[int](($bounds.Height-$form.Height)/2)))
        }
        'winclose' {Try-CloseWindow}
        'close' {Try-CloseWindow}
    }
}

# RC4: native clickable WinForms controls. RC3 only handled parent-form MouseClick;
# overlapping paints / coordinate scaling could prevent users from activating actions.
$script:hotspots = @{}
foreach ($entry in $script:targets) {
    $ctl = New-Object AeroHotspot
    $ctl.Name = ('aero_' + $entry.name)
    $ctl.Tag = $entry.name
    $ctl.Skin = $script:skin
    $ctl.SourceArea = $entry.rect
    $ctl.Bounds = $entry.rect
    $ctl.AccessibleRole = [System.Windows.Forms.AccessibleRole]::PushButton
    $ctl.AccessibleName = switch($entry.name) {
        'install' {'Kur / Onar'}
        'diagnose' {'Bağlantı Testi'}
        'remove' {'Kaldır'}
        'warp' {'WARP Hazırla'}
        'download' {"Discord'u İndir"}
        'launch' {"Discord'u Aç"}
        'close' {'Kapat'}
        'minimize' {'Simge durumuna küçült'}
        'maximize' {'Pencere boyutunu değiştir'}
        'winclose' {'Pencereyi kapat'}
    }
    $ctl.Add_Click({ param($sender,$eventArgs) Perform-Action ([string]$sender.Tag) })
    [void]$form.Controls.Add($ctl)
    $script:hotspots[$entry.name]=$ctl
}
# Keep independent button hitboxes aligned with the stretched artwork at 125% size.
$form.Add_ClientSizeChanged({
    foreach($entry in $script:targets) {
        $r=$entry.rect
        $script:hotspots[$entry.name].Bounds=[System.Drawing.Rectangle]::new(
            [int][Math]::Round($r.X * $form.ClientSize.Width / $script:W),
            [int][Math]::Round($r.Y * $form.ClientSize.Height / $script:H),
            [int][Math]::Round($r.Width * $form.ClientSize.Width / $script:W),
            [int][Math]::Round($r.Height * $form.ClientSize.Height / $script:H))
    }
})

$timer=New-Object System.Windows.Forms.Timer
$timer.Interval=500
$timer.Add_Tick({
    if(-not $script:job){return}
    if($script:jobLog -and (Test-Path -LiteralPath $script:jobLog)) {
        try {
            $latest=Get-Content -LiteralPath $script:jobLog -Raw -Encoding UTF8 -ErrorAction Stop
            if($latest -ne $script:jobDisplayedText){
                $script:jobDisplayedText=$latest
                Set-LogText $latest
            }
        } catch { }
    }
    $script:job.Refresh()
    if($script:job.HasExited){
        $code=$script:job.ExitCode
        $what=$script:jobKind
        $script:job=$null
        Set-Busy $false
        Refresh-SystemStatus
        if($code -eq 0){
            switch($what){
                'kurulum' {$script:footerText="Kurulum tamamlandı. Discord'u açarak doğrulayın."}
                'warp-hazırlık' {$script:footerText='WARP Local Proxy hazırlığı tamamlandı.'}
                'kaldırma' {$script:footerText='Kaldırma tamamlandı. Sihirbazı kapatabilirsiniz.'}
                'başlatma' {$script:footerText='Discord başlatma isteği tamamlandı; uygulamayı kontrol edin.'}
                default {$script:footerText='Bağlantı testi tamamlandı. Günlüğü kontrol edin.'}
            }
        } else {$script:footerText='İşlem başarısız. Ayrıntıları günlükte inceleyin.'}
        $form.Invalidate()
    }
})
$timer.Start()

$form.Add_MouseDown({
    $pt=Resolve-Point $_.X $_.Y
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $pt.Y -lt 37 -and $pt.X -ge 35 -and $pt.X -lt 737) {
        [AeroNative]::ReleaseCapture()|Out-Null
        [AeroNative]::SendMessage($form.Handle,0xA1,[IntPtr]::new(2),[IntPtr]::Zero)|Out-Null
    }
})
$form.Add_MouseWheel({
    $max=[Math]::Max(0,$script:logLines.Length-$script:visibleLogLines)
    $move=if($_.Delta -gt 0){-3}else{3}
    $script:scrollPosition=[Math]::Max(0,[Math]::Min($max,($script:scrollPosition+$move)))
    $form.Invalidate()
})
$form.Add_KeyDown({
    if($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape){Try-CloseWindow}
    if($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::C){[System.Windows.Forms.Clipboard]::SetText(($script:logLines -join "`r`n"));$script:footerText='İşlem günlüğü panoya kopyalandı.';$form.Invalidate()}
    if($_.Alt){switch($_.KeyCode){
        'I' {Perform-Action 'install'}
        'D' {Perform-Action 'diagnose'}
        'U' {Perform-Action 'remove'}
        'W' {Perform-Action 'warp'}
        'O' {Perform-Action 'launch'}
    }}
})
$form.Add_FormClosing({if($script:busy){$_.Cancel=$true;[System.Windows.Forms.MessageBox]::Show('İşlem tamamlanana kadar bekleyin.','İşlem devam ediyor')|Out-Null}})
$form.Add_FormClosed({$timer.Stop();$timer.Dispose();$script:logFont.Dispose();$script:statusFont.Dispose();$script:footerFont.Dispose();$script:logBrush.Dispose();$script:okBrush.Dispose();$script:offBrush.Dispose();$script:footerBrush.Dispose();$script:penHover.Dispose();$script:penHover2.Dispose();$script:skin.Dispose()})
Refresh-SystemStatus

if($env:DWG_UI_SMOKE -eq '1') {
    if($script:skin.Width -ne 864 -or $script:skin.Height -ne 642){throw 'Incorrect Vista artwork dimensions'}
    foreach($item in $script:targets){if($item.rect.Right -gt $script:W -or $item.rect.Bottom -gt $script:H){throw ('Hitbox clipped: '+$item.name)}}
    if($script:targets.Count -ne 10 -or $script:hotspots.Count -ne 10){throw 'Ten native Vista controls required'}
    foreach($entry in $script:targets){if(-not $script:hotspots.ContainsKey($entry.name)){throw ('Missing native control: '+$entry.name)}}
    Write-Output 'Türkçe Vista Aero arayüzü ve 10 yerel Windows düğmesi başlatıldı: OK'
    $form.Dispose()
    return
}
[System.Windows.Forms.Application]::Run($form)
