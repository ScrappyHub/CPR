# What CPR Is

Canonical Packet Runtime (CPR) is the deterministic runtime surface for canonical packet build and verify under Packet Constitution v1 Option A.

CPR is responsible for:
- building canonical packet directory bundles
- verifying canonical packet directory bundles
- enforcing packet law strictly
- rejecting invalid packets with explicit fail tokens
- emitting append-only receipts

CPR is not:
- an identity authority
- a policy engine
- a witness ledger
- a UI product
- a business application

In the stack, CPR is the reusable packet runtime that other systems call when they need canonical packet production or canonical packet verification.

## Current Tier-0 surface

- build_packet_v1.ps1
- verify_packet_v1.ps1
- _selftest_cpr_v1.ps1
- FULL_GREEN_RUNNER_CPR_v1.ps1
- cli/cpr.ps1

## Current guarantees

- manifest.json must not contain packet_id
- packet_id.txt must equal SHA-256 of manifest.json bytes on disk
- sha256sums.txt must match exact on-disk bytes
- sha256sums.txt must cover all packet files except itself
- traversal-unsafe relative paths are rejected
- verification is strict and non-mutating
