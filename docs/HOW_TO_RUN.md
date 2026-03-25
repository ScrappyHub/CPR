# How To Run CPR

## Selftest

Run from the repo root:

.\cli\cpr.ps1 selftest -RepoRoot .

Expected success token:

CPR_SELFTEST_OK

## Full green

Run from the repo root:

.\scripts\FULL_GREEN_RUNNER_CPR_v1.ps1 -RepoRoot .

Expected success token:

CPR_TIER0_FULL_GREEN

## Build a packet

.\cli\cpr.ps1 build -RepoRoot . -InputDir C:\path\to\input -OutDir C:\path\to\outbox

Expected success token:

CPR_BUILD_OK

The build command creates a packet directory named by packet id inside the output directory.

## Verify a packet

.\cli\cpr.ps1 verify -RepoRoot . -PacketPath C:\path\to\packet

Expected success token:

CPR_VERIFY_OK

## Receipt log

proofs/receipts/cpr.ndjson
