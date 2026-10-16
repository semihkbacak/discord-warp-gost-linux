// Windows-only, self-contained GUI bootstrapper; no elevation and no external Go modules.
package main

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
)

//go:embed assets/*.ps1 assets/aero-skin.png assets/app.ico
var bundle embed.FS

func main() {
	if len(os.Args) > 1 && os.Args[1] == "--launch" {
		launchDiscord()
		return
	}
	temp, err := os.MkdirTemp("", "discord-warp-setup-*")
	if err != nil {
		showError(err)
		return
	}
	// Clear stale startup reports so diagnostics always refer to the current run.
	_ = os.Remove(filepath.Join(os.TempDir(), "discord-warp-setup-error.txt"))
	// Windows may expose a Unicode profile folder as an 8.3 TEMP path such as
	// C:\Users\SEMH~1. Windows PowerShell's provider has known failures with
	// such paths. Resolve to the real long name BEFORE extracting scripts.
	longTemp, err := longWindowsPath(temp)
	if err != nil {
		showError(fmt.Errorf("cannot resolve temporary folder: %w", err))
		_ = os.RemoveAll(temp)
		return
	}
	temp = longTemp
	defer os.RemoveAll(temp)
	for _, filename := range []string{"Setup-GUI.ps1", "Install.ps1", "Remove.ps1", "Diagnose.ps1", "Launch-Discord.ps1", "Common.ps1", "Setup-Warp.ps1", "aero-skin.png", "app.ico"} {
		b, e := fs.ReadFile(bundle, "assets/"+filename)
		if e != nil {
			showError(e)
			return
		}
		if e = os.WriteFile(filepath.Join(temp, filename), b, 0600); e != nil {
			showError(e)
			return
		}
	}
	exe, _ := os.Executable()
	cmd := exec.Command("powershell.exe", "-NoLogo", "-NoProfile", "-STA", "-ExecutionPolicy", "Bypass", "-File", filepath.Join(temp, "Setup-GUI.ps1"))
	env, err := safeChildEnvironment(temp, exe)
	if err != nil {
		showError(err)
		return
	}
	cmd.Env = env
	output, err := cmd.CombinedOutput()
	if err != nil {
		report := fmt.Sprintf("Discord WARP + GOST v1.0.0 - setup error: %v\r\n\r\n%s", err, string(output))
		if len(report) > 12000 { report = report[:12000] + "\r\n[output truncated]" }
		reportPath := filepath.Join(os.TempDir(), "discord-warp-setup-error.txt")
		_ = os.WriteFile(reportPath, []byte(report), 0600)
		showError(fmt.Errorf("kurulum arayuzu acilamadi (%v). Ayrinti: %s", err, reportPath))
	}
}

// The same signed-or-unsigned .exe is installed as the desktop shortcut target.
// Start powershell without opening a Windows Terminal window; unlike a VBS
// wrapper this uses the native Win32 process flags and requires no scripting host.
func launchDiscord() {
	exe, err := os.Executable()
	if err != nil {
		showError(err)
		return
	}
	script := filepath.Join(filepath.Dir(exe), "Launch-Discord.ps1")
	if _, err := os.Stat(script); err != nil {
		showError(fmt.Errorf("launcher script not found: %w", err))
		return
	}
	ps := filepath.Join(os.Getenv("SystemRoot"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
	cmd := exec.Command(ps, "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	env, err := safeChildEnvironment(filepath.Dir(exe), exe)
	if err != nil {
		showError(err)
		return
	}
	cmd.Env = env
	if err := cmd.Run(); err != nil {
		// The PowerShell launcher displays an actionable dialog for ordinary
		// failures. Avoid showing a second generic error popup on exit code 1.
		if _, isScriptExit := err.(*exec.ExitError); isScriptExit {
			return
		}
		showError(fmt.Errorf("Discord launcher could not start: %w", err))
	}
}

func showError(err error) {
	// The GUI executable has no console; send error to stderr for scripted use.
	fmt.Fprintln(os.Stderr, err)
	alertWindows(err.Error())
	// A failure before powershell starts is rare; also save a plain-text diagnostic.
	path := filepath.Join(os.TempDir(), "discord-warp-setup-error.txt")
	if _, statErr := os.Stat(path); os.IsNotExist(statErr) {
		_ = os.WriteFile(path, []byte(err.Error()), 0600)
	}
}
