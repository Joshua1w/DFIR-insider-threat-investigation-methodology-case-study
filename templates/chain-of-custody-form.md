# Chain of custody record

> A template for evidence items in this investigation. Fill in one record per evidence item. Every movement, access, copy or verification goes in the transfer log, with **no gaps**. If something unexpected happens (a broken seal, a hash mismatch, a time gap), record it as it happened. Never correct it after the fact.

## Case details

| Field | Value |
|---|---|
| Case reference | |
| Authorising officer and authority reference | |
| Lead examiner | |
| Second examiner / witness | |
| Time zone used in this record | e.g. WAT (UTC+1) |
| Trusted time source | e.g. NTP-synced reference clock |

## Item details

| Field | Value |
|---|---|
| Item ID | e.g. `E01` (physical), `E01-IMG` (image derived from E01) |
| Description | Make, model, serial number, asset tag, condition |
| Location where found | Building, floor, desk |
| Date and time seized | |
| Seized by | Name, role |
| Seal number(s) | |
| State when found | Powered on / off / locked / unlocked; screen contents photographed (Y/N); photo refs |
| Device clock vs trusted time | Device shows `__:__:__` when the trusted source shows `__:__:__` (offset ±___ s) |
| Encryption | None / BitLocker / other; recovery key secured (Y/N, source) |

## Digital acquisition

| Field | Value |
|---|---|
| Acquisition type | Physical image / logical / memory / triage package / log export |
| Tool and version | |
| Write protection | Hardware blocker (model) / software / not possible (state why) |
| Output file(s) | |
| Hash algorithm | SHA-256 |
| Acquisition hash | |
| Verification hash | |
| Hashes match | Y / N |
| Changes caused by live capture | e.g. tool execution, files written to the host, network connections |

## Transfer and access log

| # | Date | Time | Item ID | Action | Released by (name, signature) | Received by (name, signature) | Purpose | Storage location | Integrity check |
|---|---|---|---|---|---|---|---|---|---|
| 1 | | | | Seized and sealed | | | | | Seal no. ___ |
| 2 | | | | | | | | | |
| 3 | | | | | | | | | |
| 4 | | | | | | | | | |
| 5 | | | | | | | | | |

**Actions** typically include: seized and sealed, forensic image created, placed in evidence store, released for analysis, returned to store, hash re-verified, copy provided to (party), returned to owner, destroyed (with authority).

**Integrity checks** typically include: seal intact (no.), hash matched, hash **mismatch** (stop and escalate), not applicable (state why).

## Disposition

| Field | Value |
|---|---|
| Final disposition | Retained / returned / destroyed |
| Authority for disposition | |
| Date | |
| Signature | |

## Worked example (illustrative)

| Date | Time (WAT) | Item | Action | From / to | Integrity |
|---|---|---|---|---|---|
| 10 Nov | 09:10 | E01 Laptop | Seized and sealed (seal 004417) | Desk → lead examiner | n/a |
| 10 Nov | 10:05 | E01-IMG | Forensic image created | Lead examiner | SHA-256 recorded |
| 10 Nov | 13:40 | E01 Laptop | Placed in evidence store | Examiner → custodian | Seal intact |
| 11 Nov | 08:30 | E01-IMG copy | Released for analysis | Custodian → examiner | Hash matched |
