Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Die([string]$Message) {
  throw $Message
}

function EnsureDir([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) {
    Die "ENSURE_DIR_EMPTY_PATH"
  }
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-Utf8NoBomLf([string]$Path,[string]$Text) {
  $Parent = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($Parent)) {
    EnsureDir $Parent
  }
  $T = $Text.Replace("`r`n","`n").Replace("`r","`n")
  if (-not $T.EndsWith("`n")) {
    $T += "`n"
  }
  $Enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$T,$Enc)
}

function Parse-GateFile([string]$Path) {
  $Tok = $null
  $Err = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile(
    $Path,
    [ref]$Tok,
    [ref]$Err
  )
  if ($Err -and $Err.Count -gt 0) {
    $E = $Err[0]
    throw ("PARSE_GATE_FAIL: {0}:{1}:{2}: {3}" -f `
      $Path,
      $E.Extent.StartLineNumber,
      $E.Extent.StartColumnNumber,
      $E.Message)
  }
}

function Get-FileSha256Hex([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-BytesSha256Hex([byte[]]$Bytes) {
  $Sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $HashBytes = $Sha.ComputeHash($Bytes)
  }
  finally {
    $Sha.Dispose()
  }
  return ([System.BitConverter]::ToString($HashBytes).Replace("-","").ToLowerInvariant())
}

function Get-RelativePathNormalized([string]$BasePath,[string]$TargetPath) {
  $BaseFull = [System.IO.Path]::GetFullPath($BasePath)
  $TargetFull = [System.IO.Path]::GetFullPath($TargetPath)
  $BaseUri = [System.Uri]($BaseFull.TrimEnd('\') + '\')
  $TargetUri = [System.Uri]$TargetFull
  $Rel = $BaseUri.MakeRelativeUri($TargetUri).ToString()
  $Rel = [System.Uri]::UnescapeDataString($Rel)
  return $Rel.Replace('\','/')
}

function Test-SafeRelativePath([string]$RelativePath) {
  if ([string]::IsNullOrWhiteSpace($RelativePath)) { return $false }
  if ($RelativePath.StartsWith('/')) { return $false }
  if ($RelativePath.StartsWith('\')) { return $false }
  if ($RelativePath -match '^[A-Za-z]:') { return $false }
  $Parts = $RelativePath.Replace('\','/').Split('/')
  foreach ($Part in $Parts) {
    if ($Part -eq '' -or $Part -eq '..') { return $false }
  }
  return $true
}

function Add-CprReceipt(
  [string]$RepoRoot,
  [hashtable]$Receipt
) {
  $ReceiptPath = Join-Path $RepoRoot "proofs\receipts\cpr.ndjson"
  $Line = ($Receipt | ConvertTo-Json -Depth 20 -Compress)
  $Existing = ""
  if (Test-Path -LiteralPath $ReceiptPath -PathType Leaf) {
    $Existing = [System.IO.File]::ReadAllText($ReceiptPath)
    $Existing = $Existing.Replace("`r`n","`n").Replace("`r","`n")
  }
  if ($Existing.Length -gt 0 -and -not $Existing.EndsWith("`n")) {
    $Existing += "`n"
  }
  $Existing += $Line
  $Existing += "`n"
  Write-Utf8NoBomLf $ReceiptPath $Existing
}
