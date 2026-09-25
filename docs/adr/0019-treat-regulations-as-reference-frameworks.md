# 0019. Treat financial regulations as reference frameworks for controls

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The platform models a securities exchange, where record keeping, access
control, operational resilience and personal-data protection are regulated. The project
is a learning and portfolio platform, not an audited production system, so it must not
claim compliance, but its controls should be traceable to real requirements.

The European Union framework is used as the single reference set: it is comprehensive,
public and widely used as a benchmark internationally. National rulebooks are not mapped.

Frameworks used as references:

| Framework | Scope used here |
|---|---|
| MiFID II / MiFIR, incl. RTS 24 (order data kept by venues) and RTS 25 (clock synchronisation) | Order and trade record keeping (MiFIR Art. 25), timestamp accuracy |
| MiFID II Art. 48 and RTS 7 | Venue resilience, capacity and circuit breakers |
| MAR (Regulation (EU) No 596/2014) Art. 16 | Detecting and reporting suspicious orders and transactions |
| DORA (Regulation (EU) 2022/2554) | ICT risk management, change management, backup and recovery, resilience testing, incidents |
| CSDR | Settlement cycle and settlement discipline |
| GDPR | Personal data: minimisation, pseudonymisation, erasure |
| ISO/IEC 27001:2022 Annex A | Generic security controls: secrets, cryptography, access, logging, configuration |

## Options

| Option | Pros | Cons |
|---|---|---|
| Ignore regulation | Simpler | Unrealistic for the domain |
| Claim compliance | Sounds strong | Untrue without an audit; misleading |
| Map controls to frameworks as references, with evidence | Honest, traceable, reviewable | Requires a maintained control matrix |

## Decision

Maintain a **control matrix** in `docs/compliance/`:
reference → control → implementation → evidence. Wording is always
"inspired by" / "maps to", never "compliant with".

## Consequences

- Every phase adds or updates rows in the control matrix.
- Retention, audit immutability and PII handling get their own ADRs when implemented.
- Specific retention periods quoted must cite the source clause.
