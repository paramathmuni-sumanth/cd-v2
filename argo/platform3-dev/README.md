# platform3-dev — ArgoCD Applications (v2 layout)

Generated manifests for the **io** namespace on **platform3-dev**.

| Item | Value |
|------|-------|
| Environment | `platform3-dev` |
| Domain | `io` |
| Applications | 32 |
| Repo | `paramathmuni-sumanth/cd-v2` |
| Branch | `main` |

## Regenerate

```bash
./scripts/generate-argo-apps-for-env.sh platform3-dev io
```

## Apply to cluster (test only)

Register the cd-v2 repo in ArgoCD first, then:

```bash
# Preview
./scripts/apply-argo-apps.sh platform3-dev io --dry-run

# Apply all io apps
./scripts/apply-argo-apps.sh platform3-dev io
```

Or apply one service:

```bash
kubectl apply -f argo/platform3-dev/io/hello-world/application.yaml
```

## Cutover notes

- App names match legacy (`hello-world`, `integrator-workers`, …) — **do not apply alongside legacy apps** on the same cluster without renaming or offboarding legacy apps first.
- For parallel testing, suffix app names: `./scripts/generate-argo-app.sh platform3-dev io/hello-world hello-world-v2`
- Legacy apps use `celigo/cd` @ `platform3-dev`; v2 apps use `cd-v2` @ `main`.

## Manifest index

See [`manifests.txt`](../manifests.txt) for the full list of `application.yaml` paths.
