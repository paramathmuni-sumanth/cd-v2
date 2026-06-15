# Migration status

All environments imported into `environments/` on branch `main`. Legacy sources preserved in [`registry.yaml`](../environments/registry.yaml).

## Environment import status

| Environment | Folder | Source | Files imported | Argo v2 cutover |
|-------------|--------|--------|----------------|-----------------|
| qa1 | `environments/qa1/` | `celigo/cd` `qa1` | ~502 | Not started |
| qa-prod | `environments/qa-prod/` | `celigo/cd` `qa-prod` | ~320 | Not started |
| ia-qa | `environments/ia-qa/` | `celigo/cd` `ia-qa` | ~312 | Not started |
| core | `environments/core/` | `celigo/cd` `core` | ~213 | Not started |
| platform1-dev | `environments/platform1-dev/` | `celigo/cd` | ~239 | Not started |
| platform2-dev | `environments/platform2-dev/` | `celigo/cd` | ~208 | Not started |
| platform3-dev | `environments/platform3-dev/` | `celigo/cd` | ~235 | Not started |
| platform4-dev | `environments/platform4-dev/` | `celigo/cd` | ~165 | Not started |
| platform5-dev | `environments/platform5-dev/` | `celigo/cd` | ~194 | Not started |
| platform1-dev-dr | `environments/platform1-dev-dr/` | `celigo/cd` | ~146 | Not started |
| staging | `environments/staging/` | `celigo/cd-staging` `staging` | ~272 | Not started |
| production-na | `environments/production-na/` | `celigo/cd-prod` | ~293 | Not started |
| production-eu | `environments/production-eu/` | `celigo/cd-prod` | ~286 | Not started |
| master-dev | `environments/master-dev/` | `celigo/dev-environments` | ~205 | Not started |

**Total:** ~3,591 files under `environments/`

## Recommended cutover order

1. `platform3-dev` (or your assigned platform) — lowest prod risk
2. `platform1-dev` … `platform5-dev`, `master-dev`
3. `qa1`, `ia-qa`, `core`
4. `qa-prod`
5. `staging`
6. `production-na`, `production-eu` — last, with change window

## Per-environment checklist

- [ ] Spot-check 3 services: Helm render matches legacy branch
- [ ] Schema validation passes (`@celigo/schema-manager`)
- [ ] Generate Argo apps: `./scripts/generate-argo-app.sh <env> <service>`
- [ ] Test ArgoCD sync on non-prod cluster
- [ ] Update `ci` repo paths for Jenkins validation
- [ ] PR to `celigo/cd` (or org decision to adopt `cd-v2` as new org repo)
- [ ] Switch production ArgoCD `repoURL` + `targetRevision` + valueFiles
- [ ] Freeze legacy branch/repo for that environment

## Next work items

- [ ] ApplicationSet generator per environment (replace legacy `argo_app_manifest.json`)
- [ ] GitHub Action: YAML lint + schema validation on PRs
- [ ] `base/` DRY extraction for high-churn services (optional optimization)
- [ ] Promotion script: diff + PR from `environments/qa1` → `environments/qa-prod`

## Re-sync from upstream

```bash
./scripts/import-all-environments.sh
```

Run after upstream changes to pull latest legacy state into cd-v2.
