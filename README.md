# Canonical Packet Runtime (CPR)

CPR is the deterministic runtime surface for canonical packet build and verify under Packet Constitution v1 Option A.

## Current Tier-0 surface

- strict packet build
- strict packet verify
- deterministic selftest
- deterministic negative vectors
- append-only receipts

## Commands

Selftest:
.\cli\cpr.ps1 selftest -RepoRoot .

Build:
.\cli\cpr.ps1 build -RepoRoot . -InputDir C:\path\to\input -OutDir C:\path\to\outbox

Verify:
.\cli\cpr.ps1 verify -RepoRoot . -PacketPath C:\path\to\packet

## Success tokens

- CPR_BUILD_OK
- CPR_VERIFY_OK
- CPR_SELFTEST_OK
- CPR_TIER0_FULL_GREEN

## Core guarantees

- manifest.json must not contain packet_id
- packet_id.txt must equal SHA-256 of manifest.json bytes on disk
- sha256sums.txt must match exact on-disk bytes
- sha256sums.txt must cover all packet files except itself
- traversal-unsafe relative paths are rejected
- verification is non-mutating

## Receipt log

proofs/receipts/cpr.ndjson
