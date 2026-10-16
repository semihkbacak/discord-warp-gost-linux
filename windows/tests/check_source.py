"""Portable source-integrity / Windows artifact checks, not a substitute for Windows E2E."""
from pathlib import Path
import struct, hashlib

root = Path(__file__).resolve().parents[1]
contents = {x.name: x.read_text(encoding='utf-8-sig') for x in (root / 'assets').glob('*.ps1')}
assert set(contents) == {'Common.ps1', 'Setup-GUI.ps1', 'Install.ps1', 'Remove.ps1', 'Diagnose.ps1', 'Launch-Discord.ps1','Setup-Warp.ps1'}
installer = contents['Install.ps1']
paths = (root / 'windows_paths.go').read_text()
assert 'GetLongPathNameW' in paths
assert 'safeChildEnvironment' in (root / 'main.go').read_text()
for expected in [
    'cc8ac946f86994a3aed47ef1f838cfb6b7649d9245c91fcb9899654b33d61170',
    'f423e10b0e5fac02ca1d2294e008bab16480938055e7620af27aba319979ccac',
    'github.com/go-gost/gost/releases/download/',
    'Get-FileHash',
]:
    assert expected in installer, expected
assert 'Assert-WarpProxyMode' in contents['Launch-Discord.ps1']
assert 'Confirm-WarpConsent' in contents['Launch-Discord.ps1']
assert 'Prepare-WarpIfNeeded' in contents['Launch-Discord.ps1']
assert 'Setup-Warp.ps1' in contents['Launch-Discord.ps1']
assert 'Discord-WARP-GOST.exe' in contents['Common.ps1']
assert 'launchDiscord()' in (root / 'main.go').read_text()
assert 'CreationFlags: 0x08000000' in (root / 'main.go').read_text()
assert 'Save-WarpConsent' in contents['Setup-Warp.ps1']
assert 'Get-WarpConsentPath' in contents['Common.ps1']
assert 'Check-DiscordProcesses' in contents['Launch-Discord.ps1']
assert '127.0.0.1:40001' in contents['Launch-Discord.ps1']
assert '127.0.0.1:40000' in contents['Launch-Discord.ps1']
assert 'Run-WarpCli' in contents['Setup-Warp.ps1']
assert 'Cloudflare.Warp' in contents['Setup-Warp.ps1']
assert 'Get-WarpConnectionState' in contents['Setup-Warp.ps1']
assert "-ne 'disconnected'" in contents['Setup-Warp.ps1']
assert 'Ask-WarpConsent' in contents['Setup-GUI.ps1']
assert "'warp'" in contents['Setup-GUI.ps1']
assert 'Kaldırma tamamlandı.' in contents['Setup-GUI.ps1']
assert "'close'" in contents['Setup-GUI.ps1']
for name, source in contents.items():
    bad_fragments = ('netsh interface ip set dns', 'Set-DnsClientServerAddress', 'netsh winhttp set proxy', 'New-NetRoute', 'Set-NetFirewallRule', 'Set-ItemProperty -Path HKLM:')
    for fragment in bad_fragments:
        assert fragment.lower() not in source.lower(), f'{name}: {fragment}'
    assert source.count('{') == source.count('}'), f'brace mismatch in {name}'
    assert source.count('(') == source.count(')'), f'parenthesis mismatch in {name}'

exe = Path('/mnt/data/Discord-WARP-GOST-Setup-v1.0.0.exe')
if exe.exists():
    blob = exe.read_bytes()
    assert blob[:2] == b'MZ'
    e_lfanew = struct.unpack_from('<I', blob, 0x3C)[0]
    assert blob[e_lfanew:e_lfanew+4] == b'PE\x00\x00'
    print('Windows PE x64:', len(blob), 'bytes; sha256:', hashlib.sha256(blob).hexdigest())
print('PASS: source structure, GOST pins, proxy isolation, GUI flow, and PE signature')

assert 'AeroSkinForm' in contents['Setup-GUI.ps1'] and 'Hit-Target' in contents['Setup-GUI.ps1']
assert 'DWG_UI_SMOKE' in contents['Setup-GUI.ps1']
assert "'1.0.0'" in contents['Install.ps1']

assert 'class AeroHotspot : Control' in contents['Setup-GUI.ps1']
assert 'AccessibleRole' in contents['Setup-GUI.ps1']
assert '$ctl.Add_Click' in contents['Setup-GUI.ps1']

assert "using System.Drawing;" in contents["Setup-GUI.ps1"]
assert "Kapat" in contents["Setup-GUI.ps1"]
assert "class AeroHotspot : Control" in contents["Setup-GUI.ps1"]
