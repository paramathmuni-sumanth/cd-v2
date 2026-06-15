#!/usr/bin/env bash
# Apply all ArgoCD Application manifests for an environment domain (requires kubectl).
#
# Usage:
#   ./scripts/apply-argo-apps.sh ENV [DOMAIN] [--dry-run]
#
# Example:
#   ./scripts/apply-argo-apps.sh platform3-dev io --dry-run
#   ./scripts/apply-argo-apps.sh platform3-dev io

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENV="${1:?Usage: $0 ENV [DOMAIN] [--dry-run]}"
DOMAIN="${2:-}"
DRY_RUN="${3:-}"

ARGO_DIR="${REPO_ROOT}/argo/${ENV}"
if [[ -n "${DOMAIN}" && "${DOMAIN}" != "--dry-run" ]]; then
  ARGO_DIR="${ARGO_DIR}/${DOMAIN}"
  shift 2 || true
else
  [[ "${2:-}" == "--dry-run" ]] && DRY_RUN="--dry-run"
fi

if [[ ! -d "${ARGO_DIR}" ]]; then
  echo "error: argo manifests not found at ${ARGO_DIR}" >&2
  echo "Run: ./scripts/generate-argo-apps-for-env.sh ${ENV} ${DOMAIN}" >&2
  exit 1
fi

manifests="$(find "${ARGO_DIR}" -name application.yaml | sort)"
count="$(echo "${manifests}" | grep -c . || true)"
echo "Applying ${count} manifest(s) from ${ARGO_DIR}"

echo "${manifests}" | while read -r manifest; do
  [[ -z "${manifest}" ]] && continue
  echo "  kubectl apply -f ${manifest}"
  if [[ "${DRY_RUN}" != "--dry-run" ]]; then
    kubectl apply -f "${manifest}"
  fi
done

echo "Done."
