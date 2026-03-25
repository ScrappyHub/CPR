param(
  [Parameter(Mandatory=$true)]
  [string]$RepoRoot,
  [Parameter(Mandatory=$true)]
  [string]$PacketPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $RepoRoot "scripts\_lib_cpr_v1.ps1")

function Fail([string]$Code) {
  Write-Host ("CPR_VERIFY_FAIL:" + $Code) -ForegroundColor Red
  exit 1
}

try {
  $PacketFull = [System.IO.Path]::GetFullPath($PacketPath)

  if (-not (Test-Path -LiteralPath $PacketFull -PathType Container)) {
    Fail "PACKET_DIR_MISSING"
  }

  $ManifestPath = Join-Path $PacketFull "manifest.json"
  $PacketIdPath = Join-Path $PacketFull "packet_id.txt"
  $ShaPath = Join-Path $PacketFull "sha256sums.txt"

  if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    Fail "MISSING_MANIFEST"
  }
  if (-not (Test-Path -LiteralPath $PacketIdPath -PathType Leaf)) {
    Fail "MISSING_PACKET_ID"
  }
  if (-not (Test-Path -LiteralPath $ShaPath -PathType Leaf)) {
    Fail "MISSING_SHA256SUMS"
  }

  $ManifestObj = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
  $ManifestProps = @($ManifestObj.PSObject.Properties.Name)
  if ($ManifestProps -contains "packet_id") {
    Fail "MANIFEST_CONTAINS_PACKET_ID"
  }

  $ExpectedPacketId = ([System.IO.File]::ReadAllText($PacketIdPath)).Trim().ToLowerInvariant()
  if ($ExpectedPacketId -notmatch '^[0-9a-f]{64}$') {
    Fail "BAD_PACKET_ID_FORMAT"
  }

  $ManifestBytes = [System.IO.File]::ReadAllBytes($ManifestPath)
  $ActualPacketId = Get-BytesSha256Hex $ManifestBytes
  if ($ActualPacketId -ne $ExpectedPacketId) {
    Fail "PACKET_ID_MISMATCH"
  }

  $ShaText = [System.IO.File]::ReadAllText($ShaPath)
  $ShaText = $ShaText.Replace("`r`n","`n").Replace("`r","`n")
  $ShaLines = @($ShaText.Split("`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if ($ShaLines.Count -eq 0) {
    Fail "EMPTY_SHA256SUMS"
  }

  $Listed = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)

  foreach ($Line in $ShaLines) {
    if ($Line -notmatch '^([0-9a-f]{64})  (.+)$') {
      Fail "BAD_SHA256SUM_LINE"
    }

    $ExpectedHash = $Matches[1]
    $RelPath = $Matches[2]

    if (-not (Test-SafeRelativePath $RelPath)) {
      Fail "TRAVERSAL_PATH"
    }

    if ($RelPath -eq "sha256sums.txt") {
      Fail "SHA256SUMS_SELF_INCLUDED"
    }

    $TargetPath = Join-Path $PacketFull $RelPath
    $TargetFull = [System.IO.Path]::GetFullPath($TargetPath)

    if (-not $TargetFull.StartsWith($PacketFull,[System.StringComparison]::OrdinalIgnoreCase)) {
      Fail "TRAVERSAL_PATH"
    }

    if (-not (Test-Path -LiteralPath $TargetFull -PathType Leaf)) {
      Fail "MISSING_TARGET"
    }

    $ActualHash = Get-FileSha256Hex $TargetFull
    if ($ActualHash -ne $ExpectedHash) {
      Fail "SHA256_MISMATCH"
    }

    [void]$Listed.Add($RelPath.Replace('\','/'))
  }

  $ActualFiles = Get-ChildItem -LiteralPath $PacketFull -File -Recurse |
    Where-Object { $_.FullName -ne $ShaPath }

  $ActualSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)

  foreach ($File in $ActualFiles) {
    $Rel = Get-RelativePathNormalized $PacketFull $File.FullName
    [void]$ActualSet.Add($Rel)
  }

  foreach ($Rel in $ActualSet) {
    if (-not $Listed.Contains($Rel)) {
      Fail "SHA256SUMS_MISSING_COVERAGE"
    }
  }

  foreach ($Rel in $Listed) {
    if (-not $ActualSet.Contains($Rel)) {
      Fail "SHA256SUMS_EXTRA_ENTRY"
    }
  }

  $Receipt = [ordered]@{
    schema = "cpr.receipt.v1"
    event_type = "verify"
    result = "PASS"
    packet_rel = Get-RelativePathNormalized $RepoRoot $PacketFull
    packet_id = $ActualPacketId
  }

  Add-CprReceipt -RepoRoot $RepoRoot -Receipt $Receipt

  Write-Host "CPR_VERIFY_OK" -ForegroundColor Green
  exit 0
}
catch {
  Write-Host ("CPR_VERIFY_FAIL:UNHANDLED:" + $_.Exception.Message) -ForegroundColor Red
  exit 1
}
