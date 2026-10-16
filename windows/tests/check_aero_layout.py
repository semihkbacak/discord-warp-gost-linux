"""Visual-asset and click region regression test for RC3 Vista skin."""
from pathlib import Path
from PIL import Image
import re
root=Path(__file__).resolve().parents[1]
s=(root/'assets'/'Setup-GUI.ps1').read_text(encoding='utf-8-sig')
with Image.open(root/'assets'/'aero-skin.png') as im:
    assert im.size==(864,642), 'unexpected reference art dimensions'
    assert im.getpixel((705,79)) != im.getpixel((40,421)), 'expected distinct Aero header and log'
buttons={'install':(12,275,165,74),'diagnose':(180,275,166,74),'remove':(350,275,165,74),'warp':(519,275,167,74),'download':(690,275,165,74),'launch':(513,578,189,49),'close':(719,578,134,49)}
for name, (x,y,w,h) in buttons.items():
    assert 0 <= x and 0 <= y and x+w<=864 and y+h<=642
    assert re.search(r"name='"+name+r"';rect=\[System.Drawing.Rectangle\]::new\("+f'{x},{y},{w},{h}'+r"\)",s), name
assert 'BackgroundImageLayout' in s and 'Hit-Target' in s
print('PASS: exact reference-art geometry and functional hit regions')
