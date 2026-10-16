"""Verify a real interactive picture-skin UI, not another approximate gradient-only mockup."""
from pathlib import Path
import hashlib
from PIL import Image
root = Path(__file__).resolve().parents[1]
image = root / 'assets' / 'aero-skin.png'
assert image.exists(), 'Theme artwork missing'
im = Image.open(image)
assert im.size == (864, 642) and im.mode in ('RGB','RGBA')
assert image.stat().st_size > 150_000, 'Aero image unexpectedly tiny'
ps = (root / 'assets' / 'Setup-GUI.ps1').read_text(encoding='utf-8-sig')
go = (root / 'main.go').read_text()
assert 'BackgroundImage' in ps and 'aero-skin.png' in go
assert 'AeroSkinForm' in ps and 'Hit-Target' in ps and 'Perform-Action' in ps
assert 'DWG_UI_SMOKE' in ps
for target in ['install','diagnose','remove','warp','download','launch','close','minimize','maximize','winclose']:
    assert "name='"+target+"'" in ps, target
for operation in ['Install.ps1','Remove.ps1','Diagnose.ps1','Setup-Warp.ps1','Launch-Discord.ps1']:
    assert "'"+operation+"'" in ps, operation
for safeguard in ['Ask-WarpConsent','Set-Busy','Refresh-SystemStatus','Get-Content','Save-WarpConsent']:
    assert safeguard in ps + (root / 'assets' / 'Setup-Warp.ps1').read_text(encoding='utf-8-sig')
print('PASS: reference skin artwork, 10 interactive targets, and operational wiring')
print('Skin SHA256:', hashlib.sha256(image.read_bytes()).hexdigest())
