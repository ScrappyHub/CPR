# CPR Receipts

Receipt ledger path:

proofs/receipts/cpr.ndjson

## Current receipt schema marker

cpr.receipt.v1

## Current event types

- build
- verify
- selftest
- full_green

## Contract

- append-only NDJSON
- UTF-8 without BOM
- LF newlines
- one canonical JSON object per line

## Purpose

Receipts prove runtime behavior and create an auditable record of packet production and verification.
