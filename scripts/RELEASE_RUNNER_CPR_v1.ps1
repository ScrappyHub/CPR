param(
  [Parameter(Mandatory=$true)]
  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not [System.IO.Path]::IsPathRooted($RepoRoot)) {
  $RepoRoot = Join-Path $PSScriptRoot ".."
}

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

function Fail([string]$Code) {
  Write-Host ("CPR_RELEASE_FAIL:" + $Code) -ForegroundColor Red
  exit 1
}

$Targets = @(
  (Join-Path $RepoRoot "README.md"),
  (Join-Path $RepoRoot "docs\PACKET_CONSTITUTION.md"),
  (Join-Path $RepoRoot "docs\RECEIPTS.md"),
  (Join-Path $RepoRoot "docs\WHAT_IS_CPR.md"),
  (Join-Path $RepoRoot "docs\HOW_TO_RUN.md"),
  (Join-Path $RepoRoot "docs\AUDIT.md"),
  (Join-Path $RepoRoot "docs\DEBUG.md"),
  (Join-Path $RepoRoot "docs\RELEASE.md"),
  (Join-Path $RepoRoot "scripts\FULL_GREEN_RUNNER_CPR_v1.ps1")
)

foreach ($Target in $Targets) {
  if (-not (Test-Path -LiteralPath $Target)) {
    Fail ("MISSING_REQUIRED_FILE:" + $Target)
  }
}

$PSExe = (Get-Command powershell.exe).Source
$Output = & $PSExe `
  -NoProfile `
  -NonInteractive `
  -ExecutionPolicy Bypass `
  -File (Join-Path $RepoRoot "scripts\FULL_GREEN_RUNNER_CPR_v1.ps1") `
  -RepoRoot $RepoRoot 2>&1

$ExitCode = $LASTEXITCODE
$OutputText = (($Output | ForEach-Object { $_.ToString() }) -join "`n")

if ($ExitCode -ne 0) {
  $OutputText | Out-Host
  Fail "FULL_GREEN_EXIT_NONZERO"
}

if ($OutputText -notmatch 'CPR_TIER0_FULL_GREEN') {
  $OutputText | Out-Host
  Fail "FULL_GREEN_TOKEN_MISSING"
}

Write-Host "CPR_RELEASE_READY" -ForegroundColor Green
