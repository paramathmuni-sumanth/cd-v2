# cd-v2 — CD layout modernization (experimental)

Experimental sandbox for migrating Celigo's GitOps CD repo from **branch-per-environment** to **folder-per-environment** on a single default branch.

> **Not production.** ArgoCD in production clusters must continue to use [`celigo/cd`](https://github.com/celigo/cd) until an explicit per-environment cutover.

## Repo roles

| Repo | Purpose |
|------|---------|
| [`celigo/cd`](https://github.com/celigo/cd) | Org source of truth (production GitOps) |
| [`paramathmuni-sumanth/cd`](https://github.com/paramathmuni-sumanth/cd) | Regular fork — tickets and day-to-day env-branch PRs |
| **`paramathmuni-sumanth/cd-v2`** (this repo) | Migration lab — new layout, scripts, ADRs, test Argo apps |

## Target layout

```
cd-v2/
├── charts/                              # shared Helm charts
├── base/{domain}/{service}/             # shared defaults per service
│   └── microservice.yaml
├── environments/{env}/{domain}/{service}/  # env-specific overrides only
│   └── env.yaml
├── argo/                                # ArgoCD Application manifests (v2 layout)
├── scripts/                             # inventory, diff, promote helpers
└── docs/                                # ADRs and migration tracking
```

ArgoCD valueFiles (example):

```yaml
valueFiles:
  - ../../../base/io/hello-world/microservice.yaml
  - ../../../environments/platform3-dev/io/hello-world/env.yaml
targetRevision: main
```

## Pilot

| Item | Value |
|------|-------|
| Environment | `platform3-dev` |
| Service | `io/hello-world` |
| Status | See [docs/migration-status.md](docs/migration-status.md) |

## Remotes

```bash
git remote add upstream https://github.com/celigo/cd.git
git remote add cd-legacy https://github.com/paramathmuni-sumanth/cd.git   # optional
```

Sync chart or service content from org repo:

```bash
git fetch upstream
# Example: export a service from an env branch
git archive upstream/platform3-dev io/hello-world | tar -x
```

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/inventory-services.sh` | List all services under a domain from an upstream branch |
| `scripts/diff-env-branches.sh` | Diff a service's YAML between two upstream branches |
| `scripts/promote-service.sh` | Copy env overrides from one environment folder to another |

## Testing with ArgoCD

Point a **non-production** ArgoCD instance at this repo:

- `repoURL`: `https://github.com/paramathmuni-sumanth/cd-v2.git`
- `targetRevision`: `main`
- Application manifest: `argo/platform3-dev/io/hello-world.yaml`

Do not point production ArgoCD at this repo.

## Contributing upstream

When a pattern is validated here, port it to `paramathmuni-sumanth/cd` and open a PR to `celigo/cd`. See [docs/migration-status.md](docs/migration-status.md) for the promotion checklist.

## Related docs

- [ADR 001: Folder-based environments](docs/adr/001-folder-based-environments.md)
- [Migration status](docs/migration-status.md)
