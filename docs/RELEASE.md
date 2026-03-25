# CPR Release Notes

## Release readiness

CPR is ready for initial public release when all of the following are true:

- CPR_SELFTEST_OK passes
- CPR_TIER0_FULL_GREEN passes
- README exists
- docs exist
- receipt ledger exists
- positive and negative vectors exist
- build and verify are both proven on disk

## Release contents

- scripts
- cli
- docs
- test vectors
- proofs/receipts sample ledger
- README

## First public release goal

The first public release should prove that CPR is a deterministic packet runtime with:
- strict build
- strict verify
- deterministic fail tokens
- deterministic selftest
- deterministic full green runner

## Suggested first tag

cpr-tier0-seal-2026
