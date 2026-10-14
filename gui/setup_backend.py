"""Discord WARP + GOST user-scoped setup logic. No system DNS changes."""
from __future__ import annotations

import hashlib
import io
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import tempfile
import time
import urllib.request

HERE = Path(__file__).resolve().parents[1]
GOST_VERSION = '3.3.0'
GOST_HASHES = {
    'x86_64': ('amd64', '676fb7f78d267b6ae73df719c0c7f2b565dde7147da935cfafbc1e1da558b6d5'),
    'aarch64': ('arm64', 'd03699e3f385d4ff5dad68046712adfcc7515325a064d2ab046e0bece30f8f8f'),
}


class SetupError(Exception):
    pass


def call(args, log, timeout=180, check=True, capture=True):
    """Fixed argv lists only. No shell interpolation and no sudo GUI process."""
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE if capture else None,
                            stderr=subprocess.STDOUT if capture else None,
                            stdin=subprocess.DEVNULL, timeout=timeout, check=False)
    output = (result.stdout or '').strip()
    if output:
        for line in output.splitlines()[-12:]:
            log('   ' + line[:400])
    if check and result.returncode:
        raise SetupError(f"Komut başarısız ({result.returncode}): {' '.join(args[:3])}\n{output[-700:]}")
    return result


def installed(cmd):
    return shutil.which(cmd) is not None


def status_snapshot():
    checks = {
        'Cloudflare WARP': installed('warp-cli'),
        'Flatpak': installed('flatpak'),
        'curl': installed('curl'),
        'GOST v3': (Path.home() / '.local/bin/gost').is_file() or installed('gost'),
        'Discord Flatpak': False,
    }
    if checks['Flatpak']:
        checks['Discord Flatpak'] = subprocess.run(
            ['flatpak', 'info', 'com.discordapp.Discord'], stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, timeout=10, check=False).returncode == 0
    return checks


def install_warp_if_missing(log):
    if installed('warp-cli'):
        log('WARP zaten kurulu, mevcut paket korunuyor.')
        return
    helper = Path('/usr/lib/discord-warp-gost/privileged-install')
    if not helper.exists():
        # Developer checkout without the .deb.
        helper = HERE / 'gui/privileged-install'
    if not installed('pkexec'):
        raise SetupError('Yönetici izin aracı pkexec bulunamadı. WARP’ı resmî depodan yükleyin.')
    log('WARP eksik. Resmî Cloudflare deposundan kurulum için yönetici izni istenecek.')
    call(['pkexec', str(helper), 'warp'], log, timeout=600)
    if not installed('warp-cli'):
        raise SetupError('WARP kurulumu tamamlanamadı; warp-cli bulunamadı.')


def download_gost(log):
    if (Path.home() / '.local/bin/gost').is_file() or installed('gost'):
        log('GOST zaten mevcut, tekrar indirmiyorum.')
        return
    record = GOST_HASHES.get(platform.machine())
    if not record:
        raise SetupError('GOST otomatik indirme yalnızca x86_64 / aarch64 destekler.')
    arch, expected = record
    url = (f'https://github.com/go-gost/gost/releases/download/v{GOST_VERSION}/'
           f'gost_{GOST_VERSION}_linux_{arch}.tar.gz')
    log('GOST v3.3.0 resmî GitHub sürümünden indiriliyor ve SHA-256 kontrol ediliyor…')
    with tempfile.TemporaryDirectory(prefix='discord-gost-') as tmp:
        archive = Path(tmp) / 'gost.tar.gz'
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Discord-WARP-GOST-Installer/0.2'})
            with urllib.request.urlopen(req, timeout=60) as inp, open(archive, 'wb') as out:
                shutil.copyfileobj(inp, out)
        except Exception as exc:
            raise SetupError('GOST indirilemedi. GitHub Releases erişiminizi kontrol edin.') from exc
        with open(archive, 'rb') as downloaded:
            digest = hashlib.file_digest(downloaded, 'sha256').hexdigest()
        if digest != expected:
            raise SetupError('GOST SHA-256 doğrulaması başarısız! İndirilen dosya kullanılmadı.')
        with tarfile.open(archive, 'r:gz') as tar:
            member = next((m for m in tar.getmembers() if m.name.lstrip('./') == 'gost' and m.isfile()), None)
            if member is None:
                raise SetupError('GOST arşivinde gost dosyası bulunamadı.')
            source = tar.extractfile(member)
            if source is None:
                raise SetupError('GOST çalıştırılabilir dosyası okunamadı.')
            target_dir = Path.home() / '.local/bin'
            target_dir.mkdir(parents=True, exist_ok=True)
            temp_binary = target_dir / 'gost.download'
            try:
                with open(temp_binary, 'wb') as f:
                    shutil.copyfileobj(source, f)
                temp_binary.chmod(0o755)
                temp_binary.replace(target_dir / 'gost')
            finally:
                temp_binary.unlink(missing_ok=True)
    log('GOST SHA-256 doğrulaması geçti; kullanıcı dizinine yüklendi.')


