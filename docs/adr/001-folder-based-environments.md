# ADR 001: Folder-based environments

## Status

Proposed (pilot in cd-v2)

## Context

The `celigo/cd` repository uses **long-lived git branches as environments** (`qa-prod`, `qa1`, `platform3-dev`, etc.). ArgoCD `Application` resources set `targetRevision` to the branch name. Each branch contains a full copy of ~350+ deployment files.

Problems:

- Config drift between branches (not just env vars — replicas, auth policies, probes differ)
- Promotion requires PRs across branches/repos with no single diff view
- `main` holds CI workflows only; deployment manifests live on env branches — confusing for new engineers
- 100+ stale experiment branches accumulate over time

## Decision

Adopt a **folder-per-environment** layout on a **single default branch (`main`)**:

```
base/{domain}/{service}/microservice.yaml     # shared service defaults
environments/{env}/{domain}/{service}/env.yaml  # env-specific overrides only
```

Helm `valueFiles` merge base + env override. ArgoCD `targetRevision` becomes `main` (after per-env cutover).

**Do not adopt Kapitan.** Continue with Helm + ArgoCD; add Kustomize or ApplicationSet only if Helm layering is insufficient.

## Consequences

### Positive

- One PR can show changes across environments
- `git diff environments/qa1 environments/qa-prod` for promotion review
- Clear home for CI and manifests on `main`
- Enables ApplicationSet to replace hand-written `argo_app_manifest.json` files

### Negative

- Large one-time migration effort (~100 services × N environments)
- Must update `ci` repo validators, onboarding templates, and ArgoCD apps
- Staging/prod in separate repos (`cd-staging`, `cd-prod`) need a later phase
- During transition, both legacy and v2 paths may coexist

## Alternatives considered

| Option | Rejected because |
|--------|------------------|
| Keep branch-per-env | Drift and DX problems persist |
| Kapitan | New compile toolchain on top of Helm; team already invested in Helm values |
| New org repo (`celigo/cd-v2`) immediately | Requires org-wide ArgoCD cutover before validation |
| Kustomize-only | Helm chart is entrenched; values layering is lower migration cost |

## Migration strategy

1. Pilot one service + one env in **this repo** (`cd-v2`)
2. Validate on test ArgoCD (non-prod cluster)
3. Port proven pattern to `celigo/cd` via PR from regular fork
4. Migrate env-by-env; deprecate env branches last
5. Archive `cd-v2` or merge into `celigo/cd` when complete

## References

- Pilot: `base/io/hello-world/` + `environments/platform3-dev/io/hello-world/`
- Legacy: `celigo/cd` branch `platform3-dev`, path `io/hello-world/`
