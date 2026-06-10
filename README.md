# EuroTransit Marketplace — Configuration repository (g03)

Desired state and platform configuration — the **configuration** half of the two-repository
GitOps model (continued from Lab03/Lab04). The **application** repository
(`capstone-application-g03`) holds the service source, tests and CI.

This repository contains:

- `deploy/charts/eurotransit/` — the Helm chart describing the desired application state
  (five services, their CloudNativePG databases, Traefik routing, PDBs).
- `platform/` — bootstrap for shared infrastructure installed once per cluster
  (Traefik, cert-manager, CloudNativePG, Strimzi, Sealed Secrets, Argo CD,
  kube-prometheus-stack, Chaos Mesh). See [platform/README.md](platform/README.md).
- `docs/` — team-owned documentation: the DoD, design/consistency justification, SLO
  definitions, chaos-experiment reports, the postmortem, the agent threat-model, and the
  agent-verification log.

## Delivery flow

```
application repo  →  CI builds/tests, pushes immutable images to ACR,
                     bumps services.<svc>.image.tag in this repo's values.yaml
this repo (Git)   →  Argo CD watches deploy/charts/eurotransit
Argo CD           →  reconciles the cluster to match Git (no manual kubectl/helm)
```

CI never holds cluster credentials. Secrets live in Git **only** as SealedSecrets.

## Docs index

- [docs/capstone-dod.md](docs/capstone-dod.md) — Definition of Done
- [docs/design.md](docs/design.md) — service decomposition, sync/async boundaries, consistency model
- [docs/slo.md](docs/slo.md) — SLO/SLI definitions and error budget
- [docs/agent-threat-model.md](docs/agent-threat-model.md) — non-human actor blast radius
- [docs/agent-log.md](docs/agent-log.md) — where agent-produced artifacts were wrong (graded)
- [docs/chaos/](docs/chaos/) — chaos-experiment reports
- [docs/postmortem.md](docs/postmortem.md) — blameless postmortem of the live incident