def ensure_flatpak_discord(log):
    if not installed('flatpak'):
        raise SetupError('Flatpak yok. .deb paketini bağımlılıklarıyla kurun.')
    result = subprocess.run(['flatpak', 'info', 'com.discordapp.Discord'],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    if result.returncode == 0:
        log('Discord Flatpak kurulu, korunuyor.')
        return
    log('Flathub kullanıcı deposu tanımlanıyor…')
    call(['flatpak', 'remote-add', '--user', '--if-not-exists', 'flathub',
          'https://dl.flathub.org/repo/flathub.flatpakrepo'], log, timeout=120)
    log('Discord, Flathub üzerinden kullanıcı hesabınıza indiriliyor…')
    call(['flatpak', 'install', '--user', '-y', '--noninteractive', 'flathub',
          'com.discordapp.Discord'], log, timeout=1200)


def warp_is_proxy():
    if not installed('warp-cli'):
        return False
    res = subprocess.run(['warp-cli', 'settings'], stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True, timeout=20, check=False)
    return 'Mode: WarpProxy on port 40000' in res.stdout


def configure_warp(log, terms_accepted):
    if not terms_accepted:
        raise SetupError('Cloudflare koşullarını kabul etmeden WARP kaydı oluşturulamaz.')
    # If WARP is currently active in a whole-device mode, refuse to change it.
    if not warp_is_proxy():
        status = subprocess.run(['warp-cli', '--accept-tos', 'status'],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, timeout=20, check=False)
        if 'Status update: Connected' in status.stdout:
            raise SetupError('WARP başka bir modda bağlı. Genel trafiğe dokunmamak için otomatik işlem durduruldu.')

    log('WARP kullanıcı kaydı kontrol ediliyor…')
    reg = subprocess.run(['warp-cli', '--accept-tos', 'registration', 'show'],
                         text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                         timeout=20, check=False)
    if reg.returncode:
        log('Kayıt bulunamadı, yeni WARP kaydı oluşturuluyor…')
        call(['warp-cli', '--accept-tos', 'registration', 'new'], log, timeout=120)

    if not warp_is_proxy():
        log('WARP yalnızca yerel proxy moduna ayarlanıyor…')
        call(['warp-cli', 'mode', 'proxy'], log, timeout=40)
        call(['warp-cli', 'proxy', 'port', '40000'], log, timeout=40)
    if not warp_is_proxy():
        raise SetupError('WARP proxy modunun etkinleştiği doğrulanamadı; bağlantı açılmadı.')
    log('WARP modu doğrulandı: WarpProxy, localhost:40000.')
    status = subprocess.run(['warp-cli', 'status'], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, timeout=20, check=False)
    if 'Status update: Connected' not in status.stdout:
        call(['warp-cli', 'connect'], log, timeout=120)
    log('WARP bağlantı kontrolü sürüyor…')
    for _ in range(15):
        status = subprocess.run(['warp-cli', 'status'], stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=20, check=False)
        if 'Status update: Connected' in status.stdout:
            log('WARP bağlı.')
            return
        time.sleep(1)
    raise SetupError('WARP bağlanamadı. Kullanıcı kaydı veya ağ erişimini kontrol edin.')


def install(log, terms_accepted):
    if os.geteuid() == 0:
        raise SetupError('Kurulum sihirbazını root/sudo olarak başlatmayın.')
    log('Gereksinimler denetleniyor…')
    install_warp_if_missing(log)
    download_gost(log)
    ensure_flatpak_discord(log)
    configure_warp(log, terms_accepted)
    log('Discord başlatıcısı, GOST servisi ve masaüstü kısayolu kuruluyor…')
    call(['bash', str(HERE / 'install.sh')], log, timeout=60)
    log('Tamamlandı. Discord (WARP) uygulama veya masaüstü kısayolundan açılabilir.')


def uninstall(log):
    call(['bash', str(HERE / 'uninstall.sh')], log, timeout=60)
    log('WARP, GOST ve Discord uygulamaları kurulu kaldı; genel DNS değiştirilmedi.')


def doctor(log):
    call(['bash', str(HERE / 'doctor.sh')], log, timeout=60, check=False)
