# cd-v2 — unified Celigo CD (all environments, one branch)

Single-branch GitOps repo consolidating **all** Celigo deployment environments that were previously spread across:

- **`celigo/cd`** — env branches: `qa1`, `qa-prod`, `ia-qa`, `core`, `platform1-dev` … `platform5-dev`, `platform1-dev-dr`
- **`celigo/cd-staging`** — `staging`
- **`celigo/cd-prod`** — `production-na`, `production-eu`
- **`celigo/dev-environments`** — `master-dev`

> **Experimental / not production.** Production ArgoCD still points at the legacy repos until per-environment cutover.

## Layout

```
cd-v2/
├── charts/                          # shared Helm charts (single copy)
├── environments/
│   ├── registry.yaml                # env metadata + legacy source mapping
│   ├── qa1/                         # full service trees per env
│   ├── qa-prod/
│   ├── ia-qa/
│   ├── core/
│   ├── platform1-dev/ … platform5-dev/
│   ├── platform1-dev-dr/
│   ├── staging/
│   ├── production-na/
│   ├── production-eu/
│   └── master-dev/
│       └── {io,core,ia,di,ui,internal,tools}/
│           └── {service}/
│               ├── microservice.yaml
│               ├── env.yaml         # when present
│               └── argo_app_manifest.json  # legacy, for reference
├── argo/                            # v2 ArgoCD Application manifests
├── base/                            # optional future DRY layer (see base/README.md)
├── scripts/
└── docs/
```

## Environments (14 total)

| Folder | Legacy source | Tier |
|--------|---------------|------|
| `qa1` | `celigo/cd` → `qa1` | qa |
| `qa-prod` | `celigo/cd` → `qa-prod` | qa |
| `ia-qa` | `celigo/cd` → `ia-qa` | qa |
| `core` | `celigo/cd` → `core` | qa |
| `platform1-dev` … `platform5-dev` | `celigo/cd` | dev |
| `platform1-dev-dr` | `celigo/cd` | dev |
| `staging` | `celigo/cd-staging` → `staging` | staging |
| `production-na` | `celigo/cd-prod` → `production-na` | production |
| `production-eu` | `celigo/cd-prod` → `production-eu` | production |
| `master-dev` | `celigo/dev-environments` → `master-dev` | dev |

See [`environments/registry.yaml`](environments/registry.yaml) for full metadata.

## ArgoCD (v2 layout)

```yaml
source:
  path: charts/microservice
  repoURL: https://github.com/paramathmuni-sumanth/cd-v2.git
  targetRevision: main
  helm:
    valueFiles:
      - ../../../environments/qa-prod/io/hello-world/microservice.yaml
      - ../../../environments/qa-prod/io/hello-world/env.yaml   # if exists
```

Generate an app manifest:

```bash
./scripts/generate-argo-app.sh qa-prod io/integrator-workers
```

Generate all apps for a domain:

```bash
./scripts/generate-argo-apps-for-env.sh platform3-dev io
```

Apply to cluster (after registering cd-v2 in ArgoCD):

```bash
./scripts/apply-argo-apps.sh platform3-dev io --dry-run
```

## Scripts

| Script | Purpose |
|--------|---------|
| `import-all-environments.sh` | Re-sync all envs from upstream repos |
| `inventory-services.sh` | List services on a legacy branch |
| `diff-env-branches.sh` | Diff a service between two legacy branches |
| `scaffold-service.sh` | Scaffold one service from upstream |
| `promote-service.sh` | Copy env folder → env folder |
| `generate-argo-app.sh` | Generate v2 Argo Application YAML |
| `generate-argo-apps-for-env.sh` | Generate all apps for an env domain |
| `apply-argo-apps.sh` | kubectl apply all generated apps |

### Re-import from upstream

```bash
./scripts/import-all-environments.sh
```

## Git remotes

| Remote | URL |
|--------|------|
| `origin` | `paramathmuni-sumanth/cd-v2` |
| `upstream` | `celigo/cd` |
| `upstream-staging` | `celigo/cd-staging` |
| `upstream-prod` | `celigo/cd-prod` |
| `upstream-dev-envs` | `celigo/dev-environments` |
| `cd-legacy` | `paramathmuni-sumanth/cd` (your ticket fork) |

## Repo roles

| Repo | Use |
|------|-----|
| `paramathmuni-sumanth/cd` | Day-to-day tickets, legacy env-branch PRs |
| **`paramathmuni-sumanth/cd-v2`** | Unified layout, migration lab, future org CD |
| `celigo/cd` (+ staging/prod) | Production GitOps today |

## Cutover plan

1. Validate render on test ArgoCD per environment
2. Port Argo apps one env at a time (`targetRevision: main`, new valueFiles paths)
3. Update `ci` repo validators + onboarding templates
4. Deprecate legacy env branches/repos per environment

Track progress in [`docs/migration-status.md`](docs/migration-status.md).
