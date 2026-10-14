#!/usr/bin/env python3
"""Native Ubuntu desktop setup wizard for Discord-specific WARP + GOST."""
from __future__ import annotations

import queue
import sys
import threading
import tkinter as tk
from tkinter import ttk
import webbrowser
from pathlib import Path

from setup_backend import SetupError, doctor, install, status_snapshot, uninstall

BG = '#101827'
PANEL = '#172338'
FG = '#EDF3FA'
MUTED = '#AABBD0'
ACCENT = '#667EEA'
GOOD = '#56C6A1'
BAD = '#F3A4A4'
VERSION = '0.2.0'


class Installer(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('Discord (WARP) • Kurulum Sihirbazı')
        self.geometry('760x680')
        self.minsize(730, 640)
        self.configure(bg=BG)
        self.events = queue.Queue()
        self.busy = False
        self.finished = False
        self.step = 0
        self.accepted = tk.BooleanVar(value=False)
        self.status_text = tk.StringVar(value='Kuruluma hazır')
        self._build()
        self.after(90, self._poll)
        self._page(0)

    def label(self, parent, text, size=11, weight='normal', color=FG, **kw):
        return tk.Label(parent, text=text, font=('DejaVu Sans', size, weight),
                        fg=color, bg=parent.cget('bg'), anchor='w', justify='left', **kw)

    def _build(self):
        top = tk.Frame(self, bg=PANEL, padx=30, pady=24)
        top.pack(fill='x')
        self.label(top, 'DISCORD  /  WARP  /  GOST', 11, 'bold', ACCENT).pack(anchor='w')
        self.label(top, 'Linux Kurulum Sihirbazı', 23, 'bold').pack(anchor='w', pady=(7, 0))
        self.label(top, 'Yalnızca Discord için yerel proxy • Genel DNS ayarlarına dokunmaz',
                   10, color=MUTED).pack(anchor='w', pady=(8, 0))

        progressrow = tk.Frame(self, bg=BG)
        progressrow.pack(fill='x', padx=30, pady=(18, 9))
        self.step_labels = []
        for i, name in enumerate(['1  Hoş geldiniz', '2  Kontrol', '3  Yükleme', '4  Tamamlandı']):
            lbl = self.label(progressrow, name, 10, color=MUTED)
            lbl.pack(side='left', expand=True, fill='x')
            self.step_labels.append(lbl)
        self.content = tk.Frame(self, bg=BG)
        self.content.pack(fill='both', expand=True, padx=30)
        self.status = self.label(self, '', 10, color=MUTED)
        self.status.pack(fill='x', padx=30, pady=(4, 4))
        self.bar = ttk.Progressbar(self, mode='indeterminate')
        self.bar.pack(fill='x', padx=30)
        bottom = tk.Frame(self, bg=BG, pady=15, padx=30)
        bottom.pack(fill='x')
        self.back_button = self.button(bottom, '‹  Geri', self._back, muted=True)
        self.back_button.pack(side='left')
        self.next_button = self.button(bottom, 'İleri  ›', self._next)
        self.next_button.pack(side='right')
        self.remove_button = self.button(bottom, 'Kaldır', lambda: self._run('uninstall'), muted=True)
        self.remove_button.pack(side='right', padx=(0, 10))

    def button(self, parent, title, command, muted=False):
        return tk.Button(parent, text=title, command=command, cursor='hand2',
                         padx=19, pady=9, font=('DejaVu Sans', 10, 'bold'),
                         bg=PANEL if muted else ACCENT, fg=FG, activebackground='#5369D7',
                         activeforeground='white', relief='flat', bd=0)

    def _clear(self):
        for widget in self.content.winfo_children():
            widget.destroy()

    def _page(self, step):
        self.step = step
        # Restore the ordinary navigation handler after retry/diagnostic actions.
        self.next_button.configure(command=self._next)
        self._clear()
        for i, label in enumerate(self.step_labels):
            label.configure(fg=ACCENT if i == step else MUTED)
        self.status.configure(textvariable=self.status_text)
        self.back_button.configure(state='normal' if step in (1, 2) and not self.busy else 'disabled')
        self.remove_button.configure(state='normal' if not self.busy else 'disabled')
        if step == 0:
            self.label(self.content, 'Hoş geldiniz', 19, 'bold').pack(anchor='w', pady=(10, 16))
            text = ('Bu sihirbaz Discord için ayrı bir WARP + GOST bağlantısı hazırlar.\n\n'
                    '• Ubuntu’nun DNS, NetworkManager ve VPN yapılandırmasına dokunmaz.\n'
                    '• WARP eksikse yalnızca resmî Cloudflare paketini kurar.\n'
                    '• GOST dosyasının SHA-256 özeti doğrulanır.\n'
                    '• Discord, Flathub üzerinden kurulur (kuruluysa korunur).\n'
                    '• Masaüstüne “Discord (WARP)” kısayolu ekler.\n\n'
                    'Not: Ses ve ekran paylaşımındaki UDP/WebRTC akışları her ağda\n'
                    'proxy üzerinden taşınmayabilir.')
            self.label(self.content, text, 11, color=MUTED).pack(anchor='w')
            self.next_button.configure(text='Başla  ›', state='normal')
        elif step == 1:
            self.label(self.content, 'Sistem kontrolü', 19, 'bold').pack(anchor='w', pady=(10, 15))
            snap = status_snapshot()
            for name, present in snap.items():
                frame = tk.Frame(self.content, bg=PANEL, padx=14, pady=8)
                frame.pack(fill='x', pady=3)
                self.label(frame, name, 10).pack(side='left')
                self.label(frame, 'Kurulu ✓' if present else 'Kurulacak', 10,
                           'bold', GOOD if present else MUTED).pack(side='right')
            accept = tk.Checkbutton(self.content,
                     text='Cloudflare WARP hizmet koşullarını ve gizlilik politikasını okudum, kabul ediyorum.',
                     variable=self.accepted, bg=BG, fg=FG, activebackground=BG,
                     activeforeground=FG, selectcolor=PANEL, font=('DejaVu Sans', 9),
                     wraplength=670, justify='left')
            accept.pack(anchor='w', pady=(16, 6))
            linkrow = tk.Frame(self.content, bg=BG)
            linkrow.pack(anchor='w')
            for name, url in [('Hizmet koşulları', 'https://www.cloudflare.com/application/terms/'),
                              ('Gizlilik politikası', 'https://www.cloudflare.com/application/privacypolicy/')]:
                btn = self.button(linkrow, name + ' ↗', lambda u=url: webbrowser.open(u), muted=True)
                btn.pack(side='left', padx=(0, 8))
            self.next_button.configure(text='Yükle  ›', state='normal')
        elif step == 2:
            self.label(self.content, 'Yükleme ilerlemesi', 19, 'bold').pack(anchor='w', pady=(8, 12))
            frame = tk.Frame(self.content, bg=PANEL)
            frame.pack(fill='both', expand=True)
            self.logbox = tk.Text(frame, bg=PANEL, fg=FG, insertbackground=FG,
                                  font=('DejaVu Sans Mono', 9), bd=0, padx=13,
                                  pady=13, wrap='word', state='disabled')
            scrollbar = ttk.Scrollbar(frame, command=self.logbox.yview)
            self.logbox.configure(yscrollcommand=scrollbar.set)
            self.logbox.pack(side='left', fill='both', expand=True)
            scrollbar.pack(side='right', fill='y')
            self.next_button.configure(text='Discord’u Aç', state='disabled')
        elif step == 3:
            self.label(self.content, 'Kurulum tamamlandı!', 21, 'bold', GOOD).pack(anchor='w', pady=(18, 18))
            self.label(self.content,
                       'Discord (WARP) kısayolu artık uygulama menüsünde ve varsa\n'
                       'masaüstünüzde yer alıyor. Bir terminal açmanız gerekmiyor.\n\n'
                       'Chrome, Steam ve diğer uygulamalar normal bağlantılarını kullanır.\n'
                       'Genel DNS ayarlarında değişiklik yapılmadı.',
                       11, color=MUTED).pack(anchor='w')
            self.next_button.configure(text='Discord’u Aç', state='normal')
            self.button(self.content, 'Bağlantı tanılama', lambda: self._run('doctor'),
                        muted=True).pack(anchor='w', pady=(24, 0))

    def _next(self):
        if self.busy:
            return
        if self.step == 0:
            self._page(1)
        elif self.step == 1:
            if not self.accepted.get():
                self.status_text.set('Devam etmek için Cloudflare hizmet koşullarını kabul etmelisiniz.')
                return
            self._page(2)
            self._run('install')
        elif self.step == 3:
            try:
                import subprocess
                subprocess.Popen([str(Path.home()/'.local/bin/discord-warp-gost-linux')],
                                 start_new_session=True)
                self.destroy()
            except Exception as ex:
                self.status_text.set(f'Başlatılamadı: {ex}')

    def _back(self):
        if not self.busy:
            self._page(0 if self.step == 1 else 1)

    def _append_log(self, message):
        if hasattr(self, 'logbox') and self.logbox.winfo_exists():
            self.logbox.configure(state='normal')
            self.logbox.insert('end', message + '\n')
            self.logbox.see('end')
            self.logbox.configure(state='disabled')

    def _run(self, operation):
        if self.busy:
            return
        if operation == 'uninstall' and not self.finished:
            # Make removing a pre-existing setup intentional.
            from tkinter import messagebox
            if not messagebox.askyesno('Kaldırma onayı',
                   'Discord (WARP) başlatıcısını kaldırmak istiyor musunuz?\n'
                   'Orijinal Discord, WARP ve GOST uygulamaları korunacak.'):
                return
        if operation != 'install':
            self._page(2)
        self.busy = True
        self.next_button.configure(state='disabled')
        self.back_button.configure(state='disabled')
        self.remove_button.configure(state='disabled')
        self.bar.start(12)
        self.status_text.set('İşlem devam ediyor…')
        self._append_log('--- ' + {'install':'Kurulum', 'uninstall':'Kaldırma', 'doctor':'Tanılama'}[operation] + ' ---')

        def worker():
            def log(msg):
                self.events.put(('log', msg))
            try:
                if operation == 'install':
                    install(log, True)
                elif operation == 'uninstall':
                    uninstall(log)
                else:
                    doctor(log)
                self.events.put(('done', operation))
            except Exception as exc:
                self.events.put(('error', str(exc)))
        threading.Thread(target=worker, daemon=True).start()

    def _poll(self):
        try:
            while True:
                tag, value = self.events.get_nowait()
                if tag == 'log':
                    self._append_log(value)
                else:
                    self.busy = False
                    self.bar.stop()
                    self.remove_button.configure(state='normal')
                    self.back_button.configure(state='normal')
                    if tag == 'error':
                        self._append_log('HATA: ' + value)
                        self.status_text.set('İşlem tamamlanamadı: ayrıntılar yukarıda.')
                        self.next_button.configure(text='Tekrar Dene', state='normal',
                                                   command=lambda: self._run('install'))
                    elif value == 'install':
                        self.finished = True
                        self.status_text.set('Kurulum tamamlandı.')
                        self._page(3)
                    elif value == 'uninstall':
                        self.status_text.set('Kurulum kaldırıldı. WARP ve Discord korunuyor.')
                        self.next_button.configure(text='Başa Dön', state='normal',
                                                   command=lambda: self._page(0))
                    else:
                        self.status_text.set('Tanılama tamamlandı.')
                        self.next_button.configure(text='Başa Dön', state='normal',
                                                   command=lambda: self._page(0))
        except queue.Empty:
            pass
        self.after(90, self._poll)


if __name__ == '__main__':
    if '--self-test' in sys.argv:
        # No graphical session or network required.
        print(f'GUI module ready: version {VERSION}')
    else:
        try:
            Installer().mainloop()
        except tk.TclError as error:
            print('Grafik oturumu başlatılamadı:', error, file=sys.stderr)
            sys.exit(1)
