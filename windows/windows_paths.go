//go:build windows

package main

import (
	"fmt"
	"os"
	"strings"
	"syscall"
	"unsafe"
)

var kernel32 = syscall.NewLazyDLL("kernel32.dll")
var getLongPathNameW = kernel32.NewProc("GetLongPathNameW")

// longWindowsPath converts short 8.3 aliases in existing paths into their
// canonical long spelling. It is not a security bypass or a network change.
func longWindowsPath(path string) (string, error) {
	input, err := syscall.UTF16PtrFromString(path)
	if err != nil {
		return "", err
	}
	n := uint32(512)
	for n <= 32768 {
		buf := make([]uint16, n)
		r, _, e := getLongPathNameW.Call(uintptr(unsafe.Pointer(input)), uintptr(unsafe.Pointer(&buf[0])), uintptr(n))
		size := uint32(r)
		if size == 0 {
			return "", fmt.Errorf("GetLongPathNameW(%q): %w", path, e)
		}
		if size < n {
			return syscall.UTF16ToString(buf[:size]), nil
		}
		n = size + 1
	}
	return "", fmt.Errorf("resolved path is too long")
}

// Apply a case-insensitive environment override without duplicating keys.
func overrideEnv(env []string, key, value string) []string {
	for i := range env {
		k, _, ok := strings.Cut(env[i], "=")
		if ok && strings.EqualFold(k, key) {
			env[i] = key + "=" + value
			return env
		}
	}
	return append(env, key+"="+value)
}

func safeChildEnvironment(bundle, exe string) ([]string, error) {
	env := os.Environ()
	for _, key := range []string{"TEMP", "TMP", "LOCALAPPDATA", "APPDATA", "USERPROFILE"} {
		val := os.Getenv(key)
		if val == "" {
			continue
		}
		long, err := longWindowsPath(val)
		if err != nil {
			// Temp is required, but a machine may not define some other folders.
			if key == "TEMP" || key == "TMP" {
				return nil, fmt.Errorf("cannot normalize %s: %w", key, err)
			}
			continue
		}
		env = overrideEnv(env, key, long)
	}
	env = overrideEnv(env, "DWG_BUNDLE", bundle)
	env = overrideEnv(env, "DWG_ORIGINAL_EXE", exe)
	return env, nil
}
