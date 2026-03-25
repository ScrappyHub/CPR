# CPR Audit Notes

## Audit surfaces

- README.md
- docs/PACKET_CONSTITUTION.md
- docs/RECEIPTS.md
- docs/WHAT_IS_CPR.md
- docs/HOW_TO_RUN.md
- docs/DEBUG.md
- scripts/_selftest_cpr_v1.ps1
- scripts/FULL_GREEN_RUNNER_CPR_v1.ps1
- proofs/receipts/cpr.ndjson
- test_vectors/packet_constitution_v1/minimal
- test_vectors/packet_constitution_v1/negative

## What to audit

1. Positive vector passes.
2. Negative vectors fail with deterministic reason tokens.
3. Build emits packet directory named by packet id.
4. Verify is non-mutating.
5. Receipt log appends and does not rewrite history.
6. sha256sums.txt excludes itself and covers all other packet files.
7. packet_id.txt equals SHA-256 of manifest.json bytes exactly as written.

## Current negative vectors

- manifest_contains_packet_id
- packet_id_mismatch
- sha256_mismatch

## Current receipt event types

- build
- verify
- selftest
- full_green
