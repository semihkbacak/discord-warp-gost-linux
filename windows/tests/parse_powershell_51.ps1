$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failed = $false
Get-ChildItem -LiteralPath (Join-Path $root 'assets') -Filter '*.ps1' | ForEach-Object {
  $tokens = $null
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
  if ($errors.Count -gt 0) {
    $failed = $true
    foreach ($e in $errors) {
      Write-Host ($_.Name + ':' + $e.Extent.StartLineNumber + ':' + $e.Extent.StartColumnNumber + ' ' + $e.Message)
    }
  }
}
if ($failed) { exit 1 }
Write-Host 'PowerShell 5.1 parser: PASS'
