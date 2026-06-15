# Migration status

Track progress migrating from `celigo/cd` branch-per-environment to folder-per-environment layout.

## Environments

| Environment | Branch today (`celigo/cd`) | Folder in cd-v2 | Argo cutover | Notes |
|-------------|---------------------------|-----------------|--------------|-------|
| platform3-dev | `platform3-dev` | `environments/platform3-dev/` | Not started | Pilot env |
| qa1 | `qa1` | — | — | |
| qa-prod | `qa-prod` | — | — | |
| core | `core` | — | — | |
| ia-qa | `ia-qa` | — | — | |
| staging | `cd-staging` repo | — | — | Separate repo |
| production | `cd-prod` repo | — | — | Separate repo |

## Services

| Service | Base extracted | Env override | Argo v2 manifest | Tested on cluster | Upstream PR |
|---------|----------------|--------------|------------------|-------------------|-------------|
| `io/hello-world` | Yes | `platform3-dev` | Yes | No | No |

## Promotion checklist (per service)

- [ ] Split validated: `base/` + `environments/<env>/` renders same as legacy branch YAML
- [ ] Schema validation passes (`@celigo/schema-manager` / Jenkins)
- [ ] ArgoCD sync healthy on test cluster pointing at cd-v2
- [ ] Pattern ported to `paramathmuni-sumanth/cd` branch
- [ ] PR opened to `celigo/cd`
- [ ] Production ArgoCD app updated (with rollback path documented)
- [ ] Legacy path on env branch marked deprecated

## Next steps

1. Validate `hello-world` Argo app on platform3-dev test ArgoCD
2. Add `scripts/split-base-and-env.sh` automation
3. Migrate second pilot service (e.g. `io/microservices-template`)
4. Draft ApplicationSet for `platform3-dev`
