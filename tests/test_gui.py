#!/usr/bin/env python3
"""Headless Tkinter wizard transition regression tests (xvfb-run)."""
from __future__ import annotations

import sys
import time
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'gui'))
import installer  # noqa: E402


def wait_until_done(app, limit=4.0):
    end = time.monotonic() + limit
    while time.monotonic() < end:
        app.update()
        if not app.busy and app.events.empty():
            return
        time.sleep(.01)
    raise AssertionError('GUI background operation did not complete')


def assert_destroyed(app):
    try:
        still_exists = app.winfo_exists()
    except installer.tk.TclError:
        # Tk tears down the whole Tcl application on root destroy.
        return
    assert not still_exists, 'Close button did not close wizard'


def test_uninstall_finishes():
    with mock.patch.object(installer, 'status_snapshot', return_value={'Discord Flatpak': True}), \
         mock.patch('tkinter.messagebox.askyesno', return_value=True), \
         mock.patch.object(installer, 'uninstall', side_effect=lambda log: log('Removed successfully')) as backend:
        app = installer.Installer()
        app.withdraw()
        try:
            app._run('uninstall')
            wait_until_done(app)
            assert backend.call_count == 1
            assert app.step == 3, f'Uninstall did not enter final page: {app.step}'
            assert app.next_button.cget('text') == 'Kapat'
            assert 'Kaldırma tamamlandı' in app.status_text.get()
            assert app.remove_button.winfo_manager() == ''
            labels = [c.cget('text') for c in app.content.winfo_children() if isinstance(c, installer.tk.Label)]
            assert any('Kaldırma tamamlandı' in l for l in labels)
            assert all('Kurulum tamamlandı!' not in l for l in labels)
            app.next_button.invoke()
            assert_destroyed(app)
        finally:
            try:
                app.destroy()
            except installer.tk.TclError:
                pass


def test_install_finishes():
    with mock.patch.object(installer, 'status_snapshot', return_value={'Discord Flatpak': True}), \
         mock.patch.object(installer, 'install', side_effect=lambda log, accepted: log('Installed')) as backend:
        app = installer.Installer()
        app.withdraw()
        try:
            app._page(2)
            app._run('install')
            wait_until_done(app)
            assert backend.call_count == 1
            assert app.step == 3
            assert app.next_button.cget('text') == 'Discord’u Aç'
            assert app.close_button.winfo_manager() == 'pack', 'Missing close option on install finish'
            app.close_button.invoke()
            assert_destroyed(app)
        finally:
            try:
                app.destroy()
            except installer.tk.TclError:
                pass


def test_uninstall_retry_stays_uninstall():
    calls = {'n': 0}

    def fail_once(log):
        calls['n'] += 1
        if calls['n'] == 1:
            raise installer.SetupError('mock removal failed')
        log('Removed on second try')

    with mock.patch.object(installer, 'status_snapshot', return_value={'Discord Flatpak': True}), \
         mock.patch('tkinter.messagebox.askyesno', return_value=True), \
         mock.patch.object(installer, 'uninstall', side_effect=fail_once), \
         mock.patch.object(installer, 'install', side_effect=AssertionError('Must not install')):
        app = installer.Installer()
        app.withdraw()
        try:
            app._run('uninstall')
            wait_until_done(app)
            assert app.step == 2
            assert app.next_button.cget('text') == 'Tekrar Dene'
            app.next_button.invoke()
            wait_until_done(app)
            assert calls['n'] == 2
            assert app.step == 3
            assert app.next_button.cget('text') == 'Kapat'
        finally:
            app.destroy()


if __name__ == '__main__':
    test_uninstall_finishes()
    test_install_finishes()
    test_uninstall_retry_stays_uninstall()
    print('PASS: GUI install, uninstall finish, correct retry operation')
