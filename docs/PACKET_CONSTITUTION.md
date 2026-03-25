# Packet Constitution v1 Option A (CPR surface)

## Required files

- manifest.json
- packet_id.txt
- sha256sums.txt

## Law

- manifest.json MUST NOT contain packet_id
- packet_id.txt MUST equal SHA-256 of manifest.json bytes exactly as written on disk
- sha256sums.txt MUST be generated after manifest.json and packet_id.txt exist
- sha256sums.txt MUST NOT include itself
- every other file in the packet MUST be covered by sha256sums.txt
- relative paths MUST be traversal-safe

## Verify behavior

CPR verify is strict and non-mutating.

Expected outputs are:

- CPR_VERIFY_OK
- CPR_VERIFY_FAIL:<REASON>
