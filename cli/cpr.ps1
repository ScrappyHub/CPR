param(
  [Parameter(Mandatory=$true,Position=0)]
  [ValidateSet("verify","build","selftest")]
  [string]$Command,

  [Parameter(Mandatory=$false)]
  [string]$RepoRoot,

  [Parameter(Mandatory=$false)]
  [string]$PacketPath,

  [Parameter(Mandatory=$false)]
  [string]$InputDir,

  [Parameter(Mandatory=$false)]
  [string]$OutDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Join-Path $PSScriptRoot ".."
}

if (-not [System.IO.Path]::IsPathRooted($RepoRoot)) {
  $RepoRoot = Join-Path (Get-Location).Path $RepoRoot
}

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

switch ($Command) {
  "verify" {
    if ([string]::IsNullOrWhiteSpace($PacketPath)) {
      throw "CPR_VERIFY_PACKET_PATH_MISSING"
    }
    & (Join-Path $RepoRoot "scripts\verify_packet_v1.ps1") `
      -RepoRoot $RepoRoot `
      -PacketPath $PacketPath
    exit $LASTEXITCODE
  }

  "build" {
    if ([string]::IsNullOrWhiteSpace($InputDir)) {
      throw "CPR_BUILD_INPUT_DIR_MISSING"
    }
    if ([string]::IsNullOrWhiteSpace($OutDir)) {
      throw "CPR_BUILD_OUT_DIR_MISSING"
    }
    & (Join-Path $RepoRoot "scripts\build_packet_v1.ps1") `
      -RepoRoot $RepoRoot `
      -InputDir $InputDir `
      -OutDir $OutDir
    exit $LASTEXITCODE
  }

  "selftest" {
    & (Join-Path $RepoRoot "scripts\_selftest_cpr_v1.ps1") -RepoRoot $RepoRoot
    exit $LASTEXITCODE
  }

  default {
    throw "CPR_UNKNOWN_COMMAND"
  }
}
