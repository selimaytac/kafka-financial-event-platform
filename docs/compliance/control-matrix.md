# Control matrix

Status values: `planned` · `implemented` · `verified` (evidence exists and is repeatable).

| ID | Reference (maps to) | Control | Implementation | Evidence | Status |
|---|---|---|---|---|---|
| CM-01 | DORA Art. 9(4)(e) (ICT change management); ISO 27001 A.8.32 | Every change is a reviewed, attributable commit that passed CI | Pull requests only; ruleset `protect-main` with required checks, no bypass; managed as code in `infra/stacks/github/` | `git log`; PR history; rejected direct push (GH013); drift test on repository settings | implemented |
| CM-02 | DORA Art. 6 (documented ICT risk framework); ISO 27001 A.5.37 | Architecture decisions are recorded with alternatives | ADRs in `docs/adr/` | [ADR index](../adr/README.md) | implemented |
| CM-03 | DORA Art. 9(4)(e); ISO 27001 A.8.9 | Cluster state changes only through Git (no manual drift) | Argo CD automated sync with self-heal | Manually deleted Deployment restored in ~5 s (Phase 1 test) | implemented |
| CM-04 | DORA Art. 9(4)(e); ISO 27001 A.8.32 | Changes are validated before deployment | Every GitOps component rendered per profile and substrate and schema-validated in CI | `task gitops:check`; CI `lint` job; rejected invalid value (test) | implemented |
| CM-05 | ISO 27001 A.8.2 (privileged access); DORA Art. 9(4)(c) | Emergency (break-glass) changes follow a documented, ordered procedure | Runbook: revert in Git first, then reinstall from corrected state | [Argo CD recovery runbook](../runbooks/recover-argocd.md) (not yet exercised) | planned |
| SEC-01 | ISO 27001 A.5.17 (authentication information) | No secrets committed to the repository | gitleaks pre-commit hook, GitHub push protection, full-history scan in CI | `task secrets:scan`; `secrets` job in `.github/workflows/ci.yml` | implemented |
| SEC-02 | ISO 27001 A.8.24 (use of cryptography) | Encrypt data in transit | Gateway TLS via cert-manager from a lab PKI (done); Kafka TLS listeners (Phase 3) | `curl` verification against the root; chain leaf ← intermediate ← root | implemented (gateway) |
| SEC-03 | ISO 27001 A.5.15 / A.8.3 (access control); DORA Art. 9(4)(c) | Least-privilege access to event streams | Kafka SCRAM users and ACLs per service | _Phase 3_ | planned |
| SEC-04 | ISO 27001 A.8.9 (configuration management) | Secure workload configuration baseline | Kyverno policies (Audit → Enforce) | _Phase 2_ | planned |
| SEC-05 | ISO 27001 A.5.21 (ICT supply chain) | Third-party code is content-addressed | CI actions and pre-commit hooks pinned by commit SHA; OpenTofu providers locked by hash; images pinned by digest | `.github/workflows/ci.yml`, `.pre-commit-config.yaml`, `infra/**/.terraform.lock.hcl` | implemented |
| REC-01 | MiFIR Art. 25; RTS 24 | Order and trade records retained and retrievable | Audit tables in ClickHouse, retention per data class | _Phase 4_ | planned |
| REC-02 | MiFIR Art. 25; ISO 27001 A.8.15 | Audit records are tamper-evident | Append-only storage, hash chaining / object lock | _Phase 4_ | planned |
| LOG-01 | ISO 27001 A.8.15 (logging); DORA Art. 10 (detection) | Security and access logs retained with defined periods | Log pipeline with retention tiers | _Phase 2_ | planned |
| PII-01 | GDPR Art. 5(1)(c) data minimisation; Art. 32 pseudonymisation | Personal data classified and masked where not needed | Schema tags + field masking | _Phase 4_ | planned |
| MKT-01 | MiFID II Art. 48(5); RTS 11 | Pre-trade controls: tick sizes and price corridors with volatility interruptions | Order entry and matching engine rules | _Phase 4_ | planned |
| TIME-01 | RTS 25 | Event timestamps in UTC with microsecond granularity | Event schemas and producers | _Phase 4_ | planned |
| SUR-01 | MAR Art. 16 | Detect suspicious order patterns (e.g. spoofing, wash trades) | Surveillance consumer | _Phase 4_ | planned |
| RES-01 | DORA Art. 12 (backup, restoration and recovery) | Backups with tested restore | State store backup (`task lab:backup`) and restore drill; cluster data backups in Phase 7 | L3 drill: restore in 33 s, all plans clean ([host operations](../runbooks/host-operations.md)) | implemented (state only) |
| RES-02 | DORA Art. 24-25 (resilience testing) | HA/DR scenarios exercised with measured RPO/RTO | Chaos Mesh + DR drills | [DR catalogue](../dr/README.md), _Phase 7_ | planned |
| OPS-01 | ISO 27001 A.8.8 (vulnerability management) and A.8.32 | Components have documented upgrade and maintenance plans | `docs/operations/` | _Phase 8_ | planned |
