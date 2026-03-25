param(
  [Parameter(Mandatory=$true)]
  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# FIX: anchor RepoRoot to script location if relative
if (-not [System.IO.Path]::IsPathRooted($RepoRoot)) {
  $RepoRoot = Join-Path $PSScriptRoot ".."
}

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

. (Join-Path $RepoRoot "scripts\_lib_cpr_v1.ps1")

function Fail([string]$Code) {
  Write-Host ("CPR_FULL_GREEN_FAIL:" + $Code) -ForegroundColor Red
  exit 1
}

try {
  $Targets = @(
    (Join-Path $RepoRoot "scripts\_lib_cpr_v1.ps1"),
    (Join-Path $RepoRoot "scripts\verify_packet_v1.ps1"),
    (Join-Path $RepoRoot "scripts\build_packet_v1.ps1"),
    (Join-Path $RepoRoot "scripts\_selftest_cpr_v1.ps1"),
    (Join-Path $RepoRoot "cli\cpr.ps1")
  )

  foreach ($Target in $Targets) {
    Parse-GateFile $Target
  }

  $PSExe = (Get-Command powershell.exe).Source

  $SelftestOutput = & $PSExe `
    -NoProfile `
    -NonInteractive `
    -ExecutionPolicy Bypass `
    -File (Join-Path $RepoRoot "scripts\_selftest_cpr_v1.ps1") `
    -RepoRoot $RepoRoot 2>&1

  $SelftestExit = $LASTEXITCODE
  $SelftestText = (($SelftestOutput | ForEach-Object { $_.ToString() }) -join "`n")

  if ($SelftestExit -ne 0) {
    $SelftestText | Out-Host
    Fail "SELFTEST_EXIT_NONZERO"
  }

  if ($SelftestText -notmatch 'CPR_SELFTEST_OK') {
    $SelftestText | Out-Host
    Fail "SELFTEST_TOKEN_MISSING"
  }

  $Receipt = [ordered]@{
    schema = "cpr.receipt.v1"
    event_type = "full_green"
    result = "PASS"
    selftest_token = "CPR_SELFTEST_OK"
  }

  Add-CprReceipt -RepoRoot $RepoRoot -Receipt $Receipt

  Write-Host "CPR_TIER0_FULL_GREEN" -ForegroundColor Green
  exit 0
}
catch {
  Write-Host ("CPR_FULL_GREEN_FAIL:UNHANDLED:" + $_.Exception.Message) -ForegroundColor Red
  exit 1
}
