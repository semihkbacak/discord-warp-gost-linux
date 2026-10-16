//go:build windows

package main

import (
	"syscall"
	"unsafe"
)

func alertWindows(message string) {
	title, _ := syscall.UTF16PtrFromString("Discord WARP + GOST Setup")
	body, _ := syscall.UTF16PtrFromString(message)
	dll := syscall.NewLazyDLL("user32.dll")
	dialog := dll.NewProc("MessageBoxW")
	_, _, _ = dialog.Call(0, uintptr(unsafe.Pointer(body)), uintptr(unsafe.Pointer(title)), 0x10)
}
