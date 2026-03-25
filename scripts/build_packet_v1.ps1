param(
  [Parameter(Mandatory=$true)]
  [string]$RepoRoot,
  [Parameter(Mandatory=$true)]
  [string]$InputDir,
  [Parameter(Mandatory=$true)]
  [string]$OutDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$InputDir = [System.IO.Path]::GetFullPath($InputDir)
$OutDir   = [System.IO.Path]::GetFullPath($OutDir)

. (Join-Path $RepoRoot "scripts\_lib_cpr_v1.ps1")

function Fail([string]$Code) {
  Write-Host ("CPR_BUILD_FAIL:" + $Code) -ForegroundColor Red
  exit 1
}

try {
  if (-not (Test-Path -LiteralPath $InputDir -PathType Container)) {
    Fail "INPUT_DIR_MISSING"
  }

  EnsureDir $OutDir

  $TmpRoot = Join-Path $OutDir "_cpr_build_tmp"
  if (Test-Path -LiteralPath $TmpRoot) {
    Remove-Item -LiteralPath $TmpRoot -Recurse -Force
  }

  EnsureDir $TmpRoot
  $TmpPayload = Join-Path $TmpRoot "payload"
  EnsureDir $TmpPayload

  $SourceFiles = @(
    Get-ChildItem -LiteralPath $InputDir -File -Recurse |
    Sort-Object FullName
  )

  if ($SourceFiles.Count -eq 0) {
    Fail "INPUT_DIR_EMPTY"
  }

  $ManifestFiles = New-Object System.Collections.Generic.List[object]

  foreach ($SourceFile in $SourceFiles) {
    $InputRel = Get-RelativePathNormalized $InputDir $SourceFile.FullName
    if (-not (Test-SafeRelativePath $InputRel)) {
      Fail "INPUT_RELATIVE_PATH_UNSAFE"
    }

    $DestPath = Join-Path $TmpPayload $InputRel
    $DestParent = Split-Path -Parent $DestPath
    EnsureDir $DestParent
    Copy-Item -LiteralPath $SourceFile.FullName -Destination $DestPath -Force

    $DestHash = Get-FileSha256Hex $DestPath
    $DestSize = ([System.IO.FileInfo]$DestPath).Length

    $Entry = [ordered]@{
      path = ("payload/" + $InputRel.Replace('\','/'))
      size = $DestSize
      sha256 = $DestHash
    }
    [void]$ManifestFiles.Add($Entry)
  }

  $Manifest = [ordered]@{
    schema = "cpr.packet.manifest.v1"
    constitution = "packet_constitution_v1_option_a"
    payload = [ordered]@{
      root = "payload"
      files = @($ManifestFiles.ToArray())
    }
  }

  $ManifestPath = Join-Path $TmpRoot "manifest.json"
  $ManifestJson = $Manifest | ConvertTo-Json -Depth 50 -Compress
  Write-Utf8NoBomLf $ManifestPath $ManifestJson

  $PacketId = Get-BytesSha256Hex ([System.IO.File]::ReadAllBytes($ManifestPath))
  $PacketIdPath = Join-Path $TmpRoot "packet_id.txt"
  Write-Utf8NoBomLf $PacketIdPath $PacketId

  $ShaTargets = @(
    Get-ChildItem -LiteralPath $TmpRoot -File -Recurse |
    Where-Object { $_.Name -ne "sha256sums.txt" } |
    Sort-Object FullName
  )

  $ShaLines = New-Object System.Collections.Generic.List[string]
  foreach ($File in $ShaTargets) {
    $Rel = Get-RelativePathNormalized $TmpRoot $File.FullName
    $Hash = Get-FileSha256Hex $File.FullName
    [void]$ShaLines.Add(($Hash + "  " + $Rel))
  }

  $ShaPath = Join-Path $TmpRoot "sha256sums.txt"
  Write-Utf8NoBomLf $ShaPath (($ShaLines.ToArray()) -join "`n")

  $FinalPacketDir = Join-Path $OutDir $PacketId
  if (Test-Path -LiteralPath $FinalPacketDir) {
    Remove-Item -LiteralPath $FinalPacketDir -Recurse -Force
  }

  Move-Item -LiteralPath $TmpRoot -Destination $FinalPacketDir

  $Receipt = [ordered]@{
    schema = "cpr.receipt.v1"
    event_type = "build"
    result = "PASS"
    input_dir = $InputDir.Replace('\','/')
    out_dir = $OutDir.Replace('\','/')
    packet_id = $PacketId
    packet_rel = Get-RelativePathNormalized $RepoRoot $FinalPacketDir
  }

  Add-CprReceipt -RepoRoot $RepoRoot -Receipt $Receipt

  Write-Host ("PACKET_DIR: " + $FinalPacketDir) -ForegroundColor Gray
  Write-Host ("PACKET_ID: " + $PacketId) -ForegroundColor Gray
  Write-Host "CPR_BUILD_OK" -ForegroundColor Green
  exit 0
}
catch {
  Write-Host ("CPR_BUILD_FAIL:UNHANDLED:" + $_.Exception.Message) -ForegroundColor Red
  exit 1
}
