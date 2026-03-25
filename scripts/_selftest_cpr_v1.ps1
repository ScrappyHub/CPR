param(
  [Parameter(Mandatory=$true)]
  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

. (Join-Path $RepoRoot "scripts\_lib_cpr_v1.ps1")

function Fail([string]$Code) {
  Write-Host ("CPR_SELFTEST_FAIL:" + $Code) -ForegroundColor Red
  exit 1
}

function Invoke-Verify(
  [string]$RepoRoot,
  [string]$PacketPath
) {
  $PSExe = (Get-Command powershell.exe).Source
  $Output = & $PSExe `
    -NoProfile `
    -NonInteractive `
    -ExecutionPolicy Bypass `
    -File (Join-Path $RepoRoot "scripts\verify_packet_v1.ps1") `
    -RepoRoot $RepoRoot `
    -PacketPath $PacketPath 2>&1

  $ExitCode = $LASTEXITCODE
  $OutputText = (($Output | ForEach-Object { $_.ToString() }) -join "`n")

  return [PSCustomObject]@{
    ExitCode = $ExitCode
    OutputText = $OutputText
  }
}

try {
  Parse-GateFile (Join-Path $RepoRoot "scripts\_lib_cpr_v1.ps1")
  Parse-GateFile (Join-Path $RepoRoot "scripts\verify_packet_v1.ps1")
  Parse-GateFile (Join-Path $RepoRoot "scripts\build_packet_v1.ps1")
  Parse-GateFile (Join-Path $RepoRoot "cli\cpr.ps1")

  $VectorPath = Join-Path $RepoRoot "test_vectors\packet_constitution_v1\minimal"
  $ExpectedPacketIdPath = Join-Path $VectorPath "expected_packet_id.txt"
  $ExpectedShaPath = Join-Path $VectorPath "expected_sha256sums.txt"
  $PacketIdPath = Join-Path $VectorPath "packet_id.txt"
  $ShaPath = Join-Path $VectorPath "sha256sums.txt"

  if (-not (Test-Path -LiteralPath $VectorPath -PathType Container)) {
    Fail "VECTOR_MISSING"
  }

  $RunRoot = Join-Path $RepoRoot "proofs\receipts\selftest_packet"
  if (Test-Path -LiteralPath $RunRoot) {
    Remove-Item -LiteralPath $RunRoot -Recurse -Force
  }
  EnsureDir $RunRoot
  EnsureDir (Join-Path $RunRoot "payload")

  Copy-Item -LiteralPath (Join-Path $VectorPath "manifest.json")      -Destination (Join-Path $RunRoot "manifest.json")      -Force
  Copy-Item -LiteralPath (Join-Path $VectorPath "packet_id.txt")      -Destination (Join-Path $RunRoot "packet_id.txt")      -Force
  Copy-Item -LiteralPath (Join-Path $VectorPath "sha256sums.txt")     -Destination (Join-Path $RunRoot "sha256sums.txt")     -Force
  Copy-Item -LiteralPath (Join-Path $VectorPath "payload\hello.txt")  -Destination (Join-Path $RunRoot "payload\hello.txt")  -Force

  $Positive = Invoke-Verify -RepoRoot $RepoRoot -PacketPath $RunRoot
  if ($Positive.ExitCode -ne 0) {
    $Positive.OutputText | Out-Host
    Fail "POSITIVE_VERIFY_EXIT_NONZERO"
  }
  if ($Positive.OutputText -notmatch 'CPR_VERIFY_OK') {
    $Positive.OutputText | Out-Host
    Fail "POSITIVE_VERIFY_TOKEN_MISSING"
  }

  $ExpectedPacketId = ([System.IO.File]::ReadAllText($ExpectedPacketIdPath)).Trim().ToLowerInvariant()
  $ActualPacketId = ([System.IO.File]::ReadAllText($PacketIdPath)).Trim().ToLowerInvariant()
  if ($ExpectedPacketId -ne $ActualPacketId) {
    Fail "EXPECTED_PACKET_ID_MISMATCH"
  }

  $ExpectedSha = ([System.IO.File]::ReadAllText($ExpectedShaPath)).Replace("`r`n","`n").Replace("`r","`n").Trim()
  $ActualSha = ([System.IO.File]::ReadAllText($ShaPath)).Replace("`r`n","`n").Replace("`r","`n").Trim()
  if ($ExpectedSha -ne $ActualSha) {
    Fail "EXPECTED_SHA256SUMS_MISMATCH"
  }

  $NegativeCases = @(
    [PSCustomObject]@{
      Name = "manifest_contains_packet_id"
      Path = (Join-Path $RepoRoot "test_vectors\packet_constitution_v1\negative\manifest_contains_packet_id")
      Token = "CPR_VERIFY_FAIL:MANIFEST_CONTAINS_PACKET_ID"
    },
    [PSCustomObject]@{
      Name = "packet_id_mismatch"
      Path = (Join-Path $RepoRoot "test_vectors\packet_constitution_v1\negative\packet_id_mismatch")
      Token = "CPR_VERIFY_FAIL:PACKET_ID_MISMATCH"
    },
    [PSCustomObject]@{
      Name = "sha256_mismatch"
      Path = (Join-Path $RepoRoot "test_vectors\packet_constitution_v1\negative\sha256_mismatch")
      Token = "CPR_VERIFY_FAIL:SHA256_MISMATCH"
    }
  )

  foreach ($Case in $NegativeCases) {
    if (-not (Test-Path -LiteralPath $Case.Path -PathType Container)) {
      Fail ("NEGATIVE_VECTOR_MISSING_" + $Case.Name.ToUpperInvariant())
    }

    $Result = Invoke-Verify -RepoRoot $RepoRoot -PacketPath $Case.Path

    if ($Result.ExitCode -eq 0) {
      $Result.OutputText | Out-Host
      Fail ("NEGATIVE_EXIT_ZERO_" + $Case.Name.ToUpperInvariant())
    }

    if ($Result.OutputText -notmatch [regex]::Escape($Case.Token)) {
      $Result.OutputText | Out-Host
      Fail ("NEGATIVE_TOKEN_MISSING_" + $Case.Name.ToUpperInvariant())
    }
  }

  $Receipt = [ordered]@{
    schema = "cpr.receipt.v1"
    event_type = "selftest"
    result = "PASS"
    vector_rel = "test_vectors/packet_constitution_v1/minimal"
    negatives = @(
      "manifest_contains_packet_id",
      "packet_id_mismatch",
      "sha256_mismatch"
    )
  }

  Add-CprReceipt -RepoRoot $RepoRoot -Receipt $Receipt

  Write-Host "CPR_SELFTEST_OK" -ForegroundColor Green
  exit 0
}
catch {
  Write-Host ("CPR_SELFTEST_FAIL:UNHANDLED:" + $_.Exception.Message) -ForegroundColor Red
  exit 1
}
