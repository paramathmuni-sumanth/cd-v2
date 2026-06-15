# Optional shared defaults per service (DRY layer).

This directory is for **future** extraction of common config across environments.
The authoritative per-environment configs live under `environments/{env}/`.

When splitting a service into base + overrides:

1. Run `./scripts/diff-env-branches.sh DOMAIN/SERVICE env-a env-b`
2. Move shared keys into `base/DOMAIN/SERVICE/microservice.yaml`
3. Keep env-specific keys in `environments/{env}/DOMAIN/SERVICE/env.yaml`

Not required for ArgoCD cutover — full configs in `environments/` are sufficient.
