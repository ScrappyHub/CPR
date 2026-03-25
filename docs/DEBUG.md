# CPR Debug Guide

## Common failure classes

### RepoRoot resolves incorrectly

Symptom:
- script tries to load files from the wrong directory

Fix:
- normalize RepoRoot to an absolute path
- anchor relative repo resolution to script location when needed

### packet verify fails with MISSING_MANIFEST

Symptom:
- packet path points to a directory that is not a packet root

Fix:
- verify the packet directory contains:
  - manifest.json
  - packet_id.txt
  - sha256sums.txt

### packet verify fails with SHA256SUMS_MISSING_COVERAGE

Symptom:
- extra files exist in the packet directory that are not covered by sha256sums.txt

Fix:
- ensure only true packet files are inside the packet directory
- keep harness files outside packet roots

### packet verify fails with PACKET_ID_MISMATCH

Symptom:
- packet_id.txt does not equal SHA-256 of manifest.json bytes

Fix:
- recompute packet_id from manifest.json bytes on disk
- rewrite packet_id.txt
- regenerate sha256sums.txt last

### parse-gate failures

Symptom:
- parser rejects a script before execution

Fix:
- parse-gate every script after writing it
- avoid fragile quoting and malformed here-strings
- prefer explicit path normalization and deterministic file writers

## Known good success tokens

- CPR_BUILD_OK
- CPR_VERIFY_OK
- CPR_SELFTEST_OK
- CPR_TIER0_FULL_GREEN
