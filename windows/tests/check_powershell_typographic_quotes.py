"""Guard Windows PowerShell 5.1's special interpretation of curly quote characters.

PowerShell treats typographic single/double quotes like syntax delimiters.
They must be properly escaped; this project forbids them in .ps1 to avoid this RC4 regression.
This is a static guard. Use PowerShell's Parser.ParseFile on Windows for a real syntax check.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
smart={chr(0x2018),chr(0x2019),chr(0x201C),chr(0x201D)}
for ps in (root/'assets').glob('*.ps1'):
    text=ps.read_text(encoding='utf-8-sig')
    for i,line in enumerate(text.splitlines(), 1):
        if any(c in line for c in smart):
            raise AssertionError(f'{ps.name}:{i}: unsafe smart-quote in PowerShell source')
assert 'Kurulum tamamlandı. Discord\'u açarak doğrulayın.' in (root/'assets'/'Setup-GUI.ps1').read_text(encoding='utf-8-sig')
print('PASS: PowerShell quotation-mark regression guard')
